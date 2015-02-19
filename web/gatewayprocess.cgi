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

#use Crypt::CBC;

main();

sub main	{

    ## Need one of these PER gateway

	my $logID= param('ci') || 0;
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
    #my %clientValues = getClient($payTry->{'client'});
    #my $client= setClient(\%clientValues);
    #$Data{'client'}=$client;
    #$Data{'clientValues'} = \%clientValues;

     $Data{'clientValues'} = $payTry;
    my $client= setClient(\%{$payTry});
    $Data{'client'}=$client;

    $Data{'sessionKey'} = $payTry->{'session'};
    getDBConfig(\%Data);
    $Data{'SystemConfig'}=getSystemConfig(\%Data);
    initLocalisation(\%Data);

    # Do they update
    if ($submit_action eq '1') {
        my %returnVals = ();
        $returnVals{'action'} = param('sa') || 0;
        $returnVals{'ext'} = param('ext') || 0;
        #$returnVals{'ei'} = param('ei') || 0;
        $returnVals{'chkv'} = param('chkv') || 0;

        $returnVals{'GATEWAY_TXN_ID'}= param('txnid') || '';
        $returnVals{'GATEWAY_AUTH_ID'}= param('authid') || '';
        $returnVals{'GATEWAY_SIG'}= param('sig') || '';
        $returnVals{'GATEWAY_SETTLEMENT_DATE'}= param('settdate') || '';
        $returnVals{'GATEWAY_RESPONSE_CODE'}= param('rescode') || '';
        $returnVals{'ResponseCode'}= "OK" if (param('rescode') =~ /08|00/);
        $returnVals{'GatewayResponseCode'}= param('rescode') || '';

        $returnVals{'GATEWAY_RESPONSE_TEXT'}= param('restext') || '';
        $returnVals{'ResponseText'}= param('restext') || '';
        $returnVals{'Other1'} = param('restext') || '';
        $returnVals{'Other2'} = param('authid') || '';
        gatewayProcess(\%Data, $logID, $client, \%returnVals, '');
    }

	disconnectDB($db);
    if ($process_action eq '1')    {
        payTryContinueProcess(\%Data, $payTry, $client, $logID, 1);
    }

    if ($display_action eq '1')    {
        payTryRedirectBack(\%Data, $payTry, $client, $logID, 1);
    }

}

1;
