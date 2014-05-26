DROP TABLE if EXISTS tblProductAttributes;

CREATE TABLE tblProductAttributes (
    intProductAttributeID	INTEGER NOT NULL AUTO_INCREMENT,
    intProductID            int(11) NOT NULL,
    intAttributeType      int(11) NOT NULL,
    strAttributeValue		VARCHAR(50) NOT NULL,
    intRealmID				int(11) default 0,
    intID					int(11) default 0,
    intLevel				int(11) default 0,
		
    PRIMARY KEY (intProductAttributeID)
,
	KEY index_intRealmID (intRealmID),
	KEY index_intIDLevel (intID, intLevel),
	KEY index_intProductID (intProductID)
);
