#!/usr/bin/perl -w

use lib "..","../web","../web/comp", "../web/user", '../web/RegoForm', "../web/dashboard", "../web/RegoFormBuilder",'../web/PaymentSplit', "../web/Clearances";

use strict;
use Defs;
use Utils;
use DBI;
use CGI qw(unescape);
use SystemConfig;
use Data::Dumper;

main();
1;

sub main	{
    my $db=connectDB();

    my $st = qq[
        SELECT
            PR.intPersonRegistrationID,
            PR.intPersonID,
            PR.intEntityID,
            PR.strSport,
            PR.dtFrom,
            PR.dtTo
        FROM
            tblPersonRegistration_1 PR
            INNER JOIN tblPerson P ON (PR.intPersonID = P.intPersonID)
        WHERE
            P.intInternationalTransfer = 1 
        ORDER BY
            PR.intPersonID, PR.dtFrom, PR.dtTo
    ];

    my $qry = $db->prepare($st) or query_error($st);
    $qry->execute();

    my $currentPID = 0;
    my $currentEID = 0;
    my $skipflag = 0;
    my $FAFInternational = '1659';
    my @PRids;

    while (my $dref = $qry->fetchrow_hashref()) {
        if($currentPID != $dref->{'intPersonID'}) {
            $skipflag = 0;
            $currentPID = $dref->{'intPersonID'};

            if($dref->{'intEntityID'} == $FAFInternational) {
                push @PRids, $dref->{'intPersonRegistrationID'};
            }
            else {
                $skipflag = 1;
            }
        }
        else {
            if($skipflag == 1) {
                next;
            }
            elsif($dref->{'intEntityID'} == $FAFInternational) {
                push @PRids, $dref->{'intPersonRegistrationID'};
            }
            else {
                $skipflag = 1;
            }
        }
    }

    my $PRList = join(',', @PRids);
    my $stUP = qq[
        UPDATE
            tblPersonRegistration_1
        SET
            intNewBaseRecord = 1
        WHERE 
            intPersonRegistrationID IN ($PRList)
    ];

    my $qryUP = $db->prepare($stUP) or query_error($stUP);
    $qryUP->execute();

}

