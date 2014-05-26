package TermsMemberSQL;
                           
use lib '../..';

require Exporter;
@ISA       = qw(Exporter);
@EXPORT    = qw(getTermsMemberListSQL);
@EXPORT_OK = qw(getTermsMemberListSQL);

use strict;

sub getTermsMemberListSQL {
    my (%params) = @_;

    my $fields   = $params{'fields'}   || '*';
    my $memberID = $params{'memberID'} || 0;
    my $level    = $params{'level'}    || 0;
    my $orderBy  = $params{'orderBy'}  || '';

    my $sql = qq[SELECT $fields FROM tblTermsMember WHERE 1=1];

    $sql .= q[ AND intMemberID=?]  if $memberID;
    $sql .= q[ AND intLevel=?]     if $level;
    $sql .= qq[ ORDER BY $orderBy] if $orderBy;

    return $sql;
}

1;
