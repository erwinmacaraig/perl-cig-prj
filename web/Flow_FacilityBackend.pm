package Flow_FacilityBackend;

use strict;
use lib '.', '..', '../..', "../dashboard", "../user";
use Flow_BaseObj;
our @ISA =qw(Flow_BaseObj);

use TTTemplate;
use CGI;
use FieldLabels;
use EntityObj;
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
                jQuery(document).ready(function()  {
                    jQuery('#l_row_strLatinFirstname').hide();
                    jQuery('#l_row_strLatinSurname').hide();
                    jQuery('#l_intLocalLanguage').change(function()   {
                        var lang = parseInt(jQuery('#l_intLocalLanguage').val());
                        nonlatinvals = [$vals];
                        if(nonlatinvals.indexOf(lang) !== -1 )  {
                            jQuery('#l_row_strLatinFirstname').show();
                            jQuery('#l_row_strLatinSurname').show();
                        }
                        else    {
                            jQuery('#l_row_strLatinFirstname').hide();
                            jQuery('#l_row_strLatinSurname').hide();
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
                strLocalFirstname => {
                    label       => $FieldLabels->{'strLocalFirstname'},
                    value       => $values->{'strLocalFirstname'},
                    type        => 'text',
                    size        => '40',
                    maxsize     => '50',
                },
                strLocalSurname => {
                    label       => $self->{'SystemConfig'}{'strLocalSurname_Text'} ? $self->{'SystemConfig'}{'strLocalSurname_Text'} : $FieldLabels->{'strLocalSurname'},
                    value       => $values->{'strLocalSurname'},
                    type        => 'text',
                    size        => '40',
                    maxsize     => '50',
                    compulsory => 1,
                },
                intGender => {
                    label       => $FieldLabels->{'intGender'},
                    value       => $values->{'intGender'},
                    type        => 'lookup',
                    options     => \%genderoptions,
                    compulsory => 1,
                    firstoption => [ '', " " ],
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
                strLatinFirstname => {
                    label       => $self->{'SystemConfig'}{'person_strLatinNames'} || $FieldLabels->{'strLatinFirstname'},
                    value       => $values->{'strLatinFirstname'},
                    type        => 'text',
                    size        => '40',
                    maxsize     => '50',
                    active      => $nonLatin,
                },
                strLatinSurname => {
                    label       => $self->{'SystemConfig'}{'person_strLatinNames'} || $FieldLabels->{'strLatinSurname'},
                    value       => $values->{'strLatinSurname'},
                    type        => 'text',
                    size        => '40',
                    maxsize     => '50',
                    active      => $nonLatin,
                },
                strMaidenName => {
                    label       => $FieldLabels->{'strMaidenName'},
                    value       => $values->{'strMaidenName'},
                    type        => 'text',
                    size        => '40',
                    maxsize     => '50',
                },
                dtDOB => {
                    label       => $FieldLabels->{'dtDOB'},
                    value       => $values->{'dtDOB'},
                    type        => 'date',
                    datetype    => 'dropdown',
                    format      => 'dd/mm/yyyy',
                    validate    => 'DATE',
                    compulsory => 1,
                },
                strISONationality => {
                    label       => $FieldLabels->{'strISONationality'},
                    value       => $values->{'strISONationality'},
                    type        => 'lookup',
                    options     => $isocountries,
                    firstoption => [ '', 'Select Country' ],
                    compulsory => 1,
                },
                strISOCountryOfBirth => {
                    label       => $FieldLabels->{'strISOCountryOfBirth'},
                    value       => $values->{'strISOCountryOfBirth'},
                    type        => 'lookup',
                    options     => $isocountries,
                    firstoption => [ '', 'Select Country' ],
                    compulsory => 1,
                },
                strRegionOfBirth => {
                    label       => $FieldLabels->{'strRegionOfBirth'},
                    value       => $values->{'strRegionOfBirth'},
                    type        => 'text',
                    size        => '30',
                    maxsize     => '45',
                },
                strPlaceOfBirth => {
                    label       => $FieldLabels->{'strPlaceOfBirth'},
                    value       => $values->{'strPlaceOfBirth'},
                    type        => 'text',
                    size        => '30',
                    maxsize     => '45',
                    compulsory => 1,
                },
                intGender => {
                    label       => $FieldLabels->{'intGender'},
                    value       => $values->{'intGender'},
                    type        => 'lookup',
                    options     => \%genderoptions,
                    compulsory => 1,
                    firstoption => [ '', " " ],
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
        personidentifierdetails =>{
        	'fields' => {
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
        		}
        		
        	},
        	'order' =>[ 
        		qw(strBirthCert strBirthCertCountry dtBirthCertValidityDateFrom dtBirthCertValidityDateTo strBirthCertDesc )
        	],
        	fieldtransform => {
        		
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

            },
            'order' => [qw(
                strPreferredLang
                intEthnicityID
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
    my $pagedata = "validate core details";
    return ($pagedata,0);
}

sub display_contact_details {
    my $pagedata = "dcd";
    return ($pagedata,0);
}

sub validate_contact_details {
    my $pagedata = "vcd";
    return ($pagedata,0);
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
    my $pagedata = "dp";
    return ($pagedata,0);
}

sub process_products {
    my $pagedata = "pp";
    return ($pagedata,0);
}

sub display_documents {
    my $pagedata = "dd";
    return ($pagedata,0);
}

sub process_documents {
    my $pagedata = "pd";
    return ($pagedata,0);
}

sub display_complete {

}
