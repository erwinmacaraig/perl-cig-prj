package ProcessFile;
require Exporter;
@EXPORT = qw(getAssocs getSeasons getProducts handle_venues handle_clubs handle_members handle_players handle_RefCoachTypes);
@EXPORT_OK = qw(getAssocs getSeasons getProducts handle_venues handle_clubs handle_members handle_players handle_RefCoachTypes);
@ISA =  qw(Exporter);

use Data::Dumper;
use DBI;
use strict;

sub calcAssocID	{

	my ($row, $newIDs) = @_;

	my $assocID=0;
	if ((! exists $row->{'AssocID'} or ! $row->{'AssocID'}) and $row->{'AssocName'})	{
		$assocID = $newIDs->{'AssocByName'}{$row->{'AssocName'}}{'ID'} || 0;
	}	
	elsif ($row->{'AssocID'})	{
		$assocID = $row->{'AssocID'};
	}

	return $assocID;
}

sub calcClubID	{
	my ($db, $assocID, $row, $newIDs) = @_;

	my $clubID=0;
	if ((! exists $row->{'ClubID'} or ! $row->{'ClubID'}) and $row->{'ClubName'})	{
		$clubID = $newIDs->{$assocID}{'ClubByName'}{$row->{'ClubName'}}{'ID'} || 0;
		if (! $clubID)	{
			my $st_club=qq[
				INSERT INTO tblClub (intRecStatus, strName)
				VALUES (1, ?)
			];
			my $qry=$db->prepare($st_club);
			$qry->execute($row->{'ClubName'});
			$clubID = $qry->{mysql_insertid};
			$newIDs->{$assocID}{'ClubByName'}{$row->{'ClubName'}}{'ID'} = $clubID;

			my $st_assocclub=qq[
				INSERT IGNORE INTO tblAssoc_Clubs (intRecStatus, intAssocID, intClubID)
				VALUES (1, ?, ?)
			];
			my $qry_ac=$db->prepare($st_assocclub);
			$qry_ac->execute($assocID, $clubID);
		}
	}	
	elsif ($row->{'ClubID'})	{
		$clubID= $row->{'ClubID'};
	}
	elsif ($row->{'ClubExtID'})	{
		$clubID = $newIDs->{$assocID}{'ClubByExtID'}{$row->{'ClubExtKey'}}{'ID'};
	}
	return $clubID
}

sub calcMemberID	{
	my ($row, $newIDs) = @_;

	my $memberID = 0;
	if ((! exists $row->{'MemberID'} or ! $row->{'MemberID'}) and $row->{'MemberExtID'})	{
		$memberID= $newIDs->{'MemberByExtID'}{$row->{'MemberExtID'}}{'ID'} || 0;
	}	
	else	{
		$memberID= $row->{'MemberID'};
	}

	return $memberID
}
	
sub insertMA_row	{
	my ($db, $status, $assocID, $memberID, $dtLastRegistered) = @_;
	my $st=qq[
		INSERT IGNORE INTO tblMember_Associations (intRecStatus, intAssocID, intMemberID, dtLastRegistered)
		VALUES (?, ?, ?, ?)
	];
	my $qry=$db->prepare($st);
	$qry->execute($status, $assocID, $memberID, $dtLastRegistered);
}

sub insertMC_row	{
	my ($db, $status, $clubID, $memberID, $primary) = @_;
	$primary||=0;

	my $st=qq[
		INSERT IGNORE INTO tblMember_Clubs (intStatus, intClubID, intMemberID, intPrimaryClub)
		VALUES (?, ?, ?, ?)
	];
	my $qry=$db->prepare($st);
	$qry->execute($status, $clubID, $memberID, $primary);
}

