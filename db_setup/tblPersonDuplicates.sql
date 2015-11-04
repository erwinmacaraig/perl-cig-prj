DROP TABLE IF EXISTS tblPersonDuplicates;
CREATE TABLE `tblPersonDuplicates` (
    `intPersonDuplicateID` INT NOT NULL AUTO_INCREMENT,
    `intChildPersonID` INT NOT NULL COMMENT 'The person who was the duplicate',
    `intParentPersonID` INT NOT NULL COMMENT 'Parent Person',
    `dtAdded` DATETIME NOT NULL COMMENT 'Date the record first added',
    `dtUpdated` DATETIME NOT NULL COMMENT 'Date updated',
    PRIMARY KEY (`intPersonDuplicateID`),
    INDEX key_ChildPersonID (intChildPersonID),
    INDEX key_ParentPersonID (intParentPersonID)
)  ENGINE=InnoDB DEFAULT CHARACTER SET = utf8;

