DROP TABLE tblDefCompTypes;

CREATE table tblDefCompTypes (
    intCompTypeNO   INTEGER NOT NULL AUTO_INCREMENT,
    intAssocID	    INTEGER NOT NULL DEFAULT 0,
    intCompType	    INTEGER NOT NULL,
    strName         VARCHAR (50) NOT NULL,

PRIMARY KEY (intCompTypeNO),
KEY index_lookup(intAssocID,intCompType)
);
