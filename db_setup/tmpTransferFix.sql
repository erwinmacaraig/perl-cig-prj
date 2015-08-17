CREATE TABLE tmpTransferFix (
    intFixID int(11) NOT NULL auto_increment,
    intPersonID INT DEFAULT 0,
    intEntityID INT DEFAULT 0,
    strPersonLevel VARCHAR(30) DEFAULT '',
    strSport VARCHAR(30) DEFAULT '',
    intNationalPeriodID INT DEFAULT 0,
    strStatus VARCHAR(30) DEFAULT '',
    intOnLoan int default 0,
    intIsLoanedOut int default 0,
    strImportPersonCode varchar(45) default '',
    intPersonRequestID INT default 0,
    tTimeStamp TIMESTAMP,
  PRIMARY KEY  (intFixID),
    UNIQUE KEY index_PersonID (intPersonID, strSport, strPersonLevel)
) DEFAULT CHARSET=utf8;

