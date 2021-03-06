ALTER TABLE `tblEntity` 
ADD COLUMN `strLegalID` VARCHAR(45) NULL COMMENT 'a field to type in the ID that corresponds to the LegalType' AFTER `strShortNotes`;

ALTER TABLE `tblEntity` 
CHANGE COLUMN `strLegalID` `strLegalID` VARCHAR(45) NULL DEFAULT NULL COMMENT 'a field to type in the ID that corresponds to the LegalType' AFTER `intLegalTypeID`,
CHANGE COLUMN `strLegalTypeID` `intLegalTypeID` INT(11) NULL DEFAULT NULL COMMENT 'Type of Legal ID provided as listed in the tblLegalType Table' ;

ALTER TABLE `tblEntity` 
ADD COLUMN `strImportEntityCode` VARCHAR(45) NULL COMMENT 'Reference to the imported records inputted by client' AFTER `strShortNotes`;

ALTER TABLE `tblEntity` 
ADD COLUMN `strAddress2` VARCHAR(200) NULL COMMENT 'Secondary address detail' AFTER `strAddress`;
