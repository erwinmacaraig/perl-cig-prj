package Flow_SelfRegExtraProduct;

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
    my $typename = 'Add Products/Licenses'; 
       
    $self->{'ProcessOrder'} = [       
       
        {
            'action' => 'r',
            'function' => 'display_registration',
            'label'  => 'Registration',
            'title'  => $typename . " - Registration Type",
        },
        {
            'action' => 'ru',
            'function' => 'process_registration',
        },
       
        {
            'action' => 'p',
            'function' => 'display_products',
            'label'  => 'License',
            'title'  => $typename . " - Confirm License",
        },
        {
            'action' => 'pu',
            'function' => 'process_products',
        },
       {
            'action' => 'summ',
            'function' => 'display_summary',
            'label'  => 'Summary',
            'title'  => $typename . " - Summary",
        },
       {
            'action' => 'c',
            'function' => 'display_complete',
            'label'  => 'Complete',
            'title'  => $typename . " - Submitted",
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
            1,
        );
        
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

    my $regoID = $self->{'RunParams'}{'rID'} || 0;
    my $msg = '';
    if($personID)   {
        
        
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
    }

    if(!$personID)    {
        push @{$self->{'RunDetails'}{'Errors'}}, 'Invalid Person';
    }
    if (!$regoID)   {
        push @{$self->{'RunDetails'}{'Errors'}}, $lang->txt("Invalid Registration");
        
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
        $rego_ref->{'strRegistrationNature'} = 'RENEWAL';
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


###
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
    my $initialTaskAssigneeLevel;
    my %Config;
    my $selectedProducts = '';
    
    my @additionalProds = split ':', $self->{'RunParams'}{'prodIds'};
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
        my $tempcontent = '';
        ($tempcontent, $gatewayConfig)= displayRegoFlowSummary(
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
        $selectedProducts = getSelectedProducts($self->{'Data'}, \@additionalProds);
        
        
    }
    else    {
        push @{$self->{'RunDetails'}{'Errors'}}, $self->{'Lang'}->txt("Invalid Registration ID");
    }
    if($self->{'RunDetails'}{'Errors'} and scalar(@{$self->{'RunDetails'}{'Errors'}})) {
        #There are errors - reset where we are to go back to the form again
        $self->decrementCurrentProcessIndex();
        return ('',2);
    }
    ($initialTaskAssigneeLevel, undef) = getInitialTaskAssignee(
            $self->{'Data'},
            $personID,
            $regoID,
            0
    );
    %Config = (
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
    my $displayContinueBtn = 0;
     if(!$selectedProducts){
        $selectedProducts = qq[
        <div class="alert existingReg">
            <div>
                <span class="fa fa-info"></span>
                <p>] . $self->{'Lang'}->txt("No additional product(s) chosen, please click  ") . qq[ <strong> ] . $self->{'Lang'}->txt("Back") . qq [</strong>] . $self->{'Lang'}->txt(" link to go back to the product/license listing") . qq[.</p>
            </div>
        </div>
        ];
        $displayContinueBtn = 1;
    }

    my %PageData = (
        Errors => $self->{'RunDetails'}{'Errors'} || [],
        FlowSummaryContent => personSummaryPanel($self->{'Data'}, $personObj->ID()) || '',
        Content => $selectedProducts,
        Title => '',
        TextTop => '',
        TextBottom => '',
        HiddenFields => $Config{'HiddenFields'},
        Target => $Config{'Target'},
        ContinueButtonText => $Config{'ContinueButtonText'},
        NoContinueButton => $displayContinueBtn,
    );    
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
        

        my $hiddenFields = $self->getCarryFields();
        $hiddenFields->{'rfp'} = 'c';#$self->{'RunParams'}{'rfp'};
        $hiddenFields->{'__cf'} = $self->{'RunParams'}{'__cf'};
        print STDERR "COMPLETE: $regoID | Perso: $personID\n";
        
        ($content, $gateways) = displaySelfRegoAddProductComplete(
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


