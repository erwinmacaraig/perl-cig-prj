ALTER TABLE tblPersonRequest
ADD COLUMN `dtLoanFrom` DATETIME NULL AFTER `strRequestStatus`,
ADD COLUMN `dtLoanTo` DATETIME NULL AFTER `dtLoanFrom`,
ADD COLUMN `intOpenLoan` INT NULL DEFAULT 0 AFTER `dtLoanTo`,
ADD COLUMN `strTMSReference` VARCHAR(100) NULL AFTER `intOpenLoan`;
