
LOAD DATA LOCAL INFILE '/home/jescoto/src/FIFASPOnline/db_setup/new_realm/singapore/ref_data/tblEntityLinks.csv'

INTO TABLE tblEntityLinks
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    @intParentEntityID,
	@intChildEntityID,
	intPrimary,
    tTimeStamp
)

SET intParentEntityID = (SELECT @intEntityID:=intEntityID
	FROM tblEntity
		WHERE strLocalName = @intParentEntityID),
	intChildEntityID = (SELECT @intEntityID:=intEntityID
	FROM tblEntity
        WHERE strLocalName = @intChildEntityID)
;
