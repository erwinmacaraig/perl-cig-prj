#!/usr/bin/perl

#
# $Header: svn://svn/SWM/trunk/misc/moneylogInsert.pl 8250 2013-04-08 08:24:36Z rlee $
#

use strict;

use lib "..","../web","../web/comp", "../web/user";

use Defs;
use Utils;
use DBI;
use WorkFlow;
use UserObj;
use CGI qw(unescape);

main();

sub main	{


	my %Data = ();
	my $db = connectDB();
	$Data{'db'} = $db;
	$Data{'Realm'} = 1;
#    addTasks(\%Data, 0,0,1);
    addTasks(\%Data, 749,0,0);
}
