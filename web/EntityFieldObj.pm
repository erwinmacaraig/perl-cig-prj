package EntityFieldObj;

use strict;
use BaseObject;
use Switch;
use Defs;
use Data::Dumper;
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
    my ($field, $prefixID) = @_;

    $self->getValue($field);
    my $inputFieldName = $self->_inputFieldName($field, $prefixID);
    my $fieldIDhtml = qq[<input type='hidden' name="$inputFieldName"/>];
    return $fieldIDhtml;
}

sub fieldNameHtml {
    my $self = shift;
    my ($field, $prefixID) = @_;

    $self->getValue($field);
    my $inputFieldName = $self->_inputFieldName($field, $prefixID);
    my $fieldNamehtml = qq[<input type='text' name='$inputFieldName'/>];
    return $fieldNamehtml;
}

sub disciplineHtml {
    my $self = shift;
    my ($field, $prefixID) = @_;

    my $options = qq[
        <option value="">Select Sport</option>
    ];

    my $selected = "";
    foreach my $discipline (keys %Defs::sportType) {
        $selected = "selected" if ($self->getValue($field) eq $discipline);
        $options .= qq[
            <option $selected value="$discipline">$Defs::sportType{$discipline}</option>
        ];
    }
    my $inputFieldName = $self->_inputFieldName($field, $prefixID);
    my $fieldDisciplinehtml = qq[<select name='$inputFieldName'>$options</select>];
    return $fieldDisciplinehtml;
}

sub capacityHtml {
    my $self = shift;
    my ($field, $prefixID) = @_;

    $self->getValue($field);
    my $inputFieldName = $self->_inputFieldName($field, $prefixID);
    my $fieldCapacityhtml = qq[<input type='text' name='$inputFieldName'/>];
    return $fieldCapacityhtml;
}

sub fieldOrderNumberHtml {
    my $self = shift;
    my ($field, $prefixID) = @_;

    $self->getValue($field);
    my $inputFieldName = $self->_inputFieldName($field, $prefixID);
    my $fieldOrderNumberhtml = qq[<input type='text' name='$inputFieldName'/>];
    return $fieldOrderNumberhtml;
}

sub groundNatureHtml {
    my $self = shift;
    my ($field, $prefixID) = @_;

    my $options = qq[
        <option value="">Select Ground Nature</option>
    ];

    my $selected = "";
    foreach my $groundNature (keys %Defs::fieldGroundNatureType) {
        $selected = "selected" if ($self->getValue($field) eq $groundNature);
        $options .= qq[
            <option $selected value="$groundNature">$Defs::fieldGroundNatureType{$groundNature}</option>
        ];
    }
    my $inputFieldName = $self->_inputFieldName($field, $prefixID);
    my $fieldGroundNaturehtml = qq[<select name='$inputFieldName'>$options</select>];
    return $fieldGroundNaturehtml;
}

sub lengthHtml {
    my $self = shift;
    my ($field, $prefixID) = @_;

    $self->getValue($field);
    my $inputFieldName = $self->_inputFieldName($field, $prefixID);
    my $fieldLengthhtml = qq[<input type='text' name='$inputFieldName'/>];
    return $fieldLengthhtml;
}

sub widthHtml {
    my $self = shift;
    my ($field, $prefixID) = @_;

    $self->getValue($field);
    my $inputFieldName = $self->_inputFieldName($field, $prefixID);
    my $fieldWidthhtml = qq[<input type='text' name='$inputFieldName'/>];
    return $fieldWidthhtml;
}

sub getHtml {
    my $self = shift;
    my ($field, $prefixID) = @_;

    switch($field){
        case 'intEntityFieldID' {
            return $self->fieldIDHtml($field, $prefixID);
        }
        case 'intFieldOrderNumber' {
            return $self->fieldOrderNumberHtml($field, $prefixID);
        }
        case 'strName' {
            return $self->fieldNameHtml($field, $prefixID);
        }
        case 'strDiscipline' {
            return $self->disciplineHtml($field, $prefixID);
        }
        case 'intCapacity' {
            return $self->capacityHtml($field, $prefixID);
        }
        case 'strGroundNature' {
            return $self->groundNatureHtml($field, $prefixID);
        }
        case 'dblLength' {
            return $self->lengthHtml($field, $prefixID);
        }
        case 'dblWidth' {
            return $self->widthHtml($field, $prefixID);
        }
        else {
            return;
        }
    }
}

sub _inputFieldName {
    my $self = shift;
    my ($field, $prefixID) = @_;

    return $field . "_" . $prefixID;
}

1;
