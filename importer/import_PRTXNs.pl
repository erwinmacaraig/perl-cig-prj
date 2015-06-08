#!/usr/bin/perl -w

#
# $Header: svn://svn/SWM/trunk/misc/import_bowls_clubs.pl 9483 2013-09-10 04:48:08Z tcourt $
#

use lib "..","../web","../web/comp", "../web/user", '../web/RegoForm', "../web/dashboard", "../web/RegoFormBuilder",'../web/PaymentSplit', "../web/Clearances";

use strict;
use Defs;
use Utils;
use DBI;
use CGI qw(unescape);
use SystemConfig;
use ImporterTXNs;
                                                                                                    
main();
1;

sub main	{
    my $db=connectDB();

    insertPRTransactions($db);
}

sub insertPRTransactions  {
    my ($db) = @_;

    my $st = qq[
        SELECT 
            * 
        FROM 
            tblPersonRegistration_1
        WHERE
            tmpProductID > 0
    ];
    my $qry = $db->prepare($st) or query_error($st);
    $qry->execute();
    while (my $dref= $qry->fetchrow_hashref())    {
        my $status = 0;
        $status = 1 if ($dref->{'tmpisPaid'} eq 'YES');
        importTXN(
            $db, 
            $dref->{'intPersonID'}, 
            $dref->{'intPersonRegistrationID'}, 
            $dref->{'intEntityID'}, 
            $dref->{'tmpProductID'}, 
            $dref->{'tmpAmount'}, 
            $dref->{'tmpdtPaid'}, 
            $dref->{'tmpPaymentRef'}, 
            $status, 
            0
        );
    }
    
}
#sub linkProducts {
#    my ($db) = @_;
#    my $st = qq[
#        UPDATE tblPersonRegistration_1 as PR
#            INNER JOIN tblProducts as P ON (P.strProductCode = CONCAT(PR.tmpProductCode, PR.strPersonType, PR.strSport))
#        SET PR.tmpProductID = P.intProductID
#        WHERE P.strProductCode <> ''
#    ];
#    $db->do($st);
#}

