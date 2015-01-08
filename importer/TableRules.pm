#!/usr/bin/perl
package TableRules;
require Exporter;
@ISA =  qw(Exporter);
@EXPORT = qw(multiplyEntry insertLink removeLinkField getConfig strToIntEntry setUniqField multiDestEntry insertField entityLink linkIdEntry defaultValue);
@EXPORT_OK = qw(multiplyEntry insertLink removeLinkField getConfig strToIntEntry setUniqField multiDestEntry insertField entityLink linkIdEntry defaultValue);

# This is where you should include the migration rule for your table
use Data::Dumper;
use JSON;
use DBInserter;
use ImporterConfig;

use feature qw(say);
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
	#my @tag = split(/\./,$filename);
	my @tag = split(/\.([^.]+)$/,$filename, 2);
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
    my ($records,$rule, $rulekey) = @_;
    my $collection = $rule->{"collection"};
    my @newRecords = ();
    foreach my $key ( @{$collection} ){
    	foreach my $record ( @{$records} ){
    		my $copy = {%$record};
	        $copy->{$rule->{"field"}} = $key;
			delete $copy->{$rulekey} if $rule->{"field"} ne $rulekey;
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
		say $rule->{"field"};
        my %link = (
            "intParentEntityID" => getRecord($db,"tblEntity","intEntityID","strImportEntityCode",$record->{$rule->{"field"}}),
            "intChildEntityID" => getRecord($db,"tblEntity","intEntityID","strImportEntityCode",$record->{"strImportEntityCode"}),
        );
		#say Dumper($record);
        push ($links,\%link)
    }
    return $links;
}
sub entityLink{
	my ($links,$records,$rule) = @_;
	my $entstruct = [];
    foreach my $record ( @{$records} ){
		say $rule->{"field"}.' =='. $rule->{"regionfld"};
		my $values = $rule->{"values"};
        #my $isocntry = $record->{ $rule->{"field"} };
        my $isocntry = $ImporterConfig::DefaultISOCountry;
		
		say $rule->{"rule"};
		
		#my $realm = $db->selectrow_array("select intrealmid,strRealmName from tblRealms where $values->{}");
        my $realmid = getRecord($db,"tblRealms","intrealmid","strRealmName",$values->{ $isocntry });
        #my $parentid = getRecord($db,"tblEntity","intEntityID","strLocalName",$values->{ $isocntry });
        my $parentid = getRecord($db,"tblEntity","intEntityID","strLocalShortName",$values->{ $isocntry });
		my $childid = getRecord($db,"tblEntity","intEntityID","strImportEntityCode",$record->{"strImportEntityCode"}),

		my %link = ();
		my %structure = ();
		my $regionval = $record->{ $rule->{"regionfld"} };
		if( ($isocntry eq "SG" || $regionval eq "" ) && ($parentid)) {
			$link{'intParentEntityID'} = $parentid;
			$link{'intChildEntityID'} = getRecord($db,"tblEntity","intEntityID","strImportEntityCode",$record->{"strImportEntityCode"}),
			
			$structure{'intParentLevel'} = "100";
			
			
			#$structure{'intChildLevel'} = "3";
			$structure{'intDirect'} = "1";
		} else {
			$link{'intParentEntityID'} = getRecord($db,"tblEntity","intEntityID","strLocalName",$regionval);
			#%link = (
            #"intParentEntityID" => getRecord($db,"tblEntity","intEntityID","strLocalName",$regionval),
            #"intChildEntityID" => getRecord($db,"tblEntity","intEntityID","strImportEntityCode",$record->{"strImportEntityCode"})
			#);
			$structure{'intParentLevel'} = getRecord($db,"tblEntity","intEntityLevel","strLocalName",$regionval);
			
			
        
		}
		$link{'intChildEntityID'} = $childid;
		
		if( ($record->{'strEntityType'} eq 'CLUB') || ($record->{'strEntityType'} eq 'ACADEMY') ) {
			$structure{'intChildLevel'} = "3";
		}elsif( $record->{'strEntityType'} eq 'ZONE') {
			$structure{'intChildLevel'} = "10";
		}elsif( $record->{'strEntityType'} eq 'REGION') {
			$structure{'intChildLevel'} = "20";
		}elsif( $record->{'strEntityType'} eq 'STATE') {
			$structure{'intChildLevel'} = "30";
		}elsif( $record->{'strEntityType'} eq 'VENUE') {
			$structure{'intChildLevel'} = "-47";
		}
		
		$structure{'intRealmID'} = $realmid;
		$structure{'intParentID'} = $link{'intParentEntityID'};
		$structure{'intChildID'} = $link{'intChildEntityID'};

        push ($links,\%link);
		push ($entstruct,\%structure)
    }
    return $links, $entstruct;
}

