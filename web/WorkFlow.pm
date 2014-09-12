package WorkFlow;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = @EXPORT_OK = qw(
	handleWorkflow
  	addWorkFlowTasks
  	approveTask
  	checkForOutstandingTasks
    addIndividualTask
    cleanTasks
);

use strict;
use lib '.', '..', 'Clearances'; #"comp", 'RegoForm', "dashboard", "RegoFormBuilder",'PaymentSplit', "user";
use Utils;
use Reg_common;
use TTTemplate;
use Log;
use PersonUtils;
use Clearances;
use Duplicates;
use PersonRegistration;
use CGI qw(param unescape escape);

sub cleanTasks  {

    my ($Data, $personID, $entityID, $personRegistrationID, $ruleFor) = @_;
    return if (!$personID and !$entityID and !$personRegistrationID);

    my $st = qq[
        DELETE tblWFTaskPreReq.* 
        FROM 
            tblWFTaskPreReq 
            INNER JOIN tblWFTask USING (intWFTaskID) 
        WHERE 
            intPersonID = ?
            AND intEntityID = ?
            AND intPersonRegistrationID=?
            AND strWFRuleFor = ?
    ];

    my $q= $Data->{'db'}->prepare($st);
    $q->execute($personID, $entityID, $personRegistrationID, $ruleFor);
    
    $st = qq[
        DELETE 
        FROM 
            tblWFTask
        WHERE 
            intPersonID = ?
            AND intEntityID = ?
            AND intPersonRegistrationID=?
            AND strWFRuleFor = ?
    ];
    $q= $Data->{'db'}->prepare($st);
    $q->execute($personID, $entityID, $personRegistrationID, $ruleFor);
}

