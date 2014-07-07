package PersonRegistration;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = @EXPORT_OK = qw(
  getRegistrationData
  addRegistration
  addTasks
  approveTask
  checkForOutstandingTasks
);

use strict;
use Log;
use Data::Dumper;

sub getRegistrationData	{
	my (
		$Data, 
		$personID, 
		$templateData_ref
	)=@_;
	
my $statement = qq[
    SELECT pr.*, e.strLocalName 
    FROM
      tblPersonRegistration_$Data->{'Realm'} AS pr
      INNER JOIN tblEntity e ON pr.intEntityID = e.intEntityID 
      WHERE intPersonID = ?
    ORDER BY
      dtAdded DESC
  ];	

my $db=$Data->{'db'};
my $query = $db->prepare($statement) or query_error($statement);
$query->execute($personID) or query_error($statement);

my @Registration = ();
  
while(my $dref= $query->fetchrow_hashref()) {

	my %single_registration = (
		intEntityID => $dref->{intEntityID},
		strLocalName => $dref->{strLocalName},
		strSubTypeName => $dref->{strSubTypeName},
		strPersonLevel => $dref->{strPersonLevel},
		strPersonType => $dref->{strPersonType},
		strSport => $dref->{strSport},
		dtAdded  => $dref->{dtAdded},
		dtFrom  => $dref->{dtFrom},
		dtTo  => $dref->{dtTo},
	 	);
	push @Registration, \%single_registration;
  }
	
$templateData_ref->{'RegistrationInfo'} = \@Registration;	
	
}

sub addRegistration {
    my(
        $Data,
        $Reg_ref,
    ) = @_;

  	my $st = '';
	my $q = '';
	my $db=$Data->{'db'};
	
	$st = qq[
   		INSERT INTO tblPersonRegistration_$Data->{'RealmID'}
		(
		intPersonID,
		intRealmID,
		intSubRealmID,
		intEntityID,
		strPersonType,
		strPersonLevel,
		strStatus,
		strSport,
		intRegistrationNature,
		strAgeLevel
		)
		VALUES
		(?,
		?,
		?,
		?,
		?,
		?,
		?,
		?,
		?,
		?)
		];

  	$q = $db->prepare($st);
  	$q->execute(
  		$Reg_ref->{'personID'},,
  		$Data->{'Realm'},
  		$Data->{'SubRealm'},
  		$Reg_ref->{'entityID'},
  		$Reg_ref->{'personType'},  		
  		$Reg_ref->{'personLevel'},  		
  		'PENDING',
  		$Reg_ref->{'sport'},  		
  		$Reg_ref->{'registrationNature'},
  		$Reg_ref->{'ageLevel'},
  		);
	
	if ($q->errstr) {
		return $q->errstr . '<br>' . $st
	}
  	my $personRegistrationID = $q->{mysql_insertid};

 	return $personRegistrationID ;

}

sub addTasks {
     my(
        $Data,
        $personRegistrationID,
    ) = @_;
 
   	my $st = '';
	my $q = '';
	my $db=$Data->{'db'};
	
	$st = qq[
		INSERT INTO tblWFTask (
			intWFRuleID, 
			intWFRoleID, 
			intWFEntityID, 
			strTaskType, 
			intDocumentTypeID, 
			strTaskStatus, 
			intPersonID, 
			intPersonRegistrationID, 
			intEntityID, 
			intEntityLinksID
			)
		SELECT 
			r.intWFRuleID, 
			r.intRoleID, 
			r.intEntityID, 
			r.strTaskType, 
			r.intDocumentTypeID, 
			r.strTaskStatus, 
			pr.intPersonID, 
			pr.intPersonRegistrationID, 
			0, 
			0
		FROM tblPersonRegistration_$Data->{'RealmID'} AS pr
		INNER JOIN tblWFRule AS r
			ON pr.intEntityID = r.intEntityID
			AND pr.strPersonLevel = r.strPersonLevel
			AND pr.strAgeLevel = r.strAgeLevel
			AND pr.strSport = r.strSport
			AND pr.intRegistrationNature = r.intRegistrationNature
		WHERE pr.intPersonRegistrationID = ?;
		];
		
	$q = $db->prepare($st);
  	$q->execute($personRegistrationID);
	
	if ($q->errstr) {
		return $q->errstr . '<br>' . $st
	}			
	$st = qq[
		INSERT INTO tblWFTaskPreReq (
			intWFTaskID, 
			intWFRuleID, 
			intPreReqWFRuleID
		)
		SELECT 
			t.intWFTaskID, 	
			t.intWFRuleID, 
			rpr.intPreReqWFRuleID 
		FROM tblWFTask AS t
		INNER JOIN tblWFRulePreReq AS rpr 
			ON t.intWFRuleID = rpr.intWFRuleID
		WHERE t.intPersonRegistrationID = ?;
		];

  	$q = $db->prepare($st);
  	$q->execute($personRegistrationID);
	
	if ($q->errstr) {
		return $q->errstr . '<br>' . $st;
	}

	checkForOutstandingTasks($Data,$personRegistrationID);

	return(0); 
}

