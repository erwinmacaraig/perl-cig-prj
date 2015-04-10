ALTER TABLE tblPersonRegistration_1
    ADD COLUMN intPersonLevelChanged TINYINT DEFAULT 0,
    ADD COLUMN strPreviousPersonLevel varchar(30) DEFAULT '';
