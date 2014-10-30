package EntityFieldObj;

use strict;
use BaseObject;
use Switch;
use Defs;
our @ISA =qw(BaseObject);

sub load {
  my $self = shift;

  my $st=qq[
    SELECT * 
    FROM tblEntityFields
    WHERE intEntityFieldID = ?
  ];

  my $q = $self->{'db'}->prepare($st);
  $q->execute($self->{'ID'});
  if($DBI::err)  {
    $self->LogError($DBI::err);
  }
  else  {
    $self->{'DBData'}=$q->fetchrow_hashref();  
  }
}

sub name {
  my $self = shift;
    my($db) = @_;
    return $self->{'DBData'}{'intEntityID'} 
        || $self->{'DBData'}{'strName'} 
        || '';
}

sub _get_sql_details{

    my $field_details = {
        #'fields_to_ignore' => ['tTimestamp'],
        'table_name' => 'tblEntityFields',
        'key_field' => 'intEntityFieldID',
    };

    return $field_details;
}

sub fieldIDHtml {
    my $self = shift;
    my ($field) = @_;

    $self->getValue($field);
    my $fieldIDhtml = "";
    return $fieldIDhtml;
}

sub fieldNameHtml {
    my $self = shift;
    my ($field) = @_;

    my $fieldNamehtml = "";
    return $fieldNamehtml;
}

sub disciplineHtml {
    my $self = shift;
    my ($field) = @_;

    my $fieldDisciplinehtml = "";
    return $fieldDisciplinehtml;
}

sub capacityHtml {
    my $self = shift;
    my ($field) = @_;

    my $fieldCapacityhtml = "";
    return $fieldCapacityhtml;
}

sub fieldOrderNumberHtml {
    my $self = shift;
    my ($field) = @_;

    my $fieldOrderNumberhtml = "";
    return $fieldOrderNumberhtml;
}

sub groundNatureHtml {
    my $self = shift;
    my ($field) = @_;

    my $fieldGroundNaturehtml = "";
    return $fieldGroundNaturehtml;
}

sub lengthHtml {
    my $self = shift;
    my ($field) = @_;

    my $fieldLengthhtml = "";
    return $fieldLengthhtml;
}

sub widthHtml {
    my $self = shift;
    my ($field) = @_;

    my $fieldWidthhtml = "";
    return $fieldWidthhtml;
}

sub getHtml {
    my $self = shift;
    my ($field) = @_;

    switch($field){
        case 'intEntityFieldID' {
            return $self->fieldNameHtml($field);
        }
        case 'intFieldOrderNumber' {
            return $self->fieldOrderNumberHtml($field);
        }
        case 'strName' {
            return $self->fieldNameHtml($field);
        }
        case 'strDiscipline' {
            return $self->disciplineHtml($field);
        }
        case 'intCapacity' {
            return $self->capacityHtml($field);
        }
        case 'strGroundNature' {
            return $self->groundNatureHtml($field);
        }
        case 'dblLength' {
            return $self->lengthHtml($field);
        }
        case 'dblWidth' {
            return $self->widthHtml($field);
        }
        else {
            return;
        }
    }
}

1;
