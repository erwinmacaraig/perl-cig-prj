package PersonRegistrationFlow_Common;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = @EXPORT_OK = qw(
    displayRegoFlowComplete
    displayRegoFlowCompleteBulk
    displayRegoFlowCheckout
    displayRegoFlowDocuments
    displayRegoFlowProducts
    displayRegoFlowProductsBulk
    generateRegoFlow_Gateways
    validateRegoID
    save_rego_products
    add_rego_record
    bulkRegoSubmit
);

use strict;
use lib '.', '..', "comp", 'RegoForm', "dashboard", "RegoFormBuilder",'PaymentSplit', "user";
use PersonRegistration;
use RegistrationItem;
use PersonRegisterWhat;
use RegoProducts;
use Reg_common;
use CGI qw(:cgi unescape);
use Payments;
use RegoTypeLimits;
use TTTemplate;
use Transactions;
use Products;
use WorkFlow;
use Data::Dumper;

sub displayRegoFlowCompleteBulk {

    my ($Data, $client) = @_;
    my %PageData = (
        target => $Data->{'target'},
        Lang => $Data->{'lang'},
        client=>$client,
    );
    my $body = runTemplate($Data, \%PageData, 'registration/completebulk.templ') || '';
    return $body;
}
    
sub displayRegoFlowComplete {

    my ($Data, $regoID, $client, $originLevel, $rego_ref, $entityID, $personID, $hidden_ref) = @_;
    my $lang=$Data->{'lang'};

    my $ok = 0;
    if ($rego_ref->{'strRegistrationNature'} eq 'RENEWAL' or $rego_ref->{'registrationNature'} eq 'RENEWAL') {
        $ok=1;
    }
    else    {
        $ok = checkRegoTypeLimits($Data, $personID, $regoID, $rego_ref->{'sport'}, $rego_ref->{'personType'}, $rego_ref->{'personEntityRole'}, $rego_ref->{'personLevel'}, $rego_ref->{'ageLevel'});
    }
    my $body = '';
    if (!$ok)   {
        my $error = $lang->txt("You cannot register this combination, limit exceeded");
        my $url = $Data->{'target'}."?client=$client&amp;a=PREGF_T";
        my %PageData = (
            return_url => $url,
            error => $error,
            target => $Data->{'target'},
            Lang => $lang,
            client => $client,
        );
        $body = runTemplate($Data, \%PageData, 'registration/error.templ') || '';
    }
    if ($ok)   {
        submitPersonRegistration(
            $Data, 
            $personID,
            $regoID,
            $rego_ref
         );
         
        my @products= split /:/, $hidden_ref->{'prodIds'};
        foreach my $prod (@products){ $hidden_ref->{"prod_$prod"} =1;}
        my @productQty= split /:/, $hidden_ref->{'prodQty'};
        foreach my $prodQty (@productQty){ 
            my ($prodID, $qty) = split /-/, $prodQty;
            $hidden_ref->{"prodQTY_$prodID"} =$qty;
        }
        $hidden_ref->{'txnIds'} = save_rego_products($Data, $regoID, $personID, $entityID, $rego_ref->{'entityLevel'}, $rego_ref, $hidden_ref); #\%params);

         my $url = $Data->{'target'}."?client=$client&amp;a=P_HOME;";
         my $pay_url = $Data->{'target'}."?client=$client&amp;a=P_TXNLog_list;";
        my $gateways = '';
         if (1==2)   {
            $gateways = generateRegoFlow_Gateways($Data, $client, "PREGF_CHECKOUT", $hidden_ref);
         }
        my %PageData = (
            person_home_url => $url,
            gateways => $gateways,
            txns_url => $pay_url,
            target => $Data->{'target'},
            RegoStatus => $rego_ref->{'strStatus'},
            hidden_ref=> $hidden_ref,
            Lang => $Data->{'lang'},
            client=>$client,
        );
        $body = runTemplate($Data, \%PageData, 'registration/complete.templ') || '';
    }
    return $body;
}

sub displayRegoFlowCheckout {

    my ($Data, $hidden_ref) = @_;

    my $gCount = param('gatewayCount') || 0;
    my $cc_submit = '';
    foreach my $i (1 .. $gCount)    {
        if (param("cc_submit[$i]")) {
            $cc_submit = param("pt_submit[$i]");
        }
    }
    my @transactions= split /:/, $hidden_ref->{'txnIds'};
        
    my $checkout_body = Payments::checkoutConfirm($Data, $cc_submit, \@transactions,1);
    my $body = qq[PAY];
    $body .= $checkout_body;
    return $body;
}

