/** Set new Realm **/
SET @strRealmName="Philippines", 
	@strLocalShortName="PH";

/** Create new Realm **/
INSERT INTO `tblRealms` (`strRealmName`) 
VALUES (@strRealmName);

/** Get the new Realm ID **/
SELECT @intRealmID:=intRealmID
FROM tblRealms
WHERE strRealmName = @strRealmName;

/** Create new Entity **/
INSERT INTO `tblEntity` (
	`intEntityLevel`, 
	`intRealmID`, 
	`strStatus`, 
	`strLocalName`, 
	`strLocalShortName`, 
	`intDataAccess`
)
VALUES (
	'100', 
	@intRealmID, 
	'ACTIVE', 
	@strRealmName, 
	@strLocalShortName, 
	'10'
);

/** Get the new Entity ID **/
SELECT @intEntityID:=intEntityID
FROM tblEntity
WHERE 	intRealmID = @intRealmID
	AND strLocalShortName = @strLocalShortName;

/** Load Child Entity Files **/
LOAD DATA INFILE '/home/fcascante/src/FIFASPOnline/db_setup/new_realm/philippines/ref_data/tblEntity.csv'
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

/** Load Hierarchy Files **/
LOAD DATA INFILE '/home/fcascante/src/FIFASPOnline/db_setup/new_realm/philippines/ref_data/tblTempEntityStructure.csv'
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

/** Load User Acces Files **/
LOAD DATA INFILE '/home/fcascante/src/FIFASPOnline/db_setup/new_realm/philippines/ref_data/tblUserAuth.csv'
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
	WHERE 	intRealmID = @intRealmID
		AND strLocalShortName = @entityId)
;

SET @c = CONCAT("CREATE TABLE tblPersonRegistration_",@intRealmID,"(
  `intPersonRegistrationID` int(11) NOT NULL AUTO_INCREMENT,
  `intPersonID` int(11) DEFAULT '0',
  `intEntityID` int(11) DEFAULT '0',
  `strPersonType` varchar(20) DEFAULT '',
  `strPersonSubType` varchar(50) DEFAULT '',
  `strPersonLevel` varchar(30) DEFAULT '',
  `strPersonEntityRole` varchar(50) DEFAULT '',
  `strStatus` varchar(20) DEFAULT '',
  `strSport` varchar(20) DEFAULT '',
  `intCurrent` tinyint(4) DEFAULT '0',
  `intOriginLevel` tinyint(4) DEFAULT '0',
  `intOriginID` int(11) DEFAULT '0',
  `dtFrom` date DEFAULT NULL,
  `dtTo` date DEFAULT NULL,
  `intRealmID` int(11) DEFAULT '0',
  `intSubRealmID` int(11) DEFAULT '0',
  `dtAdded` datetime DEFAULT NULL,
  `dtLastUpdated` datetime DEFAULT NULL,
  `intIsPaid` tinyint(4) DEFAULT '0',
  `intNationalPeriodID` int(11) NOT NULL DEFAULT '0',
  `intAgeGroupID` int(11) NOT NULL DEFAULT '0',
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `intCreatedByUserID` int(11) DEFAULT '0',
  `strPreTransferredStatus` varchar(30) DEFAULT '',
  `strAgeLevel` varchar(100) DEFAULT '',
  `intPaymentRequired` tinyint(4) DEFAULT '0',
  `strRegistrationNature` varchar(30) DEFAULT '',
  `intClearanceID` int(11) DEFAULT '0',
  PRIMARY KEY (`intPersonRegistrationID`),
  KEY `index_intPersonID` (`intPersonID`),
  KEY `index_intEntityID` (`intEntityID`),
  KEY `index_strPersonType` (`strPersonType`),
  KEY `index_strStatus` (`strStatus`),
  KEY `index_IDs` (`intEntityID`,`intPersonID`)
) ENGINE=InnoDB AUTO_INCREMENT=2278 DEFAULT CHARSET=utf8;");

PREPARE stmt from @c;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;