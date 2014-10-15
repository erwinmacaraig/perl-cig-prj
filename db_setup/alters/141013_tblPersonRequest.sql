ALTER TABLE `tblPersonRequest` 
ADD COLUMN `intParentMAEntityID` INT NOT NULL DEFAULT 0 COMMENT 'Populated by cron job (set to requestToEntity MA parent)' AFTER `intRequestToMAOverride`;
