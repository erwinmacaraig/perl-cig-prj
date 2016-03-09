#
# $Header: svn://svn/SWM/trunk/web/Reports/ReportAdvanced_Member.pm 11613 2014-05-20 03:02:24Z cgao $
#

package Reports::ReportAdvanced_DuplicateMarked;

use strict;
use lib ".", "../..";
use ReportAdvanced_Common;
use Reports::ReportAdvanced;
use Reg_common;

use Log;
use Data::Dumper;
our @ISA = qw(Reports::ReportAdvanced);

use strict;

sub _getConfiguration {
    my $self = shift;

    my $currentLevel = $self->{'EntityTypeID'} || 0;
    my $Data         = $self->{'Data'};
    my $clientValues = $Data->{'clientValues'};
    my $natnumname =
      $Data->{'SystemConfig'}{'NationalNumName'} || 'National Number';
    my $natteamname = $Data->{'SystemConfig'}{'NatTeamName'} || 'National Team';
    my $SystemConfig = $Data->{'SystemConfig'};
    my $CommonVals   = getCommonValues(
        $Data,
        {
            SubRealms        => 1,
            DefCodes         => 1,
            Countries        => 1,
            CustomFields     => 1,
            FieldLabels      => 1,
            AgeGroups        => 1,
            Products         => 1,
            RecordTypes      => 1,
            NationalPeriods  => 1,
            CertTypes => 1,
        },
    );
    my $hideSeasons = $CommonVals->{'Seasons'}{'Hide'} || 0;
    my $enable_record_types = $Data->{'SystemConfig'}{'EnableMemberRecords'} || 0; 

    my $FieldLabels = $CommonVals->{'FieldLabels'} || undef;
    my %NRO = ();

    my $txt_Clr = $Data->{'SystemConfig'}{'txtCLR'} || 'Clearance';

    my $txn_WHERE = '';
    if ( $clientValues->{clubID} and $clientValues->{clubID} > 0 ) {
        $txn_WHERE = qq[ AND TX.intTXNEntityID IN (0, $clientValues->{clubID})];
    }

    my $lang = $Data->{'lang'};
    my %config = (
        Name => 'Detailed Person Report',

        StatsReport  => 0,
        MemberTeam   => 0,
        ReportEntity => 1,
        ReportLevel  => 0,

        #Template => 'default_adv_CSV',
        Template       => 'default_adv',
        TemplateEmail  => 'default_adv_CSV',
        DistinctValues => 1,

        SQLBuilder => \&SQLBuilder,
        Fields     => {
            strNationalNum => [
                $natnumname,
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 1,
                    optiongroup => 'details',
                    dbfield     => 'P.strNationalNum'
                }
            ],
            MasterNationalNum => [
                $lang->txt('Master - ') . $natnumname,
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 1,
                    optiongroup => 'details',
                    dbfield     => 'PMaster.strNationalNum'
                }
            ],
 
            MemberID => [
                'Person ID',
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 1,
                    optiongroup => 'details',
                    dbfield     => 'P.intPersonID'
                }
            ],
            strMemberNo => [
                $Data->{'SystemConfig'}{'FieldLabel_strMemberNo'}
                  || 'Member No.',
                {
                    displaytype   => 'text',
                    fieldtype     => 'text',
                    allowsort     => 1,
                    optiongroup   => 'details',
                    allowgrouping => 1,
                    dbfield     => 'P.strMemberNo'
                }
            ],
            PstrImportCode=> [
                $lang->txt('Imported Person Code'),
                {
                    dbfield         => 'P.strImportPersonCode',
                    displaytype   => 'text',
                    fieldtype     => 'text',
                    allowsort     => 1,
                    optiongroup   => 'details',
                }
            ],
 
            PstrStatus=> [
                'Person Status',
                {
                    dbfield         => 'P.strStatus',
                    displaytype     => 'lookup',
                    fieldtype       => 'dropdown',
                    dropdownoptions => \%Defs::personStatus,
                    translate       => 1,
                    optiongroup     => 'details',
                    allowgrouping   => 1
                }
            ],
            MasterLatinFirstname => [
                'Master - International First name',
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    active      => 1,
                    allowsort   => 1,
                    dbfield         => 'PMaster.strLatinFirstname',
                    optiongroup => 'details'
                }
            ],

            MasterLatinSurname => [
                'Master - International Family name',
                {
                    displaytype   => 'text',
                    fieldtype     => 'text',
                    active        => 1,
                    allowsort     => 1,
                    optiongroup   => 'details',
                    dbfield         => 'PMaster.strLatinSurname',
                    allowgrouping => 1
                }
            ],
            MasterLocalFirstname => [
                'Master - First Name',
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    active      => 1,
                    allowsort   => 1,
                    dbfield         => 'PMaster.strLocalFirstname',
                    optiongroup => 'details'
                }
            ],

            MasterLocalSurname => [
                'Master - Family Name',
                {
                    displaytype   => 'text',
                    fieldtype     => 'text',
                    active        => 1,
                    allowsort     => 1,
                    optiongroup   => 'details',
                    dbfield         => 'PMaster.strLocalSurname',
                    allowgrouping => 1
                }
            ],

            strLatinFirstname => [
                'International First name',
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    active      => 1,
                    allowsort   => 1,
                    dbfield         => 'P.strLatinFirstname',
                    optiongroup => 'details'
                }
            ],

            strLatinSurname => [
                'International Family name',
                {
                    displaytype   => 'text',
                    fieldtype     => 'text',
                    active        => 1,
                    allowsort     => 1,
                    optiongroup   => 'details',
                    dbfield         => 'P.strLatinSurname',
                    allowgrouping => 1
                }
            ],
            strLocalFirstname => [
                'First Name',
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    active      => 1,
                    allowsort   => 1,
                    dbfield         => 'P.strLocalFirstname',
                    optiongroup => 'details'
                }
            ],

            strLocalSurname => [
                'Family Name',
                {
                    displaytype   => 'text',
                    fieldtype     => 'text',
                    active        => 1,
                    allowsort     => 1,
                    optiongroup   => 'details',
                    dbfield         => 'P.strLocalSurname',
                    allowgrouping => 1
                }
            ],
            strISONationality=> [
                'Nationality',
                {
                    displaytype     => 'lookup',
                    fieldtype       => 'dropdown',
                    dropdownoptions => $CommonVals->{'Countries'},
                    allowsort       => 1,
                    optiongroup     => 'details',
                    dbfield         => 'UCASE(P.strISONationality)',
                    allowgrouping   => 1
                }
            ],

            strISOCountryOfBirth => [
                'Country of Birth',
                {
                    displaytype     => 'lookup',
                    fieldtype       => 'dropdown',
                    dropdownoptions => $CommonVals->{'Countries'},
                    allowsort       => 1,
                    optiongroup     => 'details',
                    dbfield         => 'UCASE(P.strISOCountryOfBirth)',
                    allowgrouping   => 1
                }
            ],

            dtDOB => [
                'Date of Birth',
                {
                    displaytype => 'date',
                    fieldtype   => 'date',
                    allowsort   => 1,
                    dbfield     => 'P.dtDOB',
                    datetimeformat => ['MEDIUM',''],
                    optiongroup => 'details'
                }
            ],

            dtYOB => [
                $lang->txt('Year of Birth'),
                {
                    displaytype   => 'date',
                    fieldtype     => 'text',
                    allowgrouping => 1,
                    allowsort     => 1,
                    dbfield       => 'YEAR(P.dtDOB)',
                    dbformat      => ' YEAR(P.dtDOB)',
                    optiongroup   => 'details'
                }
            ],
            strRegionOfBirth => [
                'Region of Birth',
                {
                    displaytype   => 'text',
                    fieldtype     => 'text',
                    allowsort     => 0,
                    optiongroup   => 'details',
                    dbfield         => 'P.strRegionOfBirth',
                    allowgrouping => 1
                }
            ],


            strPlaceOfBirth => [
                'City of Birth',
                {
                    displaytype   => 'text',
                    fieldtype     => 'text',
                    allowsort     => 0,
                    optiongroup   => 'details',
                    dbfield         => 'P.strPlaceOfBirth',
                    allowgrouping => 1
                }
            ],

            intGender => [
                'Gender',
                {
                    displaytype => 'lookup',
                    fieldtype   => 'dropdown',
                    dropdownoptions =>
                      { 1 => 'Male', 2 => 'Female' },
                    dropdownorder => [ '', 1, 2 ],
                    size          => 2,
                    multiple      => 1,
                    optiongroup   => 'details',
                    translate       => 1,
                    allowgrouping => 1,
                    dbfield         => 'P.intGender',
                    allowsort     => 1
                }
            ],

            
            intEthnicityID => [
                $lang->txt('Race'),
                {
                    displaytype     => 'lookup',
                    fieldtype       => 'dropdown',
                    dropdownoptions => $CommonVals->{'DefCodes'}{-8},
                    translate       => 1,
                    optiongroup     => 'details',
                    dbfield         => 'P.intEthnicityID',
                    allowgrouping   => 1
                }
            ],

            intMinorProtection => [
                'Minor Protection',
                {
                    displaytype     => 'lookup',
                    fieldtype       => 'dropdown',
                    dropdownoptions => {
                        1 => 'Move non-football',
                        2 => '50km from border',
                        3 => 'Already in Country',
                        4 => 'Inside EU',
                    },
                    translate       => 1,
                    optiongroup     => 'details',
                    dbfield         => 'P.intMinorProtection',
                    allowgrouping   => 1
                }
            ],

           strAddress1 => [
                'Address 1',
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    dbfield     => 'P.strAddress1',
                    optiongroup => 'contactdetails'
                }
            ],

            strAddress2 => [
                'Address 2',
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    dbfield     => 'P.strAddress2',
                    optiongroup => 'contactdetails'
                }
            ],

            strSuburb => [
                'City',
                {
                    displaytype   => 'text',
                    fieldtype     => 'text',
                    dbfield       => 'P.strSuburb',
                    allowsort     => 1,
                    optiongroup   => 'contactdetails',
                    allowgrouping => 1
                }
            ],

            strState => [
                'State',
                {
                    displaytype   => 'text',
                    fieldtype     => 'text',
                    dbfield       => 'P.strState',
                    allowsort     => 1,
                    optiongroup   => 'contactdetails',
                    allowgrouping => 1
                }
            ],

            strISOCountry => [
                'Country',
                {
                    displaytype   => 'text',
                    fieldtype     => 'text',
                    dbfield       => 'P.strISOCountry',
                    allowsort     => 1,
                    optiongroup   => 'contactdetails',
                    allowgrouping => 1
                }
            ],

            strPostalCode => [
                'Postal Code',
                {
                    displaytype   => 'text',
                    fieldtype     => 'text',
                    dbfield       => 'P.strPostalCode',
                    allowsort     => 1,
                    optiongroup   => 'contactdetails',
                    allowgrouping => 1
                }
            ],

            strPhoneHome => [
                'Home Phone',
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    dbfield       => 'P.strPhoneHome',
                    optiongroup => 'contactdetails'
                }
            ],

            strPhoneMobile => [
                'Mobile Phone',
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    dbfield       => 'P.strPhoneMobile',
                    optiongroup => 'contactdetails'
                }
            ],

            strEmail => [
                'Email',
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    dbfield     => 'P.strEmail',
                    optiongroup => 'contactdetails'
                }
            ],

           strEmergContName => [
                'Emergency Contact Name',
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 0,
                    dbfield     => 'P.strEmergContName',
                    optiongroup => 'contactdetails'
                }
            ],

            strEmergContRel => [
                'Emergency Contact Relationship',
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 0,
                    dbfield     => 'P.strEmergContRel',
                    optiongroup => 'contactdetails'
                }
            ],

            strEmergContNo => [
                'Emergency Contact No',
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 0,
                    dbfield     => 'P.strEmergContNo',
                    optiongroup => 'contactdetails',
                }
            ],

            strEmergContNo2 => [
                'Emergency Contact No 2',
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 0,
                    dbfield     => 'P.strEmergContNo2',
                    optiongroup => 'contactdetails',
                }
            ],


            strPreferredLang => [
                $lang->txt('Preferred Language'),
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 0,
                    dbfield     => 'P.strPreferredLang',
                    optiongroup => 'identifications'
                }
            ],

            strBirthCert => [
                $lang->txt('Birth Certificate Number'),
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 0,
                    dbfield     => 'P.strBirthCert',
                    optiongroup => 'identifications'
                }
            ],
            strBirthCertDesc=> [
                $lang->txt('Birth Certificate Notes'),
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 0,
                    dbfield     => 'P.strBirthCertDesc',
                    optiongroup => 'identifications'
                }
            ],
            strBirthCertCountry => [
                $lang->txt('Birth Certificate Country'),
                {
                    displaytype     => 'lookup',
                    fieldtype       => 'dropdown',
                    dropdownoptions => $CommonVals->{'Countries'},
                    allowsort       => 1,
                    optiongroup     => 'identifications',
                    dbfield         => 'UCASE(P.strBirthCertCountry)',
                    allowgrouping   => 1
                }
            ],

            dtBirthCertValidityDateFrom=> [
                $lang->txt('Birth Certificate Valid From'),
                {
                    displaytype => 'date',
                    fieldtype   => 'date',
                    allowsort   => 1,
                    datetimeformat => ['MEDIUM',''],
                    optiongroup => 'identifications',
                    dbfield     => 'P.dtBirthCertValidityDateFrom'
                }
            ],
            dtBirthCertValidityDateTo=> [
                $lang->txt('Birth Certificate Valid To'),
                {
                    displaytype => 'date',
                    fieldtype   => 'date',
                    allowsort   => 1,
                    datetimeformat => ['MEDIUM',''],
                    optiongroup => 'identifications',
                    dbfield     => 'P.dtBirthCertValidityDateTo'
                }
            ],

            strOtherPersonIdentifier=> [
                $Data->{'SystemConfig'}{'strOtherPersonIdentifier_Text'} ? $Data->{'SystemConfig'}{'strOtherPersonIdentifier_Text'} : $lang->txt('Other Identifier'),
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 0,
                    dbfield     => 'P.strOtherPersonIdentifier',
                    optiongroup => 'identifications'
                }
            ],
            strOtherPersonIdentifierDesc=> [
                $Data->{'SystemConfig'}{'strOtherPersonIdentifierDesc_Text'} ? $Data->{'SystemConfig'}{'strOtherPersonIdentifierDesc_Text'} : $lang->txt('Other Identifier Description'),
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 0,
                    dbfield     => 'P.strOtherPersonIdentifierDesc',
                    optiongroup => 'identifications'
                }
            ],
            strOtherPersonIdentifierIssueCountry=> [
                $Data->{'SystemConfig'}{'strOtherPersonIdentifierIssueCountry_Text'} ? $Data->{'SystemConfig'}{'strOtherPersonIdentifierIssueCountry_Text'} : $lang->txt('Other Identifier Issuance Country'),
                {
                    displaytype     => 'lookup',
                    fieldtype       => 'dropdown',
                    dropdownoptions => $CommonVals->{'Countries'},
                    allowsort       => 1,
                    optiongroup     => 'identifications',
                    dbfield         => 'UCASE(P.strOtherPersonIdentifierIssueCountry)',
                    allowgrouping   => 1
                }
            ],

            dtOtherPersonIdentifierValidDateFrom=> [
                $Data->{'SystemConfig'}{'dtOtherPersonIdentifierValidDateFrom_Text'} ? $Data->{'SystemConfig'}{'dtOtherPersonIdentifierValidDateFrom_Text'} : $lang->txt('Other Identifier Validity Date From'),
                {
                    displaytype => 'date',
                    fieldtype   => 'date',
                    allowsort   => 1,
                    datetimeformat => ['MEDIUM',''],
                    optiongroup => 'identifications',
                    dbfield     => 'P.dtOtherPersonIdentifierValidDateFrom'
                }
            ],
            dtOtherPersonIdentifierValidDateTo=> [
                $Data->{'SystemConfig'}{'dtOtherPersonIdentifierValidDateTo_Text'} ? $Data->{'SystemConfig'}{'dtOtherPersonIdentifierValidDateTo_Text'} : $lang->txt('Other Identifier Validity Date To'),
                {
                    displaytype => 'date',
                    fieldtype   => 'date',
                    allowsort   => 1,
                    datetimeformat => ['MEDIUM',''],
                    optiongroup => 'identifications',
                    dbfield     => 'P.dtOtherPersonIdentifierValidDateTo'
                }
            ],
            intOtherPersonIdentifierTypeID=> [
                $Data->{'SystemConfig'}{'intOtherPersonIdentifierTypeID_Text'} ? $Data->{'SystemConfig'}{'intOtherPersonIdentifierTypeID_Text'} : 'Other Identifier Type',
                {
                    displaytype     => 'lookup',
                    fieldtype       => 'dropdown',
                    dropdownoptions => $CommonVals->{'DefCodes'}{-20},
                    optiongroup => 'identifications',
                    allowgrouping   => 1,
                    dbfield     => 'P.intOtherPersonIdentifierTypeID'
                }
            ],


            strP1FName => [
                'Parent/Guardian 1 Firstname',
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 0,
                    optiongroup => 'parents',
                    dbfield     => 'P.strP1FName'
                }
            ],

            strP1SName => [
                'Parent/Guardian 1 Surname',
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 0,
                    optiongroup => 'parents',
                    dbfield     => 'P.strP1SName'
                }
            ],

            strP1Phone => [
                'Parent/Guardian 1 Phone',
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    optiongroup => 'parents',
                    dbfield     => 'P.strP1Phone'
                }
            ],

            strP1Email => [
                'Parent/Guardian 1 Email',
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    optiongroup => 'parents',
                    dbfield     => 'P.strP1Email'
                }
            ],
            intOccupationID => [
                'Occupation',
                {
                    displaytype     => 'lookup',
                    fieldtype       => 'dropdown',
                    dropdownoptions => $CommonVals->{'DefCodes'}{-9},
                    optiongroup     => 'otherfields',
                    allowgrouping   => 1,
                    dbfield     => 'P.intOccupationID'
                }
            ],


            strNatCustomStr1 => [
                $CommonVals->{'CustomFields'}->{'strNatCustomStr1'}[0],
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 0,
                    optiongroup => 'otherfields',
                    dbfield     => 'P.strNatCustomStr1'
                }
            ],

            strNatCustomStr2 => [
                $CommonVals->{'CustomFields'}->{'strNatCustomStr2'}[0],
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 0,
                    optiongroup => 'otherfields',
                    dbfield     => 'P.strNatCustomStr2'
                }
            ],

            strNatCustomStr3 => [
                $CommonVals->{'CustomFields'}->{'strNatCustomStr3'}[0],
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 0,
                    optiongroup => 'otherfields',
                    dbfield     => 'P.strNatCustomStr3'
                }
            ],

            strNatCustomStr4 => [
                $CommonVals->{'CustomFields'}->{'strNatCustomStr4'}[0],
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 0,
                    optiongroup => 'otherfields',
                    dbfield     => 'P.strNatCustomStr4'
                }
            ],

            strNatCustomStr5 => [
                $CommonVals->{'CustomFields'}->{'strNatCustomStr5'}[0],
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 0,
                    optiongroup => 'otherfields',
                    dbfield     => 'P.strNatCustomStr5'
                }
            ],

            strNatCustomStr6 => [
                $CommonVals->{'CustomFields'}->{'strNatCustomStr6'}[0],
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 0,
                    optiongroup => 'otherfields',
                    dbfield     => 'P.strNatCustomStr6'
                }
            ],

            strNatCustomStr7 => [
                $CommonVals->{'CustomFields'}->{'strNatCustomStr7'}[0],
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 0,
                    optiongroup => 'otherfields',
                    dbfield     => 'P.strNatCustomStr7'
                }
            ],

            strNatCustomStr8 => [
                $CommonVals->{'CustomFields'}->{'strNatCustomStr8'}[0],
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 0,
                    optiongroup => 'otherfields',
                    dbfield     => 'P.strNatCustomStr8'
                }
            ],

            strNatCustomStr9 => [
                $CommonVals->{'CustomFields'}->{'strNatCustomStr9'}[0],
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 0,
                    optiongroup => 'otherfields',
                    dbfield     => 'P.strNatCustomStr9'
                }
            ],

            strNatCustomStr10 => [
                $CommonVals->{'CustomFields'}->{'strNatCustomStr10'}[0],
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 0,
                    optiongroup => 'otherfields',
                    dbfield     => 'P.strNatCustomStr10'
                }
            ],

            strNatCustomStr11 => [
                $CommonVals->{'CustomFields'}->{'strNatCustomStr11'}[0],
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 0,
                    optiongroup => 'otherfields',
                    dbfield     => 'P.strNatCustomStr11'
                }
            ],

            strNatCustomStr12 => [
                $CommonVals->{'CustomFields'}->{'strNatCustomStr12'}[0],
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 0,
                    optiongroup => 'otherfields',
                    dbfield     => 'P.strNatCustomStr12'
                }
            ],

            strNatCustomStr13 => [
                $CommonVals->{'CustomFields'}->{'strNatCustomStr13'}[0],
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 0,
                    optiongroup => 'otherfields',
                    dbfield     => 'P.strNatCustomStr13'
                }
            ],

            strNatCustomStr14 => [
                $CommonVals->{'CustomFields'}->{'strNatCustomStr14'}[0],
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 0,
                    optiongroup => 'otherfields',
                    dbfield     => 'P.strNatCustomStr14'
                }
            ],

            strNatCustomStr15 => [
                $CommonVals->{'CustomFields'}->{'strNatCustomStr15'}[0],
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 0,
                    optiongroup => 'otherfields',
                    dbfield     => 'P.strNatCustomStr15'
                }
            ],

            dblNatCustomDbl1 => [
                $CommonVals->{'CustomFields'}->{'dblNatCustomDbl1'}[0],
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 0,
                    optiongroup => 'otherfields',
                    dbfield     => 'P.dblNatCustomDbl1'
                }
            ],

            dblNatCustomDbl2 => [
                $CommonVals->{'CustomFields'}->{'dblNatCustomDbl2'}[0],
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 0,
                    optiongroup => 'otherfields',
                    dbfield     => 'P.dblNatCustomDbl2'
                }
            ],

            dblNatCustomDbl3 => [
                $CommonVals->{'CustomFields'}->{'dblNatCustomDbl3'}[0],
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 0,
                    optiongroup => 'otherfields',
                    dbfield     => 'P.dblNatCustomDbl3'
                }
            ],

            dblNatCustomDbl4 => [
                $CommonVals->{'CustomFields'}->{'dblNatCustomDbl4'}[0],
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 0,
                    optiongroup => 'otherfields',
                    dbfield     => 'P.dblNatCustomDbl4'
                }
            ],

            dblNatCustomDbl5 => [
                $CommonVals->{'CustomFields'}->{'dblNatCustomDbl5'}[0],
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 0,
                    optiongroup => 'otherfields',
                    dbfield     => 'P.dblNatCustomDbl5'
                }
            ],

            dblNatCustomDbl6 => [
                $CommonVals->{'CustomFields'}->{'dblNatCustomDbl6'}[0],
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 0,
                    optiongroup => 'otherfields',
                    dbfield     => 'P.dblNatCustomDbl6'
                }
            ],

            dblNatCustomDbl7 => [
                $CommonVals->{'CustomFields'}->{'dblNatCustomDbl7'}[0],
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 0,
                    optiongroup => 'otherfields',
                    dbfield     => 'P.dblNatCustomDbl7'
                }
            ],

            dblNatCustomDbl8 => [
                $CommonVals->{'CustomFields'}->{'dblNatCustomDbl8'}[0],
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 0,
                    optiongroup => 'otherfields',
                    dbfield     => 'P.dblNatCustomDbl8'
                }
            ],

            dblNatCustomDbl9 => [
                $CommonVals->{'CustomFields'}->{'dblNatCustomDbl9'}[0],
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 0,
                    optiongroup => 'otherfields',
                    dbfield     => 'P.dblNatCustomDbl9'
                }
            ],

            dblNatCustomDbl10 => [
                $CommonVals->{'CustomFields'}->{'dblNatCustomDbl10'}[0],
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 0,
                    optiongroup => 'otherfields',
                    dbfield     => 'P.dblNatCustomDbl10'
                }
            ],

            dtNatCustomDt1 => [
                $CommonVals->{'CustomFields'}->{'dtNatCustomDt1'}[0],
                {
                    displaytype => 'date',
                    fieldtype   => 'date',
                    allowsort   => 0,
                    optiongroup => 'otherfields',
                    datetimeformat => ['MEDIUM',''],
                    dbfield => 'P.dtNatCustomDt1'
                }
            ],

            dtNatCustomDt2 => [
                $CommonVals->{'CustomFields'}->{'dtNatCustomDt2'}[0],
                {
                    displaytype => 'date',
                    fieldtype   => 'date',
                    allowsort   => 0,
                    optiongroup => 'otherfields',
                    datetimeformat => ['MEDIUM',''],
                    dbfield => 'P.dtNatCustomDt2'
                }
            ],

            dtNatCustomDt3 => [
                $CommonVals->{'CustomFields'}->{'dtNatCustomDt3'}[0],
                {
                    displaytype => 'date',
                    fieldtype   => 'date',
                    allowsort   => 0,
                    optiongroup => 'otherfields',
                    datetimeformat => ['MEDIUM',''],
                    dbfield => 'P.dtNatCustomDt3'
                }
            ],

            dtNatCustomDt4 => [
                $CommonVals->{'CustomFields'}->{'dtNatCustomDt4'}[0],
                {
                    displaytype => 'date',
                    fieldtype   => 'date',
                    allowsort   => 0,
                    optiongroup => 'otherfields',
                    datetimeformat => ['MEDIUM',''],
                    dbfield => 'P.dtNatCustomDt4'
                }
            ],

            dtNatCustomDt5 => [
                $CommonVals->{'CustomFields'}->{'dtNatCustomDt5'}[0],
                {
                    displaytype => 'date',
                    fieldtype   => 'date',
                    allowsort   => 0,
                    optiongroup => 'otherfields',
                    datetimeformat => ['MEDIUM',''],
                    dbfield => 'P.dtNatCustomDt5'
                }
            ],

            intNatCustomLU1 => [
                $CommonVals->{'CustomFields'}->{'intNatCustomLU1'}[0],
                {
                    displaytype     => 'lookup',
                    fieldtype       => 'dropdown',
                    dropdownoptions => $CommonVals->{'DefCodes'}{-53},
                    optiongroup     => 'otherfields',
                    size            => 3,
                    dbfield => 'P.intNatCustomLU1',
                    multiple        => 1
                }
            ],

            intNatCustomLU2 => [
                $CommonVals->{'CustomFields'}->{'intNatCustomLU2'}[0],
                {
                    displaytype     => 'lookup',
                    fieldtype       => 'dropdown',
                    dropdownoptions => $CommonVals->{'DefCodes'}{-54},
                    optiongroup     => 'otherfields',
                    size            => 3,
                    dbfield => 'P.intNatCustomLU2',
                    multiple        => 1
                }
            ],

            intNatCustomLU3 => [
                $CommonVals->{'CustomFields'}->{'intNatCustomLU3'}[0],
                {
                    displaytype     => 'lookup',
                    fieldtype       => 'dropdown',
                    dropdownoptions => $CommonVals->{'DefCodes'}{-55},
                    optiongroup     => 'otherfields',
                    size            => 3,
                    dbfield => 'P.intNatCustomLU3',
                    multiple        => 1
                }
            ],

            intNatCustomLU4 => [
                $CommonVals->{'CustomFields'}->{'intNatCustomLU4'}[0],
                {
                    displaytype     => 'lookup',
                    fieldtype       => 'dropdown',
                    dropdownoptions => $CommonVals->{'DefCodes'}{-64},
                    optiongroup     => 'otherfields',
                    size            => 3,
                    dbfield => 'P.intNatCustomLU4',
                    multiple        => 1
                }
            ],

            intNatCustomLU5 => [
                $CommonVals->{'CustomFields'}->{'intNatCustomLU5'}[0],
                {
                    displaytype     => 'lookup',
                    fieldtype       => 'dropdown',
                    dropdownoptions => $CommonVals->{'DefCodes'}{-65},
                    optiongroup     => 'otherfields',
                    size            => 3,
                    dbfield => 'P.intNatCustomLU5',
                    multiple        => 1
                }
            ],

            intNatCustomLU6 => [
                $CommonVals->{'CustomFields'}->{'intNatCustomLU6'}[0],
                {
                    displaytype     => 'lookup',
                    fieldtype       => 'dropdown',
                    dropdownoptions => $CommonVals->{'DefCodes'}{-66},
                    optiongroup     => 'otherfields',
                    size            => 3,
                    dbfield => 'P.intNatCustomLU6',
                    multiple        => 1
                }
            ],

            intNatCustomLU7 => [
                $CommonVals->{'CustomFields'}->{'intNatCustomLU7'}[0],
                {
                    displaytype     => 'lookup',
                    fieldtype       => 'dropdown',
                    dropdownoptions => $CommonVals->{'DefCodes'}{-67},
                    optiongroup     => 'otherfields',
                    size            => 3,
                    dbfield => 'P.intNatCustomLU7',
                    multiple        => 1
                }
            ],

            intNatCustomLU8 => [
                $CommonVals->{'CustomFields'}->{'intNatCustomLU8'}[0],
                {
                    displaytype     => 'lookup',
                    fieldtype       => 'dropdown',
                    dropdownoptions => $CommonVals->{'DefCodes'}{-68},
                    optiongroup     => 'otherfields',
                    size            => 3,
                    dbfield => 'P.intNatCustomLU8',
                    multiple        => 1
                }
            ],

            intNatCustomLU9 => [
                $CommonVals->{'CustomFields'}->{'intNatCustomLU9'}[0],
                {
                    displaytype     => 'lookup',
                    fieldtype       => 'dropdown',
                    dropdownoptions => $CommonVals->{'DefCodes'}{-69},
                    optiongroup     => 'otherfields',
                    size            => 3,
                    dbfield => 'P.intNatCustomLU9',
                    multiple        => 1
                }
            ],

            intNatCustomLU10 => [
                $CommonVals->{'CustomFields'}->{'intNatCustomLU10'}[0],
                {
                    displaytype     => 'lookup',
                    fieldtype       => 'dropdown',
                    dropdownoptions => $CommonVals->{'DefCodes'}{-70},
                    optiongroup     => 'otherfields',
                    size            => 3,
                    dbfield => 'P.intNatCustomLU10',
                    multiple        => 1
                }
            ],

            intNatCustomBool1 => [
                $CommonVals->{'CustomFields'}->{'intNatCustomBool1'}[0],
                {
                    displaytype     => 'lookup',
                    fieldtype       => 'dropdown',
                    dropdownoptions => { 0 => 'No', 1 => 'Yes' },
                    dropdownorder => [ 0, 1 ],
                    dbfield => 'P.intNatCustomBool1',
                    optiongroup   => 'otherfields',
                }
            ],

            intNatCustomBool2 => [
                $CommonVals->{'CustomFields'}->{'intNatCustomBool2'}[0],
                {
                    displaytype     => 'lookup',
                    fieldtype       => 'dropdown',
                    dropdownoptions => { 0 => 'No', 1 => 'Yes' },
                    dropdownorder => [ 0, 1 ],
                    dbfield => 'P.intNatCustomBool2',
                    optiongroup   => 'otherfields',
                }
            ],

            intNatCustomBool3 => [
                $CommonVals->{'CustomFields'}->{'intNatCustomBool3'}[0],
                {
                    displaytype     => 'lookup',
                    fieldtype       => 'dropdown',
                    dropdownoptions => { 0 => 'No', 1 => 'Yes' },
                    dropdownorder => [ 0, 1 ],
                    dbfield => 'P.intNatCustomBool3',
                    optiongroup   => 'otherfields',
                }
            ],

            intNatCustomBool4 => [
                $CommonVals->{'CustomFields'}->{'intNatCustomBool4'}[0],
                {
                    displaytype     => 'lookup',
                    fieldtype       => 'dropdown',
                    dropdownoptions => { 0 => 'No', 1 => 'Yes' },
                    dropdownorder => [ 0, 1 ],
                    dbfield => 'P.intNatCustomBool4',
                    optiongroup   => 'otherfields',
                }
            ],

            intNatCustomBool5 => [
                $CommonVals->{'CustomFields'}->{'intNatCustomBool5'}[0],
                {
                    displaytype     => 'lookup',
                    fieldtype       => 'dropdown',
                    dropdownoptions => { 0 => 'No', 1 => 'Yes' },
                    dropdownorder => [ 0, 1 ],
                    dbfield => 'P.intNatCustomBool5',
                    optiongroup   => 'otherfields',
                }
            ],
           
            strMemberNotes => [
                $lang->txt('Notes'),
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 0,
                    dbfield     => 'strMemberNotes',
                    optiongroup => 'otherfields',
                    dbfrom =>
'LEFT JOIN tblPersonNotes as MN ON (MN.intNotesMemberID = tblPerson_Associations.intPersonID AND MN.intNotesAssocID = tblPerson_Associations.intAssocID)'
                }
            ],

            intPhoto => [
                $lang->txt('Photo Present?'),
                {
                    displaytype     => 'lookup',
                    fieldtype       => 'dropdown',
                    dropdownoptions => { 0 => 'No', 1 => 'Yes' },
                    dropdownorder => [ 0, 1 ],
                    dbfield       => 'P.intPhoto',
                    optiongroup   => 'otherfields',
                    allowgrouping => 1
                }
            ],

            dtSuspendedUntil => [
                $Data->{'SystemConfig'}{'NoComps'} ? '' : 'Suspended Until',
                {
                    displaytype => 'date',
                    fieldtype   => 'date',
                    allowsort   => 1,
                    datetimeformat => ['MEDIUM',''],
                    optiongroup => 'otherfields',
                    dbfield     => 'P.dtSuspendedUntil'
                }
            ],

          },