sub addIndividualTask   {

    my ($Data, $ruleID, $taskType, $ruleFor, $task_ref) = @_;

     my $stINS = qq[
        INSERT IGNORE INTO tblWFTask (
            intWFRuleID,
            intRealmID,
            intSubRealmID,
            intCreatedByUserID,
            intApprovalEntityID,
            strTaskType,
            strWFRuleFor,
            strRegistrationNature,
            intDocumentTypeID,
            strTaskStatus,
            intProblemResolutionEntityID,
            intEntityID,
            intPersonID,
            intPersonRegistrationID,
            intDocumentID
        )
        VALUES (
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
            ?
        )
    ];
    my $approvalEntityID = getEntityParentID($Data, $task_ref->{'entityID'}, $task_ref->{'approvalLevel'} || $Defs::LEVEL_NATIONAL) || 0;
    my $problemEntityID = $task_ref->{'problemEntityID'} || $task_ref->{'entityID'} || 0;
    my $q= $Data->{'db'}->prepare($stINS);
    $q->execute(
        $ruleID || 0,
        $Data->{'Realm'},
        $Data->{'RealmSubType'},
        $Data->{'clientValues'}{'userID'},
        $approvalEntityID,
        $taskType,
        $ruleFor,
        $task_ref->{'registrationNature'} || '',
        $task_ref->{'documentTypeID'} || 0,
        $task_ref->{'taskStatus'} || 'ACTIVE',
        $problemEntityID,
        $task_ref->{'entityID'} || 0,
        $task_ref->{'personID'} || 0,
        $task_ref->{'personRegistrationID'} || 0,
        $task_ref->{'documentID'} || 0,
    );
}
        
        
    


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
    elsif ( $action eq 'WF_notesS' ) {
        ( $body, $title ) = updateTaskNotes( $Data );	
    }
    elsif ( $action eq 'WF_Resolve' ) {
        resolveTask($Data);
        ( $body, $title ) = addTaskNotes( $Data );	
    }
    elsif ( $action eq 'WF_Reject' ) {
        rejectTask($Data);
        ( $body, $title ) = addTaskNotes( $Data );	
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
		SELECT 
            t.intWFTaskID, 
            t.strTaskStatus, 
            t.strTaskType, 
            pr.strPersonLevel, 
            pr.strAgeLevel, 
            pr.strSport, 
			t.strRegistrationNature, 
            dt.strDocumentName,
			p.strLocalFirstname, 
            p.strLocalSurname, 
            p.intGender as PersonGender,
            e.strLocalName as EntityLocalName,
            p.intPersonID, 
            t.strTaskStatus, 
            t.strWFRuleFor,
            uar.entityID as UserEntityID, 
            uarRejected.entityID as UserRejectedEntityID,
            e.intEntityID,
            e.intEntityLevel,
            t.intApprovalEntityID,
            t.intProblemResolutionEntityID,
            t.strTaskNotes as TaskNotes
		FROM tblWFTask AS t
        LEFT JOIN tblEntity as e ON (e.intEntityID = t.intEntityID)
		LEFT JOIN tblPersonRegistration_$Data->{'Realm'} AS pr ON (t.intPersonRegistrationID = pr.intPersonRegistrationID)
		LEFT JOIN tblPerson AS p ON (t.intPersonID = p.intPersonID)
		LEFT JOIN tblUserAuthRole AS uar ON ( t.intApprovalEntityID = uar.entityID )
		LEFT OUTER JOIN tblDocumentType AS dt ON (t.intDocumentTypeID = dt.intDocumentTypeID)
		LEFT JOIN tblUserAuthRole AS uarRejected ON ( t.intProblemResolutionEntityID = uarRejected.entityID )
		WHERE 
            t.intRealmID = $Data->{'Realm'}
			AND (
                (intApprovalEntityID = ? AND t.strTaskStatus = 'ACTIVE')
                OR
                (intProblemResolutionEntityID= ? AND t.strTaskStatus = 'REJECTED')
            )
    ];

        #my $userID = $Data->{'clientValues'}{'userID'}
        ## if ($userID)
        ## $st .= qqp AND t.intCreatedByUserID <> $userID ];

            #uar.userID as UserID, 
            #uarRejected.userID as RejectedUserID, 
            #AND t.intApprovalRoleID = uar.roleId
			#AND t.intProblemResolutionRoleID = uarRejected.roleId
            #AND
            #(
            #    uar.userID = ? 
            #    OR uarRejected.userID = ?
            #)
		#$Data->{'clientValues'}{'userID'},
		#$Data->{'clientValues'}{'userID'},

	$db=$Data->{'db'};
	$q = $db->prepare($st) or query_error($st);
	$q->execute(
		$entityID,
		$entityID,
	) or query_error($st);
	
	my @TaskList = ();
	my $rowCount = 0;
	  
    my $client = unescape($Data->{client});
	while(my $dref= $q->fetchrow_hashref()) {
        my %tempClientValues = getClient($client);
		$rowCount ++;
        my $name = '';
        $name = $dref->{'EntityLocalName'} if ($dref->{strWFRuleFor} eq 'ENTITY');
        $name = formatPersonName($Data, $dref->{'strLocalFirstname'}, $dref->{'strLocalSurname'}, $dref->{'PersonGender'}) if ($dref->{strWFRuleFor} eq 'REGO' or $dref->{strWFRuleFor} eq 'PERSON');
        my $home = '';
        if ($dref->{'intEntityID'}) {
            $tempClientValues{currentLevel} = $dref->{'intEntityLevel'};
            my $level = 'clubID';
            $level = 'regionID' if ($dref->{'intEntityLevel'} == $Defs::LEVEL_REGION);
            $level = 'zoneID' if ($dref->{'intEntityLevel'} == $Defs::LEVEL_ZONE);
            $level = 'stateID' if ($dref->{'intEntityLevel'} == $Defs::LEVEL_STATE);
            $level = 'natID' if ($dref->{'intEntityLevel'} == $Defs::LEVEL_NATIONAL);
            $home = 'E_HOME';
            $tempClientValues{$level} = $dref->{intEntityID};
        }
        if ($dref->{'intPersonID'}) {
            $tempClientValues{currentLevel} = $Defs::LEVEL_PERSON;
            $tempClientValues{personID} = $dref->{intPersonID};
            $home = 'P_HOME';
        }
        my $tempClient= setClient(\%tempClientValues);
        my $viewURL = "$Data->{'target'}?client=$tempClient&amp;a=$home";
        
        my $taskDescription = $Data->{'lang'}->txt('Please review this record');
        if ($dref->{'strTaskType'} eq $Defs::WF_TASK_TYPE_CHECKDUPL)    {
            $taskDescription =$Data->{'lang'}->txt('This person has been duplicate resolved and appears to have an incorrect Registration count');
        }    

        my $showReject=0;
        $showReject = 1 if ($dref->{'intProblemResolutionEntityID'} and $dref->{'intProblemResolutionEntityID'} != $entityID);

        my $showApprove=0;
        $showApprove= 1 if ($dref->{'intApprovalEntityID'} and $dref->{'intApprovalEntityID'} == $entityID);

        my $showResolve=0;
        $showResolve= 1 if ($dref->{'strTaskStatus'} eq $Defs::WF_TASK_STATUS_REJECTED and $dref->{'intProblemResolutionEntityID'} and $dref->{'intProblemResolutionEntityID'} == $entityID);

		my %single_row = (
			WFTaskID => $dref->{intWFTaskID},
            TaskDescription => $taskDescription,
			TaskType => $dref->{strTaskType},
			TaskNotes=> $dref->{TaskNotes},
			AgeLevel => $dref->{strAgeLevel},
			RuleFor=> $dref->{strWFRuleFor},
			RegistrationNature => $dref->{strRegistrationNature},
			DocumentName => $dref->{strDocumentName},
            Name=>$name,
			LocalEntityName=> $dref->{EntityLocalName},
			LocalFirstname => $dref->{strLocalFirstname},
			LocalSurname => $dref->{strLocalSurname},
			PersonID => $dref->{intPersonID},			
			TaskStatus => $dref->{strTaskStatus},
            viewURL => $viewURL,
            showReject => $showReject,
            showApprove => $showApprove,
            showResolve => $showResolve,
		);
		push @TaskList, \%single_row;
	}

    ## Calc Dupl Res and Pending Clr here
    my $clrCount = getClrTaskCount($Data, $entityID);
    my $dupCount = Duplicates::getDupTaskCount($Data, $entityID);
    if ($clrCount)   {
        my %row=(
            TaskType => 'TRANSFERS',
            TaskDescription=> $Data->{'lang'}->txt('You have Transfers to view'),
        );
		push @TaskList, \%row;
    }
    if ($dupCount)   {
        my %row=(
            TaskType => 'DUPLICATES',
            TaskDescription=> $Data->{'lang'}->txt('You have Duplicates to resolve'),
        );
		push @TaskList, \%row;
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
			'dashboards/worktasks.templ',
	);
	

	return($body,$Data->{'lang'}->txt('Registration Authorisation')); 	
}

