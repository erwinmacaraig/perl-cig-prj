DROP TABLE tblDefCodes;

CREATE table tblDefCodes (
    intCodeID	    INTEGER NOT NULL AUTO_INCREMENT,
    intAssocID	    INTEGER NOT NULL DEFAULT 0,
    intTypeID	    INTEGER NOT NULL,
    strCode	    VARCHAR (10) NOT NULL,
    intCode	    INTEGER NOT NULL DEFAULT 0,
    strName         VARCHAR (50) NOT NULL,
		strExtKey			VARCHAR(20) NOT NULL DEFAULT '',

PRIMARY KEY (intCodeID),
KEY index_intAssocID(intAssocID),
KEY index_intAssocIDTypeID(intAssocID,intTypeID),
KEY index_strName(strName),
KEY index_Lookup(intAssocID,intTypeID,strCode)
);
