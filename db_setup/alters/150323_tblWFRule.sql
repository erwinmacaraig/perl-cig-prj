ALTER TABLE tblWFRule ADD COLUMN intUsingITCFilter tinyint default 0 COMMENT 'Using ITC filter', ADD COLUMN intNeededITC tinyint default 0 COMMENT 'Was an ITC needed';
