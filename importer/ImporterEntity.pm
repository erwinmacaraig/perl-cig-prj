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
            strGender
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
            ?,
            'ALL'
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

print "ENTITY LINKS ARE ALL FOR 10000\n";
    while (my $dref= $qry->fetchrow_hashref())    {
        my $status = $dref->{'strStatus'};
        my $localLang = 0; ## NEEDS LINKING TO tmpPerson.strLocalLanguage
        my $gender = 0;
        my $otherIdentifierType = 0;
        
        my $entityLevel = 3;
        my $entityType= $dref->{'strEntityType'} || 'CLUB';
        $dref->{'strOrganisationLevel'}||= 'BOTH';
        my $parentEntityID = $ParentIDs{$dref->{'strParentCode'}} || 0;

        #if ($dref->{'strParentCode'} ne '1014') {
        #    $dref->{'strParentCode'} = '10000';
        #    $parentEntityID = $ParentIDs{$dref->{'strParentCode'}} || 0;
        #}
        
        if ($maCode eq 'HKG')   {
            ## Config here for HKG
        }
        
        $qryINS->execute(
            $entityLevel,
            $entityType,
            $dref->{'strEntityCode'},
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
            $dref->{'intAcceptSelfRego'} || 0,
            $dref->{'intNotifications'} || 0,
            $dref->{'strOrganisationLevel'},
        ) or print "SQL ERROR\n";
        my $ID = $qryINS->{mysql_insertid};
        #print "ID IS $ID\n";
        next if (! $ID);
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
#	my @fields=split /;/,$line;
	my @fields=split /\t/,$line;

    if ($maCode eq 'HKG')   {
        ## Update field mapping for HKG 
    }
    elsif ($maCode eq 'AZE')   {
        ## Update field mapping for HKG 
        ## NEED GHANA MAPPING
#SystemID;PalloID;Status;LocalFirstName;LocalLastName;LocalPreviousLastName;LocalLanguageCode;PreferedName;LatinFirstName;LatinLastName;LatinPreviousLastName;DateOfBirth;Gender;Nationality;CountryOfBirth;RegionOfBirth;PlaceOfBirth;Fax;Phone;Address1;Address2;PostalCode;Town;Suburb;Email;Identifier;IdentifierType;CountryIssued;DateFrom;DateTo

        next if ($fields['4'] eq 'MA'); # Skip MA
        next if ($fields['4'] eq 'REGION'); # Skip MA

    	$parts{'ENTITYCODE'} = $fields[0] || '';
	    $parts{'PARENTCODE'} = $fields[1] || ''; 
	    $parts{'STATUS'} = uc($fields[3]) || '';
	    $parts{'ENTITYTYPE'} = $fields[4] || ''; 
	    $parts{'LOCALNAME'} = $fields[6] || '';
	    $parts{'LOCALSHORTNAME'} = $fields[7] || '';
	    $parts{'LOCALLANGUAGE'} = 2;
	    $parts{'INTNAME'} = $fields[8] || '';
	    $parts{'INTSHORTNAME'} = $fields[9] || '';
	    $parts{'dtFROM'} = $fields[10] || '0000-00-00'; 
	    $parts{'dtTO'} = $fields[11] || '0000-00-00'; 
	    $parts{'DISCIPLINE'} = $fields[12] || ''; 
	    $parts{'ISO_COUNTRY'} = $fields[13] || ''; 
	    $parts{'WEBURL'} = $fields[14] || ''; 
	    $parts{'FAX'} = $fields[15] || ''; 
	    $parts{'PHONE'} = $fields[16] || ''; 
	    $parts{'ADDRESS'} = $fields[17] || ''; 
	    $parts{'ADDRESS2'} = ''; 
	    $parts{'POSTALCODE'} = $fields[18] || ''; 
	    $parts{'REGION'} = $fields[2] || ''; 
	    $parts{'CITY'} = $fields[20] || ''; 
	    $parts{'STATE'} = $fields[21] || ''; 
	    $parts{'EMAIL'} = $fields[22] || ''; 

        $parts{'LOCALNAME'} = '' if $parts{'LOCALNAME'} eq 'NULL';
        $parts{'LOCALSHORTNAME'} = '' if $parts{'LOCALSHORTNAME'} eq 'NULL';
        $parts{'INTNAME'} = '' if $parts{'INTNAME'} eq 'NULL';
        $parts{'INTSHORTNAME'} = '' if $parts{'INTSHORTNAME'} eq 'NULL';
        $parts{'WEBURL'} = '' if $parts{'WEBURL'} eq 'NULL';
        $parts{'FAX'} = '' if $parts{'FAX'} eq 'NULL';
        $parts{'PHONE'} = '' if $parts{'PHONE'} eq 'NULL';
        $parts{'ADDRESS'} = '' if $parts{'ADDRESS'} eq 'NULL';
        $parts{'ADDRESS2'} = '' if $parts{'ADDRESS2'} eq 'NULL';
        $parts{'POSTALCODE'} = '' if $parts{'POSTALCODE'} eq 'NULL';
        $parts{'REGION'} = '' if $parts{'REGION'} eq 'NULL';
        $parts{'CITY'} = '' if $parts{'CITY'} eq 'NULL';
        $parts{'EMAIL'} = '' if $parts{'EMAIL'} eq 'NULL';

	    $parts{'ORGLEVEL'} = 'BOTH';

        (my $dtFrom = $parts{'dtFROM'}) =~ s/(\d\d)\/(\d\d)\/(\d\d\d\d)/$3-$2-$1/;
        $parts{'dtFROM'} = $dtFrom;

        (my $dtTo = $parts{'dtTO'}) =~ s/(\d\d)\/(\d\d)\/(\d\d\d\d)/$3-$2-$1/;
        $parts{'dtTO'} = $dtTo;

    	#$parts{'MAID'} = $fields[1] || '';
	    #$parts{'ACCEPTREGO'} = $fields[21] || 0; 
	    #$parts{'NOTIFICATIONS'} = $fields[22] || 0; 
    }
elsif ($maCode eq 'GHA')   {
        ## Update field mapping for HKG 
        ## NEED GHANA MAPPING
#SystemID;PalloID;Status;LocalFirstName;LocalLastName;LocalPreviousLastName;LocalLanguageCode;PreferedName;LatinFirstName;LatinLastName;LatinPreviousLastName;DateOfBirth;Gender;Nationality;CountryOfBirth;RegionOfBirth;PlaceOfBirth;Fax;Phone;Address1;Address2;PostalCode;Town;Suburb;Email;Identifier;IdentifierType;CountryIssued;DateFrom;DateTo

    	$parts{'ENTITYCODE'} = $fields[0] || '';
next if ($parts{'ENTITYCODE'} eq '1014'); # Skip MA
next if ($parts{'ENTITYCODE'} <= 33);
	    $parts{'PARENTCODE'} = $fields[1] || ''; 
    
	    $parts{'STATUS'} = uc($fields[2]) || '';
	    $parts{'ENTITYTYPE'} = $fields[3] || ''; 
	    $parts{'LOCALNAME'} = $fields[4] || '';
	    $parts{'LOCALSHORTNAME'} = $fields[5] || '';
	    $parts{'LOCALLANGUAGE'} = 1; #$fields[6] || '';
	    $parts{'INTNAME'} = $fields[7] || '';
	    $parts{'INTSHORTNAME'} = $fields[8] || '';
	    $parts{'dtFROM'} = $fields[9] || '0000-00-00'; 
	    $parts{'dtTO'} = $fields[10] || '0000-00-00'; 
	    $parts{'DISCIPLINE'} = $fields[11] || ''; 
	    $parts{'ISO_COUNTRY'} = $fields[12] || ''; 
	    $parts{'WEBURL'} = $fields[13] || ''; 
	    $parts{'FAX'} = $fields[14] || ''; 
	    $parts{'PHONE'} = $fields[15] || ''; 
	    $parts{'ADDRESS'} = $fields[16] || ''; 
	    $parts{'ADDRESS2'} = $fields[17] || ''; 
	    $parts{'POSTALCODE'} = $fields[18] || ''; 
	    $parts{'REGION'} = $fields[19] || ''; 
	    $parts{'CITY'} = $fields[19] || ''; 
	    $parts{'STATE'} = $fields[20] || ''; 
	    $parts{'EMAIL'} = $fields[21] || ''; 

	    $parts{'ORGLEVEL'} = 'BOTH';
    	#$parts{'MAID'} = $fields[1] || '';
	    #$parts{'ACCEPTREGO'} = $fields[21] || 0; 
	    #$parts{'NOTIFICATIONS'} = $fields[22] || 0; 
    }
    else    {
    }
	if ($countOnly)	{
		$insCount++;
		next;
	}

	my $st = qq[
		INSERT INTO tmpEntity
		(
            strFileType, 
            strEntityType,
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
            ?,
            ?
        )
	];
	my $query = $db->prepare($st) or query_error($st);
 	$query->execute(
        $type,
        $parts{'ENTITYTYPE'},
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