#strP1Salutation
#              strP1FName
#              strP1SName
#              intP1Gender
#              strP1Phone
#              strP1Phone2
#              strP1PhoneMobile
#              strP1Email


          Order => [
            qw(
              MasterNationalNum
              MasterLocalFirstname
              MasterLocalSurname
              MasterLatinFirstname
              MasterLatinSurname

              strNationalNum
              PstrImportCode
              strLocalFirstname
              strLocalSurname
              strISONationality
              strLatinFirstname
              strLatinSurname
              dtDOB
              dtYOB
              strRegionOfBirth
              strPlaceOfBirth
              strISOCountryOfBirth
              strMotherCountry
              strFatherCountry
              intGender
              intDeceased
              intEthnicityID
              intMinorProtection

              strAddress1
              strAddress2
              strSuburb

              strState
              strISOCountry
              strPostalCode
              strPhoneHome
              strEmail
              strEmail2
              strPassportIssueCountry
              strPassportNationality
              strPassportNo
              dtPassportExpiry
              strBirthCert
                strBirthCertDesc
                strBirthCertCountry
                dtBirthCertValidityDateFrom
                dtBirthCertValidityDateTo

                strOtherPersonIdentifier
                strOtherPersonIdentifierDesc
                strOtherPersonIdentifierIssueCountry        
                dtOtherPersonIdentifierValidDateFrom    
                dtOtherPersonIdentifierValidDateTo
                intOtherPersonIdentifierTypeID

               intOccupationID

              strNatCustomStr1
              strNatCustomStr2
              strNatCustomStr3
              strNatCustomStr4
              strNatCustomStr5
              strNatCustomStr6
              strNatCustomStr7
              strNatCustomStr8
              strNatCustomStr9
              strNatCustomStr10
              strNatCustomStr11
              strNatCustomStr12
              strNatCustomStr13
              strNatCustomStr14
              strNatCustomStr15
              dblNatCustomDbl1
              dblNatCustomDbl2
              dblNatCustomDbl3
              dblNatCustomDbl4
              dblNatCustomDbl5
              dblNatCustomDbl6
              dblNatCustomDbl7
              dblNatCustomDbl8
              dblNatCustomDbl9
              dblNatCustomDbl10
              dtNatCustomDt1
              dtNatCustomDt2
              dtNatCustomDt3
              dtNatCustomDt4
              dtNatCustomDt5
              intNatCustomLU1
              intNatCustomLU2
              intNatCustomLU3
              intNatCustomLU4
              intNatCustomLU5
              intNatCustomLU6
              intNatCustomLU7
              intNatCustomLU8
              intNatCustomLU9
              intNatCustomLU10
              intNatCustomBool1

              intNatCustomBool2
              intNatCustomBool3
              intNatCustomBool4
              intNatCustomBool5

              intPhoto
              )
          ],
          Config => {
            EmailExport        => 1,
            limitView          => 5000,
            EmailSenderAddress => $Defs::admin_email,
            SecondarySort      => 1,
            RunButtonLabel     => 'Run Report',
            ReturnProcessData  => [
                qw(tblPerson.strEmail tblPerson.strPhoneMobile tblPerson.strSurname tblPerson.strFirstname tblPerson.intPersonID)
            ],
            DateTimeFormatObject => $Data->{'l10n'}{'date'},
          },
          ExportFormats => {
          },
          OptionGroups => {
            details         => [ $lang->txt('Personal Details'), { active => 1 } ],
            contactdetails  => [ $lang->txt('Contact Details'),  {} ],
            identifications => [ $lang->txt('Identifications'),  {} ],
            otherfields     => [ $lang->txt('Other Fields'),     {} ],
            affiliations    => [ $lang->txt('Affiliations'),     {} ],
            records         => [ $lang->txt('Member Records'),   {} ],
          },

    );

    $self->{'Config'} = \%config;
}

