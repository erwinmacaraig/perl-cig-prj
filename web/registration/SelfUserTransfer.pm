package SelfUserTransfer;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = @EXPORT_OK = qw(
    handleSelfUserTransfer
);

use strict;
use lib '.', '..', '../..', "../../..", "../user", "user";

use TTTemplate;
use CGI qw(param);
use Defs;
use Utils;
use Lang;
use SelfUserObj;
use SystemConfig;
use PersonSummaryPanel;
use Switch;
use Data::Dumper;
use InstanceOf;

sub handleSelfUserTransfer {
    my ($Data, $user, $action) = @_;

    my $resultHTML  = q{};
    my $pageHeading;

    switch($action){
        case "TRANSFER_INIT" {
            ($resultHTML, $pageHeading) = initTransfer($Data, $user);
        }
        case "TRANSFER_S" {
            ($resultHTML, $pageHeading) = submitRequest($Data, $user);
        }
        else {
            return;
        }
    }

    return ($resultHTML, $pageHeading);
}

sub initTransfer {
    my ($Data, $user) = @_;

    my $query = new CGI;
    my $personID = safe_param('pID', 'number') || '';
    my $personRegistrationID = safe_param('rtargetid','number') || '';
    my $transferTo = safe_param('transferto','number') || '';
    my $notes = safe_param('request_notes', 'words') || '';
    my $action = safe_param('a','word') || '';

    my $heading = $Data->{'lang'}->txt("Start Transfer");

    my $userid ||= $user->id();
    return (
        $Data->{'lang'}->txt("Invalid parameters."),
        $Data->{'lang'}->txt("Error"),
    ) if (!$userid or !$personID or !$personRegistrationID);


    my $dref = _getValidRegistration($Data, $user, $personID, $personRegistrationID);

    return (
        $Data->{'lang'}->txt("It's either the record does not exist or you have a pending request for the same person registration record."),
        $Data->{'lang'}->txt("Error"),
    ) if (!$dref);

    $dref->{'PersonType'} = $Defs::personType{$dref->{'strPersonType'}};
    $dref->{'RegistrationNature'} = $Defs::registrationNature{$dref->{'strRegistrationNature'}};
    $dref->{'RegistationStatus'} = $Defs::personRegoStatus{$dref->{'strStatus'}};
    $dref->{'Sport'} = $Defs::sportType{$dref->{'strSport'}};
    $dref->{'PersonLevel'} = $Defs::personLevel{$dref->{'strPersonLevel'}};
    $dref->{'AgeLevel'} = $Defs::ageLevel{$dref->{'strAgeLevel'}};

    my @exclude;
    push @exclude, $dref->{'intEntityID'};

    my $entityOptions =  _getTargetEntityList($Data, \@exclude); 
	my %TemplateData = (
        rego => $dref,
		Lang => $Data->{'lang'},
        action => "TRANSFER_S",
        entityList => $entityOptions,
        pid => $dref->{'intPersonID'},
        rtargetid => $dref->{'intPersonRegistrationID'},
	);

    if($action eq "TRANSFER_S" and (!$transferTo or !$notes)) {
        $TemplateData{'error'} = $Data->{'lang'}->txt("Please select from the list of Clubs.");
        $TemplateData{'displayMessage'} = 1;
    }

	my $body = runTemplate(
        $Data,
        \%TemplateData,
        'selfrego/transfer_init.templ'
    );

    return ($body, $heading);
}

