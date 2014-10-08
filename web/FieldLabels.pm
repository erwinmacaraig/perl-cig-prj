package FieldLabels;
require Exporter;
@ISA = qw(Exporter);
@EXPORT=qw(getFieldLabels);

use strict;

use lib '.', '..';

use Defs;
require CustomFields;

sub getFieldLabels	{
	my($Data, $level, $raw)=@_;

	my %labels=();
	return \%labels if(!$Data or !$level);

	my $CustomFieldNames=CustomFields::getCustomFieldNames($Data);
    my $natnumname=$Data->{'SystemConfig'}{'NationalNumName'} || 'National Number';

	if($level== $Defs::LEVEL_PERSON)	{

		%labels = (
			strNationalNum => $natnumname,
			strStatus => "Status",
			strSalutation => 'Title',
			strLocalFirstname => 'First name',
			strLocalMiddlename => 'Middle name',
			strPreferredName => 'Preferred name',
			strLocalSurname => 'Family name',
			strLatinSurname => 'Family name (International)',
			strLatinFirstname=> 'First name (International)',
			strMaidenName => 'Maiden name',
			strMotherCountry=> 'Country of Birth (Mother)',
			strFatherCountry=> 'Country of Birth (Father)',
			dtDOB => 'Date of Birth',
			dtDeath=> 'Date of Death',
			dtSuspendedUntil=> 'Date Suspended Until',
			strRegionOfBirth => 'Region of Birth',
			strPlaceOfBirth => 'Place (Town) of Birth',
            strCountryOfBirth => 'Country of Birth',
			strGender => 'Gender',
			strAddress1 => 'Address Line 1',
			strAddress2 => 'Address Line 2',
			strSuburb => 'Suburb',
			strState => 'State',
			strCountry => 'Country',
			strPostalCode => 'Postal Code',
			strPhoneHome => 'Phone (Home)',
			strPhoneWork => 'Phone (Work)',
			strPhoneMobile => 'Phone (Mobile)',
			strPager => 'Pager',
			strFax => 'Fax',
			strEmail => 'Email',
			strEmail2 => 'Email 2',
			intEthnicityID => 'Ethnicity',
			intDeceased => 'Deceased?',
			strLoyaltyNumber => 'Loyalty Number',
			strPassportNationality => 'Passport Nationality',
			strPassportNo => 'Passport Number',
			strPassportIssueCountry => 'Passport Country of Issue',
			dtPassportExpiry => 'Passport Expiry Date',
			strEmergContName => 'Emergency Contact Name',
			strEmergContNo => 'Emergency Contact Number',
			strEmergContNo2 => 'Emergency Contact Number 2',
			strEmergContRel => 'Emergency Contact Relationship',
			intP1Gender => 'Parent/Guardian 1 Gender',
			intP2Gender => 'Parent/Guardian 2 Gender',
			strP1Salutation=> 'Parent/Guardian 1 Salutation',
			strP1FName => 'Registering Parent Firstname',
			strP1SName => 'Registering Parent Surname',
			strP2Salutation=> 'Parent/Guardian 2 Salutation',
			strP2FName => 'Parent/Guardian 2 Firstname',
			strP2SName => 'Parent/Guardian 2 Surname',
			strP1Phone => 'Registering Parent Phone',
			strP1Phone2 => 'Parent/Guardian 1 Phone 2',
			strP1PhoneMobile => 'Parent/Guardian 1 Mobile',
			strP2Phone => 'Parent/Guardian 2 Phone',
			strP2Phone2 => 'Parent/Guardian 2 Phone 2',
			strP2PhoneMobile => 'Parent/Guardian 2 Mobile',
			strP1Email=> 'Registering Parent Email',
			strP2Email=> 'Parent/Guardian 2 Email',
			strP1Email2=> 'Parent/Guardian 1 Email 2',
			strP2Email2=> 'Parent/Guardian 2 Email 2',
			strEyeColour => 'Eye Colour',
			strHairColour => 'Hair Colour',
			strHeight => 'Height',
			strWeight => 'Weight',
			strNotes => 'Notes',
			dtLastUpdate => 'Last Updated',
			tTimeStamp => 'Last Updated',
			dtPoliceCheck => $Data->{'SystemConfig'}{'dtPoliceCheck_Text'} ? $Data->{'SystemConfig'}{'dtPoliceCheck_Text'} : 'Police Check Date',
			dtPoliceCheckExp => $Data->{'SystemConfig'}{'dtPoliceCheckExp_Text'} ? $Data->{'SystemConfig'}{'dtPoliceCheckExp_Text'} : 'Police Check Expiry Date',
			strPoliceCheckRef => 'Police Check Number',
			strPreferredLang => 'Preferred Language',
			strISONationality => 'Nationality',
			strISOCountry => 'Country (ISO)',
			strISOCountryOfBirth => 'Country of Birth (ISO)',
            intMinorMoveOtherThanFootball => 'Move to Country for reasons other than football',
            intMinorDistance => 'Live 50km from National border. Maximum distance between the players domicile and the Clubs HQ shall be 100km',
            intMinorEU => 'The transfer takes place within the territory of the European Union and player is aged between 16 and 18',
            intMinorNone => 'None of the Above',
            intLocalLanguage => 'Local Name Language',
       
		);
	}

	if($level== $Defs::LEVEL_CLUB)	{
		%labels = (
            strFIFAID => 'FIFA ID',
            strLocalName => 'Name',
            strLocalShortName => 'Short Name',
            strLatinName => 'Name (International)',
            strLatinShortName => 'Short Name (International)',
            strStatus => 'Status',
            strISOCountry => 'Country (ISO)',

            strRegion => 'Region',
            strPostalCode => 'Postal Code',
            strTown => 'Town',
            strAddress => 'Address',
            strWebURL => 'Website',
            strEmail => 'Email',
            strPhone => 'Phone',
            strFax => 'Fax',
            strContactTitle => 'Contact Person Title',
            strContactEmail => 'Contact Person Email',
            strContactPhone => 'Contact Person Phone',
            strContact => 'Contact Person',
            intIdentifierTypeID => 'Identifier Type',
            strIdentifier => 'Identifier',
            dtValidFrom => 'Valid From',
            dtValidUntil =>'Valid Until',
            strDescription => 'Description',
            strAssocNature => 'Association Nature',
            strMANotes => 'MA Comment',
            intLegalTypeID => 'Legal Entity Type', 
            intLocalLanguage => 'Local Name Language',
            strLegalID => "Legal Type Number",
            strMAID => 'MA ID',
            dtFrom => 'Foundation Date',
            dtTo => 'Dissolution Date',
            strGender => 'Gender',
            strDiscipline => 'Sport',
            	
	);
	}
	for my $k (keys %labels)	{
		$labels{$k}= ($Data->{'SystemConfig'}{'FieldLabel_'.$k} || '') if exists $Data->{'SystemConfig'}{'FieldLabel_'.$k};
	}

    if($raw)    {
        return \%labels;
    }
    my $lang = $Data->{lang};

    foreach my $key (keys %labels) {
        $labels{$key} = $lang->txt($labels{$key});
    }

	return \%labels;
}
