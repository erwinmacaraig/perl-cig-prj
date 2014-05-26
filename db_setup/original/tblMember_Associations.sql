DROP TABLE tblMember_Associations;
 
#
# Table               : tblMember_Associations
# Description         : Member Information for an Association they are registered for.
#---------------------
# intMemberAssociationID : Automatic Member Association ID 
# intMemberID         : Member ID
# intAssociationID    : Association ID 
#
CREATE table tblMember_Associations (
    intMemberAssociationID     INT NOT NULL AUTO_INCREMENT,
    intMemberID      INT NOT NULL,
    intAssocID	     INT NOT NULL,
		intStatus				 INT NOT NULL,
PRIMARY KEY (intMemberAssociationID),
KEY index_intMemberID(intMemberID),
KEY index_intStatus(intStatus),
KEY index_intAssociationID(intAssocID)
);
 
