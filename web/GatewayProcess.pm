package GatewayProcess;
require Exporter;
@ISA = qw(Exporter);
@EXPORT=qw(gatewayProcess markTXNSentToGateway markGatewayAsResponded calcPayTryRef);
@EXPORT_OK=qw(gatewayProcess markTXNSentToGateway markGatewayAsResponded calcPayTryRef);

use lib '.', '..', "comp", 'RegoForm', "dashboard", "RegoFormBuilder",'PaymentSplit', "user" ;

use strict;
use DBI;

use Lang;
use Utils;
use Payments;
use SystemConfig;
use ConfigOptions;
use Reg_common;
use Products;
use PageMain;
use CGI qw(param unescape escape);

use ExternalGateway;
use Gateway_Common;
use TTTemplate;
use ClubFlow;

use Data::Dumper;

sub calcPayTryRef	{
	my ($prefix, $logID) = @_;

	$prefix ||= '';
	my $value = $prefix.$logID;
	
	return $value;
}

sub markTXNSentToGateway    {

    my ($Data, $logID) = @_;

    $logID ||= 0;
    return if (! $logID);

	return if (! $Data->{'SystemConfig'}{'MarkTXN_SentToGateway'});

    my $st = qq[
        UPDATE tblTransLog as TL 
            INNER JOIN tblTXNLogs as TXNLogs ON (TXNLogs.intTLogID = TL.intLogID)
            INNER JOIN tblTransactions as T ON (T.intTransactionID = TXNLogs.intTXNID)
        SET
            TL.intSentToGateway = 1, 
            T.intSentToGateway = 1, 
            TL.intPaymentGatewayResponded = 0, 
            T.intPaymentGatewayResponded = 0
        WHERE
            TL.intLogID = ?
            AND TL.intStatus=0 
            AND T.intStatus=0
    ];

    my $query = $Data->{'db'}->prepare($st);
    $query->execute($logID);
}

sub markGatewayAsResponded  {

    my ($Data, $logID) = @_;
    return if ! $logID;

    my $stUPD = qq[
        UPDATE tblTransLog as TL
            INNER JOIN tblTXNLogs as TXNLogs ON (TXNLogs.intTLogID = TL.intLogID)
            INNER JOIN tblTransactions as T ON (T.intTransactionID = TXNLogs.intTXNID)
        SET
            TL.intPaymentGatewayResponded = 1, T.intPaymentGatewayResponded= 1
        WHERE
            TL.intLogID = ?
	    AND TL.intStatus NOT IN (3)
    ];
    my $query = $Data->{'db'}->prepare($stUPD);
    $query->execute($logID);


    my $st = qq[
        SELECT
            DISTINCT
                t.intWFTaskID
        FROM
            tblTransLog as TL
            INNER JOIN tblTXNLogs as TXNLogs ON (TXNLogs.intTLogID = TL.intLogID)
            INNER JOIN tblTransactions as TXN ON (TXN.intTransactionID = TXNLogs.intTXNID)
            INNER JOIN tblWFTask as t ON (t.intPersonRegistrationID = TXN.intPersonRegistrationID)
        WHERE
            TL.intLogID = ?
            AND t.intPersonRegistrationID > 0
            AND TXN.intTableType = $Defs::LEVEL_PERSON
	    AND TL.intStatus NOT IN (3)
    ];
    my $q= $Data->{'db'}->prepare($st);
    $q->execute($logID);
    my $dref = $q->fetchrow_hashref();
    my $taskID = $dref->{'intWFTaskID'} || 0;

    if (! $taskID)  {
        ## Lets check if its a Club Product
        $st = qq[
            SELECT
                DISTINCT
                    t.intWFTaskID
            FROM
                tblTransLog as TL
                INNER JOIN tblTXNLogs as TXNLogs ON (TXNLogs.intTLogID = TL.intLogID)
                INNER JOIN tblTransactions as TXN ON (TXN.intTransactionID = TXNLogs.intTXNID)
                INNER JOIN tblWFTask as t ON (t.intEntityID= TXN.intID)
            WHERE
                TL.intLogID = ?
                AND TXN.intTableType = $Defs::LEVEL_CLUB
                AND t.strTaskStatus = 'ACTIVE'
	    	AND TL.intStatus NOT IN (3)
        ];
        $q= $Data->{'db'}->prepare($st);
        $q->execute($logID);
        my $dref = $q->fetchrow_hashref();
        $taskID = $dref->{'intWFTaskID'} || 0;
    }

    if ($taskID)    {
        $stUPD = qq[
            UPDATE tblWFTask
                SET intPaymentGatewayResponded = 1
            WHERE
                intRealmID = ?
                AND intWFTaskID = ?
        ];
        my $qUPD= $Data->{'db'}->prepare($stUPD);
        $qUPD->execute($Data->{'Realm'}, $taskID);
    }

}

