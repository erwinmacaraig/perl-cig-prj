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
use ImporterPerson;
                                                                                                    
main();
1;

sub main	{
    my $db=connectDB();
    my $countOnly=0;
    my $infile1='GHA_TEST_people.txt';

    importPersonFile($db, $countOnly, 'PEOPLE', $infile1);

}

