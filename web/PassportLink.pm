#
# $Header: svn://svn/SWM/trunk/web/PassportLink.pm 11485 2014-05-06 01:43:10Z eobrien $
#

package PassportLink;
require Exporter;
@ISA    = qw(Exporter);
@EXPORT = qw(
  redirectPassportLogin
  passportURL
  passportParams
);
@EXPORT_OK = qw(
  redirectPassportLogin
  passportURL
  passportParams
);

use strict;

use lib "..";
use Defs;
use CGI qw(:cgi escape);

sub passportParams {
    my (
         $url,
         $returnurlParams,
         $extraURLParams,
    ) = @_;

    my $returnurl = $url;
    my $qs = '';
    for my $k ( keys %{$returnurlParams} ) {
        $qs .= ';' if ($qs);
        $qs .= "$k=" . escape( $returnurlParams->{$k} );
    }
    if ($qs) {
        $returnurl .= ( $returnurl =~ /\?/ ? ';' : '?' ) . $qs;
    }

    my %params = (
                   url => $returnurl,
                   apk => $Defs::PassportPublicKey,
    );
    if ($extraURLParams) {
        for my $k ( keys %{$extraURLParams} ) {
            $params{$k} = $extraURLParams->{$k};
        }
    }

    return \%params;
}

sub passportURL {
    my (
         $Data,
         $returnurlParams,
         $passportaction,
         $returnurl_other,
         $extraURLParams,
    ) = @_;

    $passportaction ||= 'login';
    my $cgi = new CGI;

    my $passportURL = $Data->{'PassportURL'}{$passportaction} || "$Defs::PassportURL/$passportaction/?";

    my $returnurl = $returnurl_other || $cgi->url( -full => 1, -query => 1 );

    my $params = passportParams( $returnurl, $returnurlParams, $extraURLParams );

    my $passportQS = '';
    for my $k ( keys %{$params} ) {
        $passportQS .= ';' if ($passportQS);
        $passportQS .= "$k=" . escape( $params->{$k} );
    }
    if ($passportQS) {
        $passportURL .= ( $passportURL =~ /\?/ ? ';' : '?' ) . $passportQS;
    }

    return $passportURL;
}

sub redirectPassportLogin {
    my (
         $Data,
         $returnurlParams,
         $extraURLParams,
    ) = @_;

    my $cgi = new CGI;
    my $passportURL = passportURL(
                                   $Data,
                                   $returnurlParams,
                                   'login',
                                   '',
                                   $extraURLParams,
    );

    my $header = $cgi->redirect($passportURL);
    print $header;
    exit;
}

1;
