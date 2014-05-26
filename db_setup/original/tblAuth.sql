DROP TABLE tblAuth;
 
#
# Table               : tblAuth
# Description         : Username and password information.
#---------------------
# intAuthID	      :
# strUsername         :
# strPassword         :
# intLevel            : A constant referring to the type of entity ie MEMBER, ASSOCIATION, ZONE etc
# intID               : The id code of this entity from the particular table as denoted in the previous field
# intAssocID          : Association ID
# intLogins           : Total number of logins so far, for your information
# dtLastlogin         : Last login date
# dtCreated           : Date this account was created
# strName             : Actual name of this person
# strContactnumber    : Phone contact number
# strEmail			  : Email Address
#

CREATE table tblAuth (
    intAuthID	     INTEGER NOT NULL AUTO_INCREMENT,
    strUsername      VARCHAR(12) NOT NULL,
    strPassword      VARCHAR(12) NOT NULL,
    intLevel         INT NOT NULL,
    intAssocID       INT NOT NULL DEFAULT 0 ,
    intID            INT NOT NULL,
    intLogins        INT,
    dtLastlogin      DATE,
    dtCreated        DATE,
    strName          VARCHAR(100),
    strEmail         VARCHAR(200),
    strContactnumber VARCHAR(20),
PRIMARY KEY (intAuthID),
KEY index_intLevel(intLevel,strPassword,strUsername)
);
