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
use Localisation;

use Digest::SHA qw(hmac_sha256_hex);

#use Crypt::CBC;

main();

sub main	{

    ## Need one of these PER gateway
print STDERR "IN GATEWAYPROCESS_cofi\n";

	my $logID= param('STAMP') || param('ci') || 0;
	my $submit_action= param('sa') || '';
	my $display_action= param('da') || '';
    my $process_action= param('pa') || '';

    my $db=connectDB();
	my %Data=();
	$Data{'db'}=$db;
    ## LOOK UP tblPayTry
    my $payTry = payTryRead(\%Data, $logID, 0);

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
    getDBConfig(\%Data);
    $Data{'SystemConfig'}=getSystemConfig(\%Data);
    initLocalisation(\%Data);

    # Do they update
    if ($submit_action eq '1') {
        my %returnVals = ();
        $returnVals{'action'} = param('sa') || 0;
        $returnVals{'ext'} = param('ext') || 0;
        $returnVals{'chkv'} = param('chkv') || 0;

        my %Vals = ();
        $Vals{'VERSION'}= param('VERSION') || '';
        $Vals{'STAMP'}= param('STAMP') || '';
        $Vals{'REFERENCE'}= param('REFERENCE') || '';
        $Vals{'PAYMENT'}= param('PAYMENT') || '';
        $Vals{'STATUS'}= param('STATUS') || '';
        $Vals{'ALGORITHM'}= param('ALGORITHM') || '';
        $Vals{'MAC'}= param('MAC') || '';
        
########
my ($Order, $Transactions) = gatewayTransactions(\%Data, $logID);
my ($paymentSettings, undef) = getPaymentSettings(\%Data,$Order->{'PaymentType'}, $Order->{'PaymentConfigID'}, 1);
########

        my $str = "$Vals{'VERSION'}&$Vals{'STAMP'}&$Vals{'REFERENCE'}&$Vals{'PAYMENT'}&$Vals{'STATUS'}&$Vals{'ALGORITHM'}";
        my $digest=uc(hmac_sha256_hex($str, $paymentSettings->{'gatewayPassword'}));
        my $chkAction = 'FAILURE';
print STDERR "$Vals{'MAC'} $str $digest |  $paymentSettings->{'gatewayPassword'}\n";
        if ($Vals{'MAC'} eq $digest)    {
            $chkAction = 'SUCCESS';
        }
print STDERR "MAC ACTION IS $chkAction\n";

        $returnVals{'GATEWAY_TXN_ID'}= param('PAYMENT') || '';
        $returnVals{'GATEWAY_AUTH_ID'}= param('REFERENCE') || '';
        my $co_status = param('STATUS') || '';
        $returnVals{'GATEWAY_RESPONSE_CODE'}= "99";
        $returnVals{'GATEWAY_RESPONSE_CODE'}= "OK" if (
            $co_status eq "2" 
            or $co_status eq "5" 
            or $co_status eq "6"
            or $co_status eq "7"
            or $co_status eq "8"
            or $co_status eq "9"
            or $co_status eq "10"
        );
        $returnVals{'GATEWAY_RESPONSE_TEXT'}= param('REFERENCE') || '';
        $returnVals{'GatewayResponseCode'}= $co_status;
        $returnVals{'ResponseCode'}= $returnVals{'GATEWAY_RESPONSE_CODE'};
        $returnVals{'ResponseText'}= $Defs::FIN_coResponseText{$co_status} || '';
        $returnVals{'Other1'} = $co_status || '';
        $returnVals{'Other2'} = param('MAC') || '';
        gatewayProcess(\%Data, $logID, $client, \%returnVals, $chkAction);
        #print "Content-type: text/html\n\n" if (! $display_action);
    }

	disconnectDB($db);
    if ($process_action eq '1')    {
        payTryContinueProcess(\%Data, $payTry, $client, $logID);
        print "Content-type: text/html\n\n" if (! $display_action);
    }

    if ($display_action eq '1')    {
        payTryRedirectBack(\%Data, $payTry, $client, $logID, 1);
    }

}

1;
