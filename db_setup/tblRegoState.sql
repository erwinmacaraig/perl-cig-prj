DROP TABLE IF EXISTS tblRegoState;
CREATE TABLE tblRegoState (
    id INT NOT NULL AUTO_INCREMENT,
    userEntityID INT NOT NULL,
    userID INT NOT NULL,
    regoType VARCHAR(30) NOT NULL,
    entityID INT NOT NULL DEFAULT 0,
    regoID INT NOT NULL DEFAULT 0,
    parameters TEXT,
    ts  TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY (regoType, userEntityID, entityID, regoID),
    KEY index_userEntityID (userEntityID),
    KEY index_userID (userID)
);
