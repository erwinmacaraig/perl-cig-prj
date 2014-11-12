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
        _keyword            => $args{keyword},
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

sub getKeyword {
    my ($self) = shift;
    return $self->{_keyword};
}

sub displaySearchForm {
    my ($self) = shift;

	my %SearchFormData = (
        client=> $self->getData()->{'client'},
        action => $self->getSearchType(),
        #search_keyword => $params{'search_keyword'},
        search_keyword => $self->getKeyword(),
	);

	my $content = runTemplate(
			$self->getData(),
			\%SearchFormData,
			'search/form.templ',
	);

}

sub displayResultGrid {
    my ($self) = shift;
    my ($list) = @_;

    my %SearchFormData = (
        RegoList => $list,
	);

	my $content = runTemplate(
        $self->getData(),
        \%SearchFormData,
        $self->getGridTemplate(),
	);

    return $content;
}

sub process {}

sub cleanKeyword {
    my $self = shift;
    my ($rawKeyword) = @_;

    $rawKeyword ||= '';
    $rawKeyword =~ s/\h+/ /g;
    $rawKeyword =~ s/^\s+|\s+$//;

    return $rawKeyword;
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

sub setKeyword {
    my $self = shift;
    my ($keyword) = @_;
    $self->{_keyword} = $keyword if defined $keyword;

    return $self;
}

1;
