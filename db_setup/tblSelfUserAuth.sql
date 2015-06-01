DROP TABLE IF EXISTS tblSelfUserAuth;
CREATE TABLE tblSelfUserAuth (
    intSelfUserID INT UNSIGNED NOT NULL,
    intEntityTypeID INT NOT NULL,
    intEntityID INT NOT NULL,
    dtLastLogin   DATETIME,
    intMinor TINYINT DEFAULT 0,

    PRIMARY KEY (intSelfUserID, intEntityTypeID, intEntityID)
);

