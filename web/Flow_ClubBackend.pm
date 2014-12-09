package Flow_ClubBackend;

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
use PersonUserAccess;
use EntityFieldsSetup;
use Data::Dumper;

sub setProcessOrder {
    my $self = shift;
  
    $self->{'ProcessOrder'} = [       
        {
            'action' => 'cd',
            'function' => 'display_core_details',
            'label'  => 'Club Details',
            'fieldset'  => 'core',
            'title'  => 'Club - Enter Club Information',
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
            'title'  => 'Club - Enter Contact Information',
        },
        {
            'action' => 'condu',
            'function' => 'validate_contact_details',
            'fieldset'  => 'contactdetails',
        },
        {
            'action' => 'role',
            'function' => 'display_role_details',
            'label'  => 'Organisation Details',
            'fieldset' => 'roledetails',
            'title'  => 'Club - Enter Organisation Information',
        },
        {
            'action' => 'roleu',
            'function' => 'validate_role_details',
            'fieldset' => 'roledetails',
        },
        {
            'action' => 'd',
            'function' => 'display_documents',
            'label'  => 'Documents',
            'title'  => 'Club - Upload Documents',
        },
        {
            'action' => 'du',
            'function' => 'process_documents',
        },
        {
            'action' => 'p',
            'function' => 'display_products',
            'label'  => 'Products',
            'title'  => 'Club - Choose Products',
        },
        {
            'action' => 'pu',
            'function' => 'process_products',
        },
        {
            'action' => 'summ',
            'function' => 'display_summary',
            'label'  => 'Summary',
            'title'  => 'Club - Summary',
        },
        {
            'action' => 'c',
            'function' => 'display_complete',
            'label'  => 'Complete',
            'title'  => 'Club - Submitted',
        },
    ];
}

sub setupValues    {
    my $self = shift;
    my ($values) = @_;
    $values ||= {};
    $self->{'FieldSets'} = clubFieldsSetup($self->{'Data'}, $values);
}


sub display_core_details { 
    my $self = shift;

    my $clubperm = ProcessPermissions($self->{'Data'}->{'Permissions'}, $self->{'FieldSets'}{'core'}, 'Club',);

    my $id = $self->ID() || 0;
    if($id)   {
        my $clubObj = new EntityObj(db => $self->{'db'}, ID => $id, cache => $self->{'Data'}{'cache'});
        $clubObj->load();
        if($clubObj->ID())    {
            my $objectValues = $self->loadObjectValues($clubObj);
            $self->setupValues($objectValues);
        }
        if(!doesUserHaveEntityAccess($self->{'Data'}, $id,'WRITE')) {
            return ('Invalid User',0);
        }

    }
    my($fieldsContent, undef, $scriptContent, $tabs) = $self->displayFields($clubperm);

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

    my $clubData = {};
    my $memperm = ProcessPermissions($self->{'Data'}->{'Permissions'}, $self->{'FieldSets'}{'core'}, 'Club',);
    ($clubData, $self->{'RunDetails'}{'Errors'}) = $self->gatherFields($memperm);


    if($self->{'RunDetails'}{'Errors'} and scalar(@{$self->{'RunDetails'}{'Errors'}})) {
        #There are errors - reset where we are to go back to the form again
        $self->decrementCurrentProcessIndex();
        return ('',2);
    }

    my $authID = getID($self->{'ClientValues'}, $self->{'ClientValues'}{'authLevel'});
    my $entityID = getID($self->{'ClientValues'});

    my $id = $self->ID() || 0;
    my $clubObj = new EntityObj(db => $self->{'db'}, ID => $id, cache => $self->{'Data'}{'cache'});
    $clubObj->load();
    if($id and !doesUserHaveEntityAccess($self->{'Data'}, $id,'WRITE')) {
        return ('Invalid User',0);
    }

    my $clubStatus = ($clubData->{'dissolved'}) ? $Defs::ENTITY_STATUS_DE_REGISTERED : $Defs::ENTITY_STATUS_INPROGRESS;
    $clubData->{'strStatus'} = $clubStatus;
    $clubData->{'intRealmID'} = $self->{'Data'}{'Realm'};
    $clubData->{'intEntityLevel'} = $Defs::LEVEL_CLUB;
    $clubData->{'intCreatedByEntityID'} = $authID;
    $clubData->{'intDataAccess'} = $Defs::DATA_ACCESS_FULL;

    #delete dissolved value as it doesn't exist in tblEntity
    delete $clubData->{'dissolved'};
    $clubObj->setValues($clubData);

    $clubObj->write();
    if($clubObj->ID()){
        if(!$id)    { 
            $self->setID($clubObj->ID()); 
            $self->addCarryField('newclub',1);
            $self->addCarryField('newclubid', $clubObj->ID());
        }
        #my $client = setClient($self->{'ClientValues'});
        #$self->addCarryField('client',$client);
        auditLog(
            $clubObj->ID(),
            $self->{'Data'},
            'ADD',
            'CLUB',
        );

        my $st = qq[
            INSERT INTO tblEntityLinks (intParentEntityID, intChildEntityID)
            VALUES (?,?)
        ];
        my $query = $self->{'db'}->prepare($st);
        $query->execute($entityID, $clubObj->ID());

        $query->finish();
        createTempEntityStructure($self->{'Data'}); 
    }


    return ('',1);
}

