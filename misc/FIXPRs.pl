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
                                                                                                    
main();
1;

sub main	{
    my $db=connectDB();

    fixPRs($db);
}

sub fixPRs {
    my ($db) = @_;

    my $st = qq[
        SELECT 
            * 
        FROM 
            tmpTransferFix
        WHERE
            intNationalPeriodID > 0
            AND intOnLoan = 0
            AND intIsLoanedOut = 0
    ];
        #LIMIT 10
    my $qry = $db->prepare($st) or query_error($st);
    $qry->execute();

    my $stUPD = qq[
        UPDATE tblPersonRegistration_1
        SET 
            intRealmID= 88,
            strPreTransferredStatus = strStatus,
            strStatus='TRANSFERRED'
        WHERE
            intPersonID = ?
            AND intEntityID <> ?
            AND strPersonType='PLAYER'
            AND strSport = ?
            AND strPersonLevel = ?
            AND intNationalPeriodID < ?
            AND strStatus IN ('PASSIVE')
            AND intNationalPeriodID NOT IN (120)
            AND intIsLoanedOut=0
    ];
#, 'ROLLED_OVER')
    my $qryUPD = $db->prepare($stUPD) or query_error($stUPD);
    while (my $dref= $qry->fetchrow_hashref())    {
        $qryUPD->execute(
            $dref->{'intPersonID'},
            $dref->{'intEntityID'},
            $dref->{'strSport'},
            $dref->{'strPersonLevel'},
            $dref->{'intNationalPeriodID'},
        );
        
    }
    
}
