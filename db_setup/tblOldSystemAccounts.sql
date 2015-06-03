DROP TABLE IF EXISTS tblOldSystemAccounts;
CREATE TABLE tblOldSystemAccounts (
    intPersonID INTEGER NOT NULL,
    strUsername VARCHAR(30) NOT NULL DEFAULT '',
    strPassword VARCHAR(30) NOT NULL DEFAULT '',

    PRIMARY KEY(intPersonID),
    UNIQUE KEY index_un (strUsername)
);