sub getAssocs {

	my ($db, $realm, $id_ref) = @_;
	
	my $st = qq[
		SELECT
			intAssocID,
			strName,
			intAssocTypeID	
		FROM
			tblAssoc
		WHERE intRealmID=?
	];

	my $query=$db->prepare($st);
	$query->execute($realm);
	my @Assocs=();
	while (my $dref=$query->fetchrow_hashref())	{
		$id_ref->{'AssocByID'}{$dref->{'intAssocID'}}{'Name'} = $dref->{'strName'};
		$id_ref->{'AssocByID'}{$dref->{'intAssocID'}}{'SubRealm'} = $dref->{'intAssocTypeID'};
		$id_ref->{'AssocByName'}{$dref->{'strName'}}{'ID'} = $dref->{intAssocID};
		my %assoc = (	
			'AssocID'=>$dref->{'intAssocID'},
			'AssocName'=>$dref->{'strName'},
			'SubRealm'=>$dref->{'intAssocTypeID'},
		);
		push @Assocs, \%assoc;
	}
	return \@Assocs;
}

sub getProducts	{

	my ($db, $realm, $id_ref) = @_;
	
	my $st = qq[
		SELECT
			intProductID,
			strName
		FROM
			tblProducts
		WHERE intRealmID=?
	];

	my $query=$db->prepare($st);
	$query->execute($realm);
	while (my $dref=$query->fetchrow_hashref())	{
		$id_ref->{'ProductByName'}{$dref->{'strName'}}{'ID'} = $dref->{'intProductID'};
	}
}


sub getSeasons	{

	my ($db, $realm, $id_ref) = @_;
	
	my $st = qq[
		SELECT
			intSeasonID,
			intAssocID,
			strSeasonName
		FROM
			tblSeasons
		WHERE intRealmID=?
	];

	my $query=$db->prepare($st);
	$query->execute($realm);
	while (my $dref=$query->fetchrow_hashref())	{
		$id_ref->{'SeasonByID'}{$dref->{'intSeasonID'}}{'Name'} = $dref->{'strSeasonName'};
		$id_ref->{'SeasonByName'}{$dref->{'strSeasonName'}}{'ID'} = $dref->{intSeasonID};
	}
}

sub updateVenueKeyValue
{
	my ($db, $venueID, $row, $config_ref) = @_;

	my $st = qq[
		INSERT INTO tblDefVenueKeyValue
		SET intVenueID=?, strKey=?,strValue=?
		ON DUPLICATE KEY UPDATE
			strValue=?
	];
	my $qry=$db->prepare($st);
	foreach my $key (keys %{$config_ref->{'VenuesKV'}})	{
		my $value = $row->{$key} || '';
		$qry->execute($venueID, $key, $value, $value);
	}
}


sub updateVenue	
{
	my ($db, $venueID, $row, $config_ref) = @_;

	my $set = '';
	my @binding_array=();
	foreach my $key (keys %{$config_ref->{'Venues'}})	{
		$set .= "," if ($set);
		$set .= $config_ref->{'Venues'}{$key} . "= ?";
		push @binding_array, $row->{$key};
	}
			
	return if ! $set;
	my $st = qq[
		UPDATE tblDefVenue as V
		SET $set
		WHERE
			intDefVenueID=$venueID
		LIMIT 1
	];
	my $qry=$db->prepare($st);
	$qry->execute(@binding_array);
}

sub handle_venues	{

	my ($db, $config_ref, $assocd, $newIDs, $vd)=@_;

	my $st=qq[
		INSERT INTO tblDefVenue (intRecStatus, intVenueSubRealmID, intAssocID, strName)
		VALUES (1, ?, ?, ?);
	];
	my $qry=$db->prepare($st);
	my $subRealmID = $config_ref->{'SubRealm'} || 0;

	my $count=0;
    	for my $row (@$vd)   {
		$count++;
		$row->{'VenueName'} || next;
		$row->{'Address1'} ||= '';
		$row->{'Address2'} ||= '';
		$row->{'Suburb'} ||= '';
		$row->{'XCoordinate'} ||= '';
		$row->{'YCoordinate'} ||= '';
		$row->{'AssocID'} || $config_ref->{'venueAssocID'} || 0;
		if ($row->{'AssocID'} eq 'ALL')	{
			for my $assoc (@$assocd)	{
				my $assocID = $assoc->{'AssocID'} || next;
				$qry->execute($subRealmID, $assocID, $row->{'VenueName'});
				my $venueID= $qry->{mysql_insertid};
				updateVenue($db, $venueID, $row, $config_ref);
				updateVenueKeyValue($db, $venueID, $row, $config_ref);
			}
		}
		else	{
			my $assocID = calcAssocID($row, $newIDs) || 0;
			$qry->execute($subRealmID, $assocID, $row->{'VenueName'});
			my $venueID= $qry->{mysql_insertid};
			updateVenue($db, $venueID, $row, $config_ref);
			updateVenueKeyValue($db, $venueID, $row, $config_ref);
		}
	}
}

