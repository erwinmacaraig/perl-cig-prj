CREATE table tblNodeLinks (
    intNodeLinksID   INT NOT NULL AUTO_INCREMENT,
    intParentNodeID  INT NOT NULL,
    intChildNodeID 	 INT NOT NULL,
		intPrimary			 TINYINT NOT NULL DEFAULT 1,

PRIMARY KEY (intNodeLinksID),
KEY index_intParentNodeID (intParentNodeID),
KEY index_intChildNodeID (intChildNodeID),
KEY index_intPrimary(intPrimary)
);
 
