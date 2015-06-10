DROP TABLE IF EXISTS tblTermsConditions;
CREATE TABLE tblTermsConditions (
    intTermsID INT NOT NULL AUTO_INCREMENT,
    strType VARCHAR(20) NOT NULL DEFAULT '',
    strLocale VARCHAR(10) NOT NULL DEFAULT '',
    strTerms MEDIUMTEXT NOT NULL DEFAULT '',
    intCurrent TINYINT DEFAULT 0,
    tTimestamp TIMESTAMP,

    PRIMARY KEY (intTermsID),
    KEY index_type (strType, strLocale, intCurrent)

);
