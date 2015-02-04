package GatewayProcess;
require Exporter;
@ISA = qw(Exporter);
@EXPORT=qw(gatewayProcess payTryRead payTryRedirectBack);
@EXPORT_OK=qw(gatewayProcess payTryRead payTryRedirectBack);

use lib '.', '..', "comp", 'RegoForm', "dashboard", "RegoFormBuilder",'PaymentSplit', "user";

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
use Data::Dumper;

sub payTryRedirectBack  {
print STDERR "IN REDIRECT BACK!!\n";

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
        next if $k =~/dtype/;
        next if $k =~/^ss$/;
        next if $k =~/^cc_submit/;
        next if $k =~/^pt_submit/;
        $redirect_link .= "&$k=".$payTry->{$k};
    }
    my $body = "HELLO";
    #print "Content-type: text/html\n\n";
    #print $body;
    #print qq[<a href="$redirect_link">LINK</a><br>$redirect_link];
    return $redirect_link if ! $autoRun;

print STDERR $redirect_link;
print STDERR "SSSS";
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
    if (! $logID and $try)  {
        $where = qq[intTryID = ?];
        $id = $try;;
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
print STDERR $st;
    my $values = JSON::from_json($href->{'strLog'});
    return $values;
}

sub gatewayProcess {

    my ($Data, $logID, $client, $returnVals_ref) = @_;

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
	 $Order->{'Status'} = $Order->{'TLStatus'} >=1 ? 1 : 0;
  $Data->{'SystemConfig'}{'PaymentConfigID'} = $Data->{'SystemConfig'}{'PaymentConfigUsedID'} ||  $Data->{'SystemConfig'}{'PaymentConfigID'};

  my ($paymentSettings, undef) = getPaymentSettings($Data,$Order->{'PaymentType'}, $Order->{'PaymentConfigID'}, $external);


    print STDERR $paymentSettings->{'gatewayCode'};
    ### Might need IF test here per gatewayCode
  $returnVals_ref->{'ResponseText'} = NABResponseCodes($returnVals_ref->{'GATEWAY_RESPONSE_CODE'});
  $returnVals_ref->{'ResponseCode'} = $returnVals_ref->{'GATEWAY_RESPONSE_CODE'};
  if ($returnVals_ref->{'GATEWAY_RESPONSE_CODE'} =~/^00|08|OK$/)  {
    $returnVals_ref->{'ResponseCode'} = 'OK';
  }




  {
    my $chkvalue= param('rescode') . $Order->{'TotalAmount'}. $logID; ## NOTE: Different to one being sent
    my $m;
    $m = new MD5;
    $m->reset();
    $m->add($paymentSettings->{'gatewaySalt'}, $chkvalue);
    $chkvalue = $m->hexdigest();
    warn "chkv VS. chkvalue :: $chkv :::::  $chkvalue ";
    $Order->{'Status'} = -1 if ($chkv ne $chkvalue);
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
		$body = ExternalGatewayUpdate($Data, $paymentSettings, $client, $returnVals_ref, $logID, $Order->{'AssocID'}); #, $Order, $external, $encryptedID);
	}
	disconnectDB($db);

 	#print "Content-type: text/html\n\n";
  	#print $body;
}

1;
