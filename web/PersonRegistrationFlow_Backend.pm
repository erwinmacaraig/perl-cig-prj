package PersonRegistrationFlow_Backend;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = @EXPORT_OK = qw(
    handleRegistrationFlowBackend
);

use strict;
use lib "../..","..";
use PersonRegistration;
use RegistrationItem;
use PersonRegisterWhat;
use RegoProducts;
use Reg_common;
use CGI qw(:cgi unescape);
use Payments;
use Data::Dumper;

sub handleRegistrationFlowBackend   {
    my (
        $action,
        $Data
         ) = @_;

    my $body = '';
    my $title = '';
    my $client = $Data->{'client'};
    my $clientValues = $Data->{'clientValues'};
    my $cl = setClient($clientValues);
    my $rego_ref = {};
    my $cgi=new CGI;
    my %params=$cgi->Vars();
    my $lang = $Data->{'lang'};
    my $personID = getID($clientValues, $Defs::LEVEL_PERSON) || 0;
    my $entityID = getLastEntityID($clientValues) || 0;
    my $entityLevel = getLastEntityLevel($clientValues) || 0;
    my %Flow = ();
    $Flow{'PREGF_TU'} = 'PREGF_P'; #Typees
    $Flow{'PREGF_PU'} = 'PREGF_D'; #Products
    $Flow{'PREGF_DU'} = 'PREGF_C'; #Documents
    
    my %Hidden=();
    my $regoID = param('rID') || 0;
    $Hidden{'rID'} = $regoID;
    $Hidden{'client'} = unescape($cl);
    $Hidden{'txnIds'} = $params{'txnIds'} || '';

    if($regoID) {
        my $valid =0;
        ($valid, $rego_ref) = validateRegoID($Data, $personID, $regoID, $entityID);
        $regoID = 0 if !$valid;
        $Hidden{'rID'} = $regoID;
        $personID = $personID || $rego_ref->{'personID'} || $rego_ref->{'intPersonID'} || 0;
    }
    if ( $action eq 'PREGF_TU' ) {
        #add rego record with types etc.
        ($regoID, $rego_ref) = add_rego_record($Data, $personID, $entityID, $entityLevel);
        $Hidden{'rID'} = $regoID;
        $action = $Flow{$action};
        $personID = $personID || $rego_ref->{'personID'} || $rego_ref->{'intPersonID'} || 0;
    }
    if ( $action eq 'PREGF_PU' ) {
        #Update product records
        $Hidden{'txnIds'} = save_rego_products($Data, $regoID, $personID, $entityID, $entityLevel, \%params);
        $action = $Flow{$action};
    }
    if ( $action eq 'PREGF_DU' ) {
        #Update document records
        $action = $Flow{$action};
    }

    if ( $action eq 'PREGF_T' ) {
        my $url = $Data->{'target'}."?client=$client&amp;a=PREGF_TU&amp;";
        my $dob = '';
        my $gender = '';
        $body = displayPersonRegisterWhat(
            $Data,
            $personID,
            $entityID,
            $dob,
            $gender,        
            $entityLevel,
            $url,
        );
    }
    elsif ( $action eq 'PREGF_P' ) {
        my $url = $Data->{'target'}."?client=$client&amp;a=PREGF_PU&amp;rID=$regoID";
        my $products = getRegistrationItems(
            $Data,
            'REGO',
            'PRODUCT',
            $entityLevel,
            $rego_ref->{'strRegistrationNature'} || $rego_ref->{'registrationNature'},
            $entityID,
            0,
            0,
            $rego_ref,
        );
        my @prodIDs = ();
        my $productIDs = '';
        my %ProductRules=();
        foreach my $product (@{$products})  {
            $productIDs .= " " if ($productIDs);
            $productIDs .= $product->{'ID'};
            push @prodIDs, $product->{'ID'};
            $ProductRules{$product->{'ID'}} = $product;
warn("PRODID: $product");
        }
        if (@prodIDs)   {
            $body .= qq[
                <form action="$Data->{target}" method="POST">
                <input type="hidden" name="a" value="PREGF_PU">
            ];
            foreach my $hidden (keys %Hidden)   {
                $body .= qq[<input type="hidden" name="$hidden" value="].$Hidden{$hidden}.qq[">];
            }
            $body .= getRegoProducts($Data, \@prodIDs, $entityID, $regoID, $personID, $rego_ref, 0, \%ProductRules);
            $body .= qq[
                <input type="submit" name="submit" value="]. $lang->txt("Continue").qq[" class = "button proceed-button"><br><br>
                </form>
            ];
        }
        $body .= qq[
            display product information
            HANDLE NO PRODUCTS
        ];
        
    }
    elsif ( $action eq 'PREGF_D' ) {
        my $url = $Data->{'target'}."?client=$client&amp;a=PREGF_DU&amp;rID=$regoID";
        my $documents = getRegistrationItems(
            $Data,
            'REGO',
            'DOCUMENT',
            $entityLevel,
            $rego_ref->{'strRegistrationNature'} || $rego_ref->{'registrationNature'},
            $entityID,
            0,
            0,
            $rego_ref,
        );
        $body = qq[
            display document upload information

            <a href = "$url">Continue</a>
        ];
        $body .= qq[
                <form action="$Data->{target}" method="POST">
                <input type="hidden" name="a" value="PREGF_DU">
            ];
            foreach my $hidden (keys %Hidden)   {
                $body .= qq[<input type="hidden" name="$hidden" value="].$Hidden{$hidden}.qq[">];
            }
            $body .= qq[
                <input type="submit" name="submit" value="]. $lang->txt("Continue").qq[" class = "button proceed-button"><br><br>
                </form>
            ];
    }    
    elsif ( $action eq 'PREGF_C' ) {
        submitPersonRegistration(
            $Data, 
            $personID,
            $regoID,
        );
        my $url = $Data->{'target'}."?client=$client&amp;a=P_HOME;";
        $body = qq[
            Registration is complete
            <a href = "$url">Continue</a><br>
        ];
        my (undef, $paymentTypes) = getPaymentSettings($Data, 0, 0, $Data->{'clientValues'});
        my $CC_body = qq[<div id = "payment_cc" style= "ddisplay:none;"><br>];
        my $gatewayCount = 0;
        foreach my $gateway (@{$paymentTypes})  {
            $gatewayCount++;
            my $id = $gateway->{'intPaymentConfigID'};
            my $pType = $gateway->{'paymentType'};
            my $name = $gateway->{'gatewayName'};
            $CC_body .= qq[
                    <input type="submit" name="cc_submit[$gatewayCount]" value="]. $lang->txt("Pay via").qq[ $name" class = "button proceed-button"><br><br>
                    <input type="hidden" value="$pType" name="pt_submit[$gatewayCount]">
            ];
        }
        $CC_body .= qq[
                    <input type="hidden" value="$gatewayCount" name="gatewayCount">
                    <div style= "clear:both;"></div>
                </div>
        ];
        $CC_body = '' if ! $gatewayCount;
        $body .= qq[
            <form action="$Data->{target}" method="POST">
            <input type="hidden" name="a" value="PREGF_CHECKOUT">
        ];
        foreach my $hidden (keys %Hidden)   {
            $body .= qq[<input type="hidden" name="$hidden" value="].$Hidden{$hidden}.qq[">];
        }
        $body .= qq[
            $CC_body
            </form>
        ];
        
    }    
    elsif ($action eq 'PREGF_CHECKOUT') {
        my $gCount = param('gatewayCount') || 0;
        my $cc_submit = '';
        foreach my $i (1 .. $gCount)    {
            if (param("cc_submit[$i]")) {
                $cc_submit = param("pt_submit[$i]");
            }
            print STDERR "THE VALUE IS " . $cc_submit;
        }
        my @transactions= split /:/, $Hidden{'txnIds'};
        
        my $bb = Payments::checkoutConfirm($Data, $cc_submit, \@transactions,1);
        $body = qq[PAY];
        $body .= $bb;
    }
    else {
    }

    return ( $body, $title );
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
    my ($Data, $personID, $entityID, $entityLevel) =@_;

    my $clientValues = $Data->{'clientValues'};
    my $rego_ref = {
        status => 'INPROGRESS',
        personType => param('pt') || '',
        personLevel => param('pl') || '',
        sport => param('sp') || '',
        ageLevel => param('ag') || '',
        registrationNature => param('nat') || '',
        originLevel => $entityLevel,
        originID => $entityID,
        entityID => $entityID,
        personID => $personID,
        current => 1,
    };

    my ($regID,$rc) = addRegistration($Data,$rego_ref);
    if ($regID)     {
        return ($regID, $rego_ref);
    }
    return (0, undef);
}