sub checkForOutstandingTasks {
    my(
        $Data,
        $PersonRegistrationID,
    ) = @_;

	my $st = '';
	my $q = '';
	my $db=$Data->{'db'};
		
	#As a result of this update, check to see if there are any Tasks that now have all their pre-reqs completed
	$st = qq[	
		SELECT DISTINCT 
			pt.intWFTaskID, ct.strTaskStatus 
		FROM tblWFTask pt
		INNER JOIN tblWFTaskPreReq ptpr ON pt.intWFTaskID = ptpr.intWFTaskID
		INNER JOIN tblWFTask ct on ptpr.intPreReqWFRuleID = ct.intWFRuleID 
		WHERE pt.intPersonRegistrationID = ? 
			AND pt.strTaskStatus = ?
			AND ct.intPersonRegistrationID = ?
			AND ct.strTaskStatus IN (?,?)
		ORDER by pt.intWFTaskID;
	];
	
	$q = $db->prepare($st);
  	$q->execute(
  		$PersonRegistrationID,
  		'PENDING',
  		$PersonRegistrationID,
  		'ACTIVE',
  		'COMPLETE',
  		);
  		
	if ($q->errstr) {
		return $q->errstr . '<br>' . $st
	}

	my $prev_WFTaskID = 0;
   	my $updateThisTask = '';
   	my $pfx = '';
   	my $list_WFTaskID = '';
   	my $update_count = 0;
   	my $count = 0;
   		
   	#Should be a cleverer way to do this, but check all the Pending Tasks and see if all of their
   	# pre-reqs have been completed. If so, update their status from Pending to Active.
	while(my $dref= $q->fetchrow_hashref()) {
		$count ++;
	
   		if ($dref->{intWFTaskID} != $prev_WFTaskID) {
   			if ($prev_WFTaskID != 0) {
   				if ($updateThisTask eq 'YES') {
   					$list_WFTaskID .= $pfx . $prev_WFTaskID;
   					$pfx = ",";
					$update_count ++;
			   			}
   			}
   			$updateThisTask = 'YES';
   			$prev_WFTaskID = $dref->{intWFTaskID};
   		}
   		
   		if ($dref->{strTaskStatus} eq 'ACTIVE') {
   			$updateThisTask = "nope";
   		}
    }
    
   	if ($prev_WFTaskID != 0) {
   		if ($updateThisTask eq 'YES') {
   			$list_WFTaskID .= $pfx . $prev_WFTaskID;
			$update_count ++;
		}
   	}
	
	my $rc = 0;
	 
	if ($update_count > 0) {
		#Update the Tasks to Active as their pre-reqs have been completed
		$st = qq[
		  	UPDATE tblWFTask SET 
		  		strTaskStatus = 'ACTIVE',
		  		dtActiveDate = Now(),
		  		intActivePersonID = 1
		  	WHERE intWFTaskID IN ($list_WFTaskID); 
			];
			
	  	$q = $db->prepare($st);
	  	$q->execute();
	  		
		if ($q->errstr) {
			return $q->errstr . '<br>' . $st
		}
		    
	} 
	else {	
		# Nothing to update. Do a check to see if there all tasks have been completed
		$st = qq[
            SELECT count(*) as NumRows
            FROM tblWFTask
            WHERE intPersonRegistrationID = ?
			AND strTaskStatus IN (?,?)
        ];
        
        $q = $db->prepare($st);
        $q->execute(
       		$PersonRegistrationID,
	  		'PENDING',
	  		'ACTIVE'
	  	);
  
        
        if (!$q->fetchrow_array()) {
        	$rc = 1;	# Signifies that all registration tasks have been completed
            $st = qq[
            	UPDATE tblPersonRegistration_$Data->{'RealmID'} SET
            	strStatus = ?,
            	dtFrom = Now()
    	        WHERE intPersonRegistrationID = ?
        	];
    
	        $q = $db->prepare($st);
	        $q->execute(
	        	'ACTIVE',
	       		$PersonRegistrationID
	  			);         
        }
	}      

return ($rc) 
       	
}

sub approveTask {
    my(
        $Data,
        $WFTaskID,
    ) = @_;
	
	#Q - Add in the PersonID of whoever is logged on
	my $st = '';
	my $q = '';
	my $db=$Data->{'db'};
	
	#Update this task to COMPLETE
	$st = qq[
	  	UPDATE tblWFTask SET 
	  		strTaskStatus = 'COMPLETE',
	  		dtApprovedDate = Now(),
	  		intApprovedPersonID = 1
	  	WHERE intWFTaskID = ?; 
		];
		
  	$q = $db->prepare($st);
  	$q->execute(
  		$WFTaskID,
  		);
  		
	if ($q->errstr) {
		return $q->errstr . '<br>' . $st
	}
	
    $st = qq[
        SELECT intPersonRegistrationID
        FROM tblWFTask
        WHERE intWFTaskID = ?
    ];
        
    $q = $db->prepare($st);
    $q->execute($WFTaskID);
            
    my $dref= $q->fetchrow_hashref();
    my $PersonRegistrationID = $dref->{intPersonRegistrationID};
    
    return($PersonRegistrationID);
    
}
1;