sub displayRegoFlowDocuments    {

    my ($Data, $regoID, $client, $entityRegisteringForLevel, $originLevel, $rego_ref, $entityID, $personID, $hidden_ref) = @_;
    my $lang=$Data->{'lang'};

     my $url = $Data->{'target'}."?client=$client&amp;a=PREGF_DU&amp;rID=$regoID";
     my $documents = getRegistrationItems(
        $Data,
        'REGO',
        'DOCUMENT',
        $originLevel,
        $rego_ref->{'strRegistrationNature'} || $rego_ref->{'registrationNature'},
        $entityID,
        $entityRegisteringForLevel,
        0,
        $rego_ref,
     );
    
    ### FOR FILTERING 
    my @docos = (); 
	my %approved_docs = (); 
    my $db = $Data->{'db'}; 
	my $query = qq[SELECT intDocumentTypeID FROM tblDocuments WHERE strApprovalStatus = ? AND intPersonID = ?  GROUP BY intDocumentTypeID]; 
	my $sth = $db->prepare($query); 
	$sth->execute('APPROVED',$personID);
		
	while(my @approved_doc_arr = $sth->fetchrow_array()){
		$approved_docs{ $approved_doc_arr[0] } = 'APPROVED';
	}	
	foreach my $dc (@{$documents}){ 
    	next if(exists $approved_docs{$dc->{'ID'}} && $dc->{'UseExistingAnyEntity'});
    	push @docos,$dc; 
    }
     
     #END OF FILTERING 
     ######################
     print STDERR Dumper($documents);


    
  my %PageData = (
        nextaction => "PREGF_DU",
        target => $Data->{'target'},
        documents => \@docos,
        hidden_ref => $hidden_ref,
        Lang => $Data->{'lang'},
        client => $client,
  );  
 my $pagedata = runTemplate($Data, \%PageData, 'registration/document_flow_backend.templ') || '';

    return $pagedata;

#########################
   # return $body;
}

sub displayRegoFlowProducts {

    my ($Data, $regoID, $client, $entityRegisteringForLevel, $originLevel, $rego_ref, $entityID, $personID, $hidden_ref) = @_;
    my $lang=$Data->{'lang'};

    my $url = $Data->{'target'}."?client=$client&amp;a=PREGF_PU&amp;rID=$regoID";
    my $CheckProducts = getRegistrationItems(
        $Data,
        'REGO',
        'PRODUCT',
        $originLevel,
        $rego_ref->{'strRegistrationNature'} || $rego_ref->{'registrationNature'},
        $entityID,
        $entityRegisteringForLevel,
        0,
        $rego_ref,
    );
    my @prodIDs = ();
    my %ProductRules=();
    foreach my $product (@{$CheckProducts})  {
        #next if($product->{'UseExistingThisEntity'} && checkExistingProduct($Data, $product->{'ID'}, $Defs::LEVEL_PERSON, $personID, $entityID, 'THIS_ENTITY'));
        #next if($product->{'UseExistingAnyEntity'} && checkExistingProduct($Data, $product->{'ID'}, $Defs::LEVEL_PERSON, $personID, $entityID, 'ANY_ENTITY'));

        $product->{'HaveForAnyEntity'} =1 if($product->{'UseExistingAnyEntity'} && checkExistingProduct($Data, $product->{'ID'}, $Defs::LEVEL_PERSON, $personID, $entityID, 'ANY_ENTITY'));
        $product->{'HaveForThisEntity'} =1 if($product->{'UseExistingThisEntity'} && checkExistingProduct($Data, $product->{'ID'}, $Defs::LEVEL_PERSON, $personID, $entityID, 'THIS_ENTITY'));

        push @prodIDs, $product->{'ID'};
        $ProductRules{$product->{'ID'}} = $product;
     }
    my $product_body='';
    if (@prodIDs)   {
        $product_body= getRegoProducts($Data, \@prodIDs, 0, $entityID, $regoID, $personID, $rego_ref, 0, \%ProductRules);
     }

     my %PageData = (
        nextaction=>"PREGF_PU",
        target => $Data->{'target'},
        product_body => $product_body,
        hidden_ref=> $hidden_ref,
        Lang => $Data->{'lang'},
        client=>$client,
    );
    my $pagedata = runTemplate($Data, \%PageData, 'registration/product_flow_backend.templ') || '';

    return $pagedata;
}
sub displayRegoFlowProductsBulk {

    my ($Data, $regoID, $client, $entityRegisteringForLevel, $originLevel, $rego_ref, $entityID, $personID, $hidden_ref) = @_;
    my $lang=$Data->{'lang'};

    my $url = $Data->{'target'}."?client=$client&amp;a=PREGF_PU&amp;rID=$regoID";
    my $CheckProducts = getRegistrationItems(
        $Data,
        'REGO',
        'PRODUCT',
        $originLevel,
        $rego_ref->{'strRegistrationNature'} || $rego_ref->{'registrationNature'},
        $entityID,
        $entityRegisteringForLevel,
        0,
        $rego_ref,
    );
    my @prodIDs = ();
    my %ProductRules=();
    foreach my $product (@{$CheckProducts})  {
        push @prodIDs, $product->{'ID'};
        $ProductRules{$product->{'ID'}} = $product;
     }
    my $product_body='';
    if (@prodIDs)   {
        $product_body= getRegoProducts($Data, \@prodIDs, 0, $entityID, $regoID, $personID, $rego_ref, 0, \%ProductRules);
     }

     my %PageData = (
        nextaction=>"PREGFB_PU",
        target => $Data->{'target'},
        product_body => $product_body,
        allowManualPay=> 1,
        manualPaymentTypes => \%Defs::manualPaymentTypes,
        hidden_ref=> $hidden_ref,
        Lang => $Data->{'lang'},
        client=>$client,
    );
    my $pagedata = runTemplate($Data, \%PageData, 'registration/product_flow_backend.templ') || '';

    return $pagedata;
}
 

