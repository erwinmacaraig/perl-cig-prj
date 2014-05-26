DROP TABLE IF EXISTS tblSystemConfig ;
 
CREATE table tblSystemConfig (
	intSystemConfigID INT NOT NULL AUTO_INCREMENT,
  intTypeID 			SMALLINT NOT NULL,
  strOption VARCHAR (100) NOT NULL,
  strValue	VARCHAR (250) NOT NULL,
		
	PRIMARY KEY (intSystemConfigID),
	KEY index_TypeID(intTypeID),
	KEY index_strOption(strOption),
	KEY index_TypeOption(intTypeID,strOption)
);
 
