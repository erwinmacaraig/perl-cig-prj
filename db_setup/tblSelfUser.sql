DROP TABLE IF EXISTS tblSelfUser;
CREATE TABLE tblSelfUser (
    intSelfUserID INT UNSIGNED NOT NULL AUTO_INCREMENT,
    strEmail VARCHAR(250) NOT NULL,
    strStatus VARCHAR(20) NOT NULL DEFAULT '',
    strFirstName VARCHAR(100),
    strFamilyName VARCHAR(100),
    strConfirmKey VARCHAR(20) DEFAULT '',
    dtCreated DATETIME,
    dtConfirmed DATETIME,
    tsTimestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (intSelfUserID),
    UNIQUE KEY index_username(strEmail)
);

