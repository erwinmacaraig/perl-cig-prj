package NationalNumber;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = @EXPORT_OK = qw(
	assignNationalNumber 
);

use strict;
use lib '.', '..', 'Clearances',"../web/user";
use Utils;
use GenCode;
use InstanceOf;
use Reg_common;
use AuditLog;

sub assignNationalNumber {
    my (
        $Data, 
        $type, 
        $id,
        $personRegistrationID,
    ) = @_;

    if($type eq 'PERSON')   {
        my $person = getInstanceOf($Data, 'person',$id);
        if($person and $person->ID())   {
            my $natnum = $person->getValue('strNationalNum');
            if(!$natnum)    {

                my %params = (
                    'dob' => $person->getValue('dtDOB'),
                    'gender' => $person->getValue('intGender'),
                    'nationality' => $person->getValue('strISONationality'),
                    'countryofbirth' => $person->getValue('strISOCountryOfBirth'),
                );
                my $RegionEntityID = getRegionEntityID($Data, $id, $Defs::LEVEL_STATE, $personRegistrationID);
                my $code = new GenCode(
                    $Data->{'db'}, 
                    'PERSON',
                    $Data->{'Realm'}, 
                    $Data->{'RealmSubType'}, 
                    $RegionEntityID, 
                );
                my $newNumber = $code->getNumber(\%params);
                if($newNumber)  {
                    $person->setValues({ strNationalNum => $newNumber });
                    $person->write();
                    $Data->{'cache'}->delete('swm','PersonObj-'.$id) if $Data->{'cache'};
                auditLog($id, $Data, 'Assign National Number', 'Person');
                }
            }

        }

    }
    elsif(
        $type eq 'ENTITY'
        or $type eq 'FACILITY'
    )   {
        my $entity = getInstanceOf($Data, 'entity',$id);
        if($entity and $entity->ID())   {
            my $natnum = $entity->getValue('strMAID');
            if(!$natnum)    {

                my %params = (
                    'entityType' => $entity->getValue('strEntityType') || '',
                );
                my $RegionEntityID = getRegionEntityID($Data, $id, $Defs::LEVEL_REGION);
                my $code = new GenCode(
                    $Data->{'db'}, 
                    $type,
                    $Data->{'Realm'}, 
                    $Data->{'RealmSubType'}, 
                    $RegionEntityID, 
                );
                my $newNumber = $code->getNumber(\%params);
                if($newNumber)  {
                    $entity->setValues({ strMAID => $newNumber });
                    $entity->write();
                    $Data->{'cache'}->delete('swm','EntityObj-'.$id) if $Data->{'cache'};
            auditLog($id, $Data, 'Assign National Number', 'Entity');
                }
            }
        }
    }

    return '';
}


sub getRegionEntityID   {
    my (
        $Data, 
        $entityID, 
        $targetLevel,
        $personRegistrationID,
    ) = @_;

    if($personRegistrationID)   {
        my $realmID = $Data->{'Realm'};
        my $st = qq[
            SELECT
                intEntityID
            FROM
                tblPersonRegistration_$realmID
            WHERE
                intPersonRegistrationID = ?
            LIMIT 1
        ];
        my $query = $Data->{'db'}->prepare($st);
        $query->execute(
            $personRegistrationID,
        );
        ($entityID) = $query->fetchrow_array();
        $query->finish();
    }

    return 0 if !$entityID;

    my $st = qq[
        SELECT
            intParentID
        FROM
            tblTempEntityStructure
        WHERE
            intChildID = ?
            AND intParentLevel = ?
        LIMIT 1
    ];
    my $query = $Data->{'db'}->prepare($st);
    $query->execute(
        $entityID,
        $targetLevel,
    );
    my ($parentID) = $query->fetchrow_array();
    $query->finish();
    return $parentID || 0;
}

1;