sub generateRegoFlow_Gateways   {

    my ($Data, $client, $nextAction, $hidden_ref) = @_;

    my $lang = $Data->{'lang'};
    my (undef, $paymentTypes) = getPaymentSettings($Data, 0, 0, $Data->{'clientValues'});
    my $gateway_body = qq[
        <div id = "payment_cc" style= "ddisplay:none;"><br>
    ];
    my $gatewayCount = 0;
    foreach my $gateway (@{$paymentTypes})  {
        $gatewayCount++;
        my $id = $gateway->{'intPaymentConfigID'};
        my $pType = $gateway->{'paymentType'};
        my $name = $gateway->{'gatewayName'};
        $gateway_body .= qq[
            <input type="submit" name="cc_submit[$gatewayCount]" value="]. $lang->txt("Pay via").qq[ $name" class = "button proceed-button"><br><br>
            <input type="hidden" value="$pType" name="pt_submit[$gatewayCount]">
        ];
    }
    $gateway_body .= qq[
        <input type="hidden" value="$gatewayCount" name="gatewayCount">
        <div style= "clear:both;"></div>
        </div>
    ];
    $gateway_body = '' if ! $gatewayCount;

    my %PageData = (
        nextaction=>$nextAction,
        target => $Data->{'target'},
        gateway_body => $gateway_body,
        hidden_ref=> $hidden_ref,
        Lang => $Data->{'lang'},
        client=>$client,
    );
    return runTemplate($Data, \%PageData, 'registration/show_gateways.templ') || '';
}

sub validateRegoID {
    my ($Data, $personID, $regoID, $entityID) = @_;

    my %Reg = (
        personRegistrationID => $regoID,
        entityID => $entityID || 0,
    );
    my ($count, $regs) = getRegistrationData(
        $Data, 
        $personID,
        \%Reg
    );
    if ($count) {
        return ($count, $regs->[0]);
    }
    return (0, undef);

}

sub save_rego_products {
    my ($Data, $regoID, $personID, $entityID, $entityLevel, $rego_ref, $params) = @_;

    my $session='';

    my $CheckProducts = getRegistrationItems(
        $Data,
        'REGO',
        'PRODUCT',
        $rego_ref->{'intOriginLevel'} || $rego_ref->{'originLevel'},
        $rego_ref->{'strRegistrationNature'} || $rego_ref->{'registrationNature'},
        $entityID,
        $entityLevel,
        0,
        $rego_ref,
    );
    my ($txns_added, $amount) = insertRegoTransaction($Data, $regoID, $personID, $params, $entityID, $entityLevel, 1, $session, $CheckProducts);
    my $txnIds = join(':',@{$txns_added});
    return $txnIds;
}


