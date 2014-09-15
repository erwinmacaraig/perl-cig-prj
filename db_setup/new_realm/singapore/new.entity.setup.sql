SET @strRealmName="Singapore", 
    @strStatus="ACTIVE",
    @intDataAccess="10";

/** Get the Realm ID **/
SELECT @intRealmID:=intRealmID
FROM tblRealms
WHERE strRealmName = @strRealmName;

/** Load Child Entity Files **/
LOAD DATA LOCAL INFILE '/home/jescoto/src/FIFASPOnline/db_setup/new_realm/singapore/ref_data/tblEntity.csv'

INTO TABLE tblEntity
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
	intEntityLevel,
	intRealmID,
	strStatus,
	strLocalName,
	strLocalShortName,
	strISOCountry,
	strPostalCode,
	strTown,
	strAddress,
	strPhone,
	intDataAccess
)

/** SET data manipulation here**/
SET intRealmID = @intRealmID;
