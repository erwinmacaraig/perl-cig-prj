#!/usr/bin/perl -w

use lib ".", "..", "../web";
use Defs;
use Utils;
use DBI;
use strict;
use SystemConfig;
#use PersonRequest;
use Data::Dumper;

{
    my %Data = ();
    my $db = connectDB();
    my @realm;

    $Data{'db'} = $db;

    my $targetRealm = getRealm(\%Data);

    while(my $realm = $targetRealm->fetchrow_hashref()) {
        $Data{'Realm'} = $realm->{'intRealmID'};
        $Data{'SystemConfig'} = getSystemConfig(\%Data);

        if($Data{'SystemConfig'}{'allowPersonRequest'} and $Data{'SystemConfig'}{'personRequestTimeout'}) {
            setToMAOverride(\%Data);


            #PREP IN CASE THERE'S A NEED TO ASSIGN TO RA LEVEL
            #my $personRequests = getPersonRequests(\%Data);
            #while(my $personRequest = $personRequests->fetchrow_hashref()) {
            #    my $requestFromParents = getParents(\%Data, $personRequest->{'intRequestFromEntityID'});
            #    my $requestToParents = getParents(\%Data, $personRequest->{'intRequestToEntityID'});
            #    print STDERR Dumper $requestFromParents->{'raParentID'};
            #    print STDERR Dumper $requestToParents->{'raParentID'};
            #    #check: if requestFromRAparent = requestToRAparent, re-assign to requestToRAparent otherwise re-assign to requestToMAparent
            #}
        }

    }
}

sub getPersonRequests {
    my ($Data) = @_;

    my $timeOut = $Data->{'SystemConfig'}{'personRequestTimeout'};

    my $where;
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
            pq.strRequestStatus,
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
            AND DATE(DATE_ADD(pq.dtDateRequest, INTERVAL ? DAY)) <= DATE(NOW())
            AND pq.strRequestResponse IS NULL
    ];

    my $db = $Data->{'db'};
    my $q = $db->prepare($st);
    $q->execute(
        $Data->{'Realm'},
        $timeOut
    ) or query_error($st);
    return $q;
}

sub getRealm {
    my ($Data) = @_;

    my $st = qq[
        SELECT 
            intRealmID
        FROM 
            tblRealms
    ];

    my $db = $Data->{'db'};
    my $q = $db->prepare($st);
    $q->execute() or query_error($st);

    return $q;
}

sub getParents {
    my ($Data, $entityID) = @_;

    my $st = qq[
        SELECT
            ma.intParentID as maParentID,
            ra.intParentID as raParentID,
            c.intChildID as childID
        FROM
            tblTempEntityStructure c
        INNER JOIN
            tblTempEntityStructure ra ON (ra.intChildID = c.intChildID AND ra.intParentLevel = ?)
        INNER JOIN
            tblTempEntityStructure ma ON (ma.intChildID = ra.intChildID AND ma.intParentLevel = ?)
        WHERE
            c.intChildID = ?
            AND c.intRealmID = ?
        LIMIT 1
    ];

    my @parentMap = ();

    my $db = $Data->{'db'};
    my $q = $db->prepare($st);
    $q->execute(
        $Defs::LEVEL_REGION,
        $Defs::LEVEL_NATIONAL,
        $entityID,
        $Data->{'Realm'}
    ) or query_error($st);

    return $q->fetchrow_hashref();
}

sub setToMAOverride {
    my ($Data) = @_;

    #TODO: might handle RAoverride later on

    my $timeOut = $Data->{'SystemConfig'}{'personRequestTimeout'};
    my $st = qq[
        UPDATE
            tblPersonRequest pq
        INNER JOIN
            tblTempEntityStructure es
            ON (
                es.intChildID = pq.intRequestToEntityID
                AND es.intChildLevel = ?
                AND es.intParentLevel = ?
            )
        SET
            pq.intRequestToMAOverride = 1,
            pq.intParentMAEntityID = es.intParentID
        WHERE
            pq.intRealmID = ?
            AND DATE(DATE_ADD(pq.dtDateRequest, INTERVAL ? DAY)) <= DATE(NOW())
            AND pq.strRequestResponse IS NULL
    ];

    my $db = $Data->{'db'};
    my $q = $db->prepare($st);
    $q->execute(
        $Defs::LEVEL_CLUB,
        $Defs::LEVEL_NATIONAL,
        $Data->{'Realm'},
        $timeOut
    ) or query_error($st);
}
