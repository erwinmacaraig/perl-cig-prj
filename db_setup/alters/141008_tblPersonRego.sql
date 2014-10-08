ALTER TABLE `tblPersonRegistration_1` 
ADD COLUMN `intPersonRequestID` INT NOT NULL DEFAULT 0 COMMENT 'For tracking purposes if entry came from Person Request (TRANSFER or ACCESS)' AFTER `intClearanceID`;
