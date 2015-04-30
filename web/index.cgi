#!/usr/bin/perl -w

#
# $Header: svn://svn/SWM/trunk/web/index.cgi 10277 2013-12-15 21:15:06Z tcourt $
#

use strict;
use lib ".", "..";
use CGI qw(param unescape escape cookie);
use Defs;
use Utils;
use Lang;
use TTTemplate;
use SystemConfig;
use LanguageChooser;
use Localisation;

    my ( $db, $message ) = connectDB() || die;
    my %Data = (
        db => $db,
        Realm => 1,
    );
    $Data{'SystemConfig'} = getSystemConfig( \%Data );

	my $lang= Lang->get_handle('', $Data{'SystemConfig'}) || die "Can't get a language handle!";
    $Data{'lang'} = $lang;
	
	my $title=$lang->txt('APPNAME') || 'FIFA Connect';
    initLocalisation(\%Data);
    updateSystemConfigTranslation(\%Data);
	my %TemplateData = (
		Lang => $lang,
        SystemConfig => $Data{'SystemConfig'},
    );

    my $nav = runTemplate(\%Data, \%TemplateData, 'user/globalnav.templ',);
    my $pagebody = runTemplate(\%Data, \%TemplateData, 'user/loginform.templ',);

	%TemplateData = (
		Lang => $lang,
        title => $title,
        globalnav=> $nav,
        pagebody=> $pagebody,
        SystemConfig => $Data{'SystemConfig'},
        LanguageChooser => genLanguageChooser(\%Data),
	);

    disconnectDB($db);
    
    print "Content-type: text/html\n\n";
    print runTemplate(
        \%Data,
        \%TemplateData,
        'user/index.templ',
    );
