package SphinxUpdate;
require Exporter;
@ISA    = qw(Exporter);
@EXPORT = @EXPORT_OK = qw(
  updateSphinx
);

use strict;
use lib '.', '..';
use Defs;
use DBI;

sub updateSphinx {
    my ($db, $cache, $type, $actionType, $object) = @_;
    return 0 if !$object;
    return 0 if !$object->ID();
    my $realm= $object->getValue('intRealmID') || 0;
    my $indexName =$Defs::SphinxIndexes{$type};
    return 0 if !$indexName;
    $indexName .= '_r' . $realm;
    my $actionstring = $actionType eq 'insert'
        ? 'INSERT'
        : 'REPLACE';

    if($type eq 'Person')   {
        my $sphinx = connectSphinx();
        my $personID = $object->ID();
        my $fname = $object->getValue('strLocalFirstname') || '';
        my $sname = $object->getValue('strLocalSurname') || '';
        my $natnum = $object->getValue('strNationalNum') || '';
        my $entityIDs = '';
        {
            my $st_e = qq[
                SELECT intEntityID 
                FROM tblPersonRegistration_$realm 
                WHERE 
                    intPersonID = ?
                    AND strStatus NOT IN('DELETED','ROLLED_OVER')
            ];
            my $q = $db->prepare($st_e);
            $q->execute($personID);
            my @ids = ();
            while(my($eID) = $q->fetchrow_array())  {
                push @ids, $eID;
            }
            $entityIDs = join(',',@ids); 
        }
        my $st = qq[
            $actionstring INTO $indexName (
                id,
                strLocalFirstname,
                strLocalSurname,
                intRealmID,
                strNationalNum,
                intEntityID
            )
            VALUES (
                ?,
                ?,
                ?,
                ?,
                ?,
                ($entityIDs)
            )
        ];
        my $q = $sphinx->prepare($st);
        $q->execute(
            $personID,
            $fname,
            $sname,
            $realm,         
            $natnum,
        );

    }

    if($type eq 'Entity')   {
        my $sphinx = connectSphinx();
        my $entityID = $object->ID();
        my $name = $object->getValue('strLocalName') || '';
        my $shortname = $object->getValue('strLocalShortName') || '';
        my $latinname = $object->getValue('strLatinName') || '';
        my $latinshortname = $object->getValue('strLatinShortName') || '';
        my $fifaid = $object->getValue('strFIFAID') || '';
        my $maid = $object->getValue('strMAID') || '';
        my $entitylevel = $object->getValue('intEntityLevel') || '';
        my $entitytype = $object->getValue('strEntityType') || '';
        my $entityIDs = '';
        {
            my $st_e = qq[
                SELECT intParentID 
                FROM tblTempEntityStructure
                WHERE 
                    intChildID = ?
            ];
            my $q = $db->prepare($st_e);
            $q->execute($entityID);
            my @ids = ();
            while(my($eID) = $q->fetchrow_array())  {
                push @ids, $eID;
            }
            $entityIDs = join(',',@ids); 
        }
        my $st = qq[
            $actionstring INTO $indexName (
                id,
                strLocalName,
                strFIFAID,
                strMAID,
                strLocalShortName,
                strLatinName,
                strLatinShortName,
                intRealmID,
                intEntityLevel,
                strEntityType,
                intParentID
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
                ($entityIDs)
            )
        ];
        my $q = $sphinx->prepare($st);
        $q->execute(
            $entityID,
            $name,
            $fifaid,
            $maid,
            $shortname,
            $latinname,
            $latinshortname,
            $realm,         
            $entitylevel,         
            $entitytype,         
        );

    }


    return 1;
}

sub connectSphinx {
    my $dsn = 'DBI:mysql:;host='.$Defs::Sphinx_Host . ';port=' . $Defs::Sphinx_PortSQL;
    my $sphinx = DBI->connect($dsn, '','');

    if (!defined $sphinx) { return "Sphinx Error"; }
    else  { return $sphinx; }

}


1;
