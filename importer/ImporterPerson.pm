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
use L10n::DateFormat;

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
            dtOtherPersonIdentifierValidDateTo,
            strNatCustomStr1,
            strNatCustomStr2
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
        
        $otherIdentifierType = 558018 if ($dref->{'strIdentifierType'} eq 'NATIONALIDNUMBER');
        $otherIdentifierType = 558019 if ($dref->{'strIdentifierType'} eq 'PASSPORT');

        if ($maCode eq 'HKG')   {
            ## Config here for HKG
        } elsif ($maCode eq 'AZE') {
            $otherIdentifierType = 558019 if ($dref->{'strIdentifierType'} eq 'Passport');
            $otherIdentifierType = 558049 if ($dref->{'strIdentifierType'} eq 'BirthCertificate');

            $gender = 1 if ($dref->{'strGender'} eq 'M');
            $gender = 2 if ($dref->{'strGender'} eq 'F');
        }
        else    {
            ## Finland at moment
            $gender = 1 if ($dref->{'strGender'} eq 'MALE');
            $gender = 2 if ($dref->{'strGender'} eq 'FEMALE');
            $otherIdentifierType = 0; ## Needs work from tmpPerspn.strIdentifierType
            $localLang = 0; ## Needs work from tmpPerson.strLocalLanguage
        }
        
        $qryINS->execute(
            $dref->{'strPersonCode'},
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
            $dref->{'dtIdentifierTo'},
            $dref->{'strNatCustomStr1'},
            $dref->{'strNatCustomStr2'},
        );
        my $ID = $qryINS->{mysql_insertid} || 0;
    }
}

