drop table tblAssoc_Comp;
 
 
#
# Table               : tblAssoc_Comp
# Description         : Association Competition List
#---------------------
# intCompID           : Competition ID 
# intAssocID          : League (Association) ID 
# strTitle            : Competition Title 
# strAbbrev	      : Competition Abbreviation
# strSeason           : Season
# intCompGender       : Competition gender. From Defs.pm
# intGradeID          : Competition grade 
# intCompTypeID       : Competition Type ID
# strAgeLevel         : Age Level
# dtStart	      : Competition Start Date
# strContact	      : Competition Contact
# intStatus	      : Competition Status
#

CREATE table tblAssoc_Comp (
    intCompID       INTEGER NOT NULL AUTO_INCREMENT,
    intAssocID      INTEGER NOT NULL,
    strTitle        VARCHAR (150) NOT NULL,
    strAbbrev	    VARCHAR (10),
    strSeason       VARCHAR (10),
    intCompGender   INTEGER,
    intGradeID      INTEGER,
    intCompTypeID   INTEGER,
    strAgeLevel     VARCHAR (3),
    dtStart         DATE,
    strContact      VARCHAR (30),
    intStatus       INTEGER NOT NULL,
    intCompLevel    INTEGER DEFAULT 0,
PRIMARY KEY (intCompID, intAssocID)
);
 
