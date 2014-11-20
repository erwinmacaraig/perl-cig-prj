package Search::Person;

use strict;
use lib '.', '..', '../..';
use Search::Base;
our @ISA = qw(Search::Base);

use Defs;
use Data::Dumper;
use Switch;

sub process {
    my ($self) = shift;
    my ($raw) = @_;

    $raw ||= 0;
    $self->setGridTemplate('search/grid/people.templ') if !$self->getGridTemplate();

    my $searchType = $self->getSearchType() || 'default';
    #set filters here based on search type
    #ie transfer, access, unique otherwise default

    print STDERR Dumper "SEARCH TYPE " . $searchType;
    switch($searchType){
        case 'unique' {
            return $self->getUnique($raw);
            #return $self->getUnique();
        }
        case 'transfer' {
            return $self->getTransfer($raw);
        }
        case 'access' {
            return;
        }
        case 'default' {
            return $self->getUnique($raw);
        }
        else {
            return $self->getUnique($raw);
            #return unique for now
        }
    }
}

sub getUnique {
    my ($self) = shift;
    my ($raw) = @_;

    my ($intermediateNodes, $subNodes) = $self->getIntermediateNodes();
    my $filters = $self->setupFilters($subNodes);

    my $realmID = $self->getData()->{'Realm'};
    $self->getSphinx()->ResetFilters();
    $self->getSphinx()->SetFilter('intrealmid', [$filters->{'realm'}]);

    $self->getSphinx()->SetFilter('intentityid', $filters->{'entity'}) if $filters->{'entity'};
    my $results = $self->getSphinx()->Query($self->getKeyword(), 'FIFA_Persons_r'.$filters->{'realm'});
    my @persons = ();

    if($results and $results->{'total'})  {
        for my $r (@{$results->{'matches'}})  {
            push @persons, $r->{'doc'};
        }
    }

    my @memarray = ();
    if(@persons)  {
        my $person_list = join(',',@persons);

        my $entity_list = '';
        $entity_list = join(',', @{$subNodes});

        my $clubID = $self->getData()->{'clientValues'}{'clubID'} || 0;
        $clubID = 0 if $clubID == $Defs::INVALID_ID;

        my $st = qq[
          SELECT DISTINCT
            tblPerson.intPersonID,
            tblPerson.strLocalFirstname,
            tblPerson.strLocalSurname,
            tblPerson.strNationalNum,
            tblPerson.strFIFAID,
            tblPerson.dtDOB,
            E.strLocalName AS EntityName,
            E.intEntityID,
            E.intEntityLevel
          FROM
            tblPerson
            INNER JOIN tblPersonRegistration_$realmID AS PR ON (
              tblPerson.intPersonID = PR.intPersonID
              AND PR.strStatus <> 'DELETED'
              AND PR.intEntityID IN ($entity_list)
            )
            INNER JOIN tblEntity AS E ON (
              PR.intEntityID = E.intEntityID
            )
          WHERE tblPerson.intPersonID IN ($person_list)
          ORDER BY 
            strLocalSurname, 
            strLocalFirstname
          LIMIT 10
        ];
        my $q = $self->getData->{'db'}->prepare($st);
        $q->execute();
        my %origClientValues = %{$self->getData()->{'clientValues'}};

        my $numnotshown = ($results->{'total'} || 0) - 10;
        $numnotshown = 0 if $numnotshown < 0;
        while(my $dref = $q->fetchrow_hashref())  {
          my $link = $self->getSearchLink(
            $self->getData(),
            $Defs::LEVEL_PERSON,
            '',
            $dref->{'intPersonID'},
            $intermediateNodes,
            $dref->{'intEntityID'},
            $dref->{'intEntityLevel'},
          );            
          my $name = "$dref->{'strLocalSurname'}, $dref->{'strLocalFirstname'}" || '';
          $name .= " #$dref->{'strNationalNum'}" if $dref->{'strNationalNum'};
          $name .= "  ($dref->{'EntityName'})" if $dref->{'EntityName'};
          push @memarray, {
            id => $dref->{'intPersonID'} || next,
            label => $name,
            category => 'Persons',
            link => $link,
            numnotshown => $numnotshown,
            otherdetails => {
                dob => $dref->{'dtDOB'},
                dtadded => $dref->{'dtadded'},
            }
          };
        }
    }

    if($raw){
        return \@memarray;
    }
    else {
        return $self->displayResultGrid(\@memarray);
    }
}

