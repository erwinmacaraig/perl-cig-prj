package Flow_DuplicateMarking;

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
use PlayerPassport;
use SphinxUpdate;

sub setProcessOrder {
    my $self = shift;
  
    my $lang = $self->{'Data'}{'lang'};
    $self->{'ProcessOrder'} = [       
        {
            'action' => 'findparent',
            'function' => 'display_find_parent',
            'label'  => $lang->txt('Find Record'),
            'title'  => $lang->txt('Find other Record'),
        },
        {
            'action' => 'showmatches',
            'function' => 'display_show_matches',
            'label'  => $lang->txt('Show Record'),
            'title'  => $lang->txt('Show other records'),
        },
        {
            'action' => 'sid',
            'function' => 'validate_otherPersonID',
        },
        {
            'action' => 'select_regos',
            'function' => 'display_regos',
            'label'  => $lang->txt('Select Previous Registrations'),
            'title'  => $lang->txt('Select Previous Registrations to copy'),
        },
        {
            'action' => 'sru',
            'function' => 'copy_regos',
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
            'title'  => 'Duplicate Marking - Complete',
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
    $self->{'FieldSets'} = personFieldsSetup($self->{'Data'}, $values);
}

sub display_find_parent { 
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

   my %DuplPageData = (
        HiddenFields => $self->stringifyCarryField(),
        target => $self->{'Data'}{'target'},
        Lang => $self->{'Data'}->{'lang'},
        NoFormFields=>1,
  );

    my $content= runTemplate(
        $self->{'Data'},
        \%DuplPageData,
        'duplicate/find_parent.templ',
    );

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


sub display_show_matches { 
    my $self = shift;

    my $ma_id= $self->{'RunParams'}{'findMA_ID'} || '';
	$self->addCarryField('cd_vstd', 1);
    my $id = $self->ID() || 0;
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
    my $st = qq[
        SELECT 
            *
        FROM
            tblPerson
        WHERE 
            strStatus IN ('REGISTERED')
            AND strNationalNum = ?
        LIMIT 100
    ];
    my $q = $self->{'Data'}->{'db'}->prepare($st) or query_error($st);
    $q->execute(
        $ma_id
    );
    my @Matches = ();
    while (my $dref=$q->fetchrow_hashref()) {
        push @Matches, $dref;
    }
    my $singleRecordSelected = (scalar @Matches == 1) ? "checked" : '';
my %DuplPageData = (
        HiddenFields => $self->stringifyCarryField(),
        target => $self->{'Data'}{'target'},
        Lang => $self->{'Data'}->{'lang'},
        Matches_ref => \@Matches,
        singleRecordSelected => $singleRecordSelected || '',
        NoFormFields=>1,
  );

    my $content= runTemplate(
        $self->{'Data'},
        \%DuplPageData,
        'duplicate/show_matches.templ',
    );

    my %PageData = (
        HiddenFields => $self->stringifyCarryField(),
        Target => $self->{'Data'}{'target'},
        Errors => $self->{'RunDetails'}{'Errors'} || [],
        Content => $content || '',
        ScriptContent => $scriptContent || '',
        Title => '',
        TextTop => '',
        FlowSummaryContent => personSummaryPanel($self->{'Data'}, $id) || '',
        ContinueButtonText => $self->{'Lang'}->txt('Continue'),
        TextBottom => '',
    );

    my $pagedata = $self->display(\%PageData);

    return ($pagedata,0);

}

sub validate_otherPersonID  {
    my $self = shift;
    my $parentPersonID= $self->{'RunParams'}{'parentPersonID'} || 0;
    if ($parentPersonID) {
print STDERR "ALL OK\n";
	    $self->addCarryField('parentPersonID', $parentPersonID);
        return ('',1);
    }    
    $self->decrementCurrentProcessIndex();
    return ('',2);
}

sub display_regos { 
    my $self = shift;
    my $parentPersonID= $self->{'RunParams'}{'parentPersonID'} || 0;

    my $id = $self->ID() || 0;
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
my @statusNOTIN = ($Defs::PERSONREGO_STATUS_DELETED, $Defs::PERSONREGO_STATUS_INPROGRESS, $Defs::PERSONREGO_STATUS_REJECTED);
    my %Reg = (
       statusNOTIN => \@statusNOTIN, 
    );
    my ($count, $regs) = PersonRegistration::getRegistrationData(
        $self->{'Data'},
        $id,
        \%Reg
    );
    
my %DuplPageData = (
        HiddenFields => $self->stringifyCarryField(),
        target => $self->{'Data'}{'target'},
        Lang => $self->{'Data'}->{'lang'},
        regos_ref => $regs,
        NoFormFields=>1,
  );

    my $content= runTemplate(
        $self->{'Data'},
        \%DuplPageData,
        'duplicate/select_regos.templ',
    );

    my %PageData = (
        HiddenFields => $self->stringifyCarryField(),
        Target => $self->{'Data'}{'target'},
        Errors => $self->{'RunDetails'}{'Errors'} || [],
        Content => $content || '',
        ScriptContent => $scriptContent || '',
        Title => '',
        TextTop => '',
        FlowSummaryContent => personSummaryPanel($self->{'Data'}, $id) || '',
        ContinueButtonText => $self->{'Lang'}->txt('Continue'),
        TextBottom => '',
    );

    my $pagedata = $self->display(\%PageData);

    return ($pagedata,0);

}

sub copy_regos {
    my $self = shift;

    my $id = $self->ID() || 0;
    my %Reg = (
    );
    my ($count, $regs_ref) = PersonRegistration::getRegistrationData(
        $self->{'Data'},
        $id,
        \%Reg
    );
 
    my @Regos = ();
    my @Docs= ();
    my @Pays= ();
    foreach my $rego (@{$regs_ref})  {
        if ($self->{'RunParams'}{'rego_' . $rego->{'intPersonRegistrationID'}} eq "1")  {
            push @Regos, $rego->{'intPersonRegistrationID'};
        }
        if ($self->{'RunParams'}{'regoDocuments_' . $rego->{'intPersonRegistrationID'}} eq "1")  {
            push @Docs, $rego->{'intPersonRegistrationID'};
        }
        if ($self->{'RunParams'}{'regoPayments_' . $rego->{'intPersonRegistrationID'}} eq "1")  {
            push @Pays, $rego->{'intPersonRegistrationID'};
        }
    }    
    my $copyRegos = join('|',@Regos);
    if (scalar @Regos)  { $self->addCarryField('copyRegos' , $copyRegos); }

    my $copyRegoDocs = join('|',@Docs);
    if (scalar @Docs)  { $self->addCarryField('copyRegoDocs' , $copyRegoDocs); }

    my $copyRegoPays = join('|',@Pays);
    if (scalar @Pays)  { $self->addCarryField('copyRegoPays' , $copyRegoPays); }

    return ('',1);
}

sub buildDuplicateSummary   {
    my ($Data, $personID, $otherPersonID, $regosToCopy) = @_;

    my $content = '';
    $content = qq[We want to MARK $personID as a DUPLICATE and the PARENT is $otherPersonID<br>];
    $content .= qq[In doing this we will copy ] . scalar(@{$regosToCopy}) .qq[Registrations];
    return $content;
}

sub display_summary { 
    my $self = shift;
    my $id = $self->ID() || 0;

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

    $personObj = new PersonObj(db => $self->{'db'}, ID => $personID, cache => $self->{'Data'}{'cache'});
        $personObj->load();

    my $parentPersonID= $self->{'RunParams'}{'parentPersonID'} || 0;
    my $regoIDs= $self->{'RunParams'}{'copyRegos'} || '';
    my @Regos = split /\|/, $regoIDs;

    my $content = buildDuplicateSummary(
        $self->{'Data'}, 
        $personID,
        $parentPersonID,
        \@Regos
    );

    my %Config = (
        HiddenFields => $self->stringifyCarryField(),
        Target => $self->{'Data'}{'target'},
        ContinueButtonText => $self->{'Lang'}->txt('Mark as Duplicate'),
    );
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

sub FinaliseDuplicateFlow   {

    my ($Data, $personID, $parentPersonID, $regosToCopy, $docsToCopy, $paysToCopy) = @_;

    $personID ||= 0;
    return if (! $personID);
    my %Reg = (
    );
    my ($count, $regs_ref) = PersonRegistration::getRegistrationData(
        $Data,
        $personID,
        \%Reg
    );
    my $stMovePR = qq[
        UPDATE tblPersonRegistration_$Data->{'Realm'}
        SET intPersonID = ?
        WHERE 
            intPersonID = ?
            AND intPersonRegistrationID = ?
        LIMIT 1
    ];
    my $qMovePR=$Data->{'db'}->prepare($stMovePR);

    my $stMoveTXNs = qq[
        UPDATE tblTransactions
        SET intID = ?
        WHERE
            intID = ?
            AND intTableType=1
            AND intPersonRegistrationID = ?
    ];
    my $qMoveTXNs=$Data->{'db'}->prepare($stMoveTXNs);

    my $stMoveWFTask= qq[
         UPDATE tblWFTask
        SET intPersonID = ?
        WHERE 
            intPersonID = ?
            AND intPersonRegistrationID = ?
    ];
    my $qMoveWFTask=$Data->{'db'}->prepare($stMoveWFTask);

    my $stMovePersonReq= qq[
         UPDATE tblPersonRequest
        SET intPersonID = ?
        WHERE 
            intPersonID = ?
            AND intExistingPersonRegistrationID = ?
    ];
    my $qMovePersonReq=$Data->{'db'}->prepare($stMovePersonReq);

    my $stMoveIntTransfer= qq[
         UPDATE tblIntTransfer
        SET intPersonID = ?
        WHERE 
            intPersonID = ?
    ];
    my $qMoveIntTransfer=$Data->{'db'}->prepare($stMoveIntTransfer);

    my $stMovePersonCert= qq[
         UPDATE tblPersonCertifications
        SET intPersonID = ?
        WHERE 
            intPersonID = ?
    ];
    my $qMovePersonCert=$Data->{'db'}->prepare($stMovePersonCert);



    my $stMarkPerson= qq[
        UPDATE tblPerson
        SET strStatus=?
        WHERE 
            intPersonID = ?
        LIMIT 1
    ];
    my $qMarkPerson=$Data->{'db'}->prepare($stMarkPerson);
    $qMarkPerson->execute($Defs::PERSON_STATUS_DUPLICATE, $personID);

    my $stInsLinkage= qq[
        INSERT INTO tblPersonDuplicates
        (intChildPersonID, intParentPersonID, dtAdded, dtUpdated)
        VALUES (?,?,NOW(), NOW())
    ];
    my $qInsLinkage=$Data->{'db'}->prepare($stInsLinkage);
    $qInsLinkage->execute($personID, $parentPersonID);
    
    my $stUpdOldLinkage= qq[
        UPDATE tblPersonDuplicates
        SET intParentPersonID = ?, dtUpdated = NOW()
        WHERE intParentPersonID = ?
    ];
    my $qUpdLinkage=$Data->{'db'}->prepare($stUpdOldLinkage);
    $qUpdLinkage->execute($parentPersonID, $personID);
    


    foreach my $rego (@{$regs_ref})  {
        my $copyRego = $regosToCopy->{$rego->{'intPersonRegistrationID'}};
        my $regoIDToCopy = $rego->{'intPersonRegistrationID'} || next;
        next if $copyRego ne "1";

        $qMovePR->execute($parentPersonID, $personID, $regoIDToCopy);
        $qMoveWFTask->execute($parentPersonID, $personID, $regoIDToCopy);
        $qMovePersonReq->execute($parentPersonID, $personID, $regoIDToCopy);
        $qMoveIntTransfer->execute($parentPersonID, $personID);
        $qMovePersonCert->execute($parentPersonID, $personID);
        if ($docsToCopy->{$regoIDToCopy} eq "1")  {
           moveDocuments($Data, $regoIDToCopy, $parentPersonID);
        }
        
        if ($paysToCopy->{$regoIDToCopy} eq "1")  {
            $qMoveTXNs->execute($parentPersonID, $personID, $regoIDToCopy);
        }
    }    
    {
        my $personObject = getInstanceOf($Data, 'person',$personID);
        updateSphinx($Data->{'db'},$Data->{'cache'}, 'Person','update',$personObject);
        auditLog($personID, $Data, 'Person Marked as Duplicate', 'Person');
    }
    {
        my $personObject = getInstanceOf($Data, 'person',$parentPersonID);
        updateSphinx($Data->{'db'},$Data->{'cache'}, 'Person','update',$personObject);
        auditLog($parentPersonID, $Data, 'Person Registrations merged', 'Person');
    }

    savePlayerPassport($Data, $parentPersonID)
}
sub displayDuplicateComplete    {

    return "DONE";
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

    my $parentPersonID= $self->{'RunParams'}{'parentPersonID'} || 0;
    my $regoIDs= $self->{'RunParams'}{'copyRegos'} || '';
    my @Regos = split /\|/, $regoIDs;
    my %RegoIDs=();
    foreach my $ID (@Regos) {
        $RegoIDs{$ID} = 1;
    }

    my $DocIDs= $self->{'RunParams'}{'copyRegoDocs'} || '';
    my @Docs = split /\|/, $DocIDs;
    my %DocRegos=();
    foreach my $ID (@Docs) {
        $DocRegos{$ID} = 1;
    }

    my $PayIDs= $self->{'RunParams'}{'copyRegoPays'} || '';
    my @Pays = split /\|/, $PayIDs;
    my %PayRegos=();
    foreach my $ID (@Pays) {
        $PayRegos{$ID} = 1;
    }

    my $content = '';

    if($personID and $parentPersonID) {
        $personObj = new PersonObj(db => $self->{'db'}, ID => $personID, cache => $self->{'Data'}{'cache'});
        $personObj->load();

        my $run = $self->{'RunParams'}{'run'} || 0;
        if(! $run)  {
            FinaliseDuplicateFlow(
                $self->{'Data'},
                $personID,
                $parentPersonID,        
                \%RegoIDs,
                \%DocRegos,
                \%PayRegos,
            );
        }

        my $hiddenFields = $self->getCarryFields();
        $hiddenFields->{'rfp'} = 'c';#$self->{'RunParams'}{'rfp'};
        $hiddenFields->{'__cf'} = $self->{'RunParams'}{'__cf'};
        ($content) = displayDuplicateComplete(
            $self->{'Data'}, 
            $personID,
            $parentPersonID,        
            \@Regos
        );
    }
    else    {
        push @{$self->{'RunDetails'}{'Errors'}}, $self->{'Lang'}->txt("Invalid Duplicate Process");
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
        Title => $self->{'Data'}{'lang'}->txt("Person has been marked as a Duplicate"),
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

sub moveDocuments {
    my ($Data, $regoID, $newPersonID) = @_;

    my $st = qq[
        UPDATE tblDocuments
        SET intPersonID= ?
        WHERE intPersonRegistrationID = ?
    ];
    my $q=$Data->{'db'}->prepare($st);
    $q->execute($newPersonID, $regoID);
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

 

