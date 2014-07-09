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
use TTTemplate;
use Log;
use Data::Dumper;

sub handleWorkflow {
    my ( 
    	$action, 
    	$Data,
    	$roleID,
    	$entityID,
    	$WFTaskID
    	 ) = @_;
 
	my $body = '';
	my $title = '';
   	my $st = '';
	my $q = '';
	my $db=$Data->{'db'};
	
    if (!$roleID) {
    	# A single person may have multiple roles at multiple organisations - get them to select which one they want to look at
    	# Perhaps do a LEFT OUTER JOIN to show a count of how many outstanding tasks for each role. Low probability of having multiple roles
    	$st = qq[
    		SELECT COUNT(*) as numRows
        	FROM tblUserAuth AS ua 
			INNER JOIN tblUserAuthRole AS uar on ua.userId = uar.userID AND ua.entityId = uar.entityID
			INNER JOIN tblUserRole AS ur on uar.roleId = ur.roleID
			WHERE ua.userID = ?;
	    ];
        
	    $q = $db->prepare($st);
	    $q->execute($Data->{'clientValues'}{'userID'});
	            
	    my $dref= $q->fetchrow_hashref();
	    my $numRows = $dref->{numRows};
   
	    if ($numRows == 0) {
	    	$body = qq[<p class="warningmsg">Your user ID is not authorised to manage registrations.</p>];
	    	return($body,"Registration Authorisation")
	    }
	    elsif ($numRows == 1) {
	    	$body = qq[<p class="warningmsg">Found 1 registration ID.</p>];
	    	return($body,"Registration Authorisation")	    	
	    }
	    else {
	    	$action = 'WF_ListRoles';
	    };
	}
      
    if ( $action eq 'WF_ListRoles' ) {
        ( $body, $title ) = listRoles( $Data );
    }
    elsif ( $action eq 'WF_Approve' ) {
        approveTask($Data, $WFTaskID);
        ( $body, $title ) = listTasks( $Data, $roleID, $entityID );	
    }
	else {
        ( $body, $title ) = listTasks( $Data, $roleID, $entityID );		
	};
   
    return ( $body, $title );
}

sub listTasks {
     my(
        $Data,
        $roleID, 
        $entityID,
    ) = @_;

	my $body = '';
   	my $st = '';
	my $q = '';
	my $db=$Data->{'db'};
	
    $st = qq[
		SELECT t.intWFTaskID, t.strTaskStatus, t.strTaskType, pr.strPersonLevel, pr.strAgeLevel, pr.strSport, 
			pr.intRegistrationNature, dt.strDocumentName,
			p.strLocalFirstname, p.strLocalSurname, p.intPersonID
		FROM tblWFTask t
		INNER JOIN tblPersonRegistration_1 pr ON t.intPersonRegistrationID = pr.intPersonRegistrationID
		INNER JOIN tblPerson p on t.intPersonID = p.intPersonID
		LEFT OUTER JOIN tblDocumentType dt ON t.intDocumentTypeID = dt.intDocumentTypeID
		WHERE t.intWFRoleID = ?
			AND t.intWFRoleEntityID = ?
			AND t.strTaskStatus = 'ACTIVE'		
		ORDER BY p.strLocalSurname, p.strLocalFirstname, p.intPersonID, t.strTaskType, dt.strDocumentName
    ];
	
	$db=$Data->{'db'};
	$q = $db->prepare($st) or query_error($st);
	$q->execute(
		$roleID,
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
		 	);
		push @TaskList, \%single_row;
	}
	
	#PP - Get language string
	my $msg = ''; 
	if ($rowCount == 0) {
		$msg = "No outstanding tasks";
	}
	else {
		$msg = "The following are the outstanding tasks to be authorised";
	};
	
	my %TemplateData = (
			TaskList => \@TaskList,
			TaskMsg => $msg,
			TaskEntityID => $entityID,
			TaskRoleID => $roleID,
			client => $Data->{client},
	);

	$body = runTemplate(
			$Data,
			\%TemplateData,
			'dashboards/persontasks.templ',
	);
	

	return($body,"Registration Authorisation"); #PP - Get language string 	
}

