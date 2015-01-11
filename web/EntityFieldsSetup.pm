package EntityFieldsSetup;
require Exporter;
@ISA    = qw(Exporter);
@EXPORT = @EXPORT_OK = qw(
  clubFieldsSetup
  entityFieldsSetup
);

use strict;
use lib '.', '..', '../..', "../dashboard", "../user";

use CGI;
use FieldLabels;
use Countries;
use Reg_common;
use FieldCaseRule;
use DefCodes;
use PersonLanguages;
use CustomFields;


sub clubFieldsSetup {
    my ($Data, $values) = @_;
    $values ||= {};

    my $FieldLabels   = FieldLabels::getFieldLabels( $Data, $Defs::LEVEL_CLUB );
    my $isocountries  = getISOCountriesHash();
    my %countriesonly = ();
    my %Mcountriesonly = ();

    my @limitCountriesArr = ();
    while(my($k,$c) = each(%{$isocountries})){
    	$countriesonly{$k} = $c;
    	if(@limitCountriesArr){
    		next if(grep(/^$k/, @limitCountriesArr));
    	}
    	$Mcountriesonly{$c} = $c;
    }

    my $dissDateReadOnly = 0;

    if ($Data->{'SystemConfig'}{'Entity_EditDissolutionDateMinLevel'} && $Data->{'SystemConfig'}{'Entity_EditDissolutionDateMinLevel'} < $Data->{'clientValues'}{'authLevel'}){
        $dissDateReadOnly = 1; ### Allow us to set custom Level that can edit. ###
    }
    elsif ($Data->{'clientValues'}{'authLevel'} < $Defs::LEVEL_NATIONAL){
        $dissDateReadOnly = 1;
    }

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
    my $nonlatinscript = '';
    if($nonLatin)   {
        my $vals = join(',',@nonLatinLanguages);
        $nonlatinscript =   qq[
           <script>
                jQuery(document).ready(function()  {
                    jQuery('#l_intLocalLanguage').change(function()   {
                        showLocalLanguage();
                    });
                    showLocalLanguage();
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
                });
            </script> 

        ];
    }
    my ($DefCodes, $DefCodesOrder) = getDefCodes(
        dbh        => $Data->{'db'},
        realmID    => $Data->{'Realm'},
        subRealmID => $Data->{'RealmSubType'},
    );

    my @intNatCustomLU_DefsCodes = (undef, -53, -54, -55, -64, -65, -66, -67, -68,-69,-70);
    my $CustomFieldNames = getCustomFieldNames( $Data, $Data->{'RealmSubType'}) || {};

    my %legalTypeOptions = ();
    my $query = "SELECT strLegalType, intLegalTypeID FROM tblLegalType WHERE intRealmID IN (0,?)";
    my $sth = $Data->{'db'}->prepare($query);
    $sth->execute($Data->{'Realm'});
    while(my $href = $sth->fetchrow_hashref()){
        $legalTypeOptions{$href->{'intLegalTypeID'}} = $href->{'strLegalType'};
    }
    $sth->finish();

    my %entityTypeOptions = ();
    for my $eType ( keys %Defs::entityType ) {
        next if !$eType;
        next if $eType eq $Defs::EntityType_WORLD_FEDERATION;
        next if $eType eq $Defs::EntityType_NATIONAL_ASSOCIATION;
        next if $eType eq $Defs::EntityType_REGIONAL_ASSOCIATION;
        $entityTypeOptions{$eType} = $Defs::entityType{$eType} || '';
    }

    my %dissolvedOptions = (
        0 => 'No',
        1 => 'Yes',
    );

    $Data->{'FieldSets'} = {
        core => {
            'fields' => {
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
                dtFrom => {
                    label       => $FieldLabels->{'dtFrom'},
                    value       => $values->{'dtFrom'},
                    type        => 'date',
                    datetype    => 'dropdown',
                    format      => 'dd/mm/yyyy',
                    validate    => 'DATE',
                    maxyear     => (localtime)[5] + 1900,
                    compulsory => 1,
                    sectionname => 'core',
                    displayFunction => sub {$Data->{'l10n'}{'date'}->format(@_)},
                    displayFunctionParams=> ['MEDIUM'],
                },
                dissolved => {
                    label       => $FieldLabels->{'dissolved'},
                    value       => $values->{'dissolved'},
                    options     => \%dissolvedOptions,
                    type        => 'lookup',
                    sectionname => 'core',
                },
                dtTo => {
                    label       => $FieldLabels->{'dtTo'},
                    value       => $values->{'dtTo'},
                    type        => 'date',
                    datetype    => 'dropdown',
                    format      => 'dd/mm/yyyy',
                    validate    => 'DATE',
                    maxyear     => (localtime)[5] + 1900,
                    readonly    => $dissDateReadOnly,
                    sectionname => 'core',
                    displayFunction => sub {$Data->{'l10n'}{'date'}->format(@_)},
                    displayFunctionParams=> ['MEDIUM'],
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
                    value       => $values->{strISOCountry} ||  $Data->{'SystemConfig'}{'DefaultCountry'} || '',
                    type        => 'lookup',
                    options     => $isocountries,
                    firstoption => [ '', 'Select Country' ],
                    compulsory => 1,
                    sectionname => 'core',
                    class       => 'chzn-select',
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
                dtFrom
                dissolved
                dtTo
                strCity
                strRegion
                strISOCountry
            )],
            sections => [
                [ 'core',        'Club Details','','',$values->{'footer-core'} ],
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
                    compulsory  => 1,
                },
                strAddress2 => {
                    label       => $FieldLabels->{'strAddress2'},
                    value       => $values->{'strAddress2'},
                    type        => 'text',
                    size        => '50',
                    maxsize     => '100',
                },
                strContactCity  => {
                    label       => $FieldLabels->{'strContactCity'},
                    value       => $values->{'strContactCity'} || $Data->{'SystemConfig'}{'DefaultCity'} || '',
                    type        => 'text',
                    size        => '30',
                    maxsize     => '100',
                    compulsory  => 0,
                },
                strState => {
                    label       => $FieldLabels->{'strState'},
                    value       => $values->{'strState'},
                    type        => 'text',
                    size        => '50',
                    maxsize     => '100',
                },
                strPhone => {
                    label       => $FieldLabels->{'strPhone'},
                    value       => $values->{'strPhone'},
                    type        => 'text',
                    size        => '15',
                    maxsize     => '15',
                },
                strContactISOCountry   => {
                    label       => $FieldLabels->{'strContactISOCountry'},
                    value       => $values->{'strContactISOCountry'} ||  $Data->{'SystemConfig'}{'DefaultCountry'} || '',
                    type        => 'lookup',
                    options     => $isocountries,
                    firstoption => [ '', 'Select Country' ],
                    compulsory => 0,
                    class       => 'chzn-select',
                },
                strPostalCode => {
                    label       => $FieldLabels->{'strPostalCode'},
                    value       => $values->{'strPostalCode'},
                    type        => 'text',
                    size        => '50',
                    maxsize     => '100',
                },
                strContact=> {
                    label       => $FieldLabels->{'strContact'},
                    value       => $values->{'strContact'},
                    type        => 'text',
                    size        => '50',
                    maxsize     => '100',
                },
                strEmail => {
                    label       => $FieldLabels->{'strEmail'},
                    value       => $values->{'strEmail'},
                    type        => 'text',
                    size        => '50',
                    maxsize     => '100',
                    validate    => 'EMAIL',
                },
            },
            'order' => [qw(
                strAddress
                strAddress2
                strState
                strContactCity
                strPostalCode
                strContactISOCountry
                strContact
                strPhone
                strEmail
            )],
            sections => [
                [ 'main',        'Contact Details','','',$values->{'footer-contactdetails'} ],
            ],
            #fieldtransform => {
                #textcase => {
                    #strSuburb    => $field_case_rules->{'strSuburb'}    || '',
                #}
            #},
        },
        roledetails  => {
            'fields' => {
                strEntityType   => {
                    label       => $FieldLabels->{'strEntityType'},
                    value       => $values->{strEntityType} || '',
                    type        => 'lookup',
                    options     => \%entityTypeOptions,
                    firstoption => [ '', 'Select Type of Organisation' ],
                    compulsory => 1,
                },
                intLegalTypeID  => {
                    label       => $FieldLabels->{'intLegalTypeID'},
                    value       => $values->{'intLegalTypeID'},
                    type        => 'lookup',
                    options     => \%legalTypeOptions,
                    firstoption => [ '', 'Select Legal Entity Type' ],
                    compulsory  => 1,
                },
                strLegalID      => {
                    label       => $FieldLabels->{'strLegalID'},
                    value       => $values->{'strLegalID'},
                    type        => 'text',
                    size        => '40',
                    maxsize     => '45',
                    compulsory  => 1,
                },
                strDiscipline   => {
                    label       => $FieldLabels->{'strDiscipline'},
                    value       => $values->{'strDiscipline'},
                    type        => 'lookup',
                    options     => \%Defs::entitySportType,
                    firstoption => [ '', 'Select Sport' ],
                    compulsory  => 1,
                },
                strOrganisationLevel    => {
                    label       => $FieldLabels->{'strOrganisationLevel'},
                    value       => $values->{'strOrganisationLevel'},
                    type        => 'lookup',
                    options     => \%Defs::organisationLevel,
                    firstoption => [ '', 'Select Level' ],
                    compulsory  => 1,
                },
                strMANotes      => {
                    label       => $FieldLabels->{'strMANotes'},
                    value       => $values->{'strMANotes'},
                    type        => 'text',
                    size        => '50',
                    maxsize     => '100',
                    readonly    => $Data->{'clientValues'}{'authLevel'} < $Defs::LEVEL_NATIONAL ? 1 : 0,
                },
            },
            'order' => [qw(
                strEntityType
                intLegalTypeID
                strLegalID
                strDiscipline
                strOrganisationLevel
                strMANotes
            )],
            sections => [
                [ 'main',        'Organisation Details','','',$values->{'footer-roledetails'} ],
            ],
        },
    };
}

