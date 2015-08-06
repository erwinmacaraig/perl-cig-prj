package WorkFlow;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = @EXPORT_OK = qw(
	handleWorkflow
  	addWorkFlowTasks
  	approveTask
  	resolveTask
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
    checkRulePaymentFlagActions
    getRegistrationWorkTasks
    updateTaskNotes
    updateTaskScreen
    getInitialTaskAssignee
    redirectTemplate
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
use PersonUtils;
use PersonUserAccess;

use SphinxUpdate;
use InstanceOf;

use PersonLanguages;
use GatewayProcess;

use PersonRegistrationStatusChange;

sub checkRulePaymentFlagActions {

    my(
        $Data,
        $entityID,
        $personID,
        $personRegistrationID,
    ) = @_;
    $entityID ||= 0;
    $personID ||= 0;
    $personRegistrationID ||= 0;
    
    return if (! $entityID and ! $personID and ! $personRegistrationID);

    my $st = qq[
        SELECT
            T.intWFTaskID,
            R.intAutoActivateOnPayment,
            R.intLockTaskUntilPaid,
            R.intRemoveTaskOnPayment
        FROM
            tblWFTask as T
            INNER JOIN tblWFRule as R ON (R.intWFRuleID = T.intWFRuleID)
        WHERE
            T.strTaskStatus = 'ACTIVE'
            AND T.intPersonID = ?
            AND T.intEntityID = ?
            AND T.intPersonRegistrationID = ?
        ORDER BY intWFTaskID DESC LIMIT 1
    ];

    my $q= $Data->{'db'}->prepare($st);
    $q->execute($personID, $entityID, $personRegistrationID);


    my $countTaskSkipped= 0;
    while (my $dref = $q->fetchrow_hashref())   {
        if ($dref->{'intAutoActivateOnPayment'} == 1)   {
            if ($personRegistrationID)  {
                my $stUPD = qq[
                    UPDATE tblPersonRegistration_$Data->{'Realm'}
                    SET 
                        dtLastUpdated=NOW(),
                        dtApproved=NOW(),
                        dtFrom = NOW(),
                        strStatus = 'ACTIVE', 
                        intWasActivatedByPayment = 1
                    WHERE 
                        intPersonID = ?
                        AND intEntityID = ?
                        AND intPersonRegistrationID = ?
                        AND (
                            strStatus = 'PENDING'
                            OR (strStatus = 'ACTIVE' and dtApproved = '0000-00-00 00:00:00')
                        )
                        AND intPaymentRequired=0
                ];
                my $qUPD= $Data->{'db'}->prepare($stUPD);
                $qUPD->execute($personID, $entityID, $personRegistrationID);

                addPersonRegistrationStatusChangeLog($Data, $personRegistrationID, $Defs::PERSONREGO_STATUS_PENDING, $Defs::PERSONREGO_STATUS_ACTIVE)
            }
            if (! $personRegistrationID and $entityID)  {
                my $stUPD = qq[
                    UPDATE tblEntity
                    SET strStatus = 'ACTIVE', intWasActivatedByPayment = 1
                    WHERE 
                        intRealmID = ?
                        AND intEntityID = ?
                        AND strStatus = 'PENDING'
                ];
                my $qUPD= $Data->{'db'}->prepare($stUPD);
                $qUPD->execute($Data->{'Realm'}, $entityID);
            }
        }
        if ($dref->{'intRemoveTaskOnPayment'} == 1) {
            my $stUPD = qq[
                UPDATE tblWFTask
                SET strTaskStatus = 'DELETED', intPaymentGatewayResponded = 1
                WHERE 
                    intRealmID = ?
                    AND intWFTaskID = ?
            ];
            my $qUPD= $Data->{'db'}->prepare($stUPD);
            $qUPD->execute($Data->{'Realm'}, $dref->{'intWFTaskID'});
            $countTaskSkipped++;
        }
        else    {
            my $stUPD = qq[
                UPDATE tblWFTask
                SET intPaymentGatewayResponded = 1
                WHERE 
                    intRealmID = ?
                    AND intWFTaskID = ?
            ];
            my $qUPD= $Data->{'db'}->prepare($stUPD);
            $qUPD->execute($Data->{'Realm'}, $dref->{'intWFTaskID'});
        }
        #GatewayProcess::markGatewayAsResponded($Data, $dref->{'intWFTaskID'});
    }
    my $ruleFor = 'PERSON';
    $ruleFor = 'REGO' if ($personRegistrationID);
    $ruleFor = 'ENTITY' if (! $personID and ! $personRegistrationID);
    if ($countTaskSkipped)    {
        my $rc = checkForOutstandingTasks($Data, $ruleFor, '', $entityID, $personID, $personRegistrationID, 0);
    }


}
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

                #setFlashMessage($Data, 'WF_U_FM', \%flashMessage);
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
        #( $body, $title ) = viewTask( $Data );
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
    elsif ($action eq 'WF_H') {
        ($body, $title) = viewWorkFlowHistory($Data);
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
            pr.intNewBaseRecord,
            t.strRegistrationNature,
            t.tTimeStamp AS taskDate,
            UNIX_TIMESTAMP(t.tTimeStamp) AS taskTimeStamp,
            dt.strDocumentName,
            p.intSystemStatus,
            p.strLocalFirstname, 
            p.strLocalSurname, 
            p.intGender as PersonGender,
            p.intInternationalTransfer,
            p.intInternationalLoan,
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
            preqTo.strLocalName as preqToClub,
            pr.intPersonLevelChanged,
            pr.strPreviousPersonLevel,
            IF(t.strWFRuleFor = 'ENTITY', e.intCreatedByEntityID, IF(t.strWFRuleFor = 'REGO', pr.intOriginID, 0)) as CreatedByEntityID,
            IF(t.strWFRuleFor = 'ENTITY', IF(e.intEntityLevel = -47, 'VENUE', IF(e.intEntityLevel = 3, 'CLUB', '')), IF(t.strWFRuleFor = 'REGO', 'REGO', '')) as sysConfigApprovalLockRuleFor,
            IF(t.strWFRuleFor = 'ENTITY', e.intPaymentRequired, IF(t.strWFRuleFor = 'REGO', pr.intPaymentRequired, 0)) as paymentRequired
	    FROM tblWFTask AS t
                LEFT JOIN tblWFRule ON (tblWFRule.intWFRuleID = t.intWFRuleID)
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
                    tblWFRule.intLockTaskUntilPaid <> 1 
                    OR pr.intPersonRegistrationID IS NULL
                    OR (
                        tblWFRule.intLockTaskUntilPaid= 1
                        AND tblWFRule.intAutoActivateOnPayment <> 1
                        AND pr.intPaymentRequired = 0 
                    )
                )
                AND (
                    tblWFRule.intLockTaskUntilGatewayResponse <> 1
                    OR (
                        tblWFRule.intLockTaskUntilGatewayResponse = 1 
                        AND t.intPaymentGatewayResponded=1
                    )
                )
		    AND (
                      (t.intApprovalEntityID = ? AND (t.strTaskStatus = 'ACTIVE' OR t.strTaskStatus = 'REJECTED'))
                        OR
                      (((t.intProblemResolutionEntityID = ?) or (t.intProblemResolutionEntityID = ? AND t.intApprovalEntityID = ?)) AND t.strTaskStatus = 'HOLD')
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
        #FC-409 - don't include in list of taskStatus = REJECTED
        next if ($dref->{strTaskStatus} eq $Defs::WF_TASK_STATUS_REJECTED);

        my $sysConfigApprovalLockPaymentRequired = $Data->{'SystemConfig'}{'lockApproval_PaymentRequired_' . $dref->{'sysConfigApprovalLockRuleFor'}};
        if($sysConfigApprovalLockPaymentRequired and $dref->{'paymentRequired'}){
            $dref->{'strTaskStatus'} = 'LOCKED';
        }
        #F-609 - list in dashboard if ON-HOLD and created by == approval entity
        #next if (
        #    $dref->{strTaskStatus} eq $Defs::WF_TASK_STATUS_HOLD
        #    and $dref->{'intApprovalEntityID'} != $entityID
        #    and $dref->{'intProblemResolutionEntityID'} != $entityID
        #    and ($dref->{'CreatedByEntityID'} != $entityID)
        #);

        #moved checking of POSSIBLE_DUPLICATE here (if included in query, tasks for ENTITY are not capture)
        next if (defined $dref->{intSystemStatus} && $dref->{intSystemStatus} eq $Defs::PERSONSTATUS_POSSIBLE_DUPLICATE && $dref->{strWFRuleFor} ne $Defs::WF_RULEFOR_PERSON);

        my $newTask = ($dref->{'taskTimeStamp'} >= $lastLoginTimeStamp) ? 1 : 0; #additional check if tTimeStamp > currentTimeStamp

        if($dref->{'strRegistrationNature'} =~ /_LOAN/) {
            $taskCounts{$Defs::PERSON_REQUEST_LOAN}++;
        }
        elsif($dref->{'intInternationalTransfer'} == 1 and $dref->{'intNewBaseRecord'} == 1) {
            $taskCounts{$Defs::PERSON_REQUEST_TRANSFER}++;
        }
        elsif($dref->{'intInternationalLoan'} == 1 and $dref->{'intNewBaseRecord'} == 1) {
            $taskCounts{$Defs::PERSON_REQUEST_LOAN}++;
        }
        else {
            $taskCounts{$dref->{'strRegistrationNature'}}++;
        }

        $taskCounts{$dref->{'strTaskStatus'}}++;
        $taskCounts{"newTasks"}++ if $newTask;

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
        my $registrationNatureLabel = "";

        if($dref->{'strWFRuleFor'} eq "ENTITY" and $dref->{'intEntityLevel'} == $Defs::LEVEL_CLUB){
            $ruleForType = $dref->{'strRegistrationNature'} . "_CLUB";
        }
        elsif($dref->{'strWFRuleFor'} eq "ENTITY" and $dref->{'intEntityLevel'} == $Defs::LEVEL_VENUE) {
            $ruleForType = $dref->{'strRegistrationNature'} . "_VENUE";
			$viewTaskURL = "$Data->{'target'}?client=$client&amp;a=WF_View&TID=$dref->{'intWFTaskID'}";
        }
        elsif($dref->{'strWFRuleFor'} eq "REGO") {
            if($dref->{'intInternationalTransfer'} == 1 and $dref->{'intNewBaseRecord'}) {
                $ruleForType = "INTERNATIONAL_TRANSFER_" . $dref->{'strPersonType'};
                $registrationNatureLabel = $dref->{'strRegistrationNature'} . "_" . $dref->{'strPersonType'};
            }
            elsif($dref->{'intInternationalLoan'} == 1 and $dref->{'intNewBaseRecord'}) {
                $ruleForType = "INTERNATIONAL_LOAN_" . $dref->{'strPersonType'};
                $registrationNatureLabel = $dref->{'strRegistrationNature'} . "_" . $dref->{'strPersonType'};
            }
            else {
                $ruleForType = $dref->{'strRegistrationNature'} . "_" . $dref->{'strPersonType'};
            }
        }
        elsif($dref->{'strWFRuleFor'} eq "PERSON") {
            $ruleForType = $dref->{'strRegistrationNature'} . "_PERSON";
        }

        my $changeLevelDescription = '';
        if ($dref->{'intPersonLevelChanged'} and $dref->{'strPersonLevel'} ne $dref->{'strPreviousPersonLevel'})    {
            my $fromLevel = $Data->{'lang'}->txt($Defs::personLevel{$dref->{'strPreviousPersonLevel'}});
            my $newLevel = $Data->{'lang'}->txt($Defs::personLevel{$dref->{'strPersonLevel'}});
            $changeLevelDescription = $Data->{'lang'}->txt("with Level change from [_1] to [_2]", $fromLevel, $newLevel);
        }

	 my %single_row = (
			WFTaskID => $dref->{intWFTaskID},
            TaskDescription => $taskDescription,
			TaskType => $dref->{strTaskType},
			TaskNotes=> $dref->{TaskNotes},
			AgeLevel => $dref->{strAgeLevel},
			RuleFor=> $dref->{strWFRuleFor},
			RegistrationNature => $dref->{strRegistrationNature},
			RegistrationNatureLabel => $Data->{'lang'}->txt($Defs::workTaskTypeLabel{$registrationNatureLabel})|| $Data->{'lang'}->txt($Defs::workTaskTypeLabel{$ruleForType}),
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
            taskDate => $Data->{'l10n'}{'date'}->TZformat($dref->{taskDate},'MEDIUM'),
            taskDate_RAW => $dref->{taskDate},
            viewURL => $viewTaskURL,
            taskTypeLabel => $viewTaskURL,
            RequestToClub => $dref->{'preqToClub'},
            RequestFromClub => $dref->{'preqFromClub'},
            taskTimeStamp => $dref->{'taskTimeStamp'},
            newTask => $newTask,
            changeLevelDescription => $changeLevelDescription,
            NewBaseRecord => $dref->{'intNewBaseRecord'},
            InternationalTransferDescription => ($dref->{'intInternationalTransfer'} and $dref->{'intNewBaseRecord'}) ? '('.$Data->{'lang'}->txt("International Transfer").')' : "",
            InternationalLoanDescription => ($dref->{'intInternationalLoan'} and $dref->{'intNewBaseRecord'}) ? '('.$Data->{'lang'}->txt("International Player Loan").')' : "",
		);
        #print STDERR Dumper \%single_row;
        if($dref->{strRegistrationNature} eq 'NEW' and $dref->{'intPersonLevelChanged'} and $dref->{'strPersonLevel'} ne $dref->{'strPreviousPersonLevel'} ){
            $single_row{'RegistrationNatureLabel'} = 'Player Registration <br />(Level Change)';
        }
   
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
                or $request->{'strRequestStatus'} eq $Defs::PERSON_REQUEST_STATUS_CANCELLED
                or ($request->{'strRequestResponse'} eq $Defs::PERSON_REQUEST_STATUS_ACCEPTED and $entityID == $request->{'intRequestToEntityID'})
                or $request->{'personRegoStatus'} eq $Defs::PERSONREGO_STATUS_PENDING
                or $request->{'personRegoStatus'} eq $Defs::PERSONREGO_STATUS_HOLD
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
                personRequestLabel => $Data->{'lang'}->txt($Defs::personRequest{$request->{'strRequestType'}}),
                TaskType => $request->{'strRequestType'},
                TaskDescription => $Data->{'lang'}->txt('Person Request'),
                Name => $name,
                TaskStatus => $request->{'strRequestResponse'} ? $request->{'strRequestResponse'} : 'PENDING',
                TaskStatusLabel => $taskStatusLabel,
                viewURL => $viewURL,
                showView => 1,
                taskDate => $Data->{'l10n'}{'date'}->TZformat($request->{dtDateRequest},'MEDIUM'),
                taskDate_RAW => $request->{dtDateRequest},
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
		PersonType => \%Defs::personType,
        CurrentLevel => $Data->{'clientValues'}{'currentLevel'},
        TaskCounts => \%taskCounts,
        TaskMsg => $msg,
        TaskEntityID => $entityID,
        TaskFilters => \%taskFilters,
        client => $Data->{client},
		Levels => {
			CLUB => $Defs::LEVEL_CLUB,
			NATIONAL => $Defs::LEVEL_NATIONAL,	
			REGION => $Defs::LEVEL_REGION
		},
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

sub getSelfUserParentID {
    my ($Data, $CreatedByUserID, $PersonID, $PersonRegistrationID) = @_;

    my $st = qq[
        SELECT
            intSelfUserID
        FROM
            tblSelfUserAuth
        WHERE
            intEntityTypeID = $Defs::LEVEL_PERSON
            AND intEntityID = ?
            AND intSelfUserID = ?
    ];


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
        $documentID,
	$itc
    ) = @_;

	
    $itc ||= 0;
    $entityID ||= 0;
    $personID ||= 0;
    $originLevel ||= 0;
    $personRegistrationID ||= 0;
    $documentID ||= 0;
    #
    my $notificationType = $Defs::NOTIFICATION_WFTASK_ADDED; 
    # 
	
    my $q = '';
    my $db=$Data->{'db'};
    my $checkOk = 1;


    if ($ruleFor ne 'DOCUMENT') {
        my $stCheck = qq[
            SELECT 
                intWFTaskID
            FROM
                tblWFTask
            WHERE
                intRealmID=?
                AND strWFRuleFor = ?
                AND intPersonID=?
                AND intPersonRegistrationID=?
                AND intEntityID = ?
                AND strTaskStatus IN ('ACTIVE', 'HOLD')
            ORDER BY intWFTaskID DESC
            LIMIT 1
        ];
		
        my $qCheck = $Data->{'db'}->prepare($stCheck);
        $qCheck->execute(
            $Data->{'Realm'},
            $ruleFor,
            $personID,
            $personRegistrationID,
            $entityID,
        );
        my $existingTaskID = $qCheck->fetchrow_array() || 0;
        $checkOk = 0 if $existingTaskID;
		
    }
            
    

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
			pr.intCreatedByUserID,
			pr.intNewBaseRecord,
			p.intInternationalLoan,
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
	    AND (r.intUsingITCFilter =0 
		OR (r.intUsingITCFilter = 1 AND r.intNeededITC = ?)
	    )
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
            AND (
                r.intUsingPersonLevelChangeFilter = 0
                OR 
                (r.intUsingPersonLevelChangeFilter = 1 AND r.intPersonLevelChange = pr.intPersonLevelChanged)
            )
		];
	    $q = $db->prepare($st);
	    $itc ||= 0;
  	    $q->execute($itc, $personRegistrationID, $Data->{'Realm'}, $Data->{'RealmSubType'}, $originLevel, $regNature);
  	   
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
	
    if ($checkOk)   {
        while (my $dref= $q->fetchrow_hashref())    {
			
            my $approvalEntityID = getEntityParentID($Data, $dref->{RegoEntity}, $dref->{'intApprovalEntityLevel'}) || 0;
            my $problemEntityID = 0;
           
            if($originLevel == 1) {
                $problemEntityID = doesSelfUserHaveAccess($Data, $dref->{'intPersonID'}, $dref->{'intCreatedByUserID'}) ? $dref->{'intCreatedByUserID'} : 0;
                $emailNotification->setFromSelfUserID($problemEntityID);
            }
            else {
                $problemEntityID = getEntityParentID($Data, $dref->{RegoEntity}, $dref->{'intProblemResolutionEntityLevel'});
                $emailNotification->setFromEntityID($problemEntityID);
            }

            next if (! $approvalEntityID and ! $problemEntityID);
            print STDERR "^^^^^^^^^^^^^^^^^^^^^^^^^^^RULE ADDED WAS " . $dref->{'intWFRuleID'} . "\n\n\n";
            
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
            my $task = getTask($Data, $qINS->{mysql_insertid});
			
            my ($workTaskType, $workTaskRule) = getWorkTaskType($Data, $task);
            if($dref->{'intInternationalLoan'} and $dref->{'intNewBaseRecord'}){
		$workTaskType .=  qq[ ($Defs::workTaskTypeLabel{'INTERNATIONAL_LOAN_PLAYER'}) ];
		$notificationType = $Defs::NOTIFICATION_INTERNATIONALPLAYERLOAN_SENT
            }
            #'Person' => $task->{'strLocalFirstname'} . ' ' . $task->{'strLocalSurname'}            
            my %notificationData = (
                'Reason' => '',
                'WorkTaskType' => $workTaskType,
                'Person' =>  formatPersonName($Data, $task->{'strLocalFirstname'}, $task->{'strLocalSurname'}, ''),
                'PersonRegisterTo' => $task->{'registerToEntity'},
                'Club' => $task->{'strLocalName'},
                'Venue' => $task->{'strLocalName'},
                'PersonRegisterTo' => $task->{'registerToEntity'},
                'RegistrationType' => $task->{'sysConfigApprovalLockRuleFor'},
            );
            
	    $emailNotification->setRealmID($Data->{'Realm'});
            $emailNotification->setSubRealmID(0);
            $emailNotification->setToEntityID($approvalEntityID);
            $emailNotification->setDefsEmail($Defs::admin_email); #if set, this will be used instead of toEntityID
            $emailNotification->setDefsName($Defs::admin_email_name);
            $emailNotification->setNotificationType($notificationType);
            $emailNotification->setSubject($workTaskType);
            $emailNotification->setLang($Data->{'lang'});
            $emailNotification->setDbh($Data->{'db'});
            $emailNotification->setData($Data);
            $emailNotification->setWorkTaskDetails(\%notificationData);

            my $emailTemplate = $emailNotification->initialiseTemplate()->retrieve();
            $emailNotification->send($emailTemplate) if ($emailTemplate->getConfig('toEntityNotification') == 1 and $task->{'strTaskStatus'} eq $Defs::WF_TASK_STATUS_ACTIVE);

        }
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
        $errorStr = $Data->{'lang'}->txt("Error").': '. $Data->{'lang'}->txt("Payment required"); 
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
  	    auditLog($WFTaskID, $Data, 'Updated Work Task', 'WFTask');
  	    ###
        setDocumentStatus($Data, $WFTaskID, 'APPROVED');
	    if ($q->errstr) {
	    	return $q->errstr . '<br>' . $st
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
            PersonRequest::setRequestStatus($Data, $task, $Defs::PERSON_REQUEST_STATUS_COMPLETED);
        }
        elsif ($allComplete) {
            PersonRequest::finaliseTransfer($Data, $personRequestID);
            PersonRequest::setRequestStatus($Data, $task, $Defs::PERSON_REQUEST_STATUS_COMPLETED);
        }
    }
    if($registrationNature eq $Defs::REGISTRATION_NATURE_DOMESTIC_LOAN) {
        #check for pending tasks?

        my $allComplete = checkRelatedTasks($Data);
        if ($allComplete) {
            PersonRequest::setRequestStatus($Data, $task, $Defs::PERSON_REQUEST_STATUS_COMPLETED);
            PersonRequest::finalisePlayerLoan($Data, $personRequestID);
        }
    }
    elsif($personRequestID and $registrationNature eq $Defs::REGISTRATION_NATURE_NEW) {
        PersonRequest::setRequestStatus($Data, $task, $Defs::PERSON_REQUEST_STATUS_COMPLETED);
    }
    else {
        my ($workTaskType, $workTaskRule) = getWorkTaskType($Data, $task);
        my $cc = getCCRecipient($Data, $task);
        formatPersonName($Data, $task->{'strLocalFirstname'}, $task->{'strLocalSurname'}, ''),
        # 'Person' => $task->{'strLocalFirstname'} . ' ' . $task->{'strLocalSurname'},
        my %notificationData = (
            'Reason' => $task->{'holdNotes'},
            'WorkTaskType' => $workTaskType,
            'Person' =>  formatPersonName($Data, $task->{'strLocalFirstname'}, $task->{'strLocalSurname'}, ''),
            'PersonRegisterTo' => $task->{'registerToEntity'},
            'Club' => $task->{'strLocalName'},
            'Venue' => $task->{'strLocalName'},
            'PersonRegisterTo' => $task->{'registerToEntity'},
            'RegistrationType' => $task->{'sysConfigApprovalLockRuleFor'},
            'CC' => $cc || '',
        );

        if($emailNotification) {
            $emailNotification->setRealmID($Data->{'Realm'});
            $emailNotification->setSubRealmID(0);
            $emailNotification->setToEntityID($task->{'intProblemResolutionEntityID'});
            $emailNotification->setFromEntityID($task->{'intApprovalEntityID'});
            $emailNotification->setDefsEmail($Defs::admin_email);
            $emailNotification->setDefsName($Defs::admin_email_name);
            $emailNotification->setNotificationType($Defs::NOTIFICATION_WFTASK_APPROVED);
            $emailNotification->setSubject($workTaskType);
            $emailNotification->setLang($Data->{'lang'});
            $emailNotification->setDbh($Data->{'db'});
            $emailNotification->setData($Data);
            $emailNotification->setWorkTaskDetails(\%notificationData);

            my $emailTemplate = $emailNotification->initialiseTemplate()->retrieve();
            $emailNotification->send($emailTemplate) if $emailTemplate->getConfig('toEntityNotification') == 1;
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
    my @target_WFTaskID;

   	#Should be a cleverer way to do this, but check all the Pending Tasks and see if all of their
   	# pre-reqs have been completed. If so, update their status from Pending to Active.
    while(my $dref= $q->fetchrow_hashref()) {
        $count ++;

        if ($dref->{intWFTaskID} != $prev_WFTaskID) {
            if ($prev_WFTaskID != 0) {
                if ($updateThisTask eq 'YES') {
                    if(!($prev_WFTaskID ~~ @target_WFTaskID)){
                        push @target_WFTaskID, $prev_WFTaskID;
                    }

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
            if(!($prev_WFTaskID ~~ @target_WFTaskID)){
                push @target_WFTaskID, $prev_WFTaskID;
            }

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

        foreach my $TID (@target_WFTaskID) {
            my $emailNotification = new EmailNotifications::WorkFlow();
            my $task = getTask($Data, $TID);

            my ($workTaskType, $workTaskRule) = getWorkTaskType($Data, $task);
            my %notificationData = (
                'Reason' => '',
                'WorkTaskType' => $workTaskType,
                'Person' => formatPersonName($Data, $task->{'strLocalFirstname'}, $task->{'strLocalSurname'}, ''),
                'PersonRegisterTo' => $task->{'registerToEntity'},
                'Club' => $task->{'strLocalName'},
                'Venue' => $task->{'strLocalName'},
                'PersonRegisterTo' => $task->{'registerToEntity'},
                'RegistrationType' => $task->{'sysConfigApprovalLockRuleFor'},
            );

            $emailNotification->setRealmID($Data->{'Realm'});
            $emailNotification->setSubRealmID(0);
            $emailNotification->setToEntityID($task->{'intApprovalEntityID'});
            $emailNotification->setFromEntityID($task->{'intProblemResolutionEntityID'});
            $emailNotification->setDefsEmail($Defs::admin_email); #if set, this will be used instead of toEntityID
            $emailNotification->setDefsName($Defs::admin_email_name);
            $emailNotification->setNotificationType($Defs::NOTIFICATION_WFTASK_ADDED);
            $emailNotification->setSubject($workTaskType);
            $emailNotification->setLang($Data->{'lang'});
            $emailNotification->setDbh($Data->{'db'});
            $emailNotification->setData($Data);
            $emailNotification->setWorkTaskDetails(\%notificationData);

            my $emailTemplate = $emailNotification->initialiseTemplate()->retrieve();
            $emailNotification->send($emailTemplate) if $emailTemplate->getConfig('toEntityNotification') == 1;
        }

		####
  	    auditLog('', $Data, 'Updated Work Task', 'WFTask');
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
                auditLog($entityID, $Data, 'Registration Approved', 'Entity');
        }
        if ($ruleFor eq 'DOCUMENT' and $documentID and !$rowCount)   {
            $st = qq[
                    UPDATE tblDocuments
                    SET
                        strApprovalStatus = 'APPROVED',
                        dtLastUpdated=NOW()
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
                my $personObject = getInstanceOf($Data, 'person',$personID);

                updateSphinx($db,$Data->{'cache'}, 'Person','update',$personObject);
                auditLog($personID, $Data, 'Person Registered', 'Person');

        	#}
        }

        if ($ruleFor eq 'REGO' and $personRegistrationID and !$rowCount) {

                my $regoref = getPersonRegistrationStatus($Data, $personRegistrationID);
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
                        AND PR.strRegistrationNature NOT IN ('DOMESTIC_LOAN')
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
				# Do the check
				$st = qq[SELECT * FROM tblPersonRegistration_$Data->{Realm} WHERE intPersonRegistrationID = ?];
                my $qPR = $db->prepare($st);
				$qPR->execute($personRegistrationID);
				my $ppref = $qPR->fetchrow_hashref();

                my $stp = qq [SELECT * FROM tblPerson WHERE intPersonID = ?];
                my $qP = $db->prepare($stp); 
				$qP->execute($personID);
				my $personref = $qP->fetchrow_hashref();

                if ($ppref->{'strRegistrationNature'} eq $Defs::REGISTRATION_NATURE_RENEWAL)    {
                    PersonRegistration::rolloverExistingPersonRegistrations($Data, $personID, $personRegistrationID);
                }
                {
                    #my %PE = ();
                    #$PE{'personType'} = $ppref->{'strPersonType'} || '';
                    #$PE{'personLevel'} = $ppref->{'strPersonLevel'} || '';
                    #$PE{'personEntityRole'} = $ppref->{'strPersonEntityRole'} || '';
                    #$PE{'sport'} = $ppref->{'strSport'} || '';
                    
                    #my $peID = doesOpenPEExist($Data, $personID, $ppref->{'intEntityID'}, \%PE);
                    #addPERecord($Data, $personID, $ppref->{'intEntityID'}, \%PE) if (! $peID);

                    my $personObject = getInstanceOf($Data, 'person',$personID);
                    updateSphinx($db,$Data->{'cache'}, 'Person','update',$personObject);
                }
                # if check  pass call save
                if($ppref->{'strPersonType'} eq 'PLAYER' and $Data->{'SystemConfig'}{'cleanPlayerPersonRecords'}) {
                    PersonRegistration::cleanPlayerPersonRegistrations($Data, $personID, $personRegistrationID);
                }
    
                if( ($ppref->{'strPersonType'} eq 'PLAYER') && ($ppref->{'strSport'} eq 'FOOTBALL'))    {
                	savePlayerPassport($Data, $personID);
                }

                if($ppref->{'intNewBaseRecord'} == 1 and $personref->{'intInternationalLoan'} == 1) {
                    PersonRequest::setPlayerLoanValidDate($Data, 0, $personID, $personRegistrationID);
                }
                auditLog($personRegistrationID, $Data, 'Registration Approved', 'Person Registration');
                if ($ppref->{'strRegistrationNature'} ne $Defs::REGISTRATION_NATURE_DOMESTIC_LOAN)    {
                    addPersonRegistrationStatusChangeLog($Data, $personRegistrationID, $regoref->{'strStatus'}, $Defs::PERSONREGO_STATUS_ACTIVE);
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
        SET strApprovalStatus = ?,
                        dtLastUpdated=NOW()
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

    my($Data, $selfUserAsEntityID) = @_;

    my $WFTaskID = safe_param('TID','number') || '';
    my $notes= safe_param('notes','words') || '';
    my $type = safe_param('type','words') || '';
    my $lang = $Data->{'lang'};
    my $title = $lang->txt('Work task notes Updated');

    my $task = getTask($Data, $WFTaskID);
    my $targetAction = "";
    my $targetTemplate = "",

    #identify type of action (rejection or resolution based on intApprovalEntityID and intProblemResolutionID)
    my $entityID = $selfUserAsEntityID || getID($Data->{'clientValues'},$Data->{'clientValues'}{'currentLevel'});
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
	my $documentID = safe_param('f','number') || 0;
	my $regoID = safe_param('regoID','number') || 0;
	my $documentStatus = param('status') || '';

	my $st;
	my $q;


    if($regoID && $documentID){
        $st = qq[
            UPDATE 
                tblDocuments as D 
                LEFT JOIN tblPersonRegistration_$Data->{'Realm'} as PR ON (
                    D.intPersonRegistrationID = PR.intPersonRegistrationID 
                    AND D.intPersonID=PR.intPersonID
                ) 
            SET 
                D.intPersonRegistrationID = ? ,
                D.dtLastUpdated=NOW()
            WHERE 
                D.intPersonRegistrationID > 0
                AND (
                    PR.intPersonID IS NULL 
                    OR PR.strStatus = 'INPROGRESS'
                ) 
                AND D.intUploadFileID= ?
        ];
        $q = $Data->{'db'}->prepare($st);
        $q->execute($regoID,$documentID);
    }


	if($documentID){
    	$st = qq[
        	UPDATE tblDocuments
        	SET
        	    strApprovalStatus = ?,
                dtLastUpdated=NOW()
        	WHERE
        		intUploadFileID = ?
    	];

    	$q = $Data->{'db'}->prepare($st);
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
    my $title = $lang->txt('Work task notes');

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
        $emailNotification,
        $WFTaskID,
        $selfUserEntityID
    ) = @_;

	my $st = '';
	my $q = '';
	my $db=$Data->{'db'};

	#Get values from the QS
    $WFTaskID ||= safe_param('TID','number') || '';

    #FC-144 get current task based on taskid param
    my $task = getTask($Data, $WFTaskID);

    return if (!$task or ($task eq undef));

    return 0 if($selfUserEntityID
                and $selfUserEntityID != $task->{'intProblemResolutionEntityID'}
                and !doesSelfUserHaveAccess($Data, $task->{'intPersonID'}, $selfUserEntityID));

	my $srn = qq[
        SELECT
            strNotes
        FROM tblWFTaskNotes
        WHERE
            intWFTaskID = ?
            AND strType = 'RESOLVE'
        ORDER BY
            intTaskNoteID
        LIMIT 1
    ];

    my $nq = $db->prepare($srn);
    $nq->execute($WFTaskID);
    my $nr = $nq->fetchrow_hashref();

    my ($workTaskType, $workTaskRule) = getWorkTaskType($Data, $task);
    my %notificationData = (
        'Reason' => $nr->{'strNotes'},
        'WorkTaskType' => $workTaskType,
        'Person' => formatPersonName($Data, $task->{'strLocalFirstname'}, $task->{'strLocalSurname'}, ''),,
        'PersonRegisterTo' => $task->{'registerToEntity'},
        'Club' => $task->{'strLocalName'},
        'Venue' => $task->{'strLocalName'},
        'PersonRegisterTo' => $task->{'registerToEntity'},
        'RegistrationType' => $task->{'sysConfigApprovalLockRuleFor'},
    );


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
        $selfUserEntityID || getLastEntityID($Data->{'clientValues'}),
        $Data->{'Realm'}
  	);
	if ($q->errstr) {
		return $q->errstr . '<br>' . $st
	}
    setDocumentStatus($Data, $WFTaskID, 'PENDING');

    #resetRelatedTasks($Data, $WFTaskID, 'ACTIVE');
    ####
  	auditLog($WFTaskID, $Data, 'Updated Work Task', 'WFTask');
  	###

    if($emailNotification) {
        $emailNotification->setRealmID($Data->{'Realm'});
        $emailNotification->setSubRealmID(0);
        $emailNotification->setToEntityID($task->{'intApprovalEntityID'});
        $emailNotification->setFromEntityID($task->{'intProblemResolutionEntityID'});
        $emailNotification->setDefsEmail($Defs::admin_email);
        $emailNotification->setDefsName($Defs::admin_email_name);
        $emailNotification->setNotificationType($Defs::NOTIFICATION_WFTASK_RESOLVED);
        $emailNotification->setSubject($workTaskType);
        $emailNotification->setLang($Data->{'lang'});
        $emailNotification->setDbh($Data->{'db'});
        $emailNotification->setData($Data);
        $emailNotification->setWorkTaskDetails(\%notificationData);

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
  	auditLog($WFTaskID, $Data, 'Updated Work Task to Rejected', 'WFTask');
  	###

    if($task->{'strRegistrationNature'} eq $Defs::REGISTRATION_NATURE_TRANSFER
        or $task->{'strRegistrationNature'} eq $Defs::REGISTRATION_NATURE_DOMESTIC_LOAN) {
        #check for pending tasks?

        #if($Data->{'clientValues'}{'currentLevel'} eq $Defs::LEVEL_NATIONAL) {
            PersonRequest::setRequestStatus($Data, $task, $Defs::PERSON_REQUEST_STATUS_REJECTED);
        #}
    }
    elsif($task->{'intPersonRequestID'} and $task->{'strRegistrationNature'} eq $Defs::REGISTRATION_NATURE_NEW) {
        PersonRequest::setRequestStatus($Data, $task, $Defs::PERSON_REQUEST_STATUS_REJECTED);
    }
    else {
        my ($workTaskType, $workTaskRule) = getWorkTaskType($Data, $task);
        my $cc = getCCRecipient($Data, $task);
        my %notificationData = (
            'Reason' => $task->{'rejectNotes'},
            'WorkTaskType' => $workTaskType,
            'Person' => formatPersonName($Data, $task->{'strLocalFirstname'}, $task->{'strLocalSurname'}, ''),
            'PersonRegisterTo' => $task->{'registerToEntity'},
            'Club' => $task->{'strLocalName'},
            'Venue' => $task->{'strLocalName'},
            'PersonRegisterTo' => $task->{'registerToEntity'},
            'RegistrationType' => $task->{'sysConfigApprovalLockRuleFor'},
            'CC' => $cc || '',
        );

        if($emailNotification) {
            $emailNotification->setRealmID($Data->{'Realm'});
            $emailNotification->setSubRealmID(0);
            $emailNotification->setToEntityID($task->{'intProblemResolutionEntityID'});
            $emailNotification->setFromEntityID($task->{'intApprovalEntityID'});
            $emailNotification->setToOriginLevel($task->{'intOriginLevel'});
            $emailNotification->setDefsEmail($Defs::admin_email);
            $emailNotification->setDefsName($Defs::admin_email_name);
            $emailNotification->setNotificationType($Defs::NOTIFICATION_WFTASK_REJECTED);
            $emailNotification->setSubject($workTaskType);
            $emailNotification->setLang($Data->{'lang'});
            $emailNotification->setDbh($Data->{'db'});
            $emailNotification->setData($Data);
            $emailNotification->setWorkTaskDetails(\%notificationData);

            my $emailTemplate = $emailNotification->initialiseTemplate()->retrieve();
            $emailNotification->send($emailTemplate) if $emailTemplate->getConfig('toEntityNotification') == 1;
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

sub getWorkTaskType {
    my ($Data, $task) = @_;

    my $ruleForType;

    if($task->{'strWFRuleFor'} eq "ENTITY" and $task->{'intEntityLevel'} == $Defs::LEVEL_CLUB){
        $ruleForType = $task->{'strRegistrationNature'} . "_CLUB";
    }
    elsif($task->{'strWFRuleFor'} eq "ENTITY" and $task->{'intEntityLevel'} == $Defs::LEVEL_VENUE) {
        $ruleForType = $task->{'strRegistrationNature'} . "_VENUE";
    }
    elsif($task->{'strWFRuleFor'} eq "REGO") {
        $ruleForType = $task->{'strRegistrationNature'} . "_" . $task->{'strPersonType'};
    }
    elsif($task->{'strWFRuleFor'} eq "PERSON") {
        $ruleForType = $task->{'strRegistrationNature'} . "_PERSON";
    }

    return ($Data->{'lang'}->txt($Defs::workTaskTypeLabel{$ruleForType}), $ruleForType);
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
            IF(t.strWFRuleFor = 'ENTITY', IF(e.intEntityLevel = -47, 'VENUE', IF(e.intEntityLevel = 3, 'CLUB', '')), IF(t.strWFRuleFor = 'REGO', IF(t.strRegistrationNature = 'TRANSFER', 'TRANSFER', ''), ''))as sysConfigApprovalLockRuleFor,
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
            p.strInternationalLoanSourceClub,
	    p.strInternationalLoanTMSRef, 
	    p.dtInternationalLoanFromDate, 
	    p.dtInternationalLoanToDate,
            p.strStatus as personStatus,
            DATE_FORMAT(p.dtDOB, "%d/%m/%Y") as DOB,
            p.dtDOB AS DOB_RAW,
            p.intInternationalLoan,
            TIMESTAMPDIFF(YEAR, p.dtDOB, CURDATE()) as currentAge,
            rnt.intTaskNoteID as rejectTaskNoteID,
            rnt.intCurrent as rejectCurrent,
            rnt.strNotes as rejectNotes,
            tnt.intTaskNoteID as holdTaskNoteID,
            tnt.strNotes as holdNotes,
            pre.strLocalName as registerToEntity,
            tnt.intCurrent as holdCurrent,
            wr.intApprovalEntityLevel,
            wr.intProblemResolutionEntityLevel,
            wr.intOriginLevel,
            wr.intEntityLevel
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
        LEFT JOIN tblWFRule as wr ON (wr.intWFRuleID = t.intWFRuleID)
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
    $result->{'currentAge'} = personAge($Data,$result->{'DOB_RAW'});
    return $result || undef;
}

sub viewTask {
    my ($Data, $WFTID, $entityID) = @_;

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

    my $WFTaskID = $WFTID || safe_param('TID','number') || '';
    $entityID ||= getID($Data->{'clientValues'},$Data->{'clientValues'}{'currentLevel'});

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
            pr.strShortNotes,
            pr.intOriginLevel,
            pr.intNewBaseRecord,
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
            p.intInternationalTransfer,
            p.intInternationalLoan,
            TIMESTAMPDIFF(YEAR, p.dtDOB, CURDATE()) as currentAge,
            p.intGender as PersonGender,
            p.intInternationalTransfer as InternationalTransfer,
            p.intInternationalLoan as InternationalLoan,
            p.strInternationalTransferSourceClub,
            p.dtInternationalTransferDate,
            p.strInternationalTransferTMSRef,
            p.strInternationalLoanSourceClub,
            p.strInternationalLoanTMSRef,
            p.dtInternationalLoanFromDate,
            p.dtInternationalLoanToDate,
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
            e.dtFrom as dateFrom,
            e.dtTo as dateTo,
            e.intLegalTypeID as intLegalTypeID,
            e.strLegalID as strLegalID,
            e.strDiscipline as strDiscipline,
            e.strOrganisationLevel as strOrganisationLevel,
            e.strMANotes as strMANotes,
            e.strContact as entityContact,
            e.strEmail as entityEmail,
            e.strPhone as entityPhone,
            e.strCity as strCity,
            e.strFax as entityFax,
            e.strISOCountry as entityCountry,
            e.tTimeStamp as entityCreatedUpdated,
            e.strBankAccountNumber,
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
        #return (undef, "ERROR: no data retrieved/no access.");
        return displayGenericError($Data, $Data->{'lang'}->txt("Error"), $Data->{'lang'}->txt("No data retrieved/no access"));
    }

    $dref->{'currentAge'} = personAge($Data,$dref->{'dtDOB'});

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
        ($dref->{'strRegistrationNature'} ne $Defs::REGISTRATION_NATURE_AMENDMENT and $dref->{'strTaskStatus'} eq $Defs::WF_TASK_STATUS_ACTIVE and $dref->{'intProblemResolutionEntityID'} and $dref->{'intProblemResolutionEntityID'} != $entityID)
        or
        ($dref->{'strRegistrationNature'} ne $Defs::REGISTRATION_NATURE_AMENDMENT and $dref->{'strTaskStatus'} eq $Defs::WF_TASK_STATUS_ACTIVE and $dref->{'intProblemResolutionEntityID'} eq $dref->{'intApprovalEntityID'})
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
    if ($dref->{strWFRuleFor} eq 'REGO' or $dref->{strWFRuleFor} eq 'ENTITY')    {
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

    my $activeTab = safe_param('at','number') || 1;

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
    #my $LocalName = "$dref->{'strLocalFirstname'} $dref->{'strLocalMiddleName'} $dref->{'strLocalSurname'}" || '';
    my $LocalName = formatPersonName($Data, $dref->{'strLocalFirstname'}, $dref->{'strLocalSurname'}, ''), 
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
            LatinName => join(' ',[$dref->{'strLatinFirstname'} || '', $dref->{'strLatinMiddleName'} || '', $dref->{'strLatinSurname'} || '']),
            Address => join(' ',[$dref->{'strAddress1'}||'',$dref->{'strAddress2'}||'',$dref->{'strSuburb'}||'',$dref->{'strState'}||'',$dref->{'strPostalCode'} || '']),
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
            City => $dref->{'strSuburb'} || '',
            State => $dref->{'strState'} || '',
            ContactISOCountry =>$isocountries->{$dref->{'strISOCountry'}} || '',
            ContactPhone =>$dref->{'strPhoneHome'} || '',
            Email =>$dref->{'strEmail'} || '',
            PostalCode => $dref->{'strPostalCode'} || '',
            InternationalTransfer => $dref->{'InternationalTransfer'} || 0,
            InternationalLoan => $dref->{'InternationalLoan'} || 0,
            strInternationalTransferSourceClub => $dref->{'strInternationalTransferSourceClub'} || '',
            dtInternationalTransferDate => $dref->{'dtInternationalTransferDate'} || '',
            strInternationalTransferTMSRef => $dref->{'strInternationalTransferTMSRef'} || '',
            strInternationalLoanSourceClub => $dref->{'strInternationalLoanSourceClub'} || '',
            strInternationalLoanTMSRef => $dref->{'strInternationalLoanTMSRef'} || '',
            dtInternationalLoanFromDate => $dref->{'dtInternationalLoanFromDate'} || '',
            dtInternationalLoanToDate => $dref->{'dtInternationalLoanToDate'} || '',
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
            strShortNotes => $dref->{'strShortNotes'} || '',
            OriginLevel => $dref->{'intOriginLevel'},
            NewBaseRecord => $dref->{'intNewBaseRecord'} || 0,
        },
        EditDetailsLink => $PersonEditLink,
        ReadOnlyLogin => $readonly,
        PersonSummary => personSummaryPanel($Data, $dref->{intPersonID}) || '',
        childEntityID => $dref->{'intEntityID'},
        parentEntityID => $Data->{'clientValues'}{'_intID'},
        WFTaskID => $dref->{'intWFTaskID'},
        ActiveTab => $activeTab
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
        $TemplateData{'TransferDetails'}{'TransferTo'} = $personRequestData->{'requestFrom'} || '';
        $TemplateData{'TransferDetails'}{'TransferFrom'} = $personRequestData->{'requestTo'} || '';
        $TemplateData{'TransferDetails'}{'RegistrationDateFrom'} = $dref->{'NPdtFrom'};
        $TemplateData{'TransferDetails'}{'RegistrationDateTo'} = $dref->{'NPdtTo'};
        $TemplateData{'TransferDetails'}{'Summary'} = $personRequestData->{'strRequestNotes'} || '';
	    $TemplateData{'Notifications'}{'LockApproval'} = $Data->{'lang'}->txt('Locking Approval: Payment required.') if ($Data->{'SystemConfig'}{'lockApproval_PaymentRequired_TRANSFER'} == 1 and $dref->{'regoPaymentRequired'});


    }
    elsif($dref->{'strRegistrationNature'} eq $Defs::REGISTRATION_NATURE_DOMESTIC_LOAN){
        $title = $Data->{'lang'}->txt('Player Loan') . " - $LocalName";;
        $templateFile = 'workflow/view/loan.templ';

        my %regFilter = (
            'requestID' => $dref->{'intPersonRequestID'},
        );
        my $request = getRequests($Data, \%regFilter);
        $personRequestData = $request->[0];
        $TemplateData{'PlayerLoanDetails'}{'PlayerLoanTo'} = $personRequestData->{'requestFrom'} || '';
        $TemplateData{'PlayerLoanDetails'}{'PlayerLoanFrom'} = $personRequestData->{'requestTo'} || '';
        $TemplateData{'PlayerLoanDetails'}{'LoanStartDate'} = $personRequestData->{'dtLoanFrom'};
        $TemplateData{'PlayerLoanDetails'}{'LoanEndDate'} = $personRequestData->{'dtLoanTo'};
        $TemplateData{'PlayerLoanDetails'}{'TMSReference'} = $personRequestData->{'strTMSReference'};
        $TemplateData{'PlayerLoanDetails'}{'Summary'} = $personRequestData->{'strRequestNotes'} || '';
	    $TemplateData{'Notifications'}{'LockApproval'} = $Data->{'lang'}->txt('Locking Approval: Payment required.') if ($Data->{'SystemConfig'}{'lockApproval_PaymentRequired_TRANSFER'} == 1 and $dref->{'regoPaymentRequired'});


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

    my $self = shift;
    my %TemplateData;
    my %fields;
    my $isocountries  = getISOCountriesHash();
    use Club;
    my $client=setClient($Data->{'clientValues'});
    my %tempClientValues = getClient($client);
    $tempClientValues{currentLevel} = $dref->{intEntityLevel};
    setClientValue(\%tempClientValues, $dref->{intEntityLevel}, $dref->{intEntityID});

    my $tempClient = setClient(\%tempClientValues);
    my $readonly = !( $Data->{'clientValues'}{'authLevel'} >= $Defs::LEVEL_NATIONAL ? 1 : 0 );

    my $WFTaskID = safe_param('TID','number') || '';
    my $entityID = getID($Data->{'clientValues'},$Data->{'clientValues'}{'currentLevel'});

    my $task = getTask($Data, $WFTaskID);

    my $activeTab = safe_param('at','number') || 1;
	
	%TemplateData = (
        EntityDetails => {
            Status => $Data->{'lang'}->txt($Defs::entityStatus{$dref->{'entityStatus'} || 0}) || '',
            LocalShortName => $dref->{'strLocalShortName'} || '',
            LocalName => $dref->{'entityLocalName'} || '',
            FoundationDate => $dref->{'dateFrom'} || '',
            DissolutionDate => $dref->{'dateTo'} || '',
            Country => $isocountries->{$dref->{'entityCountry'}},
            Region => $dref->{'entityRegion'} || '',
            Address => $dref->{'entityAddress'} || '',
            Town => $dref->{'entityTown'} || '',
            WebUrl => $dref->{'entityWebUrl'} || '',
            Email => $dref->{'entityEmail'} || '',
            Phone => $dref->{'entityPhone'} || '',
            Fax => $dref->{'entityFax'} || '',
            PostalCode => $dref->{'entityPostalCode'} || '',
            Contact => $dref->{'entityContact'} || '',
            organizationType => $dref->{'strEntityType'},
            organizationTypeName => $Defs::entityType{$dref->{'strEntityType'}},
            strLegalID => $dref->{'strLegalID'},
            comment => $dref->{'strMANotes'},
            sport => $dref->{'strDiscipline'},
            sportName => $Defs::entitySportType{$dref->{'strDiscipline'}},
            strCity => $dref->{'strCity'},
            organizationLevel => $dref->{'strOrganisationLevel'},
            organizationLevelName => $Defs::personLevel{$dref->{'strOrganisationLevel'}},
            legaltype => Club::getLegalTypeName($Data, $dref->{'intLegalTypeID'}),
            intEntityID => $dref->{'intEntityID'},
            bankAccountDetails => $dref->{'strBankAccountNumber'},
        },
        EditDetailsLink => "$Data->{'target'}?client=$tempClient&amp;dtype=$dref->{'strPersonType'}",
		AddDetailsLink => "$Data->{'target'}?client=$client",
        ReadOnlyLogin => $readonly,
        intWFTaskID => $dref->{'intWFTaskID'},
        ActiveTab => $activeTab,
        
	);
    my ($PaymentsData) = populateRegoPaymentsViewData($Data, $task);

    switch ($dref->{intEntityLevel}) {
        case "$Defs::LEVEL_CLUB"  {
            %fields = (
                title => $Data->{'lang'}->txt('Club Registration') .' - ' . $Data->{'lang'}->txt($dref->{'entityLocalName'}),
                templateFile => 'workflow/view/club.templ',
            );

            $TemplateData{'Notifications'}{'LockApproval'} = $Data->{'lang'}->txt('Locking Approval: Payment required.')
                if ($Data->{'SystemConfig'}{'lockApproval_PaymentRequired_CLUB'} == 1 and $dref->{'entityPaymentRequired'});

            #TODO: add details specific to CLUB
        }
        case "$Defs::LEVEL_VENUE" {
            %fields = (
                title => $Data->{'lang'}->txt('Venue Registration') .' - ' . $Data->{'lang'}->txt($dref->{'entityLocalName'}),
                templateFile => 'workflow/view/venue.templ',
            );

            $TemplateData{'Notifications'}{'LockApproval'} = $Data->{'lang'}->txt('Locking Approval: Payment required.')
            if ($Data->{'SystemConfig'}{'lockApproval_PaymentRequired_VENUE'} == 1 and $dref->{'entityPaymentRequired'});
			$TemplateData{'VenueDocuments'} = $Data->{'SystemConfig'}{'hasVenueDocuments'};
			$TemplateData{'ActiveTab'} = $Data->{'SystemConfig'}{'hasVenueDocuments'}?$activeTab: param('at')? param('at') : 2; 
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

    my $languages = PersonLanguages::getPersonLanguages($Data, 1, 0);
    my $selectedLanguage;
    for my $l ( @{$languages} ) {
        if($l->{intLanguageID} == $dref->{'intLocalLanguage'}){
             $selectedLanguage = $l->{'language'};
            last
        }
    }

    my $LocalName = "$dref->{'strLocalFirstname'} $dref->{'strLocalMiddleName'} $dref->{'strLocalSurname'}" || '';
    my $ruleForType = $dref->{'strRegistrationNature'} . "_PERSON";

    my %fields = (
        title => $Data->{'lang'}->txt($Defs::workTaskTypeLabel{$ruleForType}) . ' - ' . $LocalName,
        templateFile => 'workflow/view/person.templ',
    );

    my $isocountries  = getISOCountriesHash();
	

	#get Registration Details for this person within this club
	my $sql = qq[SELECT tblEntity.strLocalName, pr.strPersonType, pr.strRegistrationNature, pr.strPersonLevel, pr.strPersonEntityRole, pr.strStatus, pr.strSport, pr.strAgeLevel, tblNationalPeriod.strNationalPeriodName, tblNationalPeriod.dtFrom, tblNationalPeriod.dtTo FROM tblPersonRegistration_$Data->{'Realm'} as pr 
INNER JOIN tblNationalPeriod ON pr.intNationalPeriodID = tblNationalPeriod.intNationalPeriodID INNER JOIN tblEntity ON tblEntity.intEntityID = pr.intEntityID
WHERE pr.intPersonID = ? AND pr.intEntityID = ?];
	my $sth = $Data->{'db'}->prepare($sql);
	$sth->execute($dref->{'intPersonID'} ,$dref->{'intEntityID'});

	my @registrations = ();
	while(my $data = $sth->fetchrow_hashref()){
		
		my $certifications = getPersonCertifications(
        $Data,
        $dref->{'intPersonID'},
        $data->{'strPersonType'},
        0
 	   ); # anonymous array that contains certifications
		my @certString;
		if(scalar @{$certifications}){
			 foreach my $cert (@{$certifications}) {
       			 push @certString, $cert->{'strCertificationName'};
   			 }
			$data->{'certifications'} = join(', ', @certString);  # append to the specific registration
		}
		
		push @registrations, $data;
		
		
	}
	
	

   
   

	%TemplateData = (
        PersonDetails => {
            Status => $Data->{'lang'}->txt($Defs::personStatus{$dref->{'PersonStatus'} || 0}) || '',
            Gender => $Data->{'lang'}->txt($Defs::genderInfo{$dref->{'PersonGender'} || 0}) || '',
            DOB => $dref->{'dtDOB'} || '',
            LocalName => "$dref->{'strLocalFirstname'} $dref->{'strLocalMiddleName'} $dref->{'strLocalSurname'}" || '',
            LatinName => "$dref->{'strLatinFirstname'} $dref->{'strLatinMiddleName'} $dref->{'strLatinSurname'}" || '',
            FamilyName => "$dref->{'strLocalSurname'}" || '',
            FirstName => "$dref->{'strLocalFirstname'}" || '',
            LanguageOfName => $selectedLanguage || '',
            Address => "$dref->{'strAddress1'} $dref->{'strAddress2'} $dref->{'strAddress2'} $dref->{'strSuburb'} $dref->{'strState'} $dref->{'strPostalCode'}" || '',
            Address1 => $dref->{'strAddress1'} || '',
            Address2 => $dref->{'strAddress2'} || '',
            City => $dref->{'strSuburb'} || '',          
            State => "$dref->{'strState'}" || '',
            PostalCode => "$dref->{'strPostalCode'}" || '',
            ContactISOCountry => $isocountries->{$dref->{'strISOCountry'}} || '',
            ContactPhone => $dref->{'strPhoneHome'} || '',
            Email => $dref->{'strEmail'} || '',
            Nationality => $isocountries->{$dref->{'strISONationality'}} || '', #TODO identify extract string
            BirthCountry => $isocountries->{$dref->{'strISOCountryOfBirth'}} || '', #TODO identify extract string
            BirthRegion => "$dref->{'strRegionOfBirth'}" || '',
            MinorProtection => $dref->{'intMinorProtection'} || '',
            DateSuspendedUntil => '',
            LastUpdate => '',
            ruleForPerson => $ruleForType || '',
        },
		PersonRegoDetails => \@registrations,
		
        PersonSummary => personSummaryPanel($Data, $dref->{intPersonID}) || '',
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

    return ({}, {}, {}) if !$dref->{'strTaskStatus'};

	my @validdocsforallrego = ();
	my %validdocs = ();
	my %validdocsStatus = ();
## BAFF: Below needs WHERE tblRegistrationItem.strPersonType = XX AND tblRegistrationItem.strRegistrationNature=XX AND tblRegistrationItem.strAgeLevel = XX AND tblRegistrationItem.strPersonLevel=XX AND tblRegistrationItem.intOriginLevel = XX

    my $internationalTransfer = ($dref->{'intNewBaseRecord'} and $dref->{'intInternationalTransfer'}) ? 1 : 0;
    my $internationalLoan = ($dref->{'intNewBaseRecord'} and $dref->{'intInternationalLoan'}) ? 1 : 0;

    my $query = qq[
        SELECT
            DISTINCT
            tblDocuments.strApprovalStatus,
            tblDocuments.intDocumentTypeID,
            tblDocumentType.strActionPending,
            tblDocuments.intUploadFileID
        FROM
            tblDocuments
            INNER JOIN tblDocumentType ON (tblDocuments.intDocumentTypeID = tblDocumentType.intDocumentTypeID)
            INNER JOIN tblRegistrationItem ON (tblDocumentType.intDocumentTypeID = tblRegistrationItem.intID)
        WHERE
            strApprovalStatus IN('PENDING', 'APPROVED', 'REJECTED')
            AND intPersonID = ?
            AND tblRegistrationItem.intRealmID=?
            AND (tblRegistrationItem.intUseExistingThisEntity = 1 OR tblRegistrationItem.intUseExistingAnyEntity = 1)
            AND tblRegistrationItem.strItemType='DOCUMENT'
            AND tblRegistrationItem.strPersonType IN ('', ?)
            AND tblRegistrationItem.strRegistrationNature IN ('', ?)
            AND tblRegistrationItem.strAgeLevel IN ('', ?)
            AND tblRegistrationItem.strPersonLevel IN ('', ?)
            AND (tblRegistrationItem.intItemForInternationalTransfer = 0 OR tblRegistrationItem.intItemForInternationalTransfer = ?)
            AND (tblRegistrationItem.intItemForInternationalLoan = 0 OR tblRegistrationItem.intItemForInternationalLoan = ?)
            AND tblRegistrationItem.intEntityLevel = ?
    ];
     
    my @levels = ();
    push @levels, $dref->{'intEntityLevel'};
    if ($dref->{'intOriginLevel'} && $dref->{'intOriginLevel'} > 0)   {
        $query .= qq[ AND tblRegistrationItem.intOriginLevel = ?  ];
        push @levels, $dref->{'intOriginLevel'};
    }
    $query .= qq[
        ORDER BY
            tblDocuments.tTimeStamp DESC,
            tblDocuments.intUploadFileID DESC
    ];

    my $sth = $Data->{'db'}->prepare($query);
    $sth->execute(
        $dref->{'intPersonID'}, $Data->{'Realm'},
        $dref->{'strPersonType'} || '',
        $dref->{'strRegistrationNature'} || '',
        $dref->{'strAgeLevel'} || '',
        $dref->{'strPersonLevel'} || '',
        $internationalTransfer,
        $internationalLoan,
        @levels
    );
    
    while(my $adref = $sth->fetchrow_hashref()){
        next if (defined $dref->{'intPersonRegistrationID'} and $adref->{'strApprovalStatus'} eq 'REJECTED' and $adref->{'strActionPending'} ne 'REGO'); ## If its a personRego ID lets only get Approved/Pending docos
        next if exists $validdocs{$adref->{'intDocumentTypeID'}};
        #if (! exists $validdocs{$adref->{'intDocumentTypeID'}} or $adref->{'strApprovalStatus'} ne 'APPROVED')     {
        $validdocsStatus{$adref->{'intDocumentTypeID'}} = $adref->{'strApprovalStatus'};
        #if ( ! exists $validdocs{$adref->{'intDocumentTypeID'}})    {
        push @validdocsforallrego, $adref->{'intDocumentTypeID'};
        #}
        $validdocs{$adref->{'intDocumentTypeID'}} = $adref->{'intUploadFileID'};
        #}
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

    my $entityID = getID($Data->{'clientValues'},$Data->{'clientValues'}{'currentLevel'}) || $Data->{'UserID'};
      
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
			addPersonItem.intRequired as personRequired,
			addPersonItem.intItemID as personItemID,
			entityItem.intRequired as EntityRequired,
            entityItem.intItemID as entityItemID,
            E.intEntityID as DocoEntityID,
            E.intEntityLevel as DocoEntityLevel,
            dt.strLockAtLevel 
        FROM tblWFRuleDocuments AS rd
        INNER JOIN tblWFTask AS wt ON (wt.intWFRuleID = rd.intWFRuleID)
        INNER JOIN tblWFRule as wr ON (wr.intWFRuleID = wt.intWFRuleID)
        LEFT JOIN tblPersonRegistration_$Data->{'Realm'} AS pr ON (pr.intPersonRegistrationID = wt.intPersonRegistrationID)
        LEFT JOIN tblEntity as E ON (E.intEntityID=pr.intEntityID)
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
                AND (regoItem.intItemForInternationalTransfer = 0 OR regoItem.intItemForInternationalTransfer = $internationalTransfer)
                AND (regoItem.intItemForInternationalLoan = 0 OR regoItem.intItemForInternationalLoan = $internationalLoan)
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
        
        #next if((!$dref->{'InternationalTransfer'} and $tdref->{'strDocumentFor'} eq 'TRANSFERITC') or ($dref->{'InternationalTransfer'} and $tdref->{'strDocumentFor'} eq 'TRANSFERITC' and $dref->{'PersonStatus'} ne $Defs::PERSON_STATUS_PENDING));
		my $status;
        $count++;
		$fileID = $tdref->{'intFileID'};
		if(!$tdref->{'strApprovalStatus'}){     
			if(!grep /$tdref->{'doctypeid'}/,@validdocsforallrego){  

				if($tdref->{'Required'} or $tdref->{'personRequired'}){				
#or $tref->{'PersonRequired'} or $tref->{'EntityRequired'}
					$documentStatusCount{'MISSING'}++;
					$status = $Data->{'lang'}->txt('MISSING');
				}
				else {
					$status = $Data->{'lang'}->txt('Optional. Not Provided.');
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
		elsif($level == $Defs::LEVEL_PERSON){
			$cv{'personID'} = $targetID;
		}        

       $cv{'currentLevel'} = $level;
       my $clm = setClient(\%cv);
				
        my $docDesc = $tdref->{'descr'};
        $docDesc =~ s/'/\\\'/g;

        my $docName = $tdref->{'strDocumentName'};
        $docName =~ s/'/\\\'/g;
		my $parameters = qq[&amp;client=$clm&doctype=$tdref->{'intDocumentTypeID'}&pID=$targetID];
		
        #$registrationID ? $parameters .= qq[&regoID=$registrationID] : $parameters .= qq[&entitydocs=1];
        $registrationID ? $parameters .= qq[&regoID=$registrationID] : $parameters .= '';
        $level != $Defs::LEVEL_PERSON ? $parameters .= qq[&entitydocs=1] : $parameters .= '';
		
        if ($fileID)    {
		    $replaceLink = qq[ <span style="position: relative"><a href="#" class="btn-inside-docs-panel" onclick="replaceFile($fileID,'$parameters','$docName','$docDesc');return false;">]. $Data->{'lang'}->txt('Replace') . q[</a></span>]; 
        }

		
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

			$parameters = qq[client=$Data->{'client'}&amp;a=$action];
			$parameters .= qq[&regoID=$registrationID] if($registrationID); 
			$viewLink = qq[ <span style="position: relative"><a href="#" class="btn-inside-docs-panel" onclick="docViewer($fileID,'$parameters');return false;">]. $Data->{'lang'}->txt('View') . q[</a></span>];	
           	#$viewLink = qq[ <span style="position: relative"><a href="#" class="btn-inside-docs-panel" onclick="docViewer($fileID,'client=$Data->{'client'}&amp;a=$action');return false;">]. $Data->{'lang'}->txt('View') . q[</a></span>];			

        }

        if($tdref->{'strLockAtLevel'})   {
            if($tdref->{'strLockAtLevel'} =~ /\|$Data->{'clientValues'}{'authLevel'}\|/ and getLastEntityID($Data->{'clientValues'}) != $tdref->{'DocoEntityID'}){
                $displayView=0;
                $displayReplace=0;
            }
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

    my $targetID = 0;
    my $targetLEVEL = 0;
    my $otherID = 0;

    if($dref->{'strWFRuleFor'} eq "ENTITY" and $dref->{'intEntityLevel'} == $Defs::LEVEL_CLUB){
        $targetID = $dref->{'intEntityID'};
        $targetLEVEL = $Defs::LEVEL_CLUB;
        $otherID = 0; 
    }
    elsif($dref->{'strWFRuleFor'} eq "ENTITY" and $dref->{'intEntityLevel'} == $Defs::LEVEL_VENUE) {
        $targetID = $dref->{'intEntityID'};
        $targetLEVEL = $Defs::LEVEL_VENUE;
        $otherID = 0; 
    }
    elsif($dref->{'strWFRuleFor'} eq "REGO") {
        $targetID = $dref->{'intPersonID'};
        $targetLEVEL = $Defs::LEVEL_PERSON;
        $otherID = $dref->{'intPersonRegistrationID'}; 
    }

    my $st = qq[
        SELECT
            T.intQty,
            T.curAmount,
            P.strName as ProductName,
            P.strDisplayName as ProductDisplayName,
            P.strProductType as ProductType,
            T.intStatus,
            T.intTransactionID,
            TL.intPaymentType,
			I.strInvoiceNumber
        FROM
            tblTransactions as T
            INNER JOIN tblProducts as P ON (P.intProductID=T.intProductID)
			INNER JOIN tblInvoice as I ON (T.intInvoiceID = I.intInvoiceID)
            LEFT JOIN tblTransLog as TL ON (TL.intLogID=T.intTransLogID)
        WHERE
            T.intID = ?
            AND T.intTableType = ?
            AND T.intPersonRegistrationID = ?
    ];

    my $q = $Data->{'db'}->prepare($st) or query_error($st);
    $q->execute(
        $targetID,
        $targetLEVEL,
        $otherID,
    ) or query_error($st);

	my @TXNs= ();
	my $rowCount = 0;

    while(my $tdref = $q->fetchrow_hashref()) {
        my %row= (
            TransactionNumber=> $tdref->{'intTransactionID'},
			InvoiceNumber => $tdref->{'strInvoiceNumber'},
            PaymentLogID=> $tdref->{'intTransLogID'},
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
            ParentNoteType => $Defs::wfTaskAction{$tdref->{'parentNoteType'}},
            ParentTimeStamp => $tdref->{'parentTimeStamp'},
            ChildNote => $tdref->{'childNote'},
            ChildNoteType => $Defs::wfTaskAction{$tdref->{'childNoteType'}},
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
    my ($Data, $dref) = @_;

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

    my $club = qq[SELECT strStatus as entityStatus, strLocalName FROM tblEntity WHERE intEntityID = ?];
    my $sth = $Data->{'db'}->prepare($club);

    $sth->execute($task->{'intCreatedByEntityID'});

    $dref = $sth->fetchrow_hashref();

    my $clubName = $dref->{'strLocalName'};

    switch($task->{'strWFRuleFor'}) {
        case ['REGO', 'PERSON'] {
            if($task->{'strRegistrationNature'} eq $Defs::REGISTRATION_NATURE_TRANSFER){
                $templateFile = 'workflow/summary/transfer.templ';
                $title = $Data->{'lang'}->txt("Transfer") . " : " .$Data->{'lang'}->txt("Approved");
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
            if($task->{'strRegistrationNature'} eq $Defs::REGISTRATION_NATURE_DOMESTIC_LOAN){
                $templateFile = 'workflow/summary/loan.templ';
                $title = $Data->{'lang'}->txt("Player Loan - Approved");
                my %regFilter = (
                    'requestID' => $task->{'intPersonRequestID'},
                );
                my $request = getRequests($Data, \%regFilter);
                $request = $request->[0];

                my ($PaymentsData) = populateRegoPaymentsViewData($Data, $task);
        
                $TemplateData{'PlayerLoanDetails'}{'personType'} = $Defs::personType{$task->{'strPersonType'}};
                $TemplateData{'PlayerLoanDetails'}{'BorrowingClub'} = $request->{'requestFrom'};
                $TemplateData{'PlayerLoanDetails'}{'LendingClub'} = $request->{'requestTo'};
                $TemplateData{'PlayerLoanDetails'}{'LoanStartDate'} = $request->{'dtLoanFrom'};
                $TemplateData{'PlayerLoanDetails'}{'LoanEndDate'} = $request->{'dtLoanTo'};
                $TemplateData{'PlayerLoanDetails'}{'TMSReference'} = $request->{'strTMSReference'};
                $TemplateData{'PlayerLoanDetails'}{'Summary'} = $request->{'strRequestNotes'};
                $TemplateData{'PlayerLoanDetails'}{'Fee'} = $PaymentsData->{'TXNs'}[0]{'Amount'};
                
            }
            elsif($task->{'strRegistrationNature'} eq $Defs::REGISTRATION_NATURE_AMENDMENT){
                $TemplateData{'PersonRegistrationDetails'}{'currentClub'} = $task->{'strLocalName'};
                $templateFile = 'workflow/summary/person.templ';
                my $header = $Defs::workTaskTypeLabel{$task->{'strRegistrationNature'} . "_PERSON"}; 

                $title = $Data->{'lang'}->txt($header . " - Approval");
            }
            else {
                $templateFile = 'workflow/summary/personregistration.templ';
                $title = $Data->{'lang'}->txt('New [_1] Registration', $Data->{'lang'}->txt($Defs::personType{$task->{'strPersonType'}})) . " - " . $Data->{'lang'}->txt('Approval');
            }
	    $TemplateData{'PersonRegistrationDetails'}{'isInternationalPlayerLoan'} = $task->{'intInternationalLoan'};
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
            #
            $TemplateData{'PersonRegistrationDetails'}{'InternationalLoanSourceClub'} = $task->{'strInternationalLoanSourceClub'} || '';
            $TemplateData{'PersonRegistrationDetails'}{'InternationalLoanTMSRef'} = $task->{'strInternationalLoanTMSRef'} || '';
            $TemplateData{'PersonRegistrationDetails'}{'InternationalLoanFromDate'} = $Data->{'l10n'}{'date'}->TZformat($task->{'dtInternationalLoanFromDate'},'MEDIUM') || '';
            $TemplateData{'PersonRegistrationDetails'}{'InternationalLoanToDate'} =  $Data->{'l10n'}{'date'}->TZformat($task->{'dtInternationalLoanToDate'},'MEDIUM') || '';
            #
            $TemplateData{'PersonSummaryPanel'} = personSummaryPanel($Data, $task->{'intPersonID'});

        }
        case 'ENTITY' {
            switch ($task->{'intEntityLevel'}) {
                case "$Defs::LEVEL_CLUB"  {
                    #TODO: add details specific to CLUB
                    my ($PaymentsData) = populateRegoPaymentsViewData($Data, $task);
                    $templateFile = 'workflow/summary/club.templ';
                    $title = $Data->{'lang'}->txt('New Club Registration - Approval');
                }
                case "$Defs::LEVEL_VENUE" {
                    #TODO: add details specific to VENUE
                    my ($PaymentsData) = populateRegoPaymentsViewData($Data, $task);
                    $templateFile = 'workflow/summary/venue.templ';
                    $title = $Data->{'lang'}->txt('New Facility Registration - Approval');
                }
                else {

                }
            }

             %TemplateData = (
                EntityDetails => {
                    Status => $Data->{'lang'}->txt($Defs::entityStatus{$dref->{'entityStatus'} || 0}) || '',
                    LocalShortName => $task->{'strLocalShortName'} || '',
                    LocalName => $task->{'strLocalName'} || '',
                    LegalID => $task->{'strLegalID'} || '',
                    FoundationDate => $task->{'dtFrom'} || '',
                    ISOCountry => $c->{$task->{'strISOCountry'}} || '',
                    Discipline => $Defs::entitySportType{$task->{'strDiscipline'}} || '',
                    ContactPerson => $task->{'strContact'} || '',
                    Email => $task->{'strEmail'} || '',
                    Website => $task->{'strWebURL'} || '',
                    EntityID => $task->{'intCreatedByEntityID'} || '',
                    ClubName => $clubName,
                },
                TaskAction => \%TaskAction,
            );
            $TemplateData{'EntitySummaryPanel'} = entitySummaryPanel($Data, $task->{'intEntityID'});
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
    my ($Data, $dref) = @_;

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

    my $c = Countries::getISOCountriesHash();

    $TemplateData{'TaskAction'} = \%TaskAction;
    my $clubName = $dref->{'strLocalName'};

    my $typeName = $Data->{'lang'}->txt($Defs::personType{$task->{'strPersonType'}});
    switch($task->{'strWFRuleFor'}) {
        case 'REGO' {
            $templateFile = 'workflow/result/personregistration.templ';
            $title = $Data->{'lang'}->txt("New [_1] Registration",$typeName) . ' - ' . $Data->{'lang'}->txt('Approval');
            $TemplateData{'PersonRegistrationDetails'}{'personType'} = $typeName;
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
                    $title = $Data->{'lang'}->txt('New Club Registration - Approval');
                }
                case "$Defs::LEVEL_VENUE" {
                    #TODO: add details specific to VENUE
                    $templateFile = 'workflow/result/venue.templ';
                    $title = $Data->{'lang'}->txt('New Facility Registration - Approval');
                }
                else {

                }
            }
             %TemplateData = (
                EntityDetails => {
                    Status => $Data->{'lang'}->txt($Defs::entityStatus{$dref->{'entityStatus'} || 0}) || '',
                    LocalShortName => $task->{'strLocalShortName'} || '',
                    LocalName => $task->{'strLocalName'} || '',
                    LegalID => $task->{'strLegalID'} || '',
                    FoundationDate => $task->{'dtFrom'} || '',
                    ISOCountry => $c->{$task->{'strISOCountry'}} || '',
                    Discipline => $Defs::entitySportType{$task->{'strDiscipline'}} || '',
                    ContactPerson => $task->{'strContact'} || '',
                    Email => $task->{'strEmail'} || '',
                    Website => $task->{'strWebURL'} || '',
                    EntityID => $task->{'intCreatedByEntityID'} || '',
                    ClubName => $clubName,
                },
                TaskAction => \%TaskAction,
            );
            $TemplateData{'EntitySummaryPanel'} = entitySummaryPanel($Data, $task->{'intEntityID'});

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
    my ($Data, $action, $selfUserAsEntityID) = @_;

    my $WFTaskID = safe_param('TID','number') || '';
    my $entityID = getID($Data->{'clientValues'},$Data->{'clientValues'}{'currentLevel'}) || $selfUserAsEntityID;

    my $task = getTask($Data, $WFTaskID);


    #return (" ", "Access forbidden.") if($entityID != $task->{'intApprovalEntityID'});

    my $title;
    my $titlePrefix;
    my $message;
    my $body;
    my $status;
    my $TaskType;

    my $st = qq[
        SELECT 
            strLocalName 
        FROM
            tblEntity 
        WHERE 
            intEntityID = ?
        LIMIT 1
    ];

    my $qt = $Data->{'db'}->prepare($st) or query_error($st);
    my $res = $qt->execute(
        $Data->{'clientValues'}{'regionID'}
    ) or query_error($st);

    my $raID = $qt->fetchrow_hashref();

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
    elsif($task->{'strWFRuleFor'} eq "PERSON") {
        $titlePrefix = $Defs::workTaskTypeLabel{$task->{'strRegistrationNature'} . "_PERSON"}; 
        $TaskType = $task->{'strRegistrationNature'} . "_PERSON";
    }

   switch($action) {
        case "WF_PR_H" {
            my $SysConfigOptionSuffix = 'HOLD';

            $title = $Data->{'lang'}->txt($titlePrefix) . ' - ' . $Data->{'lang'}->txt('On-Hold');
            
            if($TaskType eq 'TRANSFER_PLAYER') {
                $message = $Data->{'lang'}->txt("You have put this task on-hold, once the submitting Club resolves the issue, you would be able to verify and continue with the Transfer process.");
                $status = $Data->{'lang'}->txt("Pending");
            }
            if($TaskType eq 'DOMESTIC_LOAN_PLAYER') {
                $message = $Data->{'lang'}->txt("You have put this task on-hold, once the submitting Club resolves the issue, you would be able to verify and continue with the Player Loan process.");
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
                $message = $Data->{'SystemConfig'}{$TaskType . '_' . $SysConfigOptionSuffix};
                $message = $message ? $message : $Data->{'lang'}->txt("You have put this task on-hold, once the submitting MA resolves the issue, you would be able to verify and continue with the Referee Registration process.");
                $status = $Data->{'lang'}->txt("Pending");
            }
            elsif($TaskType eq 'NEW_MAOFFICIAL') {
                $message = $Data->{'lang'}->txt("You have put this task on-hold, once the submitting MA resolves the issue, you would be able to verify and continue with the MA Official Registration process.");
                $status = $Data->{'lang'}->txt("Pending");
            }
            elsif($TaskType eq 'NEW_RAOFFICIAL') {
                $message = $Data->{'lang'}->txt("You have put this task on-hold, once the submitting RA resolves the issue, you would be able to verify and continue with the RA Official Registration process.");
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
            elsif($TaskType eq 'AMENDMENT_PERSON') {
                $message = $Data->{'lang'}->txt("You have put this task on-hold, once the submitting Club resolves the issue, you would be able to verify and continue with the Amendment of Person Details process.");
                $status = $Data->{'lang'}->txt("Pending");
            }
            elsif($TaskType eq 'AMENDMENT_CLUB') {
                $message = $Data->{'lang'}->txt("You have put this task on-hold, once the submitting Organisation resolves the issue, you would be able to verify and continue with the Amendment of Club Details process.");
                $status = $Data->{'lang'}->txt("Pending");
            }
            elsif($TaskType eq 'AMENDMENT_VENUE') {
                $message = $Data->{'lang'}->txt("You have put this task on-hold, once the submitting Organisation resolves the issue, you would be able to verify and continue with the Amendment of Venue Details process.");
                $status = $Data->{'lang'}->txt("Pending");
            }
            elsif($TaskType =~ /^RENEWAL_/) {
                if($task->{'strTaskStatus'} eq 'HOLD'){
                    if ($task->{'strPersonType'} eq 'PLAYER') {
                     $message = $Data->{'lang'}->txt("You have placed this Player Renewal On Hold, the [_1] will be informed.",$raID->{'strLocalName'});
                     $status = $Data->{'lang'}->txt("Pending");
                    }elsif ($task->{'strPersonType'} eq 'CLUBOFFICIAL'){
                     $message = $Data->{'lang'}->txt("You have placed this Club Official Renewal On Hold, the [_1] will be informed.",$raID->{'strLocalName'});
                     $status = $Data->{'lang'}->txt("Pending");
                    }elsif($task->{'strPersonType'} eq 'MAOFFICIAL'){
                     $message = $Data->{'lang'}->txt("You have placed this MA Official Renewal On Hold, the [_1] will be informed.",$raID->{'strLocalName'});
                     $status = $Data->{'lang'}->txt("Pending");
                    }elsif($task->{'strPersonType'} eq 'TEAMOFFICIAL'){
                     $message = $Data->{'lang'}->txt("You have placed this Team Official Renewal On Hold, the [_1] will be informed.",$raID->{'strLocalName'});
                     $status = $Data->{'lang'}->txt("Pending");
                    }else{
                     $message = $Data->{'lang'}->txt("You have placed this [_1] Renewal On Hold, the [_1] will be informed.",ucfirst(lc($Data->{'lang'}->txt($task->{'strPersonType'}))), $raID->{'strLocalName'});
                     $status = $Data->{'lang'}->txt("Pending");
                    }
                }
            }

        }
        case "WF_PR_R" {

            $title = $Data->{'lang'}->txt($titlePrefix) . ' - ' . $Data->{'lang'}->txt('Rejected');
            
            if($TaskType eq 'TRANSFER_PLAYER') {
                $message = $Data->{'lang'}->txt("You have rejected this transfer, the clubs will be informed. To proceed with this transfer the clubs need to start a new transfer.");
                $status = $Data->{'lang'}->txt("Rejected");
            }
			elsif($TaskType eq 'DOMESTIC_LOAN_PLAYER'){
				$message = $Data->{'lang'}->txt("You have rejected the player loan of [_1] [_2]",$task->{'strLocalFirstname'}, $task->{'strLocalSurname'});
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
            elsif($TaskType eq 'NEW_RAOFFICIAL') {
                $message = $Data->{'lang'}->txt("You have rejected this RA Official Registration. To proceed with this Registration, start a new Registration.");
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

                if ($task->{'intCreatedByEntityID'} eq '1') {
                 $message = $Data->{'lang'}->txt("You have rejected this Venue Registration. To proceed with this Registration start a new Registration.");   
                } else {
                 $message = $Data->{'lang'}->txt("You have rejected this Venue Registration, the club will be informed. To proceed with this Registration the club need to start a new Registration.");   
                }
                
                $status = $Data->{'lang'}->txt("Rejected");
            }
            elsif($TaskType eq 'NEW_CLUB') {
                $message = $Data->{'lang'}->txt("You have rejected this Club Registration. To proceed with this Registration, start a new Registration.");
                $status = $Data->{'lang'}->txt("Rejected");
            }
            elsif($TaskType eq 'AMENDMENT_PERSON') {
                $message = $Data->{'lang'}->txt("You have rejected this Amendment of Person Registration.");
                $status = $Data->{'lang'}->txt("Rejected");
            }
            elsif($TaskType =~ /^RENEWAL_/) {
                if($task->{'strTaskStatus'} eq 'REJECTED'){
                    if ($task->{'strPersonType'} eq 'PLAYER') {
                     $message = $Data->{'lang'}->txt("You have rejected this Player Renewal. To proceed with this Renewal, start a new Renewal.");
                     $status = $Data->{'lang'}->txt("Rejected");
                    }elsif ($task->{'strPersonType'} eq 'CLUBOFFICIAL'){
                     $message = $Data->{'lang'}->txt("You have rejected this Club Official Renewal. To proceed with this Renewal, start a new Renewal.");
                     $status = $Data->{'lang'}->txt("Rejected");
                    }elsif($task->{'strPersonType'} eq 'MAOFFICIAL'){
                     $message = $Data->{'lang'}->txt("You have rejected this MA Official Renewal. To proceed with this Renewal, start a new Renewal.");
                     $status = $Data->{'lang'}->txt("Rejected");
                    }elsif($task->{'strPersonType'} eq 'RAOFFICIAL'){
                     $message = $Data->{'lang'}->txt("You have rejected this RA Official Renewal. To proceed with this Renewal, start a new Renewal.");
                     $status = $Data->{'lang'}->txt("Rejected");
                    }elsif($task->{'strPersonType'} eq 'TEAMOFFICIAL'){
                     $message = $Data->{'lang'}->txt("You have rejected this Team Official Renewal. To proceed with this Renewal, start a new Renewal.");
                     $status = $Data->{'lang'}->txt("Rejected");
                    }else{
                     $message = $Data->{'lang'}->txt("You have rejected this [_1] Renewal. To proceed with this Renewal, start a new Renewal.",ucfirst(lc($Data->{'lang'}->txt($task->{'strPersonType'}))));
                     $status = $Data->{'lang'}->txt("Rejected");
                    }
                }
            }
        }
        case "WF_PR_S" {
            $title = $Data->{'lang'}->txt($titlePrefix . ' - ' . 'Resolved');
            $message = $Data->{'lang'}->txt("You have resolved this task.");
            $status = $Data->{'lang'}->txt("Resolved");
        }
    }

    my $currentViewLevel = ($Data->{'clientValues'}{'currentLevel'} > 1) ? $Data->{'clientValues'}{'currentLevel'} : 1;

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
        'CurrentViewLevel' => $currentViewLevel
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
            $emailNotification->setData($Data);

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

    my ($workTaskType, $workTaskRule) = getWorkTaskType($Data, $task);
    my $cc = getCCRecipient($Data, $task);
    # 'Person' => $task->{'strLocalFirstname'} . ' ' . $task->{'strLocalSurname'}
    my %notificationData = (
        'Reason' => $task->{'holdNotes'},
        'WorkTaskType' => $workTaskType,
        'Person' => formatPersonName($Data, $task->{'strLocalFirstname'}, $task->{'strLocalSurname'}, ''), 
        'PersonRegisterTo' => $task->{'registerToEntity'},
        'Club' => $task->{'strLocalName'},
        'Venue' => $task->{'strLocalName'},
        'PersonRegisterTo' => $task->{'registerToEntity'},
        'RegistrationType' => $task->{'sysConfigApprovalLockRuleFor'},
        'CC' => $cc || '',
    );

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
            $emailNotification->setToOriginLevel($task->{'intOriginLevel'});
            $emailNotification->setDefsEmail($Defs::admin_email);
            $emailNotification->setDefsName($Defs::admin_email_name);
            $emailNotification->setNotificationType($nType);
            $emailNotification->setSubject($workTaskType);
            $emailNotification->setLang($Data->{'lang'});
            $emailNotification->setDbh($Data->{'db'});
            $emailNotification->setData($Data);
            $emailNotification->setWorkTaskDetails(\%notificationData);

            my $emailTemplate = $emailNotification->initialiseTemplate()->retrieve();
            $emailNotification->send($emailTemplate) if $emailTemplate->getConfig('toEntityNotification') == 1;
        }

        #resetRelatedTasks($Data, $WFTaskID, 'PENDING');

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
            AND intSentToGateway = 0
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

sub displayGenericError {
    my ($Data, $titleHeader, $message) = @_;

    $titleHeader ||= $Data->{'lang'}->txt("Error");
    my $body = runTemplate(
        $Data,
        {
            message => $message,
        },
        'personrequest/generic/error.templ',
    );

    return ($body, $titleHeader);
}

sub getRegistrationWorkTasks {
    my ($Data, $param) = @_;

    # %param = (
    #   'type' => (ENTITY|PERSON)
    #   'registrationid' => 
    #   'personid' => 
    #   'entityid' => 
    # );

    my $cond = '';
    my @values = ();

    switch($param->{'type'}) {
        case 'ENTITY' {
            $cond .= qq[ AND WT.intEntityID = ? ];
            push @values, $param->{'entityid'} || 0;
        }
        case 'PERSON' {
            $cond .= qq[ AND WT.intPersonID = ? AND WT.intPersonRegistrationID = ? ];
            push @values, $param->{'personid'} || 0;
            push @values, $param->{'registrationid'} || 0;
        }
    }

    my $st = qq[
        SELECT
            WT.intWFTaskID,
            WT.intApprovalEntityID,
            WT.intProblemResolutionEntityID,
            WR.intApprovalEntityLevel,
            WR.intProblemResolutionEntityLevel,
            AE.strLocalName AS approvalEntityLocalName,
            RE.strLocalName AS problemResolutionEntityLocalName,

            IF(WR.intApprovalEntityLevel = 3, 'club', '') as AEgetInstanceType,
            IF(WR.intApprovalEntityLevel = 20, 'region', '') as AEgetInstanceType,
            IF(WR.intApprovalEntityLevel = 100, 'national', '') as AEgetInstanceType,

            IF(WR.intProblemResolutionEntityLevel = 100, 'national', '') as REgetInstanceType,
            IF(WR.intProblemResolutionEntityLevel = 20, 'region', '') as REgetInstanceType,
            IF(WR.intProblemResolutionEntityLevel = 3, 'club', '') as REgetInstanceType
        FROM
            tblWFTask AS WT
            LEFT JOIN tblWFRule WR ON (WR.intWFRuleID = WT.intWFRuleID)
            LEFT JOIN tblEntity AE ON (AE.intEntityID = WT.intApprovalEntityID)
            LEFT JOIN tblEntity RE ON (RE.intEntityID = WT.intProblemResolutionEntityID)
        WHERE
            WT.intRealmID = $Data->{'Realm'}
            $cond
    ];

    my $q = $Data->{'db'}->prepare($st) or query_error($st);
	$q->execute(
        @values
	) or query_error($st);

	my @TaskNotes = ();
	my $rowCount = 0;

    my @workTaskHistory = ();

    while(my $tdref = $q->fetchrow_hashref()) {
        my $approvalEntity;
        my $problemResolutionEntity;
        my $taskType;

        switch($tdref->{'intProblemResolutionEntityLevel'}) {
            case 3 {
                $problemResolutionEntity = getInstanceOf($Data, 'club', $tdref->{'intProblemResolutionEntityID'});
            }
            case 20 {
                $problemResolutionEntity = getInstanceOf($Data, 'entity', $tdref->{'intProblemResolutionEntityID'});
            }
            case 100 {
                $problemResolutionEntity = getInstanceOf($Data, 'entity', $tdref->{'intProblemResolutionEntityID'});
            }
        }

        switch($tdref->{'intApprovalEntityLevel'}) {
            case 3 {
                $approvalEntity = getInstanceOf($Data, 'club', $tdref->{'intApprovalEntityID'});
                $taskType = $Data->{'lang'}->txt('Approval by Club');
            }
            case 20 {
                $approvalEntity = getInstanceOf($Data, 'entity', $tdref->{'intApprovalEntityID'});
                $taskType = $Data->{'lang'}->txt('Approval by Regional Association');
            }
            case 100 {
                $approvalEntity = getInstanceOf($Data, 'entity', $tdref->{'intApprovalEntityID'});
                $taskType = $Data->{'lang'}->txt('Approval by Member Association');
            }
        }

        my $workTaskNotes = populateTaskNotesViewData($Data, $tdref);
        my %TaskNotes = %{$workTaskNotes};

        my $notesBlock = runTemplate(
            $Data,
            \%TaskNotes,
            'workflow/generic/notes.templ'
        );

        my %taskhistory = (
            TaskID => $tdref->{'intWFTaskID'},
            TaskType => $taskType,
            ApprovalEntity => $approvalEntity ? $approvalEntity->name() : $Data->{'lang'}->txt("N/A"),
            ProblemResolutionEntity => $problemResolutionEntity ? $problemResolutionEntity->name() : $Data->{'lang'}->txt("N/A"),
            TaskNotes => $workTaskNotes->{'TaskNotes'},
            NotesBlock => $notesBlock,
        );

        push @workTaskHistory, \%taskhistory;
    }

    return \@workTaskHistory;
}

sub viewWorkFlowHistory {
    my ($Data, $WFTID) = @_;

    my $WFTaskID = safe_param('id','number') || $WFTID || '';
    return displayGenericError($Data, $Data->{'lang'}->txt("Error"), $Data->{'lang'}->txt("Invalid ID")) if !$WFTaskID;

    my $entityID = getID($Data->{'clientValues'}, $Data->{'clientValues'}{'authLevel'});
    my $entityLevel = $Data->{'clientValues'}{'authLevel'};
    my $task = getTask($Data, $WFTaskID);

    if (
        ($entityID == $task->{'intProblemResolutionEntityID'} and $entityLevel == $task->{'intProblemResolutionEntityLevel'})
        or
        ($entityID == $task->{'intApprovalEntityID'} and $entityLevel == $task->{'intApprovalEntityLevel'})
    ) {

        my ($workTaskType, $workTaskRule) = getWorkTaskType($Data, $task);
        my %params;
        switch($task->{strWFRuleFor}) {
            case ['REGO', 'PERSON'] {
                %params = (
                    type => 'PERSON',
                    registrationid => $task->{'intPersonRegistrationID'},
                    personid => $task->{'intPersonID'},
                );
            }
            case 'ENTITY' {
                %params = (
                    type => 'ENTITY',
                    entityid => $task->{'intEntityID'},
                );
            }
        }

        my $workTaskHistory = getRegistrationWorkTasks($Data, \%params);
        my $relatedWorkTaskHistory;

        foreach my $worktask (@{$workTaskHistory}) {
            next if $task->{'intWFTaskID'} != $worktask->{'TaskID'};
            $relatedWorkTaskHistory = $worktask;
        }

        $relatedWorkTaskHistory->{'RegistrationType'} = $workTaskType;
        my %TemplateData = (
            worktask => $relatedWorkTaskHistory,
        );

        my $body = runTemplate(
            $Data,
            \%TemplateData,
            'workflow/history.templ',
        );

        return ($body, $Data->{'lang'}->txt("Work Flow History"));
    }
    else {
        return displayGenericError($Data, $Data->{'lang'}->txt("Error"), $Data->{'lang'}->txt("No data retrieved/no access"))
    }

}

sub getCCRecipient {
    my ($Data, $task) = @_;

    my ($workTaskType, $workTaskRule) = getWorkTaskType($Data, $task);

    if(
        $task->{'intApprovalEntityID'} == $task->{'intProblemResolutionEntityID'}
        and $task->{'intEntityLevel'} != $task->{'intOriginLevel'}) {

        switch ($workTaskRule) {
            case "AMENDMENT_CLUB" {
                my $clubObj = getInstanceOf($Data, 'club', $task->{'intEntityID'});
                return $clubObj->getValue('strEmail') || '';
            }
            case "AMENDMENT_VENUE" {
                #TODO: confirm if parent entity's email or venue contact email address
            }
        }
    }

    return;
}

sub getInitialTaskAssignee {
     my(
        $Data,
        $personID,
        $registrationID,
        $entityID
    ) = @_;

    if($entityID){
        my $originLevel = $Data->{'clientValues'}{'authLevel'} || 0;
        my $st = qq[
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
            ORDER BY
                r.intApprovalEntityLevel
            LIMIT 1
		];
        my $q = $Data->{'db'}->prepare($st);
        $q->execute(
            $entityID,
            $Data->{'Realm'},
            $Data->{'RealmSubType'},
            $originLevel,
            'NEW'
        );

  	    $q->execute($entityID, $Data->{'Realm'}, , $originLevel, 'NEW');
        my $dref = $q->fetchrow_hashref();
        return $Defs::initialTaskAssignee{$dref->{'intApprovalEntityLevel'} || 100};
    }
    elsif($personID and $registrationID){
        my $st = qq[
            SELECT tr.*
            FROM tblWFRule tr
            INNER JOIN tblPersonRegistration_$Data->{'Realm'} tp
            ON (
                tp.strPersonType = tr.strPersonType
                AND tp.strPersonLevel = tr.strPersonLevel
                AND tp.strSport = tr.strSport
                AND tp.strAgeLevel = tr.strAgeLevel
                AND tr.strRegistrationNature = tp.strRegistrationNature
                AND tr.intOriginLevel = tp.intOriginLevel
            )
            INNER JOIN tblPerson p
            ON (
                p.intPersonID = tp.intPersonID
            )
            INNER JOIN tblEntity te
            ON (
                te.intEntityID = tp.intEntityID
            )
            WHERE
                tp.intPersonRegistrationID = ?
                AND tr.intEntityLevel = te.intEntityLevel
                AND tr.intRealmID = ?
                AND tr.strTaskStatus = 'ACTIVE'
                AND (tr.strISOCountry_IN IS NULL or tr.strISOCountry_IN = '' OR r.strISOCountry_IN LIKE CONCAT('%|',p.strISONationality ,'|%'))
                AND (tr.strISOCountry_NOTIN IS NULL or tr.strISOCountry_NOTIN = '' OR r.strISOCountry_NOTIN NOT LIKE CONCAT('%|',p.strISONationality ,'|%'))
            ORDER BY
                tr.intApprovalEntityLevel
            LIMIT 1
        ];

        my $q = $Data->{'db'}->prepare($st);
        $q->execute(
            $registrationID,
            $Data->{'Realm'}
        );

        my $dref = $q->fetchrow_hashref();
        return $Defs::initialTaskAssignee{$dref->{'intApprovalEntityLevel'} || 100};
    }
}

1;
