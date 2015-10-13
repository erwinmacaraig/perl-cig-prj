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
use MinorProtection;
use Flow_DisplayFields;
use TermsConditions;
use Data::Dumper;

sub personFieldsSetup {
    my ($Data, $values, $runParams) = @_;
    $values ||= {};
    $runParams ||= {};

    my $FieldLabels   = FieldLabels::getFieldLabels( $Data, $Defs::LEVEL_PERSON );
    my $isocountries  = getISOCountriesHash();
    my $isoHistoricalCountries  = getISOCountriesHash(historicalCountries => 1);
    my $field_case_rules = get_field_case_rules({
        dbh=>$Data->{'db'}, 
        client=>$Data->{'client'}, 
        type=>'Person'
    });

    my $dtLoanFromDate = _concatenateDate(
        $runParams->{'d_dtInternationalLoanFromDate_day'},
        $runParams->{'d_dtInternationalLoanFromDate_mon'},
        $runParams->{'d_dtInternationalLoanFromDate_year'},
    );

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
                jQuery("#l_dtDOB_year, #l_dtDOB_mon, #l_dtDOB_day,#l_strISONationality").change(function(){
                    showMinorProtection();
                });
    
                function showMinorProtection()  {
                    var dob_y = jQuery("#l_dtDOB_year").val();
                    var dob_m = jQuery("#l_dtDOB_mon").val();
                    var dob_d = jQuery("#l_dtDOB_day").val();
                    var nationality= jQuery("#l_strISONationality").val();
                    var show = 0;
                    var showITC = 0;
                    if(dob_y && dob_m && dob_d && (nationality != '$Data->{'SystemConfig'}{'DefaultNationality'}'))  {
                        if(dob_m < 10) { dob_m = '0' + dob_m; }
                        if(dob_d < 10) { dob_d = '0' + dob_d; }
                        var dob = dob_y + '-' + dob_m + '-' + dob_d;
                        if(dob > '$minorComparisonDate_low'
                            && dob < '$minorComparisonDate_high')    {
                            show = 1;
                        }
                        if(dob < '$minorComparisonDate_low')    {
                            showITC = 1;
                        }
                    }
                    if(show)    {
                        jQuery('#block-minor').show();
                    }
                    else    {
                        jQuery('#block-minor').hide();
                    }
                    if(showITC)    {
                        jQuery('#block-itc').show();
                    }
                    else    {
                        jQuery('#block-itc').hide();
                    }
                }
                showMinorProtection();
            });
        </script> 
    ];

    my $allowMinorProtection = 0;
    my $showITCReminder = 0;
    if($values->{'defaultType'} eq 'PLAYER')    {
        #minor protection only for player
        $allowMinorProtection = 1;
        $showITCReminder = 1;
    }
    $showITCReminder = 0 if $values->{'itc'};
    my $selfRego = $values->{'selfRego'} || 0;
    my $minorRego = $values->{'minorRego'} || 0;
    my $minorProtectionOptions = getMinorProtectionOptions($Data,$values->{'itc'} || 0);
    my $minorProtectionExplanation= getMinorProtectionExplanation($Data,$values->{'itc'} || 0);

    my $terms = '';
    if($selfRego)   {
        (undef, $terms) = getTerms($Data, 'SELFREG');
    }
    my ($DefCodes, $DefCodesOrder) = getDefCodes(
        dbh        => $Data->{'db'},
        realmID    => $Data->{'Realm'},
        subRealmID => $Data->{'RealmSubType'},
        locale     => $Data->{'lang'}->getLocale(),
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
                    #noedit      => 1,
                },
                strLocalSurname => {
                    label       => $Data->{'SystemConfig'}{'strLocalSurname_Text'} ? $Data->{'SystemConfig'}{'strLocalSurname_Text'} : $FieldLabels->{'strLocalSurname'},
                    value       => $values->{'strLocalSurname'},
                    type        => 'text',
                    size        => '40',
                    maxsize     => '50',
                    compulsory => 1,
                    sectionname => 'core',
                    #noedit      => 1,
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
                    #noedit      => 1,
                },                
                intLocalLanguage => {
                    label       => $FieldLabels->{'intLocalLanguage'},
                    value       => $values->{'intLocalLanguage'} || $Data->{'SystemConfig'}{'Default_NameLanguage'},
                    type        => 'lookup',
                    options     => \%languageOptions,
                    firstoption => [ '', $Data->{'lang'}->txt('Select Language') ],
                    compulsory => 1,
                    posttext => $nonlatinscript,
                    sectionname => 'core',
                    class       => 'chzn-select',
                    #noedit      => 1,
                },
                strLatinFirstname => {
                    label       => $Data->{'SystemConfig'}{'person_strLatinNames'} || $FieldLabels->{'strLatinFirstname'},
                    value       => $values->{'strLatinFirstname'},
                    type        => 'text',
                    size        => '40',
                    maxsize     => '50',
                    active      => $nonLatin,
                    sectionname => 'core',
                    #noedit      => 1,
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
                    #noedit      => 1,
                },
                strMaidenName => {
                    label       => $FieldLabels->{'strMaidenName'},
                    value       => $values->{'strMaidenName'},
                    type        => 'text',
                    size        => '40',
                    maxsize     => '50',
                    posttext    => $maidennamescript,
                    sectionname => 'core',
                    #noedit      => 1,
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
                    displayFunction => sub {$Data->{'l10n'}{'date'}->format(@_)},
                    displayFunctionParams=> ['MEDIUM'],
                    adddatecsvalidation => 1,

                    #noedit      => 1,
                },
                strISONationality => {
                    label       => $FieldLabels->{'strISONationality'},
                    value       => $values->{'strISONationality'} ||  $Data->{'SystemConfig'}{'DefaultNationality'} || '',
                    type        => 'lookup',
                    options     => $isocountries,
                    firstoption => [ '', $Data->{'lang'}->txt('Select Country') ],
                    compulsory => 1,
                    class       => 'chzn-select',
                    sectionname => 'core',
                    #noedit      => 1,
                },
                strISOCountryOfBirth => {
                    label       => $FieldLabels->{'strISOCountryOfBirth'},
                    value       => $values->{'strISOCountryOfBirth'} ||  $Data->{'SystemConfig'}{'DefaultCountry'} || '',
                    type        => 'lookup',
                    options     => $isoHistoricalCountries,
                    firstoption => [ '', $Data->{'lang'}->txt('Select Country') ],
                    class       => 'chzn-select',
                    compulsory => 1,
                    sectionname => 'core',
                    #noedit      => 1,
                },
                strRegionOfBirth => {
                    label       => $FieldLabels->{'strRegionOfBirth'},
                    value       => $values->{'strRegionOfBirth'},
                    type        => 'text',
                    size        => '30',
                    maxsize     => '45',
                    sectionname => 'core',
                    #noedit      => 1,
                },
                strPlaceOfBirth => {
                    label       => $FieldLabels->{'strPlaceOfBirth'},
                    value       => $values->{'strPlaceOfBirth'},
                    type        => 'text',
                    size        => '30',
                    maxsize     => '45',
                    compulsory => 1,
                    sectionname => 'core',
                    #noedit      => 1,
                },
                strPreferredLang => {
                    label       => $FieldLabels->{'strPreferredLang'},
                    value       => $values->{'strPreferredLang'},
                    type        => 'lookup',
                    options     => \%languageOptions,
                    firstoption => [ '', $Data->{'lang'}->txt('Select Language') ],
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
                    firstoption => [ '', $Data->{'lang'}->txt('Select Country') ],
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
                    displayFunction => sub {$Data->{'l10n'}{'date'}->format(@_)},
                    displayFunctionParams=> ['MEDIUM'],
        		},
        		dtBirthCertValidityDateTo => {
        			label       => $FieldLabels->{'dtValidUntil'},
                    value       => $values->{'dtBirthCertValidityDateTo'},
                    type        => 'date',
                    datetype    => 'dropdown',
                    format      => 'dd/mm/yyyy',
                    validate    => 'DATE',
                    sectionname => 'other',
                    displayFunction => sub {$Data->{'l10n'}{'date'}->format(@_)},
                    displayFunctionParams=> ['MEDIUM'],
        		},
        		strBirthCertDesc => {
        			label => $FieldLabels->{'strBirthCertDesc'},
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
                    firstoption => [ '', $Data->{'lang'}->txt('Select Country') ],
                    sectionname => 'other',
                    class       => 'chzn-select',
                },
                strPassportIssueCountry => {
                	label => $FieldLabels->{'strPassportIssueCountry'},
                	value => $values->{'strPassportIssueCountry'},
                	type        => 'lookup',
                    options     => $isocountries,
                    firstoption => [ '', $Data->{'lang'}->txt('Select Country') ],                	
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
                    displayFunction => sub {$Data->{'l10n'}{'date'}->format(@_)},
                    displayFunctionParams=> ['MEDIUM'],
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
                    firstoption => [ '', $Data->{'lang'}->txt('Select Country') ],
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
                    displayFunction => sub {$Data->{'l10n'}{'date'}->format(@_)},
                    displayFunctionParams=> ['MEDIUM'],
                },
                dtOtherPersonIdentifierValidDateTo => {
                	label => $FieldLabels->{'dtValidUntil'},
                	value => $values->{'dtOtherPersonIdentifierValidDateTo'},
                	type        => 'date',
                    datetype    => 'dropdown',
                    format      => 'dd/mm/yyyy',
                    validate    => 'DATE',
                    sectionname => 'other',
                    displayFunction => sub {$Data->{'l10n'}{'date'}->format(@_)},
                    displayFunctionParams=> ['MEDIUM'],
                },
                strOtherPersonIdentifierDesc => {
                	label => $FieldLabels->{'strOtherPersonIdentifierDesc'},
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
                    class       => 'chzn-select',
                },
                intMinorProtection => {
                    label => $FieldLabels->{'intMinorProtection'} || '',
                    value => $values->{'intMinorProtection'} || 0,
                    type        => 'lookup',
                    options     => $minorProtectionOptions,
                    firstoption => [ '', " " ],
                    sectionname => 'core',
                    class       => 'fcToggleGroup',
                    posttext    => $minorscript,
                    active => $allowMinorProtection,
                    compulsoryIfVisible => 'block-minor',
                },
                minorBlockStart => {
                    label       => 'minorblockstart',
                    value       => qq[<div id = "block-minor" class = "dynamic-panel">
                        <div class="form-group"> 
                            <div class="col-md-12">
                                <p>$minorProtectionExplanation</p>
                                <p>].$Data->{'lang'}->txt('You must choose one of the following options').qq[</p>
                            </div>
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
                ITCReminder => {
                    label       => 'itcreminder',
                    value       => qq[<div id = "block-itc" class = "ddynamic-panel">
                        <div class="form-group"> 
                            <div class="col-md-12">
                                <div class = "alert">
                                    <div><span class = "fa fa-info"></span>
                                <p>].$Data->{'lang'}->txt('If the player has been registered in another country before, you will need an ITC to continue with the registration.').qq[  <a href = "$values->{'BaseURL'}PRA_T">].$Data->{'lang'}->txt('If you have the ITC then please start the transfer process here.').qq[  <a href = "$values->{'BaseURL'}PRA_NC">].$Data->{'lang'}->txt("If you don't have an ITC you can request it here prior to the registration.").qq[</a></p>
                            </div> </div>
                            </div>
                        </div>
                    ],
                    type        => 'htmlrow',
                    sectionname => 'core',
                    active => $showITCReminder,
                },
                strInternationalTransferSourceClub => {
                	label => $FieldLabels->{'strInternationalTransferSourceClub'},
                	value => $values->{'strInternationalTransferSourceClub'},
                	type => 'text',
                	size => '40',
                	maxsize => '50',                	
                    sectionname => 'transfer',
                    compulsory => ($values->{'itc'} and $values->{'preqtype'} eq $Defs::PERSON_REQUEST_TRANSFER) ? 1 : 0,
                    active => ($values->{'itc'} and $values->{'preqtype'} eq $Defs::PERSON_REQUEST_TRANSFER) ? 1 : 0,
                },
                dtInternationalTransferDate => {
                	label => $FieldLabels->{'dtInternationalTransferDate'},
                	value => $values->{'dtInternationalTransferDate'},
                	type        => 'date',
                    datetype    => 'dropdown',
                    format      => 'dd/mm/yyyy',
                    validate    => 'DATE',
                    sectionname => 'transfer',
                    displayFunction => sub {$Data->{'l10n'}{'date'}->format(@_)},
                    displayFunctionParams=> ['MEDIUM'],
                    compulsory => ($values->{'itc'} and $values->{'preqtype'} eq $Defs::PERSON_REQUEST_TRANSFER) ? 1 : 0,
                    active => ($values->{'itc'} and $values->{'preqtype'} eq $Defs::PERSON_REQUEST_TRANSFER) ? 1 : 0,
                },
                strInternationalTransferTMSRef => {
                	label => $FieldLabels->{'strInternationalTransferTMSRef'},
                	value => $values->{'strInternationalTransferTMSRef'},
                	type => 'text',
                	size => '40',
                	maxsize => '50',                	
                    sectionname => 'transfer',
                    compulsory => ($values->{'itc'} and $values->{'preqtype'} eq $Defs::PERSON_REQUEST_TRANSFER) ? 1 : 0,
                    active => ($values->{'itc'} and $values->{'preqtype'} eq $Defs::PERSON_REQUEST_TRANSFER) ? 1 : 0,
                },
                strInternationalLoanSourceClub => {
                	label => $FieldLabels->{'strInternationalLoanSourceClub'},
                	value => $values->{'strInternationalLoanSourceClub'},
                	type => 'text',
                	size => '40',
                	maxsize => '50',                	
                    sectionname => 'loan',
                    compulsory => ($values->{'itc'} and $values->{'preqtype'} eq $Defs::PERSON_REQUEST_LOAN) ? 1 : 0,
                    active => ($values->{'itc'} and $values->{'preqtype'} eq $Defs::PERSON_REQUEST_LOAN) ? 1 : 0,
                },
                dtInternationalLoanFromDate => {
                	label => $FieldLabels->{'dtInternationalLoanFromDate'},
                	value => $values->{'dtInternationalLoanFromDate'},
                	type        => 'date',
                    datetype    => 'dropdown',
                    format      => 'dd/mm/yyyy',
                    validate    => 'DATE',
                    sectionname => 'loan',
                    displayFunction => sub {$Data->{'l10n'}{'date'}->format(@_)},
                    displayFunctionParams=> ['MEDIUM'],
                    compulsory => ($values->{'itc'} and $values->{'preqtype'} eq $Defs::PERSON_REQUEST_LOAN) ? 1 : 0,
                    active => ($values->{'itc'} and $values->{'preqtype'} eq $Defs::PERSON_REQUEST_LOAN) ? 1 : 0,
                    adddatecsvalidation => 1,
                },
                dtInternationalLoanToDate => {
                	label => $FieldLabels->{'dtInternationalLoanToDate'},
                	value => $values->{'dtInternationalLoanToDate'},
                	type        => 'date',
                    datetype    => 'dropdown',
                    format      => 'dd/mm/yyyy',
                    validate    => 'DATE,SS_DATEMORETHAN:' . $values->{'dtInternationalLoanFromDate'} . ',CS_DATEMORETHAN:' . 'dtInternationalLoanFromDate',
                    sectionname => 'loan',
                    displayFunction => sub {$Data->{'l10n'}{'date'}->format(@_)},
                    displayFunctionParams=> ['MEDIUM'],
                    compulsory => ($values->{'itc'} and $values->{'preqtype'} eq $Defs::PERSON_REQUEST_LOAN) ? 1 : 0,
                    active => ($values->{'itc'} and $values->{'preqtype'} eq $Defs::PERSON_REQUEST_LOAN) ? 1 : 0,
                    adddatecsvalidation => 1,
                },
                strInternationalLoanTMSRef => {
                	label => $FieldLabels->{'strInternationalLoanTMSRef'},
                	value => $values->{'strInternationalLoanTMSRef'},
                	type => 'text',
                	size => '40',
                	maxsize => '50',                	
                    sectionname => 'loan',
                    compulsory => ($values->{'itc'} and $values->{'preqtype'} eq $Defs::PERSON_REQUEST_LOAN) ? 1 : 0,
                    active => ($values->{'itc'} and $values->{'preqtype'} eq $Defs::PERSON_REQUEST_LOAN) ? 1 : 0,
                },
                parentBlock => {
                    label       => 'parentblock',
                    value       => qq[<p>].$Data->{'lang'}->txt('What is your relationship to the minor you are registering?').qq[</p>],
                    type        => 'htmlrow',
                    sectionname => 'parent',
                    active => $minorRego,
                },
                strP1FName => {
                    label       => $FieldLabels->{'strP1FName'},
                    value       => $values->{strP1FName},
                    type        => 'text',
                    size        => '30',
                    maxsize     => '50',
                    sectionname => 'parent',
                    active => $minorRego,
                },
                strP1SName => {
                    label       => $FieldLabels->{'strP1SName'},
                    value       => $values->{strP1SName},
                    type        => 'text',
                    size        => '30',
                    maxsize     => '50',
                    sectionname => 'parent',
                    active => $minorRego,
                },
                strGuardianRelationship => {
                    label       => $FieldLabels->{'strGuardianRelationship'},
                    value       => $values->{strGuardianRelationship},
                    type        => 'lookup',
                    options     => {'Parent'=>$Data->{'lang'}->txt('Parent'),'Legal Guardian' => $Data->{'lang'}->txt('Legal Guardian')},
                    firstoption => [ '', " " ],
                    class       => 'chzn-select',
                    sectionname => 'parent',
                    active => $minorRego,
                },
                strTerms => {
                    label       => 'You must agree to terms',
                    value       => qq[
<div class = "selfregterms">$terms</div>
<input type = "checkbox" value = "1" name = "d_strTerms" id = "l_strTerms"><label for = "l_strTerms">&nbsp;].$Data->{'lang'}->txt("I agree to the terms and conditions as specified above").qq[</label>],
                    type        => 'htmlrow',
                    compulsory => 1,
                    sectionname => 'terms',
                    SkipProcessing => 1,
                    active => $terms,
                },
            },
            'order' => [qw(
                parentBlock
                strGuardianRelationship
                strP1FName
                strP1SName

                strLocalSurname
                strLocalFirstname
                intLocalLanguage
                latinBlockStart
                strLatinSurname
                strLatinFirstname
                latinBlockEnd
                dtDOB


                intGender
                strMaidenName
                strISONationality
                strISOCountryOfBirth
                strRegionOfBirth
                strPlaceOfBirth

                minorBlockStart
                intMinorProtection
                minorBlockEnd                
                ITCReminder

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

                strInternationalTransferSourceClub
                dtInternationalTransferDate
                strInternationalTransferTMSRef

                strInternationalLoanSourceClub
                dtInternationalLoanFromDate
                dtInternationalLoanToDate
                strInternationalLoanTMSRef
strTerms
            )],
            sections => [
                [ 'parent',      $Data->{'lang'}->txt('Parent/Guardian Details') ],
                [ 'core',        $Data->{'lang'}->txt('Personal Details') ],
                [ 'minor',       $Data->{'lang'}->txt('FIFA Minor Protection'),'','dynamic-panel' ],
                [ 'other',       $Data->{'lang'}->txt('Additional Information') ],
                [ 'terms',       $Data->{'lang'}->txt('Terms and Conditions') ],
                [ 'loan',       $Data->{'lang'}->txt('Loan Information') ],
                [ 'transfer',       $Data->{'lang'}->txt('Transfer Information') ],
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
                    value       => $values->{'strISOCountry'} ||  $Data->{'SystemConfig'}{'DefaultCountry'} || '',
                    type        => 'lookup',
                    options     => $isocountries,
                    firstoption => [ '', $Data->{'lang'}->txt('Select Country') ],
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
                [ 'main',        $Data->{'lang'}->txt('Contact Details') ],
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
                    order       => $values->{'certificationTypesOrdered'},
                    firstoption => [ '', " " ],
                },
                dtValidFrom => {
                    label       => $FieldLabels->{'dtValidFrom'},
                    value       => $values->{'dtValidFrom'},
                    type        => 'date',
                    format      => 'yyyy-mm-dd',
                    validate    => 'DATE',
                    displayFunction => sub {$Data->{'l10n'}{'date'}->format(@_)},
                    displayFunctionParams=> ['MEDIUM'],
                    datetype    => 'dropdown',
                    maxyear => (localtime)[5] + 1900,
                },                
                dtValidUntil => {
                    label       => $FieldLabels->{'dtValidUntil'},
                    value       => $values->{'dtValidUntil'},
                    type        => 'date',
                    format      => 'yyyy-mm-dd',
                    validate    => 'DATE',
                    displayFunction => sub {$Data->{'l10n'}{'date'}->format(@_)},
                    displayFunctionParams=> ['MEDIUM'],
                    datetype    => 'dropdown',
                    maxyear => (localtime)[5] + 1900 + 15,
                },
                strDescription => {
                    label       => $FieldLabels->{'strDescription'},
                    value       => $values->{'strDescription'},
                    type        => 'text',
                    size        => '30',
                    maxsize     => '100',
                    displayFunction => sub {$Data->{'l10n'}{'date'}->format(@_)},
                    displayFunctionParams=> ['MEDIUM'],
                },
            },
            'order' => [qw(
                intCertificationTypeID
                dtValidFrom
                dtValidUntil
                strDescription
            )],
            sections => [
                [ 'main',        $Data->{'lang'}->txt('Add iiNew Certification') ],
            ],
        },
    };

    for my $i (1..15) {
        my $fieldname = "strNatCustomStr$i";
        my $name = $CustomFieldNames->{$fieldname}[0] || '';
        next if !$name;
        $fieldsets->{'core'}{'fields'}{$fieldname} = {
            label => $name,
            value => $values->{$fieldname},
            type => 'text',
            size => '40',
            maxsize => '50',
            sectionname => 'other',
        };
        push @{$fieldsets->{'core'}{'order'}} , $fieldname;
    }

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
    if($Data->{'SystemConfig'}{'NatCodeField'})  {
        my $fieldname = $Data->{'SystemConfig'}{'NatCodeField'}; 
        $fieldsets->{'core'}{'fields'}{$fieldname}{'validate'} = 'REMOTE';
        $fieldsets->{'core'}{'fields'}{$fieldname}{'validateData'} = {
                url => $Defs::base_url . '/ajax/aj_validate_natcode.cgi',
                otherfields => [
                        'dtDOB_year',
                        'dtDOB_mon',
                        'dtDOB_day',
                        'intGender',
                ],
                postvalues=> {
                        'f' => $fieldname,
                },

        };
    }

    return $fieldsets;
}

sub _concatenateDate {
    my ($day, $month, $year) = @_;

    $day = $day || q{};
    $month = $month || q{};
    $year = $year || q{};

    my $datevalue;
    my $displayField = new Flow_DisplayFields();

    if ( $day and $month and $year ) {
        $datevalue = "$day/$month/$year";
        $datevalue =  $displayField->_fix_date($datevalue);
    }

    return $datevalue || '';
}

1;
