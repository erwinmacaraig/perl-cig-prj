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
use RegistrationAllowed;
use PersonRegistration;
use Data::Dumper;

main();

sub main	{


	my %Data = ();
	my $db = connectDB();
    my $personID= 10640665;
    my $pRID= 1266;
	$Data{'db'} = $db;
	$Data{'Realm'} = 1;
	$Data{'RealmSubType'} = 0;
    my %Rego=();
    $Rego{'personType'} = 'PLAYER';
    $Rego{'sport'} = 'FUTSAL';
    $Rego{'personLevel'} = 'AMATEUR';
    $Rego{'ageLevel'} = 'SENIOR';
    $Rego{'personEntityRole'} = '';
    $Rego{'entityID'} = 35;
    
   my $ok = checkNewRegoOK(\%Data, $personID, \%Rego);
warn("try1-FAILED") if (!$ok);
warn("try1-OK to insert") if ($ok);
}
