CREATE TABLE `tblOptin` (
`intOptinID` int(11) NOT NULL AUTO_INCREMENT,
`intEntityID`  int(11) DEFAULT '0',
`intEntityTypeID` int(11) DEFAULT '0',
`strOptinText` text NOT NULL,
`intActive` tinyint(4) DEFAULT '0',
`intLevel` tinyint(4) DEFAULT '0',
`dtCreated` datetime,
`tTimestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
PRIMARY KEY (`intOptinID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

