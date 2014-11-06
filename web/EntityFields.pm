package EntityFields;

use strict;
use lib '.', '..';
use Defs;
use EntityFieldObj;
use Switch;
use Flow_DisplayFields;
use Data::Dumper;

sub new {
    my $class = shift;
    my (%args) = @_;

    my $self = {
        _count              => $args{count},
        _entityID           => $args{entityID},
        _fieldID            => $args{fieldID},
        _fieldOrderNumber   => $args{fieldOrderNumber},
        _name               => $args{name},
        _discipline         => $args{discipline},
        _capacity           => $args{capacity},
        _groundNature       => $args{groundNature},
        _length             => $args{length},
        _width              => $args{width},
        _data               => $args{data},
        _DBData             => $args{DBData},
        _HTMLFields         => $args{HTMLFields} || '',
        _errors             => undef,
    };

    $self = bless ($self, $class);

    return $self;
}

sub getEntityID {
    my ($self) = shift;
    return $self->{_entityID};
}

sub getFieldID {
    my ($self) = shift;
    return $self->{_fieldID};
}

sub getFieldOrderNumber {
    my ($self) = shift;
    return $self->{_fieldOrderNumber};
}

sub getName {
    my ($self) = shift;
    return $self->{_name};
}

sub getDiscipline {
    my ($self) = shift;
    return $self->{_discipline};
}

sub getCapacity {
    my ($self) = shift;
    return $self->{_capacity};
}

sub getGroundNature {
    my ($self) = shift;
    return $self->{_groundNature};
}

sub getLength {
    my ($self) = shift;
    return $self->{_length};
}

sub getWidth {
    my ($self) = shift;
    return $self->{_width};
}

sub getData {
    my ($self) = shift;
    return $self->{_data};
}

sub getDBData {
    my ($self) = shift;
    return $self->{_DBData};
}

sub getCount {
    my ($self) = shift;
    return $self->{_count};
}

sub getHtmlFields {
    my ($self) = shift;
    return $self->{_HTMLFields};
}

sub getErrors {
    my ($self) = shift;
    return $self->{_errors};
}


sub getAll {
    my ($self) = shift;

    my $db = $self->getData()->{'db'};

    my $st = qq[
        SELECT
            EF.intEntityFieldID,
            EF.intEntityID,
            EF.intFieldOrderNumber,
            EF.strName,
            EF.strDiscipline,
            EF.intCapacity,
            EF.strGroundNature,
            EF.dblLength,
            EF.dblWidth
        FROM
            tblEntityFields EF
        INNER JOIN
            tblEntity E ON (E.intEntityID = EF.intEntityID)
        WHERE
            EF.intEntityID = ?
            AND E.intRealmID = ?
    ];

    my $q = $db->prepare($st);
    $q->execute(
        $self->getEntityID(),
        $self->getData()->{'Realm'},
    );

    my @fields = ();
    my $count = 1;
    while (my $dref = $q->fetchrow_hashref()) {
        $self->setFieldID($dref->{'intEntityFieldID'});
        $self->setName($dref->{'strName'});

        $self->setDBData($dref);
        push @fields, $self->generateSingleRowField($count++, $dref->{'intEntityFieldID'});
        #my $fieldData = {};
        #foreach my $entityFieldCol (keys %{$dref}){
        #    #print STDERR Dumper $entityFieldCol . " " . $dref->{$entityFieldCol};
        #    $fieldData->{$entityFieldCol} = $dref->{$entityFieldCol};
        #}
        #$self->setDBData($fieldData);
        #push @fields, $self->generateSingleRowField($dref->{'intEntityFieldID'}, $dref->{'intEntityFieldID'});
            #push @fields, {
            #entityFieldID   => {value => $dref->{'intEntityFieldID'}, html => $self->fieldIDHtml()},
            #fieldName       => {value => $dref->{'strName'}, html => $self->fieldNameHtml()},
            #discipline      => {value => $dref->{'strDiscipline'}, html => $self->disciplineHtml()},
            #capacity        => {value => $dref->{'intCapacity'}, html => $self->capacityHtml},
            #groundNature    => {value => $dref->{'strGroundNature'}, html => $self->groundNatureHtml()},
            #length          => {value => $dref->{'dblLength'}, html => $self->lengthHtml()},
            #width           => {value => $dref->{'dblWidth'}, html => $self->widthHtml()},
            #intEntityFieldID    => {
            #    value => $dref->{'intEntityFieldID'},
            #    html => $entityFieldObj->getHtml('intEntityFieldID', $dref->{'intEntityFieldID'})
            #},
            #intFieldOrderNumber => {
            #    value => $dref->{'intFieldOrderNumber'},
            #    html => $entityFieldObj->getHtml('intFieldOrderNumber', $dref->{'intFieldOrderNumber'})
            #strName             => {
            #    value => $dref->{'strName'},
            #    html => $entityFieldObj->getHtml('', $dref->{''})
            #},
            #strDiscipline       => {
            #    value => $dref->{'strDiscipline'}
            #    html => $entityFieldObj->getHtml('', $dref->{''})
            #},
            #intCapacity         => {
            #    value => $dref->{'intCapacity'}
            #    html => $entityFieldObj->getHtml('', $dref->{''})
            #},
            #strGroundNature     => {
            #    value => $dref->{'strGroundNature'}
            #    html => $entityFieldObj->getHtml('', $dref->{''})
            #},
            #dblLength           => {
            #    value => $dref->{'dblLength'}
            #    html => $entityFieldObj->getHtml('', $dref->{''})
            #},
            #dblWidth            => {
            #    value => $dref->{'dblWidth'}
            #    html => $entityFieldObj->getHtml('dblWidth', $dref->{'dblWidth'})
            #},
            #};
    }

    return \@fields;
}

