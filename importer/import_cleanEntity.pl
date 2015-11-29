#!/usr/bin/perl -w

use lib "..","../web","../web/comp", "../web/user", '../web/RegoForm', "../web/dashboard", "../web/RegoFormBuilder",'../web/PaymentSplit', "../web/Clearances";

use strict;
use Defs;
use Utils;
use DBI;
use CGI qw(unescape);
use SystemConfig;
use ImporterEntity;
use ImporterCommon;
use Switch;

main();
1;

sub main	{
    my $db=connectDB();

    my $maCode = getImportMACode($db) || '';
    switch($maCode) {
        case 'FAF' {
            #linkPRPeople($db);
            #linkPRClubs($db);
            #linkPRNationalPeriods($db);
            #linkPRProducts($db);
        }
        case 'HKG' {
            #linkPRPeople($db);
            #linkPRClubs($db);
        }
        else {
            #linkPRPeople($db);
            #linkPRClubs($db);
            #linkPRNationalPeriods($db);
            #linkPRProducts($db);
        }
    }
}