sub entityFieldsSetup {
    my ($Data, $values) = @_;
    $values ||= {};

    my $FieldLabels   = FieldLabels::getFieldLabels( $Data, $Defs::LEVEL_CLUB );
    my $isocountries  = getISOCountriesHash();
    my %countriesonly = ();
    my %Mcountriesonly = ();

    my @limitCountriesArr = ();
    while(my($k,$c) = each(%{$isocountries})){
    	$countriesonly{$k} = $c;
    	if(@limitCountriesArr){
    		next if(grep(/^$k/, @limitCountriesArr));
    	}
    	$Mcountriesonly{$c} = $c;
    }

    my $dissDateReadOnly = 0;

    if ($Data->{'SystemConfig'}{'Entity_EditDissolutionDateMinLevel'} && $Data->{'SystemConfig'}{'Entity_EditDissolutionDateMinLevel'} < $Data->{'clientValues'}{'authLevel'}){
        $dissDateReadOnly = 1; ### Allow us to set custom Level that can edit. ###
    }
    elsif ($Data->{'clientValues'}{'authLevel'} < $Defs::LEVEL_NATIONAL){
        $dissDateReadOnly = 1;
    }

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
    my $nonlatinscript = '';
    if($nonLatin)   {
        my $vals = join(',',@nonLatinLanguages);
        $nonlatinscript =   qq[
           <script>
                jQuery(document).ready(function()  {
                    jQuery('#l_intLocalLanguage').change(function()   {
                        showLocalLanguage();
                    });
                    showLocalLanguage();
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
                });
            </script> 

        ];
    }
    my ($DefCodes, $DefCodesOrder) = getDefCodes(
        dbh        => $Data->{'db'},
        realmID    => $Data->{'Realm'},
        subRealmID => $Data->{'RealmSubType'},
    );

    my @intNatCustomLU_DefsCodes = (undef, -53, -54, -55, -64, -65, -66, -67, -68,-69,-70);
    my $CustomFieldNames = getCustomFieldNames( $Data, $Data->{'RealmSubType'}) || {};

    my %legalTypeOptions = ();
    my $query = "SELECT strLegalType, intLegalTypeID FROM tblLegalType WHERE intRealmID IN (0,?)";
    my $sth = $Data->{'db'}->prepare($query);
    $sth->execute($Data->{'Realm'});
    while(my $href = $sth->fetchrow_hashref()){
        $legalTypeOptions{$href->{'intLegalTypeID'}} = $href->{'strLegalType'};
    }
    $sth->finish();

    my %entityTypeOptions = ();
    for my $eType ( keys %Defs::entityType ) {
        next if !$eType;
        next if $eType eq $Defs::EntityType_WORLD_FEDERATION;
        next if $eType eq $Defs::EntityType_NATIONAL_ASSOCIATION;
        next if $eType eq $Defs::EntityType_REGIONAL_ASSOCIATION;
        $entityTypeOptions{$eType} = $Defs::entityType{$eType} || '';
    }

    my %organisationLevel = (
        PROFESSIONAL => 'Professional',
        AMATEUR => 'Amateur',
        BOTH => 'Both',
    );

    my %dissolvedOptions = (
        0 => 'No',
        1 => 'Yes',
    );

    $Data->{'FieldSets'} = {
        core => {
            'fields' => {
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
                dtFrom => {
                    label       => $FieldLabels->{'dtFrom'},
                    value       => $values->{'dtFrom'},
                    type        => 'date',
                    datetype    => 'dropdown',
                    format      => 'dd/mm/yyyy',
                    validate    => 'DATE',
                    maxyear     => (localtime)[5] + 1900,
                    compulsory => 1,
                    sectionname => 'core',
                    displayFunction => sub {$Data->{'l10n'}{'date'}->format(@_)},
                    displayFunctionParams=> ['MEDIUM'],
                },
                dissolved => {
                    label       => $FieldLabels->{'dissolved'},
                    value       => $values->{'dissolved'},
                    options     => \%dissolvedOptions,
                    type        => 'lookup',
                    sectionname => 'core',
                },
                dtTo => {
                    label       => $FieldLabels->{'dtTo'},
                    value       => $values->{'dtTo'},
                    type        => 'date',
                    datetype    => 'dropdown',
                    format      => 'dd/mm/yyyy',
                    validate    => 'DATE',
                    maxyear     => (localtime)[5] + 1900,
                    readonly    => $dissDateReadOnly,
                    sectionname => 'core',
                    displayFunction => sub {$Data->{'l10n'}{'date'}->format(@_)},
                    displayFunctionParams=> ['MEDIUM'],
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
                    value       => $values->{strISOCountry} ||  $Data->{'SystemConfig'}{'DefaultCountry'} || '',
                    type        => 'lookup',
                    options     => \%Mcountriesonly,
                    firstoption => [ '', 'Select Country' ],
                    compulsory => 1,
                    sectionname => 'core',
                    class       => 'chzn-select',
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
                dtFrom
                dissolved
                dtTo
                strCity
                strRegion
                strISOCountry
            )],
            sections => [
                [ 'core',        'Details','','',$values->{'footer-core'} ],
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
                    compulsory  => 1,
                },
                strAddress2 => {
                    label       => $FieldLabels->{'strAddress2'},
                    value       => $values->{'strAddress2'},
                    type        => 'text',
                    size        => '50',
                    maxsize     => '100',
                },
                strContactCity  => {
                    label       => $FieldLabels->{'strContactCity'},
                    value       => $values->{'strContactCity'},
                    type        => 'text',
                    size        => '30',
                    maxsize     => '100',
                    compulsory  => 0,
                },
                strState => {
                    label       => $FieldLabels->{'strState'},
                    value       => $values->{'strState'},
                    type        => 'text',
                    size        => '50',
                    maxsize     => '100',
                },
                strPhone => {
                    label       => $FieldLabels->{'strPhone'},
                    value       => $values->{'strPhone'},
                    type        => 'text',
                    size        => '15',
                    maxsize     => '15',
                },
                strContactISOCountry   => {
                    label       => $FieldLabels->{'strContactISOCountry'},
                    value       => $values->{'strContactISOCountry'} ||  $Data->{'SystemConfig'}{'DefaultCountry'} || '',
                    type        => 'lookup',
                    options     => $isocountries,
                    firstoption => [ '', 'Select Country' ],
                    compulsory => 0,
                    class       => 'chzn-select',
                },
                strPostalCode => {
                    label       => $FieldLabels->{'strPostalCode'},
                    value       => $values->{'strPostalCode'},
                    type        => 'text',
                    size        => '50',
                    maxsize     => '100',
                },
                strContact=> {
                    label       => $FieldLabels->{'strContact'},
                    value       => $values->{'strContact'},
                    type        => 'text',
                    size        => '50',
                    maxsize     => '100',
                },
                strEmail => {
                    label       => $FieldLabels->{'strEmail'},
                    value       => $values->{'strEmail'},
                    type        => 'text',
                    size        => '50',
                    maxsize     => '100',
                    validate    => 'EMAIL',
                },
            },
            'order' => [qw(
                strAddress
                strAddress2
                strState
                strPostalCode
                strContact
                strContactCity
                strContactISOCountry
                strPhone
                strEmail
            )],
            sections => [
                [ 'main',        'Contact Details','','',$values->{'footer-contactdetails'} ],
            ],
            #fieldtransform => {
                #textcase => {
                    #strSuburb    => $field_case_rules->{'strSuburb'}    || '',
                #}
            #},
        },
    };
}


1;

1;
