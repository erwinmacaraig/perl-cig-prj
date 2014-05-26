DROP TABLE IF EXISTS tblCampaignPermissions;
 
CREATE table tblCampaignPermissions	(
	intID INT NOT NULL AUTO_INCREMENT,
  	intCampaignID		INT DEFAULT 0,
  	intRealmID 			INT DEFAULT 0,
  	intAssocID 			INT DEFAULT 0,
  	intClubID 			INT DEFAULT 0,
  	intPermissionStatus	TINYINT DEFAULT 0,
	dtAdded				datetime,
  	tTimeStamp        	TIMESTAMP,
		
	PRIMARY KEY (intID),
	UNIQUE KEY index_CampClub(intCampaignID, intRealmID, intAssocID, intClubID),
	KEY index_AssocClubID(intAssocID, intClubID)
);
 
