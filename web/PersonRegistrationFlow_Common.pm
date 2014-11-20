package PersonRegistrationFlow_Common;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = @EXPORT_OK = qw(
    displayRegoFlowComplete
    displayRegoFlowCompleteBulk
    displayRegoFlowCheckout
    displayRegoFlowCertificates
    displayRegoFlowDocuments
    displayRegoFlowProducts
    displayRegoFlowProductsBulk
    generateRegoFlow_Gateways
    validateRegoID
    save_rego_products
    add_rego_record
    bulkRegoSubmit
    checkUploadedRegoDocuments
    getRegoTXNDetails
);

use strict;
use lib '.', '..', "comp", 'RegoForm', "dashboard", "RegoFormBuilder",'PaymentSplit', "user";
use PersonRegistration;
use RegistrationItem;
use PersonRegisterWhat;
use RegoProducts;
use Reg_common;
use CGI qw(:cgi unescape param);
use Payments;
use RegoTypeLimits;
use TTTemplate;
use Transactions;
use Products;
use WorkFlow;
use Person;
use Data::Dumper;
use POSIX qw(strftime);
use Date::Parse;
use PlayerPassport;
use RegoAgeRestrictions;
use DisplayPayResult;

sub displayRegoFlowCompleteBulk {

    my ($Data, $client, $hidden_ref) = @_;
    my ($unpaid_cost, $logIDs) = getRegoTXNDetails($Data, $hidden_ref->{'txnIds'});
    $hidden_ref->{'totalAmount'} = $unpaid_cost;
    my $gateways = '';

    #if ($Data->{'SystemConfig'}{'AllowTXNs_CCs_roleFlow'} && $hidden_ref->{'totalAmount'} && $hidden_ref->{'totalAmount'} > 0)   {
    #	if ($hidden_ref->{'totalAmount'} && $hidden_ref->{'totalAmount'} > 0) {

    if ($Data->{'SystemConfig'}{'AllowTXNs_CCs_roleFlow'} && $unpaid_cost)  { #hidden_ref->{'totalAmount'} && $hidden_ref->{'totalAmount'} > 0)   {
        

        $gateways = generateRegoFlow_Gateways($Data, $client, "PREGF_CHECKOUT", $hidden_ref);
    }
    my %PageData = (
        target => $Data->{'target'},
        Lang => $Data->{'lang'},
        client=>$client,
        gateways => $gateways,
    );

    my $body = runTemplate($Data, \%PageData, 'registration/completebulk.templ') || '';

    my $logID = param('tl') || 0;
    $logIDs->{$logID}=1;
    foreach my $id (keys %{$logIDs}) {
        next if ! $id;
#        $body .= displayPayResult($Data, $id);
        $body .= displayPaymentResult($Data, $id, 1, '');
    }
    
    return $body;
}


    
sub displayRegoFlowComplete {

    my ($Data, $regoID, $client, $originLevel, $rego_ref, $entityID, $personID, $hidden_ref) = @_;
    my $lang=$Data->{'lang'};

    my $ok = 0;
    my $run = $hidden_ref->{'run'} || param('run') || 0;
print STDERR "COMPLETE RUN" . $run;
    if ($rego_ref->{'strRegistrationNature'} eq 'RENEWAL' or $rego_ref->{'registrationNature'} eq 'RENEWAL' or $rego_ref->{'strRegistrationNature'} eq 'TRANSFER') {
        $ok=1;
    }
    else    {
        $ok = $run ? 1 : checkRegoTypeLimits($Data, $personID, $regoID, $rego_ref->{'sport'}, $rego_ref->{'personType'}, $rego_ref->{'personEntityRole'}, $rego_ref->{'personLevel'}, $rego_ref->{'ageLevel'});
    }
print STDERR "OK IS $ok | $run\n\n";
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
         ) if ! $run;
         
        my @products= split /:/, $hidden_ref->{'prodIds'};
        foreach my $prod (@products){ $hidden_ref->{"prod_$prod"} =1;}
        my @productQty= split /:/, $hidden_ref->{'prodQty'};
        foreach my $prodQty (@productQty){ 
            my ($prodID, $qty) = split /-/, $prodQty;
            $hidden_ref->{"prodQTY_$prodID"} =$qty;
        }
        #($hidden_ref->{'txnIds'}, undef) = save_rego_products($Data, $regoID, $personID, $entityID, $rego_ref->{'entityLevel'}, $rego_ref, $hidden_ref); #\%params);

         my $url = $Data->{'target'}."?client=$client&amp;a=P_HOME;";
         my $pay_url = $Data->{'target'}."?client=$client&amp;a=P_TXNLog_list;";
         my $gateways = '';
        my ($txnCount, $logIDs) = getPersonRegoTXN($Data, $personID, $regoID);
        savePlayerPassport($Data, $personID) if (! $run);
        $hidden_ref->{'run'} = 1;
         if ($txnCount && $Data->{'SystemConfig'}{'AllowTXNs_CCs_roleFlow'}) {
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
        my $logID = param('tl') || 0;
        $logIDs->{$logID}=1;
        foreach my $id (keys %{$logIDs}) {
            next if ! $id;
       #     $body .= displayPayResult($Data, $id);
            $body .= displayPaymentResult($Data, $id, 1, '');
        }
    }
    return $body;
}
sub getRegoTXNDetails  {

    my ($Data, $txns) = @_;

    $txns =~ s/:/,/g;

    return 0 if ! $txns;
    my $st = qq[
        SELECT 
            intStatus, 
            intTransLogID, 
            curAmount
        FROM tblTransactions
        WHERE
            intRealmID =?
            AND intTransactionID IN ($txns)
    ];
	my $qry = $Data->{'db'}->prepare($st);
	$qry->execute($Data->{'Realm'}); #, @transactions);
    my $amount = 0;
    my %tlogIDs=();
    while (my $dref= $qry->fetchrow_hashref())  {
        $tlogIDs{$dref->{'intTransLogID'}} = 1 if ($dref->{'intTransLogID'} and ! exists $tlogIDs{$dref->{'intTransLogID'}});
        if ($dref->{'intStatus'} == 0)  {
            $amount = $amount + $dref->{'curAmount'};
        }
    }
    return ($amount, \%tlogIDs);
}

