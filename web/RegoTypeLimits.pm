package RegoTypeLimits;
require Exporter;
@ISA = qw(Exporter);

@EXPORT = @EXPORT_OK = qw(
    checkRegoTypeLimits
);

use lib ".", "..";
use strict;
use Reg_common;
use Utils;
use AuditLog;
use CGI qw(unescape param);
use Log;
use PersonRegistration;
use Data::Dumper;

sub checkRegoTypeLimits    {

    my ($Data, $personID, $personRegistrationID, $sport, $personType, $entityRole, $personLevel, $ageLevel) = @_;

    ## Sport, PersonType mandatory.  But other fields can be blank in tblRegoTypeLimits
    $personID ||= 0;
    $personRegistrationID ||= 0;
    my $entityID=0;
    
    if ($personRegistrationID)  {
        my %Reg = (
            personRegistrationID => $personRegistrationID,
        );
        my ($count, $regs) = PersonRegistration::getRegistrationData(
            $Data,
            $personID,
            \%Reg
        );
        if ($count ==1) {
            $sport = $regs->[0]{'strSport'};
            $personType= $regs->[0]{'strPersonType'};
            $entityRole= $regs->[0]{'strPersonEntityRole'};
            $personLevel= $regs->[0]{'strPersonLevel'};
            $ageLevel= $regs->[0]{'strAgeLevel'};
            $entityID= $regs->[0]{'intEntityID'};
        }
    }
    my $st = qq[
        SELECT 
            *
        FROM
            tblRegoTypeLimits
        WHERE 
            intRealmID = ?
            AND intSubRealmID IN (0, ?)
            AND strPersonType = ?
    ];
    my @limitValues = (
        $Data->{'Realm'}, 
        $Data->{'RealmSubType'},
        $personType,
    );
    if (defined $sport) {
        push @limitValues, $sport;
        $st .= qq[ AND strSport IN ('', ?)];
    }
    if (defined $entityRole) {
        push @limitValues, $entityRole;
        $st .= qq[ AND strPersonEntityRole IN ('', ?)];
    }
    if (defined $personLevel) {
        push @limitValues, $personLevel;
        $st .= qq[ AND strPersonLevel IN ('', ?)];
    }
    if (defined $ageLevel) {
        push @limitValues, $ageLevel;
        $st .= qq[ AND strAgeLevel IN ('', ?)];
    }

    my $query = $Data->{'db'}->prepare($st);
    $query -> execute(@limitValues);

    ## Build up an SQL for Count of Unique Person/Entity per sport/personType
    my $stPE = qq[
        SELECT
            COUNT(intPersonRegistrationID) as CountPE,
            intEntityID
        FROM
            tblPersonRegistration_$Data->{'Realm'}
        WHERE
            intPersonID = ?
            AND intPersonRegistrationID <> ?
            AND strStatus IN ('ACTIVE', 'PENDING', 'SUSPENDED')
            AND strPersonType = ?
    ];
    my $stPR = qq[
        SELECT
            COUNT(intPersonRegistrationID) as CountPR
        FROM
            tblPersonRegistration_$Data->{'Realm'}
        WHERE
            intPersonID = ?
            AND intPersonRegistrationID <> ?
            AND strStatus IN ('ACTIVE', 'PENDING', 'SUSPENDED')
            AND strPersonType = ?
    ];
    my @values =();
    push @values, $personID;
    push @values, $personRegistrationID;
    push @values, $personType;

    while (my $dref = $query->fetchrow_hashref())   {
        next if ! $dref->{'intLimit'};
        my $stPRrow= $stPR;
        my $stPErow= $stPE;
        my @rowValues=();
        my @PErowValues=();
        @PErowValues=@values;
        @rowValues = @values;
        if ($dref->{'strSport'} and $dref->{'strSport'} ne '')    {
            $stPRrow.= qq[ AND strSport = ? ];
            push @rowValues, $dref->{'strSport'};
            $stPErow.= qq[ AND strSport = ? ];
            push @PErowValues, $dref->{'strSport'};
        }
        
        if (defined $dref->{'strPersonEntityRole'} and $dref->{'strPersonEntityRole'} ne '')    {
            $stPRrow .= qq[ AND strPersonEntityRole = ?];
            push @rowValues, $dref->{'strPersonEntityRole'};
        }
        if (defined $dref->{'strPersonLevel'} and $dref->{'strPersonLevel'} ne '')    {
            $stPRrow .= qq[ AND strPersonLevel = ?];
            push @rowValues, $dref->{'strPersonLevel'};
        }
        if (defined $dref->{'strAgeLevel'} and $dref->{'strAgeLevel'} ne '')    {
            $stPRrow .= qq[ AND strAgeLevel = ?];
            push @rowValues, $dref->{'strAgeLevel'};
        }
        $stPErow .= qq[GROUP BY intEntityID, strPersonType, strSport];

        if ($dref->{'strLimitType'} eq 'PERSONENTITY_UNIQUE')  {
            ## Only runs on PersonType & Sport
            my $peCount = 0;
            my $qryPE = $Data->{'db'}->prepare($stPErow);
            $qryPE -> execute(@PErowValues);
            my $thisEntitySeen = 0;
            while (my $pe_ref = $qryPE->fetchrow_hashref()) {
                if ($pe_ref->{'intEntityID'} and $pe_ref->{'intEntityID'} == $entityID)  {
                    $thisEntitySeen = 1;
                }
                $peCount++;
            }
            $peCount++ if (!$thisEntitySeen);
            if ($peCount > $dref->{'intLimit'}) {
                return 0;
            }
        }
        else    {
            ### Normal, across system count
            my $qryPR = $Data->{'db'}->prepare($stPRrow);
            $qryPR -> execute(@rowValues);
            my $prCount = $qryPR->fetchrow_array() || 0;
            $prCount++; #For current row
            if ($prCount > $dref->{'intLimit'}) {
                return 0;
            }
        }
    }
    return 1;
}
1;

