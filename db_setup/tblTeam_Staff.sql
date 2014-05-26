--
-- Table structure for table `tblTeam_Staff`
--

DROP TABLE IF EXISTS `tblTeam_Staff`;
CREATE TABLE `tblTeam_Staff` (
  `intTeamStaffID` int(11) NOT NULL auto_increment,
  `intAssocStaffID` int(11) default '0',
  `intAssocID` int(11) NOT NULL default '0',
  `intTeamID` int(11) NOT NULL default '0',
  `intCompID` int(11) NOT NULL default '0',
  `intMemberID` int(11) NOT NULL default '0',
  `tTimeStamp` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  PRIMARY KEY  (`intTeamStaffID`),
  KEY `index_intAssocStaffID` (`intAssocStaffID`),
  KEY `index_intAssocID` (`intAssocID`),
  KEY `index_intTeamID` (`intTeamID`),
  KEY `index_intCompID` (`intCompID`),
  KEY `index_intMemberID` (`intMemberID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