sub getPersonRegoTXN    {

    my ($Data, $personID, $regoID) = @_;

    my $st = qq[
        SELECT intTransLogID, intTransactionID, intStatus
        FROM tblTransactions
        WHERE
            intRealmID =?
            AND intID = ?
            AND intPersonRegistrationID = ?
            AND intPersonRegistrationID > 0
            AND intTableType = $Defs::LEVEL_PERSON
    ];
	my $qry = $Data->{'db'}->prepare($st);
	$qry->execute($Data->{'Realm'}, $personID, $regoID);
    my $count = 0;
   my %tlogIDs=();
    while (my $dref= $qry->fetchrow_hashref())  {
        $tlogIDs{$dref->{'intTransLogID'}} = 1 if ($dref->{'intTransLogID'} and ! exists $tlogIDs{$dref->{'intTransLogID'}});
        if ($dref->{'intStatus'} == 0)  {
            $count++;
        }
    }
    return ($count, \%tlogIDs);
}

sub displayRegoFlowCheckout {

    return '';

    ### NOT USED 
    my ($Data, $hidden_ref) = @_;

    my $gCount = param('gatewayCount') || $hidden_ref->{'gatewayCount'} || 0;
    my $cc_submit = '';
    foreach my $i (1 .. $gCount)    {
        if (param("cc_submit[$i]") or $hidden_ref->{"cc_submit[$i]"}) {
            $cc_submit = param("pt_submit[$i]") || $hidden_ref->{"pt_submit[$i]"};
        }
    }
    my @transactions= split /:/, $hidden_ref->{'txnIds'};
        
    my $checkout_body = Payments::checkoutConfirm($Data, $cc_submit, \@transactions,1);
    my $body = qq[PAY];
    $body .= $checkout_body;
    return $body;
}
sub displayRegoFlowCertificates{
	my ($Data, $regoID, $client, $originLevel, $entityLevel, $entityID, $rego_ref, $personID, $hidden_ref) = @_;
	my $lang=$Data->{'lang'};
		
	my @certificates = ();
	#SQL QUERY FOR THE DROPDOWN BOX FOR 
	my $query = qq[SELECT intCertificationTypeID, strCertificationName FROM tblCertificationTypes WHERE strCertificationtype = ? AND intRealmID = ?];
	my $sth = $Data->{'db'}->prepare($query);
	$sth->execute($rego_ref->{'personType'},$Data->{'Realm'});
	while(my $dref = $sth->fetchrow_hashref()){
		#$certificates{$dref->{'intCertificationTypeID'}} = $dref->{'strCertificationName'};				
	    push @certificates, {
	    	k => $dref->{'intCertificationTypeID'},
	    	val => $dref->{'strCertificationName'},
	    };	
	}
	my @statuses = ();
	foreach my $k (keys %Defs::person_certification_status){
		push @statuses, {
			k => $k,
			val => $Defs::person_certification_status{$k},
		};
	}	
	 my %PageData = (
        nextaction => "PREGF_PCU",
        target => $Data->{'target'},
        certificationtypes => \@certificates,
        statuses => \@statuses,
        hidden_ref => $hidden_ref,
        Lang => $Data->{'lang'},
        client => $client,       
  );  
   my $pagedata = runTemplate($Data, \%PageData, 'registration/certificate_flow_backend.templ') || '';

  return $pagedata;
}

