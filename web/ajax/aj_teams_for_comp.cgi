#!/usr/bin/perl 

use strict;
use warnings;
use lib '..','../..','../gendropdown';
use CGI qw(param);
use Utils;
use JSON;
use GenDropDown;

main(); 

sub main {
    my $compID = param('compID') || 0;

    if (!$compID) {
        process_error('A comp param must be provided.');
        return;
    }

    my %Data = ();

    $Data{'db'} = connectDB();

    my $dbh = $Data{'db'};

    my $json = genDropdownOptions(\%Data, {optType=>6, compID=>$compID, format=>'json'});

    disconnectDB($dbh);

    print "Content-type: text/html\n\n";
    print $json;
}

sub process_error {
    my ($message) = @_;

    my $json = to_json({Error=>$message});

    print "Content-type: text/html\n\n";
    print $json;
    return;
}
