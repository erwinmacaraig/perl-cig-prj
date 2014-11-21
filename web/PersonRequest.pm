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

use CGI qw(unescape param redirect);
use Log;
use Data::Dumper;
use SystemConfig;
use Switch;


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
            $title = "Request a Transfer";

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

            $title = "Request Access to Person Details";
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
        case 'PRA_S' {
            ($body, $title) = setRequestResponse($Data);
        }
        case 'PRA_NC' {
            ($body, $title) = displayNoITC($Data);
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
        $limit = qq[ LIMIT 1 ];
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

    my %RegFilters=();

    while(my $tdref = $q->fetchrow_hashref()) {
        $existsInRequestingClub = 0;
        #other club hits an still in-progress or pending request
        next if ($entityID != $tdref->{'intEntityID'} and $tdref->{'existPendingRequestID'} and ($tdref->{'personRegistrationStatus'} eq 'PENDING' or $tdref->{'personRegistrationStatus'} eq 'INPROGRESS'));

        my ($RegCount, $Reg_ref) = PersonRegistration::getRegistrationData($Data, $tdref->{'intPersonID'}, \%RegFilters);
        foreach my $reg_rego_ref (@{$Reg_ref}) {
            next if $existsInRequestingClub;
            $existsInRequestingClub = 1 if ($reg_rego_ref->{'intEntityID'} == $entityID);
        }

        next if ($existsInRequestingClub and ($requestType eq $Defs::PERSON_REQUEST_ACCESS));
        $found++;
        my $actionLink = undef;
        if($tdref->{'currEntityPendingRequestID'} and $tdref->{'currEntityPendingRegistrationID'}) {
            #current logged-in entity hits the same pending request
            $actionLink = qq[ <span class="button-small generic-button"><a href="$Data->{'target'}?client=$client&amp;a=PRA_V&amp;rid=$tdref->{'currEntityPendingRequestID'}">]. $Data->{'lang'}->txt("View pending") . q[</a></span>];    
        }
        else {
            $actionLink = qq[ <span class="button-small generic-button"><a href="$Data->{'target'}?client=$client&amp;a=PRA_initRequest&amp;pid=$tdref->{'intPersonID'}&amp;prid=$tdref->{'intPersonRegistrationID'}&amp;request_type=$request_type&amp;transfer_type=$transferType">]. $Data->{'lang'}->txt($request_type) . q[</a></span>];
        }

        push @rowdata, {
            id => $tdref->{'intPersonRegistrationID'} || 0,
            currentClub => $tdref->{'currentClub'} || '',
            personStatus => $tdref->{'personStatus'} || '',
            personRegoStatus => $tdref->{'personRegistrationStatus'} || '',
            sport => $tdref->{'strSport'} || '',
            localFirstname => $tdref->{'strLocalFirstname'} || '',
            localSurname => $tdref->{'strLocalSurname'} || '',
            personType => $tdref->{'strPersonType'} || '',
            personLevel => $tdref->{'strPersonLevel'} || '',
            DOB => $tdref->{'dtDOB'} || '',
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
            DOB => $tdref->{'dtDOB'} || '',
        };

        $personFname = $tdref->{'strLocalFirstname'} if !$personFname;
        $personLname = $tdref->{'strLocalSurname'} if !$personLname;
        $personMID = $tdref->{'strNationalNum'} if !$personMID;

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

    return ("$found record found.", $title) if !$found;

    my $resultHTML = undef;
    if($requestType eq $Defs::PERSON_REQUEST_ACCESS) {
        my @headers = (
            { 
                type => 'Selector',
                field => 'SelectLink',
            }, 
            {
                name => $Data->{'lang'}->txt('Registered To'),
                field => 'currentClub',
            }, 
            {
                name => $Data->{'lang'}->txt('First Name'),
                field => 'localFirstname',
            },
            {
                name => $Data->{'lang'}->txt('Last Name'),
                field => 'localSurname',
            },
            {
                name => $Data->{'lang'}->txt('Date of birth'),
                field => 'DOB',
            },
            {
                name => $Data->{'lang'}->txt('Person Status'),
                field => 'personStatus',
            },
            {
                name => $Data->{'lang'}->txt('Sport'),
                field => 'sport',
            }, 
            #{
            #    name => $Data->{'lang'}->txt('Type'),
            #    field => 'personType',
            #}, 
            #{
            #    name => $Data->{'lang'}->txt('Person Level'),
            #    field => 'personLevel',
            #}, 
            #{
            #    name => $Data->{'lang'}->txt('Registration Status'),
            #    field => 'personRegoStatus',
            #},
            {
                name => $Data->{'lang'}->txt('Action'),
                field => 'actionLink',
                type => 'HTML', 
            },

        ); 

        my $rectype_options = '';
        my $grid = showGrid(
            Data => $Data,
            columns => \@headers,
            rowdata => \@rowdata,
            gridid => 'grid',
            width => '99%',
        ); 

        $resultHTML = qq[
            <div class="grid-filter-wrap">
                <div style="width:99%;">$rectype_options</div>
                $grid
            </div>
        ];
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

    if($transferType eq $Defs::TRANSFER_TYPE_INTERNATIONAL) {
        $title = $Data->{'lang'}->txt("Do you have Player's International Transfer Certificate?");

        $TemplateData{'noITC'} = qq[ <span class="button generic-button"><a href="$Data->{'target'}?client=$Data->{'client'}&amp;a=PRA_NC">]. $Data->{'lang'}->txt("No") . q[</a></span>];
        $TemplateData{'withITC'} = qq[ <span class="button generic-button"><a href="$Data->{'target'}?client=$Data->{'client'}&amp;a=PF_&amp;dtype=PLAYER&amp;itc=1">]. $Data->{'lang'}->txt("Yes") . q[</a></span>];

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
                        dtDateRequest
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

            my $emailNotification = new EmailNotifications::PersonRequest();
            $emailNotification->setRealmID($Data->{'Realm'});
            $emailNotification->setSubRealmID(0);
            $emailNotification->setToEntityID($regDetails->{'intEntityID'});
            $emailNotification->setFromEntityID($entityID);
            $emailNotification->setDefsEmail($Defs::admin_email); #if set, this will be used instead of toEntityID
            $emailNotification->setDefsName($Defs::admin_email_name);
            $emailNotification->setNotificationType($requestType, "SENT");
            $emailNotification->setSubject("Request ID - " . $requestID);
            $emailNotification->setLang($Data->{'lang'});
            $emailNotification->setDbh($Data->{'db'});

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
    print $query->redirect("$Defs::base_url/" . $Data->{'target'} . "?client=$Data->{'client'}&a=PRA_F&pr=" . join(',', @requestIDs));
    #my $resultHTML;
    #return ($resultHTML, 'Request Summary');
}

sub displayCompletedRequest {
    my ($Data) = @_;

    my $body = " ";
    #todo 
    my $title = $Data->{'lang'}->txt("Request a Transfer - Submitted to Current Club");
    my $pr = param('pr');
    my @prids = split(',', $pr);

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

    for my $request (@{$personRequests}) {
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
            requestType => $Defs::personRequest{$request->{'strRequestType'}},
            requestResponse => $Defs::personRequestResponse{$request->{'strRequestResponse'}} || "N/A",
            #SelectLink => $selectLink,
        };

        $personDetails{'memberID'} = $request->{'strNationalNum'};
        $personDetails{'firstname'} = $request->{'strLocalFirstname'};
        $personDetails{'surname'} = $request->{'strLocalSurname'};
        $personDetails{'gender'} = $Defs::PersonGenderInfo{$request->{'intGender'} || 0} || '';
        $personDetails{'dob'} = $request->{'dtDOB'} || '';
    }

    return ("An error has been encountered.", " ") if $error; 
    my %TemplateData;

    $TemplateData{'personDetails'} = \%personDetails;
    $TemplateData{'personRequests'} = \@rowdata;
    $TemplateData{'client'} = $Data->{'client'};

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
    my $title = "Requests";

    my %reqFilters =  ();
    if ($personID)  {
        $reqFilters{'personID'} = $personID;
    }
    else    {
        $reqFilters{'(entityID'} = $entityID
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
            requestFrom => $request->{'requestFrom'} || '',
            requestTo => $request->{'requestTo'} || '',
            requestType => $Defs::personRequest{$request->{'strRequestType'}},
            requestResponse => $Defs::personRequestResponse{$request->{'strRequestResponse'}} || "N/A",
            SelectLink => $selectLink,
        }
    }

    return ("$found record found.", $title) if !$found;

    my @headers = (
        { 
            type => 'Selector',
            field => 'SelectLink',
        }, 
        {
            name => $Data->{'lang'}->txt('Person ID'),
            field => 'personID',
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
    ); 

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

    my $requestID = safe_param('rid', 'number') || 0;
	my $entityID = getID($Data->{'clientValues'}, $Data->{'clientValues'}{'currentLevel'});
    my $requestType = undef;
    my $title = "View Request";
    my $action = undef;

    my %regFilter = (
        'entityID' => $entityID,
        'requestID' => $requestID
    );
    my $request = getRequests($Data, \%regFilter);

    $request = $request->[0];
    return ("Request not found.", $title) if !$request;

    my $templateFile = undef;
    switch($request->{'strRequestType'}) {
        case "$Defs::PERSON_REQUEST_TRANSFER" {
            $templateFile = "personrequest/transfer/view.templ";
            $requestType = $Defs::PERSON_REQUEST_TRANSFER;
        }
        case "$Defs::PERSON_REQUEST_ACCESS" {
            $templateFile = "personrequest/access/view.templ";
            $requestType = $Defs::PERSON_REQUEST_ACCESS;
        }
        else {

        }
    }

    my $personDetails = Person::loadPersonDetails($Data->{'db'}, $request->{'intPersonID'});
    my $personCurrAgeLevel = Person::calculateAgeLevel($Data, $personDetails->{'currentAge'});
    my $originLevel = $Data->{'clientValues'}{'authLevel'};

    my %TemplateData = (
        'requestID' => $request->{'intPersonRequestID'} || undef,
        'requestType' => $Defs::personRequest{$request->{'strRequestType'}} || '',
        'requestFrom' => $request->{'requestFrom'} || '',
        'requestTo' => $request->{'requestTo'} || '',
        'dateRequest' => $request->{'dtDateRequest'} || '',
        'requestResponse' => $Defs::personRequestResponse{$request->{'strRequestResponse'}} || '',
        'responseBy' => $request->{'responseBy'} || '',
        'personFirstname' => $request->{'strLocalFirstname'} || '',
        'personSurname' => $request->{'strLocalSurname'} || '',
        'ISONationality' => $request->{'strISONationality'} || '',
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
        'contactISOCountry' => $request->{'strISOCountry'},
        'contactPhoneHome' => $request->{'strPhoneHome'},
        'contactEmail' => $request->{'strEmail'},
    );


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
                $action = "PF_";
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
        'client' => $tempClient || $Data->{client} || 0,
        'rid' => $requestID,
        'action' => $action,
        'showAction' => $showAction,
        'initiateRequestProcess' => $initiateRequestProcess,
        'request_type' => $requestType
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
    my $notes = safe_param('notes', 'words') || '';
	my $entityID = getID($Data->{'clientValues'}, $Data->{'clientValues'}{'currentLevel'});
    my $requestStatus = '';

    my %regFilter = (
        'entityID' => $entityID,
        'requestID' => $requestID
    );
    my $request = getRequests($Data, \%regFilter);
    $request = $request->[0];


    switch($response){
        case 'Deny' {
            $response = $Defs::PERSON_REQUEST_RESPONSE_DENIED;
            $requestStatus = $Defs::PERSON_REQUEST_STATUS_DENIED;
        }
        case 'Accept' {
            $response = $Defs::PERSON_REQUEST_RESPONSE_ACCEPTED;
            $requestStatus = $Defs::PERSON_REQUEST_STATUS_PENDING;
        }
        else {
            $response = undef;
        }
    }

    my $emailNotification = new EmailNotifications::PersonRequest();
    $emailNotification->setRealmID($Data->{'Realm'});
    $emailNotification->setSubRealmID(0);
    $emailNotification->setToEntityID($request->{'intRequestFromEntityID'});
    $emailNotification->setFromEntityID($request->{'intRequestToEntityID'});
    $emailNotification->setDefsEmail($Defs::admin_email); #if set, this will be used instead of toEntityID
    $emailNotification->setDefsName($Defs::admin_email_name);
    $emailNotification->setNotificationType($request->{'strRequestType'}, $response);
    $emailNotification->setSubject("Request ID - " . $requestID);
    $emailNotification->setLang($Data->{'lang'});
    $emailNotification->setDbh($Data->{'db'});

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
            strRequestStatus = ?
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
    if(scalar(%{$request}) == 0) {
        $body = $Data->{'lang'}->txt("Response has been submitted already.");
    }
    else {
        $body = $Data->{'lang'}->txt("You have " . $Defs::personRequestResponse{$response}) . " " . $request->{'requestFrom'} . "'s " . $Defs::personRequest{$request->{'strRequestType'}} . " request.";
    }

    my $title = $Data->{'lang'}->txt("Request Response");

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
    my $personRegoJoin = " LEFT JOIN tblPersonRegistration_$Data->{'Realm'} pr ON (pr.intPersonRequestID = pq.intPersonRequestID AND pr.intEntityID = intRequestFromEntityID) ";
    my @values = (
        $Data->{'Realm'}
    );

    if($filter->{'entityID'}) {
        $where .= "
            AND (
                    (pq.intParentMAEntityID = ? AND pq.intRequestToMAOverride = 1 AND pq.strRequestResponse is NULL)
                    OR
                    (pq.intRequestToEntityID = ? AND pq.strRequestResponse is NULL AND pq.intRequestToMAOverride = 0)
                    OR
                    (pq.intRequestFromEntityID = ? AND pq.strRequestResponse in (?, ?))
                )
            ";
        push @values, $filter->{'entityID'};
        push @values, $filter->{'entityID'};
        push @values, $filter->{'entityID'};
        push @values, $Defs::PERSON_REQUEST_RESPONSE_ACCEPTED;
        push @values, $Defs::PERSON_REQUEST_RESPONSE_DENIED;
    }

    if($filter->{'personID'}) {
        $where .= " AND pq.intPersonID = ?";
        push @values, $filter->{'personID'};
    }

    if($filter->{'requestID'} and $filter->{'entityID'}) {
        $where .= "
            AND (
                    (pq.intParentMAEntityID = ? AND pq.intRequestToMAOverride = 1 AND pq.strRequestResponse is NULL)
                    OR
                    (pq.intRequestToEntityID = ? AND pq.strRequestResponse is NULL AND pq.intPersonRequestID = ? AND pq.intRequestToMAOverride = 0)
                    OR
                    (pq.intRequestFromEntityID = ? AND pq.intPersonRequestID = ? AND pq.strRequestResponse in (?, ?))
                )
            ";
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
            DATE_FORMAT(pq.dtDateRequest,'%d %b %Y') AS prRequestDateFormatted,
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
            p.strPhoneHome,
            p.strEmail,
		    TIMESTAMPDIFF(YEAR, p.dtDOB, CURDATE()) as currentAge,
            ef.strLocalName as requestFrom,
            et.strLocalName as requestTo,
            erb.strLocalName as responseBy,
            pr.intPersonRegistrationID,
            pr.strStatus as personRegoStatus
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

    my $st = qq[
        UPDATE
            tblPersonRegistration_$Data->{'Realm'}
        SET
            strPreTransferredStatus = strStatus,
            strStatus = ?
        WHERE
            intEntityID = ?
            AND strPersonType = ?
            AND strSport = ?
            AND intPersonID = ?
            AND strStatus IN ('ACTIVE', 'PASSIVE', 'ROLLED_OVER', 'PENDING')
	];
            #AND strPersonLevel = ?

    my $db = $Data->{'db'};
    my $query = $db->prepare($st) or query_error($st);
    $query->execute(
       $Defs::PERSONREGO_STATUS_TRANSFERRED,
       $personRequest->{'intRequestToEntityID'},
       $personRequest->{'strPersonType'},
       $personRequest->{'strSport'},
       $personRequest->{'intPersonID'}
    ) or query_error($st);
        #$personRequest->{'strPersonLevel'},
}

sub setRequestStatus {
    my ($Data, $requestID, $requestStatus) = @_;

    $requestID ||= 0;
    $requestStatus ||= '';

    my $st = qq[
        UPDATE
            tblPersonRequest
        SET
            strRequestStatus = ?
        WHERE
            intPersonRequestID = ?
    ];

    my $db = $Data->{'db'};
    my $q = $db->prepare($st);
    $q->execute(
        $requestStatus,
        $requestID
    ) or query_error($st);
}

sub displayNoITC {
    my ($Data) = @_;

    my $title = $Data->{'lang'}->txt("Next step");
    my $body = $Data->{'lang'}->txt("Please request Player's ITC via TMS or directly to the other MA.");
    #return text for now
    return ($body, $title);

}

1;
