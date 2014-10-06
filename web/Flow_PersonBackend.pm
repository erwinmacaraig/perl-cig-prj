package Flow_PersonBackend;

use strict;
use lib '.', '..', '../..', "../dashboard", "../user";
use Flow_BaseObj;
our @ISA =qw(Flow_BaseObj);

use TTTemplate;
use CGI;
use FieldLabels;
use PersonObj;
use ConfigOptions;
use InstanceOf;
use Countries;
use PersonRegisterWhat;
use Reg_common;
use FieldCaseRule;
use WorkFlow;
use PersonRegistrationFlow_Common;
use AuditLog;


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
            'label'  => 'Details',
            'fieldset'  => 'contactdetails',
        },
        {
            'action' => 'condu',
            'function' => 'validate_contact_details',
            'fieldset'  => 'contactdetails',
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

    $self->{'FieldSets'} = {
        core => {
            'fields' => {
                strLocalFirstname => {
                    label       => $FieldLabels->{'strLocalFirstname'},
                    type        => 'text',
                    size        => '40',
                    maxsize     => '50',
                },
                strLocalSurname => {
                    label       => $self->{'SystemConfig'}{'strLocalSurname_Text'} ? $self->{'SystemConfig'}{'strLocalSurname_Text'} : $FieldLabels->{'strLocalSurname'},
                    type        => 'text',
                    size        => '40',
                    maxsize     => '50',
                    compulsory => 1,
                },
                strLatinFirstname => {
                    label       => $self->{'SystemConfig'}{'person_strLatinNames'} ? $FieldLabels->{'strLatinFirstname'} : '' ,
                    type        => 'text',
                    size        => '40',
                    maxsize     => '50',
                },
                strLatinSurname => {
                    label       => $self->{'SystemConfig'}{'person_strLatinNames'} ?  $FieldLabels->{'strLatinSurname'} : '',
                    type        => 'text',
                    size        => '40',
                    maxsize     => '50',
                },
                strMaidenName => {
                    label       => $FieldLabels->{'strMaidenName'},
                    type        => 'text',
                    size        => '40',
                    maxsize     => '50',
                },
                dtDOB => {
                    label       => $FieldLabels->{'dtDOB'},
                    type        => 'date',
                    datetype    => 'dropdown',
                    format      => 'dd/mm/yyyy',
                    validate    => 'DATE',
                    compulsory => 1,
                },
                strISONationality => {
                    label       => $FieldLabels->{'strISONationality'},
                    type        => 'lookup',
                    options     => $isocountries,
                    firstoption => [ '', 'Select Country' ],
                    compulsory => 1,

                },
                strISOCountryOfBirth => {
                    label       => $FieldLabels->{'strISOCountryOfBirth'},
                    type        => 'lookup',
                    options     => $isocountries,
                    firstoption => [ '', 'Select Country' ],
                    compulsory => 1,
                },
                strRegionOfBirth => {
                    label       => $FieldLabels->{'strRegionOfBirth'},
                    type        => 'text',
                    size        => '30',
                    maxsize     => '45',
                },
                strPlaceOfBirth => {
                    label       => $FieldLabels->{'strPlaceOfBirth'},
                    type        => 'text',
                    size        => '30',
                    maxsize     => '45',
                    compulsory => 1,
                },
                intGender => {
                    label       => $FieldLabels->{'intGender'},
                    type        => 'lookup',
                    options     => \%genderoptions,
                    compulsory => 1,
                    firstoption => [ '', " " ],
                },
            },
            'order' => [qw(
                strLocalFirstname
                strLocalSurname
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
                    strLocalFirstname => $field_case_rules->{'strLocalFirstname'} || '',
                    strLocalSurname   => $field_case_rules->{'strLocalSurname'}   || '',
                    strSuburb    => $field_case_rules->{'strSuburb'}    || '',
                }
            },
        },
        contactdetails => {
            'fields' => {
                strAddress1 => {
                    label       => $FieldLabels->{'strAddress1'},
                    type        => 'text',
                    size        => '50',
                    maxsize     => '100',
                },
                strAddress2 => {
                    label       => $FieldLabels->{'strAddress2'},
                    type        => 'text',
                    size        => '50',
                    maxsize     => '100',
                },
                strSuburb => {
                    label       => $FieldLabels->{'strSuburb'},
                    type        => 'text',
                    size        => '30',
                    maxsize     => '100',
                },
                strState => {
                    label       => $FieldLabels->{'strState'},
                    type        => 'text',
                    size        => '50',
                    maxsize     => '100',
                },
                strPostalCode => {
                    label       => $FieldLabels->{'strPostalCode'},
                    type        => 'text',
                    size        => '15',
                    maxsize     => '15',
                },
                strPhoneHome => {
                    label       => $FieldLabels->{'strPhoneHome'},
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
            fieldtransform => {
                textcase => {
                    strSuburb    => $field_case_rules->{'strSuburb'}    || '',
                }
            },
        }
    };

}



sub display_core_details    { 
    my $self = shift;


    my $fieldperms = $self->{'Data'}->{'Permissions'};
    my $memperm = ProcessPermissions($fieldperms, $self->{'FieldSets'}{'core'}, 'Person',);
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

sub validate_core_details    { 
    my $self = shift;

    my $userData = {};
    ($userData, $self->{'RunDetails'}{'Errors'}) = $self->gatherFields();

    if($self->{'RunDetails'}{'Errors'} and scalar(@{$self->{'RunDetails'}{'Errors'}})) {
        #There are errors - reset where we are to go back to the form again
        $self->decrementCurrentProcessIndex();
        return ('',2);
    }

    my $id = $self->ID() || 0;
    my $personObj = new PersonObj(db => $self->{'db'}, ID => $id);
    $userData->{'strStatus'} = 'INPROGRESS';
    $userData->{'intRealmID'} = $self->{'Data'}{'Realm'};
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

sub display_contact_details    { 
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

sub validate_contact_details    { 
    my $self = shift;

    my $userData = {};
    ($userData, $self->{'RunDetails'}{'Errors'}) = $self->gatherFields();
    my $id = $self->ID() || 0;
    if(!$id)    {
        push @{$self->{'RunDetails'}{'Errors'}}, 'Invalid Person';
    }
    if($self->{'RunDetails'}{'Errors'} and scalar(@{$self->{'RunDetails'}{'Errors'}})) {
        #There are errors - reset where we are to go back to the form again
        $self->decrementCurrentProcessIndex();
        return ('',2);
    }

    my $personObj = new PersonObj(db => $self->{'db'}, ID => $id);
    $personObj->setValues($userData);
    $personObj->write();
    return ('',1);
}

sub display_registration { 
    my $self = shift;

    my $personID = $self->ID();
    my $entityID = getLastEntityID($self->{'ClientValues'}) || 0;
    my $entityLevel = getLastEntityLevel($self->{'ClientValues'}) || 0;
    my $originLevel = $self->{'ClientValues'}{'authLevel'} || 0;

    my $client = $self->{'Data'}->{'client'};
    my $url = $self->{'Target'}."?rfp=".$self->getNextAction()."&".$self->stringifyURLCarryField();
    my $personObj = new PersonObj(db => $self->{'db'}, ID => $personID);
    $personObj->load();
    my ($dob, $gender) = $personObj->getValue(['dtDOB_RAW','intGender']); 
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
    my %PageData = (
        HiddenFields => $self->stringifyCarryField(),
        Target => $self->{'Data'}{'target'},
        Errors => $self->{'RunDetails'}{'Errors'} || [],
        Content => $content,
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

    return ('',1);
}

sub display_documents { 
    my $self = shift;

    my $personID = $self->ID();
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
    my $self = shift;

    my $personID = $self->ID();
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

        if($self->{'RunParams'}{'newreg'})  {
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

        $content = displayRegoFlowComplete(
            $self->{'Data'}, 
            $regoID, 
            $client, 
            $originLevel, 
            $rego_ref, 
            $entityID, 
            $personID, 
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


