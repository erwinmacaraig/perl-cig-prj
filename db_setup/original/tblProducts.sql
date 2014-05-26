DROP TABLE if EXISTS tblProducts;

CREATE TABLE tblProducts(
    intProductID	INTEGER NOT NULL AUTO_INCREMENT,
	strName				varchar(100) default '',
	curDefaultAmount	decimal(12,2) default '0.00',
	intMinChangeLevel	int(11) default 0,
	intMinSellLevel		int(11) default 0,
	intCreatedLevel		int(11) default 0,
	intCreatedID		int(11) default 0,
	intAssocID			int(11) default 0,
	intRealmID			int(11) default 0,
		
    PRIMARY KEY (intProductID),
	KEY index_intAssocID (intAssocID),
	KEY index_intRealmID (intRealmID)
);


