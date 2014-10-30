package Flow_FacilityBackend;

use strict;
use lib '.', '..', '../..', "../dashboard", "../user";
use Flow_BaseObj;
our @ISA =qw(Flow_BaseObj);

use TTTemplate;
use CGI;
use FieldLabels;
use EntityObj;
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
use RegistrationItem;
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
            'action' => 'p',
            'function' => 'display_products',
            'label'  => 'Products',
        },
        {
            'action' => 'role',
            'function' => 'display_role_details',
            'fieldset' => 'roledetails',
        },
        {
            'action' => 'roleu',
            'function' => 'validate_role_details',
            'fieldset' => 'roledetails',
        },
        {
            'action' => 'fld',
            'function' => 'display_fields',
            'label' => 'Fields'
        },
        {
            'action' => 'fldu',
            'function' => 'process_fields',
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
            'action' => 'd',
            'function' => 'display_documents',
            'label'  => 'Documents',
        },
        {
            'action' => 'du',
            'function' => 'process_documents',
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
    my $FieldLabels   = FieldLabels::getFieldLabels( $self->{'Data'}, $Defs::LEVEL_VENUE );
    my $isocountries  = getISOCountriesHash();
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
                    jQuery('#l_row_strLatinName').find('input').prop('disabled', true);
                    jQuery('#l_row_strLatinName').hide();
                    jQuery('#l_row_strLatinShortName').find('input').prop('disabled', true);
                    jQuery('#l_row_strLatinShortName').hide();
                    jQuery('#l_intLocalLanguage').change(function()   {
                        var lang = parseInt(jQuery('#l_intLocalLanguage').val());
                        nonlatinvals = [$vals];
                        if(nonlatinvals.indexOf(lang) !== -1 )  {
                            jQuery('#l_row_strLatinName').find('input').prop('disabled', false);
                            jQuery('#l_row_strLatinName').show();
                            jQuery('#l_row_strLatinShortName').find('input').prop('disabled', false);
                            jQuery('#l_row_strLatinShortName').show();
                        }
                        else    {
                            jQuery('#l_row_strLatinName').find('input').prop('disabled', true);
                            jQuery('#l_row_strLatinName').hide();
                            jQuery('#l_row_strLatinShortName').find('input').prop('disabled', true);
                            jQuery('#l_row_strLatinShortName').hide();
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
                },
                strLocalShortName => {
                    label       => $FieldLabels->{'strLocalShortName'},
                    value       => $values->{'strLocalShortName'},
                    type        => 'text',
                    size        => '40',
                    maxsize     => '50',
                },
                strCity         => {
                    label       => $FieldLabels->{'strCity'},
                    value       => $values->{'strCity'},
                    type        => 'text',
                    size        => '30',
                    maxsize     => '45',
                    compulsory  => 1,
                },
                strRegion       => {
                    label       => $FieldLabels->{'strRegion'},
                    value       => $values->{'strRegion'},
                    type        => 'text',
                    size        => '30',
                    maxsize     => '45',
                },
                strISOCountry   => {
                    label       => $FieldLabels->{'strISOCountry'},
                    value       => $values->{'strISOCountry'},
                    type        => 'lookup',
                    options     => $isocountries,
                    firstoption => [ '', 'Select Country' ],
                    compulsory => 1,
                },
                intLocalLanguage => {
                    label       => $FieldLabels->{'intLocalLanguage'},
                    value       => $values->{'intLocalLanguage'},
                    type        => 'lookup',
                    options     => \%languageOptions,
                    firstoption => [ '', 'Select Language' ],
                    compulsory => 1,
                    posttext => $nonlatinscript,
                },
                strLatinName    => {
                    label       => $self->{'SystemConfig'}{'facility_strLatinNames'} || $FieldLabels->{'strLatinName'},
                    value       => $values->{'strLatinName'},
                    type        => 'text',
                    size        => '40',
                    maxsize     => '50',
                    compulsory  => 1,
                    active      => $nonLatin,
                },
                strLatinShortName => {
                    label       => $self->{'SystemConfig'}{'facility_strLatinShortNames'} || $FieldLabels->{'strLatinShortName'},
                    value       => $values->{'strLatinShortName'},
                    type        => 'text',
                    size        => '40',
                    maxsize     => '50',
                    active      => $nonLatin,
                },
            },
            'order' => [qw(
                strLocalName
                strLocalShortName
                strCity
                strRegion
                strISOCountry
                intLocalLanguage
                strLatinName
                strLatinShortName
            )],
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
                    compulsory  => 1,
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
                    compulsory => 1,
                },
                strPostalCode => {
                    label       => $FieldLabels->{'strPostalCode'},
                    value       => $values->{'strPostalCode'},
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
                },
                strFax => {
                    label       => $FieldLabels->{'strFax'},
                    value       => $values->{'strFax'},
                    type        => 'text',
                    size        => '50',
                    maxsize     => '100',
                },
                strWebURL => {
                    label       => $FieldLabels->{'strWebURL'},
                    value       => $values->{'strWebURL'},
                    type        => 'text',
                    size        => '50',
                    maxsize     => '100',
                },
            },
            'order' => [qw(
                strAddress
                strAddress2
                strContactCity
                strState
                strPostalCode
                strContactISOCountry
                strPhone
                strEmail
                strFax
                strWebURL
            )],
            #fieldtransform => {
                #textcase => {
                    #strSuburb    => $field_case_rules->{'strSuburb'}    || '',
                #}
            #},
        },
    };
}

