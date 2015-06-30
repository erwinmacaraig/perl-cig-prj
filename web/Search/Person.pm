package Search::Person;

use strict;
use lib '.', '..', '../..';
use Search::Base;
our @ISA = qw(Search::Base);

use Defs;
use Data::Dumper;
use Switch;
use Reg_common;

sub process {
    my ($self) = shift;
    my ($raw) = @_;

    $raw ||= 0;
    $self->setGridTemplate('search/grid/people.templ') if !$self->getGridTemplate();

    my $searchType = $self->getSearchType() || 'default';
    #set filters here based on search type
    #ie transfer, access, unique otherwise default

    switch($searchType){
        case 'unique' {
            return $self->getUnique($raw);
            #return $self->getUnique();
        }
        case 'transfer' {
            return $self->getTransfer($raw);
        }
        case 'access' {
            return $self->getPersonAccess($raw);
        }
        case 'loan' {
            return $self->getPlayerLoan($raw);
        }
        case 'default' {
            return $self->getPersonRegistration($raw);
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

    my ($intermediateNodes, $subNodes) = $self->getIntermediateNodes(1);
    my $filters = $self->setupFilters($subNodes);

    my $realmID = $self->getData()->{'Realm'};
    $self->getSphinx()->ResetFilters();
    $self->getSphinx()->SetFilter('intrealmid', [$filters->{'realm'}]);

    $self->getSphinx()->SetFilter('intentityid', $filters->{'entity'}) if $filters->{'entity'};
    my $indexName = $Defs::SphinxIndexes{'Person'}.'_r'.$filters->{'realm'};
    my $results = $self->getSphinx()->Query($self->getKeyword(1), $indexName);
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
              AND PR.strStatus IN ('ACTIVE','PASSIVE','PENDING')
              AND PR.intEntityID IN ($entity_list)
            )
            INNER JOIN tblEntity AS E ON (
              PR.intEntityID = E.intEntityID
            )
          WHERE tblPerson.intPersonID IN ($person_list) ] . $self->getQueryParam() . qq[ 
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
            my $entityID = getLastEntityID($self->getData()->{'clientValues'});
            my $entityLevel = getLastEntityLevel($self->getData()->{'clientValues'}) || 0;
          my $link = $self->getSearchLink(
            $self->getData(),
            $Defs::LEVEL_PERSON,
            '',
            $dref->{'intPersonID'},
            $intermediateNodes,
            $entityID,
            $entityLevel,
        );
         #   $dref->{'intEntityID'},
         #   $dref->{'intEntityLevel'},
         # );            
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

    my ($intermediateNodes, $subNodes) = $self->getIntermediateNodes(0);
    my $filters = $self->setupFilters($subNodes);

    my $realmID = $self->getData()->{'Realm'};
    $self->getSphinx()->ResetFilters();
    $self->getSphinx()->SetFilter('intrealmid', [$filters->{'realm'}]);

    #exclude persons that are already in the CLUB initiating the transfer
#    $self->getSphinx()->SetFilter('intentityid', [$filters->{'club'}], 1) if $filters->{'club'};
    my $indexName = $Defs::SphinxIndexes{'Person'}.'_r'.$filters->{'realm'};
    my $results = $self->getSphinx()->Query($self->getKeyword(1), $indexName);
    my @persons = ();

    if($results and $results->{'total'})  {
        for my $r (@{$results->{'matches'}})  {
            push @persons, $r->{'doc'};
        }
    }

    my @memarray = ();
    if(@persons)  {
        my $person_list = join(',',@persons);
        my %personRegMapping = ();

        my $pst = qq [
            SELECT
                intPersonID,
                intEntityID,
                intPersonRegistrationID,
                strStatus,
                strSport
            FROM
                tblPersonRegistration_1
            WHERE
                intPersonID IN ($person_list)
                AND intEntityID = $filters->{'club'}
            ORDER BY
                intPersonID, dtFrom DESC, dtTo DESC
        ];


        my $precheck = $self->getData->{'db'}->prepare($pst);
        $precheck->execute();

        while(my $pdref = $precheck->fetchrow_hashref()) {
            next if($personRegMapping{$pdref->{'intPersonID'}}{$pdref->{'strSport'}});

            #we're only interested in the status of the registration per person per sport
            #if there's no TRANSFERRED on each of the sports, then we remove the person in the list
            #that means that person is registered under the requestor (logged in club)
            $personRegMapping{$pdref->{'intPersonID'}}{$pdref->{'strSport'}} = $pdref->{'strStatus'};
        }

        my $flag = 0;
        my @includePersonList = ();
        my $valid_person_list;

        if(scalar(%personRegMapping)) {
            foreach my $pID (keys %personRegMapping) {
                foreach my $sport (keys %Defs::sportType) {
                    #no records exist for $sport (e.g. BEACHSOCCER), allow to SEARCH from other Clubs
                    $flag++ if !$personRegMapping{$pID}{$sport};

                    $flag++ if($personRegMapping{$pID}{$sport} eq $Defs::PERSONREGO_STATUS_TRANSFERRED);
                }

                push @includePersonList, $pID if $flag > 0;
                $flag = 0;
            }

            $valid_person_list = join(',', @includePersonList);
        }
        else {
            $valid_person_list = join(',', @persons);
        }

        return if(!$valid_person_list or $valid_person_list eq '');

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
                E.intEntityLevel,
                PR.intPersonRegistrationID,
                PR.intPersonID,
                PR.dtFrom,
                PR.dtTo,
                PR.strSport,
                PR.strStatus,
                PRQinprogress.intPersonRequestID as existingInProgressRequestID,
                PRQaccepted.intPersonRequestID as existingAcceptedRequestID,
                PRQactive.intPersonRequestID as existingPersonRegistrationID,
                ePR.intPersonRegistrationID as existingPendingRegistrationID
            FROM
            tblPerson
            INNER JOIN tblPersonRegistration_$realmID AS PR ON (
                tblPerson.intPersonID = PR.intPersonID
                AND PR.strStatus IN ('ACTIVE', 'PASSIVE','PENDING')
                AND
                    (PR.strPersonType = 'PLAYER')
                AND PR.intEntityID <> $filters->{'club'}
            )
            INNER JOIN tblEntity AS E ON (
                PR.intEntityID = E.intEntityID
            )
            LEFT JOIN tblPersonRequest AS PRQinprogress ON (
                PRQinprogress.strRequestType = "TRANSFER"
                AND PRQinprogress.intPersonID = tblPerson.intPersonID
                AND PRQinprogress.strSport =  PR.strSport
                AND PRQinprogress.strPersonType = PR.strPersonType
                AND PRQinprogress.strRequestStatus NOT IN ("COMPLETED", "DENIED", "REJECTED", "CANCELLED")
            )
            LEFT JOIN tblPersonRequest AS PRQaccepted ON (
                PRQaccepted.strRequestType = "TRANSFER"
                AND PRQaccepted.intPersonID = tblPerson.intPersonID
                AND PRQaccepted.strSport =  PR.strSport
                AND PRQaccepted.strPersonType = PR.strPersonType
                AND PRQaccepted.strRequestStatus = "PENDING" AND PRQaccepted.strRequestResponse = "ACCEPTED"
                AND PRQaccepted.intRequestFromEntityID = "$clubID"
            )
            LEFT JOIN tblPersonRegistration_$realmID ePR
            ON (
                ePR.intEntityID = "$clubID"
                AND ePR.intPersonID = tblPerson.intPersonID
                AND ePR.intRealmID = tblPerson.intRealmID
                AND ePR.strStatus IN ('PENDING')
                AND ePR.strSport = PR.strSport
                AND ePR.strPersonType = PR.strPersonType
            )
            LEFT JOIN tblPersonRequest as PRQactive
            ON  (
                PRQactive.intPersonRequestID = PR.intPersonRequestID
                )
            WHERE tblPerson.intPersonID IN ($valid_person_list)
                AND tblPerson.strStatus IN ('REGISTERED')
            ORDER BY 
                PR.intPersonID,
                PR.dtFrom DESC
            LIMIT 100
        ];
                #AND PRQinprogress.intRequestFromEntityID = "$clubID"
                #AND PRQinprogress.strRequestStatus = "INPROGRESS" AND PRQinprogress.strRequestResponse IS NULL

                #print STDERR Dumper $st;
        my $q = $self->getData->{'db'}->prepare($st);
        $q->execute();
        my %origClientValues = %{$self->getData()->{'clientValues'}};

        my $count = 0;
        my $target = $self->getData()->{'target'};
        my $client = $self->getData()->{'client'};

        my %validRecords = ();
        my @sportsFilter;
        my %sportrenewals = ();
        $sportrenewals{'FOOTBALL'} = 1;
        while(my $dref = $q->fetchrow_hashref()) {            
            next if(PersonRegistration::hasPendingRegistration($self->getData(), $dref->{'intPersonID'}, $dref->{'strSport'}, [] ));
            next if $validRecords{$dref->{'intPersonID'}}{$dref->{'strSport'}};

            $validRecords{$dref->{'intPersonID'}}{$dref->{'strSport'}} = $dref;
        }


        foreach my $resPersonID (keys %validRecords) {
            foreach my $personSport (keys %{$validRecords{$resPersonID}}) {
                push @sportsFilter, $Defs::sportType{$personSport} if !(grep /$Defs::sportType{$personSport}/, @sportsFilter);

                my $result = $validRecords{$resPersonID}{$personSport};

                $count++;
                my $name = "$result->{'strLocalFirstname'} $result->{'strLocalSurname'}" || '';
                my $acceptedRequestLink = ($result->{'existingAcceptedRequestID'}) ? "$target?client=$client&amp;a=PRA_V&rid=$result->{'existingAcceptedRequestID'}" : '';
                push @memarray, {
                    id => $result->{'intPersonID'} || next,
                    name => $name,
                    sport => $Defs::sportType{$personSport},
                    link => "$target?client=$client&amp;a=PRA_getrecord&request_type=transfer&amp;search_keyword=$result->{'strNationalNum'}&amp;transfer_type=&amp;tprID=$result->{'intPersonRegistrationID'}",
                    otherdetails => {
                        dob => $result->{'dtDOB'},
                        dtadded => $result->{'dtadded'},
                        ma_id => $result->{'strNationalNum'} || '',
                        org => $result->{'EntityName'} || '',
                    },
                    inProgressRequestExists => $result->{'existingInProgressRequestID'},
                    acceptedRequestLink => $acceptedRequestLink,
                    submittedPersonRegistrationExists => $result->{'existingPendingRegistrationID'},
                };
            }
        }

        #while(my $dref = $q->fetchrow_hashref()) {
        #    $count++;
        #    my $name = "$dref->{'strLocalFirstname'} $dref->{'strLocalSurname'}" || '';
        #    my $acceptedRequestLink = ($dref->{'existingAcceptedRequestID'}) ? "$target?client=$client&amp;a=PRA_V&rid=$dref->{'existingAcceptedRequestID'}" : '';
        #    push @memarray, {
        #        id => $dref->{'intPersonID'} || next,
        #        name => $name,
        #        link => "$target?client=$client&amp;a=PRA_getrecord&request_type=transfer&amp;search_keyword=$dref->{'strNationalNum'}&amp;transfer_type=",
        #        otherdetails => {
        #            dob => $dref->{'dtDOB'},
        #            dtadded => $dref->{'dtadded'},
        #            ma_id => $dref->{'strNationalNum'} || '',
        #            org => $dref->{'EntityName'} || '',
        #        },
        #        inProgressRequestExists => $dref->{'existingInProgressRequestID'},
        #        acceptedRequestLink => $acceptedRequestLink,
        #        submittedPersonRegistrationExists => $dref->{'existingPendingRegistrationID'},
        #    };
        #}

        if($raw){
            return \@memarray;
        }
        else {

            my %filters = (
                sports => \@sportsFilter,
            );

            return $self->displayResultGrid(\@memarray, \%filters) if $count;

            return $count;
        }

    }

}

