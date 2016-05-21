package PersonRegistrationDetail;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = @EXPORT_OK = qw(
    personRegistrationDetail
);

use strict;
use WorkFlow;
use Defs;

#use Log;
use TTTemplate;
use Data::Dumper;
use PersonUtils;
use PersonRegistration;
use Reg_common;
use HTMLForm;
use FormHelpers;
use GridDisplay;
use RecordTypeFilter;
use PersonRegistrationStatusChange;

use FlashMessage;

sub personRegistrationDetail   {

    my ($action, $Data, $entityID, $personRegistrationID) = @_;

    my $flashMessage = getFlashMessage($Data, 'PRS_UPDATE');

    my $RegistrationDetail = PersonRegistration::getRegistrationDetail($Data, $personRegistrationID);
    $RegistrationDetail = pop $RegistrationDetail;

    my $option = $Data->{'clientValues'}{'authLevel'} >= $Defs::LEVEL_NATIONAL ? 'edit' : 'display';

    my $currentRegStatus = $RegistrationDetail->{'strStatus'};
    
    my $client=setClient($Data->{'clientValues'}) || '';
    
    my $intRelamID = $Data->{'Relam'} ? $Data->{'Realm'} : 0;
    my %statusoptions = ();

    for my $key (keys %Defs::personRegoStatus) {
        next if(!$key or $key eq $Defs::PERSONREGO_STATUS_ACTIVE_PENDING_PAYMENT);

        $statusoptions{$key} = ($key eq 'ACTIVE' and $RegistrationDetail->{'intPaymentRequired'} and $RegistrationDetail->{'strStatus'} eq 'ACTIVE') ? $Defs::personRegoStatus{$Defs::PERSONREGO_STATUS_ACTIVE_PENDING_PAYMENT} : $Defs::personRegoStatus{$key};
    }

    my %FieldDefinitions = (
        fields => {
            strStatus => {
                label => 'Status',
                #value => uc($RegistrationDetail->{'Status'}),
                value => $RegistrationDetail->{'strStatus'},
                type => 'lookup',
                options => \%statusoptions,
                readonly => $Data->{'clientValues'}{'authLevel'} >= $Defs::LEVEL_NATIONAL ? 0 : 1,
                translateLookupValues => 1,
            },
            strAgeLevel => {
                label => 'Age Level',
                value => $Data->{'lang'}->txt($Defs::ageLevel->{$RegistrationDetail->{'AgeLevel'}}),
                type => 'text',
                readonly => 1,
            },
            strSport => {
                label => 'Sport',
                value => $Data->{'lang'}->txt($RegistrationDetail->{'Sport'}),
                type => 'text',
                readonly => 1,
            },
            strGender => {
                label => 'Gender',
                value => $Data->{'lang'}->txt($Defs::genderInfo->{$RegistrationDetail->{'intGender'}}),
                type => 'text',
                readonly => 1,
            },
            strRegistrationNature => {
                label => 'Registration Type',
                value => $Data->{'lang'}->txt($RegistrationDetail->{'RegistrationNature'}),
                type => 'text',
                readonly => 1,
            },
            strNationalPeriodName=> {
                label => 'Registration Period',
                value => $Data->{'lang'}->txt($RegistrationDetail->{'strNationalPeriodName'}),
                type => 'text',
                readonly => 1,
            },
            strPersonType => {
                label => 'Type',
                value => $Data->{'lang'}->txt($RegistrationDetail->{'PersonType'}),
                type => 'text',
                readonly => 1,
            },
            strPersonLevel => {
                label => 'Level',
                value => $Data->{'lang'}->txt($RegistrationDetail->{'PersonLevel'}),
                type => 'text',
                readonly => 1,
            },
            DateRego=> {
                label => 'Date Registration Added',
                value => $Data->{'l10n'}{'date'}->TZformat($RegistrationDetail->{'dtApproved'},'MEDIUM','SHORT'),
                type => 'text',
                readonly => 1,
            },
            strShortNotes => {
                label => 'Notes',
                value => $RegistrationDetail->{'strShortNotes'},
                type => 'text',
                readonly => $Data->{'clientValues'}{'authLevel'} >= $Defs::LEVEL_NATIONAL ? 0 : 1,
            },
        },
        order => [qw(
            strNationalPeriodName
            strStatus
            strAgeLevel
            strSport
            strGender
            strRegistrationNature
            strPersonType
            DateRego
            strShortNotes
        )],
        options => {
            labelsuffix => ':',
            hideblank => 1,
            target => $Data->{'target'},
            formname => 'n_form',
            submitlabel => $Data->{'lang'}->txt('Update'),
            NoHTML => 1,
            updateSQL => qq[UPDATE tblPersonRegistration_$Data->{'Realm'} SET --VAL--
            WHERE intPersonRegistrationID=$personRegistrationID LIMIT 1],
            addSQL => qq[],

            #afteraddFunction => ,
            afteraddParams => [$option, $Data, $Data->{'db'}],
            afterupdateFunction => \&postPersonRegistrationUpdate,
            afterupdateParams => [$Data, $Data->{'db'}, $personRegistrationID, $currentRegStatus],
            LocaleMakeText => $Data->{'lang'},
        },
        carryfields =>  {
            client => $client,
            a => $action,
            prID => $personRegistrationID,
        },
        
    );

    #$personRegistrationID
    my $resultHTML = '';
    ($resultHTML, undef) = handleHTMLForm(\%FieldDefinitions, undef, $option, '', $Data->{'db'});
    
    my $workTasks = personRegistrationWorkTasks($Data, $personRegistrationID);
    my $regoStatusChangeLog = getPersonRegistrationStatusChangeLog($Data, $personRegistrationID);

    return $flashMessage . $resultHTML . $workTasks . $regoStatusChangeLog;

    #print STDERR Dumper $RegistrationDetail;

    ## Needs to use PersonRegistration::getRegistrationDetail
    ## Needs to get list (SQL fine) of tasks and the Entity who is tasked with each row.... see SQL in PendingRegistrations.pm for SQL example
    ## Needs to be in a template/
    ## For top half, use HTMLForm so Status can be changed if $Data->{'clientValues'}{'authLevel'} >= $Defs::LEVEL_NATIONAL or $Data->{'SystemConfig'}{'ChangePRStatus_Level'} >= $Data->{'clientValues'}{'authLevel'} -- so basically we can set a tblSystemConfig value to what level can change per Realm.  "ChangePRStatus_Level" would be the name of the key-value pair in tblSystemConfig
    #return "NEED PAGE FOR A REGISTRATION RECORD - This will show at top the full detail of the Registration, then a table at bottom showing the list of tasks";
    ## Used for both Registration History from Person level and Pending Registrations from an Entity.
}

  sub postVenueUpdate {
    my($id,$params,$action,$Data,$db, $entityID)=@_;
    return undef if !$db;
    $entityID ||= $id || 0;
  
    $Data->{'cache'}->delete('swm',"VenueObj-$entityID") if $Data->{'cache'};
  
  }

