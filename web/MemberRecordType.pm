package MemberRecordType;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = @EXPORT_OK = qw(
    handle_member_record_types
    get_mrt_list_for_entity 
    get_mrt_list_in_realm
    get_mrt_list_of_current_level
    get_mrt_list_of_parent_level
    get_mrt_select_options
    get_mrt_select_list
    get_parent_mrt_select_options
    get_parent_mrt_select_list
    get_parent_mrt_list_by_type
    get_mrt_config
    get_current_mrt_config
);

use strict;

use lib '.', "..";
use Data::Dumper;

use Defs;
use HTMLForm;
use GridDisplay;
use Reg_common;
use EntityUtils;
use DBUtils;
use Utils;
use Singleton;
use Log;


sub handle_member_record_types {
    my ($action, $data) = @_;

    if ($action eq 'MRT_ADMIN_LIST') {
        return gen_mrt_grid_html($data);

    } elsif ($action eq 'MRT_ADMIN_VIEW') {
        return gen_mrt_form_html($data, $action);

    } elsif ($action eq 'MRT_ADMIN_EDIT') {
        return gen_mrt_form_html($data, $action);

    } else {
        return ( "<b>Unknown action $action</b>", "Error");
    }
}

sub gen_mrt_grid_html {
    my ($data) = @_;
    my $lang = $data->{'lang'};
    my $client = setClient($data->{'clientValues'});

    my @headers = (
        {
            type => 'Selector',
            field => 'SelectLink',
        },
        {
            name => $lang->txt('Member Record Type'),
            field => 'strName',
        },
        {
            name => $lang->txt('Parent Member Record Type'),
            field => 'strParentMemberRecordTypeName',
        },

        ($data->{'SystemConfig'}{'EnableMemberRecordType-Linkable'}) ?
        {
            name => $lang->txt('Linkable'),
            field => 'intLinkable',
            type => 'tick',
        } : (),

        {
            name => $lang->txt('Parent Level'),
            field => 'intParentEntityTypeID',
        },
        {
            name => $lang->txt('Parent Entity ID'),
            field => 'intParentEntityID',
        },
#        {
#            name => $lang->txt('Parent Entity Type'),
#            field => 'strParentEntityType',
#        },
#        {
#            name => $lang->txt('Parent Entity Name'),
#            field => 'strParentEntityName',
#        },
        {
            name => $lang->txt('Notes'),
            field => 'strNote',
        },
    );

    my $rowdata = get_mrt_list_of_current_level($data, {strict=>1});
    for my $row (@$rowdata) {
        my $link = get_page_url($data, {
                a => "MRT_ADMIN_EDIT", 
                mrt_id => $row->{'intMemberRecordTypeID'}, 
            });
        $row->{'SelectLink'} = "$link";
        $row->{'id'} = $row->{'intMemberRecordTypeID'};
    }

    my $mrt_grid = showGrid(
        Data    => $data,
        columns => \@headers,
        rowdata => $rowdata,
        width   => '99%',
        client  => $client,
        simple  => 0,
    );

    my $addlink=qq[<span class = "button-small generic-button"><a href="$data->{'target'}?client=$client&amp;a=MRT_ADMIN_EDIT">Add</a></span>];
    my $title = qq[Member Record Types <div class="changeoptions">$addlink</div>];

    return ($mrt_grid, $title);
}

