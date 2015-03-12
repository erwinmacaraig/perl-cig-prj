package PersonRequest;
require Exporter;
@ISA = qw(Exporter);

@EXPORT = @EXPORT_OK = qw(
    handlePersonRequest
    listPersonRecord
    getRequests
    listRequests
    finaliseTransfer
    setRequestStatus
);

use lib ".", "..";
use strict;
use TTTemplate;
use GridDisplay;
use Reg_common;
use Utils;
use AuditLog;
use PersonRegistration;
use Person;
use EmailNotifications::PersonRequest;
use Search::Person;
use PersonSummaryPanel;
use InstanceOf;

use CGI qw(unescape param redirect);
use Log;
use Data::Dumper;
use SystemConfig;
use Countries;
use Switch;
use SphinxUpdate;
use InstanceOf;
use PersonEntity;
use PersonUtils;
use TemplateEmail;
use Flow_DisplayFields;


sub handlePersonRequest {
    my ($action, $Data) = @_;

    my $title = undef;
    my $body = undef;

    my %TemplateData = (
        Lang => $Data->{'lang'},
        client => $Data->{'client'},
        target => $Data->{'target'},
    );

    switch($action) {
        case 'PRA_T' {
            my $transferTypeOption = undef;
            my $defaultTypeChecked = undef;
            foreach my $transferType (sort keys %Defs::personTransferType) {
                $defaultTypeChecked = 'checked="checked"' if($transferType eq $Defs::TRANSFER_TYPE_DOMESTIC);
                $transferTypeOption .= "<input type='radio' name='transfer_type' $defaultTypeChecked value='$transferType'>$Defs::personTransferType{$transferType}</input>";
                $defaultTypeChecked = '';
            }
            $title = $Data->{'lang'}->txt('Request/Initiate a Transfer');

            $TemplateData{'action'} = 'PRA_search';
            $TemplateData{'request_type'} = 'transfer';
            $TemplateData{'Lang'} = $Data->{'lang'};
            $TemplateData{'client'} = $Data->{'client'};
            $TemplateData{'target'} = $Data->{'target'};
            #$TemplateData{'transferTypeOption'} = $transferTypeOption;
            #$TemplateData{'script'} = qq[
            #    <script>
            #        jQuery(document).ready(function(){
            #            jQuery(":radio[name=transfer_type]").click(function(){
            #                jQuery("div#international").slideToggle("fast");
            #                jQuery("div#domestic").slideToggle("fast");

            #                //if(jQuery(this).val() == "DOMESTIC"){
            #                //    jQuery("div#domestic").show();
            #                //    jQuery("div#international").hide();
            #                //} else {
            #                //    jQuery("div#domestic").show();
            #                //    jQuery("div#international").hide();                           
            #                //}
            #            });
            #        });
            #    </script>
            #];

            $body = runTemplate(
                $Data,
                \%TemplateData,
                'personrequest/generic/search_form.templ',
            );
        }
        case 'PRA_R' {
            return;

            $title = $Data->{'lang'}->txt('Request Access to Person Details');
            $TemplateData{'request_type'} = 'access';
            $TemplateData{'action'} = 'PRA_getrecord';
            $body = runTemplate(
                $Data,
                \%TemplateData,
                'personrequest/generic/search_form.templ',
            );
        }
        case 'PRA_search' {
            ($body, $title) = listPeople($Data);
        }
        case 'PRA_getrecord' {
            ($body, $title) = listPersonRecord($Data);
        }
        case 'PRA_initRequest' {
            ($body, $title) = initRequestPage($Data);
        }
        case 'PRA_submit' {
            ($body, $title) = submitRequestPage($Data);
        }
        case 'PRA_L' {
            ($body, $title) = listRequests($Data,0);
        }
        case 'PRA_V' {
            ($body, $title) = viewRequest($Data);
        }
        case 'PRA_VR' {
            my $readonly = 1;
            ($body, $title) = viewRequestHistory($Data, $readonly);
        }
        case 'PRA_S' {
            ($body, $title) = setRequestResponse($Data);
        }
        case 'PRA_NC' {
            ($body, $title) = displayNoITC($Data);
        }
		case 'PRA_NC_PROC' {
			($body,$title) = sendITC($Data);
		}
        case 'PRA_F' {
            ($body, $title) = displayCompletedRequest($Data);
        }
        else {
        }
    }

	return ($body, $title);
}

sub listPeople {
    my ($Data) = @_;

    my $searchKeyword = safe_param('search_keyword','words') || '';
    my $sphinx = Sphinx::Search->new;
    my %results = ();
    my $rawResult = 1;

    my %TemplateData = (
        'action' => 'PRA_search',
        'request_type' => '',
        'Lang' => $Data->{'lang'},
        'client' => $Data->{'client'},
        'target' => $Data->{'target'},
        'search_keyword' => $searchKeyword,
    );

    $sphinx->SetServer($Defs::Sphinx_Host, $Defs::Sphinx_Port);
    $sphinx->SetLimits(0,1000);

    my $personSearchObj = new Search::Person();
    $personSearchObj
        ->setRealmID($Data->{'Realm'})
        ->setSubRealmID(0)
        ->setSearchType("transfer")
        ->setData($Data)
        ->setKeyword($searchKeyword)
        ->setSphinx($sphinx)
        ->setGridTemplate("personrequest/transfer/search_result.templ");

    my $resultGrid = $personSearchObj->process();

    if(!$resultGrid){
        $TemplateData{'searchResultGrid'}{'count'} = 0;
    }
    else {
        $TemplateData{'searchResultGrid'}{'count'} = 1;
        $TemplateData{'searchResultGrid'}{'data'} = $resultGrid;
    }

    my $body = runTemplate(
        $Data,
        \%TemplateData,
        'personrequest/generic/search_form.templ',
    );

    return ($body, "Result");
}

