DROP TABLE tblClearancePath;
CREATE TABLE `tblClearancePath` (
  `intClearancePathID` int(11) NOT NULL AUTO_INCREMENT,
  `intClearanceID` int(11) NOT NULL DEFAULT '0',
  `intTableType` int(11) DEFAULT NULL,
  `intTypeID` int(11) DEFAULT NULL,
  `intID` int(11) NOT NULL DEFAULT '0',
  `intOrder` int(11) DEFAULT '0',
  `intDirection` int(11) DEFAULT '0',
  `dtPathNodeStarted` datetime DEFAULT NULL,
  `dtPathNodeFinished` datetime DEFAULT NULL,
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `strReasonForClearance` text,
  `intClearanceStatus` int(11) DEFAULT NULL,
  `curPathFee` decimal(12,2) DEFAULT NULL,
  `strPathNotes` text,
  `strPathFilingNumber` varchar(30) DEFAULT '',
  `intClearanceDevelopmentFeeID` int(11) DEFAULT '0',
  `intPlayerFinancial` int(11) DEFAULT '0',
  `intPlayerSuspended` int(11) DEFAULT '0',
  `intDenialReasonID` int(11) DEFAULT '0',
  `strApprovedBy` varchar(100) DEFAULT NULL,
  `curDevelFee` decimal(12,2) DEFAULT '0.00',
  `strOtherDetails1` varchar(30) DEFAULT '',
  PRIMARY KEY (`intClearancePathID`),
  KEY `index_intTypeID` (`intTypeID`),
  KEY `index_intID` (`intID`),
  KEY `index_intClearanceStatus` (`intClearanceStatus`),
  KEY `index_intClearanceID` (`intClearanceID`)
) DEFAULT CHARSET=utf8;
