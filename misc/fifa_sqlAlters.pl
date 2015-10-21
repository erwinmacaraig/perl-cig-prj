#!/usr/bin/perl

#
# $Header: 
#

use strict;
use lib '.', '..','../web';
use Defs;
use Utils;
use File::Slurp;

main();

sub main    {
    my $db = connectDB();

    my $runAlters = getRunAlters($db);

    my $dirname = '../db_setup/sqlalters/';
    opendir (DIR, $dirname) or die ;
    my @files = grep {/.*?\.sql/}  readdir DIR;
    @files = sort {$a cmp $b} @files;

    close DIR;
    foreach my $file (@files) {
        next if exists ($runAlters->{$file});
        my $content = read_file( $dirname.$file) ;
        my $error = '';
        my $status = -1;
        my $qry= $db->prepare($content);
        $qry->execute() or $error = $qry->errstr;
        $status = 1 if (! $error);
        logAlterSQL($db, $file, $error, $status);
    }

}

sub getRunAlters    {
    my ($db) = @_;

     my $stSELECT = qq[
        SELECT *
        FROM tblSQLAlters
    ];

    my $qry= $db->prepare($stSELECT);
    $qry->execute();
    my %AltersRun = ();
    while (my $ref = $qry->fetchrow_hashref())  {
        $AltersRun{$ref->{'strFilename'}} = 1;
    }
    return \%AltersRun;
}

sub logAlterSQL {
    my ($db, $file, $errors, $status) = @_;
    
    $errors ||= '';
    $status ||= 0;

    my $st= qq[
        INSERT INTO tblSQLAlters
        (strFilename, dtLog, strErrors, intStatus)
        VALUES (?,NOW(), ?, ?)
    ];
    my $qry= $db->prepare($st);
    $qry->execute(
        $file,
        $errors,
        $status
    );
}

1;
