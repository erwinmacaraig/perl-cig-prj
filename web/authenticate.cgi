#! /usr/bin/perl -w

#
# $Header: svn://svn/SWM/trunk/web/authenticate.cgi 10144 2013-12-03 21:36:47Z tcourt $
#

use strict;

use CGI qw(param);
use lib '.';
use Reg_common;
use Defs;
use Utils;
use Lang;
use AuditLogObj;
use MCache;
use UserSession;
use GlobalAuth;

#use Data::Dumper;

main();

sub main {
    my $ID_IN     = safe_param( 'i',      'number' ) || 0;
    my $typeID_IN = safe_param( 't',      'number' ) || 0;

    ## GET REDIRECT URL
    my $redirectURL = $Defs::base_url;

    my %Data = ();
    my $lang = Lang->get_handle() || die "Can't get a language handle!";
    $Data{'lang'} = $lang;
    my ($db) = connectDB();
    if ( !$db ) { kickThemOff( 'Database Connection Problems', $redirectURL ); }
    $Data{'db'}    = $db;
    $Data{'cache'} = new MCache();

    my $userObj = new UserSession(
        db    => $db,
        cache => $Data{'cache'},
    );
    $userObj->load();
    my $userID = $userObj->id() || 0;

    my $userlogin = 0;
    $userlogin = 1;
    my $success = 0;

    my $intAuthID = 0;
    my $idcode    = 0;
    my $level     = 0;
    my $logins    = 0;
    my $lastlogin = 0;
    my $days      = 0;

    my $type     = '';
    my $username = '';

    if($userID) {
        my $st = qq[
			SELECT
				entityTypeID,
				entityID,
				lastLogin
			FROM tblUserAuth
			WHERE
				userID = ?
				AND entityTypeID = ?
				AND entityID = ?
		];
        my $q = $db->prepare($st);
        $q->execute( $userID, $typeID_IN, $ID_IN );

        ( $level, $idcode, $lastlogin) = $q->fetchrow_array();

        $q->finish();
        $success = 1 if $idcode;

        if ($success) {
            my $statement = qq[
				UPDATE tblUserAuth
				SET lastlogin = NOW()
				WHERE userID = ?
					AND entityTypeID = ?
					AND entityID = ?
			];
            $q = $db->prepare($statement);
            $q->execute( $userID, $typeID_IN, $ID_IN, );
            $q->finish;
        }
        else {
            my $valid = validateGlobalAuth( \%Data, $userID, $typeID_IN, $ID_IN);
            if ($valid) {
                $level   = $typeID_IN;
                $idcode  = $ID_IN;
                $success = 1;
            }
        }
    }
    if ( !$success ) {
        disconnectDB($db);

        print qq[Content-type: text/html\n\n];
        print qq[
		<HTML>
		<BODY>
		<SCRIPT LANGUAGE="JavaScript1.2">
			parent.location.href="$redirectURL";
			noScript = 1;
		</SCRIPT>
		</BODY>
		</HTML>
		];

        exit;
    }

    # EVERYTHING OK. UPDATE LAST LOGIN AND TOTAL LOGINS.
    my $log = new AuditLogObj( db => $db );
    $log->log(
        id                => $intAuthID,
        username          => $username,
        userID        => $userID,
        type              => 'Login',
        section           => 'Authentication',
        entity_type       => $level,
        entity            => $idcode,
        login_entity_type => $level,
        login_entity      => $idcode
    );

    # SET AUTH LEVEL AND USERS NAME IN CLIENT VALUES HASH
    my %clientValues = ();
    $clientValues{authLevel}  = $level;
    $clientValues{userID} = $userID || 0;

    # BASED ON USERS LEVEL  SET UP CLIENT VARIABLES ETC.

    my $client = '';
    if ( $level == $Defs::LEVEL_PERSON ) {
        $clientValues{personID} = $idcode;
        kickThemOff( 'Invalid Login Parameters', $redirectURL );
    }
    if ( $level == $Defs::LEVEL_CLUB ) {
        $clientValues{clubID}      = $idcode;
        $clientValues{displayClub} = "true";
    }

    $clientValues{zoneID}   = $idcode if $level == $Defs::LEVEL_ZONE;
    $clientValues{regionID} = $idcode if $level == $Defs::LEVEL_REGION;
    $clientValues{stateID}  = $idcode if $level == $Defs::LEVEL_STATE;

    if ( $level == $Defs::LEVEL_NATIONAL ) {
        $clientValues{nationalID} = $idcode;
        $clientValues{natID}      = $idcode;
    }
    $clientValues{intzonID} = $idcode if $level == $Defs::LEVEL_INTZONE;
    $clientValues{intregID} = $idcode if $level == $Defs::LEVEL_INTREGION;
    $clientValues{interID}  = $idcode if $level == $Defs::LEVEL_INTERNATIONAL;

    $Data{'clientValues'} = \%clientValues;
    getDBConfig( \%Data );

    disconnectDB($db);

    $clientValues{currentLevel} = $level;

    $client = setClient( \%clientValues );

    my $cgi = new CGI;
    my $cookie  = entity_cookie( $cgi, $level, $idcode );

    my $link =
      $Defs::base_url."/main.cgi?client=$client&lastlogin=$lastlogin&days=$days&a=LOGIN";

    my $p3p=q[policyref="/w3c/p3p.xml", CP="ALL DSP COR CURa ADMa DEVa TAIi PSAa PSDa IVAi IVDi CONi OTPi OUR BUS IND PHY ONL UNI COM NAV DEM STA"];

    my $h = $cgi->header(-uri => $link, -cookie=>[$cookie], -P3P => $p3p); #This is needed, I don't know why
    print $cgi->redirect (-uri => $link, -cookie=>[$cookie], -P3P => $p3p);

    print qq[
	<HTML>

	<BODY>

	<SCRIPT LANGUAGE="JavaScript1.2">
		parent.location.href="$link";
		noScript = 1;
	</SCRIPT>

	</BODY>

	</HTML>
	];

}

#----------------------------------

sub entity_cookie {
    my ( $output, $EntityTypeID, $EntityID ) = @_;

    my $val           = $EntityTypeID . ':' . $EntityID,;
    my $cookiename    = $Defs::COOKIE_ENTITY;
    my $entity_cookie = $output->cookie(
        -name   => "$cookiename",
        -value  => "$val",
        -domain => $Defs::cookie_domain,
        -path   => "/"
    );

    return $entity_cookie;
    #my $header = $output->header( -cookie => [$entity_cookie] );

    #return $header || '';
}