sub handle_clubs {

	my ($db, $config_ref, $assocd, $cd, $newIDs)=@_;

	my $st_club=qq[
		INSERT INTO tblClub (intRecStatus, strClubCustomStr15, strName, strAbbrev, strAddress1, strAddress2, strSuburb, strPostalCode, strPhone, strWebURL, strClubNo, strExtKey, dtClubCustomDt1, dblClubCustomDbl1) 
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
	];
	my $qry=$db->prepare($st_club);

	my $st_assocclub=qq[
		INSERT IGNORE INTO tblAssoc_Clubs (intRecStatus, intAssocID, intClubID)
		VALUES (?, ?, ?)
	];
	my $qry_ac=$db->prepare($st_assocclub);

    	my $count=0;
    	for my $row (@$cd)   {
		$count++;
		my $assocID = 0;
		$row->{'ClubName'} || next;
		$row->{'ExtKey'} ||= '';
		$row->{'ClubNo'} ||= '';
		$row->{'AssocName'} ||= '';
		$row->{'AssocID'} ||= 0;
		$row->{'TypeID'} ||= 0;
		$row->{'ShortName'} ||= '';
		$row->{'Address1'} ||= '';
		$row->{'Address2'} ||= '';
		$row->{'Suburb'} ||= '';
		$row->{'Phone'} ||= '';
		$row->{'PostCode'} ||= '';
		$row->{'Status'} ||= '';
		$row->{'WebURL'} ||= '';
		my $status = 1;
		$status = 0 if ($row->{'Status'} eq 'Inactive');
		my $assocID = calcAssocID($row, $newIDs) || $config_ref->{'clubAssocID'} || 0;
		next if ! $assocID;
		$qry->execute($status, $row->{'ClubType'}, $row->{'ClubName'}, $row->{'ShortName'}, $row->{'Address1'}, $row->{'Address2'}, $row->{'Suburb'}, $row->{'PostCode'}, $row->{'Phone'}, $row->{'WebURL'}, $row->{'ClubNo'}, $row->{'ExtKey'}, $row->{'YearFormed'}, $row->{'TypeID'});
		my $clubID = $qry->{mysql_insertid};
		$qry_ac->execute($status, $assocID, $clubID);
		$newIDs->{$assocID}{'ClubByName'}{$row->{'ClubName'}}{'ID'} = $clubID;
		$newIDs->{$assocID}{'ClubByExtID'}{$row->{'ExtKey'}}{'ID'} = $clubID if ($row->{'ExtKey'});
	}
}


