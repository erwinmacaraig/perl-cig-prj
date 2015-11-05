#!/usr/bin/perl

#
# $Header: svn://svn/SWM/trunk/misc/moneylogInsert.pl 8250 2013-04-08 08:24:36Z rlee $
#

use strict;

use lib "..","../web","../web/comp", "../web/user", '../web/RegoForm', "../web/dashboard", "../web/RegoFormBuilder",'../web/PaymentSplit', "../web/Clearances";

use Defs;
use Utils;
use DBI;
use CGI qw(unescape);
use SystemConfig;

main();

sub main	{


	my %Data = ();
	my $db = connectDB();
	$Data{'db'} = $db;
	$Data{'Realm'} = 1;
	$Data{'RealmSubType'} = 0;
    $Data{'SystemConfig'}=getSystemConfig(\%Data);
    my $maxNPID = 41 ; #2014
    
    $db->do(qq[UPDATE tblPersonRegistration_1 as PR INNER JOIN tblPersonRequest as PRQ ON (PRQ.intPersonID=PR.intPersonID) SET PR.dtTo = PRQ.dtLoanTo WHERE strRequestType ='LOAN' AND PR.dtTo = '0000-00-00']);
    my $st = qq[
        SELECT
            *
        FROM
            tblPersonRegistration_$Data{'Realm'}
        WHERE
            strPersonType='PLAYER'
            AND intOnLoan = 0
            AND intIsLoanedOut = 0
        ORDER BY
            dtFrom
    ];
    

    my $stTSNF = qq[
        UPDATE tblPersonRegistration_$Data{'Realm'}
        SET 
            strOldStatus=strStatus,
            strStatus="TRANSFERRED",
            dtTo = ?
        WHERE
            intPersonID=?
            AND strPersonType="PLAYER"
            AND intPersonRegistrationID < ? 
            AND intEntityID <> ?
            AND strStatus IN ("ACTIVE", "PASSIVE", "ROLLED_OVER", "PENDING")
    ];
    my $qryTSNF= $db->prepare($stTSNF);

    my $stLEVEL = qq[
        UPDATE tblPersonRegistration_$Data{'Realm'}
        SET 
            strOldStatus=strStatus,
            strStatus="ROLLED_OVER",
            dtTo = ?
        WHERE
            intPersonID=?
            AND strPersonType="PLAYER"
            AND intPersonRegistrationID < ? 
            AND intEntityID= ?
            AND strPersonLevel <> ?
            AND strStatus IN ("ACTIVE", "PASSIVE", "ROLLED_OVER", "PENDING")
    ];
    my $qryLEVEL= $db->prepare($stLEVEL);

    my $stROLLOVER = qq[
        UPDATE tblPersonRegistration_$Data{'Realm'}
        SET 
            strOldStatus=strStatus,
            strStatus="ROLLED_OVER"
        WHERE
            intPersonID=?
            AND strPersonType="PLAYER"
            AND intPersonRegistrationID < ? 
            AND intEntityID= ?
            AND strPersonLevel = ? 
            AND strStatus IN ("ACTIVE", "PASSIVE", "PENDING")
    ];
    my $qryROLLOVER= $db->prepare($stROLLOVER);


    my $qryPR= $db->prepare($st);
    $qryPR->execute();
    while (my $dref= $qryPR->fetchrow_hashref())    {
        $qryTSNF->execute(
            $dref->{'dtTo'} || '0000-00-00',
            $dref->{'intPersonID'},
            $dref->{'intPersonRegistrationID'},
            $dref->{'intEntityID'},
        );
        $qryLEVEL->execute(
            $dref->{'dtTo'} || '0000-00-00',
            $dref->{'intPersonID'},
            $dref->{'intPersonRegistrationID'},
            $dref->{'intEntityID'},
            $dref->{'strPersonLevel'},
        );
        $qryROLLOVER->execute(
            $dref->{'intPersonID'},
            $dref->{'intPersonRegistrationID'},
            $dref->{'intEntityID'},
            $dref->{'strPersonLevel'},
        );
    }

    ## Now set rest to PASSIVE
    my $stPASSIVE = qq[
        UPDATE tblPersonRegistration_$Data{'Realm'} as PR
            LEFT JOIN tblNationalPeriod as NP ON (NP.intNationalPeriodID = PR.intNationalPeriodID)
        SET 
            PR.strOldStatus=PR.strStatus,
            PR.strStatus="PASSIVE"
        WHERE
            NP.intCurrentNew=0 
            AND NP.intCurrentRenewal=0 
            AND PR.strStatus IN ("ACTIVE")
    ];
    my $qryPASSIVE= $db->prepare($stPASSIVE);
    #$qryPASSIVE->execute($maxNPID);
    $qryPASSIVE->execute();

    $db->do(qq[UPDATE tblPersonRegistration_1 as PR INNER JOIN tblPersonRequest as PRQ ON (PRQ.intPersonID=PR.intPersonID) SET PR.dtTo = PRQ.dtLoanTo WHERE strRequestType ='LOAN' AND PR.dtTo = '0000-00-00']);

print "PR RECORDS DONE\n";
}
