ALTER TABLE tblPersonRegistration_1
ADD COLUMN `intIsLoanedOut` TINYINT NULL DEFAULT 0 COMMENT 'Flag to identify that the person registration record is loaned out' AFTER `intOnLoan`;
