package PersonRequest;
require Exporter;
@ISA = qw(Exporter);

@EXPORT = @EXPORT_OK = qw(
    handlePersonRequest
    listPersonRecord
    getRequests
    listRequests
    finaliseTransfer
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

use CGI qw(unescape param);
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
            $title = "Request a Transfer";
            $TemplateData{'action'} = 'PRA_search';
            $TemplateData{'request_type'} = 'transfer';
            $body = runTemplate(
                $Data,
                \%TemplateData,
                'personrequest/generic/search_form.templ',
            );
        }
        case 'PRA_R' {
            $title = "Request Access to Person Details";
            $TemplateData{'request_type'} = 'access';
            $TemplateData{'action'} = 'PRA_search';
            $body = runTemplate(
                $Data,
                \%TemplateData,
                'personrequest/generic/search_form.templ',
            );
        }
        case 'PRA_search' {
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
        else {
        }
    }

	return ($body, $title);
}

sub listPersonRecord {
    my ($Data) = @_;

	my $p = new CGI;
	my %params = $p->Vars();

    my $client = setClient( $Data->{'clientValues'} ) || '';
	my $entityID = getID($Data->{'clientValues'}, $Data->{'clientValues'}{'currentLevel'});

    my $MID = safe_param('mid','number') || '';
    my $firstname = safe_param('firstname','word') || '';
    my $lastname = safe_param('lastname','word') || '';
    #TODO: might need to validate dob or use jquery datepicker
    my $dob = $params{'dob'} || '';
    my $request_type = $params{'request_type'} || '';

    my $title = $Data->{'lang'}->txt('Search Result');
    warn "PERSONREQUEST $MID";
    warn "PERSONFNAME $firstname";
    warn "PERSONLNAME $lastname";
    warn "PERSONDOB $dob";
    my %result;

    #TODO: might use priority column in the query, then limit the result to 1 grouped by club
    # FOOTBALL  | 1
    # FUTSAL    | 2
    # ACTIVE    | 1
    # PASSIVE   | 2
    # PENDING   | 3
    my $st = qq[
        SELECT
            E.intEntityID,
            E.strLocalName as currentClub,
            P.intPersonID,
            P.strLocalFirstname,
            P.strLocalSurname,
            P.strStatus as personStatus,
            P.dtDOB,
            PR.intPersonRegistrationID,
            PR.strStatus as personRegistrationStatus,
            PR.strPersonType,
            PR.strSport,
            PR.strPersonLevel
        FROM
            tblPerson P
        INNER JOIN tblPersonRegistration_$Data->{'Realm'} PR
            ON (
                PR.intEntityID != ?
                AND PR.intPersonID = P.intPersonID
                AND PR.intRealmID = P.intRealmID
                AND PR.strStatus IN ('ACTIVE', 'PASSIVE','PENDING')
                AND PR.strPersonType = 'PLAYER'
                )
        LEFT JOIN tblEntity E 
            ON (E.intEntityID = PR.intEntityID and E.intRealmID = PR.intRealmID)
        WHERE
            P.intRealmID = ?
            AND P.strNationalNum = ?
            AND P.strStatus IN ('REGISTERED', 'PASSIVE','PENDING')
            AND
                (P.strLocalFirstname LIKE CONCAT('%',?,'%') OR P.strLocalSurname LIKE CONCAT('%',?,'%'))
            AND P.dtDOB = ?
    ];

    my $db = $Data->{'db'};
    my $q = $db->prepare($st) or query_error($st);
    $q->execute(
        $entityID,
        $Data->{'Realm'},
        $MID,
        $firstname,
        $lastname,
        $dob,
    ) or query_error($st);

    my $found = 0;
    my @rowdata = ();

    while(my $tdref = $q->fetchrow_hashref()) {
        $found = 1;
        print STDERR Dumper $tdref;

        my $actionLink = qq[ <span class="button-small generic-button"><a href="$Data->{'target'}?client=$client&amp;a=PRA_initRequest&amp;pid=$tdref->{'intPersonID'}&amp;prid=$tdref->{'intPersonRegistrationID'}&amp;request_type=$request_type">]. $Data->{'lang'}->txt($request_type) . q[</a></span>];    
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
        }
    }

    return ("$found record found.", $title) if !$found;

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
        {
            name => $Data->{'lang'}->txt('Type'),
            field => 'personType',
        }, 
        {
            name => $Data->{'lang'}->txt('Person Level'),
            field => 'personLevel',
        }, 
        {
            name => $Data->{'lang'}->txt('Registration Status'),
            field => 'personRegoStatus',
        },
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

    my $resultHTML = qq[
        <div class="grid-filter-wrap">
            <div style="width:99%;">$rectype_options</div>
            $grid
        </div>
    ];

    return ($resultHTML, $title);
}

sub initRequestPage {
    my ($Data) = @_;

    my $title = "Confirm Request";
    my $personID = safe_param('pid', 'number') || 0;
    my $personRegistrationID = safe_param('prid', 'number') || 0;
    my $requestType = safe_param('request_type', 'word') || '';

    my %RequestAction = (
        'request_type' => $requestType,
        'client' => $Data->{client} || 0,
        'backAction' => 'PRA_T',
        'sendAction' => 'PRA_submit',
        'target' =>$Data->{'target'},
    );

    my %TemplateData;
    $TemplateData{'RequestAction'} = \%RequestAction;
    $TemplateData{'personID'} = $personID;
    $TemplateData{'personRegistrationID'} = $personRegistrationID;

    my $body = runTemplate(
        $Data,
        \%TemplateData,
        'personrequest/generic/submit_request.templ',
    );

    return ($body, $title);
}

