#! /usr/bin/perl -w

#
# $Header: svn://svn/SWM/trunk/misc/loadFixtureTemplates.pl 8250 2013-04-08 08:24:36Z rlee $
#

use strict;
use DBI;

my $DB_DSN = "DBI:mysql:regoSWM_live";
my $DB_USER = "root";
my $DB_PASSWD = '';

my $dbh = DBI->connect($DB_DSN, $DB_USER, $DB_PASSWD);

my $query = "INSERT INTO tblCompFixtureTemplate(intRealmID,intAssocID,strName,strTemplate,intTypeID) VALUES (2,0,?,?,?)";
my $sth = $dbh->prepare($query) || die "Couldn't prepare insert statement: $!\n";

my $dir = 'fixturetemplates/reidtemplates';

opendir (DIR,$dir) or die "Open failed : $!\n";
while (my $file = readdir DIR) { 
    next if ($file =~ /^\.{1,2}$/);
    print "Processing:$file\n";
    (my $name = $file) =~s/\.txt$//;
    my $type  = 0;
    if ($name =~/Final/) {
        $type = 1;
    }
    open(FH,"$dir/$file") || die "Couldn't open $file: $!\n";
    my $template_str = '';
    
    while (<FH>) {
        $template_str .= $_; 
    }
    #print $template_str, "\n";
    
    $sth->execute($name,$template_str,$type) || die "Couldn't insert template: $!\n";
}

exit;

