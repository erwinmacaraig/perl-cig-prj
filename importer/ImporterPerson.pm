package ImporterPerson;
require Exporter;
@ISA    = qw(Exporter);
@EXPORT = @EXPORT_OK = qw(
    insertPersonRecord
    importPersonFile
);

use strict;
use lib "..","../web","../web/comp", "../web/user", '../web/RegoForm', "../web/dashboard", "../web/RegoFormBuilder",'../web/PaymentSplit', "../web/Clearances";

use Defs;
use DBI;
use Utils;
use ConfigOptions qw(ProcessPermissions);
use SystemConfig;
use CGI qw(cookie unescape);
use ImporterCommon;

use Log;
use Data::Dumper;

############
#
# COMMENTS:
#
############

sub insertPersonRecord {
    my ($db) = @_;

    my $maCode = getImportMACode($db) || '';

    my $stINS = qq[
        INSERT INTO tblPerson (
            intRealmID,
            dtAdded,
            dtApproved,
            dtLastUpdated,
            strImportPersonCode,
        )
        VALUES (
            1,
            NOW(),
            NOW(),
            NOW(),
            ?,
        )
    ];
    my $qryINS= $db->prepare($stINS) or query_error($stINS);

    my $st = qq[
        SELECT * FROM tmpPersonRego
    ];
    my $qry = $db->prepare($st) or query_error($st);
    $qry->execute();
    while (my $dref= $qry->fetchrow_hashref())    {
        next if (! $dref->{'intPersonID'} or ! $dref->{'intEntityID'} or ! $dref->{'intNationalPeriodID'});

        my $dtFrom = $dref->{'dtFrom'};
        my $dtTo   = $dref->{'dtTo'};
        my $status = $dref->{'strStatus'};

        if ($maCode eq 'HKG')   {
            ## Config here for HKG
        }
        else    {
            ## Finland at moment
        }

        
        $qryINS->execute(
            $dref->{'intID'},
            $status,
        );
        my $ID = $qryINS->{mysql_insertid} || 0;
    }
}

sub importPersonFile  {
    my ($db, $countOnly, $type, $infile) = @_;
    
    my $maCode = getImportMACode($db) || '';

open INFILE, "<$infile" or die "Can't open Input File";

my $count = 0;
                                                                                                        
seek(INFILE,0,0);
$count=0;
my $insCount=0;
my $NOTinsCount = 0;

my %cols = ();
my $stDEL = "DELETE FROM tmpPerson WHERE strFileType = ?";
my $qDEL= $db->prepare($stDEL) or query_error($stDEL);
$qDEL->execute($type);

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

    if ($maCode eq 'HKG')   {
        ## Update field mapping for HKG 
    }
    else    {
        ## Finland at moment
    	$parts{'PERSONCODE'} = $fields[0] || '';
	    $parts{'STATUS'} = $fields[2] || '';
	    $parts{'REGNATURE'} = $fields[3] || '';
	    $parts{'PERSONTYPE'} = $fields[4] || '';
	    $parts{'PERSONROLE'} = $fields[5] || '';
	    $parts{'PERSONLEVEL'} = $fields[6] || '';
	    $parts{'SPORT'} = $fields[7] || '';
	    $parts{'AGELEVEL'} = $fields[8] || '';
	    $parts{'DOB'} = $fields[9] || '0000-00-00';
	    $parts{'ISLOAN'} = $fields[12] || '';
	    $parts{'NATIONALPERIOD'} = $fields[13] || '';
	    $parts{'PRODUCTCODE'} = $fields[14] || '';
	    $parts{'PRODUCTAMOUNT'} = $fields[15] || 0;
	    $parts{'ISPAID'} = $fields[16] || '';
	    $parts{'TRANSACTIONNO'} = $fields[17] || '';
        
    }
	if ($countOnly)	{
		$insCount++;
		next;
	}

	my $st = qq[
		INSERT INTO tmpPerson
		(strFileType, strPersonCode, )
        VALUES (?,?,)
	];
	my $query = $db->prepare($st) or query_error($st);
 	$query->execute(
        $type,
        $parts{'PERSONCODE'},
    ) or print "ERROR";
}
$count --;
print STDERR "COUNT CHECK ONLY !!!\n" if $countOnly;

close INFILE;

}
1;
