package Flow_TransferBackend;

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
use PersonRequest;
use PersonFieldsSetup;
use PersonRegistration;
use PersonSummaryPanel;
use RenewalDetails;

use RegoProducts;

sub setProcessOrder {
    my $self = shift;
  
    my $lang = $self->{'Data'}{'lang'};
    $self->{'ProcessOrder'} = [       
        {
            'action' => 'club',
            'function' => 'display_old_club',
            'fieldset'  => 'contactdetails',
            'label'  => $lang->txt('Old Club'),
            'title'  => $lang->txt('Transfer') .' - ' . $lang->txt('Old Club Details'),
        },
        {
            'action' => 'cd',
            'function' => 'display_core_details',
            'label'  => $lang->txt('Personal Details'),
            'title'  => $lang->txt('Transfer') .' - ' . $lang->txt('Check/Update Personal Details'),
            'fieldset'  => 'core',
            #'noRevisit' => 1,
        },
        {
            'action' => 'cdu',
            'function' => 'validate_core_details',
            'fieldset'  => 'core',
        },        
        {
            'action' => 'cond',
            'function' => 'display_contact_details',
            'fieldset'  => 'contactdetails',
            'label'  => $lang->txt('Contact Details'),
            'title'  => $lang->txt('Transfer') .' - ' . $lang->txt('Check/Update Contact Details'),
        },
        {
            'action' => 'condu',
            'function' => 'validate_contact_details',
            'fieldset'  => 'contactdetails',
        },
        {
            'action' => 'r',
            'function' => 'display_registration',
            'label'  => $lang->txt('Registration'),
            'title'  => $lang->txt('Transfer') .' - ' . $lang->txt('Confirm Transfer Registration'),
        },
        {
            'action' => 'ru',
            'function' => 'process_registration',
        },
        {
            'action' => 'd',
            'function' => 'display_documents',
            'label'  => $lang->txt('Documents'),
            'title'  => $lang->txt('Transfer') .' - ' . $lang->txt('Check/Update Documents'),
        },
        {
            'action' => 'du',
            'function' => 'process_documents',
        },
         {
            'action' => 'p',
            'function' => 'display_products',
            'label'  => $lang->txt('Payments'),
            'title'  => $lang->txt('Transfer') .' - ' . $lang->txt('Confirm Transfer Fee'),
        },
        {
            'action' => 'pu',
            'function' => 'process_products',
        },
       {
            'action' => 'summ',
            'function' => 'display_summary',
            'label'  => $lang->txt('Summary'),
            'title'  => $lang->txt('Summary and Submission'),
        },
       {
            'action' => 'c',
            'function' => 'display_complete',
            'label'  => 'Submit',
            'title'  => 'Transfer - Submitted',
            'title'  => $lang->txt('Transfer') . ' - ' . $lang->txt('Submitted'),
            'NoNav' => 1,
            'NoDisplayInNav' => 1,
            'NoGoingBack' => 1,
        },
    ];
}

sub setupValues    {
    my $self = shift;
    my ($values) = @_;
    $values ||= {};
    $values->{'defaultType'} = $self->{'RunParams'}{'dtype'} || '';

    my $entityID = getLastEntityID($self->{'ClientValues'}) || 0;
    my %regFilter = (
        'entityID' => $entityID,
        'requestID' => $self->{'RunParams'}{'prid'},
    );

    my $request = getRequests($self->{'Data'}, \%regFilter);
    $request = $request->[0];
    $self->{'RunParams'}{'nat'} = 'TRANSFER';
    $self->{'RunParams'}{'dnat'} = 'TRANSFER';
    $self->{'RunParams'}{'dsport'} = $request->{'strSport'};
    $self->addCarryField('dtype', $request->{'strPersonType'});
    $self->addCarryField('dsport', $request->{'strSport'});
    $self->addCarryField('dage', $request->{'personCurrentAgeLevel'});

    $self->{'FieldSets'} = personFieldsSetup($self->{'Data'}, $values);
}

sub display_old_club { 
    my $self = shift;
	$self->addCarryField('club_vstd', 1);
    my $id = $self->ID() || 0;
    if(!doesUserHaveAccess($self->{'Data'}, $id,'WRITE')) {
        return ('Invalid User',0);
    }
    my $personObj = new PersonObj(db => $self->{'db'}, ID => $id, cache => $self->{'Data'}{'cache'});
    $personObj->load();
    if($personObj->ID())    {
        my $objectValues = $self->loadObjectValues($personObj);
        $self->setupValues($objectValues);
    }
    my $memperm = ProcessPermissions($self->{'Data'}->{'Permissions'}, $self->{'FieldSets'}{'contactdetails'}, 'Person',);
    my $scriptContent = '';

    my $entityID = getLastEntityID($self->{'ClientValues'}) || 0;
    my %regFilter = (
        'entityID' => $entityID,
        'requestID' => $self->{'RunParams'}{'prid'},
    );
    my $request = getRequests($self->{'Data'}, \%regFilter);
    $request = $request->[0];

    my $isocountries  = getISOCountriesHash();
    my %prevClubDetails = (
        name => $request->{'requestTo'},
        sport => $Defs::entitySportType{$request->{'requestToDiscipline'}} || '',
        country => $isocountries->{$request->{'requestToISOCountry'}} || '-',
        address => $request->{'requestToAddress'} || '',
        address2 => $request->{'requestToAddress2'} || '',
        city => $request->{'requestToCity'} | '',
        postal => $request->{'requestToPostal'} || '',
        region => $request->{'requestToRegion'} || '',
        phone => $request->{'requestToPhone'} || '-',
    );

    my $fieldsContent = runTemplate(
        $self->{'Data'},
        \%prevClubDetails,
        'personrequest/transfer/oldclubdetails.templ',
    );

    my %PageData = (
        HiddenFields => $self->stringifyCarryField(),
        Target => $self->{'Data'}{'target'},
        Errors => $self->{'RunDetails'}{'Errors'} || [],
        Content => $fieldsContent || '',
        ScriptContent => $scriptContent || '',
        FlowSummaryContent => personSummaryPanel($self->{'Data'}, $personObj->ID()) || '',
        Title => '',
        TextTop => '',
        TextBottom => '',
    );
	my $pagedata = $self->display(\%PageData);

    return ($pagedata,0);

}


