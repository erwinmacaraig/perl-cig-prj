package RegoTypeLimits;
require Exporter;
@ISA = qw(Exporter);

@EXPORT = @EXPORT_OK = qw(
    checkRegoTypeLimits
);

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
    
    if ($personRegistrationID)  {
        my %Reg = (
            personRegistrationID => $personRegistrationID,
        );
        my ($count, $regs) = getRegistrationData(
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
        my @rowValues=();
        @rowValues=@values;
        if ($dref->{'strSport'} and $dref->{'strSport'} ne '')    {
            $stPRrow.= qq[ AND strSport = ? ];
            push @rowValues, $dref->{'strSport'};
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
        my $qryPR = $Data->{'db'}->prepare($stPRrow);
        $qryPR -> execute(@rowValues);
        my $prCount = $qryPR->fetchrow_array() || 0;
        $prCount++; #For current row
warn("SQL:$stPRrow");
print STDERR Dumper(\@rowValues);
warn("COUNT IS $prCount");
        if ($prCount > $dref->{'intLimit'}) {
            return 0;
        }
    }
    return 1;
}
1;

