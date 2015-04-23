ALTER TABLE tblPerson
ADD COLUMN `strInternationalTransferSourceClub` VARCHAR(150) NULL DEFAULT NULL AFTER `strGuardianRelationship`,
ADD COLUMN `dtInternationalTransferDate` DATETIME NULL AFTER `strInternationalTransferSourceClub`,
ADD COLUMN `strInternationalTransferTMSRef` VARCHAR(100) NULL DEFAULT NULL AFTER `dtInternationalTransferDate`,
ADD COLUMN `strInternationalLoanSourceClub` VARCHAR(150) NULL DEFAULT NULL AFTER `strInternationalTransferTMSRef`,
ADD COLUMN `strInternationalLoanTMSRef` VARCHAR(100) NULL DEFAULT NULL AFTER `strInternationalLoanSourceClub`,
ADD COLUMN `dtInternationalLoanFromDate` DATETIME NULL AFTER `strInternationalLoanTMSRef`,
ADD COLUMN `dtInternationalLoanToDate` DATETIME NULL AFTER `dtInternationalLoanFromDate`,
ADD COLUMN `intInternationalLoan` INT NULL DEFAULT 0 AFTER `dtInternationalLoanToDate`;

ALTER TABLE tblPersonRegistration_1
ADD COLUMN `intOnLoan` INT NULL DEFAULT 0 AFTER `strPreviousPersonLevel`;

ALTER TABLE tblPersonRequest
ADD COLUMN `dtLoanFrom` DATETIME NULL AFTER `strRequestStatus`,
ADD COLUMN `dtLoanTo` DATETIME NULL AFTER `dtLoanFrom`,
ADD COLUMN `intOpenLoan` INT NULL DEFAULT 0 AFTER `dtLoanTo`,
ADD COLUMN `strTMSReference` VARCHAR(100) NULL AFTER `intOpenLoan`;
