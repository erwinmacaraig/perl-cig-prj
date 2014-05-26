DROP TABLE IF EXISTS tblConfig;
 
CREATE table tblConfig (
	intConfigID INT NOT NULL AUTO_INCREMENT,
	intEntityID INT NOT NULL,
	intLevelID 	INT NOT NULL,
	intTypeID   INT NOT NULL,
	strPerm     VARCHAR(20) DEFAULT '',
	strValue    VARCHAR(30) DEFAULT '',
		
	PRIMARY KEY (intConfigID),
	KEY index_Entity (intLevelID, intEntityID),
	KEY index_EntityType (intLevelID, intEntityID, intTypeID),
	KEY index_EntityTypePerm (intLevelID, intEntityID, intTypeID,strPerm)
);
 
