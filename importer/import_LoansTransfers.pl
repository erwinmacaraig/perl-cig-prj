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
                                                                                                    
main();
1;

sub main	{
my $db=connectDB();
#print STDERR "LIB, FILE NAME etc\n";
#exit;
#### SETTINGS #############
my $countOnly=0;
my $infileLoans='Loans.csv';
my $infileTransfers='Transfers.csv';
###########################
importFile($db, $countOnly, 'LOAN', $infileLoans);
#importFile($db, $countOnly, 'TRANSFER', $infileTransfers);
linkPeople($db);
linkClubs($db);
linkProducts($db);

#Need to link intFromPersonRegoID and intToPersonRegoID rego records to be able to close off loan
# Need to set intOnLoan and intIsLoanedOut to appropriate records
}
sub linkProducts {
    my ($db) = @_;
    my $st = qq[
        UPDATE tmpLoansTransfers as TL 
            INNER JOIN tblProducts as P ON (TL.strProductCode = P.strProductCode)
        SET TL.intProductID= P.intProductID
        WHERE P.strProductCode <> ''
    ];
    $db->do($st);
}


sub linkPeople  {
    my ($db) = @_;
    my $st = qq[
        UPDATE tmpLoansTransfers as TL 
            INNER JOIN tblPerson as P ON (TL.strPersonCode = P.strImportPersonCode)
        SET TL.intPersonID = P.intPersonID
        WHERE P.strImportPersonCode<> ''
    ];
    $db->do($st);
}

sub linkClubs {
    my ($db) = @_;
    my $st = qq[
        UPDATE tmpLoansTransfers as TL 
            INNER JOIN tblEntity as E ON (TL.strClubCodeFrom= E.strImportEntityCode)
        SET TL.intEntityFromID= E.intEntityID
        WHERE E.strImportEntityCode <> ''
    ];
    $db->do($st);

    $st = qq[
        UPDATE tmpLoansTransfers as TL 
            INNER JOIN tblEntity as E ON (TL.strClubCodeTo= E.strImportEntityCode)
        SET TL.intEntityToID= E.intEntityID
        WHERE E.strImportEntityCode <> ''
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
my $st = "DELETE FROM tmpLoansTransfers";
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
#Transfers:
#PersonCode;ClubFrom;ClubCodeTo;DateApplied;DateApproved;Sport;PersonLevel;ProductCode;ProductAmount;Paid;TransactionNo;ApprovedBy
#Loans:
#PersonCode;ClubCodeFrom;ClubCodeTo;DateCommenced;DateExpiry;Sport;Personlevel;Status;ProductCode;ProductAmount;Paid;TransactionNo;ApprovedBy

	$parts{'PERSONCODE'} = $fields[0] || '';
	$parts{'CLUBFROM'} = $fields[1] || '';
	$parts{'CLUBTO'} = $fields[2] || '';
    if ($type eq 'LOAN')    {
	    $parts{'DATECOMMENCED'} = $fields[3] || '0000-00-00';
	    $parts{'DATEEXPIRY'} = $fields[4] || '0000-00-00';
	    $parts{'DATEAPPLIED'} = '0000-00-00';
	    $parts{'DATEAPPROVED'} = '0000-00-00';
    }
    if ($type eq 'TRANSFER')    {
	    $parts{'DATEAPPLIED'} = $fields[3] || '0000-00-00';
	    $parts{'DATEAPPROVED'} = $fields[4] || '0000-00-00';
	    $parts{'DATECOMMENCED'} = '0000-00-00';
	    $parts{'DATEEXPIRY'} = '0000-00-00';
    }
	$parts{'SPORT'} = $fields[5] || '';
	$parts{'PERSONLEVEL'} = $fields[6] || '';
    if ($type eq 'LOAN')    {
	    $parts{'STATUS'} = $fields[7] || '';
	    $parts{'PRODUCTCODE'} = $fields[8] || '';
	    $parts{'PRODUCTAMOUNT'} = $fields[9] || 0;
	    $parts{'ISPAID'} = $fields[10] || '';
	    $parts{'TRANSACTIONNO'} = $fields[11] || '';
	    $parts{'APPROVEDBY'} = $fields[11] || '';
    }

    if ($type eq 'TRANSFER')    {
	    $parts{'STATUS'} = '';
	    $parts{'PRODUCTCODE'} = $fields[7] || '';
	    $parts{'PRODUCTAMOUNT'} = $fields[8] || 0;
	    $parts{'ISPAID'} = $fields[9] || '';
	    $parts{'TRANSACTIONNO'} = $fields[10] || '';
	    $parts{'APPROVEDBY'} = $fields[11] || '';
    }
        
	if ($countOnly)	{
		$insCount++;
		next;
	}

	my $st = qq[
		INSERT INTO tmpLoansTransfers
		(strRecordType, strPersonCode, strClubCodeFrom, strClubCodeTo, dtApplied, dtApproved, dtCommenced, dtExpiry, strSport, strPersonLevel, strStatus, strProductCode, curProductAmount, strPaid, strTransactionNo, strApprovedBy)
        VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
	];
	my $query = $db->prepare($st) or query_error($st);
 	$query->execute(
        $type,
        $parts{'PERSONCODE'},
        $parts{'CLUBFROM'},
        $parts{'CLUBTO'},
        $parts{'DATEAPPLIED'},
        $parts{'DATEAPPROVED'},
        $parts{'DATECOMMENCED'},
        $parts{'DATEEXPIRY'},
        $parts{'SPORT'},
        $parts{'PERSONLEVEL'},
        $parts{'STATUS'},
        $parts{'PRODUCTCODE'},
        $parts{'PRODUCTAMOUNT'},
        $parts{'ISPAID'},
        $parts{'TRANSACTIONNO'},
        $parts{'APPROVEDBY'}
    ) or print "ERROR";
}
$count --;
print STDERR "COUNT CHECK ONLY !!!\n" if $countOnly;

close INFILE;

}
1;
