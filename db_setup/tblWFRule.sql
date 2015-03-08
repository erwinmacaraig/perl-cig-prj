DROP TABLE IF EXISTS tblWFRule;
CREATE TABLE tblWFRule (
  intWFRuleID int(11) NOT NULL AUTO_INCREMENT,
  intRealmID int(11) NOT NULL DEFAULT '0',
  intSubRealmID int(11) NOT NULL DEFAULT '0',

  intOriginLevel INT DEFAULT 0, /* ORIGIN LEVEL (See Defs) of the record */
  strWFRuleFor VARCHAR(30) DEFAULT '' COMMENT 'PERSON, REGO, ENTITY, DOCUMENT',

  strEntityType VARCHAR(30) DEFAULT '', /* School/Club -- Can even have School rules for a REGO*/
  intEntityLevel INT DEFAULT 0, /*Venue/Club*/

  strRegistrationNature varchar(20) NOT NULL DEFAULT '0' COMMENT 'NEW,RENEWAL,AMENDMENT,TRANSFER,',

  strPersonType varchar(20) NOT NULL DEFAULT '' COMMENT 'PLAYER, COACH, REFEREE',
  strPersonLevel varchar(20) NOT NULL DEFAULT '' COMMENT 'AMATEUR,PROFESSIONAL',
    strPersonEntityRole varchar(50) DEFAULT '', /* head coach, doctor etc */
  strSport varchar(20) NOT NULL DEFAULT '' COMMENT 'FOOTBALL,FUTSAL,BEACHSOCCER',
  strAgeLevel varchar(20) NOT NULL DEFAULT '' COMMENT 'ADULT,MINOR',

  intApprovalEntityLevel int(11) NOT NULL DEFAULT '0' COMMENT 'Which Entity level has to approve this rule',
  intProblemResolutionEntityLevel int(11) NOT NULL DEFAULT '0' COMMENT 'Which Entity Level to solve issues',

  strTaskType varchar(20) NOT NULL DEFAULT 'APPROVAL' COMMENT 'APPROVAL,DOCUMENT',
  strTaskStatus varchar(20) NOT NULL DEFAULT 'PENDING' COMMENT 'PENDING,ACTIVE',
  intDocumentTypeID int(11) NOT NULL DEFAULT '0',
   
    intAutoActivateOnPayment tinyint default 0 COMMENT 'Auto Activate Person/Rego on Payment',
    intLockTaskUntilPaid tinyint default 0 COMMENT 'Locks task until paid',
    intRemoveTaskOnPayment tinyint default 0 COMMENT 'On Payment, remove task and either go to next one or approve person/Rego/Entity',

  tTimeStamp timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (intWFRuleID),
  KEY Entity (intWFRuleID),
    KEY index_intRealmID (intRealmID, intSubRealmID),
    KEY index_RuleFor (strWFRuleFor)
) DEFAULT CHARSET=utf8 COMMENT='Defines the flow of approvals for a registration. One set of rules per Realm. Within Realm there is one row for each combination of PersonType, Level, Sport, Nature, AgeLevel';
