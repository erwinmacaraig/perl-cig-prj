DROP TABLE IF EXISTS tblMemberHistory;
CREATE TABLE tblMemberHistory	(
	intMemberHistoryID 	INT NOT NULL AUTO_INCREMENT,
	intMemberID	INT NOT NULL,
	intSeasonID INT  DEFAULT 0,
	strSeasonName VARCHAR(150) NOT NULL,
	intAssocID	INT NOT NULL,
	strAssocName VARCHAR(150) DEFAULT '' NOT NULL,
	intCompID INT DEFAULT 0 NOT NULL,
	strCompName VARCHAR(150) DEFAULT '' NOT NULL,
	intGradeID INT DEFAULT 0 NOT NULL,
	strGradeName VARCHAR(150) DEFAULT '' NOT NULL,
	intClubID INT DEFAULT 0 NOT NULL,
	strClubName VARCHAR(100) DEFAULT '' NOT NULL,
	intTeamID VARCHAR(100) DEFAULT 0 NOT NULL,
	strTeamName VARCHAR(100) DEFAULT '' NOT NULL,
	dtDateAdded TIMESTAMP,

	PRIMARY KEY(intMemberHistoryID),
	KEY index_dtDateAdded (dtDateAdded),
	UNIQUE KEY key_uniq(intMemberID, strSeasonName, strAssocName, strCompName, strGradeName, strClubName, strTeamName)
);

