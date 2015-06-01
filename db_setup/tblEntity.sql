DROP TABLE IF EXISTS tblEntity;
CREATE TABLE `tblEntity` (
  `intEntityID` int(11) NOT NULL AUTO_INCREMENT,
  `intEntityLevel` int(11) DEFAULT '0' COMMENT 'integer level of this entity that determined if it is club, region or national etc.',
  `intRealmID` int(11) DEFAULT '0' COMMENT 'To which realm this entity belongs to',
  `intSubRealmID` int(11) NOT NULL DEFAULT '0',
  `strEntityType` varchar(30) DEFAULT '' COMMENT 'his type represents a generic entity and its attributes.',
  `strStatus` varchar(20) DEFAULT '' COMMENT 'The status of this entity. ACTIVE, INACTIVE, PENDING, SUSPENDED, DESOLVED',
  `intCreatedByEntityID` int(11) DEFAULT '0',
  `strFIFAID` varchar(30) DEFAULT '' COMMENT 'The worldwide unique FIFA ID of this entity.',
  `strMAID` varchar(30) DEFAULT NULL,
  `strLocalName` varchar(100) DEFAULT '' COMMENT 'The name of a organization in local language (the language specified by LocalNameLanguage attribute).',
  `strLocalShortName` varchar(100) DEFAULT '' COMMENT 'The short name of a organization in local language (the language specified by LocalNameLanguage attribute).',
  `intLocalLanguage` INT NOT NUL DEFAULT 0 COMMENT 'The language the localized names(LocalName and LocalShortName) are written in.',
  `strLocalFacilityName` varchar(150) DEFAULT '',
  `strLatinName` varchar(100) DEFAULT '' COMMENT 'The full name of the organization in Latin script/alphabet. For a club this is for example Ballsportverein Borussia Dortmund e.V.',
  `strLatinShortName` varchar(100) DEFAULT '' COMMENT 'The short name (or abbreviation) of the organization in Latin script/alphabet. As an example this could be FIFA or BVB.',
  `strLatinFacilityName` varchar(150) DEFAULT '' COMMENT 'The name (or abbreviation) of the Facility. As an example this could be Wembley or Camp Nou.',
  `dtFrom` date DEFAULT NULL COMMENT 'The date when the Entity was founded.',
  `dtTo` date DEFAULT NULL COMMENT 'The date when the Organization was dissolved or superseded by another Organization.',
  `strISOCountry` varchar(10) DEFAULT '' COMMENT 'The country code of this entity.',
  `strRegion` varchar(50) DEFAULT '' COMMENT 'The state, province or region of the address.',
  `strPostalCode` varchar(15) DEFAULT '' COMMENT 'The postal code or a similar construct.',
  `strTown` varchar(100) DEFAULT '' COMMENT 'The town, village or location name of the address.',
  `strCity` VARCHAR(100) NULL DEFAULT NULL,
  `strState` VARCHAR(100) NULL DEFAULT NULL,
  `strAddress` varchar(200) DEFAULT '' COMMENT 'The address, i.e. street name, number and any additional relevant address information.',
  `strAddress2` varchar(200) DEFAULT NULL COMMENT 'Secondary address detail',
  `strWebURL` varchar(200) DEFAULT '' COMMENT 'The web address of this entity.',
  `strEmail` varchar(200) DEFAULT '' COMMENT 'The primary email of this entity',
  `strPhone` varchar(20) DEFAULT '' COMMENT 'The primary phone number of this entity.',
  `strFax` varchar(20) DEFAULT '' COMMENT 'The primary fax number of this entity.',
  `strAssocNature` varchar(50) DEFAULT NULL,
  `strMANotes` varchar(250) DEFAULT NULL,
  `intLegalTypeID` int(11) DEFAULT NULL COMMENT 'Type of Legal ID provided as listed in the tblLegalType Table',
  `strLegalID` varchar(45) DEFAULT NULL COMMENT 'a field to type in the ID that corresponds to the LegalType',
  `strContactTitle` varchar(50) DEFAULT NULL,
  `strContact` varchar(50) DEFAULT NULL,
  `strContactEmail` varchar(200) DEFAULT NULL,
  `strContactPhone` varchar(50) DEFAULT NULL,
  `strContactCity` VARCHAR(100) NULL DEFAULT NULL,
  `strContactISOCountry` VARCHAR(10) NULL DEFAULT NULL,
  `dtAdded` datetime DEFAULT NULL,
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `intCapacity` int(11) DEFAULT '0' COMMENT 'The maximum number of people allowed as audience/spectators.',
  `intCoveredSeats` int(11) DEFAULT '0',
  `intUncoveredSeats` int(11) DEFAULT '0',
  `intCoveredStandingPlaces` int(11) DEFAULT '0',
  `intUncoveredStandingPlaces` int(11) DEFAULT '0',
  `intLightCapacity` int(11) DEFAULT '0',
  `strGroundNature` varchar(100) DEFAULT '' COMMENT 'The type of ground in the stadium, e.g. natural grass or artificial turf.',
  `strDiscipline` varchar(100) DEFAULT '' COMMENT 'The discipline/sport which is being played on the stadium.',
  `strGender` varchar(10) DEFAULT NULL,
  `strMapRef` varchar(20) DEFAULT '',
  `intMapNumber` int(11) DEFAULT '0',
  `dblLat` double DEFAULT '0',
  `dblLong` double DEFAULT '0',
  `strDescription` text,
  `intDataAccess` tinyint(4) NOT NULL DEFAULT '10',
  `intPaymentRequired` tinyint(4) DEFAULT '0',
  `intIsPaid` tinyint(4) DEFAULT '0',
  `strShortNotes` varchar(255) DEFAULT NULL,
  `strImportEntityCode` varchar(45) DEFAULT NULL COMMENT 'Reference to the imported records inputted by client',
  `intImportID` int(11) DEFAULT NULL COMMENT 'Tracking ID on which batch this record is included during import',
  `intAcceptSelfRego` INT NULL DEFAULT 1 COMMENT 'Allow an Entity to determine if they accept self registration FC-231',
  `intRealmApproved` tinyint(4) DEFAULT '0',
  `strPaymentNotificationAddress` varchar(250) DEFAULT NULL,
  `strEntityPaymentBusinessNumber` varchar(100) DEFAULT NULL,
  `strEntityPaymentInfo` text,
  `intNotifications` INT NOT NULL DEFAULT 1 COMMENT 'Flag to check whether to send notifications or not.',
  `strOrganisationLevel` VARCHAR(45) NULL,
  `intFacilityTypeID` INT NULL,
  intWasActivatedByPayment tinyint default 0 COMMENT 'Debug flag for if record was auto activated by Payment',
  `strBankAccountNumber` VARCHAR(100) NULL COMMENT 'International Bank Account Number (IBAN)',
  PRIMARY KEY (`intEntityID`),
  UNIQUE KEY `strImportEntityCode_UNIQUE` (`strImportEntityCode`),
  KEY `index_intRealmID` (`intRealmID`),
  KEY `index_intEntityLevel` (`intEntityLevel`)
) ENGINE=InnoDB AUTO_INCREMENT=1434 DEFAULT CHARSET=utf8;

