package WorkFlow;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = @EXPORT_OK = qw(
	handleWorkflow
  	addTasks
  	approveTask
  	checkForOutstandingTasks
);

use strict;
use Utils;
use Reg_common;
use TTTemplate;
use Log;
use Data::Dumper;

sub handleWorkflow {
    my ( 
    	$action, 
    	$Data
    	 ) = @_;
 
	my $body = '';
	my $title = '';
	
	if ( $action eq 'WF_Approve' ) {
        approveTask($Data);
        ( $body, $title ) = listTasks( $Data );	
    }
    elsif ( $action eq 'WF_Reject' ) {
        rejectTask($Data);
        ( $body, $title ) = listTasks( $Data );	
    }
	else {
        ( $body, $title ) = listTasks( $Data );		
	};
   
    return ( $body, $title );
}

sub listTasks {
     my(
        $Data,
    ) = @_;

	my $body = '';
   	my $st = '';
	my $q = '';
	my $db=$Data->{'db'};
	
	my $entityID = getID($Data->{'clientValues'},$Data->{'clientValues'}{'currentLevel'});
	
    $st = qq[
		SELECT t.intWFTaskID, t.strTaskStatus, t.strTaskType, pr.strPersonLevel, pr.strAgeLevel, pr.strSport, 
			pr.strRegistrationNature, dt.strDocumentName,
			p.strLocalFirstname, p.strLocalSurname, p.intPersonID
		FROM tblWFTask AS t
		INNER JOIN tblPersonRegistration_$Data->{'Realm'} AS pr ON t.intPersonRegistrationID = pr.intPersonRegistrationID
		INNER JOIN tblPerson AS p on t.intPersonID = p.intPersonID
		INNER JOIN tblUserAuthRole AS uar ON t.intApprovalEntityID = uar.entityID AND t.intApprovalRoleID = uar.roleId
		LEFT OUTER JOIN tblDocumentType AS dt ON t.intDocumentTypeID = dt.intDocumentTypeID
		WHERE uar.userID = ?
			AND uar.entityID = ?
			AND t.strTaskStatus = 'ACTIVE'
		UNION
		SELECT t.intWFTaskID, t.strTaskStatus, t.strTaskType, pr.strPersonLevel, pr.strAgeLevel, pr.strSport, 
			pr.strRegistrationNature, dt.strDocumentName,
			p.strLocalFirstname, p.strLocalSurname, p.intPersonID
		FROM tblWFTask AS t
		INNER JOIN tblPersonRegistration_$Data->{'Realm'} AS pr ON t.intPersonRegistrationID = pr.intPersonRegistrationID
		INNER JOIN tblPerson AS p on t.intPersonID = p.intPersonID
		INNER JOIN tblUserAuthRole AS uar ON t.intProblemResolutionEntityID = uar.entityID 
			AND t.intProblemResolutionRoleID = uar.roleId
		LEFT OUTER JOIN tblDocumentType AS dt ON t.intDocumentTypeID = dt.intDocumentTypeID
		WHERE uar.userID = ?
			AND uar.entityID = ?
			AND t.strTaskStatus = 'REJECTED'	
    ];

#PP		ORDER BY p.strLocalSurname, p.strLocalFirstname, p.intPersonID, t.strTaskType, dt.strDocumentName

	
	$db=$Data->{'db'};
	$q = $db->prepare($st) or query_error($st);
	$q->execute(
		$Data->{'clientValues'}{'userID'},
		$entityID,
		$Data->{'clientValues'}{'userID'},
		$entityID,
	) or query_error($st);
	
	my @TaskList = ();
	my $rowCount = 0;
	  
	while(my $dref= $q->fetchrow_hashref()) {
		$rowCount ++;
		my %single_row = (
			WFTaskID => $dref->{intWFTaskID},
			TaskType => $dref->{strTaskType},
			AgeLevel => $dref->{strAgeLevel},
			RegistrationNature => $dref->{intRegistrationNature},
			DocumentName => $dref->{strDocumentName},
			LocalFirstname => $dref->{strLocalFirstname},
			LocalSurname => $dref->{strLocalSurname},
			PersonID => $dref->{intPersonID},			
			TaskStatus => $dref->{strTaskStatus},
		);
		push @TaskList, \%single_row;
	}
	
	my $msg = ''; 
	if ($rowCount == 0) {
		$msg = $Data->{'lang'}->txt('No outstanding tasks');
	}
	else {
		$msg = $Data->{'lang'}->txt('The following are the outstanding tasks to be authorised');
	};
	
	my %TemplateData = (
			TaskList => \@TaskList,
			TaskMsg => $msg,
			TaskEntityID => $entityID,
			client => $Data->{client},
	);

	$body = runTemplate(
			$Data,
			\%TemplateData,
			'dashboards/persontasks.templ',
	);
	

	return($body,$Data->{'lang'}->txt('Registration Authorisation')); 	
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
			intRealmID,
			intSubRealmID, 
			intApprovalEntityID,
			intApprovalRoleID, 
			strTaskType, 
			intDocumentTypeID, 
			strTaskStatus, 
			intProblemResolutionEntityID, 
			intProblemResolutionRoleID,
			intPersonID, 
			intPersonRegistrationID 
		)
		SELECT 
			r.intWFRuleID, 
			r.intRealmID,
			r.intSubRealmID,
			r.intApprovalEntityID,
			r.intApprovalRoleID, 
			r.strTaskType, 
			r.intDocumentTypeID, 
			r.strTaskStatus, 
			r.intProblemResolutionEntityID, 
			r.intProblemResolutionRoleID,
			pr.intPersonID, 
			pr.intPersonRegistrationID 
		FROM tblPersonRegistration_$Data->{'Realm'} AS pr
		INNER JOIN tblWFRule AS r
			ON pr.intRealmID = r.intRealmID
			AND pr.intSubRealmID = r.intSubRealmID
			AND pr.strPersonLevel = r.strPersonLevel
			AND pr.strAgeLevel = r.strAgeLevel
			AND pr.strSport = r.strSport
			AND pr.strRegistrationNature = r.strRegistrationNature
		WHERE pr.intPersonRegistrationID = ?
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
		WHERE t.intPersonRegistrationID = ?
		];

  	$q = $db->prepare($st);
  	$q->execute($personRegistrationID);
	
	if ($q->errstr) {
		return $q->errstr . '<br>' . $st;
	}

	my $rc = checkForOutstandingTasks($Data,$personRegistrationID);

	return($rc); 
}

