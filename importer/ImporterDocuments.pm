package ImporterDocuments;
require Exporter;
@ISA    = qw(Exporter);
@EXPORT = @EXPORT_OK = qw(
    linkPhotoDocuments
    linkOtherDocuments
    importDocumentFile
    importOtherDocumentFile
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

sub linkOtherDocuments {
    my ($db) = @_;

    my $path = '';
    foreach my $dir (('import/', 'others/')) {
        $path .= $dir;
        #needed if we're not using S3
        #if( !-d "$Defs::fs_upload_dir/files/$path") { mkdir "$Defs::fs_upload_dir/files/$path",0755; }
    }

    my $dst = qq[
        SELECT *, TRIM(BOTH ' ' FROM strUsage) as trimmedstrUsage FROM tmpImportedDocuments WHERE strType = 'OTHER';
    ];

    my $qst = $db->prepare($dst) or query_error($dst);
    $qst->execute();

    #update depending on current MA
    my %doctype = ();
    $doctype{'Passport'} = 2;
    $doctype{'Birth certificate'} = 2;
    $doctype{'Player Contract'} = 3;
    $doctype{'Parental Consent for Minors'} = 7;
    $doctype{'International Transfer Certificate'} = 11;
    $doctype{'Medical certificate'} = 17;
    $doctype{'Transfer Agreement'} = 18;
    $doctype{'T1 Form for amateur'} = 19;
    $doctype{'Work Permit'} = 20;
    $doctype{'Resident Permit'} = 21;
    $doctype{'Provisional Transfer Certificate'} = 25;
    $doctype{'Others'} = 22;
    $doctype{'National Id Card'} = 26;
    $doctype{'Juvenile Reg Form'} = 24;
    $doctype{'Free Agent Letter'} = 23;

    my $count = 0;
    while (my $dref = $qst->fetchrow_hashref()) {
        next if ($dref->{'originalFilename'} eq '');
        next if ($dref->{'strUsage'} eq '');

        my $dtype = $dref->{'strUsage'}; 
        my $prcode = $dref->{'PRregoImport'};
        my $pcode = $dref->{'strPersonCode'};
        my $filename = $dref->{'originalFilename'};
        my @file = split /\./, $filename;

        next if(scalar(@file) != 2);

        my $sgetp = qq [
            SELECT
                tpl.intPersonID,
                tpl.intPersonRegistrationID as PRid
            FROM tmpPRLinkage tpl
            WHERE
                tpl.strClientPRImportCode = ?
            LIMIT 1
        ];

        my $qgetp = $db->prepare($sgetp);
        $qgetp->execute($prcode);

        my $qgetpref = $qgetp->fetchrow_hashref();

        my $inupl = qq [
            INSERT INTO tblUploadedFiles(
                intFileID,
                intFileType,
                intEntityTypeID,
                intEntityID,
                intAddedByTypeID,
                intAddedByID,
                strTitle,
                strPath,
                strFilename,
                strOrigFilename,
                strExtension,
                intBytes,
                dtUploaded,
                intPermissions
            )
            VALUES(
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
                now(),
                ?
            )
        ];

        my $qinupl = $db->prepare($inupl);
        $qinupl->execute(
            0,
            $doctype{$dtype} || 0,
            1, #PERSON_LEVEL
            $qgetpref->{'intPersonID'} || 0,
            100, #MA level
            1, #MA id
            $filename,
            $path,
            $file[0],
            $filename,
            $file[1],
            0, #bytes
            1
        );

        my $inuplid = $qinupl->{mysql_insertid};

        my $indoc = qq[
            INSERT INTO tblDocuments(
                intDocumentID,
                intDocumentTypeID,
                intEntityLevel,
                intEntityID,
                intPersonID,
                intPersonRegistrationID,
                intClearanceID,
                strDeniedNotes,
                strApprovalStatus,
                intUploadFileID,
                dtAdded,
                dtLastUpdated,
                tTimeStamp
            )
            VALUES(
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
                now(),
                now(),
                now()
            )
        ];

        my $qindoc = $db->prepare($indoc);
        $qindoc->execute(
            0,
            $doctype{$dtype} || 0,
            1,
            0,
            $qgetpref->{'intPersonID'} || 0,
            $qgetpref->{'PRid'} || 0,
            0,
            '',
            'APPROVED',
            $inuplid
        );

        $count++;
    }

    print STDERR Dumper "COUNT VALID FILE: " . $count;
}





sub linkPhotoDocuments {
    my ($db) = @_;

    #this will be used 
    my $path = '';
    foreach my $dir (('import/', 'photos/')) {
        $path .= $dir;
        #needed if we're not using S3
        #if( !-d "$Defs::fs_upload_dir/files/$path") { mkdir "$Defs::fs_upload_dir/files/$path",0755; }
    }

    my $dst = qq[
        SELECT * FROM tmpImportedDocuments WHERE strType = 'PHOTO' AND strPersonCode = '529';
    ];

    my $qst = $db->prepare($dst) or query_error($dst);
    $qst->execute();

    my %dup = ();

    my $count = 0;
    while (my $dref = $qst->fetchrow_hashref()) {
        next if ($dref->{'originalFilename'} eq '');

        my $pcode = $dref->{'strPersonCode'};
        my $filename = $dref->{'originalFilename'};

        my $dupcheck = $dup{$pcode};
        next if($dupcheck and ($dupcheck eq $filename));
        $dup{$pcode} = $filename;

        my @file = split /\./, $filename;
        next if(scalar(@file) != 2);

        my $sgetp = qq [
            SELECT
                p.intPersonID,
                max(tpl.intPersonRegistrationID) as maxPR
            FROM tblPerson p
            LEFT JOIN tmpPRLinkage tpl ON (tpl.intPersonID = p.intPersonID)
            WHERE
                p.strImportPersonCode = ?
            LIMIT 1
        ];

        my $qgetp = $db->prepare($sgetp);
        $qgetp->execute($pcode);

        my $qgetpref = $qgetp->fetchrow_hashref();
        print STDERR Dumper $qgetpref;
        next;

        my $inupl = qq [
            INSERT INTO tblUploadedFiles(
                intFileID,
                intFileType,
                intEntityTypeID,
                intEntityID,
                intAddedByTypeID,
                intAddedByID,
                strTitle,
                strPath,
                strFilename,
                strOrigFilename,
                strExtension,
                intBytes,
                dtUploaded,
                intPermissions
            )
            VALUES(
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
                now(),
                ?
            )
        ];

        my $qinupl = $db->prepare($inupl);
        $qinupl->execute(
            0,
            1, #check tblDocumentType
            1, #PERSON_LEVEL
            $qgetpref->{'intPersonID'} || 0,
            100, #MA level
            1, #MA id
            $filename,
            $path,
            $file[0],
            $filename,
            $file[1],
            0, #bytes
            1
        );

        my $inuplid = $qinupl->{mysql_insertid};

        my $indoc = qq[
            INSERT INTO tblDocuments(
                intDocumentID,
                intDocumentTypeID,
                intEntityLevel,
                intEntityID,
                intPersonID,
                intPersonRegistrationID,
                intClearanceID,
                strDeniedNotes,
                strApprovalStatus,
                intUploadFileID,
                dtAdded,
                dtLastUpdated,
                tTimeStamp
            )
            VALUES(
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
                now(),
                now(),
                now()
            )
        ];

        my $qindoc = $db->prepare($indoc);
        $qindoc->execute(
            0,
            1, #check tblDocumentType
            1,
            0,
            $qgetpref->{'intPersonID'} || 0,
            $qgetpref->{'maxPR'} || 0,
            0,
            '',
            'APPROVED',
            $inuplid
        );

        my $inlogo = qq [
            INSERT INTO tblLogo(
                intEntityTypeID,
                intEntityID,
                strPath,
                strFilename,
                strExtension
            )
            VALUES(
                ?,
                ?,
                ?,
                ?,
                ?
            )
        ];

        my $qinlogo = $db->prepare($inlogo);
        $qinlogo->execute(
            1,
            $qgetpref->{'intPersonID'} || 0,
            $path,
            $file[0],
            $file[1]
        );

        $count++;
    }

    print STDERR Dumper "COUNT VALID FILE: " . $count;


}

sub importPhotoDocumentFile  {
    my ($db, $countOnly, $type, $infile) = @_;

    open INFILE, "<$infile" or die "Can't open Input File";

    my $count = 0;
    seek(INFILE, 0, 0);
    $count = 0;
    my $insCount = 0;
    my $NOTinsCount = 0;

    my %cols = ();
    my $stDEL = "DELETE FROM tmpImportedDocuments WHERE strType = ?";
    my $qDEL= $db->prepare($stDEL) or query_error($stDEL);
    $qDEL->execute($type);

    while (<INFILE>)	{
        my %parts = ();
        $count ++;
        next if $count == 1;
        #next if $count > 10; #records for now
        chomp;
        my $line=$_;
        $line=~s///g;
        #$line=~s/,/\-/g;
        $line=~s/"//g;
        my @fields=split /,/,$line;

        #PICTUREID,VALIDFROM,VALIDTO,USAGE,FILEPATH,PERSONID
        $parts{'PICTUREID'} = $fields[0] || 0;
        $parts{'VALIDFROM'} = $fields[1] || '';
        $parts{'VALIDTO'} = $fields[2] || '';
        $parts{'USAGE'} = $fields[3] || '';
        $parts{'ORIGINALFILENAME'} = $fields[4] || '';
        $parts{'PERSONID'} = $fields[5] || '';
        $parts{'PERSONREGOID'} = 0; #0 for now; still waiting for documents

        if ($countOnly)	{
            $insCount++;
            next;
        }

        my $st = qq[
            INSERT INTO tmpImportedDocuments
            (
                strType,
                strPersonCode,
                validFrom,
                validTo,
                strUsage,
                originalFilename,
                PRregoImport
            )
            VALUES (
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
            $parts{'PERSONID'},
            $parts{'VALIDFROM'},
            $parts{'VALIDTO'},
            $parts{'USAGE'},
            $parts{'ORIGINALFILENAME'},
            $parts{'PERSONREGOID'}
        ) or print "ERROR";
    }
    $count --;
    print STDERR "COUNT CHECK ONLY !!!\n" if $countOnly;

    close INFILE;

}

sub importOtherDocumentFile  {
    my ($db, $countOnly, $type, $infile) = @_;

    open INFILE, "<$infile" or die "Can't open Input File";

    my $count = 0;
    seek(INFILE, 0, 0);
    $count = 0;
    my $insCount = 0;
    my $NOTinsCount = 0;

    my %cols = ();
    my $stDEL = "DELETE FROM tmpImportedDocuments WHERE strType = ?";
    my $qDEL= $db->prepare($stDEL) or query_error($stDEL);
    $qDEL->execute($type);

    while (<INFILE>)	{
        my %parts = ();
        $count ++;
        next if $count == 1;
        #next if $count > 10; #records for now
        chomp;
        my $line=$_;
        $line=~s///g;
        #$line=~s/,/\-/g;
        $line=~s/"//g;
        my @fields=split /,/,$line;

        #ATTACHMENTID,VALIDFROM,VALIDTO,ATTACHMENTTYPE,FILEPATH,FILENAME,PEOPLEREGISTRATION
        $parts{'ATTACHMENTID'} = $fields[0] || 0;
        $parts{'VALIDFROM'} = $fields[1] || '';
        $parts{'VALIDTO'} = $fields[2] || '';
        $parts{'USAGE'} = $fields[3] || '';
        $parts{'ORIGINALFILENAME'} = $fields[4] || '';
        $parts{'PERSONID'} = 0;
        $parts{'PRREGOIMPORT'} = $fields[6] || ''; #0 for now; still waiting for documents

        if ($countOnly)	{
            $insCount++;
            next;
        }

        my $st = qq[
            INSERT INTO tmpImportedDocuments
            (
                strType,
                strPersonCode,
                validFrom,
                validTo,
                strUsage,
                originalFilename,
                PRregoImport
            )
            VALUES (
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
            0,
            $parts{'VALIDFROM'},
            $parts{'VALIDTO'},
            $parts{'USAGE'},
            $parts{'ORIGINALFILENAME'},
            $parts{'PRREGOIMPORT'}
        ) or print "ERROR";
    }
    $count --;
    print STDERR "COUNT CHECK ONLY !!!\n" if $countOnly;

    close INFILE;

}

1;
