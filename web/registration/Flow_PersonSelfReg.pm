package Flow_PersonSelfReg;

use strict;
use lib '.', '..', '../..', "../../..", "../dashboard", "../user", "user";
use Flow_BaseObj;
our @ISA =qw(Flow_BaseObj);

use TTTemplate;
use CGI qw(param);
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
use FieldMessages;
use TermsConditions;


sub setProcessOrder {
    my $self = shift;
  
    my $dtype = param('dtype') || '';
    my $typename = $Defs::personType{$dtype} || '';
    my $regname = $typename
        ? $typename .' Registration'
        : 'Registration';
    $self->{'ProcessOrder'} = [       
        {
            'action' => 'cd',
            'function' => 'display_core_details',
            'label'  => 'Personal Details',
            'title'  => "$regname - Enter Personal Information",
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
            'label'  => 'Contact Details',
            'fieldset'  => 'contactdetails',
            'title'  => "$regname - Enter Contact Information",
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
            'title'  => "$regname - Choose Registration Type",
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
            'title'  => "$regname - Enter Certifications",
            'NoNav' => $dtype eq 'PLAYER' ? 1 : 0,
        },
        {
            'action' => 'pcert',
            'function' => 'process_certifications',
            'fieldset'  => 'certifications',
        },
        {
            'action' => 'd',
            'function' => 'display_documents',
            'label'  => 'Documents',
            'title'  => "$regname - Upload Documents",
        },
        {
            'action' => 'du',
            'function' => 'process_documents',
        },
         {
            'action' => 'p',
            'function' => 'display_products',
            'label'  => 'License',
            'title'  => "$regname - Confirm License",
        },
        {
            'action' => 'pu',
            'function' => 'process_products',
        },
       {
            'action' => 'summ',
            'function' => 'display_summary',
            'label'  => 'Summary',
            'title'  => "$regname - Summary",
        },
       {
            'action' => 'c',
            'function' => 'display_complete',
            'label'  => 'Complete',
            'title'  => "$regname - Submitted",
            'NoGoingBack' => 1,
            'NoDisplayInNav' => 1,
        },
    ];
}

sub setupValues    {
    my $self = shift;
    my ($values) = @_;
    $values ||= {};
    $values->{'defaultType'} = $self->{'RunParams'}{'dtype'} || '';
    $values->{'itc'} = $self->{'RunParams'}{'itc'} || 0;
    $values->{'selfRego'} = 1;
    $values->{'minorRego'} = $self->{'RunParams'}{'minorRego'} || 0;
    if($self->{'Data'}{'User'}) {
        $values->{'strP1FName'} = $self->{'Data'}{'User'}->name();
        $values->{'strP1SName'} = $self->{'Data'}{'User'}->familyname();
    }
    my $client = $self->{'Data'}{'client'};
    $values->{'BaseURL'} = "$self->{'Data'}{'target'}?client=$client&amp;a=";
    $self->{'FieldSets'} = personFieldsSetup($self->{'Data'}, $values);
}

