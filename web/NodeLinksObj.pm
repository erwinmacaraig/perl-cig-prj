package NodeLinksObj;

use lib;
use BaseObject2;
our @ISA = qw(BaseObject2);

use strict;

use Utils;

sub _getTableName {
    return 'tblNodeLinks';
}

sub _getKeyName {
    return 'intNodeLinksID';
}

sub getParentNodeID {
    my $self = shift;

    my (%params) = @_;
    my $dbh      = $params{'dbh'};
    my $nodeID   = $params{'nodeID'};

    return undef if !$dbh or !$nodeID;

    my @fields = ('intParentNodeID');
    my %where  = (intChildNodeID=>$nodeID, intPrimary=>1);

    my ($sql, @bindVals) = getSelectSQL($self->_getTableName(), \@fields, \%where, undef);

    my $q = $dbh->prepare($sql);
    $q->execute(@bindVals);

    my ($parentNodeID) = $q->fetchrow_array() || 0;

    return $parentNodeID;
}

1;
