DROP TABLE IF EXISTS tblPersonRegistrationStatusChangeLog;
CREATE TABLE `tblPersonRegistrationStatusChangeLog` (
    `intPersonRegistrationStatusChangeLogID` INT NOT NULL AUTO_INCREMENT,
    `intPersonRegistrationID` INT NOT NULL COMMENT 'The person registration id',
    `dtChanged` DATETIME NOT NULL COMMENT 'Date the status changed',
    `intOriginLevel` INT NOT NULL COMMENT 'Entity level the status change originated',
    `intUserID` INT NOT NULL COMMENT 'User who initiated the status change',
    `strOldStatus` VARCHAR(30) NOT NULL COMMENT 'Old status',
    `strNewStatus` VARCHAR(30) NOT NULL COMMENT 'New status',
    PRIMARY KEY (`intPersonRegistrationStatusChangeLogID`)
) DEFAULT CHARACTER SET = utf8;

