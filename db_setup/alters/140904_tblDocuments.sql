ALTER TABLE `tblDocuments` 
ADD COLUMN `dtDateAdded` DATETIME NULL DEFAULT CURRENT_TIMESTAMP AFTER `intUploadFileID`,
ADD COLUMN `dtLastUpdated` DATETIME NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP AFTER `dtDateAdded`;
