drop table tblNode;

# Table               : tblNode
# Description         : Node 
#----------------
# intNodeID         : Node Identifier 
# strName             : Full Name of Nodeiation
# strContact          : Primary Contact Person 
# strAddress1         : Address 1 
# strAddress2         : Address 2 
# strAddress3         : Address 3 
# strPostalCode       : Postcode 
# strState            : State 
# strPhone            : Phone Number 
# strFax              : Fax Number 
# strEmail            : Email address 
# intTypeID           :

CREATE table tblNode (
    intNodeID     INT NOT NULL AUTO_INCREMENT, 
    intTypeID       INT NOT NULL DEFAULT 0,
    intStatusID     TINYINT NOT NULL DEFAULT 1,
    strName         VARCHAR (150) NOT NULL,
    strNameAbbrev   VARCHAR (50),
    strContact      VARCHAR (50),
    strAddress1     VARCHAR (50),
    strAddress2     VARCHAR (50),
    strSuburb       VARCHAR (50),
    strState        VARCHAR (50),
    strCountry      VARCHAR (50),
    strPostalCode   VARCHAR (15),
    strPhone        VARCHAR (20),
    strFax          VARCHAR (20),
    strEmail        VARCHAR (250) NOT NULL,


PRIMARY KEY (intNodeID),
KEY index_strName(strName),
KEY index_intStatusID(intStatusID),
KEY index_intTypeID(intTypeID)
);
 

