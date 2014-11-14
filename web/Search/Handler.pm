package Search::Handler;
require Exporter;

use strict;
use lib "..",".","../..";
use CGI qw(param);
use Utils;
use Data::Dumper;
use Switch;
use Search::Person;
use TTTemplate;

sub handle {
    my ($action, $Data, $render) = @_;

    my $searchObj = undef;
    my $searchType = param('type') || '';


    switch ($action) {
        case 'INITSRCH_P' {
            $searchObj = new Search::Person();
        }
        case 'INITSRCH_C' {
            return;
        }
        case 'INITSRCH_V' {
            return;
        }
        else {
            #return ALL here
            return;
        }
    }

    $searchObj
        ->setRealmID($Data->{'Realm'})
        ->setSubRealmID(0)
        ->setSearchType($searchType)
        ->setAction($action)
        ->setSphinx()
        ->setData($Data);

    my $cgi = $searchObj->{'_cgi'};
	my %params = $searchObj->{'_cgi'}->Vars();
	my %SearchData = ();

        print STDERR Dumper "RENDER " . $render;
    if($render){
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
    else {
    
    }
}
