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
    populateVenueFieldsData
    resetRelatedTasks
    viewApprovalPage
    viewSummaryPage
    toggleTask
    checkRelatedTasks
    deleteRegoTransactions
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
use Documents;
use EntityDocuments;
use PersonRequest;
use CGI qw(param unescape escape redirect);
use AuditLog;
use NationalNumber;
use EmailNotifications::WorkFlow;
use EntityFields;
use EntityTypeRoles;
use JSON;
use Countries;
use HomePerson;
use PersonSummaryPanel;
use MinorProtection;
use PersonCertifications;
use EntitySummaryPanel;
use PersonEntity;

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
    my $error = '';

    my $emailNotification = new EmailNotifications::WorkFlow();

	if ( $action eq 'WF_updateAction' ) {
        my $query = new CGI;
        # this will now filter any actions based on type (HOLD, RESOLVE, REJECT) from modal
        # approve remains the same (WF_Approve)
        my $WFTaskID = safe_param('TID', 'number') || '';
        my $notes= safe_param('notes','words') || '';
        my $type = safe_param('type','words') || '';
        my $regNature = safe_param('regNat','words') || '';
        my %flashMessage;

        ($body, $title) = updateTaskNotes( $Data );
        switch($type) {
            case "$Defs::WF_TASK_ACTION_RESOLVE" {
                my $actionMessage = resolveTask($Data, $emailNotification);

                $flashMessage{'flash'}{'type'} = 'success';
                $flashMessage{'flash'}{'message'} = $actionMessage;

                setFlashMessage($Data, 'WF_U_FM', \%flashMessage);
                #$Data->{'RedirectTo'} = "$Defs::base_url/" . $Data->{'target'} . "?client=$Data->{'client'}&a=WF_";
                $Data->{'RedirectTo'} = "$Defs::base_url/" . $Data->{'target'} . "?client=$Data->{'client'}&a=WF_PR_S&TID=$WFTaskID";
                ($body, $title) = redirectTemplate($Data);
            }
            case "$Defs::WF_TASK_ACTION_REJECT" {
                my $actionMessage = rejectTask($Data, $emailNotification);

                #if($regNature eq $Defs::REGISTRATION_NATURE_TRANSFER){
                    #$Data->{'RedirectTo'} = "$Defs::base_url/" . $Data->{'target'} . "?client=$Data->{'client'}&a=WF_PR_R&TID=$WFTaskID";
                #}
                #else {
                    #$flashMessage{'flash'}{'type'} = 'success';
                    #$flashMessage{'flash'}{'message'} = $actionMessage;

                    #setFlashMessage($Data, 'WF_U_FM', \%flashMessage);

                    #$Data->{'RedirectTo'} = "$Defs::base_url/" . $Data->{'target'} . "?client=$Data->{'client'}&a=WF_View&TID=$WFTaskID";
                #}
                $Data->{'RedirectTo'} = "$Defs::base_url/" . $Data->{'target'} . "?client=$Data->{'client'}&a=WF_PR_R&TID=$WFTaskID";
                ($body, $title) = redirectTemplate($Data);
            }
            case "$Defs::WF_TASK_ACTION_HOLD" {
                my $res = holdTask($Data, $emailNotification);

                if($res){
                    $flashMessage{'flash'}{'type'} = 'success';
                    $flashMessage{'flash'}{'message'} = $Data->{'lang'}->txt('Task has been put on-hold.');
                }
                else {
                    $flashMessage{'flash'}{'type'} = 'success';
                    $flashMessage{'flash'}{'message'} = $Data->{'lang'}->txt('An error has been encountered.');
                }

                #if($regNature eq $Defs::REGISTRATION_NATURE_TRANSFER){
                    #$Data->{'RedirectTo'} = "$Defs::base_url/" . $Data->{'target'} . "?client=$Data->{'client'}&a=WF_PR_H&TID=$WFTaskID";
                #}
                #else {
                    #setFlashMessage($Data, 'WF_U_FM', \%flashMessage);
                #    $Data->{'RedirectTo'} = "$Defs::base_url/" . $Data->{'target'} . "?client=$Data->{'client'}&a=WF_View&TID=$WFTaskID";
                #}

                $Data->{'RedirectTo'} = "$Defs::base_url/" . $Data->{'target'} . "?client=$Data->{'client'}&a=WF_PR_H&TID=$WFTaskID";
                ($body, $title) = redirectTemplate($Data);
                #print $query->redirect("$Defs::base_url/" . $Data->{'target'} . "?client=$Data->{'client'}&a=WF_View&TID=$WFTaskID");
            }
        }
    }
	if ( $action eq 'WF_Approve' ) {
        ($body, $title, $error) = approveTask($Data, $emailNotification);

        if(!$error) {
            my $allComplete = checkRelatedTasks($Data);
            if($allComplete) {
                ( $body, $title ) = viewSummaryPage( $Data );
            }
            else {
                ( $body, $title ) = viewApprovalPage( $Data );
            }
        }
    }
    elsif ( $action eq 'WF_notesS' ) {
        ( $body, $title ) = updateTaskNotes( $Data );
    }
    elsif ( $action eq 'WF_Resolve' ) {
        resolveTask($Data, $emailNotification);
        ( $body, $title ) = addTaskNotes( $Data, $Defs::WF_TASK_ACTION_RESOLVE );
    }
    elsif ( $action eq 'WF_Reject' ) {
        rejectTask($Data, $emailNotification);
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
        my $res = toggleTask($Data, $emailNotification);
        if($res) {
            ( $body, $title ) = addTaskNotes( $Data, "TOGGLE" );
        }
        else {
            ( $body, $title ) = ("", "No access");
        }
    }
    elsif ( $action eq 'WF_Hold' ) {
        my $res = holdTask($Data, $emailNotification);
        if($res) {
            ( $body, $title ) = addTaskNotes( $Data, "HOLD" );
        }
        else {
            ( $body, $title ) = ("", "No access");
        }
    }
    elsif ($action eq 'WF_amd') {
        ($body, $title) = addMissingDocument($Data);
    }
    elsif ($action eq 'WF_PR_H' or $action eq 'WF_PR_R' or $action eq 'WF_PR_S') {
        ($body, $title) = updateTaskScreen($Data, $action);
    }
    elsif ($action eq 'WF_VNA') {
        ($body, $title) = viewNextAvailableTask($Data);
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
    my %taskCounts;

    my $cquery = new CGI;
    my $lastLoginTimeStamp = $cquery->cookie($Defs::COOKIE_LASTLOGIN_TIMESTAMP);

    $st = qq[
            SELECT
            t.intWFTaskID,
            t.strTaskStatus,
            t.strTaskType,
            pr.strPersonLevel,
            pr.strAgeLevel,
            pr.strSport,
            pr.strPersonType,
            t.strRegistrationNature,
            t.tTimeStamp AS taskDate,
            UNIX_TIMESTAMP(t.tTimeStamp) AS taskTimeStamp,
            dt.strDocumentName,
            p.intSystemStatus,
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
            t.intOnHold as OnHold,
            preqFrom.strLocalName as preqFromClub,
            preqTo.strLocalName as preqToClub
	    FROM tblWFTask AS t
                LEFT JOIN tblEntity as e ON (e.intEntityID = t.intEntityID)
		LEFT JOIN tblPersonRegistration_$Data->{'Realm'} AS pr ON (t.intPersonRegistrationID = pr.intPersonRegistrationID)
		LEFT JOIN tblPersonRequest AS preq ON (preq.intPersonRequestID = pr.intPersonRequestID)
		LEFT JOIN tblEntity AS preqFrom ON (preqFrom.intEntityID = preq.intRequestFromEntityID)
		LEFT JOIN tblEntity AS preqTo ON (preqTo.intEntityID = preq.intRequestToEntityID)
		LEFT JOIN tblPerson AS p ON (t.intPersonID = p.intPersonID)
		LEFT JOIN tblUserAuthRole AS uar ON ( t.intApprovalEntityID = uar.entityID )
		LEFT OUTER JOIN tblDocumentType AS dt ON (t.intDocumentTypeID = dt.intDocumentTypeID)
		LEFT JOIN tblUserAuthRole AS uarRejected ON ( t.intProblemResolutionEntityID = uarRejected.entityID )
		WHERE
                  t.intRealmID = $Data->{'Realm'}
		    AND (
                      (intApprovalEntityID = ? AND (t.strTaskStatus = 'ACTIVE' OR t.strTaskStatus = 'HOLD' OR t.strTaskStatus = 'REJECTED'))
                        OR
                      (intProblemResolutionEntityID = ? AND t.strTaskStatus = 'HOLD')
            )
    ];
    #OR
    #(intOnHold = 1 AND (intApprovalEntityID = ? OR intProblemResolutionEntityID = ?))

    #p.intSystemStatus != $Defs::PERSONSTATUS_POSSIBLE_DUPLICATE
    #AND


#print STDERR Dumper 'VALUE IS:' .$st;
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
    my @taskType = ();
    my @taskStatus = ();

	my $rowCount = 0;

    my $client = unescape($Data->{client});
    my $taskTypeLabel = "";
	while(my $dref= $q->fetchrow_hashref()) {
        #print STDERR Dumper $dref;
        my $newTask = ($dref->{'taskTimeStamp'} >= $lastLoginTimeStamp) ? 1 : 0; #additional check if tTimeStamp > currentTimeStamp
        $taskCounts{$dref->{'strTaskStatus'}}++;
        $taskCounts{$dref->{'strRegistrationNature'}}++;
        $taskCounts{"newTasks"}++ if $newTask;

        #FC-409 - don't include in list of taskStatus = REJECTED
        next if ($dref->{strTaskStatus} eq $Defs::WF_TASK_STATUS_REJECTED);

        #F-409 - skip if strTaskStatus = HOLD and approvalEntityID = current entity
        next if ($dref->{strTaskStatus} eq $Defs::WF_TASK_STATUS_HOLD and $dref->{'intApprovalEntityID'} == $entityID);

        #moved checking of POSSIBLE_DUPLICATE here (if included in query, tasks for ENTITY are not capture)
        next if ($dref->{intSystemStatus} eq $Defs::PERSONSTATUS_POSSIBLE_DUPLICATE and $dref->{strWFRuleFor} ne $Defs::WF_RULEFOR_PERSON);

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

        my $viewTaskURL = "$Data->{'target'}?client=$client&amp;a=WF_View&TID=$dref->{'intWFTaskID'}";
        my $taskTypeLabel = '';

        my $ruleForType = "";
        if($dref->{'strWFRuleFor'} eq "ENTITY" and $dref->{'intEntityLevel'} == $Defs::LEVEL_CLUB){
            $ruleForType = $dref->{'strRegistrationNature'} . "_CLUB";
        }
        elsif($dref->{'strWFRuleFor'} eq "ENTITY" and $dref->{'intEntityLevel'} == $Defs::LEVEL_VENUE) {
            $ruleForType = $dref->{'strRegistrationNature'} . "_VENUE";
        }
        elsif($dref->{'strWFRuleFor'} eq "REGO") {
            $ruleForType = $dref->{'strRegistrationNature'} . "_" . $dref->{'strPersonType'};
        }
        elsif($dref->{'strWFRuleFor'} eq "PERSON") {
            $ruleForType = $dref->{'strRegistrationNature'} . "_PERSON";
        }

        print STDERR Dumper "RULE FOR TYPE " . $ruleForType;

	 my %single_row = (
			WFTaskID => $dref->{intWFTaskID},
            TaskDescription => $taskDescription,
			TaskType => $dref->{strTaskType},
			TaskNotes=> $dref->{TaskNotes},
			AgeLevel => $dref->{strAgeLevel},
			RuleFor=> $dref->{strWFRuleFor},
			RegistrationNature => $dref->{strRegistrationNature},
			RegistrationNatureLabel => $Defs::workTaskTypeLabel{$ruleForType},
			DocumentName => $dref->{strDocumentName},
            Name=>$name,
			LocalEntityName=> $dref->{EntityLocalName},
			LocalFirstname => $dref->{strLocalFirstname},
			LocalSurname => $dref->{strLocalSurname},
			PersonID => $dref->{intPersonID},
			TaskStatus => $dref->{strTaskStatus},
			TaskStatusLabel => $Defs::wfTaskStatus{$dref->{strTaskStatus}},
            viewURL => $viewURL,
            showReject => $showReject,
            showApprove => $showApprove,
            showResolve => $showResolve,
            showView => $showView,
            OnHold => $dref->{OnHold},
            taskDate => $dref->{taskDate},
            viewURL => $viewTaskURL,
            taskTypeLabel => $viewTaskURL,
            RequestFromClub => $dref->{'preqFromClub'},
            RequestToClub => $dref->{'preqToClub'},
            taskTimeStamp => $dref->{'taskTimeStamp'},
            newTask => $newTask,
		);
        #print STDERR Dumper \%single_row;
   
        if(!($Defs::workTaskTypeLabel{$ruleForType} ~~ @taskType)){
            push @taskType, $Defs::workTaskTypeLabel{$ruleForType};
        }

        if(!($Defs::wfTaskStatus{$dref->{strTaskStatus}} ~~ @taskStatus)){
            push @taskStatus, $Defs::wfTaskStatus{$dref->{strTaskStatus}};
        }

		push @TaskList, \%single_row;
	}


    ## Calc Dupl Res and Pending Clr here
    my $clrCount = 0; #getClrTaskCount($Data, $entityID);
    my $dupCount = 0; #Duplicates::getDupTaskCount($Data, $entityID);
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


    my %reqFilters = (
        'entityID' => $entityID
    );

    my $personRequests = getRequests($Data, \%reqFilters);

    if(scalar @{$personRequests}) {

        for my $request (@{$personRequests}) {
            next if (
                $request->{'strRequestStatus'} eq $Defs::PERSON_REQUEST_STATUS_COMPLETED
                or $request->{'strRequestStatus'} eq $Defs::PERSON_REQUEST_STATUS_REJECTED
                or $request->{'strRequestStatus'} eq $Defs::PERSON_REQUEST_STATUS_DENIED
                or $request->{'personRegoStatus'} eq $Defs::PERSONREGO_STATUS_PENDING
            );
            $rowCount++;
            my $name = formatPersonName($Data, $request->{'strLocalFirstname'}, $request->{'strLocalSurname'}, $request->{'intGender'});
            my $viewURL = "$Data->{'target'}?client=$client&amp;a=PRA_V&rid=$request->{'intPersonRequestID'}";

            my $requestStatus = $request->{'strRequestResponse'} ? $request->{'strRequestResponse'} : 'PENDING';
            $taskCounts{$requestStatus}++;
            $taskCounts{$request->{'strRequestType'}}++;

            my $newTask = ($request->{'prRequestUpdateTimeStamp'} >= $lastLoginTimeStamp) ? 1 : 0; #additional check if tTimeStamp > currentTimeStamp
            $taskCounts{"newTasks"}++ if $newTask;

            my $taskStatusLabel = $request->{'strRequestResponse'} ? $Defs::personRequestStatus{$request->{'strRequestResponse'}} : $Defs::personRequestStatus{'PENDING'};
            my %personRequest = (
                personRequestLabel => $Defs::personRequest{$request->{'strRequestType'}},
                TaskType => $request->{'strRequestType'},
                TaskDescription => $Data->{'lang'}->txt('Person Request'),
                Name => $name,
                TaskStatus => $request->{'strRequestResponse'} ? $request->{'strRequestResponse'} : 'PENDING',
                TaskStatusLabel => $taskStatusLabel,
                viewURL => $viewURL,
                showView => 1,
                taskDate => $request->{'dtDateRequest'},
                requestFrom => $request->{'requestFrom'},
                requestTo => $request->{'requestTo'},
                taskTimeStamp => $request->{'prRequestUpdateTimeStamp'},
                currentClubView => $entityID == $request->{'intRequestToEntityID'} ? 1 : 0,
                newTask => $newTask,
            );

            if(!($Defs::personRequest{$request->{'strRequestType'}} ~~ @taskType)){
                push @taskType, $Defs::personRequest{$request->{'strRequestType'}};
            }

            if(!($taskStatusLabel ~~ @taskStatus)){
                push @taskStatus, $taskStatusLabel;
            }

            push @TaskList, \%personRequest;
        }

    }

    my @sortedTaskList = sort { $b->{'taskTimeStamp'} <=> $a->{'taskTimeStamp'}} @TaskList;
	my $msg = '';
	if ($rowCount == 0) {
		$msg = $Data->{'lang'}->txt('No outstanding tasks');
	}
	else {
		$msg = $Data->{'lang'}->txt('The following are the outstanding tasks to be authorised');
	};


    my %taskFilters = (
        'type' => \@taskType,
        'status' => \@taskStatus,
    );
	my %TemplateData = (
        #TaskList => \@TaskList,
        MA_allowTransfer => $Data->{'SystemConfig'}{'MA_allowTransfer'} || 0,
        TaskList => \@sortedTaskList,
        CurrentLevel => $Data->{'clientValues'}{'currentLevel'},
        TaskCounts => \%taskCounts,
        TaskMsg => $msg,
        TaskEntityID => $entityID,
        TaskFilters => \%taskFilters,
        client => $Data->{client},
	);

    my $flashMessage = getFlashMessage($Data, 'WF_U_FM');
    $TemplateData{'FlashMessage'} = $flashMessage;

	$body = runTemplate(
			$Data,
			\%TemplateData,
			'dashboards/worktasks.templ',
	);

	

	return($body,$Data->{'lang'}->txt('Dashboard'));
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
        )
		WHERE e.intEntityID= ?
            AND r.strWFRuleFor = 'ENTITY'
            AND r.intRealmID = ?
            AND r.intSubRealmID IN (0, ?)
            AND r.intOriginLevel = ?
			AND r.strRegistrationNature = ?
		];
        #AND e.strEntityType = r.strEntityType
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


    my $emailNotification = new EmailNotifications::WorkFlow();

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

        $emailNotification->setRealmID($Data->{'Realm'});
        $emailNotification->setSubRealmID(0);
        $emailNotification->setToEntityID($approvalEntityID);
        $emailNotification->setFromEntityID($problemEntityID);
        $emailNotification->setDefsEmail($Defs::admin_email); #if set, this will be used instead of toEntityID
        $emailNotification->setDefsName($Defs::admin_email_name);
        $emailNotification->setNotificationType($Defs::NOTIFICATION_WFTASK_ADDED);
        $emailNotification->setSubject("Work Task ID ");
        $emailNotification->setLang($Data->{'lang'});
        $emailNotification->setDbh($Data->{'db'});

        my $emailTemplate = $emailNotification->initialiseTemplate()->retrieve();
        $emailNotification->send($emailTemplate) if $emailTemplate->getConfig('toEntityNotification') == 1;

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
        $emailNotification
    ) = @_;

	my $st = '';
	my $q = '';
	my $db=$Data->{'db'};

	#Get values from the QS
    my $WFTaskID = safe_param('TID','number') || '';

    my $task = getTask($Data, $WFTaskID);
    my $sysConfigApprovalLockPaymentRequired = $Data->{'SystemConfig'}{'lockApproval_PaymentRequired_' . $task->{'sysConfigApprovalLockRuleFor'}};
    my $error = 0;
    my $response;
    my $errorStr;

    #NOTE if new approval check needs to be done, just add another condition here (increment error, concat $response)
    if($sysConfigApprovalLockPaymentRequired and $task->{'paymentRequired'}){
        $errorStr = $Data->{'lang'}->txt("ERROR: Payment required."); 
        $response = qq [
            <span>$errorStr</span><br/>
        ];
        $error++;
    }

    return ($response, "Work Task Approval Result", $error) if $error gt 0;


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
  	    ####
  	    auditLog($WFTaskID, $Data, 'Updated WFTask', 'WFTask');
  	    ###
        setDocumentStatus($Data, $WFTaskID, 'APPROVED');
	    if ($q->errstr) {
	    	return $q->errstr . '<br>' . $st
	    }

        if($emailNotification) {
            $emailNotification->setRealmID($Data->{'Realm'});
            $emailNotification->setSubRealmID(0);
            $emailNotification->setToEntityID($task->{'intProblemResolutionEntityID'});
            $emailNotification->setFromEntityID($task->{'intApprovalEntityID'});
            $emailNotification->setDefsEmail($Defs::admin_email);
            $emailNotification->setDefsName($Defs::admin_email_name);
            $emailNotification->setNotificationType($Defs::NOTIFICATION_WFTASK_APPROVED);
            $emailNotification->setSubject("Work Task ID " . $WFTaskID);
            $emailNotification->setLang($Data->{'lang'});
            $emailNotification->setDbh($Data->{'db'});

            my $emailTemplate = $emailNotification->initialiseTemplate()->retrieve();
            #$emailNotification->send($emailTemplate) if $emailTemplate->getConfig('toEntityNotification') == 1;
        }

    $st = qq[
        SELECT
            wft.intPersonID,
            wft.intPersonRegistrationID,
            wft.intEntityID,
            wft.intDocumentID,
            wft.intDocumentTypeID,
            wft.strTaskType,
            wft.strWFRuleFor,
            wft.strRegistrationNature,
            pr.intPersonRegistrationID,
            pr.intEntityID as personRegoEntityID,
            pr.intPersonRequestID
        FROM
            tblWFTask wft
        LEFT JOIN
            tblPersonRegistration_$Data->{'Realm'} as pr ON (pr.intPersonRegistrationID = wft.intPersonRegistrationID)
        WHERE wft.intWFTaskID = ?
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
    my $registrationNature = $dref->{'strRegistrationNature'} || '';
    my $personRequestID = $dref->{'intPersonRequestID'} || '';
    my $personRegoEntityID = $dref->{'personRegoEntityID'} || '';

    if($registrationNature eq $Defs::REGISTRATION_NATURE_TRANSFER) {
        #check for pending tasks?

        my $allComplete = checkRelatedTasks($Data);
        if($Data->{'clientValues'}{'currentLevel'} eq $Defs::LEVEL_NATIONAL) {
            PersonRequest::finaliseTransfer($Data, $personRequestID);
            PersonRequest::setRequestStatus($Data, $personRequestID, $Defs::PERSON_REQUEST_STATUS_COMPLETED);
        }
        elsif ($allComplete) {
            PersonRequest::finaliseTransfer($Data, $personRequestID);
            PersonRequest::setRequestStatus($Data, $personRequestID, $Defs::PERSON_REQUEST_STATUS_COMPLETED);
        }
    }

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
		####
  	    auditLog('', $Data, 'Updated WFTask', 'WFTask');
      	###

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
                        strStatus = 'ACTIVE'
                    WHERE
                        intEntityID= ?
                ];

                $q = $db->prepare($st);
                $q->execute(
                    $entityID
                    );
                $rc = 1;
                $Data->{'cache'}->delete('swm','EntityObj-'.$entityID) if $Data->{'cache'};
                assignNationalNumber(
                    $Data,
                    'ENTITY',
                    $entityID,
                );
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
         if (!$rowCount and $personID and $taskType ne $Defs::WF_TASK_TYPE_CHECKDUPL)  {
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
                $Data->{'cache'}->delete('swm','PersonObj-'.$personID) if $Data->{'cache'};
                if ($personRegistrationID)  {
                    assignNationalNumber(
                        $Data,
                        'PERSON',
                        $personID,
                        $personRegistrationID,
                    );
                }

        	#}
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
                        dtLastUpdated=NOW(),
                        dtApproved=NOW(),
                        dtFrom = NOW()
	    	        WHERE
                        PR.intPersonRegistrationID = ?
                        AND PR.strStatus IN ('PENDING', 'INPROGRESS')
	        	];
                        #dtTo = IF (dtFrom>dtTo, dtFrom, dtTo)
                        #dtFrom = IF (dtFrom<NOW(), NOW(), dtFrom),
                        #AND strStatus NOT IN ('SUSPENDED', 'TRANSFERRED', 'DELETED')

		        $q = $db->prepare($st);
		        $q->execute(
		       		$personRegistrationID
		  			);
	        	$rc = 1;	# All registration tasks have been completed
                PersonRegistration::rolloverExistingPersonRegistrations($Data, $personID, $personRegistrationID);
				# Do the check
				$st = qq[SELECT * FROM tblPersonRegistration_$Data->{Realm} WHERE intPersonRegistrationID = ?];
                my $qPR = $db->prepare($st);
				$qPR->execute($personRegistrationID);
				my $ppref = $qPR->fetchrow_hashref();
