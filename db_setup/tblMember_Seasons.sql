CREATE TABLE `tblMember_Seasons_7` (
  `intMemberSeasonID` int(11) NOT NULL auto_increment,
  `intMemberID` int(11) NOT  NULL default '0',
  `intAssocID` int(11) NOT NULL default '0',
  `intClubID` int(11) NOT NULL default '0',
  `intSeasonID` int(11) NOT NULL default '0',

  intMSRecStatus tinyint NOT NULL DEFAULT 1,
  `intSeasonMemberPackageID` int(11) default '0',
  `intPlayerAgeGroupID` int(11) default '0',
  `intPlayerStatus` tinyint(4) default '0',
  `intPlayerFinancialStatus` tinyint(4) default '0', 

  `intCoachStatus` tinyint(4) default '0',
  `intCoachFinancialStatus` tinyint(4) default '0',

  `intUmpireStatus` tinyint(4) default '0',
  `intUmpireFinancialStatus` tinyint(4) default '0',

  `intOther1Status` tinyint(4) default '0',
  `intOther1FinancialStatus` tinyint(4) default '0',

  `intOther2Status` tinyint(4) default '0',
  `intOther2FinancialStatus` tinyint(4) default '0',

  `dtInPlayer`		DATE, -- Date Registered
  `dtOutPlayer`		DATE, -- Date Registered
  `dtInCoach`		DATE, -- Date Registered
  `dtOutCoach`		DATE, -- Date Registered
  `dtInUmpire`		DATE, -- Date Registered
  `dtOutUmpire`		DATE, -- Date Registered
  `dtInOther1`		DATE, -- Date Registered
  `dtOutOther1`		DATE, -- Date Registered
  `dtInOther2`		DATE, -- Date Registered
  `dtOutOther2`		DATE, -- Date Registered
  `tTimeStamp` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,

  PRIMARY KEY  (`intMemberSeasonID`),
  UNIQUE KEY `index_intIDs` (intMemberID, intAssocID, intSeasonID, intClubID),
  KEY `index_intMAs` (intMemberID, intClubID, intAssocID),
  KEY `index_intSeasonID` (`intSeasonID`),
  KEY `index_intMSRecStatus` (`intMSRecStatus`),
  KEY `index_intAssocID` (`intAssocID`),
  KEY `index_intClubID` (`intClubID`)
);