sub listPersonRecord {
    my ($Data) = @_;

	my $p = new CGI;
	my %params = $p->Vars();

    my $client = setClient( $Data->{'clientValues'} ) || '';
	my $entityID = getID($Data->{'clientValues'}, $Data->{'clientValues'}{'currentLevel'});

    my $searchKeyword = safe_param('search_keyword','words') || '';
    $searchKeyword =~ s/\h+/ /g;
    $searchKeyword =~ s/^\s+|\s+$//;
    my $firstname = safe_param('firstname','words') || '';
    my $lastname = safe_param('lastname','words') || '';
    #TODO: might need to validate dob or use jquery datepicker
    my $dob = $params{'dob'} || '';
    my $request_type = $params{'request_type'} || '';
    my $transferType = safe_param('transfer_type', 'word') || '';

    my $title = $Data->{'lang'}->txt('Search Result');
    my %result;

    #TODO: might use priority column in the query, then limit the result to 1 grouped by club
    # FOOTBALL  | 1
    # FUTSAL    | 2
    # ACTIVE    | 1
    # PASSIVE   | 2
    # PENDING   | 3

    
    my $requestType = getRequestType();
    
    my $requestAccessCond = undef;
    my $joinCondition = '';
    my $orderBy = '';
    my $limit = '';
    my $groupBy = '';

    if($requestType eq $Defs::PERSON_REQUEST_ACCESS) {
        $joinCondition = qq [
            AND (
                (strPersonType = 'PLAYER' and strSport = 'FOOTBALL')
                OR
                (strPersonType != 'PLAYER' or strSport != 'FOOTBALL')
                )
        ];
        $orderBy = qq[
            ORDER BY
                CASE WHEN PR.strPersonType = 'PLAYER' AND PR.strSport = 'FOOTBALL' THEN personLevelWeight END desc,
                CASE WHEN PR.strPersonType != 'PLAYER' AND PR.strSport != 'FOOTBALL' THEN PR.dtAdded END asc
        ];
        #$limit = qq[ LIMIT 1 ];
    }
    elsif($requestType eq $Defs::PERSON_REQUEST_TRANSFER) {
        $joinCondition = qq [ AND PR.strPersonType = 'PLAYER' ];
        $groupBy = qq [ GROUP BY PR.strSport, PR.intEntityID ];
        $orderBy = qq[
            ORDER BY
                CASE WHEN PR.strPersonType = 'PLAYER' AND PR.strSport = 'FOOTBALL' THEN personLevelWeight END desc,
                CASE WHEN PR.strPersonType != 'PLAYER' AND PR.strSport != 'FOOTBALL' THEN PR.dtAdded END asc
        ];
        #$limit = qq[ LIMIT 1 ];
    }

    my $st = qq[
        SELECT
            E.intEntityID,
            E.strLocalName as currentClub,
            P.intPersonID,
            P.strLocalFirstname,
            P.strLocalSurname,
            P.strStatus as personStatus,
            P.dtDOB,
            P.strNationalNum,
            PR.intPersonRegistrationID,
            PR.strStatus as personRegistrationStatus,
            PR.strPersonType,
            PR.strSport,
            PR.strPersonLevel,
            IF(PR.strPersonLevel = 'PROFESSIONAL', 3, IF(PR.strPersonLevel = 'AMATEUR', 2, 1)) as personLevelWeight,
            ePR.intPersonRegistrationID as currEntityPendingRegistrationID,
            ePR.intPersonRequestID as currEntityPendingRequestID,
            eRQ.intPersonRequestID as existPendingRequestID
        FROM
            tblPerson P
        INNER JOIN tblPersonRegistration_$Data->{'Realm'} PR
            ON (
                PR.intEntityID != ?
                AND PR.intPersonID = P.intPersonID
                AND PR.intRealmID = P.intRealmID
                AND PR.strStatus IN ('ACTIVE', 'PASSIVE','PENDING')
                $joinCondition
                )
        LEFT JOIN tblPersonRequest as eRQ
            ON  (
                eRQ.intPersonRequestID = PR.intPersonRequestID
                )
        LEFT JOIN tblPersonRegistration_$Data->{'Realm'} ePR
            ON (
                ePR.intEntityID = ?
                AND ePR.intPersonID = P.intPersonID
                AND ePR.intRealmID = P.intRealmID
                AND ePR.strStatus IN ('PENDING')
                AND ePR.strSport = PR.strSport
                AND ePR.strPersonType = PR.strPersonType
            )
        LEFT JOIN tblEntity E 
            ON (E.intEntityID = PR.intEntityID and E.intRealmID = PR.intRealmID)
        WHERE
            P.intRealmID = ?
            AND P.strStatus IN ('REGISTERED', 'PASSIVE','PENDING')
            AND
                (P.strNationalNum = ? OR CONCAT_WS(' ', P.strLocalFirstname, P.strLocalSurname) LIKE CONCAT('%',?,'%') OR CONCAT_WS(' ', P.strLocalSurname, P.strLocalFirstname) LIKE CONCAT('%',?,'%'))
        $groupBy
        $orderBy
        $limit
    ];
    #(P.strNationalNum = ? OR P.strLocalFirstname LIKE CONCAT('%',?,'%') OR P.strLocalSurname LIKE CONCAT('%',?,'%'))

    my $db = $Data->{'db'};
    my $q = $db->prepare($st) or query_error($st);
    $q->execute(
        $entityID,
        $entityID,
        $Data->{'Realm'},
        $searchKeyword,
        $searchKeyword,
        $searchKeyword
    ) or query_error($st);

    my $found = 0;
    my @rowdata = ();
    my %groupResult;
    my @tData = ();
    my $existsInRequestingClub = 0;
    my @personCurrentClubs;
    my @personCurrentRegistrations;
    my @personCurrentSports;
    my $personLname = '';
    my $personFname = '';
    my $personMID = '';
    my $personID = '';
    my $personStatus = '';
    my $personRegistrationID = ''; #specific for person request access

    my %RegFilters=();

    while(my $tdref = $q->fetchrow_hashref()) {
        $personStatus = $tdref->{'personStatus'};
        $existsInRequestingClub = 0;
        #other club hits an still in-progress or pending request
        next if ($entityID != $tdref->{'intEntityID'} and $tdref->{'existPendingRequestID'} and ($tdref->{'personRegistrationStatus'} eq 'PENDING' or $tdref->{'personRegistrationStatus'} eq 'INPROGRESS'));

        my ($RegCount, $Reg_ref) = PersonRegistration::getRegistrationData($Data, $tdref->{'intPersonID'}, \%RegFilters);
        foreach my $reg_rego_ref (@{$Reg_ref}) {
            next if $existsInRequestingClub;
            $existsInRequestingClub = 1 if ($reg_rego_ref->{'intEntityID'} == $entityID and $reg_rego_ref->{'personRegistrationStatus'} eq $Defs::PERSON_STATUS_REGISTERED);
        }

        #next if ($existsInRequestingClub and ($requestType eq $Defs::PERSON_REQUEST_ACCESS));
        return displayGenericError($Data, $Data->{'lang'}->txt("Error"), $Data->{'lang'}->txt("Member is currently registered.")) if ($existsInRequestingClub and ($requestType eq $Defs::PERSON_REQUEST_ACCESS));

        $found++;
        my $actionLink = undef;
        my $btnLabel = 'Request Access';
        $btnLabel = 'Request Transfer' if ($requestType eq $Defs::PERSON_REQUEST_TRANSFER);
        if($tdref->{'currEntityPendingRequestID'} and $tdref->{'currEntityPendingRegistrationID'}) {
            return displayGenericError($Data, $Data->{'lang'}->txt("Error"), $Data->{'lang'}->txt("Pending request has been found."));

            #current logged-in entity hits the same pending request
            #$actionLink = qq[ <span class="btn-inside-panels"><a href="$Data->{'target'}?client=$client&amp;a=PRA_V&amp;rid=$tdref->{'currEntityPendingRequestID'}">]. $Data->{'lang'}->txt("View pending") . q[</a></span>];    
        }
        else {
            $actionLink = qq[ <span class="btn-inside-panels"><a href="$Data->{'target'}?client=$client&amp;a=PRA_initRequest&amp;pid=$tdref->{'intPersonID'}&amp;prid=$tdref->{'intPersonRegistrationID'}&amp;request_type=$request_type&amp;transfer_type=$transferType">]. $Data->{'lang'}->txt($btnLabel) . q[</a></span>];
        }

        push @rowdata, {
            id => $tdref->{'intPersonRegistrationID'} || 0,
            currentClub => $tdref->{'currentClub'} || '',
            localFirstname => $tdref->{'strLocalFirstname'} || '',
            localSurname => $tdref->{'strLocalSurname'} || '',

            personStatus => $Defs::personStatus{$tdref->{'personStatus'}} || '',
            personRegoStatus => $Defs::personRegoStatus{$tdref->{'personRegistrationStatus'}} || '',

            sport => $Defs::sportType{$tdref->{'strSport'}} || '',
            personType => $Defs::personType{$tdref->{'strPersonType'}} || '',
            personLevel => $Defs::personLevel{$tdref->{'strPersonLevel'}} || '',
            DOB => $Data->{'l10n'}{'date'}->format($tdref->{'dtDOB'} || '','MEDIUM'),
            DOB_RAW => $tdref->{'dtDOB'} || '',
            actionLink => $actionLink,
            SelectLink => ''
        };

        push @tData, {
            id => $tdref->{'intPersonRegistrationID'} || 0,
            personID => $tdref->{'intPersonID'} || 0,
            currentClub => $tdref->{'currentClub'} || '',
            personStatus => $tdref->{'personStatus'} || '',
            personRegoStatus => $tdref->{'personRegistrationStatus'} || '',
            sport => $tdref->{'strSport'} || '',
            sportLabel => $Defs::sportType{$tdref->{'strSport'}} || '',
            localFirstname => $tdref->{'strLocalFirstname'} || '',
            localSurname => $tdref->{'strLocalSurname'} || '',
            personType => $tdref->{'strPersonType'} || '',
            personLevel => $tdref->{'strPersonLevel'} || '',
            DOB => $Data->{'l10n'}{'date'}->format($tdref->{'dtDOB'} || '','MEDIUM'),
            DOB_RAW => $tdref->{'dtDOB'} || '',
        };

        $personFname = $tdref->{'strLocalFirstname'} if !$personFname;
        $personLname = $tdref->{'strLocalSurname'} if !$personLname;
        $personMID = $tdref->{'strNationalNum'} if !$personMID;
        $personID = $tdref->{'intPersonID'} if !$personID;
        $personRegistrationID = $tdref->{'intPersonRegistrationID'} if !$personRegistrationID;

        if(!($Defs::personType{$tdref->{'strPersonType'}} ~~ @personCurrentRegistrations)){
            push @personCurrentRegistrations, $Defs::personType{$tdref->{'strPersonType'}};
        }

        if(!($Defs::sportType{$tdref->{'strSport'}} ~~ @personCurrentSports)){
            push @personCurrentSports, $Defs::sportType{$tdref->{'strSport'}};
        }

        if(exists $groupResult{$tdref->{'currentClub'}}){
            push @{$groupResult{$tdref->{'currentClub'}}}, @tData;
        }
        else{
            push @personCurrentClubs, $tdref->{'currentClub'};
            $groupResult{$tdref->{'currentClub'}} = [@tData];
            #push @{$groupResult{$tdref->{'intEntityID'}}}, @rowdata;
        }

        @tData = ();
    }

    return displayGenericError($Data, $Data->{'lang'}->txt("Error"), $Data->{'lang'}->txt("No record found.")) if !$found;
    #return ("$found record found.", $title) if !$found;

    my $resultHTML = undef;
    if($requestType eq $Defs::PERSON_REQUEST_ACCESS) {
        $title = $Data->{'lang'}->txt($Defs::personRequest{$Defs::PERSON_REQUEST_ACCESS});

        my $error;
        $error = $Data->{'lang'}->txt("Request Access cannot continue until re-approved by MA.") if($personStatus eq $Defs::PERSON_STATUS_PENDING);

        my %TemplateData = (
            PersonFirstName => $personFname,
            PersonSurName => $personLname,
            CurrentRegistrations => join(', ', @personCurrentRegistrations),
            CurrentSports => join(', ', @personCurrentSports),
            CurrentClub => join(', ', @personCurrentClubs),
            PersonSummaryPanel => personSummaryPanel($Data, $personID),
            PersonID => $personID,
            PersonRegistrationID => $personRegistrationID,
            action_request => "PRA_submit",
            request_type => $request_type,
            client => $Data->{'client'},
            error => $error || '',
        );
        $resultHTML = runTemplate(
            $Data,
            \%TemplateData,
            'personrequest/access/personregistration_summary.templ',
        );
    }
    elsif($requestType eq $Defs::PERSON_REQUEST_TRANSFER) {
        $resultHTML = ' ';
        my %TemplateData;

        $TemplateData{'groupResult'} = \%groupResult;
        $TemplateData{'action'} = "PRA_search"; #this uses generic/search_form.templ and action should remain PRA_search
        #$TemplateData{'action_request'} = "PRA_initRequest";
        $TemplateData{'action_request'} = "PRA_submit";
        $TemplateData{'request_type'} = $request_type;
        $TemplateData{'transfer_type'} = $transferType;
        $TemplateData{'client'} = $Data->{'client'};
        $TemplateData{'selectedForTransferDetails'}{'currentClub'} = join(', ', @personCurrentClubs);
        $TemplateData{'selectedForTransferDetails'}{'transferToClub'} = '';
        $TemplateData{'selectedForTransferDetails'}{'currentSports'} = join(', ', @personCurrentSports);
        $TemplateData{'selectedForTransferDetails'}{'currentRegistrations'} = join(', ', @personCurrentRegistrations);
        $TemplateData{'selectedForTransferDetails'}{'firstName'} = $personFname;
        $TemplateData{'selectedForTransferDetails'}{'lastName'} = $personLname;
        $TemplateData{'selectedForTransferDetails'}{'memberID'} = $personMID;
        $resultHTML = runTemplate(
            $Data,
            \%TemplateData,
            'personrequest/generic/search_form.templ',
            #'personrequest/transfer/selection.templ',
        );
    }

    return ($resultHTML, $title);
}

