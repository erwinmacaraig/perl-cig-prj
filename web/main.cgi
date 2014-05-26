#! /usr/bin/perl -w

#
# $Header: svn://svn/SWM/trunk/web/main.cgi 11375 2014-04-24 05:18:29Z sliu $
#

use strict;
use CGI qw(param unescape escape);

use lib '.', '..', "comp", 'RegoForm', "dashboard";
use Lang;
use Reg_common;
use PageMain;
use Navbar;
use Defs;
use Utils;
use SystemConfig;
use Search;
use ReportManager;
use ConfigOptions;
use PassManage;
use Clearances;
use ClearanceSettings;
use Duplicates;
use AuditLog;
use Welcome;
use PaymentApplication;
use Agreements;
use AssocGrade;

use Node;
use Assoc;
use Club;
use Member;
use Changes;
use MemberCard;

use BankSplit;
use PaymentSplitRun;
use BankAccountSetup;
use Seasons;
use AgeGroups;

use Venues;
use Notifications;
use Facilities;
use ProgramTemplates;
use Programs;

use MCache;
use Contacts;
use Agreements;
use Documents;
use Logo;


use FieldConfig;
use EntitySettings;

use RegoFormReplication;
use AddToPage;
use AuthMaintenance;
use Dashboard;
use CheckOnLogin;
use DashboardConfig;

use Optin;
use MemberRecords;
use MemberRecordType;

use Log;
use Data::Dumper;

main();

sub main {

    # GET INFO FROM URL
    my $client = param('client') || '';
    my $action = safe_param( 'a', 'action' ) || '';
    my %Data   = ();
    my $lang   = Lang->get_handle() || die "Can't get a language handle!";
    $Data{'lang'} = $lang;
    my $target = 'main.cgi';
    $Data{'target'} = $target;
    $Data{'cache'}  = new MCache();

    $Data{'AddToPage'} = new AddToPage();

    $Data{'AddToPage'}->add( 'js_top', 'file', 'js/jquery.ui.touch-punch.min.js' );
    my %clientValues = getClient($client);

    $Data{'clientValues'} = \%clientValues;

    # AUTHENTICATE
    my $db = allowedTo( \%Data );

    #$Data{'Realm'}=getRealm(\%Data);
    ( $Data{'Realm'}, $Data{'RealmSubType'} ) = getRealm( \%Data );
    getDBConfig( \%Data );
    $Data{'SystemConfig'} = getSystemConfig( \%Data );
    $Data{'LocalConfig'}  = getLocalConfig( \%Data );
    my $assocID = getAssocID( \%clientValues ) || '';

    logPageData( \%Data, $action, $client, $assocID, );

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
    my $ID = getID( \%clientValues );
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

    if ( $action =~ /^N_/ ) {
        ( $resultHTML, $pageHeading ) =
          handleNode( $action, \%Data, $ID, $typeID );
    }
    elsif ( $action =~ /^A_/ ) {
        ( $resultHTML, $pageHeading, $breadcrumbs ) =
          handleAssoc( $action, \%Data, $ID, $typeID );
    }
    elsif ( $action =~ /^C_/ ) {
        ( $resultHTML, $pageHeading ) =
          handleClub( $action, \%Data, $ID, $typeID );
    }
    elsif ( $action =~ /^M_/ ) {
        ( $resultHTML, $pageHeading ) = handleMember( $action, \%Data, $ID );
    }
    elsif ( $action =~ /^DOC_/ ) {
        ( $resultHTML, $pageHeading ) =
          handle_documents( $action, \%Data, $ID );
    }
    elsif ( $action =~ /^LOGO_/ ) {
        ( $resultHTML, $pageHeading ) =
          handle_logos( $action, \%Data, $typeID, $ID, $client );
    }
    elsif ( $action =~ /^TB_/ ) {
        ( $resultHTML, $pageHeading ) = handleMember( $action, \%Data, $ID );
    }
    elsif ( $action =~ /^SEARCH_/ ) {
        ( $resultHTML, $pageHeading ) =
          handleSearch( $action, \%Data, $client );
    }
    elsif ( $action =~ /^REP_/ ) {
        ( $resultHTML, $report, $pageHeading ) =
          handleReports( $action, \%Data );
    }
    elsif ( $action =~ /^PW_/ ) {
        ( $resultHTML, $pageHeading ) =
          handlePasswordManagement( $action, \%Data, $typeID );
    }
    elsif ( $action =~ /^CL_/ ) {
        ( $resultHTML, $pageHeading ) = handleClearances( $action, \%Data );
    }
    elsif ( $action =~ /^CLRSET_/ ) {
        ( $resultHTML, $pageHeading ) =
          handleClearanceSettings( $action, \%Data );
    }
    elsif ( $action =~ /^DUPL_/ ) {
        ( $resultHTML, $pageHeading ) = handleDuplicates( $action, \%Data );
    }
    elsif ( $action =~ /^AL/ ) {
        ( $resultHTML, $pageHeading ) = displayAuditLog( \%Data );
    }
    elsif ( $action =~ /^AM/ ) {
        ( $resultHTML, $pageHeading ) =
          handleAuthMaintenance( $action, \%Data, $typeID, $ID );
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
    elsif ( $action =~ /^ASSGR_/ ) {
        ( $resultHTML, $pageHeading ) = handleAssocGrades( $action, \%Data );
    }
    elsif ( $action =~ /^VENUE_/ ) {
        ( $resultHTML, $pageHeading ) = handleVenues( $action, \%Data );
    }
    elsif ( $action =~ /^FACILITY_/ ) {
        ( $resultHTML, $pageHeading ) = handleFacilities( $action, \%Data );
    }
    elsif ( $action =~ /^PROGRAM_TEMPLATE_/ ) {
        ( $resultHTML, $pageHeading ) = handle_program_templates( $action, \%Data );
    }
    elsif ( $action =~ /^PROGRAM_/ ) {
        ( $resultHTML, $pageHeading ) = handle_programs( $action, \%Data );
    }
    elsif ( $action =~ /^AGREE_/ ) {
        ( $resultHTML, $pageHeading ) =
          handleAgreements( $action, \%Data, $typeID, $ID );
    }
    elsif ( $action =~ /^CON_/ ) {
        ( $resultHTML, $pageHeading ) =
          handleContacts( $action, \%Data, $typeID, $ID );
    }
    elsif ( $action =~ /^BANKSPLIT/ ) {
        ( $resultHTML, $pageHeading ) = handleBankSplit( $action, \%Data );
    }
    elsif ( $action =~ /^PSR/ ) {
        ( $resultHTML, $pageHeading ) =
          handlePaymentSplitRun( $action, \%Data );
    }
    elsif ( $action =~ /^BA_/ ) {
        ( $resultHTML, $pageHeading ) =
          handleBankAccount( $action, \%Data, $ID, $typeID );
    }
    elsif ( $action =~ /^PY_/ ) {
        ( $resultHTML, $pageHeading ) =
          handlePaymentApplication( $action, \%Data, $ID, $typeID );
    }
    elsif ( $action =~ /^MEMCARD_/ ) {
        ( $resultHTML, $pageHeading ) =
          handleMemberCard( $action, \%Data, $client, $ID, $typeID );
    }
    elsif ( $action =~ /^RFR_/ ) {
        ( $resultHTML, $pageHeading ) =
          handleFormReplication( $action, \%Data );
    }
    elsif ( $action =~ /^FC_C_/ ) {
        ( $resultHTML, $pageHeading ) = handleFieldConfig( $action, \%Data );
    }
    elsif ( $action =~ /^ESET_/ ) {
        ( $resultHTML, $pageHeading ) = handleEntitySettings( $action, \%Data );
    }
    elsif ( $action =~ /^DASHCFG_/ ) {
        ( $resultHTML, $pageHeading ) =
          handle_DashboardConfig( $action, \%Data, $ID, $typeID, $client );
    }
    elsif ( $action =~ /^NOTS/ ) {
        ( $resultHTML, $pageHeading ) =
          handleNotifications( $action, \%Data, $client, $typeID, $ID );
    }
    elsif ($action =~/^OPTIN/) {
        ( $resultHTML, $pageHeading ) =
            handleOptins($action,\%Data, $client, $typeID, $ID);
    }
    elsif ($action =~/^MR_/) {
        ( $resultHTML, $pageHeading ) = handle_member_records($action, \%Data);
    }
    elsif ($action =~/^MRT_/) {
        ( $resultHTML, $pageHeading ) = handle_member_record_types($action, \%Data);
    }
    else {
        #$resultHTML=getWelcomeText(\%Data);
    }

    # BUILD PAGE
    if ( !$report ) {
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
    }
    else { printReport( $resultHTML, $lang ); }
    disconnectDB($db);
}

sub defaultAction {
    my ($level) = @_;
    return 'A_HOME'  if $level == $Defs::LEVEL_ASSOC;
    return 'C_HOME'  if $level == $Defs::LEVEL_CLUB;
    return 'CO_HOME' if $level == $Defs::LEVEL_COMP;
    return 'T_HOME'  if $level == $Defs::LEVEL_TEAM;
    return 'N_HOME'  if $level > $Defs::LEVEL_ASSOC;
}

sub logPageData {
    my ( $Data, $action, $client, $assoc_id ) = @_;

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
        assocID     => $assoc_id,
    );

    my $cachekey = 'MEMACTION_' . $ENV{'SERVER_ADDR'} . '_' . $processID;
    $cache->set( 'swm', $cachekey, \%pagedata, undef, 60 * 180 ) if $cache;
}