sub generateSingleRowField {
    my $self = shift;
    my ($prefixID, $entityFieldID) = @_;

    $entityFieldID ||= 0;

    my $htmlFields = '';
    my $count = $self->getCount();
    my $entityFieldObj = new EntityFieldObj(db => $self->getData()->{'db'}, ID => $entityFieldID);

    #$entityFieldObj->setValues($self->getDBData()) if !$entityFieldID;
    $entityFieldObj->setValues($self->getDBData());
    #$entityFieldObj->load() if $entityFieldID;

    my %row = (
        intEntityFieldID => $entityFieldID ? $entityFieldObj->getHtml('intEntityFieldID', $prefixID) : '',
        intFieldOrderNumber => $entityFieldObj->getHtml('intFieldOrderNumber', $prefixID),
        strName => $entityFieldObj->getHtml('strName', $prefixID),
        strDiscipline => $entityFieldObj->getHtml('strDiscipline', $prefixID),
        intCapacity => $entityFieldObj->getHtml('intCapacity', $prefixID),
        strGroundNature => $entityFieldObj->getHtml('strGroundNature', $prefixID),
        dblLength => $entityFieldObj->getHtml('dblLength', $prefixID),
        dblWidth => $entityFieldObj->getHtml('dblWidth', $prefixID),
    );

    return \%row;
}

sub validateFormFields {

}

sub retrieveFormFieldData {
    my $self = shift;
    my ($params) = @_;

    my $facilityFieldData;
    my @facilityFieldDataCluster;
    my @errors;
    my @htmlElements = ();
    my %fields = (
        'intEntityFieldID' => {
            label => 'Field ID',
        },
        'intFieldOrderNumber' => {
            label => 'Field Order Number',
            validate => 'NUMBER',
        },
        'strName' => {
            label => 'Field Name',
        },
        'strDiscipline' => {
            label => 'Discipline',
        },
        'strGroundNature' => {
            label => 'Ground Nature',
        },
        'intCapacity' => {
            label => 'Capacity',
            validate => 'NUMBER',
        },
        'dblLength' => {
            label => 'Length',
            validate => 'FLOAT',
        },
        'dblWidth' => {
            label => 'Width',
            validate => 'FLOAT',
        },
    );

    my $obj = new Flow_DisplayFields(
        Data => $self->getData(),
        Lang => $self->getData()->{'Lang'},
        SystemConfig => $self->getData()->{'SystemConfig'},
        Fields => undef,
    );


    for my $index (1 .. $self->getCount()) {
        $facilityFieldData = {};
        $facilityFieldData->{'intEntityID'} = $self->getEntityID();

        foreach my $field (keys %fields) {
            my $fieldname = $field . '_' . $index;
            my $fieldlabel = $fields{$field}{'label'};

            if(($field ne 'intEntityFieldID') and !$params->{$fieldname}){
                push @errors, $fieldlabel . " " . $index . ": " . $obj->langlookup('Field required');
            }

            my $errs = $obj->_validate($fields{$field}{'validate'}, $params->{$fieldname});

            for my $err ( @{$errs} ) {
                push @errors, $fieldlabel . " " . $index . ": " . $err;
            }

            $facilityFieldData->{$field} = $params->{$fieldname};
        }

        $self->setDBData($facilityFieldData);
        push @htmlElements, $self->generateSingleRowField($index, $params->{'intEntityFieldID' . '_' . $index});
        push @facilityFieldDataCluster, $facilityFieldData;
    }

    return (\@facilityFieldDataCluster, \@errors, \@htmlElements);
}

sub setEntityID {
    my $self = shift;
    my ($entityID) = @_;
    $self->{_entityID} = $entityID if defined $entityID;
}

sub setFieldID {
    my $self = shift;
    my ($fieldID) = @_;
    $self->{_fieldID} = $fieldID if defined $fieldID;
}

sub setFieldOrderNumber {
    my $self = shift;
    my ($fieldOrderNumber) = @_;
    $self->{_fieldOrderNumber} = $fieldOrderNumber if defined $fieldOrderNumber;
}

sub setName {
    my $self = shift;
    my ($name) = @_;
    $self->{_name} = $name if defined $name;
}

sub setDiscipline {
    my $self = shift;
    my ($discipline) = @_;
    $self->{_discipline} = $discipline if defined $discipline;
}

sub setGroundNature {
    my $self = shift;
    my ($groundNature) = @_;
    $self->{_groundNature} = $groundNature if defined $groundNature;
}

sub setLength {
    my $self = shift;
    my ($length) = @_;
    $self->{_length} = $length if defined $length;
}

sub setWidth {
    my $self = shift;
    my ($width) = @_;
    $self->{_width} = $width if defined $width;
}

sub setData {
    my $self = shift;
    my ($data) = @_;
    $self->{_data} = $data if defined $data;
}

sub setDBData {
    my $self = shift;
    my ($DBdata) = @_;
    $self->{_DBData} = $DBdata if defined $DBdata;
}

sub setCount {
    my $self = shift;
    my ($count) = @_;
    $self->{_count} = $count if defined $count;
}


sub setHtmlFields {
    my $self = shift;
    my ($htmlField) = @_;
    $self->{_HTMLFields} = $htmlField if defined $htmlField;
}

sub setErrors {
    my $self = shift;
    my ($error) = @_;
    push @{$self->{_errors}}, $error if defined $error;
}

1;