sub handle_members	{

	my ($db, $config_ref, $realmID, $md, $newIDs, $singleRow, $statusOverride)=@_;
	my $createdFrom = $config_ref->{'CreatedFrom'} || 0;

	my $st=qq[
		INSERT INTO tblMember (intRealmID, intCreatedFrom, intStatus, strMemberNo, strExtKey, strFirstname, strSurname, dtDOB, intGender) 
		VALUES (?, $config_ref->{'CreatedFrom'}, ?, ?, ?, ?, ?, ?, ?)
	];
	my $qry=$db->prepare($st);

 	my $count=0;
    	for my $row (@$md)   {
		$count++;
		my $assocID = 0;
		my $clubID= 0;
		$row->{'MemberExtID'} ||= '';
		my $ID = $row->{'MemberExtID'};
		$row->{'Firstname'} ||= '';
		$row->{'Surname'} ||= '';
		$row->{'Gender'} ||= '';
		if ($config_ref->{'RandomGender'} and ! $row->{'Gender'})	{
			$row->{'Gender'} = 1;
			if ($count % 3 == 0)	{
				$row->{'Gender'} = 2;
			}
		}
		$row->{'DOB'} ||= '';
		$row->{'FixedDOB'} = fixDate($config_ref, $row->{'DOB'});
		$row->{'Country'} ||= $config_ref->{'Country'};
		$row->{'Country'} = 'Finland' if (uc($row->{'Country'}) eq 'SUOMI');
		$row->{'Status'} ||= '';
		$row->{'PassportExpiryDate'} ||= '';
		$row->{'LastRegisteredDate'} ||='';
	
		my $status = 0;
		$status = 1 if (uc($row->{'Status'}) eq 'ACTIVE');
		$status = 1 if (uc($row->{'Status'}) eq 'AKTIIVINEN');
		$status = $statusOverride if (defined $statusOverride);	
		$qry->execute($realmID, $status, $row->{'MemberExtID'}, $row->{'MemberExtID'}, $row->{'Firstname'}, $row->{'Surname'}, $row->{'FixedDOB'}, $row->{'Gender'});
		my $memberID= $qry->{mysql_insertid};

		my $assocID = calcAssocID($row, $newIDs) || 0;
		my $clubID= calcClubID($db, $assocID, $row, $newIDs) || 0;
		my $dtLastRegistered = fixDate($config_ref, $row->{'LastRegisteredDate'});
		insertMA_row($db, 1, $assocID, $memberID, $dtLastRegistered) if ($assocID);
		insertMC_row($db, 1, $clubID, $memberID,1) if ($clubID);
		insertMS($db, 'Members', $config_ref, $realmID, $assocID, 0, $memberID);
		insertMS($db, 'Members', $config_ref, $realmID, $assocID, $clubID, $memberID) if ($clubID);
		updateMCustomFields($db, 'Members', $memberID, $assocID, $row, $config_ref, $newIDs);
		$newIDs->{'MemberByExtID'}{$ID}{'ID'} = $memberID;
		if ($singleRow)	{
			return $memberID;
		}
	}
}

sub insertMS	{
	my($db, $section, $config_ref, $realmID, $assocID, $clubID, $memberID) = @_;
	my $seasonID = $config_ref->{'SeasonID'} || 0;
	return if (!$realmID or !$memberID or !$assocID or !$seasonID);

	my $sectionFieldInsert ='';
	my $sectionFieldUpdate ='tTimeStamp=NOW()';
	if ($section eq "Players")	{
		$sectionFieldUpdate= " intPlayerStatus=1";
		$sectionFieldInsert = ", " . $sectionFieldUpdate
	}
	if ($section eq "Referees")	{
		$sectionFieldInsert = ", intUmpireStatus=1";
		$sectionFieldUpdate= " intUmpireStatus=1";
	}
	if ($section eq "Coaches")	{
		$sectionFieldInsert = ", intCoachStatus=1";
		$sectionFieldUpdate= " intCoachStatus=1";
	}
	my $st=qq[
		INSERT INTO tblMember_Seasons_$realmID
			SET intSeasonID=?, intMemberID=?, intClubID=?, intAssocID=?, intMSRecStatus=? $sectionFieldInsert
		ON DUPLICATE KEY UPDATE $sectionFieldUpdate
	];
	my $qry=$db->prepare($st);
	$qry->execute($seasonID, $memberID, $clubID, $assocID, 1);
}


