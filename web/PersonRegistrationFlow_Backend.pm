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
use CGI qw(:cgi);

sub handleRegistrationFlowBackend   {
    my (
        $action,
        $Data
         ) = @_;

    my $body = '';
    my $title = '';
    my $client = $Data->{'client'};
    my $clientValues = $Data->{'clientValues'};
    my $rego_ref = {};
    my $cgi=new CGI;
    my %params=$cgi->Vars();
    
        
    my $regoID = param('rID') || 0;
    if($regoID) {
        my $valid =0;
        ($valid, $rego_ref) = validateRegoID($Data, $regoID);
        $regoID = 0 if !$valid;
    }
    if ( $action eq 'PREGF_TU' ) {
        #add rego record with types etc.
        ($regoID, $rego_ref) = add_rego_record($Data);
warn("RID $regoID");
use Data::Dumper;
print STDERR Dumper($rego_ref);
        $action = 'PREGF_P';
    }
    if ( $action eq 'PREGF_PU' ) {
        #Update product records
warn("ABOUT TO SAVE");
$params{'prod_1'} = 1;
        save_rego_products($Data, $regoID, $rego_ref->{'personID'} || $rego_ref->{'intPersonID'}, getLastEntityID($clientValues) || 0, getLastEntityLevel($clientValues), \%params);
        $action = 'PREGF_D';
    }
    if ( $action eq 'PREGF_DU' ) {
        #Update document records
        $action = 'PREGF_C';
    }

    if ( $action eq 'PREGF_T' ) {
        my $url = $Data->{'target'}."?client=$client&amp;a=PREGF_TU&amp;";
        my $dob = '';
        my $gender = '';
        $body = displayPersonRegisterWhat(
            $Data,
            getID($clientValues, $Defs::LEVEL_PERSON) || 0,
            getLastEntityID($clientValues) || 0,
            $dob,
            $gender,        
            getLastEntityLevel($clientValues),
            $url,
        );
#getLastEntityLevel($clientValues) -- OriginLevel
    }
    elsif ( $action eq 'PREGF_P' ) {
        my $url = $Data->{'target'}."?client=$client&amp;a=PREGF_PU&amp;rID=$regoID";
        my $products = getRegistrationItems(
            $Data,
            'REGO',
            'PRODUCT',
            getLastEntityLevel($clientValues),
            $rego_ref->{'registrationNature'},
            getLastEntityID($clientValues) || 0,
            0,
            0,
            $rego_ref,
        );
        my @prodIDs = ();
        my $productIDs = '';
        foreach my $product (@{$products})  {
            $productIDs .= " " if ($productIDs);
            $productIDs .= $product->{'ID'};
            push @prodIDs, $product->{'ID'};
        }
        if (@prodIDs)   {
            $body .= getRegoProducts($Data, \@prodIDs);
        }
        $body .= qq[
            display product information
            HANDLE NO PRODUCTS

            <a href = "$url">Continue</a>
        ];
        
    }
    elsif ( $action eq 'PREGF_D' ) {
        my $url = $Data->{'target'}."?client=$client&amp;a=PREGF_DU&amp;rID=$regoID";
        my $documents = getRegistrationItems(
            $Data,
            'REGO',
            'DOCUMENT',
            getLastEntityLevel($clientValues),
            $rego_ref->{'registrationNature'},
            getLastEntityID($clientValues) || 0,
            0,
            0,
            $rego_ref,
        );
use Data::Dumper;
print STDERR Dumper($documents);
        $body = qq[
            display document upload information

            <a href = "$url">Continue</a>
        ];
    }    
    elsif ( $action eq 'PREGF_C' ) {
        submitPersonRegistration(
            $Data, 
            getID($Data->{'clientValues'}),
            $regoID,
        );
        my $url = $Data->{'target'}."?client=$client&amp;a=P_HOME;";
        $body = qq[
            Registration is complete

            <a href = "$url">Continue</a>
        ];
    }    
    else {
    }

    return ( $body, $title );
}

sub validateRegoID {
    my ($Data, $regoID) = @_;

    my %Reg = (
        personRegistrationID => $regoID,
        entityID => getLastEntityID($Data->{'clientValues'}) || 0,
    );
    my ($count, $regs) = getRegistrationData(
        $Data, 
        getID($Data->{'clientValues'}),
        \%Reg
    );
    return ($count, $regs) || (0, undef);

}

sub save_rego_products {
    my ($Data, $regoID, $personID, $entityID, $entityLevel, $params) = @_;

    my $session='';
    insertRegoTransaction($Data, $regoID, $personID, $params, $entityID, $entityLevel, 1, $session);
}

    

sub add_rego_record{
    my ($Data) =@_;

    my $clientValues = $Data->{'clientValues'};
    my $rego_ref = {
        status => 'INPROGRESS',
        personType => param('pt') || '',
        personLevel => param('pl') || '',
        sport => param('sp') || '',
        ageLevel => param('ag') || '',
        registrationNature => param('nat') || '',
        originLevel => getLastEntityLevel($clientValues) || 0,
        originID => getLastEntityID($clientValues) || 0,
        entityID => getLastEntityID($clientValues) || 0,
        personID => getID($clientValues) || 0,
        current => 1,
    };

    my ($regID,$rc) = addRegistration($Data,$rego_ref);
    if ($regID)     {
        return ($regID, $rego_ref);
    }
    return (0, undef);
}
