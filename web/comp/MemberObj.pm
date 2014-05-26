#
# $Header: svn://svn/SWM/trunk/web/comp/MemberObj.pm 10035 2013-12-01 01:27:12Z cchurchill $
#

package MemberObj;

use strict;
use BaseObject;
our @ISA =qw(BaseObject);


sub load {
  my $self = shift;

	my $st=qq[
  SELECT
    tblMember.*,
    MA.intRecStatus,
    DATE_FORMAT(dtPassportExpiry,'%d/%m/%Y') AS dtPassportExpiry,
    DATE_FORMAT(dtDOB,'%d/%m/%Y') AS dtDOB,
    tblMember.dtDOB AS dtDOB_RAW,
    DATE_FORMAT(dtLastRegistered,'%d/%m/%Y') AS dtLastRegistered,
    DATE_FORMAT(dtRegisteredUntil,'%d/%m/%Y') AS dtRegisteredUntil,
    DATE_FORMAT(dtFirstRegistered,'%d/%m/%Y') AS dtFirstRegistered,
    DATE_FORMAT(dtPoliceCheck,'%d/%m/%Y') AS dtPoliceCheck,
    DATE_FORMAT(dtPoliceCheckExp,'%d/%m/%Y') AS dtPoliceCheckExp,
    DATE_FORMAT(dtCreatedOnline,'%d/%m/%Y') AS dtCreatedOnline,
    DATE_FORMAT(tblMember.tTimeStamp,'%d/%m/%Y') AS tTimeStamp,
    MA.strCustomStr1,
    MA.strCustomStr2,
    MA.strCustomStr3,
    MA.strCustomStr4,
    MA.strCustomStr5,
    MA.strCustomStr6,
    MA.strCustomStr7,
    MA.strCustomStr8,
    MA.strCustomStr9,
    MA.strCustomStr10,
    MA.strCustomStr11,
    MA.strCustomStr12,
    MA.strCustomStr13,
    MA.strCustomStr14,
    MA.strCustomStr15,
    MA.strCustomStr16,
    MA.strCustomStr17,
    MA.strCustomStr18,
    MA.strCustomStr19,
    MA.strCustomStr20,
    MA.strCustomStr21,
    MA.strCustomStr22,
    MA.strCustomStr23,
    MA.strCustomStr24,
    MA.strCustomStr25,
    MA.dblCustomDbl1,
    MA.dblCustomDbl2,
    MA.dblCustomDbl3,
    MA.dblCustomDbl4,
    MA.dblCustomDbl5,
    MA.dblCustomDbl6,
    MA.dblCustomDbl7,
    MA.dblCustomDbl8,
    MA.dblCustomDbl9,
    MA.dblCustomDbl10,
    MA.dblCustomDbl11,
    MA.dblCustomDbl12,
    MA.dblCustomDbl13,
    MA.dblCustomDbl14,
    MA.dblCustomDbl15,
    MA.dblCustomDbl16,
    MA.dblCustomDbl17,
    MA.dblCustomDbl18,
    MA.dblCustomDbl19,
    MA.dblCustomDbl20,
    DATE_FORMAT(MA.dtCustomDt1, '%d/%m/%Y') AS dtCustomDt1,
    DATE_FORMAT(MA.dtCustomDt2, '%d/%m/%Y') AS dtCustomDt2,
    DATE_FORMAT(MA.dtCustomDt3, '%d/%m/%Y') AS dtCustomDt3,
    DATE_FORMAT(MA.dtCustomDt4, '%d/%m/%Y') AS dtCustomDt4,
    DATE_FORMAT(MA.dtCustomDt5, '%d/%m/%Y') AS dtCustomDt5,
    DATE_FORMAT(MA.dtCustomDt6, '%d/%m/%Y') AS dtCustomDt6,
    DATE_FORMAT(MA.dtCustomDt7, '%d/%m/%Y') AS dtCustomDt7,
    DATE_FORMAT(MA.dtCustomDt8, '%d/%m/%Y') AS dtCustomDt8,
    DATE_FORMAT(MA.dtCustomDt9, '%d/%m/%Y') AS dtCustomDt9,
    DATE_FORMAT(MA.dtCustomDt10,'%d/%m/%Y') AS dtCustomDt10,
    DATE_FORMAT(MA.dtCustomDt11,'%d/%m/%Y') AS dtCustomDt11,
    DATE_FORMAT(MA.dtCustomDt12,'%d/%m/%Y') AS dtCustomDt12,
    DATE_FORMAT(MA.dtCustomDt13,'%d/%m/%Y') AS dtCustomDt13,
    DATE_FORMAT(MA.dtCustomDt14,'%d/%m/%Y') AS dtCustomDt14,
    DATE_FORMAT(MA.dtCustomDt15,'%d/%m/%Y') AS dtCustomDt15,
    MA.intCustomLU1,
    MA.intCustomLU2,
    MA.intCustomLU3,
    MA.intCustomLU4,
    MA.intCustomLU5,
    MA.intCustomLU6,
    MA.intCustomLU7,
    MA.intCustomLU8,
    MA.intCustomLU9,
    MA.intCustomLU10,
    MA.intCustomLU11,
    MA.intCustomLU12,
    MA.intCustomLU13,
    MA.intCustomLU14,
    MA.intCustomLU15,
    MA.intCustomLU16,
    MA.intCustomLU17,
    MA.intCustomLU18,
    MA.intCustomLU19,
    MA.intCustomLU20,
    MA.intCustomLU21,
    MA.intCustomLU22,
    MA.intCustomLU23,
    MA.intCustomLU24,
    MA.intCustomLU25,
    MA.intCustomBool1,
    MA.intCustomBool2,
    MA.intCustomBool3,
    MA.intCustomBool4,
    MA.intCustomBool5,
    MA.intCustomBool6,
    MA.intCustomBool7,
    DATE_FORMAT(dtNatCustomDt1,'%d/%m/%Y') AS dtNatCustomDt1,
    DATE_FORMAT(dtNatCustomDt2,'%d/%m/%Y') AS dtNatCustomDt2,
    DATE_FORMAT(dtNatCustomDt3,'%d/%m/%Y') AS dtNatCustomDt3,
    DATE_FORMAT(dtNatCustomDt4,'%d/%m/%Y') AS dtNatCustomDt4,
    DATE_FORMAT(dtNatCustomDt5,'%d/%m/%Y') AS dtNatCustomDt5,
    tblSchool.strName AS strSchoolName,
    tblSchool.strSuburb AS strSchoolSuburb,
    tblSchool.strSuburb AS strSchoolSuburb,
    A.intAssocTypeID,
    MA.intLifeMember,
    MA.curMemberFinBal,
    MA.intFinancialActive,
    MA.intMemberPackageID,
    MA.strLoyaltyNumber,
    MA.intMailingList,
    MN.strMemberNotes,
    MN.strMemberMedicalNotes,
    MN.strMemberCustomNotes1,
    MN.strMemberCustomNotes2,
    MN.strMemberCustomNotes3,
    MN.strMemberCustomNotes4,
    MN.strMemberCustomNotes5
      FROM
    tblMember
    LEFT  JOIN tblMember_Associations AS MA ON (MA.intMemberID=tblMember.intMemberID and MA.intAssocID= ? )
    LEFT JOIN tblAssoc AS A ON (MA.intAssocID=A.intAssocID)
    LEFT JOIN tblSchool ON (tblMember.intSchoolID=tblSchool.intSchoolID)
    LEFT JOIN tblMemberNotes as MN ON (
      MN.intNotesMemberID = tblMember.intMemberID
      AND MN.intNotesAssocID=MA.intAssocID
    )
      WHERE
    tblMember.intMemberID = ?
	];
	my $q = $self->{'db'}->prepare($st);
	$q->execute(
		$self->{'assocID'},
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

    my $surname   = $self->getValue('strSurname');
    my $firstname = $self->getValue('strFirstname');

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
            M.strFirstname,
            M.strSurname,
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