sub importPersonFile  {
    my ($db, $countOnly, $type, $infile) = @_;
    
	my $dateFormat = new L10n::DateFormat();
    my $maCode = getImportMACode($db) || '';

    if ($maCode eq 'AZE')   {
        open INFILE, '<:encoding(UTF-16)', $infile or die "Can't open Input File";
    } else {
        open INFILE, "<$infile" or die "Can't open Input File";
    }


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
	#my @fields=split /;/,$line;
	my @fields=split /\t/,$line;

    if ($maCode eq 'AZE')   {

    	$parts{'PERSONCODE'} = $fields[0] || '';
	    $parts{'STATUS'} = $fields[2] || '';
        $parts{'STATUS'} = 'REGISTERED';
	    $parts{'LOCALFIRSTNAME'} = $fields[3] || '';
	    $parts{'LOCALSURNAME'} = $fields[4] || '';
	    $parts{'LOCALLANGUAGE'} = 2; #$fields[4] || '';
	    $parts{'PREFERREDNAME'} = '' if $fields[5] eq 'NULL' || $fields[5] || '';  ## Don't think we use it
	    $parts{'INTFIRSTNAME'} = '' if $fields[6] eq 'NULL' || $fields[6] || '';
	    $parts{'INTSURNAME'} = '' if $fields[7] eq 'NULL' || $fields[7] || '';
	    $parts{'DOB'} = $fields[8] || '0000-00-00';
	    $parts{'GENDER'} = uc($fields[9]) || '';
	    $parts{'ISO_NATIONALITY'} = $fields[10] || ''; 
	    $parts{'ISO_COUNTRYOFBIRTH'} = $fields[11] || ''; 
	    $parts{'REGIONOFBIRTH'} = $fields[12] || ''; 
	    $parts{'PLACEOFBIRTH'} = '' if $fields[13] eq 'NULL' || $fields[13] || ''; 
	    $parts{'PHONE'} = '' if $fields[14] eq 'NULL' || $fields[14] || ''; 
	    $parts{'FAX'} = '' if $fields[15] eq 'NULL' || $fields[15] || ''; 
	    $parts{'ADDRESS1'} = '' if $fields[16] eq 'NULL' || $fields[16] || ''; 
	    $parts{'ADDRESS2'} = '' if $fields[17] eq 'NULL' || $fields[17] || ''; 
	    $parts{'POSTALCODE'} = '' if $fields[18] eq 'NULL' || $fields[18] || ''; 
	    $parts{'SUBURB'} = '' if $fields[19] eq 'NULL' || $fields[19] || ''; 
	    $parts{'TOWN'} = '' if $fields[20] eq 'NULL' || $fields[20] || ''; 
	    $parts{'EMAIL'} = '' if $fields[21] eq 'NULL' || $fields[21] || ''; 
	    $parts{'OTHERIDENTIFIER'} = $fields[22] || ''; 
	    $parts{'OTHERIDENTIFIERTYPE'} = $fields[23] || ''; 
	    $parts{'OTHERIDENTIFIERCOUNTRY'} = $fields[24] || ''; 

	    $parts{'OTHERIDENTIFIER_dtFROM'} = '0000-00-00'; 
	    $parts{'OTHERIDENTIFIER_dtTO'} = '0000-00-00'; 
	    $parts{'LOCALMAIDENNAME'} = '';
	    $parts{'INTMAIDENNAME'} = ''; 
    	$parts{'NATIONALNUM'} = '';
    	$parts{'LOCALFATHERNAME'} = $fields[25] || '';
    	$parts{'LOCALMOTHERNAME'} = $fields[26] || '';


        (my $db_date = $parts{'DOB'}) =~ s/(\d\d)\/(\d\d)\/(\d\d\d\d)/$3-$2-$1/;
        $parts{'DOB'} = $db_date;
    }

    if ($maCode eq 'GHA')   {
        ## Update field mapping for HKG 
#SystemID;PalloID;Status;LocalFirstName;LocalLastName;LocalPreviousLastName;LocalLanguageCode;PreferedName;LatinFirstName;LatinLastName;LatinPreviousLastName;DateOfBirth;Gender;Nationality;CountryOfBirth;RegionOfBirth;PlaceOfBirth;Fax;Phone;Address1;Address2;PostalCode;Town;Suburb;Email;Identifier;IdentifierType;CountryIssued;DateFrom;DateTo

    	$parts{'PERSONCODE'} = $fields[0] || '';
	    $parts{'STATUS'} = $fields[1] || '';
        $parts{'STATUS'} = 'REGISTERED';
	    $parts{'LOCALFIRSTNAME'} = $fields[2] || '';
	    $parts{'LOCALSURNAME'} = $fields[3] || '';
	    $parts{'LOCALLANGUAGE'} = 1; #$fields[4] || '';
	    $parts{'PREFERREDNAME'} = $fields[5] || '';  ## Don't think we use it
	    $parts{'INTFIRSTNAME'} = $fields[6] || '';
	    $parts{'INTSURNAME'} = $fields[7] || '';
	    $parts{'DOB'} = $fields[8] || '0000-00-00';
	    $parts{'GENDER'} = uc($fields[9]) || '';
	    $parts{'ISO_NATIONALITY'} = $fields[10] || ''; 
	    $parts{'ISO_COUNTRYOFBIRTH'} = $fields[11] || ''; 
	    $parts{'REGIONOFBIRTH'} = $fields[12] || ''; 
	    $parts{'PLACEOFBIRTH'} = $fields[13] || ''; 
	    $parts{'FAX'} = $fields[14] || ''; 
	    $parts{'PHONE'} = $fields[15] || ''; 
	    $parts{'ADDRESS1'} = $fields[16] || ''; 
	    $parts{'ADDRESS2'} = $fields[17] || ''; 
	    $parts{'POSTALCODE'} = $fields[18] || ''; 
	    $parts{'SUBURB'} = $fields[19] || ''; 
	    $parts{'TOWN'} = $fields[20] || ''; 
	    $parts{'EMAIL'} = $fields[21] || ''; 
	    $parts{'OTHERIDENTIFIER'} = $fields[22] || ''; 
	    $parts{'OTHERIDENTIFIERTYPE'} = $fields[23] || ''; 
	    $parts{'OTHERIDENTIFIERCOUNTRY'} = $fields[24] || ''; 

	    $parts{'OTHERIDENTIFIER_dtFROM'} = '0000-00-00'; 
	    $parts{'OTHERIDENTIFIER_dtTO'} = '0000-00-00'; 
	    $parts{'LOCALMAIDENNAME'} = '';
	    $parts{'INTMAIDENNAME'} = ''; 
    	$parts{'NATIONALNUM'} = '';
       
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
            dtIdentifierTo,
            strNatCustomStr1,
            strNatCustomStr2
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
	    $parts{'OTHERIDENTIFIER_dtTO'},
	    $parts{'LOCALFATHERNAME'},
	    $parts{'LOCALMOTHERNAME'},
    ) or print "ERROR";
}
$count --;
print STDERR "COUNT CHECK ONLY !!!\n" if $countOnly;

close INFILE;

}
1;
