DROP TABLE tblMember_Types_Names;
 
#
# Table               : tblMember_Types_Names
# Description         : Names for the fields in the Member_Types Table
#---------------------
# intMemberTypeID : Member Type ID 

CREATE table tblMember_Types_Names (
    intMemberTypeID        INT NOT NULL,
    strString1Name         VARCHAR(50),
    strString2Name         VARCHAR(50),
    strString3Name         VARCHAR(50),
    strString4Name         VARCHAR(50),
    strString5Name         VARCHAR(50),
    strString6Name         VARCHAR(50),
    strInt1Name            VARCHAR(50),
    strInt2Name            VARCHAR(50),
    strInt3Name            VARCHAR(50),
    strInt4Name            VARCHAR(50),
    strInt5Name            VARCHAR(50),
    strInt6Name            VARCHAR(50),
    strInt7Name            VARCHAR(50),
    strInt8Name            VARCHAR(50),
    strInt9Name            VARCHAR(50),
    strInt10Name           VARCHAR(50),
    strDate1Name           VARCHAR(50),
    strDate2Name           VARCHAR(50),
PRIMARY KEY (intMemberTypeID)
);
 
