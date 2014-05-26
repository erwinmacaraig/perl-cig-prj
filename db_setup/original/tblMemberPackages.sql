DROP TABLE tblMemberPackages;
CREATE table tblMemberPackages (
    intMemberPackagesID	     INTEGER NOT NULL AUTO_INCREMENT,
		intRealmID							 INTEGER NOT NULL,
		intAssocID							 INTEGER NOT NULL,
		strPackageName 					 VARCHAR(50),
PRIMARY KEY (intMemberPackagesID),
	KEY index_intRealmAssoc(intRealmID,intAssocID)
);
