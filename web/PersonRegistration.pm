package PersonRegistration;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = @EXPORT_OK = qw(
    getRegistrationData
    addRegistration
    deletePersonRegistered
    isPersonRegistered
    mergePersonRegistrations
    submitPersonRegistration
    updatePersonRegistration
    checkRenewalRegoOK
    checkNewRegoOK
    rolloverExistingPersonRegistrations
    checkIsSuspended
    getRegistrationDetail
    cleanPlayerPersonRegistrations
    hasPendingRegistration
    hasPendingTransferRegistration
);
use strict;
use lib "..",".";

use WorkFlow;
#use Log;
use RuleMatrix;
use NationalReportingPeriod;
use GenAgeGroup;
use Data::Dumper;
use Person;
use PersonRegisterWhat;
use AuditLog;
use Reg_common;
use PersonCertifications;
use PersonEntity;
use PersonUtils;
use PersonRegistrationStatusChange;

sub cleanPlayerPersonRegistrations  {

    my ($Data, $personID, $personRegistrationID) = @_;

    my @statusIN = ($Defs::PERSONREGO_STATUS_ACTIVE, $Defs::PERSONREGO_STATUS_PASSIVE);
    my %Reg = (
        personRegistrationID=> $personRegistrationID || 0,
        statusIN => \@statusIN,
    );
    my ($count, $reg_ref) = getRegistrationData(
        $Data,
        $personID,
        \%Reg
    );

    return if (! $count);
    #my %PE = ();
    #{
    #    my $entityID = $reg_ref->[0]{'intEntityID'};
    #    $PE{'personType'} = $reg_ref->[0]{'strPersonType'} || '';
    #    $PE{'personLevel'} = $reg_ref->[0]{'strPersonLevel'} || '';
    #    $PE{'personEntityRole'} = $reg_ref->[0]{'strPersonEntityRole'} || '';
    #    $PE{'sport'} = $reg_ref->[0]{'strSport'} || '';
    #    my $peID = doesOpenPEExist($Data, $personID, $entityID, \%PE);
    #    addPERecord($Data, $personID, $entityID, \%PE) if (! $peID)
    #}
    


    my %ExistingReg = (
        sport=> $reg_ref->[0]{'strSport'} || '',
        personType=> $reg_ref->[0]{'strPersonType'} || '',
        entityID=> $reg_ref->[0]{'intEntityID'} || 0,
        statusIN => \@statusIN,
    );
        #status=> $Defs::PERSONREGO_STATUS_ACTIVE,

        #ageLevel=> $reg_ref->[0]{'strAgeLevel'} || '',
    my ($countRecords, $regs_ref) = getRegistrationData(
        $Data,
        $personID,
        \%ExistingReg
    );
    foreach my $rego (@{$regs_ref})  {
        next if ($rego->{'intPersonRegistrationID'} == $personRegistrationID);
#        next if ($rego->{'strPersonLevel'} eq $reg_ref->[0]{'strPersonLevel'});
        my $thisRego = $rego;
        $thisRego->{'intCurrent'} = 0;
        $thisRego->{'strStatus'} = $Defs::PERSONREGO_STATUS_ROLLED_OVER;
        #$thisRego->{'strStatus'} = $Defs::PERSONREGO_STATUS_PASSIVE;
        my ($Second, $Minute, $Hour, $Day, $Month, $Year, $WeekDay, $DayOfYear, $IsDST) = localtime(time);
        $Year+=1900;
        $Month++;
        $thisRego->{'dtTo'} = "$Year-$Month-$Day" if (! $rego->{'dtTo'} or $rego->{'dtTo'} eq '0000-00-00');

        #$PE{'personLevel'} = $thisRego->{'strPersonLevel'} || '';
        #closePERecord($Data, $personID, $thisRego->{'intEntityID'}, '', \%PE);
        updatePersonRegistration($Data, $personID, $rego->{'intPersonRegistrationID'}, $thisRego, 0);
    }
}


sub rolloverExistingPersonRegistrations {

    my ($Data, $personID, $personRegistrationID) = @_;

    return if (! $personID or ! $personRegistrationID);
    my %Reg = (
        personRegistrationID=> $personRegistrationID || 0,
    );
    my ($count, $reg_ref) = getRegistrationData(
        $Data,
        $personID,
        \%Reg
    );
    
    return if (! $count);
    
    my @statusIN = ($Defs::PERSONREGO_STATUS_ACTIVE, $Defs::PERSONREGO_STATUS_PASSIVE);#, $Defs::PERSONREGO_STATUS_PENDING, $Defs::PERSONREGO_STATUS_INPROGRESS);
    my %ExistingReg = (
        sport=> $reg_ref->[0]{'strSport'} || '',
        personType=> $reg_ref->[0]{'strPersonType'} || '',
        personEntityRole=> $reg_ref->[0]{'strPersonEntityRole'} || '',
        entityID=> $reg_ref->[0]{'intEntityID'} || 0,
        statusIN => \@statusIN,
    );
        #status=> $Defs::PERSONREGO_STATUS_ACTIVE,
        #personLevel=> $reg_ref->[0]{'strPersonLevel'} || '',
        #ageLevel=> $reg_ref->[0]{'strAgeLevel'} || '',
    my ($countRecords, $regs_ref) = getRegistrationData(
        $Data,
        $personID,
        \%ExistingReg
    );
    foreach my $rego (@{$regs_ref})  {
        next if ($rego->{'intPersonRegistrationID'} == $personRegistrationID);
        my $oldStatus = $rego->{'strStatus'};
        my $originaldtTo = $rego->{'dtTo_'};

        my $thisRego = $rego;
        $thisRego->{'intCurrent'} = 0;
        $thisRego->{'strStatus'} = $Defs::PERSONREGO_STATUS_ROLLED_OVER;
        my ($Second, $Minute, $Hour, $Day, $Month, $Year, $WeekDay, $DayOfYear, $IsDST) = localtime(time);
        $Year+=1900;
        $Month++;
        $Day = sprintf("%02s", $Day);
        $Month= sprintf("%02s", $Month);
        my $dtNow = "$Year$Month$Day";
        if (! $originaldtTo or $originaldtTo eq "00000000" or $originaldtTo > $dtNow) {
            $thisRego->{'dtTo'} = "$Year-$Month-$Day";
        }
        
        addPersonRegistrationStatusChangeLog($Data, $rego->{'intPersonRegistrationID'}, $oldStatus, $Defs::PERSONREGO_STATUS_ROLLED_OVER, -1);
        updatePersonRegistration($Data, $personID, $rego->{'intPersonRegistrationID'}, $thisRego, 0);
    }
}

 
sub checkIsSuspended    {

    my ($Data, $personID, $entityID, $personType) = @_;

    my $st = qq[
        SELECT
            P.strStatus as PersonStatus,
            PR.strStatus as PRStatus
        FROM
            tblPerson as P
            LEFT JOIN tblPersonRegistration_$Data->{'Realm'} as PR ON (
                PR.intPersonID=P.intPersonID
                AND PR.intEntityID = ?
                AND PR.strPersonType = ?
                AND PR.strStatus='SUSPENDED'
            )
        WHERE
            P.intRealmID = ?
            AND P.intPersonID = ?
        LIMIT 1
    ];
  	my $q= $Data->{'db'}->prepare($st);
    $q->execute($entityID, $personType, $Data->{'Realm'}, $personID) or query_error($st);
    my ($personStatus, $prStatus) = $q->fetchrow_array();
    $personStatus ||= '';
    $prStatus ||= '';
    return ($personStatus, $prStatus);
}
    
     
sub checkNewRegoOK  {

    my ($Data, $personID, $rego_ref) = @_;
    my %Reg = (
        sport=> $rego_ref->{'sport'} || '',
        personType=> $rego_ref->{'personType'} || '',
        personEntityRole=> $rego_ref->{'personEntityRole'} || '',
        personLevel=> $rego_ref->{'personLevel'} || '',
        ageLevel=> $rego_ref->{'ageLevel'} || '',
    );
    my ($count, $regs) = getRegistrationData(
        $Data,
        $personID,
        \%Reg
    );
    my $ok = 1;
#    foreach my $reg (@{$regs})  {
#       next if $reg->{'intEntityID'} == $rego_ref->{'entityID'};
#       $ok = 0 if ($reg->{'strStatus'} ne $Defs::PERSONREGO_STATUS_DELETED or $reg->{'strStatus'} ne $Defs::PERSONREGO_STATUS_TRANSFERRED or $reg->{'strStatus'} ne $Defs::PERSONREGO_STATUS_INPROGRESS);
#    }

    return $ok if (! $ok);
    ## I assume the above is handled via checkLimits?
#Not OK.. Transfer needed

    my $playerInEntity = 0;
    if ($rego_ref->{'personType'} eq $Defs::PERSON_TYPE_PLAYER) {
        ## Do they have a ACTIVE or PASSIVE record in current Entity as ANY level
        %Reg=();
        my @statusIN = ($Defs::PERSONREGO_STATUS_ACTIVE, $Defs::PERSONREGO_STATUS_PASSIVE);
        %Reg = (
            sport=> $rego_ref->{'sport'} || '',
            personType=> $rego_ref->{'personType'} || '',
            entityID => $rego_ref->{'entityID'},
            personEntityRole=> $rego_ref->{'personEntityRole'} || '',
            statusIN => \@statusIN,
        );
            #ageLevel=> $rego_ref->{'ageLevel'} || '',
        $count=0;
        $regs='';
        ($count, $regs) = getRegistrationData(
            $Data,
            $personID,
            \%Reg
        );
        $playerInEntity = 1 if ($count);
    }
     
    ## Now check within this ENTITY
    %Reg=();
    %Reg = (
        sport=> $rego_ref->{'sport'} || '',
        personType=> $rego_ref->{'personType'} || '',
        entityID => $rego_ref->{'entityID'},
        personEntityRole=> $rego_ref->{'personEntityRole'} || '',
        personLevel=> $rego_ref->{'personLevel'} || '',
    );
        #ageLevel=> $rego_ref->{'ageLevel'} || '',
    $count=0;
    $regs='';
    ($count, $regs) = getRegistrationData(
        $Data,
        $personID,
        \%Reg
    );
    $ok=1;
    foreach my $reg (@{$regs})  {
        next if $reg->{'intEntityID'} != $rego_ref->{'entityID'};
        $ok = 0 if ($reg->{'strStatus'} eq $Defs::PERSONREGO_STATUS_PENDING or $reg->{'strStatus'} eq $Defs::PERSONREGO_STATUS_ACTIVE or $reg->{'strStatus'} eq $Defs::PERSONREGO_STATUS_PASSIVE);
        $ok = 0 if (! $playerInEntity and $reg->{'strStatus'} eq $Defs::PERSONREGO_STATUS_TRANSFERRED);
    }
    return $ok;
}

sub checkRenewalRegoOK  {

    my ($Data, $personID, $rego_ref) = @_;
    my $pref= undef;
    $pref = Person::loadPersonDetails($Data, $personID) if ($personID);
    return 0 if (defined $pref and ($pref->{'strStatus'} eq $Defs::PERSON_STATUS_SUSPENDED));
    my ($nationalPeriodID, undef, undef) = getNationalReportingPeriod($Data->{db}, $Data->{'Realm'}, $Data->{'RealmSubType'}, $rego_ref->{'sport'}, $rego_ref->{'personType'}, 'RENEWAL');

    $rego_ref->{'ruleFor'} = 'REGO';
    my ($personRegisterWhat, $errorMsg) = PersonRegisterWhat::optionsPersonRegisterWhat(
        $Data,
        $Data->{'Realm'},
        $Data->{'RealmSubType'},
        $rego_ref->{'originLevel'},
        'RENEWAL',
        $rego_ref->{'personType'} || '',
        '',
        $rego_ref->{'personEntityRole'} || '',
        '',
        $rego_ref->{'personLevel'} || '',
        '',
        $rego_ref->{'sport'} || '',
        '',
        $rego_ref->{'ageLevel'} || '',
        $rego_ref->{'personID'},
        $rego_ref->{'entityID'},
        '',
        '',
        'nature',
        0
    );

    my $validRego = 0;
    foreach my $option (@{$personRegisterWhat}) {
        if($option->{'value'} eq 'RENEWAL') {
            $validRego = 1;
            last;
        }
    }

    return $validRego if (!$validRego);

    my @statusIN = ($Defs::PERSONREGO_STATUS_ROLLED_OVER, $Defs::PERSONREGO_STATUS_ACTIVE, $Defs::PERSONREGO_STATUS_PASSIVE);#, $Defs::PERSONREGO_STATUS_PENDING, $Defs::PERSONREGO_STATUS_INPROGRESS);
    my %Reg = (
        sport=> $rego_ref->{'sport'} || '',
        personType=> $rego_ref->{'personType'} || '',
        personEntityRole=> $rego_ref->{'personEntityRole'} || '',
        statusIN => \@statusIN,
        entityID=> $rego_ref->{'entityID'} || 0,
    );
        #personLevel=> $rego_ref->{'personLevel'} || '',


    my ($count, undef) = getRegistrationData(
        $Data,
        $personID,
        \%Reg
    );
    my @statusNOTIN = ();
    @statusNOTIN = ($Defs::PERSONREGO_STATUS_INPROGRESS, $Defs::PERSONREGO_STATUS_REJECTED, $Defs::PERSONREGO_STATUS_PASSIVE, $Defs::PERSONREGO_STATUS_DELETED);

    %Reg=();
    %Reg = (
        sport=> $rego_ref->{'sport'} || '',
        personType=> $rego_ref->{'personType'} || '',
        personEntityRole=> $rego_ref->{'personEntityRole'} || '',
        personLevel=> $rego_ref->{'personLevel'} || '',
        statusNOTIN => \@statusNOTIN,
        entityID=> $rego_ref->{'entityID'} || 0,
        nationalPeriodID=>$nationalPeriodID,
        LoaningEntityOpenLoan => 0,
    );
    my ($countAlready, undef) = getRegistrationData(
        $Data,
        $personID,
        \%Reg
    );

    #return 1 if ($countActive or $countInactive or $countRolledOver); ## Must have an ACTIVE or PASSIVE record
    return 1 if ($count and ! $countAlready);
    return 0;
}


sub deletePersonRegistered  {
	my ($Data, $personID, $personRegistrationID) = @_;

    my $st = qq[
        UPDATE tblPersonRegistration_$Data->{'Realm'}
        SET strStatus = 'DELETED',
            dtLastUpdated=NOW()
        WHERE
            intPersonID = ?
            AND intPersonRegistrationID = ?
        LIMIT 1
    ];
  	my $q= $Data->{'db'}->prepare($st);
    $q->execute($personID, $personRegistrationID) or query_error($st);
    ####
    auditLog($personRegistrationID, $Data, 'Delete Person Registraton', 'Person Registration');
    ####
}

sub isPersonRegistered {

	my ( $Data, $personID, $regFilters_ref)=@_;

## Are there any "current" registration records for the member in the system
## Changed to ACTIVE/PASSIVE
    my %Reg=();
    for my $k (keys %{$regFilters_ref})  {
        $Reg{$k} = $regFilters_ref->{$k};
    }
    my @statusIN = ($Defs::PERSONREGO_STATUS_ACTIVE, $Defs::PERSONREGO_STATUS_PASSIVE);
    $Reg{'statusIN'} = \@statusIN;
    
    my ($count, $refs) = getRegistrationData($Data, $personID, \%Reg);

    my $ok = 0;
    foreach my $reg (@{$refs})  {
        $ok = 1 if (
            $reg->{'strStatus'} eq $Defs::PERSONREGO_STATUS_ACTIVE
            or $reg->{'strStatus'} eq $Defs::PERSONREGO_STATUS_PASSIVE
        );
        last if $ok;
    }
    return $ok;
}

sub mergePersonRegistrations    {

    my ($Data, $pFromId, $pToId) = @_;

    my ($pFromCount, $pFrom_refs) = getRegistrationData($Data, $pFromId, undef);
    my ($pToCount, $pTo_refs) = getRegistrationData($Data, $pToId, undef);

    my $stMove = qq[
        UPDATE tblPersonRegistration_$Data->{'Realm'}
        SET
            intPersonID = ?
        WHERE
            intPersonID = ?
            AND intPersonRegistrationID = ?
        LIMIT 1
    ];
  	my $qMove = $Data->{'db'}->prepare($stMove);

    my $stMerge = qq[
        UPDATE tblPersonRegistration_$Data->{'Realm'}
        SET
            intPersonID = ?,
            strStatus=?,
            dtFrom = ?,
            dtTo = ?,
            intCurrent = ?,
            intIsPaid = ?,
            intPaymentRequired = ?,
            dtAdded= ?,
            dtLastUpdated = ?
        WHERE
            intPersonID = ?
            AND intPersonRegistrationID = ?
        LIMIT 1
    ];
  	my $qMerge = $Data->{'db'}->prepare($stMerge);
        
    my $stTXNs = qq[
        UPDATE tblTransactions
        SET intPersonRegistrationID = ?
        WHERE 
            intPersonRegistrationID >0 
            AND intPersonRegistrationID = ?
    ];
  	my $qTXNs= $Data->{'db'}->prepare($stTXNs);

    my $stTASKs = qq[
        UPDATE tblWFTask
        SET
            intPersonID = ?,
            intPersonRegistrationID = ?
        WHERE
            intPersonID = ?
            AND intPersonRegistrationID = ?
    ];
  	my $qTasks= $Data->{'db'}->prepare($stTASKs);

    my $stDELTasks= qq[
        DELETE FROM tblWFTask
        WHERE
            intPersonID = ?
            AND strWFRuleFor = 'REGO'
            AND intPersonRegistrationID = ?
    ];
  	my $qDELTasks= $Data->{'db'}->prepare($stDELTasks);


    
    for my $From_ref (@{$pFrom_refs}) {
        my $keyFrom = $From_ref->{'intEntityID'} . "|" . $From_ref->{'strPersonType'} . "|" . $From_ref->{'strPersonSubType'} . "|" . $From_ref->{'strPersonLevel'} . "|" . $From_ref->{'strPersonEntityRole'} . "|" . $From_ref->{'strSport'} . "|" . $From_ref->{'strAgeLevel'};
        my $personRegoIDFrom = $From_ref->{'intPersonRegistrationID'};
        my $found_To_ref='';
        my $personRegoIDTo = 0;
        for my $To_ref (@{$pTo_refs}) {
            #lets see if there is a match
            my $keyTo = $To_ref->{'intEntityID'} . "|" . $To_ref->{'strPersonType'} . "|" . $To_ref->{'strPersonSubType'} . "|" . $To_ref->{'strPersonLevel'} . "|" . $To_ref->{'strPersonEntityRole'} . "|" . $To_ref->{'strSport'} . "|" . $To_ref->{'strAgeLevel'};

            if ($keyTo eq $keyFrom) {
                ##Match found
                $personRegoIDTo= $To_ref->{'intPersonRegistrationID'};
                $found_To_ref = $To_ref;
                last;
            }
        }
        if ($personRegoIDFrom and ! $personRegoIDTo )   {
  	        $qMove->execute($pToId, $pFromId, $personRegoIDFrom);
  	        ####
            auditLog($personRegoIDFrom, $Data, 'Move Person Registration', 'Person Registration');
            ####
            $qTasks->execute($pToId, $personRegoIDFrom, $pFromId, $personRegoIDFrom);
            ####
            auditLog($personRegoIDFrom, $Data, 'Update WFTask', 'Person Registration');
            ####
            $qTasks->execute($pToId, 0, $pFromId, 0);
        }
        my $tasks = 'USE_TO';
        if ($personRegoIDTo) {
            my $newStatus = $From_ref->{'strStatus'} eq 'ACTIVE' ? $From_ref->{'strStatus'} : $found_To_ref->{'strStatus'};
            if ($From_ref->{'strStatus'} eq 'ACTIVE' and $found_To_ref->{'strStatus'} ne 'ACTIVE')  {
                $tasks = 'USE_FROM';
            }
            
            my $new_dtFrom = $From_ref->{'dtFrom_'} < $found_To_ref->{'dtFrom_'} ? $From_ref->{'dtFrom'} : $found_To_ref->{'dtFrom'};
            my $new_dtTo= $From_ref->{'dtTo_'} > $found_To_ref->{'dtTo_'} ? $From_ref->{'dtTo'} : $found_To_ref->{'dtTo'};
            my $new_dtAdded= $From_ref->{'dtAdded_'} < $found_To_ref->{'dtAdded_'} ? $From_ref->{'dtAdded'} : $found_To_ref->{'dtAdded'};
            my $new_dtLastUpdated= $From_ref->{'dtLastUpdated_'} > $found_To_ref->{'dtLastUpdated_'} ? $From_ref->{'dtLastUpdated'} : $found_To_ref->{'dtLastUpdated'};

            my $new_intCurrent= $From_ref->{'intCurrent'} ? 1 : $found_To_ref->{'intCurrent'};
            my $new_intIsPaid= $From_ref->{'intIsPaid'} ? 1 : $found_To_ref->{'intIsPaid'};
            my $new_intPaymentRequired= $From_ref->{'intPaymentRequired'} ? 1 : $found_To_ref->{'intPaymentRequired'};

  	        $qMerge->execute($pToId, $newStatus, $new_dtFrom, $new_dtTo, $new_intCurrent, $new_intIsPaid, $new_intPaymentRequired, $new_dtAdded, $new_dtLastUpdated, $pToId, $personRegoIDTo);
            ####
            auditLog($personRegoIDTo, $Data, 'Merge Person Registration', 'Person Registration');
            ####
            $qTXNs->execute($personRegoIDTo, $personRegoIDFrom); 
            ####
            auditLog($personRegoIDTo, $Data, 'Transaction', 'Person Registration');
            ####
            
            if ($tasks eq 'USE_TO') {
                $qDELTasks->execute($pFromId, $personRegoIDFrom);
                 ####
           		 auditLog( $personRegoIDFrom, $Data, 'DELETE WFTask', 'Person Registration');
           		 ####
            }
            if ($tasks eq 'USE_FROM')   {
                $qDELTasks->execute($pToId, $personRegoIDTo); 
                 ####
           		 auditLog( $personRegoIDTo, $Data, 'DELETE WFTask', 'Person Registration');
           		 ####
                $qTasks->execute($pToId, $$personRegoIDTo, $pFromId, $personRegoIDFrom);
            }
        }
    }
}

sub updatePersonRegistration    {

    my ($Data, $personID, $personRegistrationID, $Reg_ref, $personStatus) = @_;

    if ($Reg_ref->{'personEntityRole'} && $Reg_ref->{'personEntityRole'} eq '-')  {
        $Reg_ref->{'personEntityRole'}= '';
    }
    if ($Reg_ref->{'strPersonEntityRole'} && $Reg_ref->{'strPersonEntityRole'} eq '-')  {
        $Reg_ref->{'strPersonEntityRole'}= '';
    }
        
    my $newBaseRecord = 0;
    if($personStatus eq $Defs::PERSONREGO_STATUS_INPROGRESS) {
        $newBaseRecord = 1;
    }

	my $st = qq[
   		UPDATE tblPersonRegistration_$Data->{'Realm'} 
        SET
            strPersonType = ?,
            strPersonSubType = ?,
            strPersonLevel = ?,
            strPersonEntityRole = ?,
            strStatus = ?,
            strSport = ?,
            intCurrent = ?,
            dtFrom = ?,
            dtTo = ?,
            dtLastUpdated = ?,
            strAgeLevel = ?,
            strRegistrationNature = ?,
            intIsPaid = ?,
            intPaymentRequired = ?,
            intNewBaseRecord = ?
        WHERE
            intPersonID = ?
            AND intPersonRegistrationID = ?
        LIMIT 1
    ];

  	my $q = $Data->{'db'}->prepare($st);
  	$q->execute(
        $Reg_ref->{'personType'} || $Reg_ref->{'strPersonType'},
        $Reg_ref->{'personSubType'} || $Reg_ref->{'strPersonSubType'} || '',
        $Reg_ref->{'personLevel'} || $Reg_ref->{'strPersonLevel'} || '',
        $Reg_ref->{'personEntityRole'} || $Reg_ref->{'strPersonEntityRole'} || '',
        $Reg_ref->{'status'} || $Reg_ref->{'strStatus'},
        $Reg_ref->{'sport'} || $Reg_ref->{'strSport'} || '',
        $Reg_ref->{'current'} || $Reg_ref->{'intCurrent'},
        $Reg_ref->{'dateFrom'} || $Reg_ref->{'dtFrom'},
        $Reg_ref->{'dateTo'} || $Reg_ref->{'dtTo'},
        $Reg_ref->{'dateLastUpdated'} || $Reg_ref->{'dtLastUpdated'},
        $Reg_ref->{'ageLevel'} || $Reg_ref->{'strAgeLevel'} || '',
        $Reg_ref->{'registrationNature'} || $Reg_ref->{'strRegistrationNature'},
        $Reg_ref->{'isPaid'} || $Reg_ref->{'intIsPaid'},
        $Reg_ref->{'paymentRequired'} || $Reg_ref->{'intPaymentRequired'},
        $newBaseRecord,
        $personID,
        $personRegistrationID,
  	);
	####
    auditLog($personRegistrationID, $Data, 'Update Person Registration', 'Person Registration');
    ####
	if ($q->errstr) {
		return 0;
	}
    return 1;
}

sub getRegistrationData	{
	my ( $Data, $personID, $regFilters_ref)=@_;
	my $client = $Data->{'client'} || '';
    my %clientValues = getClient($client);
	#my $myCurrentLevelValue = $clientValues{'authLevel'};
    my $myCurrentLevelValue = getLastEntityLevel($Data->{'clientValues'}) || 0;
    my @values = (
        $personID,
    );
    my $where = '';

    if ($regFilters_ref->{'personEntityRole'} && $regFilters_ref->{'personEntityRole'} eq '-')  {
        $regFilters_ref->{'personEntityRole'}= '';
    }
    if ($regFilters_ref->{'strPersonEntityRole'} && $regFilters_ref->{'strPersonEntityRole'} eq '-')  {
        $regFilters_ref->{'strPersonEntityRole'}= '';
    }
    if($regFilters_ref->{'personRegistrationID'})  {
        push @values, $regFilters_ref->{'personRegistrationID'};
        $where .= " AND pr.intPersonRegistrationID= ? ";
    }
    if($regFilters_ref->{'personType'})  {
        push @values, $regFilters_ref->{'personType'};
        $where .= " AND pr.strPersonType = ? ";
    }
    if(exists $regFilters_ref->{'personSubType'})  {
        push @values, $regFilters_ref->{'personSubType'};
        $where .= " AND pr.strPersonSubType = ? ";
    }
    if(exists $regFilters_ref->{'ageLevel'})  {
        push @values, $regFilters_ref->{'ageLevel'};
        $where .= " AND pr.strAgeLevel= ? ";
    }
    if(exists $regFilters_ref->{'personLevel'})  {
        push @values, $regFilters_ref->{'personLevel'};
        $where .= " AND pr.strPersonLevel= ? ";
    }
    if(exists $regFilters_ref->{'personEntityRole'})  {
        push @values, $regFilters_ref->{'personEntityRole'};
        $where .= " AND pr.strPersonEntityRole= ? ";
    }
    if(exists $regFilters_ref->{'statusNOTIN'})  {
        my $statusNOTIN = "";
        foreach my $status (@{$regFilters_ref->{'statusNOTIN'}})   {
            $statusNOTIN .= "," if ($statusNOTIN);
            #$statusNOTIN .= "'".$status."'";
            $statusNOTIN .= qq["$status"];
        }
        $where .= " AND pr.strStatus NOT IN ($statusNOTIN)";
    }
    if(exists $regFilters_ref->{'statusIN'})  {
        my $statusIN = "";
        foreach my $status (@{$regFilters_ref->{'statusIN'}})   {
            $statusIN .= "," if ($statusIN);
            #$statusIN .= "'".$status."'";
            $statusIN .= qq["$status"];
        }
        $where .= " AND pr.strStatus IN ($statusIN)";
    }
    if($regFilters_ref->{'status'})  {
        push @values, $regFilters_ref->{'status'};
        $where .= " AND pr.strStatus= ? ";
    }
    if(exists $regFilters_ref->{'sport'})  {
        push @values, $regFilters_ref->{'sport'};
        $where .= " AND pr.strSport= ? ";
    }
    if(exists $regFilters_ref->{'current'})  {
        push @values, $regFilters_ref->{'current'};
        $where .= " AND pr.intCurrent = ? ";
    }
    if($regFilters_ref->{'registrationNature'})  {
        push @values, $regFilters_ref->{'registrationNature'};
        $where .= " AND pr.strRegistrationNature= ? ";
    }
    if(exists $regFilters_ref->{'nationalPeriodID'})  {
        push @values, $regFilters_ref->{'nationalPeriodID'};
        $where .= " AND pr.intNationalPeriodID= ? ";
    }
    if(exists $regFilters_ref->{'paymentRequired'})  {
        push @values, $regFilters_ref->{'paymentRequired'};
        $where .= " AND pr.intPaymentRequired = ? ";
    }
    if(exists $regFilters_ref->{'entityID'})  {
        push @values, $regFilters_ref->{'entityID'};
        $where .= " AND pr.intEntityID= ? ";
    }
    if(exists $regFilters_ref->{'originLevel'})  {
        push @values, $regFilters_ref->{'originLevel'};
        $where .= " AND pr.intOriginLevel = ? ";
    }
    if(exists $regFilters_ref->{'LoaningEntityOpenLoan'})  {
        push @values, $regFilters_ref->{'LoaningEntityOpenLoan'};
        $where .= " AND (existprq.intOpenLoan IS NULL OR existprq.intOpenLoan = ?) ";
    }

    my $st= qq[
        SELECT 
            pr.*, 
            prq.intPersonRequestID,
            prq.dtLoanFrom,
            prq.dtLoanTo,
            prq.strRequestNotes,
            prq.intOpenLoan,
            existprq.intPersonRequestID as existPersonRequestID,
            existprq.intOpenLoan as existOpenLoan,
            eprq.strLocalName as requestToEntityName,
			np.strNationalPeriodName,
			np.dtFrom as npdtFrom,
			np.dtTo as npdtTo,
            p.dtDOB,
            DATE_FORMAT(p.dtDOB, "%d/%m/%Y") as DOB,
            TIMESTAMPDIFF(YEAR, p.dtDOB, CURDATE()) as currentAge,
            p.intGender,
            p.intGender as Gender,
            p.strStatus as personStatus,
            p.strISONationality,
            p.strNationalNum,
            p.strLocalFirstname,
            p.strLocalSurname,
            DATE_FORMAT(pr.dtFrom, "%Y%m%d") as dtFrom_,
            DATE_FORMAT(pr.dtTo, "%Y%m%d") as dtTo_,
            DATE_FORMAT(pr.dtFrom,'%d %b %Y') AS spaneldtFrom,
            DATE_FORMAT(pr.dtTo,'%d %b %Y') AS spaneldtTo,
            DATE_FORMAT(pr.dtAdded, "%Y%m%d%H%i") as dtAdded_,
            DATE_FORMAT(pr.dtAdded, "%Y-%m-%d %H:%i") as dtAdded_formatted,
            DATE_FORMAT(pr.dtLastUpdated, "%Y%m%d%H%i") as dtLastUpdated_,
            COUNT(DISTINCT T.intTransactionID) as CountTXNs,
            er.strEntityRoleName,
            e.strLocalName,
            e.intEntityLevel,
            e.strLatinName,
            e.strEntityType,
            e.intEntityLevel,
	p.intInternationalTransfer,
	p.intInternationalLoan,
	p.dtInternationalLoanFromDate,
	p.dtInternationalLoanToDate,
            e.intEntityID
        FROM
            tblPersonRegistration_$Data->{'Realm'} AS pr
            LEFT JOIN tblTransactions as T ON (
                T.intPersonRegistrationID = pr.intPersonRegistrationID
                AND T.intStatus <> 1
            )
            LEFT JOIN tblNationalPeriod as np ON (
                np.intNationalPeriodID = pr.intNationalPeriodID
            )
            LEFT JOIN tblEntityTypeRoles as er ON (
                er.strEntityRoleKey = pr.strPersonEntityRole
                and er.strPersonType = pr.strPersonType
            )
            INNER JOIN tblEntity e ON (
                pr.intEntityID = e.intEntityID 
            )
            INNER JOIN tblPerson as p ON (
                p.intPersonID = pr.intPersonID
            )	
            LEFT JOIN tblPersonRequest prq ON (
                prq.intPersonRequestID = pr.intPersonRequestID
                AND prq.intPersonID = pr.intPersonID
                AND prq.strRequestType = 'LOAN'
            )
            LEFT JOIN tblPersonRequest existprq ON (
                existprq.intExistingPersonRegistrationID = pr.intPersonRegistrationID
                AND existprq.intPersonID= pr.intPersonID
                AND existprq.strRequestType = 'LOAN'
                AND existprq.strRequestStatus IN ('PENDING', 'COMPLETED')
            )
            LEFT JOIN tblEntity eprq ON (
                eprq.intEntityID = prq.intRequestToEntityID
            )

			
        WHERE     
            p.intPersonID = ?
            $where
        GROUP BY
            pr.intPersonRegistrationID
        ORDER BY
          pr.dtApproved DESC
    ];	
	
    my $db=$Data->{'db'};
    my $query = $db->prepare($st) or query_error($st);

    $query->execute(@values) or query_error($st);
    my $count=0;
	
    my @Registrations = ();
    my @reg_docs = ();  
    my $locale = $Data->{'lang'}->getLocale();
    while(my $dref= $query->fetchrow_hashref()) {
        my $internationalTransfer = (($dref->{'intNewBaseRecord'} and $dref->{'intInternationalTransfer'}) or ($dref->{'strStatus'} eq 'INPROGRESS' and $dref->{'intInternationalTransfer'})) ? 1 : 0;
        my $internationalLoan = (($dref->{'intNewBaseRecord'} and $dref->{'intInternationalLoan'}) or ($dref->{'strStatus'} eq 'INPROGRESS' and $dref->{'intInternationalLoan'})) ? 1 : 0;

        $count++;
        $dref->{'sport'} = $dref->{'strSport'} || '';
        $dref->{'personType'} = $dref->{'strPersonType'} || '';
        $dref->{'personLevel'} = $dref->{'strPersonLevel'} || '';
        $dref->{'ageLevel'} = $dref->{'strAgeLevel'} || '';
        $dref->{'registrationNature'} = $dref->{'strRegistrationNature'} || '';

        $dref->{'Sport'} = $Defs::sportType{$dref->{'strSport'}} || '';
        $dref->{'PersonType'} = $Defs::personType{$dref->{'strPersonType'}} || '';
        $dref->{'PersonLevel'} = $Defs::personLevel{$dref->{'strPersonLevel'}} || '';
        $dref->{'changeLevel'} = $dref->{'intPersonLevelChanged'} || 0;
        $dref->{'PreviousPersonLevel'} = $Defs::personLevel{$dref->{'strPreviousPersonLevel'}} || '';
        $dref->{'AgeLevel'} = $Defs::ageLevel{$dref->{'strAgeLevel'}} || '';
        $dref->{'Status'} = $Defs::personRegoStatus{$dref->{'strStatus'}} || '';
        $dref->{'RegistrationNature'} = $Defs::registrationNature{$dref->{'strRegistrationNature'}} || '';
        $dref->{'currentAge'} = personAge($Data,$dref->{'dtDOB'});

		my $sql = qq[
			SELECT 
                strApprovalStatus,
                COALESCE (LT_D.strString1,D.strDocumentName) as strDocumentName,
                intFileID,
                strOrigFilename,
                pr.intPersonRegistrationID,
                tblDocumentType.intDocumentTypeID,
                strLockAtLevel,
                tblUploadedFiles.dtUploaded as DateUploaded 
            FROM tblUploadedFiles 
                INNER JOIN tblDocuments ON tblUploadedFiles.intFileID = tblDocuments.intUploadFileID  
                INNER JOIN tblDocumentType ON tblDocumentType.intDocumentTypeID = tblDocuments.intDocumentTypeID   
                INNER JOIN tblPersonRegistration_$Data->{'Realm'} as pr ON pr.intPersonRegistrationID = tblDocuments.intPersonRegistrationID 
                LEFT JOIN tblLocalTranslations AS LT_D ON (
                    LT_D.strType = 'DOCUMENT'
                    AND LT_D.intID = tblDocumentType.intDocumentTypeID
                    AND LT_D.strLocale = '$locale'
                )

			WHERE pr.intPersonRegistrationID = $dref->{intPersonRegistrationID} AND pr.intPersonID = $personID 
		];

		$sql = qq[
		SELECT
	    t.strApprovalStatus,
		D.intDocumentTypeID,
	    t.intUploadFileID,
	    t.strOrigFilename,
	    t.DateUploaded,
	    t.intPersonRegistrationID,
        t.intEntityID as DocoEntityID,
        t.intEntityLevel as DocoEntityLevel,
	    D.strDocumentName,			
	    RI.intID,
            RI.intRequired,
            RI.intUseExistingThisEntity,
            RI.intUseExistingAnyEntity,
	    D.strLockAtLevel            
        FROM
			tblRegistrationItem as RI				
			LEFT JOIN tblDocumentType as D ON (intDocumentTypeID = RI.intID and strItemType='DOCUMENT')
			LEFT JOIN (
				SELECT intDocumentTypeID, strApprovalStatus, intUploadFileID, strOrigFilename, dtUploaded as DateUploaded,
				pr.intPersonRegistrationID, E.intEntityID, E.intEntityLevel FROM tblDocuments 
				INNER JOIN tblUploadedFiles  ON (tblUploadedFiles.intFileID = tblDocuments.intUploadFileID )
				INNER JOIN tblPersonRegistration_$Data->{'Realm'}  as pr ON (pr.intPersonRegistrationID = tblDocuments.intPersonRegistrationID )
                LEFT JOIN tblEntity as E ON (E.intEntityID=pr.intEntityID)
				WHERE pr.intPersonID = ?
				AND pr.intPersonRegistrationID = $dref->{intPersonRegistrationID}
			) as t ON t.intDocumentTypeID = RI.intID 
        WHERE
            RI.intRealmID = $Data->{'Realm'}
            AND RI.intSubRealmID IN (0, $dref->{'intSubRealmID'})
            AND RI.strRuleFor = 'REGO'
	    AND RI.strRegistrationNature = '$dref->{'strRegistrationNature'}'
            AND RI.intEntityLevel IN (0, $dref->{'intEntityLevel'})
            AND RI.intOriginLevel = $dref->{'intOriginLevel'}
	    AND RI.strPersonType IN ('', '$dref->{'strPersonType'}') 
	    AND RI.strPersonLevel IN ('', '$dref->{'strPersonLevel'}')
        AND RI.strPersonEntityRole IN ('', '')
	    AND RI.strSport IN ('', '$dref->{'strSport'}')
	    AND RI.strAgeLevel IN ('', '$dref->{'strAgeLevel'}')  
        AND RI.strItemType = 'DOCUMENT' 
        AND (RI.strISOCountry_IN ='' OR RI.strISOCountry_IN IS NULL OR RI.strISOCountry_IN LIKE CONCAT('%|$dref->{'strISONationality'}|%'))
        AND (RI.strISOCountry_NOTIN ='' OR RI.strISOCountry_NOTIN IS NULL OR RI.strISOCountry_NOTIN NOT LIKE CONCAT('%|$dref->{'strISONationality'}|%'))
        AND (RI.intFilterFromAge = 0 OR RI.intFilterFromAge <= $dref->{'currentAge'})
        AND (RI.intFilterToAge = 0 OR RI.intFilterToAge >= $dref->{'currentAge'})
        AND (RI.intItemForInternationalTransfer = 0 OR RI.intItemForInternationalTransfer = $internationalTransfer)
        AND (RI.intItemForInternationalLoan = 0 OR RI.intItemForInternationalLoan = $internationalLoan)
];		
            #AND RI.intEntityLevel IN (0, $myCurrentLevelValue)
            #AND RI.intOriginLevel = $Data->{'clientValues'}{'authLevel'}

		my $sth = $Data->{'db'}->prepare($sql);
		$sth->execute($personID);
		while(my $data_ref = $sth->fetchrow_hashref()){
			#push @reg_docs, $data_ref;	
            $data_ref->{'DateUploaded_RAW'} = $data_ref->{'DateUploaded'};
            $data_ref->{'DateUploaded'} = $Data->{'l10n'}{'date'}->TZformat(
                $data_ref->{'DateUploaded'},
                'MEDIUM',
                'SHORT'
            );
			push @{$dref->{'documents'}},$data_ref;				
		}			

        my $certifications = getPersonCertifications(
            $Data,
            $dref->{'intPersonID'},
            $dref->{'strPersonType'},
            0
        );

        my @certString;
        foreach my $cert (@{$certifications}) {
            push @certString, $cert->{'strCertificationName'};
        }

        $dref->{'regCertifications'} = join(', ', @certString);				

        push @Registrations, $dref;

		
    }
	
    return ($count, \@Registrations);
}

sub addRegistration {
    my($Data, $Reg_ref) = @_;
	if ($Reg_ref->{'personEntityRole'} eq '-')  {
        $Reg_ref->{'personEntityRole'}= '';
    }
    my $status = $Reg_ref->{'status'} || 'PENDING';

    if (! exists $Reg_ref->{'paymentRequired'})    {
        my $ruleFor = 'REGO';
        $ruleFor = $Reg_ref->{'ruleFor'} if ($Reg_ref->{'ruleFor'});
        my $matrix_ref = getRuleMatrix($Data, $Reg_ref->{'originLevel'}, $Reg_ref->{'entityLevel'}, $Defs::LEVEL_PERSON, $Reg_ref->{'entityType'} || '', $ruleFor, $Reg_ref);
        $Reg_ref->{'paymentRequired'} = $matrix_ref->{'intPaymentRequired'} || 0;
        #$Reg_ref->{'dateFrom'} = $matrix_ref->{'dtFrom'} if (! $Reg_ref->{'dtFrom'});
        #$Reg_ref->{'dateTo'} = $matrix_ref->{'dtTo'} if (! $Reg_ref->{'dtTo'});
        $Reg_ref->{'paymentRequired'} = $matrix_ref->{'intPaymentRequired'} || 0;		
    }
    my ($nationalPeriodID, $npFrom, $npTo) = getNationalReportingPeriod($Data->{db}, $Data->{'Realm'}, $Data->{'RealmSubType'}, $Reg_ref->{'sport'}, $Reg_ref->{'personType'}, $Reg_ref->{'registrationNature'});
    #$Reg_ref->{'dateFrom'} = $npFrom if (! $Reg_ref->{'dtFrom'});
    #$Reg_ref->{'dateTo'} = $npTo if (! $Reg_ref->{'dtTo'} and $Reg_ref->{'personType'} ne $Defs::PERSON_TYPE_PLAYER);
    my $genAgeGroup ||=new GenAgeGroup ($Data->{'db'},$Data->{'Realm'}, $Data->{'RealmSubType'});
    my $ageGroupID = 0;

    if ($Reg_ref->{'personID'})  {
        my $st= qq[
            SELECT 
                DATE_FORMAT(dtDOB, "%Y%m%d") as DOBAgeGroup, 
                intGender
            FROM 
                tblPerson
            WHERE 
                intPersonID= ?
        ];
        my $qry=$Data->{'db'}->prepare($st);
        $qry->execute($Reg_ref->{'personID'});
        my ($DOBAgeGroup, $Gender)=$qry->fetchrow_array();
        $ageGroupID=$genAgeGroup->getAgeGroup($Gender, $DOBAgeGroup) || 0;
    }

	my $st = qq[
   		INSERT INTO tblPersonRegistration_$Data->{'Realm'} (
            intPersonID,
            intEntityID,
            strPersonType,
            strPersonSubType,
            strPersonLevel,
            strPersonEntityRole,
            strStatus,
            strSport,
            intCurrent,
            intOriginLevel,
            intOriginID,
            intCreatedByUserID,
            dtFrom,
            dtTo,
            intRealmID,
            intSubRealmID,
            dtAdded,
            dtLastUpdated,
            intNationalPeriodID,
            intAgeGroupID,
            strAgeLevel,
            strRegistrationNature,
            intPaymentRequired,
            intClearanceID,
            intPersonRequestID,
            strShortNotes
		)
		VALUES
		(
            ?,
            ?,
            ?,
            ?,
            ?,
            ?,
            ?,
            ?,
            ?,
            ?,
            ?,
            ?,
            ?,
            ?,
            ?,
            ?,
            NOW(),
            NOW(),
            ?,
            ?,
            ?,
            ?,
            ?,
            ?,
            ?,
            ?
        )
    ];

  	my $q = $Data->{'db'}->prepare($st);
  	$q->execute(
  		$Reg_ref->{'personID'},
  		$Reg_ref->{'entityID'},
  		$Reg_ref->{'personType'} || '',  		
  		$Reg_ref->{'personSubType'} || '',  		
  		$Reg_ref->{'personLevel'} || '',  		
  		$Reg_ref->{'personEntityRole'} || '',  		
  		$status || '',  		
  		$Reg_ref->{'sport'} || '',  		
  		$Reg_ref->{'current'} || 0,  		
  		$Reg_ref->{'originLevel'} || 0,  		
  		$Reg_ref->{'originID'} || 0,  		
        $Reg_ref->{'originLevel'} == 1 ? $Data->{'User'}{'UserID'} || 0 : $Data->{'clientValues'}{'userID'} || 0,
  		$Reg_ref->{'dateFrom'},  		
  		$Reg_ref->{'dateTo'},  		
  		$Data->{'Realm'},
  		$Data->{'RealmSubType'} || 0,
  		$nationalPeriodID || 0,
  		$ageGroupID || 0,
  		$Reg_ref->{'ageLevel'} || '',
  		$Reg_ref->{'registrationNature'} || '',
  		$Reg_ref->{'paymentRequired'} || 0,
  		$Reg_ref->{'clearanceID'} || 0,
  		$Reg_ref->{'personRequestID'} || 0,
  		$Reg_ref->{'MAComment'} || '',
  	);
	
	if ($q->errstr) {
		return (0, 0);
	}
  	my $personRegistrationID = $q->{mysql_insertid};
  	####
  	auditLog($personRegistrationID, $Data, 'Add Person Registration', 'Person Registration');
  	###	
    my $rc=0;
    if ($status eq 'PENDING')   {
        cleanTasks(
            $Data,
            $Reg_ref->{'personID'},
            $Reg_ref->{'entityID'},
            $personRegistrationID,
            'REGO'
        );
        personInProgressToPending($Data, $Reg_ref->{'personID'});
  	    $rc = addWorkFlowTasks(
            $Data,
            'REGO', 
            $Reg_ref->{'registrationNature'}, 
            $Reg_ref->{'originLevel'} || 0, 
            $Reg_ref->{'entityID'} || 0,
            $Reg_ref->{'personID'},
            $personRegistrationID, 
            0,
		$Reg_ref->{'intInternationalTransfer'}
        );
    }
  	
 	return ($personRegistrationID, $rc) ;
}

