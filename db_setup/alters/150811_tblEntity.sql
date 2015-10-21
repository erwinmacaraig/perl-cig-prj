ALTER TABLE tblEntity
ADD COLUMN `intIsInternationalTransfer` TINYINT NULL DEFAULT 0 COMMENT 'Flag to determine a HOLDING club' AFTER `intWasActivatedByPayment`;