sub handle_RefCoachTypes	{
	my ($db, $section, $config_ref, $realmID, $subRealmID, $pd, $newIDs)=@_;

    	my $count=0;
	for my $row (@$pd)   {
		$count++;
		my $memberID=0;
		my $assocID=0;
		my $clubID=0;
		$row->{'MemberExtID'} || 0;
		$row->{'AssocID'} ||= '';
		$row->{'AssocName'} ||= '';
		$row->{'ClubID'} ||= '';
		$row->{'ClubName'} ||= '';

		$row->{'dateOfCitizenship'} = fixDate($config_ref, $row->{'dateOfCitizenship'});
		$row->{'dateOfPR'} = fixDate($config_ref, $row->{'dateOfPR'});
		$row->{'DateStartEnlistment'} = fixDate($config_ref, $row->{'DateStartEnlistment'});
		$row->{'DateEndEnlistment'} = fixDate($config_ref, $row->{'DateEndEnlistment'});

		$assocID = calcAssocID($row, $newIDs) || 0;
		if ($section eq 'Coaches' and !$assocID)	{
			$assocID = $config_ref->{'coachAssocID'} || 0;;
		}
		if ($section eq 'Referees' and !$assocID)	{
			$assocID = $config_ref->{'refAssocID'} || 0;;
		}
		my $clubID= calcClubID($db,$assocID, $row, $newIDs) || 0;
		my $memberID= calcMemberID($row, $newIDs) || 0;
		if (!$memberID and exists $row->{'Firstname'} and exists $row->{'Surname'})	{
			my @md = ();
			push @md, $row;
			$memberID = handle_members($db, $config_ref, $realmID, \@md, $newIDs, 1, $config_ref->{$section.'_MemberStatusOverride'}); ## 1 defines "single row"
		}
		if (! $memberID)	{
			print "ERROR - $section record not inserted. A|$assocID, M|$memberID. " . $row->{'MemberExtID'} . "\n";
			next;
		}
		my $dtLastRegistered = fixDate($config_ref, $row->{'LastRegisteredDate'});
		insertMA_row($db, 1, $assocID, $memberID, $dtLastRegistered) if ($assocID);
		insertMC_row($db, 1, $clubID, $memberID,1) if ($clubID);

		insertMS($db, $section, $config_ref, $realmID, $assocID, 0, $memberID);
		insertMS($db, $section, $config_ref, $realmID, $assocID, $clubID, $memberID) if ($clubID);
		if ($section eq 'Coaches')	{
			$config_ref->{'Coaches'}{'isCoach'} = 'M.intCoach';
			$row->{'isCoach'} = 1;
		}
		if ($section eq 'Referees')	{
			$config_ref->{'Referees'}{'isUmpire'} = 'M.intUmpire';
			$row->{'isUmpire'} = 1;
		}
		updateMCustomFields($db, $section, $memberID, $assocID, $row, $config_ref, $newIDs);
	}
}


sub handle_players {

	my ($db, $config_ref, $realmID, $subRealmID, $assocd, $pd, $newIDs)=@_;

    	my $count=0;
    	for my $row (@$pd)   {
		$count++;
		$row->{'MemberExtID'} || 0;
		$row->{'AssocID'} ||= '';
		$row->{'AssocName'} ||= '';
		$row->{'ClubID'} ||= '';
		$row->{'ClubName'} ||= '';
		$row->{'Sport'} ||= '';
		$row->{'Product'} ||= '';
		$row->{'Amount'} ||= '';
		$row->{'DatePaid'} ||= '';
		$row->{'NSServedYN'} = (uc($row->{'NSServed'}) eq 'YES') ? 1: 0;

		$row->{'dateOfCitizenship'} = fixDate($config_ref, $row->{'dateOfCitizenship'});
		$row->{'dateOfPR'} = fixDate($config_ref, $row->{'dateOfPR'});
		$row->{'DateStartEnlistment'} = fixDate($config_ref, $row->{'DateStartEnlistment'});
		$row->{'DateEndEnlistment'} = fixDate($config_ref, $row->{'DateEndEnlistment'});
		insertProduct($db, $realmID, $config_ref->{'SeasonID'}, $row->{'Product'}, $newIDs) if ($row->{'Product'});
		my $productID = $newIDs->{'ProductByName'}{$row->{'Product'}}{'ID'} || 0;
		my $assocID = calcAssocID($row, $newIDs) || $config_ref->{'playerAssocID'} || 0;
		my $clubID= calcClubID($db,$assocID, $row, $newIDs) || 0;
		my $memberID= calcMemberID($row, $newIDs) || 0;
		if (!$memberID and exists $row->{'Firstname'} and exists $row->{'Surname'})	{
			my @md = ();
			push @md, $row;
			$memberID = handle_members($db, $config_ref, $realmID, \@md, $newIDs, 1, $config_ref->{'Players_MemberStatusOverride'}); ## 1 defines "single row"
		}
		if ((!$assocID and !$clubID) or !$memberID)	{
			print "ERROR - Playing record not inserted. A|$assocID, C|$clubID, M|$memberID. " . $row->{'MemberExtID'} . "|" . $row->{'ClubName'} . "|" . $row->{'AssocName'} . "\n";
			next;
		}

		my $dtLastRegistered = fixDate($config_ref, $row->{'LastRegisteredDate'});
		insertMA_row($db, 1, $assocID, $memberID, $dtLastRegistered);
		insertMC_row($db, 1, $clubID, $memberID,1) if ($clubID);
		insertMS($db, 'Players', $config_ref, $realmID, $assocID, 0, $memberID);
		insertMS($db, 'Players', $config_ref, $realmID, $assocID, $clubID, $memberID) if ($clubID);
		my ($futsal, $football) = (0,0);
		$football =1 if (uc($row->{'Sport'}) eq 'FOOTBALL' or uc($row->{'Sport'}) eq 'BOTH');
		$futsal=1 if (uc($row->{'Sport'}) eq 'FUTSAL' or uc($row->{'Sport'}) eq 'BOTH');
		$config_ref->{'Players'}{'FootballPlayer'} = 'M.intNatCustomBool1';
		$config_ref->{'Players'}{'FutsalPlayer'} = 'M.intNatCustomBool2';
		$config_ref->{'Players'}{'isPlayer'} = 'M.intPlayer';
		$row->{'isPlayer'} = 1;
		$row->{'FootballPlayer'} = $football;
		$row->{'FutsalPlayer'} = $futsal;
		updateMCustomFields($db, 'Players', $memberID, $assocID, $row, $config_ref, $newIDs);
		if ($productID)	{
			$row->{'FixedDatePaid'} = fixDate($config_ref, $row->{'DatePaid'});
			insertTransaction($db, $assocID, $clubID, $config_ref->{'SeasonID'}, $realmID, $subRealmID, $memberID, $productID, $row->{'Amount'}, $row->{'FixedDatePaid'});
		}
	}
}

sub calcLUValue	{
	my ($db, $fieldname, $value, $newIDs, $realmID) =@_;

	my $retValue=0;
	if (! $value or $value eq 'NULL')	{
		return 0;
	}
	elsif ($newIDs->{'LUByValue'}{$fieldname}{$value}{'ID'})	{
		return $newIDs->{'LUByValue'}{$fieldname}{$value}{'ID'};
	}
	else	{
		my %DefCodes=(
			'intNatCustomLU1'=>-53,
			'intNatCustomLU2'=>-54,
			'intNatCustomLU3'=>-55,
			'intNatCustomLU4'=>-64,
			'intNatCustomLU5'=>-65,
			'intNatCustomLU6'=>-66,
			'intNatCustomLU7'=>-67,
			'intNatCustomLU8'=>-68,
			'intNatCustomLU9'=>-69,
			'intNatCustomLU10'=>-70,
		);
		my $st = qq[
			INSERT INTO tblDefCodes
			(intType, strName, intRealmID, intRecStatus)
			VALUES (?,?,?, 1)
		];

		my $qry=$db->prepare($st);
		$qry->execute($DefCodes{$fieldname}, $value, $realmID);
		$retValue= $qry->{mysql_insertid};
		$newIDs->{'LUByValue'}{$fieldname}{$value}{'ID'} = $retValue;
	}
	return $retValue || 0;
}

sub updateMCustomFields	{
	my ($db, $section, $memberID, $assocID, $row, $config_ref, $newIDs) = @_;

	my $set = '';
	my @binding_array=();
	foreach my $key (keys %{$config_ref->{$section}})	{
		$set .= "," if ($set);
		$set .= $config_ref->{$section}{$key} . "= ?";
		my $value=$row->{$key} || '';
		$value = 0 if ($config_ref->{$section}{$key} =~ /\.dbl/ and (!$value or ! defined $value));
		$value = 0 if ($config_ref->{$section}{$key} =~ /\.int/ and (!$value or ! defined $value));
		$value = '' if ($config_ref->{$section}{$key} =~ /\.str/ and (!$value or ! defined $value));
		my $fieldname = $config_ref->{$section}{$key};
		$fieldname =~ s/^.*\.//g;
		if ($fieldname =~ /CustomLU/)	{
			$value = calcLUValue($db, $fieldname, $value, $newIDs, $config_ref->{'Realm'});
		}
		push @binding_array, $value;
	}
			
	return if ! $set;
	my $st = qq[
		UPDATE tblMember as M LEFT JOIN tblMember_Associations as MA ON (MA.intMemberID=M.intMemberID)
		SET $set
		WHERE
			M.intMemberID=$memberID
	];
	if ($assocID)	{
		$st .= qq[
			AND MA.intAssocID=$assocID
		];
	}
	my $qry=$db->prepare($st);
	$qry->execute(@binding_array);
}

