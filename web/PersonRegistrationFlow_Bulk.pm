package PersonRegistrationFlow_Bulk;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = @EXPORT_OK = qw(
    handleRegistrationFlowBulk
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
use PersonRegistrationFlow_Common;
use Person;
use TTTemplate;
use UploadFiles;
use ListPersons;
use BulkPersons;

use Data::Dumper;

sub handleRegistrationFlowBulk {
    my ($action, $Data) = @_;

    my $bulk=1;
    my $body = '';
    my $title = '';
    my $client = $Data->{'client'};
    my $clientValues = $Data->{'clientValues'};
    my $cl = setClient($clientValues);
    my $rego_ref = {};
    my $cgi=new CGI;
    my %params=$cgi->Vars();
    my $lang = $Data->{'lang'};
    my $personID = 0; #param('pID') || getID($clientValues, $Defs::LEVEL_PERSON) || 0;
    my $entityID = getLastEntityID($clientValues) || 0;
    my $entityLevel = getLastEntityLevel($clientValues) || 0;
    my $originLevel = $Data->{'clientValues'}{'authLevel'} || 0;

    my %Flow = ();
    $Flow{'PREGFB_TU'} = 'PREGFB_P'; #Typees
    $Flow{'PREGFB_PU'} = 'PREGFB_SP'; #Products-
    $Flow{'PREGFB_SPU'} = 'PREGFB_C'; #Select people submit->Complete
    
    my %Hidden=();
    $Hidden{'client'} = unescape($cl);
    $Hidden{'txnIds'} = $params{'txnIds'} || '';

    my $pref= undef;
   #if ($personID && $personID> 0)  {
   #     $pref = loadPersonDetails($Data->{'db'}, $personID);
   # }

        my $bulk_ref = {
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
            current => 1,
        };
        $Hidden{'pt'} = param('pt');
        $Hidden{'per'} = param('per');
        $Hidden{'pl'} = param('pl');
        $Hidden{'sp'} = param('sp');
        $Hidden{'ag'} = param('ag');
        $Hidden{'nat'} = param('nat');
        $body.= "NOW SELECT PEOPLE OF $bulk_ref->{'personType'} | $bulk_ref->{'sport'} | $bulk_ref->{'personLevel'}"; 
    if ( $action eq 'PREGFB_TU' ) {
        #add rego record with types etc.
        my $msg='';
        my $error = '';
        $action = $Flow{$action};
    }

    if ( $action eq 'PREGFB_SPU' ) {
        my $rolloverIDs= param('rolloverIDs') || '';
        $body .= bulkRegoSubmit($Data, $bulk_ref, $rolloverIDs);
#        return $Data->{'lang'}->txt("No $Data->{'LevelNames'}{$Defs::LEVEL_PERSON.'_P'} selected") if (! scalar @MembersToRollover);
        $body .= qq[ROLLOVER FOR $rolloverIDs];
        warn("ROLLOVER$rolloverIDs");
        $action = $Flow{$action};
    }
    if ( $action eq 'PREGFB_PU' ) {
        #Update product records
        #$Hidden{'txnIds'} = save_rego_products($Data, $regoID, $personID, $entityID, $entityLevel, \%params);
        ## PUT PRODUCTS IN HIDDEN
        $action = $Flow{$action};
    }

## FLOW SCREENS
    if ( $action eq 'PREGFB_T' ) {
        my $url = $Data->{'target'}."?client=$client&amp;a=PREGFB_TU&amp;";
        $body = displayPersonRegisterWhat(
            $Data,
            $personID,
            $entityID,
            $pref->{'dtDOB_RAW'} || '',
            $pref->{'intGender'} || 0,
            $originLevel,
            $url,
            $bulk
        );
    }
    elsif ( $action eq 'PREGFB_SP' ) {
#        my ($listPersons_body, undef) = listPersons($Data, $entityID, '');
        my ($listPersons_body, undef) = bulkPersonRollover($Data, 'PREGFB_SPU', $bulk_ref, \%Hidden);
        $body .= qq[NEED TO FILTER FOR THOSE WHO ALREADY MATCH BUT IF RENEWAL, SHOW NEW etc<br>IF NEW, WANT ZERO ALREADY ETC];
        $body .= $listPersons_body;
   }
    elsif ( $action eq 'PREGFB_P' ) {
        $body .= displayRegoFlowProductsBulk($Data, 0, $client, $entityLevel, $originLevel, $rego_ref, $entityID, $personID, \%Hidden);
   }
    elsif ( $action eq 'PREGFB_C' ) {
        $body .= displayRegoFlowCompleteBulk($Data, 0, $client, $originLevel, $rego_ref, $entityID, $personID, \%Hidden);
    }    
    else {
    }

    return ( $body, $title );
}
1;
