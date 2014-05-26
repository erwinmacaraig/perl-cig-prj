package EntityUtils;

require Exporter;
@ISA = qw(Exporter);

@EXPORT = @EXPORT_OK = qw(
    get_entity_parent_nodes 
    get_current_entity_info 
    get_parent_entity_info 
    get_entity_list
    get_entity_select_options
    get_entity_realm_info
);

use strict;
use warnings;
use lib '.', '..';

use Reg_common;
use Utils;
use DBUtils;
use Singleton;
use Log;
use Data::Dumper;

#
# Get entity parent nodes
#
# Params: 
#   enenty_type_id: Entity type defined in Defs: team - 2, club - 3, assoc - 5, ...
#   entity_id: Entity ID
#   extra: list of key, could be club_id, assoc_id for level member or below
#
# Result:
#   parent nodes array refs, each item is like [entity_type, ENTITY_ID]
#
# Example: get_entity_parent_nodes(5, 14291)
#   return [ [ 10, 3884 ], [ 20, 3877 ], [ 30, 3870 ], [ 100, 3868 ] ]
#
sub get_entity_parent_nodes {
    my ($entity_type, $entity_id, $extra) = @_;
    DEBUG "($entity_type, $entity_id), ", Dumper($extra);
    return [] if !$entity_type or !$entity_id;

    my $top_lookup_level = $extra->{'top_lookup_level'} || $Defs::LEVEL_NATIONAL;

    my @result = ();

    # try to fetch from cache
    my $cache = get_cache();
    my $cache_key = "ENTITY_PARENT_${entity_type}_${entity_id}";
    if ($cache) {
        my $c = $cache->get('swm', $cache_key);
        if ($c) {
            for my $item (@{$c}) {
                last if ($item->[0] > $top_lookup_level);
                push @result, $item;
            }

            return \@result;
        }
    }

    my $dbh = get_dbh();
    my $assoc_id = 0;

    if ($entity_type <= $Defs::LEVEL_ASSOC) {
        if ($entity_type == $Defs::LEVEL_MEMBER) {
            if (exists $extra->{'club_id'}) {
                $entity_type = $Defs::LEVEL_CLUB;
                $entity_id = $extra->{'club_id'};
                push @result, [$entity_type, $entity_id];
            }
            elsif (exists $extra->{'assoc_id'}) {
                $entity_type = $Defs::LEVEL_ASSOC;
                $entity_id = $extra->{'assoc_id'};
                push @result, [$entity_type, $entity_id];
            }
        } 

        if ($entity_type == $Defs::LEVEL_ASSOC) {
            $assoc_id = $entity_id;
        } 
        elsif ($entity_type == $Defs::LEVEL_CLUB) {
            $assoc_id = query_value(qq[
                SELECT intAssocID FROM tblAssoc_Clubs WHERE intClubID=?
            ], $entity_id);
            push @result, [$Defs::LEVEL_ASSOC, $assoc_id];
        }
        elsif ($entity_type == $Defs::LEVEL_TEAM) {
            my $row = query_one(qq[
                SELECT ac.intAssocID, t.intClubID
                FROM tblAssoc_Clubs ac
                JOIN tblTeam t ON ac.intClubID = t.intClubID
                WHERE t.intTeamID = ?
            ], $entity_id);
            $assoc_id = $row->{'intAssocID'};
            push @result, [$Defs::LEVEL_CLUB, $row->{'intClubID'}];
            push @result, [$Defs::LEVEL_ASSOC, $assoc_id];
        }
        else {
            WARN "trying get entity parent structure from a not supported level";
            return [];
        }
        
        my $row = query_one(qq[SELECT * FROM tblTempNodeStructure WHERE intAssocID=?], $assoc_id);
        for my $level (10, 20, 30, 100) {
            push @result, [$level, $row->{"int${level}_ID"}];
        }
    }
    else {
        my $node_id = $entity_id;
        for my $level (10, 20, 30, 100) {
            next if $level <= $entity_type;
            last if $top_lookup_level and $level > $top_lookup_level;
            $node_id = query_value(qq[
                SELECT intParentNodeID FROM tblNodeLinks 
                WHERE intChildNodeID=$node_id AND intPrimary=1
                ]);
            push @result, [$level, $node_id];
        }
    }

    # filter result by top_lookup_level
    @result = grep {$_->[0] <= $top_lookup_level} @result if $top_lookup_level;

    # convert the id from string to integer
    for my $item (@result) {
        $item->[1] = 0 + $item->[1] || 0;
    }

    # set the cache
    if ($cache) {
        my $group = "ENTITY_PARENT_${entity_type}_${entity_id}";
        $cache->set('swm', $cache_key, \@result, $group, 60*60*8);
    }

    #DEBUG "Node: ($entity_type, $entity_id), Parent: ", Dumper(\@result);
    return \@result;
}


