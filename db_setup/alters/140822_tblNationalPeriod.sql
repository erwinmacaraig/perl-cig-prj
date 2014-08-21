ALTER TABLE tblNationalPeriod ADD COLUMN intCurrentNew TINYINT DEFAULT 0, ADD COLUMN intCurrentRenewal TINYINT DEFAULT 0;

UPDATE tblNationalPeriod SET intCurrentNew=1, intCurrentRenewal=1;
