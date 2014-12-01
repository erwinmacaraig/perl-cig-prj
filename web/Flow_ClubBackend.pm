package Flow_ClubBackend;

use strict;
use lib '.', '..', '../..', "../dashboard", "../user";
use Flow_BaseObj;
our @ISA =qw(Flow_BaseObj);

use TTTemplate;
use CGI;
use FieldLabels;
use EntityObj;
use EntityFields;
use EntityFieldObj;
use EntityStructure;
use ConfigOptions;
use InstanceOf;
use Countries;
use Reg_common;
use FieldCaseRule;
use WorkFlow;
use AuditLog;
use PersonLanguages;
use CustomFields;
use DefCodes;
use RegoProducts;
use RegistrationItem;
use PersonUserAccess;
use Data::Dumper;

sub setProcessOrder {
    my $self = shift;
  
    $self->{'ProcessOrder'} = [       
        {
            'action' => 'cd',
            'function' => 'display_core_details',
            'label'  => 'Core Details',
            'fieldset'  => 'core',
        },
        {
            'action' => 'cdu',
            'function' => 'validate_core_details',
            'fieldset'  => 'core',
        },
        {
            'action' => 'cond',
            'function' => 'display_contact_details',
            'label'  => 'Contact Details',
            'fieldset'  => 'contactdetails',
        },
        {
            'action' => 'condu',
            'function' => 'validate_contact_details',
            'fieldset'  => 'contactdetails',
        },
        {
            'action' => 'role',
            'function' => 'display_role_details',
            'label'  => 'Organisation Details',
            'fieldset' => 'roledetails',
        },
        {
            'action' => 'roleu',
            'function' => 'validate_role_details',
            'fieldset' => 'roledetails',
        },
        {
            'action' => 'd',
            'function' => 'display_documents',
            'label'  => 'Documents',
        },
        {
            'action' => 'du',
            'function' => 'process_documents',
        },
        {
            'action' => 'p',
            'function' => 'display_products',
            'label'  => 'Products',
        },
        {
            'action' => 'pu',
            'function' => 'process_products',
        },
        {
            'action' => 'c',
            'function' => 'display_complete',
            'label'  => 'Complete',
        },
    ];
}

