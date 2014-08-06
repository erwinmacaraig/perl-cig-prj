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
use RegoTypeLimits;
use PersonRegistrationFlow_Common;

use Data::Dumper;

sub handleRegistrationFlowBackend   {
    my ($action, $Data) = @_;

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
    my $originLevel = $Data->{'clientValues'}{'authLevel'} || 0;

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
        my $msg='';
        ($regoID, $rego_ref, $msg) = add_rego_record($Data, $personID, $entityID, $entityLevel, $originLevel);
        if (!$regoID)   {
            if ($msg eq 'LIMIT_EXCEEDED')   {
                $body = $lang->txt("You cannot register this combination, limit exceeded");
            }
            if ($msg eq 'RENEWAL_FAILED')   {
                $body = $lang->txt("Renewal failed, cannot find existing registration");
            }
            my $url = $Data->{'target'}."?client=$client&amp;a=PREGF_T";
            $body .= qq[<a href="$url">].$lang->txt("Click here to select new combination").qq[</a>];
        }
        else    {
            $Hidden{'rID'} = $regoID;
            $action = $Flow{$action};
            $personID = $personID || $rego_ref->{'personID'} || $rego_ref->{'intPersonID'} || 0;
        }
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


## FLOW SCREENS
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
            $originLevel,
            $url,
        );
    }
    elsif ( $action eq 'PREGF_P' ) {
        $body .= displayRegoFlowProducts($Data, $regoID, $client, $originLevel, $rego_ref, $entityID, $personID, \%Hidden);
   }
    elsif ( $action eq 'PREGF_D' ) {
        $body .= displayRegoFlowDocuments($Data, $regoID, $client, $originLevel, $rego_ref, $entityID, $personID, \%Hidden);
    }    
    elsif ( $action eq 'PREGF_C' ) {
        $body .= displayRegoFlowComplete($Data, $regoID, $client, $originLevel, $rego_ref, $entityID, $personID, \%Hidden);
    }    
    elsif ($action eq 'PREGF_CHECKOUT') {
        $body .= displayRegoFlowCheckout($Data, \%Hidden);
    }
    else {
    }

    return ( $body, $title );
}
1;
