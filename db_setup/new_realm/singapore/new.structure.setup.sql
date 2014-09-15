/** Realm Settings **/
SET @strRealmName="Singapore", 
    @strStatus="ACTIVE",
    @intEntityLevel="100";

/** Retrieve target realm id **/
SELECT @intRealmID:=intRealmID
FROM tblRealms
WHERE strRealmName = @strRealmName;

/** Retrieve entity id of current realm @intRealmID **/
SELECT @intEntityID:=intEntityID
FROM tblEntity
WHERE intRealmID = @intRealmID
	AND intEntityLevel = @intEntityLevel;

LOAD DATA LOCAL INFILE '/home/jescoto/src/FIFASPOnline/db_setup/new_realm/singapore/ref_data/tblTempEntityStructure.csv'

INTO TABLE tblTempEntityStructure
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
	intRealmID,
	@intParentID,
	intParentLevel,
	@intChildID,
	intChildLevel,
	intDirect,
	intDataAccess,
	intPrimary
)
/** SET data manipulation here**/

SET intRealmID = @intRealmID,
	intParentID = (SELECT @intEntityID:=intEntityID
	FROM tblEntity
	WHERE 	intRealmID = @intRealmID
		AND strLocalShortName = @intParentID),
	intChildID = (SELECT @intEntityID:=intEntityID
	FROM tblEntity
	WHERE 	intRealmID = @intRealmID
		AND strLocalShortName = @intChildID)
;
