#
# $Header: svn://svn/SWM/trunk/web/comp/Fixture.pm 10320 2013-12-17 06:16:50Z apurcell $
#

package ProgramObj;

use strict;

use lib ".", "..", "../..", "comp";

use base qw(BaseObject);

use Defs;
use ServicesContacts;
use ProductUtils;
use Log;
use Utils;
use DateTime::Format::MySQL;
use Scalar::Util qw( blessed );

require FacilityObj;
require Logo;

sub delete {
    my $self = shift;

    my $result = $self->SUPER::delete();
    
    if (!$result){
        WARN "Deleting Program failed for $self->{'ID'}";
    }
    return $result;
}

sub _can_delete_self {
    my $self = shift;
    
    return 1;
}

sub _delete_self {
    my $self = shift;
    
    # Delete Self
    $self->{'DBData'}{'intStatus'} = $Defs::RECSTATUS_DELETED;
    $self->write();
} 

sub _get_sql_details {
    my $self = shift;
    
    my $field_details = {
        'fields_to_ignore' => [],
        'table_name' => 'tblPrograms',
        'key_field' => 'intProgramID',
    };
    
    return $field_details;
}

sub name{
    my $self = shift;
    
    return $self->getValue('strProgramName') || '';
}

sub get_display_name{
    my $self = shift;
    
    my $display_name = $self->{'DBData'}{'strProgramName'} . ' (' . $self->display_ages() . ')';
    
    return $display_name;
    
}

sub display_ages{
    my $self = shift;
    my $prefix = shift;
    
    if (!defined $prefix){
        $prefix = 'ages ';
    }
    
    my $age_display = 'all ages';
    
    my $min_age = $self->{'DBData'}{'intMinSuggestedAge'};
    my $max_age = $self->{'DBData'}{'intMaxSuggestedAge'};
    
    if ($min_age && $max_age){
        $age_display = $prefix . "$min_age to $max_age";
    }
    elsif ($min_age){
        $age_display = $prefix . "$min_age and up";
    }
    elsif ($max_age){
        $age_display = $prefix . "$max_age and under";
    }
    
    return $age_display
}

sub display_costs{
    my $self = shift;
    
    #TODO: implement this after we get products, will have to do some funky searching
    
    return '$65';
}


sub display_day_of_week{
    my $self = shift;
    my $type = shift;
    
    $type ||= 'long';
    my %days_of_week =(
        'intMon' =>{
            'short' => 'Mon',
            'long' => 'Monday',
        },
        'intTue' =>{
            'short' => 'Tue',
            'long' => 'Tuesday',
        },
        'intWed' =>{
            'short' => 'Wed',
            'long' => 'Wednesday',
        },
        'intThu' =>{
            'short' => 'Thu',
            'long' => 'Thursday',
        },
        'intFri' =>{
            'short' => 'Fri',
            'long' => 'Friday',
        },
        'intSat' =>{
            'short' => 'Sat',
            'long' => 'Saturday',
        },
        'intSun' =>{
            'short' => 'Sun',
            'long' => 'Sunday',
        },
    );
    
    my ($row) = @_;
    my @days;
    foreach my $day ( qw/ intMon intTue intWed intThu intFri intSat intSun /){
        push @days, $days_of_week{$day}{$type} if ($self->{'DBData'}->{$day});
    }
    
    return join(', ', @days) || 'TBD';
}

sub display_rego_link{
    my $self = shift;
    my $link_title = shift;
    
    my $form_link = '';
    $link_title ||= 'Register';
    
    my $rego_form_id = $self->get_rego_form_id();
    
    if ($rego_form_id){
        $form_link = HTML_link($link_title, "$Defs::base_url/regoform.cgi", {
            '-target'   => '_blank', 
            'formID'    => $rego_form_id, 
            'programID' => $self->ID(),
        });
    }

    return $form_link;
}

sub display_start_date{
    my $self = shift;
    my $separator = shift;
    $separator ||= '-';
    my $start_date = '';
    
    if ($self->getValue('dtStartDate') && ($self->getValue('dtStartDate') ne '0000-00-00') ){
        my $start_date_dt = DateTime::Format::MySQL->parse_date($self->getValue('dtStartDate'));
        
        $start_date = $start_date_dt->dmy($separator);
    }

    return $start_date;
}