sub gatewayProcess {

    my ($Data, $logID, $client, $returnVals_ref, $check_action) = @_;

    my $db = $Data->{'db'};
	my $action = $returnVals_ref->{'action'} || '';
	my $external= $returnVals_ref->{'ext'} || '';
	my $chkv= $returnVals_ref->{'chkv'} || '';

	my $st = qq[
		INSERT IGNORE INTO tblTransLog_Counts
		(intTLogID, dtLog, strResponseCode)
		VALUES (?, NOW(), ?)
	];
	my $qry= $db->prepare($st);
	#$qry->execute($logID, $returnVals_ref->{'GATEWAY_RESPONSE_CODE'});


	my ($Order, $Transactions) = gatewayTransactions($Data, $logID);
	 $Order->{'Status'} = $Order->{'TLStatus'} ==1 ? 1 : 0;
print STDERR "ORDER STATUS " . $Order->{'Status'};
  $Data->{'SystemConfig'}{'PaymentConfigID'} = $Data->{'SystemConfig'}{'PaymentConfigUsedID'} ||  $Data->{'SystemConfig'}{'PaymentConfigID'};

  my ($paymentSettings, undef) = getPaymentSettings($Data,$Order->{'PaymentType'}, $Order->{'PaymentConfigID'}, $external);

    markGatewayAsResponded($Data, $logID) if ($returnVals_ref->{'GATEWAY_RESPONSE_CODE'} ne 'HOLD');
	#return if ($Order->{'Status'} == -1 or $Order->{'Status'} == 1);

  {
    #my $chkvalue= param('rescode') . $Order->{'TotalAmount'}. $logID; ## NOTE: Different to one being sent
    my $chkvalue= $returnVals_ref->{'GATEWAY_RESPONSE_CODE'} . $Order->{'TotalAmount'}. $logID; ## NOTE: Different to one being senn
    my $m;
    $m = new MD5;
    $m->reset();
	
$paymentSettings->{'gatewaySalt'} ||='';
    $m->add($paymentSettings->{'gatewaySalt'}, $chkvalue);
    $chkvalue = $m->hexdigest();
    #warn "chkv VS. chkvalue :: $chkv :::::  $chkvalue ";
    unless ($check_action eq 'SUCCESS') {
        $Order->{'Status'} = -1 if ($chkv ne $chkvalue);
    }
  }
   my $body='';
	if ($Order->{'Status'} != 0)	{
		$body  = qq[<div align="center" class="warningmsg" style="font-size:14px;">There was an error</div>BB$Order->{'Status'} $Order->{'AssocID'}];
		if ($Order->{'AssocID'})	{
			my $template_ref = getPaymentTemplate($Data, $Order->{'AssocID'});
			my $templateBody = $template_ref->{'strFailureTemplate'} || 'payment_failure.templ';
      my $trans_ref = gatewayTransLog($Data, $logID);
      if ($Order->{'Status'} == 1)	{
				$trans_ref->{'AlreadyPaid'} = 1;
				$trans_ref->{'CC_SOFT_DESC'} = $paymentSettings->{'gatewayCreditCardNote'} || '';
		  	$templateBody = $template_ref->{'strSuccessTemplate'} || 'payment_success.templ';
      }
      $trans_ref->{'headerImage'}= $template_ref->{'strHeaderHTML'} || '';
      my $result = runTemplate(
            undef,
            $trans_ref, ,
            'payment/'.$templateBody
      );
      $body = $result if($result);
		}
	}
	elsif ($action eq '1' or $action eq 'S')	{ ## WAS 'S'

		$body = ExternalGateway::ExternalGatewayUpdate($Data, $paymentSettings, $client, $returnVals_ref, $logID, $Order->{'AssocID'}); #, $Order, $external, $encryptedID);
        markGatewayAsResponded($Data, $logID) if ($returnVals_ref->{'GATEWAY_RESPONSE_CODE'} ne 'HOLD');
	}
	#disconnectDB($db);

 	#print "Content-type: text/html\n\n";
  	#print $body;
}

1;
