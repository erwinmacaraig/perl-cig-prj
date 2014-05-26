drop table tblTeam;
 
#
# Table               : tblTeam
# Description         : Team Information
#---------------------
# intTeamID           : Team ID 
# strTeamNo           : Team Number
# intClubID           : Club ID
# intAssocID          : Assoc ID
# strName             : Team name 
# strContact          : Team Contact Name
# strAddress1         : Team Contact Street Address
# strSuburb           : Team Contact Suburb
# strPostalCode       : Team Contact PostCode
# strState            : Team Contact State
# strPhone1           : Phone number 1 
# strPhone2           : Phone number 2 
# strEmail            : Team Contact Email
# strNickname         : Team Nickname
# strColors           : Team Colors
# dtRegistered        : Date Registered
#
CREATE table tblTeam (
    intTeamID       INTEGER NOT NULL AUTO_INCREMENT,
    strTeamNo       VARCHAR (20), 
    intAssocID       INTEGER NOT NULL DEFAULT 0,
    intClubID       INTEGER NOT NULL DEFAULT 0,
    strName         VARCHAR (50) NOT NULL,
    strContact      VARCHAR (100),
    strAddress1     VARCHAR (100),
    strAddress2     VARCHAR (100),
    strSuburb       VARCHAR (100),
    strPostalCode   VARCHAR (10),
    strState        VARCHAR (50),
    strPhone1       VARCHAR (20),
    strPhone2       VARCHAR (20),
    strEmail        VARCHAR (200),
    strExtKey	    VARCHAR (20),
    strNickname	    VARCHAR (20),
    dtRegistered    DATE,

PRIMARY KEY (intTeamID),
KEY index_strTeamNo(strTeamNo),
KEY index_strName(strName),
KEY index_intClubID(intClubID)
);
 
