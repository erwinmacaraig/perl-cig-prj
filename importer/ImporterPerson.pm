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
            strImportPersonCode,
            strNationalNum,
            strStatus,
            strLocalFirstname,
            strLocalSurname,
            strMaidenName,
            intLocalLanguage,
            strLatinFirstname,
            strLatinSurname,
            strISONationality,
            strISOCountryOfBirth,
            strRegionOfBirth,
            strPlaceOfBirth,
            strFax,
            strPhoneHome,
            strAddress1,
            strAddress2,
            strPostalCode,
            strSuburb,
            strEmail,
            intGender,
            dtDOB,
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

    my $st = qq[
        SELECT * FROM tmpPerson
    ];
    my $qry = $db->prepare($st) or query_error($st);
    $qry->execute();
    while (my $dref= $qry->fetchrow_hashref())    {
        my $status = $dref->{'strStatus'};
        my $localLang = 0; ## NEEDS LINKING TO tmpPerson.strLocalLanguage
        my $gender = 0;
        my $otherIdentifierType = 0;
        
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
            $dref->{'intID'},
            $dref->{'strNationalNum'},
            $status,
            $dref->{'strLocalFirstname'},
            $dref->{'strLocalSurname'},
            $dref->{'strLocalMaidenName'},
            $localLang,
            $dref->{'strLatinFirstname'},
            $dref->{'strLatinSurname'},
            $dref->{'strISONationality'},
            $dref->{'strISOCountryOfBirth'},
            $dref->{'strRegionOfBirth'},
            $dref->{'strPlaceOfBirth'},
            $dref->{'strFax'},
            $dref->{'strPhone'},
            $dref->{'strAddress1'},
            $dref->{'strAddress2'},
            $dref->{'strPostalCode'},
            $dref->{'strSuburb'},
            $dref->{'strEmail'},
            $gender,
            $dref->{'dtDOB'},
            $dref->{'strIdentifier'},
            $otherIdentifierType,
            $dref->{'strIdentifierCountryIssued'},
            $dref->{'dtIdentifierFrom'},
            $dref->{'dtIdentifierTo'}
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
#SystemID;PalloID;Status;LocalFirstName;LocalLastName;LocalPreviousLastName;LocalLanguageCode;PreferedName;LatinFirstName;LatinLastName;LatinPreviousLastName;DateOfBirth;Gender;Nationality;CountryOfBirth;RegionOfBirth;PlaceOfBirth;Fax;Phone;Address1;Address2;PostalCode;Town;Suburb;Email;Identifier;IdentifierType;CountryIssued;DateFrom;DateTo

    	$parts{'PERSONCODE'} = $fields[0] || '';
    	$parts{'NATIONALNUM'} = $fields[1] || '';
	    $parts{'STATUS'} = $fields[2] || '';
	    $parts{'LOCALFIRSTNAME'} = $fields[3] || '';
	    $parts{'LOCALSURNAME'} = $fields[4] || '';
	    $parts{'LOCALMAIDENNAME'} = $fields[5] || '';
	    $parts{'LOCALLANGUAGE'} = $fields[6] || '';
	    $parts{'PREFERREDNAME'} = $fields[7] || '';  ## Don't think we use it
	    $parts{'INTFIRSTNAME'} = $fields[8] || '';
	    $parts{'INTSURNAME'} = $fields[9] || '';
	    $parts{'INTMAIDENNAME'} = $fields[10] || ''; ## Not ued
	    $parts{'DOB'} = $fields[11] || '0000-00-00';
	    $parts{'GENDER'} = $fields[12] || '';
	    $parts{'ISO_NATIONALITY'} = $fields[13] || ''; 
	    $parts{'ISO_COUNTRYOFBIRTH'} = $fields[14] || ''; 
	    $parts{'REGIONOFBIRTH'} = $fields[15] || ''; 
	    $parts{'PLACEOFBIRTH'} = $fields[16] || ''; 
	    $parts{'FAX'} = $fields[17] || ''; 
	    $parts{'PHONE'} = $fields[18] || ''; 
	    $parts{'ADDRESS1'} = $fields[19] || ''; 
	    $parts{'ADDRESS2'} = $fields[20] || ''; 
	    $parts{'POSTALCODE'} = $fields[21] || ''; 
	    $parts{'TOWN'} = $fields[22] || ''; 
	    $parts{'SUBURB'} = $fields[23] || ''; 
	    $parts{'EMAIL'} = $fields[24] || ''; 
	    $parts{'OTHERIDENTIFIER'} = $fields[25] || ''; 
	    $parts{'OTHERIDENTIFIERTYPE'} = $fields[26] || ''; 
	    $parts{'OTHERIDENTIFIERCOUNTRY'} = $fields[27] || ''; 
	    $parts{'OTHERIDENTIFIER_dtFROM'} = $fields[28] || '0000-00-00'; 
	    $parts{'OTHERIDENTIFIER_dtTO'} = $fields[29] || '0000-00-00'; 
        
    }
	if ($countOnly)	{
		$insCount++;
		next;
	}

	my $st = qq[
		INSERT INTO tmpPerson
		(
            strFileType, 
            strPersonCode, 
            strNationalNum, 
            strStatus,
            strLocalFirstname,
            strLocalSurname,
            strLocalMaidenName,
            strLocalLanguage,
            strLatinFirstname,
            strLatinSurname,
            strISONationality,  
            strISOCountryOfBirth,
            strRegionOfBirth,
            strPlaceOfBirth,
            strFax,
            strPhone,
            strAddress1,
            strAddress2,
            strPostalCode,
            strSuburb,
            strEmail,
            strGender,
            dtDOB,
            strIdentifier,
            strIdentifierType,
            strIdentifierCountryIssued,
            dtIdentifierFrom,
            dtIdentifierTo
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
        $parts{'PERSONCODE'},
        $parts{'NATIONALNUM'},
        $parts{'STATUS'},
        $parts{'LOCALFIRSTNAME'},
        $parts{'LOCALSURNAME'},
        $parts{'LOCALMAIDENNAME'},
        $parts{'LOCALLANGUAGE'},
        $parts{'INTFIRSTNAME'},
        $parts{'INTSURNAME'},
        $parts{'ISO_NATIONALITY'},
        $parts{'ISO_COUNTRYOFBIRTH'},
        $parts{'REGIONOFBIRTH'},
        $parts{'PLACEOFBIRTH'},
        $parts{'FAX'},
        $parts{'PHONE'},
        $parts{'ADDRESS1'},
        $parts{'ADDRESS2'},
        $parts{'POSTALCODE'},
        $parts{'TOWN'},
        $parts{'EMAIL'},
        $parts{'GENDER'},
        $parts{'DOB'},
	    $parts{'OTHERIDENTIFIER'},
	    $parts{'OTHERIDENTIFIERTYPE'},
	    $parts{'OTHERIDENTIFIERCOUNTRY'},
	    $parts{'OTHERIDENTIFIER_dtFROM'},
	    $parts{'OTHERIDENTIFIER_dtTO'}
    ) or print "ERROR";
}
$count --;
print STDERR "COUNT CHECK ONLY !!!\n" if $countOnly;

close INFILE;

}
1;
