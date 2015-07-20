ALTER TABLE tblTransLog ADD COLUMN intCheckOnceDaily TINYINT default 0, ADD COLUMN dtTLCreated datetime default '0000-00-00 00:00:00';
ALTER TABLE tblTransLog ADD INDEX index_intCheckOnceDaily (intCheckOnceDaily);

