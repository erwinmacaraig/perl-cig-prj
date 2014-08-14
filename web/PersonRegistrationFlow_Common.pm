package PersonRegistrationFlow_Common;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = @EXPORT_OK = qw(
    displayRegoFlowComplete
    displayRegoFlowCheckout
    displayRegoFlowDocuments
    displayRegoFlowProducts
    generateRegoFlow_Gateways
    validateRegoID
    save_rego_products
    add_rego_record
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
use Data::Dumper;

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
         );
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
     my $body = qq[
        display document upload information
     ];
     $body .= qq[
        <form action="$Data->{target}" method="POST">
            <input type="hidden" name="a" value="PREGF_DU">
     ];
     foreach my $doc (@{$documents})   {
        $body .= qq[ <p>Document ID needed ]. $doc->{'ID'}. qq[</p>];
     }
     foreach my $hidden (keys %{$hidden_ref})   {
        $body .= qq[<input type="hidden" name="$hidden" value="].$hidden_ref->{$hidden}.qq[">];
     }
     $body .= qq[
            <input type="submit" name="submit" value="]. $lang->txt("Continue").qq[" class = "button proceed-button"><br><br>
        </form>
     ];

    return $body;
}

sub displayRegoFlowProducts {

    my ($Data, $regoID, $client, $entityRegisteringForLevel, $originLevel, $rego_ref, $entityID, $personID, $hidden_ref) = @_;
    my $lang=$Data->{'lang'};

    my $url = $Data->{'target'}."?client=$client&amp;a=PREGF_PU&amp;rID=$regoID";
    my $products = getRegistrationItems(
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
    foreach my $product (@{$products})  {

        next if($product->{'UseExistingThisEntity'} && checkExistingProduct($Data, $product->{'ID'}, $Defs::LEVEL_PERSON, $personID, $entityID, 'THIS_ENTITY'));
        next if($product->{'UseExistingAnyEntity'} && checkExistingProduct($Data, $product->{'ID'}, $Defs::LEVEL_PERSON, $personID, $entityID, 'ANY_ENTITY'));

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
    my ($Data, $regoID, $personID, $entityID, $entityLevel, $params) = @_;

    my $session='';

    my $txns_added = insertRegoTransaction($Data, $regoID, $personID, $params, $entityID, $entityLevel, 1, $session);
    my $txnIds = join(':',@{$txns_added});
    return $txnIds;
}


sub add_rego_record{
    my ($Data, $personID, $entityID, $entityLevel, $originLevel) =@_;

    my $clientValues = $Data->{'clientValues'};
    my $rego_ref = {
        status => 'INPROGRESS',
        personType => param('pt') || '',
        personEntityRole=> param('per') || '',
        personLevel => param('pl') || '',
        sport => param('sp') || '',
        ageLevel => param('ag') || '',
        registrationNature => param('nat') || '',
        originLevel => $originLevel,
        originID => $entityID,
        entityID => $entityID,
        entityLevel => $entityLevel,
        personID => $personID,
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
