#!/usr/bin/perl -w

#
# $Header: svn://svn/SWM/trunk/web/admin/index.cgi 11645 2014-05-22 03:47:31Z apurcell $
#

#use lib "../..","..",".", "../user";
use lib "../..", '.', '..', "../comp", '../RegoForm', "../dashboard", "../RegoFormBuilder",'../PaymentSplit','../Clearances', "../user";
use DBI;
use CGI qw(param unescape escape);
use Defs;
use Utils;
use strict;
use warnings;
use AdminPageGen;
use AdminCommon;
use RealmAdmin;
use FormHelpers;
use UtilsAdmin;
use MCache;
use SystemConfigAdmin;
use Data::Dumper;
use AdminTests;

main();

sub main	{

# Variables coming in
    my $header = "Content-type: text/html\n\n";
    my $body = "";
    my $title = "$Defs::sitename Administration";
    my $output=new CGI;
    my $action = param('action') || param('a') || 'SEARCH_FORM';
    my $sport= param('sport') || '';
    my $country= param('country') || '';
    my $url = param('decodeurl') || '';
    my $assoc_name_IN = param('assoc_name') || '';
    my $assoc_fsc_IN = param('assoc_fsc') || '';
    my $assoc_un_IN = param('assoc_un') || '';
    my $assoc_id_IN = param('assoc_id') || '';
    my $assoc_email_IN = param('assoc_email') || '';
    my $assoc_sportID_IN = param('sportID') || 0;

    my $assocID=param('intAssocID') || param('entityID') || param('aID') || param("swmid") || 0;
    my $assocName=param('AssocName') || '';
    my $escAssocName=escape($assocName);
    my $subBody='';
    my $menu='';
    my $activetab=0;
    my $activetop=0;
    my $target="index.cgi";

    my $error='';
    my $db=connectDB();
    if(!$db)	{
        $subBody=qq[You must select a country and sport<br>$error];
        $action='ERROR';
    }

    my @tabs=();
    my @topTabs=(

        ["selfrego_admin.cgi",'Self Rego Admin'],
        ["person_finder.cgi",'Person Finder'],
        ["kickpassport.cgi",'Passport Update'],
        ["login_admin.cgi",'Login Admin'],
        ["$target?action=REALM_CONFIG",'System Config'],
    );

    #["$target?action=TEAM",'Team']
    if ($action =~/CLEAR/)	{
        ($subBody,$menu)=handle_clearDollar($db,$action,$target, $escAssocName, $sport, $country);
    }
    elsif ($action =~ /REALM_/) {
        $activetop=0;
        $activetab=0;

        @tabs=(
            ["$target?action=REALM_CONFIG",'Realm Config'],
    #        ["$target?action=REALM_DETAILS",'List of Realms'],
    #        ["$target?action=REALM_ADD",'Add Realm'],
    #        ["$target?action=REALM_SUBADD",'Add Subrealm'],
    #        ["$target?action=REALM_DEFCODES",'Realm Defcodes'],
    #        ["$target?action=REALM_PAYMENT",'Realm Payments'],
        );


        if($action =~ /REALM_CONFIG/ or $action=~/REALM_SC/) {
            $activetab = 0;
            ($subBody, $menu) = handle_system_config($db, $action, $target);
        }
    }

    if(check_access($action)==0) {
        $subBody = '<p align="center">You do not have access for this page.If you feel this may be an error, please contact someone.</p>';
    }
    $subBody=create_tabs($subBody, \@topTabs,\@tabs, $activetop,$activetab, $assocName, $menu);
    $body=$subBody if $subBody;
    disconnectDB($db) if $db;
    print_adminpageGen($body, $title,'');
}

