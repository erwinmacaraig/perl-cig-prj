ALTER TABLE `tblTransLog` 
DROP COLUMN `intClubPaymentID`,
DROP COLUMN `intAssocPaymentID`,
ADD COLUMN `intEntityPaymentID` INT(11) NULL DEFAULT 0 AFTER `dtSettlement`,
DROP INDEX `indexAssocClubPaymentID` ,
DROP INDEX `index_AssocClubID` ,
ADD INDEX `indexPaymentID` (`intEntityPaymentID` ASC);