#!/usr/bin/perl

#
# $Header: svn://svn/SWM/trunk/misc/selectedplayers_off.pl 8250 2013-04-08 08:24:36Z rlee $
#

use strict;

use lib "..","../web","../web/comp";

use Defs;
use Utils;
use DBI;
use LWP::UserAgent;
use CGI qw(unescape);
use DeQuote;
use Getopt::Long;
use Seasons;
use AgeGroups;

main();

sub main	{

	my %Data = ();
	my $db = connectDB();
	$Data{'db'} = $db;

	my $st = qq[
		UPDATE
			tblAssocConfig
		SET 
			strValue=0
		WHERE
			strOption = 'SwitchOnSelectedPlayers'
	];
	$db->do($st);
}
1;
