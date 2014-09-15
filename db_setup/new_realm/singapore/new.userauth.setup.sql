SET @strRealmName="Singapore", 
    @strStatus="ACTIVE",
    @intEntityLevel="100";

/** Retrieve target realm id **/
SELECT @intRealmID:=intRealmID
FROM tblRealms
WHERE strRealmName = @strRealmName;

/** Load User Acces Files **/
LOAD DATA LOCAL INFILE '/home/jescoto/src/FIFASPOnline/db_setup/new_realm/singapore/ref_data/tblUserAuth.csv'

INTO TABLE tblUserAuth
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
	userId,
	entityTypeId,
	@entityId
)
/** SET data manipulation here**/

SET entityId = (SELECT @intEntityID:=intEntityID
	FROM tblEntity
	WHERE intRealmID = @intRealmID
		AND strLocalName = @entityId)
;


