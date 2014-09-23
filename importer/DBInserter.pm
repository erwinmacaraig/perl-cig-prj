
package DBInserter;
require Exporter;
@EXPORT = qw(insertBatch connectDB getRecord insertRow);
@EXPORT_OK = qw(insertBatch connectDB getRecord insertRow);
@ISA =  qw(Exporter);
use Data::Dumper;
use DBI;
use strict;
use ImporterConfig;


sub insertRow {
	my ($db,$table,$record,$importId) = @_;
    my $keystr = (join ",\n        ", (keys $record));
	my $valstr = join ', ', (split(/ /, "? " x (scalar(values $record))));
	if(defined $importId){
    	$keystr = (join ",\n        ","intImportID", $keystr);
    	$valstr = (join ",","$importId", $valstr);
    }
	my @values = values $record;
	my %success = ();
	my $query = qq[
	    INSERT INTO $table (
		    $keystr
		)
		VALUES (
		    $valstr
		)
	];
	my $sth = $db->prepare($query) or die "Can't prepare insert: ".$db->errstr()."\n";
	my $result = $sth->execute(@values) or die "Can't execute insert: ".$db->errstr()."\n";
	print "INSERT SUCCESS :: TABLE:: '",$table,"' ID:: ",$sth->{mysql_insertid},"' RECORDS:: '",join(', ', @values),"'\n";
	return $sth->{mysql_insertid};
}

sub insertBatch {
	my ($db,$table,$records,$importId) = @_;
	foreach my $i (@{$records}){
		insertRow($db,$table,$i,$importId);
	}
}

sub getRecord{
	my ($db,$table,$field,$filter,$value) = @_;
	my $statement=qq[
	    SELECT 
          $field
	      FROM $table
	      WHERE $filter = ?
	  ];
	  my $query = $db->prepare($statement);
	  $query->execute($value);
	  my $field=$query->fetchrow_hashref();
	  $query->finish;
	  
	  return $field->{"intEntityID"};
}

sub connectDB{

    my $dbh = DBI->connect($ImporterConfig::DB_CONFIG{"DB_DSN"}, $ImporterConfig::DB_CONFIG{"DB_USER"},$ImporterConfig::DB_CONFIG{"DB_PASSWD"}) or die $DBI::errstr;
    $dbh->do("SET NAMES 'utf8'");
    return $dbh;
}
1;