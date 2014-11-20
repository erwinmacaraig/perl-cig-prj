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

use NABGateway;
use Gateway_Common;
use TTTemplate;
use Data::Dumper;

sub payTryRedirectBack  {

    my ($payTry, $client, $logID) = @_;

    my $a = $payTry->{'nextPayAction'} || $payTry->{'a'};
    my $redirect_link = "main.cgi?client=$client&amp;a=$a&amp;run=1&tl=$logID";
    foreach my $k (keys %{$payTry}) {
        next if $k eq 'client';
        next if $k eq 'a';
        next if $k =~/clubID|teamID|userID|stateID|assocID|intzonID|regionID|zoneID|intregID|authLevel|natID|venueID|authLevel|currentLevel|interID/;
        next if $k =~/dtype/;
        next if $k =~/^ss$/;
        next if $k =~/^cc_submit/;
        next if $k =~/^pt_submit/;
        $redirect_link .= "&amp;$k=".$payTry->{$k};
    }
    my $body = "HELLO";
    #print "Content-type: text/html\n\n";
    #print $body;
    #print qq[<a href="$redirect_link">LINK</a><br>$redirect_link];

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

    my ($Data, $try) = @_;

    my $st = qq[
        SELECT 
            * 
        FROM
            tblPayTry
        WHERE 
            intTransLogID = ?
    ];
    my $query = $Data->{'db'}->prepare($st);
    $query->execute($try);
    my $href = $query->fetchrow_hashref();
print STDERR $st;
print STDERR "TRY: $try\n";
    my $values = JSON::from_json($href->{'strLog'});
    return $values;
}

sub gatewayProcess {

    my ($Data, $logID, $client) = @_;

    my $db = $Data->{'db'};
	my $action = param('sa') || 0;
	my $external= param('ext') || 0;
	my $encryptedID= param('ei') || 0;
	my $chkv= param('chkv') || 0;

  my %returnVals = ();
  my $redirect =0;
  $returnVals{'GATEWAY_TXN_ID'}= param('txnid') || '';
  $returnVals{'GATEWAY_AUTH_ID'}= param('authid') || '';
  $returnVals{'GATEWAY_SIG'}= param('sig') || '';
  $returnVals{'GATEWAY_SETTLEMENT_DATE'}= param('settdate') || '';
  $returnVals{'GATEWAY_RESPONSE_CODE'}= param('rescode') || '';
  $returnVals{'GATEWAY_RESPONSE_TEXT'}= param('restext') || '';
  $returnVals{'Other1'} = param('restext') || '';
  $returnVals{'Other2'} = param('authid') || '';
  $returnVals{'ResponseCode'} = 'ERROR';

  $returnVals{'ResponseText'} = NABResponseCodes($returnVals{'GATEWAY_RESPONSE_CODE'});
  if ($returnVals{'GATEWAY_RESPONSE_CODE'} =~/^00|08|OK$/)  {
    $returnVals{'ResponseCode'} = 'OK';
  }
	
	my $st = qq[
		INSERT IGNORE INTO tblTransLog_Counts
		(intTLogID, dtLog, strResponseCode)
		VALUES (?, NOW(), ?)
	];
	my $qry= $db->prepare($st);
	$qry->execute($logID, $returnVals{'GATEWAY_RESPONSE_CODE'});


	my ($Order, $Transactions) = gatewayTransactions($Data, $logID);
	 $Order->{'Status'} = $Order->{'TLStatus'} >=1 ? 1 : 0;
  $Data->{'SystemConfig'}{'PaymentConfigID'} = $Data->{'SystemConfig'}{'PaymentConfigUsedID'} ||  $Data->{'SystemConfig'}{'PaymentConfigID'};

  my ($paymentSettings, undef) = getPaymentSettings($Data,$Order->{'PaymentType'}, $Order->{'PaymentConfigID'}, $external);

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
	elsif ($action eq '1')	{ ## WAS 'S'
		$body = NABUpdate($Data, $paymentSettings, $client, \%returnVals, $logID, $Order->{'AssocID'}); #, $Order, $external, $encryptedID);
	}
	disconnectDB($db);

 	#print "Content-type: text/html\n\n";
  	#print $body;
}

1;
