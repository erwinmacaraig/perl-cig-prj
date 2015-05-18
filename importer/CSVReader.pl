#!/usr/bin/perl -w
use strict;
use Data::Dumper;

use English;
use Getopt::Long;
use Text::CSV;
use TableRules;
use DBInserter;
use Text::CSV::Encoded;

use feature qw(say);

my $directory = '';
my $format = '';
my $notes = '';
my $realmID = 0;
my $fromNational = 0;
my $db = connectDB();

GetOptions ('directory=s' => \$directory, 'format=s' => \$format, 'notes=s' => \$notes, 'realmid=i' => \$realmID, 'national=i'=>$fromNational);

foreach my $fp (glob("$directory/*.".$format)) {
    my %importRecord = (
    	"strNotes" => $notes,
    );
	
	if( $fromNational) {
	    my $national = ucfirst((split '/', $directory)[1]);
	    my $natID = getRecord($db,"tblEntity","intEntityID","strLocalName",$national);
	    if( !$natID) {
		    my %natRec = (
			    'intEntityLevel' => '100',
			    'strStatus' => 'ACTIVE',
			    'strLocalName' => $national,
			    'strISOCountry' => uc($national)
		    );
		    insertRow($db,"tblEntity",\%natRec, 0, $realmID);
	    }
	}
	
    my ($importId) = insertRow($db,"tblImportTrack",\%importRecord);
    readCSVFile($fp,$importId, $realmID);
}


sub readCSVFile{
    my ($file,$importId, $realmID) = @_;
    my @records;
    my @directory = split /\//, $file;
    my $dirlength  = scalar @directory;
    my $table =  $directory[$dirlength - 1];
    
    #open my $fh, '<:utf8', $file or die "Cannot open: $!";
    open my $fh, "<", $file or die "Cannot open: $!";
    my $csv_config = {};
    
    if($format eq 'tsv'){
        $csv_config->{sep_char} = qq|\t|;
    }
    elsif($format eq 'csv'){
    	$csv_config->{sep_char} = qq|,|;
    }
	$csv_config->{'encoding_in'} = "iso-8859-1";
	$csv_config->{'encoding_out'} = "cp1252";
	$csv_config->{binary} = 1;
	
    my @tag = split(/\.([^.]+)$/,$table,2);
    my $object =  $tag[0];
    my $tbl =  (split /\./, $object)[0];
    my $csv = Text::CSV::Encoded->new($csv_config) or die "Text::CSV error: " . Text::CSV->error_diag;
	
    my $tblPRFlag = 0;
	if( $object =~ /(\w+)_(\d+)/ && $1 eq "tblPersonRegistration") {
        $tblPRFlag = 1;
        copyDbTable($db, $1."_1", $object);
	}

    my @headers = $csv->getline($fh) or die "no header";
	
    my $config = getConfig($object);
    my @keys = MapKeys(@headers, $config->{"mapping"});
    $csv->column_names(@keys);
    my $ctr = 0;

    while (my $hashref = $csv->getline_hr($fh)) {
        if($tblPRFlag) {
            #ordering of tblPersonRegistration_x.dtFrom matters
            my @dtFrom = split('-', $hashref->{'dtFrom'});
            @dtFrom = split('/', $hashref->{'dtFrom'}) if scalar(@dtFrom) < 3; #failover if diff format

            $hashref->{'dtFromSortValue'} = join('', @dtFrom);
        }

	    push @records, $hashref;
	    $ctr++;
    }

    if($tblPRFlag) {
        my @tempRecords;
        my @sortedRecords = sort { $a->{'dtFromSortValue'} <=> $b->{'dtFromSortValue'}} @records;
        foreach my $rec (@sortedRecords) {
            delete $rec->{'dtFromSortValue'};
	        push @tempRecords, $rec;
        }

        @records = @tempRecords;
    }

    say 'Total Input Records: #'.$ctr;
    my $records = ApplyPreRules($config->{"rules"},\@records);
    my $inserts = ApplyRemoveLinks($config->{"rules"},$records);

    #print STDERR Dumper $inserts;
    insertBatch($db,$tbl,$inserts,$importId, $realmID);
    my ($links, $entstruct) = ApplyPostRules($tbl,$config->{"rules"},\@records);
    #say Dumper($links);
    #say Dumper($entstruct);
    insertBatch($db,"tblEntityLinks",$links,$importId);

    #removing call to insertBatch for tblTempEntityStructure; automatic/tempEntityStructure.pl shall handle this
    #insertBatch($db,"tblTempEntityStructure",$entstruct,0,0);

    close $fh;
}

# Run only rules if there is any specified in the TableRules.
sub ApplyPreRules{
    my ($rules,$records) = @_;
    my @irecords = ();
    my @links = ();
    foreach my $key ( keys %{$rules} ){
        my $rule = $rules->{$key};
        if($rule->{"rule"} eq "multiplyEntry"){
           $records = multiplyEntry($records,$rule, $key);
        }
        #elsif($rule->{"rule"} eq "swapEntry"){
        #   $records = swapEntry($records,$rule);
        #}
		elsif($rule->{"rule"} eq "StrToIntEntry"){
			$records = strToIntEntry($records, $key, $rule->{"value"});
        }
        elsif($rule->{"rule"} eq "setUniqField"){
            $records = setUniqField($records, $key);
        }
        elsif($rule->{"rule"} eq "multiDestEntry"){
            $records = multiDestEntry($records, $rule, $key);
        }
		elsif($rule->{"rule"} eq "insertField") {
            $records = insertField($records, $rule, $key);
		}
		elsif($rule->{"rule"} eq "linkIdEntry") {
            $records = linkIdEntry($records, $rule, $key);
		}
		elsif($rule->{"rule"} eq "defaultValue") {
            $records = defaultValue($records, $rule, $key);
		}
		elsif($rule->{"rule"} eq "calculateAgeLevel") {
            $records = calculateAgeLevel($records, $rule, $key);
		}
    }

    return $records;
}

sub ApplyRemoveLinks{
	my ($rules,$records) = @_;
    my @irecords = ();
    my @links = ();
    foreach my $key ( keys %{$rules} ){
        my $rule = $rules->{$key};
        #if($rule->{"rule"} eq "insertLink"){
		if($rule->{"rule"} eq "removeLinkField"){
           $records = removeLinkField($records,$rule);
        }
    }
    return $records;
}
# Run only rules if there is any specified in the TableRules.
sub ApplyPostRules{
    my ($table,$rules,$records) = @_;
    my $links = [];
	my $entstruct = [];
    foreach my $key ( keys %{$rules} ){
        my $rule = $rules->{$key};
		
        if($rule->{"rule"} eq "insertLink"){
           ($links, $entstruct) = insertLink($links,$records,$rule);
        } elsif($rule->{"rule"} eq "entityLink") {
			($links, $entstruct) = entityLink($links,$records,$rule);
        } elsif($rule->{"rule"} eq "entityLink2") {
			($links, $entstruct) = entityLink2($links,$records,$rule);
		}
    }
    return $links, $entstruct;
   
}
sub MapKeys{
	my ($headers,$mapping) = @_;
	my @keys = ();
	foreach my $i (@{$headers}){
		# include fieldname if its in mapping rule
		push @keys,$mapping->{$i} if exists $mapping->{$i};
	}
	return @keys;
}
