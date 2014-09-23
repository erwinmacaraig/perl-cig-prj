ALTER TABLE `tblEntity` 
ADD UNIQUE INDEX `strImportEntityCode_UNIQUE` (`strImportEntityCode` ASC),
ADD COLUMN `intImportID` INT NULL COMMENT 'Tracking ID on which batch this record is included during import';