sub checkUploadedRegoDocuments {
    my($Data,$personID, $regoID,$entityID,$entityLevel,$originLevel,$rego_ref) = @_;
    
    my $query = qq[SELECT count(intItemID) as items FROM tblRegistrationItem WHERE intRealmID = ? AND intOriginLevel = ? AND strRuleFor = ? AND intEntityLevel = ? AND strRegistrationNature = ? AND strPersonType = ? AND strPersonLevel = ? AND strSport = ? AND strAgeLevel = ? AND strItemType = ? AND (strISOCountry_IN ='' OR strISOCountry_IN IS NULL OR strISOCountry_IN LIKE CONCAT('%|',?,'|%')) AND (strISOCountry_NOTIN ='' OR strISOCountry_NOTIN IS NULL OR strISOCountry_NOTIN NOT LIKE CONCAT('%|',?,'|%'))  ];   
    my $sth = $Data->{'db'}->prepare($query);
    $sth->execute(  $Data->{'Realm'},
    				$originLevel,
    				'REGO',
    				$entityLevel,
    				$rego_ref->{'strRegistrationNature'}, 
    				$rego_ref->{'strPersonType'},
    				$rego_ref->{'strPersonLevel'},
    				$rego_ref->{'strSport'},
    				$rego_ref->{'strAgeLevel'},
    				'DOCUMENT',
    				$rego_ref->{'strISONationality'},
    				$rego_ref->{'strISONationality'}
    );
    
    my $dref = $sth->fetchrow_hashref();
    my $total_items = $dref->{'items'};     
    return 1 if($total_items == 0);
    #there are no required documents to be uploaded
     
    $query = qq[SELECT count(intDocumentID) as tot FROM tblDocuments WHERE intPersonID = ? AND intPersonRegistrationID = ?];
    
    $sth = $Data->{'db'}->prepare($query);
    $sth->execute($personID, $regoID);
    $dref = $sth->fetchrow_hashref();
    
    $sth->finish();
    return 1 if( ($dref->{'tot'} > 0) && $dref->{'tot'} == $total_items);
    return 0;
}
sub displayRegoFlowDocuments    {

    my ($Data, $regoID, $client, $entityRegisteringForLevel, $originLevel, $rego_ref, $entityID, $personID, $hidden_ref, $noFormFields) = @_;
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

    my %PersonRef = ();
    $PersonRef{'strPersonType'} = $rego_ref->{'strPersonType'} || '';
    my $personRegoNature = 'NEW';
    my $pref = loadPersonDetails($Data->{'db'}, $personID);

    if ($pref->{'strStatus'} ne $Defs::PERSON_STATUS_INPROGRESS)    {
        $personRegoNature = 'RENEWAL';
    }
    my $personLeveldocs = getRegistrationItems(
        $Data,
        'PERSON',
        'DOCUMENT',
        $originLevel,
        $personRegoNature,
        $entityID,
        $entityRegisteringForLevel,
        0,
        \%PersonRef,
     );

     my $transferdocs  = '';
     
    if (1==2)   {
        $transferdocs  = getRegistrationItems(
            $Data,
            'TRANSFER',
            'DOCUMENT',
            $originLevel,
            $personRegoNature,
            $entityID,
            $entityRegisteringForLevel,
            0,
            \%PersonRef,
        );
    }
     
    ### FOR FILTERING 
    my @docos = (); 
	my %approved_docs = (); 
	my @listing = ();
    my $db = $Data->{'db'}; 
	my $query = qq[SELECT intDocumentTypeID FROM tblDocuments WHERE strApprovalStatus = ? AND intPersonID = ?  GROUP BY intDocumentTypeID]; 
	my $sth = $db->prepare($query); 
	$sth->execute('APPROVED',$personID);
		
	while(my @approved_doc_arr = $sth->fetchrow_array()){
		$approved_docs{ $approved_doc_arr[0] } = 'APPROVED';
	}	
	foreach my $dc (@{$documents}){ 
    	#next if(exists $approved_docs{$dc->{'ID'}} && $dc->{'UseExistingAnyEntity'});
    	#push @docos,$dc;
    	if(exists $approved_docs{$dc->{'ID'}} && $dc->{'UseExistingAnyEntity'}){
    		push @listing,$dc;
    	}
    	elsif(($dc->{'DocumentFor'} eq 'TRANSFERITC' and $rego_ref->{'InternationalTransfer'}) or $dc->{'DocumentFor'} ne 'TRANSFERITC') {
            push @docos,$dc;	
    	}
    }
     
     #END OF FILTERING 
     ######################


    
  my %PageData = (
        nextaction => "PREGF_DU",
        target => $Data->{'target'},
        documents => \@docos,
        approveddocs => \@listing, 
        personleveldocs => $personLeveldocs,
        transferdocs=> $transferdocs,
        hidden_ref => $hidden_ref,
        Lang => $Data->{'lang'},
        client => $client,
        regoID => $regoID,
        NoFormFields =>$noFormFields,
  );  
 my $pagedata = runTemplate($Data, \%PageData, 'registration/document_flow_backend.templ') || '';

    return $pagedata;
}

