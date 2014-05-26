CREATE table tblFacilities (
    intFacilityID  INT NOT NULL AUTO_INCREMENT,
    intRealmID     INT NOT NULL,
    intSubRealmID  INT DEFAULT -1,
    strName        VARCHAR(150),
    intRecStatus   TINYINT(4) DEFAULT 0,
    strAbbrev      VARCHAR(50) DEFAULT '',
    intTypeID      TINYINT DEFAULT 0, ## eg: Ground, Club, Tribunal
    strAddress1    VARCHAR(200) DEFAULT '',
    strAddress2    VARCHAR(200) DEFAULT '',
    strSuburb      VARCHAR(100) DEFAULT '',
    strState       VARCHAR(100) DEFAULT '',
    strPostalCode  VARCHAR(20) DEFAULT '',
    strCountry     VARCHAR(100) DEFAULT '',
    strPhone       VARCHAR(50) DEFAULT '',
    strPhone2      VARCHAR(50) DEFAULT '',
    strFax         VARCHAR(50) DEFAULT '',
    strMapRef      VARCHAR(20) DEFAULT '',
    intMapNumber   INT DEFAULT 0,
    dblLat         DOUBLE DEFAULT 0,
    dblLong        DOUBLE DEFAULT 0,
    strLGA         VARCHAR(250) DEFAULT '',

PRIMARY KEY (intFacilityID),
KEY index_intRealmID(intRealmID)
);