
CREATE TABLE _tblDocumentConfig (
    intConfigID int(11) NOT NULL AUTO_INCREMENT,
    strRuleFor VARCHAR(30) DEFAULT '' COMMENT 'REGO, ENTITY',
    strRegistrationNature varchar(20) NOT NULL DEFAULT '0' COMMENT 'NEW,RENEWAL,AMENDMENT,TRANSFER,',
    strPersonType varchar(20) NOT NULL DEFAULT '' COMMENT 'PLAYER, COACH, REFEREE',
    strPersonLevel varchar(20) NOT NULL DEFAULT '' COMMENT 'AMATEUR,PROFESSIONAL',
    strPersonEntityRole varchar(50) DEFAULT '', /* head coach, doctor etc */
    strSport varchar(20) NOT NULL DEFAULT '' COMMENT 'FOOTBALL,FUTSAL,BEACHSOCCER',
    strAgeLevel varchar(20) NOT NULL DEFAULT '' COMMENT 'ADULT,MINOR',
    strItemType varchar(20) default '' COMMENT 'DOCUMENT (TYPE), PRODUCT',
    intID INT DEFAULT 0 COMMENT 'ID of strItemType',
    intUseExisting TINYINT DEFAULT 0, 
    intRequired TINYINT DEFAULT 0 COMMENT '0=Optional, 1 =Required',
    strISOCountry_IN varchar(200) DEFAULT NULL,
    strISOCountry_NOTIN varchar(200) DEFAULT NULL,
    intFilterFromAge INT DEFAULT 0,
    intFilterToAge INT DEFAULT 0,

	intItemNeededITC tinyint default 0 COMMENT 'Was an ITC needed',
	intItemUsingITCFilter tinyint default 0 COMMENT 'Using ITC filter',

	intItemForInternationalTransfer tinyint default 0,
    intItemForInternationalLoan TINYINT NULL DEFAULT 0,

    tTimeStamp timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (intConfigID)
) DEFAULT CHARSET=utf8;
