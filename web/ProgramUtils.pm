#
# $Header: svn://svn/SWM/trunk/web/Venues.pm 10333 2013-12-18 23:54:25Z apurcell $
#

package ProgramUtils;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(get_program_titles);
@EXPORT_OK = qw(get_program_titles);

use lib ".", "..", "../..",;

use strict;
use Log;
use Defs;
use Data::Dumper;

require ProgramObj;

# Just returns the singular and pural titles for programs
sub get_program_titles {
    my $Data = shift;
    
    my $program_singular = $Data->{'SystemConfig'}{'Custom_Program_Title_Singular'} || 'Program';
    my $program_plural = $Data->{'SystemConfig'}{'Custom_Program_Title_Plural'} || 'Programs';
    
    return ($program_singular, $program_plural);
}

sub get_programs {
    my ($db, $params) = @_;
 
    my @programs_list;
    
    my @where_clauses = ( 'intStatus <> ?' );
    my @values = ($Defs::RECSTATUS_DELETED);
    
    if ($params->{'facility_id'}){
        push @where_clauses,  'intFacilityID = ?';
        push @values, $params->{'facility_id'}; 
    }
    
    if ( defined $params->{'assoc_id'} ) {
        push @where_clauses,  'intAssocID = ?';
        push @values, $params->{'assoc_id'}; 
    }
    
    if ($params->{'program_template_id'}){
        push @where_clauses,  'intProgramTemplateID = ?';
        push @values, $params->{'program_template_id'}; 
    }
    
    if ($params->{'program_id'}){
        push @where_clauses,  'intProgramID = ?';
        push @values, $params->{'program_id'}; 
    }

    if ( defined $params->{'search_days'} ) {
        my @days = @{ $params->{'search_days'} };
        my $days_clause = '';
        $days_clause = join( ' OR ', map { 'int' . $_ . ' = ?' } @days );
        $days_clause = '(' . $days_clause . ')';
        push @where_clauses, $days_clause;
        for my $day (@days) {
            push @values, 1;
        }
    }
    
    my $where_statement = join(' AND ', @where_clauses);
     
    my $search_sql = qq[
        SELECT
          *
        FROM 
          tblPrograms
        WHERE 
          $where_statement
    ];


    my $search_stmt = $db->prepare($search_sql);
    $search_stmt->execute(@values);

    my $programs = $search_stmt->fetchall_arrayref({});
    
    foreach my $program_dref (@{$programs}){
        my $program_obj = ProgramObj->new(
            'ID' => $program_dref->{intProgramID},
            'db' => $db,
            'DBData' => $program_dref,
        );
        
        push @programs_list, $program_obj;
    }  
        
    return \@programs_list
}

1;