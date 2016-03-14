#! /usr/bin/perl -w

use strict;
use CGI qw(param unescape escape cookie);

use lib '.', '..', '../..',"user","../PaymentSplit",'../Clearances';
use Lang;
use Localisation;
use Reg_common;
use PageMain;
use Defs;
use Utils;
use SystemConfig;
use ConfigOptions;
use SelfUserSession;

use MCache;
use FieldConfig;
use TTTemplate;
use AddToPage;

use SelfUserHome;
use Flow_PersonSelfReg;
use SelfUserWorkFlow;
use AccountActivation;
use AccountProfile;
use OldSystemAccounts;

use SelfUserFlow;
use SelfUserTransfer;
use ForgottenPassword;
use Data::Dumper;
use SelfRegoPersonEdit;
use PersonUtils;
use SelfUserExtraProductFlow;
main();

sub main {

    # GET INFO FROM URL
    my $client = param('client') || '';
    my $action = safe_param( 'a', 'action' ) || '';
    my $srp = param( 'srp') || '';
    my %Data   = ();
    my $target = 'index.cgi';
    $Data{'target'} = $target;
    $Data{'cache'}  = new MCache();
    $Data{'AddToPage'} = new AddToPage();
    $Data{'SelfRego'} = 1;

    my %clientValues = getClient($client);
    $Data{'clientValues'} = \%clientValues;

    # AUTHENTICATE
    my $db = connectDB();
    $Data{'db'} = $db;

    ( $Data{'Realm'}, $Data{'RealmSubType'} ) = getRealm( \%Data );
    $Data{'Realm'} ||= 1;
    getDBConfig( \%Data );
    $Data{'SystemConfig'} = getSystemConfig( \%Data );
    $Data{'LocalConfig'}  = getLocalConfig( \%Data );
    my $lang   = Lang->get_handle('', $Data{'SystemConfig'}) || die "Can't get a language handle!";
    $Data{'lang'} = $lang;
    initLocalisation(\%Data);
    updateSystemConfigTranslation(\%Data);

    # DO DATABASE THINGS
    my $DataAccess_ref = getDataAccess( \%Data );
    $Data{'DataAccess'} = $DataAccess_ref;

    my $resultHTML  = q{};
    my $pageHeading = q{};

    $Data{'clientValues'} = \%clientValues;
    $client               = setClient( \%clientValues );
    $Data{'client'}       = $client;
    $Data{'unesc_client'} = unescape($client);

    $Data{'Permissions'} = GetPermissions(
        \%Data,
        $Defs::LEVEL_NATIONAL,
        getNationalID($db),
        $Data{'Realm'},
        $Data{'RealmSubType'},
        'regoform',
        0,
    );
    my $user = new SelfUserSession(
        db    => $db,
        cache => $Data{'cache'},
    );
    $user->load();
    my $userID = $user->id() || 0;
    
    $Data{'UserName'} =  formatPersonName(\%Data, $user->name(), $user->familyname(), '');
   
    $Data{'User'} = $user;
    $Data{'UserID'} = $userID;
    
    $action = 'LOGIN' if(!$userID and $action ne 'activate' and $action !~/FORGOT/);
    
    if(!$action and $userID)  {
        $action = 'HOME';
    }
    if ( $action eq 'HOME' ) {
        $resultHTML = showHome(\%Data, $user, $srp);
    }
    elsif ( $action =~ /SIGNUP_/ ) {
    }
    elsif ( $action =~ /REG_/ ) {
        my $content = handleSelfUserFlow($action, \%Data, undef);
        $resultHTML .= $content;
    }
    elsif ( $action =~ /WF_/ ) {
        ($resultHTML, $pageHeading) = handleSelfUserWorkFlow(\%Data, $user, $action);
    }
    elsif ($action =~ /activate/) {
        ($resultHTML, $pageHeading) = handleAccountActivation(\%Data, $action);
    }
    elsif ($action =~ /FORGOT/) {
        ($resultHTML, $pageHeading) = handleForgottenPassword(\%Data, $action);
    }
    elsif ($action eq 'link') {
        $resultHTML .= linkOldAccount(\%Data, $user);
        $resultHTML .= showHome(\%Data, $user, $srp);
    }
    elsif ($action =~ /P_/) {
        ($resultHTML, $pageHeading) = handleAccountProfile(\%Data, $action);
        if($action eq 'P_u')    {
            $resultHTML .= showHome(\%Data, $user, $srp);
        }
    }
    elsif($action =~ /SPE_/){         
        ($resultHTML, $pageHeading) = handleSelfRegoPersonEdit(\%Data, $action);
    }
    elsif ($action =~ /TRANSFER_/) {
        ($resultHTML, $pageHeading) = handleSelfUserTransfer(\%Data, $user, $action);
    }
    elsif($action =~ /ADD_PROD/){
        my $extraprod = handleSelfUserExtraProductFlow($action, \%Data, undef);
        $resultHTML .= $extraprod;       
    }
   else {
        # Display login page
        $resultHTML = runTemplate(
            \%Data,
            {
                srp => $srp,
            },
            'selfrego/user/login.templ',
        );    
    }

    # BUILD PAGE
    $client = setClient( \%clientValues );
    $clientValues{INTERNAL_db} = $db;
    $resultHTML = qq[
        <div class="pageHeading">$pageHeading</div>
        $resultHTML
    ] if $pageHeading;

    $resultHTML ||= textMessage("An invalid Action Code has been passed to me.");

    regoPageForm($Defs::page_title, $resultHTML, \%clientValues,$client, \%Data);
    disconnectDB($db);
}


sub getNationalID {
    my ($db) = @_;
    my $st = qq[
        SELECT 
            intEntityID
        FROM
            tblEntity
        WHERE
            intEntityLevel = $Defs::LEVEL_NATIONAL
            AND strStatus = 'ACTIVE'
        ORDER BY
            intEntityID
        LIMIT 1
    ];
    my $q = $db->prepare($st);
    $q->execute();
    my ($id) = $q->fetchrow_array();
    $q->finish();
    return $id || 0;
}
