package Search::Handler;
require Exporter;

use strict;
use lib '.', '..';
use Utils;
use Data::Dumper;
use Switch;
use Search::Person;
use TTTemplate;

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

    my $cgi = $searchObj->{'_cgi'};
	my %params = $searchObj->{'_cgi'}->Vars();
	my %SearchData = ();

    if($params{'submit'} eq 'Search') {
        $searchObj->setKeyword($params{'search_keyword'});
        $SearchData{'searchForm'} = $searchObj->displaySearchForm();

        my $resultGrid = $searchObj->process();
        $SearchData{'searchResultGrid'} = $resultGrid;
    }
    else {
        $SearchData{'searchForm'} = $searchObj->displaySearchForm();
    }

	my $content = runTemplate(
        $Data,
        \%SearchData,
        'search/wrapper.templ',
	);

    return ($content, "Search");
}
