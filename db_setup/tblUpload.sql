# MySQL dump 7.1
#
# Host: localhost    Database: baffpulse
#--------------------------------------------------------
# Server version	3.22.32-log

#
# Table structure for table 'tblUpload'
#
DROP TABLE IF EXISTS tblUpload;
CREATE TABLE tblUpload (
  intUploadID int(11) NOT NULL auto_increment,
  intAssocID int(11) DEFAULT '0' NOT NULL,
  dtUploadDateTime datetime DEFAULT '0000-00-00 00:00:00' NOT NULL,
  strAppName varchar(50),
  strAppVer varchar(50),
  strAppType varchar(50),
  intStatus int(11) DEFAULT '-1',
  PRIMARY KEY (intUploadID),
  KEY index_strUsername (intAssocID)
);
