#!/usr/bin/perl -w
use strict;
use Data::Dumper;

use English;
use Getopt::Long;
use Text::CSV;
use TableRules;
use DBInserter;

my $directory = '';  
my $format = '';
my $notes = '';
my $db = connectDB();

GetOptions ('directory=s' => \$directory, 'format=s' => \$format, 'notes=s' => \$notes);

foreach my $fp (glob("$directory/*.".$format)) {
    my %importRecord = (
    	"strNotes" => $notes,
    );
    my ($importId) = insertRow($db,"tblImportTrack",\%importRecord);
    readCSVFile($fp,$importId);
}


sub readCSVFile{
    my ($file,$importId) = @_;
    my @records;
    my @directory = split /\//, $file;
    my $dirlength  = scalar @directory;
    my $table =  $directory[$dirlength - 1];
    
    open my $fh, '<:utf8', $file or die "Cannot open: $!";
    my $csv_config = {};
    
    if($format eq 'tsv'){
        $csv_config->{sep_char} = qq|\t|;
    }
    elsif($format eq 'csv'){
    	$csv_config->{sep_char} = qq|,|;
    }
    my @tag = split(/\./,$table);
	my $object =  $tag[0];
    my $csv = Text::CSV->new($csv_config) or die "Text::CSV error: " . Text::CSV->error_diag;
    my @headers = $csv->getline($fh) or die "no header";
    my $config = getConfig($object);
	;
    my @keys = MapKeys(@headers,$config->{"mapping"});
    $csv->column_names(@keys);
    while (my $hashref = $csv->getline_hr($fh)) {
      push @records, $hashref;
    }
    my $records = ApplyPreRules($config->{"rules"},\@records);
    my $inserts = ApplyRemoveLinks($config->{"rules"},$records);
   
    insertBatch($db,$object,$inserts,$importId);
    my $links = ApplyPostRules($object,$config->{"rules"},\@records); 
    insertBatch($db,"tblEntityLinks",$links,$importId);
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
           $records = multiplyEntry($records,$rule);
        }
        if($rule->{"rule"} eq "swapEntry"){
        	print Dumper($rule);
           $records = swapEntry($records,$rule);
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
        if($rule->{"rule"} eq "insertLink"){
           $records = removeLinkField($records,$rule);
        }
    }
    return $records;
}
# Run only rules if there is any specified in the TableRules.
sub ApplyPostRules{
    my ($table,$rules,$records) = @_;
    my $links = [];
    foreach my $key ( keys %{$rules} ){
        my $rule = $rules->{$key};
        if($rule->{"rule"} eq "insertLink"){
           $links = insertLink($links,$records,$rule);
        }
    }
    return $links;
   
}
sub MapKeys{
	my ($headers,$mapping) = @_;
	my @keys = ();
	foreach my $i (@{$headers}){
		push @keys,$mapping->{$i};
	}
	return @keys;
}
