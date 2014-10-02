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
    ];
}

sub setupValues    {
    my $self = shift;

    my $FieldLabels   = FieldLabels::getFieldLabels( $self->{'Data'}, $Defs::LEVEL_PERSON );
    my $isocountries  = getISOCountriesHash();
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
                    compulsory => 1,
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
                dtDOB => {
                    label       => $FieldLabels->{'dtDOB'},
                    type        => 'date',
                    datetype    => 'dropdown',
                    format      => 'dd/mm/yyyy',
                    validate    => 'DATE',
                    compulsory => 1,
                },
                strISOCountryOfBirth => {
                    label       => $FieldLabels->{'strISOCountryOfBirth'},
                    type        => 'lookup',
                    options     => $isocountries,
                    firstoption => [ '', 'Select Country' ],
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
                strISOCountryOfBirth
                intGender
            )],
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
        Fields => $fieldsContent || '',
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
use Data::Dumper;
print STDERR Dumper($userData);
$self->{'RunDetails'}{'Errors'} = ['test error'];
    if(scalar(@{$self->{'RunDetails'}{'Errors'}})) {
        #There are errors - reset where we are to go back to the form again
        $self->setCurrentProcessIndex('cd');
        return ('',2);
    }

    my $id = $self->ID() || 0;
    my $personObj = new PersonObj(db => $self->{'db'}, ID => $id);
    $personObj->setValues($userData);
    $personObj->write();
    if(!$id)    {
        warn("NEW" .$personObj->ID());
        $self->setID($personObj->ID());
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
        Fields => $fieldsContent || '',
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
    if(scalar(@{$self->{'RunDetails'}{'Errors'}})) {
        #There are errors - reset where we are to go back to the form again
        $self->setCurrentProcessIndex('cond');
        return ('',2);
    }

    my $personObj = new PersonObj(db => $self->{'db'}, ID => $id);
    $personObj->setValues($userData);
    $personObj->write();
    return ('',1);
}