sub display_core_details { 
    my $self = shift;

    #my $fieldperms = $self->{'Data'}->{'Permissions'};
    #my $memperm = ProcessPermissions($fieldperms, $self->{'FieldSets'}{'core'}, 'Person',);
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

sub validate_core_details {
    my $self = shift;

    my $facilityData = {};
    ($facilityData, $self->{'RunDetails'}{'Errors'}) = $self->gatherFields();

    if($self->{'RunDetails'}{'Errors'} and scalar(@{$self->{'RunDetails'}{'Errors'}})) {
        #There are errors - reset where we are to go back to the form again
        $self->decrementCurrentProcessIndex();
        return ('',2);
    }

    my $authID = getID($self->{'ClientValues'}, $self->{'ClientValues'}{'authLevel'});
    my $entityID = getID($self->{'ClientValues'});

    my $id = $self->ID() || 0;
    my $facilityObj = new EntityObj(db => $self->{'db'}, ID => $id);
    $facilityObj->load();
    $facilityData->{'strStatus'} = $Defs::ENTITY_STATUS_PENDING;
    $facilityData->{'intRealmID'} = $self->{'Data'}{'Realm'};
    $facilityData->{'intEntityLevel'} = $Defs::LEVEL_VENUE;
    $facilityData->{'intCreatedByEntityID'} = $authID;
    $facilityObj->setValues($facilityData);

    $facilityObj->write();
    if($facilityObj->ID()){
        if(!$id)    { 
            $self->setID($facilityObj->ID()); 
            $self->addCarryField('newvenue',1);
        }
        #my $client = setClient($self->{'ClientValues'});
        #$self->addCarryField('client',$client);
        auditLog(
            $facilityObj->ID(),
            $self->{'Data'},
            'ADD',
            'VENUE',
        );

        my $st = qq[
            INSERT INTO tblEntityLinks (intParentEntityID, intChildEntityID)
            VALUES (?,?)
        ];
        my $query = $self->{'db'}->prepare($st);
        $query->execute($entityID, $facilityObj->ID());

        warn "POST VENUE ADD id " . $facilityObj->ID();
        warn "POST VENUE ADD entity id $entityID";
        $query->finish();
        createTempEntityStructure($self->{'Data'}); 
    }

    return ('',1);
}

sub display_contact_details {
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

sub validate_contact_details {
    my $self = shift;

    my $facilityData = {};
    ($facilityData, $self->{'RunDetails'}{'Errors'}) = $self->gatherFields();
    my $id = $self->ID() || 0;
    warn "CURRENT FACILITY ID $id";
    if(!$id){
        push @{$self->{'RunDetails'}{'Errors'}}, 'Invalid facility.';
    }
    if($self->{'RunDetails'}{'Errors'} and scalar(@{$self->{'RunDetails'}{'Errors'}})) {
        #There are errors - reset where we are to go back to the form again
        $self->decrementCurrentProcessIndex();
        return ('',2);
    }

    my $facilityObj = new EntityObj(db => $self->{'db'}, ID => $id);
    $facilityObj->load();
    $facilityObj->setValues($facilityData);

    $facilityObj->write();

    return ('',1);

}

sub display_role_details {
    my $pagedata = "drd";
    return ($pagedata,0);
}

sub validate_role_details {
    my $pagedata = "vrd";
    return ($pagedata,0);
}

sub display_fields {
    my $pagedata = "df";
    return ($pagedata,0);
}

sub process_fields {
    my $pagedata = "pf";
    return ($pagedata,0);
}

sub display_products { 
    my $self = shift;

    my $facilityID = $self->ID();
    my $entityID = getLastEntityID($self->{'ClientValues'}) || 0;
    my $entityLevel = getLastEntityLevel($self->{'ClientValues'}) || 0;
    my $originLevel = $self->{'ClientValues'}{'authLevel'} || 0;
    my $client = $self->{'Data'}->{'client'};

    warn "FACILITY ID $facilityID";
    warn "ENTITY ID $entityID";
    warn "ENTITY LEVEL $entityLevel";
    warn "ORIGIN LEVEL $originLevel";
    warn "CLIENT $client";
    #my $rego_ref = {};
    #my $content = '';
    #if($regoID) {
    #    my $valid =0;
    #    ($valid, $rego_ref) = validateRegoID(
    #        $self->{'Data'}, 
    #        $personID, 
    #        $regoID, 
    #        $entityID
    #    );
    #    $regoID = 0 if !$valid;
    #}

    #my $personObj = new PersonObj(db => $self->{'db'}, ID => $personID);
    #$personObj->load();
    #if($regoID) {
    #    my $nationality = $personObj->getValue('strISONationality') || ''; 
    #    $rego_ref->{'Nationality'} = $nationality;

    #    $content = displayRegoFlowProducts(
    #        $self->{'Data'}, 
    #        $regoID, 
    #        $client, 
    #        $entityLevel, 
    #        $originLevel, 
    #        $rego_ref, 
    #        $entityID, 
    #        $personID, 
    #        {},
    #        1,
    #    );
    #}
    #else    {
    #    push @{$self->{'RunDetails'}{'Errors'}}, $self->{'Lang'}->txt("Invalid Registration ID");
    #}
    #if($self->{'RunDetails'}{'Errors'} and scalar(@{$self->{'RunDetails'}{'Errors'}})) {
    #    #There are errors - reset where we are to go back to the form again
    #    $self->decrementCurrentProcessIndex();
    #    return ('',2);
    #}
    #my %PageData = (
    #    HiddenFields => $self->stringifyCarryField(),
    #    Target => $self->{'Data'}{'target'},
    #    Errors => $self->{'RunDetails'}{'Errors'} || [],
    #    Content => $content,
    #    #FlowSummary => buildSummaryData($self->{'Data'}, $personObj) || '',
    #    #FlowSummaryTemplate => 'registration/person_flow_summary.templ',
    #    Title => '',
    #    TextTop => '',
    #    TextBottom => '',
    #);
    #my $pagedata = $self->display(\%PageData);

    #exit;
    return (" ",1);

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

    my $personID = $self->ID();
    my $entityID = getLastEntityID($self->{'ClientValues'}) || 0;
    my $entityLevel = getLastEntityLevel($self->{'ClientValues'}) || 0;
    my $originLevel = $self->{'ClientValues'}{'authLevel'} || 0;
    my $regoID = $self->{'RunParams'}{'rID'} || 0;
    my $client = $self->{'Data'}->{'client'};
    my $rego_ref = {};
    if($regoID) {
        my $valid =0;
        ($valid, $rego_ref) = validateRegoID(
            $self->{'Data'}, 
            $personID, 
            $regoID, 
            $entityID
        );
        $regoID = 0 if !$valid;
    }

    my $txnIds = save_rego_products($self->{'Data'}, $regoID, $personID, $entityID, $entityLevel, $rego_ref, $self->{'RunParams'});
    $self->addCarryField('txnIds',$txnIds);

    return ('',1);
}

sub display_documents { 
    my $self = shift;

    my $facilityID = $self->ID();
    my $entityID = getLastEntityID($self->{'ClientValues'}) || 0;
    my $entityLevel = getLastEntityLevel($self->{'ClientValues'}) || 0;
    my $originLevel = $self->{'ClientValues'}{'authLevel'} || 0;
    my $entityRegisteringForLevel = getLastEntityLevel($self->{'ClientValues'}) || 0;
    my $client = $self->{'Data'}->{'client'};

    my $rego_ref = {};
    my $venue_documents = '';
    my $content = '';

    warn "DOCUMENT ORIGIN LEVEL $originLevel";
    if($facilityID) {
        $venue_documents = getRegistrationItems(
            $self->{'Data'},
            'ENTITY',
            'DOCUMENT',
            $originLevel,
            'NEW',
            $facilityID,
            $entityRegisteringForLevel,
            0,
            undef,
            $Defs::DOC_FOR_VENUES,
        );

        my $cl = setClient($self->{'Data'}->{'clientValues'}) || '';
        my %cv = getClient($cl);
        $cv{'venueID'} = $facilityID;
        $cv{'currentLevel'} = $Defs::LEVEL_VENUE;
        my $clm = setClient(\%cv);

        my %documentData = (
            target => $self->{'Data'}->{'target'},
            documents => $venue_documents,
            Lang => $self->{'Data'}->{'lang'},
            nextaction => 'VENUE_DOCS_u',
            client => $clm,
            venue => $facilityID,
        );
 
        $content = runTemplate($self->{'Data'}, \%documentData, 'entity/required_docs.templ') || '';  
        #warn "REGISTERING FOR $entityRegisteringForLevel";
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
        TextTop => $content,
        TextBottom => '',
    );

    my $pagedata = $self->display(\%PageData);

    return ($pagedata,0);

}

sub process_documents { 
    my $self = shift;

    return ('',1);
}

sub display_complete {

}
