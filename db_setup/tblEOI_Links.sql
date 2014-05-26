CREATE table tblEOI_Links	(
	intRealmID	INT,
	intAssocID	INT,
	intClubID	INT,
	intEOIID	INT,
	dtCreated	DATETIME,

PRIMARY KEY (intAssocID, intClubID, intEOIID),
	KEY index_intRealmID(intRealmID),
	KEY index_intClubID(intClubID)
);
 
