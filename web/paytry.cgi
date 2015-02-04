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
            $params{'a'} = "P_TXNLog_list";
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
            dtTry
        )
        VALUES (
            ?,
            ?,
            ?,
            ?,
            NOW()
        )
    ];
    my $qry= $db->prepare($st) or query_error($st);
    $qry->execute(
        $Data{'Realm'},
        '',
        $logID,
        $datalog,
        ) or query_error($st);
    my $tryID= $qry->{mysql_insertid};
    disconnectDB($db);

    ## In here I will build up URL per Gateway -- intPaymentConfigID or have a GATEWAYCODE ?
    ## Pass control to gateway
    my $paymentURL = '';
    if ($paymentSettings->{'gatewayCode'} eq 'NABExt1') {
        print STDERR "YEP";
    }
    $paymentURL = $paymentSettings->{'gateway_url'} .qq[?nh=$Data{'noheader'}&amp;a=P&amp;client=$client&amp;ci=$logID&amp;chkv=$chkvalue&amp;session=$session&amp;amount=$amount];

    my $payTry = payTryRead(\%Data, $logID, $tryID);
    my $cancelURL = payTryRedirectBack(\%Data, $payTry, $client, $logID, 0);

    if ($paymentSettings->{'paymentType'} == $Defs::PAYMENT_ONLINEPAYPAL) {
        $paymentURL = qq[$Defs::base_url/paypal.cgi?nh=$Data{'noheader'}&amp;a=P&amp;client=$client&amp;ci=$logID&amp;session=$session];
    }
    my $gateway_body= qq[<a href="$paymentURL">Proceed to Payment</a>];
    my $cancel_body= qq[<a href="$cancelURL">Cancel Payment</a>];
    my $cancelPayPalURL = $Defs::base_url . $paymentSettings->{'gatewayCancelURL'} . qq[&amp;ci=$logID&client=$client]; ##$Defs::paypal_CANCEL_URL;

    my $proceed_body = qq[
    <html>
    <body onload="document.sform.submit()">
        <h3>Please Wait - Processing</h3>
        <p>If you are not automatically redirected to the payment page within 30 seconds then you can <a href = "$paymentURL">proceed manually by pressing this link</a>.</p>
        <form action = "$paymentURL" method = "POST" name = "sform" id = "sform">
            <input type = "hidden" name = "a" value = "P">
            <input type = "hidden" name = "ci" value = "$logID">
            <input type = "hidden" name = "chkv" value = "$chkvalue">
            <input type = "hidden" name = "sessions" value = "$session">
            <input type = "hidden" name = "amount" value = "$amount">
        </form>
    </body>
    </html>
    ];
            #<input type = "hidden" name = "client" value = "].unescape($client).qq[">
            #<input type = "hidden" name = "nh" value = "$Data{'noheader'}"
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