sub displayRegoFlowProducts {

    my ($Data, $regoID, $client, $entityRegisteringForLevel, $originLevel, $rego_ref, $entityID, $personID, $hidden_ref, $noFormFields) = @_;
    my $lang=$Data->{'lang'};

    my $url = $Data->{'target'}."?client=$client&amp;a=PREGF_PU&amp;rID=$regoID";
#    my $pref = loadPersonDetails($Data->{'db'}, $personID);
 #   $rego_ref->{'Nationality'} = $pref->{'strISONationality'};
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
        NoFormFields =>$noFormFields,
    );
    my $pagedata = runTemplate($Data, \%PageData, 'registration/product_flow_backend.templ') || '';

    return $pagedata;
}
sub displayRegoFlowProductsBulk {

    my ($Data, $regoID, $client, $entityRegisteringForLevel, $originLevel, $rego_ref, $entityID, $personID, $hidden_ref) = @_;
    my $lang=$Data->{'lang'};

    my $url = $Data->{'target'}."?client=$client&amp;a=PREGF_PU&amp;rID=$regoID";
    my $pref = loadPersonDetails($Data->{'db'}, $personID);
    $rego_ref->{'Nationality'} = $pref->{'strISONationality'};
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
    my ($paymentSettings, $paymentTypes) = getPaymentSettings($Data, 0, 0, $Data->{'clientValues'});
    my $gateway_body = qq[
        <div id = "payment_cc" style= "display:none;"><br>
    ];
    my $gatewayCount = 0;
    my $paymentType = 0;
    foreach my $gateway (@{$paymentTypes})  {
        $gatewayCount++;
        my $id = $gateway->{'intPaymentConfigID'};
        my $pType = $gateway->{'paymentType'};
        $paymentType = $pType;
        my $name = $gateway->{'gatewayName'};
        $gateway_body .= qq[
            <input type="submit" name="cc_submit[$gatewayCount]" value="]. $lang->txt("Pay via").qq[ $name" class = "button proceed-button"><br><br>
        ];
            #<input type="hidden" value="$pType" name="pt_submit[$gatewayCount]">
        #<input type="hidden" value="$gatewayCount" name="gatewayCount">
    }
    $gateway_body .= qq[
        <div style= "clear:both;"></div>
        </div>
    ];
    $gateway_body = '' if ! $gatewayCount;
    my $target = 'paytry.cgi';#$Data->{'target'};

    my $txnList = displayTXNToPay($Data, $hidden_ref->{'txnIds'}, $paymentSettings);
    my %PageData = (
        nextaction=>$nextAction,
        target => $target,
        txnList =>$txnList,
        gateway_body => $gateway_body,
        hidden_ref=> $hidden_ref,
        Lang => $Data->{'lang'},
        client=>$client,
    );
    if ($gatewayCount == 1) {
        $hidden_ref->{"pt_submit[1]"} = $paymentType; 
        $hidden_ref->{"gatewayCount"} = 1;
    }
    else    {
        $hidden_ref->{"gatewayCount"} = $gatewayCount;
    }
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
    return ($txnIds, $amount);
}


