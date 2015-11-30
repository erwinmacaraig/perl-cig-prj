#
# $Header: svn://svn/SWM/trunk/web/ListMembers.pm 11631 2014-05-21 04:32:15Z sliu $
#

package BulkPersons;

require Exporter;
@ISA =    qw(Exporter);
@EXPORT = qw(bulkPersonRollover);
@EXPORT_OK = qw(bulkPersonRollover);

use strict;
use CGI qw(param unescape escape);

use lib '.', "..";
use InstanceOf;
use Defs;
use Reg_common;
use FieldLabels;
use Utils;
use DBUtils;
use CustomFields;
use RecordTypeFilter;
use GridDisplay;
use AgeGroups;
use Seasons;
use FormHelpers;
use AuditLog;
use Log;
use TTTemplate;
use Person;
use Data::Dumper;
use PersonUtils;

sub bulkPersonRollover {
    my($Data, $nextAction, $bulk_ref, $hidden_ref, $countOnly) = @_;
    
    my $body = '';
    my $client = setClient($Data->{'clientValues'});
    my $realmID = $Data->{'Realm'};

    my $surname = param('d_surname') || '';
    my $yobfrom= param('d_yobfrom') || '';
    my $yobto = param('d_yobto') || '';
    my $gender= param('d_gender') || '';
    my $surnameFilter = '';
    if ($surname)   {
        $surnameFilter = qq[ AND P.strLocalSurname LIKE '$surname%'];
    }
    my $yobFilter = '';
    $yobfrom = '' if ($yobfrom !~ /\d+/);
    if ($yobfrom)   {
        $yobFilter.= qq[ AND YEAR(P.dtDOB) >= $yobfrom ];
    }
    $yobto = '' if ($yobto !~ /\d+/);
    if ($yobto)   {
print STDERR "OK: $yobto\n";
        $yobFilter.= qq[ AND YEAR(P.dtDOB) <= $yobto ];
    }
    my $genderFilter = '';
    if ($gender and $gender =~ /1|2/)   {
        $genderFilter = qq[ AND P.intGender = $gender ];
    }
    my $maxCount = $Data->{'SystemConfig'}{'BulkRenewalsMaxCount'} || 100000;

    #my $st = qq[
    #    SELECT DISTINCT
    #        P.intPersonID,
    #        P.strLocalSurname,
    #        P.strLocalFirstname,
    #        DATE_FORMAT(P.dtDOB,"%d/%m/%Y") AS dtDOB,
    #        P.dtDOB AS dtDOB_RAW,
    #        P.strNationalNum
    #    FROM 
    #        tblPerson as P
    #        INNER JOIN tblPersonRegistration_$realmID as PR ON (
    #            PR.intPersonID = P.intPersonID
    #            AND PR.strPersonType = ?
    #            AND PR.strPersonLevel= ?
    #            AND PR.strPersonEntityRole= ?
    #            AND PR.strAgeLevel= ?
    #            AND PR.strStatus IN ('ACTIVE', 'PASSIVE')
    #            AND PR.strRegistrationNature = ?
    #            AND PR.intEntityID = ?
    #            AND PR.intNationalPeriodID <> ?
    #        )
    #    WHERE 
    #        P.strStatus NOT IN ('DELETED', 'SUSPENDED')
    #        AND P.intRealmID = ?
    #    ORDER BY strLocalSurname, strLocalFirstname
    #];

    my $st = qq[
        SELECT DISTINCT
            P.intPersonID,
            P.strLocalSurname,
            P.strLocalFirstname,
            P.dtDOB,
            TIMESTAMPDIFF(YEAR, P.dtDOB, CURDATE()) as currentAge,
            P.dtDOB AS dtDOB_RAW,
            P.strNationalNum
        FROM 
            tblPerson as P
            INNER JOIN tblPersonRegistration_$realmID as PR ON (
                PR.intPersonID = P.intPersonID
                AND PR.strPersonType = ?
                AND PR.strSport = ?
                AND PR.strPersonLevel= ?
                AND PR.strPersonEntityRole= ?
                AND PR.strStatus IN ("$Defs::PERSONREGO_STATUS_ACTIVE", "$Defs::PERSONREGO_STATUS_PASSIVE")
                AND PR.intEntityID = ?
                AND PR.intNationalPeriodID <> ?
            )
            LEFT JOIN tblPersonRegistration_$realmID as PRto ON (
                PRto.intPersonID = P.intPersonID
                AND PRto.strPersonType = PR.strPersonType
                AND PRto.strSport = PR.strSport 
                AND PRto.strPersonLevel= PR.strPersonLevel
                AND PRto.strPersonEntityRole= PR.strPersonEntityRole
                AND PRto.strStatus IN ("$Defs::PERSONREGO_STATUS_ACTIVE", "$Defs::PERSONREGO_STATUS_PASSIVE", "$Defs::PERSONREGO_STATUS_PENDING", "$Defs::PERSONREGO_STATUS_ROLLED_OVER")
                AND PRto.intEntityID = PR.intEntityID
                AND PRto.intNationalPeriodID = ?
            )
            LEFT JOIN tblPersonRequest prq ON (
                prq.intPersonID= PR.intPersonID
                AND prq.intPersonRequestID = PR.intPersonRequestID
                AND prq.strRequestType = 'LOAN'
            )
            LEFT JOIN tblPersonRequest existprq ON (
                existprq.intPersonID= PR.intPersonID
                AND existprq.intExistingPersonRegistrationID = PR.intPersonRegistrationID
                AND existprq.strRequestType = 'LOAN'
                AND existprq.strRequestStatus IN ('PENDING', 'COMPLETED')
            )
        WHERE 
            P.strStatus NOT IN ("$Defs::PERSON_STATUS_DELETED", "$Defs::PERSON_STATUS_SUSPENDED")
            AND P.strStatus IN ("$Defs::PERSON_STATUS_REGISTERED")
            AND P.intRealmID = ?
            AND PRto.intPersonRegistrationID IS NULL
            AND (
                (PR.intIsLoanedOut = 0 and PR.intOnLoan = 0)
                OR (PR.intIsLoanedOut = 1 AND (existprq.intPersonRequestID IS NULL OR existprq.intOpenLoan = 0))
                OR (PR.intOnLoan = 1 AND prq.intOpenLoan= 1)
            )
            $surnameFilter
            $yobFilter
            $genderFilter
                
        ORDER BY strLocalSurname, strLocalFirstname
    ];

    my @values=(
        $bulk_ref->{'personType'} || '',
        $bulk_ref->{'sport'} || '',
        $bulk_ref->{'personLevel'} || '',
        $bulk_ref->{'personEntityRole'} || '',
        $bulk_ref->{'entityID'} || '',
        $bulk_ref->{'nationalPeriodID'} || '',
        $bulk_ref->{'nationalPeriodID'} || '',
        $realmID
    );
       
    my $q = $Data->{'db'}->prepare($st);
    $q->execute(@values);
    my $count = 0;
    my @rowdata    = ();

    while (my $dref = $q->fetchrow_hashref()) {
        next if(PersonRegistration::hasPendingTransferRegistration($Data,$dref->{'intPersonID'},$bulk_ref->{'sport'},[]));
        $dref->{'currentAge'} = personAge($Data,$dref->{'dtDOB'});
        my $newAgeLevel = Person::calculateAgeLevel($Data, $dref->{'currentAge'});
        next if $newAgeLevel ne $bulk_ref->{'ageLevel'};
        $count++;
        last if ($count > $maxCount);
        my %row = ();
        
        for my $i (qw(intPersonID strLocalSurname strLocalFirstname dtDOB dtDOB_RAW strNationalNum))    {
            $row{$i} = $dref->{$i};
        }
        $row{'dtDOB'} = $Data->{'l10n'}{'date'}->format($dref->{'dtDOB'},'MEDIUM');
        $row{'id'} = $dref->{'intPersonID'};
        push @rowdata, \%row;
    }

    #Depends on the call
    #if countOnly == 1, simply return the number of records
    return $count if($countOnly);
    my $title = $Data->{'lang'}->txt('Bulk Registration');
    if ($count > $maxCount) {
        my $errMsg = $Data->{'lang'}->txt("Too many records returned - You must enter a Family Name filter");
        $body = qq[
            <div class="alert">
                <div>
                    <span class="fa fa-exclamation"></span>
                    <p>$errMsg</p>
                </div>
            </div>
        ];
        return ($body, $title);
    }

    my $memfieldlabels=FieldLabels::getFieldLabels($Data,$Defs::LEVEL_PERSON);
    my @headers = (
        {
            name => $Data->{'lang'}->txt("Check"),
            field => 'intPersonID',
            type => 'RowCheckbox',
        },
        #{
            #name => "ID for now",
            #field => 'intPersonID',
        #},
        {
            name => $memfieldlabels->{'strNationalNum'} || $Data->{'lang'}->txt('National Num.'),
            field => 'strNationalNum',
        },
        {
            name => $memfieldlabels->{'strLocalSurname'} || $Data->{'lang'}->txt('Family Name'),
            field => 'strLocalSurname',
        },
        {
            name => $memfieldlabels->{'strLocalFirstname'} || $Data->{'lang'}->txt('First Name'),
            field => 'strLocalFirstname',
        },
        {
            name => $memfieldlabels->{'dtDOB'} || $Data->{'lang'}->txt('Date of Birth'),
            field => 'dtDOB',
            sortdata => 'dtDOB_RAW',
        },

    );
    my $grid = showGrid(Data=>$Data, columns=>\@headers, rowdata=>\@rowdata, gridid=>'grid', width=>'100%', height=>700, instanceDestroy=>'true');

    my $lang = $Data->{'lang'};

    my $type = $Data->{'clientValues'}{'currentLevel'};

    my %PageData = (
        grid=> $grid,
        hidden_ref=> $hidden_ref,
        nextAction => $nextAction, 
        target => $Data->{'target'},
        Lang => $lang,
        client => $client,
        rowcount => scalar(@rowdata),
    );
    $body = runTemplate($Data, \%PageData, 'registration/bulkpersons.templ') || '';

    return ($body, $title);
}
1;
# vim: set et sw=4 ts=4:
