DROP TABLE IF EXISTS tblSelfUserHash;
CREATE TABLE tblSelfUserHash (
    intSelfUserID INT UNSIGNED NOT NULL,
    strPasswordHash VARCHAR(100),
    strPasswordChangeKey VARCHAR(50) NOT NULL,
    tsTimestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (intSelfUserID)
);

