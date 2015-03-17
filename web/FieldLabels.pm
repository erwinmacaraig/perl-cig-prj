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

	my $customFieldNames=CustomFields::getCustomFieldNames($Data);
    my $natnumname=$Data->{'SystemConfig'}{'NationalNumName'} || 'National Number';

	if($level== $Defs::LEVEL_PERSON)	{

		%labels = (
			strNationalNum => $natnumname,
			strStatus => "Status",
			strSalutation => 'Title',
			strLocalFirstname => 'First Name',
			strLocalMiddlename => 'Local Middle name',
			strPreferredName => 'Preferred name',
			strLocalSurname => 'Family Name',
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
			strPlaceOfBirth => 'City of Birth',
			strAddress1 => 'Address 1',
			strAddress2 => 'Address 2',
			strSuburb => 'City',
			strState => 'State',
			strISOCountry => 'Country',
			strPostalCode => 'Postcode',
			strPhoneHome => 'Contact Number',
			strPhoneWork => 'Phone (Work)',
			strPhoneMobile => 'Phone (Mobile)',
			strPager => 'Pager',
			strFax => 'Fax',
			strEmail => 'Contact Email',
			strEmail2 => 'Email 2',
			intEthnicityID => 'Race',
			intDeceased => 'Deceased',
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
			strP1FName => 'Parent/Guardian first name',
			strP1SName => 'Parent/Guardian family name',
			strGuardianRelationship => 'Parent/Guradian Relationship',
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
			strISOCountryOfBirth => 'Country of Birth',
            intMinorProtection=> 'FIFA Minor Protection',
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
            intOtherPersonIdentifierTypeID=> $Data->{'SystemConfig'}{'intOtherPersonIdentifierTypeID_Text'} ? $Data->{'SystemConfig'}{'intOtherPersonIdentifierTypeID_Text'} : 'Other Identifier Type',
            strNatCustomStr1 => $customFieldNames->{'strNatCustomStr1'} || '',
            strNatCustomStr2 => $customFieldNames->{'strNatCustomStr2'} || '',
            strNatCustomStr3 => $customFieldNames->{'strNatCustomStr3'} || '',
            strNatCustomStr4 => $customFieldNames->{'strNatCustomStr4'} || '',
            strNatCustomStr5 => $customFieldNames->{'strNatCustomStr5'} || '',
            strNatCustomStr6 => $customFieldNames->{'strNatCustomStr6'} || '',
            strNatCustomStr7 => $customFieldNames->{'strNatCustomStr7'} || '',
            strNatCustomStr8 => $customFieldNames->{'strNatCustomStr8'} || '',
            strNatCustomStr9 => $customFieldNames->{'strNatCustomStr9'} || '',
            strNatCustomStr10 => $customFieldNames->{'strNatCustomStr10'} || '',
            strNatCustomStr11 => $customFieldNames->{'strNatCustomStr11'} || '',
            strNatCustomStr12 => $customFieldNames->{'strNatCustomStr12'} || '',
            strNatCustomStr13 => $customFieldNames->{'strNatCustomStr13'} || '',
            strNatCustomStr14 => $customFieldNames->{'strNatCustomStr14'} || '',
            strNatCustomStr15 => $customFieldNames->{'strNatCustomStr15'} || '',
            dblNatCustomDbl1 => $customFieldNames->{'dblNatCustomDbl1'} || '',
            dblNatCustomDbl2 => $customFieldNames->{'dblNatCustomDbl2'} || '',
            dblNatCustomDbl3 => $customFieldNames->{'dblNatCustomDbl3'} || '',
            dblNatCustomDbl4 => $customFieldNames->{'dblNatCustomDbl4'} || '',
            dblNatCustomDbl5 => $customFieldNames->{'dblNatCustomDbl5'} || '',
            dblNatCustomDbl6 => $customFieldNames->{'dblNatCustomDbl6'} || '',
            dblNatCustomDbl7 => $customFieldNames->{'dblNatCustomDbl7'} || '',
            dblNatCustomDbl8 => $customFieldNames->{'dblNatCustomDbl8'} || '',
            dblNatCustomDbl9 => $customFieldNames->{'dblNatCustomDbl9'} || '',
            dblNatCustomDbl10 => $customFieldNames->{'dblNatCustomDbl10'} || '',
            dtNatCustomDt1 => $customFieldNames->{'dtNatCustomDt1'} || '',
            dtNatCustomDt2 => $customFieldNames->{'dtNatCustomDt2'} || '',
            dtNatCustomDt3 => $customFieldNames->{'dtNatCustomDt3'} || '',
            dtNatCustomDt4 => $customFieldNames->{'dtNatCustomDt4'} || '',
            dtNatCustomDt5 => $customFieldNames->{'dtNatCustomDt5'} || '',
            intNatCustomBool1 => $customFieldNames->{'intNatCustomBool1'} || '',
            intNatCustomBool2 => $customFieldNames->{'intNatCustomBool2'} || '',
            intNatCustomBool3 => $customFieldNames->{'intNatCustomBool3'} || '',
            intNatCustomBool4 => $customFieldNames->{'intNatCustomBool4'} || '',
            intNatCustomBool5 => $customFieldNames->{'intNatCustomBool5'} || '',
            intNatCustomLU1 => $customFieldNames->{'intNatCustomLU1'} || '',
            intNatCustomLU2 => $customFieldNames->{'intNatCustomLU2'} || '',
            intNatCustomLU3 => $customFieldNames->{'intNatCustomLU3'} || '',
            intNatCustomLU4 => $customFieldNames->{'intNatCustomLU4'} || '',
            intNatCustomLU5 => $customFieldNames->{'intNatCustomLU5'} || '',
            intNatCustomLU6 => $customFieldNames->{'intNatCustomLU6'} || '',
            intNatCustomLU7 => $customFieldNames->{'intNatCustomLU7'} || '',
            intNatCustomLU8 => $customFieldNames->{'intNatCustomLU8'} || '',
            intNatCustomLU9 => $customFieldNames->{'intNatCustomLU9'} || '',
            intNatCustomLU10 => $customFieldNames->{'intNatCustomLU10'} || '',

             
            
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
            strCity => 'City',
            strRegion => 'Region of Organisation',
            strISOCountry => 'Country',
            strAddress => 'Address 1',
            strAddress2 => 'Address 2',
            strContactCity => 'City',
            strTown => 'Town',
            strState => 'State',
            strPostalCode => 'Postcode',
            strContactISOCountry => 'Country of Address',
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
            intNotifications => 'Email Notifications',
            strOrganisationLevel => 'Level',
            dissolved => 'Dissolved',
            intFacilityTypeID => 'Venue Type',
            strBankAccountNumber => 'Bank Account Details',
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
            strFax => 'Fax',
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
            intNotifications => 'Email Notifications',
            intEntityFieldCount => 'Number of Fields',
            intFacilityTypeID => 'Venue Type',
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
