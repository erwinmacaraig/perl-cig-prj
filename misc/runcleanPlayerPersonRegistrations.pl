#!/usr/bin/perl

#
# $Header: svn://svn/SWM/trunk/misc/moneylogInsert.pl 8250 2013-04-08 08:24:36Z rlee $
#

use strict;

use lib "..","../web","../web/comp", "../web/user", '../web/RegoForm', "../web/dashboard", "../web/RegoFormBuilder",'../web/PaymentSplit', "../web/Clearances";

use Defs;
use Utils;
use DBI;
use WorkFlow;
use UserObj;
use CGI qw(unescape);
use PlayerPassport;
use SystemConfig;
use Data::Dumper;
use PersonRegistration;

main();

sub main	{


	my %Data = ();
	my $db = connectDB();
    my $lang     = Lang->get_handle() || die "Can't get a language handle!";
	$Data{'db'} = $db;
	$Data{'Realm'} = 1;
    $Data{'lang'} = $lang;
	$Data{'RealmSubType'} = 0;
    $Data{'SystemConfig'}=getSystemConfig(\%Data);

    cleanPlayerPersonRegistrations(\%Data, 10759654, 1934);
}