sub display_contact_details {
    my $self = shift;
    my $id = $self->ID() || 0;
    if($id)   {
        my $clubObj = new EntityObj(db => $self->{'db'}, ID => $id, cache => $self->{'Data'}{'cache'});
        $clubObj->load();
        if($clubObj->ID())    {
            my $objectValues = $self->loadObjectValues($clubObj);
            $self->setupValues($objectValues);
        }
        if(!doesUserHaveEntityAccess($self->{'Data'}, $id,'WRITE')) {
            return ('Invalid User',0);
        }
    }

    my $clubperm = ProcessPermissions($self->{'Data'}->{'Permissions'}, $self->{'FieldSets'}{'contactdetails'}, 'Club',);
    my($fieldsContent, undef, $scriptContent, $tabs) = $self->displayFields($clubperm);
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

    my $clubData = {};
    my $clubperm = ProcessPermissions($self->{'Data'}->{'Permissions'}, $self->{'FieldSets'}{'contactdetails'}, 'Club',);
    ($clubData, $self->{'RunDetails'}{'Errors'}) = $self->gatherFields($clubperm);
    my $id = $self->ID() || 0;
    if(!doesUserHaveEntityAccess($self->{'Data'}, $id,'WRITE')) {
        return ('Invalid User',0);
    }
    if(!$id){
        push @{$self->{'RunDetails'}{'Errors'}}, 'Invalid club.';
    }
    if($self->{'RunDetails'}{'Errors'} and scalar(@{$self->{'RunDetails'}{'Errors'}})) {
        #There are errors - reset where we are to go back to the form again
        $self->decrementCurrentProcessIndex();
        return ('',2);
    }

    my $clubObj = new EntityObj(db => $self->{'db'}, ID => $id, cache => $self->{'Data'}{'cache'});
    $clubObj->load();
    $clubObj->setValues($clubData);

    $clubObj->write();

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

    my $clubData = {};
    my $memperm = ProcessPermissions($self->{'Data'}->{'Permissions'}, $self->{'FieldSets'}{'core'}, 'Club',);
    ($clubData, $self->{'RunDetails'}{'Errors'}) = $self->gatherFields($memperm);
    my $id = $self->ID() || 0;
    if(!doesUserHaveEntityAccess($self->{'Data'}, $id,'WRITE')) {
        return ('Invalid User',0);
    }
    #delete $clubData->{'strLevel'};
    if(!$id){
        push @{$self->{'RunDetails'}{'Errors'}}, 'Invalid club.';
    }
    if($self->{'RunDetails'}{'Errors'} and scalar(@{$self->{'RunDetails'}{'Errors'}})) {
        #There are errors - reset where we are to go back to the form again
        $self->decrementCurrentProcessIndex();
        return ('',2);
    }

    my $clubObj = new EntityObj(db => $self->{'db'}, ID => $id, cache => $self->{'Data'}{'cache'});
    $clubObj->load();
    $clubObj->setValues($clubData);

    $clubObj->write();

    return ('',1);
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
    my $entityRegisteringForLevel = getLastEntityLevel($self->{'ClientValues'}) || 0;
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
        $entityRegisteringForLevel,
        0,
        undef,
        undef,
    );

    my ($txns_added, $amount) = insertRegoTransaction($self->{'Data'}, 0, 0, $self->{'RunParams'}, $entityID, $entityLevel, 1, '', $CheckProducts);
    $txnIds = join(':',@{$txns_added});

    $self->addCarryField('txnIds',$txnIds);

    return ('',1);
}