sub get_mrt_fields_def {
    my ($data, $action, $id) = @_;

    my $readonly = ($action eq 'MRT_ADMIN_EDIT') ? 0 : 1;
    my $client = setClient($data->{'clientValues'});

    my $field = ($id) ? get_mrt_list_of_current_level($data, {id=>$id})->[0] : {};
    my ($entity_type, $entity_id) = get_current_entity_info($data);

    my $fields_def = {
        fields => {
            strName => {
                label => 'Type Name',
                value => $field->{'strName'},
                type  => 'text',
                compulsory => 1,
                size  => '40',
                sectionname => 'details',
            },

            intMemberRecordTypeParentID => {
                label => 'Parent Type',
                type  => 'lookup',
                value => $field->{'intMemberRecordTypeParentID'},
                compulsory => 1,
                options => get_parent_mrt_select_options($data, { linkable => 1 }),
                sectionname => 'details',
                readonly => ($id) ? 1 : 0,
            },

            ($data->{'SystemConfig'}{'EnableMemberRecordType-Linkable'}) ?
            (intLinkable => {
                label => 'Linkable',
                type  => 'checkbox',
                default => 1,
                value => $field->{'intLinkable'},
                sectionname => 'details',
                displaylookup => {1 => 'Yes', 0 => 'No'},
            }) : (),
        },

        order => [qw/ strName intMemberRecordTypeParentID intLinkable /],
        options => {
            labelsuffix => ':',
            hideblank => 1,
            target => $data->{'target'},
            view_url => get_page_url($data, {'a'=>'MRT_ADMIN_LIST'}),
            submitlabel => "Submit",
            updateSQL => qq [
                UPDATE tblMemberRecordType
                SET --VAL--
                WHERE intMemberRecordTypeID = $id
            ],
            addSQL => qq [
                INSERT INTO tblMemberRecordType
                (
                    intEntityTypeID, intEntityID, intRealmID, intSubRealmID, dtCreated, 
                    --FIELDS--
                )
                VALUES
                (
                    $entity_type, $entity_id, $data->{'Realm'}, $data->{'RealmSubType'}, SYSDATE(), 
                    --VAL--
                )
            ],
        },
        sections => [
            ['details', 'Details'],
        ],
        carryfields => {
            client => $client,
            a => $action,
            mrt_id => $id,
        },
    };

    return $fields_def;
}

sub gen_mrt_form_html {
    my ($data, $action) = @_;
    my $mrt_id = safe_param('mrt_id');

    my $mode;
    $mode = 'display' if ($action eq 'MRT_ADMIN_VIEW');
    $mode = 'add' if ($action eq 'MRT_ADMIN_EDIT' and not $mrt_id);
    $mode = 'edit' if ($action eq 'MRT_ADMIN_EDIT' and $mrt_id);

    my $fields_def = get_mrt_fields_def($data, $action, $mrt_id);
    my ($resultHTML, undef) = handleHTMLForm($fields_def, undef, $mode, '', get_dbh(), undef);

    return ($resultHTML, "Member Record Type");
}


#######################################################################
#
# Member Record Type helper funtions
#
#######################################################################

sub get_mrt_list {
    my ($entity_type, $entity_id, $extra) = @_;

    my $sql = qq[
        SELECT mrt.*, 
#            ep.strEntityTypeName AS strParentEntityType,
#            ep.strEntityName AS strParentEntityName,
            mrtp.strName AS strParentMemberRecordTypeName,
            mrtp.intEntityTypeID AS intParentEntityTypeID,
            mrtp.intEntityID AS intParentEntityID
        FROM tblMemberRecordType mrt
        LEFT JOIN tblMemberRecordType mrtp
            ON mrt.intMemberRecordTypeParentID = mrtp.intMemberRecordTypeID
#        LEFT JOIN viewEntity ep 
#            ON ep.intEntityTypeID = mrtp.intEntityTypeID AND ep.intEntityID = mrtp.intEntityID
        WHERE mrt.intStatus = 0 
            AND mrt.intEntityTypeID = ?
            AND mrt.intEntityID = ?
    ];

    if (exists $extra->{'realm'}) {
        $sql .= qq[ AND mrt.intRealmID = $extra->{'realm'} ];
    }
    if (exists $extra->{'subrealm'}) {
        $sql .= qq[ AND mrt.intSubRealmID = $extra->{'subrealm'} ];
    }
    if ($extra->{'EnableMemberRecordType-Linkable'}) {
        if (exists $extra->{'linkable'}) {
            $sql .= qq[ AND mrt.intLinkable = $extra->{'linkable'} ];
        }
    }
    if (exists $extra->{'id'}) {
        $sql .= qq[ AND mrt.intMemberRecordTypeID = $extra->{'id'} ];
    }

    my $result = query_data($sql, $entity_type, $entity_id);
    # TODO: post-process for mrt list
    return $result;
}