sub display_core_details    { 
    my $self = shift;

    #$self->addCarryField('club_vstd', 1);
	$self->addCarryField('cd_vstd', 1);
    my $id = $self->ID() || 0;
    my $defaultType = $self->{'RunParams'}{'dtype'} || '';
    if($id)   {
        my $personObj = new PersonObj(db => $self->{'db'}, ID => $id, cache => $self->{'Data'}{'cache'});
        $personObj->load();
        if($personObj->ID())    {
            my $objectValues = $self->loadObjectValues($personObj);
            $self->setupValues($objectValues);
        }
    }

    my $memperm = ProcessPermissions($self->{'Data'}->{'Permissions'}, $self->{'FieldSets'}{'core'}, 'Person',);
    my($fieldsContent, undef, $scriptContent, $tabs) = $self->displayFields($memperm);
    my $newRegoWarning = '';
    if(!$id)    {
        my $lang = $self->{'Data'}{'lang'};
        my $client = $self->{'Data'}{'client'};
        my $burl = "$self->{'Data'}{'target'}?client=$client&amp;a=";
        my $transfer = $burl."PRA_T";
        my $search = $burl."INITSRCH_P";
        my $txt;

        $newRegoWarning = qq[
            <div class="alert"> 
                <div> <span class="fa fa-info"></span> <p>$txt</p> </div> </div>
        ];
    }
    my %PageData = (
        HiddenFields => $self->stringifyCarryField(),
        Target => $self->{'Data'}{'target'},
        Errors => $self->{'RunDetails'}{'Errors'} || [],
        Content => $fieldsContent || '',
        ScriptContent => $scriptContent || '',
        Title => '',
        TextTop => $newRegoWarning,
        FlowSummaryContent => personSummaryPanel($self->{'Data'}, $id) || '',
        ContinueButtonText => $self->{'Lang'}->txt('Save & Continue'),
        TextBottom => '',
    );

    my $pagedata = $self->display(\%PageData);

    return ($pagedata,0);

}

sub validate_core_details    { 
    my $self = shift;

    #my $defaultType = $self->{'RunParams'}{'dtype'} || '';
    #if($defaultType eq 'TRANSFER')   {
        #all core details are read-only for Transfer
        #$self->incrementCurrentProcessIndex();
        #$self->incrementCurrentProcessIndex();
        #return ('',2);
    #}

    my $userData = {};
    my $memperm = ProcessPermissions($self->{'Data'}->{'Permissions'}, $self->{'FieldSets'}{'core'}, 'Person',);
    ($userData, $self->{'RunDetails'}{'Errors'}) = $self->gatherFields($memperm);

#    if(!scalar(@{$self->{'RunDetails'}{'Errors'}})) {
#        if(isPossibleDuplicate($self->{'Data'}, $userData))    {
#            push @{$self->{'RunDetails'}{'Errors'}}, 'This person is a possible duplicate';
#        }
#    }

    if($self->{'RunDetails'}{'Errors'} and scalar(@{$self->{'RunDetails'}{'Errors'}})) {
        #There are errors - reset where we are to go back to the form again
        $self->decrementCurrentProcessIndex();
        return ('',2);
    }

    my $id = $self->ID() || 0;
    my $newreg = $id ? 0 : 1;
    my $personObj = new PersonObj(db => $self->{'db'}, ID => $id, cache => $self->{'Data'}{'cache'});
    $personObj->load();
    if($newreg)    {
        $userData->{'strStatus'} = 'INPROGRESS';
        $userData->{'intRealmID'} = $self->{'Data'}{'Realm'};
        $userData->{'intInternationalTransfer'} = 1 if $self->getCarryFields('itc');
    }
    $personObj->setValues($userData);
    $personObj->write();
    if($personObj->ID())    {
        if($newreg)    { 
            $self->setID($personObj->ID()); 
            $self->addCarryField('newreg',1);
        }
        $self->{'ClientValues'}{'personID'} = $personObj->ID();
        $self->{'ClientValues'}{'currentLevel'} = $Defs::LEVEL_PERSON;
        my $client = setClient($self->{'ClientValues'});
        $self->addCarryField('client',$client);
        if($newreg) {
            auditLog(
                $personObj->ID(),
                $self->{'Data'},
                'ADD',
                'PERSON',
            );
        }
#WR: SHoudl we check for duplicates here
    }

    return ('',1);
}


sub display_contact_details    { 
    my $self = shift;

    $self->addCarryField('cond_vstd', 1);
    my $id = $self->ID() || 0;
    if(!doesUserHaveAccess($self->{'Data'}, $id,'WRITE')) {
        return ('Invalid User',0);
    }
    my $personObj = new PersonObj(db => $self->{'db'}, ID => $id, cache => $self->{'Data'}{'cache'});
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
        FlowSummaryContent => personSummaryPanel($self->{'Data'}, $personObj->ID()) || '',
        ContinueButtonText => $self->{'Lang'}->txt('Save & Continue'),
        Title => '',
        TextTop => '',
        TextBottom => '',
    );
    my $pagedata = $self->display(\%PageData);

    return ($pagedata,0);

}

sub validate_contact_details    { 
    my $self = shift;
	$self->addCarryField('cond', 1);
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

    my $personObj = new PersonObj(db => $self->{'db'}, ID => $id, cache => $self->{'Data'}{'cache'});
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
    my $personObj = new PersonObj(db => $self->{'db'}, ID => $id, cache => $self->{'Data'}{'cache'});
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
        FlowSummaryContent => personSummaryPanel($self->{'Data'}, $personObj->ID()) || '',
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

    my $personObj = new PersonObj(db => $self->{'db'}, ID => $id, cache => $self->{'Data'}{'cache'});
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
    my $personObj = new PersonObj(db => $self->{'db'}, ID => $id, cache => $self->{'Data'}{'cache'});
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
        FlowSummaryContent => personSummaryPanel($self->{'Data'}, $personObj->ID()) || '',
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

    my $personObj = new PersonObj(db => $self->{'db'}, ID => $id, cache => $self->{'Data'}{'cache'});
    $personObj->load();
    $personObj->setValues($userData);
    $personObj->write();
    return ('',1);
}

sub display_registration { 
    my $self = shift;
	
	$self->addCarryField('cond_vstd', 1);   
    my $personID = $self->ID();
    if(!doesUserHaveAccess($self->{'Data'}, $personID,'WRITE')) {
        return ('Invalid User',0);
    }
    my $entityID = getLastEntityID($self->{'ClientValues'}) || 0;
    my $entityLevel = getLastEntityLevel($self->{'ClientValues'}) || 0;
    my $originLevel = $self->{'ClientValues'}{'authLevel'} || 0;

    my $client = $self->{'Data'}->{'client'};
    my $url = $self->{'Target'}."?transfer=1&rfp=".$self->getNextAction()."&".$self->stringifyURLCarryField();
    my $personObj = new PersonObj(db => $self->{'db'}, ID => $personID, cache => $self->{'Data'}{'cache'});
    $personObj->load();
    my ($dob, $gender) = $personObj->getValue(['dtDOB','intGender']); 

    my $content = '';
    my $noContinueButton = 1;

    my $lang = $self->{'Data'}{'lang'};

    $self->{'Data'}->{'AddToPage'}->add('js_bottom','file','js/regwhat.js');

    my $defaultRegistrationNature = $self->{'RunParams'}{'dnat'} || '';
    my $regoID = $self->{'RunParams'}{'rID'} || 0;
    my $entitySelection = 0;#= $originLevel == $Defs::LEVEL_CLUB ? 0 : 1;
    if(
        $entitySelection 
        and exists $self->{'SystemConfig'}{'maFlowEntitySelect'}
        and $self->{'SystemConfig'}{'maFlowEntitySelect'} == 0
    )   {
        $entitySelection = 0;
    }
    $noContinueButton = 0;
    my %regFilter = (
        'entityID' => $entityID,
        'requestID' => $self->{'RunParams'}{'prid'},
        #'requestID' => 12213,
    );
    my $request = getRequests($self->{'Data'}, \%regFilter);
    $request = $request->[0];

    if(!$request) {
        push @{$self->{'RunDetails'}{'Errors'}}, 'Invalid Person Request';
        $noContinueButton = 1;
        $content = "Person Request Details not found.";
    }
    else {
        #$request->{'personType'} = $Defs::personType{$request->{'strPersonType'}};
        #$request->{'sport'} = $Defs::sportType{$request->{'strSport'}};
        #$request->{'personLevel'} = $Defs::personLevel{$request->{'strPersonLevel'}};

        #$self->addCarryField('dnat', 'TRANSFER');
        #$self->addCarryField('dtype', $request->{'strPersonType'});
        ##$self->addCarryField('d_level', $request->{'strPersonLevel'});
        #$self->addCarryField('dsport', $request->{'strSport'});
        #$self->addCarryField('dage', $request->{'personCurrentAgeLevel'});

        #$content = runTemplate(
        #    $self->{'Data'},
        #    {
        #        requestSummary => $request,
        #    },
        #    'personrequest/generic/reg_summary.templ'
        #);
    }
    #else {
		
         $content = PersonRegisterWhat::displayPersonRegisterWhat(
            $self->{'Data'},
            $personID,
            $entityID,
            $dob || '',
            $gender || 0,
            $originLevel,
            $url,
            0,
            $regoID,
            $entitySelection, #display entity Selection
            1 #Transfer on
        );
    #}

    my %PageData = (
        HiddenFields => $self->stringifyCarryField(),
        Target => $self->{'Data'}{'target'},
        Errors => $self->{'RunDetails'}{'Errors'} || [],
        Content => $content,
        FlowSummaryContent => personSummaryPanel($self->{'Data'}, $personObj->ID()) || '',
        Title => '',
        TextTop => '',
        TextBottom => '',
        #NoContinueButton => $noContinueButton,
    );
    my $pagedata = $self->display(\%PageData);

    if($self->{'RunDetails'}{'Errors'} and scalar(@{$self->{'RunDetails'}{'Errors'}}) and ($defaultRegistrationNature eq 'TRANSFER' or $defaultRegistrationNature eq 'RENEWAL')) {
        #display the same step with error notification (for Transfers atm)
        return ($pagedata,0);
    }

    return ($pagedata,0);
}

sub process_registration { 
    my $self = shift;

    #add rego record with types etc.

    my $personID = $self->ID();
    if(!doesUserHaveAccess($self->{'Data'}, $personID,'WRITE')) {
        return ('Invalid User',0);
    }
    my $entityID = getLastEntityID($self->{'ClientValues'}) || 0;
    my $entityLevel = getLastEntityLevel($self->{'ClientValues'}) || 0;
    my $originLevel = $self->{'ClientValues'}{'authLevel'} || 0;
    my $lang = $self->{'Lang'};

    my $personObj = new PersonObj(db => $self->{'db'}, ID => $personID, cache => $self->{'Data'}{'cache'});
    $personObj->load();
    my ($dob, $gender) = $personObj->getValue(['dtDOB','intGender']); 

    my $content = '';
    my $noContinueButton = 1;

    $self->{'Data'}->{'AddToPage'}->add('js_bottom','file','js/regwhat.js');

    #my $personLevel = $self->{'RunParams'}{'d_level'};
    #$personLevel =~ s/,.*$//;
    #$self->{'RunParams'}{'d_nature'} = '';
    #$self->{'RunParams'}{'d_type'} = '';
    #$self->{'RunParams'}{'d_level'} = '';
    #$self->{'RunParams'}{'d_sport'} = '';
    #$self->{'RunParams'}{'d_age'} = '';

    my $regoID = $self->{'RunParams'}{'rID'} || 0;

    if ($self->{'RunParams'}{'prid'})   {
        my $st = qq[
            UPDATE 
                tblPersonRequest 
            SET 
                strNewPersonLevel = ? 
            WHERE 
                intPersonRequestID = ?
            LIMIT 1
        ];
        my $q = $self->{'Data'}->{'db'}->prepare($st) or query_error($st);
        $q->execute(
            $self->{'RunParams'}{'d_level'},
            $self->{'RunParams'}{'prid'}
        );
    }
    my %regFilter = (
        'entityID' => $entityID,
        'requestID' => $self->{'RunParams'}{'prid'},
    );
    my $request = getRequests($self->{'Data'}, \%regFilter);
    $request = $request->[0];

    if(!$request) {
        push @{$self->{'RunDetails'}{'Errors'}}, 'Invalid Person Request';
        $noContinueButton = 1;
        $content = "Person Request Details not found.";
    }
    else {
        #$self->addCarryField('d_nature', 'TRANSFER');
        #$self->addCarryField('d_type', $request->{'strPersonType'});
        #$self->addCarryField('d_level', $request->{'strNewPersonLevel'});
        #$self->addCarryField('d_sport', $request->{'strSport'});
        #$self->addCarryField('d_age', $request->{'personCurrentAgeLevel'});
    }

    ## NORMAL process_registration code
 
    my $personType = $self->{'RunParams'}{'d_type'} || '';
    my $personEntityRole= $self->{'RunParams'}{'d_role'} || '';
    #my $personLevel = $self->{'RunParams'}{'d_level'} || '';
	my $personLevel = $request->{'strNewPersonLevel'} || '';    
	my $sport = $self->{'RunParams'}{'d_sport'} || '';
    my $ageLevel = $self->{'RunParams'}{'d_age'} || '';
    my $existingReg = $self->{'RunParams'}{'existingReg'} || 0;
    my $changeExistingReg = $self->{'RunParams'}{'changeExisting'} || 0;
    #$existingReg = $regoID ? 1 : 0;
    #$changeExistingReg= $regoID ? 1 : 0;
    
    my $registrationNature = $self->{'RunParams'}{'d_nature'} || '';
    my $personRequestID = $self->{'RunParams'}{'prid'} || '';

    if(!doesUserHaveAccess($self->{'Data'}, $personID,'WRITE')) {
        return ('Invalid User',0);
    }

    #initial validation for required fields
    if(
        ((!$personType or !$ageLevel or !$registrationNature) and !$existingReg and !$changeExistingReg)
        or
        ((!$personType or !$ageLevel or !$registrationNature) and $changeExistingReg)
    ) {
        push @{$self->{'RunDetails'}{'Errors'}}, $lang->txt("This type of registration is not available");

        $self->decrementCurrentProcessIndex();
        return ('',2);
    }


    my $msg = '';
    if($personID)   {
        if($changeExistingReg)    {
            $self->deleteExistingReg($existingReg, $personID);
        }
        if ((! $existingReg and ! $regoID) or $changeExistingReg)  {
            my (undef, $errorMsgRego) = PersonRegisterWhat::optionsPersonRegisterWhat(
                $self->{'Data'},
                $self->{'Data'}->{'Realm'},
                $self->{'Data'}->{'RealmSubType'},
                $originLevel,
                $registrationNature,
                $personType || '',
                '',
                $personEntityRole || '',
                '',
                $personLevel || '',
                '',
                $sport || '',
                '',
                $ageLevel || '',
                $personID,
                $entityID,
                '',
                '',
                'nature',
                0
            );
            if ($errorMsgRego)  {
                push @{$self->{'RunDetails'}{'Errors'}}, $errorMsgRego;
                $self->setCurrentProcessIndex('r');
                return ('',2);
            }
        }
        if ((! $existingReg and ! $regoID) or $changeExistingReg)  {
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
                undef,
                undef,
                $personRequestID,
            );
		}
        if ($regoID && $personRequestID)    {
                my $stChange = qq[
                    UPDATE tblPersonRegistration_$self->{'Data'}->{'Realm'}
                    SET strPreviousPersonLevel = '', intPersonLevelChanged=0
                    WHERE
                        intPersonRegistrationID = ?
                    LIMIT 1
                ];
                my $q = $self->{'Data'}->{'db'}->prepare($stChange) or query_error($stChange);
                $q->execute(
                    $regoID,
                );

                $stChange = qq[
                    UPDATE
                        tblPersonRegistration_$self->{'Data'}->{'Realm'} as PR
                        INNER JOIN tblPersonRequest as Req ON (
                            PR.intPersonRequestID = Req.intPersonRequestID
                            AND PR.intPersonID = Req.intPersonID
                        )
                    SET
                        strPreviousPersonLevel = Req.strPersonLevel,
						PR.strPersonLevel = Req.strNewPersonLevel,
                        intPersonLevelChanged = 1
                    WHERE
                        Req.strPersonLevel <> ''
                        AND Req.strNewPersonLevel <> ''
                        AND Req.strPersonLevel <> Req.strNewPersonLevel
                        AND PR.intPersonRegistrationID = ?
                        AND Req.intPersonRequestID = ?
                ];
                $q = $self->{'Data'}->{'db'}->prepare($stChange) or query_error($stChange);
                $q->execute(
                    $regoID,
                    $personRequestID
                );
        }
        if ($changeExistingReg) {
            $self->moveDocuments($existingReg, $regoID, $personID);
        }
        
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
        push @{$self->{'RunDetails'}{'Errors'}}, $lang->txt("Transfer failed, cannot find registration.");
    }
    else    {
        if(!$existingReg or $changeExistingReg)   {
            $self->addCarryField('rID',$regoID);
            $self->addCarryField('pType',$personType);
        }
    }

    if($self->{'RunDetails'}{'Errors'} and scalar(@{$self->{'RunDetails'}{'Errors'}})) {
        #There are errors - reset where we are to go back to the form again
        $self->decrementCurrentProcessIndex();
        $self->decrementCurrentProcessIndex();
        return ('',2);
    }

    return ('',1);
}

sub display_products { 
    my $self = shift;

    $self->addCarryField('payMethod','');
    $self->addCarryField('d_vstd', 1);
    my $personID = $self->ID();
    if(!doesUserHaveAccess($self->{'Data'}, $personID,'WRITE')) {
        return ('Invalid User',0);
    }
    my $entityID = getLastEntityID($self->{'ClientValues'}) || 0;
    my $entityLevel = getLastEntityLevel($self->{'ClientValues'}) || 0;
    my $originLevel = $self->{'ClientValues'}{'authLevel'} || 0;
    my $regoID = $self->{'RunParams'}{'rID'} || 0;
    my $client = $self->{'Data'}->{'client'};
print STDERR "DISPLAY_PRODUCTS FOR $personID $regoID\n";

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

    if (! $regoID or ! $personID)  {
        my $lang = $self->{'Data'}{'lang'};
        push @{$self->{'RunDetails'}{'Errors'}}, $lang->txt("Transfer failed, cannot find registration.");
        $self->setCurrentProcessIndex(1);
        #$self->decrementCurrentProcessIndex();
        #$self->decrementCurrentProcessIndex();
        return ('',2);
    }
    my $personObj = new PersonObj(db => $self->{'db'}, ID => $personID, cache => $self->{'Data'}{'cache'});
    $personObj->load();

    if($regoID) {
        my $nationality = $personObj->getValue('strISONationality') || ''; 
        $rego_ref->{'Nationality'} = $nationality;

        cleanRegoTransactions($self->{'Data'},$regoID, $personID, $Defs::LEVEL_PERSON);
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
        if (! $self->{'RunDetails'}{'Errors'} and  ! scalar(@{$self->{'RunDetails'}{'Errors'}})) {
            push @{$self->{'RunDetails'}{'Errors'}}, $self->{'Lang'}->txt("Invalid Registration ID");
            if($self->{'RunDetails'}{'Errors'} and scalar(@{$self->{'RunDetails'}{'Errors'}})) {
                #There are errors - reset where we are to go back to the form again
                $self->setCurrentProcessIndex('r');
                return ('',2);
            }
        }
    }

    if($self->{'RunDetails'}{'Errors'} and scalar(@{$self->{'RunDetails'}{'Errors'}})) {
        #There are errors - reset where we are to go back to the form again
        #$self->setCurrentProcessIndex(1);
        #$self->decrementCurrentProcessIndex();
        #return ('',2);
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
        FlowSummaryContent => personSummaryPanel($self->{'Data'}, $personObj->ID()) || '',
        Title => '',
        TextTop => '',
        TextBottom => '',
        ContinueButtonText => $self->{'Lang'}->txt('Save & Continue'),
    );
    my $pagedata = $self->display(\%PageData);

    return ($pagedata,0);

}

sub process_products { 
    my $self = shift;

print STDERR "~~~~~~~~~~~~~~~~~~~~~~~~~~~PROCESS PRODUCTS";
    $self->addCarryField('seenProds', 1);
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

cleanRegoTransactions($self->{'Data'},$regoID, $personID, $Defs::LEVEL_PERSON);
    my ($resultHTML, $error) = checkMandatoryProducts($self->{'Data'}, $personID, $Defs::LEVEL_PERSON, $self->{'RunParams'});
    if ($error) {
        push @{$self->{'RunDetails'}{'Errors'}}, $resultHTML;
        $self->setCurrentProcessIndex('p');
        return ('',2);
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
            processTransLog($self->{'Data'}->{'db'}, '', 'OK', 'OK', 'APPROVED', $logID, \%Settings, undef, undef, '', '', '', '', '', '','',1);
            UpdateCart($self->{'Data'}, undef, $self->{'Data'}->{'client'}, undef, 'OK', $logID);
            product_apply_transaction($self->{'Data'},$logID);
        }
    $self->addCarryField('paymentType',$paymentType);
    $self->addCarryField('markPaid',$markPaid);
####

    $self->addCarryField('txnIds',$txnIds);
print STDERR "TXN IDS" . $txnIds;

    return ('',1);
}

sub display_documents { 
    my $self = shift;
	
    $self->addCarryField('r_vstd', 1);
    my $personID = $self->ID();
    if(!doesUserHaveAccess($self->{'Data'}, $personID,'WRITE')) {
        return ('Invalid User',0);
    }
	my $entityID = getLastEntityID($self->{'ClientValues'}) || 0;
    my $entityLevel = getLastEntityLevel($self->{'ClientValues'}) || 0;
    my $originLevel = $self->{'ClientValues'}{'authLevel'} || 0;
    my $regoID = $self->{'RunParams'}{'rID'} || 0;
    if (! $regoID)  {

    }
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
    if (! $regoID or ! $personID)  {
        my $lang = $self->{'Data'}{'lang'};
        push @{$self->{'RunDetails'}{'Errors'}}, $lang->txt("Transfer failed, cannot find registration.");
        $self->setCurrentProcessIndex(1);
        #$self->decrementCurrentProcessIndex();
        return ('',2);
    }
	my $personObj = new PersonObj(db => $self->{'db'}, ID => $personID, cache => $self->{'Data'}{'cache'});
    $personObj->load();
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
        #if (! $content)   {
        #    $self->incrementCurrentProcessIndex();
        #    return ('',2);
        #}
	my %PageData = (
        HiddenFields => $self->stringifyCarryField(),
        Target => $self->{'Data'}{'target'},
        Errors => $self->{'RunDetails'}{'Errors'} || [],
        FlowSummaryContent => personSummaryPanel($self->{'Data'}, $personObj->ID()) || '',
        Content => '',
        Title => '',
        TextTop => '',
        Documents => $content,
        TextBottom => '',
        ContinueButtonText => $self->{'Lang'}->txt('Save & Continue'),
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
	my $personObj;
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
		$personObj = new PersonObj(db => $self->{'db'}, ID => $personID, cache => $self->{'Data'}{'cache'});
    	$personObj->load();
		my $nationality = $personObj->getValue('strISONationality') || ''; 
        my $itc = $personObj->getValue('intInternationalTransfer') || '';
        $rego_ref->{'Nationality'} = $nationality;
        $rego_ref->{'InternationalTransfer'} = $itc;
    }
    if (! $regoID or ! $personID)  {
        my $lang = $self->{'Data'}{'lang'};
        push @{$self->{'RunDetails'}{'Errors'}}, $lang->txt("Transfer failed, cannot find registration.");
        $self->setCurrentProcessIndex(1);
        #$self->decrementCurrentProcessIndex();
        return ('',2);
    }

    #check for uploaded document
    my ($error_message, $isRequiredDocPresent) = checkUploadedRegoDocuments($self->{'Data'}, 
            $regoID, 
            $client, 
            $entityLevel, 
            $originLevel, 
            $rego_ref, 
            $entityID, 
            $personID, 
            {},
	);
    if(!$isRequiredDocPresent){
	#if(1==1){
    	push @{$self->{'RunDetails'}{'Errors'}}, $self->{'Lang'}->txt("Required Document Missing") . $error_message;

        if($self->{'RunDetails'}{'Errors'} and scalar(@{$self->{'RunDetails'}{'Errors'}})) {
            #There are errors - reset where we are to go back to the form again
            $self->decrementCurrentProcessIndex();
            return ('',2);
        }
		#my $labelBackBtn = 'Back to Documents';
    	#my %PageData = (
        #HiddenFields => $self->stringifyCarryField(),
        #Target => $self->{'Data'}{'target'},
        #Errors => $self->{'RunDetails'}{'Errors'} || [],
        #FlowSummary => buildSummaryData($self->{'Data'}, $personObj) || '',
        #FlowSummaryTemplate => 'registration/person_flow_summary.templ',
        #Content => '',
        #Title => '',
        #TextTop => $content,
        #TextBottom => '',
        #NoContinueButton => 1,       
		#Back => $labelBackBtn, 
    #);
      #my $pagedata = $self->display(\%PageData);
     
    	#return ($pagedata,0);

    }
    return ('',1);
}

