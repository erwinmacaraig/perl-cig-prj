package MemberRecords;

require Exporter;
@ISA =  qw(Exporter);
@EXPORT = @EXPORT_OK = qw(
    handle_member_records 
    create_member_records
);

use strict;
use lib '.', "..";

use Data::Dumper;

use Defs;
use Reg_common;
use FieldLabels;
use Seasons;
use GridDisplay;
use HTMLForm;
use FormHelpers;
use JSON;
use AuditLog;
use MemberRecordType;
use EntityUtils;
use Singleton;
use Utils;
use DBUtils;
use Log;

my $ACTION_LIST_VIEW = 'MR_LIST';
my $ACTION_RECORD_VIEW = 'MR_VIEW';
my $ACTION_RECORD_EDIT = 'MR_EDIT';

sub handle_member_records {
    my ($action, $data) = @_;

    if ($action eq $ACTION_LIST_VIEW ) {
        return gen_member_record_grid_html($data);

    } elsif ($action eq $ACTION_RECORD_VIEW  ) {
        return ( gen_member_record_form($data, $action), "Member Record");

    } elsif ($action eq $ACTION_RECORD_EDIT) {
        return ( gen_member_record_form($data, $action), "Member Record");

    } else {
        return ( "<b>Unknown action $action</b>", "Error");
    }
}

sub hasEditPermission {
    my ($data, $level) = @_;
    return (not $data->{'ReadOnlyLogin'} 
            and $data->{'clientValues'}{'authLevel'} >= $level); 
}

sub get_member_records_tablename_for_realm {
    my $data = shift;
    my $realm_id = $data->{'Realm'};
    return "tblMemberRecords_${realm_id}";
}   

sub get_default_age_group_id {
    my ($data, $member_id) = @_;
    my $dbh = $data->{'db'} || undef;
    my $realm_id = $data->{'Realm'};
    my $assoc_id = $data->{'clientValues'}{'assocID'};
    my $sub_realm_id = $data->{'RealmSubType'} || 0;

    my $member = query_one(qq[SELECT * FROM tblMember m WHERE intMemberID = ?], $member_id);

    my $age_group_default = query_value(qq[
        SELECT 
            intAgeGroupID
        FROM 
            tblAgeGroups
        WHERE 
            intRealmID = $realm_id
            AND (intAssocID=$assoc_id OR intAssocID =0)
            AND (intRealmSubTypeID = $sub_realm_id OR intRealmSubTypeID = 0)
            AND intRecStatus >= 0
            AND dtDOBStart < ?
            AND dtDOBEnd > ?
    ], $member->{'dtDOB'}, $member->{'dtDOB'});

    return $age_group_default;
}

sub get_member_record_list {
    my ($data, $extra) = @_;

    my $member_id = $data->{'clientValues'}{'memberID'};
    my $tablename = get_member_records_tablename_for_realm($data);
    my $filter_sql = '';

    if (exists $extra->{'id'}) {
        $filter_sql = qq[ AND intMemberRecordID = $extra->{'id'} ];
    }

    # prepare the data for grids
    my $sql =  qq {
        SELECT 
            mr.intMemberRecordID,
            sa.strSeasonName, 
            mrt.strName, 
            e.strEntityTypeName,
            e.strEntityName,
            ag.strAgeGroupDesc, 
            mr.*
        FROM $tablename mr
        LEFT JOIN tblMemberRecordType mrt 
            ON mr.intMemberRecordTypeID = mrt.intMemberRecordTypeID
        LEFT JOIN tblSeasons sa 
            ON mr.intSeasonID = sa.intSeasonID
        LEFT JOIN tblAgeGroups ag 
            ON mr.intAgeGroupID = ag.intAgeGroupID
        LEFT JOIN viewEntity e
            ON mr.intEntityID = e.intEntityID and mr.intEntityTypeID = e.intEntityTypeID
        WHERE 
            mr.intRecStatus >= 0 AND intMemberID = $member_id
            #AND intRefMemberRecordID = 0
            $filter_sql
        ORDER BY
            sa.strSeasonName DESC, 
            mrt.strName, 
            intEntityTypeID
    };

    return query_data($sql);
}