#
# "strict" option: 
#   True  - only search in current level, 
#   False - go up and search in parent level when no data found
#
# "with_god_node" option:
#   True  - the "No Parent" node is included in result when no data found
#   False - no "No Parent" node in result when no data found
#
# "TopParentLevel" option: defined in tblMemberRecordTypeConfig, use this to
# stop searching MRT in parent nodes at the specific level 
#
sub get_mrt_list_for_entity {
    my ($entity_type, $entity_id, $extra) = @_;
    DEBUG "LOOKUP MRT FOR $entity_type, $entity_id", Dumper($extra);

    if (exists $extra->{'top_lookup_level'} and $entity_type > $extra->{'top_lookup_level'}) {
        return [];
    }

    my $result = get_mrt_list($entity_type, $entity_id, $extra);

    # if no result found and not in "strict" mode, then keep trying to find
    # out the mrt in parent level until found something or reach top level
    if (@$result == 0 and not $extra->{'strict'}) {
        my $parents = get_entity_parent_nodes($entity_type, $entity_id, {
            exists $extra->{'top_lookup_level'} ? 
                (top_lookup_level => $extra->{'top_lookup_level'}) : 
                (),
            });

        DEBUG "Gona search in parent nodes: ", Dumper($parents);
        for my $node ( @$parents ) {
            $result = get_mrt_list($node->[0], $node->[1], $extra);
            return $result if (@$result > 0);
        }

        # no data available in parent levels, trying to find default node of realm
        # TODO: need to clarify the definition of "default realm'
        #if (@$result == 0) {
        #    $result = get_mrt_list_for_entity(0, 0, {
        #            realm => $extra->{'realm'}, 
        #            subrealm => $extra->{'subrealm'},
        #            strict => 1,
        #        });
        #}

        # return the GOD node if needed, this node should be initialized when create 
        # the table, the id and parent id are -1, all other fields are 0
        if (@$result == 0 and $extra->{'with_god_node'}) {
            $result = get_mrt_list(0, 0, {id=>-1, realm=>0, subrealm=>0});
        }
    }

    return $result;
}


# find mrt list of given entity in given realm or runtime entity realm
sub get_mrt_list_in_realm {
    my ($data, $entity_type, $entity_id, $extra) = @_;
    $extra ||= {};
    set_extra_feature_config($data, $extra);

    $extra->{'realm'} = $data->{'Realm'} if not exists $extra->{'realm'};
    $extra->{'subrealm'} = $data->{'RealmSubType'} if not exists $extra->{'subrealm'};

    return get_mrt_list_for_entity($entity_type, $entity_id, $extra);
}


# find mrt list of current entity in current realm
sub get_mrt_list_of_current_level {
    my ($data, $extra) = @_;
    $extra ||= {};

    my ($entity_type, $entity_id) = get_current_entity_info($data);

    # a member could belong to multiple club or assoc, so if current level is
    # LEVEL_MEMBER, we need to find out which club or assoc this member belong to
    if ($entity_type == $Defs::LEVEL_MEMBER) {
        if ($data->{'clientValues'}{'clubID'} > 0) {
            $entity_type = $Defs::LEVEL_CLUB;
            $entity_id = $data->{'clientValues'}{'clubID'};
        }
        elsif ($data->{'clientValues'}{'assocID'} > 0) {
            $entity_type = $Defs::LEVEL_ASSOC;
            $entity_id = $data->{'clientValues'}{'assocID'};
        }
    }

    return get_mrt_list_in_realm($data, $entity_type, $entity_id, $extra);
}


# find the mrt list of parent level by given entity info or runtime parent entity info
sub get_mrt_list_of_parent_level {
    my ($data, $extra) = @_;
    $extra ||= {};

    my ($entity_type, $entity_id) = (exists $extra->{'entity_type'} and exists $extra->{'entity_id'})
    ? ($extra->{'entity_type'}, $extra->{'entity_id'})
    : get_parent_entity_info($data);

    return get_mrt_list_in_realm($data, $entity_type, $entity_id, $extra);
}


#
# This method usually used when adding a member record and get available
# member record types of member.
# 
# Will check the config TopLookupLevel
#
sub get_mrt_select_options {
    my ($data, $extra) = @_;
    my $mrt_list = get_mrt_select_list($data, $extra);
    return hash_list_to_hash($mrt_list, 'intMemberRecordTypeID', 'strName');
}

sub get_mrt_select_list {
    my ($data, $extra) = @_;
    $extra ||= {};

    my ($entity_type, $entity_id) = (exists $extra->{'entity_type'} and exists $extra->{'entity_id'})
    ? ($extra->{'entity_type'}, $extra->{'entity_id'})
    : get_current_entity_info($data);

    # get the config for destination entity
    my $config = get_mrt_config($entity_type, $entity_id, $extra->{'realm'}, $extra->{'subrealm'});

    if (exists $config->{'TopLookupLevelForEntity'}) {
        $extra->{'top_lookup_level'} = $config->{'TopLookupLevelForEntity'};
    }

    my $mrt_list = get_mrt_list_in_realm($data, $entity_type, $entity_id, $extra);

    return $mrt_list;
}

