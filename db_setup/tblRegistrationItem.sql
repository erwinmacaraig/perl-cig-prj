DROP TABLE IF EXISTS tblRegistrationItem;

CREATE TABLE tblRegistrationItem (
    intItemID int(11) NOT NULL AUTO_INCREMENT,
    intRealmID int(11) NOT NULL DEFAULT '0',
    intSubRealmID int(11) NOT NULL DEFAULT '0',

    intOriginLevel INT DEFAULT 0, /* ORIGIN LEVEL (See Defs) of the record. 0 = ALL */
    strRuleFor VARCHAR(30) DEFAULT '' COMMENT 'REGO, ENTITY',

    strEntityType VARCHAR(30) DEFAULT '', /* School/Club -- Can even have School rules for a REGO*/
    intEntityLevel INT DEFAULT 0, /*Persin/Venue/Club*/


    strRegistrationNature varchar(20) NOT NULL DEFAULT '0' COMMENT 'NEW,RENEWAL,AMENDMENT,TRANSFER,',

    strPersonType varchar(20) NOT NULL DEFAULT '' COMMENT 'PLAYER, COACH, REFEREE',
    strPersonLevel varchar(20) NOT NULL DEFAULT '' COMMENT 'AMATEUR,PROFESSIONAL',
    strPersonEntityRole varchar(50) DEFAULT '', /* head coach, doctor etc */
    strSport varchar(20) NOT NULL DEFAULT '' COMMENT 'FOOTBALL,FUTSAL,BEACHSOCCER',
    strAgeLevel varchar(20) NOT NULL DEFAULT '' COMMENT 'ADULT,MINOR',

    strItemType varchar(20) default '' COMMENT 'DOCUMENT (TYPE), PRODUCT',
    intID INT DEFAULT 0 COMMENT 'ID of strItemType',

    intUseExistingThisEntity TINYINT DEFAULT 0, /* An existing use of this ID is possible within this entity */
    intUseExistingAnyEntity TINYINT DEFAULT 0,/* An existing use of this ID is Ok against ANY entity */
    intPaymentRequired TINYINT DEFAULT 0 COMMENT '0=Optional, 1 =Required', /* Sets intPaymentRequired in tblPersonRego */
    intRequired TINYINT DEFAULT 0 COMMENT '0=Optional, 1 =Required',
    strISOCountry_IN varchar(200) DEFAULT NULL,
    strISOCountry_NOTIN varchar(200) DEFAULT NULL,
    intFilterFromAge INT DEFAULT 0,
    intFilterToAge INT DEFAULT 0,
	intItemNeededITC tinyint default 0 COMMENT 'Was an ITC needed',
	intItemUsingITCFilter tinyint default 0 COMMENT 'Using ITC filter',

	intItemUsingActiveFilter tinyint default 0 COMMENT 'Using Active Periods filter',
	strItemActiveFilter varchar(10) default '' COMMENT 'Which Periods to check Active on',
	intItemActive tinyint default 0 COMMENT 'Active status if Active Periods filter on',

	intItemUsingPaidProductFilter tinyint default 0 COMMENT 'Using Active Products filter',
	strItemActiveFilterPaidProducts varchar(10) default '' COMMENT 'Which Products to check Active on',
	intItemPaidProducts tinyint default 0 COMMENT 'Active status if Active Products filter on',

    tTimeStamp timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,


    PRIMARY KEY (intItemID),
    KEY index_Realms (intRealmID, intSubRealmID),
    KEY strRuleFor (strRuleFor)
) DEFAULT CHARSET=utf8;
