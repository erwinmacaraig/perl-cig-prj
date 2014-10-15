DROP TABLE IF EXISTS `tblEmailTemplates`;

CREATE TABLE `tblEmailTemplates` (
    `intEmailTemplateID` INT NOT NULL AUTO_INCREMENT,
    `intEmailTemplateTypeID` INT NULL,
    `strHTMLTemplatePath` VARCHAR(100) NULL COMMENT 'html responsive web email template',
    `strTextTemplatePath` VARCHAR(100) NULL COMMENT 'Plain Text Email Template incase client or reader does not support html',
    `strSubjectPrefix` VARCHAR(100) NULL COMMENT 'Prefix Email Subject',
    `intLanguageID` INT NOT NULL COMMENT 'links to tblLanguages',
    `intActive` INT NULL DEFAULT '1',
    `tTimestamp` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
PRIMARY KEY (`intEmailTemplateID`));