#                if ($ppref->{'strRegistrationNature'} eq $Defs::REGISTRATION_NATURE_NEW)    {
                {
                    my %PE = ();
                    $PE{'personType'} = $ppref->{'strPersonType'} || '';
                    $PE{'personLevel'} = $ppref->{'strPersonLevel'} || '';
                    $PE{'personEntityRole'} = $ppref->{'strPersonEntityRole'} || '';
                    $PE{'sport'} = $ppref->{'strSport'} || '';
                    
                    my $peID = doesOpenPEExist($Data, $personID, $ppref->{'intEntityID'}, \%PE);
                    addPERecord($Data, $personID, $ppref->{'intEntityID'}, \%PE) if (! $peID);
                }
                # if check  pass call save
                if($ppref->{'strPersonType'} eq 'PLAYER' and $Data->{'SystemConfig'}{'cleanPlayerPersonRecords'}) {
                    PersonRegistration::cleanPlayerPersonRegistrations($Data, $personID, $personRegistrationID);
                }
    
                if( ($ppref->{'strPersonType'} eq 'PLAYER') && ($ppref->{'strSport'} eq 'FOOTBALL'))    {
                	savePlayerPassport($Data, $personID);
                }
           ##############################################################################################################
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
    my $targetAction = "";
    my $targetTemplate = "",

    #identify type of action (rejection or resolution based on intApprovalEntityID and intProblemResolutionID)
    my $entityID = getID($Data->{'clientValues'},$Data->{'clientValues'}{'currentLevel'});
    #my $type = ($entityID == $task->{'intApprovalEntityID'}) ? 'REJECT' : ($entityID == $task->{'intProblemResolutionEntityID'}) ? 'RESOLVE' : '';
    my $WFRejectCurrentNoteID = $task->{'rejectTaskNoteID'} || 0;
    my $WFToggleCurrentNoteID = $task->{'toggleTaskNoteID'} || 0;
    my $WFHoldCurrentNoteID = $task->{'holdTaskNoteID'} || 0;
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
       #####
       auditLog($q->{mysql_insertid},$Data,'New TaskNote','WFTaskNotes');
       ####

       $targetAction = "WF_View";
    }
    elsif (($entityID == $task->{'intProblemResolutionEntityID'}) and ($type eq $Defs::WF_TASK_ACTION_RESOLVE)) { #resolve

        #check if there's a current rejection note
        #if exists, update it with intCurrent = 0 then insert new record,
        #otherwise do nothing (to prevent duplicate entries and un-mapped notes)
        #if($WFRejectCurrentNoteID and $task->{'rejectCurrent'} == 1) {
        if($WFHoldCurrentNoteID and $task->{'holdCurrent'} == 1) {
            my $q = $Data->{'db'}->prepare($st);
            $q->execute(
                0,
                #$WFRejectCurrentNoteID,
                $WFHoldCurrentNoteID,
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
                #$WFRejectCurrentNoteID
                $WFHoldCurrentNoteID
            ) or query_error($streset);

        }

        $targetAction = "WF_List";
        $targetTemplate = "dashboards/worktasks.templ";
    }
    elsif ($type eq "TOGGLE") {
        #check intOnHold
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
    elsif ($type eq "HOLD") {
        if($task->{'strTaskStatus'} eq $Defs::WF_TASK_STATUS_ACTIVE) {
            #put on-hold
            #WFToggleCurrentNoteID as bind param
            #to prevent duplicate entry
            my $q = $Data->{'db'}->prepare($st);
            $q->execute(
                $WFHoldCurrentNoteID,
                0,
                $WFTaskID,
                $notes,
                1,
                $Defs::WF_TASK_ACTION_HOLD
            );
        }

       $targetAction = "WF_View";
       $targetTemplate = "workflow/view/personregistration.templ";
    }

    my %TemplateData = (
        TID=> $WFTaskID,
        MA_allowTransfer => $Data->{'SystemConfig'}{'MA_allowTransfer'} || 0,
        Lang => $Data->{'lang'},
        TaskNotes=> $notes,
        client => $Data->{client},
        target=>$Data->{'target'},
        #action => 'WF_list',
        action => $targetAction,
        #PersonSummary => personSummaryPanel($Data, $personID) || '',
    );

warn("OO");

    $TemplateData{'Notifications'}{'actionResult'} = "ID: $WFTaskID " . $Data->{'lang'}->txt("Work Flow task updated.");

	my $body = runTemplate(
        $Data,
        \%TemplateData,
        $targetTemplate,
	);

    return ($body, $title);

}

sub setPersonRegoStatus  {

    my ($Data, $taskID, $status) = @_;
    #my $prevStatus = ($status eq $Defs::WF_TASK_STATUS_PENDING) ? $Defs::WF_TASK_STATUS_REJECTED : $Defs::WF_TASK_STATUS_PENDING;
    my $prevStatus = ($status eq $Defs::WF_TASK_STATUS_PENDING) ? $Defs::WF_TASK_STATUS_HOLD : $Defs::WF_TASK_STATUS_PENDING;

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
    #my $prevStatus = ($status eq $Defs::WF_TASK_STATUS_PENDING) ? $Defs::WF_TASK_STATUS_REJECTED : $Defs::WF_TASK_STATUS_PENDING;
    my $prevStatus = ($status eq $Defs::WF_TASK_STATUS_PENDING) ? $Defs::WF_TASK_STATUS_HOLD : $Defs::WF_TASK_STATUS_PENDING;

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

    #my $WFTaskID = safe_param('TID','number') || '';
    #my $documentID = safe_param('did','number') || '';
	my  $documentID = safe_param('f','number') || 0;
	my $documentStatus = param('status') || '';
	if($documentID){
    	my $st = qq[
        	UPDATE tblDocuments
        	SET
        	    strApprovalStatus = ?
        	WHERE
        		intUploadFileID = ?
    	];

    	my $q = $Data->{'db'}->prepare($st);
    	$q->execute(
			$documentStatus,
        	$documentID
    	);		
	}

}

sub addTaskNotes    {

    my( $Data, $noteType) = @_;

    my $WFTaskID = safe_param('TID','number') || '';
    my $WFCurrentNoteID = safe_param('NID','number') || '';

    my $lang = $Data->{'lang'};
    my $title = $lang->txt('Work task Notes');

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
        $emailNotification
    ) = @_;

	my $st = '';
	my $q = '';
	my $db=$Data->{'db'};

	#Get values from the QS
    my $WFTaskID = safe_param('TID','number') || '';

    #FC-144 get current task based on taskid param
    my $task = getTask($Data, $WFTaskID);

    return if (!$task or ($task eq undef));

    #if($task->{strWFRuleFor} eq 'ENTITY') {
    #    #setEntityStatus($Data, $WFTaskID, $Defs::WF_TASK_STATUS_REJECTED);
    #    #setEntityStatus($Data, $WFTaskID, $Defs::WF_TASK_STATUS_HOLD);
    #}

    #if($task->{strWFRuleFor} eq 'REGO') {
    #    #setPersonRegoStatus($Data, $WFTaskID, $Defs::WF_TASK_STATUS_REJECTED);
    #    #setPersonRegoStatus($Data, $WFTaskID, $Defs::WF_TASK_STATUS_HOLD);
    #}


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
    ####
  	auditLog($WFTaskID, $Data, 'Updated WFTask', 'WFTask');
  	###

    if($emailNotification) {
        $emailNotification->setRealmID($Data->{'Realm'});
        $emailNotification->setSubRealmID(0);
        $emailNotification->setToEntityID($task->{'intApprovalEntityID'});
        $emailNotification->setFromEntityID($task->{'intProblemResolutionEntityID'});
        $emailNotification->setDefsEmail($Defs::admin_email);
        $emailNotification->setDefsName($Defs::admin_email_name);
        $emailNotification->setNotificationType($Defs::NOTIFICATION_WFTASK_RESOLVED);
        $emailNotification->setSubject("Work Task ID " . $WFTaskID);
        $emailNotification->setLang($Data->{'lang'});
        $emailNotification->setDbh($Data->{'db'});

        my $emailTemplate = $emailNotification->initialiseTemplate()->retrieve();
        $emailNotification->send($emailTemplate) if $emailTemplate->getConfig('toEntityNotification') == 1;
    }

    return getNotificationMessage($Data, $task, 'RESOLVE');
}