sub linkIdEntry{
	my ($records,$rule, $rkey) = @_;
	my @newRecords = ();
    foreach my $record ( @{$records} ){
        #TODO add checking $rule->{"required"}
        # if $rule->{"required"} eq "true" and there's no found link, skip current record (needed for PersonRegistration)

    	my $copy = {%$record};
        my $selectColumn = $rule->{"primarykey"} ? $rule->{"primarykey"} : $rule->{"destination"};
	    $copy->{$rule->{"destination"}} = getRecord($db,$rule->{"table"},$selectColumn,$rule->{"source"},$record->{$rkey});
	    delete $copy->{$rule->{"source"}}  if (defined $rule->{"swap"} && $copy->{$rule->{"swap"}});
	    push (@newRecords, $copy);

    }
    return \@newRecords;
}

sub defaultValue{
	my ($records,$rule, $rkey) = @_;

    my $value = $rule->{"value"};
    my @newRecords = ();
    foreach my $record ( @{$records} ){
    	my $copy = {%$record};
        $copy->{'dtAdded'} = $value;
	    push (@newRecords, $copy);
    }

    return \@newRecords;
}

sub linkIdEntry2{
	my ($records,$rule) = @_;
	my @newRecords = ();
	my $table = $rule->{"reference"};
	say Dumper($table);
	
    foreach my $record ( @{$records} ){
    	my $copy = {%$record};
		foreach my $key ( keys %{$table} ){
		    say $key.' == '.$table->{$key};
	        $copy->{ $table->{$key} } = getRecord($db, $key, $table->{$key}, $rule->{"link"}, $record->{$rule->{"link"}});
		}
	    push (@newRecords, $copy);
		
    }
    return \@newRecords;
}

sub strToIntEntry{
    my ($records,$key, $value) = @_;
    foreach my $record ( @{$records} ){
        if( $record->{$key} ) {
            #say Dumper( $value->{ $record->{$key} });
            $record->{$key} = $value->{ $record->{$key} };
        }
    }
    return $records;
}

sub insertField{
	my ($records,$rule, $key) = @_;
    my $values = $rule->{"values"};
    my @newRecords = ();
    foreach my $record ( @{$records} ){
        my $copy = {%$record};
        $copy->{$rule->{"field"}} = $values->{ $record->{$key} };
        push (@newRecords, $copy);
    }
    return \@newRecords;
}

sub insertEntityLevel{
	my ($records,$rule, $key) = @_;
    my $values = $rule->{"values"};
	say $rule->{"cntryfld"}.' =='. $rule->{"regionfld"};
    my @newRecords = ();
    foreach my $record ( @{$records} ){
		my $copy = {%$record};
		
		say $rule->{"rule"};
        #my $isocntry = $record->{ $rule->{"cntryfld"} };
        my $isocntry = $ImporterConfig::DefaultISOCountry;

        my $realmid = getRecord($db,"tblRealms","intrealmid","strRealmName",$values->{ $isocntry });
		
		if( ($isocntry eq "SG") || ( $record->{ $rule->{"regionfld"} } eq "" ) ) {
			my $parentE = $realmid;
			$copy->{$rule->{"newfield"}} = "100";
		} else {
			my $val = join "", (values $record);
			if( $val ) {
			    $copy->{$rule->{"newfield"}} = "3";
			}
			
		}
		say Dumper($record);
        push (@newRecords, $copy);
    }
    return \@newRecords;
}

sub multiDestEntry{
	my ($records,$rule,$key) = @_;
	my @newrecords = ();
	my @types = keys %{$rule->{'type'}};
	foreach my $record ( @{$records}) {
		my $copy = {%$record};
		foreach my $type (@types) {
			if( $record->{$key} && $record->{$key} eq $type ) {
				my $newfields = $rule->{'type'}->{$type};
				foreach my $fld (keys %{$newfields}) {
					# check if new field is not equal from orig field
					if( $fld ne $newfields->{$fld} ) {
						# create the new key/value pair
						$copy->{$fld} = $record->{ $newfields->{$fld} };
					}
					# delete the orig key
					delete $copy->{ $newfields->{$fld} } if exists $copy->{ $newfields->{$fld} };
				}
			}
		}
		# we must delete the source iden type since its not on the table
		delete $copy->{$key};
		# finally, fill out the new records
		push @newrecords, $copy;
	}
	return \@newrecords;
}

sub setUniqField{
    my ($records,$fieldname) = @_;
	my @newrecords = ();
    foreach my $record ( @{$records} ){
		my $copy = {%$record};
		
        if( $record->{$fieldname} ) {
            $copy->{"uniqField"} = $fieldname;
			push @newrecords, $copy;
        }
    }
    return \@newrecords;
}
1;
