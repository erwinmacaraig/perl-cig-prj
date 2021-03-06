package ImporterExtraPayments;
require Exporter;
@ISA    = qw(Exporter);
@EXPORT = @EXPORT_OK = qw(
    linkEPPersonRego
    createEPTXNRecords
    linkEPNationalPeriod
    linkEPProducts
    linkEPPeople
    importEPFile
);

use strict;
use lib "..","../web","../web/comp", "../web/user", '../web/RegoForm', "../web/dashboard", "../web/RegoFormBuilder",'../web/PaymentSplit', "../web/Clearances";

use Defs;
use DBI;
use Utils;
use ConfigOptions qw(ProcessPermissions);
use SystemConfig;
use CGI qw(cookie unescape);
use ImporterTXNs;

use Log;
use Data::Dumper;

sub linkEPPersonRego {
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
    
sub createEPTXNRecords    {
    my ($db) = @_;

    my $st = qq[
        SELECT * FROM tmpTXNs
        WHERE intPersonID>0 AND intProductID>0
    ];

	my $qry = $db->prepare($st) or query_error($st);
 	$qry->execute();
    while (my $dref= $qry->fetchrow_hashref())    {
        my $status = 0;
        $status = 1 if ($dref->{'strPaid'} eq 'YES');
        importTXN($db, $dref->{'intPersonID'}, $dref->{'intPersonRegistrationID'}, $dref->{'intEntityID'}, $dref->{'intProductID'}, $dref->{'curProductAmount'}, $dref->{'dtPaid'}, $dref->{'strTransactionNo'}, $status, 0);        
    }
}

sub linkEPNationalPeriod{
    my ($db) = @_;
    my $st = qq[
        UPDATE tmpTXNs as TL 
            INNER JOIN tblNationalPeriod as NP ON (TL.strNationalPeriod = strImportPeriodCode)
        SET TL.intNationalPeriodID = NP.intNationalPeriodID
        WHERE strImportPeriodCode <> ''
    ];
    $db->do($st);
}


sub linkEPProducts {
    my ($db) = @_;
    my $st = qq[
        UPDATE tmpTXNs as TL 
            INNER JOIN tblProducts as P ON (TL.strProductCode = P.strProductCode)
        SET TL.intProductID= P.intProductID
        WHERE P.strProductCode <> ''
    ];
    $db->do($st);
}


sub linkEPPeople  {
    my ($db) = @_;
    my $st = qq[
        UPDATE tmpTXNs as TL 
            INNER JOIN tblPerson as P ON (TL.strPersonCode = P.strImportPersonCode)
        SET TL.intPersonID = P.intPersonID
        WHERE P.strImportPersonCode<> ''
    ];
    $db->do($st);
}

sub importEPFile  {
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
