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
use Passport;
use GlobalAuth;

#use Data::Dumper;

main();

sub main {
    my $origusername = safe_param( 'username', 'words' ) || '';
    my $password = param('pass') || '';
    my $ID_IN     = safe_param( 'i',      'number' ) || 0;
    my $typeID_IN = safe_param( 't',      'number' ) || 0;

    ## GET REDIRECT URL
    $redirectURL = $Defs::base_url;

    my %Data = ();
    my $lang = Lang->get_handle() || die "Can't get a language handle!";
    $Data{'lang'} = $lang;
    my ($db) = connectDB();
    if ( !$db ) { kickThemOff( 'Database Connection Problems', $redirectURL ); }
    $Data{'db'}    = $db;
    $Data{'cache'} = new MCache();

    my $passportObj = new Passport(
        db    => $db,
        cache => $Data{'cache'},
    );
    $passportObj->loadSession();
    my $passportID = $passportObj->id() || 0;

    my $passportlogin = 0;
    if (    !$origusername
        and !$password
        and $ID_IN
        and $typeID_IN
        and $passportID )
    {
        #Check for Passport login
        $passportlogin = 1;
    }
    my $success = 0;

    my $intAuthID = 0;
    my $idcode    = 0;
    my $level     = 0;
    my $logins    = 0;
    my $lastlogin = 0;
    my $assocID   = 0;
    my $days      = 0;

    my $type     = '';
    my $username = '';

    if ($passportlogin) {
        my $st = qq[
			SELECT
				intEntityTypeID,
				intEntityID,
				dtLastLogin,
				intAssocID
			FROM tblPassportAuth
			WHERE
				intPassportID = ?
				AND intEntityTypeID = ?
				AND intEntityID = ?
		];
        my $q = $db->prepare($st);
        $q->execute( $passportID, $typeID_IN, $ID_IN, );

        ( $level, $idcode, $lastlogin, $assocID, $days ) = $q->fetchrow_array();

        $q->finish();
        $success = 1 if $idcode;

        if ($success) {
            my $statement = qq[
				UPDATE tblPassportAuth
				SET intLogins = intLogins+1, dtLastlogin = NOW()
				WHERE intPassportID = ?
					AND intEntityTypeID = ?
					AND intEntityID = ?
			];
            $q = $db->prepare($statement);
            $q->execute( $passportID, $typeID_IN, $ID_IN, );
            $q->finish;
        }
        else {
            my ( $valid, $assocID_login ) =
              validateGlobalAuth( \%Data, $passportID, $typeID_IN, $ID_IN, );
            if ($valid) {
                $level   = $typeID_IN;
                $idcode  = $ID_IN;
                $assocID = $assocID_login || 0;
                $success = 1;
            }
        }
    }
    else {

        # CHECK USERNAME/PASSWORD COMBINATION AND GET ID IF SUCCESSFUL

        ( $type, $username ) = $origusername =~ /^(\d)(.+)/;
        $username = $origusername if !$username;
        kickThemOff( 'Invalid Login Parameters', $redirectURL ) if !$username;
        $type ||= 0;
        $type = 0 if $type !~ /^\d$/;
        my $typestr = ($type) ? " AND intLevel = $type " : '';
        $username = '';
        my $statement = qq[
			SELECT intAuthID, intID, intLevel, intLogins, dtLastlogin, intAssocID, DATEDIFF(CURDATE(), dtLastlogin) 
			FROM tblAuth 
			WHERE strUsername = ?
				AND strPassword = ?
				$typestr
			];
        my $query = $db->prepare($statement);
        $query->execute( $username, $password ) or die("AAAGH");

        ( $intAuthID, $idcode, $level, $logins, $lastlogin, $assocID, $days ) =
          $query->fetchrow_array();
        $success = 1 if $intAuthID;
        $query->finish;
        if ($success) {
            $logins++;
            my $thisaccessdate =
                ( (localtime)[5] + 1900 ) . '-'
              . ( (localtime)[4] + 1 ) . '-'
              . (localtime)[3];
            $statement = qq[
				UPDATE tblAuth 
				SET intLogins = ?, dtLastlogin = ?
				WHERE intAuthID = ?
			];
            $query = $db->prepare($statement);
            $query->execute( $logins, $thisaccessdate, $intAuthID );
            $query->finish;
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
        passportID        => $passportID,
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
    $clientValues{userName}   = $username;
    $clientValues{passportID} = $passportID || 0;

    # BASED ON USERS LEVEL  SET UP CLIENT VARIABLES ETC.

    my $client = '';
    if ( $level == $Defs::LEVEL_MEMBER ) {
        $clientValues{memberID} = $idcode;
        $clientValues{assocID}  = $assocID;
        kickThemOff( 'Invalid Login Parameters', $redirectURL );
    }
    if ( $level == $Defs::LEVEL_TEAM ) {
        $clientValues{teamID}      = $idcode;
        $clientValues{clubAssocID} = $assocID;
        $clientValues{assocID}     = $assocID;
    }
    if ( $level == $Defs::LEVEL_CLUB ) {
        $clientValues{clubID}      = $idcode;
        $clientValues{clubAssocID} = $assocID;
        $clientValues{assocID}     = $assocID;
        $clientValues{displayClub} = "true";
    }
    if ( $level == $Defs::LEVEL_COMP ) {    # NOT USED INITIALLY
        $clientValues{compID} = $idcode;
    }

    $clientValues{assocID}  = $idcode if $level == $Defs::LEVEL_ASSOC;
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

    if ($passportlogin) {
        print entity_cookie( new CGI, $level, $idcode );
    }
    else {
        my $cookie_header =
          cookie_string( new CGI, $intAuthID, $password, 1, $level );
        print $cookie_header;
    }

    my $link =
      "main.cgi?client=$client&lastlogin=$lastlogin&days=$days&amp;a=LOGIN";

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

sub cookie_string {
    my ( $output, $intAuthID, $password, $add, $level ) = @_;
    my ($expiry) = '';
    if   ($add) { $expiry = '+60d' }
    else        { $expiry = '-1d'; }

    my $val = $intAuthID . 'Y' . authstring( $password . $intAuthID );
    $val = '' if !$add;
    my $cookiename = $Defs::COOKIE_MEMBER;
    $cookiename = $Defs::COOKIE_EVENT if $level == $Defs::LEVEL_EVENT;
    $cookiename = $Defs::COOKIE_EVENT if $level == $Defs::LEVEL_EVENT_ACCRED;
    $cookiename = $Defs::COOKIE_EVENT if $level == $Defs::LEVEL_EVENT_TRANSPORT;
    my $member_cookie = $output->cookie(
        -name    => "$cookiename",
        -value   => "$val",
        -domain  => $Defs::cookie_domain,
        -secure  => 0,
        -expires => "$expiry",
        -path    => "/"
    );

    my $header = $output->header( -cookie => [$member_cookie] );

    return $header || '';
}

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

    my $header = $output->header( -cookie => [$entity_cookie] );

    return $header || '';
}
