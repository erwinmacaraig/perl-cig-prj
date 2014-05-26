DROP TABLE IF EXISTS tblMember_Campaigns ;
 
CREATE table tblMember_Campaigns (
	intMemberCampaignID INT NOT NULL AUTO_INCREMENT,
  	intMemberID			INT NOT NULL,
  	intCampaignID		INT DEFAULT 0,
  	intAssocID 			INT DEFAULT 0,
  	intClubID 			INT DEFAULT 0,
  	intRegoFormID		INT DEFAULT 0,
  	intCampaignStatus 	INT DEFAULT 0,
		dtAdded				datetime,
  	tTimeStamp        	TIMESTAMP,
		dtSent				DATETIME,
		strExtRef			VARCHAR(50) DEFAULT '',
		strResponse	TEXT,
		strExtRef2			VARCHAR(50) DEFAULT '',
		strResponse2	TEXT,
		
	PRIMARY KEY (intMemberCampaignID),
	UNIQUE KEY index_CampMemberID(intMemberID, intCampaignID),
	KEY index_AssocClubID(intAssocID, intClubID),
	KEY index_CampaignID(intCampaignID)
);
 
