DROP TABLE IF EXISTS tblMediaReportScheduledTimes;
CREATE TABLE tblMediaReportScheduledTimes (
  intScheduledTimeID int(11) NOT NULL auto_increment,
  intMediaReportID   int(11) NOT NULL,
  strSchedule        VARCHAR(20),
  intAssocID         int(11) NOT NULL,
  tTimeStamp         TIMESTAMP,
  PRIMARY KEY  (intScheduledTimeID)
);