sub fixDate	{
	my ($config_ref, $date) = @_;
	if ($date =~ /(\d{1,2})\.(\d{1,2})\.(\d{4})/)	{
		$date =~ s/(\d{1,2})\.(\d{1,2})\.(\d{4})/$3-$2-$1/;
	}
#	if ($date =~ /(\d{2})\.(\d{2})\.(\d{4})/)	{
#		$date =~ s/(\d{2})\.(\d{2})\.(\d{4})/$3-$2-$1/;
#	}
	if ($config_ref->{'DateMDY'} and $date =~ /(\d{1,2})\/(\d{1,2})\/(\d{4})/)	{
		$date =~ s/(\d{1,2})\/(\d{1,2})\/(\d{4})/$3-$1-$2/;
	}
	elsif($date =~ /(\d{1,2})\/(\d{1,2})\/(\d{4})/)	{
		$date =~ s/(\d{1,2})\/(\d{1,2})\/(\d{4})/$3-$2-$1/;
	}
	return $date;
}
sub insertTransaction {
	my ($db, $assocID, $clubID, $seasonID, $realmID, $subRealmID, $memberID, $productID, $amount, $dtPaid) = @_;

	$assocID ||=0;# return;
	$realmID ||=0;# return;
	$memberID ||=0;# return;
	$productID ||=0;# return;
	$amount ||= 0;
	$subRealmID ||=0;
	$clubID ||= 0;
	$seasonID ||= 0;

	my $st = qq[
		INSERT INTO tblTransactions 
		(intStatus, curAmount, intQty, dtTransaction, dtPaid, intAssocID, intRealmID, intRealmSubTypeID, intID, intTableType, intProductID, intTransLogID, curPerItem, intTXNClubID)
		VALUES (0,?,1,?,?,?,?,?,?,1,?,?,?,?)
	];
	my $qry=$db->prepare($st);
	$qry->execute($amount, $dtPaid, $dtPaid, $assocID, $realmID, $subRealmID, $memberID, $productID, 0, $amount, $clubID);
	my $txnID= $qry->{mysql_insertid};

	return if (! $txnID);
	my $st_tl = qq[
		INSERT INTO tblTransLog
		(dtLog, intAmount, intPaymentType, intRealmID, intAssocPaymentID, intClubPaymentID, intStatus)
		VALUES (?,?,3,?,?,?,1)
	];
	$qry=$db->prepare($st_tl);
	$qry->execute($dtPaid, $amount, $realmID, $assocID, $clubID);
	my $logID= $qry->{mysql_insertid};
	return if (! $logID);

	my $st_txnlogs = qq[
		INSERT INTO tblTXNLogs
		(intTXNID, intTLogID)
		VALUES (?,?)
	];
	$qry=$db->prepare($st_txnlogs);
	$qry->execute($txnID, $logID);

	$st= qq[
		UPDATE tblTransactions
		SET intStatus=1, intTransLogID=?
		WHERE intTransactionID=?
		LIMIT 1
	];
	$qry=$db->prepare($st);
	$qry->execute($logID, $txnID);
}


sub insertProduct	{
	my ($db, $realmID, $seasonID, $productName, $newIDs) = @_;

	return if (! $productName);
	return if (exists $newIDs->{'ProductByName'}{$productName}{'ID'} and $newIDs->{'ProductByName'}{$productName}{'ID'});
	my $st = qq[
		INSERT INTO tblProducts
		(strName, intRealmID, intProductSeasonID)
		VALUES (?,?,?)
	];
	my $qry=$db->prepare($st);
	$qry->execute($productName, $realmID, $seasonID);
	my $productID= $qry->{mysql_insertid};
	
	$newIDs->{'ProductByName'}{$productName}{'ID'} = $productID;
}


1;
