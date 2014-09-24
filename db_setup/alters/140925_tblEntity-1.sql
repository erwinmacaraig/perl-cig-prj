ALTER TABLE `tblEntity` 
ADD COLUMN `intRealmApproved` TINYINT NULL DEFAULT 0 AFTER `strAcceptSelfRego`,
ADD COLUMN `strPaymentNotificationAddress` VARCHAR(250) NULL AFTER `intRealmApproved`,
ADD COLUMN `strEntityPaymentBusinessNumber` VARCHAR(100) NULL AFTER `strPaymentNotificationAddress`,
ADD COLUMN `strEntityPaymentInfo` TEXT NULL AFTER `strEntityPaymentBusinessNumber`;