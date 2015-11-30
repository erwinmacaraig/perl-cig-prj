DROP TABLE IF EXISTS tmpEntityLinkage;
CREATE TABLE tmpEntityLinkage (
    strEntityCode varchar(10) default '',
    strRegionEntityCode varchar(10) default '',
    intChildEntityID INT default 0,
    intParentEntityID INT default 0,
    
    INDEX index_Entity (intChildEntityID, intParentEntityID),
    INDEX index_entityCodes (strEntityCode, strRegionEntityCode)
) DEFAULT CHARACTER SET = utf8;