sub display_summary { 
    my $self = shift;

    $self->addCarryField('p_vstd', 1);

    my $personObj;
    my $personID = $self->ID();
    if(!doesUserHaveAccess($self->{'Data'}, $personID,'WRITE')) {
        return ('Invalid User',0);
    }
    my $entityID = getLastEntityID($self->{'ClientValues'}) || 0;
    my $entityLevel = getLastEntityLevel($self->{'ClientValues'}) || 0;
    my $originLevel = $self->{'ClientValues'}{'authLevel'} || 0;
    my $regoID = $self->{'RunParams'}{'rID'} || 0;
    my $client = $self->{'Data'}->{'client'};
    my $lang = $self->{'Data'}{'lang'};
    my $gatewayConfig = undef;

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

    if (! $regoID or ! $personID)  {
        my $lang = $self->{'Data'}{'lang'};
        push @{$self->{'RunDetails'}{'Errors'}}, $lang->txt("Transfer failed, cannot find registration.");
        $self->setCurrentProcessIndex(1);
        #$self->decrementCurrentProcessIndex();
        #$self->decrementCurrentProcessIndex();
        return ('',2);
    }

    #if (! $self->{'RunParams'}{'seenProds'})  {
     #   push @{$self->{'RunDetails'}{'Errors'}}, $lang->txt("Transfer failed, you must step through Payments screen.");
     #   $self->setCurrentProcessIndex('p');
     #   return ('',2);
    #}
    my $payMethod = '';
    if($regoID) {
        $personObj = new PersonObj(db => $self->{'db'}, ID => $personID, cache => $self->{'Data'}{'cache'});
        $personObj->load();
        my $nationality = $personObj->getValue('strISONationality') || ''; 
        $rego_ref->{'Nationality'} = $nationality;
    
        $self->addCarryField('txnIds', $self->{'RunParams'}{'txnIds'} || 0);
        $self->addCarryField('payMethod', $self->{'RunParams'}{'payMethod'} || '');
        $payMethod = $self->{'RunParams'}{'payMethod'} || '';

        my $hiddenFields = $self->getCarryFields();
        $hiddenFields->{'rfp'} = 'c';#$self->{'RunParams'}{'rfp'};
        $hiddenFields->{'__cf'} = $self->{'RunParams'}{'__cf'};
        $hiddenFields->{'cA'} = "TRANSFER";
        ($content, $gatewayConfig) = displayRegoFlowSummary(
            $self->{'Data'}, 
            $regoID, 
            $client, 
            $originLevel, 
            $rego_ref, 
            $entityID, 
            $personID, 
            $hiddenFields,
		    $self->stringifyURLCarryField(),
        );
        $content = '' if ! $content;
        if (! $content)  {
            my $lang = $self->{'Data'}{'lang'};
            push @{$self->{'RunDetails'}{'Errors'}}, $lang->txt("Transfer failed, cannot find registration.");
        $self->setCurrentProcessIndex(1);
        #    $self->decrementCurrentProcessIndex();
        #    $self->decrementCurrentProcessIndex();
        #    $self->decrementCurrentProcessIndex();
        #    $self->decrementCurrentProcessIndex();
            return ('',2);
        }
        

    }
    else    {
        my $lang = $self->{'Data'}{'lang'};
        push @{$self->{'RunDetails'}{'Errors'}}, $self->{'Lang'}->txt("Invalid Registration ID");
    }
    if($self->{'RunDetails'}{'Errors'} and scalar(@{$self->{'RunDetails'}{'Errors'}})) {
        #There are errors - reset where we are to go back to the form again
        $self->decrementCurrentProcessIndex();
        return ('',2);
    }

    my $initialTaskAssigneeLevel = getInitialTaskAssignee(
        $self->{'Data'},
        $personID,
        $regoID,
        0
    );

    my %Config = (
        HiddenFields => $self->stringifyCarryField(),
        Target => $self->{'Data'}{'target'},
        ContinueButtonText => $self->{'Lang'}->txt('Submit to '. $initialTaskAssigneeLevel),
    );
    if ($gatewayConfig->{'amountDue'} and $payMethod eq 'now')    {
        ## Change Target etc
        %Config = (
            HiddenFields => $gatewayConfig->{'HiddenFields'},
            Target => $gatewayConfig->{'Target'},
            ContinueButtonText => $self->{'Lang'}->txt('Proceed to Payment and Submit to [_1]', $initialTaskAssigneeLevel),
        );
    }
    my %PageData = (
        Errors => $self->{'RunDetails'}{'Errors'} || [],
        FlowSummaryContent => personSummaryPanel($self->{'Data'}, $personObj->ID()) || '',
        Content => '',
        Title => '',
        TextTop => $content,
        TextBottom => '',
        HiddenFields => $Config{'HiddenFields'},
        Target => $Config{'Target'},
        ContinueButtonText => $Config{'ContinueButtonText'},
    );
    my $pagedata = $self->display(\%PageData);

    return ($pagedata,0);

}

sub display_complete { 
    my $self = shift;
    my $personObj;
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
    my $gateways = '';
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
        $personObj = new PersonObj(db => $self->{'db'}, ID => $personID, cache => $self->{'Data'}{'cache'});
        $personObj->load();
        my $nationality = $personObj->getValue('strISONationality') || ''; 
        $rego_ref->{'Nationality'} = $nationality;

        my $run = $self->{'RunParams'}{'run'} || 0;
        if($self->{'RunParams'}{'newreg'} and ! $run)  {
                #$self->{'RunParams'}{'run'} = 1;
                #$self->addCarryField('run',1);
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
        ($content, $gateways) = displayRegoFlowComplete(
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
        #FlowSummary => buildSummaryData($self->{'Data'}, $personObj) || '',
        #FlowSummaryTemplate => 'registration/person_flow_summary.templ',
        processStatus => 1,
        Content => '',
        Title => $self->{'Data'}{'lang'}->txt('Transfer Submitted to MA'),
        TextTop => $content,
        TextBottom => '',
        NoContinueButton => 1,
    );

    my $pagedata = $self->display(\%PageData);

    return ($pagedata,0);

}

sub buildSummaryData    {
    my ($Data, $personObj) = @_;

    return {} if !$personObj;
    return {} if !$personObj->ID();
    my $isocountries  = getISOCountriesHash();
    my %summary = (
        'name' => $personObj->name(),
        'dob' => $personObj->getValue('dtDOB'),
        'gender' => $Defs::PersonGenderInfo{$personObj->getValue('intGender')},
        'nationality' => $isocountries->{$personObj->getValue('strISONationality')},
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
            strISOCountry
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
            intOtherPersonIdentifierTypeID

            intMinorMoveOtherThanFootball
            intMinorDistance
            intMinorEU
            intMinorNone
            intNatCustomLU1
            intNatCustomLU2
            intNatCustomLU3
            intNatCustomLU4
            intNatCustomLU5
            intNatCustomLU6
            intNatCustomLU7
            intNatCustomLU8
            intNatCustomLU9
            intNatCustomLU10

            intInternationalTransfer

strLocalTitle
strPreferredName
intLocalLanguage
dtDeath
strFirstClubName
strMaidenName
strPhoneWork
strPhoneMobile
strFax
strEmail
strCityOfResidence
strEmergContName
strEmergContRel
strEmergContNo
strP1FName
strP1SName
strP2FName
strP2SName
strP1Email
strP2Email
strP1Phone
strP2Phone
strP1Salutation
strP2Salutation
intP1Gender
intP2Gender
strP1Phone2
strP2Phone2
strP1PhoneMobile
strP2PhoneMobile
strP1Email2
strP2Email2
intMedicalConditions
intAllergies
intAllowMedicalTreatment
intConsentSignatureSighted
strMotherCountry
strFatherCountry
strNatCustomStr1
strNatCustomStr2
strNatCustomStr3
strNatCustomStr4
strNatCustomStr5
strNatCustomStr6
strNatCustomStr7
strNatCustomStr8
strNatCustomStr9
strNatCustomStr10
strNatCustomStr11
strNatCustomStr12
strNatCustomStr13
strNatCustomStr14
strNatCustomStr15
dblNatCustomDbl1
dblNatCustomDbl2
dblNatCustomDbl3
dblNatCustomDbl4
dblNatCustomDbl5
dblNatCustomDbl6
dblNatCustomDbl7
dblNatCustomDbl8
dblNatCustomDbl9
dblNatCustomDbl10
dtNatCustomDt1
dtNatCustomDt2
dtNatCustomDt3
dtNatCustomDt4
dtNatCustomDt5
intNatCustomBool1
intNatCustomBool2
intNatCustomBool3
intNatCustomBool4
intNatCustomBool5
strISOMotherCountry
strISOFatherCountry
        )) {
            $values{$field} = $object->getValue($field);
        }
    }
    return \%values;
}

