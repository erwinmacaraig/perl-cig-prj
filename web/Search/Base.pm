package Search::Base;

use strict;
use lib '.', '..';
use Defs;
use Data::Dumper;

sub new {
    my $class = shift;
    my (%args) = @_;

    my $self = {
        _realmID            => $args{realmID},
        _subRealmID         => $args{subRealmID},
        _Data               => $args{Data},
        _db                 => $args{db},
        _SystemConfig       => $args{SystemConfig},
        _searchType         => $args{searchType},
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

sub getSubRealmID {
    my ($self) = shift;
    return $self->{_subRealmID};
}

sub displaySearchForm {

}

sub search {

}
