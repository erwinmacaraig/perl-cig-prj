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
use Documents;
use SystemConfig;
use Data::Dumper;
use WorkFlow;
use MCache;
use PersonObj;

main();

sub main	{


	my %Data = ();
	my $db = connectDB();
    my $personID= 10760182;
    my $regoID= 2579;
    my $documentID = 3707;
    $Data{'clientValues'}{'authLevel'}=100;
	$Data{'db'} = $db;
	$Data{'Realm'} = 1;
	$Data{'RealmSubType'} = 0;
    $Data{'SystemConfig'}=getSystemConfig(\%Data);
    $Data{'cache'}  = new MCache();
    
   pendingDocumentActions(\%Data, $personID, $regoID, $documentID);
}
