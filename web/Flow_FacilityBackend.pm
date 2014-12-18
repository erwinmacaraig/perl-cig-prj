package Flow_FacilityBackend;

use strict;
use lib '.', '..', '../..', "../dashboard", "../user";
use Flow_BaseObj;
our @ISA =qw(Flow_BaseObj);

use TTTemplate;
use CGI;
use FieldLabels;
use EntityObj;
use EntityFields;
use EntityFieldObj;
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
use RegoProducts;
use RegistrationItem;
use FacilityTypes;
use PersonUserAccess;
use Data::Dumper;
use FacilityFieldsSetup;

sub setProcessOrder {
    my $self = shift;
  
    $self->{'ProcessOrder'} = [       
        {
            'action' => 'cd',
            'function' => 'display_core_details',
            'label'  => 'Venue Details',
            'fieldset'  => 'core',
            'title'  => 'Facility- Enter Venue Information',
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
            'title'  => 'Facility - Enter Contact Details',
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
            'label' => 'Fields',
            'title'  => 'Facility - Enter Role Details',
        },
        {
            'action' => 'roleu',
            'function' => 'validate_role_details',
            'fieldset' => 'roledetails',
        },
        {
            'action' => 'fld',
            'function' => 'display_fields',
            'title'  => 'Facility - Enter Additional Information',
            'ShareNav'  => 'Fields',
        },
        {
            'action' => 'fldu',
            'function' => 'process_fields',
        },
        {
            'action' => 'd',
            'function' => 'display_documents',
            'label'  => 'Documents',
            'title'  => 'Facility - Upload Documents',
        },
        {
            'action' => 'du',
            'function' => 'process_documents',
        },
        #{
        #    'action' => 'p',
        #    'function' => 'display_products',
        #    'label'  => 'Products',
        #},
        #{
        #    'action' => 'pu',
        #    'function' => 'process_products',
        #},
        {
            'action' => 'summ',
            'function' => 'display_summary',
            'label'  => 'Summary',
            'title'  => 'Facility - Summary',
        },
        {
            'action' => 'c',
            'function' => 'display_complete',
            'label'  => 'Complete',
            'title'  => 'Facility - Submitted',
            'NoGoingBack' => 1,
            'NoDisplayInNav' => 1,
        },
    ];

}

sub setupValues    {
    my $self = shift;
    my ($values) = @_;
    $values ||= {};
    $self->{'FieldSets'} = facilityFieldsSetup($self->{'Data'}, $values);
}