sub getEntityParentID   {

    my ($Data, $fromEntityID, $getEntityLevel) = @_;

    my $st = qq[
        SELECT      
            intEntityLevel
        FROM
            tblEntity
        WHERE
            intEntityID = ?
    ];
	my $q = $Data->{'db'}->prepare($st);
  	$q->execute($fromEntityID);
    my $entityLevel = $q->fetchrow_array() || 0;
    return $fromEntityID if ($getEntityLevel == $entityLevel);

    $st = qq[
        SELECT 
            intParentID
		FROM 
            tblTempEntityStructure as T
		WHERE
            intChildID = ?
            AND intParentLevel = ?
        ORDER BY intPrimary DESC
        LIMIT 1            
    ];
            #AND intPrimary=1

	$q = $Data->{'db'}->prepare($st);
  	$q->execute($fromEntityID, $getEntityLevel);
        
    return  $q->fetchrow_array() || 0;
    
}
sub addWorkFlowTasks {
     my(
        $Data,
        $ruleFor,
        $regNature,
        $originLevel,
        $entityID,
        $personID,
        $personRegistrationID,
        $documentID
    ) = @_;
 
    $entityID ||= 0;
    $personID ||= 0;
    $originLevel ||= 0;
    $personRegistrationID ||= 0;
    $documentID ||= 0;

	my $q = '';
	my $db=$Data->{'db'};
	
	my $stINS = qq[
		INSERT IGNORE INTO tblWFTask (
			intWFRuleID,
			intRealmID,
			intSubRealmID, 
            intCreatedByUserID,
			intApprovalEntityID,
			strTaskType, 
            strWFRuleFor,
            strRegistrationNature,
			intDocumentTypeID, 
			strTaskStatus, 
			intProblemResolutionEntityID, 
            intEntityID,
			intPersonID, 
			intPersonRegistrationID,
            intDocumentID
		)
        VALUES (
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
            ?
        )
    ];
	my $qINS = $db->prepare($stINS);
            
    my $st = '';
    ## Build up SELECT based on what sort of record we are approving
    if ($ruleFor eq 'PERSON' and $personID)   {
        ## APPROVAL FOR PERSON REGO
        $st = qq[
		SELECT 
			r.intWFRuleID, 
			r.intRealmID,
			r.intSubRealmID,
			r.intApprovalEntityLevel,
			r.strTaskType, 
            r.strWFRuleFor,
			r.intDocumentTypeID, 
			r.strTaskStatus, 
			r.intProblemResolutionEntityLevel, 
			p.intPersonID, 
			0 as intPersonRegistrationID,
            0 as RegoEntity,
            0 as DocumentID
		FROM tblPerson as p
		INNER JOIN tblWFRule AS r ON (
			p.intRealmID = r.intRealmID
        )
		WHERE 
            p.intPersonID= ?
            AND r.strWFRuleFor = 'PERSON'
            AND r.intRealmID = ?
            AND r.intSubRealmID IN (0, ?)
            AND r.intOriginLevel = ?
			AND r.strRegistrationNature = ?
		];
	    $q = $db->prepare($st);
  	    $q->execute($personID, $Data->{'Realm'}, $Data->{'RealmSubType'}, $originLevel, $regNature);
    }
 
    if ($ruleFor eq 'REGO' and $personRegistrationID)   {
        ## APPROVAL FOR PERSON REGO
        $st = qq[
		SELECT 
			r.intWFRuleID, 
			r.intRealmID,
			r.intSubRealmID,
			r.intApprovalEntityLevel,
			r.strTaskType, 
            r.strWFRuleFor,
			r.intDocumentTypeID, 
			r.strTaskStatus, 
			r.intProblemResolutionEntityLevel, 
			pr.intPersonID, 
			pr.intPersonRegistrationID,
            pr.intEntityID as RegoEntity,
            0 as DocumentID
		FROM tblPersonRegistration_$Data->{'Realm'} AS pr
        INNER JOIN tblPerson as p ON (p.intPersonID = pr.intPersonID)
        INNER JOIN tblEntity as e ON (e.intEntityID = pr.intEntityID)
		INNER JOIN tblWFRule AS r ON (
			pr.intRealmID = r.intRealmID
			AND pr.intSubRealmID = r.intSubRealmID
			AND pr.strPersonLevel = r.strPersonLevel
			AND pr.strAgeLevel = r.strAgeLevel
			AND pr.strSport = r.strSport
            AND pr.strPersonType = r.strPersonType
            AND r.intEntityLevel = e.intEntityLevel
            AND (r.strISOCountry_IN = '' OR r.strISOCountry_IN LIKE CONCAT('%|',p.strISONationality ,'|%'))
            AND (r.strISOCountry_NOTIN = '' OR r.strISOCountry_NOTIN NOT LIKE CONCAT('%|',p.strISONationality ,'|%'))
        )
		WHERE 
            pr.intPersonRegistrationID = ?
            AND r.strWFRuleFor = 'REGO'
            AND r.intRealmID = ?
            AND r.intSubRealmID IN (0, ?)
            AND r.intOriginLevel = ?
            AND r.strEntityType IN ('', e.strEntityType)
			AND r.strRegistrationNature = ?
            AND r.strPersonEntityRole IN ('', pr.strPersonEntityRole)
		];
	    $q = $db->prepare($st);
  	    $q->execute($personRegistrationID, $Data->{'Realm'}, $Data->{'RealmSubType'}, $originLevel, $regNature);
    }
    if ($ruleFor eq 'ENTITY' and $entityID)  {
        ## APPROVAL FOR ENTITY
        $st = qq[
		SELECT 
			r.intWFRuleID, 
			r.intRealmID,
			r.intSubRealmID,
			r.intApprovalEntityLevel,
			r.strTaskType, 
            r.strWFRuleFor,
			r.intDocumentTypeID, 
			r.strTaskStatus, 
			r.intProblemResolutionEntityLevel, 
            0 as intPersonID,
            0 as intPersonRegistrationID,
            e.intEntityID as RegoEntity,
            0 as DocumentID
		FROM tblEntity as e
		INNER JOIN tblWFRule AS r ON (
			e.intRealmID = r.intRealmID
			AND e.intSubRealmID = r.intSubRealmID
            AND r.strPersonType = ''
			AND r.intEntityLevel = e.intEntityLevel
            AND e.strEntityType = r.strEntityType
        )
		WHERE e.intEntityID= ?
            AND r.strWFRuleFor = 'ENTITY'
            AND r.intRealmID = ?
            AND r.intSubRealmID IN (0, ?)
            AND r.intOriginLevel = ?
			AND r.strRegistrationNature = ?
		];
	    $q = $db->prepare($st);
  	    $q->execute($entityID, $Data->{'Realm'}, $Data->{'RealmSubType'}, $originLevel, $regNature);
    }
    if ($ruleFor eq 'DOCUMENT' and $documentID)    {
        ## APPROVAL FOR DOCUMENT
        $st = qq[
		SELECT 
			r.intWFRuleID, 
			r.intRealmID,
			r.intSubRealmID,
			r.intApprovalEntityLevel,
			r.strTaskType, 
            r.strWFRuleFor,
			r.intDocumentTypeID, 
			r.strTaskStatus, 
			r.intProblemResolutionEntityLevel, 
            0 as intPersonID,
            0 as intPersonRegistrationID,
            e.intEntityID as RegoEntity,
            d.intDocumentID as DocumentID
		FROM tblDocuments as d 
		INNER JOIN tblWFRule AS r ON (
            d.intDocumentTypeID = r.intDocumentTypeID
            AND d.intEntityLevel = r.intEntityLevel
        )
		WHERE d.intDocumentID = ?
            AND r.strWFRuleFor = 'DOCUMENT'
            AND r.intRealmID = ?
            AND r.intSubRealmID IN (0, ?)
            AND r.intOriginLevel = ?
			AND r.strRegistrationNature = ?
		];
	    $q = $db->prepare($st);
  	    $q->execute($documentID, $Data->{'Realm'}, $Data->{'RealmSubType'}, $originLevel, $regNature);
    }



    while (my $dref= $q->fetchrow_hashref())    {
        my $approvalEntityID = getEntityParentID($Data, $dref->{RegoEntity}, $dref->{'intApprovalEntityLevel'}) || 0;
        my $problemEntityID = getEntityParentID($Data, $dref->{RegoEntity}, $dref->{'intProblemResolutionEntityLevel'});
        next if (! $approvalEntityID and ! $problemEntityID);
  	    $qINS->execute(
            $dref->{'intWFRuleID'},
            $dref->{'intRealmID'},
            $dref->{'intSubRealmID'},
            $Data->{'clientValues'}{'userID'} || 0,
            $approvalEntityID,
            $dref->{'strTaskType'},
            $ruleFor,
            $regNature,
            $dref->{'intDocumentTypeID'},
            $dref->{'strTaskStatus'},
            $problemEntityID,
            $entityID,
            $dref->{'intPersonID'},
            $dref->{'intPersonRegistrationID'},
            $dref->{'DocumentID'}
        );

    }
	
	if ($q->errstr) {
		return $q->errstr . '<br>' . $st
	}			
	$st = qq[
		INSERT IGNORE INTO tblWFTaskPreReq (
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

	my $rc = checkForOutstandingTasks($Data,$ruleFor, '', $entityID, $personID, $personRegistrationID, $documentID);

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
	  		strTaskStatus = ?,
	  		intApprovalUserID = ?,
	  		dtApprovalDate = NOW()
	  	WHERE intWFTaskID = ? 
            AND intRealmID=?
		];
		
  	$q = $db->prepare($st);
  	$q->execute(
        $Defs::WF_TASK_STATUS_COMPLETE,
	  	$Data->{'clientValues'}{'userID'},
  		$WFTaskID,
        $Data->{'Realm'}
  	);
  		
    setDocumentStatus($Data, $WFTaskID, 'APPROVED');
	if ($q->errstr) {
		return $q->errstr . '<br>' . $st
	}
	
    $st = qq[
        SELECT 
            intPersonID,
            intPersonRegistrationID,
            intEntityID,
            intDocumentID,
            intDocumentTypeID,
            strTaskType,
            strWFRuleFor
        FROM tblWFTask
        WHERE intWFTaskID = ?
    ];
        
    $q = $db->prepare($st);
    $q->execute($WFTaskID);
            
    my $dref= $q->fetchrow_hashref();
    my $personID = $dref->{intPersonID} || 0;
    my $personRegistrationID = $dref->{intPersonRegistrationID} || 0;
    my $entityID= $dref->{intEntityID} || 0;
    my $documentID= $dref->{intDocumentID} || 0;
    my $ruleFor = $dref->{strWFRuleFor} || '';
    my $taskType= $dref->{strTaskType} || '';
    
   	my $rc = checkForOutstandingTasks($Data,$ruleFor, $taskType, $entityID, $personID, $personRegistrationID, $documentID);
    
    return($rc);
    
}

sub checkForOutstandingTasks {
    my(
        $Data,
        $ruleFor,
        $taskType,
        $entityID,
        $personID,
        $personRegistrationID,
        $documentID
    ) = @_;

	my $st = '';
	my $q = '';
	my $db=$Data->{'db'};
    $taskType ||= '';
		
	#As a result of an update, check to see if there are any Tasks that now have all their pre-reqs completed
	# or if all tasks have been completed
	$st = qq[	
		SELECT DISTINCT 
			pt.intWFTaskID, ct.strTaskStatus 
		FROM tblWFTask pt
		INNER JOIN tblWFTaskPreReq ptpr ON pt.intWFTaskID = ptpr.intWFTaskID
		INNER JOIN tblWFTask ct on ptpr.intPreReqWFRuleID = ct.intWFRuleID 
        WHERE
			pt.strTaskStatus = ?
		    AND (pt.intPersonRegistrationID = ? AND pt.intEntityID = ? AND pt.intPersonID = ? and pt.intDocumentID = ?)
			AND (ct.intPersonRegistrationID = pt.intPersonRegistrationID AND ct.intEntityID = pt.intEntityID AND ct.intPersonID = pt.intPersonID and ct.intDocumentID = pt.intDocumentID)
            AND pt.strWFRuleFor = ?
            AND ct.strWFRuleFor = pt.strWFRuleFor
		ORDER by pt.intWFTaskID;
	];
			#AND ct.strTaskStatus IN (?,?,?)
        #$Defs::WF_TASK_STATUS_ACTIVE,
        #$Defs::WF_TASK_STATUS_COMPLETE,
        #$Defs::WF_TASK_STATUS_REJECTED,
	$q = $db->prepare($st);
  	$q->execute(
  		$Defs::WF_TASK_STATUS_PENDING,
  		$personRegistrationID,
        $entityID,
        $personID,
        $documentID,
        $ruleFor,
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
   		if ($dref->{strTaskStatus} eq 'PENDING') {
   			$updateThisTask = "nope";
   		}
   		if ($dref->{strTaskStatus} eq 'REJECTED') {
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
		  		dtActivateDate = NOW()
		  	WHERE intWFTaskID IN ($list_WFTaskID); 
			];
		  		#intActiveUserID = 1
			
	  	$q = $db->prepare($st);
	  	$q->execute();
	  		
		if ($q->errstr) {
			return $q->errstr . '<br>' . $st
		}
		    
	} 
	else {	
		# Nothing to update. Do a check to see if all tasks have been completed
		$st = qq[
            SELECT 
                COUNT(*) as NumRows
            FROM 
                tblWFTask
            WHERE 
                intPersonID = ?
                AND intPersonRegistrationID = ?
                AND intEntityID= ?
                AND intDocumentID = ?
                AND strWFRUleFor = ?
			    AND strTaskStatus IN (?,?)
        ];
        
        $q = $db->prepare($st);
        $q->execute(
            $personID,
       		$personRegistrationID,
            $entityID,
            $documentID,
            $ruleFor,
            $Defs::WF_TASK_STATUS_PENDING,
            $Defs::WF_TASK_STATUS_ACTIVE
	  	);
  
        my $rowCount = $q->fetchrow_array() || 0;
        
        if ($ruleFor eq 'ENTITY' and $entityID and ! $rowCount) {
            $st = qq[
                    UPDATE tblEntity
                    SET
                        strStatus = 'ACTIVE',
                        dtFrom = NOW()
                    WHERE
                        intEntityID= ?
                ];

                $q = $db->prepare($st);
                $q->execute(
                    $entityID
                    );
                $rc = 1;
        }
        if ($ruleFor eq 'DOCUMENT' and $documentID and !$rowCount)   {
            $st = qq[
                    UPDATE tblDocuments
                    SET
                        strApprovalStatus = 'APPROVED'
                    WHERE
                        intDocumentID= ?
                ];

                $q = $db->prepare($st);
                $q->execute(
                    $documentID
                );
                $rc = 1;
        }
 
        if ($ruleFor eq 'REGO' and $personRegistrationID and !$rowCount) {

                ## Handle intPaymentRequired ?  What abotu $0 products
        
	            $st = qq[
	            	UPDATE tblPersonRegistration_$Data->{'Realm'} 
                    SET
	            	    strStatus = 'ACTIVE',
                        intCurrent=1,
	            	    dtFrom = NOW(),
                        dtLastUpdated=NOW()
	    	        WHERE 
                        intPersonRegistrationID = ?
                        AND strStatus IN ('PENDING', 'INPROGRESS')
	        	];
                        #AND strStatus NOT IN ('SUSPENDED', 'TRANSFERRED', 'DELETED')
	    
		        $q = $db->prepare($st);
		        $q->execute(
		       		$personRegistrationID
		  			);         
	        	$rc = 1;	# All registration tasks have been completed        		
                PersonRegistration::rolloverExistingPersonRegistrations($Data, $personID, $personRegistrationID);
        }
        if ($personID and $taskType ne $Defs::WF_TASK_TYPE_CHECKDUPL)  {
                $st = qq[
	            	UPDATE tblPerson
                    SET
	            	    strStatus = 'ACTIVE'
	    	        WHERE 
                        intPersonID= ?
                        AND strStatus='PENDING'
	        	];
	    
		        $q = $db->prepare($st);
		        $q->execute( $personID); 
	        	$rc = 1;	# All registration tasks have been completed        		
        	#}
        }
	}      

return ($rc) # 1 = Registration is complete, 0 = There are still outstanding Tasks to be completed
       	
}

sub setDocumentStatus  {

    my ($Data, $taskID, $status) = @_;
    my $st = qq[
        SELECT
            intPersonID,
            intPersonRegistrationID,
            intEntityID,
            intDocumentID,
            intDocumentTypeID
        FROM tblWFTask
        WHERE intWFTaskID = ?
    ];

    my $q = $Data->{'db'}->prepare($st);
    $q->execute($taskID);

    my $dref= $q->fetchrow_hashref();
    my $personID = $dref->{intPersonID} || 0;
    my $entityID = $dref->{intEntityID} || 0;
    my $personRegistrationID = $dref->{intPersonRegistrationID} || 0;
    my $documentID= $dref->{intDocumentID} || 0;
    my $documentTypeID= $dref->{intDocumentTypeID} || 0;
    my $ruleFor = $dref->{strWFRuleFor} || '';
    my $taskType= $dref->{strTaskType} || '';

    return if (! $entityID and !$personID);
    return if (! $documentID and !$documentTypeID);

    $st = qq[
        UPDATE tblDocuments
        SET strApprovalStatus = ?
        WHERE
            1=1
    ];
    my @values=();
    push @values, $status;
    if ($personID)  {
        $st .= qq[ AND intPersonID = ?];
        push @values, $personID;
    }
    else    {
        $st .= qq[ AND intEntityID = ?];
        push @values, $entityID;
        $st .= qq[ AND intEntityLevel <> ?];
        push @values, $Defs::LEVEL_PERSON;
    }
    
    
    if ($documentTypeID)    {
        $st .= qq[ AND intDocumentTypeID = ?];
        push @values, $documentTypeID;
    }
    if ($documentID)    {
        $st .= qq[ AND intDocumentID = ?];
        push @values, $documentID;
    }
    if ($personRegistrationID)    {
        $st .= qq[ AND intPersonRegistrationID IN (0,?) ];
        push @values, $personRegistrationID;
        $st .= qq[ 
            ORDER BY intPersonRegistrationID DESC
        ];
    }
    $st .= qq[
        LIMIT 1
    ];
  	$q = $Data->{'db'}->prepare($st);
  	$q->execute(@values);
}

sub updateTaskNotes {

    my( $Data) = @_;

    my $WFTaskID = safe_param('TID','number') || '';
    my $notes= safe_param('notes','words') || '';
    my $lang = $Data->{'lang'};
    my $title = $lang->txt('Work task notes Updated');

    my $st = qq[
        UPDATE tblWFTask
        SET 
            strTaskNotes = ?
        WHERE 
            intWFTaskID = ?
            AND intRealmID=?
        LIMIT 1
    ];
    
  	my $q = $Data->{'db'}->prepare($st);
  	$q->execute($notes, $WFTaskID, $Data->{'Realm'});

   my %TemplateData = (
			TaskID=> $WFTaskID,
            Lang => $Data->{'lang'},
			TaskNotes=> $notes,
			client => $Data->{client},
            target=>$Data->{'target'},
            action => 'WF_list',
	);

	my $body = runTemplate(
			$Data,
			\%TemplateData,
			'dashboards/worktask_notes_updated.templ',
	);
    
    return ($body, $title);

}
    
sub setPersonRegoStatus  {

    my ($Data, $taskID, $status) = @_;
    my $prevStatus = ($status eq $Defs::WF_TASK_STATUS_PENDING) ? $Defs::WF_TASK_STATUS_REJECTED : $Defs::WF_TASK_STATUS_PENDING;

    my $st;
    my $q;

    $st = qq[
        UPDATE tblPersonRegistration_$Data->{'Realm'} as PR
            INNER JOIN tblWFTask as T ON (
                PR.intPersonRegistrationID = T.intPersonRegistrationID
                AND PR.intPersonID = T.intPersonID
            )
        SET strStatus='$status'
        WHERE 
            intWFTaskID = ?
            AND PR.strStatus IN ('$prevStatus')
            AND T.strWFRuleFor = 'REGO'
    ];
  	$q = $Data->{'db'}->prepare($st);
  	$q->execute(
  		$taskID,
    );
}

sub setEntityStatus  {

    my ($Data, $taskID, $status) = @_;
    my $prevStatus = ($status eq $Defs::WF_TASK_STATUS_PENDING) ? $Defs::WF_TASK_STATUS_REJECTED : $Defs::WF_TASK_STATUS_PENDING;

    my $st;
    my $q;

    $st = qq[
        UPDATE tblEntity as EN
            INNER JOIN tblWFTask as T ON (
                EN.intEntityID = T.intEntityID
            )
        SET strStatus='$status'
        WHERE 
            intWFTaskID = ?
            AND EN.strStatus IN ('$prevStatus')
            AND T.strWFRuleFor = 'ENTITY'
            AND EN.intRealmID = ?
    ];
  	$q = $Data->{'db'}->prepare($st);
  	$q->execute(
  		$taskID,
        $Data->{'Realm'},
    );
}



sub addTaskNotes    {

    my( $Data) = @_;

    my $WFTaskID = safe_param('TID','number') || '';

    my $lang = $Data->{'lang'};
    my $title = $lang->txt('Work task Notes');
    my $st = qq[
        SELECT
            strTaskNotes
        FROM
            tblWFTask
        WHERE 
            intWFTaskID = ?
    ];
  	my $q = $Data->{'db'}->prepare($st);
  	$q->execute($WFTaskID);
    my $notes = $q->fetchrow_array() || '';

    my %TemplateData = (
			TaskID=> $WFTaskID,
            Lang => $Data->{'lang'},
			TaskNotes=> $notes,
			client => $Data->{client},
            target=>$Data->{'target'},
            action => 'WF_notesS',
	);

	my $body = runTemplate(
			$Data,
			\%TemplateData,
			'dashboards/worktask_notes.templ',
	);
    
    return ($body, $title);
}
sub resolveTask {
    my(
        $Data,
    ) = @_;
	
	my $st = '';
	my $q = '';
	my $db=$Data->{'db'};

	#Get values from the QS
    my $WFTaskID = safe_param('TID','number') || '';

    #FC-144 get current task based on taskid param
    my $task = getTask($Data, $WFTaskID);
	
    return if (!$task or ($task eq undef));

    if($task->{strWFRuleFor} eq 'ENTITY') {
        setEntityStatus($Data, $WFTaskID, $Defs::WF_TASK_STATUS_REJECTED);
    }

    if($task->{strWFRuleFor} eq 'REGO') {
        setPersonRegoStatus($Data, $WFTaskID, $Defs::WF_TASK_STATUS_REJECTED);
    }


	#Update this task to REJECTED
	$st = qq[
	  	UPDATE tblWFTask 
        SET 
	  		strTaskStatus = 'ACTIVE'
	  	WHERE 
            intWFTaskID = ? 
            AND intProblemResolutionEntityID = ?
            AND intRealmID = ?
    ];

    if($task->{strWFRuleFor} eq 'ENTITY') {
        setEntityStatus($Data, $WFTaskID, $Defs::WF_TASK_STATUS_PENDING);
    }

    if($task->{strWFRuleFor} eq 'REGO') {
        setPersonRegoStatus($Data, $WFTaskID, $Defs::WF_TASK_STATUS_PENDING);
    }

  	$q = $db->prepare($st);
  	$q->execute(
  		$WFTaskID,
        getLastEntityID($Data->{'clientValues'}),
        $Data->{'Realm'}
  	);
	if ($q->errstr) {
		return $q->errstr . '<br>' . $st
	}
    setDocumentStatus($Data, $WFTaskID, 'PENDING');

    return(0);
    
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

    #FC-144 get current task based on taskid param
    my $task = getTask($Data, $WFTaskID);
	
    return if (!$task or ($task eq undef));

    if($task->{strWFRuleFor} eq 'ENTITY') {
        setEntityStatus($Data, $WFTaskID, $Defs::WF_TASK_STATUS_REJECTED);
    }

    if($task->{strWFRuleFor} eq 'REGO') {
        setPersonRegoStatus($Data, $WFTaskID, $Defs::WF_TASK_STATUS_REJECTED);
    }

	#Update this task to REJECTED
    $st = qq[
	  	UPDATE tblWFTask 
        SET 
	  		strTaskStatus = 'REJECTED',
	  		intRejectedUserID = ?,
	  		dtRejectedDate = NOW()
	  	WHERE 
            intWFTaskID = ? 
            AND intRealmID= ?
    ];

    $q = $db->prepare($st);
  	$q->execute(
	  	$Data->{'clientValues'}{'userID'},
  		$WFTaskID,
        $Data->{'Realm'}
  	);

    setDocumentStatus($Data, $WFTaskID, 'REJECTED');

    if ($q->errstr) {
		return $q->errstr . '<br>' . $st
	}

    return(0);
    
}

sub getTask {
    my ($Data, $WFTaskID) = @_;

    my $st = '';
    my $q = '';
	$st = qq[
	  	SELECT
            intWFTaskID,
            intWFRuleID,
            intRealmID,
            intApprovalEntityID,
            strWFRuleFor,
            strTaskStatus
        FROM
            tblWFTask 
	  	WHERE 
            intWFTaskID = ? 
            AND intRealmID = ?
    ];

    $q = $Data->{'db'}->prepare($st);
    $q->execute(
        $WFTaskID,
        $Data->{'Realm'},
    );

    my $result = $q->fetchrow_hashref();
    return $result || undef;
}
1;