sub approveTask {
    my(
        $Data,
    ) = @_;
	
	my $st = '';
	my $q = '';
	my $db=$Data->{'db'};

	#Get values from the QS
    my $WFTaskID = safe_param('TID','number') || '';
	
	#Update this task to COMPLETE
	$st = qq[
	  	UPDATE tblWFTask SET 
	  		strTaskStatus = 'COMPLETE',
	  		dtApprovalDate = Now(),
	  		intApprovalUserID = ?
	  	WHERE intWFTaskID = ?; 
		];
		
  	$q = $db->prepare($st);
  	$q->execute(
	  	$Data->{'clientValues'}{'userID'},
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
    my $personRegistrationID = $dref->{intPersonRegistrationID};
    
   	my $rc = checkForOutstandingTasks($Data,$personRegistrationID);
    
    return($rc);
    
}

sub checkForOutstandingTasks {
    my(
        $Data,
        $PersonRegistrationID,
    ) = @_;

	my $st = '';
	my $q = '';
	my $db=$Data->{'db'};
		
	#As a result of an update, check to see if there are any Tasks that now have all their pre-reqs completed
	# or if all tasks have been completed
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
		  		dtActivateDate = Now(),
		  		intActiveUserID = 1
		  	WHERE intWFTaskID IN ($list_WFTaskID); 
			];
			
	  	$q = $db->prepare($st);
	  	$q->execute();
	  		
		if ($q->errstr) {
			return $q->errstr . '<br>' . $st
		}
		    
	} 
	else {	
		# Nothing to update. Do a check to see if all tasks have been completed
		$st = qq[
            SELECT count(*) as NumRows
            FROM tblWFTask
            WHERE intPersonRegistrationID = ?
			AND strTaskStatus IN ('PENDING','ACTIVE')
        ];
        
        $q = $db->prepare($st);
        $q->execute(
       		$PersonRegistrationID,
	  		'PENDING',
	  		'ACTIVE'
	  	);
  
        
        if (!$q->fetchrow_array()) {
        	#Now check to see if there is a payment outstanding
        	$st = qq[
			        SELECT intPaymentRequired
			        FROM tblPersonRegistration_$Data->{'Realm'} 
			        WHERE intPersonRegistrationID = ?
			];
			        
			$q = $db->prepare($st);
			$q->execute($PersonRegistrationID);
			            
			my $dref= $q->fetchrow_hashref();
			my $intPaymentRequired = $dref->{intPaymentRequired};
			  	
        	if (!$intPaymentRequired) {
        		#Nothing outstanding, so mark this registration as complete
	            $st = qq[
	            	UPDATE tblPersonRegistration_$Data->{'Realm'} SET
	            	strStatus = 'ACTIVE',
	            	dtFrom = Now()
	    	        WHERE intPersonRegistrationID = ?
	        	];
	    
		        $q = $db->prepare($st);
		        $q->execute(
		       		$PersonRegistrationID
		  			);         
	        	$rc = 1;	# All registration tasks have been completed        		
        	}
        }
	}      

return ($rc) # 1 = Registration is complete, 0 = There are still outstanding Tasks to be completed
       	
}

sub rejectTask {
    my(
        $Data,
    ) = @_;
	
	my $st = '';
	my $q = '';
	my $db=$Data->{'db'};

	#Get values from the QS
    my $WFTaskID = safe_param('TID','number') || '';
	
	#Update this task to REJECTED
	$st = qq[
	  	UPDATE tblWFTask SET 
	  		strTaskStatus = 'REJECTED',
	  		dtRejectedDate = Now(),
	  		intRejectedUserID = ?
	  	WHERE intWFTaskID = ?; 
		];
		
  	$q = $db->prepare($st);
  	$q->execute(
	  	$Data->{'clientValues'}{'userID'},
  		$WFTaskID,
  		);
  		
	if ($q->errstr) {
		return $q->errstr . '<br>' . $st
	}
	
    return(0);
    
}
1;
