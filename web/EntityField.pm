package EntityField;

use strict;
use lib '.', '..';
use Defs;
use Data::Dumper;

sub new {
    my $class = shift;
    my (%args) = @_;

    my $self = {
        _venueID            => $args{venueID},
        _fieldID            => $args{fieldID},
        _fieldOrderNumber   => $args{fieldOrderNumber},
        _name               => $args{name},
        _discipline         => $args{discipline},
        _capacity           => $args{capacity},
        _groundNature       => $args{groundNature},
        _length             => $args{length},
        _width              => $args{width},
        _data               => $args{data},
    };

    $self = bless ($self, $class);

    return $self;
}

sub getVenueID {
    my ($self) = shift;
    return $self->{_venueID};
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

sub getField {
    my ($self) = shift;
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
        $self->getVenueID(),
        $self->getData()->{'Realm'},
    );

    warn "VENUE ID " . $self->getVenueID();
    warn "REALM ID " . $self->getData()->{'Realm'};

    my @fields = ();
    while (my $dref = $q->fetchrow_hashref()) {
        $self->setFieldID($dref->{'intEntityFieldID'});
        $self->setName($dref->{'strName'});
        push @fields, {
            entityFieldID   => {value => $dref->{'intEntityFieldID'}, html => $self->fieldIDHtml()},
            fieldName       => {value => $dref->{'strName'}, html => $self->fieldNameHtml()},
            discipline      => {value => $dref->{'strDiscipline'}, html => $self->disciplineHtml()},
            capacity        => {value => $dref->{'intCapacity'}, html => $self->capacityHtml},
            groundNature    => {value => $dref->{'strGroundNature'}, html => $self->groundNatureHtml()},
            length          => {value => $dref->{'dblLength'}, html => $self->lengthHtml()},
            width           => {value => $dref->{'dblWidth'}, html => $self->widthHtml()},
        };
    }

    return \@fields;
}

sub setVenueID {
    my $self = shift;
    my ($venueID) = @_;
    $self->{_venueID} = $venueID if defined $venueID;
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

sub fieldIDHtml {

}

sub fieldNameHtml {

}

sub disciplineHtml {

}

sub capacityHtml {

}

sub fieldOrderNumberHtml {

}

sub fieldNameHtml {

}

sub groundNatureHtml {

}

sub lengthHtml {

}

sub widthHtml {

}

1;
