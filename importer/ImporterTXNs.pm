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

    my ($db, $personID, $personRegistrationID, $entityID, $productID, $amountPaid, $dtPaid, $payRef, $status, $paymentType) = @_;

    my $responseText = 'PAYMENT_SUCCESSFUL';
    my $responseCode= 'OK';

    $payRef ||= '';
    $paymentType ||= 20;
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
            INNER JOIN tblNationalPeriod as NP ON (
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
            dtEnd,
            curPerItem
        )
        VALUES (
            ?,
            ?,
            1,
            ?,
            ?,
            ?,
            ?,
            1,
            ?,
            ?,
            0,
            ?,
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
            strResponseCode,
            strResponseText,
            intPaymentType,
            strTXN,
            strOtherRef2
        )
        VALUES (
            ?,
            ?,
            ?,
            ?,
            ?,
            ?,
            ?,
            ?,
            'Imported'
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
        $dtPaid,
        $dtPaid,
        1,
        $personID,
        $entityID,
        $productID,
        $personRegistrationID,
        $dref->{'NPFrom'},
        $dref->{'NPTo'},
        $amountPaid
    );
    my $txnID = $qryTXN->{mysql_insertid} || 0;
    return if ! $txnID;
    return if ! $status;
    $qryTL->execute(
        $dtPaid,
        $amountPaid,
        1,
        $status,
        $responseCode,
        $responseText,
        $paymentType,
        $payRef
    );
    my $TLogID= $qryTL->{mysql_insertid} || 0;
    return if ! $TLogID;
    $qryTXNLogs->execute(
        $txnID,
        $TLogID
    );
    $qryTXNUpdate->execute(
        $TLogID,
        $txnID
    );
    my $stRef = qq[
        UPDATE tblTransLog
        SET strOnlinePayReference = ?
        WHERE intLogID = ?
    ];

    my $ref = $TLogID;
    my $qryRef= $db->prepare($stRef);
    $qryRef->execute(
        $ref,
        $TLogID
    );
}

