DROP TABLE tblTribunal;
#
CREATE table tblTribunal(
	intTribunalID	INT NOT NULL AUTO_INCREMENT,
	intMemberID		INT(11) NOT NULL DEFAULT 0,
	intRealmID		INT(11) NOT NULL DEFAULT 0,
	intAssocID		INT(11) NOT NULL DEFAULT 0,
	intTeamID		INT(11) NOT NULL DEFAULT 0,
	intCompID		INT(11) NOT NULL DEFAULT 0,
	dtCharged			DATETIME,
	strOffence		VARCHAR(50) DEFAULT '',
	dtHearing			DATE,
	tHearing			TIME,
	intHearingVenueID		INT(11) NOT NULL DEFAULT 0,
	strOutcome		VARCHAR(20) DEFAULT '',
	intPenalty			INT(11) DEFAULT 0,
	strPenaltyType		VARCHAR(5) DEFAULT '',
	dtPenaltyExp			DATETIME,
	intSuspendedPenalty		INT(11) DEFAULT 0,
	strSuspendedPenaltyType		VARCHAR(5) DEFAULT '',
	dtSuspPenExpDate		DATETIME,
	intMemberWitnessID		INT(11) DEFAULT 0,
	strReporter			VARCHAR(40) DEFAULT 0,
	strNotes			TEXT,
	intRecStatus	INT(11) DEFAULT 0,
	tTimeStamp			TIMESTAMP,


PRIMARY KEY (intTribunalID),
	KEY index_intMemberID(intMemberID),
	KEY index_intTeamID(intTeamID),
	KEY index_intCompID(intCompID),
	KEY index_intRealmID(intRealmID),
	KEY index_intAssocID(intAssocID)
);
 