sub setupValues {
    my $self = shift;
    my ($values) = @_;
    $values ||= {};

    #my $FieldLabels   = FieldLabels::getFieldLabels( $self->{'Data'}, $Defs::LEVEL_PERSON );
    my $FieldLabels   = FieldLabels::getFieldLabels( $self->{'Data'}, $Defs::LEVEL_CLUB );
    my $isocountries  = getISOCountriesHash();
    my %countriesonly = ();
    my %Mcountriesonly = ();

    my @limitCountriesArr = ();
    if($self->{'Data'}->{'RegoForm'} && $self->{'SystemConfig'}{'AllowedRegoCountries'}){
    	@limitCountriesArr = split(/\|/, $self->{'SystemConfig'}{'AllowedRegoCountries'} );
    }

    while(my($k,$c) = each(%{$isocountries})){
    	$countriesonly{$k} = $c;
    	if(@limitCountriesArr){
    		next if(grep(/^$k/, @limitCountriesArr));
    	}
    	$Mcountriesonly{$c} = $c;
    }

    my $dissDateReadOnly = 0;

    if ($self->{'SystemConfig'}{'Entity_EditDissolutionDateMinLevel'} && $self->{'SystemConfig'}{'Entity_EditDissolutionDateMinLevel'} < $self->{'ClientValues'}{'authLevel'}){
        $dissDateReadOnly = 1; ### Allow us to set custom Level that can edit. ###
    }
    elsif ($self->{'ClientValues'}{'authLevel'} < $Defs::LEVEL_NATIONAL){
        $dissDateReadOnly = 1;
    }

    my $field_case_rules = get_field_case_rules({
        dbh=>$self->{'db'}, 
        client=>$self->{'Data'}{'client'}, 
        type=>'Person'
    });

    my %genderoptions = ();
    for my $k ( keys %Defs::PersonGenderInfo ) {
        next if !$k;
        next if ( $self->{'SystemConfig'}{'NoUnspecifiedGender'} and $k eq $Defs::GENDER_NONE );
        $genderoptions{$k} = $Defs::PersonGenderInfo{$k} || '';
    }

    my $languages = getPersonLanguages( $self->{'Data'}, 1, 0);
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
                    jQuery('#fsg-latinnames').hide();
                    jQuery('#l_intLocalLanguage').change(function()   {
                        var lang = parseInt(jQuery('#l_intLocalLanguage').val());
                        nonlatinvals = [$vals];
                        if(nonlatinvals.indexOf(lang) !== -1 )  {
                            jQuery('#fsg-latinnames').show();
                        }
                        else    {
                            jQuery('#fsg-latinnames').hide();
                        }
                    });
                });
            </script> 

        ];
    }
    my ($DefCodes, $DefCodesOrder) = getDefCodes(
        dbh        => $self->{'Data'}{'db'},
        realmID    => $self->{'Data'}{'Realm'},
        subRealmID => $self->{'Data'}{'RealmSubType'},
    );

    my @intNatCustomLU_DefsCodes = (undef, -53, -54, -55, -64, -65, -66, -67, -68,-69,-70);
    my $CustomFieldNames = getCustomFieldNames( $self->{'Data'}, $self->{'Data'}{'RealmSubType'}) || {};

    my %legalTypeOptions = ();
    my $query = "SELECT strLegalType, intLegalTypeID FROM tblLegalType WHERE intRealmID IN (0,?)";
    my $sth = $self->{'db'}->prepare($query);
    $sth->execute($self->{'Data'}->{'Realm'});
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

    $self->{'FieldSets'} = {
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
                    sectionname => 'core2',
                },
                dissolved => {
                    label       => $FieldLabels->{'dissolved'},
                    value       => $values->{'dissolved'},
                    options     => \%dissolvedOptions,
                    type        => 'lookup',
                    sectionname => 'core2',
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
                    sectionname => 'core2',
                },
                strCity         => {
                    label       => $FieldLabels->{'strCity'},
                    value       => $values->{'strCity'},
                    type        => 'text',
                    size        => '30',
                    maxsize     => '45',
                    compulsory  => 1,
                    sectionname => 'core2',
                },
                strRegion       => {
                    label       => $FieldLabels->{'strRegion'},
                    value       => $values->{'strRegion'},
                    type        => 'text',
                    size        => '30',
                    maxsize     => '45',
                    sectionname => 'core2',
                },
                strISOCountry   => {
                    label       => $FieldLabels->{'strISOCountry'},
                    value       => $values->{strISOCountry} ||  $self->{'SystemConfig'}{'DefaultCountry'} || '',
                    type        => 'lookup',
                    options     => \%Mcountriesonly,
                    firstoption => [ '', 'Select Country' ],
                    compulsory => 1,
                    sectionname => 'core2',
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
                    label       => $self->{'SystemConfig'}{'facility_strLatinNames'} || $FieldLabels->{'strLatinName'},
                    value       => $values->{'strLatinName'},
                    type        => 'text',
                    size        => '40',
                    maxsize     => '50',
                    active      => $nonLatin,
                    sectionname => 'latinnames',
                },
                strLatinShortName => {
                    label       => $self->{'SystemConfig'}{'facility_strLatinShortNames'} || $FieldLabels->{'strLatinShortName'},
                    value       => $values->{'strLatinShortName'},
                    type        => 'text',
                    size        => '40',
                    maxsize     => '50',
                    active      => $nonLatin,
                    sectionname => 'latinnames',
                },
            },
            'order' => [qw(
                strLocalName
                strLocalShortName
                intLocalLanguage
                strLatinName
                strLatinShortName
                dtFrom
                dissolved
                dtTo
                strCity
                strRegion
                strISOCountry
            )],
            sections => [
                [ 'core',        '' ],
                [ 'latinnames',   '','','dynamic-panel'],
                [ 'core2',        '' ],
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
                    value       => $values->{'strContactISOCountry'},
                    type        => 'lookup',
                    options     => $isocountries,
                    firstoption => [ '', 'Select Country' ],
                    compulsory => 0,
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
                    options     => \%organisationLevel,
                    firstoption => [ '', 'Select Level' ],
                    compulsory  => 1,
                },
                strMANotes      => {
                    label       => $FieldLabels->{'strMANotes'},
                    value       => $values->{'strMANotes'},
                    type        => 'text',
                    size        => '50',
                    maxsize     => '100',
                    readonly    => $self->{'ClientValues'}{'authLevel'} < $Defs::LEVEL_NATIONAL ? 1 : 0,
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
        },
    };
}

