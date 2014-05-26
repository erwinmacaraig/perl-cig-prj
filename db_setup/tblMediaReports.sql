DROP TABLE IF EXISTS tblMediaReports;
CREATE TABLE tblMediaReports (
  intMediaReportID int(11) NOT NULL auto_increment,
  intRealmID   int(11) DEFAULT 0, 
  strName      varchar(50) NOT NULL,
  intReportID  int(11) NOT NULL,
  intReportType tinyint NOT NULL, -- 1 = saved report, 2 = custom report.
  intDateFilter tinyint DEFAULT 0,
  intRoundFilter tinyint DEFAULT 0,
  PRIMARY KEY  (intMediaReportID)
);