sub display_core_details { 
    my $self = shift;

    my $id = $self->ID() || 0;
    if($id)   {
        my $facilityObj = new EntityObj(db => $self->{'db'}, ID => $id, cache => $self->{'Data'}->{'cache'});
        $facilityObj->load();
        if($facilityObj->ID())    {
            my $objectValues = $self->loadObjectValues($facilityObj);
            $self->setupValues($objectValues);
        }
        if(!doesUserHaveEntityAccess($self->{'Data'}, $id,'WRITE')) {
            return ('Invalid User',0);
        }
    }

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
    if($id) {
        if(!doesUserHaveEntityAccess($self->{'Data'}, $id,'WRITE')) {
            return ('Invalid User',0);
        }
    }
    my $facilityObj = new EntityObj(db => $self->{'db'}, ID => $id, cache => $self->{'Data'}->{'cache'});
    $facilityObj->load();
    $facilityData->{'strStatus'} = $Defs::ENTITY_STATUS_INPROGRESS;
    $facilityData->{'intRealmID'} = $self->{'Data'}{'Realm'};
    $facilityData->{'intEntityLevel'} = $Defs::LEVEL_VENUE;
    $facilityData->{'intCreatedByEntityID'} = $authID;
    $facilityObj->setValues($facilityData);

    $facilityObj->write();
    if($facilityObj->ID()){
        if(!$id)    { 
            $self->setID($facilityObj->ID()); 
            $self->addCarryField('newvenue',1);
            $self->addCarryField('newvenueid', $facilityObj->ID());
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

        $query->finish();
        createTempEntityStructure($self->{'Data'}); 
    }
    else    {
        push @{$self->{'RunDetails'}{'Errors'}}, $self->{'Lang'}->txt("Invalid Registration ID");
        $self->decrementCurrentProcessIndex();
        return ('',2);
    }

    return ('',1);
}

sub display_contact_details {
    my $self = shift;
    my $id = $self->ID() || 0;
    if($id)   {
        my $facilityObj = new EntityObj(db => $self->{'db'}, ID => $id, cache => $self->{'Data'}->{'cache'});
        $facilityObj->load();
        if($facilityObj->ID())    {
            my $objectValues = $self->loadObjectValues($facilityObj);
            $self->setupValues($objectValues);
        }
        if(!doesUserHaveEntityAccess($self->{'Data'}, $id,'WRITE')) {
            return ('Invalid User',0);
        }
    }

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
    my $memperm = ProcessPermissions($self->{'Data'}->{'Permissions'}, $self->{'FieldSets'}{'contactdetails'}, 'Club',);
    ($facilityData, $self->{'RunDetails'}{'Errors'}) = $self->gatherFields($memperm);
    my $id = $self->ID() || 0;
    if(!$id){
        push @{$self->{'RunDetails'}{'Errors'}}, 'Invalid facility.';
    }
    if($self->{'RunDetails'}{'Errors'} and scalar(@{$self->{'RunDetails'}{'Errors'}})) {
        #There are errors - reset where we are to go back to the form again
        $self->decrementCurrentProcessIndex();
        return ('',2);
    }

    my $facilityObj = new EntityObj(db => $self->{'db'}, ID => $id, cache => $self->{'Data'}->{'cache'});
    $facilityObj->load();
    $facilityObj->setValues($facilityData);

    $facilityObj->write();

    return ('',1);

}

sub display_role_details {
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

sub validate_role_details {
    my $self = shift;

    my $facilityFieldData = {};

    #make intEntityFieldCount as it's always required during add Facility flow
    my %fieldCount = (
        'intEntityFieldCount' => 1
    );
    ($facilityFieldData, $self->{'RunDetails'}{'Errors'}) = $self->gatherFields(\%fieldCount);

    if(!$facilityFieldData->{'intEntityFieldCount'}){
        #push @{$self->{'RunDetails'}{'Errors'}}, 'Invalid number of facility fields.';
        $self->incrementCurrentProcessIndex();
        $self->incrementCurrentProcessIndex();
        return ('',2);
    }
    if($self->{'RunDetails'}{'Errors'} and scalar(@{$self->{'RunDetails'}{'Errors'}})) {
        #There are errors - reset where we are to go back to the form again
        $self->decrementCurrentProcessIndex();
        return ('',2);
    }

    #my $facilityObj = new EntityObj(db => $self->{'db'}, ID => $id);
    #$facilityObj->load();
    #$facilityObj->setValues($facilityData);

    #$facilityObj->write();

    $self->addCarryField('facilityFieldCount', $facilityFieldData->{'intEntityFieldCount'});

    return ('',1);
}

sub display_fields {
    my $self = shift;

    my $facilityFieldCount = $self->{'RunParams'}{'facilityFieldCount'} || 0;

print STDERR "SSSS";
    my $entityID = getLastEntityID($self->{'ClientValues'}) || 0;
    my $facilityFields = new EntityFields();
    $facilityFields->setCount($facilityFieldCount);
    $facilityFields->setEntityID($self->{'RunParams'}{'e'});
    $facilityFields->setData($self->{'Data'});
    
    my @facilityFieldsData = ();
    my $startNewIndex = 1;

    #if user navigates back, reload previous data
    foreach my $fieldObjData (@{$facilityFields->getAll()}){
        $facilityFields->setDBData($fieldObjData);
        push @facilityFieldsData, $facilityFields->generateSingleRowField($startNewIndex, $fieldObjData->{'intEntityFieldID'});
        $startNewIndex++;
    }

    for my $i ($startNewIndex .. $facilityFieldCount){
        $facilityFields->setDBData({});
        push @facilityFieldsData, $facilityFields->generateSingleRowField($i, undef);
    }

    my %FieldsGridData = (
        FieldElements => \@facilityFieldsData,
    );

    my $facilityFieldsContent = runTemplate(
        $self->{'Data'},
        \%FieldsGridData,
        'flow/facility_fields_grid.templ',
    );

    my %PageData = (
        HiddenFields => $self->stringifyCarryField(),
        Target => $self->{'Data'}{'target'},
        Errors => $self->{'RunDetails'}{'Errors'} || [],
        Content => $facilityFieldsContent || '',
        ScriptContent => '',
        Title => '',
        TextTop => '',
        TextBottom => '',
    );

    my $pagedata = $self->display(\%PageData);
}

sub process_fields {
    my $self = shift;

    #test validate
    my $facilityFieldCount = $self->{'RunParams'}{'facilityFieldCount'} || 0;

    my $entityID = getLastEntityID($self->{'ClientValues'}) || 0;
    my $facilityFields = new EntityFields();
    $facilityFields->setCount($facilityFieldCount);
    $facilityFields->setEntityID($self->{'RunParams'}{'e'});
    $facilityFields->setData($self->{'Data'});

    my $facilityFieldDataCluster;
    ($facilityFieldDataCluster, $self->{'RunDetails'}{'Errors'}) = $facilityFields->retrieveFormFieldData($self->{'RunParams'});
 
    #my @testErrors;
    #push @testErrors, "test error";
    #$self->{'RunDetails'}{'Errors'} = \@testErrors;
    if($self->{'RunDetails'}{'Errors'} and scalar(@{$self->{'RunDetails'}{'Errors'}})) {
        #There are errors - reset where we are to go back to the form again
        $self->decrementCurrentProcessIndex();
        return ('',2);
    }

    my $addedFields = 0;

    #check current tblEntityFields entry count for this specific process to avoid duplicates
    #if($facilityFieldCount != scalar@{$facilityFields->getAll()}){
    #    foreach my $fieldObjData (@{$facilityFieldDataCluster}){
    #        my $entityFieldObj = new EntityFieldObj(db => $self->{'db'}, ID => 0);
    #        $entityFieldObj->load();
    #        $entityFieldObj->setValues($fieldObjData);
    #        $entityFieldObj->write();
    #        $addedFields++;
    #    }

    #    $self->addCarryField('addedFields', $addedFields);
    #}

    foreach my $fieldObjData (@{$facilityFieldDataCluster}){
        my $existingEntityFieldID = $fieldObjData->{'intEntityFieldID'} || 0;
        #if previously added, set ID to $existingEntityFieldID to update record instead of inserting duplicates
        my $entityFieldObj = new EntityFieldObj(db => $self->{'db'}, ID => $existingEntityFieldID);
        $entityFieldObj->load();
        $entityFieldObj->setValues($fieldObjData);
        $entityFieldObj->write();
        $addedFields++;
    }

    return ('', 1);
}

sub display_products { 
    my $self = shift;

    my $facilityID = $self->ID();
    my $entityID = getLastEntityID($self->{'ClientValues'}) || 0;
    my $entityLevel = getLastEntityLevel($self->{'ClientValues'}) || 0;
    my $originLevel = $self->{'ClientValues'}{'authLevel'} || 0;
    my $entityRegisteringForLevel = getLastEntityLevel($self->{'ClientValues'}) || 0;
    my $client = $self->{'Data'}->{'client'};
    my $content = '';

    my $CheckProducts = getRegistrationItems(
        $self->{'Data'},
        'ENTITY',
        'PRODUCT',
        $originLevel,
        'NEW',
        $entityID,
        $entityRegisteringForLevel,
        0,
        undef,
        undef,
    );

    my @prodIDs = ();
    my %ProductRules=();
    foreach my $product (@{$CheckProducts})  {
        #next if($product->{'UseExistingThisEntity'} && checkExistingProduct($Data, $product->{'ID'}, $Defs::LEVEL_PERSON, $personID, $entityID, 'THIS_ENTITY'));
        #next if($product->{'UseExistingAnyEntity'} && checkExistingProduct($Data, $product->{'ID'}, $Defs::LEVEL_PERSON, $personID, $entityID, 'ANY_ENTITY'));

        $product->{'HaveForAnyEntity'} =1 if($product->{'UseExistingAnyEntity'} && checkExistingProduct($self->{'Data'}, $product->{'ID'}, $Defs::LEVEL_VENUE, 0, $entityID, 'ANY_ENTITY'));
        $product->{'HaveForThisEntity'} =1 if($product->{'UseExistingThisEntity'} && checkExistingProduct($self->{'Data'}, $product->{'ID'}, $Defs::LEVEL_VENUE, 0, $entityID, 'THIS_ENTITY'));

        push @prodIDs, $product->{'ID'};
        $ProductRules{$product->{'ID'}} = $product;
     }
    my $product_body='';
    if (@prodIDs)   {
        $product_body= getRegoProducts($self->{'Data'}, \@prodIDs, 0, $entityID, 0, 0, 0, 0, \%ProductRules);
     }

     my %ProductPageData = (
         #nextaction=>"PREGF_PU",
        target => $self->{'Data'}->{'target'},
        product_body => $product_body,
        hidden_ref => {},
        Lang => $self->{'Data'}->{'lang'},
        client => $client,
        NoFormFields => 1,
    );
    $content = runTemplate($self->{'Data'}, \%ProductPageData, 'registration/product_flow_backend.templ') || '';

    my %PageData = (
        HiddenFields => $self->stringifyCarryField(),
        Target => $self->{'Data'}{'target'},
        Errors => $self->{'RunDetails'}{'Errors'} || [],
        Content => $content,
        FlowSummary => '',
        FlowSummaryTemplate => '',
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

    my $entityID = getLastEntityID($self->{'ClientValues'}) || 0;
    my $entityLevel = getLastEntityLevel($self->{'ClientValues'}) || 0;
    my $originLevel = $self->{'ClientValues'}{'authLevel'} || 0;
    my $client = $self->{'Data'}->{'client'};
    my $rego_ref = {};

    my $txnIds = undef;
    my $CheckProducts = getRegistrationItems(
        $self->{'Data'},
        'ENTITY',
        'PRODUCT',
        $originLevel,
        'NEW',
        $entityID,
        $entityLevel,
        0,
        $rego_ref,
    );
    my ($txns_added, $amount) = insertRegoTransaction($self->{'Data'}, 0, 0, $self->{'RunParams'}, $entityID, $entityLevel, 1, '', $CheckProducts);
    $txnIds = join(':',@{$txns_added});

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
		my $diff = EntityDocuments::checkUploadedEntityDocuments($self->{'Data'}, $facilityID,  $venue_documents);

        my $cl = setClient($self->{'Data'}->{'clientValues'}) || '';
        my %cv = getClient($cl);
        $cv{'venueID'} = $facilityID;
        $cv{'currentLevel'} = $Defs::LEVEL_VENUE;
        my $clm = setClient(\%cv);

        my %documentData = (
            target => $self->{'Data'}->{'target'},
            documents => $diff,
            Lang => $self->{'Data'}->{'lang'},
            nextaction => 'VENUE_DOCS_u',
            client => $clm,
            venue => $facilityID,
        );
 
        $content = runTemplate($self->{'Data'}, \%documentData, 'entity/required_docs.templ') || '';  
    }
    else    {
        push @{$self->{'RunDetails'}{'Errors'}}, $self->{'Lang'}->txt("Invalid Registration ID");
    }


    my %PageData = (
        HiddenFields => $self->stringifyCarryField(),
        Target => $self->{'Data'}{'target'},
        Errors => $self->{'RunDetails'}{'Errors'} || [],
        #FlowSummary => buildSummaryData($self->{'Data'}, $personObj) || '',
        #FlowSummaryTemplate => 'registration/person_flow_summary.templ',
        Content => '',
        DocUploader => $content,
        Title => '',
        TextTop => '',
        TextBottom => '',
    );

    my $pagedata = $self->display(\%PageData);

    return ($pagedata,0);

}

sub process_documents { 
    my $self = shift;

	my $facilityID = $self->ID();
    my $entityID = getLastEntityID($self->{'ClientValues'}) || 0;
    my $entityLevel = getLastEntityLevel($self->{'ClientValues'}) || 0;
    my $originLevel = $self->{'ClientValues'}{'authLevel'} || 0;
    my $entityRegisteringForLevel = getLastEntityLevel($self->{'ClientValues'}) || 0;
    my $client = $self->{'Data'}->{'client'};  

	my $documents = getRegistrationItems(
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
	my $diff = EntityDocuments::checkUploadedEntityDocuments($self->{'Data'}, $facilityID, $documents);
	foreach my $dc (@{$diff}){ 
		push @{$self->{'RunDetails'}{'Errors'}},$dc->{'Name'};		
	}
	if($self->{'RunDetails'}{'Errors'} and scalar(@{$self->{'RunDetails'}{'Errors'}})) {
        #There are errors - reset where we are to go back to the form again
        $self->decrementCurrentProcessIndex();
        return ('',2);
    }
    return ('',1);
}

sub display_summary {
    my $self = shift;

    my $entityID = getLastEntityID($self->{'ClientValues'}) || 0;
    my $entityLevel = getLastEntityLevel($self->{'ClientValues'}) || 0;
    my $originLevel = $self->{'ClientValues'}{'authLevel'} || 0;
    my $client = $self->{'Data'}->{'client'};

    my $facilityFields = new EntityFields();
    $facilityFields->setEntityID($self->{'RunParams'}{'e'});
    $facilityFields->setData($self->{'Data'});

    my $content = '';

    if($self->{'RunDetails'}{'Errors'} and scalar(@{$self->{'RunDetails'}{'Errors'}})) {
        #There are errors - reset where we are to go back to the form again
        $self->decrementCurrentProcessIndex();
        return ('',2);
    }

    my %summaryData = ();
    my $summaryContent = runTemplate(
        $self->{'Data'},
        \%summaryData,
        'flow/facility_summary.templ',
    );

    my %PageData = (
        HiddenFields => $self->stringifyCarryField(),
        Target => $self->{'Data'}{'target'},
        Errors => $self->{'RunDetails'}{'Errors'} || [],
        FlowSummaryContent => 'note: follow personSummaryPanel',
        Content => $summaryContent,
        Title => '',
        TextTop => $content,
        TextBottom => '',
        ContinueButtonText => $self->{'Lang'}->txt('Submit to Member Association'),
    );
    my $pagedata = $self->display(\%PageData);

    return ($pagedata,0);
}
sub display_complete {
    my $self = shift;

    my $entityID = getLastEntityID($self->{'ClientValues'}) || 0;
    my $entityLevel = getLastEntityLevel($self->{'ClientValues'}) || 0;
    my $originLevel = $self->{'ClientValues'}{'authLevel'} || 0;
    my $client = $self->{'Data'}->{'client'};

    my $facilityFields = new EntityFields();
    $facilityFields->setEntityID($self->{'RunParams'}{'e'});
    $facilityFields->setData($self->{'Data'});

    my $content = '';
    if(scalar@{$facilityFields->getAll()}) {
        my $facilityID = $facilityFields->getEntityID();
        my $facilityObj = new EntityObj(db => $self->{'db'}, ID => $facilityID, cache => $self->{'Data'}->{'cache'});
        $facilityObj->load();
        my $PendingStatus =  {};
        $PendingStatus->{'strStatus'} = $Defs::ENTITY_STATUS_PENDING;
        $facilityObj->setValues($PendingStatus);
        $facilityObj->write();
        if($self->{'RunParams'}{'newvenue'})  {
            my $rc = WorkFlow::addWorkFlowTasks(
                $self->{'Data'},
                'ENTITY',
                'NEW',
                $self->{'ClientValues'}{'authLevel'} || 0,
                $facilityFields->getEntityID(),
                0,
                0,
                0,
            );
        }
        $facilityObj->load();

        $content = qq [<div class="alert"><div><span class="flash_success fa fa-check"></span><p>$self->{'Data'}->{'LevelNames'}{$Defs::LEVEL_VENUE} submitted for approval</p></div></div>]; # Venue ID = $facilityID AND entityID = $entityID </div><br> ];
    }
    else {
        push @{$self->{'RunDetails'}{'Errors'}}, $self->{'Lang'}->txt("Invalid Facility ID");
    }

    if($self->{'RunDetails'}{'Errors'} and scalar(@{$self->{'RunDetails'}{'Errors'}})) {
        #There are errors - reset where we are to go back to the form again
        $self->decrementCurrentProcessIndex();
        return ('',2);
    }

    my %facilityApprovalData = ();
    my $displayFacilityForApproval = runTemplate(
        $self->{'Data'},
        \%facilityApprovalData,
        'entity/complete.templ',
    );

    my %PageData = (
        HiddenFields => $self->stringifyCarryField(),
        Target => $self->{'Data'}{'target'},
        Errors => $self->{'RunDetails'}{'Errors'} || [],
        processStatus => 1,
        Content => $displayFacilityForApproval,
        Title => '',
        #TextTop => $content,
        TextTop => '',
        TextBottom => '',
        NoContinueButton => 1,
    );
    my $pagedata = $self->display(\%PageData);

    return ($pagedata,0);
}

sub loadObjectValues    {
    my $self = shift;
    my ($object) = @_;

    my %values = ();
    if($object) {
        for my $field (qw(
            strLocalName
            strLocalShortName
            intLocalLanguage
            strLatinName
            strLatinShortName
            strCity
            strRegion
            strISOCountry

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

            strEntityType
            intLegalTypeID
            strLegalID
            strDiscipline
            strOrganisationLevel
            strMANotes
            intFacilityTypeID
            strGender
            strDiscipline
            strEntityType
            intNotifications
            intEntityFieldCount

        )) {
            $values{$field} = $object->getValue($field);
        }
    }
    return \%values;
}

1;
