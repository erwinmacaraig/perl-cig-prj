package PersonRegistrationFlow_Backend;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = @EXPORT_OK = qw(
    handleRegistrationFlowBackend
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

use Data::Dumper;

sub handleRegistrationFlowBackend   {
    return;


### NOT USED ANYMORE.... ALL PERSON FLOW IN FLOW_PERSONBACKEND.pm





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
    my $personID = param('pID') || getID($clientValues, $Defs::LEVEL_PERSON) || 0;
    #my $personID = getID($clientValues, $Defs::LEVEL_PERSON) || param('pID') || 0;
    my $entityID = getLastEntityID($clientValues) || 0;
    my $entityLevel = getLastEntityLevel($clientValues) || 0;
    my $originLevel = $Data->{'clientValues'}{'authLevel'} || 0;

    my %Flow = ();
  
    #$Flow{'PREGF_TU'} = 'PREGF_D'; #Typees 1 
    $Flow{'PREGF_PCU'} = 'PREGF_D'; #Typees
    $Flow{'PREGF_TU'} = 'PREGF_CERT'; #Certificates
    $Flow{'PREGF_DU'} = 'PREGF_P'; #Products2
    $Flow{'PREGF_PU'} = 'PREGF_C'; #Documents3
    
    my %Hidden=();
    my $regoID = param('rID') || 0;
    $Hidden{'rID'} = $regoID;
    $Hidden{'client'} = unescape($cl);
    $Hidden{'txnIds'} = $params{'txnIds'} || '';
    $Hidden{'prodIds'} = $params{'prodIds'} || '';
    $Hidden{'prodQty'} = $params{'prodQty'} || '';

    #TODO : check how to populate Data client Values (if current level is LEVEL_PERSON?)
    $Hidden{'pID'} = $personID;
	
    my $pref= undef;
    if ($personID && $personID>0)  {
        $pref = loadPersonDetails($Data, $personID);       
    }

    if($regoID) {
        my $valid =0;
        ($valid, $rego_ref) = validateRegoID($Data, $personID, $regoID, $entityID);
        $regoID = 0 if !$valid;
        $Hidden{'rID'} = $regoID;
        $personID = $personID || $rego_ref->{'personID'} || $rego_ref->{'intPersonID'} || 0;
    }

    $rego_ref->{'Nationality'} ='';
    if (defined $pref and $pref->{'strISONationality'}) {
        $rego_ref->{'Nationality'} = $pref->{'strISONationality'} || '';
    }
    if ( $action eq 'PREGF_TU' ) {
    	
    	
        #add rego record with types etc.
        my $msg='';
        my $personType = param('pt') || '';  #####   Check For Coach or Referee 
        my $personEntityRole= param('per') || '';
        my $personLevel = param('pl') || '';
        my $sport = param('sp') || '';
        my $ageLevel = param('ag') || '';
        my $registrationNature = param('nat') || ''; 
        my $personRequestID = param('reqID') || 0; 

        ($regoID, $rego_ref, $msg) = add_rego_record($Data, $personID, $entityID, $entityLevel, $originLevel, $personType, $personEntityRole, $personLevel, $sport, $ageLevel, $registrationNature, undef, undef, $personRequestID);
    
       ##########################################
        if (!$regoID)   {
            my $error = '';
            if ($msg eq 'SUSPENDED')   {
                $error = $lang->txt("You cannot register at this time, Person is currently SUSPENDED");
            }
            if ($msg eq 'LIMIT_EXCEEDED')   {
                $error = $lang->txt("You cannot register this combination, limit exceeded");
            }
            if ($msg eq 'NEW_FAILED')   {
                $error = $lang->txt("New failed, existing registration found. In order to continue, a Transfer from the existing Entity must be organised or select another Level");
            }
            if ($msg eq 'RENEWAL_FAILED')   {
                $error = $lang->txt("Renewal failed, cannot find existing registration. Might have already been renewed");
            }
          
            
            my $url = $Data->{'target'}."?client=$client&amp;a=PREGF_T";
            ## Make this a template for errors
            my %PageData = (
                return_url => $url,
                error => $error,
                target => $Data->{'target'},
                Lang => $lang,
                client => $client,
            );
            return runTemplate($Data, \%PageData, 'registration/error.templ') || '';
        }
        else    {
            $Hidden{'rID'} = $regoID;
            #$action = 'PREGF_D';
            #if($personType eq 'COACH' || $personType eq 'REFEREE' ){
                $action = $Flow{$action};
            #}            

            $personID = $personID || $rego_ref->{'personID'} || $rego_ref->{'intPersonID'} || 0;
        }
    }
    if ( $action eq 'PREGF_PU' ) {
        #Update product records
        my @productsselected=();
        my @productsqty=();
        for my $k (%params)  {
            if($k=~/prod_/) {
                if($params{$k}==1)  {
                    my $prod=$k;
                    $prod=~s/[^\d]//g;
                    push @productsselected, $prod;
                }
            }
            if($k=~/prodQTY_/) {
                if($params{$k})  {
                    my $prod=$k;
                    $prod=~s/[^\d]//g;
                    push @productsqty, "$prod-$params{$k}";
                }
            }
        }
        my $prodQty= join(':',@productsqty);
        $Hidden{'prodQty'} = $prodQty;
        my $prodIds= join(':',@productsselected);
        $Hidden{'prodIds'} = $prodIds;

        ($Hidden{'txnIds'}, undef) = save_rego_products($Data, $regoID, $personID, $entityID, $entityLevel, $rego_ref, \%params);
        $action = $Flow{$action};
    }
    if ( $action eq 'PREGF_DU' ) {

        my $uploaded_filename = param('file') || ''; 
	    my $docTypeID = param('doctypeID') || 0; 
        if($uploaded_filename ne ''){  
            my $filefield = 'file';  
            my $permission = 1; 
            my @files = (
                        [$uploaded_filename, $filefield, $permission,],
            );  
            my %other_person_info = ();
            $other_person_info{'docTypeID'} = $docTypeID; 
            $other_person_info{'regoID'} = $regoID;    
            processUploadFile($Data,\@files,$Defs::LEVEL_PERSON,$personID,$Defs::UPLOADFILETYPE_DOC,\%other_person_info,);             
         
        }
        else {
             #Update document records
             $action = $Flow{$action}; 
        }
    }
    ############ Store Person Certification   ################
    if($action eq 'PREGF_PCU'){
    	# get posted values 
    	my $query = qq[INSERT INTO tblPersonCertifications (intPersonID, intRealmID, intCertificationTypeID, dtValidFrom, dtValidUntil, strDescription, strStatus) 
    	VALUES ( ?, ?, ?, ?, ?, ?, ?)];
    	my $sth = $Data->{'db'}->prepare($query); 
    	$sth->execute(
    	               $params{'pID'},
    	               $Data->{'Realm'},
    	               $params{'intCertificationTypeID'},
    	               $params{'dtValidFrom'},
    	               $params{'dtValidUntil'},
    	               $params{'strDescription'},
    	               $params{'strStatus'}
    	);
    	
    	$action = $Flow{$action}; 

    }
   ###########################################################
print STDERR "**************************************$action\n";
## FLOW SCREENS
    #if ( $action eq 'PREGF_T' ) {
    #    my $url = $Data->{'target'}."?client=$client&amp;a=PREGF_TU&amp;";
    #    $body = displayPersonRegisterWhat(
    #        $Data,
    #        $personID,
    #        $entityID,
    #        $pref->{'dtDOB_RAW'} || '',
    #        $pref->{'intGender'} || 0,
    #        $originLevel,
    #        $url,
   #     );
   # }
   # elsif ( $action eq 'PREGF_P' ) {    	
   #     $body .= displayRegoFlowProducts($Data, $regoID, $client, $entityLevel, $originLevel, $rego_ref, $entityID, $personID, \%Hidden);
   #}
   ############# 
   #elsif ($action eq 'PREGF_CERT'){
   #    $body .= displayRegoFlowCertificates($Data, $regoID, $client, $originLevel, $entityLevel, $entityID, $rego_ref, $personID, \%Hidden);                                                         	
   #}
   ##########3
    #elsif ( $action eq 'PREGF_D' ) {
    #    $body .= displayRegoFlowDocuments($Data, $regoID, $client, $entityLevel, $originLevel, $rego_ref, $entityID, $personID, \%Hidden);
    #}    
    #elsif ( $action eq 'PREGF_C' ) {
    #    $body .= displayRegoFlowComplete($Data, $regoID, $client, $originLevel, $rego_ref, $entityID, $personID, \%Hidden);
    #}    
    #elsif ($action eq 'PREGF_CHECKOUT') {
    #    $body .= displayRegoFlowCheckout($Data, \%Hidden);
    #}
    #else {
    #}

    return ( $body, $title );
}
1;
