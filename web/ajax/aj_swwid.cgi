#!/usr/bin/perl  -w 

use strict;

use lib '..','../..';

use CGI qw(param);
use Defs;
use Utils;
use LWP::Simple;

main();

sub main {
    my $clubID      = safe_param('clubID', 'number') || 0;
    my $compID      = safe_param('compID', 'number') || 0;
    my $teamID      = safe_param('teamID', 'number') || 0;
    my $contentType = safe_param('contentType', 'word') || 'application/json';

    die "No valid parameters have been passed in!" if !$clubID and !$compID and !$teamID;

    my $url = $Defs::sww_base_url;

    $url .= "/aj_swwid.cgi";
    $url .= "?compID=$compID&amp;teamID=$teamID";

    my $uri = URI->new($url);

    my $content = get $uri;

    my $output = "Content-Type: $contentType\n\n";

    $output .= $content;

    print $output;
}
