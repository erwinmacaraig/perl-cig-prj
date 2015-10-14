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
            intRealmApproved,
            intEntityLevel,
            strEntityType,
            strImportEntityCode,
            strMAID,
            strStatus,
            strLocalName,
            strLocalShortName,
            intLocalLanguage,
            strLatinName,
            strLatinShortName,
            dtFrom,
            dtTo,
            strISOCountry,
            strRegion,
            strCity,
            strState,
            strFax,
            strPhone,
            strAddress,
            strAddress2,
            strPostalCode,
            strWebURL,
            strEmail,
            dtAdded,
            strDiscipline,
            intAcceptSelfRego,
            intNotifications,
            strOrganisationLevel,
        )
        VALUES (
            1,
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
            NOW(),
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
        my $entityType= 'CLUB';
        my $parentEntityID = $ParentIDs{$dref->{'strParentCode'}} || 0;
        
        if ($maCode eq 'HKG')   {
            ## Config here for HKG
        }
        
        $qryINS->execute(
            $entityLevel,
            $entityType,
            $dref->{'intID'},
            $dref->{'strMAID'},
            $status,
            $dref->{'strLocalName'},
            $dref->{'strLocalShortName'},
            $localLang,
            $dref->{'strLatinName'},
            $dref->{'strLatinShortName'},
            $dref->{'dtFrom'},
            $dref->{'dtTo'},
            $dref->{'strISOCountry'},
            $dref->{'strRegion'},
            $dref->{'strCity'},
            $dref->{'strState'},
            $dref->{'strFax'},
            $dref->{'strPhone'},
            $dref->{'strAddress'},
            $dref->{'strAddress2'},
            $dref->{'strPostalCode'},
            $dref->{'strWebURL'},
            $dref->{'strEmail'},
            $dref->{'strDiscipline'},
            $dref->{'intAcceptSelfRego'},
            $dref->{'intNotifications'},
            $dref->{'strOrganisationLevel'},
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
        ## NEED GHANA MAPPING
#SystemID;PalloID;Status;LocalFirstName;LocalLastName;LocalPreviousLastName;LocalLanguageCode;PreferedName;LatinFirstName;LatinLastName;LatinPreviousLastName;DateOfBirth;Gender;Nationality;CountryOfBirth;RegionOfBirth;PlaceOfBirth;Fax;Phone;Address1;Address2;PostalCode;Town;Suburb;Email;Identifier;IdentifierType;CountryIssued;DateFrom;DateTo

    	$parts{'ENTITYCODE'} = $fields[0] || '';
    	$parts{'MAID'} = $fields[1] || '';
	    $parts{'STATUS'} = $fields[2] || '';
	    $parts{'LOCALNAME'} = $fields[3] || '';
	    $parts{'LOCALSHORTNAME'} = $fields[4] || '';
	    $parts{'LOCALLANGUAGE'} = $fields[5] || '';
	    $parts{'INTNAME'} = $fields[6] || '';
	    $parts{'INTSHORTNAME'} = $fields[7] || '';
	    $parts{'dtFROM'} = $fields[8] || '0000-00-00'; 
	    $parts{'dtTO'} = $fields[9] || '0000-00-00'; 
	    $parts{'ISO_COUNTRY'} = $fields[10] || ''; 
	    $parts{'REGION'} = $fields[11] || ''; 
	    $parts{'CITY'} = $fields[12] || ''; 
	    $parts{'STATE'} = $fields[13] || ''; 
	    $parts{'FAX'} = $fields[14] || ''; 
	    $parts{'PHONE'} = $fields[15] || ''; 
	    $parts{'ADDRESS'} = $fields[16] || ''; 
	    $parts{'ADDRESS2'} = $fields[17] || ''; 
	    $parts{'POSTALCODE'} = $fields[18] || ''; 
	    $parts{'WEBURL'} = $fields[19] || ''; 
	    $parts{'DISCIPLINE'} = $fields[20] || ''; 
	    $parts{'ACCEPTREGO'} = $fields[21] || 0; 
	    $parts{'NOTIFICATIONS'} = $fields[22] || 0; 
	    $parts{'ORGLEVEL'} = $fields[23] || ''; 
	    $parts{'PARENTCODE'} = $fields[24] || ''; 
        
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
            strMAID, 
            strStatus,
            strLocalName,
            strLocalShortName,
            strLocalLanguage,
            strLatinName,
            strLatinShortName,
            dtFrom,
            dtTo,
            strISOCountry,
            strRegion,
            strCity,
            strState,
            strFax,
            strPhone,
            strAddress,
            strAddress2,
            strPostalCode,
            strEmail,
            strWebURL,
            strDiscipline,
            intAcceptSelfRego,
            intNotifications,
            strOrganisationLevel,
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
        $parts{'MAID'},
        $parts{'STATUS'},
        $parts{'LOCALNAME'},
        $parts{'LOCALSHORTNAME'},
        $parts{'LOCALLANGUAGE'},
        $parts{'INTNAME'},
        $parts{'INTSHORTNAME'},
        $parts{'dtFROM'},
        $parts{'dtTO'},
        $parts{'ISO_COUNTRY'},
        $parts{'REGION'},
        $parts{'CITY'},
        $parts{'STATE'},
        $parts{'FAX'},
        $parts{'PHONE'},
        $parts{'ADDRESS'},
        $parts{'ADDRESS2'},
        $parts{'POSTALCODE'},
        $parts{'EMAIL'},
        $parts{'WEBURL'},
        $parts{'DISCIPLINE'},
	    $parts{'ACCEPTREGO'},
	    $parts{'NOTIFICATIONS'},
	    $parts{'ORGLEVEL'},
	    $parts{'PARENTCODE'}
    ) or print "ERROR";
}
$count --;
print STDERR "COUNT CHECK ONLY !!!\n" if $countOnly;

close INFILE;

}
1;
