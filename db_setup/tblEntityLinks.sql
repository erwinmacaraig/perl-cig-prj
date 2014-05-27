CREATE table tblEntityLinks (
    intEntityLinksID   INT NOT NULL AUTO_INCREMENT,
    intParentEntityID  INT NOT NULL,
    intChildEntityID 	 INT NOT NULL,
		intPrimary			 TINYINT NOT NULL DEFAULT 1,
    intDataAccess   TINYINT NOT NULL DEFAULT 10,

PRIMARY KEY (intEntityLinksID),
KEY index_intParentEntityID (intParentEntityID),
KEY index_intChildEntityID (intChildEntityID),
KEY index_intPrimary(intPrimary)
);
 