sub gen_member_record_grid_html {
    my ($data) = @_;
    my $client = setClient($data->{'clientValues'});

    my $member_id = $data->{'clientValues'}{'memberID'};
    my $lang = $data->{'lang'};
    my $result_html = '';

    # make data for grids
    my $level_data = {};
    my @rowdata_all = ();

    my $result = get_member_record_list($data);
    for my $row (@$result) {
        $row->{'SelectLink'} = get_page_url($data, {
                a     => $ACTION_RECORD_EDIT,
                mr_id => $row->{'intMemberRecordID'}
            });
        $row->{'id'} = $row->{'intMemberRecordID'};

        push (@rowdata_all, $row);

        my $level = sprintf("%05d_%s", $row->{'intEntityTypeID'}, $row->{'strEntityTypeName'});
        if (not exists $level_data->{$level}) {
            $level_data->{$level} = ();
        }
        push @{$level_data->{$level}}, $row;
    }

    # headers of grids
    my @header = (
#        {
#            name  => $lang->txt('Ref'),
#            field => 'intRefMemberRecordID',
#            type => 'tick',
#        },
        {
            name  => $lang->txt('Season'),
            field => 'strSeasonName',
        },
        {
            name  => $lang->txt('Type'),
            field  => 'strName',
        },
        {
            name  => $lang->txt('Age Group'),
            field  => 'strAgeGroupDesc',
        },
        {
            name  => $lang->txt('In'),
            field  => 'dtIn',
        },
        {
            name  => $lang->txt('Out'),
            field  => 'dtOut',
        },
        {
            name  => $lang->txt('Financial'),
            field  => 'intFinancialStatus',
            type => 'tick',
        },
        {
            name  => $lang->txt('From Rego Form'),
            field  => 'intFromRegoForm',
            type => 'tick',
        },
        {
            name  => $lang->txt('Status'),
            field  => 'intStatus',
            type => 'tick',
        },
    );


    # for each level in data
    for my $level (sort keys %$level_data) {
        my ($level_id, $level_name) = split('_', $level);

        my @header_level = @header;
        if (hasEditPermission($data, $level_id)) { 
            @header_level = (
                {
                    type => 'Selector',
                    field => 'SelectLink',
                }, @header_level);
        }

        my $record_grid_html = showGrid(
            Data    => $data,
            columns => \@header_level,
            rowdata => $level_data->{$level},
            gridid  => "grid_$level",
            width   => '99%',
            simple  => 1,
        );

        $result_html .= qq[
        <div class="sectionheader">$level_name Summary</div>
        <div id="${level}_records"> $record_grid_html </div>
        <br/>
        ];
    }

    # generate HTML for all-data grid
    my @header_all = (
        {
            name  => $lang->txt('Level'),
            field  => 'strEntityTypeName',
        },
        {
            name  => $lang->txt('Entity'),
            field  => 'strEntityName',
        },
        @header,
    );
    my $record_grid_html = showGrid(
        Data  => $data,
        columns  => \@header_all,
        rowdata  => \@rowdata_all,
        gridid  => 'record_all',
        width  => '99%',
        simple  => 1,
    );

    $result_html .= qq[
    <div class="sectionheader">All Summary</div>
    <div id="all_records"> $record_grid_html </div>
    <br/>
    ];

    my $title = "Member Records Summary";
    if (hasEditPermission($data, $Defs::LEVEL_ASSOC)) {
        my $url = get_page_url($data, {a=>$ACTION_RECORD_EDIT});
        $title .= qq[ <div class="changeoptions"> <span class = "button-small generic-button"><a href="$url">New  Season  Record</a></span> </div>] 
    }


    # combine and return the content HTML
    return ($result_html, $title);
}