sub listRoles {
     my(
        $Data, 
    ) = @_;

	my $body = '';
	my $st = '';
	my $q = '';
	my $db=$Data->{'db'};
	
    $st = qq[
        SELECT ua.entityId, uar.roleId, ur.title, e.strLocalName
			FROM       tblUserAuth     AS ua
			INNER JOIN tblUserAuthRole AS uar on ua.userId   = uar.userID AND ua.entityId = uar.entityID
			INNER JOIN tblUserRole     AS ur  on uar.roleId  = ur.roleID
			INNER JOIN tblEntity       AS e   on ua.entityId = e.intEntityID
			WHERE ua.userID = ?
			ORDER BY ua.entityId;
    ];	
	
	$db=$Data->{'db'};
	$q = $db->prepare($st) or query_error($st);
	$q->execute($Data->{'clientValues'}{'userID'}) or query_error($st);
	
	my @RoleList = ();
	  
	while(my $dref= $q->fetchrow_hashref()) {
	
		my %single_role = (
			EntityID => $dref->{entityId},
			RoleID => $dref->{roleId},			
			RoleTitle => $dref->{title},
			EntityTitle => $dref->{strLocalName},
		 	);
		push @RoleList, \%single_role;
	}
	
	#PP - Get language string 
	my $msg = "Your User ID has multiple roles - please select which role you wish to view";
	
	my %TemplateData = (
			RoleList => \@RoleList,
			RoleMsg => $msg,
			client => $Data->{client},
	);

	$body = runTemplate(
			$Data,
			\%TemplateData,
			'dashboards/personrole.templ',
	);
		
	return($body,"Registration Authorisation"); #PP - Get language string 	

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
			intWFRoleEntityID, 
			strTaskType, 
			intDocumentTypeID, 
			strTaskStatus, 
			intPersonID, 
			intPersonRegistrationID, 
			intProblemResolutionEntityID, 
			intProblemResolutionRoleID
			)
		SELECT 
			r.intWFRuleID, 
			r.intRoleID, 
			r.intRoleEntityID, 
			r.strTaskType, 
			r.intDocumentTypeID, 
			r.strTaskStatus, 
			pr.intPersonID, 
			pr.intPersonRegistrationID, 
			r.intProblemResolutionEntityID, 
			r.intProblemResolutionRoleID
		FROM tblPersonRegistration_$Data->{'RealmID'} AS pr
		INNER JOIN tblWFRule AS r
			ON pr.intEntityID = r.intEntityID
			AND pr.strPersonLevel = r.strPersonLevel
			AND pr.strAgeLevel = r.strAgeLevel
			AND pr.strSport = r.strSport
			AND pr.intRegistrationNature = r.intRegistrationNature
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
	  		intApprovedPersonID = ?
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
		# Nothing to update. Do a check to see if all tasks have been completed
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
        	$rc = 1;	# All registration tasks have been completed
        }
	}      

return ($rc) # 1 = Registration is complete, 0 = There are still outstanding Tasks to be completed
       	
}

sub list_tasks {
    my(
        $db,
        $roleID,
        $entityID,
        $WFTaskID,
    ) = @_;
    
   	#Fudge to setup %Data
	my %clientValues = (userID => 5);
	my %Data = (
		db => $db,
		RealmID => 1,
		SubRealm => 0,
		clientValues => \%clientValues,
	 	);
    
    if ($WFTaskID) {
    	my $PersonRegistrationID = approveTask(\%Data, $WFTaskID);
    }
    
    my $st = qq[
        SELECT u.userId, u.firstName, u.familyName, ua.entityId, uar.roleId, ur.title, e.strLocalName
			FROM       tblUser         AS u
			INNER JOIN tblUserAuth     AS ua  on u.userId    = ua.userId
			INNER JOIN tblUserAuthRole AS uar on ua.userId   = uar.userID AND ua.entityId = uar.entityID
			INNER JOIN tblUserRole     AS ur  on uar.roleId  = ur.roleID
			INNER JOIN tblEntity       AS e   on ua.entityId = e.intEntityID
			WHERE u.userID = 5
			ORDER BY ua.entityId;
    ];
 
    my $query = $db->prepare($st);
    $query->execute();
    my $body = '';
    
    while(my $dref= $query->fetchrow_hashref()) {
	    $body .= qq[
	      <tr>
	        <td class="listborder">$dref->{roleId}</td>
	        <td class="listborder">$dref->{firstName} $dref->{familyName}</td>
	        <td>&nbsp;</td>
	        <td class="listborder">$dref->{title}</td>
	        <td class="listborder"><a href="approval.cgi?RID=$dref->{roleId}&EID=$dref->{entityId}">$dref->{title} / $dref->{strLocalName}</a></td>
	      </tr>
	    ];
    }

    $body = '<h1>Select your current Role</h1>'
    	. '<p><a href="registration.cgi">Register another player</a>'
    	. '<table cellpadding="5">'
	    . '<tr style="margin: 10px;"><th>RoleID</th><th>Name</th><th>&nbsp;</th><th>Role/Entity</th></tr>' 
	    . $body . 
	    '</table>';

    if (!$roleID) {
    	return($body);	
    }    

    $body .= '<h1>Approve any outstanding tasks</h1><table cellpadding="5">'
	    . '<tr style="margin: 10px;"><th>TaskID</th><th>Name</th><th>Status</th><th>TaskType</th><th>PersonLevel</th><th>AgeLevel</th><th>Sport</th><th>Registration<br>Type</th><th>Document</th><th>&nbsp;</th><th>Approve</th><th>Reject</th></tr>';

    $st = qq[
		SELECT t.intWFTaskID, t.strTaskStatus, t.strTaskType, pr.strPersonLevel, pr.strAgeLevel, pr.strSport, pr.intRegistrationNature, dt.strDocumentName,
			p.strLocalFirstname, p.strLocalSurname, p.intPersonID
		FROM tblWFTask t
		INNER JOIN tblPersonRegistration_1 pr ON t.intPersonRegistrationID = pr.intPersonRegistrationID
		INNER JOIN tblPerson p on t.intPersonID = p.intPersonID
		LEFT OUTER JOIN tblDocumentType dt ON t.intDocumentTypeID = dt.intDocumentTypeID
		WHERE t.intWFRoleID = ?
			AND t.intWFRoleEntityID = ?		
		ORDER BY p.strLocalSurname, p.strLocalFirstname, p.intPersonID, t.strTaskType, dt.strDocumentName
    ];

 
    $query = $db->prepare($st);
    $query->execute($roleID, $entityID);

    my $link = '';
    
    while(my $dref= $query->fetchrow_hashref()) {
	        if ($dref->{strTaskStatus} eq 'ACTIVE') {
        		$link = qq[<td class="listborder"><a href="approval.cgi?RID=$roleID&EID=$entityID&TID=$dref->{intWFTaskID}">Approve</a></td><td class="listborder">Reject</td>]
	        }
	        else {
        		$link = qq[<td class="listborder">&nbsp;</td><td class="listborder">&nbsp;</td>]
	        }
     	
	    $body .= qq[
	      <tr>
	        <td class="listborder">$dref->{intWFTaskID}</td>
	        <td class="listborder">$dref->{strLocalFirstname} $dref->{strLocalSurname}</td>
	        <td class="listborder">$dref->{strTaskStatus}</td>
	        <td class="listborder">$dref->{strTaskType}</td>
	        <td class="listborder">$dref->{strPersonLevel}</td>
	        <td class="listborder">$dref->{strAgeLevel}</td>
	        <td class="listborder">$dref->{istrSport}</td>
	        <td class="listborder">$dref->{intRegistrationNature}</td>
	        <td class="listborder">$dref->{strDocumentName}</td>
	        <td>&nbsp;</td>
	   		$link
	      </tr>
	    ];
    }
    
    return $body . '</table>';

    
}


sub list_tasksxx {
    my(
        $db,
        $roleID,
        $entityID,
        $WFTaskID,
    ) = @_;
    
   	#Fudge to setup %Data
	my %clientValues = (userID => 5);
	my %Data = (
		db => $db,
		RealmID => 1,
		SubRealm => 0,
		clientValues => \%clientValues,
	 	);
    
    if ($WFTaskID) {
    	my $PersonRegistrationID = approveTask(\%Data, $WFTaskID);
    }
    
    my $st = qq[
        SELECT u.userId, u.firstName, u.familyName, ua.entityId, uar.roleId, ur.title, e.strLocalName
			FROM       tblUser         AS u
			INNER JOIN tblUserAuth     AS ua  on u.userId    = ua.userId
			INNER JOIN tblUserAuthRole AS uar on ua.userId   = uar.userID AND ua.entityId = uar.entityID
			INNER JOIN tblUserRole     AS ur  on uar.roleId  = ur.roleID
			INNER JOIN tblEntity       AS e   on ua.entityId = e.intEntityID
			WHERE u.userID = 5
			ORDER BY ua.entityId;
    ];
 
    my $query = $db->prepare($st);
    $query->execute();
    my $body = '';
    
    while(my $dref= $query->fetchrow_hashref()) {
	    $body .= qq[
	      <tr>
	        <td class="listborder">$dref->{roleId}</td>
	        <td class="listborder">$dref->{firstName} $dref->{familyName}</td>
	        <td>&nbsp;</td>
	        <td class="listborder">$dref->{title}</td>
	        <td class="listborder"><a href="approval.cgi?RID=$dref->{roleId}&EID=$dref->{entityId}">$dref->{title} / $dref->{strLocalName}</a></td>
	      </tr>
	    ];
    }

    $body = '<h1>Select your current Role</h1>'
    	. '<p><a href="registration.cgi">Register another player</a>'
    	. '<table cellpadding="5">'
	    . '<tr style="margin: 10px;"><th>RoleID</th><th>Name</th><th>&nbsp;</th><th>Role/Entity</th></tr>' 
	    . $body . 
	    '</table>';

    if (!$roleID) {
    	return($body);	
    }    

    $body .= '<h1>Approve any outstanding tasks</h1><table cellpadding="5">'
	    . '<tr style="margin: 10px;"><th>TaskID</th><th>Name</th><th>Status</th><th>TaskType</th><th>PersonLevel</th><th>AgeLevel</th><th>Sport</th><th>Registration<br>Type</th><th>Document</th><th>&nbsp;</th><th>Approve</th><th>Reject</th></tr>';

    $st = qq[
		SELECT t.intWFTaskID, t.strTaskStatus, t.strTaskType, pr.strPersonLevel, pr.strAgeLevel, pr.strSport, pr.intRegistrationNature, dt.strDocumentName,
			p.strLocalFirstname, p.strLocalSurname, p.intPersonID
		FROM tblWFTask t
		INNER JOIN tblPersonRegistration_1 pr ON t.intPersonRegistrationID = pr.intPersonRegistrationID
		INNER JOIN tblPerson p on t.intPersonID = p.intPersonID
		LEFT OUTER JOIN tblDocumentType dt ON t.intDocumentTypeID = dt.intDocumentTypeID
		WHERE t.intWFRoleID = ?
			AND t.intWFRoleEntityID = ?		
		ORDER BY p.strLocalSurname, p.strLocalFirstname, p.intPersonID, t.strTaskType, dt.strDocumentName
    ];

 
    $query = $db->prepare($st);
    $query->execute($roleID, $entityID);

    my $link = '';
    
    while(my $dref= $query->fetchrow_hashref()) {
	        if ($dref->{strTaskStatus} eq 'ACTIVE') {
        		$link = qq[<td class="listborder"><a href="approval.cgi?RID=$roleID&EID=$entityID&TID=$dref->{intWFTaskID}">Approve</a></td><td class="listborder">Reject</td>]
	        }
	        else {
        		$link = qq[<td class="listborder">&nbsp;</td><td class="listborder">&nbsp;</td>]
	        }
     	
	    $body .= qq[
	      <tr>
	        <td class="listborder">$dref->{intWFTaskID}</td>
	        <td class="listborder">$dref->{strLocalFirstname} $dref->{strLocalSurname}</td>
	        <td class="listborder">$dref->{strTaskStatus}</td>
	        <td class="listborder">$dref->{strTaskType}</td>
	        <td class="listborder">$dref->{strPersonLevel}</td>
	        <td class="listborder">$dref->{strAgeLevel}</td>
	        <td class="listborder">$dref->{istrSport}</td>
	        <td class="listborder">$dref->{intRegistrationNature}</td>
	        <td class="listborder">$dref->{strDocumentName}</td>
	        <td>&nbsp;</td>
	   		$link
	      </tr>
	    ];
    }
    
    return $body . '</table>';

    
}




1;
