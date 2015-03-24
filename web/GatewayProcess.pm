package GatewayProcess;
require Exporter;
@ISA = qw(Exporter);
@EXPORT=qw(gatewayProcess payTryRead payTryRedirectBack payTryContinueProcess markTXNSentToGateway markGatewayAsResponded calcPayTryRef);
@EXPORT_OK=qw(gatewayProcess payTryRead payTryRedirectBack payTryContinueProcess markTXNSentToGateway markGatewayAsResponded calcPayTryRef);

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
use PersonFlow;
use TransferFlow;
use BulkRenewalsFlow;

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

    my $st = qq[
        UPDATE tblTransLog as TL 
            INNER JOIN tblTXNLogs as TXNLogs ON (TXNLogs.intTLogID = TL.intLogID)
            INNER JOIN tblTransactions as T ON (T.intTransactionID = TXNLogs.intTXNID)
        SET
            TL.intSentToGateway = 1, T.intSentToGateway = 1
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

sub payTryContinueProcess {

    my ($Data, $payTry, $client, $logID) = @_;

    $payTry->{'return'} = 1;
    if ($payTry->{'strContinueAction'} eq 'CLUBFLOW')   {
        handleClubFlow($payTry->{'a'}, $Data, $payTry);
    }
    if ($payTry->{'strContinueAction'} eq 'REGOFLOW')   {
        handlePersonFlow($payTry->{'a'}, $Data, $payTry);
    }
    if ($payTry->{'strContinueAction'} eq 'TRANSFER')   {
        handleTransferFlow($payTry->{'a'}, $Data, $payTry);
    }
    if ($payTry->{'strContinueAction'} eq 'BULKRENEWALS')   {
        handleBulkRenewalsFlow($payTry->{'a'}, $Data, $payTry);
    }
    return;
}

sub payTryRedirectBack  {

    my ($Data, $payTry, $client, $logID, $autoRun) = @_;

    $autoRun ||= 0;
    my $a = $payTry->{'nextPayAction'} || $payTry->{'a'};
    #my $redirect_link = "main.cgi?client=$client&amp;a=$a&amp;run=1&tl=$logID";
    my $redirect_link = "main.cgi?client=$client&amp;a=$a&amp;payMethod=now&amp;run=0&amp;tl=$logID";

    foreach my $k (keys %{$payTry}) {
        next if $k eq 'client';
        next if $k eq 'a';
        next if $k =~/clubID|teamID|userID|stateID|assocID|intzonID|regionID|zoneID|intregID|authLevel|natID|venueID|authLevel|currentLevel|interID/;
        next if $k =~/intAmount|dt_end_paid|strComments|paymentType|^act_|dtLog|dt_start_paid|paymentID|dd_|gatewayCount/;
        #next if $k =~/dtype/;
        next if $k =~/^ss$/;
        next if $k =~/^cc_submit/;
        next if $k =~/^pt_submit/;
        $redirect_link .= "&$k=".$payTry->{$k};
		
    }
print STDERR $redirect_link;
    return $redirect_link if ! $autoRun;

    print "Status: 302 Moved Temporarily\n";
    print "Location: $redirect_link\n\n";
    return;

     print qq[Content-type: text/html\n\n];
        print qq[
        <HTML>
        <BODY>
        <SCRIPT LANGUAGE="JavaScript1.2">
            parent.location.href="$redirect_link";
            noScript = 1;
        </SCRIPT>
        </BODY>
        </HTML>
        ];

}

sub payTryRead  {

    my ($Data, $logID, $try) = @_;

    my $where = qq[intTransLogID = ?];
    my $id = $logID;
    if ($logID and $try)  {
        $where = qq[strPayReference = ?];
        #$id = $try;
    }
    return undef if (! $logID and ! $try);
    my $st = qq[
        SELECT 
            * 
        FROM
            tblPayTry
        WHERE 
            $where
    ];
    my $query = $Data->{'db'}->prepare($st);
    $query->execute($id);
    my $href = $query->fetchrow_hashref();
    my $values = JSON::from_json($href->{'strLog'});
    $values->{'strContinueAction'} = $href->{'strContinueAction'};
    $values->{'intTransLogID'} = $href->{'intTransLogID'};
    $values->{'strPayReference'} = $href->{'strPayReference'};
    return $values;
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
	$qry->execute($logID, $returnVals_ref->{'GATEWAY_RESPONSE_CODE'});


	my ($Order, $Transactions) = gatewayTransactions($Data, $logID);
	 $Order->{'Status'} = $Order->{'TLStatus'} ==1 ? 1 : 0;
  $Data->{'SystemConfig'}{'PaymentConfigID'} = $Data->{'SystemConfig'}{'PaymentConfigUsedID'} ||  $Data->{'SystemConfig'}{'PaymentConfigID'};

  my ($paymentSettings, undef) = getPaymentSettings($Data,$Order->{'PaymentType'}, $Order->{'PaymentConfigID'}, $external);

    markGatewayAsResponded($Data, $logID);
	#return if ($Order->{'Status'} == -1 or $Order->{'Status'} == 1);

  {
    #my $chkvalue= param('rescode') . $Order->{'TotalAmount'}. $logID; ## NOTE: Different to one being sent
    my $chkvalue= $returnVals_ref->{'GATEWAY_RESPONSE_CODE'} . $Order->{'TotalAmount'}. $logID; ## NOTE: Different to one being senn
    my $m;
    $m = new MD5;
    $m->reset();
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
	}
	#disconnectDB($db);

 	#print "Content-type: text/html\n\n";
  	#print $body;
}

1;
