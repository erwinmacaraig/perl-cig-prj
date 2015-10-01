package Logo;
require Exporter;
@ISA =  qw(Exporter);
@EXPORT = qw(convertToLogo);
@EXPORT_OK = qw(convertToLogo);

use strict;
use lib "..",".";
use Defs;
use Utils;

use S3Upload;

#functions

#getLogo
#showLogo
#convertToLogo - from documentId

sub convertToLogo {
    my (
        $Data,
        $entityTypeID,
        $entityID,
        $fileID,
    ) = @_;

    my $statement=qq[
        SELECT 
            strPath,
            strFilename,
            strExtension
        FROM 
            tblUploadedFiles
        WHERE 
            intFileID = ?
    ];
    my $db = $Data->{'db'};
    my $query = $db->prepare($statement);
    $query->execute($fileID);
    my $dref =$query->fetchrow_hashref();
    $query->finish();
    if($dref)   {
        my $existingKey = $dref->{'strPath'}.$dref->{'strFilename'}.'.'.$dref->{'strExtension'};
        my $newKey = "logo/$entityTypeID/$entityID".'.'.$dref->{'strExtension'};
        copyFileInS3($existingKey, $newKey);

        my $updateSQL = qq[
            INSERT INTO tblLogo (
                intEntityTypeID,
                intEntityID,
                strPath,
                strFilename,
                strExtension
            )
            VALUES (
                ?,
                ?,
                ?,
                ?,
                ?
            )
            ON DUPLICATE KEY UPDATE
                strPath = ?,
                strFilename = ?,
                strExtension = ?
        ];
        my $qu = $db->prepare($updateSQL);
        $qu->execute(
            $entityTypeID,
            $entityID,
            "logo/$entityTypeID/",
            $entityID,
            $dref->{'strExtension'},
            "logo/$entityTypeID/",
            $entityID,
            $dref->{'strExtension'},
        );
        $qu->finish();
    }
    return 1;
}


