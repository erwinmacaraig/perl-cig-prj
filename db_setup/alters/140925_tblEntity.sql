ALTER TABLE `tblEntity`
CHANGE COLUMN `intEntityLevel` `intEntityLevel` INT(11) NULL DEFAULT '0' COMMENT 'integer level of this entity that determined if it is club, region or national etc.' ,
CHANGE COLUMN `intRealmID` `intRealmID` INT(11) NULL DEFAULT '0' COMMENT 'To which realm this entity belongs to' ,
CHANGE COLUMN `strEntityType` `strEntityType` VARCHAR(30) NULL DEFAULT '' COMMENT 'his type represents a generic entity and its attributes.' ,
CHANGE COLUMN `strLocalName` `strLocalName` VARCHAR(100) NULL DEFAULT '' COMMENT 'The name of a organization in local language (the language specified by LocalNameLanguage attribute).' ,
CHANGE COLUMN `strLocalShortName` `strLocalShortName` VARCHAR(100) NULL DEFAULT '' COMMENT 'The short name of a organization in local language (the language specified by LocalNameLanguage attribute).' ,
CHANGE COLUMN `strISOLocalLanguage` `strISOLocalLanguage` VARCHAR(20) NULL DEFAULT NULL COMMENT 'The language the localized names(LocalName and LocalShortName) are written in.' ,
CHANGE COLUMN `strLatinName` `strLatinName` VARCHAR(100) NULL DEFAULT '' COMMENT 'The full name of the organization in Latin script/alphabet. For a club this is for example Ballsportverein Borussia Dortmund e.V.' ,
CHANGE COLUMN `strLatinShortName` `strLatinShortName` VARCHAR(100) NULL DEFAULT '' COMMENT 'The short name (or abbreviation) of the organization in Latin script/alphabet. As an example this could be FIFA or BVB.' ,
CHANGE COLUMN `dtFrom` `dtFrom` DATE NULL DEFAULT NULL COMMENT 'The date when the Entity was founded.' ,
CHANGE COLUMN `dtTo` `dtTo` DATE NULL DEFAULT NULL COMMENT 'The date when the Organization was dissolved or superseded by another Organization.' ,
CHANGE COLUMN `intSubRealmID` `intSubRealmID` INT(11) NOT NULL DEFAULT '0' AFTER `intRealmID`,
CHANGE COLUMN `strStatus` `strStatus` VARCHAR(20) NULL DEFAULT '' COMMENT 'The status of this entity. ACTIVE, INACTIVE, PENDING, SUSPENDED, DESOLVED' ,
ADD COLUMN `strAcceptSelfRego` VARCHAR(15) NULL COMMENT 'Allow an Entity to determine if they accept self registration FC-231' AFTER `intImportID`;