sub display_time{
    my $self = shift;
    my $start_time = '';
    
    if ($self->getValue('tmStartTime') && $self->getValue('dtStartDate') && ($self->getValue('dtStartDate') ne '0000-00-00') ){
        my $start_time_dt = DateTime::Format::MySQL->parse_datetime( $self->getValue('dtStartDate') . ' ' . $self->getValue('tmStartTime'));
        
        # Format of 'hh:mm AM/PM' eg: '3:00 PM' or '11:30 AM'
        $start_time = $start_time_dt->strftime('%l:%M %p');
    }

    return $start_time;
}

sub get_rego_form_id{
    my $self = shift;
    my $rego_form_id;
    
    my $program_template_obj = $self->get_program_template_obj();
    
    if (ref $program_template_obj){
        $rego_form_id = $program_template_obj->get_rego_form_id();
    }   
    
    return $rego_form_id
}

sub get_template_id{
    my $self = shift;
    
    return $self->{'DBData'}->{'intProgramTemplateID'} || 0;
    
}

sub is_active{
    my $self = shift;
    
    if ($self->{'DBData'}->{'intStatus'} == $Defs::RECSTATUS_ACTIVE){
        return 1
    }
    else{
        return 0;
    }
}

sub enrol_member{
    my $self = shift;
    my $params = shift;
    
    my $member_id = $params->{'member_id'};
    
    my $new_to_program = 1;
    
    if (defined $params->{'new_to_program'}){
        $new_to_program = $params->{'new_to_program'};
    }
    
    my $enrolment_status = $self->getValue('intOnMemberEnrolmentStatus');
    
    if ( !defined $enrolment_status){
        $enrolment_status = $Defs::RECSTATUS_ACTIVE;
    }
    
    my $sql = qq[
        INSERT IGNORE INTO tblProgramEnrolment  (
            intProgramID,
            intMemberID,
            intNewToProgram,
            intStatus,
            dtEnroled
        )
        VALUES (
            ?,
            ?,
            ?,
            ?,
            NOW()
        )
    ];
    my $stmt = $self->{'db'}->prepare($sql);
    $stmt->execute($self->ID(), $member_id, $new_to_program, $enrolment_status);
    
}

sub withdraw_enrolment {
    my $self = shift;
    my $enrolment_id = shift;

    my $sql = qq[
        UPDATE tblProgramEnrolment
        SET 
            intStatus = ?, 
            dtUnenroled = now()
        WHERE 
            intProgramEnrolmentID = ?
            AND intProgramID = ?
    ];
    my $stmt = $self->{'db'}->prepare($sql);
    $stmt->execute($Defs::RECSTATUS_DELETED, $enrolment_id, $self->ID());
    
    # Return true if we actually updated rows
    return $stmt->rows() > 0 ? 1 : 0;
}

sub get_enrolled_members{
    my $self = shift;
    my $params = shift;
    
    my @where_conditions;
    my @values;
    
    # Program
    push @where_conditions, 'intProgramID = ?';
    push @values, $self->ID();
    
    # Status
    push @where_conditions, 'PE.intStatus = ?';
    push @values, $Defs::RECSTATUS_ACTIVE;
    
    if (defined $params->{'program_enrolment_id'}){
        push @where_conditions, 'intProgramEnrolmentID = ?';
        push @values, $params->{'program_enrolment_id'};
    }
    
    # New to Program
    if (defined $params->{'new_to_program'}){
        push @where_conditions, 'intNewToProgram = ?';
        push @values, $params->{'new_to_program'};
    }

    # Enrolment Date searching
    if (defined $params->{'enrolled_before'} && $params->{'enrolled_before'} =~ m/^\d{4}-\d{1,2}-\d{1,2}$/){
        push @where_conditions, 'dtEnroled < ?';
        push @values, $params->{'enrolled_before'};
    }
    if (defined $params->{'enrolled_after'} && $params->{'enrolled_after'} =~ m/^\d{4}-\d{1,2}-\d{1,2}$/){
        push @where_conditions, 'dtEnroled > ?';
        push @values, $params->{'enrolled_after'};
    }
    
    my $where_statement = join (' AND ', @where_conditions);

    my $search_sql = qq[
        SELECT 
            M.*,
            PE.intProgramEnrolmentID,
            PE.intNewToProgram,
            PE.intStatus as intEnrolmentStatus
        FROM
            tblProgramEnrolment AS PE
            JOIN tblMember AS M ON (PE.intMemberID = M.intMemberID)
        WHERE
            $where_statement
    ];

    my $search_stmt = $self->{'db'}->prepare($search_sql);
    $search_stmt->execute( @values );
    
    my $enrolled_members = $search_stmt->fetchall_arrayref({});
    
    return $enrolled_members
}

sub get_assoc_id{
    my $self = shift;
    
    return $self->{'DBData'}->{'intAssocID'} || 0;
}

sub get_program_template_obj{
    my $self = shift;

    if (!defined $self->{'program_template_obj'}){
        my $program_template_obj = ProgramTemplateObj->new(
            'ID' => $self->{'DBData'}->{'intProgramTemplateID'},
            'db' => $self->{'db'},      
        );
        
        $program_template_obj->load();
        
        $self->{'program_template_obj'} = $program_template_obj;
    }

    return $self->{'program_template_obj'};
}

sub get_facility_obj{
    my $self = shift;

    if (!defined $self->{'facility_obj'}){
        my $facility_obj = FacilityObj->new(
            'ID' => $self->{'DBData'}->{'intFacilityID'},
            'db' => $self->{'db'},      
        );
        $facility_obj->load();
        
        $self->{'facility_obj'} = $facility_obj;
    }

    return $self->{'facility_obj'};
}

sub get_location_obj {
    my $self = shift;

    #TODO: Update this when we expand programs to support different 'locations'
    # At the moment, only have national facilities

    return $self->get_facility_obj();
}

sub have_permission{
    my $self = shift;
    my $param = shift;
    
    # only perform permission checks if we have an ID, else we are a new object
    if ($self->ID()){
        
        my $assoc_id = $param->{'assoc_id'};
        my $auth_level = $param->{'auth_level'};
        if ($assoc_id && $assoc_id > 0 ){
            # If we have an assoc, check against that assoc
            if($self->{'DBData'}{'intAssocID'} != $assoc_id){
                # Keep off the grass!
                return 0; 
            }
        }
        elsif($auth_level > $Defs::LEVEL_ASSOC){
            # Failing having an assoc, check against auth level and check permissions on the template
            my $program_template_obj = $self->get_program_template_object();
            return $program_template_obj->have_permission($param);
        }
        else{
            # Who are you and why should I care?
            return 0;
        }
    }
    
    return 1;
}

sub get_products{
    my $self = shift;
    
    my @product_ids = ();
    
    my $program_template_obj = $self->get_program_template_obj();
    
    if (ref $program_template_obj){
        my $rego_form_id = $program_template_obj->get_rego_form_id();
        
        if ($rego_form_id){
            my $sql = qq[
                SELECT 
                    intProductID
                FROM
                    tblRegoFormProducts
                WHERE
                    intRegoFormID = ?
            ];
            my $stmt = $self->{'db'}->prepare($sql);
            $stmt->execute($rego_form_id);
            
            foreach my $ref (@{$stmt->fetchall_arrayref()}){ # Fetch the first row only
                push @product_ids, $ref->[0];
            };
        }    
    }
    
    return \@product_ids
}

sub get_contact_email{
    my $self = shift;
    my $Data = shift;
    
    #TODO: have contacts per program? Future development
    
    # For now just use the primary contact for the Assoc
    my $contacts = $self->get_contacts();
    
    my $email = '';
    
    if (ref($contacts) eq 'ARRAY'){
        foreach my $contact (@$contacts){
            $email = $contact->{'strContactEmail'} || '';
            last if $email;
        }
    }
    
    return $email;
    
}

# We are only full if we have a capacity, and we have enrolments equaling or greater than our capacity
sub is_full{
    my $self = shift;
    
    my $capacity = $self->getValue('intCapacity') || 0;
    my $enrolments = $self->get_enrolment_count() || 0;
    
    if ( $capacity && ($enrolments >= $capacity) ){
        return 1; # Full!
    }
    
    return 0;
    
}

sub get_enrolment_count{
    my $self = shift;
    
    my $sql = qq[
        SELECT 
            count(intMemberID) as intEnrolmentCount
        FROM
            tblProgramEnrolment
        WHERE
            intProgramID = ?
            AND intStatus != ?
    ];
    my $stmt = $self->{'db'}->prepare($sql);
    $stmt->execute($self->ID(), $Defs::RECSTATUS_DELETED);
    
    my $enrolment_count = $stmt->fetchrow_array();

    return $enrolment_count || 0;
}

sub get_prices{
    my $self = shift;
    
    my %costs;
    
    my $products_list = $self->get_products();
    
    if (@{$products_list}){
        
        my $product_price_sql = qq[
            SELECT
                P.curDefaultAmount, 
                PP.curAmount
            FROM
                tblProducts as P 
                LEFT JOIN tblProductPricing as PP 
                    ON (
                        PP.intProductID = P.intProductID 
                        AND PP.intID = ?
                        AND PP.intLevel = ?
                    )
            WHERE
                P.intProductID = ?
        ];
        
        my $product_price_stmt = $self->{'db'}->prepare($product_price_sql);
        
        
        foreach my $product_id (@{$products_list}){
            # Load products?
            $product_price_stmt->execute($self->ID(), $Defs::LEVEL_PROGRAM, $product_id);
            
            my ($default_price, $program_level_price) = $product_price_stmt->fetchrow_array();
            my $product_price = $default_price;
            
            if (defined $program_level_price && $program_level_price ne 'NULL' ){
                $product_price = $program_level_price
            }
            
            # find attributes to filter
            my $attributes = get_product_attributes({
                'dbh' => $self->{'db'},
                'product_id' => $product_id,
            });
            
            my $type = 'none';

            if (ref $attributes){
                if ( $attributes->{$Defs::PRODUCT_PROGRAM_NEW}->[0] ){
                    $type = 'new';
                }
                elsif ( $attributes->{$Defs::PRODUCT_PROGRAM_RETURNING}->[0] ){
                    $type = 'returning';
                }
            }
            
            $costs{$type} += $product_price; 
        }
    }
    
    return \%costs;
}

sub get_logo_url{
    my $self = shift;

    
    # In future we can have logos for programs themselves or from the templates even
    # But for now we are just using the assoc logo
    
    my $logo_url = Logo::showLogo(
        {'db' => $self->{'db'}}, # Data (but only need db handle)
        $Defs::LEVEL_ASSOC,      # Entity Type
        $self->get_assoc_id(),   # Entity ID
        '',                      # Client
        0,                       # Allow Edit
        0,                       # Width (not used)
        0,                       # Height (not used)
        1,                       # url only
    );

    return $logo_url || '';
}

sub get_contacts{
    my $self = shift;
    
    if (!defined $self->{'contacts'}){
        my $contacts = get_service_contacts({
            'dbh'      => $self->{'db'},
            'assoc_id' => $self->get_assoc_id(),
            'contact_types' => $ServicesContacts::CONTACTS_PRIMARY,
        });
        
        $self->{'contacts'} = $contacts;

    }

    return $self->{'contacts'};
}

sub valid_dob{
    my $self = shift;
    my $dob_dt = shift;
    
    my $valid = 1;
    my @reasons = ();
    
    my $dtMaxDOB = $self->getValue('dtMaxDOB'); # MaxDOB is the OLDEST DOB someone can have (earlist date)
    my $dtMinDOB = $self->getValue('dtMinDOB'); # MinDOB is the YOUNGEST DOB someone can have (latest date)
    
    # if we have a valid max DOB date and no exceptions allowed...
    if ($dtMaxDOB && ($dtMaxDOB ne '0000-00-00') && !$self->getValue('intAllowMaxAgeExceptions')){
        my $max_dob_dt = DateTime::Format::MySQL->parse_date($dtMaxDOB);

        if (blessed($dob_dt) && $dob_dt->isa('DateTime')){
            
            $dob_dt->truncate( to => 'day');
            # Check if DOB is before the max DOB
            if ($dob_dt < $max_dob_dt){
                $valid = 0; # DOB was too old
                push @reasons, 'Provided Date of Birth was too old';
            }
        }
        else{
            $valid = 0; # no date time object
            push @reasons, 'Valid Date of Birth is required for this Program'; #TODO: config prog
        }
    }
    
    # if we have a valid min DOB date and no exceptions allowed...
    if ($dtMinDOB && ($dtMinDOB ne '0000-00-00') && !$self->getValue('intAllowMinAgeExceptions')){
        my $min_dob_dt = DateTime::Format::MySQL->parse_date($dtMinDOB);

        if (blessed($dob_dt) && $dob_dt->isa('DateTime')){
            # Check if DOB is before the max DOB
            if ($dob_dt > $min_dob_dt){
                $valid = 0; # DOB was too young
                push @reasons, 'Provided Date of Birth was too young';
            }
        }
        elsif ($valid){
            $valid = 0; # no date time object
            push @reasons, 'Valid Date of Birth is required for this Program';
        }
    }
    
    if (wantarray){
        return $valid, \@reasons;
    }
    else{
        return $valid;
    }
}

1;
