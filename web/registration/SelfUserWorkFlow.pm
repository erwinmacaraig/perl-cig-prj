package SelfUserWorkFlow;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = @EXPORT_OK = qw(
    handleSelfUserWorkFlow
);

use strict;
use lib '.', '..', '../..', "../../..", "../user", "user";

use TTTemplate;
use CGI qw(param);
use WorkFlow;
use Defs;
use Utils;
use Lang;
use Switch;
use PersonUtils;
use PersonUserAccess;
use EmailNotifications::WorkFlow;

use Data::Dumper;

sub handleSelfUserWorkFlow {
    my ($Data, $user, $action) = @_;

    switch($action){
        case "WF_L" {
            return listTasks($Data, $user);
        }
        case "WF_R" {
        }
        case "WF_V" {
            return selfUserViewTask($Data, $user);
        }
        case "WF_updateAction" {
            my $query = new CGI;
            # this will now filter any actions based on type (HOLD, RESOLVE, REJECT) from modal
            # approve remains the same (WF_Approve)
            my $WFTaskID = safe_param('TID', 'number') || '';
            my $notes= safe_param('notes','words') || '';
            my $type = safe_param('type','words') || '';
            my $regNature = safe_param('regNat','words') || '';

            switch($type) {
                case "$Defs::WF_TASK_ACTION_RESOLVE" {
                    updateTaskNotes($Data, $user->id());
                    my $actionMessage = selfUserResolveTask($Data, $user, $WFTaskID);

                    if(!$actionMessage) {
                        return displayGenericError($Data, $Data->{'lang'}->txt("Error"), $Data->{'lang'}->txt("Invalid access"));
                    }
                    else {
                        $Data->{'RedirectTo'} = "$Defs::base_url/registration/" . $Data->{'target'} . "?a=WF_PR_S&TID=$WFTaskID";
                        my ($body, $title) = redirectTemplate($Data);
                        return ($body, $title);
                    }
                }
                else {
                    return displayGenericError($Data, $Data->{'lang'}->txt("Error"), $Data->{'lang'}->txt("An invalid Action Code has been passed to me."));
                }
            }
        }
        case "WF_PR_S" {
            my ($body, $title) = selfUserUpdateTaskScreen($Data, $action, $user);
            return ($body, $title);
        }
        else {
            return listTasks($Data, $user);
        }

    }
}

sub listTasks {
    my ($Data, $user) = @_;

	my $body = '';
   	my $st = '';
	my $q = '';
	my $db=$Data->{'db'};

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
            p.intSystemStatus,
            p.strLocalFirstname, 
            p.strLocalSurname, 
            p.intGender as PersonGender,
            e.strLocalName as EntityLocalName,
            p.intPersonID,
            t.strTaskStatus,
            t.strWFRuleFor,
            e.intEntityID,
            e.intEntityLevel,
            t.intApprovalEntityID,
            t.intProblemResolutionEntityID,
            t.strTaskNotes as TaskNotes,
            e.intCreatedByEntityID as CreatedByEntityID
	    FROM
            tblWFTask AS t
        LEFT JOIN tblEntity as e ON (e.intEntityID = t.intEntityID)
		LEFT JOIN tblPersonRegistration_$Data->{'Realm'} AS pr ON (t.intPersonRegistrationID = pr.intPersonRegistrationID)
		LEFT JOIN tblPerson AS p ON (t.intPersonID = p.intPersonID)
		INNER JOIN tblSelfUserAuth AS sua ON (sua.intEntityID = p.intPersonID)
		WHERE
            t.intRealmID = $Data->{'Realm'}
            AND t.strTaskStatus = "$Defs::WF_TASK_STATUS_HOLD"
            AND pr.intOriginLevel = 1
            AND pr.intCreatedByUserID = ?
            AND sua.intSelfUserID = ?
    ];

	$db=$Data->{'db'};
	$q = $db->prepare($st) or query_error($st);
	$q->execute(
        $user->id(),
        $user->id()
	) or query_error($st);

	my @TaskList = ();
    my @taskType = ();
    my @taskStatus = ();
    my %taskCounts;

	my $rowCount = 0;

    my $taskTypeLabel = "";
	while(my $dref= $q->fetchrow_hashref()) {
        next if ($dref->{strTaskStatus} eq $Defs::WF_TASK_STATUS_REJECTED);
        next if (defined $dref->{intSystemStatus} && $dref->{intSystemStatus} eq $Defs::PERSONSTATUS_POSSIBLE_DUPLICATE && $dref->{strWFRuleFor} ne $Defs::WF_RULEFOR_PERSON);

        my $newTask = ($dref->{'taskTimeStamp'} >= $lastLoginTimeStamp) ? 1 : 0;
        $taskCounts{$dref->{'strTaskStatus'}}++;
        $taskCounts{$dref->{'strRegistrationNature'}}++;
        $taskCounts{"newTasks"}++ if $newTask;

        my $name = formatPersonName($Data, $dref->{'strLocalFirstname'}, $dref->{'strLocalSurname'}, $dref->{'PersonGender'}) if ($dref->{strWFRuleFor} eq 'REGO' or $dref->{strWFRuleFor} eq 'PERSON');

        my $showResolve = 1;
        my $showView = 1;

        my $viewTaskURL = "$Data->{'target'}?&amp;a=WF_V&TID=$dref->{'intWFTaskID'}";
        my $taskTypeLabel = '';

        my $ruleForType = "";
        if($dref->{'strWFRuleFor'} eq "REGO") {
            $ruleForType = $dref->{'strRegistrationNature'} . "_" . $dref->{'strPersonType'};
        }
        elsif($dref->{'strWFRuleFor'} eq "PERSON") {
            $ruleForType = $dref->{'strRegistrationNature'} . "_PERSON";
        }

        my %single_row = (
            WFTaskID => $dref->{intWFTaskID},
            TaskDescription => "",
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
            viewURL => "",
            showReject => 0,
            showApprove => 0,
            showResolve => 1,
            showView => 1,
            OnHold => $dref->{OnHold},
            taskDate => $dref->{taskDate},
            viewURL => $viewTaskURL,
            taskTypeLabel => $viewTaskURL,
            taskTimeStamp => $dref->{'taskTimeStamp'},
            newTask => $newTask,
        );
   
        if(!($Defs::workTaskTypeLabel{$ruleForType} ~~ @taskType)){
            push @taskType, $Defs::workTaskTypeLabel{$ruleForType};
        }

        if(!($Defs::wfTaskStatus{$dref->{strTaskStatus}} ~~ @taskStatus)){
            push @taskStatus, $Defs::wfTaskStatus{$dref->{strTaskStatus}};
        }

        push @TaskList, \%single_row;

    }

    my @sortedTaskList = sort { $b->{'taskTimeStamp'} <=> $a->{'taskTimeStamp'}} @TaskList;

    my %taskFilters = (
        'type' => \@taskType,
        'status' => \@taskStatus,
    );

    my $msg = '';
        if ($rowCount == 0) {
        $msg = $Data->{'lang'}->txt('No outstanding tasks');
    }
    else {
        $msg = $Data->{'lang'}->txt('The following are the outstanding tasks to be authorised');
    };


    my %TemplateData = (
        MA_allowTransfer => $Data->{'SystemConfig'}{'MA_allowTransfer'} || 0,
        TaskList => \@sortedTaskList,
        PersonType => \%Defs::personType,
        CurrentLevel => 1,
        TaskCounts => \%taskCounts,
        TaskMsg => $msg,
        TaskEntityID => 0,
        TaskFilters => \%taskFilters,
        client => $Data->{client},
        Levels => {
            CLUB => $Defs::LEVEL_CLUB,
            NATIONAL => $Defs::LEVEL_NATIONAL,	
            REGION => $Defs::LEVEL_REGION,
        },
    );

    $body = runTemplate(
        $Data,
        \%TemplateData,
        'selfrego/worktasks.templ',
    );

    return ($body, $Data->{'lang'}->txt('Self Registration Work Tasks'));

}

sub selfUserViewTask {
    my ($Data, $user) = @_;

    my $WFTaskID = safe_param('TID','number') || 0;
    my ($body, $title) = viewTask($Data, 0, $user->id());

    return ($body, $title);
}

sub selfUserResolveTask {
    my ($Data, $user, $WFTaskID) = @_;

    my $emailNotification = new EmailNotifications::WorkFlow();
    return resolveTask($Data, $emailNotification, $WFTaskID, $user->id());

}

sub selfUserUpdateTaskScreen {
    my ($Data, $action, $user) = @_;

    return updateTaskScreen($Data, $action, $user->id());
}

1;

