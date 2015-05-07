ALTER TABLE tblPersonRequest ADD COLUMN intExistingPersonRegistrationID INT DEFAULT 0 AFTER intPersonID;
ALTER TABLE tblPersonRequest ADD COLUMN strNewPersonLevel VARCHAR(30) NULL COMMENT 'PROFESSIONAL, AMATEUR, (blank)' AFTER strPersonLevel;
UPDATE tblPersonRequest SET strNewPersonLevel=strPersonLevel;

