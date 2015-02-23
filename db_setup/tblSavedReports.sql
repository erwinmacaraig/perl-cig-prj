DROP TABLE tblSavedReports;

CREATE TABLE tblSavedReports (
  intSavedReportID unsigned int NOT NULL AUTO_INCREMENT,
  strReportName varchar(50) NOT NULL DEFAULT '',
  intLevelID int(11) NOT NULL DEFAULT '0',
  intID int(11) NOT NULL DEFAULT '0',
  strReportType varchar(50) DEFAULT NULL,
  strReportData text,
  intReportID int(11) DEFAULT '0',
  intTemporary    TINTINT DEFAULT 0,
  ts      TIMESTAMP,
  PRIMARY KEY (intSavedReportID),
  KEY index_user (intLevelID,intID,strReportType)
  KEY index_temporary (intTemporary, ts)

);