sub getPlayerLoan {
    my ($self) = shift;
    my ($raw) = @_;

    my ($intermediateNodes, $subNodes) = $self->getIntermediateNodes(0);
    my $filters = $self->setupFilters($subNodes);

    my $realmID = $self->getData()->{'Realm'};
    $self->getSphinx()->ResetFilters();
    $self->getSphinx()->SetFilter('intrealmid', [$filters->{'realm'}]);

    #exclude persons that are already in the CLUB initiating the transfer
#    $self->getSphinx()->SetFilter('intentityid', [$filters->{'club'}], 1) if $filters->{'club'};
    my $indexName = $Defs::SphinxIndexes{'Person'}.'_r'.$filters->{'realm'};
    my $results = $self->getSphinx()->Query($self->getKeyword(1), $indexName);
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

        my %personRegMapping = ();

        my $pst = qq [
            SELECT
                intPersonID,
                intEntityID,
                intPersonRegistrationID,
                strStatus,
                strSport
            FROM
                tblPersonRegistration_1
            WHERE
                intPersonID IN ($person_list)
                AND intEntityID = $filters->{'club'}
            ORDER BY
                intPersonID, dtFrom DESC, dtTo DESC
        ];


        my $precheck = $self->getData->{'db'}->prepare($pst);
        $precheck->execute();

        while(my $pdref = $precheck->fetchrow_hashref()) {
            next if($personRegMapping{$pdref->{'intPersonID'}}{$pdref->{'strSport'}});

            #we're only interested in the status of the registration per person per sport
            #if there's no TRANSFERRED on each of the sports, then we remove the person in the list
            #that means that person is registered under the requestor (logged in club)
            $personRegMapping{$pdref->{'intPersonID'}}{$pdref->{'strSport'}} = $pdref->{'strStatus'};
        }

        my $flag = 0;
        my @includePersonList = ();
        my $valid_person_list;

        if(scalar(%personRegMapping)) {
            foreach my $pID (keys %personRegMapping) {
                foreach my $sport (keys %Defs::sportType) {
                    #no records exist for $sport (e.g. BEACHSOCCER), allow to SEARCH from other Clubs
                    $flag++ if !$personRegMapping{$pID}{$sport};

                    $flag++ if($personRegMapping{$pID}{$sport} eq $Defs::PERSONREGO_STATUS_TRANSFERRED);
                }

                push @includePersonList, $pID if $flag > 0;
                $flag = 0;
            }

            $valid_person_list = join(',', @includePersonList);
        }
        else {
            $valid_person_list = join(',', @persons);
        }

        return if(!$valid_person_list or $valid_person_list eq '');



        my $allowedPeriods = $self->getData()->{'SystemConfig'}{'loan_newLoanAllowedPeriods'};
        my $periodSQL='';
        if ($allowedPeriods)    {
            my @periods= split /\|/, $allowedPeriods;
            my $periods_list = join(',',@periods);
            $periodSQL="AND PR.intNationalPeriodID IN ($periods_list)";
        }

        my $allowedLevels= $self->getData()->{'SystemConfig'}{'loan_personLevels'};
        my $levelSQL='';
        if ($allowedLevels)    {
            my @levels= split /\|/, $allowedLevels;
            my $level_list = join(',',@levels);
            $levelSQL="AND PR.strPersonLevel IN ($level_list)";
        }
        
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
                E.intEntityLevel,
                PR.intPersonRegistrationID,
                PR.intPersonID,
                PR.dtFrom,
                PR.dtTo,
                PR.strSport,
                PR.strStatus,
                PRQinprogress.intPersonRequestID as existingInProgressRequestID,
                PRQaccepted.intPersonRequestID as existingAcceptedRequestID,
                PRQactive.intPersonRequestID as existingPersonRegistrationID,
                ePR.intPersonRegistrationID as existingPendingRegistrationID
            FROM
            tblPerson
            INNER JOIN tblPersonRegistration_$realmID AS PR ON (
                tblPerson.intPersonID = PR.intPersonID
                AND PR.strStatus IN ('ACTIVE', 'PASSIVE','PENDING','ROLLED_OVER')
                AND
                    (PR.strPersonType = 'PLAYER')
                AND PR.intEntityID <> $filters->{'club'}
                $levelSQL
                $periodSQL
            )
            INNER JOIN tblEntity AS E ON (
                PR.intEntityID = E.intEntityID
            )
            LEFT JOIN tblPersonRequest AS PRQinprogress ON (
                PRQinprogress.strRequestType IN ("LOAN")
                AND PRQinprogress.intPersonID = tblPerson.intPersonID
                AND PRQinprogress.strSport =  PR.strSport
                AND PRQinprogress.strPersonType = PR.strPersonType
                AND PRQinprogress.strRequestStatus NOT IN ("COMPLETED", "DENIED", "REJECTED", "CANCELLED")
            )
            LEFT JOIN tblPersonRequest AS PRQaccepted ON (
                PRQaccepted.strRequestType = "LOAN"
                AND PRQaccepted.intPersonID = tblPerson.intPersonID
                AND PRQaccepted.strSport =  PR.strSport
                AND PRQaccepted.strPersonType = PR.strPersonType
                AND PRQaccepted.strRequestStatus = "PENDING" AND PRQaccepted.strRequestResponse = "ACCEPTED"
                AND PRQaccepted.intRequestFromEntityID = "$clubID"
            )
            LEFT JOIN tblPersonRegistration_$realmID ePR
            ON (
                ePR.intEntityID = "$clubID"
                AND ePR.intPersonID = tblPerson.intPersonID
                AND ePR.intRealmID = tblPerson.intRealmID
                AND ePR.strStatus IN ('PENDING')
                AND ePR.strSport = PR.strSport
                AND ePR.strPersonType = PR.strPersonType
            )
            LEFT JOIN tblPersonRequest as PRQactive
            ON  (
                PRQactive.intPersonRequestID = PR.intPersonRequestID
                )
            WHERE tblPerson.intPersonID IN ($valid_person_list)
                AND tblPerson.strStatus IN ('REGISTERED')
            ORDER BY 
                PR.intPersonID,
                PR.dtFrom DESC
            LIMIT 100
        ];

		 
        my $q = $self->getData->{'db'}->prepare($st);
        $q->execute();
        my %origClientValues = %{$self->getData()->{'clientValues'}};

        my $count = 0;
        my $target = $self->getData()->{'target'};
        my $client = $self->getData()->{'client'};

        my %validRecords = ();
        my @sportsFilter;

        while(my $dref = $q->fetchrow_hashref()) {
            next if $validRecords{$dref->{'intPersonID'}}{$dref->{'strSport'}};

            $validRecords{$dref->{'intPersonID'}}{$dref->{'strSport'}} = $dref;
        }


        foreach my $resPersonID (keys %validRecords) {
            foreach my $personSport (keys %{$validRecords{$resPersonID}}) {
                push @sportsFilter, $Defs::sportType{$personSport} if !(grep /$Defs::sportType{$personSport}/, @sportsFilter);

                my $result = $validRecords{$resPersonID}{$personSport};

                $count++;
                my $name = "$result->{'strLocalFirstname'} $result->{'strLocalSurname'}" || '';
                my $acceptedRequestLink = ($result->{'existingAcceptedRequestID'}) ? "$target?client=$client&amp;a=PRA_V&rid=$result->{'existingAcceptedRequestID'}" : '';
                push @memarray, {
                    id => $result->{'intPersonID'} || next,
                    name => $name,
                    sport => $Defs::sportType{$personSport},
                    link => "$target?client=$client&amp;a=PRA_getrecord&request_type=loan&amp;search_keyword=$result->{'strNationalNum'}&amp;transfer_type=&amp;tprID=$result->{'intPersonRegistrationID'}",
                    otherdetails => {
                        dob => $result->{'dtDOB'},
                        dtadded => $result->{'dtadded'},
                        ma_id => $result->{'strNationalNum'} || '',
                        org => $result->{'EntityName'} || '',
                    },
                    inProgressRequestExists => $result->{'existingInProgressRequestID'},
                    acceptedRequestLink => $acceptedRequestLink,
                    submittedPersonRegistrationExists => $result->{'existingPendingRegistrationID'},
                };
            }
        }


        #while(my $dref = $q->fetchrow_hashref()) {
        #    $count++;
        #    my $name = "$dref->{'strLocalFirstname'} $dref->{'strLocalSurname'}" || '';
        #    my $acceptedRequestLink = ($dref->{'existingAcceptedRequestID'}) ? "$target?client=$client&amp;a=PRA_V&rid=$dref->{'existingAcceptedRequestID'}" : '';
        #    push @memarray, {
        #        id => $dref->{'intPersonID'} || next,
        #        name => $name,
        #        link => "$target?client=$client&amp;a=PRA_getrecord&request_type=loan&amp;search_keyword=$dref->{'strNationalNum'}&amp;transfer_type=",
        #        otherdetails => {
        #            dob => $dref->{'dtDOB'},
        #            dtadded => $dref->{'dtadded'},
        #            ma_id => $dref->{'strNationalNum'} || '',
        #            org => $dref->{'EntityName'} || '',
        #        },
        #        inProgressRequestExists => $dref->{'existingInProgressRequestID'},
        #        acceptedRequestLink => $acceptedRequestLink,
        #        submittedPersonRegistrationExists => $dref->{'existingPendingRegistrationID'},
        #    };
        #}

        if($raw){
            return \@memarray;
        }
        else {
            my %filters = (
                sports => \@sportsFilter,
            );

            return $self->displayResultGrid(\@memarray, \%filters) if $count;

            return $count;
        }

    }

}


