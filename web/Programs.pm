#
# $Header: svn://svn/SWM/trunk/web/Venues.pm 10333 2013-12-18 23:54:25Z apurcell $
#

package Programs;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(handle_programs);
@EXPORT_OK = qw(handle_programs);

use strict;
use Reg_common;
use Utils;
use HTMLForm;
use AuditLog;
use CGI qw(unescape param);
use FormHelpers;
use GridDisplay;
use FacilitiesUtils;
use ProgramTemplateUtils;
use ProgramUtils;

use Log;
require RecordTypeFilter;
require ProgramObj;
use Data::Dumper;

sub handle_programs {
    my ( $action, $Data ) = @_;

    my $programID = param('programID') || param("id") || 0;
    my $programTemplateID = param('programTemplateID') || 0;
    my $assocID = $Data->{clientValues}{assocID};
    
    my $resultHTML = '';
    my $title      = '';
    
    if ( $action =~ /^PROGRAM_L/ ) {
        #List Programs
        my $tempResultHTML = '';
        ( $tempResultHTML, $title ) = list_programs($Data, {'assocID' => $assocID, 'intProgramTemplateID' => $programTemplateID});
        $resultHTML .= $tempResultHTML;
    }
    else{
        # We will need to do something to a specific program
    
        # create program  object
        my $program_obj = ProgramObj->new(
            'ID' => $programID,
            'db' => $Data->{'db'},
        );
        
        # load only if we have an ID
        $program_obj->load() if $programID;
        
        my $permission = $program_obj->have_permission({
            'realm_id'    => $Data->{'Realm'}, 
            'subrealm_id' => $Data->{'RealmSubType'} ,
            'assoc_id'    => $assocID,
            'auth_level'  => $Data->{'clientValues'}{'authLevel'},
        });
        
        if ( $permission ){
            # we have permission to use this program
        
            if ( $action =~ /^PROGRAM_DT/ ) {
                if (!$programID && !$programTemplateID) {
                    # we need to select a template to start a program
                    ( $resultHTML, $title ) = select_program_template($Data);
                }
                else{
                    ( $resultHTML, $title ) = program_details( $action, $Data, $program_obj, $programTemplateID); 
                }
                
            }
            elsif ( $action =~ /^PROGRAM_DEL/ ) {
                ( $resultHTML, $title ) = delete_program($Data, $program_obj);
            }
            elsif ( $action =~ /^PROGRAM_M_L/ ) {
                #List Members of a Program
                my $tempResultHTML = '';
                ( $tempResultHTML, $title ) = list_program_members($Data, $program_obj);
                $resultHTML .= $tempResultHTML;
            }
            elsif ( $action =~ /^PROGRAM_E_/ ) {
                # Withdraw and enrolled member
                my $program_enrolment_id =  param('programEnrolmentID') || 0;
                ( $resultHTML, $title ) = process_withdraw_enrolment($Data, $action, $program_obj, $program_enrolment_id);
            }
        }
        else{
            # We dont have access to this program, no soup for you!
            $resultHTML = 'No access to this program';
            $title = 'Program';
        }
    }
    
    

    return ( $resultHTML, $title );
}

