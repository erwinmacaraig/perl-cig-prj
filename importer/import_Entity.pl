#!/usr/bin/perl -w

use lib "..","../web","../web/comp", "../web/user", '../web/RegoForm', "../web/dashboard", "../web/RegoFormBuilder",'../web/PaymentSplit', "../web/Clearances";

use strict;
use Defs;
use Utils;
use DBI;
use CGI qw(unescape);
use SystemConfig;
use ImporterEntity;
                                                                                                    
main();
1;

sub main	{
    my $db=connectDB();
    my $countOnly=0;

    switch($maCode) {
        case 'FAF' {
            $infile1 = '';
        }
        case 'HKG' {
            $infile1 = '';
        }
        case 'AZE' {
            $infile1 = 'AFFA_ORGANISATIONS_2016_11_06.txt';
        }
        else {
            $infile1 = 'GHA_TEST_clubs.txt';
        }
    }



    importEntityFile($db, $countOnly, 'CLUB', $infile1);

}

