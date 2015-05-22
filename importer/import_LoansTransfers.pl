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
my $countOnly=0;
my $infileLoans='Loans.csv';
my $infileTransfers='Transfers.csv';
importFile($db, $countOnly, 'LOAN', $infileLoans);
#importFile($db, $countOnly, 'TRANSFER', $infileTransfers);


linkPeople($db);
linkClubs($db);
linkProducts($db);
linkLOANBorrowingPR($db);
linkLOANLendingPR($db);

insertLOANPersonRequestRecord($db);
insertTransactions($db);
}

sub insertTransactions  {
    my ($db) = @_;

    my $st = qq[
        SELECT * FROM tmpLoansTransfers
        WHERE       
            intPersonID>0 
            AND intProductID >0 
            AND intEntityToID > 0
            AND strRecordType = 'LOAN'
            AND strPaid = 'YES'
    ];
    my $qry = $db->prepare($st) or query_error($st);
    $qry->execute();
    while (my $dref= $qry->fetchrow_hashref())    {
        importTXN($db, $dref->{'intPersonID'}, $dref->{'intToPersonRegoID'}, $dref->{'intEntityToID'}, $dref->{'intProductID'}, $dref->{'curProductAmount'}, $dref->{'dtCommenced'}, $dref->{'strTransactionNo'}, 1, 0);
    }
    
}
sub insertLOANPersonRequestRecord   {
    my ($db) = @_;

    my $stINS = qq[
        INSERT INTO tblPersonRequest (
            strRequestType,
            intPersonID,
            intExistingPersonRegistrationID,
            strSport,
            strPersonType,
            strPersonLevel,
            strNewPersonLevel,
            strPersonEntityRole,
            intRealmID,
            intRequestFromEntityID,
            intRequestToEntityID,
            intRequestToMAOverride,
            intParentMAEntityID,
            strRequestNotes,
            dtDateRequest,
            strRequestResponse,
            strResponseNotes,
            intResponseBy,
            strRequestStatus,
            dtLoanFrom,
            dtLoanTo,
            intOpenLoan,
            strTMSReference,
            NOW()    
        )
        VALUES (
            ?,
            ?,
            ?,
            ?,  
            ?,
            ?,
            ?,
            ?,
            1,
            ?,
            ?,
            ?,
            ?,
            ?,
            ?,
            ?,  
            ?,
            ?,
            ?,
            ?,
            ?,
            ?,
            ?,
        )
    ];
    my $qryINS= $db->prepare($stINS) or query_error($stINS);

    my $st = qq[
        SELECT * FROM tmpLoansTransfers
        WHERE       
            intPersonID>0 
            AND intEntityToID > 0
            AND (
                intToPersonRegoID > 0 OR intFromPersonRegoID > 0
            )
            AND strRecordType = 'LOAN'
            AND strStatus = 'APPROVED' 
    ];
    ## We only bring in the OPEN "APPROVED" ie: NOT "FINISHED" loans
    my $qry = $db->prepare($st) or query_error($st);
    $qry->execute();
    while (my $dref= $qry->fetchrow_hashref())    {
        my $status = 'COMPLETED';
        my $openLoan = 0;
        if ($dref->{'strStatus'} eq 'APPROVED')   {
            $status = 'ACTIVE';
            $openLoan = 1;
        }
        
        $qryINS->execute(
            'LOAN',
            $dref->{'intPersonID'},
            $dref->{'intFromPersonRegoID'},
            $dref->{'strSport'},
            'PLAYER',
            $dref->{'strPersonLevel'},
            $dref->{'strPersonLevel'},
            '',
            $dref->{'intEntityToID'},  # The TO entity is the FROM in Request table
            $dref->{'intEntityFromID'},
            0,
            0, #??
            '',
            '0000-00-00',
            'COMPLETED',
            '',
            0,
            $status,
            $dref->{'dtCommenced'},
            $dref->{'dtExpiry'},
            $openLoan,
        );
        my $ID = $qryINS->{mysql_insertid} || 0;
        if ($ID and $dref->{'intToPersonRegoID'})   {
            my $stUPD = qq[
                UPDATE tblPersonRegistration_1
                SET intPersonRequestID = ?, strStatus = IF(dtFrom < NOW() and dtTo>NOW(), 'ACTIVE', 'PASSIVE')
                WHERE intPersonRegistrationID = ?
            ];
            my $qryUPD = $db->prepare($stUPD) or query_error($stUPD);
            $qryUPD->execute($dref->{'intToPersonRegoID'});
        }
    }
}
 


