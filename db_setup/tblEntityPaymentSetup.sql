DROP TABLE IF EXISTS tblEntityPaymentSetup;
CREATE TABLE tblEntityPaymentSetup (
    intParentEntityID int(11) DEFAULT 0,
    intRealmID INT DEFAULT 0,
    intSubRealmID INT DEFAULT 0,
    intPaymentType TINYINT DEFAULT 0,

    intAllowPayment TINY INT DEFAULT 0,

    intPaymentConfigID TINY INT DEFAULT 0,
    strEntityPaymentABN VARCHAR(100) DEFAULT '',
    strEntityPaymentInfo TEXT, 
    strPaymentReceiptBodyTEXT TEXT,
    strPaymentReceiptBodyHTML TEXT,
    intAllowRegoForm TINYINT DEFAULT 0,
    intEntityFeeAllocationType TINYINT DEFAULT 0,
    intApproveThisLevelPayment TINYINT DEFAULT 0,
    intApproveChildrenPayment TINYINT DEFAULT 0,
    
    tTimeStamp timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (intParentEntityID, intRealmID, intSubRealmID, intPaymentType),
    KEY index_intRealmID (intRealmID)
) DEFAULT CHARSET=utf8;

