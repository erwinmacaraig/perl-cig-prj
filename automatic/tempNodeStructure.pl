#!/usr/bin/perl -w

#
# $Header: svn://svn/SWM/trunk/automatic/tempNodeStructure.pl 8250 2013-04-08 08:24:36Z rlee $
#

use lib "../web","..";
use Defs;
use Utils;
use DBI;
use strict;

use Lang;
use SystemConfig;
use NodeStructure;



{
my $db=connectDB();

	
	my %Data=();
        my $lang= Lang->get_handle() || die "Can't get a language handle!";
        $Data{'lang'}=$lang;
        my $target='main.cgi';
        $Data{'target'}=$target;
	$Data{'db'}=$db;
        # AUTHENTICATE
        ($Data{'Realm'}, $Data{'RealmSubType'})= (2,0);
        $Data{'SystemConfig'}=getSystemConfig(\%Data);
	my $realmID= $ARGV[0] || 0;

	createTempNodeStructure(\%Data, $realmID);
}
1;

