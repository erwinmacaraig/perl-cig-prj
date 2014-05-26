#
# $Header: svn://svn/SWM/trunk/web/comp/Fixture.pm 10320 2013-12-17 06:16:50Z apurcell $
#

package FacilityObj;

use strict;
use lib ".", "..", "../..", "comp";

require Exporter;

use base qw(BaseObject);

use Defs;
use Log;

require ProgramUtils;
require ProgramObj;
require ProgramTemplateObj;

sub new {

    my $this = shift;
    my $class = ref($this) || $this;
    my %params=@_;
    my $self = {};
    ##bless selfhash to class
    bless $self, $class;
    
    #Set Defaults
    $self->{'db'} = $params{'db'};
    $self->{'ID'} = $params{'ID'};
    
    return undef unless $self->{'db'};
    return undef unless $self->{'ID'};
    
    # load DB data if provided
    if ($params{'DBData'}){
        $self->{'DBData'} = $params{'DBData'};
    }

    ##return the blessed hash
    return $self;
}

sub delete {
    my $self = shift;

    my $result = $self->SUPER::delete();
    
    if (!$result){
        WARN "Deleting Facility failed for $self->{'ID'}";
    }
    return $result;
}

sub _can_delete_self {
    my $self = shift;
    
    # Should be nothing to stop this
    
    return 1;
}

sub _can_delete_children {
    my $self = shift;
    
    #TODO: check for active programs run at this facility
    
    #TODO: check for courts (when implemented) and make sure they don't have any matches or events (when implemented)
    return 1;
}

sub _delete_children {
    my $self = shift;
    
    #TODO: Delete courts, when implemented
  
    return;
}

sub _delete_self {
    my $self = shift;

    # Delete Self
    $self->{'DBData'}{'intRecStatus'} = $Defs::RECSTATUS_DELETED;
    
    $self->write();
} 

sub _get_sql_details{
    
    my $field_details = {
        'fields_to_ignore' => [],
        'table_name' => 'tblFacilities',
        'key_field' => 'intFacilityID',
    };
    
    return $field_details;
}

sub get_programs{
    my ($self, $params) = @_;

    $params->{'facility_id'} = $self->ID();
    my $programs = ProgramUtils::get_programs($self->{'db'}, $params);

    return $programs || [];
}

sub get_program_templates{
    my ($self, $params) = @_;
    
    my $programs = $self->get_programs();
    my %template_ids;
    
    foreach my $program (@$programs){
        $template_ids{$program->get_template_id()} ++;
    }
    
    my @program_templates;
    
    foreach my $template_id (sort keys %template_ids){
        my $program_template_obj = ProgramTemplateObj->new(
            'ID' => $template_id,
            'db' => $self->{'db'},
        );
        
        $program_template_obj->load();
        
        push @program_templates, $program_template_obj;
    }
    
    return \@program_templates;
}

# Returns single line address string
sub get_address {
    my $self = shift;
    
    my $address_string = '';
    
    my @field_order = qw(strAddress1 strAddress2 strSuburb strState strPostalCode);
    
    foreach my $field (@field_order) {
        my $value = $self->getValue($field);
        if ($value) {
            $address_string .= " $value";
        }
    }

    return $address_string;
}
1;
