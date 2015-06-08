DROP TABLE IF EXISTS tmpTXNs;
CREATE TABLE `tmpTXNs` (
    intID INT NOT NULL AUTO_INCREMENT,
    strRecordType varchar(10) default '',
    strPersonCode varchar(30) default '',
    intPersonID int default 0,
    intPersonRegistrationID int default 0,
    intEntityID int default 0,
    strNationalPeriod varchar(50) default '',
    intNationalPeriodID int default 0,
    strProductCode varchar(30) default '',
    intProductID int default 0,
    curProductAmount decimal(12,2) default 0.00,
    strPaid varchar(30) default '',
    strTransactionNo varchar(30) default '',
    dtPaid date,
    
    PRIMARY KEY (`intID`)
) DEFAULT CHARACTER SET = utf8;
