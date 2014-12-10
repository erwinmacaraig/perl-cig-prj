ALTER TABLE tblPerson
    DROP COLUMN intMinorMoveOtherThanFootball,
    DROP COLUMN intMinorDistance,
    DROP COLUMN intMinorEU,
    DROP COLUMN intMinorNone,
    ADD COLUMN intMinorProtection TINYINT NOT NULL DEFAULT 0;

