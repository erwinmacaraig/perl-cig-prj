DROP TABLE IF EXISTS `tblEmailTemplateTypes`;

CREATE TABLE `tblEmailTemplateTypes` (
    `intEmailTemplateTypeID` INT NOT NULL AUTO_INCREMENT,
    `intRealmID` INT NOT NULL,
    `intSubRealmID` INT NOT NULL,
    `strTemplateType` VARCHAR(100) NULL,
    `strFileNamePrefix` VARCHAR(100) NULL,
    `intActive` INT NULL DEFAULT '1',
    `tTimestamp` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`intEmailTemplateTypeID`),
    UNIQUE KEY `realm_template_type` (`intRealmID`, `strTemplateType`));
