ALTER TABLE tblPerson
ADD COLUMN `strInternationalTransferSourceClub` VARCHAR(150) NULL DEFAULT NULL AFTER `strGuardianRelationship`,
ADD COLUMN `dtInternationalTransferDate` DATE NULL AFTER `strInternationalTransferSourceClub`,
ADD COLUMN `strInternationalTransferTMSRef` VARCHAR(100) NULL DEFAULT NULL AFTER `dtInternationalTransferDate`,
ADD COLUMN `strInternationalLoanSourceClub` VARCHAR(150) NULL DEFAULT NULL AFTER `strInternationalTransferTMSRef`,
ADD COLUMN `strInternationalLoanTMSRef` VARCHAR(100) NULL DEFAULT NULL AFTER `strInternationalLoanSourceClub`,
ADD COLUMN `dtInternationalLoanFromDate` DATE NULL AFTER `strInternationalLoanTMSRef`,
ADD COLUMN `dtInternationalLoanToDate` DATE NULL AFTER `dtInternationalLoanFromDate`,
ADD COLUMN `intInternationalLoan` INT NULL DEFAULT 0 AFTER `dtInternationalLoanToDate`;

ALTER TABLE tblPersonRegistration_1
ADD COLUMN `intOnLoan` INT NULL DEFAULT 0 AFTER `strPreviousPersonLevel`;

ALTER TABLE tblPersonRequest
ADD COLUMN `dtLoanFrom` DATE NULL AFTER `strRequestStatus`,
ADD COLUMN `dtLoanTo` DATE NULL AFTER `dtLoanFrom`,
ADD COLUMN `intOpenLoan` INT NULL DEFAULT 0 AFTER `dtLoanTo`,
ADD COLUMN `strTMSReference` VARCHAR(100) NULL AFTER `intOpenLoan`;

ALTER TABLE tblRegistrationItem
ADD COLUMN `intItemForInternationalTransfer` TINYINT NULL DEFAULT 0 AFTER `intItemPaidProducts`,
ADD COLUMN `intItemForInternationalLoan` TINYINT NULL DEFAULT 0 AFTER `intItemForInternationalTransfer`;

ALTER TABLE `tblMatrix` 
ADD COLUMN `dtOpenFrom` DATE NULL DEFAULT NULL AFTER `dtTo`,
ADD COLUMN `dtOpenTo` DATE NULL DEFAULT NULL AFTER `dtOpenFrom`,
ADD COLUMN `intHonourOpenDates` TINYINT NULL DEFAULT 0 AFTER `dtOpenTo`;


ALTER TABLE tblNationalPeriod ADD COLUMN intDontUseForLoans TINYINT DEFAULT 0;
