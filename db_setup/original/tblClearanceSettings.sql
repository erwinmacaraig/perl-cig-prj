DROP TABLE tblClearanceSettings;
#
CREATE table tblClearanceSettings (
	intClearanceSettingID	INT NOT NULL AUTO_INCREMENT,
	intID		INT(11) NOT NULL DEFAULT 0,
	intTypeID	INT(11) NOT NULL DEFAULT 0,
	intAssocTypeID INT(11) DEFAULT 0,
	intAutoApproval INT(11) NOT NULL DEFAULT 0,
	curDefaultFee      DECIMAL(12,2),
	dtDOBStart	datetime,
	dtDOBEnd 	datetime,
	tTimeStamp			TIMESTAMP,

PRIMARY KEY (intClearanceSettingID),
	KEY index_intID(intID),
	KEY index_intAssocTypeID(intAssocTypeID),
	KEY index_intTypeID(intTypeID)
);
 
