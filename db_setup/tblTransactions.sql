DROP TABLE IF EXISTS tblTransactions;
CREATE TABLE tblTransactions (
    intTransactionID int(11) NOT NULL auto_increment,
    intStatus tinyint(4) default '0',
    strNotes text,
    curAmount decimal(12,2) default 0.00,
    intQty int(11) default '0',
    dtTransaction datetime default NULL,
    dtPaid datetime default NULL,
    tTimeStamp timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
    intDelivered tinyint(11) default '0',
    intRealmID int(11) default '0',
    intRealmSubTypeID int(11) default '0',
    intID int(11) default '0',
    intTableType tinyint(4) default '0',
    intTXNEntityID INT default 0,
    intProductID int(11) default NULL,
    intTransLogID int(11) default '0',
    intCurrencyID int(11) default '0',
    intTempLogID int(11) default '0',
    intExportAssocBankFileID INT DEFAULT 0,
    dtStart DATETIME,
    dtEnd DATETIME,
    curPerItem decimal(12,2) default 0.00,
    intRenewed TINYINT default 0,
    intParentTXNID INT default 0,
    strPayeeName VARCHAR(100) default '',
    strPayeeNotes text,
  PRIMARY KEY  (intTransactionID),
  KEY index_intStatus (intStatus),
  KEY index_intTXNEntityID(intTXNEntityID),
  KEY transLogID (intTransLogID),
  KEY index_intRealmIDintRealmSubTypeID (intRealmID, intRealmSubTypeID),
  KEY intRealmSubTypeID (intRealmSubTypeID),
  KEY index_intIDintTableType (intID, intTableType),
  KEY intTableType (intTableType),
  KEY intProductID (intProductID)
) DEFAULT CHARSET=utf8;
