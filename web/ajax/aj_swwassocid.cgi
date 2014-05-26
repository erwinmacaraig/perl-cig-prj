#!/usr/bin/perl 

use strict;
use warnings;
use lib '..','../..';
use CGI qw(param);
use Utils;
use JSON;

main(); 

sub main {
    my $assocID = param('assocID') || 0;

    if (!$assocID) {
        process_error('An assoc param must be provided.');
        return;
    }

    my %Data = ();

    $Data{'db'} = connectDB();

    my $dbh = $Data{'db'};

    my $sql = qq[SELECT intSWWAssocID FROM tblAssoc WHERE intAssocID=?];

    my $query = $dbh->prepare($sql);

    $query->execute($assocID);

    my ($swwAssocID) = $query->fetchrow_array() || 0;

    disconnectDB($dbh);

    my $json = to_json({
        result     => 'Success', 
        swwAssocID => $swwAssocID,
    });


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
