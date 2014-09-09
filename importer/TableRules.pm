#!/usr/bin/perl
package TableRules;
require Exporter;
@ISA =  qw(Exporter);
@EXPORT = qw(getRules multiplyEntry);
@EXPORT_OK = qw(getRules multiplyEntry);

# This is where you should include the migration rule for your table
use Rules::tblEntityRegistrationAllowed;
use Data::Dumper;


my %rules = ();

# This is where you should load your table specific rules per field
$rules->{"tblEntityRegistrationAllowed"} = load tblEntityRegistrationAllowed();

sub getRules{
	my ($table) = @_;
	return ($rules->{$table});
}

# Allow cloning of record and change each clone value base on the collection attribute.

sub multiplyEntry{
    my ($records,$hashref,$rule) = @_;
    my $collection = $rule->{"collection"};
    foreach my $key ( @{$collection} ){
        my $row = {%$hashref};
        $row->{$rule->{field}} = $key;
        push $records, $row;
    }
   # print Dumper($records);
}