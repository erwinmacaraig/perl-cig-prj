package Search::Handler;
require Exporter;

use strict;
use lib '.', '..';
use Utils;
use Data::Dumper;
use Switch;
use Search::Person;

sub handle {
    my ($action, $Data) = @_;

    my $searchObj = undef;
    my $searchType = '';

    switch ($action) {
        case 'INITSRCH_P' {
            $searchType = "INITSRCH_P";
            $searchObj = new Search::Person();
        }
        case 'INITSRCH_C' {
            return;
        }
        case 'INITSRCH_V' {
            return;
        }
        else {
            return;
        }
    }

    $searchObj
        ->setRealmID($Data->{'Realm'})
        ->setSubRealmID(0)
        ->setSearchType($searchType)
        ->setData($Data);

    

    return $searchObj->displaySearchForm();
}
