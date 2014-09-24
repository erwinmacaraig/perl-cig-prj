ALTER TABLE `tblPerson` 
CHANGE COLUMN `strPreferredName` `strPreferredName` VARCHAR(100) NULL AFTER `strLatinSurname2`,
ADD COLUMN `strDemographicField1` VARCHAR(45) NULL COMMENT 'TBC' AFTER `dtSuspendedUntil`,
ADD COLUMN `strDemographicField2` VARCHAR(45) NULL COMMENT 'TBC' AFTER `strDemographicField1`,
ADD COLUMN `strDemographicField3` VARCHAR(45) NULL COMMENT 'TBC' AFTER `strDemographicField2`,
ADD COLUMN `strDemographicField4` VARCHAR(45) NULL COMMENT 'TBC' AFTER `strDemographicField3`,
ADD COLUMN `strDemographicField5` VARCHAR(45) NULL COMMENT 'TBC' AFTER `strDemographicField4`,
ADD COLUMN `strDemographicField6` VARCHAR(45) NULL COMMENT 'TBC' AFTER `strDemographicField5`;
ADD COLUMN `strGender` VARCHAR(45) NULL COMMENT 'to replace intGender in the future' AFTER `intGender`;

ALTER TABLE `tblPerson` 
ADD COLUMN `strImportPersonCode` VARCHAR(45) NULL AFTER `intPersonID`,
ADD UNIQUE INDEX `strImportPersonCode_UNIQUE` (`strImportPersonCode` ASC);