sub display_core_details    { 
    my $self = shift;

    my $id = $self->ID() || 0;
    my $defaultType = $self->{'RunParams'}{'dtype'} || '';
    my $itc = $self->{'RunParams'}{'itc'} || 0;
    if($id)   {
        if(!doesSelfUserHaveAccess($self->{'Data'}, $id, $self->{'UserID'})) {
            return ('Invalid User',0);
        }
        my $personObj = new PersonObj(db => $self->{'db'}, ID => $id, cache => $self->{'Data'}{'cache'});
        $personObj->load();
        if($personObj->ID())    {
            my $objectValues = $self->loadObjectValues($personObj);
            $objectValues->{'itc'} = $itc;
            $self->setupValues($objectValues);
        }
    }

    my $memperm = ProcessPermissions($self->{'Data'}->{'Permissions'}, $self->{'FieldSets'}{'core'}, 'PersonRegoForm',);
    my $fieldMessages = getFieldMessages($self->{'Data'}, 'person', $self->{'Data'}->{'lang'}->getLocale());
    my($fieldsContent, undef, $scriptContent, $tabs) = $self->displayFields($memperm,'', $fieldMessages);
    my $newRegoWarning = '';
    my $bypassduplicate = '';
    if(!$id)    {
        my $lang = $self->{'Data'}{'lang'};
        my $client = $self->{'Data'}{'client'};
        my $burl = "$self->{'Data'}{'target'}?client=$client&amp;a=";
        my $transfer = $burl."PRA_T";
        my $search = $burl."INITSRCH_P";
        my $txt;

        if($defaultType eq $Defs::PERSON_TYPE_PLAYER and $self->{'SystemConfig'}{'allowPersonRequest'}) {
            $txt = $lang->txt('Please check that this player has not been registered with another club?')
                .qq[ <a href = "$transfer">].$lang->txt('If yes, they need to apply for a Transfer.').'</a>'
        }
        else {
        }

        $newRegoWarning = qq[
            <div class="alert"> 
                <div> <span class="fa fa-info"></span> <p>$txt</p> </div> </div>
        ] if $txt;
        if($self->{'RunDetails'}{'FoundDuplicate'}) {
            $bypassduplicate = qq[
                <p>
                <a href = "#" id = "btn-notduplicate" class = "btn-main btn-proceed">].$lang->txt('I have validated that this person is not a duplicate').qq[</a>
                </p>
                <script>
                    jQuery(document).ready(function(){
                        jQuery('#btn-notduplicate').click(function(e)   {
                            e.preventDefault();
                            jQuery('#flowFormID').append('<input type = "hidden" name = "bd" value = "1">');
                            jQuery('#flowFormID').submit();
                        });

                    });
                </script>
            ];
        }
    }
    my $panel = '';
    $panel = personSummaryPanel($self->{'Data'}, $id,1) if $id;
    my %PageData = (
        HiddenFields => $self->stringifyCarryField(),
        Target => $self->{'Data'}{'target'},
        Errors => $self->{'RunDetails'}{'Errors'} || [],
        Content => $fieldsContent || '',
        ScriptContent => $scriptContent || '',
        FlowSummaryContent => $panel || '',
        Title => '',
        PageInfo => $newRegoWarning,
        TextTop => $bypassduplicate,
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
    my $memperm = ProcessPermissions($self->{'Data'}->{'Permissions'}, $self->{'FieldSets'}{'core'}, 'PersonRegoForm',);
    ($userData, $self->{'RunDetails'}{'Errors'}) = $self->gatherFields($memperm);

    my $id = $self->ID() || 0;
    if($id) {
        if(!doesSelfUserHaveAccess($self->{'Data'}, $id, $self->{'UserID'})) {
            return ('Invalid User',0);
        }
    }
    my $lang = $self->{'Data'}{'lang'};
    if(!scalar(@{$self->{'RunDetails'}{'Errors'}})) {
        if(!$id and isPossibleDuplicate($self->{'Data'}, $userData) and !$self->{'RunParams'}{'bd'})    {
            my $msg = $lang->txt('This person is a possible duplicate.');
            $msg .= $lang->txt(qq[  If you have checked and this person is not a duplicate, then click the button below.]);
            push @{$self->{'RunDetails'}{'Errors'}}, $msg;
            $self->{'RunDetails'}{'FoundDuplicate'} = 1;
        }
    }

    if($self->{'RunDetails'}{'Errors'} and scalar(@{$self->{'RunDetails'}{'Errors'}})) {
        #There are errors - reset where we are to go back to the form again
        $self->decrementCurrentProcessIndex();
        return ('',2);
    }

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
            #Add permissions to user
            my $st = qq[
                INSERT INTO tblSelfUserAuth (
                    intSelfUserID,
                    intEntityTypeID,
                    intEntityID,
                    intMinor
                )
                VALUES (
                    ?,
                    $Defs::LEVEL_PERSON,
                    ?,
                    ?
                )
            ];
            my $q = $self->{'db'}->prepare($st);
            $q->execute(
                $self->{'UserID'},
                $personObj->ID(),
                $self->{'RunParams'}{'minorRego'} || 0,
            );
        }
        if($self->{'RunParams'}{'d_strTerms'})  {
            logTermsAcceptance($self->{'Data'}, 'SELFREG', $self->{'UserID'}, $personObj->ID());
        }
        $self->{'ClientValues'}{'personID'} = $personObj->ID();
        $self->{'ClientValues'}{'currentLevel'} = $Defs::LEVEL_PERSON;
        my $client = setClient($self->{'ClientValues'});
        $self->addCarryField('client',$client);
        if($newreg) {
            auditLog(
                $personObj->ID(),
                $self->{'Data'},
                'Add',
                'Person',
            );
        }
#WR: SHoudl we check for duplicates here
    }

    return ('',1);
}