sub getPersonRegistration {
    my ($self) = shift;
    my ($raw) = @_;

    $self->setGridTemplate("search/grid/personregistration.templ");

    my ($intermediateNodes, $subNodes) = $self->getIntermediateNodes(1);
    my $filters = $self->setupFilters($subNodes);

    my $realmID = $self->getData()->{'Realm'};
    $self->getSphinx()->ResetFilters();
    $self->getSphinx()->SetFilter('intrealmid', [$filters->{'realm'}]);

    #exclude persons that are already in the CLUB initiating the transfer
    $self->getSphinx()->SetFilter('intentityid', $filters->{'entity'}) if $filters->{'entity'};
    #my $results = $self->getSphinx()->Query($self->getKeyword(), 'FIFA_Persons_r'.$filters->{'realm'});
    my $indexName = $Defs::SphinxIndexes{'Person'}.'_r'.$filters->{'realm'};
    my $results = $self->getSphinx()->Query($self->getKeyword(1), $indexName);
    my @persons = ();

    if($results and $results->{'total'})  {
        for my $r (@{$results->{'matches'}})  {
            push @persons, $r->{'doc'};
        }
    }

	my @persontypes = ();
	my $filterstring = '';
	my $personTypeFilter = '';
	my $currentLevel = $self->getData()->{'clientValues'}{'currentLevel'};
	if($currentLevel == $Defs::LEVEL_CLUB){
		my $filterstatement = qq[ SELECT DISTINCT strPersonType FROM tblMatrix WHERE intRealmID = ? and intEntityLevel= ?];
		my $query = $self->getData->{'db'}->prepare($filterstatement);
        $query->execute($self->getData()->{'Realm'},$Defs::LEVEL_CLUB);
		while(my $dref = $query->fetchrow_hashref()){
			push @persontypes, $dref->{'strPersonType'};
		}
		$filterstring = q['] . join("','",@persontypes) . q['];
		$personTypeFilter = qq[AND PR.strPersonType IN ($filterstring) ];
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
                tblPerson.strStatus as PersonStatus,
                PR.intPersonRegistrationID,
                PR.strPersonType,
                PR.strSport,
                E.strLocalName AS EntityName,
                E.intEntityID,
                E.intEntityLevel
            FROM
            tblPerson
            INNER JOIN tblPersonRegistration_$realmID AS PR ON (
                tblPerson.intPersonID = PR.intPersonID
                AND (PR.strStatus IN ('ACTIVE', 'PASSIVE') OR PR.intOnLoan = 1)
                AND PR.intEntityID IN ($entity_list)
            )
            INNER JOIN tblEntity AS E ON (
                PR.intEntityID = E.intEntityID
            )
            WHERE tblPerson.intPersonID IN ($person_list)
                AND tblPerson.strStatus IN ('REGISTERED', 'PENDING')
                $personTypeFilter
            ORDER BY 
                PR.dtFrom DESC,
                tblPerson.strLocalSurname,
                tblPerson.strLocalFirstname,
                tblPerson.strNationalNum
            LIMIT 1000
        ];

        #GROUP BY PR.strPersonType, E.intEntityID
	#print STDERR "SELECT DISTINCT tblPerson.intPersonID, tblPerson.strLocalFirstname, tblPerson.strLocalSurname, tblPerson.strNationalNum, tblPerson.strFIFAID, tblPerson.dtDOB, tblPerson.strStatus as PersonStatus, PR.intPersonRegistrationID, PR.strPersonType, PR.strSport, E.strLocalName AS EntityName, E.intEntityID, E.intEntityLevel FROM tblPerson INNER JOIN tblPersonRegistration_$realmID AS PR ON ( tblPerson.intPersonID = PR.intPersonID AND PR.strStatus IN ('ACTIVE', 'PASSIVE') AND PR.intEntityID IN ($entity_list) ) INNER JOIN tblEntity AS E ON ( PR.intEntityID = E.intEntityID ) WHERE tblPerson.intPersonID IN ($person_list) AND tblPerson.strStatus IN ('REGISTERED', 'PENDING') $personTypeFilter ORDER BY tblPerson.strLocalSurname, tblPerson.strLocalFirstname, tblPerson.strNationalNum LIMIT 100";
        my $q = $self->getData->{'db'}->prepare($st);
        $q->execute();
        my %origClientValues = %{$self->getData()->{'clientValues'}};

        my $count = 0;
        my $target = $self->getData()->{'target'};
        my $client = $self->getData()->{'client'};
        while(my $dref = $q->fetchrow_hashref()) {
            my $entityID = getLastEntityID($self->getData()->{'clientValues'});
            my $entityLevel = getLastEntityLevel($self->getData()->{'clientValues'}) || 0;
            my $link = $self->getSearchLink(
                $self->getData(),
                $Defs::LEVEL_PERSON,
                '',
                $dref->{'intPersonID'},
                $intermediateNodes,
                $entityID,
                $entityLevel,
            );
            #    $dref->{'intEntityID'},
            #    $dref->{'intEntityLevel'},
            #);

            $count++;
            my $name = "$dref->{'strLocalFirstname'} $dref->{'strLocalSurname'}" || '';
            push @memarray, {
                id => $dref->{'intPersonID'} || next,
                ma_id => $dref->{'strNationalNum'} || $Defs::personStatus{$dref->{'PersonStatus'}} || '',
                link => $link,
                name => $name,
                org => $dref->{'EntityName'},
                dob => $dref->{'dtDOB'},
                role => $Defs::personType{$dref->{'strPersonType'}},
            };
        }
		
        $self->setResultCount($count);

        if($raw){
            return \@memarray;
        }
        else {
            my @roleFilters;
			foreach my $role (keys %Defs::personType){
				if(scalar @persontypes){
					if(grep /$role/,@persontypes){
	                	push @roleFilters, $Defs::personType{$role};
					}
				}
				else {
					push @roleFilters, $Defs::personType{$role};
				}
			}			
            my %filters = (
                role => \@roleFilters,
            );

            return $self->displayResultGrid(\@memarray, \%filters) if $count;

            return $count;
        }

    }

    return;

}

