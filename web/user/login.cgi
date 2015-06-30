#!/usr/bin/perl -w

use DBI;
use CGI qw(:cgi escape unescape);

use strict;

use lib ".", "..", "../..", "user";

use Defs;
use Utils;
use PageMain;
use Lang;
use Login;
use TTTemplate;
use SystemConfig;
use Localisation;
use LanguageChooser;

main();

sub main {

    my %Data = ();
    my $db   = connectDB();
    $Data{'db'} = $db;
    my $lang = Lang->get_handle() || die "Can't get a language handle!";
    $Data{'lang'} = $lang;
    my $target = 'authlist.cgi';
    $Data{'target'} = $target;
    $Data{'cache'}  = new MCache();

    $Data{'Realm'} = 1;
    $Data{'SystemConfig'} = getSystemConfig( \%Data );
    my $email = param('email') || '';
    my $password = param('pw') || '';

    my($sessionKey, $errors) = login(\%Data, $email, $password);

    my $body = '';
    if($sessionKey) {
        push @{$Data{'WriteCookies'}}, [
            $Defs::COOKIE_LOGIN,
            $sessionKey,
            '+3h',
        ];

        my $user = new UserSession(
            db    => $db,
            cache => $Data{'cache'},
            key   => $sessionKey,
        );

        my $uID = $user->id() || 0;
        if ( !$uID ) {
            $Data{'RedirectTo'} = "$Defs::base_url/";
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

                $Data{'RedirectTo'} = "$Defs::base_url/";
            }
            else    {
                push @{$Data{'WriteCookies'}}, [
                    $Defs::COOKIE_LASTLOGIN_TIMESTAMP,
                    $lastLogin,
                    '+1h',
                ];

                $Data{'RedirectTo'} = "$Defs::base_url/authenticate.cgi?i=$id&amp;t=$type";
            }
        $body = qq[
                <SCRIPT LANGUAGE="JavaScript1.2">
                        parent.location.href="$Defs::base_url/authenticate.cgi?i=$id&amp;t=$type";
                        noScript = 1;
                </SCRIPT>
        ];

        }

    }
    else    {
      $body = runTemplate(
        \%Data,
        {'returnURL'=>"../index.cgi",'errors' => $errors},
        #{'returnURL'=>"$Data{'SystemConfig'}{'loginError_returnURL'}" ,'errors' => $errors},
        'user/loginerror.templ',
      );
    }

    my $title = 'Login';


    my $title=$lang->txt('APPNAME') || 'FIFA Connect';
    initLocalisation(\%Data);
    updateSystemConfigTranslation(\%Data);
    my %TemplateData = (
        Lang => $lang,
        SystemConfig => $Data{'SystemConfig'},
        DirPrefix => '../',
    );

    my $nav = runTemplate(\%Data, \%TemplateData, 'user/globalnav.templ',);

    %TemplateData = (
        Lang => $lang,
        title => $title,
        globalnav=> $nav,
        pagebody=> $body,
        SystemConfig => $Data{'SystemConfig'},
        LanguageChooser => genLanguageChooser(\%Data),
        DirPrefix => '../',
    );


    if($Data{'RedirectTo'}) {
        pageForm(
                  $title,
                  $body,
                  {},
                  '',
                  \%Data,
                  'user/index.templ',
        );

    }
    else    {
        print "Content-type: text/html\n\n";
        print runTemplate(
            \%Data,
            \%TemplateData,
            'user/index.templ',
        );
    }

}

