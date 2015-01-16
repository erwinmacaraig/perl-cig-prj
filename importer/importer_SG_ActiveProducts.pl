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
    
    my $st = qq[
        SELECT
            PR.*,
            NP.dtFrom as NPFrom,
            NP.dtTo as NPTo
        FROM
            tblPersonRegistration_$Data{'Realm'} as PR
            LEFT JOIN tblNationalPeriod as NP ON (
                NP.intNationalPeriodID = PR.intNationalPeriodID
            )
        WHERE
            strStatus='ACTIVE'
            AND PR.intNationalPeriodID=8
    ];
    my $qry= $db->prepare($st);
    

    my $stTXN = qq[
        INSERT INTO tblTransactions (
            intStatus,
            curAmount,
            intQty,
            dtTransaction,
            dtPaid,
            intRealmID,
            intID,
            intTableType,
            intTXNEntityID,
            intProductID,
            intTransLogID,
            intPersonRegistrationID,
            dtStart,
            dtEnd
        )
        VALUES (
            1,
            ?,
            1,
            NOW(),
            NOW(),
            ?,
            ?,
            1,
            ?,
            ?,
            0,
            ?,
            ?,
            ?
        )
    ];
    my $qryTXN= $db->prepare($stTXN);
            
    my $stTL = qq[
        INSERT INTO tblTransLog (
            dtLog,
            intAmount,
            intRealmID,
            intStatus
        )
        VALUES (
            NOW(),
            ?,
            ?,
            1
        )
    ];
    my $qryTL= $db->prepare($stTL);

    my $stTXNLogs = qq[
        INSERT INTO tblTXNLogs (
            intTXNID,
            intTLogID 
        )
        VALUES (
            ?,
            ?
        )
    ];
    my $qryTXNLogs= $db->prepare($stTXNLogs);

    my $stTXNUpdate = qq[
        UPDATE 
            tblTransactions 
        SET 
            intTransLogID=?
        WHERE
            intTransactionID=?
    ];
    my $qryTXNUpdate= $db->prepare($stTXNUpdate);

    my $stProd = qq[
        SELECT 
            *
        FROM 
            tblProducts
        WHERE 
            intRealmID=?
            AND intProductID=?
    ];
    my $qryProd= $db->prepare($stProd);
    
    $qry->execute();
    while (my $dref= $qry->fetchrow_hashref())    {
        my $productID=0;
        $productID = 1 if ($dref->{'strPersonType'} eq 'COACH');
        $productID = 2 if ($dref->{'strPersonType'} eq 'REFEREE');
        $productID = 3 if ($dref->{'strPersonType'} eq 'PLAYER' and $dref->{'strPersonLevel'} eq 'PROFESSIONAL');
        $productID = 3 if ($dref->{'strPersonType'} eq 'PLAYER' and $dref->{'strPersonLevel'} eq 'AMATEUR_U_C');
        $productID = 4 if ($dref->{'strPersonType'} eq 'PLAYER' and $dref->{'strPersonLevel'} eq 'AMATEUR');
        $productID = 5 if ($dref->{'strPersonType'} eq 'PLAYER' and $dref->{'strPersonLevel'} eq 'AMATEUR' and $dref->{'strAgeLevel'} eq 'MINOR');
        next if ! $productID;

        $qryProd->execute(
            $Data{'Realm'},
            $productID
        );
        my $prodRef = $qryProd->fetchrow_hashref();

        $qryTXN->execute(
            $prodRef->{'curDefaultAmount'},
            $Data{'Realm'},
            $dref->{'intPersonID'},
            $dref->{'intEntityID'},
            $productID,
            $dref->{'intPersonRegistrationID'},
            $dref->{'NPFrom'},
            $dref->{'NPTo'},
        );
        my $txnID = $qryTXN->{mysql_insertid} || 0;
        next if ! $txnID;
        $qryTL->execute(
            $prodRef->{'curDefaultAmount'},
            $Data{'Realm'}
        );
        my $TLogID= $qryTL->{mysql_insertid} || 0;
        next if ! $TLogID;
        $qryTXNLogs->execute(
            $txnID,
            $TLogID
        );
        $qryTXNUpdate->execute(
            $TLogID,
            $txnID
        );
    }

}
