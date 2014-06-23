package PersonObj;

use strict;
use BaseObject;
our @ISA =qw(BaseObject);


sub load {
  my $self = shift;

	my $st=qq[
  SELECT
    tblPerson.*,
    DATE_FORMAT(dtPassportExpiry,'%d/%m/%Y') AS dtPassportExpiry,
    DATE_FORMAT(dtDOB,'%d/%m/%Y') AS dtDOB,
    tblPerson.dtDOB AS dtDOB_RAW,
    DATE_FORMAT(dtPoliceCheck,'%d/%m/%Y') AS dtPoliceCheck,
    DATE_FORMAT(dtPoliceCheckExp,'%d/%m/%Y') AS dtPoliceCheckExp,
    DATE_FORMAT(tblPerson.tTimeStamp,'%d/%m/%Y') AS tTimeStamp,
    DATE_FORMAT(dtNatCustomDt1,'%d/%m/%Y') AS dtNatCustomDt1,
    DATE_FORMAT(dtNatCustomDt2,'%d/%m/%Y') AS dtNatCustomDt2,
    DATE_FORMAT(dtNatCustomDt3,'%d/%m/%Y') AS dtNatCustomDt3,
    DATE_FORMAT(dtNatCustomDt4,'%d/%m/%Y') AS dtNatCustomDt4,
    DATE_FORMAT(dtNatCustomDt5,'%d/%m/%Y') AS dtNatCustomDt5,
    MN.strNotes
      FROM
    tblPerson
    LEFT JOIN tblPersonNotes as MN ON (
      MN.intPersonID = tblPerson.intPersonID
    )
      WHERE
    tblPerson.intPersonID = ?
	];
	my $q = $self->{'db'}->prepare($st);
	$q->execute(
		$self->{'ID'},
	);
	if($DBI::err)	{
		$self->LogError($DBI::err);
	}
	else	{
		$self->{'DBData'}=$q->fetchrow_hashref();	
	}
}

sub name {
    my $self = shift;

    my $surname   = $self->getValue('strLocalSurname');
    my $firstname = $self->getValue('strLocalFirstname');

    return "$firstname $surname";
}


sub assocID {
  my $self = shift;
  return $self->{'assocID'} || 0;
}

# Across realm check to see there is an existing member with this firstname/surname/dob and with primary club set.
# Static method.
sub already_exists {
    my $class = shift;

    my ($Data, $new_member, $sub_realm_id) = @_;

    my $realm_id = $Data->{'Realm'};

    $sub_realm_id ||= $Data->{'RealmSubType'};

    my $st = qq[
        SELECT
            MC.intMemberID,
            M.strLocalFirstname,
            M.strLocalSurname,
            M.strEmail,
            M.dtDOB,
            M.strNationalNum,
            DATE_FORMAT(MT.dtDate1, '%d/%m/%Y') AS LastPlayed,
            MC.intClubID,
            C.strName  AS ClubName,
            A.intAssocID,
            A.strName  AS AssocName,
            A.strState AS AssocState,
            TNS.int30_ID AS SourceStateID
        FROM tblMember_Clubs                AS MC
            INNER JOIN tblMember            AS M  ON (M.intMemberID =  MC.intMemberID) 
            INNER JOIN tblClub              AS C  ON (C.intClubID = MC.intClubID)
            INNER JOIN tblAssoc_Clubs       AS AC ON (AC.intClubID = C.intClubID)
            INNER JOIN tblAssoc             AS A  ON (A.intAssocID=AC.intAssocID)
            LEFT  JOIN tblMember_Types      AS MT ON (MT.intAssocID=A.intAssocID AND MT.intMemberID=MC.intMemberID)
            INNER JOIN tblTempNodeStructure AS TNS ON TNS.intAssocID=A.intAssocID
        WHERE
            A.intRealmID=?
            AND A.intAssocTypeID=?
#            AND M.intPlayer=1
            AND M.strFirstname=?
            AND M.strSurname=?
            AND M.dtDOB=?
            AND M.intStatus=1
#           AND MC.intPrimaryClub=1 #temporary patch for natrego demo purposes.
        ORDER BY
            LastPlayed, AssocName
     ];

    my $q = $Data->{'db'}->prepare($st);
    $q->execute(
        $realm_id,
        $sub_realm_id,
        $new_member->{'firstname'},
        $new_member->{'surname'},
        $new_member->{'dob'},
    );

    my @matched_members = ();
    while (my $dref = $q->fetchrow_hashref()) {
        push @matched_members, $dref;
 }
    return \@matched_members;
}

1;
