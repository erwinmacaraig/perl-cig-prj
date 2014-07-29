CREATE TABLE `tblMatrix` (
    intMatrixID int NOT NULL AUTO_INCREMENT,
    intRealmID  INT DEFAULT 0,
    intSubRealmID  INT DEFAULT 0,
    intEntityLevel TINYINT DEFAULT 0, /* club/venue/person */
    strWFRuleFor VARCHAR(30) DEFAULT '',
    strEntityType VARCHAR(30) DEFAULT '', /* School/club /Player/COACH*/
    strPersonType VARCHAR(30) DEFAULT '', /* School/club /Player/COACH*/
    strRegistrationNature VARCHAR(30) DEFAULT '',
    strPersonLevel varchar(10) DEFAULT '', /* pro, amateur */  
    strSport    VARCHAR(20) DEFAULT '',
    intOriginLevel INT DEFAULT 0, /* Self, club, Reg, MA */
    strAgeLevel VARCHAR(20) NOT NULL DEFAULT 'ALL', /* ALL,ADULT,MINOR */
    intPaymentRequired TINYINT DEFAULT 0,
    intProblemResolutionLevel INT NOT NULL DEFAULT 3,
    dtAdded date,

    tTimeStamp timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  PRIMARY KEY (intMatrixID),
  KEY `index_intRealmID` (`intRealmID`, intSubRealmID),
  KEY `index_strWFRuleFor` (`strWFRuleFor`),
  KEY `index_intPersonType` (`strPersonType`)
) DEFAULT CHARSET=utf8;
