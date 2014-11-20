package Flow_PersonBackend;

use strict;
use lib '.', '..', '../..', "../dashboard", "../user";
use Flow_BaseObj;
our @ISA =qw(Flow_BaseObj);

use TTTemplate;
use CGI;
use FieldLabels;
use PersonObj;
use PersonUtils;
use ConfigOptions;
use InstanceOf;
use Countries;
use PersonRegisterWhat;
use Reg_common;
use FieldCaseRule;
use WorkFlow;
use PersonRegistrationFlow_Common;
use AuditLog;
use PersonLanguages;
use CustomFields;
use DefCodes;
use PersonCertifications;
use DuplicatesUtils;
use PersonUserAccess;
use Data::Dumper;
use Payments;
use Products;


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
            'action' => 'minor',
            'function' => 'display_minor_fields',
            'label'  => 'Minor',
            'fieldset'  => 'minor',
            'NoNav'     => 1,
        },
        {
            'action' => 'minoru',
            'function' => 'validate_minor_fields',
            'fieldset'  => 'minor',
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
            'action' => 'od',
            'function' => 'display_other_details',
            'label'  => 'Other Details',
            'fieldset'  => 'otherdetails',
        },
        {
            'action' => 'odu',
            'function' => 'validate_other_details',
            'fieldset'  => 'otherdetails',
        },
        {
            'action' => 'r',
            'function' => 'display_registration',
            'label'  => 'Registration',
        },
        {
            'action' => 'ru',
            'function' => 'process_registration',
        },
        {
            'action' => 'cert',
            'function' => 'display_certifications',
            'label'  => 'Certifications',
            'fieldset'  => 'certifications',
        },
        {
            'action' => 'pcert',
            'function' => 'process_certifications',
            'fieldset'  => 'certifications',
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

sub setupValues    {
    my $self = shift;
    my ($values) = @_;
    $values ||= {};

    my $FieldLabels   = FieldLabels::getFieldLabels( $self->{'Data'}, $Defs::LEVEL_PERSON );
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
                \$(document).ready(function()  {
                    \$('#l_row_strLatinFirstname').hide();
                    \$('#l_row_strLatinSurname').hide();
                    \$('#l_intLocalLanguage').change(function()   {
                        var lang = parseInt(jQuery('#l_intLocalLanguage').val());
                        nonlatinvals = [$vals];
                        if(nonlatinvals.indexOf(lang) !== -1 )  {
                            \$('#l_row_strLatinFirstname').show();
                            \$('#l_row_strLatinSurname').show();
                        }
                        else    {
                            \$('#l_row_strLatinFirstname').hide();
                            \$('#l_row_strLatinSurname').hide();
                        }
                    });
                });
            </script> 

        ];
    }

    my $maidennamescript = qq[
        <script>
            jQuery(document).ready(function()  {
                jQuery('#l_row_strMaidenName').hide();

                jQuery("select#l_intGender").change(function(){
                    if(jQuery(this).val() == 2) {
                        jQuery("#l_row_strMaidenName").show();
                    } else {
                        jQuery("#l_row_strMaidenName").hide();
                    }
                });
            });
        </script> 
    ];


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
                strLocalFirstname => {
                    label       => $FieldLabels->{'strLocalFirstname'},
                    value       => $values->{'strLocalFirstname'},
                    type        => 'text',
                    size        => '40',
                    maxsize     => '50',
                    readonly    => $self->{'RunParams'}{'dtype'} eq 'TRANSFER' ? 1 : 0,
                },
                strLocalSurname => {
                    label       => $self->{'SystemConfig'}{'strLocalSurname_Text'} ? $self->{'SystemConfig'}{'strLocalSurname_Text'} : $FieldLabels->{'strLocalSurname'},
                    value       => $values->{'strLocalSurname'},
                    type        => 'text',
                    size        => '40',
                    maxsize     => '50',
                    compulsory => 1,
                    readonly    => $self->{'RunParams'}{'dtype'} eq 'TRANSFER' ? 1 : 0,
                },
                intGender => {
                    label       => $FieldLabels->{'intGender'},
                    value       => $values->{'intGender'},
                    type        => 'lookup',
                    options     => \%genderoptions,
                    compulsory => 1,
                    firstoption => [ '', " " ],
                    readonly    => $self->{'RunParams'}{'dtype'} eq 'TRANSFER' ? 1 : 0,
                },                
                intLocalLanguage => {
                    label       => $FieldLabels->{'intLocalLanguage'},
                    value       => $values->{'intLocalLanguage'},
                    type        => 'lookup',
                    options     => \%languageOptions,
                    firstoption => [ '', 'Select Language' ],
                    compulsory => 1,
                    posttext => $nonlatinscript,
                    readonly    => $self->{'RunParams'}{'dtype'} eq 'TRANSFER' ? 1 : 0,
                },
                strLatinFirstname => {
                    label       => $self->{'SystemConfig'}{'person_strLatinNames'} || $FieldLabels->{'strLatinFirstname'},
                    value       => $values->{'strLatinFirstname'},
                    type        => 'text',
                    size        => '40',
                    maxsize     => '50',
                    active      => $nonLatin,
                    readonly    => $self->{'RunParams'}{'dtype'} eq 'TRANSFER' ? 1 : 0,
                },
                strLatinSurname => {
                    label       => $self->{'SystemConfig'}{'person_strLatinNames'} || $FieldLabels->{'strLatinSurname'},
                    value       => $values->{'strLatinSurname'},
                    type        => 'text',
                    size        => '40',
                    maxsize     => '50',
                    active      => $nonLatin,
                    readonly    => $self->{'RunParams'}{'dtype'} eq 'TRANSFER' ? 1 : 0,
                },
                strMaidenName => {
                    label       => $FieldLabels->{'strMaidenName'},
                    value       => $values->{'strMaidenName'},
                    type        => 'text',
                    size        => '40',
                    maxsize     => '50',
                    posttext    => $maidennamescript,
                    readonly    => $self->{'RunParams'}{'dtype'} eq 'TRANSFER' ? 1 : 0,
                },
                dtDOB => {
                    label       => $FieldLabels->{'dtDOB'},
                    value       => $values->{'dtDOB'},
                    type        => 'date',
                    datetype    => 'dropdown',
                    format      => 'dd/mm/yyyy',
                    validate    => 'DATE',
                    compulsory => 1,
                    readonly    => $self->{'RunParams'}{'dtype'} eq 'TRANSFER' ? 1 : 0,
                },
                strISONationality => {
                    label       => $FieldLabels->{'strISONationality'},
                    value       => $values->{'strISONationality'},
                    type        => 'lookup',
                    options     => $isocountries,
                    firstoption => [ '', 'Select Country' ],
                    compulsory => 1,
                    readonly    => $self->{'RunParams'}{'dtype'} eq 'TRANSFER' ? 1 : 0,
                },
                strISOCountryOfBirth => {
                    label       => $FieldLabels->{'strISOCountryOfBirth'},
                    value       => $values->{'strISOCountryOfBirth'},
                    type        => 'lookup',
                    options     => $isocountries,
                    firstoption => [ '', 'Select Country' ],
                    compulsory => 1,
                    readonly    => $self->{'RunParams'}{'dtype'} eq 'TRANSFER' ? 1 : 0,
                },
                strRegionOfBirth => {
                    label       => $FieldLabels->{'strRegionOfBirth'},
                    value       => $values->{'strRegionOfBirth'},
                    type        => 'text',
                    size        => '30',
                    maxsize     => '45',
                    readonly    => $self->{'RunParams'}{'dtype'} eq 'TRANSFER' ? 1 : 0,
                },
                strPlaceOfBirth => {
                    label       => $FieldLabels->{'strPlaceOfBirth'},
                    value       => $values->{'strPlaceOfBirth'},
                    type        => 'text',
                    size        => '30',
                    maxsize     => '45',
                    compulsory => 1,
                    readonly    => $self->{'RunParams'}{'dtype'} eq 'TRANSFER' ? 1 : 0,
                },
                intGender => {
                    label       => $FieldLabels->{'intGender'},
                    value       => $values->{'intGender'},
                    type        => 'lookup',
                    options     => \%genderoptions,
                    compulsory => 1,
                    firstoption => [ '', " " ],
                    readonly    => $self->{'RunParams'}{'dtype'} eq 'TRANSFER' ? 1 : 0,
                },
            },
            'order' => [qw(
                strLocalFirstname
                strLocalSurname
                intLocalLanguage
                strLatinFirstname
                strLatinSurname
                dtDOB
                intGender
                strMaidenName
                strISONationality
                strISOCountryOfBirth
                strRegionOfBirth
                strPlaceOfBirth
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
            },
            'order' => [qw(
                strAddress1
                strAddress2
                strSuburb
                strState
                strPostalCode
                strPhoneHome
            )],
            #fieldtransform => {
                #textcase => {
                    #strSuburb    => $field_case_rules->{'strSuburb'}    || '',
                #}
            #},
        },
        otherdetails => {
            'fields' => {
                strPreferredLang => {
                    label       => $FieldLabels->{'strPreferredLang'},
                    value       => $values->{'strPreferredLang'},
                    type        => 'lookup',
                    options     => \%languageOptions,
                    firstoption => [ '', 'Select Language' ],
                },
                intEthnicityID => {
                    label       => $FieldLabels->{'intEthnicityID'},
                    value       => $values->{intEthnicityID},
                    type        => 'lookup',
                    options     => $DefCodes->{-8},
                    order       => $DefCodesOrder->{-8},
                    firstoption => [ '', " " ],
                },
                strBirthCert => {
        			label       => $FieldLabels->{'strBirthCert'},
                    value       => $values->{'strBirthCert'},
                    type        => 'text',
                    size        => '40',
                    maxsize     => '50',
        		},
        		strBirthCertCountry => {
        			label       => $FieldLabels->{'strBirthCertCountry'},
                    value       => $values->{'strBirthCertCountry'},
                    type        => 'lookup',
                    options     => $isocountries,
                    firstoption => [ '', 'Select Country' ],
                    compulsory => 1,
                  
        		},
        		dtBirthCertValidityDateFrom => {
        			label       => $FieldLabels->{'dtValidFrom'},
                    value       => $values->{'dtBirthCertValidityDateFrom'},
                    type        => 'date',
                    datetype    => 'dropdown',
                    format      => 'dd/mm/yyyy',
                    validate    => 'DATE',
        		},
        		dtBirthCertValidityDateTo => {
        			label       => $FieldLabels->{'dtValidUntil'},
                    value       => $values->{'dtBirthCertValidityDateTo'},
                    type        => 'date',
                    datetype    => 'dropdown',
                    format      => 'dd/mm/yyyy',
                    validate    => 'DATE',
        		},
        		strBirthCertDesc => {
        			label => $FieldLabels->{'strDescription'},
      	            value => $values->{'strBirthCertDesc'},
                    type => 'textarea',
                    rows => '10',
                    cols => '40',
        		},
        		strPassportNo => { 
                	label => $FieldLabels->{'strPassportNo'},
                	value => $values->{'strPassportNo'},
                	type => 'text',
                	size => '40',
                	maxsize => '50',
                },
                strPassportNationality => {
                	label => $FieldLabels->{'strPassportNationality'},
                	value => $values->{'strPassportNationality'},
                	type        => 'lookup',
                    options     => $isocountries,
                    firstoption => [ '', 'Select Country' ],
                    
                },
                strPassportIssueCountry => {
                	label => $FieldLabels->{'strPassportIssueCountry'},
                	value => $values->{'strPassportIssueCountry'},
                	type        => 'lookup',
                    options     => $isocountries,
                    firstoption => [ '', 'Select Country' ],                	
                },
                dtPassportExpiry => {
                	label => $FieldLabels->{'dtPassportExpiry'},
                	value => $values->{'dtPassportExpiry'},
                	type        => 'date',
                    datetype    => 'dropdown',
                    format      => 'dd/mm/yyyy',
                    validate    => 'DATE',
                },
                strOtherPersonIdentifier => {
                	label => $FieldLabels->{'strOtherPersonIdentifier'},
                	value => $values->{'strOtherPersonIdentifier'},
                	type => 'text',
                	size => '40',
                	maxsize => '50',                	
                },
                strOtherPersonIdentifierIssueCountry => {
                	label => $FieldLabels->{'strOtherPersonIdentifierIssueCountry'},
                	value => $values->{'strOtherPersonIdentifierIssueCountry'},
                	type        => 'lookup',
                    options     => $isocountries,
                    firstoption => [ '', 'Select Country' ],
                },
                dtOtherPersonIdentifierValidDateFrom => {
                	label => $FieldLabels->{'dtValidFrom'},
                	value => $values->{'dtOtherPersonIdentifierValidDateFrom'},
                	type        => 'date',
                    datetype    => 'dropdown',
                    format      => 'dd/mm/yyyy',
                    validate    => 'DATE',
                },
                dtOtherPersonIdentifierValidDateTo => {
                	label => $FieldLabels->{'dtValidUntil'},
                	value => $values->{'dtOtherPersonIdentifierValidDateTo'},
                	type        => 'date',
                    datetype    => 'dropdown',
                    format      => 'dd/mm/yyyy',
                    validate    => 'DATE',
                },
                strOtherPersonIdentifierDesc => {
                	label => $FieldLabels->{'strDescription'},
                	value => $values->{'strOtherPersonIdentifierDesc'},
                    type => 'textarea',
                    rows => '10',
                    cols => '40',                	
                },
                
                
            },
            'order' => [qw(
                strPreferredLang
                intEthnicityID                 
                strBirthCert strBirthCertCountry dtBirthCertValidityDateFrom dtBirthCertValidityDateTo strBirthCertDesc 
                strPassportNationality
                strPassportIssueCountry
                dtPassportExpiry
               
                strOtherPersonIdentifier
                strOtherPersonIdentifierIssueCountry
                dtOtherPersonIdentifierValidDateFrom
                dtOtherPersonIdentifierValidDateTo
                strOtherPersonIdentifierDesc
            )],
        },
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
        },
        minor => {
            'fields' => {
                intMinorMoveOtherThanFootball => {
                    label => $FieldLabels->{'intMinorMoveOtherThanFootball'} || '',
                    value => $values->{'intMinorMoveOtherThanFootball'} || 0,
                    type  => 'checkbox',
                    displaylookup => { 1 => 'Yes', 0 => 'No' },
                },
                intMinorDistance => {
                    label => $FieldLabels->{'intMinorDistance'} || '',
                    value => $values->{'intMinorDistance'} || 0,
                    type  => 'checkbox',
                    displaylookup => { 1 => 'Yes', 0 => 'No' },
                },
                intMinorEU => {
                    label => $FieldLabels->{'intMinorEU'} || '',
                    value => $values->{'intMinorEU'} || 0,
                    type  => 'checkbox',
                    displaylookup => { 1 => 'Yes', 0 => 'No' },
                },
                intMinorNone => {
                    label => $FieldLabels->{'intMinorNone'} || '',
                    value => $values->{'intMinorNone'} || 0,
                    type  => 'checkbox',
                    displaylookup => { 1 => 'Yes', 0 => 'No' },
                },
            },
            'order' => [qw(
                intMinorMoveOtherThanFootball
                intMinorDistance
                intMinorEU
                intMinorNone
            )],
        }
    };
    for my $i (1..10) {
        my $fieldname = "intNatCustomLU$i";
        my $name = $CustomFieldNames->{$fieldname}[0] || '';
        next if !$name;
        $self->{'FieldSets'}{'otherdetails'}{'fields'}{$fieldname} = {
            label => $name,
            value => $values->{$fieldname},
            type  => 'lookup',
            options     => $DefCodes->{$intNatCustomLU_DefsCodes[$i]},
            order       => $DefCodesOrder->{$intNatCustomLU_DefsCodes[$i]},
            firstoption => [ '', " " ],
        };
        push @{$self->{'FieldSets'}{'otherdetails'}{'order'}} , $fieldname;
    }

}

