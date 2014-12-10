ALTER TABLE tblPersonRequest
CHANGE COLUMN `dtDateRequest` `dtDateRequest` DATETIME NOT NULL COMMENT 'Date the request was made',
ADD COLUMN `tTimeStamp` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP AFTER `strRequestStatus`;
