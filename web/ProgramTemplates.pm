#
# $Header: svn://svn/SWM/trunk/web/Venues.pm 10333 2013-12-18 23:54:25Z apurcell $
#

package ProgramTemplates;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(handle_program_templates );
@EXPORT_OK = qw(handle_program_templates );

use strict;
use Reg_common;
use Utils;
use HTMLForm;
use AuditLog;
use CGI qw(unescape param);
use FormHelpers;
use GridDisplay;
use ProgramTemplateUtils;
use ProgramUtils;

use Log;
require RecordTypeFilter;
require ProgramTemplateObj;
use Data::Dumper;

sub handle_program_templates {
    my ( $action, $Data ) = @_;

    my $resultHTML = '';
    my $title      = '';
    
    if ( $action =~ /^PROGRAM_TEMPLATE_L/ ) {
    
        #List Program Templates
        my $tempResultHTML = '';
        ( $tempResultHTML, $title ) = list_program_templates($Data);
        $resultHTML .= $tempResultHTML;
    }
    else{
        # We will need to do something to a specific program template
        
        my $programTemplateID = param('programTemplateID') || param("id") || 0;
    
	    # create program template object
	    my $program_template_obj = ProgramTemplateObj->new(
	        'ID' => $programTemplateID,
	        'db' => $Data->{'db'},
	    );
	    
	    # load only if we have an ID
	    $program_template_obj->load() if $programTemplateID;
	    
	    if ( $program_template_obj->have_permission({'realm_id' => $Data->{'Realm'}, 'subrealm_id' => $Data->{'RealmSubType'} }) ){
	        # Have permission to this program template, do what you like
	        
		    if ( $action =~ /^PROGRAM_TEMPLATE_DT/ ) {
		        ( $resultHTML, $title ) = program_template_details( $action, $Data, $program_template_obj );
		    }
		    elsif ( $action =~ /^PROGRAM_TEMPLATE_DEL/ ) {
		        ($resultHTML,$title) = delete_program_template( $Data, $program_template_obj );
		    }
		    elsif ( $action =~ /^PROGRAM_TEMPLATE_P_D/ ){
		        ( $resultHTML, $title ) = program_template_permissions_display( $Data, $program_template_obj );
		    }
		    elsif ( $action =~ /^PROGRAM_TEMPLATE_P_U/ ){
		        ( $resultHTML, $title ) = program_template_permissions_update( $Data, $program_template_obj );
		    }
	    }
	    else{
	        # No permission, no soup for you!
	        $resultHTML = 'No access to this program template';
            $title = 'Program Template';
	    }
    }

    return ( $resultHTML, $title );
}

