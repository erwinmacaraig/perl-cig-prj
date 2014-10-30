
package DBInserter;
require Exporter;
@EXPORT = qw(insertBatch connectDB getRecord insertRow createRecord);
@EXPORT_OK = qw(insertBatch connectDB getRecord insertRow createRecord);
@ISA =  qw(Exporter);
use Data::Dumper;
use DBI;
use strict;
use ImporterConfig;
use feature qw(say);

sub insertRow {
	my ($db,$table,$record,$importId, $rules) = @_;
	$rules ||= "";
	
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
	
	if ($rules) {
		foreach my $key ( keys %{$rules} ){
			my $rule = $rules->{$key};
			say Dumper($rule);
			createRecord($db, $record, $rule);
		}
	}
	
	return $sth->{mysql_insertid};
	#say "INSERT SUCCESS :: TABLE:: '",$table,"' ID:: ' RECORDS:: '",join(', ', @values),"'\n";
	
	1;
}

sub insertBatch {
	my ($db,$table,$records,$importId, $rules) = @_;
	$rules ||= "None";
	foreach my $i (@{$records}){
		insertRow($db,$table,$i,$importId, $rules);
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
	  $field=$query->fetchrow_hashref();
	  $query->finish;
	  
	  return $field->{"intEntityID"};
}

sub connectDB{

    my $dbh = DBI->connect($ImporterConfig::DB_CONFIG{"DB_DSN"}, $ImporterConfig::DB_CONFIG{"DB_USER"},$ImporterConfig::DB_CONFIG{"DB_PASSWD"}) or die $DBI::errstr;
    $dbh->do("SET NAMES 'utf8'");
    return $dbh;
}

# this supports the rule to create record for other tables based from the fields declaration
sub createRecord {
    my ($db, $record, $rule) = @_;
	if($rule->{"rule"} eq "createRecord") {
		my $tbl    = $rule->{"table"};
		my $refID  = $rule->{"refID"};
		my $fields = $rule->{"fields"};
		my @values = $rule->{"values"};
		# exit if refID is empty
		if( !$record->{$refID} ) {
				return;
		}
		my @fldstr = ();
		my @vstr = ();
		foreach my $k( keys %{$fields} ){
			push @fldstr, $k;
			my $v = $record->{$fields->{$k}};
			if( defined $v){
				push @vstr, $v; 
				#say Dumper($record->{$fields->{$k}});
			} else {
				push @vstr, $fields->{$k};
			}
		}
		# prepare field names and its values
		my $keystr = (join ",\n        ", (@fldstr));
		my $valstr = join ', ', (split(/ /, "? " x (scalar(@vstr))));
		# construct mysql query
		my $query = qq[
			INSERT INTO $tbl ( $keystr )
				VALUES ( $valstr )
		];
		#$records = createRecord($records,$rule);
		my $sth = $db->prepare($query) or die "Can't prepare insert: ".$db->errstr()."\n";
		my $result = $sth->execute(@vstr) or die "Can't execute insert: ".$db->errstr()."\n";
		print "INSERT SUCCESS :: TABLE:: '",$tbl,"' ID:: ",$sth->{mysql_insertid},"' RECORDS:: '",join(', ', @vstr),"'\n";
	}
}

1;