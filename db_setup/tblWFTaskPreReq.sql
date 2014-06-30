CREATE TABLE `tblWFTaskPreReq` (
  `intWFTaskPreReqID` int(11) NOT NULL AUTO_INCREMENT,
  `intWFTaskID` int(11) NOT NULL DEFAULT '0',
  `intWFRuleID` int(11) NOT NULL DEFAULT '0',
  `intPreReqWFRuleID` int(11) NOT NULL DEFAULT '0',
  `dtDeletedDate` datetime DEFAULT NULL,
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`intWFTaskPreReqID`),
  KEY `index_intEntityID` (`intWFTaskID`)
)  DEFAULT CHARSET=utf8;
