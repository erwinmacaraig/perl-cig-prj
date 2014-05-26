#!/usr/bin/perl 

#
# $Header: svn://svn/SWM/trunk/web/nagscreen.cgi 10130 2013-12-03 04:05:46Z tcourt $
#

use strict;
use warnings;
use CGI qw(param);
use lib "..",".";
use Defs;
use Reg_common;
use Utils;
use Lang;
use SystemConfig;
use TTTemplate;

main();	

sub main	{
	# GET INFO FROM URL
  my $client = param('client') || '';
                                                                                                        
  my %Data=();
  my $lang= Lang->get_handle() || die "Can't get a language handle!";
  $Data{'lang'}=$lang;
  my $target='main.cgi';
  $Data{'target'}=$target;
  my %clientValues = getClient($client);
  $Data{'clientValues'} = \%clientValues;
	
  # AUTHENTICATE
  my $db=allowedTo(\%Data);
  ($Data{'Realm'}, $Data{'RealmSubType'})=getRealm(\%Data);
	getDBConfig(\%Data);
	$Data{'SystemConfig'}=getSystemConfig(\%Data);

	print "Content-type: text/html\n\n";
	if($db)	{
		if($Data{'SystemConfig'}{'NagScreen'} 
				and $Data{'SystemConfig'}{'NagScreen'}=~/\.templ/)	{

			my $filename = "nagscreen/$Data{'SystemConfig'}{'NagScreen'}";
			my $output = runTemplate(\%Data, undef, $filename);
			print $output;
		}
	}
}
