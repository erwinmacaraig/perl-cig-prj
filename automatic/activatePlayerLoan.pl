#!/usr/bin/perl -w

use lib "../web","..", "../web/user", "../web/Clearances", "../web/PaymentSplit", "../web/RegoFormBuilder", "../web/dashboard", "../web/RegoForm";
use Defs;
use Utils;
use DBI;
use PersonRequest;
use SystemConfig;
use Data::Dumper;
use strict;

{
    my $db = connectDB();
	my %Data = ();
	$Data{'db'} = $db;
    $Data{'Realm'} = 1; #default to 1
    $Data{'SystemConfig'} = getSystemConfig(\%Data);

    my $st = qq [
        SELECT
            prq.*
        FROM
            tblPersonRequest prq
        INNER JOIN
            tblPersonRegistration_$Data{'Realm'} pr ON (pr.intPersonRequestID = prq.intPersonRequestID)
        WHERE
            pr.strStatus = 'PENDING'
            AND prq.strRequestType = 'LOAN'
            AND prq.strRequestStatus IN ('COMPLETED')
            AND prq.strRequestResponse = 'ACCEPTED'
            AND DATE_FORMAT(prq.dtLoanFrom, '%Y-%m-%d') <= DATE_FORMAT(NOW(), '%Y-%m-%d') 
    ];

    my @personRequestIDs;
    my @personIDs;

    my $q = $db->prepare($st);
    $q->execute() or query_error($st);

    while(my $personRequest = $q->fetchrow_hashref()) {
        push @personRequestIDs, $personRequest->{'intPersonRequestID'};
        push @personIDs, $personRequest->{'intPersonID'};
    }

    if(scalar(@personRequestIDs) and scalar(@personIDs)) {
        activatePlayerLoan(\%Data, \@personRequestIDs, \@personIDs);
    }

}
1;

