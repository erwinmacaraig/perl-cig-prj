DROP TABLE tblClearancePath;
#
CREATE table tblClearancePath (
	intClearancePathID     				INT NOT NULL AUTO_INCREMENT,
	intClearanceID	INT(11) NOT NULL DEFAULT 0,
	intTableType		INTEGER,
	intTypeID		INTEGER,
	intID		INT(11) NOT NULL DEFAULT 0,
	intOrder	INT(11) DEFAULT 0,
	intDirection	INT(11) DEFAULT 0,
	dtPathNodeStarted	DATETIME,
	dtPathNodeFinished	DATETIME,
	tTimeStamp			TIMESTAMP,
	strReasonForClearance		TEXT,
	intClearanceStatus		INTEGER,
	curPathFee	DECIMAL(12,2),
	strPathNotes TEXT,
	strPathFilingNumber varchar(30) default '',
	intClearanceDevelopmentFeeID INT(11) DEFAULT 0,
	intPlayerFinancial	INT(11) DEFAULT 0,	
	intPlayerSuspended	INT(11) DEFAULT 0,	
	intDenialReasonID INT(11) DEFAULT 0,	

PRIMARY KEY (intClearancePathID),
	KEY index_intClearanceID(intID),
	KEY index_intTypeID(intTypeID),
	KEY index_intID(intID),
	KEY index_intClearanceStatus(intClearanceStatus)
);
 
