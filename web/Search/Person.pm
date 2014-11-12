package Search::Person;

use strict;
use lib '.', '..', '../..';
use Search::Base;
our @ISA = qw(Search::Base);

use Data::Dumper;

sub process {
    my ($self) = shift;

    $self->setGridTemplate('search/grid/people.templ');

    my $cleanKeyword = $self->cleanKeyword($self->getKeyword());
    my $realmID = $self->getRealmID();
    my $st = qq[
        SELECT
            P.strLocalFirstname,
            P.strLocalSurname,
            P.strNationalNum,
            P.dtDOB,
            E.strLocalName,
            PR.intPersonRegistrationID,
            PR.strPersonType,
            PR.dtAdded
        FROM
            tblPerson P
        INNER JOIN tblPersonRegistration_$realmID PR ON (PR.intPersonID = P.intPersonID)
        INNER JOIN tblEntity E ON (E.intEntityID = PR.intEntityID)
        WHERE
            P.intRealmID = ?
            AND P.strStatus IN ('REGISTERED', 'PASSIVE','PENDING')
            AND PR.strStatus IN ('ACTIVE', 'PASSIVE','PENDING')
            AND
                (P.strNationalNum = ? OR CONCAT_WS(' ', P.strLocalFirstname, P.strLocalSurname) LIKE CONCAT('%',?,'%') OR CONCAT_WS(' ', P.strLocalSurname, P.strLocalFirstname) LIKE CONCAT('%',?,'%'))
    ];

    my $db = $self->getData()->{'db'};
    my $q = $db->prepare($st) or query_error($st);
    $q->execute(
        $self->getRealmID(),
        $cleanKeyword,
        $cleanKeyword,
        $cleanKeyword
    ) or query_error($st);

    my @RegoList;
    while(my $dref = $q->fetchrow_hashref()) {
        my %single_rego = (
            'dob' => $dref->{'dtDOB'},
            'name' => $dref->{'strLocalFirstname'} . ' ' . $dref->{'strLocalSurname'},
            'added' => $dref->{'dtAdded'},
            'type' => $Defs::personType{$dref->{'strPersonType'}},
        );

        push @RegoList, \%single_rego;
    }

    return $self->displayResultGrid(\@RegoList);
}

1;
