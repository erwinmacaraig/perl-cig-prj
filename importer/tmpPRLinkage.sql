DROP TABLE IF EXISTS tmpPRLinkage;
CREATE TABLE tmpPRLinkage (
    intPersonID INT default 0,
    intPersonRegistrationID INT default 0,
    strClientPRImportCode varchar(100) default '',
    
    INDEX index_intPersonID (intPersonID),
    INDEX index_intPRID (intPersonRegistrationID),
    INDEX index_strCode (strClientPRImportCode)
) DEFAULT CHARACTER SET = utf8;
