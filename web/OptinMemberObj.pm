package OptinMemberObj;

use lib;
use BaseObject2;
our @ISA = qw(BaseObject2);

use strict;

use Utils;
use OptinMemberSQL;

sub _getSQL {
    my $sql = getSimpleSQL('*', _getTableName(), _getKeyName(), 1);
    return $sql;
}

sub _getTableName {
    return 'tblOptinMember';
}

sub _getKeyName {
    return 'intOptinMemberID';
}

sub getList {
    my $self = shift;

    my %params = @_;
    my $dbh      = $params{'dbh'};
    my $memberID = $params{'memberID'} || 0;
    my $optinID  = $params{'optinID'}  || 0;
    my $orderBy  = $params{'orderBy'}  || '';

    return undef if !$dbh;

    my $sql = getOptinMemberListSQL(memberID=>$memberID, optinID=>$optinID, orderBy=>$orderBy);

    my @bindVars = ();
    push @bindVars, $memberID if $memberID;
    push @bindVars, $optinID  if $optinID;

    my $q = getQueryPreparedAndBound($dbh, $sql, \@bindVars);
   
    $q->execute();

    my @optinMemberObjs = ();

    while (my $dref = $q->fetchrow_hashref()) {
        my $optinMemberObj = $self->load(db=>$dbh, ID=>$dref->{'intOptinMemberID'});
        push @optinMemberObjs, $optinMemberObj;
    }
    
    $q->finish();

    return \@optinMemberObjs;
}

1;