sub display_core_details    { 
    my $self = shift;

    my $id = $self->ID() || 0;
    my $defaultType = $self->{'RunParams'}{'dtype'} || '';
    if($defaultType eq 'TRANSFER')   {
        my $personObj = new PersonObj(db => $self->{'db'}, ID => $id);
        $personObj->load();
        if($personObj->ID())    {
            my $objectValues = $self->loadObjectValues($personObj);
            $self->setupValues($objectValues);
        }
    }

    my $memperm = ProcessPermissions($self->{'Data'}->{'Permissions'}, $self->{'FieldSets'}{'core'}, 'Person',);
    my($fieldsContent, undef, $scriptContent, $tabs) = $self->displayFields($memperm);
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

sub validate_core_details    { 
    my $self = shift;

    my $userData = {};
    my $memperm = ProcessPermissions($self->{'Data'}->{'Permissions'}, $self->{'FieldSets'}{'core'}, 'Person',);
    ($userData, $self->{'RunDetails'}{'Errors'}) = $self->gatherFields($memperm);

    if(!scalar(@{$self->{'RunDetails'}{'Errors'}})) {
        if(isPossibleDuplicate($self->{'Data'}, $userData))    {
            push @{$self->{'RunDetails'}{'Errors'}}, 'This person is a possible duplicate';
        }
    }

    if($self->{'RunDetails'}{'Errors'} and scalar(@{$self->{'RunDetails'}{'Errors'}})) {
        #There are errors - reset where we are to go back to the form again
        $self->decrementCurrentProcessIndex();
        return ('',2);
    }

    my $id = $self->ID() || 0;
    my $personObj = new PersonObj(db => $self->{'db'}, ID => $id);
    $personObj->load();
    $userData->{'strStatus'} = 'INPROGRESS';
    $userData->{'intRealmID'} = $self->{'Data'}{'Realm'};
    $userData->{'intInternationalTransfer'} = 1 if $self->getCarryFields('itc');
    $personObj->setValues($userData);
    $personObj->write();
    if($personObj->ID())    {
        if(!$id)    { 
            $self->setID($personObj->ID()); 
            $self->addCarryField('newreg',1);
        }
        $self->{'ClientValues'}{'personID'} = $personObj->ID();
        $self->{'ClientValues'}{'currentLevel'} = $Defs::LEVEL_PERSON;
        my $client = setClient($self->{'ClientValues'});
        $self->addCarryField('client',$client);
        auditLog(
            $personObj->ID(),
            $self->{'Data'},
            'ADD',
            'PERSON',
        );
#WR: SHoudl we check for duplicates here
    }

    return ('',1);
}

sub display_minor_fields { 
    my $self = shift;

    my $id = $self->ID() || 0;
    if(!doesUserHaveAccess($self->{'Data'}, $id,'WRITE')) {
        return ('Invalid User',0);
    }
    my $personObj = new PersonObj(db => $self->{'db'}, ID => $id);
    $personObj->load();
    my $dob = $personObj->getValue('dtDOB');
    my $isMinor = personIsMinor($self->{'Data'}, $dob);
    my $defaultType = $self->{'RunParams'}{'dtype'} || '';
    if(!$isMinor or $defaultType ne 'PLAYER')   {
        $self->incrementCurrentProcessIndex();
        $self->incrementCurrentProcessIndex();
        return ('',2);
    }
    if($personObj->ID())    {
        my $objectValues = $self->loadObjectValues();
        $self->setupValues($objectValues);
    }

    my $memperm = ProcessPermissions($self->{'Data'}->{'Permissions'}, $self->{'FieldSets'}{'minor'}, 'Person',);
    my($fieldsContent, undef, $scriptContent, $tabs) = $self->displayFields($memperm);
    my %PageData = (
        HiddenFields => $self->stringifyCarryField(),
        Target => $self->{'Data'}{'target'},
        Errors => $self->{'RunDetails'}{'Errors'} || [],
        Content => $fieldsContent || '',
        ScriptContent => $scriptContent || '',
        FlowSummary => buildSummaryData($self->{'Data'}, $personObj) || '',
        FlowSummaryTemplate => 'registration/person_flow_summary.templ',
        Title => '',
        TextTop => '',
        TextBottom => '',
    );
    my $pagedata = $self->display(\%PageData);

    return ($pagedata,0);

}

sub validate_minor_fields { 
    my $self = shift;

    my $userData = {};
    my $memperm = ProcessPermissions($self->{'Data'}->{'Permissions'}, $self->{'FieldSets'}{'minor'}, 'Person',);
    ($userData, $self->{'RunDetails'}{'Errors'}) = $self->gatherFields($memperm);
    my $id = $self->ID() || 0;
    if(!$id)    {
        push @{$self->{'RunDetails'}{'Errors'}}, 'Invalid Person';
    }
    if($userData->{'intMinorNone'})   {
        push @{$self->{'RunDetails'}{'Errors'}}, 'This person is not eligible for registration';
    }
    if($self->{'RunDetails'}{'Errors'} and scalar(@{$self->{'RunDetails'}{'Errors'}})) {
        #There are errors - reset where we are to go back to the form again
        $self->decrementCurrentProcessIndex();
        return ('',2);
    }

    my $personObj = new PersonObj(db => $self->{'db'}, ID => $id);
    $personObj->load();
    if(!doesUserHaveAccess($self->{'Data'}, $id,'WRITE')) {
        return ('Invalid User',0);
    }
    $personObj->setValues($userData);
    $personObj->write();
    return ('',1);
}


sub display_contact_details    { 
    my $self = shift;

    my $id = $self->ID() || 0;
    if(!doesUserHaveAccess($self->{'Data'}, $id,'WRITE')) {
        return ('Invalid User',0);
    }
    my $personObj = new PersonObj(db => $self->{'db'}, ID => $id);
    $personObj->load();
    if($personObj->ID())    {
        my $objectValues = $self->loadObjectValues($personObj);
        $self->setupValues($objectValues);
    }
    my $memperm = ProcessPermissions($self->{'Data'}->{'Permissions'}, $self->{'FieldSets'}{'contactdetails'}, 'Person',);
    my($fieldsContent, undef, $scriptContent, $tabs) = $self->displayFields($memperm);
    my %PageData = (
        HiddenFields => $self->stringifyCarryField(),
        Target => $self->{'Data'}{'target'},
        Errors => $self->{'RunDetails'}{'Errors'} || [],
        Content => $fieldsContent || '',
        ScriptContent => $scriptContent || '',
        FlowSummary => buildSummaryData($self->{'Data'}, $personObj) || '',
        FlowSummaryTemplate => 'registration/person_flow_summary.templ',
        Title => '',
        TextTop => '',
        TextBottom => '',
    );
    my $pagedata = $self->display(\%PageData);

    return ($pagedata,0);

}

sub validate_contact_details    { 
    my $self = shift;

    my $userData = {};
    my $memperm = ProcessPermissions($self->{'Data'}->{'Permissions'}, $self->{'FieldSets'}{'contactdetails'}, 'Person',);
    ($userData, $self->{'RunDetails'}{'Errors'}) = $self->gatherFields($memperm);
    my $id = $self->ID() || 0;
    if(!$id)    {
        push @{$self->{'RunDetails'}{'Errors'}}, 'Invalid Person';
    }
    if(!doesUserHaveAccess($self->{'Data'}, $id,'WRITE')) {
        return ('Invalid User',0);
    }
    if($self->{'RunDetails'}{'Errors'} and scalar(@{$self->{'RunDetails'}{'Errors'}})) {
        #There are errors - reset where we are to go back to the form again
        $self->decrementCurrentProcessIndex();
        return ('',2);
    }

    my $personObj = new PersonObj(db => $self->{'db'}, ID => $id);
    $personObj->load();
    $personObj->setValues($userData);
    $personObj->write();
    return ('',1);
}
sub display_person_identifier {
	my $self = shift; 
	my $id = $self->ID() || 0;
    if(!doesUserHaveAccess($self->{'Data'}, $id,'WRITE')) {
        return ('Invalid User',0);
    }
    my $personObj = new PersonObj(db => $self->{'db'}, ID => $id);
    $personObj->load();
    if($personObj->ID())    {
        my $objectValues = $self->loadObjectValues($personObj);
        $self->setupValues($objectValues);
    }
    
	my($fieldsContent, undef, $scriptContent, $tabs) = $self->displayFields();
    my %PageData = (
        HiddenFields => $self->stringifyCarryField(),
        Target => $self->{'Data'}{'target'},
        Errors => $self->{'RunDetails'}{'Errors'} || [],
        Content => $fieldsContent || '',
        ScriptContent => $scriptContent || '',
        FlowSummary => buildSummaryData($self->{'Data'}, $personObj) || '',
        FlowSummaryTemplate => 'registration/person_flow_summary.templ',
        Title => '',
        TextTop => '',
        TextBottom => '',
    );
    my $pagedata = $self->display(\%PageData);

    return ($pagedata,0);
	
}
sub validate_person_identifier_details    { 
    my $self = shift;

    my $userData = {};
    ($userData, $self->{'RunDetails'}{'Errors'}) = $self->gatherFields();
    my $id = $self->ID() || 0;
    if(!$id)    {
        push @{$self->{'RunDetails'}{'Errors'}}, 'Invalid Person';
    }
    if(!doesUserHaveAccess($self->{'Data'}, $id,'WRITE')) {
        return ('Invalid User',0);
    }
    if($self->{'RunDetails'}{'Errors'} and scalar(@{$self->{'RunDetails'}{'Errors'}})) {
        #There are errors - reset where we are to go back to the form again
        $self->decrementCurrentProcessIndex();
        return ('',2);
    }

    my $personObj = new PersonObj(db => $self->{'db'}, ID => $id);
    $personObj->load();
    $personObj->setValues($userData);
    $personObj->write();
    return ('',1);
}

sub display_other_details    { 
    my $self = shift;

    my $id = $self->ID() || 0;
    if(!doesUserHaveAccess($self->{'Data'}, $id,'WRITE')) {
        return ('Invalid User',0);
    }
    my $personObj = new PersonObj(db => $self->{'db'}, ID => $id);
    $personObj->load();
    if($personObj->ID())    {
        my $objectValues = $self->loadObjectValues($personObj);
        $self->setupValues($objectValues);
    }
    my $memperm = ProcessPermissions($self->{'Data'}->{'Permissions'}, $self->{'FieldSets'}{'otherdetails'}, 'Person',);
    my($fieldsContent, undef, $scriptContent, $tabs) = $self->displayFields($memperm);
    my %PageData = (
        HiddenFields => $self->stringifyCarryField(),
        Target => $self->{'Data'}{'target'},
        Errors => $self->{'RunDetails'}{'Errors'} || [],
        Content => $fieldsContent || '',
        ScriptContent => $scriptContent || '',
        FlowSummary => buildSummaryData($self->{'Data'}, $personObj) || '',
        FlowSummaryTemplate => 'registration/person_flow_summary.templ',
        Title => '',
        TextTop => '',
        TextBottom => '',
    );
    my $pagedata = $self->display(\%PageData);

    return ($pagedata,0);

}

sub validate_other_details    { 
    my $self = shift;

    my $userData = {};
    my $memperm = ProcessPermissions($self->{'Data'}->{'Permissions'}, $self->{'FieldSets'}{'otherdetails'}, 'Person',);
    ($userData, $self->{'RunDetails'}{'Errors'}) = $self->gatherFields($memperm);
    my $id = $self->ID() || 0;
    if(!$id)    {
        push @{$self->{'RunDetails'}{'Errors'}}, 'Invalid Person';
    }
    if(!doesUserHaveAccess($self->{'Data'}, $id,'WRITE')) {
        return ('Invalid User',0);
    }
    if($self->{'RunDetails'}{'Errors'} and scalar(@{$self->{'RunDetails'}{'Errors'}})) {
        #There are errors - reset where we are to go back to the form again
        $self->decrementCurrentProcessIndex();
        return ('',2);
    }

    my $personObj = new PersonObj(db => $self->{'db'}, ID => $id);
    $personObj->load();
    $personObj->setValues($userData);
    $personObj->write();
    return ('',1);
}

sub display_registration { 
    my $self = shift;

    my $personID = $self->ID();
    if(!doesUserHaveAccess($self->{'Data'}, $personID,'WRITE')) {
        return ('Invalid User',0);
    }
    my $entityID = getLastEntityID($self->{'ClientValues'}) || 0;
    my $entityLevel = getLastEntityLevel($self->{'ClientValues'}) || 0;
    my $originLevel = $self->{'ClientValues'}{'authLevel'} || 0;

    my $client = $self->{'Data'}->{'client'};
    my $url = $self->{'Target'}."?rfp=".$self->getNextAction()."&".$self->stringifyURLCarryField();
    my $personObj = new PersonObj(db => $self->{'db'}, ID => $personID);
    $personObj->load();
    my ($dob, $gender) = $personObj->getValue(['dtDOB','intGender']); 
    my $content = displayPersonRegisterWhat(
        $self->{'Data'},
        $personID,
        $entityID,
        $dob || '',
        $gender || 0,
        $originLevel,
        $url,
    );
    my %PageData = (
        HiddenFields => $self->stringifyCarryField(),
        Target => $self->{'Data'}{'target'},
        Errors => $self->{'RunDetails'}{'Errors'} || [],
        Content => $content,
        FlowSummary => buildSummaryData($self->{'Data'}, $personObj) || '',
        FlowSummaryTemplate => 'registration/person_flow_summary.templ',
        Title => '',
        TextTop => '',
        TextBottom => '',
        NoContinueButton => 1,
    );
    my $pagedata = $self->display(\%PageData);

    return ($pagedata,0);

}

sub process_registration { 
    my $self = shift;

    #add rego record with types etc.
    my $personType = $self->{'RunParams'}{'pt'} || '';
    my $personEntityRole= $self->{'RunParams'}{'per'} || '';
    my $personLevel = $self->{'RunParams'}{'pl'} || '';
    my $sport = $self->{'RunParams'}{'sp'} || '';
    my $ageLevel = $self->{'RunParams'}{'ag'} || '';
    my $registrationNature = $self->{'RunParams'}{'nat'} || '';
    my $entityID = getLastEntityID($self->{'ClientValues'}) || 0;
    my $entityLevel = getLastEntityLevel($self->{'ClientValues'}) || 0;
    my $originLevel = $self->{'ClientValues'}{'authLevel'} || 0;
    my $lang = $self->{'Lang'};

    my $personID = $self->ID() || 0;
    if(!doesUserHaveAccess($self->{'Data'}, $personID,'WRITE')) {
        return ('Invalid User',0);
    }
    my $regoID = 0;
    my $msg = '';
    if($personID)   {
        ($regoID, undef, $msg) = add_rego_record(
            $self->{'Data'}, 
            $personID, 
            $entityID, 
            $entityLevel, 
            $originLevel, 
            $personType, 
            $personEntityRole, 
            $personLevel, 
            $sport, 
            $ageLevel, 
            $registrationNature,
       );
    }
    if(!$personID)    {
        push @{$self->{'RunDetails'}{'Errors'}}, 'Invalid Person';
    }
    if (!$regoID)   {
        if ($msg eq 'SUSPENDED')   {
            push @{$self->{'RunDetails'}{'Errors'}}, $lang->txt("You cannot register at this time, Person is currently SUSPENDED");
        }
        if ($msg eq 'LIMIT_EXCEEDED')   {
            push @{$self->{'RunDetails'}{'Errors'}}, $lang->txt("You cannot register this combination, limit exceeded");
        }
        if ($msg eq 'NEW_FAILED')   {
            push @{$self->{'RunDetails'}{'Errors'}}, $lang->txt("New failed, existing registration found.  In order to continue, a Transfer from the existing Entity must be organised.");
        }
        if ($msg eq 'RENEWAL_FAILED')   {
            push @{$self->{'RunDetails'}{'Errors'}}, $lang->txt("Renewal failed, cannot find existing registration. Might have already been renewed");
        }
    }
    else    {
        $self->addCarryField('rID',$regoID);
        $self->addCarryField('pType',$personType);
    }

    if($self->{'RunDetails'}{'Errors'} and scalar(@{$self->{'RunDetails'}{'Errors'}})) {
        #There are errors - reset where we are to go back to the form again
        $self->decrementCurrentProcessIndex();
        return ('',2);
    }

    return ('',1);
}

sub display_certifications { 
    my $self = shift;

    my $id = $self->ID() || 0;
    if(!doesUserHaveAccess($self->{'Data'}, $id,'WRITE')) {
        return ('Invalid User',0);
    }
    my $personObj = new PersonObj(db => $self->{'db'}, ID => $id);
    $personObj->load();
    my $personType = $self->{'RunParams'}{'pType'} || '';
    if(!($personType eq 'COACH' or $personType eq 'REFEREE'))   {
        #only continue if these types
        $self->incrementCurrentProcessIndex();
        $self->incrementCurrentProcessIndex();
        return ('',2);
    }

    if($personObj->ID())    {
        my $objectValues = $self->loadObjectValues($personObj);
        my $certificationTypes  = getPersonCertificationTypes(
            $self->{'Data'},
            $personType,
        );
        my %ctypes = ();
        for my $type (@{$certificationTypes})   {
            $ctypes{$type->{'intCertificationTypeID'}} = $type->{'strCertificationName'} || next;
        }
        $objectValues->{'certificationTypes'} = \%ctypes;
        $self->setupValues($objectValues);
    }
    my($fieldsContent, undef, $scriptContent, $tabs) = $self->displayFields();

    my $certifications = getPersonCertifications(
        $self->{'Data'},
        $personObj->ID(),
        $personType,
        0
    );
    my $content = runTemplate(
        $self->{'Data'},
        {
            certifications => $certifications,
        },
        'registration/certifications.templ'
    );
    my %PageData = (
        HiddenFields => $self->stringifyCarryField(),
        Target => $self->{'Data'}{'target'},
        Errors => $self->{'RunDetails'}{'Errors'} || [],
        Content => $fieldsContent || '',
        ScriptContent => $scriptContent || '',
        FlowSummary => buildSummaryData($self->{'Data'}, $personObj) || '',
        FlowSummaryTemplate => 'registration/person_flow_summary.templ',
        Title => '',
        TextTop => $content,
        TextBottom => '',
    );
    my $pagedata = $self->display(\%PageData);

    return ($pagedata,0);

}

sub process_certifications { 
    my $self = shift;

    my $userData = {};
    ($userData, $self->{'RunDetails'}{'Errors'}) = $self->gatherFields();
    my $id = $self->ID() || 0;
    if(!$id)    {
        push @{$self->{'RunDetails'}{'Errors'}}, 'Invalid Person';
    }
    if(!doesUserHaveAccess($self->{'Data'}, $id,'WRITE')) {
        return ('Invalid User',0);
    }

    if(!scalar(@{$self->{'RunDetails'}{'Errors'}}))    {
        my $personObj = new PersonObj(db => $self->{'db'}, ID => $id);
        $personObj->load();

        if($userData->{'intCertificationTypeID'})   {
           my $ret = addPersonCertification(
                $self->{'Data'},
                $personObj->ID(),
                $userData->{'intCertificationTypeID'},
                $userData->{'dtValidFrom'} || '',
                $userData->{'dtValidUntil'} || '',
                $userData->{'strDescription'} || '',
                'ACTIVE',
            ); 

            if(!$ret)    {
                push @{$self->{'RunDetails'}{'Errors'}}, 'Invalid Certification Data';
            }
        }
    }
    if($self->{'RunDetails'}{'Errors'} and scalar(@{$self->{'RunDetails'}{'Errors'}})) {
        #There are errors - reset where we are to go back to the form again
        $self->decrementCurrentProcessIndex();
        return ('',2);
    }
    return ('',1);
}

sub display_products { 
    my $self = shift;

    my $personID = $self->ID();
    if(!doesUserHaveAccess($self->{'Data'}, $personID,'WRITE')) {
        return ('Invalid User',0);
    }
    my $entityID = getLastEntityID($self->{'ClientValues'}) || 0;
    my $entityLevel = getLastEntityLevel($self->{'ClientValues'}) || 0;
    my $originLevel = $self->{'ClientValues'}{'authLevel'} || 0;
    my $regoID = $self->{'RunParams'}{'rID'} || 0;
    my $client = $self->{'Data'}->{'client'};

    my $rego_ref = {};
    my $content = '';
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

    my $personObj = new PersonObj(db => $self->{'db'}, ID => $personID);
    $personObj->load();

    if($regoID) {
        my $nationality = $personObj->getValue('strISONationality') || ''; 
        $rego_ref->{'Nationality'} = $nationality;

        $content = displayRegoFlowProducts(
            $self->{'Data'}, 
            $regoID, 
            $client, 
            $entityLevel, 
            $originLevel, 
            $rego_ref, 
            $entityID, 
            $personID, 
            {},
            1,
        );
    }
    else    {
        push @{$self->{'RunDetails'}{'Errors'}}, $self->{'Lang'}->txt("Invalid Registration ID");
    }
    if($self->{'RunDetails'}{'Errors'} and scalar(@{$self->{'RunDetails'}{'Errors'}})) {
        #There are errors - reset where we are to go back to the form again
        $self->decrementCurrentProcessIndex();
        return ('',2);
    }
    my %ManualPayPageData = (
        HiddenFields => $self->stringifyCarryField(),
        Target => $self->{'Data'}{'target'},
        Errors => $self->{'RunDetails'}{'Errors'} || [],
        FlowSummary => buildSummaryData($self->{'Data'}, $personObj) || '',
        FlowSummaryTemplate => 'registration/person_flow_manual_pay.templ',
        allowManualPay=> 1,
        manualPaymentTypes => \%Defs::manualPaymentTypes,
        Title => '',
        TextTop => '',
        TextBottom => '',
    );
    my $pay_body = runTemplate(
            $self->{'Data'},
            \%ManualPayPageData,
            'registration/person_flow_manual_pay.templ',
    );
    if ($self->{'SystemConfig'}{'AllowTXNs_Manual_roleFlow'}) {
        $content = $pay_body . $content;
    }


    my %PageData = (
        HiddenFields => $self->stringifyCarryField(),
        Target => $self->{'Data'}{'target'},
        Errors => $self->{'RunDetails'}{'Errors'} || [],
        Content => $content,
        FlowSummary => buildSummaryData($self->{'Data'}, $personObj) || '',
        FlowSummaryTemplate => 'registration/person_flow_summary.templ',
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

    my $personID = $self->ID();
    if(!doesUserHaveAccess($self->{'Data'}, $personID,'WRITE')) {
        return ('Invalid User',0);
    }
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

    my ($txnIds, $amount) = save_rego_products($self->{'Data'}, $regoID, $personID, $entityID, $entityLevel, $rego_ref, $self->{'RunParams'});

####
    my $paymentType = $self->{'RunParams'}{'paymentType'} || 0;
    my $markPaid= $self->{'RunParams'}{'markPaid'} || 0;
    my @txnIds = split ':',$txnIds ;
    if ($paymentType and $markPaid)  {
            my %Settings=();
            $Settings{'paymentType'} = $paymentType;
            my $logID = createTransLog($self->{'Data'}, \%Settings, $entityID,\@txnIds, $amount);
            UpdateCart($self->{'Data'}, undef, $self->{'Data'}->{'client'}, undef, undef, $logID);
            product_apply_transaction($self->{'Data'},$logID);
        }
    $self->addCarryField('paymentType',$paymentType);
    $self->addCarryField('markPaid',$markPaid);
####

    $self->addCarryField('txnIds',$txnIds);

    return ('',1);
}

sub display_documents { 
    my $self = shift;

    my $personID = $self->ID();
    if(!doesUserHaveAccess($self->{'Data'}, $personID,'WRITE')) {
        return ('Invalid User',0);
    }
    my $entityID = getLastEntityID($self->{'ClientValues'}) || 0;
    my $entityLevel = getLastEntityLevel($self->{'ClientValues'}) || 0;
    my $originLevel = $self->{'ClientValues'}{'authLevel'} || 0;
    my $regoID = $self->{'RunParams'}{'rID'} || 0;
    my $client = $self->{'Data'}->{'client'};

    my $rego_ref = {};
    my $content = '';
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

    my $personObj = new PersonObj(db => $self->{'db'}, ID => $personID);
    $personObj->load();
    if($regoID) {
        my $nationality = $personObj->getValue('strISONationality') || ''; 
        my $itc = $personObj->getValue('intInternationalTransfer') || '';
        $rego_ref->{'Nationality'} = $nationality;
        $rego_ref->{'InternationalTransfer'} = $itc;

        $content = displayRegoFlowDocuments(
            $self->{'Data'}, 
            $regoID, 
            $client, 
            $entityLevel, 
            $originLevel, 
            $rego_ref, 
            $entityID, 
            $personID, 
            {},
            1
        );
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
        FlowSummary => buildSummaryData($self->{'Data'}, $personObj) || '',
        FlowSummaryTemplate => 'registration/person_flow_summary.templ',
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
    
    my $personID = $self->ID();
    if(!doesUserHaveAccess($self->{'Data'}, $personID,'WRITE')) {
        return ('Invalid User',0);
    }
    my $entityID = getLastEntityID($self->{'ClientValues'}) || 0;
    my $entityLevel = getLastEntityLevel($self->{'ClientValues'}) || 0;
    my $originLevel = $self->{'ClientValues'}{'authLevel'} || 0;
    my $regoID = $self->{'RunParams'}{'rID'} || 0;
    my $client = $self->{'Data'}->{'client'};

    my $rego_ref = {};
    my $content = '';
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

    my $personObj = new PersonObj(db => $self->{'db'}, ID => $personID);
    $personObj->load();
    
    #check for uploaded document
    my $isRequiredDocPresent = checkUploadedRegoDocuments($self->{'Data'},$personID, $regoID,$entityID,$entityLevel,$originLevel,$rego_ref);
    if(!$isRequiredDocPresent){
    	push @{$self->{'RunDetails'}{'Errors'}}, $self->{'Lang'}->txt("Required Document Missing");
    	my %PageData = (
        HiddenFields => $self->stringifyCarryField(),
        Target => $self->{'Data'}{'target'},
        Errors => $self->{'RunDetails'}{'Errors'} || [],
        FlowSummary => buildSummaryData($self->{'Data'}, $personObj) || '',
        FlowSummaryTemplate => 'registration/person_flow_summary.templ',
        Content => '',
        Title => '',
        TextTop => $content,
        TextBottom => '',
        NoContinueButton => 1,        
    );
         
        my $pagedata = $self->display(\%PageData);
     
    	return ($pagedata,0);

    }
    return ('',1);
}


sub display_complete { 
    my $self = shift;

    my $personID = $self->ID();
    if(!doesUserHaveAccess($self->{'Data'}, $personID,'WRITE')) {
        return ('Invalid User',0);
    }
    my $entityID = getLastEntityID($self->{'ClientValues'}) || 0;
    my $entityLevel = getLastEntityLevel($self->{'ClientValues'}) || 0;
    my $originLevel = $self->{'ClientValues'}{'authLevel'} || 0;
    my $regoID = $self->{'RunParams'}{'rID'} || 0;
    my $client = $self->{'Data'}->{'client'};

    my $rego_ref = {};
    my $content = '';
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

    if($regoID) {
        my $personObj = new PersonObj(db => $self->{'db'}, ID => $personID);
        $personObj->load();
        my $nationality = $personObj->getValue('strISONationality') || ''; 
        $rego_ref->{'Nationality'} = $nationality;

        my $run = $self->{'RunParams'}{'run'} || 0;
print STDERR "IN display_complete --- COMPLETE $run\n";
        if($self->{'RunParams'}{'newreg'} and ! $run)  {
                #$self->{'RunParams'}{'run'} = 1;
                #$self->addCarryField('run',1);
print STDERR "RRRRRRRRULES RUNNINGS\n";
            my $rc = WorkFlow::addWorkFlowTasks(
                $self->{'Data'},
                'PERSON',
                'NEW',
                $self->{'ClientValues'}{'authLevel'} || 0,
                getID($self->{'ClientValues'}) || 0,
                $personID,
                0,
                0,
                0
            );
        }

        my $hiddenFields = $self->getCarryFields();
        $hiddenFields->{'rfp'} = 'c';#$self->{'RunParams'}{'rfp'};
        $hiddenFields->{'__cf'} = $self->{'RunParams'}{'__cf'};
        $content = displayRegoFlowComplete(
            $self->{'Data'}, 
            $regoID, 
            $client, 
            $originLevel, 
            $rego_ref, 
            $entityID, 
            $personID, 
            $hiddenFields,
        );
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
        Content => '',
        Title => '',
        TextTop => $content,
        TextBottom => '',
    );
    my $pagedata = $self->display(\%PageData);

    return ($pagedata,0);

}

sub buildSummaryData    {
    my ($Data, $personObj) = @_;

    return {} if !$personObj;
    return {} if !$personObj->ID();
    my %summary = (
        'name' => $personObj->name(),
        'dob' => $personObj->getValue('dtDOB'),
        'gender' => $Defs::PersonGenderInfo{$personObj->getValue('intGender')},
    );
    return \%summary; 
}

sub loadObjectValues    {
    my $self = shift;
    my ($object) = @_;

    my %values = ();
    if($object) {
        for my $field (qw(
            strLocalFirstname
            strLocalSurname
            intLocalLanguage
            strLatinFirstname
            strLatinSurname
            dtDOB
            intGender
            strMaidenName
            strISONationality
            strISOCountryOfBirth
            strRegionOfBirth
            strPlaceOfBirth
            
            strBirthCert 
            strBirthCertCountry 
            dtBirthCertValidityDateFrom 
            dtBirthCertValidityDateTo 
            strBirthCertDesc
            
            strAddress1
            strAddress2
            strSuburb
            strState
            strPostalCode
            strPhoneHome

            strPreferredLang
            intEthnicityID
            
            strPassportNo
            strPassportNationality
            strPassportIssueCountry
            dtPassportExpiry

            strOtherPersonIdentifier
            strOtherPersonIdentifierIssueCountry
            dtOtherPersonIdentifierValidDateFrom
            dtOtherPersonIdentifierValidDateTo
            strOtherPersonIdentifierDesc

            intMinorMoveOtherThanFootball
            intMinorDistance
            intMinorEU
            intMinorNone
        )) {
            $values{$field} = $object->getValue($field);
        }
    }
    return \%values;
}

