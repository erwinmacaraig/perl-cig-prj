#!/usr/bin/perl -w

#
# $Header: svn://svn/SWM/trunk/web/nabprocess.cgi 8249 2013-04-08 08:14:07Z rlee $
#

use lib '.', '..', "comp", 'RegoForm', "dashboard", "RegoFormBuilder",'PaymentSplit', "user";
use DBI;
use CGI qw(:cgi escape unescape);

use strict;

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
use GatewayProcess;
use PayTry;
use Localisation;
use MCache;

use Digest::SHA qw(hmac_sha256_hex);
#

#use Crypt::CBC;

main();

sub main	{

    ## Need one of these PER gateway
print STDERR "IN GATEWAYPROCESS_hkpay\n";

    my $db=connectDB();
	my %Data=();
	$Data{'db'}=$db;
	$Data{'Realm'}=1;
    getDBConfig(\%Data);
    $Data{'SystemConfig'}=getSystemConfig(\%Data);
    $Data{'cache'}  = new MCache();

	my $payRef= param('Ref') || param('ci') || '';
	my $submit_action= param('sa') || '';
	$submit_action  =1;
	my $display_action= param('da') || '';
	$submit_action  =0 if ($display_action eq '1');
    my $process_action= param('pa') || '';

    ## LOOK UP tblPayTry
    my $payTry = payTryRead(\%Data, $payRef, 1);
#use Data::Dumper;
#print STDERR Dumper($payTry);
	my $logID = $payTry->{'intTransLogID'};

print STDERR "LOG IS $logID\n";

my $cgi=new CGI;
    my %params=$cgi->Vars();
print STDERR Dumper(\%params);
print STDERR "~~~~~~~~~~~~~~~~~END~~~~~~~~~~~~~~~~~\n";
    my $lang   = Lang->get_handle('', $Data{'SystemConfig'}) || die "Can't get a language handle!";
    $Data{'lang'}=$lang;
    $Data{'clientValues'} = $payTry;
    my $client= setClient(\%{$payTry});
    $Data{'client'}=$client;
    #my %clientValues = getClient($payTry->{'client'});
    #my $client= setClient(\%clientValues);
    #$Data{'client'}=$client;
    #$Data{'clientValues'} = \%clientValues;

    $Data{'sessionKey'} = $payTry->{'session'};
    initLocalisation(\%Data);

	if ($submit_action)	{
    print "Content-type: text/html\n\n";
	print "OK";
	}
    return if (! $logID);
print STDERR "STILL AROUND IN G\n";

########
my ($Order, $Transactions) = gatewayTransactions(\%Data, $logID);
my ($paymentSettings, undef) = getPaymentSettings(\%Data,$Order->{'PaymentType'}, $Order->{'PaymentConfigID'}, 1);
########
    # Do they update
    if ($submit_action eq '1') {
print STDERR "IN SUBMIT ACTION";
        my %returnVals = ();
        $returnVals{'action'} = $submit_action;
        $returnVals{'ext'} = param('ext') || 0;
        $returnVals{'chkv'} = param('chkv') || 0;

        my %Vals = ();
        $Vals{'src'}= param('src') || '';
        $Vals{'prc'}= param('prc') || '';
        $Vals{'Ord'}= param('Ord') || '';
        $Vals{'Holder'}= param('Holder') || '';
        $Vals{'successcode'}= param('successcode') || '';
        $Vals{'Ref'}= $payRef; #param('STAMP') || '';
        $Vals{'PayRef'}= param('PayRef') || ''; ## Gateways ref number
        $Vals{'Amt'}= param('Amt') || '';
        $Vals{'Cur'}= param('Cur') || '';
        $Vals{'remark'}= param('remark') || '';
        $Vals{'secureHash'}= param('secureHash') || '';
        $Vals{'payType'}= param('payType') || 'N';
        $Vals{'merchantId'}= param('merchantId') || ''; ## is this same as gatewayUsername
	print "Content-type: text/html\n\nOK";
        

	my $coKey = $paymentSettings->{'gatewayUsername'} ."|". $Vals{'Ref'} ."|". $Vals{'Cur'} ."|". $Vals{'Amt'} ."|". $Vals{'payType'} ."|". $paymentSettings->{'gatewayPassword'};

       my $secureHash = 1;#sha1($coKey);

        my $chkAction = 'FAILURE';
print STDERR "$Vals{'secureHash'} | " . $secureHash;
	if ($Vals{'secureHash'}  && $Vals{'secureHash'} eq $secureHash)	{
            $chkAction = 'SUCCESS';
	}
            $chkAction = 'SUCCESS';
print STDERR "MAC ACTION IS $chkAction\n";

        $returnVals{'GATEWAY_TXN_ID'}= param('PAYMENT') || '';
        $returnVals{'GATEWAY_AUTH_ID'}= param('AuthId') || '';
        my $co_status = param('successcode');
        $returnVals{'GATEWAY_RESPONSE_CODE'}= "99";
        $returnVals{'GATEWAY_RESPONSE_CODE'}= "OK" if (
            $co_status eq "0" 
        );
        #$returnVals{'GATEWAY_RESPONSE_CODE'}= "HOLD" if (
        #    $co_status eq "3"  ## Delayed Payment
        #    or $co_status eq "6" 
        #    or $co_status eq "7" 
        #);
         $returnVals{'GATEWAY_RESPONSE_TEXT'}= param('REFERENCE') || '';
        $returnVals{'GatewayResponseCode'}= $co_status;
        $returnVals{'ResponseCode'}= $returnVals{'GATEWAY_RESPONSE_CODE'};

        my %_coResponseText = (
            -1 => "PAYMENT_UNSUCCESSFUL",
            0=>"PAYMENT_SUCCESSFUL",
        );
        my $respTextCode = $_coResponseText{$co_status} || '';
        $returnVals{'ResponseText'}= $respTextCode; #$Defs::paymentResponseText{$respTextCode} || '';
        $returnVals{'Other1'} = $co_status || '';
        $returnVals{'Other2'} = param('MAC') || '';
        gatewayProcess(\%Data, $logID, $client, \%returnVals, $chkAction);
        #print "Content-type: text/html\n\n" if (! $display_action);
    }

	disconnectDB($db);
    if (! $paymentSettings->{'gatewayProcessPreGateway'} and $process_action eq '1')    {
        payTryContinueProcess(\%Data, $payTry, $client, $logID);
        $payTry->{'run'} = 1;
    }
    
    if ($display_action eq '1')    {
        payTryRedirectBack(\%Data, $payTry, $client, $logID, 1);
    }

}

1;
