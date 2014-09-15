/** Set new Realm **/
SET @strRealmName="Singapore", 
	@strLocalShortName="SIN",
    @intEntityLevel="100",
    @strStatus="ACTIVE",
    @intDataAccess="10";

/** Create new Realm (added checking of duplicate) **/
INSERT INTO `tblRealms` (
    `strRealmName`,
    `strRealmAdType`
) 
    SELECT * FROM (
        SELECT @strRealmName, ''
    ) AS tmptblRealms
    WHERE NOT EXISTS (
        SELECT * FROM `tblRealms`
        WHERE strRealmName = @strRealmName
    );

/** Get the new Realm ID **/
SELECT @intRealmID:=intRealmID
FROM tblRealms
WHERE strRealmName = @strRealmName;

/** Create new National Level Entity (added duplicate checks using intEntityLevel, strLocalName and intRealmID) **/
INSERT INTO `tblEntity` (
	`intEntityLevel`, 
	`intRealmID`, 
	`strStatus`, 
	`strLocalName`, 
	`strLocalShortName`, 
	`intDataAccess`
)
    SELECT * FROM (
        SELECT
            @intEntityLevel,
            @intRealmID,
            @strStatus,
            @strRealmName,
            @strLocalShortName,
            @intDataAccess
    ) AS tmptblEntity 
    WHERE NOT EXISTS (
        SELECT * from `tblEntity`
        WHERE
            intEntityLevel = @intEntityLevel
            AND strLocalName = @strRealmName
            AND intRealmID = @intRealmID
    );

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

SET @c = CONCAT("CREATE TABLE tblSnapShotMemberCounts_",@intRealmID,"(
  `intEntityTypeID` int(11) NOT NULL,
  `intEntityID` int(11) NOT NULL,
  `intYear` int(11) NOT NULL,
  `intMonth` tinyint(4) NOT NULL,
  `intSeasonID` int(11) NOT NULL DEFAULT '0',
  `intGender` tinyint(4) NOT NULL DEFAULT '0',
  `intAgeGroupID` int(11) NOT NULL DEFAULT '0',
  `intMembers` int(11) NOT NULL DEFAULT '0',
  `intNewMembers` int(11) NOT NULL DEFAULT '0',
  `intRegoFormMembers` int(11) NOT NULL DEFAULT '0',
  `intPermitMembers` int(11) NOT NULL DEFAULT '0',
  `intPlayer` int(11) NOT NULL DEFAULT '0',
  `intCoach` int(11) NOT NULL DEFAULT '0',
  `intUmpire` int(11) NOT NULL DEFAULT '0',
  `intOther1` int(11) NOT NULL DEFAULT '0',
  `intOther2` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`intYear`,`intMonth`,`intEntityTypeID`,`intEntityID`,`intGender`,`intAgeGroupID`),
  KEY `index_Entity` (`intEntityTypeID`,`intEntityID`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;");

PREPARE stmt from @c;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