sub display_core_details { 
    my $self = shift;

    my $clubperm = ProcessPermissions($self->{'Data'}->{'Permissions'}, $self->{'FieldSets'}{'core'}, 'Club',);

    my $id = $self->ID() || 0;
    if($id)   {
        my $clubObj = new EntityObj(db => $self->{'db'}, ID => $id, cache => $self->{'Data'}{'cache'});
        $clubObj->load();
        if($clubObj->ID())    {
            my $objectValues = $self->loadObjectValues($clubObj);
            $self->setupValues($objectValues);
        }
        if(!doesUserHaveEntityAccess($self->{'Data'}, $id,'WRITE')) {
            return ('Invalid User',0);
        }

    }
    my($fieldsContent, undef, $scriptContent, $tabs) = $self->displayFields($clubperm);

    my %PageData = (
        HiddenFields => $self->stringifyCarryField(),
        Target => $self->{'Data'}{'target'},
        Errors => $self->{'RunDetails'}{'Errors'} || [],
        Content => $fieldsContent || '',
        ScriptContent => $scriptContent || '',
        Title => '',
        TextTop => '',
        TextBottom => '',
    );

    my $pagedata = $self->display(\%PageData);

    return ($pagedata,0);

}

sub validate_core_details {
    my $self = shift;

    my $clubData = {};
    my $memperm = ProcessPermissions($self->{'Data'}->{'Permissions'}, $self->{'FieldSets'}{'core'}, 'Club',);
    ($clubData, $self->{'RunDetails'}{'Errors'}) = $self->gatherFields($memperm);


    if($self->{'RunDetails'}{'Errors'} and scalar(@{$self->{'RunDetails'}{'Errors'}})) {
        #There are errors - reset where we are to go back to the form again
        $self->decrementCurrentProcessIndex();
        return ('',2);
    }

    my $authID = getID($self->{'ClientValues'}, $self->{'ClientValues'}{'authLevel'});
    my $entityID = getID($self->{'ClientValues'});

    my $id = $self->ID() || 0;
    my $clubObj = new EntityObj(db => $self->{'db'}, ID => $id, cache => $self->{'Data'}{'cache'});
    $clubObj->load();
    if(!doesUserHaveEntityAccess($self->{'Data'}, $id,'WRITE')) {
        return ('Invalid User',0);
    }

    my $clubStatus = ($clubData->{'dissolved'}) ? $Defs::ENTITY_STATUS_DE_REGISTERED : $Defs::ENTITY_STATUS_PENDING;
    $clubData->{'strStatus'} = $clubStatus;
    $clubData->{'intRealmID'} = $self->{'Data'}{'Realm'};
    $clubData->{'intEntityLevel'} = $Defs::LEVEL_CLUB;
    $clubData->{'intCreatedByEntityID'} = $authID;
    $clubData->{'intDataAccess'} = $Defs::DATA_ACCESS_FULL;

    #delete dissolved value as it doesn't exist in tblEntity
    delete $clubData->{'dissolved'};
    $clubObj->setValues($clubData);

    $clubObj->write();
    if($clubObj->ID()){
        if(!$id)    { 
            $self->setID($clubObj->ID()); 
            $self->addCarryField('newclub',1);
            $self->addCarryField('newclubid', $clubObj->ID());
        }
        #my $client = setClient($self->{'ClientValues'});
        #$self->addCarryField('client',$client);
        auditLog(
            $clubObj->ID(),
            $self->{'Data'},
            'ADD',
            'CLUB',
        );

        my $st = qq[
            INSERT INTO tblEntityLinks (intParentEntityID, intChildEntityID)
            VALUES (?,?)
        ];
        my $query = $self->{'db'}->prepare($st);
        $query->execute($entityID, $clubObj->ID());

        $query->finish();
        createTempEntityStructure($self->{'Data'}); 
    }


    return ('',1);
}

sub display_contact_details {
    my $self = shift;
    my $id = $self->ID() || 0;
    if($id)   {
        my $clubObj = new EntityObj(db => $self->{'db'}, ID => $id, cache => $self->{'Data'}{'cache'});
        $clubObj->load();
        if($clubObj->ID())    {
            my $objectValues = $self->loadObjectValues($clubObj);
            $self->setupValues($objectValues);
        }
        if(!doesUserHaveEntityAccess($self->{'Data'}, $id,'WRITE')) {
            return ('Invalid User',0);
        }
    }

    my $clubperm = ProcessPermissions($self->{'Data'}->{'Permissions'}, $self->{'FieldSets'}{'contactdetails'}, 'Club',);
    my($fieldsContent, undef, $scriptContent, $tabs) = $self->displayFields($clubperm);
    my %PageData = (
        HiddenFields => $self->stringifyCarryField(),
        Target => $self->{'Data'}{'target'},
        Errors => $self->{'RunDetails'}{'Errors'} || [],
        Content => $fieldsContent || '',
        ScriptContent => $scriptContent || '',
        Title => '',
        TextTop => '',
        TextBottom => '',
    );

    my $pagedata = $self->display(\%PageData);

    return ($pagedata,0);
}

sub validate_contact_details {
    my $self = shift;

    my $clubData = {};
    my $clubperm = ProcessPermissions($self->{'Data'}->{'Permissions'}, $self->{'FieldSets'}{'contactdetails'}, 'Club',);
    ($clubData, $self->{'RunDetails'}{'Errors'}) = $self->gatherFields($clubperm);
    my $id = $self->ID() || 0;
    if(!doesUserHaveEntityAccess($self->{'Data'}, $id,'WRITE')) {
        return ('Invalid User',0);
    }
    if(!$id){
        push @{$self->{'RunDetails'}{'Errors'}}, 'Invalid club.';
    }
    if($self->{'RunDetails'}{'Errors'} and scalar(@{$self->{'RunDetails'}{'Errors'}})) {
        #There are errors - reset where we are to go back to the form again
        $self->decrementCurrentProcessIndex();
        return ('',2);
    }

    my $clubObj = new EntityObj(db => $self->{'db'}, ID => $id, cache => $self->{'Data'}{'cache'});
    $clubObj->load();
    $clubObj->setValues($clubData);

    $clubObj->write();

    return ('',1);

}

sub display_role_details {
    my $self = shift;

    my($fieldsContent, undef, $scriptContent, $tabs) = $self->displayFields();
    my %PageData = (
        HiddenFields => $self->stringifyCarryField(),
        Target => $self->{'Data'}{'target'},
        Errors => $self->{'RunDetails'}{'Errors'} || [],
        Content => $fieldsContent || '',
        ScriptContent => $scriptContent || '',
        Title => '',
        TextTop => '',
        TextBottom => '',
    );

    my $pagedata = $self->display(\%PageData);

    return ($pagedata,0);
}

