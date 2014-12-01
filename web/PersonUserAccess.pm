package PersonUserAccess;
require Exporter;
@ISA = qw(Exporter);


@EXPORT = @EXPORT_OK = qw(
    doesUserHaveAccess
    doesUserHaveEntityAccess
);

use lib ".", "..";
use strict;
use Reg_common;
use Utils;
use Data::Dumper;

# This job of this module is to work out whether a particular logged in user 
# has access to a person's details

sub doesUserHaveAccess  {
    my (
        $Data,
        $personID,
        $accessType,
        $authLevel,
    ) = @_;

    my $client = setClient( $Data->{'clientValues'} ) || '';
	my $entityID = $authLevel
        ? getID($Data->{'clientValues'}, $Data->{'clientValues'}{'authLevel'})
        : getLastEntityID($Data->{'clientValues'});

    #TODO: might use priority column in the query, then limit the result to 1 grouped by club
    # FOOTBALL  | 1
    # FUTSAL    | 2
    # ACTIVE    | 1
    # PASSIVE   | 2
    # PENDING   | 3
    
    my $st = qq[
        SELECT
            PR.intEntityID,
            P.intPersonID,
            P.strStatus,
            PR.strPersonLevel,
            PREQ.intPersonID,
            PREQ.intRequestFromEntityID,
            PREQ.intPersonRequestID,
            IF(PR.strPersonLevel = 'PROFESSIONAL', 3, IF(PR.strPersonLevel = 'AMATEUR', 2, 1)) as personLevelWeight
        FROM
            tblPerson P
            LEFT JOIN tblPersonRegistration_$Data->{'Realm'} PR
                ON (
                    PR.intPersonID = P.intPersonID
                    AND PR.intRealmID = P.intRealmID
                    AND PR.strStatus IN ('ACTIVE', 'PASSIVE','PENDING')
                )
            LEFT JOIN tblPersonRequest PREQ
                ON (
                    PREQ.intPersonID = P.intPersonID
                    AND PREQ.strRequestResponse = 'ACCEPTED'
                )
        WHERE
            P.intRealmID = ?
            AND P.intPersonID = ?
            AND P.strStatus IN ('REGISTERED', 'PASSIVE','PENDING','INPROGRESS')
    ];

    my $db = $Data->{'db'};
    my $q = $db->prepare($st);
    $q->execute(
        $Data->{'Realm'},
        $personID,
    );

    my %entities  = ();

    my $count = 1;
    while(my $dref = $q->fetchrow_hashref()) {
        if($dref->{'strStatus'} eq 'INPROGRESS')    {
            #person is in the process of being initially registered - everyone has access
            return 1;
        }
        $entities{'WRITE'}{$dref->{'intEntityID'}} = 1 if $count == 1;
        $entities{'WRITE'}{$dref->{'intRequestFromEntityID'}} = 1 if $count > 1;
        $entities{'READ'}{$dref->{'intEntityID'}} = 1;
        $entities{'READ'}{$dref->{'intRequestFromEntityID'}} = 1;
        $count++;
    }

    # we have worked out which entities have what kind of access 
    # now need to compare to where we are

    return 1 if $entities{$accessType}{$entityID};
    
    #if we are here then the person isn't directly registered to the current entity

    $st = qq[
        SELECT
            intChildID 
        FROM
            tblTempEntityStructure
        WHERE
            intParentID = ?
            AND intDataAccess = $Defs::DATA_ACCESS_FULL
    ];
    $q = $Data->{'db'}->prepare($st);
    $q->execute($entityID);
    while(my($eID) = $q->fetchrow_array())  {
        return 1 if $entities{$accessType}{$eID};
    }

    return 0;
}

sub doesUserHaveEntityAccess  {
    my (
        $Data,
        $entityID,
        $accessType,
        $authLevel,
    ) = @_;

    my $client = setClient( $Data->{'clientValues'} ) || '';
	my $topEntityID = getID($Data->{'clientValues'}, $Data->{'clientValues'}{'authLevel'});
    #if we are here then the person isn't directly registered to the current entity

    my $st = qq[
        SELECT
            intChildID 
        FROM
            tblTempEntityStructure
        WHERE
            intParentID = ?
            AND intChildID = ?
            AND intDataAccess = $Defs::DATA_ACCESS_FULL
    ];
    my $q = $Data->{'db'}->prepare($st);
    $q->execute($topEntityID, $entityID);
    my ($found) = $q->fetchrow_array();
    $q->finish();
    return $found || 0;
}
1;
