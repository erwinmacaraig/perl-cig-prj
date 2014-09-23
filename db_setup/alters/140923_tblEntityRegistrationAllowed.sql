ALTER TABLE `tblEntityRegistrationAllowed` 
ADD COLUMN `strGender` VARCHAR(20) NULL COMMENT 'Change previous intGender to strgender to support importer requirement and transfer of reference criteria from tblentityRegistrationAllowed to tblEntity';
ADD COLUMN `intImportID` INT NULL COMMENT 'Tracking ID on which batch this record is included during import';