sub get_form_fields_def {
    my ($data, $action, $mr_id) = @_;

    my $dbh = get_dbh();
    my $client = setClient($data->{'clientValues'});
    my $lang = $data->{'lang'};
    my $realm_id = $data->{'Realm'};
    my $sub_realm_id = $data->{'RealmSubType'} || 0;
    my $assoc_id = $data->{'clientValues'}{'assocID'};
    my $tablename = get_member_records_tablename_for_realm($data);
    my $member_id = $data->{'clientValues'}{'memberID'};

    # TODO: ? set form readonly if no permission to edit
    #$readonly = $readonly and hasEditPermission($data, $Defs::LEVEL_ASSOC);
    my $readonly = ($action eq $ACTION_RECORD_EDIT) ? 0 : 1;
    my $row = {};
    if ($mr_id) {
        my $result = get_member_record_list($data, {id=>$mr_id});
        $row = $result->[0];
    } 
    else {
        # setup the default entity value
        my ($entity_type, $entity_id) = get_current_entity_info($data, {from=>$Defs::LEVEL_CLUB});
        $row->{'intEntityTypeID'} = $entity_type;
        $row->{'intEntityID'} = $entity_id;
        $row->{'intSeasonID'} = safe_param('season_id');
    }

    #$readonly = $readonly or $data->{'SystemConfig'}{'LockSeasons'} ? 1 : 0;

    # prepare the dropdown listbox values for seasons
    my ($seasons_options, $seasons_order) = getDBdrop_down_Ref($dbh, qq[
        SELECT 
            intSeasonID, strSeasonName
        FROM
            tblSeasons
        WHERE 
            intRealmID = $realm_id
            AND (intAssocID=$assoc_id OR intAssocID = 0)
            AND (intRealmSubTypeID = $sub_realm_id OR intRealmSubTypeID = 0)
            AND intArchiveSeason <> 1
            AND intLocked <> 1
        ORDER BY
            intSeasonOrder, strSeasonName DESC
        ], '');

    # prepare the dropdown listbox values for age group
    my ($age_group_options, $age_group_order) = getDBdrop_down_Ref($dbh, qq[
        SELECT 
            intAgeGroupID, 
            IF(intRecStatus<1, 
                CONCAT(strAgeGroupDesc, ' (Inactive)'),  
                strAgeGroupDesc) AS strAgeGroupDesc
        FROM 
            tblAgeGroups
        WHERE 
            intRealmID = $realm_id
            AND (intAssocID=$assoc_id OR intAssocID =0)
            AND (intRealmSubTypeID = $sub_realm_id OR intRealmSubTypeID = 0)
            AND intRecStatus >= 0
        ORDER BY 
            strAgeGroupDesc
    ], '');

    my $age_group_default = get_default_age_group_id($data, $data->{'clientValues'}{'memberID'});

    my $entity_list_options = get_entity_select_options($data, $row->{'intEntityTypeID'});
    my $mrt_select_options = get_mrt_select_options($data, {
            entity_type => $row->{'intEntityTypeID'}, 
            entity_id   => $row->{'intEntityID'},
       });

    my ($assoc_options, $assoc_order) = getDBdrop_down_Ref($dbh, qq[
        SELECT 
            intMemberRecordTypeID, strName
        FROM
            tblMemberRecordType
        WHERE 
            intRealmID = $realm_id
            AND (intSubRealmID = $sub_realm_id OR intSubRealmID = 0)
            AND intRecStatus >= 0
        ORDER BY
            intMemberRecordTypeID, intMemberRecordTypeParentID, strName
        ], '');
    
    my ($club_options, $club_order) = getDBdrop_down_Ref($dbh, qq[
        SELECT 
            intMemberRecordTypeID, strName
        FROM
            tblMemberRecordType
        WHERE 
            intRealmID = $realm_id
            AND (intSubRealmID = $sub_realm_id OR intSubRealmID = 0)
            AND intRecStatus >= 0
        ORDER BY
            intMemberRecordTypeID, intMemberRecordTypeParentID, strName
        ], '');

    my $entity_type_options = {
        $Defs::LEVEL_CLUB => 'Club',
        $Defs::LEVEL_ASSOC => 'Association',
    };

    my $fields_def = {
        fields => {
            intSeasonID => {
                label => $lang->txt('Season'),
                value => $row->{'intSeasonID'},
                type => 'lookup',
                options => $seasons_options,
                firstoption => ['', ''],
                readonly => $readonly,
                sectionname => 'main',
            },
            intEntityTypeID => {
                label => $lang->txt('Entity Type'),
                value => $row->{'intEntityTypeID'},
                type => 'lookup',
                options => $entity_type_options,
                firstoption => ['', ''],
                disable => ($row->{'intEntityTypeID'} > 0),
                readonly => ($row->{'intEntityTypeID'} > 0 
                        and $row->{'intEntityID'} > 0),
                sectionname => 'main',
            },
            intEntityID => {
                label => $lang->txt('Entity'),
                value => $row->{'intEntityID'},
                type => 'lookup',
                options => $entity_list_options,
                firstoption => ['', ''],
                disable => ($row->{'intEntityID'} > 0),
                readonly => ($row->{'intEntityTypeID'} > 0 
                        and $row->{'intEntityID'} > 0),
                sectionname => 'main',
            },
            intMemberRecordTypeID => {
                label => $lang->txt('Type'),
                value => $row->{'intMemberRecordTypeID'},
                type => 'lookup',
                options => $mrt_select_options,
                firstoption => ['', ''],
                readonly => $readonly,
                sectionname => 'main',
            },
            intAgeGroupID => {
                label => $lang->txt('Age Group'),
                value => $row->{'intAgeGroupID'},
                type => 'lookup',
                options => $age_group_options,
                firstoption => ['', ''],
                readonly => $readonly,
                sectionname => 'main',
                default => $age_group_default,
            },
            dtIn => {
                label => $lang->txt('In'),
                value => $row->{'dtIn'},
                type => 'date',
                readonly => $readonly,
                sectionname => 'main',
                default => now_str(),
            },
            dtOut => {
                label => $lang->txt('Out'),
                value => $row->{'dtOut'},
                type => 'date',
                readonly => $readonly,
                sectionname => 'main',
            },
            intFinancialStatus => {
                label => $lang->txt('Financial'),
                value => $row->{'intFinancialStatus'},
                type => 'checkbox',
                displaylookup => {1 => 'Yes', 0 => 'No'},
                readonly => $readonly,
                sectionname => 'main',
            },
            intStatus => {
                label => $lang->txt('Status'),
                value => $row->{'intStatus'},
                type => 'checkbox', 
                displaylookup => {1 => 'Yes', 0 => 'No'}, 
                readonly => $readonly,
                sectionname => 'main',
                default => 1,
            },
        },

        order => [qw(
            intSeasonID
            intEntityTypeID
            intEntityID
            intMemberRecordTypeID
            intAgeGroupID
            dtIn
            dtOut
            intFinancialStatus
            intStatus
        )],

        options => {
            labelsuffix => ':',
            hideblank => 1,
            target => $data->{'target'},
            formname => 'record_form',
            submitlabel => 'Update Record',
            view_url => get_page_url($data, {a=>$ACTION_LIST_VIEW}),
            introtext => 'auto',
            noHTML => '1',
            updateSQL => qq[
                UPDATE $tablename
                SET --VAL--
                WHERE intMemberRecordID = $mr_id
            ],
            addSQL => qq[
                INSERT INTO $tablename
                (
                    dtCreated, 
                    intMemberID,
                    --FIELDS-- 
                )
                VALUES
                (   
                    SYSDATE(), 
                    $member_id,
                    --VAL-- 
                )
            ],
            auditFunction => \&auditLog,
            auditAddParams => [
                $data,
                'Add Member Record',
                'Record'
            ],

            afteraddFunction    => \&post_edit_function,
            afterupdateFunction => \&post_edit_function,
            afterupdateParams => [$data, $mr_id],

            auditEditParams => [
                $mr_id,
                $data,
                'Update Member Record',
                'Record'
            ],
        },
        carryfields =>  {
            client => $client,
            a => $action,
            mr_id => $mr_id,
        },
    };

    return $fields_def;
}

