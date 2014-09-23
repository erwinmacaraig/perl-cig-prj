ALTER TABLE `tblPerson` 
ADD COLUMN `intImportID` INT NULL COMMENT 'Tracking ID on which batch this record is included during import';
ALTER TABLE `tblEntity` 
ADD COLUMN `intImportID` INT NULL COMMENT 'Tracking ID on which batch this record is included during import';
ALTER TABLE `tblEntityLinks` 
ADD COLUMN `intImportID` INT NULL COMMENT 'Tracking ID on which batch this record is included during import';