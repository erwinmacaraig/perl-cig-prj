DROP TABLE tblMember_Types;
 
#
# Table               : tblMember_Types
# Description         : Member Information for all the types they are, eg: Player, coach etc...
#---------------------
# intMemberTypeID : Automatic Member ID 
# intMemberID     : Member's Number
# intTypeID       : Type of Member : eg Player

CREATE table tblMember_Types (
    intMemberTypeID        INT NOT NULL AUTO_INCREMENT,
    intMemberID            INT NOT NULL,
    intTypeID              INT NOT NULL,
    intSubTypeID           INT NOT NULL DEFAULT 0,
    intActive   	         TINYINT NOT NULL DEFAULT 0,
    strString1             VARCHAR(100),
    strString2             VARCHAR(100),
    strString3             VARCHAR(100),
    strString4             VARCHAR(100),
    strString5             VARCHAR(100),
    strString6             VARCHAR(100),
    intInt1                INT DEFAULT 0,
    intInt2                INT DEFAULT 0,
    intInt3                INT DEFAULT 0,
    intInt4                INT DEFAULT 0,
    intInt5                INT DEFAULT 0,
    intInt6                INT DEFAULT 0,
    intInt7                INT DEFAULT 0,
    intInt8                INT DEFAULT 0,
    intInt9                INT DEFAULT 0,
    intInt10               INT DEFAULT 0,
    dtDate1                DATE,
    dtDate2                DATE,
PRIMARY KEY (intMemberTypeID),
KEY index_intMemberID(intMemberID),
KEY index_intTypeID(intTypeID),
KEY index_intSubTypeID(intSubTypeID)
);
 
