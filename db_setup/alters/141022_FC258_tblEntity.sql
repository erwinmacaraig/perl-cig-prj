ALTER TABLE `tblEntity` 
ADD COLUMN `intNotifications` INT NOT NULL DEFAULT 1 COMMENT 'Flag to check whether to send notifications or not.' AFTER `strShortNotes`;
