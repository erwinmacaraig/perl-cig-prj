-- Created 080718 for the new Grades development
DROP TABLE tblGrades;

#
# Table               : tblGrades
# Description         : Defines seasons by Association and/or Realm
#---------------------

CREATE table tblGrades	(
	intGradeID		INT NOT NULL AUTO_INCREMENT,
    	intRealmID            	INT DEFAULT 0,
    	intRealmSubTypeID       INT DEFAULT 0,
    	intAssocID            	INT DEFAULT 0,
	strGradeName		VARCHAR(100),
	intGradeOrder		INT DEFAULT 0, -- Is it worth having an order for the seasons list
	intGradeGender 		TINYINT(4) DEFAULT 0,
	intActiveGrade		TINYINT(4) DEFAULT 0, 
	dtAdded		DATE,
	dtDOBStart	DATE,
	dtDOBEnd		DATE,
	tTimeStamp 		TIMESTAMP,

PRIMARY KEY (intGradeID),
KEY index_intAssocID(intAssocID),
KEY index_intRealm(intRealmID, intRealmSubTypeID)
);

