package DBInserter;
require Exporter;
@EXPORT = qw(insertBatch connectDB);
@EXPORT_OK = qw(insertBatch connectDB);
@ISA =  qw(Exporter);
use lib '.','..';
use Data::Dumper;
use DBI;
use strict;
use Config;

sub insertRow {
	my ($db,$table,$record) = @_;
    my $keystr = (join ",\n        ", (keys $record));
	my $valstr = join ', ', (split(/ /, "? " x (scalar(values $record))));
	my @values = values $record;
	my $query = qq[
	    INSERT INTO $table (
		        $keystr
		    )
		    VALUES (
		        $valstr
		    )
	];
	my $sth = $db->prepare($query) or die "Can't prepare insert: ".$db->errstr()."\n";
	$sth->execute(@values) or die "Can't execute insert: ".$db->errstr()."\n";
}

sub insertBatch {
	my ($db,$table,$records) = @_;
	foreach my $i (@{$records}){
		insertRow($db,$table,$i);
	}
}

sub connectDB{

    print $Config::DB_USER;
    print "\n\n";
    my $dbh = DBI->connect('DBI:mysql:test', 'root','') or die $DBI::errstr;
    $dbh->do("SET NAMES 'utf8'");
    return $dbh;
}