sub initRequestPage {
    my ($Data) = @_;

    my $title = undef;
    my $body = undef;
    my $personID = safe_param('pid', 'number') || 0;
    my $personRegistrationID = safe_param('prid', 'number') || 0;
    my $requestType = safe_param('request_type', 'word') || '';
    my $transferType = safe_param('transfer_type', 'word') || '';
    #my $multiParam = 

	my $p = new CGI;
	my %params = $p->Vars();

    my %requestParams;
    for my $selectedRego ($p->param()) {
        if(my ($personID, $personRegoID) = $selectedRego =~ /^regoselected\[([0-9]+)\]\[([0-9]+)\]\z/) {
            if(exists $requestParams{$personID}){
                push @{$requestParams{$personID}}, $personRegoID;
            }
            else{
                push @{$requestParams{$personID}}, $personRegoID;
            }
        }
    }

    if(scalar(%requestParams) == 0){
        #specific for PERSON REQUEST ACCESS
        push @{$requestParams{$personID}}, $personRegistrationID;
    }

    my %TemplateData;
    $TemplateData{'PersonSummaryPanel'}  = personSummaryPanel($Data, $personID) || '';

    if($transferType eq $Defs::TRANSFER_TYPE_INTERNATIONAL) {
        $title = $Data->{'lang'}->txt("Do you have Player's International Transfer Certificate?");

        $TemplateData{'noITC'} = qq[ <span class="btn-inside-panels"><a href="$Data->{'target'}?client=$Data->{'client'}&amp;a=PRA_NC">]. $Data->{'lang'}->txt("No") . q[</a></span>];
        $TemplateData{'withITC'} = qq[ <span class="btn-inside-panels"><a href="$Data->{'target'}?client=$Data->{'client'}&amp;a=PF_&amp;dtype=PLAYER&amp;itc=1">]. $Data->{'lang'}->txt("Yes") . q[</a></span>];

        $body = runTemplate(
            $Data,
            \%TemplateData,
            'personrequest/transfer/itc_question.templ',
        );

        my %TemplateData;

    }
    else {
        $title = $Data->{'lang'}->txt("Confirm Request");
        my %RequestAction = (
            'request_type' => $requestType,
            'client' => $Data->{client} || 0,
            'backAction' => 'PRA_T',
            'sendAction' => 'PRA_submit',
            'target' =>$Data->{'target'},
        );

        $TemplateData{'RequestAction'} = \%RequestAction;
        $TemplateData{'personRegoParamDetails'} = \%requestParams;
        #$TemplateData{'personID'} = $personID;
        #$TemplateData{'personRegistrationID'} = $personRegistrationID;

        $body = runTemplate(
            $Data,
            \%TemplateData,
            'personrequest/generic/submit_request.templ',
        );

    }
    return ($body, $title);
}

sub submitRequestPage {
    my ($Data) = @_;

    my $notes = safe_param('request_notes', 'words') || '';
	my $entityID = getID($Data->{'clientValues'}, $Data->{'clientValues'}{'currentLevel'});

    my @rowdata = ();
	my $p = new CGI;
	my %params = $p->Vars();
    my @requestIDs;

    for my $selectedRego ($p->param()) {
        if(my ($personID, $personRegoID) = $selectedRego =~ /^regoselected\[([0-9]+)\]\[([0-9]+)\]\z/) {

            #TODO: check below
            #if inter-RA, override to MA
            #otherwise RA approves
            my $MAOverride = 0;

            my $requestType = getRequestType();

            my %Reg = (
                personRegistrationID => $personRegoID || 0,
            );

            my ($count, $reg_ref) = PersonRegistration::getRegistrationData(
                $Data,
                $personID,
                \%Reg
            );

            #return ("Record does not exist.", "Send Request") if(!$count);

            my $st = qq[
                INSERT INTO
                    tblPersonRequest
                    (
                        strRequestType,
                        intPersonID,
                        strSport,
                        strPersonType,
                        strPersonLevel,
                        strPersonEntityRole,
                        intRealmID,
                        intRequestFromEntityID,
                        intRequestToEntityID,
                        intRequestToMAOverride,
                        strRequestNotes,
                        strRequestStatus,
                        dtDateRequest,
                        tTimeStamp
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
                        NOW(),
                        NOW()
                    )
            ];

            my $regDetails = ${$reg_ref}[0];

            my $db = $Data->{'db'};
            my $q = $db->prepare($st);
            $q->execute(
                $requestType,
                $personID,
                $regDetails->{'strSport'},
                $regDetails->{'strPersonType'},
                $regDetails->{'strPersonLevel'},
                $regDetails->{'strPersonEntityRole'},
                $Data->{'Realm'},
                $entityID,
                $regDetails->{'intEntityID'},
                $MAOverride,
                $notes,
                $Defs::PERSON_REQUEST_STATUS_INPROGRESS,
            );

            my $requestID = $db->{mysql_insertid};
            push @requestIDs, $requestID;

            my $notificationType = undef;

            my %notificationData = (
                Reason => $notes,
                WorkTaskType => $Defs::personRequest{$requestType},
                Person => $regDetails->{'strLocalFirstname'} . ' ' . $regDetails->{'strLocalSurname'},
                CurrentClub => $regDetails->{'strLocalName'} || '',
            );

            my $clubObj = getInstanceOf($Data, 'club');

            my $emailNotification = new EmailNotifications::PersonRequest();
            $emailNotification->setRealmID($Data->{'Realm'});
            $emailNotification->setSubRealmID(0);
            $emailNotification->setToEntityID($regDetails->{'intEntityID'});
            $emailNotification->setFromEntityID($entityID);
            #$emailNotification->setDefsEmail($clubObj->getValue('strEmail')); #if set, this will be used instead of toEntityID
            #$emailNotification->setDefsName($clubObj->getValue('strLocalName') || $Defs::admin_email_name);
            $emailNotification->setDefsEmail($Defs::admin_email); #if set, this will be used instead of toEntityID
            $emailNotification->setDefsName($Defs::admin_email_name);
            $emailNotification->setNotificationType($requestType, "SENT");
            $emailNotification->setSubject($regDetails->{'strLocalFirstname'} . " " . $regDetails->{'strLocalSurname'});
            $emailNotification->setLang($Data->{'lang'});
            $emailNotification->setDbh($Data->{'db'});
            $emailNotification->setData($Data);
            $emailNotification->setWorkTaskDetails(\%notificationData);

            my $emailTemplate = $emailNotification->initialiseTemplate()->retrieve();
            $emailNotification->send($emailTemplate) if $emailTemplate->getConfig('toEntityNotification') == 1;

            push @rowdata, {
                id => $regDetails->{'intPersonRegistrationID'} || 0,
                currentClub => $regDetails->{'strLocalName'} || '',
                localFirstname => $regDetails->{'strLocalFirstname'} || '',
                localSurname => $regDetails->{'strLocalSurname'} || '',
                MAID => $regDetails->{'strNationalNum'} || '',
                Sport => $regDetails->{'Sport'} || '',
            };
        }
    }

    my $query = new CGI;
    my $rType = getRequestType();
    print $query->redirect("$Defs::base_url/" . $Data->{'target'} . "?client=$Data->{'client'}&a=PRA_F&rtype=$rType&pr=" . join(',', @requestIDs));
    #my $resultHTML;
    #return ($resultHTML, 'Request Summary');
}

