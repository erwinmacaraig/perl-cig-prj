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

    my ($Data, $personID, $personRegistrationID, $sport, $personType, $entityRole, $personLevel, $ageLevel,$entityID) = @_;
	
	
    ## Sport, PersonType mandatory.  But other fields can be blank in tblRegoTypeLimits
    $personID ||= 0;
    $personRegistrationID ||= 0;
    $entityID ||= 0;
	my $entityType = '';
    
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
            $entityType= $regs->[0]{'strEntityType'};
            return 1 if ($regs->[0]{'strRegistrationNature'} eq 'DOMESTIC_LOAN');
        }
    }
    my $st = qq[
        SELECT 
            *,
            IF(strSport = '', 0, 1) +
            IF(strPersonType = '', 0, 1) +
            IF(strPersonEntityRole = '', 0, 1) +
            IF(strPersonLevel = '', 0, 1) +
            IF(strEntityType = '', 0, 1) +
            IF(strAgeLevel = '', 0, 1) as fieldSpecifiedExistCount
        FROM
            tblRegoTypeLimits
        WHERE 
            intRealmID = ?
            AND intSubRealmID IN (0, ?)
    ];
            #AND strPersonType = ?
    my @limitValues = (
        $Data->{'Realm'}, 
        $Data->{'RealmSubType'},
        #$personType,
    );
    if (defined $entityType) {
		$st .= qq[ AND strEntityType IN ('', '$entityType')];
    }
    if (defined $sport) {
		$st .= qq[ AND strSport IN ('', '$sport')];
    }
    if (defined $personType) {
        #push @limitValues, $personType;
        #$st .= qq[ AND strPersonType IN ('', ?)];  
		$st .= qq[ AND strPersonType IN ('', '$personType')];   
    }
    if (defined $entityRole) {
        #push @limitValues, $entityRole;
        #$st .= qq[ AND strPersonEntityRole IN ('', ?)];
		$st .= qq[ AND strPersonEntityRole IN ('', '$entityRole')];
    }
    if (defined $personLevel) {
        #push @limitValues, $personLevel;
        $st .= qq[ AND strPersonLevel IN ('', '$personLevel')];
    }
    if (defined $ageLevel) {
        #push @limitValues, $ageLevel;
        #$st .= qq[ AND strAgeLevel IN ('', ?)];
		$st .= qq[ AND strAgeLevel IN ('', '$ageLevel')];
    }

    $st .= qq[ ORDER BY fieldSpecifiedExistCount DESC ];
    my $query = $Data->{'db'}->prepare($st);
    $query->execute(@limitValues);
		
    ## Build up an SQL for Count of Unique Person/Entity per sport/personType
    my $stPE = qq[
        SELECT
            COUNT(intPersonRegistrationID) as CountPE,
            PR.intEntityID
        FROM
            tblPersonRegistration_$Data->{'Realm'} as PR
		INNER JOIN tblEntity as E ON (E.intEntityID = PR.intEntityID)
        WHERE
            PR.intPersonID = ?
            AND PR.intPersonRegistrationID <> ?
            AND PR.strStatus IN ('ACTIVE', 'PENDING', 'SUSPENDED', 'PASSIVE')
    ];
            #AND strPersonType = ?
    my $stPR = qq[
        SELECT
            COUNT(intPersonRegistrationID) as CountPR
        FROM
            tblPersonRegistration_$Data->{'Realm'} as PR
		INNER JOIN tblEntity as E ON (E.intEntityID = PR.intEntityID)
        WHERE
            PR.intPersonID = ?
            AND PR.intPersonRegistrationID <> ?
            AND PR.strStatus IN ('ACTIVE', 'PENDING', 'SUSPENDED', 'PASSIVE')
    ];
            #AND strPersonType = ?
    my @values =();
    push @values, $personID;
    push @values, $personRegistrationID;
    #push @values, $personType;

    while (my $dref = $query->fetchrow_hashref())   {
        next if ! $dref->{'intLimit'};
        my $stPRrow= $stPR;
        my $stPErow= $stPE;
        my @rowValues=();
        my @PErowValues=();
        @PErowValues=@values;
        @rowValues = @values;

        if ($dref->{'strEntityType'} and $dref->{'strEntityType'} ne '')    {
            $stPRrow.= qq[ AND E.strEntityType = ? ];
            push @rowValues, $dref->{'strEntityType'};
        }

        if ($dref->{'strSport'} and $dref->{'strSport'} ne '')    {
            $stPRrow.= qq[ AND PR.strSport = ? ];
            push @rowValues, $dref->{'strSport'};
            $stPErow.= qq[ AND PR.strSport = ? ];
            push @PErowValues, $dref->{'strSport'};
        }

        if ($dref->{'strPersonType'} and $dref->{'strPersonType'} ne '')    {
            $stPRrow.= qq[ AND PR.strPersonType = ? ];
            push @rowValues, $dref->{'strPersonType'};
            $stPErow.= qq[ AND PR.strPersonType = ? ];
            push @PErowValues, $dref->{'strPersonType'};
        }
        if (defined $dref->{'strPersonEntityRole'} and $dref->{'strPersonEntityRole'} ne '')    {
            $stPRrow .= qq[ AND PR.strPersonEntityRole = ?];
            push @rowValues, $dref->{'strPersonEntityRole'};
            $stPErow.= qq[ AND PR.strPersonEntityRole= ? ];
            push @PErowValues, $dref->{'strPersonEntityRole'};
        }
        if (defined $dref->{'strPersonLevel'} and $dref->{'strPersonLevel'} ne '')    {
            $stPRrow .= qq[ AND PR.strPersonLevel = ?];
            push @rowValues, $dref->{'strPersonLevel'};
            $stPErow.= qq[ AND PR.strPersonLevel= ? ];
            push @PErowValues, $dref->{'strPersonLevel'};
        }
        if (defined $dref->{'strAgeLevel'} and $dref->{'strAgeLevel'} ne '')    {
            $stPRrow .= qq[ AND PR.strAgeLevel = ?];
            push @rowValues, $dref->{'strAgeLevel'};
            $stPErow.= qq[ AND PR.strAgeLevel= ? ];
            push @PErowValues, $dref->{'strAgeLevel'};
        }
        #$stPErow .= qq[GROUP BY intEntityID, strPersonType, strSport];
        $stPErow .= qq[GROUP BY PR.intEntityID, PR.strPersonType];
        $stPErow .= qq[, PR.strSport] if ($dref->{'strSport'} and $dref->{'strSport'} ne '');
        $stPErow .= qq[, PR.strPersonLevel] if (defined $dref->{'strPersonLevel'} and $dref->{'strPersonLevel'} ne '');
        $stPErow .= qq[, PR.strAgeLevel] if (defined $dref->{'strAgeLevel'} and $dref->{'strAgeLevel'} ne '');

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