#
# This method usually only be used when create a new member record type, two options 
# will be checked in this method: AllowToCreateRootNode and TopParentLevel
#
# AllowToCreateRootNode: is current level allowed to create a new member record
# type, if it is then the "No Parent" node will show up in parent node listbox
# when no parent node found.
#
# TopParentLevel: which level should stop at when finding the parent nodes,
# e.g. if this is set to 100 then the search will stop at National level, if
# nothing found then return an empty list or one "No Parent" node in list when
# AllowToCreateRootNode is set
#
sub get_parent_mrt_select_options {
    my ($data, $extra) = @_;
    my $mrt_list = get_parent_mrt_select_list($data, $extra);
    return hash_list_to_hash($mrt_list, 'intMemberRecordTypeID', 'strName');
}

sub get_parent_mrt_select_list {
    my ($data, $extra) = @_;

    # setup entity 
    my ($curr_entity_type, $curr_entity_id);
    if (exists $extra->{'entity_type'} and exists $extra->{'entity_id'}) {
        ($curr_entity_type, $curr_entity_id) = ($extra->{'entity_type'}, $extra->{'entity_id'});
        ($extra->{'realm'}, $extra->{'realm'}) = get_entity_realm_info($curr_entity_type, $curr_entity_id);
    }
    else {
        ($curr_entity_type, $curr_entity_id) = get_current_entity_info($data);
        $extra->{'realm'} = $data->{'Realm'} if not exists $extra->{'realm'};
        $extra->{'subrealm'} = $data->{'RealmSubType'} if not exists $extra->{'subrealm'};
    }


    # setup realm 
    my $config = get_mrt_config($curr_entity_type, $curr_entity_id, $extra->{'realm'}, $extra->{'subrealm'});

    # convert MRT Config
    if (exists $config->{'AllowToCreateRootNode'}) {
        $extra->{'with_god_node'} = $config->{'AllowToCreateRootNode'};
    }

    if (exists $config->{'TopLookupLevelForParent'}) {
        $extra->{'top_lookup_level'} = $config->{'TopLookupLevelForParent'};
    }

    # lookup parent mrt list
    my ($entity_type, $entity_id) = get_parent_entity_info($data, {
            entity_type => $curr_entity_type,
            entity_id   => $curr_entity_id,
        });
    my $mrt_list = get_mrt_list_in_realm($data, $entity_type, $entity_id, $extra);
    return $mrt_list;
}

sub get_current_mrt_config {
    my ($data) = @_;
    return get_mrt_config(get_current_entity_info($data));
}

sub get_mrt_config {
    my ($entity_type, $entity_id, $realm_id, $subrealm_id) = @_;
    $entity_id ||= 0;
    $realm_id ||= 0;
    $subrealm_id ||= 0;

    #TODO: add cache support
    
    my $data = query_data(qq[
        SELECT * FROM tblMemberRecordTypeConfig
        WHERE intEntityTypeID = ? AND intEntityID IN (0, ?) 
            AND intRealmID IN (0, ?) AND intSubRealmID IN (0, ?)
        ORDER BY intEntityTypeID DESC, intRealmID, intSubRealmID, intEntityID
        ], $entity_type, $entity_id, $realm_id, $subrealm_id);

    my $result = hash_list_to_hash($data, 'strName', 'strValue');
    DEBUG "MRT Config for ($entity_type, $entity_id, $realm_id, $subrealm_id): ", Dumper($result);
    return $result;
}

sub set_extra_feature_config {
    my ($data, $extra) = @_;
    $extra->{'EnableMemberRecordType-Linkable'} = 
        $data->{'SystemConfig'}{'EnableMemberRecordType-Linkable'};
}

sub get_parent_mrt_list_by_type {
    my ($mrt_id) = @_;

    my $type = query_one(qq[
        SELECT * FROM tblMemberRecordType
        WHERE intMemberRecordTypeID = ?
        ], $mrt_id);

    my @result = ();
    while ( 1 ) {
        last if $type->{'intMemberRecordTypeParentID'} <= 0;

        $type = query_one(qq[
            SELECT * FROM tblMemberRecordType
            WHERE intMemberRecordTypeID = ?
            ], $type->{'intMemberRecordTypeParentID'});

        push @result, $type;
    }

    return \@result;
}

1;
# vim: set et sw=4 ts=4:
