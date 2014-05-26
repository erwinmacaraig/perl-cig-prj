DROP TABLE IF EXISTS tblCustomFields;
 
CREATE table tblCustomFields	(
	intCustomFieldsID INT NOT NULL AUTO_INCREMENT,
  intAssocID 			INT NOT NULL,
	strDBFName			VARCHAR(30) NOT NULL,
	strName					VARCHAR(30) NOT NULL,
	intLocked				SMALLINT NOT NULL DEFAULT 0,

	PRIMARY KEY (intCustomFieldsID),
	KEY index_AssocID(intAssocID)
);