sub SQLBuilder {
    my ( $self, $OptVals, $ActiveFields ) = @_;
    my $currentLevel = $self->{'EntityTypeID'} || 0;
    my $Data         = $self->{'Data'};
    my $clientValues = $Data->{'clientValues'};
    my $SystemConfig = $Data->{'SystemConfig'};

    my $enable_record_types = $Data->{'SystemConfig'}{'EnableMemberRecords'} || 0; 
    my $PRtablename = "tblPersonRegistration_$Data->{'Realm'}";

    my $from_levels   = $OptVals->{'FROM_LEVELS'};
    my $from_list     = $OptVals->{'FROM_LIST'};
    my $where_levels  = $OptVals->{'WHERE_LEVELS'};
    my $where_list    = $OptVals->{'WHERE_LIST'};
    my $current_from  = $OptVals->{'CURRENT_FROM'};
    my $current_where = $OptVals->{'CURRENT_WHERE'};
    my $select_levels = $OptVals->{'SELECT_LEVELS'};
    my $sql           = '';

    my $entityID = getLastEntityID($Data->{'clientValues'});

    #if ( $where_list and ( $where_levels or $current_where ) ) {
        $where_list = ' AND ' . $where_list;
    #}
    $where_list =~ s/\sAND\s*$//g;
    $where_list =~ s/AND  AND/AND /;

    $sql = qq[
        SELECT ###SELECT###
        FROM
            tblPerson as P
            LEFT JOIN tblPersonDuplicates as PD ON (PD.intChildPersonID = P.intPersonID)
            LEFT JOIN tblPerson as PMaster ON (PMaster.intPersonID = PD.intParentPersonID)
        WHERE
            $where_list
            $current_where
            AND P.strStatus = 'DUPLICATE'
    ];

    return ( $sql, '' );
}

1;
# vim: set et sw=4 ts=4:
