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
use PlayerPassport;
use SystemConfig;
use Data::Dumper;

main();

sub main	{


	my %Data = ();
	my $db = connectDB();
	$Data{'db'} = $db;
	$Data{'Realm'} = 1;
	$Data{'RealmSubType'} = 0;
    $Data{'SystemConfig'}=getSystemConfig(\%Data);
    
    my @dbFields = qw(strISOCountryOfBirth strISOCountry strISOMotherCountry strISOFatherCountry);

    my %Countries = ();
## Jervy, as we look at the Data after 1st run, we will update below hash
    $Countries{'SGP'} = 'SG';

    for my $field (@dbFields)   {
        my $st = qq[
            UPDATE tblPerson SET $field=? WHERE $field=? AND intRealmID=?
        ];
        my $qryField= $db->prepare($st);
        foreach my $key (keys %Countries)   {
            $qryField->execute($Countries{$key}, $key, $Data{'Realm'}); 
        }
    }
}