sub add_rego_record{
    my ($Data, $personID, $entityID, $entityLevel, $originLevel, $personType, $personEntityRole, $personLevel, $sport, $ageLevel, $registrationNature, $ruleFor, $nationality, $personRequestID) =@_;

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
        ruleFor=>$ruleFor,
        personRequestID => $personRequestID,
    };
    my ($personStatus, $prStatus) = checkIsSuspended($Data, $personID, $entityID, $rego_ref->{'personType'});
    return (0, undef, 'SUSPENDED') if ($personStatus eq 'SUSPENDED' or $prStatus eq 'SUSPENDED');
        
    #warn "REGISTRATION NATURE $rego_ref->{'registrationNature'}";
    if ($rego_ref->{'registrationNature'} ne 'RENEWAL' and $rego_ref->{'registrationNature'} ne 'TRANSFER') {
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

    my $totalAmount=0;
    my @total_txns_added=();
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
    my @Ages = ('ADULT',
            'MINOR'
    );

	my $invoiceNumber;
	#Generate invoice number 
	my $stt = qq[INSERT INTO tblInvoice (tTimeStamp) VALUES (NOW())];
	my $qryy=$Data->{'db'}->prepare($stt); 
	$qryy->execute();
	my $invoiceID =  $qryy->{mysql_insertid} || 0;	
	$invoiceNumber = Payments::TXNtoInvoiceNum($invoiceID); 

	$stt = qq[UPDATE tblInvoice SET strInvoiceNumber = ? WHERE intInvoiceID = ?];		
	$qryy=$Data->{'db'}->prepare($stt); 
	$qryy->execute($invoiceNumber,$invoiceID); 
	$qryy->finish();

    for my $pID (@IDs)   {
        my $pref = loadPersonDetails($Data->{'db'}, $pID) if ($pID);
        my $ageLevelOptions = checkRegoAgeRestrictions(
            $Data,
            $pID,
            0,
            $bulk_ref->{'sport'},
            $bulk_ref->{'personType'},
            $bulk_ref->{'personEntityRole'},
            $bulk_ref->{'personLevel'},
            @Ages
        );
        
        $bulk_ref->{'ageLevel'}='';
        if (defined $ageLevelOptions)   {
            $bulk_ref->{'ageLevel'}=$ageLevelOptions->[0]{'value'};#'ADULT';
        }
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
            $CheckProducts,
			$invoiceID
        );
        $totalAmount = $totalAmount + $amount;
        push @total_txns_added, @{$txns_added};
        ## Below was for each to have their own tblTransLog
        #if ($paymentType and $markPaid)  {
        #    my %Settings=();
        #    $Settings{'paymentType'} = $paymentType;
        #    my $logID = createTransLog($Data, \%Settings, $bulk_ref->{'entityID'},$txns_added, $amount); 
        #    UpdateCart($Data, undef, $Data->{'client'}, undef, undef, $logID);
        #    product_apply_transaction($Data,$logID);
        #}
          savePlayerPassport($Data, $pID);
    }
    if (scalar(@total_txns_added) and $paymentType and $markPaid)  {
        my %Settings=();
        $Settings{'paymentType'} = $paymentType;
        my $logID = createTransLog($Data, \%Settings, $bulk_ref->{'entityID'},\@total_txns_added, $totalAmount);
        UpdateCart($Data, undef, $Data->{'client'}, undef, undef, $logID);
        product_apply_transaction($Data,$logID);
    }
    my $txnIds = join(':',@total_txns_added);
    
 
    return ($totalAmount, $txnIds);
}
1;

