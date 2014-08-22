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

sub bulkPersonRollover {
    my($Data, $nextAction, $bulk_ref, $hidden_ref) = @_;

    my $body = '';
    my $client = setClient($Data->{'clientValues'});
    my $realmID = $Data->{'Realm'};


    warn("GET intNationalPeriodID");


    my $st = qq[
        SELECT DISTINCT
            P.intPersonID,
            P.strLocalSurname,
            P.strLocalFirstname,
            DATE_FORMAT(P.dtDOB,"%d/%m/%Y") AS dtDOB,
            P.dtDOB AS dtDOB_RAW,
            P.strNationalNum
        FROM 
            tblPerson as P
            INNER JOIN tblPersonRegistration_$realmID as PR ON (
                PR.intPersonID = P.intPersonID
                AND PR.strPersonType = ?
                AND PR.strPersonLevel= ?
                AND PR.strPersonEntityRole= ?
                AND PR.strAgeLevel= ?
                AND PR.strStatus IN ('ACTIVE', 'PASSIVE')
                AND PR.strRegistrationNature = ?
                AND PR.intEntityID = ?
                AND PR.intNationalPeriodID <> ?
            )
        WHERE 
            P.strStatus NOT IN ('DELETED', 'SUSPENDED')
            AND P.intRealmID = ?
        ORDER BY strLocalSurname, strLocalFirstname
    ];
    my @values=(
        $bulk_ref->{'personType'} || '',
        $bulk_ref->{'personLevel'} || '',
        $bulk_ref->{'personEntityRole'} || '',
        $bulk_ref->{'ageLevel'} || '',
        $bulk_ref->{'registrationNature'} || '',
        $bulk_ref->{'entityID'} || '',
        $bulk_ref->{'nationalPeriodID'} || '',
        $realmID
    );
    
    my $q = $Data->{'db'}->prepare($st);
    $q->execute(@values);
    my @rowdata    = ();
    while (my $dref = $q->fetchrow_hashref()) {
        my %row = ();
        for my $i (qw(intPersonID strLocalSurname strLocalFirstname dtDOB dtDOB_RAW strNationalNum))    {
            $row{$i} = $dref->{$i};
        }
        $row{'id'} = $dref->{'intPersonID'};
        push @rowdata, \%row;
    }

    my $memfieldlabels=FieldLabels::getFieldLabels($Data,$Defs::LEVEL_PERSON);
    my @headers = (
        {
            type => 'RowCheckbox',
        },
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
        },

    );
    my $grid = showGrid(Data=>$Data, columns=>\@headers, rowdata=>\@rowdata, gridid=>'grid', width=>'99%', height=>700);

    my $lang = $Data->{'lang'};

    my $type = $Data->{'clientValues'}{'currentLevel'};

    my %PageData = (
        grid=> $grid,
        hidden_ref=> $hidden_ref,
        nextAction => $nextAction, 
        target => $Data->{'target'},
        Lang => $lang,
        client => $client,
    );
    $body = runTemplate($Data, \%PageData, 'registration/bulkpersons.templ') || '';

    my $title = $Data->{'lang'}->txt('Bulk Registration');
    return ($body, $title);
}
1;
# vim: set et sw=4 ts=4: