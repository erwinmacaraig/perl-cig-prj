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
);

use strict;
use WorkFlow;
#use Log;
use Data::Dumper;

sub deletePersonRegistered  {
	my ($Data, $personID, $personRegistrationID) = @_;

    my $st = qq[
        UPDATE tblPersonRegistration_$Data->{'Realm'}
        SET strStatus = 'DELETED'
        WHERE
            intPersonID = ?
            AND intPersonRegistrationID = ?
        LIMIT 1
    ];
  	my $q= $Data->{'db'}->prepare($st);
    $q->execute($personID, $personRegistrationID) or query_error($st);
}

sub isPersonRegistered {

	my ( $Data, $personID, $regFilters_ref)=@_;

## Are there any "current" registration records for the member in the system
    $regFilters_ref->{'current'} = 1;
    my ($count, $p1_refs) = getRegistrationData($Data, $personID, $regFilters_ref);

    return 1 if $count;
    return 0;
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
            $qTasks->execute($pToId, $personRegoIDFrom, $pFromId, $personRegoIDFrom);
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

            $qTXNs->execute($personRegoIDTo, $personRegoIDFrom);
            if ($tasks eq 'USE_TO') {
                $qDELTasks->execute($pFromId, $personRegoIDFrom);
            }
            if ($tasks eq 'USE_FROM')   {
                $qDELTasks->execute($pToId, $personRegoIDTo);
                $qTasks->execute($pToId, $$personRegoIDTo, $pFromId, $personRegoIDFrom);
            }
        }
    }
}

sub updatePersonRegistration    {

    my ($Data, $personID, $personRegistrationID, $Reg_ref) = @_;

	my $st = qq[
   		UPDATE tblPersonRegistration_$Data->{'Realm'} 
        SET
            intEntityID = ?,
            strPersonType = ?,
            strPersonSubType = ?,
            strPersonLevel = ?,
            strPersonEntityRole = ?,
            strStatus = ?,
            strSport = ?,
            intCurrent = ?,
            intOriginLevel = ?,
            intOriginID = ?,
            dtFrom = ?,
            dtTo = ?,
            intRealmID = ?,
            intSubRealmID = ?,
            dtAdded = ?,
            dtLastUpdated = ?,
            intNationalPeriodID = ?,
            intAgeGroupID = ?,
            strAgeLevel = ?,
            strRegistrationNature = ?,
            intPaymentRequired = ?
        WHERE
            intPersonID = ?
            AND intPersonRegistrationID = ?
        LIMIT 1
    ];

  	my $q = $Data->{'db'}->prepare($st);
  	$q->execute(
        $Reg_ref->{'intEntityID'},
        $Reg_ref->{'strPersonType'},
        $Reg_ref->{'strPersonSubType'},
        $Reg_ref->{'strPersonLevel'},
        $Reg_ref->{'strPersonEntityRole'},
        $Reg_ref->{'strStatus'},
        $Reg_ref->{'strSport'},
        $Reg_ref->{'intCurrent'},
        $Reg_ref->{'intOriginLevel'},
        $Reg_ref->{'intOriginID'},
        $Reg_ref->{'dtFrom'},
        $Reg_ref->{'dtTo'},
        $Data->{'Realm'},
        $Data->{'RealmSubType'},
        $Reg_ref->{'dtAdded'},
        $Reg_ref->{'dtLastUpdated'},
        $Reg_ref->{'intNationalPeriodID'},
        $Reg_ref->{'intAgeGroupID'},
        $Reg_ref->{'strAgeLevel'},
        $Reg_ref->{'strRegistrationNature'},
        $Reg_ref->{'intPaymentRequired'},
        $personID,
        $personRegistrationID
  	);
	
	if ($q->errstr) {
		return 0;
	}
    return 1;
}

sub getRegistrationData	{
	my ( $Data, $personID, $regFilters_ref)=@_;
	
    my @values = (
        $personID,
    );
    my $where = '';
    if($regFilters_ref->{'personRegistrationID'})  {
        push @values, $regFilters_ref->{'personRegistrationID'};
        $where .= " AND pr.intPersonRegistrationID= ? ";
    }
    if($regFilters_ref->{'personType'})  {
        push @values, $regFilters_ref->{'personType'};
        $where .= " AND pr.strPersonType = ? ";
    }
    if($regFilters_ref->{'personSubType'})  {
        push @values, $regFilters_ref->{'personSubType'};
        $where .= " AND pr.strPersonSubType = ? ";
    }
    if($regFilters_ref->{'personLevel'})  {
        push @values, $regFilters_ref->{'personLevel'};
        $where .= " AND pr.strPersonLevel= ? ";
    }
    if($regFilters_ref->{'personEntityRole'})  {
        push @values, $regFilters_ref->{'personEntityRole'};
        $where .= " AND pr.strPersonEntityRole= ? ";
    }
    if($regFilters_ref->{'status'})  {
        push @values, $regFilters_ref->{'status'};
        $where .= " AND pr.strStatus= ? ";
    }
    if($regFilters_ref->{'sport'})  {
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

    my $st= qq[
        SELECT 
            pr.*, 
            DATE_FORMAT(pr.dtFrom, "%Y%m%d") as dtFrom_,
            DATE_FORMAT(pr.dtTo, "%Y%m%d") as dtTo_,
            DATE_FORMAT(pr.dtAdded, "%Y%m%d%H%i") as dtAdded_,
            DATE_FORMAT(pr.dtLastUpdated, "%Y%m%d%H%i") as dtLastUpdated_,
            e.strLocalName 
        FROM
            tblPersonRegistration_$Data->{'Realm'} AS pr
            INNER JOIN tblEntity e ON (
                pr.intEntityID = e.intEntityID 
            )
        WHERE     
            intPersonID = ?
            $where
        ORDER BY
          dtAdded DESC
    ];	
    my $db=$Data->{'db'};
    my $query = $db->prepare($st) or query_error($st);
    $query->execute(@values) or query_error($st);
    my $count=0;

    my @Registrations = ();
      
    while(my $dref= $query->fetchrow_hashref()) {
        $count++;
        push @Registrations, $dref;
    }
    return ($count, \@Registrations);
}

sub addRegistration {
    my($Data, $Reg_ref) = @_;

    my $status = $Reg_ref->{'status'} || 'PENDING';
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
            intPaymentRequired
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
            NOW(),
            NOW(),
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
  		$Reg_ref->{'status'} || '',  		
  		$Reg_ref->{'sport'},  		
  		$Reg_ref->{'current'} || 0,  		
  		$Reg_ref->{'originLevel'} || 0,  		
  		$Reg_ref->{'originID'} || 0,  		
  		$Reg_ref->{'dateFrom'},  		
  		$Reg_ref->{'dateTo'},  		
  		$Data->{'Realm'},
  		$Data->{'RealmSubType'} || 0,
  		$Reg_ref->{'nationalPeriodID'} || 0,
  		$Reg_ref->{'ageGroupID'} || 0,
  		$Reg_ref->{'ageLevel'} || '',
  		$Reg_ref->{'registrationNature'} || '',
  		$Reg_ref->{'paymentRequired'} || 0
  	);
	
	if ($q->errstr) {
		return (0, 0);
	}
  	my $personRegistrationID = $q->{mysql_insertid};
  	
    my $rc=0;
    if ($status eq 'PENDING')   {
  	    $rc = addWorkFlowTasks(
            $Data,
            'REGO', 
            $Reg_ref->{'registrationNature'}, 
            $Reg_ref->{'originLevel'} || 0, 
            $Reg_ref->{'entityID'} || 0,
            $Reg_ref->{'personID'},
            $personRegistrationID, 
            0
        );
    }
  	
 	return ($personRegistrationID, $rc) ;
}

sub submitPersonRegistration    {

    my ($Data, $personID, $personRegistrationID) = @_;

    my %Reg=();
    $Reg{'personRegistrationID'} = $personRegistrationID;
    my ($count, $regs) = getRegistrationData($Data, $personID, \%Reg);

    if ($count) {
        my $pr_ref = $regs->[0];
        $pr_ref->{'strStatus'} = 'PENDING';
print STDERR Dumper($pr_ref);

        updatePersonRegistration($Data, $personID, $personRegistrationID, $pr_ref);

  	    my $rc = addWorkFlowTasks(
            $Data,
            'REGO', 
            $pr_ref->{'strRegistrationNature'} || '', 
            $pr_ref->{'intOriginLevel'} || 0, 
            $pr_ref->{'intEntityID'} || 0,
            $personID,
            $personRegistrationID, 
            0
        );
    }
}



1;
