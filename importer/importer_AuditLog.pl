#!/usr/bin/perl

#
# $Header: svn://svn/SWM/trunk/misc/moneylogInsert.pl 8250 2013-04-08 08:24:36Z rlee $
#

use strict;

use lib "..","../web","../web/comp", "../web/user", '../web/RegoForm', "../web/dashboard", "../web/RegoFormBuilder",'../web/PaymentSplit', "../web/Clearances";

use Defs;
use Utils;
use DBI;
use CGI qw(unescape);
use SystemConfig;
use AuditLog;

main();

sub main	{


	my %Data = ();
	my $db = connectDB();
	$Data{'db'} = $db;
	$Data{'Realm'} = 1;
	$Data{'RealmSubType'} = 0;
	$Data{'UserName'} = "Importer";
    $Data{'SystemConfig'}=getSystemConfig(\%Data);
    $Data{'clientValues'}{'currentLevel'} = 1;
    $Data{'clientValues'}{'authLevel'} = 100;
    
    my $st = qq[
        SELECT intPersonID FROM tblPerson WHERE intRealmID=?
    ];
    my $qry= $db->prepare($st);
    $qry->execute($Data{'Realm'}); 
    while (my $dref= $qry->fetchrow_hashref()) {
        auditLog($dref->{'intPersonID'}, \%Data, 'Person Imported', 'Person');
    }

    my $st = qq[
        SELECT intPersonRegistrationID FROM tblPersonRegistration_$Data{'Realm'}
    ];
    my $qry= $db->prepare($st);
    $qry->execute(); 
    while (my $dref= $qry->fetchrow_hashref()) {
        auditLog($dref->{'intPersonRegistrationID'}, \%Data, 'Person Registration Imported', 'Person Registration');
    }

    my $st = qq[
        SELECT intEntityID FROM tblEntity WHERE intRealmID=?
    ];
    my $qry= $db->prepare($st);
    $qry->execute($Data{'Realm'}); 
    while (my $dref= $qry->fetchrow_hashref()) {
        auditLog($dref->{'intEntityID'}, \%Data, 'Imported', 'Entity');
    }




}