sub program_details {
    my ( $action, $Data, $program_obj, $programTemplateID ) = @_;

    my $option = 'display';
    
    my $programID = $program_obj->ID();
    if ($action eq 'PROGRAM_DTE' and allowedAction( $Data, 'programs_e' )){
        $option = 'edit';
    }
    elsif ($action eq 'PROGRAM_DTA' and allowedAction( $Data, 'programs_a' )){
        $option = 'add';
        $programID = 0;
        if (!$programTemplateID) {
            return select_program_template($Data);
        }
    }

    my $intRealmID = $Data->{'Realm'} >= 0 ? $Data->{'Realm'} : 0;
    my $intAssocID = $Data->{clientValues}{assocID};

    my $fields = $program_obj->getAllValues() || {};
    
    $programTemplateID ||= $fields->{'intProgramTemplateID'};
    
    my $template_fields = get_program_template_field_details({
        'dbh' => $Data->{'db'},
        'program_template_id' => $programTemplateID,
    });
       
    my $client = setClient( $Data->{'clientValues'} ) || '';
    my ($program_singular, $program_plural) = get_program_titles($Data);
    my ($facility_singular, $facility_plural) = get_facility_titles($Data);

    my $facility_options;
    
    my $facility_list = get_available_facilities({
        'dbh' => $Data->{'db'},
        'realm_id' => $intRealmID,
    });
    
    foreach my $facility_obj (@$facility_list){
        $facility_options->{$facility_obj->ID()} = $facility_obj->name();
    }
    
    # Override what the program has with the template values if they are readonly or empty
    foreach my $field (keys %{$template_fields}){
        if ( defined $template_fields->{$field}->{'value'} && $template_fields->{$field}->{'readonly'} ){
            $fields->{$field} = $template_fields->{$field}->{'value'};
        }
        elsif( defined $template_fields->{$field}->{'value'} && !defined $fields->{$field} ){
            $fields->{$field} = $template_fields->{$field}->{'value'};
        }
    }
    
    
    # Work out info for ranged fields
    my $field_details = {
        'intNumSessions' => _get_field_range_properties(
            $template_fields->{'intMinNumSessions'}->{'value'},
            $template_fields->{'intMaxNumSessions'}->{'value'}
        ),
        'intDuration' => _get_field_range_properties(
            $template_fields->{'intMinDuration'}->{'value'},
            $template_fields->{'intMaxDuration'}->{'value'}
        ),
    };
    
    foreach my $field (keys %{$field_details}){
        if ( defined $field_details->{$field}->{'force_value'}){
            $fields->{$field} = $field_details->{$field}->{'force_value'};
        }
    }

    my %FieldDefinitions = (
        fields => {
            intProgramID => {
                label       => "$program_singular ID",
                value       => $fields->{intProgramID},
                type        => 'text',
                readonly    => 1,
                size        => '40',
                maxsize     => '100',
                compulsory  => 0,
                sectionname => 'details',
            },
            strProgramName => {
                label   => "$program_singular Name",
                value   => $fields->{strProgramName},
                type    => 'text',
                size    => '40',
                maxsize => '100',
                disabled    => $template_fields->{'strProgramName'}->{'readonly'},
                compulsory  => $template_fields->{'strProgramName'}->{'compulsory'},
                hidden      => $template_fields->{'strProgramName'}->{'hidden'},
                sectionname => 'details',
            },
            intStatus => {
                label         => 'Active?',
                value         => $fields->{intStatus},
                type          => 'checkbox',
                default       => 1,
                displaylookup => { 1 => 'Yes', 0 => 'No' },
                sectionname   => 'details',
            },
            intFacilityID => {
                label         => $facility_singular, 
                value         => $fields->{intFacilityID},
                type          => 'lookup',
                options       => $facility_options,
                sectionname   => 'details',
                compulsory    => 1,
                firstoption   => ['',"Choose $facility_singular"],
            },
            intMinSuggestedAge => {
                label       => "Minimum Suggested Age",
                value       => $fields->{intMinSuggestedAge},
                type        => 'text',
                size        => '6',
                sectionname => 'age',
                validate    => 'BETWEEN:5-50',
                disabled    => $template_fields->{'intMinSuggestedAge'}->{'readonly'},
                compulsory  => $template_fields->{'intMinSuggestedAge'}->{'compulsory'},
                hidden      => $template_fields->{'intMinSuggestedAge'}->{'hidden'},
            },
            intMaxSuggestedAge => {
                label       => "Maximum Suggested Age",
                value       => $fields->{intMaxSuggestedAge},
                type        => 'text',
                size        => '6',
                sectionname => 'age',
                validate    => 'BETWEEN:5-50',
                disabled    => $template_fields->{'intMinSuggestedAge'}->{'readonly'},
                compulsory  => $template_fields->{'intMinSuggestedAge'}->{'compulsory'},
                hidden      => $template_fields->{'intMinSuggestedAge'}->{'hidden'},
            },
            
            dtMinDOB => {
                label       => "Min DOB",
                value       => $fields->{dtMinDOB},
                type        => 'date',
                size        => '20',
                disabled    => $template_fields->{'dtMinDOB'}->{'readonly'},
                compulsory  => $template_fields->{'dtMinDOB'}->{'compulsory'},
                hidden      => $template_fields->{'dtMinDOB'}->{'hidden'},
                sectionname => 'age',
                datepicker_options => {
                    'link_min_field' => 'dtMaxDOB',
                    'min_date'       => $fields->{dtMaxDOB},
                },
            },
            intAllowMinAgeExceptions  => {
                label       => "Allow Min DOB exceptions?",
                value       => $fields->{intAllowMinAgeExceptions},
                type        => 'checkbox',
                default     => 0,
                displaylookup => { 1 => 'Yes', 0 => 'No' },
                disabled    => $template_fields->{'intAllowMinAgeExceptions'}->{'readonly'},
                compulsory  => $template_fields->{'intAllowMinAgeExceptions'}->{'compulsory'},
                hidden      => $template_fields->{'intAllowMinAgeExceptions'}->{'hidden'},
                sectionname => 'age',
            },
            dtMaxDOB => {
                label       => "Max DOB",
                value       => $fields->{dtMaxDOB},
                type        => 'date',
                size        => '20',
                disabled    => $template_fields->{'dtMaxDOB'}->{'readonly'},
                compulsory  => $template_fields->{'dtMaxDOB'}->{'compulsory'},
                hidden      => $template_fields->{'dtMaxDOB'}->{'hidden'},
                sectionname => 'age',
                datepicker_options => {
                    'link_max_field' => 'dtMinDOB',
                    'max_date'       => $fields->{dtMinDOB},
                },
            },
            intAllowMaxAgeExceptions  => {
                label       => "Allow Max DOB exceptions?",
                value       => $fields->{intAllowMaxAgeExceptions},
                type        => 'checkbox',
                default     => 0,
                displaylookup => { 1 => 'Yes', 0 => 'No' },
                disabled    => $template_fields->{'intAllowMaxAgeExceptions'}->{'readonly'},
                compulsory  => $template_fields->{'intAllowMaxAgeExceptions'}->{'compulsory'},
                hidden      => $template_fields->{'intAllowMaxAgeExceptions'}->{'hidden'},
                sectionname => 'age',
            },
            
            dtStartDate => {
                label => 'Start Date',
                value => $fields->{'dtStartDate'},
                type  => 'date',
                format => 'dd/mm/yyyy',
                validate => 'DATE',
                compulsory =>  1,
                sectionname => 'session',
                datepicker_options => {
                    'min_date' => $template_fields->{'dtMinStartDate'}->{'value'},
                    'max_date' => $template_fields->{'dtMaxStartDate'}->{'value'},
                    'prevent_user_input' => 1,
                },
            },
            tmStartTime => {
                label => 'Start Time',
                value => $fields->{'tmStartTime'} ,
                type  => 'time',
                sectionname => 'session',
                compulsory =>  1,
            },
            intDuration => {
                label   => "Duration",
                value   => $fields->{intDuration},
                type    => 'text',
                size    => 7,
                maxsize => 3,
                compulsory  => 1,
                validate    => $field_details->{'intDuration'}->{'between'} || '',
                placeholder => $field_details->{'intDuration'}->{'placeholder'} || '',
                disabled    => $field_details->{'intDuration'}->{'readonly'} || 0,
                sectionname => 'session',
            },
            intVenueRequiredMins => {
                label   => "Venue Required Mins", #TODO: custom venue text
                value   => $fields->{intVenueRequiredMins},
                type    => 'text',
                size    => 3,
                maxsize => 3,
                validate => 'BETWEEN:1-200',
                sectionname => 'session',
            },
            intCapacity => {
                label   => "Capacity",
                value   => $fields->{intCapacity},
                type    => 'text',
                size    => 7,
                maxsize => 3,
                compulsory  => 1,
                validate    => 'BETWEEN:1-999',
                sectionname => 'session',
            },
            intNumSessions => {
                label   => "Number of Sessions", #TODO: custom session text
                value   => $fields->{intNumSessions},
                type    => 'text',
                size    => 7,
                maxsize => 2,
                compulsory  => 1,
                validate    => $field_details->{'intNumSessions'}->{'between'} || '',
                placeholder => $field_details->{'intNumSessions'}->{'placeholder'} || '',
                disabled    => $field_details->{'intNumSessions'}->{'readonly'} || 0,
                sectionname => 'session',
            },
            DAYTEXT => {
                label => 'Select Days',
                value => "Please ensure that the day of week matches your start date.",
                type  => 'textvalue',
                sectionname => 'days',
                nodisplay => 1,
            },
            intMon => {
                label => "Monday?",
                value => $fields->{'intMon'},
                type => 'checkbox',
                default => 0,
                displaylookup => {1=>'Yes',0=>'No'},
                sectionname => 'days',
            },
            intTue => {
                label => "Tuesday?",
                value => $fields->{'intTue'},
                type => 'checkbox',
                default => 0,
                displaylookup => {1=>'Yes',0=>'No'},
                sectionname => 'days',
            },
            intWed => {
                label => "Wednesday?",
                value => $fields->{'intWed'},
                type => 'checkbox',
                default => 0,
                displaylookup => {1=>'Yes',0=>'No'},
                sectionname => 'days',
            },
            intThu => {
                label => "Thursday?",
                value => $fields->{'intThu'},
                type => 'checkbox',
                default => 0,
                displaylookup => {1=>'Yes',0=>'No'},
                sectionname => 'days',
            },
            intFri => {
                label => "Friday?",
                value => $fields->{'intFri'},
                type => 'checkbox',
                default => 0,
                displaylookup => {1=>'Yes',0=>'No'},
                sectionname => 'days',
            },
            intSat => {
                label => "Saturday?",
                value => $fields->{'intSat'},
                type => 'checkbox',
                default => 0,
                displaylookup => {1=>'Yes',0=>'No'},
                sectionname => 'days',
            },
            intSun => {
                label => "Sunday?",
                value => $fields->{'intSun'},
                type => 'checkbox',
                default => 0,
                displaylookup => {1=>'Yes',0=>'No'},
                sectionname => 'days',
            },
            intOnMemberEnrolmentStatus => {        
                label         => 'Default status of new Members on Enrolment',
                value         => $fields->{intOnMemberEnrolmentStatus},
                type          => 'lookup',
                default       => $Defs::RECSTATUS_ACTIVE,
                options       => { $Defs::RECSTATUS_ACTIVE => 'Active', $Defs::RECSTATUS_INACTIVE => 'Pending' },
                compulsory    => 1,
                #firstoption   => ['',"Choose Status"],
                sectionname   => 'rego',
            },
        },
        order => [ qw(
            strProgramName intStatus intFacilityID intMinSuggestedAge intMaxSuggestedAge
            dtMaxDOB intAllowMaxAgeExceptions dtMinDOB intAllowMinAgeExceptions dtStartDate tmStartTime 
            intCapacity intDuration  intNumSessions DAYTEXT intMon intTue intWed intThu intFri 
            intSat intSun intOnMemberEnrolmentStatus
        )],
        sections => [
            [ 'details', "$program_singular Details" ],
            [ 'age',     "Age Details"],
            [ 'session', "Session Details"],
            [ 'days', "Days Run" ],
            [ 'product', "Product Details"],
            [ 'rego', "Registration Details"],
        ],
        options => {
            labelsuffix => ':',
            hideblank   => 1,
            target      => $Data->{'target'},
            formname    => 'n_form',
            submitlabel => ($option eq 'add') ? "Create $program_singular" : "Update $program_singular",
            introtext   => 'auto',
            NoHTML      => 1,
            updateSQL   => qq[
                UPDATE tblPrograms
                SET --VAL--
                WHERE 
                    intProgramID = $programID
            ],
            addSQL => qq[
                INSERT INTO tblPrograms (
                    intAssocID,
                    intProgramTemplateID, 
                    --FIELDS-- 
                )
                VALUES (
                    $intAssocID, 
                    $programTemplateID,
                    --VAL-- 
                )
            ],
            auditFunction   => \&auditLog,
            auditAddParams  => [ $Data, 'Add', 'Programs' ],
            auditEditParams => [ $programID, $Data, 'Update', 'Programs' ],
            LocaleMakeText  => $Data->{'lang'},
        },
        carryfields => {
            client  => $client,
            a       => $action,
            programID => $programID,
            programTemplateID => $programTemplateID,
        },
    );
    
    my $resultHTML = '';
    ( $resultHTML, undef ) = handleHTMLForm( \%FieldDefinitions, undef, $option, '', $Data->{'db'} );
    my $title = qq[Program - $fields->{strName}];
    
    my $chgoptions = '';

    if ( $option eq 'edit' ) {
        my $program_obj = ProgramObj->new('db'=>$Data->{db},ID=>$programID );
        $program_obj->load();
        $chgoptions .= qq[<span class = "button-small generic-button"><a href="$Data->{'target'}?client=$client&amp;a=PROGRAM_DEL&amp;programID=$programID" onclick="return confirm('Are you sure you want to delete this $program_singular');">Delete $program_singular</a> ] if $program_obj->canDelete();
    }

    $chgoptions = qq[<div class="changeoptions">$chgoptions</div>] if $chgoptions;
    $title = $chgoptions . $title;

    $title = "Add New $program_singular" if $option eq 'add';

    my $text = qq[<p style = "clear:both;"><a href="$Data->{'target'}?client=$client&amp;a=PROGRAM_L">Click here</a> to return to list of $program_plural</p>];
    $resultHTML = $text . $resultHTML . $text;

    return ( $resultHTML, $title );
}


