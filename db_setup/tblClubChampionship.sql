DROP TABLE IF EXISTS tblClubChampionship;
CREATE TABLE tblClubChampionship (
  intClubChampionshipID int(11) NOT NULL auto_increment,
  intRecStatus          tinyint(4) NOT NULL DEFAULT 1,
  intRealmID            int(11) NOT NULL DEFAULT 0, 
  intAssocID            int(11) NOT NULL DEFAULT 0,
  strName               varchar(50)NOT NULL,
  strNotes              varchar(250),
  intPointsWin          tinyint(4) NOT NULL default 0,
  intPointsDraw         tinyint(4) default 0,
  intPointsLoss         tinyint(4) default 0,
  intPointsBye          tinyint(4) default 0,
  intPointsGivingForfeit      tinyint(4) default 0,
  intPointsReceivingForfeit   tinyint(4) default 0,
  intShowWeb            tinyint(4) DEFAULT 0,
  intShowMedia          tinyint(4) DEFAULT 0,
  tTimeStamp            timestamp NOT NULL default CURRENT_TIMESTAMP,
  PRIMARY KEY  (intClubChampionshipID),
  KEY index_intAssocID(intAssocID)

);

DROP TABLE IF EXISTS tblClubChampionshipComps;
CREATE TABLE tblClubChampionshipComps (
  intClubChampionshipCompID int(11) NOT NULL auto_increment,
  intClubChampionshipID      int(11) NOT NULL, 
  intCompID                  int(11) NOT NULL,
  intPercentage              tinyint(4) NOT NULL default 100,
  tTimeStamp            timestamp NOT NULL default CURRENT_TIMESTAMP,
  PRIMARY KEY (intClubChampionshipCompID),
  KEY index_intClubChampionshipID(intClubChampionshipID)

);


DROP TABLE IF EXISTS tblClubChampionshipClubs;
CREATE TABLE tblClubChampionshipClubs (
  intClubChampionshipID int(11) NOT NULL, 
  intClubID int(11) NOT NULL,
  intCompID int(11) NOT NULL default 0,
  dblPoints double NOT NULL default 0,
  intNoOfWins int(11) NOT NULL default 0,
  intNoOfDraws int(11) NOT NULL default 0,
  intNoOfLosses int(11) NOT NULL default 0,
  intNoOfByes int(11) NOT NULL default 0,
  intNoOfForfeitsReceived int(11) NOT NULL default 0,
  intNoOfForfeitsGiven int(11) NOT NULL default 0,
  intFor int(11) NOT NULL default 0,
  intAgainst int(11) NOT NULL default 0,
  tTimeStamp  timestamp NOT NULL default CURRENT_TIMESTAMP,
  PRIMARY KEY (intClubChampionshipID,intClubID,intCompID),
  KEY index_intClubChampionshipID(intClubChampionshipID)
);

