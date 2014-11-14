package Search::Base;

use strict;
use CGI qw(:cgi escape);

use lib '.', '..';
use Defs;
use Sphinx::Search;
use TTTemplate;
use Data::Dumper;
use Reg_common;
use Utils;

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
        _queryParam         => $args{queryParam},
        _sphinx             => $args{sphinx},
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

sub getQuery {
    my ($self) = shift;
    return $self->{_query};
}

sub getQueryParam {
    my ($self) = shift;
    return $self->{_queryParam};
}

sub getSphinx {
    my ($self) = shift;
    return $self->{_sphinx};
}

sub execute {
    my ($self) = shift;
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

sub setupFilters  {
    my $self = shift;

    my ($subEntities) = @_;

    my $realm = $self->getData()->{'Realm'} || 0;
    my $clubID = $self->getData()->{'clientValues'}{'clubID'} || 0;
    $clubID = 0 if $clubID < 0;

    my %filters = (
        realm => $realm,
        club => $clubID,
    );

    if($subEntities)  {
        $filters{'entity'} = $subEntities;
    }

    return \%filters;
}

sub getSearchLink  {
    my ($self) = shift;
    my (
        $Data,
        $level,
        $field,
        $value,
        $intermediateNodes,
        $entityID,
        $entityLevel,
    ) = @_;

    my %tempClientValues = %{$Data->{'clientValues'}};
    $field ||= getClientFieldKey($level);

    my %actions=(
        $Defs::LEVEL_PERSON => 'P_HOME',
        $Defs::LEVEL_CLUB => 'C_HOME',
        $Defs::LEVEL_ZONE => 'E_HOME',
        $Defs::LEVEL_REGION => 'E_HOME',
        $Defs::LEVEL_STATE => 'E_HOME',
        $Defs::LEVEL_NATIONAL => 'E_HOME',
        $Defs::LEVEL_INTZONE => 'E_HOME',
        $Defs::LEVEL_INTREGION => 'E_HOME',
        $Defs::LEVEL_INTERNATIONAL => 'E_HOME',
    );

    my $structlevel = $level || 0;
    my $structvalue = $value || 0;
    if($level == $Defs::LEVEL_PERSON)    {
        $structlevel = $entityLevel;
        $structvalue = $entityID || 0;
    }

    for my $k (keys %{$intermediateNodes->{$structlevel}{$structvalue}})  {
        if(
            !$tempClientValues{$k} 
            or ($tempClientValues{$k} and $tempClientValues{$k} == $Defs::INVALID_ID )
        )  {
            $tempClientValues{$k} = $intermediateNodes->{$structlevel}{$structvalue}{$k} || 0;
        }
    }

    $tempClientValues{$field} = $value;
    $tempClientValues{currentLevel} = $level;
    my $tempClient = setClient(\%tempClientValues);

    my $act = $actions{$level};
    my $url = "$Data->{'target'}?client=$tempClient&amp;a=$act";

    return $url;
}

sub getIntermediateNodes {
    my ($self) = shift;

    my $currentLevel = $self->getData()->{'clientValues'}{'currentLevel'} || 0;
    my $currentID = getID($self->getData()->{'clientValues'}) || 0;

    return undef if !$currentLevel;
    return undef if !$currentID;

    my $field = '';
    $field = 'int100_ID' if $currentLevel == $Defs::LEVEL_NATIONAL;
    $field = 'int30_ID' if $currentLevel == $Defs::LEVEL_STATE;
    $field = 'int20_ID' if $currentLevel == $Defs::LEVEL_REGION;
    $field = 'int10_ID' if $currentLevel == $Defs::LEVEL_ZONE;
    $field = 'int3_ID' if $currentLevel == $Defs::LEVEL_CLUB;

    my $st = qq[
        SELECT 
            int100_ID,
            int30_ID,
            int20_ID,
            int10_ID,
            int3_ID
        FROM
            tblTempTreeStructure
        WHERE
            intRealmID = ?
        AND $field = ?
    ];
        #AND intPrimary = 1
    my $q = $self->getData()->{'db'}->prepare($st);
    $q->execute(
        $self->getData()->{'Realm'},
        $currentID,
    );

    my %intermediateNodes = ();
    my %nodes = ();
    while(my $dref = $q->fetchrow_hashref())  {
        my $zoneID = $dref->{'int10_ID'} || 0;
        my $regionID = $dref->{'int20_ID'} || 0;
        my $stateID = $dref->{'int30_ID'} || 0;
        my $nationalID = $dref->{'int100_ID'} || 0;
        my $clubID = $dref->{'int3_ID'} || 0;
        #if($currentLevel <= $Defs::LEVEL_NATIONAL)  {
              #$nationalID = 0;
        #}
        #if($currentLevel <= $Defs::LEVEL_STATE)  {
              #$stateID = 0;
        #}
        #if($currentLevel <= $Defs::LEVEL_REGION)  {
              #$regionID = 0;
        #}
        #if($currentLevel <= $Defs::LEVEL_ZONE)  {
              #$zoneID = 0;
        #}
        #if($currentLevel <= $Defs::LEVEL_CLUB)  {
              #$clubID = 0;
        #}
        $intermediateNodes{$Defs::LEVEL_STATE}{$stateID} = {
          natID => $nationalID || 0,  
        };
        $intermediateNodes{$Defs::LEVEL_REGION}{$regionID} = {
          natID => $nationalID || 0,  
          stateID => $stateID || 0,  
        };
        $intermediateNodes{$Defs::LEVEL_ZONE}{$zoneID} = {
          natID => $nationalID || 0,  
          stateID => $stateID || 0,  
          regionID => $regionID || 0,  
        };
        $intermediateNodes{$Defs::LEVEL_CLUB}{$clubID} = {
          natID => $nationalID || 0,  
          stateID => $stateID || 0,  
          regionID => $regionID || 0,  
          zoneID => $zoneID || 0,  
          clubID => $clubID || 0,  
        };
        $nodes{$nationalID || 0} = 1;
        $nodes{$stateID || 0} = 1;
        $nodes{$regionID || 0} = 1;
        $nodes{$zoneID || 0} = 1;
        $nodes{$clubID || 0} = 1;
    }

    delete $nodes{0};
    delete $nodes{-1};
    my @nodes = keys %nodes;
    return (\%intermediateNodes, \@nodes);
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

sub setQuery {
    my $self = shift;
    my ($query) = @_;
    $self->{_query} = $query if defined $query;

    return $self;
}

sub setQueryParam {
    my $self = shift;
    my ($queryParam) = @_;
    $self->{_queryParam} = $queryParam if defined $queryParam;

    return $self;
}

sub setSphinx {
    my $self = shift;
    my ($sphinx) = @_;

    if(defined $sphinx) {
        $self->{_sphinx} = $sphinx;
    }
    else {
        my $sphinx = Sphinx::Search->new;

        $sphinx->SetServer($Defs::Sphinx_Host, $Defs::Sphinx_Port);
        $sphinx->SetLimits(0,1000);

        $self->{_sphinx} = $sphinx;
    }

    return $self;
}

1;