sub add_rego_record{
    my ($Data, $personID, $entityID, $entityLevel, $originLevel, $personType, $personEntityRole, $personLevel, $sport, $ageLevel, $registrationNature, $ruleFor) =@_;

    my $clientValues = $Data->{'clientValues'};
    my $rego_ref = {
        status => 'INPROGRESS',
        personType => $personType || '',
        personEntityRole=> $personEntityRole || '',
        personLevel => $personLevel || '',
        sport => $sport || '',
        ageLevel => $ageLevel || '',
        registrationNature => $registrationNature || '',
        originLevel => $originLevel,
        originID => $entityID,
        entityID => $entityID,
        entityLevel => $entityLevel,
        personID => $personID,
        current => 1,
        ruleFor=>$ruleFor
    };
    my ($personStatus, $prStatus) = checkIsSuspended($Data, $personID, $entityID, $rego_ref->{'personType'});
    return (0, undef, 'SUSPENDED') if ($personStatus eq 'SUSPENDED' or $prStatus eq 'SUSPENDED');
        
    if ($rego_ref->{'registrationNature'} ne 'RENEWAL') {
        my $ok = checkRegoTypeLimits($Data, $personID, 0, $rego_ref->{'sport'}, $rego_ref->{'personType'}, $rego_ref->{'personEntityRole'}, $rego_ref->{'personLevel'}, $rego_ref->{'ageLevel'});
        return (0, undef, 'LIMIT_EXCEEDED') if (!$ok);
    }
    if ($rego_ref->{'registrationNature'} eq 'RENEWAL') {
        my $ok = checkRenewalRegoOK($Data, $personID, $rego_ref);
        return (0, undef, 'RENEWAL_FAILED') if (!$ok);
    }
    if ($rego_ref->{'registrationNature'} eq 'NEW') {
        my $ok = checkNewRegoOK($Data, $personID, $rego_ref);
        return (0, undef, 'NEW_FAILED') if (!$ok);
    }
    my ($regID,$rc) = addRegistration($Data,$rego_ref);
    if ($regID)     {
        return ($regID, $rego_ref, '');
    }
    return (0, undef, '');
}
 
sub bulkRegoSubmit {

    my ($Data, $bulk_ref, $rolloverIDs, $productIDs, $productQtys, $markPaid, $paymentType) = @_;

    my $body = 'Submitting';
    my @IDs= split /\|/, $rolloverIDs;

    my $CheckProducts = getRegistrationItems(
        $Data,
        'REGO',
        'PRODUCT',
        $bulk_ref->{'originLevel'},
        $bulk_ref->{'registrationNature'},
        $bulk_ref->{'entityID'},
        $bulk_ref->{'entityLevel'},
        0,
        $bulk_ref,
    );
 

    for my $pID (@IDs)   {
        my ($regoID, $rego_ref, $msg) = add_rego_record(
            $Data, 
            $pID, 
            $bulk_ref->{'entityID'}, 
            $bulk_ref->{'entityLevel'}, 
            $bulk_ref->{'originLevel'}, 
            $bulk_ref->{'personType'}, 
            $bulk_ref->{'personEntityRole'}, 
            $bulk_ref->{'personLevel'}, 
            $bulk_ref->{'sport'}, 
            $bulk_ref->{'ageLevel'}, 
            $bulk_ref->{'registrationNature'},
            "BULKREGO"
        );
        next if (! $regoID);
        #cleanTasks(
        #    $Data,
        #    $pID,
        #    $bulk_ref->{'entityID'},
        #    $regoID,
        #    'REGO'
        #);
        submitPersonRegistration(
            $Data,
            $pID,
            $regoID,
            $bulk_ref
        );
        my @products = split /\:/, $productIDs;
        my %Products=();
        foreach my $product (@products) {
            $Products{'prod_'.$product} =1;
        }
        my @productQty= split /:/, $productQtys;
        foreach my $prodQty (@productQty){
            my ($prodID, $qty) = split /-/, $prodQty;
            $Products{"prodQTY_$prodID"} =$qty;
        }
        my ($txns_added, $amount) = insertRegoTransaction(
            $Data, 
            $regoID, 
            $pID, 
            \%Products, 
            $bulk_ref->{'entityID'}, 
            $bulk_ref->{'entityLevel'}, 
            $Defs::LEVEL_PERSON, 
            '',
            $CheckProducts
        );
        if ($paymentType and $markPaid)  {
            my %Settings=();
            $Settings{'paymentType'} = $paymentType;
            my $logID = createTransLog($Data, \%Settings, $bulk_ref->{'entityID'},$txns_added, $amount); 
            UpdateCart($Data, undef, $Data->{'client'}, undef, undef, $logID);
            product_apply_transaction($Data,$logID);
        }
    }
    
    return $body;
}

1;

