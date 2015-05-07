package ImporterTXNs;
require Exporter;
@ISA    = qw(Exporter);
@EXPORT = @EXPORT_OK = qw(
  importTXN
);

use strict;
use lib "..","../web","../web/comp", "../web/user", '../web/RegoForm', "../web/dashboard", "../web/RegoFormBuilder",'../web/PaymentSplit', "../web/Clearances";

use Defs;
use DBI;
use Utils;
use ConfigOptions qw(ProcessPermissions);
use SystemConfig;
use CGI qw(cookie unescape);

use Log;
use Data::Dumper;



sub importTXN   {

    my ($db, $personID, $personRegistrationID, $entityID, $productID, $amountPaid, $status) = @_;

    $personID || return;
    $personRegistrationID || return;
    $entityID || return;
    $productID || return;
    $amountPaid ||= 0;
    $status ||= 0;

    my $st = qq[
        SELECT
            NP.dtFrom as NPFrom,
            NP.dtTo as NPTo
        FROM
            tblPersonRegistration_1 as PR
            INNER JOIN tblNationalPeriod as NP (
                NP.intNationalPeriodID = PR.intNationalPeriodID
            )
        WHERE
            PR.intPersonID= ?
            AND PR.intPersonRegistrationID = ?
    ];
    my $qry= $db->prepare($st);
    $qry->execute(
        $personID,
        $personRegistrationID
    );
    my $dref = $qry->fetchrow_hashref();
    
            

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
            ?,
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
            intStatus,
        )
        VALUES (
            NOW(),
            ?,
            ?,
            ?
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

    $qryTXN->execute(
        $status,
        $amountPaid,
        1,
        $personID,
        $entityID,
        $productID,
        $personRegistrationID,
        $dref->{'NPFrom'},
        $dref->{'NPTo'},
    );
    my $txnID = $qryTXN->{mysql_insertid} || 0;
    next if ! $txnID;
    $qryTL->execute(
        $amountPaid,
        1,
        $status
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