sub display_documents { 
    my $self = shift;
	my $clubID = $self->ID();
    my $entityID = getLastEntityID($self->{'ClientValues'}) || 0;
    my $entityLevel = getLastEntityLevel($self->{'ClientValues'}) || 0;
    my $originLevel = $self->{'ClientValues'}{'authLevel'} || 0;
    my $entityRegisteringForLevel = getLastEntityLevel($self->{'ClientValues'}) || 0;
    my $client = $self->{'Data'}->{'client'};

    my $rego_ref = {};
    my $club_documents = '';
    my $content = '';
	
	if($clubID) {
        $club_documents = getRegistrationItems(
            $self->{'Data'},
            'ENTITY',
            'DOCUMENT',
            $originLevel,
            'NEW',
            $clubID,
            $entityRegisteringForLevel,
            0,
            undef,
            $Defs::DOC_FOR_CLUBS,
        );

			 
		my $diff = EntityDocuments::checkUploadedEntityDocuments($self->{'Data'}, $clubID,  $club_documents);
	
		my $cl = setClient($self->{'Data'}->{'clientValues'}) || '';
        my %cv = getClient($cl);
        $cv{'clubID'} = $clubID;
        $cv{'currentLevel'} = $Defs::LEVEL_CLUB;
        my $clm = setClient(\%cv);

        my %documentData = (
            target => $self->{'Data'}->{'target'},
            documents => $diff,
            Lang => $self->{'Data'}->{'lang'},
            #nextaction => 'VENUE_DOCS_u',
            client => $clm,
			clubID => $clubID,
            #venue => $facilityID,
        );
 
        $content = runTemplate($self->{'Data'}, \%documentData, 'club/required_docs.templ') || '';  
		print FH "content:\n $content \n";
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
        Title => '',
        TextTop => $content,
        TextBottom => '',
    );

    my $pagedata = $self->display(\%PageData);

    return ($pagedata,0);

}

