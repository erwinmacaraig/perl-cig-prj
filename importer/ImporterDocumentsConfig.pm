package ImporterDocumentsConfig;
require Exporter;
@ISA    = qw(Exporter);
@EXPORT = @EXPORT_OK = qw(
    insertConfigRecord
    importDocConfigFile
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

sub importDocConfigFile {
    my ($db, $countOnly, $infile) = @_;
    
    open INFILE, "<$infile" or die "Can't open Input File";

    my $count = 0;
                                                                                                            
    seek(INFILE,0,0);
    $count=0;
    my $insCount=0;
    my $NOTinsCount = 0;

    my %cols = ();
    my $stDEL = "DELETE FROM _tblDocumentConfig";
    my $qDEL= $db->prepare($stDEL) or query_error($stDEL);
    $qDEL->execute();

    while (<INFILE>)	{
        my %parts = ();
        $count ++;
        next if $count == 1;
        chomp;
        my $line=$_;
        $line=~s///g;
        #$line=~s/,/\-/g;
        $line=~s/"//g;
    #	my @fields=split /;/,$line;
        my @fields=split /\t/,$line;

        $parts{'DOC_ID'} = $fields[0] || '';
        $parts{'TYPE'} = $fields[1] || '';
        $parts{'REGONATURE'} = $fields[2] || '';
        $parts{'LEVEL'} = $fields[3] || '';
        $parts{'SPORT'} = $fields[4] || '';
        $parts{'AGE'} = $fields[5] || '';
        $parts{'NATIONALITY_IN'} = $fields[6] || '';
        $parts{'NATIONALITY_NOTIN'} = $fields[7] || '';
        $parts{'REQUIRED'} = $fields[8] || 0;
        $parts{'EXISTING'} = $fields[9] || 0;
        $parts{'FROMAGE'} = $fields[10] || 0;
        $parts{'TOAGE'} = $fields[11] || 0;
        $parts{'INT_TRANSFER_NEW'} = $fields[12] || 0;
        $parts{'INT_LOAN_NEW'} = $fields[13] || 0;
        $parts{'USING_ITC_FILTER'} = $fields[14] || 0;
        $parts{'ITC_FLAG'} = $fields[15] || 0;
        if (! $parts{'DOC_ID'}) { next; }
        if (! $parts{'REGONATURE'}) { next; }
        if ($countOnly)	{
            $insCount++;
            next;
        }

        my $st = qq[
            INSERT INTO _tblDocumentConfig
            (
                strRuleFor,
                strRegistrationNature,
                strPersonType,
                strPersonLevel,
                strPersonEntityRole,
                strSport,
                strAgeLevel,
                strItemType,
                intID,
                intUseExisting,
                intRequired,
                strISOCountry_IN,
                strISOCountry_NOTIN,
                intFilterFromAge,
                intFilterToAge,
                intItemForInternationalTransfer,
                intItemForInternationalLoan,
                intItemUsingITCFilter,
                intItemNeededITC
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
                ?
            )
                
        ];
        my $query = $db->prepare($st) or query_error($st);
        $query->execute(
            'REGO',
            $parts{'REGONATURE'},
            $parts{'TYPE'},
            $parts{'LEVEL'},
            '',
            $parts{'SPORT'},
            $parts{'AGE'},
            'DOCUMENT',
            $parts{'DOC_ID'},
            $parts{'EXISTING'},
            $parts{'REQUIRED'},
            $parts{'NATIONALITY_IN'},
            $parts{'NATIONALITY_NOTIN'},
            $parts{'FROMAGE'},
            $parts{'TOAGE'},
            $parts{'INT_TRANSFER_NEW'},
            $parts{'INT_LOAN_NEW'},
            $parts{'USING_ITC_FILTER'},
            $parts{'ITC_FLAG'}
            
        ) or print "ERROR";
}
$count --;
print STDERR "COUNT CHECK ONLY !!!\n" if $countOnly;

close INFILE;

}
1;
