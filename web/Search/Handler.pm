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
	my $title = $Data->{'lang'}->txt('Search');

    switch ($action) {
        case 'INITSRCH_P' {
            $searchObj = new Search::Person();
            $title = $Data->{'lang'}->txt('Request for Person Details Search') if($searchType eq 'access');
			
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
        #->setGridTemplate("search/grid/people.templ");

    my $cgi = $searchObj->{'_cgi'};
	my %params = $searchObj->{'_cgi'}->Vars();
	my %SearchData = ();

    if($render){
        if($params{'submitb'}) {
            $searchObj->setKeyword($params{'search_keyword'});
            $SearchData{'searchForm'} = $searchObj->displaySearchForm();

            my $resultGrid = $searchObj->process();
            $SearchData{'searchResultGrid'}{'data'} = $resultGrid;
            $SearchData{'searchResultGrid'}{'count'} = $searchObj->getResultCount();
        }
        else {
            $SearchData{'searchForm'} = $searchObj->displaySearchForm();
            $SearchData{'searchResultGrid'} = '';
        }

        my $content = runTemplate(
            $Data,
            \%SearchData,
            'search/wrapper.templ',
        );

        return ($content, $title);
    }
    else {
    
    }
}
