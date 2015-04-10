ALTER TABLE tblRegistrationItem ADD COLUMN intItemNeededITC tinyint default 0 COMMENT 'Was an ITC needed';
ALTER TABLE tblRegistrationItem ADD COLUMN intItemUsingITCFilter tinyint default 0 COMMENT 'Using ITC filter';