sub submitPersonRegistration    {

    my ($Data, $personID, $personRegistrationID, $rego_ref) = @_;

    my %Reg=();
    $Reg{'personRegistrationID'} = $personRegistrationID;
    my ($count, $regs) = getRegistrationData($Data, $personID, \%Reg);
	
    my $pr_ref = $regs->[0];
    if ($count && $pr_ref->{'strStatus'} eq $Defs::PERSONREGO_STATUS_INPROGRESS) {
        my $personStatus = $pr_ref->{'personStatus'};
        $pr_ref->{'strStatus'} = 'PENDING';
        $pr_ref->{'intPaymentRequired'} = 0 if ($pr_ref->{'CountTXNs'} == 0);
        $pr_ref->{'paymentRequired'} = 0 if ($pr_ref->{'CountTXNs'} == 0);

        updatePersonRegistration($Data, $personID, $personRegistrationID, $pr_ref, $personStatus);
        WorkFlow::cleanTasks(
            $Data,
            $personID,
            $pr_ref->{'entityID'} || $pr_ref->{'intEntityID'} || 0,
            $personRegistrationID,
            'REGO'
        );
        personInProgressToPending($Data, $personID);

        my $newBaseRecord = ($personStatus eq $Defs::PERSONREGO_STATUS_INPROGRESS) ? 1 : 0;
        my $internationalTransfer = ($newBaseRecord and $pr_ref->{'intInternationalTransfer'}) ? 1 : 0;
        my $internationalLoan = ($newBaseRecord and $pr_ref->{'intInternationalLoan'}) ? 1 : 0;

        my $rc = WorkFlow::addWorkFlowTasks(
            $Data,
            'REGO', 
            $pr_ref->{'registrationNature'} || $pr_ref->{'strRegistrationNature'} || '',
            $pr_ref->{'originLevel'} || $pr_ref->{'intOriginLevel'} || 0, 
            $pr_ref->{'entityID'} || $pr_ref->{'intEntityID'} || 0,
            $personID,
            $personRegistrationID, 
            0,
            #$pr_ref->{'intInternationalTransfer'} || $pr_ref->{'intInternationalLoan'} || 0
            $internationalTransfer || $internationalLoan || 0
        );
        ($count, $regs) = getRegistrationData($Data, $personID, \%Reg);
        if ($count) {
            my $pr_ref = $regs->[0];
            $rego_ref->{'strStatus'} = $pr_ref->{'strStatus'};
        }
    }
}

sub personInProgressToPending {

    my ($Data, $personID) = @_;

    return if (! $personID);
    my $st = qq[
        UPDATE tblPerson
        SET strStatus='PENDING', intSystemStatus=1
        WHERE 
            intPersonID=?
            AND intRealmID=?
            AND strStatus='INPROGRESS'
        LIMIT 1
    ];
    my $qry=$Data->{'db'}->prepare($st);
    $qry->execute($personID, $Data->{'Realm'}); 
    ####
    auditLog($personID, $Data, 'Update Person Registration To Pending','Person Registration');
    ###
}

