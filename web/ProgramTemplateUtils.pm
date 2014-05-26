#
# $Header: svn://svn/SWM/trunk/web/Venues.pm 10333 2013-12-18 23:54:25Z apurcell $
#

package ProgramTemplateUtils;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(get_available_program_templates get_program_template_field_details get_available_rego_forms get_program_template_titles);
@EXPORT_OK = qw(get_available_program_templates get_program_template_field_details get_available_rego_forms get_program_template_titles);

use lib ".", "..", "../..", "comp";

use strict;
use Log;
use Defs;
use Reg_common;
use Data::Dumper;

require ProgramTemplateObj;

sub get_available_program_templates {
    my $params = shift;
    
    my ($dbh, $realm_id, $subrealm_id) = @{$params}{qw/ dbh realm_id subrealm_id /};
    
    # If we dont have a database handle or a realm, then there is not much point in living...
    return unless ($dbh && $realm_id);
    
    my @where_conditions;
    my @values;
    
    # Realm
    push @where_conditions, 'intRealmID = ?';
    push @values, $realm_id;
    
    #TODO: Sub-realm
    
    push @where_conditions, 'intStatus = ?';
    push @values, $Defs::RECSTATUS_ACTIVE;
    
    my $where_statement = join (' AND ', @where_conditions);

    my $search_sql = qq[
        SELECT 
            *
        FROM
            tblProgramTemplates
        WHERE
            $where_statement
        ORDER BY 
            strTemplateName
    ];
    
    my $search_stmt = $dbh->prepare($search_sql);
    $search_stmt->execute( @values );
    my $program_templates = $search_stmt->fetchall_hashref('intProgramTemplateID') || [];
    my @program_templates_list;
    
    foreach my $programTemplateID (keys %{$program_templates}){
        my $program_template_obj = ProgramTemplateObj->new(
            'ID' => $programTemplateID,
            'db' => $dbh,
            'DBData' => $program_templates->{$programTemplateID},
        );
        
        push @program_templates_list, $program_template_obj;
    }
    
    return \@program_templates_list;
}

#TODO: move this into program template object
sub get_program_template_field_details{
    my $params = shift;
    my ($dbh, $program_template_id) = @{$params}{qw/ dbh program_template_id /};
    
    # If we dont have a database handle or a realm, then there is not much point in living...
    return {} unless ($dbh && $program_template_id);
    
    # Fetch the template and then fetch the config

    my $template_sql = qq[
        SELECT 
            *
        FROM
            tblProgramTemplates
        WHERE
            intProgramTemplateID = ?
    ];
    
    my $template_stmt = $dbh->prepare($template_sql);
    $template_stmt->execute( $program_template_id );
    my $program_template_details = $template_stmt->fetchrow_hashref();
    
    # Now for the field config 
    my $config_sql = qq[
        SELECT 
            *
        FROM
            tblProgramTemplatesConfig
        WHERE
            intProgramTemplateID = ?
    ];
    
    my $config_stmt = $dbh->prepare($config_sql);
    $config_stmt->execute( $program_template_id );
    my $program_template_config = $config_stmt->fetchall_hashref('strField');
  
    my %fields;
  
    foreach my $field (keys %{$program_template_details}){
        $fields{$field} = {
            'value'      => $program_template_details->{$field},
            'readonly'   => $program_template_config->{$field}->{'intReadonly'} || 0,
            'compulsory' => $program_template_config->{$field}->{'intCompulsory'} || 0,
            'hidden'     => $program_template_config->{$field}->{'intHidden'} || 0,
        };

    }
    
    return \%fields;
    
}

# Gets a list of availible member to program rego forms for this template
sub get_available_rego_forms{
    my $params = shift;
    
    my ($dbh, $realm_id, $subrealm_id, $Data) = @{$params}{qw/ dbh realm_id subrealm_id Data /};

    my %rego_form_list;
    $rego_form_list{'0'} = 'None';
    
    if ($realm_id && $Data) {
        $subrealm_id ||= -1;
        
        my ($entity_type, $entity_id) = getEntityValues($Data->{'clientValues'});
        my $entityStructure = getEntityStructure($Data, $entity_type, $entity_id);
        
        my @node_id_list = (0, $entity_id);
        foreach my $entityArr (@$entityStructure) {
            next if @$entityArr[0] <= $Defs::LEVEL_ASSOC;
            push @node_id_list, @$entityArr[1];
        }
        
        my $node_ids =join(', ', map { '?' } @node_id_list);
        
        my $rego_search_sql = qq[
            SELECT 
                intRegoFormID,
                strRegoFormName 
            FROM 
                tblRegoForm 
            WHERE 
                intRegoType = ?
            AND intAssocID = -1
            AND intRealmID = ?
            AND intCreatedID IN ($node_ids)
        ];
        
        my $rego_search_stmt = $dbh->prepare($rego_search_sql);
        $rego_search_stmt->execute( $Defs::REGOFORM_TYPE_MEMBER_PROGRAM, $realm_id, @node_id_list);
       my $temp = $Defs::REGOFORM_TYPE_MEMBER_PROGRAM; 
        my $rego_forms = $rego_search_stmt->fetchall_hashref('intRegoFormID');
      
        foreach my $id (keys %{$rego_forms}){
            $rego_form_list{$id} = ($rego_forms->{$id}->{'strRegoFormName'} || 'Rego Form') . ' (' . $rego_forms->{$id}->{'intRegoFormID'} . ')';
        }
    }
    
    return \%rego_form_list;
    
}

# Just returns the singular and pural titles for program templates
sub get_program_template_titles {
    my $Data = shift;
    
    my $program_template_singular = $Data->{'SystemConfig'}{'Custom_Program_Tempalte_Title_Singular'} || 'Program Template';
    my $program_template_plural = $Data->{'SystemConfig'}{'Custom_Program_Tempalte_Title_Plural'} || 'Program Templates';
    
    return ($program_template_singular, $program_template_plural);
}


1;
