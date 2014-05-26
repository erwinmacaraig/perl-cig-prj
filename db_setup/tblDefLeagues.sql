DROP TABLE tblDefLeagues;

#
# Table               : tblDefLeagues
# Description         : League Definitions
#---------------------
# intLeagueNO	      : LeagueNO
# intAssocID	      : Association ID
# strCode	      : Code	
# intCode	      : Code ID
# strName	      : Name of Code
#

CREATE table tblDefLeagues (
    intLeagueNO	    INTEGER NOT NULL AUTO_INCREMENT,
    intAssocID	    INTEGER NOT NULL DEFAULT 0,
    intLeague	    INTEGER NOT NULL DEFAULT 0,
    strName         VARCHAR (50) NOT NULL,
PRIMARY KEY (intLeagueNO),
KEY index_lookup(intLeague, intAssocID)
);