sub submitRequestPage {
    my ($Data) = @_;

    my $personID = safe_param('pid', 'number') || 0;
    my $personRegistrationID = safe_param('prid', 'number') || 0;
    my $notes = safe_param('request_notes', 'words') || '';
	my $entityID = getID($Data->{'clientValues'}, $Data->{'clientValues'}{'currentLevel'});

    #TODO: check below
    #if inter-RA, override to MA
    #otherwise RA approves
    my $MAOverride = 0;

    my $requestType = getRequestType();

    my %Reg = (
        personRegistrationID => $personRegistrationID || 0,
    );

    my ($count, $reg_ref) = PersonRegistration::getRegistrationData(
        $Data,
        $personID,
        \%Reg
    );

    return ("Record does not exist.", "Send Request") if(!$count);

    print STDERR Dumper $reg_ref;
    print STDERR Dumper $count;
 
    warn "REQUEST TYPE $requestType";
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
    );

    my $requestID = $db->{mysql_insertid};
    warn "REQUEST ID $requestID";

    return("Request has been sent.", " ");
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

    warn "REQUEST COUNT $found";

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

    my $personDetails = PersonRegistration::loadPersonDetails($Data->{'db'}, $request->{'intPersonID'});
    my $personCurrAgeLevel = PersonRegistration::calculateAgeLevel($Data, $personDetails->{'currentAge'});
    my $originLevel = $Data->{'clientValues'}{'authLevel'};

    my %TemplateData = (
        'requestID' => $request->{'intPersonRequestID'} || 0,
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
        'sport' => $request->{'strSport'} || '',
        'personType' => $request->{'strPersonType'} || '',
        'personLevel' => $request->{'strPersonLevel'} || '',
        'requestNotes' => $request->{'strRequestNotes'} || '',
        'responseNotes' => $request->{'strResponseNotes'} || '',

        'personID' => $request->{'intPersonID'},
        'personAgeLevel' => $personCurrAgeLevel,
        'requestOriginLevel' => $originLevel,
        'requestEntityID' => $entityID,
    );


    my $showAction = 0;
    if ($entityID == $request->{'intRequestToEntityID'}) {
        $showAction = 1;
        $action = "PRA_S";
    }

    my $initiateRequestProcess = 0;
    if($entityID == $request->{'intRequestFromEntityID'} and $request->{'strRequestResponse'} eq $Defs::PERSON_REQUEST_RESPONSE_ACCEPTED) {
        $initiateRequestProcess = 1;
        $action = "PREGF_TU";
    }

    my %RequestAction = (
        'client' => $Data->{client} || 0,
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

    switch($response){
        case 'Deny' {
            $response = $Defs::PERSON_REQUEST_RESPONSE_DENIED;
        }
        case 'Accept' {
            $response = $Defs::PERSON_REQUEST_RESPONSE_ACCEPTED;
        }
        else {
            $response = undef;
        }
    }

    warn "RESPONSE $response";
    warn "REQUEST ID $requestID";
    #TODO: check if current entity has the right to update the request
    my $body = " ";
    my $title = " ";

    my $st = qq[
        UPDATE
            tblPersonRequest
        SET
            strRequestResponse = ?,
            intResponseBy = ?,
            strResponseNotes = ?
        WHERE
            intPersonRequestID = ?
    ];

    my $db = $Data->{'db'};
    my $q = $db->prepare($st);
    $q->execute(
        $response,
        $entityID,
        $notes,
        $requestID
    ) or query_error($st);

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
    my @values = (
        $Data->{'Realm'}
    );

    if($filter->{'entityID'}) {
        $where .= " AND ((pq.intRequestToEntityID = ? AND pq.strRequestResponse is NULL) OR (pq.intRequestFromEntityID = ? AND pq.strRequestResponse in (?, ?))) ";
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
        $where .= " AND (((pq.intRequestToEntityID = ? AND pq.strRequestResponse is NULL AND pq.intPersonRequestID = ?)) OR (pq.intRequestFromEntityID = ? AND pq.intPersonRequestID = ? AND pq.strRequestResponse in (?, ?))) ";
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

    print STDERR Dumper $filter;
    print STDERR Dumper @values;
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
            pq.strRequestResponse,
            pq.strResponseNotes,
            pq.intResponseBy,
            p.strLocalFirstname,
            p.strLocalSurname,
            p.strStatus as personStatus,
            p.strISONationality,
            p.dtDOB,
            p.intGender,
            ef.strLocalName as requestFrom,
            et.strLocalName as requestTo,
            erb.strLocalName as responseBy
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
        WHERE
            pq.intRealmID = ?
            $where
    ];

    my $db = $Data->{'db'};
    my $q = $db->prepare($st);
    $q->execute(@values) or query_error($st);

    my @personRequests = ();
      
    while(my $dref = $q->fetchrow_hashref()) {
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
            AND strPersonLevel = ?
            AND intPersonID = ?
            AND strStatus IN ('ACTIVE', 'PASSIVE', 'ROLLED_OVER', 'PENDING')
	];

    my $db = $Data->{'db'};
    my $query = $db->prepare($st) or query_error($st);
    $query->execute(
       $Defs::PERSONREGO_STATUS_TRANSFERRED,
       $personRequest->{'intRequestToEntityID'},
       $personRequest->{'strPersonType'},
       $personRequest->{'strSport'},
       $personRequest->{'strPersonLevel'},
       $personRequest->{'intPersonID'}
    ) or query_error($st);


}

1;
