ALTER TABLE tblPerson
ADD COLUMN `strInternationalTransferSourceClub` VARCHAR(150) NULL DEFAULT NULL AFTER `strGuardianRelationship`,
ADD COLUMN `dtInternationalTransferDate` DATETIME NULL AFTER `strInternationalTransferSourceClub`,
ADD COLUMN `strInternationalTransferTMSRef` VARCHAR(100) NULL DEFAULT NULL AFTER `dtInternationalTransferDate`,
ADD COLUMN `strInternationalLoanSourceClub` VARCHAR(150) NULL DEFAULT NULL AFTER `strInternationalTransferTMSRef`,
ADD COLUMN `strInternationalLoanTMSRef` VARCHAR(100) NULL DEFAULT NULL AFTER `strInternationalLoanSourceClub`,
ADD COLUMN `dtInternationalLoanFromDate` DATETIME NULL AFTER `strInternationalLoanTMSRef`,
ADD COLUMN `dtInternationalLoanToDate` DATETIME NULL AFTER `dtInternationalLoanFromDate`,
ADD COLUMN `intInternationalLoan` INT NULL DEFAULT 0 AFTER `dtInternationalLoanToDate`;
