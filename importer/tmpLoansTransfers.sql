DROP TABLE IF EXISTS tmpLoansTransfers;
CREATE TABLE `tmpLoansTransfers` (
    `intID` INT NOT NULL AUTO_INCREMENT,
    strPersonCode varchar(30) default '',
    intPersonID int default 0,
    strRecordType varchar(10) default '',
    strClubCodeFrom varchar(10) default '',
    intEntityFromID int default 0,
    strClubCodeTo varchar(10) default '',
    intEntityToID int default 0,
    intFromPersonRegoID int default 0,
    intToPersonRegoID int default 0,
    dtApplied date,
    dtApproved date,
    dtCommenced date,
    dtExpiry date,
    strSport varchar(30) default '',
    strPersonLevel varchar(30) default '',
    strStatus varchar(30) default '',
    strProductCode varchar(30) default '',
    intProductID int default 0,
    curProductAmount decimal(12,2) default 0.00,
    strPaid varchar(30) default '',
    strTransactionNo varchar(30) default '',
    strApprovedBy varchar(30) default '',
    
    PRIMARY KEY (`intID`)
) DEFAULT CHARACTER SET = utf8;
