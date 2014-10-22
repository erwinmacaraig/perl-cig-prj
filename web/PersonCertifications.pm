package PersonCertifications;
require Exporter;
@ISA    = qw(Exporter);
@EXPORT = @EXPORT_OK = qw(
  getPersonCertifications
  getPersonCertificationTypes
  addPersonCertification
  deletePersonCertification
);

use strict;
use lib '.', '..';
use Defs;

sub getPersonCertifications {

    my (
        $Data, 
        $personID,
        $type,
        $all,
    ) = @_;

    $all ||= 0;
    $type ||= '';
    my @certifications = ();
    my $db=$Data->{'db'};
    my $realmID=$Data->{'Realm'} || 0;
    my $subtypeID =$Data->{'RealmSubType'} || 0;
    
    if($db) {
        my $statusfilter = $all ? '' : " AND strStatus = 'ACTIVE' ";
        my $typefilter = '';
        my @vals = (
            $realmID,
            $personID,
        );
        if($type)   {
            $typefilter = " AND CT.strCertificationType = ? ";
            push @vals, $type;
        }
        my $statement=qq[
            SELECT 
                PC.intCertificationID,
                PC.intPersonID,
                PC.intCertificationTypeID,
                PC.dtValidFrom,
                PC.dtValidUntil,
                PC.strDescription,
                PC.strStatus,
                CT.strCertificationName,
                CT.strCertificationType
            FROM 
                tblPersonCertifications AS PC
                INNER JOIN tblCertificationTypes AS CT
                    ON PC.intCertificationTypeID = CT.intCertificationTypeID
            WHERE 
                PC.intRealmID = ?
                AND PC.intPersonID = ?
                $statusfilter
                $typefilter

            ORDER BY
                CT.strCertificationType,
                PC.dtValidFrom,
                PC.dtValidUntil
        ];
        my $query = $db->prepare($statement);
        $query->execute(@vals);
        while (my $dref = $query->fetchrow_hashref) {
            push @certifications, $dref;
        }
    }
    return \@certifications;
}

sub getPersonCertificationTypes {

    my (
        $Data, 
        $type,
    ) = @_;

    $type ||= '';
    my @certifications = ();
    my $db=$Data->{'db'};
    my $realmID=$Data->{'Realm'} || 0;
    my $subtypeID =$Data->{'RealmSubType'} || 0;
    
    if($db) {
        my $typefilter = '';
        my @vals = (
            $realmID,
        );
        if($type)   {
            $typefilter = " AND CT.strCertificationType = ? ";
            push @vals, $type;
        }
        my $statement=qq[
            SELECT 
                CT.intCertificationTypeID,
                CT.strCertificationType,
                CT.strCertificationName
            FROM 
                tblCertificationTypes AS CT
            WHERE 
                CT.intRealmID = ?
                AND intActive = 1
                $typefilter

            ORDER BY
                CT.strCertificationType,
                CT.strCertificationName
        ];
        my $query = $db->prepare($statement);
        $query->execute(@vals);
        while (my $dref = $query->fetchrow_hashref) {
            push @certifications, $dref;
        }
    }
    return \@certifications;
}

sub addPersonCertification {

    my (
        $Data, 
        $personID,
        $type,
        $from,
        $until,
        $description,
        $status,
    ) = @_;

    $status ||= 'ACTIVE';
    $description ||= '';
    $from ||= '';
    $until ||= '';
    

    $type ||= 0;
    my @certifications = ();
    my $db=$Data->{'db'};
    my $realmID=$Data->{'Realm'} || 0;
    my $subtypeID =$Data->{'RealmSubType'} || 0;
    
    if(!$personID and $type)    {
        return 0;
    }
    if($db) {
        my $statement=qq[
            INSERT INTO tblPersonCertifications (
                intPersonID,
                intRealmID,
                intCertificationTypeID,
                dtValidFrom,
                dtValidUntil,
                strDescription,
                strStatus
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
        my $query = $db->prepare($statement);
        $query->execute((
            $personID,
            $realmID,
            $type,
            $from,
            $until,
            $description,
            $status,
        ));
        if($DBI::errstr)    {
            warn($DBI::errstr);
            return 0;
        }
        return 1;
    }
}

1;
