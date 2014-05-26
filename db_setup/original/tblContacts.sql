drop table IF EXISTS tblContacts;

#
# Table               : tblContacts
# Description         : Entity Contact Information
#---------------------
CREATE table tblContacts (
    intContactID       	INTEGER NOT NULL AUTO_INCREMENT,
	intContactRoleID	INT DEFAULT 0,
	intRealmID			INT DEFAULT 0,
	intAssocID			INT DEFAULT 0,
	intClubID			INT DEFAULT 0,
	intTeamID			INT DEFAULT 0,
	intMemberID			INT DEFAULT 0,
	
	strContactFirstname VARCHAR(50) DEFAULT '',
	strContactSurname	VARCHAR(50) DEFAULT '',
	strContactEmail		VARCHAR(100) DEFAULT '',
	strContactMobile	VARCHAR(20) DEFAULT '',

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
		KEY index_intAssocID(intAssocID),
		KEY index_ClubID(intClubID, intAssocID),
		KEY index_teamID(intTeamID)
);