sub validate_role_details {
    my $self = shift;

    my $clubData = {};
    my $memperm = ProcessPermissions($self->{'Data'}->{'Permissions'}, $self->{'FieldSets'}{'core'}, 'Club',);
    ($clubData, $self->{'RunDetails'}{'Errors'}) = $self->gatherFields($memperm);
    my $id = $self->ID() || 0;
    if(!doesUserHaveEntityAccess($self->{'Data'}, $id,'WRITE')) {
        return ('Invalid User',0);
    }
    #delete $clubData->{'strLevel'};
    if(!$id){
        push @{$self->{'RunDetails'}{'Errors'}}, 'Invalid club.';
    }
    if($self->{'RunDetails'}{'Errors'} and scalar(@{$self->{'RunDetails'}{'Errors'}})) {
        #There are errors - reset where we are to go back to the form again
        $self->decrementCurrentProcessIndex();
        return ('',2);
    }

    my $clubObj = new EntityObj(db => $self->{'db'}, ID => $id, cache => $self->{'Data'}{'cache'});
    $clubObj->load();
    $clubObj->setValues($clubData);

    $clubObj->write();

    return ('',1);
}

sub display_products { 
    my $self = shift;

    my $facilityID = $self->ID();
    my $entityID = getLastEntityID($self->{'ClientValues'}) || 0;
    my $entityLevel = getLastEntityLevel($self->{'ClientValues'}) || 0;
    my $originLevel = $self->{'ClientValues'}{'authLevel'} || 0;
    my $entityRegisteringForLevel = getLastEntityLevel($self->{'ClientValues'}) || 0;
    my $client = $self->{'Data'}->{'client'};
    my $content = '';

    my $CheckProducts = getRegistrationItems(
        $self->{'Data'},
        'ENTITY',
        'PRODUCT',
        $originLevel,
        'NEW',
        $entityID,
        $entityRegisteringForLevel,
        0,
        undef,
        undef,
    );

    my @prodIDs = ();
    my %ProductRules=();
    foreach my $product (@{$CheckProducts})  {
        #next if($product->{'UseExistingThisEntity'} && checkExistingProduct($Data, $product->{'ID'}, $Defs::LEVEL_PERSON, $personID, $entityID, 'THIS_ENTITY'));
        #next if($product->{'UseExistingAnyEntity'} && checkExistingProduct($Data, $product->{'ID'}, $Defs::LEVEL_PERSON, $personID, $entityID, 'ANY_ENTITY'));

        $product->{'HaveForAnyEntity'} =1 if($product->{'UseExistingAnyEntity'} && checkExistingProduct($self->{'Data'}, $product->{'ID'}, $Defs::LEVEL_VENUE, 0, $entityID, 'ANY_ENTITY'));
        $product->{'HaveForThisEntity'} =1 if($product->{'UseExistingThisEntity'} && checkExistingProduct($self->{'Data'}, $product->{'ID'}, $Defs::LEVEL_VENUE, 0, $entityID, 'THIS_ENTITY'));

        push @prodIDs, $product->{'ID'};
        $ProductRules{$product->{'ID'}} = $product;
     }
    my $product_body='';
    if (@prodIDs)   {
        $product_body= getRegoProducts($self->{'Data'}, \@prodIDs, 0, $entityID, 0, 0, 0, 0, \%ProductRules);
     }

     my %ProductPageData = (
         #nextaction=>"PREGF_PU",
        target => $self->{'Data'}->{'target'},
        product_body => $product_body,
        hidden_ref => {},
        Lang => $self->{'Data'}->{'lang'},
        client => $client,
        NoFormFields => 1,
    );
    $content = runTemplate($self->{'Data'}, \%ProductPageData, 'registration/product_flow_backend.templ') || '';

    my %PageData = (
        HiddenFields => $self->stringifyCarryField(),
        Target => $self->{'Data'}{'target'},
        Errors => $self->{'RunDetails'}{'Errors'} || [],
        Content => $content,
        FlowSummary => '',
        FlowSummaryTemplate => '',
        Title => '',
        TextTop => '',
        TextBottom => '',
    );
    my $pagedata = $self->display(\%PageData);

    return ($pagedata,0);
}