sub displayCompletedRequest {
    my ($Data) = @_;

    my $body = " ";
    #todo 
    #my $title = $Data->{'lang'}->txt("Request a Transfer - Submitted to Current Club");
    my $pr = param('pr');
    my @prids = split(',', $pr);

    my $rtype = param('rtype');
    my $title;
    $title = $Data->{'lang'}->txt("Request a Transfer - Submitted to Current Club") if $rtype eq $Defs::PERSON_REQUEST_TRANSFER;
    $title = $Data->{'lang'}->txt("Request Access (Add Role) - Submitted to Current Club") if $rtype eq $Defs::PERSON_REQUEST_ACCESS;

    my %reqFilters = (
        'requestIDs' => \@prids
    );

	my $entityID = getID($Data->{'clientValues'}, $Data->{'clientValues'}{'currentLevel'});
    my $personRequests = getRequests($Data, \%reqFilters);

    my $found = 0;
    my $personID = 0;
    my $error = 0;
    my @rowdata;
    my %personDetails;
    my $itemRequestType;

    for my $request (@{$personRequests}) {
        $itemRequestType = $Data->{'lang'}->txt($Defs::personRequest{$request->{'strRequestType'}} . " Request for") if $rtype eq $Defs::PERSON_REQUEST_TRANSFER;
        $itemRequestType = $Data->{'lang'}->txt($Defs::personRequest{$request->{'strRequestType'}} . " for") if $rtype eq $Defs::PERSON_REQUEST_ACCESS;
        $found = 1;
        if(!$personID) {
            $personID = $request->{'intPersonID'};
        }
        elsif(($personID and $personID != $request->{'intPersonID'})) {
            #accessing person requests by adding to request param
            $error = 1;
        }

        $error = 1 if($entityID != $request->{'intRequestFromEntityID'});

        push @rowdata, {
            id => $request->{'intPersonRequestID'} || 0,
            personID => $request->{'intPersonID'} || 0,
            sport => $Defs::sportType{$request->{'strSport'}},
            personType => $Defs::personType{$request->{'strPersonType'}},
            requestFrom => $request->{'requestFrom'} || '',
            requestTo => $request->{'requestTo'} || '',
            requestType => $itemRequestType,
            requestResponse => $Defs::personRequestResponse{$request->{'strRequestResponse'}} || $Data->{'lang'}->txt('Requested'),
            #SelectLink => $selectLink,
        };

        $personDetails{'memberID'} = $request->{'strNationalNum'};
        $personDetails{'firstname'} = $request->{'strLocalFirstname'};
        $personDetails{'surname'} = $request->{'strLocalSurname'};
        $personDetails{'gender'} = $Defs::PersonGenderInfo{$request->{'intGender'} || 0} || '';
        $personDetails{'dob'} = $request->{'dtDOB'} || '';
    }

    return displayGenericError($Data, $Data->{'lang'}->txt("Error"), $Data->{'lang'}->txt("An error has been encountered.")) if $error;
    my %TemplateData;

    $TemplateData{'personDetails'} = \%personDetails;
    $TemplateData{'personRequests'} = \@rowdata;
    $TemplateData{'client'} = $Data->{'client'};
    $TemplateData{'requesttype'} = "Transfer" if $rtype eq $Defs::PERSON_REQUEST_TRANSFER;;
    $TemplateData{'requesttype'} = "Request Access" if $rtype eq $Defs::PERSON_REQUEST_ACCESS;

    $TemplateData{'PersonSummaryPanel'} = personSummaryPanel($Data, $personID) || 'PSP';

    $body = runTemplate(
        $Data,
        \%TemplateData,
        'personrequest/generic/completed.templ',
    );

    return ($body, $title);
}

sub listRequests {
    my ($Data,$personID) = @_;
    $personID ||= 0;

	my $entityID = getID($Data->{'clientValues'}, $Data->{'clientValues'}{'currentLevel'});
    my $client = setClient( $Data->{'clientValues'} ) || '';
    my $title = $Data->{'lang'}->txt('Requests');

    my %reqFilters =  ();
    if ($personID)  {
        $reqFilters{'personID'} = $personID;
    }
    else    {
        $reqFilters{'entityID'} = $entityID
    }

    my $personRequests = getRequests($Data, \%reqFilters);

    my $found = 0;
    my @rowdata = ();

    #while(my $tdref = $q->fetchrow_hashref()) {
    for my $request (@{$personRequests}) {
        $found = 1;
        my $selectLink = '';
        if (! $personID)    {
            $selectLink = "$Data->{'target'}?client=$client&amp;a=PRA_V&rid=$request->{'intPersonRequestID'}";
        }
        push @rowdata, {
            id => $request->{'intPersonRequestID'} || 0,
            personID => $request->{'intPersonID'} || 0,
            MAID => $request->{'strNationalNum'} || 0,
            requestFrom => $request->{'requestFrom'} || '',
            requestTo => $request->{'requestTo'} || '',
            requestType => $Defs::personRequest{$request->{'strRequestType'}},
            requestResponse => $Defs::personRequestResponse{$request->{'strRequestResponse'}} || $Data->{'lang'}->txt('Requested'),
            SelectLink => "$Data->{'target'}?client=$client&amp;a=PRA_VR&rid=$request->{'intPersonRequestID'}",
            Date => $Data->{'l10n'}{'date'}->TZformat($request->{'tTimeStamp'},'MEDIUM','SHORT') || $Data->{'l10n'}{'date'}->TZformat($request->{'dtDateRequest'},'MEDIUM','SHORT') || '',
            Name => $request->{'strLocalFirstname'} . ' ' . $request->{'strLocalSurname'},
        }
    }

    return ("$found record found.", $title) if !$found;

    my @headers = (
        {
            name => $Data->{'lang'}->txt('MA ID'),
            field => 'MAID',
        }, 
        {
            name => $Data->{'lang'}->txt('Name'),
            field => 'Name',
        },
        {
            name => $Data->{'lang'}->txt('Request From'),
            field => 'requestFrom',
        }, 
        {
            name => $Data->{'lang'}->txt('Request To'),
            field => 'requestTo',
        }, 
        {
            name => $Data->{'lang'}->txt('Type'),
            field => 'requestType',
        }, 
        {
            name => $Data->{'lang'}->txt('Response Status'),
            field => 'requestResponse',
        }, 
        {
            name => $Data->{'lang'}->txt('Date'),
            field => 'Date',
        }, 
        {
            name  => $Data->{'lang'}->txt('Task Type'),
            field => 'SelectLink',
            width  => 50,
        },

    ); 

    splice @headers, 1, 1 if $personID; #exclude name if navigated down to person

    my $rectype_options = '';
    my $grid = showGrid(
        Data => $Data,
        columns => \@headers,
        rowdata => \@rowdata,
        gridid => 'grid',
        width => '99%',
    ); 

    my $resultHTML = qq[
        <div class="grid-filter-wrap">
            <div style="width:99%;">$rectype_options</div>
            $grid
        </div>
    ];

    return ($resultHTML, $title);

}

sub viewRequest {
    my ($Data) = @_;

    my $requestID = safe_param('rid', 'number') || -1;
    my $entityID = getID($Data->{'clientValues'}, $Data->{'clientValues'}{'currentLevel'});
    my $requestType = undef;
    my $action = undef;

    my %regFilter = (
        'entityID' => $entityID,
        'requestID' => $requestID,
    );
    my $request = getRequests($Data, \%regFilter);

    $request = $request->[0];

    #checking of who can only access what request is already handled in the getRequests query
    # e.g. if requestTo already accepted the request, it would be able to view it again as the $request will be empty
    return displayGenericError($Data, $Data->{'lang'}->txt("Error"), $Data->{'lang'}->txt("Person Request not found.")) if (!$request or scalar(%{$request}) == 0);

    my $templateFile = undef;
    my $error = undef;

    switch($request->{'strRequestType'}) {
        case "$Defs::PERSON_REQUEST_TRANSFER" {
            if($request->{'intPersonRequestID'} and $request->{'strRequestResponse'} eq $Defs::PERSON_REQUEST_STATUS_ACCEPTED) {
                $templateFile = "personrequest/transfer/new_club_view.templ";
            }
            else {
                $templateFile = "personrequest/transfer/current_club_view.templ";
            }

            $requestType = $Defs::PERSON_REQUEST_TRANSFER;
        }
        case "$Defs::PERSON_REQUEST_ACCESS" {
            if($request->{'intPersonRequestID'} and $request->{'strRequestResponse'} eq $Defs::PERSON_REQUEST_STATUS_ACCEPTED) {
                $templateFile = "personrequest/access/requesting_club_view.templ";
            }
            else {
                $templateFile = "personrequest/access/current_club_view.templ";
            }

            $requestType = $Defs::PERSON_REQUEST_ACCESS;
        }
        else {

        }
    }

    my $personDetails = Person::loadPersonDetails($Data->{'db'}, $request->{'intPersonID'});
    my $personCurrAgeLevel = Person::calculateAgeLevel($Data, $personDetails->{'currentAge'});
    my $originLevel = $Data->{'clientValues'}{'authLevel'};

    my $maObj = getInstanceOf($Data, 'national');

    my $isocountries  = getISOCountriesHash();
    my %TemplateData = (
        'requestID' => $request->{'intPersonRequestID'} || undef,
        'requestType' => $Defs::personRequest{$request->{'strRequestType'}} || '',
        'requestFrom' => $request->{'requestFrom'} || '',
        'requestFromDiscipline' => $Defs::entitySportType{$request->{'requestFromDiscipline'}} || '',
        'requestFromISOCountry' => $isocountries->{$request->{'requestFromISOCountry'}} || '',
        'requestFromAddress' => $request->{'requestFromAddress'} || '',
        'requestFromAddress2' => $request->{'requestFromAddress2'} || '',
        'requestFromCity' => $request->{'requestFromCity'} || '',
        'requestFromPostal' => $request->{'requestFromPostal'} || '',
        'requestFromRegion' => $request->{'requestFromRegion'} || '',
        'requestFromPhone' => $request->{'requestFromPhone'} || '',

        'requestFromTo' => $request->{'requestFromTo'} || '',

        'requestTo' => $request->{'requestTo'} || '',
        'requestToDiscipline' => $Defs::entitySportType{$request->{'requestToDiscipline'}} || '',
        'requestToISOCountry' => $isocountries->{$request->{'requestToISOCountry'}} || '',
        'requestToAddress' => $request->{'requestToAddress'} || '',
        'requestToAddress2' => $request->{'requestToAddress2'} || '',
        'requestToCity' => $request->{'requestToCity'} || '',
        'requestToPostal' => $request->{'requestToPostal'} || '',
        'requestToRegion' => $request->{'requestToRegion'} || '',
        'requestToPhone' => $request->{'requestToPhone'} || '',

        'dateRequest' => $request->{'dtDateRequest'} || '',
        'requestResponse' => $Defs::personRequestResponse{$request->{'strRequestResponse'}} || '',
        'responseBy' => $request->{'responseBy'} || '',
        'personFirstname' => $request->{'strLocalFirstname'} || '',
        'personSurname' => $request->{'strLocalSurname'} || '',
        'ISONationality' => $isocountries->{$request->{'strISONationality'}} || '',
        'ISOCountryOfBirth' => $isocountries->{$request->{'strISOCountryOfBirth'}} || '',
        'RegionOfBirth' => $request->{'strRegionOfBirth'} || '',
        'personGender' => $Defs::PersonGenderInfo{$request->{'intGender'} || 0} || '',
        'DOB' => $request->{'dtDOB'} || '',
        'personStatus' => $request->{'personStatus'} || '',
        'sport' => $Defs::sportType{$request->{'strSport'}} || '',
        'personType' => $Defs::personType{$request->{'strPersonType'}} || '',
        'personLevel' => $Defs::personLevel{$request->{'strPersonLevel'}} || '',
        'requestNotes' => $request->{'strRequestNotes'} || '',
        'responseNotes' => $request->{'strResponseNotes'} || '',

        'personID' => $request->{'intPersonID'},
        'personAgeLevel' => $personCurrAgeLevel,
        'requestOriginLevel' => $originLevel,
        'requestEntityID' => $entityID,

        'personRegistrationID' => $request->{'intPersonRegistrationID'} || 0,
        'personRegistrationStatus' => $request->{'personRegoStatus'} || 'N/A',
        'MID' => $request->{'strNationalNum'},

        'contactAddress1' => $request->{'strAddress1'},
        'contactAddress2' => $request->{'strAddress2'},
        'contactCity' => $request->{'strSuburb'},
        'contactState' => $request->{'strState'},
        'contactPostalCode' => $request->{'strPostalCode'},
        'contactISOCountry' => $isocountries->{$request->{'strISOCountry'}},
        'contactPhoneHome' => $request->{'strPhoneHome'},
        'contactEmail' => $request->{'strEmail'},
        'MA' => $maObj->name(),
        PersonSummaryPanel => personSummaryPanel($Data, $request->{'intPersonID'}) || '',
    );

    my $title = join(' ',(
        $request->{'strLocalFirstname'} || '',
        $request->{'strLocalSurname'} || '',
        ' - ',
        $Data->{'lang'}->txt($Defs::personRequest{$request->{'strRequestType'}}),
        ': ',
        $request->{'requestFrom'}
    ));

    my $showAction = 0;
    if (($entityID == $request->{'intRequestToEntityID'} and $request->{'intRequestToMAOverride'} == 0) or ($entityID == $request->{'intRequestToMAOverride'} and $request->{'intRequestToMAOverride'} == 1)) {
        $showAction = 1;
        $action = "PRA_S";
    }

    my $initiateRequestProcess = 0;
    my $tempClient = undef;

    if($entityID == $request->{'intRequestFromEntityID'} and $request->{'strRequestResponse'} eq $Defs::PERSON_REQUEST_RESPONSE_ACCEPTED) {
        #check PENDING for now
        if($request->{'intPersonRegistrationID'} and $request->{'personRegoStatus'} eq $Defs::PERSONREGO_STATUS_PENDING) {
            $initiateRequestProcess = 0;
        }
        else {
            $initiateRequestProcess = 1;
        }

        switch($requestType) {
            case "$Defs::PERSON_REQUEST_TRANSFER" {
                #$action = "PREGF_TU";
                $action = "PTF_";
            }
            case "$Defs::PERSON_REQUEST_ACCESS" {
                my %tempClientValues = %{ $Data->{'clientValues'} };
                $tempClientValues{'personID'} = $request->{'intPersonID'};
                $tempClientValues{'currentLevel'} = $Defs::LEVEL_PERSON;
                $tempClient = setClient( \%tempClientValues );
                #$action = "PREGF_T";
                $action = "P_HOME";
            }
        }
    }

    my %RequestAction = (
        'client' => $Data->{client} || 0,
        'initiateAddRoleClient' => $tempClient || 0,
        'initiateAddRoleAction' => "PF_",
        'rid' => $requestID,
        'action' => $action,
        'showAction' => $showAction,
        'initiateRequestProcess' => $initiateRequestProcess,
        'request_type' => $requestType,
        'target' => $Data->{'target'},
    );

    $TemplateData{'RequestAction'} = \%RequestAction;

    my $body = runTemplate(
        $Data,
        \%TemplateData,
        $templateFile
    );

    return ($body, $title);
}