sub getTransfer {
    my ($self) = shift;
    my ($raw) = @_;

    my ($intermediateNodes, $subNodes) = $self->getIntermediateNodes();
    my $filters = $self->setupFilters($subNodes);

    my $realmID = $self->getData()->{'Realm'};
    $self->getSphinx()->ResetFilters();
    $self->getSphinx()->SetFilter('intrealmid', [$filters->{'realm'}]);

    #exclude persons that are already in the CLUB initiating the transfer
    $self->getSphinx()->SetFilter('intentityid', [$filters->{'club'}], 1) if $filters->{'club'};
    my $results = $self->getSphinx()->Query($self->getKeyword(), 'FIFA_Persons_r'.$filters->{'realm'});
    my @persons = ();

    if($results and $results->{'total'})  {
        for my $r (@{$results->{'matches'}})  {
            push @persons, $r->{'doc'};
        }
    }

    my @memarray = ();
    if(@persons)  {
        my $person_list = join(',',@persons);

        my $entity_list = '';
        $entity_list = join(',', @{$subNodes});
        warn "ENTITY LIST " . $entity_list;

        my $clubID = $self->getData()->{'clientValues'}{'clubID'} || 0;
        $clubID = 0 if $clubID == $Defs::INVALID_ID;

        my $st = qq[
            SELECT DISTINCT
                tblPerson.intPersonID,
                tblPerson.strLocalFirstname,
                tblPerson.strLocalSurname,
                tblPerson.strNationalNum,
                tblPerson.strFIFAID,
                tblPerson.dtDOB,
                E.strLocalName AS EntityName,
                E.intEntityID,
                E.intEntityLevel
            FROM
            tblPerson
            INNER JOIN tblPersonRegistration_$realmID AS PR ON (
                tblPerson.intPersonID = PR.intPersonID
                AND PR.strStatus IN ('ACTIVE', 'PASSIVE','PENDING')
                AND PR.intEntityID <> $filters->{'club'}
            )
            INNER JOIN tblEntity AS E ON (
                PR.intEntityID = E.intEntityID
            )
            WHERE tblPerson.intPersonID IN ($person_list)
            ORDER BY 
                strLocalSurname, 
                strLocalFirstname
        ];
        my $q = $self->getData->{'db'}->prepare($st);
        $q->execute();
        my %origClientValues = %{$self->getData()->{'clientValues'}};

        my $count = 0;
        my $target = $self->getData()->{'target'};
        my $client = $self->getData()->{'client'};
        while(my $dref = $q->fetchrow_hashref()) {
            $count++;
            my $name = "$dref->{'strLocalFirstname'} $dref->{'strLocalSurname'}" || '';
            push @memarray, {
                id => $dref->{'intPersonID'} || next,
                name => $name,
                link => "$target?client=$client&amp;a=PRA_getrecord&request_type=transfer&amp;search_keyword=$dref->{'strNationalNum'}&amp;transfer_type=",
                otherdetails => {
                    dob => $dref->{'dtDOB'},
                    dtadded => $dref->{'dtadded'},
                    ma_id => $dref->{'strNationalNum'} || '',
                }
            };
        }

        if($raw){
            return \@memarray;
        }
        else {
            return $self->displayResultGrid(\@memarray) if $count;

            return $count;
        }

    }

}

sub getRegistration {

}

1;