sub program_template_details {
    my ( $action, $Data, $program_template_obj ) = @_;

    my $option = 'display';
    
    my $programTemplateID = $program_template_obj->ID();
    
    if ($action eq 'PROGRAM_TEMPLATE_DTE' and allowedAction( $Data, 'programs_e' )) {
        $option = 'edit';
    }
    elsif ($action eq 'PROGRAM_TEMPLATE_DTA' and allowedAction( $Data, 'programs_a' )) {
        $option = 'add';
        $programTemplateID = 0;
    }

    my $client = setClient( $Data->{'clientValues'} ) || '';
    my ($program_template_singular, $program_template_plural) = get_program_template_titles($Data);
    my $intRealmID = $Data->{'Realm'} >= 0 ? $Data->{'Realm'} : 0;
    my $intSubRealmID = ($Data->{'RealmSubType'} && $Data->{'RealmSubType'} >= 0) ? $Data->{'RealmSubType'} : -1;
    
    my $after_add_link =  qq[<p style = "clear:both;"><a href="$Data->{'target'}?client=$client&amp;a=PROGRAM_TEMPLATE_P_D&amp;programTemplateID=__ID__">Click here</a> to Modify Program Permissions</p>];

    my %FieldDefinitions = (
        fields => _get_loaded_fields_config($Data, $program_template_obj),
        order => _get_field_order(),
        sections => [
            [ 'details',  "$program_template_singular Details" ], 
            [ 'age',      "Age Details"     ],
            [ 'session',  "Session Details" ],  
            [ 'product',  "Product Details" ],
            [ 'rego',     "Registration Form Details" ],
        ],
        options => {
            labelsuffix => ':',
            hideblank   => 1,
            target      => $Data->{'target'},
            formname    => 'n_form',
            submitlabel => ($option eq 'add') ? "Create $program_template_singular" : "Update $program_template_singular",
            introtext   => 'auto',
            NoHTML      => 1,
            updateSQL   => qq[
                UPDATE tblProgramTemplates
                SET --VAL--
                WHERE 
                    intProgramTemplateID = $programTemplateID
                    AND intRealmID = $intRealmID
            ],
            addSQL => qq[
                INSERT INTO tblProgramTemplates (
                    intRealmID,
                    intSubRealmID, 
                    --FIELDS-- 
                )
                VALUES (
                    $intRealmID, 
                    $intSubRealmID,
                    --VAL-- 
                )
            ],
            auditFunction   => \&auditLog,
            auditAddParams  => [ $Data, 'Add', 'Program Templates' ],
            auditEditParams => [ $programTemplateID, $Data, 'Update', 'Program Templates' ],
            LocaleMakeText  => $Data->{'lang'},
            addOKlink => $after_add_link, 
        },
        carryfields => {
            client  => $client,
            a       => $action,
            programTemplateID => $programTemplateID,
        },
    );


    my $resultHTML = '';
    ( $resultHTML, undef ) = handleHTMLForm( \%FieldDefinitions, undef, $option, '', $Data->{'db'} );
    my $template_name = $program_template_obj->name() || '';
    my $title = "$program_template_singular - $template_name";
    
    my $chgoptions = '';

    if ( $option eq 'edit' ) {
        $chgoptions .= qq[<span class = "button-small generic-button"><a href="$Data->{'target'}?client=$client&amp;a=PROGRAM_TEMPLATE_DEL&amp;programTemplateID=$programTemplateID" onclick="return confirm('Are you sure you want to delete this $program_template_singular');">Delete $program_template_singular</a> ] if $program_template_obj->canDelete();
    }

    $chgoptions = qq[<div class="changeoptions">$chgoptions</div>] if $chgoptions;
    $title = $chgoptions . $title;

    $title = "Add New $program_template_singular" if $option eq 'add';

    my $text = qq[<p style = "clear:both;"><a href="$Data->{'target'}?client=$client&amp;a=PROGRAM_TEMPLATE_L">Click here</a> to return to list of $program_template_plural</p>];
    $resultHTML = $text . $resultHTML . $text ;

    return ( $resultHTML, $title );
}

sub delete_program_template {
    my ($Data, $program_template_obj) = @_;

    my $client=setClient($Data->{'clientValues'}) || '';
    my ($program_template_singular, $program_template_plural) = get_program_template_titles($Data);
    
    my $result = $program_template_obj->delete();

    my $resultHTML = '';
    if ($result && $result !~/^ERROR/) {
        $resultHTML .= '<p class="OKmsg">' . $program_template_singular . ' successfully deleted.</p>';
        auditLog($program_template_obj->ID(), $Data, 'Delete', 'Program Template');
    }
    else {
        $resultHTML .= '<p class="warningmsg">Unable to delete ' . $program_template_singular .'<br>' . $program_template_singular . ' may have active programs.</p>';
    }

    $resultHTML .= qq[<p><a href="$Data->{'target'}?client=$client&amp;a=PROGRAM_TEMPLATE_L">Click here</a> to return to list of $program_template_plural</p>];

    return $resultHTML;
}

sub list_program_templates {
    my ($Data) = @_;

    my $resultHTML = '';
    my $client     = unescape( $Data->{client} );
    my ($program_template_singular, $program_template_plural) = get_program_template_titles($Data);
    
    my $intRealmID = $Data->{'Realm'} >= 0 ? $Data->{'Realm'} : 0;
    my $intSubRealmID = ($Data->{'RealmSubType'} && $Data->{'RealmSubType'} >= 0) ? $Data->{'RealmSubType'} : -1;
    
    my @where_clauses = ( 'intRealmID = ?', 'intStatus <> ?' );
    
    my @values = ($intRealmID , $Defs::RECSTATUS_DELETED);

    my @sub_realms = (-1);
    push @sub_realms, $intSubRealmID if ($intSubRealmID);
    
    push @where_clauses,  'intSubRealmID in ( ' . join(', ', map {'?'} @sub_realms) . ' )';
    push @values, @sub_realms; 
    my $where_statement = join(' AND ', @where_clauses);
     
    my $statement = qq[
        SELECT
          * 
        FROM 
          tblProgramTemplates
        WHERE 
          $where_statement
        ORDER BY 
          strTemplateName
    ];


    my $query = $Data->{'db'}->prepare($statement);
    $query->execute(@values);

    my %tempClientValues = getClient($client);

    my @rowdata    = ();
    my $tempClient = setClient( \%tempClientValues );

    while ( my $dref = $query->fetchrow_hashref() ) {
        my $programTemplateID = $dref->{intProgramTemplateID};

        my $config_link = qq[<a href="$Data->{'target'}?client=$tempClient&amp;a=PROGRAM_TEMPLATE_P_D&amp;programTemplateID=$programTemplateID">Edit</a>];

        push @rowdata, {
            id              => $programTemplateID   || next,
            strTemplateName => $dref->{'strTemplateName'}   || '',
            strProgramName  => $dref->{'strProgramName'}   || '',
            SelectLink =>"$Data->{'target'}?client=$tempClient&amp;a=PROGRAM_TEMPLATE_DTE&amp;programTemplateID=$programTemplateID",
            PermissionsLink => $config_link,
            intStatus  => $dref->{'intStatus'} || 0,

        };
    }

    my $addlink = '';
    my $title=qq[$program_template_plural];
    {
        $addlink = qq[<span class = "button-small generic-button"><a href="$Data->{'target'}?client=$tempClient&amp;a=PROGRAM_TEMPLATE_DTA">Add</a></span>];
    }

    my $modoptions = qq[<div class="changeoptions">$addlink</div>];
    $title = $modoptions . $title;
    my $rectype_options = RecordTypeFilter::show_recordtypes( $Data, 0, undef, undef, 'Name' ) || '';
    

    my @headers = (
        {
            type  => 'Selector',
            field => 'SelectLink',
        },
        {
            type  => 'HTML',
            name  => 'Permissions',
            field => 'PermissionsLink',
            width  => 40,
            
        },
        {
            name  => $Data->{'lang'}->txt( $program_template_singular . ' Name'), 
            field => 'strTemplateName',
        },
        {
            name   => $Data->{'lang'}->txt('Status'),
            field  => 'intStatus',
            editor => 'checkbox',
            type   => 'tick',
            width  => 30,
        },

    );

    my $filterfields = [
        {
            field     => 'strTemplateName',
            elementID => 'id_textfilterfield',
            type      => 'regex',
        },
        {
            field     => 'intStatus',
            elementID => 'dd_actstatus',
            allvalue  => '2',
        },
    ];

    my $grid = showGrid(
        Data    => $Data,
        columns => \@headers,
        rowdata => \@rowdata,
        gridid  => 'grid',
        width   => '99%',
        filters => $filterfields,
        client  => $client,
        saveurl => 'ajax/aj_grid_update.cgi',
        ajax_keyfield => 'intProgramTemplateID',
        saveaction => 'edit_program_template',
    );

    $resultHTML = qq[
        <div class="grid-filter-wrap">
            <div style="width:99%;">$rectype_options</div>
            $grid
        </div>
    ];

    return ( $resultHTML, $title );
}

sub program_template_permissions_display{
    my ($Data, $program_template_obj)=@_;
    
    #Load current permissions
    my $field_permissions = get_program_template_field_details({
        'dbh' => $Data->{'db'},
        'program_template_id' => $program_template_obj->ID(),
    });
    
    
    #Display the fields and permissions options
    my $field_config = _get_loaded_fields_config($Data, $program_template_obj);
    my $field_order = _get_field_order();

    my $unescclient = unescape($Data->{client});
    my $program_template_id = $program_template_obj->ID();
    
    my $title = 'Permissions for ' . $field_config->{'strTemplateName'}->{'value'};

    my $subBody = qq[
        <p></p>
        <form action="$Data->{'target'}" method="POST">
        <table class="permsTable">
            <tr>
                <td colspan="5" class="sectionheader">$title</td>
            </tr>
            <tr>
                <th>Field</th>
                <th>Current Value</th>
                <th>Readonly</th>
                <th>Compulsory</th>
                <th>Hidden</th>
            </tr>
    ];
            
    FIELD: foreach my $field (@$field_order){
        # Check if it has a config
        if ( $field_config->{$field} ){
            
            next FIELD if ($field_config->{$field}->{'ignore_permissions'});
            
            # display various options
            my $current_label = $field_config->{$field}->{'label'} || '';
            my $current_display_value = $field_config->{$field}->{'value'} || '';
            
            if ($field_config->{$field}->{'type'} eq 'checkbox' && defined $field_config->{$field}->{'displaylookup'}){
                $current_display_value = $field_config->{$field}->{'displaylookup'}->{$field_config->{$field}->{'value'}} || '';
            }
            
            $subBody .= qq[
                <tr>
                    <td class="label">$current_label</td>
                    <td class="label" style="font-style:italic">$current_display_value</td>
            ];
            
            foreach my $type (qw/ readonly compulsory hidden /){
                my $field_name = $field . '_' . $type; 
                my $checked = '';
                my $disabled = '';
                if ($field_config->{$field}->{$type}){
                    $checked = 'checked';
                    $disabled = 'disabled';
                }
                elsif ($field_permissions->{$field}->{$type}){
                    $checked = 'checked';
                }
                
                $subBody .= qq[<td><input type="checkbox" value="1" name="$field_name" $checked $disabled class="nb"></td>];
            }
            $subBody .= '</tr>';

        }
    }
            
            
    $subBody .= qq[        
        </table>

        <br> <br>
        <input type="submit" value="Update Permissions" class = "button proceed-button">
        <input type="hidden" name="client" value="$unescclient">
        <input type="hidden" name="programTemplateID" value="$program_template_id">
        <input type="hidden" name="a" value="PROGRAM_TEMPLATE_P_U">
        </form>

    ];
    
    return ($subBody, 'Permissions');

}


sub program_template_permissions_update {
    my ($Data, $program_template_obj) = @_;

    my $db = $Data->{'db'};
    my $realmID = $Data->{'Realm'} || 0;
    
    my $program_template_id = $program_template_obj->ID();
    
    my $st_del = qq[
        DELETE FROM 
            tblProgramTemplatesConfig 
        WHERE 
            intProgramTemplateID = $program_template_id
    ];
    
    $db->do($st_del);
    
    my $txt_prob = $Data->{'lang'}->txt('Problem updating Permissions');
    return qq[<div class="warningmsg">$txt_prob (1)</div>] if $DBI::err;
    
    my $permissions_sql = qq[
        INSERT INTO tblProgramTemplatesConfig (intProgramTemplateID, strField, intReadonly, intCompulsory, intHidden)
            VALUES (?, ?, ?, ?, ?)
    ];
    my $permissions_stmt = $db->prepare($permissions_sql);
    
    my $field_config = _get_loaded_fields_config($Data, $program_template_obj);
    my $field_order = _get_field_order();
    
    
    FIELD: foreach my $field (@$field_order){
        # Check if it has a config
        if ( $field_config->{$field} ){
            next FIELD if ($field_config->{$field}->{'ignore_permissions'});
            
            my @values = ($program_template_obj->ID(), $field);

            foreach my $type (qw/ readonly compulsory hidden /){
                my $field_name = $field . '_' . $type; 
                my $value = $field_config->{$field}->{$type} || param($field_name) || 0;
                
                push @values, $value;
            }
            
            $permissions_stmt->execute(@values);
        }
    }
    
    #auditLog($assocID, $Data, 'Update', 'Permissions');
    return '<div class="OKmsg">'.$Data->{'lang'}->txt('Permissions Updated').'</div>';
}

