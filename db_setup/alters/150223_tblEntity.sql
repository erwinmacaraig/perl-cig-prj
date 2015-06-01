ALTER TABLE `tblEntity` 
ADD COLUMN `strBankAccountNumber` VARCHAR(100) NULL COMMENT 'International Bank Account Number (IBAN)' AFTER `intFacilityTypeID`;
