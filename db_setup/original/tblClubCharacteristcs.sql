DROP TABLE IF EXISTS tblClubCharacteristics;
CREATE TABLE tblClubCharacteristics (
	intCharacteristicID INT NOT NULL,
	intClubID INT NOT NULL,

	PRIMARY KEY (intCharacteristicID, intClubID),
	INDEX index_club(intClubID)
); 
