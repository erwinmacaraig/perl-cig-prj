#!/usr/bin/perl -w

#
# $Header: svn://svn/SWM/trunk/web/passport/authlistadd.cgi 10951 2014-03-12 07:27:29Z eobrien $
#

use DBI;
use CGI qw(:cgi escape unescape);

use strict;

use lib ".", "..", "../..";

use Defs;
use Utils;
use Passport;
use PassportList;
use PageMain;
use Lang;
use PassportLink;

main();

sub main {

    my %Data = ();
    my $db   = connectDB();
    $Data{'db'} = $db;
    my $lang = Lang->get_handle() || die "Can't get a language handle!";
    $Data{'lang'} = $lang;
    my $target = 'authlistadd.cgi';
    $Data{'target'} = $target;
    $Data{'cache'}  = new MCache();

    my $passport = new Passport( db    => $db,
                                 cache => $Data{'cache'}, );
    $passport->loadSession();
    my $pID = $passport->id() || 0;

    if ( !$pID ) {
        redirectPassportLogin( \%Data, );
    }

    my $username = param('username') || '';
    my $password = param('pass')     || '';
    if ( $username =~ /^\d+$/ ) {
        $username =~ s/^\d//;
    }

    my @ids = ();
    {
        my $st = qq[
			SELECT 
				intLevel,
				intID,
				intAssocID,
				intReadOnly,
				intRoleID
			FROM tblAuth
			WHERE 
				strUsername = ?
				AND strPassword = ?
		];
        my $q = $db->prepare($st);
        $q->execute( $username, $password );
        my $dref = $q->fetchrow_hashref();
        $q->finish();
        push @ids, $dref if $dref;
    }

    if ( !scalar(@ids) and $username =~ /^venue/ ) {
        my $st = qq[
			SELECT DISTINCT VAA.intOnlineVenueID AS intID, VAA.intAssocID
			FROM tblResults_VenueAuth as VA
				INNER JOIN tblResults_VenueAuthAccess as VAA ON (VAA.intVenueAuthID = VA.intVenueAuthID)
			WHERE VA.strUsername = ?
				AND VA.strPassword = ?
		];
        my $q = $db->prepare($st);
        $q->execute( $username, $password );
        while ( my $dref = $q->fetchrow_hashref() ) {
            $dref->{'intLevel'} = $Defs::LEVEL_VENUE;
            push @ids, $dref;
        }
    }

    my $title = 'Passport Authorisation';
    my $body  = '';
    if ( scalar(@ids) and $username and $password ) {
        for my $dref (@ids) {
            if ( $dref and $dref->{'intID'} and $dref->{'intLevel'} and $username and $password ) {
                if ( $Data{'SystemConfig'}{'AllowLinkMemberToPassport'} and ($dref->{'intLevel'} eq $Defs::LEVEL_MEMBER) ) {
                    my @errors = ();
                    $passport->link_member( $dref->{'intID'}, $Data{'lang'}, \@errors );
                    if ( !@errors ) {
                        $passport->addModule( 'SPMEMBERSHIPADMIN', $passport->email() );
                    }
                }
                else {
                    my $st_i = qq[
					INSERT INTO tblPassportAuth	(
						intPassportID,
						intEntityTypeID,
						intEntityID,
						intAssocID,
						intReadOnly,
						intRoleID,
						dtCreated
					)
					VALUES (
						?,
						?,
						?,
						?,
						?,
						?,
						NOW()
					)
				    ];
                    my $q_i = $db->prepare($st_i);
                    $q_i->execute(
                                   $pID,
                                   $dref->{'intLevel'},
                                   $dref->{'intID'},
                                   $dref->{'intAssocID'}  || 0,
                                   $dref->{'intReadOnly'} || 0,
                                   $dref->{'intRoleID'}   || 0,
                    );
                    $q_i->finish();
                    $passport->addModule( 'SPMEMBERSHIPADMIN', $passport->email() );
                }
            }
        }

        my $listURL = "$Defs::base_url/authlist.cgi";
        my $cgi     = new CGI;
        my $header  = $cgi->redirect($listURL);
        print $header;
        exit;

    }
    else {
        $body = qq[
		<div id="global-nav-wrap">
<style type="text/css">
  #globalnav {
    float: left;
    width: 100%;
    height: 32px;
    background: url("http://www-static.sportingpulse.com/images/globalheader/global_nav_sprite.png") repeat-x scroll 0 0 transparent;
  }
  #globalnav-inner {
    margin: 0 auto;
    width: 996px;
  }
  .gnav-logo {
    float: left;
    display: block;
    width: 106px;
    height: 27px;
    background: url("http://www-static.sportingpulse.com/images/globalheader/global_nav_sprite.png") no-repeat 0 -162px transparent;
    margin: 2px 0;
  }
  .navoptions {
    float: right;
  }
  .sp-sign-in-out-wrap {
    float: right;
    font-size: 12px;
    line-height: 32px;
  }
  .sp-sign-in-out-wrap a {
    float: left;
    color: #FFF;
    height: 32px;
    padding: 0 10px;
    display: block;
  }
  .sp-sign-in-out-wrap a:hover {
    background-image: #116faa;
    background-image: -webkit-linear-gradient(top, #2277b0 50%, #0066a4 50%);
    background-image: -moz-linear-gradient(top, #2277b0 50%, #0066a4 50%);
    background-image: -o-linear-gradient(top, #2277b0 50%, #0066a4 50%);
    background-image: -ms-linear-gradient(top, #2277b0 50%, #0066a4 50%);
    background-image: linear-gradient(top, #2277b0 50%, #0066a4 50%);
		text-decoration: none;
  }
</style>

<div id="globalnav">
  <div id="globalnav-inner">
    <a href="http://www.sportingpulse.com" class="gnav-logo"></a>
  </div>
</div>

		</div>

		<link rel="stylesheet" type="text/css" href="../css/regoform.css">
		<link rel="stylesheet" type="text/css" href="../css/passportstyle.css"> 
		<div id="pagewrapper" class="authlist-error">
			<div id="spheader"><img src="../images/sp_membership.png" ></div>
			<div id="pageholder">
				<div id="contentholder">
					<div id="content">
						<div class ="warningMsg">I'm sorry we cannot find a login account matching those credentials</div>
      			<p><a href="../authlist.cgi" class="try-again-btn">Try again</a></p>
					</div>
				</div>
			</div>
			<div id="footer">
				<div class="footerline">&copy;&nbsp; Copyright SportingPulse Pty Ltd &nbsp;2012.&nbsp; All rights reserved.</div>
				<div style="clear:both;"></div>
			</div>
		</div> 			
		];

    }

    printBasePage(
                   $body,
                   $title,
    );
}

