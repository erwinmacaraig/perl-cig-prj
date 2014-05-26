DROP TABLE IF EXISTS `tblMemberTags`;
CREATE TABLE `tblMemberTags` (
  `intMemberTagID` int(11) NOT NULL auto_increment,
  `intAssocID` int(11) NOT NULL default '0',
  `intRealmID` int(11) NOT NULL default '0',
	 intMemberID	INT NOT NULL,
	 intTagID	INT NOT NULL,
  `tTimeStamp` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  `intRecStatus` tinyint(4) default '0',
  PRIMARY KEY  (`intMemberTagID`),
  KEY `index_intAssocID` (`intAssocID`),
  KEY `IDNEX_intRecStatus` (`intRecStatus`),
  KEY `index_intRealmAssoc` (`intRealmID`,`intAssocID`),
  KEY `index_intRealmAssocMember` (`intRealmID`,`intAssocID`,`intMemberID`)
);

