ALTER TABLE tblEntity ADD COLUMN strMAID VARCHAR(30) AFTER strFIFAID,
ADD COLUMN strISOLocalLanguage VARCHAR(20) AFTER strLocalShortName,
ADD COLUMN strAssocNature VARCHAR(50) AFTER strFax,
ADD COLUMN strMANotes VARCHAR(250) AFTER strAssocNature,
ADD COLUMN strLegalType INT AFTER strMANotes