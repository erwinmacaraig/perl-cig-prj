#!/usr/bin/perl
package TableRules;
require Exporter;
@ISA =  qw(Exporter);
@EXPORT = qw(multiplyEntry insertLink removeLinkField getConfig);
@EXPORT_OK = qw(multiplyEntry insertLink removeLinkField getConfig);

# This is where you should include the migration rule for your table
use Data::Dumper;
use JSON;
use DBInserter;


my $db = connectDB();
my %config = ();

foreach my $fp (glob("Rules/*."."json")) {
	my @directory = split(/\//,$fp);
    my $dirlength  = scalar @directory;
    my $filename =  $directory[$dirlength - 1];
	readJSONFile($fp,$filename);
}

sub readJSONFile{
	
	my ($fp,$filename) = @_;
	my @tag = split(/\./,$filename);
	my $object =  $tag[0];

	my $json_text = do {
	   open(my $json_fh, "<:encoding(UTF-8)", $fp)
	      or die("Can't open $fp");
	   local $/;
	   <$json_fh>
	};
	
	my $json = JSON->new;
	my $data = $json->decode($json_text);
	$config->{$object} = $data;
}

sub getConfig{
	my ($table) = @_;
	my $cfg = $config->{$table};
	return $cfg;
}

# Allow cloning of record and change each clone value base on the collection attribute.

sub multiplyEntry{
    my ($records,$rule) = @_;
    my $collection = $rule->{"collection"};
    my @newRecords = ();
    foreach my $key ( @{$collection} ){
    	foreach my $record ( @{$records} ){
    		my $copy = {%$record};
	        $copy->{$rule->{"field"}} = $key;
	        push (@newRecords, $copy);
    	}
   }
   return \@newRecords;
   
}
sub removeLinkField{
	my ($records,$rule) = @_;
	my @newRecords = ();
    foreach my $record ( @{$records} ){
    	my $copy = {%$record};
	    delete $copy->{$rule->{"field"}};
	    push (@newRecords, $copy);
    }
    return \@newRecords;
}
sub insertLink{
	my ($links,$records,$rule) = @_;
    foreach my $record ( @{$records} ){
        my %link = (
            "intParentEntityID" => getEntity($db,"strImportEntityCode",$record->{$rule->{"field"}}),
            "intChildEntityID" => getEntity($db,"strImportEntityCode",$record->{"strImportEntityCode"}),
        );
        push ($links,\%link)
    }
    return $links;
}

1;