sub postPersonRegistrationUpdate  {
    my($id,$params,$Data,$client,$personRegistrationID, $currentStatus)=@_;

    my $cgi              = new CGI;
    my %params           = $cgi->Vars();

    addPersonRegistrationStatusChangeLog($Data, $personRegistrationID, $currentStatus, $params->{'d_strStatus'}, 0);

    my %flashMessage;
    $flashMessage{'flash'}{'type'} = 'success';
    $flashMessage{'flash'}{'message'} = $Data->{'lang'}->txt('Record updated successfully');
    setFlashMessage($Data, 'PRS_UPDATE', \%flashMessage);

    $Data->{'RedirectTo'} = "$Defs::base_url/" . $Data->{'target'} . "?client=$Data->{'client'}&a=P_REGO&prID=$personRegistrationID";
}

sub personRegistrationWorkTasks {

    my ($Data, $personRegistrationID) = @_;

    my $lang = $Data->{'lang'};
    my $client = setClient($Data->{'clientValues'}) || '';

    my %RegFilters = ();
    my $st = qq[
        SELECT
            pr.*,
            p.strLocalFirstname,
            p.strLocalSurname,
            p.strLatinFirstname,
            p.strLatinSurname,
            np.strNationalPeriodName,
            p.dtDOB,
            DATE_FORMAT(p.dtDOB, "%d/%m/%Y") as DOB,
            p.intGender,
            p.intGender as Gender,
            DATE_FORMAT(pr.dtAdded, "%Y%m%d%H%i") as dtAdded_,
            DATE_FORMAT(pr.dtAdded, "%Y-%m-%d %H:%i") as dtAdded_formatted,
            DATE_FORMAT(pr.dtLastUpdated, "%Y%m%d%H%i") as dtLastUpdated_,
            er.strEntityRoleName,
            WFT.strTaskType as WFTTaskType,
            WFT.intWFTaskID as WFTTaskID,
            WFT.strTaskStatus as WFTTaskStatus,
            ApprovalEntity.strLocalName as ApprovalLocalName,
            ApprovalEntity.strLatinName as ApprovalEntityName,
            RejectedEntity.strLocalName as RejectedLocalName,
            RejectedEntity.strLatinName as RejectedEntityName,
		WR.intAutoActivateOnPayment
        FROM
            tblPersonRegistration_$Data->{'Realm'} AS pr
            LEFT JOIN tblNationalPeriod as np ON (
                np.intNationalPeriodID = pr.intNationalPeriodID
            )
            LEFT JOIN tblEntityTypeRoles as er ON (
                er.strEntityRoleKey = pr.strPersonEntityRole
                and er.strPersonType = pr.strPersonType
            )
            INNER JOIN tblPerson as p ON (
                p.intPersonID = pr.intPersonID
            )
            INNER JOIN tblWFTask as WFT ON (
                WFT.intPersonRegistrationID = pr.intPersonRegistrationID
                AND WFT.intPersonID = pr.intPersonID
                #AND WFT.strTaskStatus IN ('ACTIVE')
            )
		LEFT JOIN tblWFRule as WR ON (
			WR.intWFRuleID = WFT.intWFRuleID
		)
            LEFT JOIN tblEntity as ApprovalEntity ON (
                ApprovalEntity.intEntityID = WFT.intApprovalEntityID
            )
            LEFT JOIN tblEntity as RejectedEntity ON (
                RejectedEntity.intEntityID = WFT.intProblemResolutionEntityID  AND WR.intProblemResolutionEntityLevel > 1
            )
        WHERE
            p.intRealmID = ?
            AND pr.intPersonRegistrationID = ?
            AND pr.strStatus IN ('ACTIVE', 'PENDING', 'REJECTED')
        ORDER BY
          pr.dtAdded DESC
    ];

    my $results=0;
    my @rowdata = ();
    my $query = $Data->{'db'}->prepare($st);
    $query->execute(
        $Data->{'Realm'},
        $personRegistrationID
    );
    while (my $dref = $query->fetchrow_hashref) {
        $results++;
        my $localname = formatPersonName($Data, $dref->{'strLocalFirstname'}, $dref->{'strLocalSurname'}, $dref->{'intGender'});
        my $name = formatPersonName($Data, $dref->{'strLatinFirstname'}, $dref->{'strLatinSurname'}, $dref->{'intGender'});
        my $local_latin_name = $localname;
        $local_latin_name .= qq[ ($name)] if ($name and $name ne ' ');

        my $entitylocalname = $dref->{'ApprovalLocalName'};
        my $taskTo= $entitylocalname;
        $taskTo.= qq[ ($dref->{'ApprovalEntityName'})] if ($dref->{'ApprovalEntityName'});
        
        if ($dref->{'strStatus'} eq $Defs::WF_TASK_STATUS_REJECTED) {
            $entitylocalname = $dref->{'RejectedLocalName'};
            $taskTo= $entitylocalname;
            $taskTo.= qq[ ($dref->{'RejectedEntityName'})] if ($dref->{'RejectedEntityName'});
        }

	my $status= $Defs::wfTaskStatus{$dref->{'WFTTaskStatus'}} || '';
	if ($dref->{'intAutoActivateOnPayment'})        {
                $status = $lang->txt('Approved upon Payment');
                $taskTo='-';
        }
        push @rowdata, {
            id => $dref->{'WFTTaskID'} || 0,
            dtAdded=>  $Data->{'l10n'}{'date'}->TZformat($dref->{'dtApproved'},'MEDIUM','SHORT') || '',
            PersonLevel=> $Data->{'lang'}->txt($Defs::personLevel{$dref->{'strPersonLevel'}}) || '',
            PersonEntityRole=> $dref->{'strEntityRoleName'} || '',
            PersonType=> $Data->{'lang'}->txt($Defs::personType{$dref->{'strPersonType'}}) || '',
            AgeLevel=> $Data->{'lang'}->txt($Defs::ageLevel{$dref->{'strAgeLevel'}}) || '',
            RegistrationNature=> $Data->{'lang'}->txt($Defs::registrationNature{$dref->{'strRegistrationNature'}}) || '',
            Status=> $status,
            PersonEntityRole=> $dref->{'strPersonEntityRole'} || '',
            Sport=> $Data->{'lang'}->txt($Defs::sportType{$dref->{'strSport'}} || ''),
            LocalName=>$localname,
            LatinName=>$name,
            LocalLatinName=>$local_latin_name,
            CurrentTask=>$dref->{'WFTTaskType'},
            CurrentTaskApproval=>$dref->{'intApprovalEntityID'},
            CurrentTaskProblem=>$dref->{'intProblemResolutionEntityID'},
            NationalPeriodName => $dref->{'strNationalPeriodName'} || '',
            TaskType => $Data->{'lang'}->txt($Defs::wfTaskType{$dref->{'WFTTaskType'}} || ''),
            TaskTo=>$taskTo,
            #SelectLink => "$Data->{'target'}?client=$client&amp;a=PENDPR_D&amp;prID=$dref->{'intPersonRegistrationID'}",
            SelectLink => "$Data->{'target'}?client=$client&amp;a=WF_H&amp;id=$dref->{'WFTTaskID'}",
          };
    }

    my $rectype_options = '';
    my @headers = (
        {
            name   => $Data->{'lang'}->txt('Registration Type'),
            field  => 'RegistrationNature',
            width  => 30,
            defaultShow => 1,
        },
        {
            name   => $Data->{'lang'}->txt('Name'),
            field  => 'LocalLatinName',
            width  => 30,
            defaultShow => 1,
        },
        {
            name   => $Data->{'lang'}->txt('Sport'),
            field  => 'Sport',
            width  => 40,
        },
        {
            name   => $Data->{'lang'}->txt('Age Level'),
            field  => 'AgeLevel',
            width  => 40,
        },
        {
            name  => $Data->{'lang'}->txt('Task Status'),
            field => 'Status',
            width  => 40,
            defaultShow => 1,
        },
        {
            name  => $Data->{'lang'}->txt('Assigned To'),
            field => 'TaskTo',
            width  => 40,
        },
        {
            name  => $Data->{'lang'}->txt('Problem Resolution'),
            field => '',
            width  => 40,
        },
        {
            name  => $Data->{'lang'}->txt('Task Type'),
            field => 'SelectLink',
            width  => 50,
            defaultShow => 1,
        },
        #{
        #    name  => $Data->{'lang'}->txt('Task Assigned To'),
        #    field => 'TaskTo',
        #    width  => 70,
        #},
        #{
        #    name  => $Data->{'lang'}->txt('Date Registration Added'),
        #    field => 'dtAdded',
        #    width  => 50,
        #},
    );

    my $filterfields = [
        {
            field     => 'strLocalName',
            elementID => 'id_textfilterfield',
            type      => 'regex',
        },
        {
            field     => 'strStatus',
            elementID => 'dd_actstatus',
            allvalue  => 'ALL',
        },
    ];

    my $grid  = showGrid(
        Data    => $Data,
        columns => \@headers,
        rowdata => \@rowdata,
        gridid  => 'grid',
        width   => '100%',
        filters => $filterfields,
        gridtitle => $Data->{'lang'}->txt('Work Task Log'),
    );

    my $resultHTML = qq[
        <div class="grid-filter-wrap">
            <div style="width:100%;">$rectype_options</div>
            $grid
        </div>
    ];

    return $resultHTML;
}

1;
