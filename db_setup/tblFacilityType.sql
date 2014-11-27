CREATE TABLE `fifasponline`.`tblFacilityType` (
    `intFacilityTypeID` INT NOT NULL AUTO_INCREMENT,
    `intRealmID` INT NOT NULL,
    `intSubRealmID` INT NULL,
    `strName` VARCHAR(100) NOT NULL DEFAULT '',
    `dtTimeStamp` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`intFacilityTypeID`),
    INDEX `index_intRealmID` (`intRealmID` ASC))
    ENGINE = InnoDB
    DEFAULT CHARACTER SET = utf8
COMMENT = 'High Level Types of Facility (Stadium, Football Pitch, Training Grounds, Venue, etc)';
