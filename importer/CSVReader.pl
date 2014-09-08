#!/usr/bin/perl
use strict;
use Data::Dumper;

use English;
use Getopt::Long;
use Text::CSV;
use TableRules;
use DBInserter;

my $directory = '';  
my $format = '';
my $db = connectDB();

GetOptions ('directory=s' => \$directory, 'format=s' => \$format);

foreach my $fp (glob("$directory/*.".$format)) {
  readCSVFile($fp);
}


sub readCSVFile{
    my ($file) = @_;
    my @records;
    my @directory = split /\//, $file;
    my $dirlength  = scalar @directory;
    my $table =  $directory[$dirlength - 1];
    
    open my $fh, '<:utf8', $file or die "Cannot open: $!";
    my $csv_config = {};
    
    if($format eq 'tsv'){
        $csv_config->{sep_char} = qq|\t|;
        $table =~ s/.tsv//g;
    }
    elsif($format eq 'csv'){
    	$csv_config->{sep_char} = qq|,|;
        $table =~ s/.csv//g;
    }
    
    my $csv = Text::CSV->new($csv_config) or die "Text::CSV error: " . Text::CSV->error_diag;
    my @headers = $csv->getline($fh) or die "no header";
    $csv->column_names(@headers);
    while (my $hashref = $csv->getline_hr($fh)) {
      push @records, $hashref;
      ApplyRules($table,$hashref);
    }
    close $fh;
}

# Run only rules if there is any specified in the TableRules.
sub ApplyRules{
    my ($table,$hashref) = @_;
    my @mrecords;
    my ($rules) = getRules($table);
    foreach my $key ( keys $rules ){
        my $rule = $rules->{$key};
        if($rule->{"rule"} eq "multiplyEntry"){
           multiplyEntry(\@mrecords,$hashref,$rule);
        }
    }
    insertBatch($db,$table,\@mrecords);
   # print Dumper(@mrecords);
}
