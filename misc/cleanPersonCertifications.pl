#!/usr/bin/perl

#
# $Header: svn://svn/SWM/trunk/misc/moneylogInsert.pl 8250 2013-04-08 08:24:36Z rlee $
#

use strict;

use lib "..","../web","../web/comp", "../web/user", '../web/RegoForm', "../web/dashboard", "../web/RegoFormBuilder",'../web/PaymentSplit', "../web/Clearances";

use Defs;
use Utils;
use DBI;
use WorkFlow;
use UserObj;
use CGI qw(unescape);
use SystemConfig;
use PersonCertifications;

main();

sub main	{


	my %Data = ();
	my $db = connectDB();
	$Data{'db'} = $db;
	$Data{'Realm'} = 1;
	$Data{'RealmSubType'} = 0;
    $Data{'SystemConfig'}=getSystemConfig(\%Data);
    my $st = qq[
        SELECT DISTINCT intPersonID FROM tblPersonCertifications WHERE intRealmID = ?
    ];
    
    my $qry = $Data{'db'}->prepare($st);
    $qry->execute(
        $Data{'Realm'}
    );
   while(my $dref = $qry->fetchrow_hashref()){
        PersonCertifications::cleanPersonCertifications(\%Data, $dref->{'intPersonID'});
    }
    print "DONE";
}
