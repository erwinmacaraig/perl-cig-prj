CREATE TABLE `tblOptinMember` (
`intOptinMemberID` int(11) NOT NULL AUTO_INCREMENT,
`intOptinID`  int(11) DEFAULT '0',
`intFormID`  int(11) DEFAULT '0',
`intMemberID` int(11) DEFAULT '0',
`intAction` tinyint(4) DEFAULT '0',
`tTimestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
PRIMARY KEY (`intOptinMemberID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

