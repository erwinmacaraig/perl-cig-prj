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
use Data::Dumper;
                                                                                                    
main();
1;

sub main	{
    my $db=connectDB();
    my $countOnly=0;
    my $maCode = getImportMACode($db) || '';
    my $infile1;

    switch($maCode) {
        case 'FAF' {
            $infile1 = 'PeopleRegistrationsCombined.csv';
        }
        case 'HKG' {
            $infile1 = 'tblPersonRegistration2.txt';
        }
        case 'AZE' {
            $infile1 = 'AFFA_Import_Registration.txt';
        }
        else {
            $infile1 = 'GHA_TEST_regos.txt';
        }
    }

    importPRFile($db, $countOnly, 'COMBINED', $infile1);

}

