package OptinMemberSQL;
                           
use lib '../..';

require Exporter;
@ISA       = qw(Exporter);
@EXPORT    = qw(getOptinMemberListSQL);
@EXPORT_OK = qw(getoptinMemberListSQL);

use strict;

sub getOptinMemberListSQL {
    my (%params) = @_;

    my $fields   = $params{'fields'}   || '*';
    my $memberID = $params{'memberID'} || 0;
    my $optinID  = $params{'optinID'}  || 0;
    my $orderBy  = $params{'orderBy'}  || '';

    my $sql = qq[SELECT $fields FROM tblOptinMember WHERE 1=1];

    $sql .= q[ AND intMemberID=?]  if $memberID;
    $sql .= q[ AND intOptinID=?]   if $optinID;
    $sql .= qq[ ORDER BY $orderBy] if $orderBy;

    return $sql;
}

1;
