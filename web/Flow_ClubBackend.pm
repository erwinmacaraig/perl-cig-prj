package Flow_ClubBackend;

use strict;
use lib '.', '..', '../..', "../dashboard", "../user";
use Flow_BaseObj;
our @ISA =qw(Flow_BaseObj);

use TTTemplate;
use CGI qw(param);
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
use PersonSummaryPanel;
use Data::Dumper;
use UploadFiles;
use EntitySummaryPanel;
use IncompleteRegistrations;
use Transactions;
use FieldMessages;

use PersonRegistrationFlow_Common;
use Payments;


sub setProcessOrder {
    my $self = shift;
  
    my $lang = $self->{'Data'}{'lang'};
    $self->{'ProcessOrder'} = [       
        {
            'action' => 'cd',
            'function' => 'display_core_details',
            'label'  => $lang->txt('Club Details'),
            'fieldset'  => 'core',
            'title'  => $lang->txt('Club') . ' - ' . $lang->txt('Enter Club Information'),
        },
        {
            'action' => 'cdu',
            'function' => 'validate_core_details',
            'fieldset'  => 'core',
        },
        {
            'action' => 'cond',
            'function' => 'display_contact_details',
            'label'  => $lang->txt('Contact Details'),
            'fieldset'  => 'contactdetails',
            'title'  => $lang->txt('Club') . ' - ' . $lang->txt('Enter Contact Information'),
        },
        {
            'action' => 'condu',
            'function' => 'validate_contact_details',
            'fieldset'  => 'contactdetails',
        },
        {
            'action' => 'role',
            'function' => 'display_role_details',
            'label'  => $lang->txt('Organisation Details'),
            'fieldset' => 'roledetails',
            'title'  => $lang->txt('Club') . ' - ' . $lang->txt('Enter Organisation Information'),
        },
        {
            'action' => 'roleu',
            'function' => 'validate_role_details',
            'fieldset' => 'roledetails',
        },
        {
            'action' => 'd',
            'function' => 'display_documents',
            'label'  => $lang->txt('Documents'),
            'title'  => $lang->txt('Club') . ' - ' . $lang->txt('Upload Documents'),
        },
        {
            'action' => 'du',
            'function' => 'process_documents',
        },
        {
            'action' => 'p',
            'function' => 'display_products',
            'label'  => $lang->txt('Products'),
            'title'  => $lang->txt('Club') . ' - ' . $lang->txt('Choose Products'),
        },
        {
            'action' => 'pu',
            'function' => 'process_products',
        },
        {
            'action' => 'summ',
            'function' => 'display_summary',
            'label'  => $lang->txt('Summary'),
            'title'  => $lang->txt('Club') . ' - ' . $lang->txt('Summary'),
        },
        {
            'action' => 'c',
            'function' => 'display_complete',
            'label'  => $lang->txt('Complete'),
            'title'  => $lang->txt('Club') . ' - ' . $lang->txt('Submitted'),
            'NoDisplayInNav' => 1,
            'NoGoingBack' => 1,
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
    my $fieldMessages = getFieldMessages($self->{'Data'}, 'club', $self->{'Data'}->{'lang'}->getLocale());
    my($fieldsContent, undef, $scriptContent, $tabs) = $self->displayFields($clubperm,'', $fieldMessages);


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
            'Add',
            'Club',
        );

        my $st = qq[
            INSERT INTO tblEntityLinks (intParentEntityID, intChildEntityID)
            VALUES (?,?)
        ];
        my $query = $self->{'db'}->prepare($st);
        $query->execute($entityID, $clubObj->ID());

        $query->finish();
        createTempEntityStructure($self->{'Data'}, $clubData->{'intRealmID'}, $clubObj->ID()); 
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
    my $fieldMessages = getFieldMessages($self->{'Data'}, 'club', $self->{'Data'}->{'lang'}->getLocale());
    my($fieldsContent, undef, $scriptContent, $tabs) = $self->displayFields($clubperm,'', $fieldMessages);
    my $entitySummaryPanel = entitySummaryPanel($self->{'Data'}, $id);
    my %PageData = (
        HiddenFields => $self->stringifyCarryField(),
        Target => $self->{'Data'}{'target'},
        Errors => $self->{'RunDetails'}{'Errors'} || [],
        Content => $fieldsContent || '',
        ScriptContent => $scriptContent || '',
        FlowSummaryContent => $entitySummaryPanel,
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
	my $id = $self->ID() || 0;
	if($id){
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
    my $clubperm = ProcessPermissions($self->{'Data'}->{'Permissions'}, $self->{'FieldSets'}{'roledetails'}, 'Club',);

    my $fieldMessages = getFieldMessages($self->{'Data'}, 'club', $self->{'Data'}->{'lang'}->getLocale());
    my($fieldsContent, undef, $scriptContent, $tabs) = $self->displayFields($clubperm,'',$fieldMessages);
   
    my $entitySummaryPanel = entitySummaryPanel($self->{'Data'}, $id);

    my %PageData = (
        HiddenFields => $self->stringifyCarryField(),
        Target => $self->{'Data'}{'target'},
        Errors => $self->{'RunDetails'}{'Errors'} || [],
        Content => $fieldsContent || '',
        FlowSummaryContent => $entitySummaryPanel || '',
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
    my $memperm = ProcessPermissions($self->{'Data'}->{'Permissions'}, $self->{'FieldSets'}{'roledetails'}, 'Club',); 
	
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

	$self->addCarryField('payMethod','');
    my $facilityID = $self->ID();
    my $entityID = getLastEntityID($self->{'ClientValues'}) || 0;
    my $entityLevel = getLastEntityLevel($self->{'ClientValues'}) || 0;
    my $originLevel = $self->{'ClientValues'}{'authLevel'} || 0;
    #my $entityRegisteringForLevel = getLastEntityLevel($self->{'ClientValues'}) || 0;
	my $entityRegisteringForLevel = $Defs::LEVEL_CLUB;
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
	my $totalamountchk = 0;
    foreach my $product (@{$CheckProducts})  {
        #next if($product->{'UseExistingThisEntity'} && checkExistingProduct($Data, $product->{'ID'}, $Defs::LEVEL_PERSON, $personID, $entityID, 'THIS_ENTITY'));
        #next if($product->{'UseExistingAnyEntity'} && checkExistingProduct($Data, $product->{'ID'}, $Defs::LEVEL_PERSON, $personID, $entityID, 'ANY_ENTITY'));

        $product->{'HaveForAnyEntity'} =1 if($product->{'UseExistingAnyEntity'} && checkExistingProduct($self->{'Data'}, $product->{'ID'}, $Defs::LEVEL_VENUE, 0, $entityID, 'ANY_ENTITY'));
        $product->{'HaveForThisEntity'} =1 if($product->{'UseExistingThisEntity'} && checkExistingProduct($self->{'Data'}, $product->{'ID'}, $Defs::LEVEL_VENUE, 0, $entityID, 'THIS_ENTITY'));

        push @prodIDs, $product->{'ID'};
        $ProductRules{$product->{'ID'}} = $product;
	$totalamountchk += $product->{'ProductPrice'} if($product->{'Required'} && $product->{'ProductPrice'} > 0);
#print STDERR "ERWIN CAN YOU CHECK.  If all products are optional needs thought on how we show Payment Options - should we adjust this in other flows";
	
     }
    my $product_body='';
    if (@prodIDs)   {
        $product_body= getRegoProducts($self->{'Data'}, \@prodIDs, 0, $entityID, 0, 0, 0, 0, \%ProductRules, 0, 0);
     }
     my %ProductPageData = (
         #nextaction=>"PREGF_PU",
        target => $self->{'Data'}->{'target'},
        product_body => $product_body,
        hidden_ref => {},
        Lang => $self->{'Data'}->{'lang'},
	mandatoryPayment => $self->{'Data'}->{'SystemConfig'}{'AllowTXNs_CCs_clubFlow'},
	payMethod => $self->{'RunParams'}{'payMethod'} || '',
        client => $client,
        NoFormFields => 1,
	amountCheck=>$totalamountchk,
    );
    
    my $id = $self->ID() || 0;
    my $entitySummaryPanel = entitySummaryPanel($self->{'Data'}, $id);
    
    $content = runTemplate($self->{'Data'}, \%ProductPageData, 'registration/product_flow_backend.templ') || '';

    my %PageData = (
        HiddenFields => $self->stringifyCarryField(),
        Target => $self->{'Data'}{'target'},
        Errors => $self->{'RunDetails'}{'Errors'} || [],
        Content => $content,
        FlowSummaryContent => $entitySummaryPanel,
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
use Data::Dumper;
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

	cleanRegoTransactions($self->{'Data'},0, $self->{'RunParams'}{'newclubid'}, $Defs::LEVEL_CLUB);
    my ($txns_added, $amount) = insertRegoTransaction($self->{'Data'}, 0, $self->{'RunParams'}{'newclubid'}, $self->{'RunParams'}, $entityID, $entityLevel, $Defs::LEVEL_CLUB, '', $CheckProducts);
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
    #my $entityRegisteringForLevel = getLastEntityLevel($self->{'ClientValues'}) || 0; 
	#my $entityLevel = getLastEntityLevel($self->{'ClientValues'}) || 0;
	my $entityRegisteringForLevel = $Defs::LEVEL_CLUB;
    my $client = $self->{'Data'}->{'client'};
 	my $ctrl = 0;
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

		#filter documents
		my @required_docs_listing = ();
		my @optional_docs_listing = ();
		
					 
		my $diff = EntityDocuments::checkUploadedEntityDocuments($self->{'Data'}, $clubID,  $club_documents, $ctrl);
		foreach my $rdc (@{$diff}){
			if($rdc->{'Required'}){
				push @required_docs_listing,$rdc;
			}
			else {
				push @optional_docs_listing, $rdc;
			}
		}	

		my %clientValues = getClient($client);
		

		$clientValues{'clubID'} = $self->ID;
		$clientValues{'currentLevel'} = $Defs::LEVEL_CLUB; 
		my $clmx = setClient(\%clientValues);

        my %documentData = (
            target => $self->{'Data'}->{'target'},
            documents => \@required_docs_listing,
			optionaldocs => \@optional_docs_listing,
            Lang => $self->{'Data'}->{'lang'},           
			client => $clmx,
			clubID => $clubID,
            
        );
		
        $content = runTemplate($self->{'Data'}, \%documentData, 'club/required_docs.templ') || '';  
		
	}
	else    {
        push @{$self->{'RunDetails'}{'Errors'}}, $self->{'Lang'}->txt("Invalid Registration ID");
    }
   
    my $entitySummaryPanel = entitySummaryPanel($self->{'Data'}, $clubID);
    
    my %PageData = (
        HiddenFields => $self->stringifyCarryField(),
        Target => $self->{'Data'}{'target'},
        Errors => $self->{'RunDetails'}{'Errors'} || [],
        FlowSummaryContent => $entitySummaryPanel || '',
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
	
	my $clubID = $self->ID();
    my $entityID = getLastEntityID($self->{'ClientValues'}) || 0;
    my $entityLevel = getLastEntityLevel($self->{'ClientValues'}) || 0;
    my $originLevel = $self->{'ClientValues'}{'authLevel'} || 0;
    #my $entityRegisteringForLevel = getLastEntityLevel($self->{'ClientValues'}) || 0;
	my $entityRegisteringForLevel = $Defs::LEVEL_CLUB;
    my $client = $self->{'Data'}->{'client'};
	my $ctrl = 1;
    my $rego_ref = {};
   
    my $content = '';
    #1 I just need to know how many documents are required
	my $club_documents = getRegistrationItems(
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

	my @required_docs_listing = ();
	my @optional_docs_listing = ();
		
	foreach my $rdc (@{$club_documents}){
		if($rdc->{'Required'}){
			push @required_docs_listing,$rdc;
		}
		else {
			push @optional_docs_listing, $rdc;
		}
	}		

	my $diff = EntityDocuments::checkUploadedEntityDocuments($self->{'Data'}, $clubID, \@required_docs_listing, $ctrl);
	my $errStringPrepend = $self->{'Data'}{'lang'}->txt('Required Document Missing') .' <ul>';
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
	my $payMethod= $self->{'RunParams'}{'payMethod'} || '';

    my $clubObj = new EntityObj(db => $self->{'db'}, ID => $id, cache => $self->{'Data'}{'cache'});
    $clubObj->load();

	my $hiddenFields = $self->getCarryFields();
	 $hiddenFields->{'rfp'} = 'c';#$self->{'RunParams'}{'rfp'};
        $hiddenFields->{'__cf'} = $self->{'RunParams'}{'__cf'};
        $hiddenFields->{'cA'} = "CLUBFLOW";

    my $content = '';
	
    my $entitySummaryPanel = entitySummaryPanel($self->{'Data'}, $id);
	
	my $gatewayConfig = undef;
	my $txn_invoice_url='';
my ($txnCount, $amountDue, $logIDs) = getEntityTXN($self->{'Data'}, $clubObj->ID());
    if ($txnCount && $self->{'Data'}->{'SystemConfig'}{'AllowTXNs_CCs_clubFlow'}) {
        $gatewayConfig = generateRegoFlow_Gateways($self->{'Data'}, $client, "PREGF_CHECKOUT", $hiddenFields, $txn_invoice_url);
        $gatewayConfig->{'amountDue'} = $amountDue;
    }
    $content = ''; 
	my $documents = getUploadedFiles( $self->{'Data'}, $Defs::LEVEL_CLUB, $id, $Defs::UPLOADFILETYPE_DOC , $client );
	use Club;	
	use Countries;
	my $isocountries  = getISOCountriesHash();

	$hiddenFields->{'payMethod'} = 'notrequired' if (! $amountDue);
        my %PaymentConfig = (
            totalAmountDue => $amountDue,
            totalPaymentDue => $amountDue,
            dollarSymbol => $self->{'Data'}->{'SystemConfig'}{'DollarSymbol'} || '$',
            paymentMethodText => $Defs::paymentMethod{$payMethod} || '',
        );
my $displayPayment = ($amountDue and $payMethod) ? 1 : 0;
    my %summaryClubData = (
			organization => $clubObj->{'DBData'}{'strLocalName'}, 
			organizationShortName => $clubObj->{'DBData'}{'strLocalShortName'},
			foundingdate => $self->{'Data'}{'l10n'}{'date'}->format($clubObj->{'DBData'}{'dtFrom'},'MEDIUM'),
			dissolutiondate => $self->{'Data'}{'l10n'}{'date'}->format($clubObj->{'DBData'}{'dtTo'},'MEDIUM'),
			country => $isocountries->{$clubObj->{'DBData'}{'strISOCountry'}},
			strLegalID => $clubObj->{'DBData'}{'strLegalID'},
			sport => $clubObj->{'DBData'}{'strDiscipline'},
			sportName => $Defs::entitySportType{$clubObj->{'DBData'}{'strDiscipline'}},
			comment => $clubObj->{'DBData'}{'strMANotes'},
			contactEmail => $clubObj->{'DBData'}{'strEmail'},
			postalcode => $clubObj->{'DBData'}{'strPostalCode'},
			contactPerson => $clubObj->{'DBData'}{'strContact'},
			contactPhone => $clubObj->{'DBData'}{'strPhone'},
			contactAddress => $clubObj->{'DBData'}{'strAddress'},
			comment => $clubObj->{'DBData'}{'strMANotes'},
			entityType => $clubObj->{'DBData'}{'strEntityType'},
			entityTypeName => $Defs::entityType{$clubObj->{'DBData'}{'strEntityType'}},
			documents => $documents,
			legaltype => Club::getLegalTypeName($self->{'Data'},$clubObj->{'DBData'}{'intLegalTypeID'}),
			organizationType => $clubObj->{'DBData'}{'strEntityType'},
			organizationTypeName => $Defs::entityType{$clubObj->{'DBData'}{'strEntityType'}},
			organizationLevel => $clubObj->{'DBData'}{'strOrganisationLevel'},  
			organizationLevelName => $Defs::personLevel{$clubObj->{'DBData'}{'strOrganisationLevel'}},  
			bankAccountDetails => $clubObj->{'DBData'}{'strBankAccountNumber'},
			editlink =>  $self->{'Data'}{'target'}."?".$self->stringifyURLCarryField(),
            OriginLevel => $originLevel,
			DisplayPayment => $displayPayment,
			payment => \%PaymentConfig,
	);
	
    my $summaryClubContent = runTemplate(
        $self->{'Data'},
       \%summaryClubData,
        'flow/club_summary.templ',
    );

	$self->addCarryField('payMethod',$payMethod);

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

print STDERR Dumper($self->stringifyCarryField());
    my %PageData = (
        Errors => $self->{'RunDetails'}{'Errors'} || [],
        FlowSummaryContent => $entitySummaryPanel || '',
        Content => $summaryClubContent,
        Title => '',
        TextTop => '',
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
                $self->{'ClientValues'}{'currentLevel'} || $self->{'ClientValues'}{'authLevel'} || 0,
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

    my $entitySummaryPanel = entitySummaryPanel($self->{'Data'}, $id);
    
    my $maObj = getInstanceOf($self->{'Data'}, 'national');
    my $maName = $maObj ? $maObj->name() : '';

### Payment
my $hiddenFields = $self->getCarryFields();
        $hiddenFields->{'rfp'} = 'c';#$self->{'RunParams'}{'rfp'};
        $hiddenFields->{'__cf'} = $self->{'RunParams'}{'__cf'};
 my $payMethod= $hiddenFields->{'payMethod'} || param('payMethod') || '';
 my $logID = param('tl') || 0;
 my $paymentResult = '';
 my $payStatus = 0;
 my $txnCount = 0;
 my $logIDs;
 my $amountDue = 0;
print STDERR "PAY METHOD $payMethod\n";
($txnCount, $amountDue, $logIDs) = getEntityTXN($self->{'Data'}, $clubObj->ID());
print STDERR "LOGID $amountDue $logID\n";
 ($payStatus, $paymentResult) = displayPaymentResult($self->{'Data'}, $logID, 1, '');

	$payMethod = '' if (!$amountDue and $payStatus == -1);
print STDERR "SSSSSS: $amountDue $payMethod $paymentResult $payStatus\n";

    my %clubApprovalData = (
        EntitySummaryPanel => $entitySummaryPanel,
        client => $self->{'Data'}->{'client'},
        target => $self->{'Data'}->{'target'},
        MA => $maName,
        url => $Defs::base_url,
	payLaterFlag=> ($amountDue and $payMethod eq 'later') ? 1 : 0,
        payNowFlag=> ($payMethod eq 'now') ? 1 : 0,
        payNowMsg=> (! $amountDue and $payMethod eq 'now') ? $paymentResult : '',
        payNowStatus=> $payStatus,
    );
    my $displayClubForApproval = runTemplate(
        $self->{'Data'},
        \%clubApprovalData,
        'club/complete.templ',
    );

    my %PageData = (
        HiddenFields => $self->stringifyCarryField(),
        Target => $self->{'Data'}{'target'},
        Errors => $self->{'RunDetails'}{'Errors'} || [],
        processStatus => 1,
        Content => $displayClubForApproval,
        Title => '',
        #TextTop => $content,
        TextTop => '',
        TextBottom => '',
        NoContinueButton=> 1,
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
            strStatus
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
            strBankAccountNumber
            intNotifications
            intAcceptSelfRego
        )) {
            $values{$field} = $object->getValue($field);
        }
    }
    return \%values;
}


sub getStateIds {
    my $self = shift;

    my $currentLevel = $self->{'ClientValues'}{'authLevel'} || 0;
    my $userEntityID = getID($self->{'ClientValues'}, $currentLevel) || 0;

    return (
        'CLUB',
        $userEntityID,
        $self->ID(),
        0,
        $self->{'ClientValues'}{'userID'},
    );
}

sub cancelFlow{
    my $self = shift;

    IncompleteRegistrations::deleteRelatedRegistrationRecords($self->{'Data'}, $self->getStateIds());

    return 1;
}

sub getEntityTXN    {

    my ($Data, $entityID) = @_;

    my $st = qq[
        SELECT curAmount, intTransLogID, intTransactionID, intStatus
        FROM tblTransactions
        WHERE
            intRealmID =?
            AND intID = ?
            AND intPersonRegistrationID = 0
            AND intTableType = $Defs::LEVEL_CLUB
    ];
        my $qry = $Data->{'db'}->prepare($st);
        $qry->execute($Data->{'Realm'}, $entityID);
    my $count = 0;
   my %tlogIDs=();
    my $amount = 0;
    while (my $dref= $qry->fetchrow_hashref())  {
        $tlogIDs{$dref->{'intTransLogID'}} = 1 if ($dref->{'intTransLogID'} and ! exists $tlogIDs{$dref->{'intTransLogID'}});
        if ($dref->{'intStatus'} == 0)  {
            $amount += $dref->{'curAmount'};
            $count++;
        }
    }
print STDERR "getEntityTXM $count $amount\n";
    return ($count, $amount, \%tlogIDs);
}

1;
