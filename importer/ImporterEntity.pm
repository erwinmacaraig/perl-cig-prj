package ImporterEntity;
require Exporter;
@ISA    = qw(Exporter);
@EXPORT = @EXPORT_OK = qw(
    insertEntityRecord
    importEntityFile
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

sub insertEntityRecord {
    my ($db, $type) = @_;

    my $maCode = getImportMACode($db) || '';

    my $stINS = qq[
        INSERT INTO tblEntity (
            intRealmID,
            intEntityLevel,
            strImportEntityCode,
            strNationalNum,
            strStatus,
            strLocalName,
            intLocalLanguage,
            strLatinName,
            strISOCountry,
            strFax,
            strPhoneHome,
            strAddress1,
            strAddress2,
            strPostalCode,
            strSuburb,
            strEmail,
            strOtherPersonIdentifier,
            intOtherPersonIdentifierTypeID,
            strOtherPersonIdentifierIssueCountry,
            dtOtherPersonIdentifierValidDateFrom,
            dtOtherPersonIdentifierValidDateTo
        )
        VALUES (
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
            ?,
            ?,
            ?,
            ?,
            ?,
            ?
        )
    ];
    my $qryINS= $db->prepare($stINS) or query_error($stINS);

    my $stELINS = qq[
        INSERT INTO tblEntityLinks (
            intParentEntityID,
            intChildEntityID,
            intPrimary,
            intImportID
        )
        VALUES (
            ?,
            ?,
            ?,
            ?
        )
    ];
    my $qryELINS= $db->prepare($stELINS) or query_error($stELINS);
 
    my $st = qq[
        SELECT * FROM tmpEntity WHERE strFileType= ?
    ];
    my $qry = $db->prepare($st) or query_error($st);
    $qry->execute($type);
    
    my $stMRAs = qq[
        SELECT strImportEntityCode, intEntityID
        FROM tblEntity
        WHERE intEntityLevel > 3
    ];
    my $qryMRAs = $db->prepare($stMRAs) or query_error($stMRAs);
    $qryMRAs->execute();
    my %ParentIDs=();
    while (my $dref = $qryMRAs->fetchrow_hashref())  {
        $ParentIDs{$dref->{'strImportEntityCode'}} = $dref->{'intEntityID'};
    }

    while (my $dref= $qry->fetchrow_hashref())    {
        my $status = $dref->{'strStatus'};
        my $localLang = 0; ## NEEDS LINKING TO tmpPerson.strLocalLanguage
        my $gender = 0;
        my $otherIdentifierType = 0;
        
        my $entityLevel = 3;
        my $parentEntityID = $ParentIDs{$dref->{'strEntityParentCode'}} || 0;
        
        if ($maCode eq 'HKG')   {
            ## Config here for HKG
        }
        else    {
            ## Finland at moment
            $gender = 1 if ($dref->{'strGender'} eq 'MALE');
            $gender = 2 if ($dref->{'strGender'} eq 'FEMALE');
            $otherIdentifierType = 0; ## Needs work from tmpPerspn.strIdentifierType
            $localLang = 0; ## Needs work from tmpPerson.strLocalLanguage
        }

        
        $qryINS->execute(
            $entityLevel,
            $dref->{'intID'},
            $dref->{'strNationalNum'},
            $status,
            $dref->{'strLocalFirstname'},
            $localLang,
            $dref->{'strLatinFirstname'},
            $dref->{'strISOCountryOfBirth'},
            $dref->{'strFax'},
            $dref->{'strPhone'},
            $dref->{'strAddress1'},
            $dref->{'strAddress2'},
            $dref->{'strPostalCode'},
            $dref->{'strSuburb'},
            $dref->{'strEmail'},
            $dref->{'strIdentifier'},
            $otherIdentifierType,
            $dref->{'strIdentifierCountryIssued'},
            $dref->{'dtIdentifierFrom'},
            $dref->{'dtIdentifierTo'}
        );
        my $ID = $qryINS->{mysql_insertid} || 0;
        $qryELINS->execute(
            $parentEntityID,
            $ID, 
            1, 
            $dref->{'intID'}
        );
    }
}

sub importEntityFile  {
    my ($db, $countOnly, $type, $infile) = @_;
    
    my $maCode = getImportMACode($db) || '';

open INFILE, "<$infile" or die "Can't open Input File";

my $count = 0;
                                                                                                        
seek(INFILE,0,0);
$count=0;
my $insCount=0;
my $NOTinsCount = 0;

my %cols = ();
my $stDEL = "DELETE FROM tmpEntity WHERE strFileType = ?";
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
#SystemID;PalloID;Status;LocalFirstName;LocalLastName;LocalPreviousLastName;LocalLanguageCode;PreferedName;LatinFirstName;LatinLastName;LatinPreviousLastName;DateOfBirth;Gender;Nationality;CountryOfBirth;RegionOfBirth;PlaceOfBirth;Fax;Phone;Address1;Address2;PostalCode;Town;Suburb;Email;Identifier;IdentifierType;CountryIssued;DateFrom;DateTo

    	$parts{'ENTITYCODE'} = $fields[0] || '';
    	$parts{'NATIONALNUM'} = $fields[1] || '';
	    $parts{'STATUS'} = $fields[2] || '';
	    $parts{'LOCALNAME'} = $fields[3] || '';
	    $parts{'LOCALLANGUAGE'} = $fields[4] || '';
	    $parts{'INTNAME'} = $fields[5] || '';
	    $parts{'ISO_COUNTRY'} = $fields[6] || ''; 
	    $parts{'FAX'} = $fields[7] || ''; 
	    $parts{'PHONE'} = $fields[8] || ''; 
	    $parts{'ADDRESS1'} = $fields[9] || ''; 
	    $parts{'ADDRESS2'} = $fields[10] || ''; 
	    $parts{'POSTALCODE'} = $fields[11] || ''; 
	    $parts{'TOWN'} = $fields[12] || ''; 
	    $parts{'SUBURB'} = $fields[13] || ''; 
	    $parts{'EMAIL'} = $fields[14] || ''; 
	    $parts{'OTHERIDENTIFIER'} = $fields[15] || ''; 
	    $parts{'OTHERIDENTIFIERTYPE'} = $fields[16] || ''; 
	    $parts{'OTHERIDENTIFIERCOUNTRY'} = $fields[17] || ''; 
	    $parts{'OTHERIDENTIFIER_dtFROM'} = $fields[18] || '0000-00-00'; 
	    $parts{'OTHERIDENTIFIER_dtTO'} = $fields[19] || '0000-00-00'; 
	    $parts{'PARENTCODE'} = $fields[20] || ''; 
        
    }
	if ($countOnly)	{
		$insCount++;
		next;
	}

	my $st = qq[
		INSERT INTO tmpEntity
		(
            strFileType, 
            strEntityCode, 
            strNationalNum, 
            strStatus,
            strLocalName,
            strLocalLanguage,
            strLatinName,
            strISOCountry,
            strFax,
            strPhone,
            strAddress1,
            strAddress2,
            strPostalCode,
            strSuburb,
            strEmail,
            strIdentifier,
            strIdentifierType,
            strIdentifierCountryIssued,
            dtIdentifierFrom,
            dtIdentifierTo,
            strParentCode
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
            ?,
            ?,
            ?
        )
	];
	my $query = $db->prepare($st) or query_error($st);
 	$query->execute(
        $type,
        $parts{'ENTITYCODE'},
        $parts{'NATIONALNUM'},
        $parts{'STATUS'},
        $parts{'LOCALNAME'},
        $parts{'LOCALLANGUAGE'},
        $parts{'INTNAME'},
        $parts{'ISO_COUNTRY'},
        $parts{'FAX'},
        $parts{'PHONE'},
        $parts{'ADDRESS1'},
        $parts{'ADDRESS2'},
        $parts{'POSTALCODE'},
        $parts{'TOWN'},
        $parts{'EMAIL'},
	    $parts{'OTHERIDENTIFIER'},
	    $parts{'OTHERIDENTIFIERTYPE'},
	    $parts{'OTHERIDENTIFIERCOUNTRY'},
	    $parts{'OTHERIDENTIFIER_dtFROM'},
	    $parts{'OTHERIDENTIFIER_dtTO'},
	    $parts{'PARENTCODE'}
    ) or print "ERROR";
}
$count --;
print STDERR "COUNT CHECK ONLY !!!\n" if $countOnly;

close INFILE;

}
1;