sub get_current_entity_info {
    my ($data, $extra) = @_;

    my $entity_type = $data->{'clientValues'}{'currentLevel'};
    if (not $entity_type) {
        WARN "!! data->{'clientValues'}{'currentLevel'} is empty";
    }

    my $entity_id = 0;
    if ($extra->{'from'}) {
        for my $level (
            $Defs::LEVEL_MEMBER,
            $Defs::LEVEL_TEAM,
            $Defs::LEVEL_CLUB,
            $Defs::LEVEL_COMP,
            $Defs::LEVEL_ASSOC,
            $Defs::LEVEL_ZONE,
            $Defs::LEVEL_REGION,
            $Defs::LEVEL_STATE,
            $Defs::LEVEL_NATIONAL,
            $Defs::LEVEL_INTZONE,
            $Defs::LEVEL_INTREGION,
            $Defs::LEVEL_INTERNATIONAL,
        ) {
            next if $level < $extra->{'from'};

            $entity_type = $extra->{'from'};
            $entity_id = getID($data->{'clientValues'}, $entity_type);

            last if $entity_id > 0;
        }
    }
    else {
        $entity_id = getID($data->{'clientValues'}, $entity_type);
    }
    return ($entity_type, $entity_id, $data->{'Realm'}, $data->{'RealmSubType'});
}

sub get_parent_entity_info {
    my ($data, $extra) = @_;

    my ($entity_type, $entity_id) = (exists $extra->{'entity_type'} and exists $extra->{'entity_id'})
        ? ($extra->{'entity_type'}, $extra->{'entity_id'})
        : get_current_entity_info($data);

    my $parents = get_entity_parent_nodes($entity_type, $entity_id);

    #DEBUG "CURRENT: ($entity_type, $entity_id), PARENT: ", Dumper($parents->[0]);;
    ($entity_type, $entity_id) = (0, 0);
    if (@$parents > 0) {
        ($entity_type, $entity_id) = @{$parents->[0]};
    }
    my ($realm_id, $sub_realm_id) = get_entity_realm_info($entity_type, $entity_id);

    return ($entity_type, $entity_id, $realm_id, $sub_realm_id);
}

#
# return entity list in form { $id => $name, ... }
#
sub get_entity_list {
    my ($data, $entity_type_id) = @_;
    my $result = []; 

    if ($entity_type_id == $Defs::LEVEL_CLUB) {
        $result = query_data(qq [
            SELECT  
                c.intClubID AS k, c.strName AS v
            FROM
                tblClub c
            JOIN tblAssoc_Clubs ac 
                ON c.intClubID = ac.intClubID AND ac.intAssocID = ? 
            WHERE 
                c.intRecStatus >= 0 
            ORDER BY
                c.strName
            ], $data->{'clientValues'}{'assocID'});
    } 
    elsif ($entity_type_id == $Defs::LEVEL_ASSOC) {
        $result = query_data(qq [
            SELECT 
                a.intAssocID AS k, a.strName AS v
            FROM    
                tblAssoc a
            WHERE   
                a.intRecStatus >= 0 AND a.intRealmID = ? 
            ORDER BY
                a.strName
            ], $data->{'Realm'});
    }
    else {
        # TODO: get other entity list
    }

    DEBUG "ENTITY LIST of $entity_type_id", Dumper($result);
    return $result;
}

sub get_entity_select_options {
    my ($data, $entity_type_id) = @_;
    my $result = get_entity_list($data, $entity_type_id); 
    $result = hash_list_to_hash($result, 'k', 'v');
    return $result;
}

sub get_entity_realm_info {
    my ($entity_type, $entity_id);

    my $row = query_one(qq[
        SELECT * FROM viewEntity 
        WHERE intEntityTypeID=? AND intEntityID=?
        ], $entity_type, $entity_id);

    return $row ? ($row->{'intRealmID'}, $row->{'intSubRealmID'}) : (0, 0);
}

1;
# vim: set et sw=4 ts=4:
