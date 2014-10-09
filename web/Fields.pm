#
# $Header: svn://svn/SWM/trunk/web/Fields.pm 10369 2014-01-03 08:58:32Z cgao $
#

package Fields;
require Exporter;
@ISA =  qw(Exporter);
@EXPORT = qw();
@EXPORT_OK = qw();

use strict;

my $Fields = {
	Member => qw(
        strNationalNum
		strMemberNo
		intActive
		strSalutation
		strFirstname
		strMiddlename
		strSurname
		strMaidenName
		strPreferredName
        intLocalLanguage
		dtDOB
		strPlaceofBirth
		strGender
		strAddress1
		strAddress2
		strSuburb
		strState
		strCityOfResidence
		strCountry
		strPostalCode
		strPhoneHome
		strPhoneWork
		strPhoneMobile
		strPager
		strFax
		strEmail
		strEmail2 
        strStatus
        strEntityType
		intOccupationID
		intEthnicityID
		intMailingList
		intLifeMember
		intDeceased
		strLoyaltyNumber
		curMemberFinBal
		strPreferredLang
		strPassportNationality
		strPassportNo
		strPassportIssueCountry
		dtPassportExpiry
		strBirthCertNo
		strHealthCareNo
		intIdentTypeID
		strIdentNum
		strEmergContName
		strEmergContRel
		strP1FName
		strP1SName
		strP2FName
		strP2SName
		strEyeColour
		strHairColour
		strHeight
		strWeight
		intPlayer
		intCoach
		intUmpire
		intOfficial
		intMisc
		intVolunteer
        intPlayerPending
		dtFirstRegistered
		dtLastRegistered
		dtRegisteredUntil
		dtLastUpdate
		dtSuspendedUntil
		intFavNationalTeamMember
		intAttendSportCount
		intWatchSportHowOftenID
		strMemberCustomNotes1
		strMemberCustomNotes2
		strMemberCustomNotes3
		strMemberCustomNotes4
		strMemberCustomNotes5
        intMemberToHideID
        intPhotoUseApproval
	),

}