sub post_edit_function {
    DEBUG "POST EDIT Params: ", Dumper(\@_);
    my ( $id, $params, $data, $mr_id) = @_;
    if ($id > 0) {
        # after create a new record
        create_shadow_member_records($data, $id);
    }
    else {
        # after update record
        update_shadow_member_records($data, $mr_id);
    }
}

sub gen_member_record_form {
    my ($data, $action) = @_;
    my $mr_id = safe_param('mr_id', 'number');

    my $client = setClient($data->{'clientValues'});
    my $mode;
    $mode = 'display' if ($action eq $ACTION_RECORD_VIEW);
    $mode = 'add' if ($action eq $ACTION_RECORD_EDIT and not $mr_id);
    $mode = 'edit' if ($action eq $ACTION_RECORD_EDIT and $mr_id);

    my $fields_def = get_form_fields_def($data, $action, $mr_id);
    my ($resultHTML, undef) = handleHTMLForm($fields_def, undef, $mode, '', get_dbh(), undef);

    if ($action eq $ACTION_RECORD_EDIT) {
        $resultHTML .= qq [
        <script>
            function updateMemberRecordTypes() {
                \$('#l_intMemberRecordTypeID option').remove();

                var entity_id = \$("#l_intEntityID").val();
                var entity_type_id = \$("#l_intEntityTypeID").val();
                if (entity_id && entity_type_id) {
                    ajax_request("client=$client&key=mrt&entity_type_id="+entity_type_id+"&entity_id="+entity_id, 
                        function(data) {
                            update_options_for("#l_intMemberRecordTypeID", data);
                        });
                }
            }

            function updateEntityList() {
                \$('#l_intEntityID option').remove();
                var entity_type_id = \$("#l_intEntityTypeID").val();
                if (entity_type_id) {
                    ajax_request("client=$client&key=entity&entity_type_id="+entity_type_id, 
                        function(data) {
                            update_options_for("#l_intEntityID", data);
                        });
                }
                updateMemberRecordTypes();
            }
            \$("#l_intEntityTypeID").change(function() {
                updateEntityList();
            });
            \$("#l_intEntityID").change(function() {
                updateMemberRecordTypes();
            });
        </script>
        ];
    }

    return $resultHTML;
}

