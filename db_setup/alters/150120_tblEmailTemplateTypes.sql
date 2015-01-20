ALTER TABLE tblEmailTemplateTypes
ADD COLUMN `strStatus` VARCHAR(45) NULL DEFAULT 'NA' AFTER `strFileNamePrefix`;
