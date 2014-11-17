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
			strLocalMiddlename => 'Local Middle name',
			strPreferredName => 'Preferred name',
			strLocalSurname => 'Family name',
			strLatinSurname => 'International Family name',
			strLatinFirstname=> 'International First name',
			strMaidenName => 'Maiden name',
			strMotherCountry=> 'Country of Birth (Mother)',
			strFatherCountry=> 'Country of Birth (Father)',
			intGender => 'Gender',
			dtDOB => 'Date of Birth',
			dtDeath=> 'Date of Death',
			dtSuspendedUntil=> 'Date Suspended Until',
			strRegionOfBirth => 'Region or State of Birth',
			strPlaceOfBirth => 'Town or Suburb of Birth',
			strAddress1 => 'Address 1',
			strAddress2 => 'Address 2',
			strSuburb => 'City of Organisation',
			strState => 'State',
			strCountry => 'Country of Address',
			strPostalCode => 'Postcode',
			strPhoneHome => 'Contact Number',
			strPhoneWork => 'Phone (Work)',
			strPhoneMobile => 'Phone (Mobile)',
			strPager => 'Pager',
			strFax => 'Fax',
			strEmail => 'Contact Email',
			strEmail2 => 'Email 2',
			intEthnicityID => 'Race',
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
			strNotes => 'Notes',
			dtLastUpdate => 'Last Updated',
			tTimeStamp => 'Last Updated',
			dtPoliceCheck => $Data->{'SystemConfig'}{'dtPoliceCheck_Text'} ? $Data->{'SystemConfig'}{'dtPoliceCheck_Text'} : 'Police Check Date',
			dtPoliceCheckExp => $Data->{'SystemConfig'}{'dtPoliceCheckExp_Text'} ? $Data->{'SystemConfig'}{'dtPoliceCheckExp_Text'} : 'Police Check Expiry Date',
			strPoliceCheckRef => 'Police Check Number',
			strPreferredLang => 'Preferred Language',
			strISONationality => 'Nationality',
			strISOCountry => 'Country',
			strISOCountryOfBirth => 'Country of Birth',
            intMinorMoveOtherThanFootball => 'Move to Country for reasons other than football',
            intMinorDistance => 'Live 50km from National border. Maximum distance between the players domicile and the Clubs HQ shall be 100km',
            intMinorEU => 'The transfer takes place within the territory of the European Union and player is aged between 16 and 18',
            intMinorNone => 'None of the Above',
            intLocalLanguage => 'Language of Name',
       
            intCertificationTypeID => "Certification",
            dtValidFrom => 'Valid From',
            dtValidUntil => 'Valid Until',
            strDescription => 'Description/Reference',
            
            strBirthCert => "Birth Certificate",
            strBirthCertCountry => "Birth Country",
            dtBirthCertValidityDateFrom => 'Birth Certificate Validity Date From',
            dtBirthCertValidityDateTo => 'Birth Certificate Validity Date To',
            strBirthCertDesc => 'Birth Certificate Description',
            
            strOtherPersonIdentifier => $Data->{'SystemConfig'}{'strOtherPersonIdentifier_Text'} ? $Data->{'SystemConfig'}{'strOtherPersonIdentifier_Text'} : 'Other Identifier',
            strOtherPersonIdentifierIssueCountry => $Data->{'SystemConfig'}{'strOtherPersonIdentifierIssueCountry_Text'} ? $Data->{'SystemConfig'}{'strOtherPersonIdentifierIssueCountry_Text'} : 'Other Identifier Issuance Country',
            dtOtherPersonIdentifierValidDateFrom => $Data->{'SystemConfig'}{'dtOtherPersonIdentifierValidDateFrom_Text'} ? $Data->{'SystemConfig'}{'dtOtherPersonIdentifierValidDateFrom_Text'} : 'Other Identifier Validity Date From',
            dtOtherPersonIdentifierValidDateTo => $Data->{'SystemConfig'}{'dtOtherPersonIdentifierValidDateTo_Text'} ? $Data->{'SystemConfig'}{'dtOtherPersonIdentifierValidDateTo_Text'} : 'Other Identifier Validity Date To',
            strOtherPersonIdentifierDesc => $Data->{'SystemConfig'}{'strOtherPersonIdentifierDesc_Text'} ? $Data->{'SystemConfig'}{'strOtherPersonIdentifierDesc_Text'} : 'Other Identifier Description',
             
            
		);
	}

	if($level== $Defs::LEVEL_CLUB)	{
		%labels = (
            strFIFAID => 'FIFA ID',
            strLocalName => 'Organisation Name',
            strLocalShortName => 'Organisation Short Name',
            strLatinName => 'Name (International)',
            strLatinShortName => 'Short Name (International)',
            strStatus => 'Status',
            strCity => 'City of Organisation',
            strRegion => 'Region of Organisation',
            strISOCountry => 'Country of Address',
            strAddress => 'Address 1',
            strAddress2 => 'Address 2',
            strContactCity => 'City',
            strTown => 'Town',
            strState => 'State',
            strPostalCode => 'Postcode',
            strContactISOCountry => 'Country',
            strWebURL => 'Web Address',
            strEmail => 'Contact Email',
            strPhone => 'Contact Phone',
            strFax => 'Fax',
            strContact => 'Contact Person',
            intIdentifierTypeID => 'Identifier Type',
            strIdentifier => 'Identifier',
            dtValidFrom => 'Valid From',
            dtValidUntil =>'Valid Until',
            strDescription => 'Description',
            strAssocNature => 'Association Nature',
            strMANotes => 'MA Comment',
            intLegalTypeID => 'Type of Legal Entity', 
            strLegalID => "Legal Entity Identification Number",
            intLocalLanguage => 'Language of Organisation Name',
            strMAID => 'MA Organisation ID',
            dtFrom => 'Organisation Foundation Date',
            dtTo => 'Organisation Dissolution Date',
            strGender => 'Gender',
            strDiscipline => 'Sport',
            #strEntityType => 'Entity Type',
            strEntityType => 'Organisation Type',
            intNotifications => 'Notification Toggle',
            strOrganisationLevel => 'Level',
            dissolved => 'Dissolved',
            );
	}

	if($level== $Defs::LEVEL_VENUE)	{
		%labels = (
            strFIFAID => 'FIFA ID',
            strLocalName => 'Venue Name',
            strLocalShortName => 'Venue Short Name',
            strLocalFacilityName => 'Facility Name',
            strLatinName => 'International Venue Name',
            strLatinShortName => 'International Venue Short Name',
            strLatinFacilityName => 'Facility Name (International)',
            strStatus => 'Status',
            strISOCountry => 'Country',
            strRegion => 'Region',
            strState => 'State',
            strTown => 'Town',
            strAddress => 'Address 1',
            strAddress2 => 'Address 2',
            strCity => 'City',
            strWebURL => 'Web Address',
            strEmail => 'Contact Email',
            strPhone => 'Contact Number',
            strFax => 'Facsimile Number',
            strContactCity => 'City',
            strPostalCode => 'Postcode',
            strContactISOCountry => 'Country of Address',
            strContact => 'Contact Person',
            intIdentifierTypeID => 'Identifier Type',
            strIdentifier => 'Identifier',
            dtValidFrom => 'Valid From',
            dtValidUntil =>'Valid Until',
            strDescription => 'Description',
            strAssocNature => 'Association Nature',
            strMANotes => 'MA Comment',
            intLegalTypeID => 'Legal Entity Type', 
            intLocalLanguage => 'Language of Venue Name',
            strLegalID => "Legal Type Number",
            strMAID => 'MA ID',
            dtFrom => 'Foundation Date',
            dtTo => 'Dissolution Date',
            strGender => 'Gender',
            strDiscipline => 'Sport',
            strEntityType => 'Entity Type',
            intNotifications => 'Notification Toggle',
            intEntityFieldCount => 'Number of Fields',
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
