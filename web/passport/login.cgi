#!/usr/bin/perl -w

#
# $Header: svn://svn/SWM/trunk/web/passport/login.cgi 10129 2013-12-03 04:05:17Z tcourt $
#

use DBI;
use CGI qw(:cgi escape unescape);

use strict;

use lib ".","..","../..";

use Defs;
use Utils;
use Passport;

main();

sub	main	{

	my $url = param('url') || '';
	my $sessionkey = param('sk') || '';

	my $body='';
	my %Data=();
	my $db = connectDB();
	$Data{'db'}=$db;
  $Data{'cache'}=new MCache();

  my $passport = new Passport(
    db => $db,
    cache => $Data{'cache'},
  );
  $passport->loadSession($sessionkey);
  my $mID = $passport->id() || 0;
 
	my $authlist_url = "$Defs::base_url/authlist.cgi";
	my $header = '';

	my $output = new CGI;
	my $p3p=q[policyref="/w3c/p3p.xml", CP="ALL DSP COR CURa ADMa DEVa TAIi PSAa PSDa IVAi IVDi CONi OTPi OUR BUS IND PHY ONL UNI COM NAV DEM STA"];
	my $cookie_string = '';
	if($mID)	{
    $cookie_string = $output->cookie(
      -name => $Defs::COOKIE_PASSPORT,
      -value => $sessionkey,
      -domain => $Defs::cookie_domain,
      -secure => $Defs::DevelMode ? 0 : 1,
      -expires => '+90d',
      -httponly => 1,
      -path=>"/"
    );
	}
	else	{
		$cookie_string = $output->cookie(
			-name => 'pp_swm_failedlogin',
			-value => 1,
			-domain => $Defs::cookie_domain,
			-path=>"/"
		);
	}
	$header = $output->redirect (
		-uri => $url,
		-cookie=>[$cookie_string], 
		-P3P => $p3p
	);

  print $header;
}

