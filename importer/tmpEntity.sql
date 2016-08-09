DROP TABLE IF EXISTS tmpEntity;
CREATE TABLE tmpEntity (
    intID INT NOT NULL AUTO_INCREMENT,
    strFileType varchar(30) default '',
    strEntityType varchar(30) default '',
    strParentCode varchar(45) default '',
    strEntityCode varchar(30) default '',
    strMAID varchar(30) default '',
    strStatus varchar(30) default '',
    strLocalName varchar(100) default '',
    strLocalShortName varchar(100) default '',
    strLatinName varchar(100) default '',
    strLatinShortName varchar(100) default '',
    strISOCountry varchar(100) default '',
    strRegion varchar(100) default '',
    strCity varchar(100) default '',
    strState varchar(100) default '',
    strFax varchar(100) default '',
    strPhone varchar(100) default '',
    strAddress varchar(100) default '',
    strAddress2 varchar(100) default '',
    strPostalCode varchar(15) default '',
    strWebURL varchar(100) default '',
    strEmail varchar(200) default '',
    strLocalLanguage varchar(100) default '',
    dtFrom date,
    dtTo date,

    strDiscipline varchar(100) default '',
    strOrganisationLevel varchar(100) default '',
    intAcceptSelfRego INT DEFAULT 0,
    intNotifications INT DEFAULT 0,
    
    PRIMARY KEY (intID),
    INDEX index_strFileType (strFileType),
    INDEX index_entityCode (strEntityCode)
) DEFAULT CHARACTER SET = utf8;