sub getRegistrationDetail {
	my ($Data, $personRegistrationID) = @_;
	
    my @params = (
        $personRegistrationID,
    );

    my $st= qq[
        SELECT 
            pr.*, 
            IF(pr.strStatus != 'ACTIVE', pr.strStatus, IF(pr.strStatus = 'ACTIVE' AND pr.intPaymentRequired = 1, 'ACTIVE_PENDING_PAYMENT', pr.strStatus)) AS displayStatus,
            np.strNationalPeriodName,
            p.dtDOB,
            DATE_FORMAT(p.dtDOB, "%d/%m/%Y") as DOB,
		    TIMESTAMPDIFF(YEAR, p.dtDOB, CURDATE()) as currentAge,
            p.intGender,
            p.intGender as Gender,
            DATE_FORMAT(pr.dtFrom, "%Y%m%d") as dtFrom_,
            DATE_FORMAT(pr.dtTo, "%Y%m%d") as dtTo_,
            DATE_FORMAT(pr.dtAdded, "%Y%m%d%H%i") as dtAdded_,
            DATE_FORMAT(pr.dtAdded, "%Y-%m-%d %H:%i") as dtAdded_formatted,
            DATE_FORMAT(pr.dtLastUpdated, "%Y%m%d%H%i") as dtLastUpdated_,
            er.strEntityRoleName,
            e.strLocalName,
            e.intEntityLevel,
            e.strLatinName
        FROM
            tblPersonRegistration_$Data->{'Realm'} AS pr
            LEFT JOIN tblNationalPeriod as np ON (
                np.intNationalPeriodID = pr.intNationalPeriodID
            )
            LEFT JOIN tblEntityTypeRoles as er ON (
                er.strEntityRoleKey = pr.strPersonEntityRole
                and er.strPersonType = pr.strPersonType
            )
            INNER JOIN tblEntity e ON (
                pr.intEntityID = e.intEntityID 
            )
            INNER JOIN tblPerson as p ON (
                p.intPersonID = pr.intPersonID
            )
        WHERE     
            pr.intPersonRegistrationID = ?
        ORDER BY
          pr.dtAdded DESC
    ];	
    my $db = $Data->{'db'};
    my $query = $db->prepare($st) or query_error($st);

    $query->execute(@params) or query_error($st);

    my @RegistrationDetail = ();
      
    while(my $dref= $query->fetchrow_hashref()) {
        $dref->{'currentAge'} = personAge($Data,$dref->{'dtDOB'});
        $dref->{'Sport'} = $Defs::sportType{$dref->{'strSport'}} || '';
        $dref->{'PersonType'} = $Defs::personType{$dref->{'strPersonType'}} || '';
        $dref->{'PersonLevel'} = $Defs::personLevel{$dref->{'strPersonLevel'}} || '';
        $dref->{'AgeLevel'} = $Defs::ageLevel{$dref->{'strAgeLevel'}} || '';
        $dref->{'strStatus'} = $dref->{'strStatus'} || '';
        $dref->{'displayStatus'} = $dref->{'displayStatus'} || '';
        $dref->{'RegistrationNature'} = $Defs::registrationNature{$dref->{'strRegistrationNature'}} || '';

        $dref->{'sport'} = $dref->{'strSport'} || '';
        $dref->{'personType'} = $dref->{'strPersonType'} || '';
        $dref->{'personLevel'} = $dref->{'strPersonLevel'} || '';
        $dref->{'ageLevel'} = $dref->{'strAgeLevel'} || '';
        $dref->{'registrationNature'} = $dref->{'strRegistrationNature'} || '';
        push @RegistrationDetail, $dref;
    }
    return (\@RegistrationDetail);
}
#
sub hasPendingRegistration {
    my ($Data, $personID, $sport, $existingRegos) = @_;
    if(1==2 and scalar @{$existingRegos}){
        my $count = 0;
        my %renewalCtrlForRego = ();
        foreach my $rego (@{$existingRegos}){
            #check for sport        
            if(!exists $renewalCtrlForRego{$rego->{'strSport'}.$rego->{'strPersonType'}}){
                $renewalCtrlForRego{$rego->{'strSport'}.$rego->{'strPersonType'}} = {
                    regoID => $rego->{'intPersonRegistrationID'},
                    enableButton => ($rego->{'strStatus'} eq 'ACTIVE' && $rego->{'strRegistrationNature'} eq 'NEW') ? 1 : 0 ,   
                    index => $count,
                    status => $rego->{'strStatus'},  
                };
            }
            else{
                # check if the last sport has a pending or active status
                if($renewalCtrlForRego{$rego->{'strSport'}.$rego->{'strPersonType'}}{'enableButton'} && $rego->{'strRegistrationNature'} eq 'RENEWAL'){ #last sport seen has active status
                    $existingRegos->[$renewalCtrlForRego{$rego->{'strSport'}.$rego->{'strPersonType'}}{'index'}]->{'renew_link'} = '';   
                    $existingRegos->[$renewalCtrlForRego{$rego->{'strSport'}.$rego->{'strPersonType'}}{'index'}]->{'changelevel_link'} = ''; 
                }
                else {
                    $existingRegos->[$count]->{'renew_link'} = ''; # 
                    $existingRegos->[$count]->{'changelevel_link'} = '';
                }                
            }            
            $count++;            
        }
        
    }
    
    if($personID){
        my $query = qq[SELECT intPersonRegistrationID FROM tblPersonRegistration_$Data->{'Realm'} WHERE intPersonID = ? AND strSport = ? AND strRegistrationNature = 'RENEWAL' AND strStatus = 'PENDING' AND strPersonType = 'PLAYER'];        
        my $st = $Data->{'db'}->prepare($query);
        $st->execute($personID,$sport);
        my $dref = $st->fetchrow_hashref();
        return $dref->{'intPersonRegistrationID'};
        
    }
   
    return 1;  
    
}

sub hasPendingTransferRegistration {
    my ($Data, $personID, $sport, $existingRegos) = @_;
    my $count = 0;
    if(scalar @{$existingRegos}){
        foreach my $rego (@{$existingRegos}){
            my $query = qq[SELECT intPersonRequestID FROM tblPersonRequest WHERE intPersonID = ? AND strRequestType = 'TRANSFER' AND intExistingPersonRegistrationID = ? AND strSport = ? AND strRequestStatus = 'INPROGRESS' AND strPersonType = 'PLAYER'];
            my $st = $Data->{'db'}->prepare($query);
            $st->execute($personID,$rego->{'intPersonRegistrationID'},$rego->{'strSport'});
            my $dref = $st->fetchrow_hashref();
            if($dref->{'intPersonRequestID'}){
                $existingRegos->[$count]->{'changelevel_link'} = '';
                $existingRegos->[$count]->{'renew_link'} = '';
            }
            $count++;
        }
    }
    if($personID){
        my $query = qq[SELECT intPersonRequestID FROM tblPersonRequest WHERE intPersonID = ? AND strRequestType = 'TRANSFER' AND strSport = ? AND strRequestStatus = 'INPROGRESS' AND strPersonType = 'PLAYER'];
         my $st = $Data->{'db'}->prepare($query);
         $st->execute($personID,$sport);
         my $dref = $st->fetchrow_hashref();
         return $dref->{'intPersonRequestID'};
    }
    return 1;
}
#
1;
