#!/usr/bin/perl

#
# $Header: svn://svn/SWM/trunk/misc/moneylogInsert.pl 8250 2013-04-08 08:24:36Z rlee $
#

use strict;

use lib "..","../web","../web/comp", "../web/user", '../web/RegoForm', "../web/dashboard", "../web/RegoFormBuilder",'../web/PaymentSplit', "../web/NationalNumber", "../web/Reg_Common";

use Defs;
use Utils;
use DBI;
use CGI qw(unescape);
use SystemConfig;
use Reg_common;
use NationalNumber;
use Data::Dumper;

main();

sub main	{


	my %Data = ();
	my $db = connectDB();
	$Data{'db'} = $db;
	$Data{'Realm'} = 1;
	$Data{'RealmSubType'} = 0;
    $Data{'SystemConfig'}=getSystemConfig(\%Data);
    
    my $stPR = qq[
        SELECT
            *
        FROM
            tblPersonRegistration_$Data{'Realm'}
        ORDER BY
            dtFrom
    ];
    
    my %tempClientValues;

    my $qryPR = $db->prepare($stPR);

    $qryPR->execute();

    while (my $dref= $qryPR->fetchrow_hashref())    {
        $tempClientValues{'personID'} = $dref->{'intPersonID'};
        $tempClientValues{'currentLevel'} = $Defs::LEVEL_PERSON;

        my $tempClient = setClient( \%tempClientValues );
        my %clientValues = getClient($tempClient);

        $Data{'clientValues'} = \%clientValues;

        assignNationalNumber(
            \%Data,
            'PERSON',
            $dref->{'intPersonID'},
            $dref->{'intPersonRegistrationID'},
        );
    }

    my $stE = qq[
        SELECT
            *
        FROM
            tblEntity
        WHERE
            strStatus = 'ACTIVE'
        ORDER BY
            tTimeStamp
    ];
 
    my $qryE = $db->prepare($stE);

    $qryE->execute();

    while (my $edref = $qryE->fetchrow_hashref())    {
        my $entityType = "ENTITY";
        my $entityLevel = $edref->{'intEntityLevel'};

        $entityType = "ENTITY" if ($entityLevel == 3);
        $entityType = "FACILITY" if ($entityLevel == -47);

        assignNationalNumber(
            \%Data,
            $entityType,
            $edref->{'intEntityID'},
        );
    }
}
