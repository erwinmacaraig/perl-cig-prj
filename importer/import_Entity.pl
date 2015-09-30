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
    my $infile1='Club.csv';

    importEntityFile($db, $countOnly, 'CLUB', $infile1);

}

