DROP TABLE if EXISTS tblProductDependencies;

CREATE TABLE tblProductDependencies (
    intProductDependencyID	INTEGER NOT NULL AUTO_INCREMENT,
    intProductID		int(11) NOT NULL,
    intDependentProductID       int(11) NOT NULL,
    intRealmID			int(11) default 0,
    intID			int(11) default 0,
    intLevel			int(11) default 0,
		
    PRIMARY KEY (intProductDependencyID)
,
	KEY index_intRealmID (intRealmID),
	KEY index_intIDLevel (intID, intLevel),
	KEY index_intProductID (intProductID)
);
