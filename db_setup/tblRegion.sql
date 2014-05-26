drop table tblRegion;

# Table               : tblRegion
# Description         : Region 
#----------------
# intRegionID         : Region Identifier 
# strName             : Full Name of Regioniation
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

CREATE table tblRegion (
    intRegionID     INT NOT NULL AUTO_INCREMENT, 
    strName         VARCHAR (150) NOT NULL,
    strNameAbbrev   VARCHAR (50),
    strContact      VARCHAR (50),
    strAddress1     VARCHAR (50),
    strAddress2     VARCHAR (50),
    strAddress3     VARCHAR (50),
    strSuburb       VARCHAR (50),
    strState        VARCHAR (50),
    strPostalCode   VARCHAR (15),
    strPhone        VARCHAR (20),
    strFax          VARCHAR (20),
    strEmail        VARCHAR (200) NOT NULL,
    intTypeID       INT NOT NULL,
    intDataAccess   INT NOT NULL DEFAULT 2,


PRIMARY KEY (intRegionID),
KEY index_strName(strName),
KEY index_intRegionID(intRegionID)
);
 

#intTypeID
# 0 Place Holder - Region Not Used
# 1 Logical Separator
# 2 Full Level
 
