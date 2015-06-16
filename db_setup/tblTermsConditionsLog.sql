DROP TABLE IF EXISTS tblTermsConditionsLog;
CREATE TABLE tblTermsConditionsLog (
    intLogID INT NOT NULL AUTO_INCREMENT,
    intTermsID INT NOT NULL,
    intUserID INT NOT NULL DEFAULT 0,
    intPersonID INT NOT NULL DEFAULT 0,
    tAgreed DATETIME,

    PRIMARY KEY (intLogID),
    KEY index_user (intUserID),
    KEY index_person (intPersonID),
    KEY index_terms (intTermsID)

) ENGINE=InnoDB DEFAULT CHARSET=utf8;
