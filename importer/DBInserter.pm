
package DBInserter;
require Exporter;
@EXPORT = qw(insertBatch connectDB getRecord insertRow);
@EXPORT_OK = qw(insertBatch connectDB getRecord insertRow);
@ISA =  qw(Exporter);
use Data::Dumper;
use DBI;
use strict;
use ImporterConfig;
use Try::Tiny;
use POSIX qw(strftime);
use feature qw(say);

sub insertRow {
	my ($db,$table,$record,$importId) = @_;
	my $keystr = (join ",\n        ", (keys $record));
	my $valstr = join ', ', (split(/ /, "? " x (scalar(values $record))));
	if(defined $importId){
    	$keystr = (join ",\n        ","intImportID", $keystr);
    	$valstr = (join ",","$importId", $valstr);
    }
	
	my @tbl_array = ("tblImportTrack", "tblEntityLinks");
	if( !grep(/^$table$/i, @tbl_array) ){	
		my $val = join "", (values $record);
		# skip insert if all data are empty
		if( !$val ) {
			say "no value";
			return 0;
		}
		
	}
	
	# add realmid=1
    if( isRealmExists($db, $table) ) {
        $keystr = (join ",\n        ","intRealmID", $keystr);
        $valstr = (join ",","1", $valstr);
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
	# write log for each insert
	writeLog("INFO: INSERT INTO $table ($keystr) VALUES(". join(', ', @values).")");
	try {
	    my $sth = $db->prepare($query) or die "Can't prepare insert: ".$db->errstr()."\n";
	    my $result = $sth->execute(@values) or die "Can't execute insert: ".$db->errstr()."\n";
		print "INSERT SUCCESS :: TABLE:: '",$table,"' ID:: ",$sth->{mysql_insertid},"' RECORDS:: '",join(', ', @values),"'\n";
	    writeLog("INFO: INSERT SUCCESS :: TABLE:: '".$table."' ID:: ".$sth->{mysql_insertid}."' RECORDS:: '". join(', ', @values).")");
		return $sth->{mysql_insertid};
	
	} catch {
		writeLog("ERROR: $_");
		#say "INSERT INTO $table ($keystr) VALUES(",join(', ', @values),")'\n";
		warn "caught error: $_";
		return 0; 
	};
	#1;
}

sub updateRow {
	my ($db,$table,$record) = @_;
	my $uniq_id = $record->{'uniqField'};
	my $filter_value = $record->{$uniq_id};
	delete $record->{'uniqField'};
	delete $record->{$uniq_id};
	my $keystr = (join "=?, ", (keys $record));
	$keystr .= "=?";
	
	my @values = values $record;

	my %success = ();
	my $query = qq[
	    UPDATE $table 
		    SET $keystr
		WHERE $uniq_id = $filter_value
	];

	writeLog("INFO: UPDATE $table SET $keystr");
	try {
	    my $sth = $db->prepare($query) or die "Can't prepare insert: ".$db->errstr()."\n";
	    my $result = $sth->execute(@values) or die "Can't execute insert: ".$db->errstr()."\n";
	    writeLog("INFO: UPDATE SUCCESS :: TABLE:: '".$table."' ID:: ".$sth->{mysql_insertid}."' RECORDS:: '". join(', ', @values).")");
		return $sth->{mysql_insertid};
	
	} catch {
		writeLog("ERROR: $_");
		warn "caught error: $_";
		return 0; 
	};
}

sub insertBatch {
	my ($db,$table,$records,$importId, $rules) = @_;
	$rules ||= "None";
	foreach my $i (@{$records}){
		
		#get nationalperiod id if any
		my $periodID = getNationalPeriodID($db, $i);
		if( $periodID) {
		    $i->{'intNationalPeriodID'} = $periodID;
		}
		
		# populate transLog and transaction recs
		createTransRecord($db, $i);
		#call_func(\&createTransReccord);
		
		# then insert the main file
		if( exists $i->{'uniqField'} ) {
			updateRow($db,$table,$i);
		} else {		
		    insertRow($db,$table,$i,$importId);
		}
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

    my $dbh = DBI->connect($ImporterConfig::DB_CONFIG{"DB_DSN"}, $ImporterConfig::DB_CONFIG{"DB_USER"},$ImporterConfig::DB_CONFIG{"DB_PASSWD"},{mysql_enable_utf8=>1} ) or die $DBI::errstr;
    $dbh->do("SET NAMES 'utf8'");
    return $dbh;
}

sub isRealmExists {
    my ($db, $table) = @_;
    my $columns = $db->selectrow_array("show columns from $table like 'intRealmID'");
    if ($columns) {
        return 1;
    }
    return 0;
}

sub getNationalPeriodID {
    my ($db,$rec) = @_;
	my $periodID = 0;
    if( exists $rec->{'NationalSeason'} && $rec->{'NationalSeason'}  ){
		my $stmt=qq[
	        SELECT 
				intNationalPeriodID
				FROM tblNationalPeriod
				WHERE strNationalPeriodName = $rec->{'NationalSeason'}
		];
		$periodID = $db->selectrow_array($stmt);
		writeLog("getNationalPeriodID() - $periodID");
	}
	delete $rec->{'NationalSeason'} if exists $rec->{'NationalSeason'};
    return $periodID;
}

sub createTransRecord {
    my ($db, $rec) = @_;
	if( exists $rec->{'PaymentReference'} && $rec->{'PaymentReference'}  ){
		# populate tblTranslog and transactions
		my %translogRecord = (
			"strAuthID"     => $rec->{'PaymentReference'},
			"strReceiptRef" => $rec->{'PaymentReference'},
		);
		my $ret_id = insertRow($db,'tblTransLog',\%translogRecord);
		writeLog("INFO: createTransRecord() - tblTransLog". \%translogRecord);
		if( $ret_id ){
		    my %transactionRecord = (
			    "intTransLogID" => $ret_id,
			    "curAmount"     => $rec->{'Amount'}, 
			    "intProductID"  => $rec->{'ProductCode'},
				"intStatus"     => 1,
				"intQty"        => 1,
		    );
		    $ret_id = insertRow($db,'tblTransactions',\%transactionRecord);
			writeLog("INFO: createTransRecord() - tblTransactions". \%transactionRecord);
		}
		
	}
	# remove fields from the hash table
    delete $rec->{'PaymentReference'} if exists $rec->{'PaymentReference'};
    delete $rec->{'Amount'} if exists $rec->{'Amount'};
	delete $rec->{'ProductCode'} if exists $rec->{'ProductCode'};
	#return $rec;
}

sub writeLog{
    my ($strMsg) = @_;
	#say $strMsg;
    my $filename = 'importer.log';
	my $date = strftime "%m/%d/%Y %H:%M:%S", localtime;
    open(my $fh, '>>', $filename) or die "Could not open file '$filename' $!";
    print $fh "$date - $strMsg\n";
    close $fh;
}
1;