sub process_products { 
    my $self = shift;

    my @productsselected=();
    my @productsqty=();
    for my $k (keys %{$self->{'RunParams'}})  {
        if($k=~/prod_/) {
            if($self->{'RunParams'}{$k}==1)  {
                my $prod=$k;
                $prod=~s/[^\d]//g;
                push @productsselected, $prod;
            }
        }
        if($k=~/prodQTY_/) {
            if($self->{'RunParams'}{$k})  {
                my $prod=$k;
                $prod=~s/[^\d]//g;
                push @productsqty, "$prod-".$self->{'RunParams'}{$k};
            }
        }
    }
    my $prodQty= join(':',@productsqty);
    $self->addCarryField('prodQty',$prodQty);
    my $prodIds= join(':',@productsselected);
    $self->addCarryField('prodIds', $prodIds);

    my $entityID = getLastEntityID($self->{'ClientValues'}) || 0;
    my $entityLevel = getLastEntityLevel($self->{'ClientValues'}) || 0;
    my $originLevel = $self->{'ClientValues'}{'authLevel'} || 0;
    my $entityRegisteringForLevel = getLastEntityLevel($self->{'ClientValues'}) || 0;
    my $client = $self->{'Data'}->{'client'};
    my $rego_ref = {};

    my $txnIds = undef;
    my $CheckProducts = getRegistrationItems(
        $self->{'Data'},
        'ENTITY',
        'PRODUCT',
        $originLevel,
        'NEW',
        $entityID,
        $entityRegisteringForLevel,
        0,
        undef,
        undef,
    );

    my ($txns_added, $amount) = insertRegoTransaction($self->{'Data'}, 0, 0, $self->{'RunParams'}, $entityID, $entityLevel, 1, '', $CheckProducts);
    $txnIds = join(':',@{$txns_added});

    $self->addCarryField('txnIds',$txnIds);

    return ('',1);
}

sub display_documents { 
    my $self = shift;

    my $clubID = $self->ID();
    my $entityID = getLastEntityID($self->{'ClientValues'}) || 0;
    my $entityLevel = getLastEntityLevel($self->{'ClientValues'}) || 0;
    my $originLevel = $self->{'ClientValues'}{'authLevel'} || 0;
    my $entityRegisteringForLevel = getLastEntityLevel($self->{'ClientValues'}) || 0;
    my $client = $self->{'Data'}->{'client'};

    my $rego_ref = {};
    my $club_documents = '';
    my $content = '';

    if($clubID) {
        $club_documents = getRegistrationItems(
            $self->{'Data'},
            'ENTITY',
            'DOCUMENT',
            $originLevel,
            'NEW',
            $clubID,
            $entityRegisteringForLevel,
            0,
            undef,
            $Defs::DOC_FOR_CLUBS,
        );

        my $cl = setClient($self->{'Data'}->{'clientValues'}) || '';
        my %cv = getClient($cl);
        $cv{'clubID'} = $clubID;
        $cv{'currentLevel'} = $Defs::LEVEL_CLUB;
        my $clm = setClient(\%cv);

        my %documentData = (
            target => $self->{'Data'}->{'target'},
            documents => $club_documents,
            Lang => $self->{'Data'}->{'lang'},
            #nextaction => 'VENUE_DOCS_u',
            client => $clm,
            #venue => $facilityID,
        );
 
        $content = runTemplate($self->{'Data'}, \%documentData, 'club/required_docs.templ') || '';  
    }
    else    {
        push @{$self->{'RunDetails'}{'Errors'}}, $self->{'Lang'}->txt("Invalid Registration ID");
    }

    if($self->{'RunDetails'}{'Errors'} and scalar(@{$self->{'RunDetails'}{'Errors'}})) {
        #There are errors - reset where we are to go back to the form again
        $self->decrementCurrentProcessIndex();
        return ('',2);
    }

    my %PageData = (
        HiddenFields => $self->stringifyCarryField(),
        Target => $self->{'Data'}{'target'},
        Errors => $self->{'RunDetails'}{'Errors'} || [],
        #FlowSummary => buildSummaryData($self->{'Data'}, $personObj) || '',
        #FlowSummaryTemplate => 'registration/person_flow_summary.templ',
        Content => '',
        Title => '',
        TextTop => '',
        TextBottom => '',
        DocumentsLists => $content,
    );

    my $pagedata = $self->display(\%PageData);

    return ($pagedata,0);

}