sub setRequestResponse {
    my ($Data) = @_;

    my $requestID = safe_param('rid', 'number') || 0;
    my $response = safe_param('response', 'word') || '';
    my $notes = safe_param('request_notes', 'words') || '';
	my $entityID = getID($Data->{'clientValues'}, $Data->{'clientValues'}{'currentLevel'});
    my $requestStatus = '';

    my %regFilter = (
        'entityID' => $entityID,
        'requestID' => $requestID
    );
    my $request = getRequests($Data, \%regFilter);
    $request = $request->[0];

    my $requestResponseSuffix = "";
    my $entityAsSenderID;
    my $entityAsReceiverID;

    switch($response){
        case 'deny' {
            $response = $Defs::PERSON_REQUEST_RESPONSE_DENIED;
            $requestStatus = $Defs::PERSON_REQUEST_STATUS_DENIED;
            $requestResponseSuffix = $Data->{'lang'}->txt("Rejected");

            $entityAsSenderID = $request->{'intRequestToEntityID'};
            $entityAsReceiverID = $request->{'intRequestFromEntityID'};
        }
        case 'accept' {
            $response = $Defs::PERSON_REQUEST_RESPONSE_ACCEPTED;
            $requestStatus = $Defs::PERSON_REQUEST_STATUS_PENDING;
            $requestResponseSuffix = $Data->{'lang'}->txt("Approved");

            $entityAsSenderID = $request->{'intRequestToEntityID'};
            $entityAsReceiverID = $request->{'intRequestFromEntityID'};
        }
        case 'cancel' {
            $response = $Defs::PERSON_REQUEST_RESPONSE_CANCELLED;
            $requestStatus = $Defs::PERSON_REQUEST_STATUS_CANCELLED;
            $requestResponseSuffix = $Data->{'lang'}->txt("Cancelled");

            $entityAsSenderID = $request->{'intRequestFromEntityID'};
            $entityAsReceiverID = $request->{'intRequestToEntityID'};
        }
        else {
            $response = undef;
        }
    }


    my %notificationData = (
        Reason => $notes,
        WorkTaskType => $Defs::personRequest{$request->{'strRequestType'}},
        Person => $request->{'strLocalFirstname'} . ' ' . $request->{'strLocalSurname'},
        CurrentClub => $request->{'requestTo'} || '',
        RequestingClub => $request->{'requestFrom'} || '',
    );


    my $emailNotification = new EmailNotifications::PersonRequest();
    $emailNotification->setRealmID($Data->{'Realm'});
    $emailNotification->setSubRealmID(0);
    #$emailNotification->setToEntityID($request->{'intRequestFromEntityID'});
    #$emailNotification->setFromEntityID($request->{'intRequestToEntityID'});
    $emailNotification->setToEntityID($entityAsReceiverID);
    $emailNotification->setFromEntityID($entityAsSenderID);
    $emailNotification->setDefsEmail($Defs::admin_email); #if set, this will be used instead of toEntityID
    $emailNotification->setDefsName($Defs::admin_email_name);
    $emailNotification->setNotificationType($request->{'strRequestType'}, $response);
    $emailNotification->setSubject($request->{'strLocalFirstname'} . ' ' . $request->{'strLocalSurname'});
    $emailNotification->setLang($Data->{'lang'});
    $emailNotification->setDbh($Data->{'db'});
    $emailNotification->setData($Data);
    $emailNotification->setWorkTaskDetails(\%notificationData);

    my $emailTemplate = $emailNotification->initialiseTemplate()->retrieve();
    $emailNotification->send($emailTemplate) if $emailTemplate->getConfig('toEntityNotification') == 1;

    #TODO: check if current entity has the right to update the request

    my $st = qq[
        UPDATE
            tblPersonRequest
        SET
            strRequestResponse = ?,
            intResponseBy = ?,
            strResponseNotes = ?,
            strRequestStatus = ?,
            tTimeStamp = NOW()
        WHERE
            intPersonRequestID = ?
    ];

    my $db = $Data->{'db'};
    my $q = $db->prepare($st);
    $q->execute(
        $response,
        $entityID,
        $notes,
        $requestStatus,
        $requestID
    ) or query_error($st);

    my $body = '';
    my $title = '';

    if(scalar(%{$request}) == 0 or $request->{'strRequestResponse'} eq $Defs::PERSON_REQUEST_STATUS_DENIED or $request->{'strRequestResponse'} eq $Defs::PERSON_REQUEST_STATUS_CANCELLED) {
        return displayGenericError($Data, $Data->{'lang'}->txt("Error"), $Data->{'lang'}->txt("Response has been submitted already."));
    }
    else {
        my $maObj = getInstanceOf($Data, 'national');
        my $maName = $maObj ? $maObj->name() : '';
	
        #print STDERR Dumper $request;
        my $templateFile = "";
        $title = $Defs::personRequest{$request->{'strRequestType'}} . ' - ' . $requestResponseSuffix;
        my $notifDetails = $Data->{'lang'}->txt("You have " . lc $requestResponseSuffix . " the " . $Defs::personRequest{$request->{'strRequestType'}} . " of ") . $request->{'strLocalFirstname'} . " " . $request->{'strLocalSurname'} . ".";

        if($response eq "ACCEPTED"){
            $templateFile = "personrequest/transfer/request_accepted.templ" if $request->{'strRequestType'} eq $Defs::PERSON_REQUEST_TRANSFER;
            $templateFile = "personrequest/access/request_accepted.templ" if $request->{'strRequestType'} eq $Defs::PERSON_REQUEST_ACCESS;
            $notifDetails .= $Data->{'lang'}->txt(" You will be notified once the transfer is effective and approved by ") . $maName if $request->{'strRequestType'} eq $Defs::PERSON_REQUEST_TRANSFER;
        }
        elsif($response eq "DENIED"){
            $templateFile = "personrequest/transfer/request_denied.templ" if $request->{'strRequestType'} eq $Defs::PERSON_REQUEST_TRANSFER;
            $templateFile = "personrequest/access/request_denied.templ" if $request->{'strRequestType'} eq $Defs::PERSON_REQUEST_ACCESS;
        }
        elsif($response eq "CANCELLED") {
            $templateFile = "personrequest/transfer/request_cancelled.templ" if $request->{'strRequestType'} eq $Defs::PERSON_REQUEST_TRANSFER;
            $templateFile = "personrequest/access/request_cancelled.templ" if $request->{'strRequestType'} eq $Defs::PERSON_REQUEST_ACCESS;       
        }

        my %TemplateData = (
            personDetails => {
                firstname => $request->{'strLocalFirstname'},
                surname => $request->{'strLocalSurname'},
                gender => $Defs::PersonGenderInfo{$request->{'intGender'}},
                dob => $request->{'dtDOB'},
                nationality => $request->{'strISONationality'},
                memberID => $request->{'strNationalNum'},
            },
            PersonSummaryPanel => personSummaryPanel($Data, $request->{'intPersonID'}) || '',
            notifDetails => $notifDetails,
            client => $Data->{'client'},
        );

        $body = runTemplate(
            $Data,
            \%TemplateData,
            $templateFile,
        );
    }

    return ($body, $title);
}

sub getRequestType {

    my $requestType = safe_param('request_type', 'word') || '';

    switch($requestType) {
        case 'transfer' {
            $requestType = uc($requestType);
            return $requestType;
        }
        case 'access' {
            $requestType = uc($requestType);
            return $requestType;
        }
        else {
            return undef;
        }
    }
}

sub getRequests {
    my ($Data, $filter) = @_;

    my $where = '';
    my $personRegoJoin = qq[ LEFT JOIN tblPersonRegistration_$Data->{'Realm'} pr ON (pr.intPersonRequestID = pq.intPersonRequestID AND pr.intEntityID = intRequestFromEntityID AND pr.strStatus NOT IN ('INPROGRESS')) ];
    my @values = (
        $Data->{'Realm'}
    );

    if($filter->{'entityID'} and !$filter->{'requestID'}) {
        $where .= "
            AND (
                    (pq.intParentMAEntityID = ? AND pq.intRequestToMAOverride = 1 AND pq.strRequestResponse is NULL)
                    OR
                    (pq.intRequestToEntityID = ?)
                    OR
                    (pq.intRequestFromEntityID = ? AND pq.strRequestResponse in (?, ?, ?))
                )
            ";
            #(pq.intRequestToEntityID = ? AND pq.strRequestResponse is NULL AND pq.intRequestToMAOverride = 0)

        push @values, $filter->{'entityID'};
        push @values, $filter->{'entityID'};
        push @values, $filter->{'entityID'};
        push @values, $Defs::PERSON_REQUEST_RESPONSE_ACCEPTED;
        push @values, $Defs::PERSON_REQUEST_RESPONSE_DENIED;
        push @values, $Defs::PERSON_REQUEST_RESPONSE_CANCELLED;
    }

    if($filter->{'personID'}) {
        $where .= " AND pq.intPersonID = ?";
        push @values, $filter->{'personID'};
    }

    if($filter->{'requestID'} and $filter->{'entityID'}) {
        my $readonlyCond = '';
        if($filter->{'readonly'}) {
            $readonlyCond = qq[
                (pq.intPersonRequestID = ?)
                OR
            ];
            push @values, $filter->{'requestID'};
        }

        $where .= qq[
            AND (
                    $readonlyCond
                    (pq.intParentMAEntityID = ? AND pq.intRequestToMAOverride = 1 AND pq.strRequestResponse is NULL)
                    OR
                    (pq.intRequestToEntityID = ? AND pq.strRequestResponse is NULL AND pq.intPersonRequestID = ? AND pq.intRequestToMAOverride = 0)
                    OR
                    (pq.intRequestFromEntityID = ? AND pq.intPersonRequestID = ? AND pq.strRequestResponse in (?, ?))
                )
            ];
        push @values, $filter->{'entityID'};
        push @values, $filter->{'entityID'};
        push @values, $filter->{'requestID'};
        push @values, $filter->{'entityID'};
        push @values, $filter->{'requestID'};
        push @values, $Defs::PERSON_REQUEST_RESPONSE_ACCEPTED;
        push @values, $Defs::PERSON_REQUEST_RESPONSE_DENIED;

    }
    elsif ($filter->{'requestID'}) {
        $where .= " AND pq.intPersonRequestID = ? ";
        push @values, $filter->{'requestID'};
    }
    elsif ($filter->{'requestIDs'}) {
        my @placeholders;
        foreach my $rid (@{$filter->{'requestIDs'}}) {
            push @placeholders, "?";
            push @values, $rid;
        }

        my $placeholder_in = join(',', @placeholders);
        $where .= " AND pq.intPersonRequestID IN ($placeholder_in)";
    }


    my $st = qq[
        SELECT
            pq.intPersonRequestID,
            pq.strRequestType,
            pq.intPersonID,
            pq.strSport,
            pq.strPersonType,
            pq.strPersonLevel,
            pq.strPersonEntityRole,
            pq.intRealmID,
            pq.intRequestFromEntityID,
            pq.intRequestToEntityID,
            pq.intRequestToMAOverride,
            pq.strRequestNotes,
            pq.dtDateRequest,
            pq.tTimeStamp,
            DATE_FORMAT(pq.dtDateRequest,'%d %b %Y') AS prRequestDateFormatted,
            UNIX_TIMESTAMP(pq.dtDateRequest) AS prRequestTimeStamp,
            UNIX_TIMESTAMP(pq.tTimeStamp) AS prRequestUpdateTimeStamp,
            pq.strRequestResponse,
            pq.strResponseNotes,
            pq.intResponseBy,
            pq.strRequestStatus,
            p.strLocalFirstname,
            p.strLocalSurname,
            p.strStatus as personStatus,
            p.strISONationality,
            p.dtDOB,
            p.intGender,
            p.strNationalNum,
            p.strAddress1,
            p.strAddress2,
            p.strSuburb,
            p.strState,
            p.strPostalCode,
            p.strISOCountry,
            p.strISOCountryOfBirth,
            p.strRegionOfBirth,
            p.strPhoneHome,
            p.strEmail,
		    TIMESTAMPDIFF(YEAR, p.dtDOB, CURDATE()) as currentAge,
            ef.strLocalName as requestFrom,
            ef.strDiscipline as requestFromDiscipline,
            ef.strISOCountry as requestFromISOCountry,
            ef.strAddress as requestFromAddress,
            ef.strAddress2 as requestFromAddress2,
            ef.strCity as requestFromCity,
            ef.strPostalCode as requestFromPostal,
            ef.strRegion as requestFromRegion,
            ef.strPhone as requestFromPhone,

            et.strLocalName as requestTo,
            et.strDiscipline as requestToDiscipline,
            et.strISOCountry as requestToISOCountry,
            et.strAddress as requestToAddress,
            et.strAddress2 as requestToAddress2,
            et.strCity as requestToCity,
            et.strPostalCode as requestToPostal,
            et.strRegion as requestToRegion,
            et.strPhone as requestToPhone,

            erb.strLocalName as responseBy,
            pr.intPersonRegistrationID,
            pr.strStatus as personRegoStatus,

            realm.strRealmName
        FROM
            tblPersonRequest pq
        INNER JOIN
            tblPerson p ON (p.intPersonID = pq.intPersonID)
        INNER JOIN
            tblEntity ef ON (ef.intEntityID = pq.intRequestFromEntityID)
        INNER JOIN
            tblEntity et ON (et.intEntityID = pq.intRequestToEntityID)
        LEFT JOIN
            tblEntity erb ON (erb.intEntityID = pq.intResponseBy)
        INNER JOIN
            tblRealms realm ON (realm.intRealmID = pq.intRealmID)
        $personRegoJoin

        WHERE
            pq.intRealmID = ?
            $where
    ];



    my $db = $Data->{'db'};
    my $q = $db->prepare($st);
    $q->execute(@values) or query_error($st);

    my @personRequests = ();
      
    while(my $dref = $q->fetchrow_hashref()) {
        $dref->{'currentAge'} = personAge($Data, $dref->{'dtDOB'});
        my $personCurrAgeLevel = Person::calculateAgeLevel($Data, $dref->{'currentAge'});
        $dref->{'personCurrentAgeLevel'} = $personCurrAgeLevel;
        push @personRequests, $dref;
    }

    return (\@personRequests);
}

