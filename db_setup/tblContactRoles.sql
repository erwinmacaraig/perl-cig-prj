drop table if exists tblContactRoles;

#
# Table               : tblContactRoles
# Description         : Contact Roles
#---------------------
CREATE table tblContactRoles (
    intRoleID       	INTEGER NOT NULL AUTO_INCREMENT,
	intRealmID			INT DEFAULT 0,
	intRealmSubTypeID	INT DEFAULT 0,
	
	intRoleOrder		INT DEFAULT 0,
	intShowAtTop		INT DEFAULT 0,
	intAllowMultiple	INT DEFAULT 0,
	
	strRoleName			VARCHAR(50) DEFAULT '',

	tTimeStamp      	TIMESTAMP,

	PRIMARY KEY (intRoleID),
	KEY index_Realm(intRealmID, intRealmSubTypeID)
);
