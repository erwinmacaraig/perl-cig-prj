package PersonFieldsSetup;
require Exporter;
@ISA    = qw(Exporter);
@EXPORT = @EXPORT_OK = qw(
  personFieldsSetup
);

use strict;
use lib '.', '..', '../..', "../dashboard", "../user";

use CGI;
use FieldLabels;
use Countries;
use Reg_common;
use FieldCaseRule;
use PersonLanguages;
use CustomFields;
use DefCodes;
use PersonUtils;
use AssocTime;

sub personFieldsSetup {
    my ($Data, $values) = @_;
    $values ||= {};

    my $FieldLabels   = FieldLabels::getFieldLabels( $Data, $Defs::LEVEL_PERSON );
    my $isocountries  = getISOCountriesHash();
    my $isoHistoricalCountries  = getISOCountriesHash(historicalCountries => 1);
    my $field_case_rules = get_field_case_rules({
        dbh=>$Data->{'db'}, 
        client=>$Data->{'client'}, 
        type=>'Person'
    });

    my %genderoptions = ();
    for my $k ( keys %Defs::PersonGenderInfo ) {
        next if !$k;
        next if ( $Data->{'SystemConfig'}{'NoUnspecifiedGender'} and $k eq $Defs::GENDER_NONE );
        $genderoptions{$k} = $Defs::PersonGenderInfo{$k} || '';
    }

    my $languages = getPersonLanguages( $Data, 1, 0);
    my %languageOptions = ();
    my $nonLatin = 0;
    my @nonLatinLanguages =();
    for my $l ( @{$languages} ) {
        $languageOptions{$l->{'intLanguageID'}} = $l->{'language'} || next;
        if($l->{'intNonLatin'}) {
            $nonLatin = 1 ;
            push @nonLatinLanguages, $l->{'intLanguageID'};
        }
    }
    my $timezone = $Data->{'SystemConfig'}{'Timezone'} || 'UTC';
    my $today = dateatAssoc($timezone);
    my $nonlatinscript = '';
    if($nonLatin)   {
        my $vals = join(',',@nonLatinLanguages);
        $nonlatinscript =   qq[
           <script>
                jQuery(document).ready(function()  {
                    jQuery('#l_intLocalLanguage').change(function()   {
                        showLocalLanguage();
                    });
                    function showLocalLanguage()    {
                        var lang = parseInt(jQuery('#l_intLocalLanguage').val());
                        nonlatinvals = [$vals];
                        if(nonlatinvals.indexOf(lang) !== -1 )  {
                            jQuery('#block-latinnames').show();
                        }
                        else    {
                            jQuery('#block-latinnames').hide();
                        }
                    }
                    showLocalLanguage();
                });
            </script> 

        ];
    }

    my $maidennamescript = qq[
        <script>
            jQuery(document).ready(function()  {
                jQuery("select#l_intGender").change(function(){
                    showMaidenName();
                });
                function showMaidenName()   {
                    if(jQuery("#l_intGender").val() ==2)   {
                        jQuery("#l_row_strMaidenName").show();
                    } else {
                        jQuery("#l_row_strMaidenName").hide();
                    }
                }
                showMaidenName();
            });
        </script> 
    ];

    my ($minorComparisonDate_low, $minorComparisonDate_high)  = minorComparisonDate($Data);
    my $minorscript = qq[
        <script>
            jQuery(document).ready(function()  {
                jQuery("#l_dtDOB_year, #l_dtDOB_mon, #l_dtDOB_day").change(function(){
                    showMinorProtection();
                });
    
                function showMinorProtection()  {
                    var dob_y = jQuery("#l_dtDOB_year").val();
                    var dob_m = jQuery("#l_dtDOB_mon").val();
                    var dob_d = jQuery("#l_dtDOB_day").val();
                    var show = 0;
                    if(dob_y && dob_m && dob_d)  {
                        if(dob_m < 10) { dob_m = '0' + dob_m; }
                        if(dob_d < 10) { dob_d = '0' + dob_d; }
                        var dob = dob_y + '-' + dob_m + '-' + dob_d;
                        if(dob > '$minorComparisonDate_low'
                            && dob < '$minorComparisonDate_high')    {
                            show = 1;
                        }
                    }
                    if(show)    {
                        jQuery('#block-minor').show();
                    }
                    else    {
                        jQuery('#block-minor').hide();
                    }
                }
                showMinorProtection();
            });
        </script> 
    ];

    my $allowMinorProtection = 0;
    if($values->{'defaultType'} eq 'PLAYER')    {
        #minor protection only for player
        $allowMinorProtection = 1;
    }

    my ($DefCodes, $DefCodesOrder) = getDefCodes(
        dbh        => $Data->{'db'},
        realmID    => $Data->{'Realm'},
        subRealmID => $Data->{'RealmSubType'},
    );

    my @intNatCustomLU_DefsCodes = (undef, -53, -54, -55, -64, -65, -66, -67, -68,-69,-70);
    my $CustomFieldNames = getCustomFieldNames( $Data, $Data->{'RealmSubType'}) || {};
    my $fieldsets = {
        core => {
            'fields' => {
                strLocalFirstname => {
                    label       => $FieldLabels->{'strLocalFirstname'},
                    value       => $values->{'strLocalFirstname'},
                    type        => 'text',
                    size        => '40',
                    maxsize     => '50',
                    sectionname => 'core',
                    noedit      => 1,
                },
                strLocalSurname => {
                    label       => $Data->{'SystemConfig'}{'strLocalSurname_Text'} ? $Data->{'SystemConfig'}{'strLocalSurname_Text'} : $FieldLabels->{'strLocalSurname'},
                    value       => $values->{'strLocalSurname'},
                    type        => 'text',
                    size        => '40',
                    maxsize     => '50',
                    compulsory => 1,
                    sectionname => 'core',
                    noedit      => 1,
                },
                intGender => {
                    label       => $FieldLabels->{'intGender'},
                    value       => $values->{'intGender'},
                    type        => 'lookup',
                    options     => \%genderoptions,
                    class       => 'fcToggleGroup',
                    compulsory => 1,
                    firstoption => [ '', " " ],
                    sectionname => 'core',
                    noedit      => 1,
                },                
                intLocalLanguage => {
                    label       => $FieldLabels->{'intLocalLanguage'},
                    value       => $values->{'intLocalLanguage'},
                    type        => 'lookup',
                    options     => \%languageOptions,
                    firstoption => [ '', 'Select Language' ],
                    compulsory => 1,
                    posttext => $nonlatinscript,
                    sectionname => 'core',
                    class       => 'chzn-select',
                    noedit      => 1,
                },
                strLatinFirstname => {
                    label       => $Data->{'SystemConfig'}{'person_strLatinNames'} || $FieldLabels->{'strLatinFirstname'},
                    value       => $values->{'strLatinFirstname'},
                    type        => 'text',
                    size        => '40',
                    maxsize     => '50',
                    active      => $nonLatin,
                    sectionname => 'core',
                    noedit      => 1,
                },
                latinBlockStart => {
                    label       => 'latinblockstart',
                    value       => qq[<div id = "block-latinnames" class = "dynamic-panel">],
                    type        => 'htmlrow',
                    sectionname => 'core',
                    active      => $nonLatin,
                },
                latinBlockEnd => {
                    label       => 'latinblockend',
                    value       => qq[</div>],
                    type        => 'htmlrow',
                    sectionname => 'core',
                    active      => $nonLatin,
                },
                strLatinSurname => {
                    label       => $Data->{'SystemConfig'}{'person_strLatinNames'} || $FieldLabels->{'strLatinSurname'},
                    value       => $values->{'strLatinSurname'},
                    type        => 'text',
                    size        => '40',
                    maxsize     => '50',
                    active      => $nonLatin,
                    sectionname => 'core',
                    noedit      => 1,
                },
                strMaidenName => {
                    label       => $FieldLabels->{'strMaidenName'},
                    value       => $values->{'strMaidenName'},
                    type        => 'text',
                    size        => '40',
                    maxsize     => '50',
                    posttext    => $maidennamescript,
                    sectionname => 'core',
                    noedit      => 1,
                },
                dtDOB => {
                    label       => $FieldLabels->{'dtDOB'},
                    value       => $values->{'dtDOB'},
                    type        => 'date',
                    datetype    => 'dropdown',
                    format      => 'dd/mm/yyyy',
                    maxyear     => (localtime)[5] + 1900,
                    validate    => 'DATE,LESSTHAN:'.$today,
                    compulsory => 1,
                    sectionname => 'core',
                    noedit      => 1,
                },
                strISONationality => {
                    label       => $FieldLabels->{'strISONationality'},
                    value       => $values->{'strISONationality'} ||  $self->{'SystemConfig'}{'DefaultNationality'} || '',
                    type        => 'lookup',
                    options     => $isocountries,
                    firstoption => [ '', 'Select Country' ],
                    compulsory => 1,
                    class       => 'chzn-select',
                    sectionname => 'core',
                    noedit      => 1,
                },
                strISOCountryOfBirth => {
                    label       => $FieldLabels->{'strISOCountryOfBirth'},
                    value       => $values->{'strISOCountryOfBirth'} ||  $self->{'SystemConfig'}{'DefaultCountry'} || '',
                    type        => 'lookup',
                    options     => $isoHistoricalCountries,
                    firstoption => [ '', 'Select Country' ],
                    class       => 'chzn-select',
                    compulsory => 1,
                    sectionname => 'core',
                    noedit      => 1,
                },
                strRegionOfBirth => {
                    label       => $FieldLabels->{'strRegionOfBirth'},
                    value       => $values->{'strRegionOfBirth'},
                    type        => 'text',
                    size        => '30',
                    maxsize     => '45',
                    sectionname => 'core',
                    noedit      => 1,
                },
                strPlaceOfBirth => {
                    label       => $FieldLabels->{'strPlaceOfBirth'},
                    value       => $values->{'strPlaceOfBirth'},
                    type        => 'text',
                    size        => '30',
                    maxsize     => '45',
                    compulsory => 1,
                    sectionname => 'core',
                    noedit      => 1,
                },
                strPreferredLang => {
                    label       => $FieldLabels->{'strPreferredLang'},
                    value       => $values->{'strPreferredLang'},
                    type        => 'lookup',
                    options     => \%languageOptions,
                    firstoption => [ '', 'Select Language' ],
                    sectionname => 'other',
                },
                intEthnicityID => {
                    label       => $FieldLabels->{'intEthnicityID'},
                    value       => $values->{intEthnicityID},
                    type        => 'lookup',
                    options     => $DefCodes->{-8},
                    order       => $DefCodesOrder->{-8},
                    firstoption => [ '', " " ],
                    class       => 'chzn-select',
                    sectionname => 'other',
                },
                strBirthCert => {
        			label       => $FieldLabels->{'strBirthCert'},
                    value       => $values->{'strBirthCert'},
                    type        => 'text',
                    size        => '40',
                    maxsize     => '50',
                    sectionname => 'other',
        		},
        		strBirthCertCountry => {
        			label       => $FieldLabels->{'strBirthCertCountry'},
                    value       => $values->{'strBirthCertCountry'},
                    type        => 'lookup',
                    options     => $isoHistoricalCountries,
                    firstoption => [ '', 'Select Country' ],
                    compulsory => 1,
                    class       => 'chzn-select',
                    sectionname => 'other',
                  
        		},
        		dtBirthCertValidityDateFrom => {
        			label       => $FieldLabels->{'dtValidFrom'},
                    value       => $values->{'dtBirthCertValidityDateFrom'},
                    type        => 'date',
                    datetype    => 'dropdown',
                    format      => 'dd/mm/yyyy',
                    validate    => 'DATE',
                    sectionname => 'other',
        		},
        		dtBirthCertValidityDateTo => {
        			label       => $FieldLabels->{'dtValidUntil'},
                    value       => $values->{'dtBirthCertValidityDateTo'},
                    type        => 'date',
                    datetype    => 'dropdown',
                    format      => 'dd/mm/yyyy',
                    validate    => 'DATE',
                    sectionname => 'other',
        		},
        		strBirthCertDesc => {
        			label => $FieldLabels->{'strDescription'},
      	            value => $values->{'strBirthCertDesc'},
                    type => 'textarea',
                    rows => '10',
                    cols => '40',
                    sectionname => 'other',
        		},
        		strPassportNo => { 
                	label => $FieldLabels->{'strPassportNo'},
                	value => $values->{'strPassportNo'},
                	type => 'text',
                	size => '40',
                	maxsize => '50',
                    sectionname => 'other',
                },
                strPassportNationality => {
                	label => $FieldLabels->{'strPassportNationality'},
                	value => $values->{'strPassportNationality'},
                	type        => 'lookup',
                    options     => $isocountries,
                    firstoption => [ '', 'Select Country' ],
                    sectionname => 'other',
                    class       => 'chzn-select',
                },
                strPassportIssueCountry => {
                	label => $FieldLabels->{'strPassportIssueCountry'},
                	value => $values->{'strPassportIssueCountry'},
                	type        => 'lookup',
                    options     => $isocountries,
                    firstoption => [ '', 'Select Country' ],                	
                    sectionname => 'other',
                    class       => 'chzn-select',
                },
                dtPassportExpiry => {
                	label => $FieldLabels->{'dtPassportExpiry'},
                	value => $values->{'dtPassportExpiry'},
                	type        => 'date',
                    datetype    => 'dropdown',
                    format      => 'dd/mm/yyyy',
                    validate    => 'DATE',
                    minyear => '1980',
                    maxyear => (localtime)[5] + 1900 + 15,
                    sectionname => 'other',
                },
                strOtherPersonIdentifier => {
                	label => $FieldLabels->{'strOtherPersonIdentifier'},
                	value => $values->{'strOtherPersonIdentifier'},
                	type => 'text',
                	size => '40',
                	maxsize => '50',                	
                    sectionname => 'other',
                },
                strOtherPersonIdentifierIssueCountry => {
                	label => $FieldLabels->{'strOtherPersonIdentifierIssueCountry'},
                	value => $values->{'strOtherPersonIdentifierIssueCountry'},
                	type        => 'lookup',
                    options     => $isocountries,
                    firstoption => [ '', 'Select Country' ],
                    sectionname => 'other',
                    class       => 'chzn-select',
                },
                dtOtherPersonIdentifierValidDateFrom => {
                	label => $FieldLabels->{'dtValidFrom'},
                	value => $values->{'dtOtherPersonIdentifierValidDateFrom'},
                	type        => 'date',
                    datetype    => 'dropdown',
                    format      => 'dd/mm/yyyy',
                    validate    => 'DATE',
                    sectionname => 'other',
                },
                dtOtherPersonIdentifierValidDateTo => {
                	label => $FieldLabels->{'dtValidUntil'},
                	value => $values->{'dtOtherPersonIdentifierValidDateTo'},
                	type        => 'date',
                    datetype    => 'dropdown',
                    format      => 'dd/mm/yyyy',
                    validate    => 'DATE',
                    sectionname => 'other',
                },
                strOtherPersonIdentifierDesc => {
                	label => $FieldLabels->{'strDescription'},
                	value => $values->{'strOtherPersonIdentifierDesc'},
                    type => 'textarea',
                    rows => '10',
                    cols => '40',                	
                    sectionname => 'other',
                },
                 intOtherPersonIdentifierTypeID=> {
                    label => $FieldLabels->{'intOtherPersonIdentifierTypeID'},
                    value => $values->{'intOtherPersonIdentifierTypeID'},
                    type        => 'lookup',
                    options     => $DefCodes->{-20},
                    order       => $DefCodesOrder->{-20},
                    firstoption => [ '', " " ],
                    sectionname => 'other',
                },
               intMinorMoveOtherThanFootball => {
                    label => $FieldLabels->{'intMinorMoveOtherThanFootball'} || '',
                    value => $values->{'intMinorMoveOtherThanFootball'} || 0,
                    type  => 'checkbox',
                    displaylookup => { 1 => 'Yes', 0 => 'No' },
                    sectionname => 'core',
                    swapLabels => 1,
                    active => $allowMinorProtection,
                },
                intMinorDistance => {
                    label => $FieldLabels->{'intMinorDistance'} || '',
                    value => $values->{'intMinorDistance'} || 0,
                    type  => 'checkbox',
                    displaylookup => { 1 => 'Yes', 0 => 'No' },
                    sectionname => 'core',
                    swapLabels => 1,
                    active => $allowMinorProtection,
                },
                intMinorEU => {
                    label => $FieldLabels->{'intMinorEU'} || '',
                    value => $values->{'intMinorEU'} || 0,
                    type  => 'checkbox',
                    displaylookup => { 1 => 'Yes', 0 => 'No' },
                    sectionname => 'core',
                    swapLabels => 1,
                    active => $allowMinorProtection,
                },
                intMinorNone => {
                    label => $FieldLabels->{'intMinorNone'} || '',
                    value => $values->{'intMinorNone'} || 0,
                    type  => 'checkbox',
                    displaylookup => { 1 => 'Yes', 0 => 'No' },
                    sectionname => 'core',
                    posttext    => $minorscript,
                    swapLabels => 1,
                    active => $allowMinorProtection,
                },
                minorBlockStart => {
                    label       => 'minorblockstart',
                    value       => qq[<div id = "block-minor" class = "dynamic-panel">
                        <div class="form-group"> 
                            <label class = "col-md-4 control-label txtright"><span class="compulsory">*</span>FIFA Minor Protection</label>
                        </div>
                    ],
                    type        => 'htmlrow',
                    sectionname => 'core',
                    active => $allowMinorProtection,
                },
                minorBlockEnd => {
                    label       => 'minorblockend',
                    value       => qq[</div>],
                    type        => 'htmlrow',
                    sectionname => 'core',
                    active => $allowMinorProtection,
                },
 
            },
            'order' => [qw(
                strLocalSurname
                strLocalFirstname
                intLocalLanguage
                latinBlockStart
                strLatinSurname
                strLatinFirstname
                latinBlockEnd
                dtDOB

                minorBlockStart
                intMinorMoveOtherThanFootball
                intMinorDistance
                intMinorEU
                intMinorNone
                minorBlockEnd                

                intGender
                strMaidenName
                strISONationality
                strISOCountryOfBirth
                strRegionOfBirth
                strPlaceOfBirth



                strPreferredLang
                intEthnicityID                 
                strBirthCert 
                strBirthCertCountry 
                dtBirthCertValidityDateFrom 
                dtBirthCertValidityDateTo 
                strBirthCertDesc 
                strPassportNo
                strPassportNationality
                strPassportIssueCountry
                dtPassportExpiry
               
                intOtherPersonIdentifierTypeID
                strOtherPersonIdentifier
                strOtherPersonIdentifierIssueCountry
                dtOtherPersonIdentifierValidDateFrom
                dtOtherPersonIdentifierValidDateTo
                strOtherPersonIdentifierDesc

            )],
            sections => [
                [ 'core',        'Personal Details' ],
                [ 'minor',       'FIFA Minor Protection','','dynamic-panel' ],
                [ 'other',       'Additional Information' ],
            ],
            fieldtransform => {
                textcase => {
                    #strLocalFirstname => $field_case_rules->{'strLocalFirstname'} || '',
                    #strLocalSurname   => $field_case_rules->{'strLocalSurname'}   || '',
                }
            },
        },
        contactdetails => {
            'fields' => {
                strAddress1 => {
                    label       => $FieldLabels->{'strAddress1'},
                    value       => $values->{'strAddress1'},
                    type        => 'text',
                    size        => '50',
                    maxsize     => '100',
                },
                strAddress2 => {
                    label       => $FieldLabels->{'strAddress2'},
                    value       => $values->{'strAddress2'},
                    type        => 'text',
                    size        => '50',
                    maxsize     => '100',
                },
                strSuburb => {
                    label       => $FieldLabels->{'strSuburb'},
                    value       => $values->{'strSuburb'},
                    type        => 'text',
                    size        => '30',
                    maxsize     => '100',
                },
                strState => {
                    label       => $FieldLabels->{'strState'},
                    value       => $values->{'strState'},
                    type        => 'text',
                    size        => '50',
                    maxsize     => '100',
                },                
                strISOCountry => {
                    label       => $FieldLabels->{'strISOCountry'},
                    value       => $values->{'strISOCountry'} ||  $self->{'SystemConfig'}{'DefaultCountry'} || '',
                    type        => 'lookup',
                    options     => $isocountries,
                    firstoption => [ '', 'Select Country' ],
                    class       => 'chzn-select',
                },
                strPostalCode => {
                    label       => $FieldLabels->{'strPostalCode'},
                    value       => $values->{'strPostalCode'},
                    type        => 'text',
                    size        => '15',
                    maxsize     => '15',
                },
                strPhoneHome => {
                    label       => $FieldLabels->{'strPhoneHome'},
                    value       => $values->{'strPhoneHome'},
                    type        => 'text',
                    size        => '20',
                    maxsize     => '30',
                },
                strEmail => {
                    label       => $FieldLabels->{'strEmail'},
                    value       => $values->{strEmail},
                    type        => 'text',
                    size        => '50',
                    maxsize     => '200',
                    validate    => 'EMAIL',
                },

            },
            sections => [
                [ 'main',        'Contact Details' ],
            ],
            'order' => [qw(
                strAddress1
                strAddress2
                strSuburb
                strState
                strPostalCode
                strISOCountry
                strPhoneHome
                strEmail
            )],
            #fieldtransform => {
                #textcase => {
                    #strSuburb    => $field_case_rules->{'strSuburb'}    || '',
                #}
            #},
        },
        #otherdetails => {
            #'fields' => {
                #strPreferredLang => {
                    #label       => $FieldLabels->{'strPreferredLang'},
                    #value       => $values->{'strPreferredLang'},
                    #type        => 'lookup',
                    #options     => \%languageOptions,
                    #firstoption => [ '', 'Select Language' ],
                #},
                #intEthnicityID => {
                    #label       => $FieldLabels->{'intEthnicityID'},
                    #value       => $values->{intEthnicityID},
                    #type        => 'lookup',
                    #options     => $DefCodes->{-8},
                    #order       => $DefCodesOrder->{-8},
                    #firstoption => [ '', " " ],
                #},
                #strBirthCert => {
        			#label       => $FieldLabels->{'strBirthCert'},
                    #value       => $values->{'strBirthCert'},
                    #type        => 'text',
                    #size        => '40',
                    #maxsize     => '50',
        		#},
        		#strBirthCertCountry => {
#        			label       => $FieldLabels->{'strBirthCertCountry'},
#                    value       => $values->{'strBirthCertCountry'},
#                    type        => 'lookup',
#                    options     => $isocountries,
#                    firstoption => [ '', 'Select Country' ],
#                    compulsory => 1,
#                  
#        		},
#        		dtBirthCertValidityDateFrom => {
#        			label       => $FieldLabels->{'dtValidFrom'},
#                    value       => $values->{'dtBirthCertValidityDateFrom'},
#                    type        => 'date',
#                    datetype    => 'dropdown',
#                    format      => 'dd/mm/yyyy',
#                    validate    => 'DATE',
#        		},
#        		dtBirthCertValidityDateTo => {
#        			label       => $FieldLabels->{'dtValidUntil'},
#                    value       => $values->{'dtBirthCertValidityDateTo'},
#                    type        => 'date',
#                    datetype    => 'dropdown',
#                    format      => 'dd/mm/yyyy',
#                    validate    => 'DATE',
#        		},
#        		strBirthCertDesc => {
#        			label => $FieldLabels->{'strDescription'},
#      	            value => $values->{'strBirthCertDesc'},
#                    type => 'textarea',
#                    rows => '10',
#                    cols => '40',
#        		},
#        		strPassportNo => { 
#                	label => $FieldLabels->{'strPassportNo'},
#                	value => $values->{'strPassportNo'},
#                	type => 'text',
#                	size => '40',
#                	maxsize => '50',
#                },
#                strPassportNationality => {
#                	label => $FieldLabels->{'strPassportNationality'},
#                	value => $values->{'strPassportNationality'},
#                	type        => 'lookup',
#                    options     => $isocountries,
#                    firstoption => [ '', 'Select Country' ],
#                    
#                },
#                strPassportIssueCountry => {
#                	label => $FieldLabels->{'strPassportIssueCountry'},
#                	value => $values->{'strPassportIssueCountry'},
#                	type        => 'lookup',
#                    options     => $isocountries,
#                    firstoption => [ '', 'Select Country' ],                	
#                },
#                dtPassportExpiry => {
#                	label => $FieldLabels->{'dtPassportExpiry'},
#                	value => $values->{'dtPassportExpiry'},
#                	type        => 'date',
#                    datetype    => 'dropdown',
#                    format      => 'dd/mm/yyyy',
#                    validate    => 'DATE',
#                },
#                strOtherPersonIdentifier => {
#                	label => $FieldLabels->{'strOtherPersonIdentifier'},
#                	value => $values->{'strOtherPersonIdentifier'},
#                	type => 'text',
#                	size => '40',
#                	maxsize => '50',                	
#                },
#                strOtherPersonIdentifierIssueCountry => {
#                	label => $FieldLabels->{'strOtherPersonIdentifierIssueCountry'},
#                	value => $values->{'strOtherPersonIdentifierIssueCountry'},
#                	type        => 'lookup',
#                    options     => $isocountries,
#                    firstoption => [ '', 'Select Country' ],
#                },
#                dtOtherPersonIdentifierValidDateFrom => {
#                	label => $FieldLabels->{'dtValidFrom'},
#                	value => $values->{'dtOtherPersonIdentifierValidDateFrom'},
#                	type        => 'date',
#                    datetype    => 'dropdown',
#                    format      => 'dd/mm/yyyy',
#                    validate    => 'DATE',
#                },
#                dtOtherPersonIdentifierValidDateTo => {
#                	label => $FieldLabels->{'dtValidUntil'},
#                	value => $values->{'dtOtherPersonIdentifierValidDateTo'},
#                	type        => 'date',
#                    datetype    => 'dropdown',
#                    format      => 'dd/mm/yyyy',
#                    validate    => 'DATE',
#                },
#                strOtherPersonIdentifierDesc => {
#                	label => $FieldLabels->{'strDescription'},
#                	value => $values->{'strOtherPersonIdentifierDesc'},
#                    type => 'textarea',
#                    rows => '10',
#                    cols => '40',                	
#                },
#                
#                
#            },
#            'order' => [qw(
#                strPreferredLang
#                intEthnicityID                 
#                strBirthCert 
#                strBirthCertCountry 
#                dtBirthCertValidityDateFrom 
#                dtBirthCertValidityDateTo 
#                strBirthCertDesc 
#                strPassportNationality
#                strPassportIssueCountry
#                dtPassportExpiry
#               
#                strOtherPersonIdentifier
#                strOtherPersonIdentifierIssueCountry
#                dtOtherPersonIdentifierValidDateFrom
#                dtOtherPersonIdentifierValidDateTo
#                strOtherPersonIdentifierDesc
#            )],
#        },
        certifications => {
            'fields' => {
                intCertificationTypeID => {
                    label       => $FieldLabels->{'intCertificationTypeID'},
                    value       => $values->{'intCertificationTypeID'},
                    type        => 'lookup',
                    options     => $values->{'certificationTypes'} || {},
                    firstoption => [ '', " " ],
                },
                dtValidFrom => {
                    label       => $FieldLabels->{'dtValidFrom'},
                    value       => $values->{'dtValidFrom'},
                    type        => 'date',
                    format      => 'yyyy-mm-dd',
                    validate    => 'DATE',
                },                
                dtValidUntil => {
                    label       => $FieldLabels->{'dtValidUntil'},
                    value       => $values->{'dtValidUntil'},
                    type        => 'date',
                    format      => 'yyyy-mm-dd',
                    validate    => 'DATE',
                },
                strDescription => {
                    label       => $FieldLabels->{'strDescription'},
                    value       => $values->{'strDescription'},
                    type        => 'text',
                    size        => '30',
                    maxsize     => '100',
                },
            },
            'order' => [qw(
                intCertificationTypeID
                dtValidFrom
                dtValidUntil
                strDescription
            )],
            sections => [
                [ 'main',        'Certifications' ],
            ],
        },
#        minor => {
#            'fields' => {
#                intMinorMoveOtherThanFootball => {
#                    label => $FieldLabels->{'intMinorMoveOtherThanFootball'} || '',
#                    value => $values->{'intMinorMoveOtherThanFootball'} || 0,
#                    type  => 'checkbox',
#                    displaylookup => { 1 => 'Yes', 0 => 'No' },
#                },
#                intMinorDistance => {
#                    label => $FieldLabels->{'intMinorDistance'} || '',
#                    value => $values->{'intMinorDistance'} || 0,
#                    type  => 'checkbox',
#                    displaylookup => { 1 => 'Yes', 0 => 'No' },
#                },
#                intMinorEU => {
#                    label => $FieldLabels->{'intMinorEU'} || '',
#                    value => $values->{'intMinorEU'} || 0,
#                    type  => 'checkbox',
#                    displaylookup => { 1 => 'Yes', 0 => 'No' },
#                },
#                intMinorNone => {
#                    label => $FieldLabels->{'intMinorNone'} || '',
#                    value => $values->{'intMinorNone'} || 0,
#                    type  => 'checkbox',
#                    displaylookup => { 1 => 'Yes', 0 => 'No' },
#                },
#            },
#            'order' => [qw(
#                intMinorMoveOtherThanFootball
#                intMinorDistance
#                intMinorEU
#                intMinorNone
#            )],
#        }
    };
    for my $i (1..10) {
        my $fieldname = "intNatCustomLU$i";
        my $name = $CustomFieldNames->{$fieldname}[0] || '';
        next if !$name;
        $fieldsets->{'core'}{'fields'}{$fieldname} = {
            label => $name,
            value => $values->{$fieldname},
            type  => 'lookup',
            options     => $DefCodes->{$intNatCustomLU_DefsCodes[$i]},
            order       => $DefCodesOrder->{$intNatCustomLU_DefsCodes[$i]},
            sectionname => 'other',
            class       => 'chzn-select',
            firstoption => [ '', " " ],
        };
        push @{$fieldsets->{'core'}{'order'}} , $fieldname;
    }

    return $fieldsets;
}

1;
