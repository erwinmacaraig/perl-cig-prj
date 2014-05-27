drop table IF EXISTS tblContacts;

CREATE table tblContacts (
    intContactID       	INTEGER NOT NULL AUTO_INCREMENT,
	intContactRoleID	INT DEFAULT 0,
	intRealmID			INT DEFAULT 0,
	intEntityID			INT DEFAULT 0,
	intMemberID			INT DEFAULT 0,
	
	intReceiveOffers	TINYINT DEFAULT 0,
	intProductUpdates 	TINYINT DEFAULT 0,

	intFnCompAdmin		TINYINT DEFAULT 0,
	intFnSocial			TINYINT DEFAULT 0,
	intFnWebsite		TINYINT DEFAULT 0,
	intFnClearances		TINYINT DEFAULT 0,
	intFnSponsorship	TINYINT DEFAULT 0,
	intFnPayments		TINYINT DEFAULT 0,
	intFnLegal			TINYINT DEFAULT 0,

	intPrimaryContact	TINYINT DEFAULT 0,
	intShowInLocator	TINYINT DEFAULT 0,

	tTimeStamp      	TIMESTAMP,

		PRIMARY KEY (intContactID),
		KEY index_intRealmID(intRealmID),
		KEY index_intMemberID(intMemberID),
		KEY index_EntityID(intEntityID)
);
