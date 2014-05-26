DROP TABLE tblMember_Teams;
 
#
# Table               : tblMember_Teams
# Description         : Teams that a registered Member plays in.
#---------------------
# intMemberTeamID     : Automatic Member Team ID 
# intMemberID         : Member's ID
# intTeamID           : Team ID
# dtRegistered        : Date Registrated 
#
CREATE table tblMember_Teams (
    intMemberTeamID  INT NOT NULL AUTO_INCREMENT,
    intMemberID      INT NOT NULL,
    intTeamID        INT NOT NULL,
PRIMARY KEY (intMemberTeamID),
KEY index_intMemberID(intMemberID),
KEY index_intTeamID(intTeamID)
);
 
