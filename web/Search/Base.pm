package Search::Base;

use strict;
use CGI qw(:cgi escape);

use lib '.', '..';
use Defs;
use TTTemplate;
use Data::Dumper;

sub new {
    my $class = shift;
    my (%args) = @_;

    my $self = {
        _realmID            => $args{realmID},
        _subRealmID         => $args{subRealmID},
        _Data               => $args{Data},
        _searchType         => $args{searchType},
        _gridTemplate       => $args{gridTemplate} || 'search/grid/default.templ',
        _cgi                => $args{cgi} || new CGI,
        _query              => $args{query},
    };

    $self = bless ($self, $class);

    return $self;
}

sub getRealmID {
    my ($self) = shift;
    return $self->{_realmID};
}

sub getSubRealmID {
    my ($self) = shift;
    return $self->{_subRealmID};
}

sub getData {
    my ($self) = shift;
    return $self->{_Data};
}

sub getSearchType {
    my ($self) = shift;
    return $self->{_searchType};
}

sub getGridTemplate {
    my ($self) = shift;
    return $self->{_gridTemplate};
}

sub displaySearchForm {
    my ($self) = shift;

    my $cgi = $self->{'_cgi'};
	my %params = $self->{'_cgi'}->Vars();

    print STDERR Dumper $cgi;
	my %SearchFormData = (
			client=> $self->getData()->{'client'},
            action => $self->getSearchType(),
            search_keyword => $params{'search_keyword'},
	);

	my $content = runTemplate(
			$self->getData(),
			\%SearchFormData,
			'search/form.templ',
	);

}

sub search {
    my ($self) = shift;
}

sub processResult {

}


sub setRealmID {
    my $self = shift;
    my ($realmID) = @_;
    $self->{_realmID} = $realmID if defined $realmID;

    return $self;
}

sub setSubRealmID {
    my $self = shift;
    my ($subRealmID) = @_;
    $self->{_subRealmID} = $subRealmID if defined $subRealmID;

    return $self;
}

sub setData {
    my $self = shift;
    my ($Data) = @_;
    $self->{_Data} = $Data if defined $Data;

    return $self;
}

sub setSearchType {
    my $self = shift;
    my ($searchType) = @_;
    $self->{_searchType} = $searchType if defined $searchType;

    return $self;
}

sub setGridTemplate {
    my $self = shift;
    my ($gridTemplate) = @_;
    $self->{_gridTemplate} = $gridTemplate if defined $gridTemplate;

    return $self;
}

1;
