#!/usr/bin/perl -w

use lib "../web","..", "../web/user", "../web/Clearances", "../web/PaymentSplit", "../web/RegoFormBuilder", "../web/dashboard", "../web/RegoForm";
use Defs;
use Utils;
use DBI;
use PersonRequest;
use SystemConfig;
use AssocTime;
use Data::Dumper;
use strict;

{
    my $db = connectDB();
	my %Data = ();
	$Data{'db'} = $db;
    $Data{'Realm'} = 1; #default to 1
    $Data{'SystemConfig'} = getSystemConfig(\%Data);

    my $timezone = $Data{'SystemConfig'}{'Timezone'} || 'UTC';
    my $today = dateatAssoc($timezone);

    my $st = qq [
        SELECT
            prq.*
        FROM
            tblPersonRequest prq
        INNER JOIN
            tblPersonRegistration_$Data{'Realm'} pr ON (pr.intPersonID = prq.intPersonID AND pr.intPersonRequestID = prq.intPersonRequestID)
        WHERE
            pr.strStatus IN ('ACTIVE', 'ROLLED_OVER', 'PASSIVE')
            AND prq.strRequestType = 'LOAN'
            AND prq.strRequestStatus IN ('COMPLETED')
            AND prq.strRequestResponse = 'ACCEPTED'
            AND prq.intOpenLoan= 1
            AND (
                    DATE_FORMAT(prq.dtLoanTo, '%Y-%m-%d') < ?
                )
            AND DATE_FORMAT(prq.dtLoanTo, '%Y-%m-%d') != '0000-00-00'
    ];
# Changed to < so its "yesterday"
#        LEFT JOIN
#            tblNationalPeriod np ON (np.intNationalPeriodID = pr.intNationalPeriodID)

#                    OR
#                    np.dtTo <= DATE_FORMAT(NOW(), '%Y-%m-%d')

    my @personRequestIDs;
    my @personIDs;

    my $q = $db->prepare($st);
    $q->execute($today) or query_error($st);

    while(my $personRequest = $q->fetchrow_hashref()) {
        push @personRequestIDs, $personRequest->{'intPersonRequestID'};
        push @personIDs, $personRequest->{'intPersonID'};
    }

    if(scalar(@personRequestIDs) and scalar(@personIDs)) {
        deactivatePlayerLoan(\%Data, \@personRequestIDs, \@personIDs);
    }

}
1;

