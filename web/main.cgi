#! /usr/bin/perl -w

#
# $Header: svn://svn/SWM/trunk/web/main.cgi 11375 2014-04-24 05:18:29Z sliu $
#

use strict;
use CGI qw(param unescape escape cookie);

use lib '.', '..', "comp", 'RegoForm', "dashboard", "RegoFormBuilder",'PaymentSplit','Clearances', "user";
use Lang;
use Localisation;
use Reg_common;
use PageMain;
use Navbar;
use Defs;
use Utils;
use SystemConfig;
use Search;
use ReportManager;
use ConfigOptions;
use Clearances;
use ClearanceSettings;
use Duplicates;
use AuditLog;
use Welcome;
use PaymentApplication;
use Agreements;

use Entity;
use Club;
use Person;
use PersonEdit;
use EntityEdit;
use Changes;
use MemberCard;
use FacilityEdit;

use BankSplit;
use PaymentSplitRun;
use BankAccountSetup;
use Seasons;
use AgeGroups;
use Products;

use Notifications;
use Venues;

use MCache;
use Contacts;
use Agreements;
use Documents;
use Logo;


use FieldConfig;
use EntitySettings;

use AddToPage;
use AuthMaintenance;
use Dashboard;
use CheckOnLogin;
use DashboardConfig;

use WorkFlow;
use EntityRegistrationAllowedEdit;
use PersonRegistrationFlow_Backend;
use PersonRegistrationFlow_Bulk;
use PendingRegistrations;
use IncompleteRegistrations;

use PersonRequest;

use Log;
use Data::Dumper;
use ListAuditLog;

use PaymentDisplay_LoggedOff;
main();

sub main {

    # GET INFO FROM URL
    my $client = param('client') || '';
    my $action = safe_param( 'a', 'action' ) || '';
    my %Data   = ();
    my $target = 'main.cgi';
    $Data{'target'} = $target;
    $Data{'cache'}  = new MCache();

    $Data{'AddToPage'} = new AddToPage();

    $Data{'AddToPage'}->add( 'js_top', 'file', 'js/jquery.ui.touch-punch.min.js' );
    my %clientValues = getClient($client);

    $Data{'clientValues'} = \%clientValues;

    # AUTHENTICATE
    my $paytry = param('ptry') || '';
    my $EncPayTry = param('eptry') || '';
    $Data{'ptry'} = $paytry;
    if ($paytry)    {
        my $m;
        $m = new MD5;
        $m->reset();
        $m->add($paytry);
        my $encLogID= uc($m->hexdigest());
        if ($encLogID ne $EncPayTry)    {
            $Data{'ptry'} = 0;
            $Data{'eptry'} = 0;
            $paytry = 0;
        }
    }
    my $db = allowedTo( \%Data );

    ( $Data{'Realm'}, $Data{'RealmSubType'} ) = getRealm( \%Data );
    getDBConfig( \%Data );
    $Data{'SystemConfig'} = getSystemConfig( \%Data );
    $Data{'LocalConfig'}  = getLocalConfig( \%Data );
    my $lang   = Lang->get_handle('', $Data{'SystemConfig'}) || die "Can't get a language handle!";
    $Data{'lang'} = $lang;
    initLocalisation(\%Data);
    updateSystemConfigTranslation(\%Data);

    if ($Data{'kickoff'} and $db and $paytry)  {
    ## Display Payment Summary if logged off
        paymentDisplay_LoggedOff(\%Data, $paytry);
        return;
    }
    logPageData( \%Data, $action, $client);

    $clientValues{'currentLevel'} = safe_param( 'cl', 'number' )
      if (  safe_param( 'cl', 'number' )
        and safe_param( 'cl', 'number' ) <= $clientValues{'authLevel'} );

    # DO DATABASE THINGS
    my $DataAccess_ref = getDataAccess( \%Data );
    $Data{'DataAccess'} = $DataAccess_ref;

    my $resultHTML  = q{};
    my $pageHeading = q{};
    my $breadcrumbs = q{};

    my $report = 0;
    $Data{'clientValues'} = \%clientValues;
    $client               = setClient( \%clientValues );
    $Data{'client'}       = $client;
    $Data{'unesc_client'} = unescape($client);
    my $typeID =
         safe_param( 'l', 'number' )
      || $clientValues{'currentLevel'}
      || $Defs::LEVEL_NONE;
    $Data{'Permissions'} = GetPermissions(
        \%Data,
        $clientValues{'authLevel'},
        getID( \%clientValues, $clientValues{'authLevel'} ),
        $Data{'Realm'},
        $Data{'RealmSubType'},
        $clientValues{'authLevel'},
        0,
    );

    if ( $action eq 'LOGIN' ) {
        checkOnLogin( \%Data );
        $action = defaultAction( $clientValues{'authLevel'} );
    }
    if($action eq 'E_HOME' and $clientValues{'currentLevel'} != $clientValues{'authLevel'}) {
        $action = 'EE_D';
    }

    if ( $action =~ /^E_/ ) {
        my $ID = getID( \%clientValues );
        if ($action eq 'E_HOME')    {
            ( $resultHTML, $pageHeading ) = handleWorkflow($action, \%Data) if ($action eq 'E_HOME');
        }
        else    {
            ( $resultHTML, $pageHeading ) = handleEntity( $action, \%Data, $ID, $typeID );
        }
    }
    elsif ( $action =~ /^C_/ ) {
        my $clubID= getID($Data{'clientValues'},$Defs::LEVEL_CLUB); 
        my $entityID = getLastEntityID($Data{'clientValues'});
        if ($action eq 'C_HOME')    {
            ( $resultHTML, $pageHeading ) = handleWorkflow($action, \%Data) if ($action eq 'C_HOME');
        }
        else    {
            $clubID = param('clubID') if param('clubID');
            ( $resultHTML, $pageHeading ) = handleClub( $action, \%Data, $entityID, $clubID, $typeID );
        }
    }
    elsif ( $action =~ /^P_/ ) {
        my $personID= param('personID') || getID($Data{'clientValues'},$Defs::LEVEL_PERSON);
        ( $resultHTML, $pageHeading ) = handlePerson( $action, \%Data, $personID);  
    }
    elsif ( $action =~ /^DOC_/ ) {  
         #needed to pass a parameter to accommodate single File Document Upload
         my $DocumentTypeID = param('doclisttype') || '';  
         my $RegistrationID = param('RegistrationID') || '';         
         my $memberID = param('memberID') || 0;
        my $ID = $memberID || getID( \%clientValues);
        ( $resultHTML, $pageHeading ) =
          handle_documents( $action, \%Data, $ID, $DocumentTypeID,$RegistrationID );  
    }
    elsif ( $action =~ /^LOGO_/ ) {
        my $ID = getID( \%clientValues );
        ( $resultHTML, $pageHeading ) = handle_logos( $action, \%Data, $typeID, $ID, $client );
    }
    elsif ( $action =~ /^TB_/ ) {
        my $personID= getID($Data{'clientValues'},$Defs::LEVEL_PERSON);
        ( $resultHTML, $pageHeading ) = handlePerson( $action, \%Data, $personID );
    }
    elsif ( $action =~ /^PE_/ ) {
        ( $resultHTML, $pageHeading ) = handlePersonEdit( $action, \%Data);
    }
    elsif ( $action =~ /^EE_/ ) {
        ( $resultHTML, $pageHeading ) = handleEntityEdit( $action, \%Data);
    }
    elsif ( $action =~ /^FE_/ ) {
        ( $resultHTML, $pageHeading ) = handleFacilityEdit( $action, \%Data);
    }
    elsif ( $action =~ /^SEARCH_/ ) {
        ( $resultHTML, $pageHeading ) = handleSearch( $action, \%Data, $client );
    }
    elsif ( $action =~ /^REP_/ ) {
        ( $resultHTML, $report, $pageHeading ) = handleReports( $action, \%Data );
    }
    elsif ( $action =~ /^CL_/ ) {
        my $entityID = getLastEntityID($Data{'clientValues'});
        ( $resultHTML, $pageHeading ) = handleClearances( $action, \%Data, $entityID );
    }
    elsif ( $action =~ /^CLRSET_/ ) {
        ( $resultHTML, $pageHeading ) = handleClearanceSettings( $action, \%Data );
    }
    elsif ( $action =~ /^DUPL_/ ) {
        ( $resultHTML, $pageHeading ) = handleDuplicates( $action, \%Data );
    }
    elsif ( $action =~ /^AL/ ) {
        ( $resultHTML, $pageHeading ) = displayAuditLog( \%Data );
    }
    elsif ( $action =~ /^AM/ ) {
        my $ID = getID( \%clientValues );
        ( $resultHTML, $pageHeading ) = handleAuthMaintenance( $action, \%Data, $typeID, $ID );
    }
    elsif ( $action =~ /^CHG/ ) {
        ( $resultHTML, $pageHeading ) = displayChanges( \%Data );
    }
    elsif ( $action =~ /^HELP/ ) {
        $resultHTML = $Data{'SystemConfig'}{'HELP'} || '';
        $pageHeading = 'Help';
    }
    elsif ( $action =~ /^SN_/ ) {
        ( $resultHTML, $pageHeading ) = handleSeasons( $action, \%Data );
    }
    elsif ( $action =~ /^AGEGRP_/ ) {
        ( $resultHTML, $pageHeading ) = handleAgeGroups( $action, \%Data );
    }
    elsif ( $action =~ /^VENUE_/ ) {
    	#####  Leaving this if venueID can be setup in Reg_common.pm    	
    	#my $venueID= getID($Data{'clientValues'},$Defs::LEVEL_VENUE); 
        my $entityID = getLastEntityID($Data{'clientValues'});
       ( $resultHTML, $pageHeading ) = handleVenues( $action, \%Data, $entityID, $typeID );
    	####
       # ( $resultHTML, $pageHeading ) = handleVenues( $action, \%Data);
    }
    elsif ( $action =~ /^CON_/ ) {
        my $ID = getID( \%clientValues );
        ( $resultHTML, $pageHeading ) = handleContacts( $action, \%Data, $typeID, $ID );
    }
    elsif ( $action =~ /^BANKSPLIT/ ) {
        ( $resultHTML, $pageHeading ) = handleBankSplit( $action, \%Data );
    }
    elsif ( $action =~ /^PSR/ ) {
        ( $resultHTML, $pageHeading ) = handlePaymentSplitRun( $action, \%Data );
    }
    elsif ( $action =~ /^MEMCARD_/ ) {
        my $ID = getID( \%clientValues );
        ( $resultHTML, $pageHeading ) = handleMemberCard( $action, \%Data, $client, $ID, $typeID );
    }
    elsif ( $action =~ /^RFR_/ ) {
        ( $resultHTML, $pageHeading ) = handleFormReplication( $action, \%Data );
    }
    elsif ( $action =~ /^FC_C_/ ) {
        ( $resultHTML, $pageHeading ) = handleFieldConfig( $action, \%Data );
    }
    elsif ( $action =~ /^ESET_/ ) {
        ( $resultHTML, $pageHeading ) = handleEntitySettings( $action, \%Data );
    }
    elsif ( $action =~ /^DASHCFG_/ ) {
        my $ID = getID( \%clientValues );
        ( $resultHTML, $pageHeading ) = handle_DashboardConfig( $action, \%Data, $ID, $typeID, $client );
    }
    elsif ( $action =~ /^NOTS/ ) {
        my $ID = getID( \%clientValues );
        ( $resultHTML, $pageHeading ) = handleNotifications( $action, \%Data, $client, $typeID, $ID );
    }
    elsif ( $action =~ /^PR_/ ) {
        ( $resultHTML, $pageHeading ) = handle_products(\%Data, $action);
    }
    elsif ( $action =~ /^WF_/ ) {
        ( $resultHTML, $pageHeading ) = handleWorkflow($action, \%Data);
    }
    elsif ( $action =~ /^ERA_/ ) {
        ( $resultHTML, $pageHeading ) = handleEntityRegistrationAllowedEdit($action, \%Data);
    }
    #elsif ( $action =~ /^PREGF_/ ) {
    #    ( $resultHTML, $pageHeading ) = handleRegistrationFlowBackend($action, \%Data);
    #}
    elsif ( $action =~ /^PREGFB_/ ) {
        ( $resultHTML, $pageHeading ) = handleRegistrationFlowBulk($action, \%Data);
    }
    elsif ( $action =~ /^PFB_/ ) {
use BulkRenewalsFlow;
        ( $resultHTML, $pageHeading ) = handleBulkRenewalsFlow($action, \%Data);
    }
    elsif ( $action =~ /^PF_/ ) {
use PersonFlow;
        ( $resultHTML, $pageHeading ) = handlePersonFlow($action, \%Data);
    }
    elsif ( $action =~ /^PTF_/ ) {
use TransferFlow;
        ( $resultHTML, $pageHeading ) = handleTransferFlow($action, \%Data);
    }
    elsif ( $action =~ /^PLF_/ ) {
use LoanFlow;
        ( $resultHTML, $pageHeading ) = handleLoanFlow($action, \%Data);
    }
    elsif ( $action =~ /^PENDPR_/ ) {
        my $prID = safe_param( 'prID', 'number' );
        my $entityID = getID($Data{'clientValues'},$Data{'clientValues'}{'currentLevel'});
        ( $resultHTML, $pageHeading ) = handlePendingRegistrations($action, \%Data, $entityID, $prID);
        #$pageHeading = $pageHeading . "entityID = " . $entityID;    
    }
    elsif ( $action =~ /^INCOMPLPR_/ ) {
        my $entityID = getID($Data{'clientValues'},$Data{'clientValues'}{'currentLevel'});
        ( $resultHTML, $pageHeading ) = handleIncompleteRegistrations($action, \%Data, $entityID);
    }
    elsif ( $action =~ /^PRA_/) {
        ($resultHTML, $pageHeading) = handlePersonRequest($action, \%Data);
    }
    elsif($action =~ /^INITSRCH_/){
        use Search::Handler;
        ($resultHTML, $pageHeading) = Search::Handler::handle($action, \%Data, 1);
    }
	elsif($action =~ /^TXN_PAY_INV/){
		use PayInvoice;
		my $clubID = getID($Data{'clientValues'},$Defs::LEVEL_CLUB); 
		($resultHTML, $pageHeading) = PayInvoice::handlePayInvoice($action, \%Data, $clubID);				
	}
	elsif($action =~ /^TXN_FIND/){
		use FindPayment;
		my $clubID = getID($Data{'clientValues'},$Defs::LEVEL_CLUB); 
		($resultHTML, $pageHeading) = FindPayment::handleFindPayment($action, \%Data, $clubID);				
	}

	elsif($action eq 'itcf'){
		use ITC_TransferCertificate;
		($resultHTML, $pageHeading) = ITC_TransferCertificate::show_itc_request_form(\%Data);
	}
    elsif ( $action =~ /^V_HISTLOG/ ) {
        my $venueID= safe_param( 'venueID', 'number' );
        ($resultHTML,$pageHeading) = listEntityAuditLog(\%Data, $venueID);
        
    }

   
    # BUILD PAGE
    #if ( !$report ) {
        $client = setClient( \%clientValues );
        $clientValues{INTERNAL_db} = $db;
        my $navbar = navBar( \%Data, $DataAccess_ref, $Data{'SystemConfig'} );
        $resultHTML ||=
          textMessage("An invalid Action Code has been passed to me.");

        $breadcrumbs ||= '';
        $resultHTML = qq[
      $breadcrumbs
			<div class="pageHeading">$pageHeading</div>
			$resultHTML
		] if $pageHeading;
        pageMain( $Defs::page_title, $navbar, $resultHTML, \%clientValues,
            $client, \%Data );
    #}
    #else { printReport( $resultHTML, $lang ); }
    disconnectDB($db);
}

sub defaultAction {
    my ($level) = @_;
    #return 'C_HOME'  if $level == $Defs::LEVEL_CLUB;
    #return 'E_HOME';
    return 'WF_';
}

sub logPageData {
    my ( $Data, $action, $client) = @_;

    my $cache     = $Data->{'cache'} || return '';
    my $processID = $$;
    my %pagedata  = (
        client      => $client,
        server      => $ENV{'SERVER_ADDR'},
        host        => $ENV{'HTTP_HOST'},
        url         => $ENV{'REQUEST_URI'},
        querystring => $ENV{'QUERY_STRING'},
        action      => $action,
        processID   => $processID,
    );

    my $cachekey = 'MEMACTION_' . $ENV{'SERVER_ADDR'} . '_' . $processID;
    $cache->set( 'swm', $cachekey, \%pagedata, undef, 60 * 180 ) if $cache;
}
