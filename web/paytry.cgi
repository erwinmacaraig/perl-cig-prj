#!/usr/bin/perl -w

#
# $Header: svn://svn/SWM/trunk/web/payments_process.cgi 8249 2013-04-08 08:14:07Z rlee $
#

use DBI;
use CGI qw(:cgi escape unescape);

use strict;

use lib "..",".",'PaymentSplit'; #, "../..";
#use lib "/u/rego_v6","/u/rego_v6/web";

use Lang;
use Utils;
use Date::Calc qw(:all);
use DeQuote;

use MD5;
use Payments;
use Reg_common;

use SystemConfig;
use ConfigOptions;
use Email;
use Products;
use GatewayProcess;
use PayTry;
use Localisation;
use WorkFlow;
use MA_Gateways;
use MCache;

main();


sub main	{

	my $client = param('client') || 0;
	my $selfRego= param('selfRego') || 0;
    my $cgi = new CGI;
    my %params=$cgi->Vars();

    my $db=connectDB();
    my %Data=();
    $Data{'db'}=$db;
    my %clientValues = getClient($client);
    $Data{'clientValues'} = \%clientValues;
    ( $Data{'Realm'}, $Data{'RealmSubType'} ) = getRealm( \%Data );
    if ($selfRego)  {
        $Data{'Realm'} ||= 1;
        $Data{'clientValues'}{'authLevel'} = 1;
    }

    $Data{'cache'}  = new MCache();


    getDBConfig(\%Data);
    $Data{'SystemConfig'}=getSystemConfig(\%Data);
    initLocalisation(\%Data);

     my $lang   = Lang->get_handle('', $Data{'SystemConfig'}) || die "Can't get a language handle!";
    foreach my $key ( keys %clientValues) {
        $params{$key} = $clientValues{$key};
    }

    my @transactions=();
    foreach my $k ( keys %params) {
        if ($k =~ /^act_/)   {
            $k=~s/.*_//;
            next  if $k=~/[^\d]/;
            push @transactions, $k;
        }
        if ($k eq 'a' and $params{$k} eq 'P_TXNLogstep2')   {
            #$params{'a'} = "P_TXNLog_list";
			$params{'a'} = "TXN_PAY_INV_RESULT_P"
        }
        if ($k eq 'a' and $params{$k} eq 'C_TXNLogstep2')   {
            $params{'a'} = "C_TXNLog_list";
        }
    }
        
    $Data{'lang'} = $lang;

    if ($params{'txnIds'})  {
        @transactions= split /:/, $params{'txnIds'};
    }
    require JSON;
    my $datalog= JSON::to_json( \%params);
    my $gCount = param('gatewayCount') || 0;
    my $continueAction = param('cA') || '';
    my $paymentType= '';
    foreach my $i (1 .. $gCount)    {
        if (param("cc_submit[$i]")) {
            $paymentType= param("pt_submit[$i]");
        }
    }

    my ($logID, $amount, $chkvalue, $session, $paymentSettings) = Payments::checkoutConfirm(\%Data, $paymentType, \@transactions,1,1);
    
	my $st = qq[
        INSERT INTO tblPayTry (
            intRealmID,
            intSelfRego,
            strPayReference,
            intTransLogID,
            strLog,
            strContinueAction,
            dtTry
        )
        VALUES (
            ?,
            ?,
            ?,
            ?,
            ?,
            ?,
            NOW()
        )
    ];
    my $qry= $db->prepare($st) or query_error($st);
	my $payRef = calcPayTryRef($Data{'SystemConfig'}{'paymentPrefix'},$logID);
    $qry->execute(
        $Data{'Realm'},
        $selfRego || 0,
        $payRef,
        $logID,
        $datalog,
        $continueAction
        ) or query_error($st);
    my $tryID= $qry->{mysql_insertid};
    $st = qq[
	UPDATE tblTransLog
		SET strOnlinePayReference= ?
		WHERE intLogID = ?
		LIMIT 1
	];
    my $qryTXNUPD= $db->prepare($st) or query_error($st);
    $qryTXNUPD->execute(
	$payRef,
	$logID
	);
    #disconnectDB($db);
    my $baseurl = $Defs::base_url;
    $baseurl = 'registration/index.cgi' if ($selfRego);
    my $cancelPayPalURL = $baseurl . $paymentSettings->{'gatewayCancelURL'} . qq[&amp;ci=$payRef&client=$client]; ##$Defs::paypal_CANCEL_URL;

    ## In here I will build up URL per Gateway -- intPaymentConfigID or have a GATEWAYCODE ?
    ## Pass control to gateway
    my $paymentURL = '';
    my $gatewaySpecific ='';

    my $currentLang = $Data{'lang'}->getLocale($Data{'SystemConfig'});

    if ($paymentSettings->{'gatewayCode'} eq 'NABExt1') {
        $paymentURL = $paymentSettings->{'gateway_url'} .qq[?nh=$Data{'noheader'}&amp;a=P&amp;client=$client&amp;ci=$payRef&amp;chkv=$chkvalue&amp;session=$session&amp;amount=$amount&amp;logID=$logID];
    }
    if ($paymentSettings->{'gatewayCode'} eq 'checkoutfi')  {
        my %MAGateway= ();
        $MAGateway{'nh'} = $Data{'noheader'};
        $MAGateway{'client'} = $client;
        $MAGateway{'ci'} = $payRef;
        $MAGateway{'chkv'} = $chkvalue;
        $MAGateway{'session'} = $session;
        $MAGateway{'amount'} = $amount;
        $MAGateway{'logID'} = $logID;
        $MAGateway{'currentLang'} = $currentLang;
        
        #$MAGateway{''} = 

        $gatewaySpecific = MAGateway_FI_checkoutFI(\%MAGateway, $paymentSettings);
        $paymentURL = $gatewaySpecific->{'paymentURL'};
        $st = qq[
	        UPDATE tblTransLog
		    SET strReceiptRef = ?
		    WHERE intLogID = ?
		    LIMIT 1
	    ];
        my $qryTXNUPD= $db->prepare($st) or query_error($st);
        my $reference = $gatewaySpecific->{'REFERENCE'} || '';
        $qryTXNUPD->execute(
	        $reference,
	        $logID
	    );
    }
    if ($paymentSettings->{'gatewayCode'} eq 'hk_paydollar')  {
        my %MAGateway= ();
        $MAGateway{'nh'} = $Data{'noheader'};
        $MAGateway{'client'} = $client;
        $MAGateway{'ci'} = $payRef;
        $MAGateway{'chkv'} = $chkvalue;
        $MAGateway{'session'} = $session;
        $MAGateway{'amount'} = $amount;
        $MAGateway{'logID'} = $logID;
        $MAGateway{'currentLang'} = $currentLang;
        
        #$MAGateway{''} = 

        $gatewaySpecific = MAGateway_HKPayDollar(\%MAGateway, $paymentSettings);
        $paymentURL = $gatewaySpecific->{'paymentURL'};
    }
    if ($paymentSettings->{'gatewayCode'} eq 'sg_easypay')  {
        my %MAGateway= ();
        $MAGateway{'nh'} = $Data{'noheader'};
        $MAGateway{'client'} = $client;
        $MAGateway{'ci'} = $payRef;
        $MAGateway{'chkv'} = $chkvalue;
        $MAGateway{'session'} = $session;
        $MAGateway{'amount'} = $amount;
        $MAGateway{'logID'} = $logID;
        $MAGateway{'currentLang'} = $currentLang;

        $gatewaySpecific = MAGateway_SGEasyPay(\%MAGateway, $paymentSettings);
        $paymentURL = $gatewaySpecific->{'paymentURL'};
    }


    markTXNSentToGateway(\%Data, $logID);

    my $payTry = payTryRead(\%Data, $logID, 0);

    if ($paymentSettings->{'gatewayProcessPreGateway'})  {
        #$Data{'clientValues'} = $payTry;
        my $client= setClient(\%{$payTry});
        #$Data{'client'}=$client;
        initLocalisation(\%Data);
        payTryContinueProcess(\%Data, $payTry, $client, $logID);
    }

    my $cancelURL = payTryRedirectBack(\%Data, $payTry, $client, $logID, 0);

    if ($paymentSettings->{'paymentType'} == $Defs::PAYMENT_ONLINEPAYPAL) {
        $paymentURL = qq[$Defs::base_url/paypal.cgi?nh=$Data{'noheader'}&amp;a=P&amp;client=$client&amp;ci=$logID&amp;session=$session];
    }
    my $gateway_body= qq[<a href="$paymentURL">Proceed to Payment</a>];
    my $cancel_body= qq[<a href="$cancelURL">Cancel Payment</a>];

    my $manualPaymentURL = $paymentURL;
	if (defined $gatewaySpecific && $gatewaySpecific)	{
        foreach my $k (keys %{$gatewaySpecific}) {
            my $val = $gatewaySpecific->{$k};
            $manualPaymentURL .= qq[&amp;$k=$val];
        } 
	}
    $manualPaymentURL .= qq[&amp;ci=$payRef&amp;logID=$logID&chkv=$chkvalue];
    my $proceed_body = qq[
    <html>
    <body onload="document.sform.submit()">
        <h3>] . $lang->txt("Please Wait - Processing") . qq[</h3>
        <p>] . $lang->txt("If you are not automatically redirected to the payment page within 30 seconds then you can click the Continue to Payment button below") . qq[</p>
        <form action = "$paymentURL" method = "POST" name = "sform" id = "sform">
            <input type = "hidden" name = "a" value = "P">
            <input type = "hidden" name = "ci" value = "$payRef">
            <input type = "hidden" name = "logID" value = "$logID">
            <input type = "hidden" name = "chkv" value = "$chkvalue">
            <input type = "hidden" name = "sessions" value = "$session">
    ];
#<a href = "$manualPaymentURL">proceed manually by pressing this link</a>.</p>
    if ($paymentSettings->{'gatewayCode'} eq 'NABExt1') {
        $proceed_body .= qq[ <input type = "hidden" name = "amount" value = "$amount"> ];
    }
	if (defined $gatewaySpecific && $gatewaySpecific)	{
    foreach my $k (keys %{$gatewaySpecific}) {
        $proceed_body .= qq[<input type="hidden" name="$k" value="$gatewaySpecific->{$k}">];
    } 
	}
    $proceed_body .= qq[
            <input type="SUBMIT" name="Submit" value="].$lang->txt("Continue to Payment") . qq[">
        </form>
    </body>
    </html>
    ];


    my $body = '';
if ($amount eq "0" or $amount eq "0.00" or ! $amount)   {
    print "Status: 302 Moved Temporarily\n";
    print "Location: $cancelURL\n\n";
}
else    {
    print qq[Content-type: text/html\n\n];
    print $proceed_body;
#print qq[Content-type: text/html\n\n];
#print "STOP";
}

}
exit;


;
