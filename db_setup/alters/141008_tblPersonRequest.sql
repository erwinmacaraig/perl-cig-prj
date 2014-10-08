ALTER TABLE `tblPersonRequest` 
ADD COLUMN `strRequestStatus` VARCHAR(20) NULL DEFAULT NULL AFTER `intResponseBy`;
