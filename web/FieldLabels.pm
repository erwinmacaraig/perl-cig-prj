#
# $Header: svn://svn/SWM/trunk/web/FieldLabels.pm 11586 2014-05-16 04:19:10Z sliu $
#

package FieldLabels;
require Exporter;
@ISA = qw(Exporter);
@EXPORT=qw(getFieldLabels);

use strict;

use lib '.', '..';

use Defs;
require CustomFields;

sub getFieldLabels	{
	my($Data, $level)=@_;

	my %labels=();
	return \%labels if(!$Data or !$level);

	my $txt_SeasonName= $Data->{'SystemConfig'}{'txtSeason'} || 'Season';
	my $txt_AgeGroupName= $Data->{'SystemConfig'}{'txtAgeGroup'} || 'Age Group';
	my $natnumname=$Data->{'SystemConfig'}{'NationalNumName'} || 'National Number';
	my $natteamname=$Data->{'SystemConfig'}{'NatTeamName'} || 'National Team';

	my $CustomFieldNames=CustomFields::getCustomFieldNames($Data);
	if($level== $Defs::LEVEL_PERSON)	{

		%labels = (
			strNationalNum => $natnumname,
			strStatus => "Active",
			strSalutation => 'Title',
			strLocalFirstname => 'First name',
			strLocalMiddlename => 'Middle name',
			strPreferredName => 'Preferred name',
			strLocalSurname => 'Family name',
			strLatinSurname => 'Family name (Latin)',


			strMaidenName => 'Maiden name',
			strMotherCountry=> 'Country of Birth (Mother)',
			strFatherCountry=> 'Country of Birth (Father)',
			dtDOB => 'Date of Birth',
			strPlaceofBirth => 'Place (Town) of Birth',
            strCountryOfBirth => 'Country of Birth',
			intGender => 'Gender',
			strAddress1 => 'Address Line 1',
			strAddress2 => 'Address Line 2',
			strSuburb => 'Suburb',
			strState => 'State',
			strCityOfResidence => 'City of Residence',
			strCountry => 'Country',
			strPostalCode => 'Postal Code',
			strPhoneHome => 'Phone (Home)',
			strPhoneWork => 'Phone (Work)',
			strPhoneMobile => 'Phone (Mobile)',
			strPager => 'Pager',
			strFax => 'Fax',
			strEmail => 'Email',
			strEmail2 => 'Email 2',
			intOccupationID => 'Occupation',
			intEthnicityID => 'Ethnicity',
			intMailingList => 'Mailing List?',
			intLifeMember => 'Life Member?',
			intDeceased => 'Deceased?',
			strLoyaltyNumber => 'Loyalty Number',
			intFinancialActive => 'Member Financial?',
			intMemberPackageID => 'Membership Package',
			curMemberFinBal => 'Member Financial Balance',
			strPassportNationality => 'Passport Nationality',
			strPassportNo => 'Passport Number',
			strPassportIssueCountry => 'Passport Country of Issue',
			dtPassportExpiry => 'Passport Expiry Date',
			strBirthCertNo => 'Birth Certificate Number',
			strHealthCareNo => 'Health Care Number',
			intIdentTypeID => 'Identification Type',
			strIdentNum => 'Identification Number',
			strEmergContName => 'Emergency Contact Name',
			strEmergContNo => 'Emergency Contact Number',
			strEmergContNo2 => 'Emergency Contact Number 2',
			strEmergContRel => 'Emergency Contact Relationship',
			intP1Gender => 'Parent/Guardian 1 Gender',
			intP2Gender => 'Parent/Guardian 2 Gender',
			strP1Salutation=> 'Parent/Guardian 1 Salutation',
			strP1FName => 'Parent/Guardian 1 Firstname',
			strP1SName => 'Parent/Guardian 1 Surname',
			strP2Salutation=> 'Parent/Guardian 2 Salutation',
			strP2FName => 'Parent/Guardian 2 Firstname',
			strP2SName => 'Parent/Guardian 2 Surname',
			strP1Phone => 'Parent/Guardian 1 Phone',
			strP1Phone2 => 'Parent/Guardian 1 Phone 2',
			strP1PhoneMobile => 'Parent/Guardian 1 Mobile',
			strP2Phone => 'Parent/Guardian 2 Phone',
			strP2Phone2 => 'Parent/Guardian 2 Phone 2',
			strP2PhoneMobile => 'Parent/Guardian 2 Mobile',
			strP1Email=> 'Parent/Guardian 1 Email',
			strP2Email=> 'Parent/Guardian 2 Email',
			strP1Email2=> 'Parent/Guardian 1 Email 2',
			strP2Email2=> 'Parent/Guardian 2 Email 2',
			strEyeColour => 'Eye Colour',
			strHairColour => 'Hair Colour',
			strHeight => 'Height',
			strWeight => 'Weight',
			intPlayer => 'Player?',
			intCoach => 'Coach?',
			intUmpire => 'Match Official?',
			intOfficial => 'Official?',
			intMisc => 'Misc?',
			intVolunteer => 'Volunteer?',
			strNotes => 'Notes',
			dtFirstRegistered => 'Date First Registered',
			dtLastRegistered => 'Date Last Registered',
			dtRegisteredUntil => 'Date Registered Until',
			dtLastUpdate => 'Last Updated',
			tTimeStamp => 'Last Updated',
			dtSuspendedUntil => 'Date Suspended Until',
			dtPoliceCheck => $Data->{'SystemConfig'}{'dtPoliceCheck_Text'} ? $Data->{'SystemConfig'}{'dtPoliceCheck_Text'} : 'Police Check Date',
			dtPoliceCheckExp => $Data->{'SystemConfig'}{'dtPoliceCheckExp_Text'} ? $Data->{'SystemConfig'}{'dtPoliceCheckExp_Text'} : 'Police Check Expiry Date',
			strPoliceCheckRef => 'Police Check Number',
			intFavStateTeamID => 'State Team Supported',
			intFavNationalTeamID => $natteamname.' Supported',
			intFavNationalTeamMember=> 'Are you a member of '. $natteamname,
			intAttendSportCount=> $Data->{'SystemConfig'}{'intAttendSportCount_Text'} ? $Data->{'SystemConfig'}{'intAttendSportCount_Text'} : 'How many national games do you attend per season?',
			intWatchSportHowOftenID=> 'How often do you watch matches on TV?',
			intHowFoundOutID	=> 'How did you find out about us?',
			intMedicalConditions => 'Any Medical Conditions?',
			strMedicalNotes => $Data->{'SystemConfig'}{'strMedicalNotesFieldName'} ? $Data->{'SystemConfig'}{'strMedicalNotesFieldName'} : 'Medical Notes',
			intP1AssistAreaID => 'Parent/Guardian 1 Assistance Area',
			intP2AssistAreaID => 'Parent/Guardian 2 Assistance Area',
			intAllowMedicalTreatment => 'Allow Medical Treatment',
			intAllergies => 'Any Allergies',
			intConsentSignatureSighted => 'Signature Sighted',
			dtCreatedOnline => 'Date Created Online',
			intSchoolID	=> 'School',
			strSchoolName => 'School Name',
			strSchoolSuburb => 'School Suburb ',
			intGradeID => 'School Grade',
			intOfflineID	=> 'Offline Number',
			addCertificate => ' ', #RE
            intMemberToHideID => "Upload to Website Results",
			strPreferredLang => 'Preferred Language',
            intPhotoUseApproval => 'Photo Use Approval',
       
			#Member Types - Player
			'Player.intActive' => 'Player Active?',
			'Player.dtDate1' => 'Last Recorded Game',
			'Player.intInt1' => 'Career Games',
			'Player.intInt2' => 'Junior?',
			'Player.intInt3' => 'Senior?',
			'Player.intInt4' => 'Veteran?',

			#Member Types - Coach
			'Coach.intActive' => 'Coach Active?',
			'Coach.strString1' => 'Coach Registration No.',
			'Coach.strString2' => 'Instructor Registration No',
			'Coach.intInt1' => 'Deregistered',

			#Member Types - Umpire
			'Umpire.intActive' => 'Match Official Active?',
			'Umpire.strString1' => 'Match Official Registration No.',
			'Umpire.strString2' => 'Instructor Registration No',
			'Umpire.intInt1' => 'Type',
			'Umpire.intInt2' => 'Deregistered',

			#Member Types - Misc
			'Misc.intActive' => 'Misc Active?',
			'Misc.strString1' => 'Misc Registration No.',
			'Misc.strString2' => 'Instructor Registration No',
			'Misc.intInt1' => 'Type',
			'Misc.intInt2' => 'Deregistered',

			#Member Types - Volunteer
			'Volunteer.intActive' => 'Volunteer Active?',
			'Volunteer.strString1' => 'Volunteer Registration No.',
			'Volunteer.strString2' => 'Instructor Registration No',
			'Volunteer.intInt1' => 'Type',
			'Volunteer.intInt2' => 'Deregistered',

			#ACCREDITATION
			'Accred.intActive' => 'Active?',
			'Accred.intInt7' => 'Re-Accreditation',
			'Accred.strString1' => '',
			'Accred.intInt1' => 'Type',
			'Accred.intInt2' => 'Level',
			'Accred.intInt4' => 'Sport',
			'Accred.intInt5' => 'Accreditation Provider',
			'Accred.dtDate1' => 'Start Date',
			'Accred.dtDate2' => 'End Date',
			'Accred.dtDate3' => 'Application Date',
			'Accred.intInt6' => 'Accreditation Result',
			'Accred.strString2' => '',
			'Accred.strString3' => '',
			'Accred.strString4' => '',

			#POSITION
			'Position.intActive' 	=> 'Active?',
			'Position.intInt1' 		=> 'Type',
			'Position.intInt2' 		=> 'Position',
			'Position.intInt3' 		=> 'Entity ID',
			'Position.dtDate1' 		=> 'Start Date',
			'Position.dtDate2' 		=> 'End Date',
			'Position.strString1'	=> 'Registration Number',
	
			#SEASONS
			'Seasons.intMSRecStatus' => "$txt_SeasonName Participating?",
			'Seasons.intPlayerStatus' => "$txt_SeasonName Player?",
			'Seasons.intPlayerFinancialStatus' => "$txt_SeasonName Player Financial?",
			'Seasons.intCoachStatus' => "$txt_SeasonName Coach?",
			'Seasons.intCoachFinancialStatus' => "$txt_SeasonName Coach Financial?",
			'Seasons.intUmpireStatus' => "$txt_SeasonName Match Official?",
			'Seasons.intUmpireFinancialStatus' => "$txt_SeasonName Match Official Financial?",
			'Seasons.intMiscStatus' => "$txt_SeasonName Misc?",
			'Seasons.intMiscFinancialStatus' => "$txt_SeasonName Misc Financial?",
			'Seasons.intVolunteerStatus' => "$txt_SeasonName Volunteer?",
			'Seasons.intVolunteerFinancialStatus' => "$txt_SeasonName Volunteer Financial?",
			'Seasons.intOther1Status' => $Data->{'SystemConfig'}{'Seasons_Other1'} ? "$txt_SeasonName $Data->{'SystemConfig'}{'Seasons_Other1'}?" : '',
			'Seasons.intOther1FinancialStatus' => $Data->{'SystemConfig'}{'Seasons_Other1'} ? "$txt_SeasonName $Data->{'SystemConfig'}{'Seasons_Other1'} Financial?" : '',
			'Seasons.intOther2Status' => $Data->{'SystemConfig'}{'Seasons_Other2'} ? "$txt_SeasonName $Data->{'SystemConfig'}{'Seasons_Other2'}?" : '',
			'Seasons.intOther2FinancialStatus' => $Data->{'SystemConfig'}{'Seasons_Other2'} ? "$txt_SeasonName $Data->{'SystemConfig'}{'Seasons_Other2'} Financial?" : '',
			'AgeGroups.strAgeGroupDesc' => "Player $txt_AgeGroupName",
			
			#Player Numbers
			'PlayerNumberClub.strJumperNum' =>  $Data->{'SystemConfig'}{'Custom_JumperNumber'} ? "$Data->{'LevelNames'}{$Defs::LEVEL_CLUB} $Data->{'SystemConfig'}{'Custom_JumperNumber'}" : "$Data->{'LevelNames'}{$Defs::LEVEL_CLUB} #",
			'PlayerNumberTeam.strJumperNum' =>  $Data->{'SystemConfig'}{'Custom_JumperNumber'} ? "$Data->{'LevelNames'}{$Defs::LEVEL_TEAM} $Data->{'SystemConfig'}{'Custom_JumperNumber'}" :"$Data->{'LevelNames'}{$Defs::LEVEL_TEAM} #",

            #Member Records
            'MemberRecordTypeList' => 'Member Record Type',
		);
	}

	if($level == $Defs::LEVEL_TEAM)	{
		%labels = (
            #TEAM FIELDS
			strAddress1               => 'Address Line 1',
			strAddress2               => 'Address Line 2',
			strSuburb                 => 'Suburb',
			strState                  => 'State',
			strCountry                => 'Country',
			strPostalCode             => 'Postal Code',
			strFax                    => 'Fax',
			strEmail                  => 'Email',
	    intExcludeClubChampionships=>'Exclude from Club Championships',
            strNickname               => 'Nickname',
            strCode          	      => 'Three Letter Code',
            strContactTitle           => 'Contact Title',
            strContact                => 'Contact Name',
            strWebURL                 => 'Website',
            strContactTitle2          => 'Contact 2 Title',
            strContactName2           => 'Contact 2 Name',
            strContactEmail2          => 'Contact 2 Email',
            strContactTitle3          => 'Contact 3 Title',
            strContactName3           => 'Contact 3 Name',
            strContactEmail3          => 'Contact 3 Email',
            strUniformTopColour       => 'Uniform Top Colour',
            strUniformBottomColour    => 'Uniform Bottom Colour',
            strUniformNumber          => 'Uniform Number',
            strAltUniformTopColour    => 'Alternate Uniform Top Colour',
            strAltUniformBottomColour => 'Alternate Uniform Bottom Colour',
            strAltUniformNumber       => 'Alternate Uniform Number',
            strTeamNotes => 'Team Notes',
			intVenue1ID 			  => 'Venue 1',
			intVenue2ID 			  => 'Venue 2',
			intVenue3ID 			  => 'Venue 3',
			dtStartTime1			  => 'Venue 1 Start Time',
			dtStartTime2			  => 'Venue 2 Start Time',
			dtStartTime3			  => 'Venue 3 Start Time',
            strName                   => "$Data->{'LevelNames'}{$Defs::LEVEL_TEAM} Name",
            strPhone1                 => 'Phone',
            strPhone2                 => 'Phone 2',
            strMobile                 => 'Mobile',
            intCoachID                => 'Team Coach',
            intManagerID              => 'Team Manager',
            strContactPhone2          => 'Contact 2 Phone',
            strContactMobile2         => 'Contact 2 Mobile',
            strContactPhone3          => 'Contact 3 Phone',
            strContactMobile3         => 'Contact 3 Mobile',

		);
	}
	if($level== $Defs::LEVEL_CLUB)	{
		%labels = (
			strName => 'Name',
			Username => 'Username',
			intRecStatus => 'Active',
			strAbbrev => 'Abbreviation',
			strAddress1 => 'Postal Address Line 1',
			strAddress2 => 'Postal Address Line 2',
			strSuburb => 'Suburb',
			strState => 'State',
			strCountry => 'Country',
			strPostalCode => 'Postal Code',
			strLGA => 'Local Government Area',
			strDevelRegion => $Data->{'SystemConfig'}{'DevelRegions'} ? 'Development Region' : '',
			strClubZone => $Data->{'SystemConfig'}{'ClubZones'} ? 'Zone' : '',
			strPhone => "$Data->{'LevelNames'}{$Defs::LEVEL_CLUB} Phone",
			strFax => "$Data->{'LevelNames'}{$Defs::LEVEL_CLUB} Fax",
			strEmail => "$Data->{'LevelNames'}{$Defs::LEVEL_CLUB} Email",
			strIncNo => 'Incorporation Number',
			strBusinessNo => 'Business Number (ABN)',
      strColours => 'Colours',
			intClubTypeID => 'Club Type',
			intClubCategoryID => 'Club Category',
			intAgeTypeID => 'Age Type',
			strNotes => 'Notes',
            intClubClassification => 'Accreditation Level',
		);
	}
	for my $k (keys %labels)	{
		$labels{$k}= ($Data->{'SystemConfig'}{'FieldLabel_'.$k} || '') if exists $Data->{'SystemConfig'}{'FieldLabel_'.$k};
	}

    my $lang = $Data->{lang};

    foreach my $key (keys %labels) {
        $labels{$key} = $lang->txt($labels{$key});
    }

	return \%labels;
}