sub deleteExistingReg {
    my $self = shift;
    my ($regoID, $personID) = @_;
    
    my $realmID = $self->{'Data'}->{'Realm'};
    my $st = qq[
        DELETE TL FROM 
            tblTransLog AS TL
            INNER JOIN tblTransactions AS TX
                ON TL.intLogID = TX.intTransLogID
        WHERE 
            TX.intPersonRegistrationID = ?
            AND (TL.intStatus = 0 OR (TL.intStatus= 1 and TL.intAmount>0))
            AND TL.intRealmID = ?
    ];
    my $q = $self->{'Data'}->{'db'}->prepare($st);
    $q->execute($regoID, $realmID);

    $st = qq[
        DELETE FROM 
            tblTransactions 
        WHERE 
            intPersonRegistrationID = ?
            AND (intStatus = 0 OR (intStatus=1 AND curAmount = 0))
            AND intRealmID = ?
            AND intID = ?
    ];
    $q = $self->{'Data'}->{'db'}->prepare($st);
    $q->execute($regoID, $realmID, $personID);

    $st = qq[
        DELETE FROM 
            tblPersonRegistration_$self->{'Data'}->{'Realm'} 
        WHERE 
            intPersonRegistrationID = ?
            AND strStatus = 'INPROGRESS'
            AND intPersonID = ?
    ];
    $q=$self->{'Data'}->{'db'}->prepare($st);
    $q->execute($regoID, $personID);

    $q->finish();
    return 1;
}

sub moveDocuments {
    my $self = shift;
    my ($oldRegoID, $newRegoID) = @_;

    my $st = qq[
        UPDATE tblDocuments
        SET intPersonRegistrationID = ?
        WHERE intPersonRegistrationID = ?
    ];
    my $q=$self->{'Data'}->{'db'}->prepare($st);
    $q->execute($oldRegoID, $newRegoID);
    $q->finish();
    return 1;
}

 
sub Navigation {
    #May need to be overriden in child class to define correct order of steps
    my $self = shift;
	
    my $lang = $self->{'Data'}{'lang'};
    my $navstring = '';
    my $meter = '';
    my @navoptions = ();
    my $step = 1;
    my $step_in_future = 0;
    my $noNav = $self->{'ProcessOrder'}[$self->{'CurrentIndex'}]{'NoNav'} || 0;
    my $noGoingBack = $self->{'ProcessOrder'}[$self->{'CurrentIndex'}]{'NoGoingBack'} || 0;
    return '' if $noNav;
    my $startingStep = $self->{'RunParams'}{'_ss'} || '';
    my $includeStep = 1;
    $includeStep = 0 if $startingStep;
    for my $i (0 .. $#{$self->{'ProcessOrder'}})    {
        my $current = 0;
        my $name = $self->{'Lang'}->txt($self->{'ProcessOrder'}[$i]{'label'} || '');
        my $action = $self->{'Lang'}->txt($self->{'ProcessOrder'}[$i]{'action'} || ''); 
		
        $name .= qq[<span class="circleBg"><i class="fa fa-check tab-ticked"></i></span>] if ($name and $self->{'RunParams'}{$action . '_vstd'});
		if($startingStep and $self->{'ProcessOrder'}[$i]{'action'} eq $startingStep)   {
            $includeStep = 1;
        }
        next if !$includeStep;
        next if($self->{'ProcessOrder'}[$i]{'NoNav'});
        next if($self->{'ProcessOrder'}[$i]{'NoDisplayInNav'});
        if($name)   {
            $current = 1 if $i == $self->{'CurrentIndex'};
            push @navoptions, [
                $name,
                $current || $step_in_future || 0,
            ];
            my $currentclass = '';
            $currentclass = 'active' if $current;
            $currentclass = 'next' if $step_in_future;
            $currentclass ||= 'previous';
            $meter = $step if $current;
            my $showlink = 0;
            $showlink = 1 if(!$current and !$step_in_future);
            $showlink = 0 if($self->{'ProcessOrder'}[$i]{'noRevisit'});
            $showlink = 0 if $noGoingBack;
            my $linkURL = $self->{'Target'}."?rfp=".$self->{'ProcessOrder'}[$i]{'action'}."&".$self->stringifyURLCarryField();
            $self->{'RunDetails'}{'DirectLinks'}[$i] = $linkURL;

            my $js = '';
            if($step_in_future) {
                $js = qq[onclick="alert('].$lang->txt('Use the Continue button to go to the next page').qq[');return false;" ];
            }
			my $inlineStyle = '';
			$inlineStyle = $currentclass eq 'previous' || $currentclass eq 'next' ? 'style="font-weight: normal;"' : '';
            my $link = qq[<a href="$linkURL" class = "$currentclass" $inlineStyle $js><small>$name</small></a>];

            $navstring .= qq[<li class = "$currentclass">$link</li>];
            $step_in_future = 2 if $current;
            $step++;
        }
    }
    my $returnHTML = '';
    $returnHTML .= qq[<ul class = "nav nav-tabs">$navstring</ul> ] if $navstring;


    if(wantarray)   {
        return ($returnHTML, \@navoptions);
    }
    return $returnHTML || '';
}

 

