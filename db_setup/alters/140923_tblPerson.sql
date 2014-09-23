ALTER TABLE `tblPerson` 
ADD COLUMN strImportPersonCode VARCHAR(45) NULL AFTER `intPersonID`,
ADD COLUMN `intImportID` INT NULL COMMENT 'Tracking ID on which batch this record is included during import';