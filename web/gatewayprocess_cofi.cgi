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

#use Crypt::CBC;

main();

sub main	{

    ## Need one of these PER gateway

	my $logID= param('ci') || 0;
	my $submit_action= param('sa') || '';
	my $display_action= param('da') || '';
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
    $Data{'sessionKey'} = $payTry->{'session'};
    getDBConfig(\%Data);
    $Data{'SystemConfig'}=getSystemConfig(\%Data);

    # Do they update
    if ($submit_action eq '1') {
        my %returnVals = ();
        $returnVals{'action'} = param('sa') || 0;
        $returnVals{'ext'} = param('ext') || 0;
        #$returnVals{'ei'} = param('ei') || 0;
        $returnVals{'chkv'} = param('chkv') || 0;

        $returnVals{'GATEWAY_TXN_ID'}= param('PAYMENT') || '';
        $returnVals{'GATEWAY_AUTH_ID'}= param('REFERENCE') || '';
        #$returnVals{'GATEWAY_SETTLEMENT_DATE'}= param('settdate') || '';
        my $co_status = param('STATUS') || '';
        $returnVals{'GATEWAY_RESPONSE_CODE'}= "99";
        $returnVals{'GATEWAY_RESPONSE_CODE'}= "OK" if ($co_status eq "2");
        $returnVals{'GATEWAY_RESPONSE_TEXT'}= param('REFERENCE') || '';
        $returnVals{'Other1'} = $co_status || '';
        $returnVals{'Other2'} = param('MAC') || '';
        gatewayProcess(\%Data, $logID, $client, \%returnVals, 'skip');
    }

	disconnectDB($db);

    if ($display_action eq '1')    {
        payTryRedirectBack(\%Data, $payTry, $client, $logID, 1);
    }
}

1;
