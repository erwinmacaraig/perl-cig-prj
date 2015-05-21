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
use ImporterTXNs;
                                                                                                    
main();
1;

sub main	{
my $db=connectDB();
#print STDERR "LIB, FILE NAME etc\n";
#exit;
#### SETTINGS #############
my $countOnly=0;
my $infile='InsurancePayment.csv';
###########################
importFile($db, $countOnly, 'INSURANCE', $infile);
linkPeople($db);
linkProducts($db);
linkNationalPeriod($db);
linkPersonRego($db);
createTXNRecords($db);
}

sub linkPersonRego {
    my ($db) = @_;
    
    my $st = qq[
        UPDATE tmpTXNs as T
            INNER JOIN tblPersonRegistration_1 as PR ON (
                PR.intPersonID = T.intPersonID
                AND PR.strPersonType = 'PLAYER'
                AND PR.intNationalPeriodID = T.intNationalPeriodID
            )
        SET 
            T.intPersonRegistrationID = PR.intPersonRegistrationID, 
            T.intEntityID = PR.intEntityID
    ];
    $db->do($st);
}
    
sub createTXNRecords    {
    my ($db) = @_;

    my $st = qq[
        SELECT * FROM tmpTXNs
        WHERE intPersonID>0 AND intProductID>0
            AND strPaid = 'YES'
    ];

	my $qry = $db->prepare($st) or query_error($st);
 	$qry->execute();
    while (my $dref= $qry->fetchrow_hashref())    {
        importTXN($db, $dref->{'intPersonID'}, $dref->{'intPersonRegistrationID'}, $dref->{'intEntityID'}, $dref->{'intProductID'}, $dref->{'curProductAmount'}, $dref->{'dtPaid'}, $dref->{'strTransactionNo'}, 1, 0);        
    }
}

sub linkNationalPeriod{
    my ($db) = @_;
    my $st = qq[
        UPDATE tmpTXNs as TL 
            INNER JOIN tblNationalPeriod as NP ON (TL.strNationalPeriod = strImportPeriodCode)
        SET TL.intNationalPeriodID = NP.intNationalPeriodID
        WHERE strImportPeriodCode <> ''
    ];
    $db->do($st);
}


sub linkProducts {
    my ($db) = @_;
    my $st = qq[
        UPDATE tmpTXNs as TL 
            INNER JOIN tblProducts as P ON (TL.strProductCode = P.strProductCode)
        SET TL.intProductID= P.intProductID
        WHERE P.strProductCode <> ''
    ];
    $db->do($st);
}


sub linkPeople  {
    my ($db) = @_;
    my $st = qq[
        UPDATE tmpTXNs as TL 
            INNER JOIN tblPerson as P ON (TL.strPersonCode = P.strImportPersonCode)
        SET TL.intPersonID = P.intPersonID
        WHERE P.strImportPersonCode<> ''
    ];
    $db->do($st);
}

sub importFile  {
    my ($db, $countOnly, $type, $infile) = @_;

open INFILE, "<$infile" or die "Can't open Input File";

my $count = 0;
                                                                                                        
seek(INFILE,0,0);
$count=0;
my $insCount=0;
my $NOTinsCount = 0;

my %cols = ();
my $st = "DELETE FROM tmpTXNs";
$db->do($st);

while (<INFILE>)	{
	my %parts = ();
	$count ++;
    if ($count==1)  {
       print "HEADERS"; 
    }
	next if $count == 1;
	chomp;
	my $line=$_;
	$line=~s///g;
	#$line=~s/,/\-/g;
	$line=~s/"//g;
	my @fields=split /;/,$line;

#InsurancePayments
#PersonCode  NationalSeason  ProductCode Amount  IsPaid  PaymentReference    PaymentDate
	$parts{'PERSONCODE'} = $fields[0] || '';
	$parts{'NATIONALSEASON'} = $fields[1] || '';
	$parts{'PRODUCTCODE'} = $fields[2] || '';
	$parts{'PRODUCTAMOUNT'} = $fields[3] || 0;
	$parts{'ISPAID'} = $fields[4] || '';
	$parts{'PAYMENTREF'} = $fields[5] || '';
	$parts{'DTPAID'} = $fields[6] || '';
        
	if ($countOnly)	{
		$insCount++;
		next;
	}

	my $st = qq[
		INSERT INTO tmpTXNs
		(strRecordType, strPersonCode, strNationalPeriod, strProductCode, curProductAmount, strPaid, strTransactionNo, dtPaid)
        VALUES (?,?,?,?,?,?,?,?)
	];
	my $query = $db->prepare($st) or query_error($st);
 	$query->execute(
        $type,
        $parts{'PERSONCODE'},
        $parts{'NATIONALSEASON'},
        $parts{'PRODUCTCODE'},
        $parts{'PRODUCTAMOUNT'},
        $parts{'ISPAID'},
        $parts{'PAYMENTREF'},
        $parts{'DTPAID'}
    ) or print "ERROR";
}
$count --;
print STDERR "COUNT CHECK ONLY !!!\n" if $countOnly;

close INFILE;

}
1;