sub create_shadow_member_records {
    my ($data, $id) = @_;

    my $tablename = get_member_records_tablename_for_realm($data);
    my $row = query_one(qq[
        SELECT * FROM $tablename 
        WHERE intMemberRecordID = ? AND intRefMemberRecordID = 0
    ], $id);

    # create shadow record for each parent types
    # refMemberRecordID=[original record id]
    my $parent_types = get_parent_mrt_list_by_type($row->{'intMemberRecordTypeID'});
    DEBUG "create shadow records for $id, ParentTypes: ", Dumper($parent_types);

    for my $parent_type (@$parent_types) {
        $row->{'intMemberRecordID'} = undef;
        $row->{'intRefMemberRecordID'} = $id;
        $row->{'intEntityTypeID'} = $parent_type->{'intEntityTypeID'};
        $row->{'intEntityID'} = $parent_type->{'intEntityID'};
        $row->{'intMemberRecordTypeID'} = $parent_type->{'intMemberRecordTypeID'};

        db_save_data($tablename, $row, {key=>'intMemberRecordID'});
    }
}

sub update_shadow_member_records {
    my ($data, $id) = @_;

    my $tablename = get_member_records_tablename_for_realm($data);
    my $rows = query_data(qq[
        SELECT * 
        FROM $tablename 
        WHERE intMemberRecordID = ? OR intRefMemberRecordID = ?
    ], $id, $id);

    my @shadow_records = (); 
    my $row = {};

    for my $item (@$rows) {
        if ($item->{'intRefMemberRecordID'} == 0) {
            $row = $item;
        }
        else {
            push @shadow_records, $item->{'intMemberRecordID'};
        }
    }

    for my $id (@shadow_records) {
        $row->{'intMemberRecordID'} = $id;
        db_save_data($tablename, $row, {key=>'intMemberRecordID'});
    }
}

sub create_member_records {
    my ($data, $member_id, $record_type, $extra) = @_;

    my $tablename = get_member_records_tablename_for_realm($data);

    my ($entity_type, $entity_id) = get_current_entity_info($data);
    my $age_group = $extra->{'age_group'} || get_default_age_group_id($data, $member_id);
    my $default_season = Seasons::getDefaultAssocSeasons($data);
    my $season = $extra->{'season'} || $default_season->{'newRegoSeasonID'};
    my $regoform_id = $extra->{'regoform'};

    # insert a record for association
    my $sth = prepare_stat(qq {
            INSERT INTO $tablename
            (
                intRefMemberRecordID,
                intMemberRecordTypeID,
                intMemberID,

                intEntityTypeID,
                intEntityID,
                intSeasonID,
                intAgeGroupID,
                intFromRegoForm,
                intUsedRegoFormID,

                dtIn,
                dtCreated
            )
            VALUES
            (
                0, ?, ?, 
                ?, ?, ?, ?, ?, ?,
                SYSDATE(),
                SYSDATE()
            )
        } );

    my @types = (ref($record_type) eq 'ARRAY' ? @{$record_type} : ($record_type));
    for my $type (@types) {
        DEBUG "Create record for type $type in entity ($entity_type, $entity_id)";
        $sth->execute(
            $type, 
            $member_id, 

            $entity_type,
            $entity_id,
            $season, 
            $age_group,
            $regoform_id ? 1 : 0,
            $regoform_id,
        );
        my $id = $sth->{mysql_insertid};
        create_shadow_member_records($data, $id);
    }
}

1;
# vim: set et sw=4 ts=4:
