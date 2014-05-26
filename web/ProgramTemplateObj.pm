#
# $Header: svn://svn/SWM/trunk/web/comp/Fixture.pm 10320 2013-12-17 06:16:50Z apurcell $
#

package ProgramTemplateObj;

use strict;

use lib ".", "..", "../..", "comp";

use base qw(BaseObject);

require ProgramUtils;
use Defs;
use Log;

sub delete  {
    my $self = shift;

    my $result = $self->SUPER::delete();
    
    if (!$result){
        WARN "Deleting Facility failed for $self->{'ID'}";
    }
    return $result;
}

sub _can_delete_self {
    my $self = shift;
    
    # Can only delete IF there are no programs active/completed/inactive created from this template
    my $count = $self->get_programs_count();
    
    if ((!defined $count) || ($count > 0)){
        WARN "Can not delete ProgramTemplate $self->ID() as it has programs that use it's template";
        return 0;
    }
    
    return 1;
}

# Returns a count of active/inactive programs created from this template
# Ignores deleted programs
sub get_programs_count{
    
    #TODO: Return a count of the number of programs created from this template
    #TODO: options for active, inactive?
    #TODO: Ignore Deleted
    
    return 0;
    
}


# Returns an array of program objects of active/inactive programs created from this template
# Ignores deleted programs
sub get_programs {
    my ($self, $params) = @_;

    $params->{'program_template_id'} = $self->ID();
    my $programs = ProgramUtils::get_programs($self->{'db'}, $params);

    return $programs || [];
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
        'table_name' => 'tblProgramTemplates',
        'key_field' => 'intProgramTemplateID',
    };
    
    return $field_details;
}

sub name{
    my $self = shift;
    
    return $self->getValue('strTemplateName') || '';
}

sub get_display_name{
    my $self = shift;
    
    my $age_display = 'all ages';
    
    my $min_age = $self->{'DBData'}{'intMinSuggestedAge'};
    my $max_age = $self->{'DBData'}{'intMaxSuggestedAge'};
    
    if ($min_age && $max_age){
        $age_display = "ages $min_age to $max_age";
    }
    elsif ($min_age){
        $age_display = "ages $min_age and up";
    }
    else{
        $age_display = "ages $max_age and under";
    }
    
    my $display_name = $self->name() . ' (' . $age_display . ')';
    
    return $display_name;
    
}

sub have_permission{
	my $self = shift;
	my $param = shift;
	
	# only perform permission checks if we have an ID, else we are a new object
	if ($self->ID()){
		
		my $realm_id = $param->{'realm_id'};
		my $subrealm_id = $param->{'subrealm_id'} || -1;
		
		if (defined $self->{'DBData'}->{'intRealmID'} && defined $self->{'DBData'}->{'intSubRealmID'}){
			if ( $self->{'DBData'}->{'intRealmID'} != -1 && $self->{'DBData'}->{'intRealmID'} != $realm_id){
				# Realm did not match
				return 0;
			}
			
			if ( $self->{'DBData'}->{'intSubRealmID'} != -1 && $subrealm_id != -1 && $self->{'DBData'}->{'intSubRealmID'} != $subrealm_id){
				# Subrealm did not match or didnt have acess to all subrealms
				return 0;
			}
		}
	}
	
	return 1;
}

sub get_rego_form_id{
    my $self = shift;
    
    return $self->getValue('intRegoFormID');
    
}

1;
