package OptinObj;

use lib;
use BaseObject2;
our @ISA = qw(BaseObject2);

use strict;

use Reg_common;

sub _getTableName {
    return 'tblOptin';
}

sub _getKeyName {
    return 'intOptinID';
}

#use this method to get the hierarchical optins for an entityID.
#to get the optins for just the entity, use the objects getlist method.

#if the entity info is for a club, then an assocID must be provided.

#list of optins will always be returned from topdown re entityType.

sub getHierarchical {
    my $self = shift;

    my %params       = @_;
    my $dbh          = $params{'dbh'};
    my $entityTypeID = $params{'entityTypeID'} || 0;
    my $entityID     = $params{'entityID'}     || 0;
    my $assocID      = $params{'assocID'}      || 0;
    my $upperLevel   = $params{'upperLevel'}   || 0;

    return undef if !$dbh or !$entityTypeID or !$entityID;
    return undef if $entityTypeID < $Defs::LEVEL_ASSOC and !$assocID;

    $upperLevel ||= $Defs::LEVEL_NATIONAL;

    return if $upperLevel < $entityTypeID;

    $assocID = $entityID if $entityTypeID == $Defs::LEVEL_ASSOC;

    my %Data = ();

    $Data{'db'} = $dbh;
    $Data{'clientValues'}{'assocID'} = $assocID if $assocID;

    my $entityStructure = getEntityStructure(\%Data, $entityTypeID, $entityID, $upperLevel, 1);

    my @esIds = ();

    foreach my $entityArr (@$entityStructure) {
        push @esIds, @$entityArr[1];
    }

    my %where = (intActive=>1, intEntityID=>{-in=>[@esIds]});
    my @order = ({-desc=>'intEntityTypeID'}, 'intDisplayOrder', 'intOptinID');

    my $optinObjs = $self->getList(dbh=>$dbh, where=>\%where, order=>\@order);

    return $optinObjs;
}

1;
