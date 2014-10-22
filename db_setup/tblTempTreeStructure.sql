DROP TABLE IF EXISTS tblTempTreeStructure;
CREATE table tblTempTreeStructure	(
	intRealmID		INT DEFAULT 0,
	int100_ID		INT DEFAULT 0,
	int30_ID		INT DEFAULT 0,
	int20_ID		INT DEFAULT 0,
	int10_ID		INT DEFAULT 0,
	int3_ID		    INT DEFAULT 0,
	tTimeStamp   TIMESTAMP,

KEY index_100_ID (int100_ID),
KEY index_10_ID (int10_ID),
KEY index_int10_20ID (int10_ID, int20_ID),
KEY index_int20_30ID (int20_ID, int30_ID),
KEY index_int30_100ID (int30_ID, int100_ID),
KEY index_int3_100ID (int3_ID, int100_ID),
KEY index_intRealmID (intRealmID)
);
 
