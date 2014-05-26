CREATE table tblLocalConfig (
	intLocalConfigID INT NOT NULL AUTO_INCREMENT,
  intLocalisationID 			INT NOT NULL,
  strOption VARCHAR (100) NOT NULL,
  strValue	VARCHAR (250) NOT NULL,
  tTimeStamp        TIMESTAMP,
		
	PRIMARY KEY (intLocalConfigID),
	KEY index_LocalisationID(intLocalisationID),
	KEY index_strOption(strOption),
	UNIQUE KEY index_LocalOption(intLocalisationID,strOption)
);
 
