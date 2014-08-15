#!/usr/bin/perl -w

#
# $Header: svn://svn/SWM/trunk/web/index.cgi 10277 2013-12-15 21:15:06Z tcourt $
#

use strict;
use lib ".", "..";
use CGI qw(param unescape escape cookie);
use Defs;
use Lang;
use TTTemplate;

	my $lang= Lang->get_handle() || die "Can't get a language handle!";
	
	my $pheading=$lang->txt('Sign in to <span class="sporange">Membership</span>');
	my $txtexpl=$lang->txt('Here you can sign in to your SportingPulse Membership database.');
	my $title=$lang->txt('APPNAME') || 'SportingPulse Membership';

    my %Data = (
        lang=> $lang
    );
	my %TemplateData = (
		Lang => $lang,
    );

    my $nav = runTemplate(\%Data, \%TemplateData, 'user/globalnav.templ',);
    my $pagebody = runTemplate(\%Data, \%TemplateData, 'user/loginform.templ',);

	%TemplateData = (
		Lang => $lang,
        title => $title,
        globalnav=> $nav,
        pagebody=> $pagebody,
	);

    
    print "Content-type: text/html\n\n";
    print runTemplate(
        \%Data,
        \%TemplateData,
        'user/index.templ',
    );
