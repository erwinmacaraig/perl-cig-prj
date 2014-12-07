#!/usr/bin/perl -w

use CGI qw(:cgi escape unescape);

use strict;

use lib ".", "..", "../..";

use Defs;
use Utils;
use MCache;

main();

#Receive logout instructions from passport

sub main {

    my $cgi = new CGI;

    my $sessionkey = $cgi->cookie($Defs::COOKIE_LOGIN) || '';
    if ( $sessionkey ) {
        my $cache = new MCache();
        $cache->delete( 'swm', "USESSION_$sessionkey" );
    }
    my $cookie_string = $cgi->cookie(
      -name     => $Defs::COOKIE_LOGIN,
      -value    => '',
      -domain   => $Defs::cookie_domain,
      -secure   => $Defs::DevelMode ? 0 : 1,
      -expires  => '-1d',
      -httponly => 1,
      -path     => "/"
    );

    my $cookie_lastlogin = $cgi->cookie(
      -name     => $Defs::COOKIE_LASTLOGIN_TIMESTAMP,
      -value    => '',
      -domain   => $Defs::cookie_domain,
      -secure   => $Defs::DevelMode ? 0 : 1,
      -expires  => '-1d',
      -httponly => 1,
      -path     => "/"
    );

    my $url = "$Defs::base_url/";
    my $p3p = q[policyref="/w3c/p3p.xml", CP="ALL DSP COR CURa ADMa DEVa TAIi PSAa PSDa IVAi IVDi CONi OTPi OUR BUS IND PHY ONL UNI COM NAV DEM STA"];
    my $header = $cgi->redirect(
     -uri    => $url,
     -cookie => [$cookie_string, $cookie_lastlogin],
     -P3P    => $p3p
    );
    print $header;
}

