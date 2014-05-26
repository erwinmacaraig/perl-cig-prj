#!/usr/bin/perl -w

#
# $Header: svn://svn/SWM/trunk/web/passport/logout.cgi 11480 2014-05-05 05:31:38Z eobrien $
#

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

    my $sessionkey = param('sk') || '';

    if ( !$sessionkey ) {    #delete the local passport cookie, before redirecting
        my $cookie_string = $cgi->cookie(
                                          -name     => $Defs::COOKIE_PASSPORT,
                                          -value    => '',
                                          -domain   => $Defs::cookie_domain,
                                          -secure   => $Defs::DevelMode ? 0 : 1,
                                          -expires  => '-1d',
                                          -httponly => 1,
                                          -path     => "/"
        );
        my $url = "$Defs::PassportURL/logout/?";
        my $p3p = q[policyref="/w3c/p3p.xml", CP="ALL DSP COR CURa ADMa DEVa TAIi PSAa PSDa IVAi IVDi CONi OTPi OUR BUS IND PHY ONL UNI COM NAV DEM STA"];
        my $header = $cgi->redirect(
                                     -uri    => $url,
                                     -cookie => [$cookie_string],
                                     -P3P    => $p3p
        );
        print $header;
    }
    else {
        my $body  = '';
        my %Data  = ();
        my $cache = new MCache();

        $cache->delete( 'swm', "PSKEY_$sessionkey" );

        print $cgi->header();
    }

}