sub finaliseTransfer {
    my ($Data, $requestID) = @_;

    my %reqFilters = (
        'requestID' => $requestID
    );

    my $personRequest = getRequests($Data, \%reqFilters);
    $personRequest = $personRequest->[0];
    my $db = $Data->{'db'};

#    my $st = qq[
#        UPDATE
#            tblPersonRegistration_$Data->{'Realm'}
#        SET
#            strPreTransferredStatus = strStatus,
#            strStatus = ?,
#            dtTo= IF(dtTo>NOW(), NOW(), dtTo),
#            dtTo= IF(dtFrom>NOW(), dtFrom, dtTo)
#        WHERE
#            intEntityID = ?
#            AND strPersonType = ?
#            AND strSport = ?
#            AND intPersonID = ?
#            AND strStatus IN ('ACTIVE', 'PASSIVE', 'ROLLED_OVER', 'PENDING')
#	];
    my $stDates = qq[
        UPDATE
            tblPersonRegistration_$Data->{'Realm'}
        SET
            dtFrom = IF(dtFrom>NOW(), NULL, dtFrom),
            dtTo= IF(dtTo>NOW(), NULL, dtTo)
        WHERE
            intEntityID = ?
            AND strPersonType = ?
            AND strPersonLevel= ?
            AND strSport = ?
            AND intPersonID = ?
            AND strStatus IN ('ACTIVE', 'PASSIVE', 'ROLLED_OVER', 'PENDING')
	];
            #dtTo= IF(dtTo>NOW(), NOW(), dtTo)
            #dtFrom = IF(dtFrom>NOW(), NOW(), dtFrom),
    my $query = $db->prepare($stDates) or query_error($stDates);
    $query->execute(
       $personRequest->{'intRequestToEntityID'},
       $personRequest->{'strPersonType'},
       $personRequest->{'strPersonLevel'},
       $personRequest->{'strSport'},
       $personRequest->{'intPersonID'}
    ) or query_error($stDates);

    ## Now handle LAST date
    my $stPeriods = qq[
        SELECT 
            intNationalPeriodID
        FROM 
            tblNationalPeriod
        WHERE 
            intRealmID = ?
        ORDER BY
            dtTo DESC
    ];

    $stDates = qq[
        UPDATE
            tblPersonRegistration_$Data->{'Realm'} as R
        SET
            R.dtTo= NOW()
        WHERE
            R.intEntityID = ?
            AND R.intNationalPeriodID = ?
            AND R.strPersonType = ?
            AND R.strPersonLevel= ?
            AND R.strSport = ?
            AND R.intPersonID = ?
            AND R.strStatus IN ('ACTIVE', 'PASSIVE', 'ROLLED_OVER', 'PENDING')
        LIMIT 1
	];
    $query = $db->prepare($stDates) or query_error($stDates);

    my $qryNP= $db->prepare($stPeriods) or query_error($stPeriods);
    $qryNP->execute($Data->{'Realm'});
    while (my $pref = $qryNP->fetchrow_hashref) {
        $query->execute(
           $personRequest->{'intRequestToEntityID'},
            $pref->{'intNationalPeriodID'},
           $personRequest->{'strPersonType'},
           $personRequest->{'strPersonLevel'},
           $personRequest->{'strSport'},
           $personRequest->{'intPersonID'}
        ) or query_error($stDates);
        my $rows = $query->rows;
        last if $rows;
    }
    
    my $st = qq[
        UPDATE
            tblPersonRegistration_$Data->{'Realm'}
        SET
            strPreTransferredStatus = strStatus,
            strStatus = ?
        WHERE
            intEntityID = ?
            AND strPersonType = ?
            AND strPersonLevel = ?
            AND strSport = ?
            AND intPersonID = ?
            AND strStatus IN ('ACTIVE', 'PASSIVE', 'ROLLED_OVER', 'PENDING')
	];

## Basically Set dtTo = NOW if they left before end of peiod.
## If dtFrom is in future (if they never started) that period won't be included in Passport
            #AND strPersonLevel = ?

    $query = $db->prepare($st) or query_error($st);
    $query->execute(
       $Defs::PERSONREGO_STATUS_TRANSFERRED,
       $personRequest->{'intRequestToEntityID'},
       $personRequest->{'strPersonType'},
       $personRequest->{'strPersonLevel'},
       $personRequest->{'strSport'},
       $personRequest->{'intPersonID'}
    ) or query_error($st);
    my %PE = ();
    {
    $PE{'personType'} = $personRequest->{'strPersonType'} || '';
    $PE{'personLevel'} = $personRequest->{'strPersonLevel'} || '';
    $PE{'personEntityRole'} = $personRequest->{'strPersonEntityRole'} || '';
    $PE{'sport'} = $personRequest->{'strSport'} || '';
    closePERecord($Data, $personRequest->{'intPersonID'}, $personRequest->{'intRequestToEntityID'}, '', \%PE);
    my $peID = doesOpenPEExist($Data, $personRequest->{'intPersonID'}, $personRequest->{'intRequestFromEntityID'}, \%PE);
    addPERecord($Data, $personRequest->{'intPersonID'}, $personRequest->{'intRequestFromEntityID'}, \%PE) if (! $peID)
    }
    

    if ($personRequest->{'intPersonID'})    {
        my $personObject = getInstanceOf($Data, 'person',$personRequest->{'intPersonID'});
        updateSphinx($db,$Data->{'cache'}, 'Person','update',$personObject);
    }

        #$personRequest->{'strPersonLevel'},
}

sub setRequestStatus {
    my ($Data, $task, $requestStatus) = @_;

    $requestStatus ||= '';

    my %reqFilters = (
        'requestID' => $task->{'intPersonRequestID'} || 0,
    );

    my $request = getRequests($Data, \%reqFilters);
    $request = $request->[0];

    my $st = qq[
        UPDATE
            tblPersonRequest
        SET
            strRequestStatus = ?,
            tTimeStamp = NOW()
        WHERE
            intPersonRequestID = ?
    ];

    my $db = $Data->{'db'};
    my $q = $db->prepare($st);
    $q->execute(
        $requestStatus,
        $task->{'intPersonRequestID'}
    ) or query_error($st);

    my $maObj = getInstanceOf($Data, 'national');

    my %notificationData = (
        Reason => $task->{'rejectNotes'},
        WorkTaskType => $Defs::personRequest{$request->{'strRequestType'}},
        Person => $request->{'strLocalFirstname'} . ' ' . $request->{'strLocalSurname'},
        CurrentClub => $request->{'requestTo'} || '',
        RequestingClub => $request->{'requestFrom'} || '',
        MA => $maObj->name(),
    );

    my $emailNotification = new EmailNotifications::PersonRequest();
    $emailNotification->setRealmID($Data->{'Realm'});
    $emailNotification->setSubRealmID(0);
    $emailNotification->setFromEntityID($task->{'intApprovalEntityID'});
    $emailNotification->setDefsEmail($Defs::admin_email); #if set, this will be used instead of toEntityID
    $emailNotification->setDefsName($Defs::admin_email_name);
    $emailNotification->setSubject($request->{'strLocalFirstname'} . ' ' . $request->{'strLocalSurname'});
    $emailNotification->setLang($Data->{'lang'});
    $emailNotification->setDbh($Data->{'db'});
    $emailNotification->setData($Data);
    $emailNotification->setWorkTaskDetails(\%notificationData);

    if($requestStatus eq $Defs::PERSON_REQUEST_STATUS_REJECTED) {
        $emailNotification->setNotificationType($request->{'strRequestType'}, $Defs::PERSON_REQUEST_STATUS_REJECTED);

        $emailNotification->setToEntityID($task->{'intProblemResolutionEntityID'});
        my $emailTemplate = $emailNotification->initialiseTemplate()->retrieve();
        $emailNotification->send($emailTemplate) if $emailTemplate->getConfig('toEntityNotification') == 1;

        #send to previous club
        $emailNotification->setToEntityID($request->{'intRequestToEntityID'});
        my $emailTemplate = $emailNotification->initialiseTemplate()->retrieve();
        $emailNotification->send($emailTemplate) if $emailTemplate->getConfig('toEntityNotification') == 1;
    }
    elsif($requestStatus eq $Defs::PERSON_REQUEST_STATUS_COMPLETED) {
        $emailNotification->setNotificationType($request->{'strRequestType'}, $Defs::PERSON_REQUEST_STATUS_COMPLETED);

        #send to new club
        $emailNotification->setToEntityID($request->{'intRequestFromEntityID'});
        my $emailTemplate = $emailNotification->initialiseTemplate()->retrieve();
        $emailNotification->send($emailTemplate) if $emailTemplate->getConfig('toEntityNotification') == 1;

        #send to previous club
        $emailNotification->setToEntityID($request->{'intRequestToEntityID'});
        my $emailTemplate = $emailNotification->initialiseTemplate()->retrieve();
        $emailNotification->send($emailTemplate) if $emailTemplate->getConfig('toEntityNotification') == 1;
    }

}

sub itcFields {
    my ($Data) = @_;
	my $isocountries  = getISOCountriesHash();
	my $FieldLabelsPerson = FieldLabels::getFieldLabels($Data, $Defs::LEVEL_PERSON);
	my %FieldDefinitions=(		
        fields => {
   		    	strLocalFirstname => {
   		    		label => $FieldLabelsPerson->{'strLocalFirstname'},
   		    		type => 'text',
   		    		size  => '50',
                	compulsory => 1,
   		    		name => 'strLocalFirstname',
                    sectionname => 'person',
   		    	},
   		    	strLocalSurname => {   		    		
					label => $FieldLabelsPerson->{'strLocalSurname'},   		    			
					type => 'text',
					size => '50',					
                	compulsory => 1,  
					name => 'strLocalSurname', 		    		
                    sectionname => 'person',
   		    	},
   		    	dtDOB => {   		    	
   		    		label => $FieldLabelsPerson->{'dtDOB'},
   		    		type => 'date',
   		    		size => '20',
					name => 'dtDOB',
                    datetype    => 'dropdown',
                    validate    => 'DATE',
                    sectionname => 'person',
                	compulsory => 1,  
   		    	},
   		    	strISONationality => {   		    	
   		    		label => $FieldLabelsPerson->{'strISONationality'},
   		    		options => $isocountries, 
   		    		name => 'strISONationality',
   		    		class => 'chzn-select',
                    sectionname => 'person',
                    firstoption => [ '', $Data->{'lang'}->txt('Select Country') ],
                    type        => 'lookup',
   		    	},
   		    	strPlayerID => {   		    		
   		    		label => 'Player\'s ID(Previous Football Association, if available)',
   		    		name => 'strPlayerID',
   		    		type => 'text',
   		    		size => '50',
                    sectionname => 'person',
   		    	},  
   		    	strISOCountry => {   		    	
   		    		label => $FieldLabelsPerson->{'strISOCountry'},
   		    		name	=> 'strISOCountry',
   		    		class   => 'chzn-select',
                    type        => 'lookup',
   		    		options => $isocountries, 
                    firstoption => [ '', $Data->{'lang'}->txt('Select Country') ],
                    sectionname => 'oldclub',
                	compulsory => 1,  
   		    	},
   		    	strClubName => {   		    	
   		    		label => 'Club\'s Name',
   		    		type => 'text',
   		    		value => '',
                	compulsory => 1,  
					size => '50',
					name => 'strClubName',
                    sectionname => 'oldclub',
   		    	},
        },
        'order' => [qw(
            strLocalSurname
            strLocalFirstname
            dtDOB
            strISONationality
            strPlayerID
            strISOCountry
            strClubName
        )],
        sections => [
            [ 'person',      'Player Details' ],
            [ 'oldclub',     'Previous Club' ],
        ],
        client => $Data->{'client'},
			
   	); #end of FieldDefinitions
    return \%FieldDefinitions;
}

