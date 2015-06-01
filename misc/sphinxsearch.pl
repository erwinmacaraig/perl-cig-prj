use strict;
use lib '.', '..';
use Defs;
use Sphinx::Search;
use Encode;

my $string = 'abby';
my $string = decode('UTF-8','姓名的語言');
my $indexName = 'FIFA_Persons_r1';
my $indexName = 'FIFA_Persons_RT_r1';

my $sphinx = Sphinx::Search->new;

$sphinx->SetServer($Defs::Sphinx_Host, $Defs::Sphinx_Port);
$sphinx->SetLimits(0,1000);

my $results = $sphinx->Query($string, $indexName);
use Data::Dumper;
print STDERR Dumper($results);


