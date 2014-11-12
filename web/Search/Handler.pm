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

    switch ($action) {
        case 'INITSRCH_P' {
            $searchObj = undef;
        }
        else {
            return;
        }
    }

}