sub process_documents { 
    my $self = shift;
	
	my $clubID = $self->ID();
    my $entityID = getLastEntityID($self->{'ClientValues'}) || 0;
    my $entityLevel = getLastEntityLevel($self->{'ClientValues'}) || 0;
    my $originLevel = $self->{'ClientValues'}{'authLevel'} || 0;
    my $entityRegisteringForLevel = getLastEntityLevel($self->{'ClientValues'}) || 0;
    my $client = $self->{'Data'}->{'client'};

    my $rego_ref = {};
   
    my $content = '';
    #1 I just need to know how many documents are required
	my $documents = getRegistrationItems(
            $self->{'Data'},
            'ENTITY',
            'DOCUMENT',
            $originLevel,
            'NEW',
            $clubID,
            $entityRegisteringForLevel,
            0,
            undef,
            $Defs::DOC_FOR_CLUBS,
        );

	my $diff = EntityDocuments::checkUploadedEntityDocuments($self->{'Data'}, $clubID, $documents);
	my $errStringPrepend = 'Required Document Missing <ul>';
	foreach my $dc (@{$diff}){ 
        $errStringPrepend .= '<li>' . $dc->{'Name'} . '</li>';		
	}
    $errStringPrepend .= '</ul>';
    
    if(scalar(@{$diff})){
            push @{$self->{'RunDetails'}{'Errors'}},$errStringPrepend;
    }

	if($self->{'RunDetails'}{'Errors'} and scalar(@{$self->{'RunDetails'}{'Errors'}})) {
        #There are errors - reset where we are to go back to the form again
        $self->decrementCurrentProcessIndex();
        return ('',2);
    }
	
    return ('',1);
}
sub display_summary     {
    my $self = shift;

    my $id = $self->ID() || 0;
    my $entityID = getLastEntityID($self->{'ClientValues'}) || 0;
    my $entityLevel = getLastEntityLevel($self->{'ClientValues'}) || 0;
    my $originLevel = $self->{'ClientValues'}{'authLevel'} || 0;
    my $client = $self->{'Data'}->{'client'};

    my $clubObj = new EntityObj(db => $self->{'db'}, ID => $id, cache => $self->{'Data'}{'cache'});
    $clubObj->load();

    my $content = '';

## Put into a template
    $content = 'Include summary here';

    my %PageData = (
        HiddenFields => $self->stringifyCarryField(),
        Target => $self->{'Data'}{'target'},
        Errors => $self->{'RunDetails'}{'Errors'} || [],
        Content => '',
        Title => '',
        TextTop => $content,
        ContinueButtonText => $self->{'Lang'}->txt('Submit to Member Association'),
        TextBottom => '',
    );
    my $pagedata = $self->display(\%PageData);

    return ($pagedata,0);
}
sub display_complete {
    my $self = shift;

    my $id = $self->ID() || 0;
    my $entityID = getLastEntityID($self->{'ClientValues'}) || 0;
    my $entityLevel = getLastEntityLevel($self->{'ClientValues'}) || 0;
    my $originLevel = $self->{'ClientValues'}{'authLevel'} || 0;
    my $client = $self->{'Data'}->{'client'};

    my $clubObj = new EntityObj(db => $self->{'db'}, ID => $id, cache => $self->{'Data'}{'cache'});
    $clubObj->load();

    my $content = '';
    my $clubStatus = $clubObj->getValue('strStatus');
    if($clubObj->ID()) {
        my $PendingStatus =  {};
        $PendingStatus->{'strStatus'} = $Defs::ENTITY_STATUS_PENDING;
        $clubObj->setValues($PendingStatus);
        $clubObj->write();
        
        if($self->{'RunParams'}{'newclub'})  {
            my $rc = WorkFlow::addWorkFlowTasks(
                $self->{'Data'},
                'ENTITY',
                'NEW',
                $self->{'ClientValues'}{'authLevel'} || 0,
                $clubObj->ID(),
                0,
                0,
                0,
            );
        }

        if($clubStatus eq $Defs::ENTITY_STATUS_DE_REGISTERED) {
            my $resetStatus = {};
            $resetStatus->{'strStatus'} = $clubStatus;

            $clubObj->setValues($resetStatus);
            $clubObj->write();
        }
        $clubObj->load();
        my $clubStatus = $clubObj->getValue('strStatus');

        my $clubID = $clubObj->ID();
        $content = qq [<div class="col-md-9"><div class="alert"><div><span class="flash_success fa fa-check"></span><p>$self->{'Data'}->{'LevelNames'}{$Defs::LEVEL_CLUB} Added Successfully</p></div></div></div> ];
    }
    else {
        push @{$self->{'RunDetails'}{'Errors'}}, $self->{'Lang'}->txt("Invalid Club ID");
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
        NoContinueButton=>1,
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
            dtFrom
            dissolved
            dtTo
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
            strContact

            strEntityType
            intLegalTypeID
            strLegalID
            strDiscipline
            strOrganisationLevel
            strMANotes
        )) {
            $values{$field} = $object->getValue($field);
        }
    }
    return \%values;
}

