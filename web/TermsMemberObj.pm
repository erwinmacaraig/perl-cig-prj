package TermsMemberObj;

use lib;
use BaseObject2;
our @ISA = qw(BaseObject2);

use strict;

use Utils;
use TermsMemberSQL;

sub _getSQL {
    my $sql = getSimpleSQL('*', _getTableName(), _getKeyName(), 1);
    return $sql;
}

sub _getTableName {
    return 'tblTermsMember';
}

sub _getKeyName {
    return 'intTermsMemberID';
}

sub getList {
    my $self = shift;

    my %params = @_;
    my $dbh      = $params{'dbh'};
    my $memberID = $params{'memberID'} || 0;
    my $level    = $params{'level'}    || 0;
    my $orderBy  = $params{'orderBy'}  || '';

    return undef if !$dbh;

    my $sql = getTermsMemberListSQL(memberID=>$memberID, level=>$level, orderBy=>$orderBy);

    my @bindVars = ();
    push @bindVars, $memberID if $memberID;
    push @bindVars, $level    if $level;

    my $q = getQueryPreparedAndBound($dbh, $sql, \@bindVars);
   
    $q->execute();

    my @termsMemberObjs = ();

    while (my $dref = $q->fetchrow_hashref()) {
        my $termsMemberObj = $self->load(db=>$dbh, ID=>$dref->{'intTermsMemberID'});
        push @termsMemberObjs, $termsMemberObj;
    }
    
    $q->finish();

    return \@termsMemberObjs;
}

1;
