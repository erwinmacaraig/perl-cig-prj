-- Created 080718 for the new Seasons development
DROP TABLE IF EXISTS tblAgeGroups;

#
# Table               : tblAgeGroups
# Description         : Defines Age Groups by Association and/or Realm
#---------------------

CREATE table tblAgeGroups	(
	intAgeGroupID		INT NOT NULL AUTO_INCREMENT,
    	intRealmID            	INT DEFAULT 0,
    	intRealmSubTypeID       INT DEFAULT 0,
    	intAssocID            	INT DEFAULT 0,
	strAgeGroupDesc		VARCHAR(100),
	intAgeGroupGender 	INT DEFAULT 0, -- Is it worth having an order for the seasons list
	intRecStatus 		TINYINT(4) DEFAULT 0, -- Is it worth having an order for the seasons list
	dtDOBStart		DATE,
	dtDOBEnd		DATE,
	dtAdded		DATE,
	intCategoryID INT DEFAULT 0,
	tTimeStamp 		TIMESTAMP,

PRIMARY KEY (intAgeGroupID),
KEY index_intAssocID(intAssocID),
KEY index_intRealm(intRealmID, intRealmSubTypeID)
);

