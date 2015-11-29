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
use ImporterDocuments;
                                                                                                    
main();
1;

sub main	{
    my $db=connectDB();
    my $countOnly=0;
    my $infile1='Picture_csv.csv';
    my $infile2='Other_csv.csv';

    importPhotoDocumentFile($db, $countOnly, 'PHOTO', $infile1);
    importOtherDocumentFile($db, $countOnly, 'OTHER', $infile2);

}

