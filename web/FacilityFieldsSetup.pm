package FacilityFieldsSetup;
require Exporter;
@ISA    = qw(Exporter);
@EXPORT = @EXPORT_OK = qw(
  facilityFieldsSetup
);

use strict;
use lib '.', '..', '../..';

use CGI qw(param);
use FieldLabels;
use Countries;
use Reg_common;
use FieldCaseRule;
use DefCodes;
use PersonLanguages;
use CustomFields;


sub facilityFieldsSetup {
    my ($Data, $values) = @_;
    $values ||= {};

    my $FieldLabels   = FieldLabels::getFieldLabels( $Data, $Defs::LEVEL_VENUE );
    my $isocountries  = getISOCountriesHash();
    my $field_case_rules = get_field_case_rules({
        dbh=>$Data->{'db'}, 
        client=>$Data->{'client'}, 
        type=>'Person'
    });

    my %facilityTypeOptions = ();
    my $facilityTypes = FacilityTypes::getAll($Data);
    for my $ft ( @{$facilityTypes} ) {
        $facilityTypeOptions{$ft->{'intFacilityTypeID'}} = $ft->{'strName'} || next;
    }

    my $facilityFieldCount = param('facilityFieldCount') || '';
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
    my ($DefCodes, $DefCodesOrder) = getDefCodes(
        dbh        => $Data->{'db'},
        realmID    => $Data->{'Realm'},
        subRealmID => $Data->{'RealmSubType'},
    );

    my %entityTypeOptions = ();
    for my $eType ( keys %Defs::entityType ) {
        next if !$eType;
        next if $eType eq $Defs::EntityType_WORLD_FEDERATION;
        next if $eType eq $Defs::EntityType_NATIONAL_ASSOCIATION;
        next if $eType eq $Defs::EntityType_REGIONAL_ASSOCIATION;
        $entityTypeOptions{$eType} = $Defs::entityType{$eType} || '';
    }

    my @intNatCustomLU_DefsCodes = (undef, -53, -54, -55, -64, -65, -66, -67, -68,-69,-70);
    my $CustomFieldNames = getCustomFieldNames( $Data, $Data->{'RealmSubType'}) || {};
    my $fieldsets = {
        core => {
            'fields' => {
                intFacilityTypeID => {
                    label       => $FieldLabels->{'intFacilityTypeID'},
                    value       => $values->{'intFacilityTypeID'},
                    type        => 'lookup',
                    options     => \%facilityTypeOptions,
                    firstoption => [ '', $Data->{'lang'}->txt('Select Type') ],
                    compulsory => 1,
                    sectionname => 'core',
                    class       => 'chzn-select',
                },
                strLocalName => {
                    label       => $FieldLabels->{'strLocalName'},
                    value       => $values->{'strLocalName'},
                    type        => 'text',
                    size        => '40',
                    maxsize     => '50',
                    compulsory  => 1,
                    sectionname => 'core',
                },
                strLocalShortName => {
                    label       => $FieldLabels->{'strLocalShortName'},
                    value       => $values->{'strLocalShortName'},
                    type        => 'text',
                    size        => '40',
                    maxsize     => '50',
                    sectionname => 'core',
                },
                strCity         => {
                    label       => $FieldLabels->{'strCity'},
                    value       => $values->{'strCity'} ||  $Data->{'SystemConfig'}{'DefaultCity'} || '',
                    type        => 'text',
                    size        => '30',
                    maxsize     => '45',
                    compulsory  => 1,
                    sectionname => 'core',
                },
                strRegion       => {
                    label       => $FieldLabels->{'strRegion'},
                    value       => $values->{'strRegion'},
                    type        => 'text',
                    size        => '30',
                    maxsize     => '45',
                    sectionname => 'core',
                },
                strISOCountry   => {
                    label       => $FieldLabels->{'strISOCountry'},
                    value       => $values->{'strISOCountry'} ||  $Data->{'SystemConfig'}{'DefaultCountry'} || '',
                    type        => 'lookup',
                    options     => $isocountries,
                    firstoption => [ '', $Data->{'lang'}->txt('Select Country') ],
                    compulsory => 1,
                    sectionname => 'core',
                    class       => 'chzn-select',
                },
                intLocalLanguage => {
                    label       => $FieldLabels->{'intLocalLanguage'},
                    value       => $values->{'intLocalLanguage'},
                    type        => 'lookup',
                    options     => \%languageOptions,
                    firstoption => [ '', $Data->{'lang'}->txt('Select Language') ],
                    compulsory => 1,
                    posttext => $nonlatinscript,
                    sectionname => 'core',
                    class       => 'chzn-select',
                },
                strLatinName    => {
                    label       => $Data->{'SystemConfig'}{'facility_strLatinNames'} || $FieldLabels->{'strLatinName'},
                    value       => $values->{'strLatinName'},
                    type        => 'text',
                    size        => '40',
                    maxsize     => '50',
                    active      => $nonLatin,
                    sectionname => 'core',
                },
                strLatinShortName => {
                    label       => $Data->{'SystemConfig'}{'facility_strLatinShortNames'} || $FieldLabels->{'strLatinShortName'},
                    value       => $values->{'strLatinShortName'},
                    type        => 'text',
                    size        => '40',
                    maxsize     => '50',
                    active      => $nonLatin,
                    sectionname => 'core',
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
                    
            },
            'order' => [qw(
                strLocalName
                strLocalShortName
                intLocalLanguage
                latinBlockStart
                strLatinName
                strLatinShortName
                latinBlockEnd
                intFacilityTypeID
                strCity
                strRegion
                strISOCountry
            )],
            sections => [
                [ 'core',        $Data->{'lang'}->txt('Venue Details'),'','',$values->{'footer-core'} ],
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
                strAddress  => {
                    label       => $FieldLabels->{'strAddress'},
                    value       => $values->{'strAddress'},
                    type        => 'text',
                    size        => '50',
                    maxsize     => '100',
                    sectionname => 'contactdetails',
                    compulsory  => 1,
                },
                strAddress2 => {
                    label       => $FieldLabels->{'strAddress2'},
                    value       => $values->{'strAddress2'},
                    type        => 'text',
                    size        => '50',
                    maxsize     => '100',
                    sectionname => 'contactdetails',
                },
                strContactCity  => {
                    label       => $FieldLabels->{'strContactCity'},
                    value       => $values->{'strContactCity'} ||  $Data->{'SystemConfig'}{'DefaultCity'} || '',
                    type        => 'text',
                    size        => '30',
                    maxsize     => '100',
                    sectionname => 'contactdetails',
                },
                strState => {
                    label       => $FieldLabels->{'strState'},
                    value       => $values->{'strState'},
                    type        => 'text',
                    size        => '50',
                    maxsize     => '100',
                    sectionname => 'contactdetails',
                },
                strPhone => {
                    label       => $FieldLabels->{'strPhone'},
                    value       => $values->{'strPhone'},
                    type        => 'text',
                    size        => '15',
                    maxsize     => '15',
                    sectionname => 'contactdetails',
                },
                strContactISOCountry   => {
                    label       => $FieldLabels->{'strContactISOCountry'},
                    value       => $values->{'strISOCountry'} ||  $Data->{'SystemConfig'}{'DefaultCountry'} || '',
                    type        => 'lookup',
                    options     => $isocountries,
                    firstoption => [ '', $Data->{'lang'}->txt('Select Country') ],
                    compulsory => 1,
                    class       => 'chzn-select',
                    sectionname => 'contactdetails',
                },
                strPostalCode => {
                    label       => $FieldLabels->{'strPostalCode'},
                    value       => $values->{'strPostalCode'},
                    type        => 'text',
                    size        => '50',
                    maxsize     => '100',
                    sectionname => 'contactdetails',
                },
                strEmail => {
                    label       => $FieldLabels->{'strEmail'},
                    value       => $values->{'strEmail'},
                    type        => 'text',
                    size        => '50',
                    maxsize     => '100',
                    validate    => 'EMAIL',
                    sectionname => 'contactdetails',
                },
                strContact=> {
                    label       => $FieldLabels->{'strContact'},
                    value       => $values->{'strContact'},
                    type        => 'text',
                    size        => '50',
                    maxsize     => '100',
                    compulsory  => 1,
                    sectionname => 'contactdetails',
                },
                strFax => {
                    label       => $FieldLabels->{'strFax'},
                    value       => $values->{'strFax'},
                    type        => 'text',
                    size        => '50',
                    maxsize     => '100',
                    sectionname => 'contactdetails',
                },
                strWebURL => {
                    label       => $FieldLabels->{'strWebURL'},
                    value       => $values->{'strWebURL'},
                    type        => 'text',
                    size        => '50',
                    maxsize     => '100',
                    validate    => 'URL',
                    sectionname => 'contactdetails',
                },
            },
            'order' => [qw(
                strAddress
                strAddress2
                strContactCity
                strState
                strPostalCode
                strContactISOCountry
                strEmail
                strPhone
                strFax
                strWebURL
            )],
            sections => [
                [ 'contactdetails',        $Data->{'lang'}->txt('Contact Details'),'','',$values->{'footer-contactdetails'} ],
            ],
            #fieldtransform => {
                #textcase => {
                    #strSuburb    => $field_case_rules->{'strSuburb'}    || '',
                #}
            #},
        },
        roledetails  => {
            'fields' => {
                intEntityFieldCount    => {
                    label       => $FieldLabels->{'intEntityFieldCount'} || 'fff',
                    value       => $facilityFieldCount,
                    type        => 'text',
                    size        => '50',
                    maxsize     => '100',
                    compulsory  => 1,
                    validate    => 'NUMBER',
                    sectionname => 'roledetails',
                },
            },
            'order' => [qw(
                intEntityFieldCount
            )],
            sections => [
                [ 'roledetails', $Data->{'lang'}->txt('Field Information'),'','',$values->{'footer-roledetails'} ],
            ],
        },
    };
    return $fieldsets;
}

1;
