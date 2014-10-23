ALTER TABLE `tblEntityIdentifier` 
ADD COLUMN `strContryIssued` varchar(100) NOT NULL DEFAULT '' AFTER `strIdentifier`;
