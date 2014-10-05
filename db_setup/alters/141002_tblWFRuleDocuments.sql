ALTER TABLE `tblWFRuleDocuments` 
ADD COLUMN `intAllowVerify` INT NOT NULL DEFAULT 0 COMMENT 'Flag to check if the approvalEntity of the task can verify documents' AFTER `intDocumentTypeID`;
