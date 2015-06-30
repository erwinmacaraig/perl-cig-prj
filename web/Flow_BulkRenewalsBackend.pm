package Flow_BulkRenewalsBackend;

use strict;
use lib '.', '..', '../..', "../dashboard", "../user";
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
use NationalReportingPeriod;
use BulkPersons;
use Person;


sub setProcessOrder {
    my $self = shift;
  
    my $dtype = param('dtype') || '';
    my $typename = $Defs::personType{$dtype} || '';
    my $lang = $self->{'Data'}{'lang'};
    my $regname = $typename
        ? $lang->txt($typename .' Registration')
        : $lang->txt('Registration');

    $self->{'ProcessOrder'} = [       
        {
            'action' => 'r',
            'function' => 'display_registration',
            'label'  => $lang->txt('Registration'),
            'title'  => $regname . ' - ' .$lang->txt('Choose Registration Type'),
        },
        {
            'action' => 'ru',
            'function' => 'process_registration',
        },
        {
            'action' => 'r',
            'function' => 'display_person_select',
            'label'  => $lang->txt('Person Selection'),
            'title'  => $regname . ' - ' .$lang->txt('Select People to Renew'),
        },
        {
            'action' => 'spu',
            'function' => 'process_person_select',
        },
         {
            'action' => 'p',
            'function' => 'display_products',
            'label'  => $lang->txt('License'),
            'title'  => $regname . ' - ' .$lang->txt('Confirm License'),
        },
        {
            'action' => 'pu',
            'function' => 'process_products',
        },
       {
            'action' => 'summ',
            'function' => 'display_summary',
            'label'  => $lang->txt('Summary'),
            'title'  => $regname . ' - ' .$lang->txt('Summary'),
        },
       {
            'action' => 'c',
            'function' => 'display_complete',
            'label'  => $lang->txt('Complete'),
            'title'  => $regname . ' - ' .$lang->txt('Submitted'),
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
    my $client = $self->{'Data'}{'client'};
    $values->{'BaseURL'} = "$self->{'Data'}{'target'}?client=$client&amp;a=";
    $self->{'FieldSets'} = personFieldsSetup($self->{'Data'}, $values);
}

sub process_person_select   {
    my $self = shift;
    my $rolloverIDs = $self->{'RunParams'}{'roIds'};
    $self->addCarryField('rolloverIDs',$rolloverIDs);
    
    return ('',1);
}

sub display_person_select   {

    my $self = shift;
 
    my $client = $self->{'Data'}->{'client'};
    my $clientValues = $self->{'Data'}->{'clientValues'};
    my $cl = setClient($clientValues);


    my $personType = $self->getCarryFields('d_type') || '';
    my $personEntityRole= $self->getCarryFields('d_role') || '';
    my $personLevel = $self->getCarryFields('d_level') || '';
    my $sport = $self->getCarryFields('d_sport') || '';
    my $ageLevel = $self->getCarryFields('d_age') || '';
    my $registrationNature = $self->getCarryFields('d_nat') || '';
#    my $existingReg = $self->{'RunParams'}{'existingReg'} || 0;
#    my $changeExistingReg = $self->{'RunParams'}{'changeExisting'} || 0;
    my $entityID = getLastEntityID($self->{'ClientValues'}) || 0;
    my $entityLevel = getLastEntityLevel($self->{'ClientValues'}) || 0;
    my $originLevel = $self->{'ClientValues'}{'authLevel'} || 0;
    my $lang = $self->{'Lang'};



    my $bulk_ref = {
            personType => $personType,
            personEntityRole=> $personEntityRole,
            personLevel => $personLevel,
            sport => $sport,
            registrationNature => $registrationNature,
            ageLevel => $ageLevel,
            originLevel => $originLevel,
            originID => $entityID,
            entityID => $entityID,
            entityLevel => $entityLevel,
            current => 1,
     };
    
    my %Hidden=();
    #$Hidden{'client'} = unescape($cl);
    #$Hidden{'txnIds'} = $params{'txnIds'} || '';
    #$Hidden{'prodIds'} = $params{'prodIds'} || '';
    #$Hidden{'prodQty'} = $params{'prodQty'} || '';
    #$Hidden{'upd'} = $params{'upd'} || 0;

    ($bulk_ref->{'nationalPeriodID'}, undef, undef) = getNationalReportingPeriod($self->{'Data'}->{db}, $self->{'Data'}->{'Realm'}, $self->{'Data'}->{'RealmSubType'}, $bulk_ref->{'sport'}, $bulk_ref->{'personType'}, $bulk_ref->{'registrationNature'});
    my ($listPersons_body, undef) = bulkPersonRollover($self->{'Data'}, 'PREGFB_SPU', $bulk_ref, \%Hidden, 0);
    
    my $content = $listPersons_body;
	my $toggleCount =  bulkPersonRollover($self->{'Data'}, 'PREGFB_SPU', $bulk_ref, \%Hidden, 1) ? 0 : 1;
    my %PageData = (
        HiddenFields => $self->stringifyCarryField(),
        Target => $self->{'Data'}{'target'},
        Errors => $self->{'RunDetails'}{'Errors'} || [],
        Content => $content,
        Title => '',
        TextTop => '',
        TextBottom => '',
        processStatus => 1,
	NoContinueButton => $toggleCount,
	BackButtonURLOverride => "$Defs::base_url/$self->{'Data'}{'target'}?client=$client&amp;a=PFB_",
    );
	my $pagedata = $self->display(\%PageData);

    return ($pagedata,0);


}

sub display_registration { 
    my $self = shift;

    my $bulk=1;
    my $personID = 0; #$self->ID();
#    if(!doesUserHaveAccess($self->{'Data'}, $personID,'WRITE')) {
#        return ('Invalid User',0);
 #   }
    my $entityID = getLastEntityID($self->{'ClientValues'}) || 0;
    my $entityLevel = getLastEntityLevel($self->{'ClientValues'}) || 0;
    my $originLevel = $self->{'ClientValues'}{'authLevel'} || 0;

    my $client = $self->{'Data'}->{'client'};
    my $url = $self->{'Target'}."?rfp=".$self->getNextAction()."&".$self->stringifyURLCarryField();
    my $personObj = new PersonObj(db => $self->{'db'}, ID => $personID, cache => $self->{'Data'}{'cache'});
    $personObj->load();
    my ($dob, $gender) = $personObj->getValue(['dtDOB','intGender']); 

    my $content = '';
    my $noContinueButton = 1;

    my $lang = $self->{'Data'}{'lang'};

    $self->{'Data'}->{'AddToPage'}->add('js_bottom','file','js/regwhatbulk.js');

    my $defaultRegistrationNature = $self->{'RunParams'}{'dnat'} || '';
    my $regoID = $self->{'RunParams'}{'rID'} || 0;
    $content = PersonRegisterWhat::displayPersonRegisterWhat(
        $self->{'Data'},
        $personID,
        $entityID,
        $dob || '',
        $gender || 0,
        $originLevel,
        $url,
        $bulk,
        0, #$regoID,
    );

    my %PageData = (
        HiddenFields => $self->stringifyCarryField(),
        Target => $self->{'Data'}{'target'},
        Errors => $self->{'RunDetails'}{'Errors'} || [],
        Content => $content,
        Title => '',
        TextTop => '',
        TextBottom => '',
        #NoContinueButton => $noContinueButton,
        processStatus => 1,
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

    my $personType = $self->{'RunParams'}{'d_type'} || '';
    my $personEntityRole= $self->{'RunParams'}{'d_role'} || '';
    my $personLevel = $self->{'RunParams'}{'d_level'} || '';
    my $sport = $self->{'RunParams'}{'d_sport'} || '';
    my $ageLevel = $self->{'RunParams'}{'d_age'} || '';
    my $registrationNature = 'RENEWAL';
    $self->addCarryField('d_type',$personType);
    $self->addCarryField('d_role',$personEntityRole);
    $self->addCarryField('d_level',$personLevel);
    $self->addCarryField('d_sport',$sport);
    $self->addCarryField('d_age',$ageLevel);
    $self->addCarryField('d_nat',$registrationNature);

    return ('',1);

}

sub display_products { 
    my $self = shift;
    $self->addCarryField('payMethod','');

    my $client = $self->{'Data'}->{'client'};
    my $clientValues = $self->{'Data'}->{'clientValues'};
    my $cl = setClient($clientValues);

    my $personType = $self->getCarryFields('d_type') || '';
    my $personEntityRole= $self->getCarryFields('d_role') || '';
    my $personLevel = $self->getCarryFields('d_level') || '';
    my $sport = $self->getCarryFields('d_sport') || '';
    my $ageLevel = $self->getCarryFields('d_age') || '';
    my $registrationNature = $self->getCarryFields('d_nat') || '';

    my $entityID = getLastEntityID($self->{'ClientValues'}) || 0;
    my $entityLevel = getLastEntityLevel($self->{'ClientValues'}) || 0;
    my $originLevel = $self->{'ClientValues'}{'authLevel'} || 0;
    my $lang = $self->{'Lang'};


		 
    my $bulk_ref = {
            personType => $personType,
            personEntityRole=> $personEntityRole,
            personLevel => $personLevel,
            sport => $sport,
            registrationNature => $registrationNature,
            ageLevel => $ageLevel,
            originLevel => $originLevel,
            originID => $entityID,
            entityID => $entityID,
            entityLevel => $entityLevel,
            current => 1,
     };
	$bulk_ref->{'payMethod'} = $self->{'RunParams'}{'payMethod'} || '';
    my %Hidden=();

    my $content= displayRegoFlowProductsBulk($self->{'Data'}, 0, $client, $entityLevel, $originLevel, $bulk_ref, $entityID, 0, \%Hidden);
    if (! $content) {
	$self->setCurrentProcessIndex('summ');
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
        processStatus => 1,
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

    $self->addCarryField('paymentType',$self->{'RunParams'}{'paymentType'});
    $self->addCarryField('markPaid',$self->{'RunParams'}{'markPaid'});
    return ('',1);
}

sub display_summary { 
    my $self = shift;
    my $personObj;
    my $personID = $self->ID();
    #if(!doesUserHaveAccess($self->{'Data'}, $personID,'WRITE')) {
    #    return ('Invalid User',0);
    #}
    my $entityID = getLastEntityID($self->{'ClientValues'}) || 0;
    my $entityLevel = getLastEntityLevel($self->{'ClientValues'}) || 0;
    my $originLevel = $self->{'ClientValues'}{'authLevel'} || 0;
    my $regoID = $self->{'RunParams'}{'rID'} || 0;
    my $client = $self->{'Data'}->{'client'};
    my $gatewayConfig = undef;
    my $rego_ref = {};
    my $content = '';

    $self->addCarryField('txnIds', $self->{'RunParams'}{'txnIds'} || 0);
    $self->addCarryField('payMethod', $self->{'RunParams'}{'payMethod'} || '');
    my $payMethod = $self->{'RunParams'}{'payMethod'} || '';

        $self->create_bulk_records();
        $personObj = new PersonObj(db => $self->{'db'}, ID => $personID, cache => $self->{'Data'}{'cache'});
        $personObj->load();
        my $nationality = $personObj->getValue('strISONationality') || ''; 
        $rego_ref->{'Nationality'} = $nationality;

        my $hiddenFields = $self->getCarryFields();
        $hiddenFields->{'rfp'} = 'c';#$self->{'RunParams'}{'rfp'};
        $hiddenFields->{'__cf'} = $self->{'RunParams'}{'__cf'};
        $hiddenFields->{'cA'} = "BULKRENEWALS";
        ($content, $gatewayConfig) = displayRegoFlowSummaryBulk(
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
    my %Config = (
        HiddenFields => $self->stringifyCarryField(),
        Target => $self->{'Data'}{'target'},
        ContinueButtonText => $self->{'Lang'}->txt('Submit to Member Association'),
    );
    if ($gatewayConfig->{'amountDue'} and $payMethod eq 'now')    {
        ## Change Target etc
        %Config = (
            HiddenFields => $gatewayConfig->{'HiddenFields'},
            Target => $gatewayConfig->{'Target'},
            ContinueButtonText => $self->{'Lang'}->txt('Proceed to Payment and Submit to Member Association'),
        );
    }

    my %PageData = (
        Errors => $self->{'RunDetails'}{'Errors'} || [],
        FlowSummaryContent => personSummaryPanel($self->{'Data'}, $personObj->ID()) || '',
        Content => $content,
        Title => '',
        TextTop => '',
        TextBottom => '',
        processStatus => 1,
        HiddenFields => $Config{'HiddenFields'},
        Target => $Config{'Target'},
        ContinueButtonText => $Config{'ContinueButtonText'},
    );
    my $pagedata = $self->display(\%PageData);

    return ($pagedata,0);

}

sub create_bulk_records {

    my $self = shift;
    my $personObj;
    my $personID = 0; #$self->ID();
    my $rego_ref = {};
    my $content = '';
    my $gateways = '';
        
    my $client = $self->{'Data'}->{'client'};
    my $clientValues = $self->{'Data'}->{'clientValues'};
    my $cl = setClient($clientValues);

    my $personType = $self->getCarryFields('d_type') || '';
    my $personEntityRole= $self->getCarryFields('d_role') || '';
    my $personLevel = $self->getCarryFields('d_level') || '';
    my $sport = $self->getCarryFields('d_sport') || '';
    my $ageLevel = $self->getCarryFields('d_age') || '';
    my $registrationNature = $self->getCarryFields('d_nat') || '';
    my $entityID = getLastEntityID($self->{'ClientValues'}) || 0;
    my $entityLevel = getLastEntityLevel($self->{'ClientValues'}) || 0;
    my $originLevel = $self->{'ClientValues'}{'authLevel'} || 0;
    my $lang = $self->{'Lang'};

    my $bulk_ref = {
            personType => $personType,
            personEntityRole=> $personEntityRole,
            personLevel => $personLevel,
            sport => $sport,
            registrationNature => $registrationNature,
            ageLevel => $ageLevel,
            originLevel => $originLevel,
            originID => $entityID,
            entityID => $entityID,
            entityLevel => $entityLevel,
            current => 1,
     };
    my @productsselected=();
    my @productsqty=();
    my $hiddenFields = $self->getCarryFields();

    ($bulk_ref->{'nationalPeriodID'}, undef, undef) = getNationalReportingPeriod($self->{'Data'}->{db}, $self->{'Data'}->{'Realm'}, $self->{'Data'}->{'RealmSubType'}, $bulk_ref->{'sport'}, $bulk_ref->{'personType'}, $bulk_ref->{'registrationNature'});
        my $count = bulkPersonRollover($self->{'Data'}, 'PREGFB_SPU', $bulk_ref, $hiddenFields, 1);

        my $rolloverIDs=$self->getCarryFields('rolloverIDs');
        my $prodIds = $self->getCarryFields('prodIds');
        my $prodQty = $self->getCarryFields('prodQty');
        my $markPaid = $self->getCarryFields('markPaid');
        my $paymentType= $self->getCarryFields('paymentType');

        #FC-145 (having duplicate entries upon page refresh.. need to check number of records upon submit)
    my $totalAmount=0;
        if($count > 0) {
            my ($txnTotalAmount, $txnIds, $regoIDs_ref) = bulkRegoCreate($self->{'Data'}, $bulk_ref, $rolloverIDs, $prodIds, $prodQty, $markPaid, $paymentType);
            $hiddenFields->{'txnIds'} = $txnIds;
            $hiddenFields->{'totalAmount'} = $txnTotalAmount || 0;
           $self->addCarryField("txnIds",$txnIds);
            $totalAmount = $txnTotalAmount;
            for my $k (keys %{$regoIDs_ref})  {
                $self->addCarryField("regoID_$k",$regoIDs_ref->{$k});
            }
        $hiddenFields->{'rolloverIDs'} = $rolloverIDs;

        $hiddenFields->{'rfp'} = 'c';#$self->{'RunParams'}{'rfp'};
        $hiddenFields->{'__cf'} = $self->{'RunParams'}{'__cf'};
        }
    if($self->{'RunDetails'}{'Errors'} and scalar(@{$self->{'RunDetails'}{'Errors'}})) {
        #There are errors - reset where we are to go back to the form again
        $self->decrementCurrentProcessIndex();
        return ('',2);
    }

}
sub display_complete { 
    my $self = shift;
    my $personObj;
    my $personID = 0; #$self->ID();
#    if(!doesUserHaveAccess($self->{'Data'}, $personID,'WRITE')) {
#        return ('Invalid User',0);
#    }
    my $rego_ref = {};
    my $content = '';
    my $gateways = '';
        
    my $client = $self->{'Data'}->{'client'};
    my $clientValues = $self->{'Data'}->{'clientValues'};
    my $cl = setClient($clientValues);


    my $lang = $self->{'Lang'};

    my $hiddenFields = $self->getCarryFields();

    my $rolloverIDs=$self->getCarryFields('rolloverIDs') || param('rolloverIDs') || '';
    my $prodIds = $self->getCarryFields('prodIds');
    my $prodQty = $self->getCarryFields('prodQty');
    my $markPaid = $self->getCarryFields('markPaid');
    my $paymentType= $self->getCarryFields('paymentType');

$hiddenFields->{'txnIds'} = $hiddenFields->{'txnIds'} || param('txnIds') || '';
$hiddenFields->{'payMethod'} = $hiddenFields->{'payMethod'} || param('payMethod') || '';

    #FC-145 (having duplicate entries upon page refresh.. need to check number of records upon submit)
    my $totalAmount=0;
    $hiddenFields->{'rolloverIDs'} = $rolloverIDs;
    $hiddenFields->{'rfp'} = 'c';#$self->{'RunParams'}{'rfp'};
    $hiddenFields->{'__cf'} = $self->{'RunParams'}{'__cf'};

    bulkRegoSubmit($self->{'Data'}, undef, $rolloverIDs);
    ($content, $gateways) = displayRegoFlowCompleteBulk(
        $self->{'Data'}, 
        $client, 
        $hiddenFields,
    );
    if($self->{'RunDetails'}{'Errors'} and scalar(@{$self->{'RunDetails'}{'Errors'}})) {
        #There are errors - reset where we are to go back to the form again
        $self->decrementCurrentProcessIndex();
        return ('',2);
    }
    my %PageData = (
        HiddenFields => $self->stringifyCarryField(),
        Target => $self->{'Data'}{'target'},
        Errors => $self->{'RunDetails'}{'Errors'} || [],
        processStatus => 1,
        Content => $content,
        Title => '',
        TextTop => '',
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

 

 

