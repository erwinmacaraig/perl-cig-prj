ALTER TABLE `tblWFTask`
ADD COLUMN `intOnHold` INT NOT NULL DEFAULT 0 AFTER `intDocumentID`;