ALTER TABLE tblAuditLog MODIFY COLUMN strType varchar(80) DEFAULT '', ADD COLUMN intUserID int(11) DEFAULT '0';
