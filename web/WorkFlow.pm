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
    viewTask
    populateRegoViewData
    populatePersonViewData
    populateDocumentViewData
    populateTaskNotesViewData
    populateEntityViewData
    resetRelatedTasks
    viewApprovalPage
    viewSummaryPage
    toggleTask
    checkRelatedTasks
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
use Data::Dumper;
use Switch;
use PlayerPassport;
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
        my $allComplete = checkRelatedTasks($Data);
        if($allComplete) {
            ( $body, $title ) = viewSummaryPage( $Data );	
        }
        else {
            ( $body, $title ) = viewApprovalPage( $Data );	
        }
    }
    elsif ( $action eq 'WF_notesS' ) {
        ( $body, $title ) = updateTaskNotes( $Data );	
    }
    elsif ( $action eq 'WF_Resolve' ) {
        resolveTask($Data);
        ( $body, $title ) = addTaskNotes( $Data, $Defs::WF_TASK_ACTION_RESOLVE );	
    }
    elsif ( $action eq 'WF_Reject' ) {
        rejectTask($Data);
        ( $body, $title ) = addTaskNotes( $Data, $Defs::WF_TASK_ACTION_REJECT );	
    }
    elsif ( $action eq 'WF_View' ) {
        ( $body, $title ) = viewTask( $Data );		
    }
    elsif ( $action eq 'WF_Verify' ) {
        verifyDocument($Data);
        ( $body, $title ) = viewTask( $Data );
    }
    elsif ( $action eq 'WF_Summary' ) {
        ( $body, $title ) = viewSummaryPreApproval( $Data );
    }
    elsif ( $action eq 'WF_Toggle' ) {
        my $res = toggleTask($Data);
        if($res) {
            ( $body, $title ) = addTaskNotes( $Data, "TOGGLE" );
        }
        else {
            ( $body, $title ) = ("", "No access");
        }
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
            t.strTaskNotes as TaskNotes,
            t.intOnHold as OnHold
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
                OR
                (intOnHold = 1)
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

        my $showView = 0;
        $showView = 1 if(($showApprove and $dref->{'OnHold'} == 1) or ($showResolve and $dref->{'OnHold'} == 1) or $dref->{'OnHold'} == 0);

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
            showView => $showView,
            OnHold => $dref->{OnHold}
		);
		push @TaskList, \%single_row;
	}

    ## Calc Dupl Res and Pending Clr here
    my $clrCount = 0; #getClrTaskCount($Data, $entityID);
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
            $entityID as RegoEntity,
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
        #0 as RegoEntity,
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
            AND (r.strISOCountry_IN IS NULL or r.strISOCountry_IN = '' OR r.strISOCountry_IN LIKE CONCAT('%|',p.strISONationality ,'|%'))
            AND (r.strISOCountry_NOTIN IS NULL or r.strISOCountry_NOTIN = '' OR r.strISOCountry_NOTIN NOT LIKE CONCAT('%|',p.strISONationality ,'|%'))
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

	my $rc = checkForOutstandingTasks($Data, $ruleFor, '', $entityID, $personID, $personRegistrationID, $documentID);
    
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
        
                        #LEFT JOIN tblNationalPeriod as NP ON (PR.intNationalPeriodID = NP.intNationalPeriodID)
	            	    #PR.dtFrom = NP.dtFrom,
                        #PR.dtTo = NP.dtTo,
	            $st = qq[
	            	UPDATE tblPersonRegistration_$Data->{'Realm'} as PR
                    SET
	            	    PR.strStatus = 'ACTIVE',
                        PR.intCurrent=1,
                        dtLastUpdated=NOW()
	    	        WHERE 
                        PR.intPersonRegistrationID = ?
                        AND PR.strStatus IN ('PENDING', 'INPROGRESS')
	        	];
                        #AND strStatus NOT IN ('SUSPENDED', 'TRANSFERRED', 'DELETED')
	    
		        $q = $db->prepare($st);
		        $q->execute(
		       		$personRegistrationID
		  			);         
	        	$rc = 1;	# All registration tasks have been completed        		
                PersonRegistration::rolloverExistingPersonRegistrations($Data, $personID, $personRegistrationID);
				# Do the check
				$st = qq[SELECT strPersonType, strSport FROM tblPersonRegistration_$Data->{Realm} WHERE intPersonRegistrationID = ?]; 
                $q = $db->prepare($st);
				$q->execute($personRegistrationID);   
				my $ppref = $q->fetchrow_hashref();				
                # if check  pass call save
                if( ($ppref->{'strPersonType'} eq 'PLAYER') && ($ppref->{'strSport'} eq 'FOOTBALL'))    {
                	savePlayerPassport($Data, $personID);
                }
           ##############################################################################################################        
        }
        if ($personID and $taskType ne $Defs::WF_TASK_TYPE_CHECKDUPL)  {
                $st = qq[
	            	UPDATE tblPerson
                    SET
	            	    strStatus = 'REGISTERED'
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
    my $type = safe_param('type','words') || '';
    my $lang = $Data->{'lang'};
    my $title = $lang->txt('Work task notes Updated');

    my $task = getTask($Data, $WFTaskID);
    #identify type of action (rejection or resolution based on intApprovalEntityID and intProblemResolutionID)
    my $entityID = getID($Data->{'clientValues'},$Data->{'clientValues'}{'currentLevel'});
    #my $type = ($entityID == $task->{'intApprovalEntityID'}) ? 'REJECT' : ($entityID == $task->{'intProblemResolutionEntityID'}) ? 'RESOLVE' : '';
    my $WFRejectCurrentNoteID = $task->{'rejectTaskNoteID'} || 0;
    my $WFToggleCurrentNoteID = $task->{'toggleTaskNoteID'} || 0;
    my $st;

    $st = qq[
        INSERT INTO tblWFTaskNotes (
            intTaskNoteID,
            intParentNoteID,
            intWFTaskID,
            strNotes,
            intCurrent,
            strType,
            tTimeStamp
        )
        VALUES (
            ?,
            ?,
            ?,
            ?,
            ?,
            ?,
            now()
        )

    ];

    if(($entityID == $task->{'intApprovalEntityID'}) and ($type eq $Defs::WF_TASK_ACTION_REJECT)) {   #reject
        my $q = $Data->{'db'}->prepare($st);
        $q->execute(
            $WFRejectCurrentNoteID,
            0,
            $WFTaskID,
            $notes,
            1,
            $Defs::WF_TASK_ACTION_REJECT
        );
    }
    elsif (($entityID == $task->{'intProblemResolutionEntityID'}) and ($type eq $Defs::WF_TASK_ACTION_RESOLVE)) { #resolve
        warn "RESOLTION $entityID";
        warn "PARENTID $WFRejectCurrentNoteID";

        #check if there's a current rejection note
        #if exists, update it with intCurrent = 0 then insert new record,
        #otherwise do nothing (to prevent duplicate entries and un-mapped notes)
        if($WFRejectCurrentNoteID and $task->{'rejectCurrent'} == 1) {
            my $q = $Data->{'db'}->prepare($st);
            $q->execute(
                0,
                $WFRejectCurrentNoteID,
                $WFTaskID,
                $notes,
                0,
                $Defs::WF_TASK_ACTION_RESOLVE
            );

            my $streset = qq[
                UPDATE
                    tblWFTaskNotes
                SET
                    intCurrent = 0
                WHERE
                    intTaskNoteID = ?
            ];

            $q = $Data->{'db'}->prepare($streset);
            $q->execute(
                $WFRejectCurrentNoteID
            ) or query_error($streset);

        }
    }
    elsif ($type = "TOGGLE") {
        #check intOnHold 
        warn "NEWFLOW HOLD STATUS $task->{'intOnHold'}";
        if($task->{'intOnHold'} == 1) {
            #put on-hold
            #WFToggleCurrentNoteID as bind param
            #to prevent duplicate entry
            my $q = $Data->{'db'}->prepare($st);
            $q->execute(
                $WFToggleCurrentNoteID,
                0,
                $WFTaskID,
                $notes,
                1,
                $Defs::WF_TASK_ACTION_HOLD
            );
        }
        else {
            if($WFToggleCurrentNoteID and $task->{'toggleCurrent'} == 1) {
                my $q = $Data->{'db'}->prepare($st);
                $q->execute(
                    0,
                    $WFToggleCurrentNoteID,
                    $WFTaskID,
                    $notes,
                    0,
                    $Defs::WF_TASK_ACTION_RESUME
                );

                my $streset = qq[
                    UPDATE
                        tblWFTaskNotes
                    SET
                        intCurrent = 0
                    WHERE
                        intTaskNoteID = ?
                ];

                $q = $Data->{'db'}->prepare($streset);
                $q->execute(
                    $WFToggleCurrentNoteID
                ) or query_error($streset);

            }
        }
    }


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

sub verifyDocument {
    my ($Data) = @_;

    my $WFTaskID = safe_param('TID','number') || '';
    my $documentID = safe_param('did','number') || '';

    my $st = qq[
        UPDATE tblDocuments
        SET
            strApprovalStatus = 'VERIFIED'
        WHERE
        intDocumentID = ?
    ];

    my $q = $Data->{'db'}->prepare($st);
    $q->execute(
        $documentID
    );

    warn "VERIFY DOCUMENT $documentID";
}

sub addTaskNotes    {

    my( $Data, $noteType) = @_;

    my $WFTaskID = safe_param('TID','number') || '';
    my $WFCurrentNoteID = safe_param('NID','number') || '';

    my $lang = $Data->{'lang'};
    my $title = $lang->txt('Work task Notes');
    #my $st = qq[
    #    SELECT
    #        strTaskNotes
    #    FROM
    #        tblWFTask
    #    WHERE 
    #        intWFTaskID = ?
    #];
  	#my $q = $Data->{'db'}->prepare($st);
  	#$q->execute($WFTaskID);
    #my $notes = $q->fetchrow_array() || '';

    my %TemplateData = (
        TaskID=> $WFTaskID,
        CurrentNoteID=> $WFCurrentNoteID,
        Lang => $Data->{'lang'},
        TaskNotes=> '',
        client => $Data->{client},
        target=>$Data->{'target'},
        action => 'WF_notesS',
        type => $noteType,
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

    resetRelatedTasks($Data, $WFTaskID, 'ACTIVE');

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

    resetRelatedTasks($Data, $WFTaskID, 'PENDING');
    if ($q->errstr) {
		return $q->errstr . '<br>' . $st
	}

    return(0);
    
}

sub getTask {
    my ($Data, $WFTaskID) = @_;

    my $st = '';
    my $q = '';
    #TODO: join to other tables: person, personrego, etc
	$st = qq[
	  	SELECT
            t.intWFTaskID,
            t.intWFRuleID,
            t.intRealmID,
            t.intApprovalEntityID,
            t.intProblemResolutionEntityID,
            t.strWFRuleFor,
            t.strTaskStatus,
            t.intOnHold,
            e.intEntityLevel,
            rnt.intTaskNoteID as rejectTaskNoteID,
            rnt.intCurrent as rejectCurrent,
            tnt.intTaskNoteID as toggleTaskNoteID,
            tnt.intCurrent as toggleCurrent
        FROM
            tblWFTask t
        LEFT JOIN tblWFTaskNotes rnt ON (t.intWFTaskID = rnt.intWFTaskID AND rnt.strType = "REJECT" AND rnt.intCurrent = 1)
        LEFT JOIN tblWFTaskNotes tnt ON (t.intWFTaskID = tnt.intWFTaskID AND tnt.strType = "HOLD" AND tnt.intCurrent = 1)
        LEFT JOIN tblEntity e ON (t.intEntityID = e.intEntityID)
	  	WHERE 
            t.intWFTaskID = ? 
            AND t.intRealmID = ?
    ];

    $q = $Data->{'db'}->prepare($st);
    $q->execute(
        $WFTaskID,
        $Data->{'Realm'},
    );

    my $result = $q->fetchrow_hashref();
    print STDERR Dumper $result;
    return $result || undef;
}

sub viewTask {
    my ($Data) = @_;
    #TODO
    #retrieve all necessary details here
    #   - person detail
    #   - or entity detail
    #   - and documents
    # DONE: using $WFTaskID, link tblWFTask to tblEntity to personRegistration (if intPersonRegistrationID != 0) and tblPerson (use intPersonID)
    # using entityID, add a check so that the entity should only have access to task specifically assigned to it
    # check strTask status
    #   - if rejected, intProblemResolutionID = entityID
    #   - if active, intApprovalEntityID = entityID
    #   - check strStatus
    #       - if COMPLETED (final approval as per comment in JIRA), display a summary page

    my $WFTaskID = safe_param('TID','number') || '';
    my $entityID = getID($Data->{'clientValues'},$Data->{'clientValues'}{'currentLevel'});

    my $st;

    $st = qq[
        SELECT 
            t.intWFTaskID, 
            t.strTaskStatus, 
            t.strTaskType, 
            t.intOnHold, 
            pr.intPersonRegistrationID, 
            pr.strStatus as personRegistrationStatus,
            pr.strPersonLevel, 
            pr.strAgeLevel, 
            pr.strSport, 
            pr.strPersonType,
            t.strRegistrationNature, 
            dt.strDocumentName,
            p.strLocalFirstname, 
            p.strStatus as PersonStatus,
            p.strLocalMiddleName,
            p.strLocalSurname,
            p.dtDOB,
            p.strAddress1,
            p.strAddress2,
            p.strSuburb,
            p.strState,
            p.strPostalCode,
            p.strLocalSurname, 
            p.dtSuspendedUntil, 
            p.strISONationality, 
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
            t.strTaskNotes as TaskNotes,
            e.strEntityType,
            e.strStatus as entityStatus,
            e.strLocalName as entityLocalName,
            e.strLocalShortName as strLocalShortName,
            e.strRegion as entityRegion,
            e.strPostalCode as entityPostalCode,
            e.strTown as entityTown,
            e.strAddress as entityAddress,
            e.strWebUrl as entityWebUrl,
            e.strEmail as entityEmail,
            e.strPhone as entityPhone,
            e.strFax as entityFax,
            e.tTimeStamp as entityCreatedUpdated,
            dPersonRego.intDocumentID as documentID,
            dPersonRego.strApprovalStatus as documentApprovalStatus,
            dPersonRego.strDeniedNotes as documentDeniedNotes,
            dt.strDocumentName as documentName,
            uf.strOrigFilename as documentOrigFilename,
            uf.strPath as documentPath,
            uf.strFilename as documentFilename,
            uf.strExtension as documentExtension,
            dPersonRego.intPersonRegistrationID as documentPersonRegistrationID,
            dPersonRego.intPersonID as documentPersonID,
            tn.intTaskNoteID as currentNoteID
        FROM tblWFTask AS t
        LEFT JOIN tblEntity as e ON (e.intEntityID = t.intEntityID)
        LEFT JOIN tblPersonRegistration_$Data->{'Realm'} AS pr ON (t.intPersonRegistrationID = pr.intPersonRegistrationID)
        LEFT JOIN tblPerson AS p ON (t.intPersonID = p.intPersonID)
        LEFT JOIN tblUserAuthRole AS uar ON ( t.intApprovalEntityID = uar.entityID )
        LEFT JOIN tblUserAuthRole AS uarRejected ON ( t.intProblemResolutionEntityID = uarRejected.entityID )
        LEFT JOIN tblDocuments as dPersonRego ON (t.intPersonID = dPersonRego.intPersonID AND t.intPersonRegistrationID = dPersonRego.intPersonRegistrationID)
        LEFT JOIN tblUploadedFiles as uf ON (dPersonRego.intUploadFileID = uf.intFileID)
        LEFT JOIN tblDocumentType as dt ON (dPersonRego.intDocumentTypeID = dt.intDocumentTypeID)
        LEFT JOIN tblWFTaskNotes as tn ON (tn.intWFTaskID = t.intWFTaskID AND tn.intCurrent = 1)
        WHERE 
            t.intRealmID = $Data->{'Realm'}
            AND t.intWFTaskID = ?
            AND (
                (intApprovalEntityID = ? AND t.strTaskStatus = 'ACTIVE')
                OR
                (intProblemResolutionEntityID = ? AND t.strTaskStatus = 'REJECTED')
            )
        LIMIT 1
    ];

    my $db = $Data->{'db'};
    my $q = $db->prepare($st) or query_error($st);
    $q->execute(
        $WFTaskID,
        $entityID,
        $entityID,
    ) or query_error($st);

    my @TaskList = ();
    my $rowCount = 0;
	  
    my $dref = $q->fetchrow_hashref();
    #print STDERR Dumper $dref;

    if(!$dref) {
        return (undef, "ERROR: no data retrieved/no access.");
    }

    warn "WORKFLOW_entityID " . $entityID;
    warn "WORKFLOW_strRuleFor " . $dref->{strWFRuleFor};

    my %TemplateData;
    my %DocumentData;
    my %NotesData;
    my %PaymentsData;
    my %ActionsData;
    my %fields;

    switch($dref->{strWFRuleFor}) {
        case 'REGO' {
            my ($TemplateData, $fields) = populateRegoViewData($Data, $dref);
            %TemplateData = %{$TemplateData};
            %fields = %{$fields};
        }
        case 'ENTITY' {
            my ($TemplateData, $fields) = populateEntityViewData($Data, $dref);
            %TemplateData = %{$TemplateData};
            %fields = %{$fields};
        }
        case 'PERSON' {
            my ($TemplateData, $fields) = populatePersonViewData($Data, $dref);
            %TemplateData = %{$TemplateData};
            %fields = %{$fields};
        }
        else {
            my ($TemplateData, $fields) = (undef, undef);
        }
    }

    my $showToggle = 0;
    #make sure only the current assignee can put on hold or resume the task
    $showToggle = 1
        if (($dref->{'strTaskStatus'} eq $Defs::WF_TASK_STATUS_REJECTED and $dref->{'intProblemResolutionEntityID'} and $dref->{'intProblemResolutionEntityID'} == $entityID)
            or ($dref->{'strTaskStatus'} eq $Defs::WF_TASK_STATUS_ACTIVE and $dref->{'intApprovalEntityID'} and $dref->{'intApprovalEntityID'} == $entityID));

    my $showReject = 0;
    $showReject = 1 if ($dref->{'intOnHold'} == 0 and $dref->{'intProblemResolutionEntityID'} and $dref->{'intProblemResolutionEntityID'} != $entityID);

    my $showApprove = 0;
    $showApprove = 1 if ($dref->{'intOnHold'} == 0 and $dref->{'intApprovalEntityID'} and $dref->{'intApprovalEntityID'} == $entityID);

    my $showResolve = 0;
    $showResolve = 1 if ($dref->{'intOnHold'} == 0 and $dref->{'strTaskStatus'} eq $Defs::WF_TASK_STATUS_REJECTED and $dref->{'intProblemResolutionEntityID'} and $dref->{'intProblemResolutionEntityID'} == $entityID);


    my %TaskAction = (
        'WFTaskID' => $dref->{intWFTaskID} || 0,
        'client' => $Data->{client} || 0,
        'showApprove' => $showApprove,
        'showReject' => $showReject,
        'showResolve' => $showResolve,
        'showToggle' => $showToggle,
        'currentNoteID' => $dref->{'currentNoteID'} || 0,   #primary set to 0 will insert new row to table
        'onHold' => $dref->{'intOnHold'},
    );

    my ($DocumentData, $fields) = populateDocumentViewData($Data, $dref);
    %DocumentData = %{$DocumentData};

    my $paymentBlock = '';
    if ($dref->{strWFRuleFor} eq 'REGO')    {
        my ($PaymentsData) = populateRegoPaymentsViewData($Data, $dref);
        %PaymentsData = %{$PaymentsData};
        $paymentBlock = runTemplate(
            $Data,
            \%PaymentsData,
            'workflow/generic/payment.templ'
        );
    }

    my ($NotesData) = populateTaskNotesViewData($Data, $dref);
    %NotesData = %{$NotesData};
    print STDERR Dumper %NotesData;

    my $documentBlock = runTemplate(
        $Data,
        \%DocumentData,
        'workflow/generic/document.templ'
    );


    my $notesBlock = runTemplate(
        $Data,
        \%NotesData,
        'workflow/generic/notes.templ'
    );

    $ActionsData{'TaskAction'} = \%TaskAction;
    my $actionsBlock = runTemplate(
        $Data,
        \%ActionsData,
        'workflow/generic/actions.templ'
    );

    $TemplateData{'TaskAction'} = \%TaskAction;
    $TemplateData{'DocumentBlock'} = $documentBlock;
    $TemplateData{'PaymentBlock'} = $paymentBlock;
    $TemplateData{'NotesBlock'} = $notesBlock;
    $TemplateData{'ActionsBlock'} = $actionsBlock;

    #print STDERR Dumper %TemplateData;
    my $body = runTemplate(
        $Data,
        \%TemplateData,
        $fields{'templateFile'},
    );

    return ($body, $fields{'title'});
    #return (undef, undef);
}

sub populateRegoViewData {
    my ($Data, $dref) = @_;

    my %TemplateData;
    my %fields = (
        title => 'Person Registration Details',
        templateFile => 'workflow/view/personregistration.templ',
    );

	%TemplateData = (
        PersonDetails => {
            Status => $Data->{'lang'}->txt($Defs::personStatus{$dref->{'PersonStatus'} || 0}) || '',
            Gender => $Data->{'lang'}->txt($Defs::genderInfo{$dref->{'PersonGender'} || 0}) || '',
            DOB => $dref->{'dtDOB'} || '',
            LocalName => "$dref->{'strLocalFirstname'} $dref->{'strLocalMiddleName'} $dref->{'strLocalSurname'}" || '',
            LatinName => "$dref->{'strLatinFirstname'} $dref->{'strLatinMiddleName'} $dref->{'strLatinSurname'}" || '',
            Address => "$dref->{'strAddress1'} $dref->{'strAddress2'} $dref->{'strAddress2'} $dref->{'strSuburb'} $dref->{'strState'} $dref->{'strPostalCode'}" || '',
            Nationality => $dref->{'strISONationality'} || '', #TODO identify extract string
            DateSuspendedUntil => '',
            LastUpdate => '',
        },
        PersonRegoDetails => {
            ID => $dref->{'intPersonRegistrationID'},
            Status => $Data->{'lang'}->txt($Defs::personRegoStatus{$dref->{'personRegistrationStatus'} || 0}) || '',
            RegoType => $Data->{'lang'}->txt($Defs::registrationNature{$dref->{'strRegistrationNature'} || 0}) || '',
            PersonType => $Data->{'lang'}->txt($Defs::personType{$dref->{'strPersonType'} || 0}) || '', 
            Sport => $Defs::sportType{$dref->{'strSport'}} || '',
            Level => $Defs::personLevel{$dref->{'strPersonLevel'}} || '',
            AgeLevel => $Defs::ageLevel{$dref->{'strAgeLevel'}} | '',
        },
	);
	
    return (\%TemplateData, \%fields);
}

sub populateEntityViewData {
    my ($Data, $dref) = @_;

    my %TemplateData;
    my %fields;

	%TemplateData = (
        EntityDetails => {
            Status => $Data->{'lang'}->txt($Defs::entityStatus{$dref->{'entityStatus'} || 0}) || '',
            LocalShortName => $dref->{'entityLocalShortName'} || '',
            LocalName => $dref->{'entityLocalName'} || '',
            Region => $dref->{'entityRegion'} || '',
            Address => $dref->{'entityAddress'} || '',
            Town => $dref->{'entityTown'} || '',
            WebUrl => $dref->{'entityWebUrl'} || '',
            Email => $dref->{'entityEmail'} || '',
            Phone => $dref->{'entityPhone'} || '',
            Fax => $dref->{'entityFax'} || '',
        },
	);
	
    switch ($dref->{intEntityLevel}) {
        case "$Defs::LEVEL_CLUB"  {
            %fields = (
                title => 'Club Registration Details',
                templateFile => 'workflow/view/club.templ',
            );
            #TODO: add details specific to CLUB
        }
        case "$Defs::LEVEL_VENUE" {
            %fields = (
                title => 'Venue Registration Details',
                templateFile => 'workflow/view/venue.templ',
            );
            #TODO: add details specific to VENUE
        }
        else {
        
        }
    }

    return (\%TemplateData, \%fields);
}

sub populatePersonViewData {
    my ($Data, $dref) = @_;

    my %TemplateData;
    my %fields = (
        title => 'Person Details',
        templateFile => 'workflow/view/person.templ',
    );

	%TemplateData = (
        PersonDetails => {
            Status => $Data->{'lang'}->txt($Defs::personStatus{$dref->{'PersonStatus'} || 0}) || '',
            Gender => $Data->{'lang'}->txt($Defs::genderInfo{$dref->{'PersonGender'} || 0}) || '',
            DOB => $dref->{'dtDOB'} || '',
            LocalName => "$dref->{'strLocalFirstname'} $dref->{'strLocalMiddleName'} $dref->{'strLocalSurname'}" || '',
            LatinName => "$dref->{'strLatinFirstname'} $dref->{'strLatinMiddleName'} $dref->{'strLatinSurname'}" || '',
            Address => "$dref->{'strAddress1'} $dref->{'strAddress2'} $dref->{'strAddress2'} $dref->{'strSuburb'} $dref->{'strState'} $dref->{'strPostalCode'}" || '',
            Nationality => $dref->{'strISONationality'} || '', #TODO identify extract string
            DateSuspendedUntil => '',
            LastUpdate => '',
        },
	);
	
    return (\%TemplateData, \%fields);

}

sub populateDocumentViewData {
    my ($Data, $dref) = @_;

    #need to retrieve list of documents here
    #since a specific work flow rule can have
    #multiple entries in tblWFRuleDocuments (1:n cardinality of task to document rules)
    
    my $joinCondition = '';

    switch($dref->{strWFRuleFor}) {
        case 'REGO' {
            $joinCondition .= qq[ (d.intDocumentTypeID = rd.intDocumentTypeID AND ((d.intPersonRegistrationID IN (0) AND pr.intNewBaseRecord = 1) OR (d.intPersonRegistrationID = wt.intPersonRegistrationID)) AND d.intPersonID = wt.intPersonID) ];
### MIGHT NEED TO MAKE d.intPersonRegistrationID IN (0, wt.intPersonRegistrationID) if its a new base record ?
        }
        case 'ENTITY' {
            $joinCondition .= qq[ (d.intDocumentTypeID = rd.intDocumentTypeID AND d.intEntityID = wt.intEntityID AND d.intPersonID = 0 AND d.intPersonRegistrationID = 0) ];
        }
        case 'PERSON' {
            $joinCondition .= qq[ (d.intDocumentTypeID = rd.intDocumentTypeID AND d.intPersonID = wt.intPersonID AND d.intPersonRegistrationID = 0) ];
        }
        else {
        }
    }

    my %TemplateData = ();

	my $entityID = getID($Data->{'clientValues'},$Data->{'clientValues'}{'currentLevel'});

    my $st = qq[
        SELECT
            rd.intWFRuleDocumentID,
            rd.intWFRuleID,
            rd.intDocumentTypeID,
            rd.intAllowProblemResolutionLevel,
            rd.intAllowVerify,
            tuf.intFileID,
            wt.intApprovalEntityID,
            wt.intProblemResolutionEntityID,
            dt.strDocumentName,
            d.strApprovalStatus,
            d.intDocumentID,
            pr.intNewBaseRecord
        FROM tblWFRuleDocuments AS rd
        INNER JOIN tblWFTask AS wt ON (wt.intWFRuleID = rd.intWFRuleID)
        LEFT JOIN tblPersonRegistration_$Data->{'Realm'} AS pr ON (pr.intPersonRegistrationID = wt.intPersonRegistrationID)
        LEFT JOIN tblDocuments AS d ON $joinCondition
        LEFT JOIN tblDocumentType dt ON (dt.intDocumentTypeID = rd.intDocumentTypeID )
        LEFT JOIN tblUploadedFiles tuf ON (tuf.intFileID = d.intUploadFileID)
        WHERE 
            wt.intWFTaskID = ?
            AND wt.intRealmID = ?
    ];

    my $q = $Data->{'db'}->prepare($st) or query_error($st);
	$q->execute(
        $dref->{'intWFTaskID'},
        $Data->{'Realm'},
        #$entityID,
        #$entityID,
	) or query_error($st);

	my @RelatedDocuments = ();
	my $rowCount = 0;
	  
    my %DocumentAction = (
        'target' => 'main.cgi',
        'WFTaskID' => $dref->{intWFTaskID} || 0,
        'client' => $Data->{client} || 0,
        'action' => 'WF_Verify',
    );

    my $count = 0;
    while(my $tdref = $q->fetchrow_hashref()) {
        $count++;
        my $displayVerify;
        my $displayAdd;
        my $displayView;
        my $viewLink = '';

        #warn "DOCUMENT TYPE ID " . $tdref->{'intDocumentTypeID'};
        if($tdref->{'intAllowProblemResolutionLevel'} eq 1 and $tdref->{'intAllowVerify'} == 1) {
            $displayVerify = $entityID == $tdref->{'intProblemResolutionEntityID'} ? 1 : 0;
        }
        elsif ($tdref->{'intApprovalEntityID'} == $entityID and $tdref->{'intAllowVerify'} == 1) {
            $displayVerify = 1;
        }

        if($tdref->{'intAllowProblemResolutionLevel'} eq 1 and $tdref->{'intAllowVerify'} == 1 and !$tdref->{'intDocumentID'}) {
            $displayAdd = $entityID == $tdref->{'intProblemResolutionEntityID'} ? 1 : 0;
        }
        elsif ($tdref->{'intApprovalEntityID'} == $entityID and $tdref->{'intAllowVerify'} == 1 and !$tdref->{'intDocumentID'}) {
            $displayAdd = 1;
        }

        if($tdref->{'intDocumentID'}) {
            $displayView = 1;
            $viewLink = qq[ <span style="position: relative" class="button-small generic-button"><a href="$Defs::base_url/viewfile.cgi?f=$tdref->{'intFileID'}" target="_blank">]. $Data->{'lang'}->txt('View') . q[</a></span>];
        }

        my %documents = (
            DocumentID => $tdref->{'intDocumentID'},
            Status => $tdref->{'strApprovalStatus'} || "MISSING",
            DocumentType => $tdref->{'strDocumentName'},
            Verifier => $tdref->{'strLocalName'},
            DisplayVerify => $displayVerify || '',
            DisplayAdd => $displayAdd || '',
            DisplayView => $displayView || '',
            viewLink => $viewLink,
            addLink => ''
        );

        push @RelatedDocuments, \%documents;
    }

    %TemplateData = (
        DocumentAction => \%DocumentAction,
        RelatedDocuments => \@RelatedDocuments,
    );

    return (\%TemplateData);

    my %DocumentData;
    my %fields = (
        title => '',
        templateFile => 'workflow/view/generic/document.templ',
    );

    return (\%DocumentData, \%fields);
}

sub populateRegoPaymentsViewData {
    my ($Data, $dref) = @_;

    my %TemplateData = ();

    my $st = qq[
        SELECT
            T.intQty,
            T.curAmount,
            P.strName as ProductName,
            P.strProductType as ProductType,
            T.intStatus,
            TL.intPaymentType
        FROM 
            tblTransactions as T 
            INNER JOIN tblProducts as P ON (P.intProductID=T.intProductID)
            LEFT JOIN tblTransLog as TL ON (TL.intLogID=T.intTransLogID)
        WHERE 
            T.intID = ?
            AND T.intTableType = ?
            AND T.intPersonRegistrationID = ?
    ];

    my $q = $Data->{'db'}->prepare($st) or query_error($st);
	$q->execute(
        $dref->{'intPersonID'},
        $Defs::LEVEL_PERSON,
        $dref->{'intPersonRegistrationID'},
	) or query_error($st);

	my @TXNs= ();
	my $rowCount = 0;
	  
    while(my $tdref = $q->fetchrow_hashref()) {
        my %row= (
            ProductName=> $tdref->{'ProductName'},
            ProductType=> $tdref->{'ProductType'},
            Amount=> $tdref->{'curAmount'},
            TXNStatus => $Defs::TransactionStatus{$tdref->{'intStatus'}},
            PaymentType=> $Defs::paymentTypes{$tdref->{'intPaymentType'}} || '-',
            Qty=> $tdref->{'intQty'},
        );
        push @TXNs, \%row;
    }

    %TemplateData = (
        TXNs=> \@TXNs,
        CurrencySymbol => $Data->{'SystemConfig'}{'DollarSymbol'} || "\$",
    );

    return (\%TemplateData);

}


sub populateTaskNotesViewData {
    my ($Data, $dref) = @_;

    my %TemplateData = ();

    my $st = qq[
        SELECT
            PN.intWFTaskID,
            PN.intTaskNoteID as parentNoteID,
            PN.strNotes as parentNote,
            PN.strType as parentNoteType,
            PN.tTimeStamp as parentTimeStamp,
            CN.intTaskNoteID as childNoteID,
            CN.strNotes as childNote,
            CN.strType as childNoteType,
            CN.tTimeStamp as childTimeStamp
        FROM
            tblWFTaskNotes AS PN
            LEFT JOIN tblWFTaskNotes AS CN ON (PN.intTaskNoteID = CN.intParentNoteID)
        WHERE
            PN.intWFTaskID = ?
            AND PN.intParentNoteID = 0
    ];

    my $q = $Data->{'db'}->prepare($st) or query_error($st);
	$q->execute(
        $dref->{'intWFTaskID'}
	) or query_error($st);

	my @TaskNotes = ();
	my $rowCount = 0;
	  
    while(my $tdref = $q->fetchrow_hashref()) {
        my %rowNotes = (
            ParentNote => $tdref->{'parentNote'},
            ParentNoteType => $tdref->{'parentNoteType'},
            ParentTimeStamp => $tdref->{'parentTimeStamp'},
            ChildNote => $tdref->{'childNote'},
            ChildNoteType => $tdref->{'childNoteType'},
            ChildTimeStamp => $tdref->{'childTimeStamp'},
        );
        push @TaskNotes, \%rowNotes;
    }

    print STDERR Dumper @TaskNotes;
    %TemplateData = (
        TaskNotes => \@TaskNotes,
    );

    return (\%TemplateData);

}

sub resetRelatedTasks {
    my ($Data, $WFTaskID, $status) = @_;

    my $st = qq[
        UPDATE
            tblWFTask AS WF
        INNER JOIN
            tblWFTask as PT ON (
                (PT.intPersonID = WF.intPersonID AND PT.intPersonRegistrationID = WF.intPersonRegistrationID AND PT.intWFTaskID != WF.intWFTaskID AND PT.strWFRuleFor = WF.strWFRuleFor AND WF.strWFRuleFor = 'REGO')
                OR
                (PT.intEntityID = WF.intEntityID AND PT.intPersonRegistrationID = 0 AND PT.intPersonID = 0 AND PT.intWFTaskID != WF.intWFTaskID AND PT.strWFRuleFor = WF.strWFRuleFor AND WF.strWFRuleFor = 'ENTITY')
                OR
                (PT.intPersonID = WF.intPersonID AND PT.intPersonRegistrationID = 0 AND PT.intWFTaskID != WF.intWFTaskID AND PT.strWFRuleFor = WF.strWFRuleFor AND WF.strWFRuleFor = 'PERSON')
                OR
                (PT.intDocumentID = WF.intDocumentID AND PT.intWFTaskID != WF.intWFTaskID AND PT.strWFRuleFor = WF.strWFRuleFor AND WF.strWFRuleFor = 'DOCUMENT')
            )
        INNER JOIN tblWFRule as R ON (R.intWFRuleID = WF.intWFRuleID)
        INNER JOIN tblWFRule as TR ON (PT.intWFRuleID = TR.intWFRuleID)
        SET
            PT.strTaskStatus = ?
        WHERE
            WF.intWFTaskID = ?
            AND WF.intRealmID = ?
            AND TR.intApprovalEntityLevel < R.intApprovalEntityLevel
    ];

    my $q = $Data->{'db'}->prepare($st) or query_error($st);
    $q->execute(
        $status,
        $WFTaskID,
        $Data->{'Realm'},
    ) or query_error($st);
}

sub viewSummaryPage {
    my ($Data) = @_;

    my $WFTaskID = safe_param('TID','number') || '';
    my $entityID = getID($Data->{'clientValues'},$Data->{'clientValues'}{'currentLevel'});

    my $task = getTask($Data, $WFTaskID);

    return (" ", "Access forbidden.") if($entityID != $task->{'intApprovalEntityID'});

    my %TemplateData;
    my $templateFile;

    my %TaskAction = (
        'WFTaskID' => $task->{intWFTaskID} || 0,
        'client' => $Data->{client} || 0,
    );

    $TemplateData{'TaskAction'} = \%TaskAction;

    switch($task->{'strWFRuleFor'}) {
        case 'REGO' {
            $templateFile = 'workflow/summary/personregistration.templ';
        }
        case 'ENTITY' {
            switch ($task->{'intEntityLevel'}) {
                case "$Defs::LEVEL_CLUB"  {
                    #TODO: add details specific to CLUB
                    $templateFile = 'workflow/summary/club.templ';
                }
                case "$Defs::LEVEL_VENUE" {
                    #TODO: add details specific to VENUE
                    $templateFile = 'workflow/summary/venue.templ';
                }
                else {
                
                }
            }
        }
        case 'PERSON' {
            $templateFile = 'workflow/summary/person.templ';
        }
        else {
            my ($TemplateData, $fields) = (undef, undef);
        }
    }

	my $body = runTemplate(
			$Data,
			\%TemplateData,
            $templateFile
	);
    
    return ($body, "Summary");

}

sub viewApprovalPage {
    my ($Data) = @_;

    #display page for now; details to be passed aren't finalised yet
    #use generic template for now

    my $WFTaskID = safe_param('TID','number') || '';

    my %TemplateData;

    my %TaskAction = (
        'WFTaskID' => $WFTaskID || 0,
        'client' => $Data->{client} || 0,
    );

    $TemplateData{'TaskAction'} = \%TaskAction;

	my $body = runTemplate(
        $Data,
        \%TemplateData,
        'workflow/result/page.templ'
	);
    
    return ($body, "Approval status:");
}

sub toggleTask {
    my ($Data) = @_;

    my $WFTaskID = safe_param('TID','number') || '';
    my $task = getTask($Data, $WFTaskID);
    my $currentToggle = safe_param('t', 'number') || 0;
    my $entityID = getID($Data->{'clientValues'},$Data->{'clientValues'}{'currentLevel'});

    #check if the task is assigned to
    #the current logged-in level
    #by this, only the current assignee can put the task on-hold
    if(($task->{'strTaskStatus'} eq 'ACTIVE' and $task->{'intApprovalEntityID'} == $entityID) or ($task->{'strTaskStatus'} eq 'REJECTED' and $task->{'intProblemResolutionEntityID'} == $entityID)) {

        if($currentToggle == $task->{'intOnHold'}) {
            my $st = qq[
                UPDATE
                    tblWFTask
                SET
                    intOnHold = IF(intOnHold = 1, 0, 1)
                WHERE
                    intWFTaskID = ?
            ];

            my $q = $Data->{'db'}->prepare($st);
            $q->execute(
                $WFTaskID
            ) or query_error($st);
        }

        return 1;
    }

    return 0;
}

sub checkRelatedTasks {
    my ($Data) = @_;

    my $WFTaskID = safe_param('TID','number') || '';
    my $st = qq[
        SELECT
            PT.intWFTaskID,
            PT.strTaskStatus
        FROM
            tblWFTask AS WF
        INNER JOIN
            tblWFTask as PT ON (
                (PT.intPersonID = WF.intPersonID AND PT.intPersonRegistrationID = WF.intPersonRegistrationID AND PT.strWFRuleFor = WF.strWFRuleFor AND WF.strWFRuleFor = 'REGO')
                OR
                (PT.intEntityID = WF.intEntityID AND PT.intPersonRegistrationID = 0 AND PT.intPersonID = 0 AND PT.strWFRuleFor = WF.strWFRuleFor AND WF.strWFRuleFor = 'ENTITY')
                OR
                (PT.intPersonID = WF.intPersonID AND PT.intPersonRegistrationID = 0 AND PT.strWFRuleFor = WF.strWFRuleFor AND WF.strWFRuleFor = 'PERSON')
                OR
                (PT.intDocumentID = WF.intDocumentID AND PT.strWFRuleFor = WF.strWFRuleFor AND WF.strWFRuleFor = 'DOCUMENT')
            )
        WHERE
            WF.intWFTaskID = ?
            AND WF.intRealmID = ?
    ];

    my $q = $Data->{'db'}->prepare($st);
    $q->execute(
        $WFTaskID,
        $Data->{'Realm'},
    ) or query_error($st);

    my $allComplete = 1;
    while(my $dref = $q->fetchrow_hashref()) {
        #continue if status = COMPLETE
        next if ($dref->{'strTaskStatus'} eq $Defs::WF_TASK_STATUS_COMPLETE);

        #flag that there are still tasks to be completed
        $allComplete = 0;
    }

    return $allComplete;
}

1;
