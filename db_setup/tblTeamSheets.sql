CREATE TABLE tblTeamSheets (
  intTeamSheetID int(11) NOT NULL AUTO_INCREMENT,
  strName varchar(255) NOT NULL,
  strDescription text,
  intNumTeams tinyint(4) DEFAULT NULL,
  strFilename varchar(200) DEFAULT NULL,
  strFunction varchar(200) DEFAULT NULL,
  strGroup varchar(100) DEFAULT NULL,
  intParameters tinyint(4) DEFAULT '0',
  intOrder int(11) DEFAULT '1',
  strRequiredOptions text,
	tTimeStamp TIMESTAMP,
  PRIMARY KEY (intTeamSheetID)
);
