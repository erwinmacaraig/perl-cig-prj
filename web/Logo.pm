package Logo;
require Exporter;
@ISA =  qw(Exporter);
@EXPORT = qw(convertToLogo getLogo getLogoData);
@EXPORT_OK = qw(convertToLogo getLogo getLogoData);

use strict;
use lib "..",".";
use Defs;
use Reg_common;
use Utils;

use S3Upload;

#functions

sub getLogo {
    my (
        $Data,
        $entityTypeID,
        $entityID,
        $logoData,
    ) = @_;

    if(!$logoData)  {
        $logoData = getLogoData(
            $Data,
            $entityTypeID,
            $entityID,
        );
    }
    if(
        $logoData
        and $logoData->{'strPath'}
        and $logoData->{'strExtension'}
        and $logoData->{'strFilename'}
    )   {
        my %clientValues = %{$Data->{'clientValues'}};
        $clientValues{'currentLevel'} = $entityTypeID;
        setClientValue(\%clientValues,$entityTypeID, $entityID);
        my $newclient = setClient(\%clientValues);
        my $url = "$Defs::base_url/photologo.cgi?client=$newclient";
        return $url;
    }
    return '';
}

sub getLogoData {
    my (
        $Data,
        $entityTypeID,
        $entityID,
    ) = @_;
    return undef if !$entityTypeID;
    return undef if !$entityID;
    my $st = qq[
        SELECT
            strPath,
            strFilename,
            strExtension
        FROM
            tblLogo
        WHERE
            intEntityTypeID = ?
            AND intEntityID = ?
    ];

    my $db = $Data->{'db'};
    my $query = $db->prepare($st);
    $query->execute(
        $entityTypeID,
        $entityID,
    );
    my $dref =$query->fetchrow_hashref();
    $query->finish();
    return $dref || undef;
}

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


