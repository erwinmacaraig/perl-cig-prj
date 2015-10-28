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


use Digest::SHA  qw(sha512_hex);
#use Crypt::CBC;

main();

sub main	{

print STDERR "IN GATEWAYPROCESS_sgEP\n";

    my $db=connectDB();
	my %Data=();
	$Data{'db'}=$db;
	$Data{'Realm'}=1;
    getDBConfig(\%Data);
    $Data{'SystemConfig'}=getSystemConfig(\%Data);
    $Data{'cache'}  = new MCache();

	my $payRef= param('TM_UserField1') || param('ci') || '';
	my $submit_action= param('sa') || '';
    print STDERR "SA IS $submit_action\n";
	$submit_action  =1;
	my $display_action= param('da') || '';
	$submit_action  =0 if ($display_action eq '1');
    my $process_action= param('pa') || '';

print STDERR "EASYPAY SUBMITTING =1\n" if ($submit_action);
print STDERR "EASYPAY DISPLAYING=1\n" if ($display_action);
print STDERR "###############IF TM_DebitAmt IS DIFFERENT DO A RESERVAL !!!!!\n";

    my $payTry = payTryRead(\%Data, $payRef, 1);
	my $logID = $payTry->{'intTransLogID'};

print STDERR "LOG IS $logID | $payRef\n";
    my $cgi=new CGI;
    my %params=$cgi->Vars();
    my $lang   = Lang->get_handle('', $Data{'SystemConfig'}) || die "Can't get a language handle!";
    $Data{'lang'}=$lang;
    $Data{'clientValues'} = $payTry;
    my $client= setClient(\%{$payTry});
    $Data{'client'}=$client;
    $Data{'sessionKey'} = $payTry->{'session'};
    initLocalisation(\%Data);

    return if (! $logID);
print STDERR "STILL AROUND IN GATEWAY - $submit_action\n";

########
my ($Order, $Transactions) = gatewayTransactions(\%Data, $logID);
my ($paymentSettings, undef) = getPaymentSettings(\%Data,$Order->{'PaymentType'}, $Order->{'PaymentConfigID'}, 1);
########
    # Do they update
    if ($submit_action eq '1') {
        my %returnVals = ();
        $returnVals{'action'} = $submit_action;
        $returnVals{'ext'} = param('ext') || 0;
        $returnVals{'chkv'} = param('chkv') || 0;

        my %Vals = ();
        $Vals{'Ref'}= $payRef; 
        $Vals{'TM_MCode'}= param('TM_MCode');
        $Vals{'TM_RefNo'}= param('TM_RefNo');
        $Vals{'TM_Currency'}= param('TM_Currency');
        $Vals{'TM_DebitAmt'}= param('TM_DebitAmt');
        $Vals{'TM_PaymentType'}= param('TM_PaymentType');
        $Vals{'TM_Status'}= param('TM_Status');
        $Vals{'TM_Error'}= param('TM_Error');
        $Vals{'TM_ErrorMsg'}= param('TM_ErrorMsg');
        $Vals{'TM_ApprovalCode'}= param('TM_ApprovalCode');
        $Vals{'TM_BankRespCode'}= param('TM_BankRespCode');
        $Vals{'TM_TrnType'}= param('TM_TrnType');
        $Vals{'TM_Version'}= param('TM_Version');
        $Vals{'TM_Signature'}= param('TM_Signature');
        $Vals{'TM_Original_RefNo'}= $payRef; #param('TM_Original_RefNo');
        $Vals{'TM_OriginalPayType'}= param('TM_OriginalPayType');

        my $coKeyReceive = "$Vals{'TM_DebitAmt'}$Vals{'TM_Original_RefNo'}$Vals{'TM_Currency'}$Vals{'TM_MCode'}$Vals{'TM_TrnType'}$Vals{'TM_Status'}$Vals{'TM_Error'}";
        my $secureHashReceive = uc(sha512_hex($coKeyReceive, $paymentSettings->{'gatewayPassword'}));

        my $ack="YES";
        my $st = qq[
            SELECT intAmount
            FROM tblTransLog
            WHERE intLogID = ?
        ];
        my $query = $Data{'db'}->prepare($st);
        $query->execute($logID);
        my $originalAmount = $query->fetchrow_array() || 0;
        if ($originalAmount != $Vals{'TM_DebitAmt'})    {
            $ack='NO';
            $Vals{'TM_Status'} = 'NO';
            $Vals{'TM_ErrorMsg'} = 'Error: Amount has changed';
        }
        
        {
            my %RetValues=();
            $RetValues{'mid'} = $Vals{'TM_MCode'};
            $RetValues{'ref'} = $payRef;
            $RetValues{'ack'} = $ack; #"YES";
print "Content-type: text/html\n\n";
print "mid=$RetValues{'mid'}&ref=$RetValues{'ref'}&ack=$ack";
        }


        my $chkAction = 'FAILURE';
print STDERR "TM_SIG $Vals{'TM_Signature'} calcd is $secureHashReceive\n";
	    if (($Vals{'TM_Signature'}  && $Vals{'TM_Signature'} eq $secureHashReceive))	{
            $chkAction = 'SUCCESS';
	    }

        #$returnVals{'GATEWAY_TXN_ID'}= param('PAYMENT') || '';
        $returnVals{'GATEWAY_TXN_ID'}=  param('TM_ApprovalCode') || '';
        $returnVals{'GATEWAY_AUTH_ID'}= param('TM_ApprovalCode') || '';
        my $co_status = $Vals{'TM_Status'}; #param('TM_Status');
        $returnVals{'GATEWAY_RESPONSE_CODE'}= "99";
        $returnVals{'GATEWAY_RESPONSE_CODE'}= "OK" if (uc($co_status) eq "YES");
        #$returnVals{'GATEWAY_RESPONSE_CODE'}= "HOLD" if (
        #    $co_status eq "3"  ## Delayed Payment
        #    or $co_status eq "6" 
        #    or $co_status eq "7" 
        #);
         $returnVals{'GATEWAY_RESPONSE_TEXT'}= $Vals{'TM_ErrorMsg'} || '';
        $returnVals{'GatewayResponseCode'}= param('TM_BankRespCode');
        $returnVals{'ResponseCode'}= $returnVals{'GATEWAY_RESPONSE_CODE'};

        my %_coResponseText = (
            "NO" => "PAYMENT_UNSUCCESSFUL",
            "YES"=>"PAYMENT_SUCCESSFUL",
        );
        my $respTextCode = $_coResponseText{$co_status} || $_coResponseText{'NO'} || '';
        $returnVals{'ResponseText'}= $respTextCode; 
        #$returnVals{'ResponseText'}= $Vals{'TM_Error'} if ($Vals{'TM_Error'});
        $returnVals{'Other1'} = $co_status || '';
        gatewayProcess(\%Data, $logID, $client, \%returnVals, $chkAction);
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