sub submitRequest {
    my ($Data, $user) = @_;

    my $query = new CGI;
    my $personID = safe_param('pID', 'number') || '';
    my $personRegistrationID = safe_param('rtargetid','number') || '';
    my $transferTo = safe_param('transferto','number') || '';
    my $request_notes = safe_param('request_notes','words') || '';

    if(!$transferTo) {
        return initTransfer($Data, $user);
    }
    else {
        my $dref = _getValidRegistration($Data, $user, $personID, $personRegistrationID);

        return (
            $Data->{'lang'}->txt("It's either the record does not exist or you have a pending request for the same person registration record."),
            $Data->{'lang'}->txt("Error"),
        ) if (!$dref);


        my $st = qq[
            INSERT INTO
                tblPersonRequest
                (
                    strRequestType,
                    intPersonID,
                    intExistingPersonRegistrationID,
                    strSport,
                    strPersonType,
                    strPersonLevel,
                    strNewPersonLevel,
                    strPersonEntityRole,
                    intRealmID,
                    intRequestFromEntityID,
                    intRequestToEntityID,
                    intRequestToMAOverride,
                    strRequestNotes,
                    strRequestStatus,
                    dtDateRequest,
                    tTimeStamp,
                    intSelfTriggered,
                    intRequestFromSelfUserID
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
                    ?,
                    ?,
                    NOW(),
                    NOW(),
                    ?,
                    ?
                )
        ];

        my $db = $Data->{'db'};
        my $q = $db->prepare($st);
        $q->execute(
            $Defs::PERSON_REQUEST_TRANSFER,
            $personID,
            $dref->{'intPersonRegistrationID'} || 0,
            $dref->{'strSport'},
            $dref->{'strPersonType'},
            $dref->{'strPersonLevel'},
            $dref->{'strPersonLevel'},
            $dref->{'strPersonEntityRole'},
            $Data->{'Realm'},
            $transferTo,
            $dref->{'intEntityID'},
            0,
            $request_notes,
            $Defs::PERSON_REQUEST_STATUS_PREAPPROVAL,
            1,
            $user->id()
        );
		
        my $requestID = $db->{mysql_insertid};
		$st = qq[SELECT strLocalName FROM tblEntity WHERE intEntityID = ? AND intRealmID = $Data->{'Realm'}];
		$q = $db->prepare($st);
		$q->execute($transferTo);
		my $clubReg = $q->fetchrow_hashref();
		
        my $notificationType = undef;

        my %notificationData = (
            Reason => $request_notes,
            WorkTaskType => $Defs::personRequest{'TRANSFER'},
            Person => $dref->{'strLocalFirstname'} . ' ' . $dref->{'strLocalSurname'},
            CurrentClub => $dref->{'EntityName'} || '',
			Requestor => $dref->{'strLocalFirstname'} . ' ' . $dref->{'strLocalSurname'},  
			RequestingClub => $clubReg->{'strLocalName'},
        );

        my $clubObj = getInstanceOf($Data, 'club');
		my $emailNotification = new EmailNotifications::PersonRequest();
        $emailNotification->setRealmID($Data->{'Realm'});
        $emailNotification->setSubRealmID(0);
        $emailNotification->setToEntityID($dref->{'intEntityID'});
        $emailNotification->setDefsName($Defs::admin_email_name);
        $emailNotification->setDefsEmail($Defs::admin_email); #if set, this will be used instead of toEntityID
        $emailNotification->setDefsName($Defs::admin_email_name);
		$emailNotification->setNotificationType($Defs::PERSON_REQUEST_SELF_TRANSFER, "SENT");
        $emailNotification->setSubject($dref->{'strLocalFirstname'} . " " . $dref->{'strLocalSurname'});
        $emailNotification->setLang($Data->{'lang'});
        $emailNotification->setDbh($Data->{'db'});
        $emailNotification->setData($Data);
        $emailNotification->setWorkTaskDetails(\%notificationData);

        my $emailTemplate = $emailNotification->initialiseTemplate()->retrieve();
        $emailNotification->send($emailTemplate) if $emailTemplate->getConfig('toEntityNotification') == 1;
        $dref->{'personRegoStatus'} = $dref->{'PersonStatus'};
		my %PageData = (
			registration => $dref,
			PersonSummaryPanel => personSummaryPanel($Data, $personID),
			url => $Defs::base_url,
		);
		
		$body = runTemplate($Data, \%PageData, 'personrequest/transfer/selftransfercomplete.templ') || '';


	return $body;
    }
}

sub _getTargetEntityList {
    my ($Data, $exclude) = @_;

    my $systemConfig = getSystemConfig($Data);
    my $acceptSelfRegoFilter = qq [ AND intAcceptSelfRego = 1 ] if ($systemConfig->{'allow_SelfRego'});

    my $excludeEntityList;
    if(scalar(@{$exclude})) {
        $excludeEntityList = join(', ', @{$exclude});
        $excludeEntityList = qq [ AND intEntityID NOT IN ($excludeEntityList) ];
    }

    my $st = qq [
        SELECT
            E.strLocalName,
            E.intEntityID
        FROM
            tblEntity AS E
        WHERE
            E.intRealmID = ?
            AND intEntityLevel = 3 
            AND E.strStatus = 'ACTIVE'
            $acceptSelfRegoFilter
            $excludeEntityList
        ORDER BY 
            E.strLocalName
        ];
    my $q = $Data->{'db'}->prepare($st);
    $q->execute(
        $Data->{'Realm'},
    );

    my @vals = ();
    while(my ($name, $id) = $q->fetchrow_array())   {
        push @vals, {
            name => $name,
            value => $id,
        };
    }

    return \@vals;
}

sub _getValidRegistration {
    my ($Data, $user, $personID, $personRegistrationID) = @_;

    my $st = qq [
        SELECT
            A.intSelfUserID,
            A.intEntityID,
            P.intPersonID,
            P.strLocalFirstname,
            P.strLocalSurname,
            P.dtDOB,
            P.intGender,
            P.strStatus as PersonStatus,
            NP.strNationalPeriodName,
            NP.dtTo as NPdtTo,
            PR.*,
            PRQ.strRequestStatus,
            E.strLocalName AS EntityName
        FROM
            tblSelfUserAuth A
            INNER JOIN
                tblPerson P ON (A.intEntityTypeID = $Defs::LEVEL_PERSON AND A.intEntityID = P.intPersonID)
            INNER JOIN
                tblPersonRegistration_$Data->{'Realm'} PR ON (PR.intPersonID = P.intPersonID)
            LEFT JOIN
                tblPersonRequest PRQ ON (PRQ.intPersonID = P.intPersonID AND PRQ.intExistingPersonRegistrationID = PR.intPersonRegistrationID)
            INNER JOIN
                tblEntity E ON (E.intEntityID = PR.intEntityID)
            INNER JOIN
                tblNationalPeriod as NP ON (NP.intNationalPeriodID = PR.intNationalPeriodID)
        WHERE
            A.intSelfUserID = ?
            AND P.intPersonID = ?
            AND PR.intPersonRegistrationID = ?
            AND (PRQ.strRequestStatus IS NULL or PRQ.strRequestStatus = '' OR PRQ.strRequestStatus NOT IN ('PENDING', 'INPROGRESS', 'PREAPPROVAL'))
        LIMIT 1
    ];

    my $q = $Data->{'db'}->prepare($st);
    $q->execute(
        $user->id(),
        $personID,
        $personRegistrationID,
    );

    my $dref = $q->fetchrow_hashref();


    return $dref || 0;
}

1;