sub getPersonAccess {
    my ($self) = shift;
    my ($raw) = @_;

    $self->setGridTemplate("search/grid/personregistration.templ");

    my ($intermediateNodes, $subNodes) = $self->getIntermediateNodes(0);
    my $filters = $self->setupFilters($subNodes);

    my $realmID = $self->getData()->{'Realm'};
    $self->getSphinx()->ResetFilters();
    $self->getSphinx()->SetFilter('intrealmid', [$filters->{'realm'}]);

    #exclude persons that are already in the CLUB initiating the transfer
    $self->getSphinx()->SetFilter('intentityid', [$filters->{'club'}], 1) if $filters->{'club'};
    my $indexName = $Defs::SphinxIndexes{'Person'}.'_r'.$filters->{'realm'};
    my $results = $self->getSphinx()->Query($self->getKeyword(1), $indexName);
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
                tblPerson.strStatus as PersonStatus,
                tblPerson.dtDOB,
                PR.strPersonType,
                E.strLocalName AS EntityName,
                E.intEntityID,
                E.intEntityLevel,
                PRQinprogress.intPersonRequestID as existingInProgressRequestID,
                PRQaccepted.intPersonRequestID as existingAcceptedRequestID,
                PRQactive.intPersonRequestID as existingPersonRegistrationID,
                ePR.intPersonRegistrationID as existingPendingRegistrationID
            FROM
            tblPerson
            INNER JOIN tblPersonRegistration_$realmID AS PR ON (
                tblPerson.intPersonID = PR.intPersonID
                AND PR.strStatus IN ('ACTIVE', 'PASSIVE')
                AND PR.intEntityID <> $filters->{'club'}
            )
            INNER JOIN tblEntity AS E ON (
                PR.intEntityID = E.intEntityID
            )
            LEFT JOIN tblPersonRequest AS PRQinprogress ON (
                PRQinprogress.strRequestType = "ACCESS"
                AND PRQinprogress.intPersonID = tblPerson.intPersonID
                AND PRQinprogress.strSport =  PR.strSport
                AND PRQinprogress.strPersonType = PR.strPersonType
                AND PRQinprogress.strRequestStatus = "INPROGRESS" AND PRQinprogress.strRequestResponse IS NULL
                AND PRQinprogress.intRequestFromEntityID = "$clubID"
            )
            LEFT JOIN tblPersonRequest AS PRQaccepted ON (
                PRQaccepted.strRequestType = "ACCESS"
                AND PRQaccepted.intPersonID = tblPerson.intPersonID
                AND PRQaccepted.strSport =  PR.strSport
                AND PRQaccepted.strPersonType = PR.strPersonType
                AND PRQaccepted.strRequestStatus = "PENDING" AND PRQaccepted.strRequestResponse = "ACCEPTED"
                AND PRQaccepted.intRequestFromEntityID = "$clubID"
            )
            LEFT JOIN tblPersonRegistration_$realmID ePR
            ON (
                ePR.intEntityID = "$clubID"
                AND ePR.intPersonID = tblPerson.intPersonID
                AND ePR.intRealmID = tblPerson.intRealmID
                AND ePR.strStatus IN ('PENDING')
                AND ePR.strSport = PR.strSport
                AND ePR.strPersonType = PR.strPersonType
            )
            LEFT JOIN tblPersonRequest as PRQactive
            ON  (
                PRQactive.intPersonRequestID = PR.intPersonRequestID
                )
            WHERE tblPerson.intPersonID IN ($person_list)
                AND tblPerson.strStatus IN ('REGISTERED', 'PENDING')
            ORDER BY 
                strLocalSurname, 
                strLocalFirstname
            LIMIT 100
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
            my $acceptedRequestLink = ($dref->{'existingAcceptedRequestID'}) ? "$target?client=$client&amp;a=PRA_V&rid=$dref->{'existingAcceptedRequestID'}" : '';
            push @memarray, {
                id => $dref->{'intPersonID'} || next,
                ma_id => $dref->{'strNationalNum'} || $Defs::personStatus{$dref->{'PersonStatus'}} || '',
                link => "$target?client=$client&amp;a=PRA_getrecord&request_type=access&amp;search_keyword=$dref->{'strNationalNum'}",
                name => $name,
                dob => $dref->{'dtDOB'},
                org => $dref->{'EntityName'},
                role => $Defs::personType{$dref->{'strPersonType'}},
                inProgressRequestExists => $dref->{'existingInProgressRequestID'},
                acceptedRequestLink => $acceptedRequestLink,
                submittedPersonRegistrationExists => $dref->{'existingPendingRegistrationID'},
            };
        }

        $self->setResultCount($count);

        if($raw){
            return \@memarray;
        }
        else {
            my @roleFilters;
            foreach my $role (keys %Defs::personType){
                push @roleFilters, $Defs::personType{$role};
            }

            my %filters = (
                role => \@roleFilters,
            );

            return $self->displayResultGrid(\@memarray, \%filters) if $count;

            return $count;
        }

    }

}

1;
