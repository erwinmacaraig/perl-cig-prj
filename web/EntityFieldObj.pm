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
    my ($field, $prefixID, $lang) = @_;

    my $existingValue = $self->getValue($field) || '';
    my $inputFieldName = $self->_inputFieldName($field, $prefixID);
    my $fieldIDhtml = qq[<input type='hidden' name="$inputFieldName" value="$existingValue"/>];
    return $fieldIDhtml;
}

sub fieldNameHtml {
    my $self = shift;
    my ($field, $prefixID, $lang) = @_;

    my $existingValue = $self->getValue($field) || '';
    my $inputFieldName = $self->_inputFieldName($field, $prefixID);
    my $fieldNamehtml = qq[<input type='text' name='$inputFieldName' value="$existingValue"/>];
    return $fieldNamehtml;
}

sub disciplineHtml {
    my $self = shift;
    my ($field, $prefixID, $lang) = @_;

    my $options = qq[
        <option value="">].$lang->txt('Select Discipline').qq[</option>
    ];

    my $selected = "";
    foreach my $discipline (keys %Defs::sportType) {
        $selected = ($self->getValue($field) eq $discipline) ? "selected" : '';
        $options .= qq[
            <option $selected value="$discipline">].$lang->txt($Defs::sportType{$discipline}).qq[</option>
        ];
    }
    my $inputFieldName = $self->_inputFieldName($field, $prefixID);
    my $fieldDisciplinehtml = qq[<select name='$inputFieldName'>$options</select>];
    return $fieldDisciplinehtml;
}

sub capacityHtml {
    my $self = shift;
    my ($field, $prefixID, $lang) = @_;

    my $existingValue = $self->getValue($field);
    my $inputFieldName = $self->_inputFieldName($field, $prefixID);
    my $fieldCapacityhtml = qq[<input type='text' name='$inputFieldName' value="$existingValue"/>];
    return $fieldCapacityhtml;
}

sub fieldOrderNumberHtml {
    my $self = shift;
    my ($field, $prefixID, $lang) = @_;

    my $existingValue = $self->getValue($field) || '';
    my $inputFieldName = $self->_inputFieldName($field, $prefixID);
    my $fieldOrderNumberhtml = qq[<input type='text' name='$inputFieldName' value="$existingValue"/>];
    return $fieldOrderNumberhtml;
}

sub groundNatureHtml {
    my $self = shift;
    my ($field, $prefixID, $lang) = @_;

    my $options = qq[
        <option value="">].$lang->txt('Select Type of Field').qq[</option>
    ];

    my $selected = "";
    foreach my $groundNature (keys %Defs::fieldGroundNatureType) {
        $selected = ($self->getValue($field) eq $groundNature) ? "selected" : "";
        $options .= qq[
            <option $selected value="$groundNature">].$lang->txt($Defs::fieldGroundNatureType{$groundNature}).qq[</option> ];
    }
    my $inputFieldName = $self->_inputFieldName($field, $prefixID);
    my $fieldGroundNaturehtml = qq[<select name='$inputFieldName'>$options</select>];
    return $fieldGroundNaturehtml;
}

sub lengthHtml {
    my $self = shift;
    my ($field, $prefixID, $lang) = @_;

    my $existingValue = $self->getValue($field) || '';
    my $inputFieldName = $self->_inputFieldName($field, $prefixID);
    my $fieldLengthhtml = qq[<input type='text' name='$inputFieldName' value="$existingValue"/>];
    return $fieldLengthhtml;
}

sub widthHtml {
    my $self = shift;
    my ($field, $prefixID, $lang) = @_;

    my $existingValue = $self->getValue($field) || '';
    my $inputFieldName = $self->_inputFieldName($field, $prefixID);
    my $fieldWidthhtml = qq[<input type='text' name='$inputFieldName' value="$existingValue"/>];
    return $fieldWidthhtml;
}

sub getHtml {
    my $self = shift;
    my ($field, $prefixID, $lang) = @_;

    switch($field){
        case 'intEntityFieldID' {
            return $self->fieldIDHtml($field, $prefixID, $lang);
        }
        case 'intFieldOrderNumber' {
            return $self->fieldOrderNumberHtml($field, $prefixID, $lang);
        }
        case 'strName' {
            return $self->fieldNameHtml($field, $prefixID, $lang);
        }
        case 'strDiscipline' {
            return $self->disciplineHtml($field, $prefixID, $lang);
        }
        case 'intCapacity' {
            return $self->capacityHtml($field, $prefixID, $lang);
        }
        case 'strGroundNature' {
            return $self->groundNatureHtml($field, $prefixID, $lang);
        }
        case 'dblLength' {
            return $self->lengthHtml($field, $prefixID, $lang);
        }
        case 'dblWidth' {
            return $self->widthHtml($field, $prefixID, $lang);
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