sub delete_program {
    my ($Data, $program_obj) = @_;

    my $client=setClient($Data->{'clientValues'}) || '';
    my ($program_singular, $program_plural) = get_program_titles($Data);
    
    my $result = $program_obj->delete();

    my $resultHTML = '';
    if ($result && $result !~/^ERROR/) {
        $resultHTML .= '<p class="OKmsg">' . $program_singular . ' successfully deleted.</p>';
        auditLog($program_obj->ID(), $Data, 'Delete', 'Program Template');
    }
    else {
        $resultHTML .= '<p class="warningmsg">Unable to delete ' . $program_singular .'<br></p>';
    }

    $resultHTML .= qq[<p><a href="$Data->{'target'}?client=$client&amp;a=PROGRAM_L">Click here</a> to return to list of $program_plural</p>];

    return $resultHTML;
}

sub list_programs {
    my ($Data, $params) = @_;

    my $client     = unescape( $Data->{client} );
    my ($program_singular, $program_plural) = get_program_titles($Data);
    my ($facility_singular, $facility_plural) = get_facility_titles($Data);
    my $resultHTML = '';
    my $title=qq[$program_plural];
    
    
    my @where_clauses = ( 'P.intStatus <> ?' );
    my @values = ($Defs::RECSTATUS_DELETED);
    
    # The two ways we should be reaching this page is from Association level
    # or from a national level with a program template ID
    
    if ($params->{'assocID'}){
        push @where_clauses,  'intAssocID = ?';
        push @values, $params->{'assocID'}; 
    }
    elsif ($params->{'intProgramTemplateID'}){
        push @where_clauses,  'intProgramTemplateID = ?';
        push @values, $params->{'intProgramTemplateID'}; 
    }
    else{
        WARN "Accessed listPrograms without assocID or intProgramTemplateID";
        $resultHTML = "Could not display program list";
        return ( $resultHTML, $title );
    }
    
    my $where_statement = join(' AND ', @where_clauses);
     
    my $statement = qq[
        SELECT
          P.*,
          PT.strTemplateName,
          F.strName as strFacilityName
        FROM 
          tblPrograms AS P
          INNER JOIN tblProgramTemplates AS PT ON (P.intProgramTemplateID = PT.intProgramTemplateID)
          LEFT JOIN tblFacilities as F ON (P.intFacilityID = F.intFacilityID)
        WHERE 
          $where_statement
        ORDER BY 
          P.dtStartDate
    ];


    my $query = $Data->{'db'}->prepare($statement);
    $query->execute(@values);
    my %tempClientValues = getClient($client);

    my @rowdata    = ();
    my $tempClient = setClient( \%tempClientValues );

    while ( my $dref = $query->fetchrow_hashref() ) {
        my $programID = $dref->{intProgramID};
        
        my @days_run;
        
        foreach my $day ('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun' ){
            if ( $dref->{'int' . $day} ){
                push @days_run, $day;
            }
        }
        
        my $prices_link = qq[<a href="$Data->{target}?a=A_PR_&amp;client=$tempClient&amp;programID=$programID">Edit Prices</a>];
        my $members_link = qq[<a href="$Data->{target}?a=PROGRAM_M_L&amp;client=$tempClient&amp;programID=$programID">View Members</a>];

        push @rowdata, {
            id              => $programID   || next,
            strProgramName  => $dref->{'strProgramName'}   || '',
            strFacilityName => $dref->{'strFacilityName'}  || '',
            dtStartDate     => $dref->{'dtStartDate'} || '',
            strDaysRun      => join(', ', @days_run ) || 'None',
            intNumSessions  => $dref->{'intNumSessions'} || '',
            SelectLink =>"$Data->{'target'}?client=$tempClient&amp;a=PROGRAM_DTE&amp;programID=$programID",
            linkPrices => $prices_link,
            linkMembers => $members_link,
            intStatus  => $dref->{'intStatus'} || 0,

        };
    }

    my $addlink = qq[<span class = "button-small generic-button"><a href="$Data->{'target'}?client=$tempClient&amp;a=PROGRAM_DTA">Add</a></span>];
    my $modoptions = qq[<div class="changeoptions">$addlink</div>];
    
    $title = $modoptions . $title;
    my $rectype_options = RecordTypeFilter::show_recordtypes( $Data, 0, undef, undef, 'Name' ) || '';

    my @headers = (
        {
            type  => 'Selector',
            field => 'SelectLink',
        },
        {
            name  => $Data->{'lang'}->txt("$program_singular Name"),
            field => 'strProgramName',
        },
        {
            name  => $Data->{'lang'}->txt("$facility_singular Name"),
            field => 'strFacilityName',
        },
        {
            name  => $Data->{'lang'}->txt('Start Date'),
            field => 'dtStartDate',
            type   => 'date',
        },
        {
            name  => $Data->{'lang'}->txt('Days Run'),
            field => 'strDaysRun',
        },
        {
            name  => $Data->{'lang'}->txt('Number of Sessions'),
            field => 'intNumSessions',
        },
        {
            name  => $Data->{'lang'}->txt('Product Prices'),
            field => 'linkPrices',  
            type  => 'HTML',
            width => 50,
        },
        {
            name  => $Data->{'lang'}->txt('Members'),
            field => 'linkMembers',  
            type  => 'HTML',
            width => 50,
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
            field     => 'strProgramName',
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
        ajax_keyfield => 'intProgramID',
        saveaction => 'edit_program',
    );

    $resultHTML = qq[
        <div class="grid-filter-wrap">
            <div style="width:99%;">$rectype_options</div>
            $grid
        </div>
    ];

    return ( $resultHTML, $title );
}

sub list_program_members {
    my ($Data, $program_obj ) = @_;

    my $client     = unescape( $Data->{client} );
    my $resultHTML = '';
    my $title = "Members in " . $program_obj->name();
    
    my $program_id = $program_obj->ID();

    my %tempClientValues = getClient($client);
    my $tempClient = undef;
    
    my @rowdata    = ();
    
    my $members = $program_obj->get_enrolled_members();
    
    foreach my $dref ( @$members ) {
        my $memberID = $dref->{'intMemberID'};
        my $program_enrolment_id = $dref->{'intProgramEnrolmentID'};

        $tempClientValues{'memberID'} = $memberID;
        $tempClientValues{'currentLevel'} = $Defs::LEVEL_MEMBER;
        $tempClient = setClient( \%tempClientValues );

        my $memberLink    = "$Data->{target}?client=$tempClient&amp;a=M_HOME";
        my $withdraw_link = qq[<a href="$Data->{target}?client=$client&amp;a=PROGRAM_E_D&amp;programEnrolmentID=$program_enrolment_id&amp;programID=$program_id">Withdraw</a>];

        push @rowdata, {
            id              => $memberID,
            intMemberID     => $memberID,
            SelectLink      => $memberLink,
            strFirstname    => $dref->{'strFirstname'} || '',
            strSurname      => $dref->{'strSurname'} || '',
            dtDOB           => $dref->{'dtDOB'} || '',
            strSuburb       => $dref->{'strSuburb'} || '',
            strPhoneMobile  => $dref->{'strPhoneMobile'} || '',
            strEmail        => $dref->{'strEmail'} || '',
            strP1FName      => $dref->{'strP1FName'} || '',
            strP1SName      => $dref->{'strP1SName'} || '',
            strP1Phone      => $dref->{'strP1Phone'} || '',
            strP1Email      => $dref->{'strP1Email'} || '',
            strP2FName      => $dref->{'strP2FName'} || '',
            strP2SName      => $dref->{'strP2SName'} || '',
            strP2Phone      => $dref->{'strP2Phone'} || '',
            strP2Email      => $dref->{'strP2Email'} || '',
            intNewToProgram => $dref->{'intNewToProgram'},
            withdraw_link   => $withdraw_link,
        };
    }

    my @headers = (
        {
            type  => 'Selector',
            field => 'SelectLink',
        },
        {
            name  => $Data->{'lang'}->txt('Family name'),
            field => 'strSurname',
        },
        {
            name  => $Data->{'lang'}->txt('First name'),
            field => 'strFirstname',
        },
        {
            name  => $Data->{'lang'}->txt('Date of Birth'),
            field => 'dtDOB',
            type   => 'date',
        },
    );
    
    if ($Data->{'SystemConfig'}{'show_program_list_suburb'}){
        #TODO make program config
        push @headers, {
            name  => $Data->{'lang'}->txt('Suburb'),
            field => 'strSuburb',
        };
    }
    
    if ($Data->{'SystemConfig'}{'show_program_list_participant_contact'}){
        #TODO make program config
        push @headers, {
            name  => $Data->{'lang'}->txt('Mobile'),
            field => 'strPhoneMobile',
        },
        {
            name  => $Data->{'lang'}->txt('Email'),
            field => 'strEmail',
        };
    }
    
    if ($Data->{'SystemConfig'}{'show_program_list_parent_guardian_1'}){
        #TODO make program config
        push @headers, {
            name  => $Data->{'lang'}->txt('Parent/Guardian Firstname'),
            field => 'strP1FName',
        },
        {
            name  => $Data->{'lang'}->txt('Parent/Guardian Surname'),
            field => 'strP1SName',
        },
        {
            name  => $Data->{'lang'}->txt('Parent/Guardian Phone'),
            field => 'strP1Phone',
        },
        
        {
            name  => $Data->{'lang'}->txt('Parent/Guardian Email'),
            field => 'strP1Email',
        };
    }
    
    if ($Data->{'SystemConfig'}{'show_program_list_parent_guardian_2'}){
        #TODO make program config
        push @headers, {
            name  => $Data->{'lang'}->txt('Parent/Guardian 2 Firstname'),
            field => 'strP2FName',
        },
        {
            name  => $Data->{'lang'}->txt('Parent/Guardian 2 Surname'),
            field => 'strP2SName',
        },
        {
            name  => $Data->{'lang'}->txt('Parent/Guardian 2 Phone'),
            field => 'strP2Phone',
        },
        {
            name  => $Data->{'lang'}->txt('Parent/Guardian 2 Email'),
            field => 'strP2Email',
        };
    }
        
    push @headers, {
        name   => $Data->{'lang'}->txt('New Enrolment'),
        field  => 'intNewToProgram',
        editor => 'checkbox',
        type   => 'tick',
    },
    {
        type  => 'HTML',
        name  => 'Withdraw',
        field => 'withdraw_link',
    }
    ;

    my $grid = showGrid(
        Data    => $Data,
        columns => \@headers,
        rowdata => \@rowdata,
        gridid  => 'grid',
        width   => '99%',
        client  => $client,
        ajax_keyfield => 'intMemberID',
        saveaction => 'list_program_members',
    );

    $resultHTML = qq[
        <div class="grid-filter-wrap">
            $grid
        </div>
    ];

    return ( $resultHTML, $title );
}

sub select_program_template {
    my ($Data) = @_;

    my $client     = unescape( $Data->{client} );
    my ($program_singular, $program_plural) = get_program_titles($Data);
    
    my $resultHTML = '';
    my $title=qq[$program_plural];
    
    my $realm_id = $Data->{'Realm'} >= 0 ? $Data->{'Realm'} : 0;
    my $program_template_list = get_available_program_templates({
        'dbh' => $Data->{'db'},
        'realm_id' => $realm_id,
    });
    
    if ($program_template_list){
        my @dropdown_rows;
        
        foreach my $program_template_obj (@$program_template_list){
            push @dropdown_rows, '<option value="' . $program_template_obj->ID() .'">' . $program_template_obj->get_display_name() . '</option>';
        }
        
        my $select_data = join ("\n", @dropdown_rows);
        
        my $body = qq[
            <div class="sectionheader">Choose which type of Program you wish to create: </div>
    
            <form action ="$Data->{'target'}" method="POST">
                <select name="programTemplateID">
                    $select_data
                </select>
                
                <input type="hidden" name="a" value="PROGRAM_DTA">
                <input type="hidden" name="client" value="$client">
                
                <br>
                <input type="submit" value="Create Program" class = "button generic-button">
                <br>
            </form>
        ];
        
        $resultHTML = $body;
    }
    else{
        $resultHTML = "There are no available programs at this time";
    }
    
    return ($resultHTML, $title);
}

sub _get_field_range_properties {
    my ($min_value, $max_value) = @_;
   
    my $field_range_details = {};
     
    if (defined $min_value && defined $max_value){
        
        if ($min_value == $max_value){
            # Same price, so lock it in
            $field_range_details->{'force_value'} = $min_value || 0;
            $field_range_details->{'readonly'} = 1;
        }
        elsif ($min_value < $max_value){
            # Max greater than Min 
            $field_range_details->{'placeholder'} = "$min_value to $max_value";
            $field_range_details->{'between'} = "BETWEEN:$min_value-$max_value";
        }
        else{
            # ARgh the Min is greater than Max, should never go full retard... 
            $field_range_details->{'placeholder'} = "$max_value to $min_value";
            $field_range_details->{'between'} = "BETWEEN:$max_value-$min_value";
        }
    }
    elsif (defined $min_value || defined $max_value){
        # Only one defined
        my $value = $min_value || $max_value;
        $field_range_details->{'force_value'} = $value || 0;
        $field_range_details->{'readonly'} = 1;
    }

    return $field_range_details;
}

sub process_withdraw_enrolment{
    my ($Data, $action, $program_obj, $enrolment_id) = @_;

    my $client=setClient($Data->{'clientValues'}) || '';
    my $program_id = $program_obj->ID();
    my $program_name = $program_obj->name();
    my $title = "Withdraw Member from $program_name";
    my $resultHTML = '';

    my $enrolment_data = $program_obj->get_enrolled_members({
        'program_enrolment_id' => $enrolment_id,
    });
    
    my $member_data = $enrolment_data->[0];
    
    #check if we have an enrolment in that program
    if ($member_data){
        my $first_name = $member_data->{strFirstname} || '';
        my $surname    = $member_data->{strSurname}   || '';
        $title         = "Withdraw $first_name $surname";
        
        if ($action =~ /PROGRAM_E_W/) {
            # Withdraw
            my $result = $program_obj->withdraw_enrolment($enrolment_id);
    
            if ($result) {
                $resultHTML .= qq[<p class="OKmsg">$first_name $surname successfully withdrawn from $program_name.</p>];
            }
            else {
                $resultHTML .= qq[<p class="warningmsg">$first_name $surname could not be withdrawn from $program_name.</p>];
            }
        }
        else {
            # Display
            my $withdraw_url = qq[$Data->{'target'}?client=$client&amp;a=PROGRAM_E_W&amp;programID=$program_id&amp;programEnrolmentID=$enrolment_id];

            $resultHTML .= qq[
                <div class="sectionheader">
                    Are you sure you want to withdraw $first_name $surname from $program_name?<br>
                    <span class="button generic-button">
                        <a href="$withdraw_url">Withdraw Enrolment</a>
                    </span>
                </div>
            ];
        }
    }
    else {
        # No enrolment found
        $resultHTML .= qq[<p class="warningmsg">Could not find enrolment.</p>];
    }

    $resultHTML .= qq[<br><p><a href="$Data->{'target'}?client=$client&amp;a=PROGRAM_M_L&amp;programID=$program_id">Click here</a> to return to list of members for $program_name</p>];

    return $resultHTML, $title;
    
}



1;

