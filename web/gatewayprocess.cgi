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
        ## REDIRECTo    
        #my $a = 'PF_';
        #$a = 'PREGFB_';#'PF_';
        my $a = $payTry->{'nextPayAction'} || $payTry->{'a'};
        my $redirect_link = "main.cgi?client=$client&amp;a=$a";
        foreach my $k (keys %{$payTry}) {
            next if $k eq 'client'; 
            next if $k eq 'a';
            next if $k =~/clubID|teamID|userID|stateID|assocID|intzonID|regionID|zoneID|intregID|authLevel|natID|venueID|authLevel|currentLevel|interID/;
            next if $k =~/dtype/;
            next if $k =~/^ss$/;
            next if $k =~/^cc_submit/;
            next if $k =~/^pt_submit/;
            $redirect_link .= "&amp;$k=".$payTry->{$k};
        } 
        my $body = "HELLO";
 	    print "Content-type: text/html\n\n";
  	    print $body;
        print qq[<a href="$redirect_link">LINK</a><br>$redirect_link];
    }
}

1;