sub rejectTask {
    my(
        $Data,
        $emailNotification
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
        my ($result) = deleteRegoTransactions($Data, $task);
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

    resetRelatedTasks($Data, $WFTaskID, 'REJECTED');

    if ($q->errstr) {
		return $q->errstr . '<br>' . $st
	}
    ####
  	auditLog($WFTaskID, $Data, 'Updated WFTask', 'WFTask');
  	###

    if($emailNotification) {
        $emailNotification->setRealmID($Data->{'Realm'});
        $emailNotification->setSubRealmID(0);
        $emailNotification->setToEntityID($task->{'intProblemResolutionEntityID'});
        $emailNotification->setFromEntityID($task->{'intApprovalEntityID'});
        $emailNotification->setDefsEmail($Defs::admin_email);
        $emailNotification->setDefsName($Defs::admin_email_name);
        $emailNotification->setNotificationType($Defs::NOTIFICATION_WFTASK_REJECTED);
        $emailNotification->setSubject("Work Task ID " . $WFTaskID);
        $emailNotification->setLang($Data->{'lang'});
        $emailNotification->setDbh($Data->{'db'});

        my $emailTemplate = $emailNotification->initialiseTemplate()->retrieve();
        $emailNotification->send($emailTemplate) if $emailTemplate->getConfig('toEntityNotification') == 1;
    }

    if($task->{'strRegistrationNature'} eq $Defs::REGISTRATION_NATURE_TRANSFER) {
        #check for pending tasks?

        if($Data->{'clientValues'}{'currentLevel'} eq $Defs::LEVEL_NATIONAL) {
            PersonRequest::setRequestStatus($Data, $task->{'intPersonRequestID'}, $Defs::PERSON_REQUEST_STATUS_REJECTED);
        }
    }

    return getNotificationMessage($Data, $task, 'REJECT');
    #return(0);

}

sub getNotificationMessage {
    my ($Data, $task, $type) = @_;

    my $message;
    my $notifPrefix;

    switch($type) {
        case 'REJECT' {
            $message = $Data->{'lang'}->txt("has been rejected.");
        }
        case 'RESOLVE' {
            $message = $Data->{'lang'}->txt("Task has been resolved.");
            return $message;
        }
    }

    if($task->{'strWFRuleFor'} eq "ENTITY" and $task->{'intEntityLevel'} == $Defs::LEVEL_CLUB){
        $notifPrefix = $Defs::workTaskTypeLabel{$task->{'strRegistrationNature'} . "_CLUB"};
    }
    elsif($task->{'strWFRuleFor'} eq "ENTITY" and $task->{'intEntityLevel'} == $Defs::LEVEL_VENUE) {
        $notifPrefix = $Defs::workTaskTypeLabel{$task->{'strRegistrationNature'} . "_VENUE"};
    }
    elsif($task->{'strWFRuleFor'} eq "REGO") {
        $notifPrefix = $Defs::workTaskTypeLabel{$task->{'strRegistrationNature'} . "_" . $task->{'strPersonType'}};
    }

    return $notifPrefix . " " . $message;
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
            t.intPersonID,
            t.strWFRuleFor,
            t.strTaskStatus,
            t.intOnHold,
            t.strRegistrationNature,
            e.*,
            IF(t.strWFRuleFor = 'ENTITY', IF(e.intEntityLevel = -47, 'VENUE', IF(e.intEntityLevel = 3, 'CLUB', '')), IF(t.strWFRuleFor = 'REGO', 'REGO', ''))as sysConfigApprovalLockRuleFor,
            IF(t.strWFRuleFor = 'ENTITY', e.intPaymentRequired, IF(t.strWFRuleFor = 'REGO', pr.intPaymentRequired, 0)) as paymentRequired,
            pr.intPersonRegistrationID,
            pr.strPersonType,
            pr.strAgeLevel,
            pr.strPersonEntityRole,
            pr.strSport,
            pr.strPersonLevel,
            pr.intPersonRequestID,
            NP.dtFrom as NPdtFrom,
            NP.dtTo as NPdtTo,
            DATE_FORMAT(NP.dtFrom,'%d %b %Y') AS dtFromOld,
            DATE_FORMAT(NP.dtTo,'%d %b %Y') AS dtToOld,
            etr.strEntityRoleName,
            p.strLocalFirstname,
            p.strLocalSurname,
            p.strISONationality,
            p.intGender,
            p.strNationalNum,
            p.strStatus as personStatus,
            DATE_FORMAT(p.dtDOB, "%d/%m/%Y") as DOB,
            TIMESTAMPDIFF(YEAR, p.dtDOB, CURDATE()) as currentAge,
            rnt.intTaskNoteID as rejectTaskNoteID,
            rnt.intCurrent as rejectCurrent,
            tnt.intTaskNoteID as holdTaskNoteID,
            pre.strLocalName as registerToEntity,
            tnt.intCurrent as holdCurrent
        FROM
            tblWFTask t
        LEFT JOIN tblWFTaskNotes rnt ON (t.intWFTaskID = rnt.intWFTaskID AND rnt.strType = "REJECT" AND rnt.intCurrent = 1)
        LEFT JOIN tblWFTaskNotes tnt ON (t.intWFTaskID = tnt.intWFTaskID AND tnt.strType = "HOLD" AND tnt.intCurrent = 1)
        LEFT JOIN tblEntity e ON (t.intEntityID = e.intEntityID)
        LEFT JOIN tblPersonRegistration_$Data->{'Realm'} AS pr ON (pr.intPersonRegistrationID = t.intPersonRegistrationID)
        LEFT JOIN tblPerson AS p ON (t.intPersonID = p.intPersonID)
        LEFT JOIN tblEntity AS pre ON (pre.intEntityID = pr.intEntityID)
        LEFT JOIN tblEntityTypeRoles AS etr ON (etr.strPersonType = pr.strPersonType AND etr.strEntityRoleKey = pr.strPersonEntityRole)
        LEFT JOIN tblNationalPeriod as NP ON (NP.intNationalPeriodID = pr.intNationalPeriodID)
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
    return $result || undef;
}

sub viewTask {
    my ($Data, $WFTID) = @_;

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

    my $WFTaskID = safe_param('TID','number') || $WFTID || '';
    my $entityID = getID($Data->{'clientValues'},$Data->{'clientValues'}{'currentLevel'});

    my $st;

    $st = qq[
        SELECT
            t.intWFTaskID,
            t.intWFRuleID,
            t.strTaskStatus,
            t.strTaskType,
            t.intOnHold,
            pr.intPersonRegistrationID,
            pr.strStatus as personRegistrationStatus,
            pr.strPersonLevel,
            pr.strAgeLevel,
            pr.strSport,
            pr.strPersonType,
            pr.strPersonEntityRole,
            pr.intOriginLevel,
            pr.intPaymentRequired as regoPaymentRequired,
            pr.intPersonRequestID,
            NP.dtFrom as NPdtFrom,
            NP.dtTo as NPdtTo,
            DATE_FORMAT(NP.dtFrom,'%d %b %Y') AS NPdtFromold,
            DATE_FORMAT(NP.dtTo,'%d %b %Y') AS NPdtToold,
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
            p.intLocalLanguage,
            p.strRegionOfBirth,
            p.strSuburb,
            p.strState,
            p.strISOCountry,
            p.strPhoneHome,
            p.strEmail,
            p.intMinorProtection,
            p.dtSuspendedUntil,
            p.strISOCountryOfBirth,
            p.strISONationality,
            TIMESTAMPDIFF(YEAR, p.dtDOB, CURDATE()) as currentAge,
            p.intGender as PersonGender,
            p.intInternationalTransfer as InternationalTransfer,
            e.strLocalName as EntityLocalName,
            p.intPersonID,
            p.strNationalNum,
            t.strTaskStatus,
            t.strWFRuleFor,
            uar.entityID as UserEntityID,
            uarRejected.entityID as UserRejectedEntityID,
            e.intEntityID,
            e.intEntityLevel,
            e.intPaymentRequired as entityPaymentRequired,
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
            tn.intTaskNoteID as currentNoteID,
	    rl.intApprovalEntityLevel as ApprovalEntityLevel,
            rl.intWFRuleID as RuleID
        FROM tblWFTask AS t
        LEFT JOIN tblWFRule as rl ON (t.intWFRuleID = rl.intWFRuleID)
        LEFT JOIN tblEntity as e ON (e.intEntityID = t.intEntityID)
        LEFT JOIN tblPersonRegistration_$Data->{'Realm'} AS pr ON (t.intPersonRegistrationID = pr.intPersonRegistrationID)
        LEFT JOIN tblPerson AS p ON (t.intPersonID = p.intPersonID)
        LEFT JOIN tblUserAuthRole AS uar ON ( t.intApprovalEntityID = uar.entityID )
        LEFT JOIN tblUserAuthRole AS uarRejected ON ( t.intProblemResolutionEntityID = uarRejected.entityID )
        LEFT JOIN tblDocuments as dPersonRego ON (t.intPersonID = dPersonRego.intPersonID AND t.intPersonRegistrationID = dPersonRego.intPersonRegistrationID)
        LEFT JOIN tblUploadedFiles as uf ON (dPersonRego.intUploadFileID = uf.intFileID)
        LEFT JOIN tblDocumentType as dt ON (dPersonRego.intDocumentTypeID = dt.intDocumentTypeID)
        LEFT JOIN tblWFTaskNotes as tn ON (tn.intWFTaskID = t.intWFTaskID AND tn.intCurrent = 1)
        LEFT JOIN tblNationalPeriod as NP ON (NP.intNationalPeriodID = pr.intNationalPeriodID)
        WHERE
            t.intRealmID = $Data->{'Realm'}
            AND t.intWFTaskID = ?
            AND (
                (intApprovalEntityID = ? AND (t.strTaskStatus = 'ACTIVE' or t.strTaskStatus = 'HOLD' or t.strTaskStatus = 'REJECTED'))
                OR
                (intProblemResolutionEntityID = ? AND t.strTaskStatus = 'HOLD')
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

    if(!$dref) {
        return (undef, "ERROR: no data retrieved/no access.");
    }


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

    my $showHold = 0;
    #make sure only the current assignee can put on hold or resume the task
    $showHold = 1
        if ($dref->{'strTaskStatus'} eq $Defs::WF_TASK_STATUS_ACTIVE and $dref->{'intApprovalEntityID'} and $dref->{'intApprovalEntityID'} == $entityID);

    my $showReject = 0;
    #$showReject = 1 if ($dref->{'intOnHold'} == 0 and $dref->{'intProblemResolutionEntityID'} and $dref->{'intProblemResolutionEntityID'} != $entityID);
    $showReject = 1 if (
        ($dref->{'strTaskStatus'} eq $Defs::WF_TASK_STATUS_ACTIVE and $dref->{'intProblemResolutionEntityID'} and $dref->{'intProblemResolutionEntityID'} != $entityID)
        or
        ($dref->{'strTaskStatus'} eq $Defs::WF_TASK_STATUS_ACTIVE and $dref->{'intProblemResolutionEntityID'} eq $dref->{'intApprovalEntityID'})
    );

    my $showApprove = 0;
    #$showApprove = 1 if ($dref->{'intOnHold'} == 0 and $dref->{'intApprovalEntityID'} and $dref->{'intApprovalEntityID'} == $entityID and !scalar($TemplateData{'Notifications'}{'LockApproval'}));
    $showApprove = 1 if (($dref->{'strTaskStatus'} eq $Defs::WF_TASK_STATUS_ACTIVE) and $dref->{'intApprovalEntityID'} and $dref->{'intApprovalEntityID'} == $entityID and !scalar($TemplateData{'Notifications'}{'LockApproval'}));

    my $showResolve = 0;
    $showResolve = 1 if ($dref->{'strTaskStatus'} eq $Defs::WF_TASK_STATUS_HOLD and $dref->{'intProblemResolutionEntityID'} and $dref->{'intProblemResolutionEntityID'} == $entityID);

    my ($showAddFields, $showEditFields) = (0, 0);
    $showAddFields = 1  if ($dref->{'intEntityLevel'} == $Defs::LEVEL_VENUE and $dref->{'strTaskStatus'} eq $Defs::WF_TASK_STATUS_HOLD and $dref->{'intProblemResolutionEntityID'} and $dref->{'intProblemResolutionEntityID'} == $entityID);
    $showEditFields = 1  if ($dref->{'intEntityLevel'} == $Defs::LEVEL_VENUE and $dref->{'strTaskStatus'} eq $Defs::WF_TASK_STATUS_HOLD and $dref->{'intProblemResolutionEntityID'} and $dref->{'intProblemResolutionEntityID'} == $entityID);

    my ($DocumentData, $fields, $documentStatusCount) = populateDocumentViewData($Data, $dref);
    %DocumentData = %{$DocumentData};

    my $disableApprove = ($documentStatusCount->{'PENDING'} or $documentStatusCount->{'MISSING'} or $documentStatusCount->{'REJECTED'}) ? 1 : 0;

    #print STDERR Dumper $dref;
    my %TaskAction = (
        'ApprovalEntityLevel' => $dref->{'ApprovalEntityLevel'},
        'WFTaskID' => $dref->{intWFTaskID} || 0,
        'client' => $Data->{client} || 0,
        'showApprove' => $showApprove,
        'showReject' => $showReject,
        'showResolve' => $showResolve,
        'showToggle' => $showToggle,
        'showHold' => $showHold,
        'showAddFields' => $showAddFields,
        'showEditFields' => $showEditFields,
        'currentNoteID' => $dref->{'currentNoteID'} || 0,   #primary set to 0 will insert new row to table
        'onHold' => $dref->{'intOnHold'},
        'venueID' => ($dref->{'intEntityLevel'} == $Defs::LEVEL_VENUE) ? $dref->{'intEntityID'} : 0,
        'disableApprove' => $disableApprove,
        'RegistrationNature' => $dref->{'strRegistrationNature'},
    );

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


    $DocumentData{'TotalPending'} = $documentStatusCount->{'PENDING'};

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
    $TemplateData{'VenueFieldsBlock'} = populateVenueFieldsData($Data, $dref) if ($dref->{'intEntityLevel'} == $Defs::LEVEL_VENUE);

    my $flashMessage = getFlashMessage($Data, 'WF_U_FM');
    $TemplateData{'FlashMessage'} = $flashMessage;

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

    my $title;
    my $templateFile;
    my %TemplateData;
    my $personRequestData;
	my $entityID = getID($Data->{'clientValues'},$Data->{'clientValues'}{'currentLevel'});

    my $role_ref = getEntityTypeRoles($Data, $dref->{'strSport'}, $dref->{'strPersonType'});

    my $isocountries  = getISOCountriesHash();

    my %tempClientValues = getClient($Data->{'client'});
    $tempClientValues{currentLevel} = $Defs::LEVEL_PERSON;
    $tempClientValues{personID} = $dref->{intPersonID};

    my $tempClient= setClient(\%tempClientValues);
    my $PersonEditLink = "$Data->{'target'}?client=$tempClient&amp;a=PE_&amp;dtype=$dref->{'strPersonType'}";
    my $readonly = !( $Data->{'clientValues'}{'authLevel'} >= $Defs::LEVEL_NATIONAL ? 1 : 0 );
    my $minorProtectionOptions = getMinorProtectionOptions($Data, $dref->{'InternationalTransfer'});
    my $LocalName = "$dref->{'strLocalFirstname'} $dref->{'strLocalMiddleName'} $dref->{'strLocalSurname'}" || '';
    my $PersonType = $Data->{'lang'}->txt($Defs::personType{$dref->{'strPersonType'} || 0}) || '';

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

    my $languages = PersonLanguages::getPersonLanguages($Data, 1, 0);
    my $selectedLanguage;
    for my $l ( @{$languages} ) {
        if($l->{intLanguageID} == $dref->{'intLocalLanguage'}){
             $selectedLanguage = $l->{'language'};
            last
        }
    }

	%TemplateData = (
        PersonDetails => {
            Status => $Data->{'lang'}->txt($Defs::personStatus{$dref->{'PersonStatus'} || 0}) || '',
            Gender => $Data->{'lang'}->txt($Defs::genderInfo{$dref->{'PersonGender'} || 0}) || '',
            DOB => $dref->{'dtDOB'} || '',
            LocalName => $LocalName,
            LatinName => "$dref->{'strLatinFirstname'} $dref->{'strLatinMiddleName'} $dref->{'strLatinSurname'}" || '',
            Address => "$dref->{'strAddress1'} $dref->{'strAddress2'} $dref->{'strAddress2'} $dref->{'strSuburb'} $dref->{'strState'} $dref->{'strPostalCode'}" || '',
            Nationality => $isocountries->{$dref->{'strISONationality'}} || '',
            DateSuspendedUntil => '',
            LastUpdate => '',
            MID => $dref->{'strNationalNum'} || '',
            LatinSurname => $dref->{'strLatinSurname'} || '',
            MinorProtection => $minorProtectionOptions->{$dref->{'intMinorProtection'}} || '',

            Address1 => $dref->{'strAddress1'} || '',
            Address2 => $dref->{'strAddress2'} || '',
            FirstName => $dref->{'strLocalFirstname'} || '',
            LastName => $dref->{'strLocalSurname'} || '',
            CountryOfBirth => $isocountries->{$dref->{'strISOCountryOfBirth'}} || '',
            LanguageOfName => $selectedLanguage || '',
            RegionOfBirth => $dref->{'strRegionOfBirth'} || '',
            City =>$dref->{'strSuburb'} || '',
            State =>$dref->{'strState'} || '',
            ContactISOCountry =>$isocountries->{$dref->{'strISOCountry'}} || '',
            ContactPhone =>$dref->{'strPhoneHome'} || '',
            Email =>$dref->{'strEmail'} || '',
            PostalCode => $dref->{'strPostalCode'} || '',
        },
        PersonRegoDetails => {
            ID => $dref->{'intPersonRegistrationID'},
            Status => $Data->{'lang'}->txt($Defs::personRegoStatus{$dref->{'personRegistrationStatus'} || 0}) || '-',
            RegoType => $Data->{'lang'}->txt($Defs::registrationNature{$dref->{'strRegistrationNature'} || 0}) || '-',
            PersonType => $PersonType || '-',
            PersonEntityTypeRole => $Data->{'lang'}->txt($role_ref->{$dref->{'strPersonEntityRole'} || 0}) || '-',
            Sport => $Defs::sportType{$dref->{'strSport'}} || '-',
            Level => $Defs::personLevel{$dref->{'strPersonLevel'}} || '-',
            AgeLevel => $Defs::ageLevel{$dref->{'strAgeLevel'}} || '-',
            RegisterTo => $dref->{'entityLocalName'} || '-',
            Status => $Defs::personRegoStatus{$dref->{'personRegistrationStatus'}} || '-',
            DateFrom => $dref->{'dtFrom'} || '',
            DateTo => $dref->{'dtTo'} || '',
            Certifications => join(', ', @certString),
            strPersonType => $dref->{'strPersonType'},
        },
        EditDetailsLink => $PersonEditLink,
        ReadOnlyLogin => $readonly,
        PersonSummary => personSummaryPanel($Data, $dref->{intPersonID}) || '',
        WFTaskID => $dref->{'intWFTaskID'}
	);

    $TemplateData{'Notifications'}{'LockApproval'} = $Data->{'lang'}->txt('Locking Approval: Payment required.')
        if ($Data->{'SystemConfig'}{'lockApproval_PaymentRequired_REGO'} == 1 and $dref->{'regoPaymentRequired'});

    if($dref->{'strRegistrationNature'} eq $Defs::REGISTRATION_NATURE_TRANSFER){
        $title = $Data->{'lang'}->txt('Transfer') . " - $LocalName";;
        $templateFile = 'workflow/view/transfer.templ';

        my %regFilter = (
            'requestID' => $dref->{'intPersonRequestID'},
        );
        my $request = getRequests($Data, \%regFilter);
        $personRequestData = $request->[0];
        #print STDERR Dumper $personRequestData;
        $TemplateData{'TransferDetails'}{'TransferTo'} = $personRequestData->{'requestFrom'} || '';
        $TemplateData{'TransferDetails'}{'TransferFrom'} = $personRequestData->{'requestTo'} || '';
        $TemplateData{'TransferDetails'}{'RegistrationDateFrom'} = $dref->{'NPdtFrom'};
        $TemplateData{'TransferDetails'}{'RegistrationDateTo'} = $dref->{'NPdtTo'};
        $TemplateData{'TransferDetails'}{'Summary'} = $personRequestData->{'strRequestNotes'} || '';
    }
    else {
        $title = $Data->{'lang'}->txt('Registration') . " - $LocalName";
        $title .= ' - ' . $PersonType if $PersonType;
        $templateFile = 'workflow/view/personregistration.templ';
    }

    my %fields = (
        title => $title,
        templateFile => $templateFile,
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
                title => $Data->{'lang'}->txt('Club Registration') .' - ' . $dref->{'entityLocalName'},
                templateFile => 'workflow/view/club.templ',
            );

            $TemplateData{'Notifications'}{'LockApproval'} = $Data->{'lang'}->txt('Locking Approval: Payment required.')
                if ($Data->{'SystemConfig'}{'lockApproval_PaymentRequired_CLUB'} == 1 and $dref->{'entityPaymentRequired'});

            #TODO: add details specific to CLUB
        }
        case "$Defs::LEVEL_VENUE" {
            %fields = (
                title => $Data->{'lang'}->txt('Venue Registration') .' - ' . $dref->{'entityLocalName'},
                templateFile => 'workflow/view/venue.templ',
            );

            $TemplateData{'Notifications'}{'LockApproval'} = $Data->{'lang'}->txt('Locking Approval: Payment required.')
                if ($Data->{'SystemConfig'}{'lockApproval_PaymentRequired_VENUE'} == 1 and $dref->{'entityPaymentRequired'});

            #TODO: add details specific to VENUE

            my $entitySummaryPanel = entitySummaryPanel($Data, $dref->{'intEntityID'});
            $TemplateData{'EntitySummaryPanel'} = $entitySummaryPanel;
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
            MinorProtection => $dref->{'intMinorProtection'} || '',
            DateSuspendedUntil => '',
            LastUpdate => '',
        },
	);

    $TemplateData{'Notifications'}{'LockApproval'} = $Data->{'lang'}->txt('Locking Approval: Payment required.')
        if ($Data->{'SystemConfig'}{'lockApproval_PaymentRequired_PERSON'} == 1 and $dref->{'regoPaymentRequired'});

    return (\%TemplateData, \%fields);

}

sub populateDocumentViewData {
    my ($Data, $dref) = @_;

    #need to retrieve list of documents here
    #since a specific work flow rule can have
    #multiple entries in tblWFRuleDocuments (1:n cardinality of task to document rules)

	my @validdocsforallrego = ();
	my %validdocs = ();
	my %validdocsStatus = ();
## BAFF: Below needs WHERE tblRegistrationItem.strPersonType = XX AND tblRegistrationItem.strRegistrationNature=XX AND tblRegistrationItem.strAgeLevel = XX AND tblRegistrationItem.strPersonLevel=XX AND tblRegistrationItem.intOriginLevel = XX
	my $query = qq[
        SELECT 
            tblDocuments.strApprovalStatus, 
            tblDocuments.intDocumentTypeID, 
            tblDocuments.intUploadFileID 
        FROM 
            tblDocuments 
            INNER JOIN tblDocumentType ON (tblDocuments.intDocumentTypeID = tblDocumentType.intDocumentTypeID) 
            INNER JOIN tblRegistrationItem ON (tblDocumentType.intDocumentTypeID = tblRegistrationItem.intID)
		WHERE 
            strApprovalStatus IN('PENDING', 'APPROVED') 
            AND intPersonID = ? 
            AND tblRegistrationItem.intRealmID=? 
            AND (tblRegistrationItem.intUseExistingThisEntity = 1 OR tblRegistrationItem.intUseExistingAnyEntity = 1) 
            AND tblRegistrationItem.strItemType='DOCUMENT'
     AND tblRegistrationItem.strPersonType IN ('', ?)
     AND tblRegistrationItem.strRegistrationNature IN ('', ?)
     AND tblRegistrationItem.strAgeLevel IN ('', ?)
     AND tblRegistrationItem.strPersonLevel IN ('', ?)
		GROUP BY intDocumentTypeID];

     #AND tblRegistrationItem.intOriginLevel = ?
     #AND tblRegistrationItem.intEntityLevel = ?


	my $sth = $Data->{'db'}->prepare($query);
	$sth->execute($dref->{'intPersonID'}, $Data->{'Realm'},
      $dref->{'strPersonType'} || '',
      $dref->{'strRegistrationNature'} || '',
      $dref->{'strAgeLevel'} || '',
      $dref->{'strPersonLevel'} || '',
    );
      #$dref->{'intOriginLevel'},
      #$dref->{'intEntityLevel'},
	while(my $adref = $sth->fetchrow_hashref()){
	    $validdocsStatus{$adref->{'intDocumentTypeID'}} = $adref->{'strApprovalStatus'};
		push @validdocsforallrego, $adref->{'intDocumentTypeID'};
		$validdocs{$adref->{'intDocumentTypeID'}} = $adref->{'intUploadFileID'};
	}
	my $fileID = 0;

	
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

    $dref->{'currentAge'} ||= 0;
    my $st = qq[
        SELECT
            rd.intWFRuleDocumentID,
            rd.intWFRuleID,
            rd.intDocumentTypeID,
            rd.intAllowApprovalEntityAdd,
            rd.intAllowApprovalEntityVerify,
            rd.intAllowProblemResolutionEntityAdd,
            rd.intAllowProblemResolutionEntityVerify,
            tuf.intFileID,
            wt.intApprovalEntityID,
            wt.intProblemResolutionEntityID,
            dt.strDocumentName,
			dt.strDescription AS descr,
            dt.strDocumentFor,
			dt.intDocumentTypeID AS doctypeid, 
            d.strApprovalStatus,
            d.intDocumentID,
            pr.intNewBaseRecord,
            addPersonItem.intItemID as addPersonItemID,
            regoItem.intItemID as regoItemID,
			regoItem.intRequired as Required,
			addPersonItem.intRequired as PersonRequired,
			entityItem.intRequired as EntityRequired,
            entityItem.intItemID as entityItemID
        FROM tblWFRuleDocuments AS rd
        INNER JOIN tblWFTask AS wt ON (wt.intWFRuleID = rd.intWFRuleID)
        INNER JOIN tblWFRule as wr ON (wr.intWFRuleID = wt.intWFRuleID)
        LEFT JOIN tblPersonRegistration_$Data->{'Realm'} AS pr ON (pr.intPersonRegistrationID = wt.intPersonRegistrationID)
        LEFT JOIN tblRegistrationItem as addPersonItem
            ON (
                addPersonItem.strItemType = 'DOCUMENT'
                AND addPersonItem.intOriginLevel = wr.intOriginLevel
                AND addPersonItem.intEntityLevel = wr.intEntityLevel
                AND addPersonItem.strRuleFor = 'PERSON'
                AND addPersonItem.intID = rd.intDocumentTypeID
                AND addPersonItem.strAgeLevel IN ('', '$dref->{'strAgeLevel'}')
                AND addPersonItem.intRealmID = wt.intRealmID
                AND (addPersonItem.strISOCountry_IN ='' OR addPersonItem.strISOCountry_IN IS NULL OR addPersonItem.strISOCountry_IN LIKE CONCAT('%|','$dref->{'strISONationality'}','|%'))
                AND (addPersonItem.strISOCountry_NOTIN ='' OR addPersonItem.strISOCountry_NOTIN IS NULL OR addPersonItem.strISOCountry_NOTIN NOT LIKE CONCAT('%|','$dref->{'strISONationality'}','|%'))
                AND (addPersonItem.intFilterFromAge = 0 OR addPersonItem.intFilterFromAge <= $dref->{'currentAge'})
                AND (addPersonItem.intFilterToAge = 0 OR addPersonItem.intFilterToAge >= $dref->{'currentAge'})
                )
        LEFT JOIN tblRegistrationItem as regoItem
            ON (
                regoItem.strItemType = 'DOCUMENT'
                AND regoItem.intRealmID = wt.intRealmID
                AND regoItem.intOriginLevel = wr.intOriginLevel
                AND regoItem.strRuleFor = 'REGO'
                AND pr.intPersonRegistrationID > 0
                AND regoItem.intID = rd.intDocumentTypeID
                AND regoItem.intEntityLevel = wr.intEntityLevel
                AND regoItem.strRegistrationNature = '$dref->{'strRegistrationNature'}'
                AND regoItem.strPersonType IN ('', '$dref->{'strPersonType'}')
                AND regoItem.strPersonLevel IN ('', '$dref->{'strPersonLevel'}')
                AND regoItem.strSport IN ('', '$dref->{'strSport'}')
                AND regoItem.strAgeLevel IN ('', '$dref->{'strAgeLevel'}')
                AND regoItem.strPersonEntityRole IN ('', '$dref->{'strPersonEntityRole'}')
                AND (regoItem.strISOCountry_IN ='' OR regoItem.strISOCountry_IN IS NULL OR regoItem.strISOCountry_IN LIKE CONCAT('%|','$dref->{'strISONationality'}','|%'))
                AND (regoItem.strISOCountry_NOTIN ='' OR regoItem.strISOCountry_NOTIN IS NULL OR regoItem.strISOCountry_NOTIN NOT LIKE CONCAT('%|','$dref->{'strISONationality'}','|%'))
                AND (regoItem.intFilterFromAge = 0 OR regoItem.intFilterFromAge <= $dref->{'currentAge'})
                AND (regoItem.intFilterToAge = 0 OR regoItem.intFilterToAge >= $dref->{'currentAge'})
                )
        LEFT JOIN tblRegistrationItem as entityItem
            ON (
                entityItem.strItemType = 'DOCUMENT'
                AND entityItem.intRealmID= wt.intRealmID
                AND entityItem.intOriginLevel = wr.intOriginLevel
                AND entityItem.strRegistrationNature = '$dref->{'strRegistrationNature'}'
                AND entityItem.strRuleFor = 'ENTITY'
                AND entityItem.intID = rd.intDocumentTypeID
                AND entityItem.intEntityLevel = wr.intEntityLevel
                )
        LEFT JOIN tblDocuments AS d ON $joinCondition
        LEFT JOIN tblDocumentType dt ON (dt.intDocumentTypeID = rd.intDocumentTypeID )
        LEFT JOIN tblUploadedFiles tuf ON (tuf.intFileID = d.intUploadFileID)
        WHERE
            wt.intWFTaskID = ?
            AND wt.intRealmID = ?
        ORDER BY dt.strDocumentName, d.intDocumentID DESC
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
    my %DocoSeen = ();

    my %DocumentAction = (
        'target' => 'main.cgi',
        'WFTaskID' => $dref->{intWFTaskID} || 0,
        'client' => $Data->{client} || 0,
        'action' => 'WF_Verify',
    );
	
    my $count = 0;
    my %documentStatusCount;
    while(my $tdref = $q->fetchrow_hashref()) {
        next if exists $DocoSeen{$tdref->{'intDocumentTypeID'}}; 
        $DocoSeen{$tdref->{'intDocumentTypeID'}} = 1;
        #skip if no registration item matches rego details combination (type/role/sport/rego_nature etc)
        next if (!$tdref->{'regoItemID'} and $dref->{'strWFRuleFor'} eq 'REGO');
        

        next if((!$dref->{'InternationalTransfer'} and $tdref->{'strDocumentFor'} eq 'TRANSFERITC') or ($dref->{'InternationalTransfer'} and $tdref->{'strDocumentFor'} eq 'TRANSFERITC' and $dref->{'PersonStatus'} ne $Defs::PERSON_STATUS_PENDING));
		my $status;
        $count++;
		$fileID = $tdref->{'intFileID'};
		if(!$tdref->{'strApprovalStatus'}){     
			if(!grep /$tdref->{'doctypeid'}/,@validdocsforallrego){  

				if($tdref->{'Required'}){				
#or $tref->{'PersonRequired'} or $tref->{'EntityRequired'}
					$documentStatusCount{'MISSING'}++;
					$status = 'MISSING';
				}
				else {
					$status = 'Optional. Not Provided.';
				}
			}
			else{
				#$status = 'APPROVED';
				#$documentStatusCount{'APPROVED'}++;
	            $status = $validdocsStatus{$tdref->{'doctypeid'}};
				$documentStatusCount{$status}++;
				$fileID = $validdocs{$tdref->{'doctypeid'}};
			}
			
     	   }
		else {
			$documentStatusCount{$tdref->{'strApprovalStatus'}}++;
			$status = $tdref->{'strApprovalStatus'};
       	}
		
        my $displayVerify;
        my $displayAdd;
        my $displayView;
        my $displayReplace;
        my $viewLink = '';
        my $addLink = '';
        my $replaceLink = '';

       	my $registrationID = $tdref->{'regoItemID'} ? $dref->{'intPersonRegistrationID'} : 0;
        my $targetID = $dref->{'intPersonID'};
        #document for ENTITY
        my $level = (!$targetID and !$registrationID) ? $Defs::LEVEL_CLUB : $Defs::LEVEL_PERSON;
        $targetID = (!$targetID and !$registrationID) ? $dref->{'intEntityID'} : $targetID;
		
       
		my $cl = setClient($Data->{'clientValues'}) || '';
        my %cv = getClient($cl);

		if($level == $Defs::LEVEL_CLUB){
			 $cv{'clubID'} = $targetID;
		}
		elsif($Defs::LEVEL_PERSON){
			$cv{'personID'} = $targetID;
		}        
       $cv{'currentLevel'} = $level;
       my $clm = setClient(\%cv);
				
        my $docDesc = $tdref->{'descr'};
        $docDesc =~ s/'/\\\'/g;

        my $docName = $tdref->{'strDocumentName'};
        $docName =~ s/'/\\\'/g;
		my $parameters = qq[&amp;client=$clm&doctype=$tdref->{'intDocumentTypeID'}&pID=$targetID];
		
		$registrationID ? $parameters .= qq[&regoID=$registrationID] : $parameters .= qq[&entitydocs=1];
		
		$replaceLink = qq[ <span style="position: relative"><a href="#" class="btn-inside-docs-panel" onclick="replaceFile($fileID,'$parameters','$docName','$docDesc');return false;">]. $Data->{'lang'}->txt('Replace') . q[</a></span>]; 

		
		$addLink = qq[ <a href="#" class="btn-inside-docs-panel" onclick="replaceFile(0,'$parameters','$docName','$docDesc');return false;">]. $Data->{'lang'}->txt('Add') . q[</a>] if (!$Data->{'ReadOnlyLogin'});

        if($tdref->{'intAllowProblemResolutionEntityAdd'} == 1) {
            if(!$tdref->{'intDocumentID'}){
                $displayAdd = $entityID == $tdref->{'intProblemResolutionEntityID'} ? 1 : 0;
            }
            else {
                $displayReplace = $entityID == $tdref->{'intProblemResolutionEntityID'} ? 1 : 0;
            }
        }

        if ($tdref->{'intApprovalEntityID'} == $entityID and $tdref->{'intAllowApprovalEntityAdd'} == 1) {
            if(!$tdref->{'intDocumentID'}){
                $displayAdd = 1;
            }
            else {
                $displayReplace = 1;
            }
        }

        if($tdref->{'intAllowProblemResolutionEntityVerify'} == 1 and !$tdref->{'intDocumentID'}) {
            $displayVerify = $entityID == $tdref->{'intProblemResolutionEntityID'} ? 1 : 0;
        }

        #if ($tdref->{'intApprovalEntityID'} == $entityID and $tdref->{'intAllowApprovalEntityVerify'} == 1 and $tdref->{'intDocumentID'}) {
        if ($tdref->{'intApprovalEntityID'} == $entityID and $tdref->{'intAllowApprovalEntityVerify'} == 1 and ($tdref->{'intDocumentID'} or $fileID)) {
            $displayVerify = 1;
        }

        #if($tdref->{'intDocumentID'} ) {
		if($fileID) {
            $displayView = 1;
            $displayReplace = 1; #FC-518; approval entity/club should have the abilit to replace documents

            my $action = "view";
            $action = "review" if($tdref->{'intApprovalEntityID'} == $entityID and $tdref->{'intAllowApprovalEntityAdd'} == 1);

           	$viewLink = qq[ <span style="position: relative"> 
<a href="#" class="btn-inside-docs-panel" onclick="docViewer($fileID,'client=$Data->{'client'}&amp;a=$action');return false;">]. $Data->{'lang'}->txt('View') . q[</a></span>];			
        }
		
        my %documents = (
            DocumentID => $tdref->{'intDocumentID'},
            #Status => $tdref->{'strApprovalStatus'} || "MISSING",
			Status => $status,
            DocumentType => $tdref->{'strDocumentName'},
            Verifier => $tdref->{'strLocalName'},
            DisplayVerify => $displayVerify || '',
            DisplayAdd => $displayAdd || '',
            DisplayView => $displayView || '',
            DisplayReplace => $displayReplace || '',
            viewLink => $viewLink,
            addLink => $addLink,
            replaceLink => $replaceLink,

			
        );

        push @RelatedDocuments, \%documents;
    }


    %TemplateData = (
        DocumentAction => \%DocumentAction,
        RelatedDocuments => \@RelatedDocuments,
    );

    return (\%TemplateData, {}, \%documentStatusCount);

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

    %TemplateData = (
        TaskNotes => \@TaskNotes,
    );

    return (\%TemplateData);

}


sub populateVenueFieldsData {
    my ($Data, $dref) = @_;

    my $entityFields = new EntityFields();

    $entityFields->setEntityID($dref->{'intEntityID'});
    $entityFields->setData($Data);

    my $fields = $entityFields->getAll();
    my $count = scalar(@{$fields});


    foreach my $field (@{$fields}){
        $field->{'strGroundNature'} = $Defs::fieldGroundNatureType{$field->{'strGroundNature'}};
        $field->{'strDiscipline'} = $Defs::sportType{$field->{'strDiscipline'}};
    }

    return ("Facility Field(s) not found.", "Error") if(!$count);

    my %PageData = (
        target  => $Data->{'target'},
        Lang    => $Data->{'lang'},
        venueID => $dref->{'intEntityID'},
        #fields  => $fields,
        FieldElements => $fields,
    );  
 
    my $fieldsPage = runTemplate(
        $Data,
        \%PageData,
        'workflow/generic/facility_fields.templ'
    );  

    return $fieldsPage;
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
    my $title = '';

    my %TaskAction = (
        'WFTaskID' => $task->{intWFTaskID} || 0,
        'client' => $Data->{client} || 0,
    );

    $TemplateData{'TaskAction'} = \%TaskAction;
    $TemplateData{'Lang'} = $Data->{'lang'};

    my $c = Countries::getISOCountriesHash();

    switch($task->{'strWFRuleFor'}) {
        case 'REGO' {
            if($task->{'strRegistrationNature'} eq $Defs::REGISTRATION_NATURE_TRANSFER){
                $templateFile = 'workflow/summary/transfer.templ';
                $title = $Data->{'lang'}->txt("Transfer - Approved");
                my %regFilter = (
                    'requestID' => $task->{'intPersonRequestID'},
                );
                my $request = getRequests($Data, \%regFilter);
                $request = $request->[0];

                my ($PaymentsData) = populateRegoPaymentsViewData($Data, $task);
        
                $TemplateData{'TransferDetails'}{'personType'} = $Defs::personType{$task->{'strPersonType'}};
                $TemplateData{'TransferDetails'}{'TransferTo'} = $request->{'requestFrom'};
                $TemplateData{'TransferDetails'}{'TransferFrom'} = $request->{'requestTo'};
                $TemplateData{'TransferDetails'}{'DateFrom'} = $task->{'NPdtFrom'};
                $TemplateData{'TransferDetails'}{'DateTo'} = $task->{'NPdtTo'};
                $TemplateData{'TransferDetails'}{'Summary'} = $request->{'strRequestNotes'};
                $TemplateData{'TransferDetails'}{'Fee'} = $PaymentsData->{'TXNs'}[0]{'Amount'};
                
            }
            else {
                $templateFile = 'workflow/summary/personregistration.templ';
                $title = $Data->{'lang'}->txt('New' . ' ' . $Defs::personType{$task->{'strPersonType'}} . " " . "Registration - Approval");
            }

            $TemplateData{'PersonRegistrationDetails'}{'personType'} = $Defs::personType{$task->{'strPersonType'}};
            $TemplateData{'PersonRegistrationDetails'}{'personLevel'} = $Defs::personLevel{$task->{'strPersonLevel'}};
            $TemplateData{'PersonRegistrationDetails'}{'sport'} = $Defs::sportType{$task->{'strSport'}};
            $TemplateData{'PersonRegistrationDetails'}{'currentAge'} = $task->{'currentAge'};
            $TemplateData{'PersonRegistrationDetails'}{'personFirstname'} = $task->{'strLocalFirstname'};
            $TemplateData{'PersonRegistrationDetails'}{'personSurname'} = $task->{'strLocalSurname'};
            $TemplateData{'PersonRegistrationDetails'}{'registerTo'} = $task->{'registerToEntity'};
            $TemplateData{'PersonRegistrationDetails'}{'nationality'} = $c->{$task->{'strISONationality'}};
            $TemplateData{'PersonRegistrationDetails'}{'dob'} = $task->{'DOB'};
            $TemplateData{'PersonRegistrationDetails'}{'gender'} = $Defs::PersonGenderInfo{$task->{'intGender'}};
            $TemplateData{'PersonRegistrationDetails'}{'personRoleName'} = $task->{'strEntityRoleName'};
            $TemplateData{'PersonRegistrationDetails'}{'MID'} = $task->{'strNationalNum'};
            $TemplateData{'PersonRegistrationDetails'}{'Status'} = $Defs::personStatus{$task->{'personStatus'}};
            $TemplateData{'PersonRegistrationDetails'}{'DateFrom'} = $task->{'dtFrom'};
            $TemplateData{'PersonRegistrationDetails'}{'DateTo'} = $task->{'dtTo'};
            $TemplateData{'PersonSummaryPanel'} = personSummaryPanel($Data, $task->{'intPersonID'});

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

    return ($body, $title);

}

sub viewApprovalPage {
    my ($Data) = @_;

    #display page for now; details to be passed aren't finalised yet
    #use generic template for now

    my $WFTaskID = safe_param('TID','number') || '';
    my $entityID = getID($Data->{'clientValues'},$Data->{'clientValues'}{'currentLevel'});

    my $task = getTask($Data, $WFTaskID);

    return (" ", "Access forbidden.") if($entityID != $task->{'intApprovalEntityID'});

    my %TemplateData;
    my $templateFile;
    my $title = '';

    my %TaskAction = (
        'WFTaskID' => $task->{intWFTaskID} || 0,
        'client' => $Data->{client} || 0,
    );

    $TemplateData{'TaskAction'} = \%TaskAction;

    switch($task->{'strWFRuleFor'}) {
        case 'REGO' {
            $templateFile = 'workflow/result/personregistration.templ';
            $title = $Data->{'lang'}->txt('New ' . $Defs::personType{$task->{'strPersonType'}} . " Registration - Approval");
            $TemplateData{'PersonRegistrationDetails'}{'personType'} = $Defs::personType{$task->{'strPersonType'}};
            $TemplateData{'PersonRegistrationDetails'}{'personLevel'} = $Defs::personLevel{$task->{'strPersonLevel'}};
            $TemplateData{'PersonRegistrationDetails'}{'sport'} = $Defs::sportType{$task->{'strSport'}};
            $TemplateData{'PersonRegistrationDetails'}{'currentAge'} = $task->{'currentAge'};
            $TemplateData{'PersonRegistrationDetails'}{'personFirstname'} = $task->{'strLocalFirstname'};
            $TemplateData{'PersonRegistrationDetails'}{'personSurname'} = $task->{'strLocalSurname'};
            $TemplateData{'PersonRegistrationDetails'}{'registerTo'} = $task->{'registerToEntity'};
            $TemplateData{'PersonRegistrationDetails'}{'nationality'} = $task->{'strISONationality'};
            $TemplateData{'PersonRegistrationDetails'}{'dob'} = $task->{'DOB'};
            $TemplateData{'PersonRegistrationDetails'}{'gender'} = $Defs::PersonGenderInfo{$task->{'intGender'}};
            $TemplateData{'PersonRegistrationDetails'}{'personRoleName'} = $task->{'strEntityRoleName'};
            $TemplateData{'PersonSummaryPanel'} = personSummaryPanel($Data, $task->{'intPersonID'});
        }
        case 'ENTITY' {
            switch ($task->{'intEntityLevel'}) {
                case "$Defs::LEVEL_CLUB"  {
                    #TODO: add details specific to CLUB
                    $templateFile = 'workflow/result/club.templ';
                }
                case "$Defs::LEVEL_VENUE" {
                    #TODO: add details specific to VENUE
                    $templateFile = 'workflow/result/venue.templ';
                }
                else {

                }
            }
        }
        case 'PERSON' {
            $templateFile = 'workflow/result/person.templ';
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

    return ($body, $title);


    #my $WFTaskID = safe_param('TID','number') || '';

    #my %TemplateData;

    #my %TaskAction = (
    #    'WFTaskID' => $WFTaskID || 0,
    #    'client' => $Data->{client} || 0,
    #);

    #$TemplateData{'TaskAction'} = \%TaskAction;

	#my $body = runTemplate(
    #    $Data,
    #    \%TemplateData,
    #    'workflow/result/page.templ'
	#);

    #return ($body, "Approval status:");
}

sub updateTaskScreen {
    my ($Data, $action) = @_;

    my $WFTaskID = safe_param('TID','number') || '';
    my $entityID = getID($Data->{'clientValues'},$Data->{'clientValues'}{'currentLevel'});

    my $task = getTask($Data, $WFTaskID);


    #return (" ", "Access forbidden.") if($entityID != $task->{'intApprovalEntityID'});

    my $title;
    my $titlePrefix;
    my $message;
    my $body;
    my $status;
    my $TaskType;

    if($task->{'strWFRuleFor'} eq "ENTITY" and $task->{'intEntityLevel'} == $Defs::LEVEL_CLUB){
        $titlePrefix = $Defs::workTaskTypeLabel{$task->{'strRegistrationNature'} . "_CLUB"};
        $TaskType = $task->{'strRegistrationNature'} . "_CLUB";
    }
    elsif($task->{'strWFRuleFor'} eq "ENTITY" and $task->{'intEntityLevel'} == $Defs::LEVEL_VENUE) {
        $titlePrefix = $Defs::workTaskTypeLabel{$task->{'strRegistrationNature'} . "_VENUE"};
        $TaskType = $task->{'strRegistrationNature'} . "_VENUE";
    }
    elsif($task->{'strWFRuleFor'} eq "REGO") {
        $titlePrefix = $Defs::workTaskTypeLabel{$task->{'strRegistrationNature'} . "_" . $task->{'strPersonType'}}; 
        $TaskType = $task->{'strRegistrationNature'} . "_" . $task->{'strPersonType'};
    }

    open FH, ">dumpfile.txt";
    print FH "Group DataL \n\n" . Dumper($titlePrefix) . "\n" . Dumper($task) . "\n" . Dumper($TaskType) . "\n";   

    switch($action) {
        case "WF_PR_H" {
            $title = $Data->{'lang'}->txt($titlePrefix . ' - ' . 'On-Hold');
            
            if($TaskType eq 'TRANSFER_PLAYER') {
                $message = $Data->{'lang'}->txt("You have put this task on-hold, once the submitting Club resolves the issue, you would be able to verify and continue with the Transfer process.");
                $status = $Data->{'lang'}->txt("Pending");
            }
            elsif($TaskType eq 'NEW_PLAYER') {
                $message = $Data->{'lang'}->txt("You have put this task on-hold, once the submitting Club resolves the issue, you would be able to verify and continue with the Player Registration process.");
                $status = $Data->{'lang'}->txt("Pending");
            }
            elsif($TaskType eq 'NEW_COACH') {
                $message = $Data->{'lang'}->txt("You have put this task on-hold, once the submitting Club resolves the issue, you would be able to verify and continue with the Coach Registration process.");
                $status = $Data->{'lang'}->txt("Pending");
            }
            elsif($TaskType eq 'NEW_REFEREE') {
                $message = $Data->{'lang'}->txt("You have put this task on-hold, once the submitting MA resolves the issue, you would be able to verify and continue with the Referee Registration process.");
                $status = $Data->{'lang'}->txt("Pending");
            }
            elsif($TaskType eq 'NEW_MAOFFICIAL') {
                $message = $Data->{'lang'}->txt("You have put this task on-hold, once the submitting MA resolves the issue, you would be able to verify and continue with the MA Official Registration process.");
                $status = $Data->{'lang'}->txt("Pending");
            }
            elsif($TaskType eq 'NEW_CLUBOFFICIAL') {
                $message = $Data->{'lang'}->txt("You have put this task on-hold, once the submitting Club resolves the issue, you would be able to verify and continue with the Club Official Registration process.");
                $status = $Data->{'lang'}->txt("Pending");
            }
            elsif($TaskType eq 'NEW_TEAMOFFICIAL') {
                $message = $Data->{'lang'}->txt("You have put this task on-hold, once the submitting Club resolves the issue, you would be able to verify and continue with the Team Official Registration process.");
                $status = $Data->{'lang'}->txt("Pending");
            }
            elsif($TaskType eq 'NEW_VENUE') {
                $message = $Data->{'lang'}->txt("You have put this task on-hold, once the submitting Club resolves the issue, you would be able to verify and continue with the New Facility Registration process.");
                $status = $Data->{'lang'}->txt("Pending");
            }
            elsif($TaskType eq 'NEW_CLUB') {
                $message = $Data->{'lang'}->txt("You have put this task on-hold, once the submitting Club resolves the issue, you would be able to verify and continue with the New Club Registration process.");
                $status = $Data->{'lang'}->txt("Pending");
            }

        }
        case "WF_PR_R" {

            $title = $Data->{'lang'}->txt($titlePrefix . ' - ' . 'Rejected');
            if($TaskType eq 'TRANSFER_PLAYER') {
                $message = $Data->{'lang'}->txt("You have rejected this transfer, the clubs will be informed. To proceed with this transfer the clubs need to start a new transfer.");
                $status = $Data->{'lang'}->txt("Rejected");
            }
            elsif($TaskType eq 'NEW_PLAYER') {
                $message = $Data->{'lang'}->txt("You have rejected this Player Registration, the club will be informed. To proceed with this Registration the club need to start a new Registration.");
                $status = $Data->{'lang'}->txt("Rejected");
            }
            elsif($TaskType eq 'NEW_COACH') {
                $message = $Data->{'lang'}->txt("You have rejected this Coach Registration, the club will be informed. To proceed with this Registration the club need to start a new Registration.");
                $status = $Data->{'lang'}->txt("Rejected");
            }
            elsif($TaskType eq 'NEW_REFEREE') {
                $message = $Data->{'lang'}->txt("You have rejected this Referee Registration. To proceed with this Registration, start a new Registration.");
                $status = $Data->{'lang'}->txt("Rejected");
            }
            elsif($TaskType eq 'NEW_MAOFFICIAL') {
                $message = $Data->{'lang'}->txt("You have rejected this MA Official Registration. To proceed with this Registration, start a new Registration.");
                $status = $Data->{'lang'}->txt("Rejected");
            }
            elsif($TaskType eq 'NEW_CLUBOFFICIAL') {
                $message = $Data->{'lang'}->txt("You have rejected this Club Official Registration, the club will be informed. To proceed with this Registration the club need to start a new Registration.");
                $status = $Data->{'lang'}->txt("Rejected");
            }
            elsif($TaskType eq 'NEW_TEAMOFFICIAL') {
                $message = $Data->{'lang'}->txt("You have rejected this Team Official Registration, the club will be informed. To proceed with this Registration the club need to start a new Registration.");
                $status = $Data->{'lang'}->txt("Rejected");
            }
            elsif($TaskType eq 'NEW_VENUE') {
                $message = $Data->{'lang'}->txt("You have rejected this Venue Registration, the club will be informed. To proceed with this Registration the club need to start a new Registration.");
                $status = $Data->{'lang'}->txt("Rejected");
            }
            elsif($TaskType eq 'NEW_CLUB') {
                $message = $Data->{'lang'}->txt("You have rejected this Club Registration. To proceed with this Registration, start a new Registration.");
                $status = $Data->{'lang'}->txt("Rejected");
            }
        }
        case "WF_PR_S" {
            $title = $Data->{'lang'}->txt($titlePrefix . ' - ' . 'Resolved');
            $message = $Data->{'lang'}->txt("You have resolved this task.");
            $status = $Data->{'lang'}->txt("Resolved");
        }
    }

    my %TemplateData = (
        'client' => $Data->{'client'},
        'PersonSummaryPanel' => personSummaryPanel($Data, $task->{'intPersonID'}),
        'EntitySummaryPanel' => entitySummaryPanel($Data, $task->{'intEntityID'}),
        'message' => $message,
        'PersonDetails' => {
            'firstname' => $task->{'strLocalFirstname'} || $task->{'strLocalName'},
            'surname' => $task->{'strLocalSurname'},
            'localname' => $task->{'strLocalName'},
        },
        'status' => $status,
        'taskType' => $TaskType,
    );

	$body = runTemplate(
        $Data,
        \%TemplateData,
        'workflow/generic/hold_reject_taskscreen.templ',
	);

    return ($body, $title);
}

sub toggleTask {
    my ($Data, $emailNotification) = @_;

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
                    intOnHold = IF(intOnHold = 1, 0, 1),
                    strTaskStatus = IF(intOnHold = 1, 'ACTIVE', 'HOLD')
                WHERE
                    intWFTaskID = ?
            ];

            my $q = $Data->{'db'}->prepare($st);
            $q->execute(
                $WFTaskID
            ) or query_error($st);
        }

        my $toEntityID = undef;
        my $fromEntityID = undef;

        if($task->{'strTaskStatus'} eq 'ACTIVE' and $task->{'intApprovalEntityID'} == $entityID) {
            $toEntityID = $task->{'intProblemResolutionEntityID'};
            $fromEntityID = $task->{'intApprovalEntityID'};
        }
        elsif($task->{'strTaskStatus'} eq 'REJECTED' and $task->{'intProblemResolutionEntityID'} == $entityID) {
            $toEntityID = $task->{'intApprovalEntityID'};
            $fromEntityID = $task->{'intProblemResolutionEntityID'};
        }

        if($emailNotification and $toEntityID and $fromEntityID) {
            my $nType = $task->{'intOnHold'} == 0 ? $Defs::NOTIFICATION_WFTASK_HELD : $Defs::NOTIFICATION_WFTASK_RESUMED;
            $emailNotification->setRealmID($Data->{'Realm'});
            $emailNotification->setSubRealmID(0);
            $emailNotification->setToEntityID($toEntityID);
            $emailNotification->setFromEntityID($fromEntityID);
            $emailNotification->setDefsEmail($Defs::admin_email);
            $emailNotification->setDefsName($Defs::admin_email_name);
            $emailNotification->setNotificationType($nType);
            $emailNotification->setSubject("Work Task ID " . $WFTaskID);
            $emailNotification->setLang($Data->{'lang'});
            $emailNotification->setDbh($Data->{'db'});

            my $emailTemplate = $emailNotification->initialiseTemplate()->retrieve();
            $emailNotification->send($emailTemplate) if $emailTemplate->getConfig('toEntityNotification') == 1;
        }

        return 1;
    }

    return 0;
}

sub holdTask {
    my ($Data, $emailNotification) = @_;

    my $WFTaskID = safe_param('TID','number') || '';
    my $task = getTask($Data, $WFTaskID);
    my $currentToggle = safe_param('t', 'number') || 0;
    my $entityID = getID($Data->{'clientValues'},$Data->{'clientValues'}{'currentLevel'});

    #check if the task is assigned to
    #the current logged-in level
    #by this, only the current assignee can put the task on-hold
    if($task->{'strTaskStatus'} eq 'ACTIVE' and $task->{'intApprovalEntityID'} == $entityID) {

        #if($currentToggle == $task->{'intOnHold'}) {
            my $st = qq[
                UPDATE
                    tblWFTask
                SET
                    strTaskStatus = 'HOLD' 
                WHERE
                    intWFTaskID = ?
            ];

            my $q = $Data->{'db'}->prepare($st);
            $q->execute(
                $WFTaskID
            ) or query_error($st);
        #}

        if($task->{strWFRuleFor} eq 'ENTITY') {
            setEntityStatus($Data, $WFTaskID, $Defs::WF_TASK_STATUS_HOLD);
        }

        if($task->{strWFRuleFor} eq 'REGO') {
            setPersonRegoStatus($Data, $WFTaskID, $Defs::WF_TASK_STATUS_HOLD);
        }


        my $toEntityID = undef;
        my $fromEntityID = undef;

        if($task->{'strTaskStatus'} eq 'ACTIVE' and $task->{'intApprovalEntityID'} == $entityID) {
            $toEntityID = $task->{'intProblemResolutionEntityID'};
            $fromEntityID = $task->{'intApprovalEntityID'};
        }
        elsif($task->{'strTaskStatus'} eq 'REJECTED' and $task->{'intProblemResolutionEntityID'} == $entityID) {
            $toEntityID = $task->{'intApprovalEntityID'};
            $fromEntityID = $task->{'intProblemResolutionEntityID'};
        }

        if($emailNotification and $toEntityID and $fromEntityID) {
            my $nType = $Defs::NOTIFICATION_WFTASK_HELD;
            $emailNotification->setRealmID($Data->{'Realm'});
            $emailNotification->setSubRealmID(0);
            $emailNotification->setToEntityID($toEntityID);
            $emailNotification->setFromEntityID($fromEntityID);
            $emailNotification->setDefsEmail($Defs::admin_email);
            $emailNotification->setDefsName($Defs::admin_email_name);
            $emailNotification->setNotificationType($nType);
            $emailNotification->setSubject("Work Task ID " . $WFTaskID);
            $emailNotification->setLang($Data->{'lang'});
            $emailNotification->setDbh($Data->{'db'});

            my $emailTemplate = $emailNotification->initialiseTemplate()->retrieve();
            $emailNotification->send($emailTemplate) if $emailTemplate->getConfig('toEntityNotification') == 1;
        }

        resetRelatedTasks($Data, $WFTaskID, 'PENDING');

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

sub addMissingDocument {
    my ($Data) = @_;

    my $registrationID = safe_param('RegistrationID', 'number') || '';
    my $memberID = safe_param('trgtid', 'number') || '';
    my $documentTypeID = safe_param('doclisttype', 'number') || '';

    my $body = undef;
    my $title = undef;
    if($registrationID) {
        ($body, $title) = Documents::handle_documents(undef, $Data, $memberID, $documentTypeID, $registrationID);
    }
    else {
        ($body, $title) = EntityDocuments::handle_entity_documents("C_DOCS_frm", $Data, $memberID, $documentTypeID, undef);
    }

    return ($body, $title);
}

sub deleteRegoTransactions {
    my ($Data, $task) = @_;

    my %TemplateData = ();

    my $st = qq[
        DELETE
        FROM
            tblTransactions
        WHERE
            intID = ?
            AND intTableType = ?
            AND intPersonRegistrationID = ?
            AND intRealmID = ?
            AND intStatus = 0
    ];

    my $q = $Data->{'db'}->prepare($st) or query_error($st);
	my $res = $q->execute(
        $task->{'intPersonID'},
        $Defs::LEVEL_PERSON,
        $task->{'intPersonRegistrationID'},
        $Data->{'Realm'},
	) or query_error($st);

    return $res;
}

sub viewNextAvailableTask {
    my ($Data) = @_;

	my $entityID = getID($Data->{'clientValues'},$Data->{'clientValues'}{'currentLevel'});

    my $st = qq[
        SELECT
            intWFTaskID
        FROM
            tblWFTask
        WHERE
            intRealmID = ?
            AND intApprovalEntityID = ?
            AND strTaskStatus = 'ACTIVE'
        ORDER BY
            intWFTaskID DESC
        LIMIT 1
    ];

    my $q = $Data->{'db'}->prepare($st) or query_error($st);
	my $res = $q->execute(
        $Data->{'Realm'},
        $entityID,
	) or query_error($st);

    my $nextID = $q->fetchrow_array();
    $Data->{'RedirectTo'} = "$Defs::base_url/" . $Data->{'target'} . "?client=$Data->{'client'}&a=WF_View&TID=$nextID";
    return redirectTemplate($Data);
}

sub redirectTemplate {
    my ($Data) = @_;

    my $body = runTemplate(
        $Data,
        {},
        '',
    );

    return ($body, ' ');
}

sub getFlashMessage {
    my ($Data, $cookie_name) = @_;

    my $query = new CGI;
    my $flashMessage = $query->cookie($cookie_name);

    #since a flash message, it should be displayed once
    #reset upon first retrieval
    if($flashMessage){
        setFlashMessage($Data, $cookie_name, '', '-1d');
        return decode_json $flashMessage;
    }

    return '';
}

sub setFlashMessage {
    my ($Data, $cookie_name, $message, $exp) = @_;

    $exp = $exp || '1h';
    $message = ($message) ? encode_json $message : '';

    push @{$Data->{'WriteCookies'}}, [
        $cookie_name,
        $message,
        $exp,
    ];
}

1;
