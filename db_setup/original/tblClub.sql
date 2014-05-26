drop table tblClub;

#
# Table               : tblClub
# Description         : Club Information
#---------------------
# intClubID           : Club ID
# intAssocID	      : Association ID
# intContactID	      : Contact ID
# strClubNo           : Club Number
# strName             : Club Name 
# strAbbrev           : Club Abbreviation
# strContact          : Cantact name 
# strAddress1         : Address line 1 
# strAddress2         : Address line 2 
# strSuburb           : Suburb 
# strPostalCode       : Postcode 
# strState            : State 
# strPhone            : Phone number 
# strFax              : Fax number 
# strEmail            : Email address 
#
CREATE table tblClub (
    intClubID       INTEGER NOT NULL AUTO_INCREMENT,
    strName         VARCHAR (50) NOT NULL,
    strAbbrev       VARCHAR (10),
    strClubNo       VARCHAR (50),
    strContact      VARCHAR (50),
    strAddress1     VARCHAR (50),
    strAddress2     VARCHAR (50),
    strSuburb       VARCHAR (50),
    strPostalCode   VARCHAR (15),
    strState        VARCHAR (20),
    strCountry      VARCHAR (30),
    strPhone        VARCHAR (20),
    strFax          VARCHAR (20),
    strEmail        VARCHAR (200),
    strExtKey				VARCHAR (20),
		PRIMARY KEY (intClubID),
		KEY index_strName(strName)
);