sub display_contact_details    { 
    my $self = shift;

    my $id = $self->ID() || 0;
    if(!doesSelfUserHaveAccess($self->{'Data'}, $id, $self->{'UserID'})) {
        return ('Invalid User',0);
    }
    my $personObj = new PersonObj(db => $self->{'db'}, ID => $id, cache => $self->{'Data'}{'cache'});
    $personObj->load();
    if($personObj->ID())    {
        my $objectValues = $self->loadObjectValues($personObj);
        $self->setupValues($objectValues);
    }
    my $memperm = ProcessPermissions($self->{'Data'}->{'Permissions'}, $self->{'FieldSets'}{'contactdetails'}, 'PersonRegoForm',);
    my $fieldMessages = getFieldMessages($self->{'Data'}, 'person', $self->{'Data'}->{'lang'}->getLocale());
    my($fieldsContent, undef, $scriptContent, $tabs) = $self->displayFields($memperm,'',$fieldMessages);
    my %PageData = (
        HiddenFields => $self->stringifyCarryField(),
        Target => $self->{'Data'}{'target'},
        Errors => $self->{'RunDetails'}{'Errors'} || [],
        Content => $fieldsContent || '',
        ScriptContent => $scriptContent || '',
        FlowSummaryContent => personSummaryPanel($self->{'Data'}, $personObj->ID(),1) || '',
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
    my $memperm = ProcessPermissions($self->{'Data'}->{'Permissions'}, $self->{'FieldSets'}{'contactdetails'}, 'PersonRegoForm',);
    ($userData, $self->{'RunDetails'}{'Errors'}) = $self->gatherFields($memperm);
    my $id = $self->ID() || 0;
    if(!$id)    {
        push @{$self->{'RunDetails'}{'Errors'}}, 'Invalid Person';
    }
    if(!doesSelfUserHaveAccess($self->{'Data'}, $id, $self->{'UserID'})) {
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
    if(!doesSelfUserHaveAccess($self->{'Data'}, $id, $self->{'UserID'})) {
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
        FlowSummaryContent => personSummaryPanel($self->{'Data'}, $personObj->ID(),1) || '',
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
    if(!doesSelfUserHaveAccess($self->{'Data'}, $id, $self->{'UserID'})) {
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

    #$self->addCarryField('','');
    my $personID = $self->ID();
    if(!doesSelfUserHaveAccess($self->{'Data'}, $personID, $self->{'UserID'})) {
        return ('Invalid User',0);
    }
    my $entityID = $self->{'RunParams'}{'de'} || 0;
    my $originLevel = $Defs::LEVEL_PERSON;

    my $client = $self->{'Data'}->{'client'};
    my $url = $self->{'Target'}."?rfp=".$self->getNextAction()."&".$self->stringifyURLCarryField();
    my $personObj = new PersonObj(db => $self->{'db'}, ID => $personID, cache => $self->{'Data'}{'cache'});
    $personObj->load();
    my ($dob, $gender) = $personObj->getValue(['dtDOB','intGender']); 

    my $content = '';
    my $noContinueButton = 1;

    my $lang = $self->{'Data'}{'lang'};

    $self->{'Data'}->{'AddToPage'}->add('js_bottom','file',$Defs::base_url.'/js/regwhat.js');

    my $defaultRegistrationNature = $self->{'RunParams'}{'dnat'} || '';
    my $regoID = $self->{'RunParams'}{'rID'} || 0;
    my $entitySelection = 1;
    $entitySelection = 0 if $entityID;
    if($defaultRegistrationNature eq 'TRANSFER')   {
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
            $request->{'personType'} = $Defs::personType{$request->{'strPersonType'}};
            $request->{'sport'} = $Defs::sportType{$request->{'strSport'}};
            $request->{'personLevel'} = $Defs::personLevel{$request->{'strPersonLevel'}};

            $self->addCarryField('d_nature', 'TRANSFER');
            $self->addCarryField('d_type', $request->{'strPersonType'});
            $self->addCarryField('d_level', $request->{'strPersonLevel'});
            $self->addCarryField('d_sport', $request->{'strSport'});
            $self->addCarryField('d_age', $request->{'personCurrentAgeLevel'});

            $content = runTemplate(
                $self->{'Data'},
                {
                    requestSummary => $request,
                },
                'personrequest/generic/reg_summary.templ'
            );
        }
    }
    elsif($defaultRegistrationNature eq 'RENEWAL') {
        my $rawDetails;
        ($content, $rawDetails) = getRenewalDetails($self->{'Data'}, $self->{'RunParams'}{'rtargetid'});

        if(!$content or !$rawDetails) {
            push @{$self->{'RunDetails'}{'Errors'}}, $lang->txt('Invalid Renewal Details');
            $content = $lang->txt("No record found.");
        }

        $self->addCarryField('d_nature', 'RENEWAL');
        $self->addCarryField('d_type', $rawDetails->{'strPersonType'});
        $self->addCarryField('d_level', $rawDetails->{'strPersonLevel'});
        $self->addCarryField('d_sport', $rawDetails->{'strSport'});
        $self->addCarryField('d_age', $rawDetails->{'newAgeLevel'}); # if $rawDetails->{'strPersonType'} eq $Defs::PERSON_TYPE_PLAYER;
        $self->addCarryField('d_role', $rawDetails->{'strPersonEntityRole'});
    }
    else {		
         $content = displayPersonRegisterWhat(
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
        );
		
    }

    my %PageData = (
        HiddenFields => $self->stringifyCarryField(),
        Target => $self->{'Data'}{'target'},
        Errors => $self->{'RunDetails'}{'Errors'} || [],
        Content => $content,
        FlowSummaryContent => personSummaryPanel($self->{'Data'}, $personObj->ID(),1) || '',
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
    my $personType = $self->{'RunParams'}{'d_type'} || '';
    my $personEntityRole= $self->{'RunParams'}{'d_role'} || '';
    my $personLevel = $self->{'RunParams'}{'d_level'} || '';
    my $sport = $self->{'RunParams'}{'d_sport'} || '';
    my $ageLevel = $self->{'RunParams'}{'d_age'} || '';
    my $existingReg = $self->{'RunParams'}{'existingReg'} || 0;
    my $changeExistingReg = $self->{'RunParams'}{'changeExisting'} || 0;
    my $registrationNature = $self->{'RunParams'}{'d_nature'} || '';
#    $registrationNature =~ s/,.*$//g;
    my $personRequestID = $self->{'RunParams'}{'prid'} || '';
    my (undef, $rawDetails) = getRenewalDetails($self->{'Data'}, $self->{'RunParams'}{'rtargetid'});
    my $entityID = $self->{'RunParams'}{'d_eId'} || $self->{'RunParams'}{'de'} || $rawDetails->{'intEntityID'};
    my $entityLevel = $self->{'RunParams'}{'d_etype'} || '';
    my $originLevel = $Defs::LEVEL_PERSON;
    my $lang = $self->{'Lang'};

    my $personID = $self->ID() || 0;
    if(!doesSelfUserHaveAccess($self->{'Data'}, $personID, $self->{'UserID'})) {
        return ('Invalid User',0);
    }
    #if(!doesUserHaveEntityAccess($self->{'Data'}, $entityID,'WRITE')) {
        #return ('Invalid User Entity',0);
    #}
    my $regoID = 0;
    my $msg = '';
    if($personID)   {
        if($changeExistingReg)    {
            $self->deleteExistingReg($existingReg, $personID);
        }
print STDERR "ENTITY IS $entityID\n";
        
        ## CHECKING REGO OK
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
        
        if($changeExistingReg)  {
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
        if ($msg eq 'NEW_FAILED')   {
            push @{$self->{'RunDetails'}{'Errors'}}, $lang->txt("New failed, existing registration found.  In order to continue, a Transfer from the existing Entity must be organised.");
        }
        if ($msg eq 'RENEWAL_FAILED')   {
            push @{$self->{'RunDetails'}{'Errors'}}, $lang->txt("Renewal failed, cannot find existing registration. Might have already been renewed");
        }
    }
    else    {
        if(!$existingReg or $changeExistingReg)   {
            $self->addCarryField('rID',$regoID);
            $self->addCarryField('pType',$personType);
            #$self->addCarryField('d_nature',$registrationNature); 
        }
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
    if(!doesSelfUserHaveAccess($self->{'Data'}, $id, $self->{'UserID'})) {
        return ('Invalid User',0);
    }
    my $personObj = new PersonObj(db => $self->{'db'}, ID => $id, cache => $self->{'Data'}{'cache'});
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
        my @certOrder=();
        for my $type (@{$certificationTypes})   {
            push @certOrder, $type->{'intCertificationTypeID'};
            $ctypes{$type->{'intCertificationTypeID'}} = $type->{'strCertificationName'} || next;
        }
        $objectValues->{'certificationTypes'} = \%ctypes;
        $objectValues->{'certificationTypesOrdered'} = \@certOrder;
        $self->setupValues($objectValues);
    }
    my $fieldMessages = getFieldMessages($self->{'Data'}, 'person', $self->{'Data'}->{'lang'}->getLocale());
    my($fieldsContent, undef, $scriptContent, $tabs) = $self->displayFields(undef,'',$fieldMessages);

    my $certifications = getPersonCertifications(
        $self->{'Data'},
        $personObj->ID(),
        $personType,
        0
    );

    my $no_prev_cert;
    my $prev_cert;

    if(! scalar(@{$certifications})){
         $no_prev_cert = runTemplate(
            $self->{'Data'},
            {},
            'registration/no_prev_certification.templ'
        );       
    }
    else {
        $prev_cert = runTemplate(
            $self->{'Data'},
            {
                certifications => $certifications,
            },
            'registration/certifications.templ'
        );
    }

    $fieldsContent = $prev_cert . $fieldsContent;
    my %PageData = (
        HiddenFields => $self->stringifyCarryField(),
        Target => $self->{'Data'}{'target'},
        Errors => $self->{'RunDetails'}{'Errors'} || [],
        Content => $fieldsContent || '',
        ScriptContent => $scriptContent || '',
        FlowSummaryContent => personSummaryPanel($self->{'Data'}, $personObj->ID(),1) || '',
        Title => '',
        TextTop => $no_prev_cert,
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
    if(!doesSelfUserHaveAccess($self->{'Data'}, $id, $self->{'UserID'})) {
        return ('Invalid User',0);
    }

    if(!scalar(@{$self->{'RunDetails'}{'Errors'}}))    {
        my $personObj = new PersonObj(db => $self->{'db'}, ID => $id, cache => $self->{'Data'}{'cache'});
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

    $self->addCarryField('payMethod','');
    my $personID = $self->ID();
    if(!doesSelfUserHaveAccess($self->{'Data'}, $personID, $self->{'UserID'})) {
        return ('Invalid User',0);
    }
    my $entityID = 0;
    my $entityLevel = 0;
    my $originLevel = $Defs::LEVEL_PERSON;
    my $regoID = $self->{'RunParams'}{'rID'} || 0;
    my $client = $self->{'Data'}->{'client'};

    my $rego_ref = {};
    my $content = '';
    if($regoID) {
        ($entityID, $entityLevel) = $self->getRegoEntity($regoID, $personID);
        $regoID = 0 if !$entityID;
    }

    my $personObj = new PersonObj(db => $self->{'db'}, ID => $personID, cache => $self->{'Data'}{'cache'});
    $personObj->load();
    if ($regoID)    {
        my $valid =0;
        ($valid, $rego_ref) = validateRegoID(
            $self->{'Data'},
            $personID,
            $regoID,
            $entityID
        );
        $regoID = 0 if ! $valid;
    }

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
        if (! $content)   {
            #$self->incrementCurrentProcessIndex();
            #return ('',2);
        }
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
        FlowSummaryContent => personSummaryPanel($self->{'Data'}, $personObj->ID(),1) || '',
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
    if(!doesSelfUserHaveAccess($self->{'Data'}, $personID, $self->{'UserID'})) {
        return ('Invalid User',0);
    }
    my $entityID = 0;
    my $entityLevel = 0;
    my $originLevel = $Defs::LEVEL_PERSON;
    my $regoID = $self->{'RunParams'}{'rID'} || 0;
    my $client = $self->{'Data'}->{'client'};
    my $rego_ref = {};
    if($regoID) {
        ($entityID, $entityLevel) = $self->getRegoEntity($regoID, $personID);
        $regoID = 0 if !$entityID;

        if ($regoID)    {
            my $valid =0;
            ($valid, $rego_ref) = validateRegoID(
                $self->{'Data'},
                $personID,
                $regoID,
                $entityID
            );
            $regoID = 0 if ! $valid;
        }
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
print STDERR "TXNID: $txnIds\n";
    if ($paymentType and $markPaid)  {
            my %Settings=();
            $Settings{'paymentType'} = $paymentType;
            my $logID = createTransLog($self->{'Data'}, \%Settings, $entityID,\@txnIds, $amount);
            processTransLog($self->{'Data'}->{'db'}, '', 'OK', 'APPROVED', $logID, \%Settings, undef, undef, '', '', '', '', '', '','',1);
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
    if(!doesSelfUserHaveAccess($self->{'Data'}, $personID, $self->{'UserID'})) {
        return ('Invalid User',0);
    }
	my $entityID = 0;
    my $entityLevel = 0;
    my $originLevel = $Defs::LEVEL_PERSON;
    my $regoID = $self->{'RunParams'}{'rID'} || 0;
    my $client = $self->{'Data'}->{'client'};
	my $rego_ref = {};
    my $content = '';
    if($regoID) {
        ($entityID, $entityLevel) = $self->getRegoEntity($regoID, $personID);
        $regoID = 0 if !$entityID;
        if ($regoID)    {
            my $valid =0;
            ($valid, $rego_ref) = validateRegoID(
                $self->{'Data'},
                $personID,
                $regoID,
                $entityID
            );
            $regoID = 0 if ! $valid;
        }
    }
	my $personObj = new PersonObj(db => $self->{'db'}, ID => $personID, cache => $self->{'Data'}{'cache'});
    $personObj->load();
	my $nationality = $personObj->getValue('strISONationality') || ''; 
        my $itc = $personObj->getValue('intInternationalTransfer') || '';
        $rego_ref->{'Nationality'} = $nationality;
        $rego_ref->{'InternationalTransfer'} = $itc;

     if (! $regoID or ! $personID)  {
        my $lang = $self->{'Data'}{'lang'};
        push @{$self->{'RunDetails'}{'Errors'}}, $lang->txt("Registration failed, cannot find registration.");
        $self->setCurrentProcessIndex('r');
        return ('',2);
    }

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
        FlowSummaryContent => personSummaryPanel($self->{'Data'}, $personObj->ID(),1) || '',
        Content => '',
        Title => '',
        DocUploader => $content,
        #TextTop => $content,
        TextTop => '',
        TextBottom => '',
    );
    my $pagedata = $self->display(\%PageData);
	

    return ($pagedata,0);

}

sub process_documents { 
    my $self = shift;
    

    my $personID = $self->ID();
    if(!doesSelfUserHaveAccess($self->{'Data'}, $personID, $self->{'UserID'})) {
        return ('Invalid User',0);
    }

    my $entityID = 0;
    my $entityLevel = 0;
    my $originLevel = $Defs::LEVEL_PERSON;
    my $regoID = $self->{'RunParams'}{'rID'} || 0;
    my $client = $self->{'Data'}->{'client'};

    my $rego_ref = {};
	my $personObj;
    my $content = '';
    if($regoID) {
        ($entityID, $entityLevel) = $self->getRegoEntity($regoID, $personID);
        $regoID = 0 if !$entityID;
		$personObj = new PersonObj(db => $self->{'db'}, ID => $personID, cache => $self->{'Data'}{'cache'});
    	$personObj->load();

        if ($regoID)    {
            my $valid =0;
            ($valid, $rego_ref) = validateRegoID(
                $self->{'Data'},
                $personID,
                $regoID,
                $entityID
            );
            $regoID = 0 if ! $valid;
        }
 

		my $nationality = $personObj->getValue('strISONationality') || ''; 
        my $itc = $personObj->getValue('intInternationalTransfer') || '';
        $rego_ref->{'Nationality'} = $nationality;
        $rego_ref->{'InternationalTransfer'} = $itc;
    }

     if (! $regoID or ! $personID)  {
        my $lang = $self->{'Data'}{'lang'};
        push @{$self->{'RunDetails'}{'Errors'}}, $lang->txt("Registration failed, cannot find registration.");
        $self->setCurrentProcessIndex('r');
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
    my $personObj;
    my $personID = $self->ID();
    if(!doesSelfUserHaveAccess($self->{'Data'}, $personID, $self->{'UserID'})) {
        return ('Invalid User',0);
    }
    my $entityID = 0;
    my $entityLevel = 0;
    my $originLevel = $Defs::LEVEL_PERSON;
    my $regoID = $self->{'RunParams'}{'rID'} || 0;
    my $client = $self->{'Data'}->{'client'};

    my $rego_ref = {};
    my $content = '';
    my $gatewayConfig = undef;
    if($regoID) {
	my $valid =0;
        ($entityID, $entityLevel) = $self->getRegoEntity($regoID, $personID);
        $regoID = 0 if !$entityID;
        ($valid, $rego_ref) = validateRegoID(
            $self->{'Data'}, 
            $personID, 
            $regoID, 
            $entityID
        );
    }

    my $payMethod = '';
print STDERR "SUMM$regoID\n";
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
        $hiddenFields->{'cA'} = "SELFREGOFLOW";
        $hiddenFields->{'selfRego'} = "1";
        ($content, $gatewayConfig)= displayRegoFlowSummary(
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
    }
    else    {
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
        ContinueButtonText => $self->{'Lang'}->txt('Submit to [_1]' , $initialTaskAssigneeLevel),
    );
    $gatewayConfig->{'Target'} = "$Defs::base_url/".$gatewayConfig->{'Target'};
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
        Content => $content,
        Title => '',
        TextTop => '',
        TextBottom => '',
        HiddenFields => $Config{'HiddenFields'},
        Target => $Config{'Target'},
        ContinueButtonText => $Config{'ContinueButtonText'},
    );    



    #my %PageData = (
    #    HiddenFields => $self->stringifyCarryField(),
    #    Target => $self->{'Data'}{'target'},
    #    Errors => $self->{'RunDetails'}{'Errors'} || [],
    #    FlowSummaryContent => personSummaryPanel($self->{'Data'}, $personObj->ID(),1) || '',
    #    Content => $content,
    #    Title => '',
    #    TextTop => '',
    #    TextBottom => '',
    #    ContinueButtonText => $self->{'Lang'}->txt('Submit to ' . $initialTaskAssigneeLevel),
    #);


    my $registrationNature = $self->{'RunParams'}{'d_nature'} || '';
    my $pagedata = $self->display(\%PageData);

    return ($pagedata,0);

}

sub display_complete { 
    my $self = shift;
    my $personObj;
    my $personID = $self->ID();
    if(!doesSelfUserHaveAccess($self->{'Data'}, $personID, $self->{'UserID'})) {
        return ('Invalid User',0);
    }
    my $entityID = 0;
    my $entityLevel = 0;
    my $originLevel = $Defs::LEVEL_PERSON;
    my $regoID = $self->{'RunParams'}{'rID'} || 0;
    my $client = $self->{'Data'}->{'client'};

    my $rego_ref = {};
    my $content = '';
    my $gateways= '';
    if($regoID) {
        ($entityID, $entityLevel) = $self->getRegoEntity($regoID, $personID);
        my $valid =0;
        ($valid, $rego_ref) = validateRegoID(
            $self->{'Data'},
            $personID,
            $regoID,
            $entityID
        );
        $regoID = 0 if !$valid;
        $regoID = 0 if !$entityID;
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
	print STDERR "COMPLETE: $regoID | Perso: $personID\n";
	open FH, ">test.txt";
	print FH Dumper( $self->{'Data'});
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
        Content => $content,
        Title => '',
        TextTop => '',
        TextBottom => '',
        NoContinueButton => 1,
        gateways => $gateways
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

            intMinorProtection
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

 
sub getRegoEntity   {
    my $self = shift;
    my ($regoID, $personID) = @_;
    
    my $st = qq[
        SELECT
            E.intEntityID,
            E.intEntityLevel
        FROM
            tblPersonRegistration_$self->{'Data'}->{'Realm'} AS PR
            INNER JOIN tblEntity AS E
                ON PR.intEntityID = E.intEntityID
        WHERE
            PR.intPersonRegistrationID = ?
            AND PR.intPersonID = ?
    ];
    my $q=$self->{'Data'}->{'db'}->prepare($st);
    $q->execute(
        $regoID,
        $personID,
    );
    my ($id, $type) = $q->fetchrow_array();
    $q->finish();
    return ($id, $type);
}


1;
