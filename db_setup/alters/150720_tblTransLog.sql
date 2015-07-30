ALTER TABLE tblTransLog ADD COLUMN intCheckOnceDaily TINYINT default 0, ADD INDEX index_intCheckOnceDaily (intCheckOnceDaily);