sub _get_loaded_fields_config{
    my ($Data, $program_template_obj) = @_;
    
    my ($program_template_singular, $program_template_plural) = get_program_template_titles($Data);
    my ($program_singular, $program_plural) = get_program_titles($Data);

    my $fields = {
        intProgramTemplateID => {
            label       => "$program_template_singular ID",
            value       => $program_template_obj->getValue('intProgramTemplateID') || '',
            type        => 'text',
            readonly    => 1,
            size        => '40',
            maxsize     => '100',
            compulsory  => 0,
            sectionname => 'details',
            hidden      => 1, 
            ignore_permissions => 1,
        },
        strTemplateName => {
            label   => "$program_template_singular Name",
            value   => $program_template_obj->getValue('strTemplateName') || '',
            type    => 'text',
            size    => '40',
            maxsize => '100',
            compulsory  => 1,
            sectionname => 'details',
            ignore_permissions => 1,
        },
        strProgramName => {
            label   => "Default $program_singular Name",
            value   => $program_template_obj->getValue('strProgramName') || '',
            type    => 'text',
            size    => '40',
            maxsize => '100',
            compulsory  => 1,
            sectionname => 'details',
        },
        intStatus => {
            label         => 'Active',
            value         => $program_template_obj->getValue('intStatus') || '',
            type          => 'checkbox',
            default       => 1,
            displaylookup => { 1 => 'Yes', 0 => 'No' },
            sectionname   => 'details',
            ignore_permissions => 1,
        },
        intMinSuggestedAge => {
            label       => "Minimum Suggested Age",
            value       => $program_template_obj->getValue('intMinSuggestedAge') || '',
            type        => 'text',
            size        => '6',
            sectionname => 'age',
            validate    => 'BETWEEN:5-50',
        },
        intMaxSuggestedAge => {
            label       => "Maximum Suggested Age",
            value       => $program_template_obj->getValue('intMaxSuggestedAge') || '',
            type        => 'text',
            size        => '6',
            sectionname => 'age',
            validate    => 'BETWEEN:5-50',
        },
        dtMaxDOB => {
            label       => "Max DOB",
            value       => $program_template_obj->getValue('dtMaxDOB') || '',
            type        => 'date',
            size        => '20',
            sectionname => 'age',
            datepicker_options => {
                'link_min_field' => 'dtMinDOB',
                'min_date' => $program_template_obj->getValue('dtMinDOB'),
                'no_min_date'    => 1,
            },
        },
        dtMinDOB => {
            label       => "Min DOB",
            value       => $program_template_obj->getValue('dtMinDOB') || '',
            type        => 'date',
            size        => '20',
            sectionname => 'age',
            datepicker_options => {
                'link_max_field' => 'dtMaxDOB',
                'max_date' => $program_template_obj->getValue('dtMaxDOB'),
                'no_min_date'    => 1,
            },
        },
        intAllowMinAgeExceptions => {
            label         => 'Allow Min DOB Exceptions',
            value         => $program_template_obj->getValue('intAllowMinAgeExceptions') || '',
            type          => 'checkbox',
            default       => 1,
            displaylookup => { 1 => 'Yes', 0 => 'No' },
            sectionname   => 'age',
        },
        intAllowMaxAgeExceptions => {
            label         => 'Allow Max DOB Exceptions',
            value         => $program_template_obj->getValue('intAllowMaxAgeExceptions') || '',
            type          => 'checkbox',
            default       => 1,
            displaylookup => { 1 => 'Yes', 0 => 'No' },
            sectionname   => 'age',
        },
        dtMinStartDate => {
            label       => "Earliest Start Date",
            value       => $program_template_obj->getValue('dtMinStartDate') || '',
            type        => 'date',
            size        => '20',
            sectionname => 'session',
            ignore_permissions => 1,
            datepicker_options => {
                'link_max_field' => 'dtMaxStartDate',
                'max_date' => $program_template_obj->getValue('dtMaxStartDate'),
                'no_min_date'    => 1,
            },
        },
        dtMaxStartDate => {
            label       => "Latest Start Date",
            value       => $program_template_obj->getValue('dtMaxStartDate') || '',
            type        => 'date',
            size        => '20',
            sectionname => 'session',
            ignore_permissions => 1,
            datepicker_options => {
                'link_min_field' => 'dtMinStartDate',
                'min_date' => $program_template_obj->getValue('dtMinStartDate'),
                'no_min_date'    => 1,
            },
        },
        intMinDuration => {
            label       => "Minimum Duration",
            value       => $program_template_obj->getValue('intMinDuration') || '',
            type        => 'text',
            size        => 3,
            maxsize     => 3,
            validate    => 'BETWEEN:20-120',
            sectionname => 'session',
            ignore_permissions => 1,
        },
        intMaxDuration => {
            label       => "Maximum Duration",
            value       => $program_template_obj->getValue('intMaxDuration') || '',
            type        => 'text',
            size        => 3,
            maxsize     => 3,
            validate    => 'BETWEEN:20-120',
            sectionname => 'session',
            ignore_permissions => 1,
        },
        intMinNumSessions => {
            label       => "Minimum number of Sessions",
            value       => $program_template_obj->getValue('intMinNumSessions') || '',
            type        => 'text',
            size        => 3,
            maxsize     => 3,
            validate    => 'BETWEEN:1-20',
            sectionname => 'session',
            ignore_permissions => 1,
        },
        intMaxNumSessions => {
            label       => "Maximum number of Sessions",
            value       => $program_template_obj->getValue('intMaxNumSessions') || '',
            type        => 'text',
            size        => 3,
            maxsize     => 3,
            validate    => 'BETWEEN:1-20',
            sectionname => 'session',
            ignore_permissions => 1,
        },
        intRegoFormID => {
            label         => 'Registration Form',
            value         => $program_template_obj->getValue('intRegoFormID') || '',
            type          => 'lookup',
            options       => get_available_rego_forms({
                'dbh'         => $Data->{'db'},
                'realm_id'    => $Data->{'Realm'},
                'subrealm_id' => $Data->{'RealmSubType'},
                'Data'        => $Data,
            }),
            sectionname   => 'rego',
            firstoption   => ['',"Choose Registration Form"],
            ignore_permissions => 1,
        }

    };
    
    return $fields;
}

sub _get_field_order {
    return [ qw(
        strTemplateName strProgramName intStatus intMinSuggestedAge intMaxSuggestedAge 
        dtMinDOB intAllowMinAgeExceptions dtMaxDOB intAllowMaxAgeExceptions dtMinStartDate
        dtMaxStartDate intMinDuration intMaxDuration intMinNumSessions intMaxNumSessions
        intRegoFormID
    )];
}



1;

