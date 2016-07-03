#!/usr/bin/perl -w

#
# $Header: svn://svn/SWM/trunk/misc/import_bowls_clubs.pl 9483 2013-09-10 04:48:08Z tcourt $
#

use lib "..","../web","../web/comp", "../web/user", '../web/RegoForm', "../web/dashboard", "../web/RegoFormBuilder",'../web/PaymentSplit', "../web/Clearances";

use strict;
use Defs;
use Utils;
use DBI;
use CGI qw(unescape);
use SystemConfig;
use ImporterPersonRego;
use ImporterCommon;
use Switch;

main();
1;

sub main	{
    my $db=connectDB();

    my $maCode = getImportMACode($db) || '';
    switch($maCode) {
        case 'FAF' {
            linkPRPeople($db);
            linkPRClubs($db);
            linkPRNationalPeriods($db);
            linkPRProducts($db);
        }
        case 'HKG' {
            linkPRPeople($db);
            linkPRClubs($db);
        }
        case 'AZE' {
            linkPRPeople($db);
            linkPRClubs($db);
            linkPRNationalPeriods($db);
            linkEntityTypeRoles($db);
        }
        else {
            linkPRPeople($db);
            linkPRClubs($db);
            linkPRNationalPeriods($db);
            linkPRProducts($db);
        }
    }
}
