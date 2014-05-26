DROP TABLE IF EXISTS tblMember_ClubsClearedOut;

#
# Table               : tblMember_ClubsClearedOut
# Description         : Defines which members a club has access to
#---------------------

CREATE table tblMember_ClubsClearedOut       (
        intMemberID     INT DEFAULT 0,
        intRealmID      INT DEFAULT 0,
        intAssocID      INT DEFAULT 0,
        intClubID       INT DEFAULT 0,
	intClearanceID  INT DEFAULT 0,
	intCurrentSeasonID INT DEFAULT 0,
        tTimeStamp      TIMESTAMP,

PRIMARY KEY (intMemberID, intRealmID, intAssocID, intClubID),
KEY index_intClubID(intClubID),
KEY index_intAssocID(intAssocID),
KEY index_intClearanceID(intClearanceID)

);

