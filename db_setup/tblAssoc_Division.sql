drop table tblAssoc_Division;

# Table               : tblAssoc_Division
# Description         : Associations Divisions 
#----------------
# intDivisionID       : Division Identifier 
# intAssocID          : Association ID
# strDivision         : Division
#
CREATE table tblAssoc_Division (
    intDivisionID   INT NOT NULL AUTO_INCREMENT,	
    intAssocID      INTEGER NOT NULL,
    strDivision     VARCHAR (150) NOT NULL,
PRIMARY KEY (intDivisionID),
KEY index_intAssocID(intAssocID)
);
 
 
