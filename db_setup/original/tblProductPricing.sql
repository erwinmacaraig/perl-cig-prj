DROP TABLE if EXISTS tblProductPricing;

CREATE TABLE tblProductPricing(
    intProductPricingID	INTEGER NOT NULL AUTO_INCREMENT,
	curAmount			decimal(12,2) default '0.00',
	intProductID		int(11) default 0,
	intRealmID			int(11) default 0,
	intID				int(11) default 0,
	intLevel		int(11) default 0,
		
    PRIMARY KEY (intProductPricingID),
	KEY index_intRealmID (intRealmID),
	KEY index_intID (intID),
	KEY index_intProductID (intProductID),
	KEY index_intLevel (intLevel)
);


