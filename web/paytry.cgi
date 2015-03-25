#!/usr/bin/perl -w

#
# $Header: svn://svn/SWM/trunk/web/payments_process.cgi 8249 2013-04-08 08:14:07Z rlee $
#

use DBI;
use CGI qw(:cgi escape unescape);

use strict;

use lib "..",".",'PaymentSplit';
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

main();


sub main	{

	my $client = param('client') || 0;
    my $cgi = new CGI;
    my %params=$cgi->Vars();

    my $db=connectDB();
    my %Data=();
    $Data{'db'}=$db;
    my %clientValues = getClient($client);
    $Data{'clientValues'} = \%clientValues;
    ( $Data{'Realm'}, $Data{'RealmSubType'} ) = getRealm( \%Data );


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
            NOW()
        )
    ];
    my $qry= $db->prepare($st) or query_error($st);
	my $payRef = calcPayTryRef($Data{'SystemConfig'}{'paymentPrefix'},$logID);
    $qry->execute(
        $Data{'Realm'},
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
    my $cancelPayPalURL = $Defs::base_url . $paymentSettings->{'gatewayCancelURL'} . qq[&amp;ci=$payRef&client=$client]; ##$Defs::paypal_CANCEL_URL;

    ## In here I will build up URL per Gateway -- intPaymentConfigID or have a GATEWAYCODE ?
    ## Pass control to gateway
    my $paymentURL = '';
    my %gatewaySpecific = ();

    my $currentLang = $Data{'lang'}->generateLocale($Data{'SystemConfig'});

    if ($paymentSettings->{'gatewayCode'} eq 'NABExt1') {
        $paymentURL = $paymentSettings->{'gateway_url'} .qq[?nh=$Data{'noheader'}&amp;a=P&amp;client=$client&amp;ci=$payRef&amp;chkv=$chkvalue&amp;session=$session&amp;amount=$amount&amp;logID=$logID];
    }
    if ($paymentSettings->{'gatewayCode'} eq 'checkoutfi')  {
        $paymentURL = $paymentSettings->{'gateway_url'} .qq[?nh=$Data{'noheader'}&amp;a=P&amp;client=$client&amp;ci=$payRef&amp;chkv=$chkvalue&amp;session=$session];
        my $cents = $amount * 100;
        my ($Second, $Minute, $Hour, $Day, $Month, $Year, $WeekDay, $DayOfYear, $IsDST) = localtime(time);
        $Year+=1900;
        $Month++;    
        $Month = sprintf("%02s", $Month);
        $Day = sprintf("%02s", $Day);
        my $DeliveryDate = "$Year$Month$Day";

	my $pa = $paymentSettings->{'gatewayProcessPreGateway'} ==1 ? 0 : 1;
        my $delayedURL= $Defs::gatewayReturnDemo . qq[/gatewayprocess_cofi.cgi?sa=1&pa=$pa&ci=$payRef];
        my $cancelURL = $Defs::gatewayReturnDemo . qq[/gatewayprocess_cofi.cgi?sa=1&da=1&ci=$payRef];
        my $returnURL = $Defs::gatewayReturnDemo . qq[/gatewayprocess_cofi.cgi?sa=1&da=1&pa=$pa&ci=$payRef];
        my $rejectURL = $Defs::gatewayReturnDemo . qq[/gatewayprocess_cofi.cgi?sa=1&da=1&pa=$pa&ci=$payRef];

        $gatewaySpecific{'VERSION'} = "0001";
        $gatewaySpecific{'STAMP'} = $payRef;
        $gatewaySpecific{'AMOUNT'} = $cents;
        $gatewaySpecific{'REFERENCE'} = $logID;
        $gatewaySpecific{'MESSAGE'} = "";
        $gatewaySpecific{'LANGUAGE'} = "FI";
        $gatewaySpecific{'LANGUAGE'} = "EN" if ($currentLang =~ /^en_/);
        
        $gatewaySpecific{'MERCHANT'} = $paymentSettings->{'gatewayUsername'};
        $gatewaySpecific{'RETURN'} = $returnURL;
        $gatewaySpecific{'CANCEL'} = $cancelURL;
        $gatewaySpecific{'REJECT'} = $rejectURL;
        $gatewaySpecific{'DELAYED'} = $delayedURL;
        $gatewaySpecific{'COUNTRY'} = "FIN";
        $gatewaySpecific{'CURRENCY'} = $paymentSettings->{'currency'};
        $gatewaySpecific{'DEVICE'} = 1;
        $gatewaySpecific{'CONTENT'} = 1;
        $gatewaySpecific{'TYPE'} = 0;
        $gatewaySpecific{'ALGORITHM'} = 3;

        $gatewaySpecific{'DELIVERY_DATE'} = $DeliveryDate;
        $gatewaySpecific{'FIRSTNAME'} = "";
        $gatewaySpecific{'FAMILYNAME'} = "";
        $gatewaySpecific{'ADDRESS'} = "";
        $gatewaySpecific{'POSTCODE'} = "";
        $gatewaySpecific{'POSTOFFICE'} = "";

        my $m = new MD5;
        my $coKey = $gatewaySpecific{'VERSION'} ."+". $gatewaySpecific{'STAMP'} ."+". $gatewaySpecific{'AMOUNT'} ."+". $gatewaySpecific{'REFERENCE'} ."+". $gatewaySpecific{'MESSAGE'} ."+". $gatewaySpecific{'LANGUAGE'} ."+". $gatewaySpecific{'MERCHANT'} ."+". $gatewaySpecific{'RETURN'} ."+". $gatewaySpecific{'CANCEL'} ."+". $gatewaySpecific{'REJECT'} ."+". $gatewaySpecific{'DELAYED'} ."+". $gatewaySpecific{'COUNTRY'} ."+". $gatewaySpecific{'CURRENCY'} ."+". $gatewaySpecific{'DEVICE'} ."+". $gatewaySpecific{'CONTENT'} ."+". $gatewaySpecific{'TYPE'} ."+". $gatewaySpecific{'ALGORITHM'} ."+". $gatewaySpecific{'DELIVERY_DATE'} ."+". $gatewaySpecific{'FIRSTNAME'} ."+". $gatewaySpecific{'FAMILYNAME'} ."+". $gatewaySpecific{'ADDRESS'} ."+". $gatewaySpecific{'POSTCODE'} ."+". $gatewaySpecific{'POSTOFFICE'} ."+". $paymentSettings->{'gatewayPassword'};
    
        $m->reset();
        $m->add($coKey);
        my $authKey= uc($m->hexdigest());
        $gatewaySpecific{'MAC'} = $authKey;

        $gatewaySpecific{'EMAIL'} = "";
        $gatewaySpecific{'PHONE'} = "";

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

    my $proceed_body = qq[
    <html>
    <body onload="document.sform.submit()">
        <h3>Please Wait - Processing</h3>
        <p>If you are not automatically redirected to the payment page within 30 seconds then you can <a href = "$paymentURL">proceed manually by pressing this link</a>.</p>
        <form action = "$paymentURL" method = "POST" name = "sform" id = "sform">
            <input type = "hidden" name = "a" value = "P">
            <input type = "hidden" name = "ci" value = "$payRef">
            <input type = "hidden" name = "logID" value = "$logID">
            <input type = "hidden" name = "chkv" value = "$chkvalue">
            <input type = "hidden" name = "sessions" value = "$session">
    ];
    if ($paymentSettings->{'gatewayCode'} eq 'NABExt1') {
        $proceed_body .= qq[ <input type = "hidden" name = "amount" value = "$amount"> ];
    }
    foreach my $k (keys %gatewaySpecific) {
        $proceed_body .= qq[<input type="hidden" name="$k" value="$gatewaySpecific{$k}">];
    } 
    $proceed_body .= qq[
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
    #print qq[$cancel_body<br>];
    #print qq[$gateway_body];
    #print qq[<br>$cancelPayPalURL];
}

}
exit;


;
