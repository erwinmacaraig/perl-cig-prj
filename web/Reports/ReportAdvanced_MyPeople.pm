#
# $Header: svn://svn/SWM/trunk/web/Reports/ReportAdvanced_Member.pm 11613 2014-05-20 03:02:24Z cgao $
#

package Reports::ReportAdvanced_MyPeople;

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
        },
    );
    my $hideSeasons = $CommonVals->{'Seasons'}{'Hide'} || 0;
    my $enable_record_types = $Data->{'SystemConfig'}{'EnableMemberRecords'} || 0; 

    my $FieldLabels = $CommonVals->{'FieldLabels'} || undef;
    my %NRO = ();

    my $txt_Clr = $Data->{'SystemConfig'}{'txtCLR'} || 'Clearance';
    my $txt_Transactions = $Data->{'SystemConfig'}{'txns_link_name'} || 'Transaction';

    my $PRtablename = "tblPersonRegistration_$Data->{'Realm'}";
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
                    optiongroup => 'details'
                }
            ],
            MemberID => [
                'Person ID',
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 1,
                    optiongroup => 'details',
                    dbfield     => 'tblPerson.intPersonID'
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
                    allowgrouping => 1
                }
            ],
            PstrImportCode=> [
                $lang->txt('Imported Person Code'),
                {
                    dbfield         => 'tblPerson.strImportPersonCode',
                    displaytype   => 'text',
                    fieldtype     => 'text',
                    allowsort     => 1,
                    optiongroup   => 'details',
                }
            ],
 
            PstrStatus=> [
                'Person Status',
                {
                    dbfield         => 'tblPerson.strStatus',
                    displaytype     => 'lookup',
                    fieldtype       => 'dropdown',
                    dropdownoptions => \%Defs::personStatus,
                    translate       => 1,
                    optiongroup     => 'details',
                    allowgrouping   => 1
                }
            ],
            strLatinFirstname => [
                'International First name',
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    active      => 1,
                    allowsort   => 1,
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
                    dbfield         => 'UCASE(strISONationality)',
                    allowgrouping   => 1
                }
            ],


            strPreferredName => [
                'Preferred Name',
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 1,
                    optiongroup => 'details'
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
                    dbfield         => 'UCASE(strISOCountryOfBirth)',
                    allowgrouping   => 1
                }
            ],

            dtDOB => [
                'Date of Birth',
                {
                    displaytype => 'date',
                    fieldtype   => 'date',
                    allowsort   => 1,
                    dbfield     => 'tblPerson.dtDOB',
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
                    dbfield       => 'YEAR(tblPerson.dtDOB)',
                    dbformat      => ' YEAR(tblPerson.dtDOB)',
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
                    allowgrouping   => 1
                }
            ],

            PRintOriginLevel=> [
                'Record Creation',
                {
                    dbfield         => 'PR.intOriginLevel',
                    displaytype     => 'lookup',
                    fieldtype       => 'dropdown',
                    dropdownoptions => \%Defs::originLevelTypes,
                    translate       => 1,
                    optiongroup     => 'regos',
                    allowgrouping   => 1
                }
            ],
             PRstrPersonType=> [
                'Role',
                {
                    dbfield         => 'PR.strPersonType',
                    displaytype     => 'lookup',
                    fieldtype       => 'dropdown',
                    dropdownoptions => \%Defs::personType,
                    translate       => 1,
                    optiongroup     => 'regos',
                    allowgrouping   => 1
                }
            ],
            PRstrAgeLevel=> [
                'Age Level',
                {
                    dbfield         => 'PR.strAgeLevel',
                    displaytype     => 'lookup',
                    fieldtype       => 'dropdown',
                    dropdownoptions => \%Defs::ageLevel,
                    translate       => 1,
                    optiongroup     => 'regos',
                    allowgrouping   => 1
                }
            ],

            PRstrPersonLevel=> [
                'Level',
                {
                    dbfield         => 'PR.strPersonLevel',
                    displaytype     => 'lookup',
                    fieldtype       => 'dropdown',
                    dropdownoptions => \%Defs::personLevel,
                    translate       => 1,
                    optiongroup     => 'regos',
                    allowgrouping   => 1
                }
            ],
            PRstrRegistrationNature=> [
                'Nature of Registration',
                {
                    dbfield         => 'PR.strRegistrationNature',
                    displaytype     => 'lookup',
                    fieldtype       => 'dropdown',
                    dropdownoptions => \%Defs::registrationNature,
                    translate       => 1,
                    optiongroup     => 'regos',
                    allowgrouping   => 1
                }
            ],

            PRstrStatus=> [
                'Status',
                {
                    dbfield         => 'PR.strStatus',
                    displaytype     => 'lookup',
                    fieldtype       => 'dropdown',
                    dropdownoptions => \%Defs::personRegoStatus,
                    translate       => 1,
                    optiongroup     => 'regos',
                    allowgrouping   => 1
                }
            ],
            PRstrSport=> [
                'Sport',
                {
                    dbfield         => 'PR.strSport',
                    displaytype     => 'lookup',
                    fieldtype       => 'dropdown',
                    dropdownoptions => \%Defs::sportType,
                    optiongroup     => 'regos',
                    translate       => 1,
                    allowgrouping   => 1
                }
            ],
            PRstrPersonEntityRole=> [
                'Sub Role',
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    dbfield     => 'ETR.strEntityRoleName',
                    translate       => 1,
                    optiongroup => 'regos',
                    dbfrom => "
                        LEFT JOIN tblEntityTypeRoles as ETR ON (
                            ETR.strEntityRoleKey = PR.strPersonEntityRole
                        ) 
                    ",
                }
            ],
            PRintNationalPeriodID=> [
                $lang->txt('Registration Period'),
                {
                    displaytype     => 'lookup',
                    fieldtype       => 'dropdown',
                    dropdownoptions => $CommonVals->{'NationalPeriods'},
                    allowsort       => 1,
                    optiongroup     => 'regos',
                    dbfield         => 'PR.intNationalPeriodID',
                    allowgrouping   => 1
                }
            ],


            PRdtFrom=> [
                'Date From',
                {
                    displaytype => 'date',
                    fieldtype   => 'date',
                    allowsort   => 1,
                    dbfield     => 'PR.dtFrom',
                    datetimeformat => ['MEDIUM',''],
                    optiongroup => 'regos'
                }
            ],
            PRdtTo=> [
                $lang->txt('Date To'),
                {
                    displaytype => 'date',
                    fieldtype   => 'date',
                    allowsort   => 1,
                    dbfield     => 'PR.dtTo',
                    datetimeformat => ['MEDIUM',''],
                    optiongroup => 'regos'
                }
            ],
            PRintPaymentRequired=> [
                $lang->txt('Payment Required ?'),
                {
                    displaytype     => 'lookup',
                    fieldtype       => 'dropdown',
                    dropdownoptions => { 0 => 'No', 1 => 'Yes' },
                    dropdownorder => [ 0, 1 ],
                    dbfield       => 'PR.intPaymentRequired',
                    defaultcomp   => 'equal',
                    defaultvalue  => '0',
                    translate       => 1,
                    active        => 1,
                    optiongroup   => 'regos'
                }
            ],
            PRintOnLoan=> [
                $lang->txt('On Loan ?'),
                {
                    displaytype     => 'lookup',
                    fieldtype       => 'dropdown',
                    dropdownoptions => { 0 => 'No', 1 => 'Yes' },
                    dropdownorder => [ 0, 1 ],
                    dbfield       => 'PR.intOnLoan',
                    defaultcomp   => 'equal',
                    defaultvalue  => '0',
                    active        => 1,
                    optiongroup   => 'regos',
                    translate       => 1,
                    allowsort   => 1,
                    allowgrouping => 1,
                }
            ],
            PRintIsLoanedOut=> [
                $lang->txt('Loaned out ?'),
                {
                    displaytype     => 'lookup',
                    fieldtype       => 'dropdown',
                    dropdownoptions => { 0 => 'No', 1 => 'Yes' },
                    dropdownorder => [ 0, 1 ],
                    dbfield       => 'PR.intIsLoanedOut',
                    defaultcomp   => 'equal',
                    defaultvalue  => '0',
                    active        => 1,
                    optiongroup   => 'regos',
                    translate       => 1,
                    allowsort   => 1,
                    allowgrouping => 1,
                }
            ],


           PRstrLocalName=> [
                $lang->txt('Entity Name'),
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    dbfield     => 'E.strLocalName',
                    optiongroup => 'regos'
                }
            ],



           strAddress1 => [
                'Address 1',
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    dbfield     => 'tblPerson.strAddress1',
                    optiongroup => 'contactdetails'
                }
            ],

            strAddress2 => [
                'Address 2',
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    dbfield     => 'tblPerson.strAddress2',
                    optiongroup => 'contactdetails'
                }
            ],

            strSuburb => [
                'City',
                {
                    displaytype   => 'text',
                    fieldtype     => 'text',
                    dbfield       => 'tblPerson.strSuburb',
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
                    dbfield       => 'tblPerson.strState',
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
                    dbfield       => 'tblPerson.strISOCountry',
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
                    dbfield       => 'tblPerson.strPostalCode',
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
                    optiongroup => 'contactdetails'
                }
            ],

            strPhoneMobile => [
                'Mobile Phone',
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    optiongroup => 'contactdetails'
                }
            ],

            strEmail => [
                'Email',
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    dbfield     => 'tblPerson.strEmail',
                    optiongroup => 'contactdetails'
                }
            ],

           strEmergContName => [
                'Emergency Contact Name',
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 0,
                    optiongroup => 'contactdetails'
                }
            ],

            strEmergContRel => [
                'Emergency Contact Relationship',
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 0,
                    optiongroup => 'contactdetails'
                }
            ],

            strEmergContNo => [
                'Emergency Contact No',
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 0,
                    optiongroup => 'contactdetails',
                }
            ],

            strEmergContNo2 => [
                'Emergency Contact No 2',
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 0,
                    optiongroup => 'contactdetails',
                }
            ],


            strPreferredLang => [
                $lang->txt('Preferred Language'),
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 0,
                    optiongroup => 'identifications'
                }
            ],

            strBirthCert => [
                $lang->txt('Birth Certificate Number'),
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 0,
                    optiongroup => 'identifications'
                }
            ],
            strBirthCertDesc=> [
                $lang->txt('Birth Certificate Notes'),
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 0,
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
                    dbfield         => 'UCASE(strBirthCertCountry)',
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
                    dbfield     => 'tblPerson.dtBirthCertValidityDateFrom'
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
                    dbfield     => 'tblPerson.dtBirthCertValidityDateTo'
                }
            ],

            strOtherPersonIdentifier=> [
                $Data->{'SystemConfig'}{'strOtherPersonIdentifier_Text'} ? $Data->{'SystemConfig'}{'strOtherPersonIdentifier_Text'} : $lang->txt('Other Identifier'),
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 0,
                    optiongroup => 'identifications'
                }
            ],
            strOtherPersonIdentifierDesc=> [
                $Data->{'SystemConfig'}{'strOtherPersonIdentifierDesc_Text'} ? $Data->{'SystemConfig'}{'strOtherPersonIdentifierDesc_Text'} : $lang->txt('Other Identifier Description'),
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 0,
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
                    dbfield         => 'UCASE(strOtherPersonIdentifierIssueCountry)',
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
                    dbfield     => 'tblPerson.dtOtherPersonIdentifierValidDateFrom'
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
                    dbfield     => 'tblPerson.dtOtherPersonIdentifierValidDateTo'
                }
            ],
            intOtherPersonIdentifierTypeID=> [
                $Data->{'SystemConfig'}{'intOtherPersonIdentifierTypeID_Text'} ? $Data->{'SystemConfig'}{'intOtherPersonIdentifierTypeID_Text'} : 'Other Identifier Type',
                {
                    displaytype     => 'lookup',
                    fieldtype       => 'dropdown',
                    dropdownoptions => $CommonVals->{'DefCodes'}{-20},
                    optiongroup => 'identifications',
                    allowgrouping   => 1
                }
            ],


            strP1FName => [
                'Parent/Guardian 1 Firstname',
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 0,
                    optiongroup => 'parents',
                }
            ],

            strP1SName => [
                'Parent/Guardian 1 Surname',
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 0,
                    optiongroup => 'parents',
                }
            ],

            strP1Phone => [
                'Parent/Guardian 1 Phone',
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    optiongroup => 'parents'
                }
            ],

            strP1Email => [
                'Parent/Guardian 1 Email',
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    optiongroup => 'parents'
                }
            ],
            intOccupationID => [
                'Occupation',
                {
                    displaytype     => 'lookup',
                    fieldtype       => 'dropdown',
                    dropdownoptions => $CommonVals->{'DefCodes'}{-9},
                    optiongroup     => 'otherfields',
                    allowgrouping   => 1
                }
            ],


            strNatCustomStr1 => [
                $CommonVals->{'CustomFields'}->{'strNatCustomStr1'}[0],
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 0,
                    optiongroup => 'otherfields'
                }
            ],

            strNatCustomStr2 => [
                $CommonVals->{'CustomFields'}->{'strNatCustomStr2'}[0],
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 0,
                    optiongroup => 'otherfields'
                }
            ],

            strNatCustomStr3 => [
                $CommonVals->{'CustomFields'}->{'strNatCustomStr3'}[0],
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 0,
                    optiongroup => 'otherfields'
                }
            ],

            strNatCustomStr4 => [
                $CommonVals->{'CustomFields'}->{'strNatCustomStr4'}[0],
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 0,
                    optiongroup => 'otherfields'
                }
            ],

            strNatCustomStr5 => [
                $CommonVals->{'CustomFields'}->{'strNatCustomStr5'}[0],
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 0,
                    optiongroup => 'otherfields'
                }
            ],

            strNatCustomStr6 => [
                $CommonVals->{'CustomFields'}->{'strNatCustomStr6'}[0],
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 0,
                    optiongroup => 'otherfields'
                }
            ],

            strNatCustomStr7 => [
                $CommonVals->{'CustomFields'}->{'strNatCustomStr7'}[0],
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 0,
                    optiongroup => 'otherfields'
                }
            ],

            strNatCustomStr8 => [
                $CommonVals->{'CustomFields'}->{'strNatCustomStr8'}[0],
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 0,
                    optiongroup => 'otherfields'
                }
            ],

            strNatCustomStr9 => [
                $CommonVals->{'CustomFields'}->{'strNatCustomStr9'}[0],
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 0,
                    optiongroup => 'otherfields'
                }
            ],

            strNatCustomStr10 => [
                $CommonVals->{'CustomFields'}->{'strNatCustomStr10'}[0],
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 0,
                    optiongroup => 'otherfields'
                }
            ],

            strNatCustomStr11 => [
                $CommonVals->{'CustomFields'}->{'strNatCustomStr11'}[0],
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 0,
                    optiongroup => 'otherfields'
                }
            ],

            strNatCustomStr12 => [
                $CommonVals->{'CustomFields'}->{'strNatCustomStr12'}[0],
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 0,
                    optiongroup => 'otherfields'
                }
            ],

            strNatCustomStr13 => [
                $CommonVals->{'CustomFields'}->{'strNatCustomStr13'}[0],
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 0,
                    optiongroup => 'otherfields'
                }
            ],

            strNatCustomStr14 => [
                $CommonVals->{'CustomFields'}->{'strNatCustomStr14'}[0],
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 0,
                    optiongroup => 'otherfields'
                }
            ],

            strNatCustomStr15 => [
                $CommonVals->{'CustomFields'}->{'strNatCustomStr15'}[0],
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 0,
                    optiongroup => 'otherfields'
                }
            ],

            dblNatCustomDbl1 => [
                $CommonVals->{'CustomFields'}->{'dblNatCustomDbl1'}[0],
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 0,
                    optiongroup => 'otherfields'
                }
            ],

            dblNatCustomDbl2 => [
                $CommonVals->{'CustomFields'}->{'dblNatCustomDbl2'}[0],
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 0,
                    optiongroup => 'otherfields'
                }
            ],

            dblNatCustomDbl3 => [
                $CommonVals->{'CustomFields'}->{'dblNatCustomDbl3'}[0],
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 0,
                    optiongroup => 'otherfields'
                }
            ],

            dblNatCustomDbl4 => [
                $CommonVals->{'CustomFields'}->{'dblNatCustomDbl4'}[0],
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 0,
                    optiongroup => 'otherfields'
                }
            ],

            dblNatCustomDbl5 => [
                $CommonVals->{'CustomFields'}->{'dblNatCustomDbl5'}[0],
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 0,
                    optiongroup => 'otherfields'
                }
            ],

            dblNatCustomDbl6 => [
                $CommonVals->{'CustomFields'}->{'dblNatCustomDbl6'}[0],
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 0,
                    optiongroup => 'otherfields'
                }
            ],

            dblNatCustomDbl7 => [
                $CommonVals->{'CustomFields'}->{'dblNatCustomDbl7'}[0],
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 0,
                    optiongroup => 'otherfields'
                }
            ],

            dblNatCustomDbl8 => [
                $CommonVals->{'CustomFields'}->{'dblNatCustomDbl8'}[0],
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 0,
                    optiongroup => 'otherfields'
                }
            ],

            dblNatCustomDbl9 => [
                $CommonVals->{'CustomFields'}->{'dblNatCustomDbl9'}[0],
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 0,
                    optiongroup => 'otherfields'
                }
            ],

            dblNatCustomDbl10 => [
                $CommonVals->{'CustomFields'}->{'dblNatCustomDbl10'}[0],
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 0,
                    optiongroup => 'otherfields'
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
                    dbfield => 'tblPerson.dtNatCustomDt1'
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
                    dbfield => 'tblPerson.dtNatCustomDt2'
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
                    dbfield => 'tblPerson.dtNatCustomDt3'
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
                    dbfield => 'tblPerson.dtNatCustomDt4'
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
                    dbfield => 'tblPerson.dtNatCustomDt5'
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
                    dbfield       => 'tblPerson.intPhoto',
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
                    dbfield     => 'tblPerson.dtSuspendedUntil'
                }
            ],

            #Affilitations

              strZoneName => [
                (
                      $currentLevel > $Defs::LEVEL_ZONE
                    ? $Data->{'LevelNames'}{$Defs::LEVEL_ZONE} . ' Name'
                    : ''
                ),
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 1,
                    dbfield =>
"IF(tblZone.intStatusID = $Defs::NODE_SHOW, tblZone.strName,'')",
                    allowgrouping => 1,
                    optiongroup   => 'affiliations'
                }
              ],

              strRegionName => [
                (
                      $currentLevel > $Defs::LEVEL_REGION
                    ? $lang->txt('Region Name')
                    : ''
                ),
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 1,
                    dbfield =>
"IF(tblRegion.intStatusID = $Defs::NODE_SHOW, tblRegion.strName,'')",
                    allowgrouping => 1,
                    optiongroup   => 'affiliations'
                }
              ],

              strStateName => [
                (
                      $currentLevel > $Defs::LEVEL_STATE
                    ? $Data->{'LevelNames'}{$Defs::LEVEL_STATE} . ' Name'
                    : ''
                ),
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 1,
                    dbfield =>
"IF(tblState.intStatusID = $Defs::NODE_SHOW, tblState.strName,'')",
                    allowgrouping => 1,
                    optiongroup   => 'affiliations'
                }
              ],

              strNationalName => [
                (
                      $currentLevel > $Defs::LEVEL_NATIONAL
                    ? $Data->{'LevelNames'}{$Defs::LEVEL_NATIONAL} . ' Name'
                    : ''
                ),
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 1,
                    dbfield =>
"IF(tblNational.intStatusID = $Defs::NODE_SHOW, tblNational.strName,'')",
                    allowgrouping => 1,
                    optiongroup   => 'affiliations'
                }
              ],

              strIntZoneName => [
                (
                      $currentLevel > $Defs::LEVEL_INTZONE
                    ? $Data->{'LevelNames'}{$Defs::LEVEL_INTZONE} . ' Name'
                    : ''
                ),
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 1,
                    dbfield =>
"IF(tblIntZone.intStatusID = $Defs::NODE_SHOW, tblIntZone.strName,'')",
                    allowgrouping => 1,
                    optiongroup   => 'affiliations'
                }
              ],

              strIntRegionName => [
                (
                      $currentLevel > $Defs::LEVEL_INTREGION
                    ? $Data->{'LevelNames'}{$Defs::LEVEL_INTREGION} . ' Name'
                    : ''
                ),
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 1,
                    dbfield =>
" IF(tblIntRegion.intStatusID = $Defs::NODE_SHOW, tblIntRegion.strName,'') ",
                    allowgrouping => 1,
                    optiongroup   => 'affiliations'
                }
              ],

              #Transactions
              intTransactionID => [
                $SystemConfig->{'AllowTXNrpts'} ? $lang->txt('Transaction ID') : '',
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 1,
                    optiongroup => 'transactions'
                }
              ],
              intProductNationalPeriodID => [
                $lang->txt('Product Reporting'),
                {
                    displaytype     => 'lookup',
                    fieldtype       => 'dropdown',
                    dropdownoptions => $CommonVals->{'NationalPeriods'},
                    allowsort       => 1,
                    optiongroup     => 'transactions',
                    allowgrouping   => 1
                }
            ],
              intProductID => [
                $SystemConfig->{'AllowTXNrpts'} ? $lang->txt('Product') : '',
                {
                    displaytype     => 'lookup',
                    fieldtype       => 'dropdown',
                    dropdownoptions => $CommonVals->{'Products'}{'Options'},
                    dropdownorder   => $CommonVals->{'Products'}{'Order'},
                    allowsort       => 1,
                    optiongroup     => 'transactions',
                    multiple        => 1,
                    size            => 6,
                    dbfield         => 'TX.intProductID',
                    allowgrouping   => 1
                }
              ],
              strGroup => [
                $SystemConfig->{'AllowTXNrpts'} ? $lang->txt('Product Group') : '',
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 1,
                    optiongroup => 'transactions',
                    ddbfield    => 'P.strGroup'
                }
              ],
              curAmount => [
                $SystemConfig->{'AllowTXNrpts'} ? $lang->txt('Line Item Total') : '',
                {
                    displaytype => 'currency',
                    fieldtype   => 'text',
                    allowsort   => 1,
                    optiongroup => 'transactions',
                    total       => 1
                }
              ],
              intQty => [
                $SystemConfig->{'AllowTXNrpts'} ? $lang->txt('Quantity') : '',
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 1,
                    optiongroup => 'transactions',
                    total       => 1
                }
              ],
              TLstrReceiptRef => [
                $SystemConfig->{'AllowTXNrpts'}
                ? $lang->txt('Receipt Reference')
                : '',
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    optiongroup => 'transactions',
                    dbfield     => 'TL.strReceiptRef'
                }
              ],
              payment_type => [
                $SystemConfig->{'AllowTXNrpts'} ? $lang->txt('Payment Type') : '',
                {
                    displaytype     => 'lookup',
                    fieldtype       => 'dropdown',
                    dropdownoptions => \%Defs::paymentTypes,
                    allowsort       => 1,
                    translate       => 1,
                    optiongroup     => 'transactions',
                    dbfield         => 'TL.intPaymentType',
                    allowgrouping   => 1
                }
              ],
              strTXN => [
                $SystemConfig->{'AllowTXNrpts'} ? $lang->txt('Bank Reference Number') : '',
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    optiongroup => 'transactions',
                    dbfield     => 'TL.strTXN'
                }
              ],
              strOnlinePayReference => [
                $lang->txt('Payment Reference Number'),
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    optiongroup => 'transactions',
                    dbfield     => 'TL.strOnlinePayReference'
                }
              ],
              intLogID => [
                $SystemConfig->{'AllowTXNrpts'} ? $lang->txt('Payment Log ID') : '',
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    optiongroup => 'transactions',
                    dbfield     => 'TL.intLogID'
                }
              ],
            intTransLogStatusID => [
                $SystemConfig->{'AllowTXNrpts'} ? $lang->txt('Payment Status') : '',
                {
                    displaytype     => 'lookup',
                    fieldtype       => 'dropdown',
                    dropdownoptions => \%Defs::TransLogStatus,
                    allowsort       => 1,
                    optiongroup     => 'transactions',
                    dbfield         => 'TL.intStatus'
                }
              ],
              intAmount => [
                $SystemConfig->{'AllowTXNrpts'} ? $lang->txt('Order Total') : '',
                {
                    displaytype => 'currency',
                    fieldtype   => 'text',
                    allowsort   => 1,
                    total       => 1,
                    optiongroup => 'transactions',
                    dbfield     => 'TL.intAmount'
                }
              ],
              dtTransaction => [
                ( $SystemConfig->{'AllowTXNrpts'} ? $lang->txt('Transaction Date') : '' ),
                {
                    displaytype => 'date',
                    fieldtype   => 'datetime',
                    allowsort   => 1,
                    datetimeformat => ['MEDIUM','MEDIUM'],
                    optiongroup => 'transactions',
                    dbfield     => 'TX.dtTransaction',
                    sortfield   => 'TX.dtTransaction'
                }
              ],
              dtPaid => [
                ( $SystemConfig->{'AllowTXNrpts'} ? $lang->txt('Payment Date') : '' ),
                {
                    displaytype => 'date',
                    fieldtype   => 'datetime',
                    allowsort   => 1,
                    datetimeformat => ['MEDIUM','MEDIUM'],
                    optiongroup => 'transactions',
                    dbfield     => 'TX.dtPaid'
                }
              ],
              dtSettlement => [
                ( $SystemConfig->{'AllowTXNrpts'} ? $lang->txt('Settlement Date') : '' ),
                {
                    displaytype   => 'date',
                    fieldtype     => 'date',
                    allowsort     => 1,
                    datetimeformat => ['MEDIUM',''],
                    optiongroup   => 'transactions',
                    dbfield       => 'TL.dtSettlement',
                    allowgrouping => 1,
                    sortfield     => 'TL.dtSettlement'
                }
              ],
              dtStart => [
                ( $SystemConfig->{'AllowTXNrpts'} ? $lang->txt('Start Date') : '' ),
                {
                    displaytype => 'date',
                    fieldtype   => 'datetime',
                    allowsort   => 1,
                    datetimeformat => ['MEDIUM',''],
                    optiongroup => 'transactions',
                    dbfield     => 'TX.dtStart'
                }
              ],
              dtEnd => [
                ( $SystemConfig->{'AllowTXNrpts'} ? $lang->txt('End Date') : '' ),
                {
                    displaytype => 'date',
                    fieldtype   => 'datetime',
                    allowsort   => 1,
                    datetimeformat => ['MEDIUM',''],
                    optiongroup => 'transactions',
                    dbfield     => 'TX.dtEnd'
                }
              ],
              intTransStatusID => [
                $SystemConfig->{'AllowTXNrpts'} ? $lang->txt('Transaction Status') : '',
                {
                    displaytype     => 'lookup',
                    fieldtype       => 'dropdown',
                    dropdownoptions => \%Defs::TransactionStatus,
                    allowsort       => 1,
                    optiongroup     => 'transactions',
                    dbfield         => 'TX.intStatus'
                }
              ],
              strTransNotes => [
                $SystemConfig->{'AllowTXNrpts'} ? $lang->txt('Transaction Notes') : '',
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    optiongroup => 'transactions',
                    dbfield     => 'TX.strNotes'
                }
              ],
              strTLNotes => [
                $SystemConfig->{'AllowTXNrpts'} ? $lang->txt('Payment Record Notes') : '',
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    optiongroup => 'transactions',
                    dbfield     => 'TL.strComments'
                }
              ],
              EntityPaymentID => [
                $SystemConfig->{'AllowTXNrpts'}
                ? qq[$Data->{'LevelNames'}{$Defs::LEVEL_CLUB} Payment for]
                : '',
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    optiongroup => 'transactions',
                    dbfield     => 'PaymentEntity.strLocalName',
                    dbfrom =>
"LEFT JOIN tblEntity as PaymentEntity ON (PaymentEntity.intEntityID =intEntityPaymentID)"
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
              strNationalNum
              PstrImportCode
              PstrStatus
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

                PRintOriginLevel
                PRstrPersonType 
                PRstrPersonLevel
                PRstrAgeLevel
                PRstrPersonEntityRole
                PRstrStatus
                PRstrSport
                PRintNationalPeriodID
                PRdtFrom
                PRdtTo
                PRstrRegistrationNature
                PRintPaymentRequired
                PRintOnLoan
                PRintIsLoanedOut
                PRstrLocalName

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
              intTransactionID
              intProductNationalPeriodID
              intProductID
              strGroup
              intQty
              curAmount
              dtTransaction
              intTransStatusID
              strTransNotes
              strTLNotes
              intLogID
                intTransLogStatusID
              payment_type
              TLstrReceiptRef
              strTXN
              strOnlinePayReference
              intAmount
              dtPaid
              dtSettlement
              dtStart
              dtEnd
              EntityPaymentID
              strMemberRecordTypeList
              dtMemberRecordIn
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
            regos=> [ $lang->txt('Registrations'),  {} ],
            contactdetails  => [ $lang->txt('Contact Details'),  {} ],
            identifications => [ $lang->txt('Identifications'),  {} ],
            financial       => [ $lang->txt('Financial'),        {} ],
            otherfields     => [ $lang->txt('Other Fields'),     {} ],
            affiliations    => [ $lang->txt('Affiliations'),     {} ],
            records         => [ $lang->txt('Member Records'),   {} ],
            transactions => [
                $txt_Transactions,
                {
                    from =>
"LEFT JOIN tblTransactions AS TX ON (TX.intStatus<>-1 AND NOT (TX.intStatus IN (0,-1)) AND tblPerson.intPersonID=TX.intID AND TX.intTableType =1 $txn_WHERE) LEFT JOIN tblTransLog as TL ON (TL.intLogID = TX.intTransLogID)",
                }
            ],
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

    my $products_join = '';
    if ( $from_list =~ /tblTransactions/ ) {
        $products_join = qq[ LEFT JOIN tblProducts as P ON (P.intProductID=TX.intProductID)];
    }

    $sql = qq[
        SELECT ###SELECT###
        FROM
            $from_levels
            $current_from
            $from_list
            $products_join
        WHERE
            $where_levels
            $where_list
            $current_where
            AND PR.intEntityID = $entityID
    ];
    return ( $sql, '' );
}

1;
# vim: set et sw=4 ts=4:
