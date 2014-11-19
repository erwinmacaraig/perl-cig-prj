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

use NABGateway;
use Gateway_Common;
use TTTemplate;
use Data::Dumper;
use GatewayProcess;

#use Crypt::CBC;

main();

sub main	{

	my $logID= param('ci') || 0;
	my $submit_action= param('sa') || '';
	my $display_action= param('da') || '';
    my $db=connectDB();
	my %Data=();
	$Data{'db'}=$db;
    ## LOOK UP tblPayTry
    my $payTry = payTryRead(\%Data, $logID);

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
        gatewayProcess(\%Data, $logID);
    }

	disconnectDB($db);

    if ($display_action eq '1')    {
        payTryRedirectBack($payTry, $client, $logID);
    }
}

1;