sub linkLOANBorrowingPR{
    my ($db) = @_;

    my $st = qq[
        SELECT * FROM tmpLoansTransfers
        WHERE intPersonID>0 and intEntityToID > 0
    ];
    my $stUPDtmp = qq[
        UPDATE tmpLoansTransfers
        SET intToPersonRegoID = ?
        WHERE intID = ?
    ];
    my $qryUPDtmp = $db->prepare($stUPDtmp) or query_error($stUPDtmp);

    my $qry = $db->prepare($st) or query_error($st);
    $qry->execute();
    while (my $dref= $qry->fetchrow_hashref())    {

        my $stTO = qq[
            SELECT *
            TO tblPersonRegistration_1
            WHERE
                intPersonID = ?
                AND intOnLoan=1
                AND strPersonType='PLAYER'
                AND strSport = ?
                AND strPersonLevel = ?
                AND dtFrom = ?
                AND dtTo = ?
                AND intEntityID = ?
            LIMIT 1
        ];
        my $qryTO = $db->prepare($stTO) or query_error($stTO);
        $qryTO->execute(
            $dref->{'intPersonID'},
            $dref->{'strSport'},
            $dref->{'strPersonLevel'},
            $dref->{'dtCommenced'},
            $dref->{'dtExpiry'},
            $dref->{'intEntityFromID'},
        );
        my $TOref= $qryTO->fetchrow_hashref();
        if ($TOref->{'intPersonRegistrationID'})  {
            $qryUPDtmp->execute($TOref->{'intPersonRegistrationID'}, $dref->{'intID'});
        }
    }

}

sub linkLOANLendingPR {
    my ($db) = @_;

     my $st = qq[
        SELECT * FROM tmpLoansTransfers
        WHERE intPersonID>0 and intEntityFromID > 0
    ];
    my $stUPDtmp = qq[
        UPDATE tmpLoansTransfers
        SET intFromPersonRegoID = ?
        WHERE intID = ?
    ];
    my $qryUPDtmp = $db->prepare($stUPDtmp) or query_error($stUPDtmp);

    my $stPRFROM= qq[
        UPDATE tblPersonRegistration_1
        SET intIsLoanedOut = 1
        WHERE intPersonRegistrationID = ?
    ];
    my $qryPRFROM= $db->prepare($stPRFROM) or query_error($stPRFROM);

    my $qry = $db->prepare($st) or query_error($st);
    $qry->execute();
    while (my $dref= $qry->fetchrow_hashref())    {

        my $stFROM = qq[
            SELECT *
            FROM tblPersonRegistration_1
            WHERE
                intPersonID = ?
                AND strPersonType='PLAYER'
                AND strSport = ?
                AND strPersonLevel = ?
                AND intEntityID = ?
                AND dtFrom < ?
            ORDER BY dtFrom DESC
            LIMIT 1
        ];
        my $qryFROM = $db->prepare($stFROM) or query_error($stFROM);
        $qryFROM->execute(
            $dref->{'intPersonID'},
            $dref->{'strSport'},
            $dref->{'strPersonLevel'},
            $dref->{'intEntityFromID'},
            $dref->{'dtCommenced'}
        );
        my $FROMref= $qryFROM->fetchrow_hashref();
        if ($FROMref->{'intPersonRegistrationID'})  {
            $qryUPDtmp->execute($FROMref->{'intPersonRegistrationID'}, $dref->{'intID'});
            $qryPRFROM->execute($FROMref->{'intPersonRegistrationID'});
        }
    }

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
