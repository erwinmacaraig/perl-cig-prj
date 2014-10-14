#!/usr/bin/perl

use strict;

use lib "..","../web","../web/EmailNotifications","../web/comp", "../web/user", '../web/RegoForm', "../web/dashboard", "../web/RegoFormBuilder",'../web/PaymentSplit', "../web/Clearances";

use Defs;
use Utils;
use DBI;
use Lang;
#use WorkFlow;
#use UserObj;
#use CGI qw(unescape);
#use RegistrationAllowed;
#use PersonRegistration;
use Data::Dumper;

use EmailNotifications::Notification;
#use EmailNotifications::PersonRequest;

main();

sub main	{
	my %Data = ();
	my $db = connectDB();
    my $lang = Lang->get_handle() || die "Can't get a language handle!";
    #print STDERR Dumper $lang;
	$Data{'db'} = $db;
	$Data{'Realm'} = 1;
	$Data{'RealmSubType'} = 0;

    my $notification = new EmailNotifications::Notification(
        'realmID' => 1,
        'subRealmID' => 0,
        'fromEntityID' => 1,
        'toEntityID' => 35,
        'notificationType' => $Defs::NOTIFICATION_WFTASK_ADDED,
        'dbh' => $db,
        'subject' => "test"
    );

    $notification->retrieve()->build();
    #$notification->initialise();
    #$notification->setRealmID(3);
    #print STDERR Dumper $notification->getDbh();
}
