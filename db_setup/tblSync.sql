DROP TABLE tblSync;
 

CREATE table tblSync	(
    intSyncID	     INTEGER NOT NULL AUTO_INCREMENT,
	intAssocID	int(11) default 0,
	dtSync	datetime,
	strStage	varchar(20),
	strReturnValues	longtext,
	intReturnAcknowledged TINYINT DEFAULT 0,
		
PRIMARY KEY (intSyncID),
INDEX index_intAssocID (intAssocID),
INDEX index_intNewID (intNewID),
INDEX index_intOldID (intOldID)
);
