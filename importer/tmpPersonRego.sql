## COMBINED FILE #PersonCode;OrganisationCode;Status;RegistrationNature;PersonType;Role;Level;Sport;AgeLevel;DateFrom;DateTo;Transferred;IsLoan;NationalSeason;ProductCode;Amount;IsPaid;PaymentReference
## COACHES FILE  #PersonCode;OrganisationCode;Status;RegistrationNature;PersonType;Role;Level;Sport;AgeLevel;DateFrom;DateTo;Transferred;IsLoan;NationalSeason;ProductCode;Amount;IsPaid;PaymentReference

DROP TABLE IF EXISTS tmpPersonRego;
CREATE TABLE tmpPersonRego (
    intID INT NOT NULL AUTO_INCREMENT,
    strFileType varchar(30) default '',
    strPersonCode varchar(30) default '',
    intPersonID int default 0,
    strEntityCode varchar(30) default '',
    intEntityID int default 0,
    strStatus varchar(30) default '',
    strRegoNature varchar(30) default '',
    strPersonType varchar(30) default '',
    strPersonRole varchar(30) default '',
    strPersonLevel varchar(30) default '',
    strSport varchar(30) default '',
    strAgeLevel varchar(30) default '',
    dtFrom date,
    dtTo date,
    dtTransferred date,
    isLoan varchar(10) default '',
    strNationalPeriodCode varchar(50) default '',
    intNationalPeriodID int default 0,
    strProductCode varchar(30) default '',
    intProductID int default 0,
    curProductAmount decimal(12,2) default 0.00,
    strPaid varchar(30) default '',
    strTransactionNo varchar(30) default '',
    dtPaid date,
    strCertifications varchar(100) default '',
    strClientPRImportCode varchar(100) default '',
    
    PRIMARY KEY (intID),
    INDEX index_strFileType (strFileType),
    INDEX index_personCode (strPersonCode),
    INDEX index_entityCode (strEntityCode),
    INDEX index_nationalPeriodCode (strNationalPeriodCode),
    INDEX index_productCode (strProductCode)
) DEFAULT CHARACTER SET = utf8;
