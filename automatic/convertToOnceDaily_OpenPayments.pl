#!/usr/bin/perl -w

#
# $Header: svn://svn/SWM/trunk/web/nabprocess.cgi 8249 2013-04-08 08:14:07Z rlee $
#

use lib '.', '..', "../web", "../web/user", "../web/PaymentSplit", "../web/RegoForm", "../web/dashboard", "../web/RegoFormBuilder","../web/user", "../web/Clearances", "../web/registration", "../web/registration/user";
use DBI;
use CGI qw(:cgi escape unescape);

use strict;

use Lang;
use Utils;
use SystemConfig;
use ConfigOptions;
use Reg_common;
use PageMain;
use CGI qw(param unescape escape);

use ExternalGateway;
use Data::Dumper;
use Localisation;

use Digest::SHA qw(hmac_sha256_hex);
use XML::Simple;


main();

sub main	{

    ## Need one of these PER gateway
print STDERR "IN convertToOnceDaily_OpenPayments\n";

    my $db=connectDB();
    my %Data=();
    $Data{'db'}=$db;
    $Data{'Realm'} = 1;
    $Data{'SystemConfig'}=getSystemConfig(\%Data);

    my $numberDays = $Data{'SystemConfig'}{'PaymentCheck_ToDailyNumDays'} || 15;

    my $st = qq[
        SELECT DISTINCT
            TL.intLogID
        FROM
            tblTransLog as TL
            INNER JOIN tblPaymentConfig as PC ON (PC.intPaymentConfigID = TL.intPaymentConfigID)
	    INNER JOIN tblPayTry as PT ON (PT.intTransLogID = TL.intLogID)
        WHERE
            TL.intStatus IN (0,3)
            AND PC.strGatewayCode = 'checkoutfi'
    		AND  TL.intSentToGateway = 1 
            AND TL.intPaymentGatewayResponded = 0
            AND NOW() >= DATE_ADD(PT.dtTry, INTERVAL $numberDays day)
            AND TL.intCheckOnceDaily = 0
    ];
    my $query = $db->prepare($st);
    $query->execute();
    my $stUPD = qq[
        UPDATE 
            tblTransLog 
        SET intCheckOnceDaily = 1 
        WHERE 
            intLogID = ? 
        LIMIT 1
    ];
    my $qryUPD = $db->prepare($stUPD);

    while (my $dref = $query->fetchrow_hashref())   {
        $qryUPD->execute($dref->{'intLogID'});
    }
}

1;