sub displayNoITC {
    my ($Data) = @_;
	my $FieldDefinitions= itcFields($Data);
    my $obj = new Flow_DisplayFields(
      Data => $Data,
      Lang => $Data->{'lang'},
      SystemConfig => $Data->{'SystemConfig'},
      Fields =>  $FieldDefinitions ,
    );
    my ($body, undef, $headJS, undef) = $obj->build({},'edit',1);

	#my $body = runTemplate($Data, $FieldDefinitions, 'person/request_itc_form.templ');
    $body = qq[
        <form method="post" action="$Data->{'target'}" id = "flowFormID">
            <input type="hidden" name="a" value="PRA_NC_PROC" />
            <input type="hidden" name="client" value="$Data->{'client'}" />
            $headJS
            $body
            <div class = "button-row">
                <div class="txtright">
                    <input id = "flow-btn-continue" type = "submit" value = "].$Data->{'lang'}->txt('Submit').qq["  class = "btn-main btn-proceed">
                </div>
            </div>
        </form>
    ];
	my $title = $Data->{'lang'}->txt("Request for an International Transfer Certificate");
	return ($body, $title);

}

sub sendITC {
	my ($Data) = @_;
	#get posted values 
    my $FieldDefinitions= itcFields($Data);
    my $obj = new Flow_DisplayFields(
      Data => $Data,
      Lang => $Data->{'lang'},
      SystemConfig => $Data->{'SystemConfig'},
      Fields =>  $FieldDefinitions ,
    );

    #my $templateFile = 'notification/'.$Data->{'Realm'}.'/personrequest/html/request_itc.templ';
    my $templateFileContent = 'emails/notification/personrequest/html/request_itc_content.templ';
    my $templateWrapper = $Data->{'SystemConfig'}{'EmailNotificationWrapperTemplate'};

    my $p = new CGI;
    my %params = $p->Vars();
    my ($userData, $errors) = $obj->gather(\%params, {},'edit');

	my $maObj = getInstanceOf($Data, 'national');
	my $clubObj = getInstanceOf($Data, 'club');

	my $email_to = $maObj->getValue('strEmail');	
	my $email_from = $clubObj->getValue('strEmail');
	my $isocountries  = getISOCountriesHash();
    $userData->{'strISOCountryName'} = $isocountries->{$userData->{'strISOCountry'}} || '';
    $userData->{'strISONationalityName'} = $isocountries->{$userData->{'strISONationality'}} || '';

    $userData->{'Status'} = 'ITCREQUEST';
    $userData->{'WorkTaskType'} = $Data->{'lang'}->txt('Request for an International Transfer Certificate');
    $userData->{'Originator'} = $clubObj->getValue('strLocalName') || $clubObj->getValue('strLatinShortName');
    $userData->{'RecipientName'} = $maObj->name();
    $userData->{'SenderName'} = $clubObj->getValue('strLocalName') || $clubObj->getValue('strLatinShortName') || $Defs::admin_email_name;

    my $content = runTemplate(
        $Data,
        $userData,
        $templateFileContent,
    );

    my %emailTemplateContent = (
        content => $content,
        MA_PhoneNumber => $Data->{'SystemConfig'}{'ma_phone_number'},
        MA_HelpDeskPhone => $Data->{'SystemConfig'}{'help_desk_phone_number'},
        MA_HelpDeskEmail => $Data->{'SystemConfig'}{'help_desk_email'},
        MA_Website => $Data->{'SystemConfig'}{'ma_website'},
        MA_HeaderName => $Data->{'SystemConfig'}{'EmailNotificationSysName'},
    );

    my ($emailsentOK, $message)  = sendTemplateEmail(
        $Data,
        $templateWrapper,
        #$userData,
        \%emailTemplateContent,
        $email_to,
        $Data->{'lang'}->txt('Request for an International Transfer Certificate') . ": " . $userData->{'strLocalFirstname'} . " " . $userData->{'strLocalSurname'},
        '',#$email_from,
    );

    my $conf_template = runTemplate(
        $Data, 
        { firstname => $Data->{'lang'}->txt($userData->{'strLocalFirstname'}),
          lastname => $Data->{'lang'}->txt($userData->{'strLocalSurname'}),
          dob => $Data->{'lang'}->txt($userData->{'dtDOB'}),
          target => $Data->{'target'},
          client => $Data->{'client'},
        },
        'personrequest/generic/itc_confirmation.templ'
    );

	if($emailsentOK){
		#store to DB;
		my $query = qq[
            INSERT INTO tblITCMessagesLog (
                intEntityFromID, 
                intEntityToID,
                strFirstname,
                strSurname,
                dtDOB,
                strNationality,
                strPlayerID,
                strClubCountry,
                strClubName,
                strMessage
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
                    ?
                )
        ];

        my $sth = $Data->{'db'}->prepare($query);
        $sth->execute(
            $clubObj->ID(), 
            $maObj->ID(),
            $userData->{'strLocalFirstname'}, 
            $userData->{'strLocalSurname'},
            $userData->{'dtDOB'}, 
            $userData->{'strISONationality'}, 
            $userData->{'strPlayerID'},
            $userData->{'strISOCountry'}, 
            $userData->{'strClubName'},
            $message
        );

		#return qq[
          #<div class="OKmsg">].$Data->{'lang'}->txt('International Transfer Certificate request has been sent').qq[ .</div> 
          #<br />  
          #<span class="btn-inside-panels"><a href="$Data->{'target'}?client=$Data->{'client'}&amp;a=PRA_T">] . $Data->{'lang'}->txt('Continue').q[</a></span>
        #];
        return ($conf_template);
	}

	else {
		return ('Error','');
        #this is for test purposes of the template
        #return ($conf_template);
	}
}

sub viewRequestHistory {
    my ($Data, $readonly) = @_;

    my $requestID = safe_param('rid', 'number') || -1;
    #my $entityID = getID($Data->{'clientValues'}, $Data->{'clientValues'}{'currentLevel'});
    my $entityID = getID($Data->{'clientValues'}, $Data->{'clientValues'}{'authLevel'});
    my $requestType = undef;
    my $action = undef;

    my %regFilter = (
        'entityID' => $entityID,
        'requestID' => $requestID,
        'readonly' => $readonly || 0,
    );
    my $request = getRequests($Data, \%regFilter);

    $request = $request->[0];

    #checking of who can only access what request is already handled in the getRequests query
    # e.g. if requestTo already accepted the request, it would be able to view it again as the $request will be empty
    return displayGenericError($Data, $Data->{'lang'}->txt("Error"), $Data->{'lang'}->txt("Person Request not found.")) if (!$request or scalar(%{$request}) == 0);

    my $templateFile = undef;
    my $error = undef;

    switch($request->{'strRequestType'}) {
        case "$Defs::PERSON_REQUEST_TRANSFER" {
            if($request->{'intPersonRequestID'} and $request->{'strRequestResponse'} eq $Defs::PERSON_REQUEST_STATUS_ACCEPTED) {
                $templateFile = "personrequest/transfer/new_club_view.templ";
            }
            else {
                $templateFile = "personrequest/transfer/current_club_view.templ";
            }

            $requestType = $Defs::PERSON_REQUEST_TRANSFER;
        }
        case "$Defs::PERSON_REQUEST_ACCESS" {
            if($request->{'intPersonRequestID'} and $request->{'strRequestResponse'} eq $Defs::PERSON_REQUEST_STATUS_ACCEPTED) {
                $templateFile = "personrequest/access/requesting_club_view.templ";
            }
            else {
                $templateFile = "personrequest/access/current_club_view.templ";
            }

            $requestType = $Defs::PERSON_REQUEST_ACCESS;
        }
        else {

        }
    }

    if($readonly) {
        $request->{'RequestResponse'} = $Defs::personRequestResponse{$request->{'strRequestResponse'}} || $Data->{'lang'}->txt('Requested');
        $request->{'RequestStatus'} = $Defs::personRequestResponse{$request->{'strRequestStatus'}} || $Defs::personRegoStatus{$request->{'personRegoStatus'}};

        my %readonlyTemplateData = (
            request => $request,
            Label => $Defs::personRequest{$request->{'strRequestType'}},
        );
        my $readonlyHTML = runTemplate(
            $Data,
            \%readonlyTemplateData,
            'personrequest/history.templ'
        );

        return ($readonlyHTML, $Data->{'lang'}->txt('Person Request History'));
    }
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

1;
