package Authorize;
require Exporter;
@ISA = qw(Exporter);
@EXPORT=qw(entityAllowed);
@EXPORT_OK=qw(entityAllowed);

use strict;
use Reg_common;
use Utils;
use AuditLog;
use CGI qw(unescape param);
use Log;


sub entityAllowed{
    #Check if this user is allowed access to this entity
    my ($Data, $recordID,$entityLevel) = @_;

    #Get parent entity and check that the user has access to that

    my $st = qq[
        SELECT
            intParentEntityID
        FROM
            tblEntityLinks AS EL
                INNER JOIN tblEntity AS E
                    ON EL.intChildEntityID = E.intEntityID
        WHERE
            intChildEntityID = ?
            AND intEntityLevel = ?
        LIMIT 1
    ];
    
   
    
    my $query = $Data->{'db'}->prepare($st);
    $query->execute($recordID,$entityLevel);
    my $parentID = $query->fetchrow_array() || 0;
    $query->finish();
    return 0 if !$parentID;
    my $authID = getID($Data->{'clientValues'}, $Data->{'clientValues'}{'authLevel'});
    return 1 if($authID== $parentID);
    $st = qq[
        SELECT
            intRealmID
        FROM
            tblTempEntityStructure
        WHERE
            intParentID = ?
            AND intChildID = ?
            AND intDataAccess = $Defs::DATA_ACCESS_FULL
        LIMIT 1
    ];
    $query = $Data->{'db'}->prepare($st);
    $query->execute($parentID, $authID);
    my ($found) = $query->fetchrow_array();
    $query->finish();
    return $found ? 1 : 0;
}
1;