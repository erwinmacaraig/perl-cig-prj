ALTER TABLE tblWFRule
    ADD COLUMN intUsingPersonLevelChangeFilter tinyint default 0 COMMENT 'Using Person Level change filter',
    ADD COLUMN intPersonLevelChange tinyint default 0 COMMENT 'Was Person Level changed';
