#!/usr/bin/perl -w

use DBI;
use CGI qw(:cgi escape unescape);

use strict;

use lib ".", "..", "../..", "registration","registration/user","../../..","user";

use Defs;
use Utils;
use PageMain;
use Lang;
use SelfUserLogin;
use TTTemplate;
use SelfUserSession;

main();

sub main {

    my %Data = ();
    my $db   = connectDB();
    $Data{'db'} = $db;
    my $lang = Lang->get_handle() || die "Can't get a language handle!";
    $Data{'lang'} = $lang;
    $Data{'target'} = 'login.cgi';
    $Data{'cache'}  = new MCache();
    my $email = param('email') || '';
    my $password = param('pw') || '';

    my($sessionKey, $errors) = login(\%Data, $email, $password);

    my $body = '';
    if($sessionKey) {
        push @{$Data{'WriteCookies'}}, [
            $Defs::COOKIE_SRLOGIN,
            $sessionKey,
            '3h',
        ];

        my $user = new SelfUserSession(
            db    => $db,
            cache => $Data{'cache'},
            key   => $sessionKey,
        );

        my $uID = $user->id() || 0;
        if ( !$uID ) {
            $Data{'RedirectTo'} = "$Defs::base_url/registration/";
        }
        else    {
            my $st = qq[
                SELECT
                    entityTypeId,
                    entityId,
                    UNIX_TIMESTAMP(lastLogin) as lastLoginUnixTimeStamp
                FROM
                    tblUserAuth
                WHERE
                    userId = ?
                LIMIT 1
            ];
            my $q = $db->prepare($st);
            $q->execute($uID);
            my ( $type, $id, $lastLogin) = $q->fetchrow_array();
            $q->finish();
            if(!$type or !$id)  {

                $Data{'RedirectTo'} = "$Defs::base_url/registration/";
            }
            else    {
                #push @{$Data{'WriteCookies'}}, [
                    #$Defs::COOKIE_LASTLOGIN_TIMESTAMP,
                    #$lastLogin,
                    #'1h',
                #];

                $Data{'RedirectTo'} = "$Defs::base_url/registration/";
            }
        $body = qq[
                <SCRIPT LANGUAGE="JavaScript1.2">
                        parent.location.href="$Defs::base_url/registration/";
                        noScript = 1;
                </SCRIPT>
        ];

        }

    }
    else    {
      $body = runTemplate(
        \%Data,
        {'errors' => $errors},
        'selfrego/user/loginerror.templ',
      );
    }

    my $title = 'Login';

    pageForm(
              $title,
              $body,
              {},
              '',
              \%Data,
    );
}