sub process_documents { 
    my $self = shift;

    return ('',1);
}

sub display_complete {
    my $self = shift;

    my $id = $self->ID() || 0;
    my $entityID = getLastEntityID($self->{'ClientValues'}) || 0;
    my $entityLevel = getLastEntityLevel($self->{'ClientValues'}) || 0;
    my $originLevel = $self->{'ClientValues'}{'authLevel'} || 0;
    my $client = $self->{'Data'}->{'client'};

    my $clubObj = new EntityObj(db => $self->{'db'}, ID => $id, cache => $self->{'Data'}{'cache'});
    $clubObj->load();

    my $content = '';
    if($clubObj->ID()) {

        my $clubStatus = $clubObj->getValue('strStatus');

        if($self->{'RunParams'}{'newclub'})  {
            my $rc = WorkFlow::addWorkFlowTasks(
                $self->{'Data'},
                'ENTITY',
                'NEW',
                $self->{'ClientValues'}{'authLevel'} || 0,
                $clubObj->ID(),
                0,
                0,
                0,
            );
        }

        if($clubStatus eq $Defs::ENTITY_STATUS_DE_REGISTERED) {
            my $resetStatus = {};
            $resetStatus->{'strStatus'} = $clubStatus;

            $clubObj->setValues($resetStatus);
            $clubObj->write();
        }

        my $clubID = $clubObj->ID();
        $content = qq [<div class="col-md-9"><div class="alert"><div><span class="flash_success fa fa-check"></span><p>$self->{'Data'}->{'LevelNames'}{$Defs::LEVEL_CLUB} Added Successfully</p></div></div></div> ];
    }
    else {
        push @{$self->{'RunDetails'}{'Errors'}}, $self->{'Lang'}->txt("Invalid Club ID");
    }

    if($self->{'RunDetails'}{'Errors'} and scalar(@{$self->{'RunDetails'}{'Errors'}})) {
        #There are errors - reset where we are to go back to the form again
        $self->decrementCurrentProcessIndex();
        return ('',2);
    }

    my %PageData = (
        HiddenFields => $self->stringifyCarryField(),
        Target => $self->{'Data'}{'target'},
        Errors => $self->{'RunDetails'}{'Errors'} || [],
        Content => '',
        Title => '',
        TextTop => $content,
        TextBottom => '',
    );
    my $pagedata = $self->display(\%PageData);

    return ($pagedata,0);
}

sub loadObjectValues    {
    my $self = shift;
    my ($object) = @_;

    my %values = ();
    if($object) {
        for my $field (qw(
            strLocalName
            strLocalShortName
            intLocalLanguage
            strLatinName
            strLatinShortName
            dtFrom
            dissolved
            dtTo
            strCity
            strRegion
            strISOCountry

            strAddress
            strAddress2
            strContactCity
            strState
            strPostalCode
            strContactISOCountry
            strPhone
            strEmail
            strContact

            strEntityType
            intLegalTypeID
            strLegalID
            strDiscipline
            strOrganisationLevel
            strMANotes
        )) {
            $values{$field} = $object->getValue($field);
        }
    }
    return \%values;
}

