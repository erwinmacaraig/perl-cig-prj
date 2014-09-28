ALTER TABLE `tblWFTaskNotes` 
DROP COLUMN `tTimeStampResolved`,
DROP COLUMN `strResolveNotes`,
CHANGE COLUMN `intTaskNoteID` `intTaskNoteID` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT ,
CHANGE COLUMN `strRejectionNotes` `strNotes` VARCHAR(250) NOT NULL ,
CHANGE COLUMN `tTimeStampRejected` `tTimeStamp` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ,
ADD COLUMN `intParentNoteID` INT UNSIGNED NOT NULL DEFAULT '0' COMMENT 'Used to track which rejection note a resolution note will be mapped.' AFTER `intTaskNoteID`,
ADD COLUMN `strType` VARCHAR(20) NULL COMMENT 'REJECT, RESOLVE, HOLD' AFTER `strNotes`;
