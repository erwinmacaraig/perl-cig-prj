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
    disconnectDB($db);

    ## Pass control to gateway
    my $paymentURL = $paymentSettings->{'gateway_url'} .qq[?nh=$Data{'noheader'}&amp;a=P&amp;client=$client&amp;ci=$logID&amp;chkv=$chkvalue&amp;session=$session&amp;amount=$amount];
    if ($paymentSettings->{'paymentType'} == $Defs::PAYMENT_ONLINEPAYPAL) {
        $paymentURL = qq[$Defs::base_url/paypal.cgi?nh=$Data{'noheader'}&amp;a=P&amp;client=$client&amp;ci=$logID&amp;session=$session];
    }
    my $gateway_body= qq[<a href="$paymentURL">Proceed to Payment</a>];
	
    my $body = '';
print qq[Content-type: text/html\n\n] if ! $body;
print qq[$gateway_body];

}
exit;

