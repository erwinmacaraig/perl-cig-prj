DROP TABLE IF EXISTS tblWFRule;
CREATE TABLE `tblWFRule` (
  `intWFRuleID` int(11) NOT NULL AUTO_INCREMENT,
  `intRealmID` int(11) NOT NULL DEFAULT '0',
  `intSubRealmID` int(11) NOT NULL DEFAULT '0',
  `strPersonType` varchar(20) NOT NULL DEFAULT '' COMMENT 'PLAYER, COACH, REFEREE',
  `strPersonLevel` varchar(20) NOT NULL DEFAULT '' COMMENT 'AMATEUR,PROFESSIONAL',
  `strSport` varchar(20) NOT NULL DEFAULT '' COMMENT 'FOOTBALL,FUTSAL,BEACHSOCCER',
  `strRegistrationNature` varchar(20) NOT NULL DEFAULT '0' COMMENT 'NEW,RENEWAL,AMENDMENT,TRANSFER,',
  `strAgeLevel` varchar(20) NOT NULL DEFAULT '' COMMENT 'SENIOR,JUNIOR',
  `intPaymentRequired` int(11) NOT NULL DEFAULT '0' COMMENT 'Is a payment required for this type of registration',
  `intApprovalEntityID` int(11) NOT NULL DEFAULT '0' COMMENT 'Which Entity has to approve this rule',
  `intApprovalRoleID` int(11) NOT NULL DEFAULT '0' COMMENT 'Which Role, within and Entity must approve this rule',
  `strTaskType` varchar(20) NOT NULL DEFAULT 'APPROVAL' COMMENT 'APPROVAL,DOCUMENT',
  `intDocumentTypeID` int(11) NOT NULL DEFAULT '0',
  `strTaskStatus` varchar(20) NOT NULL DEFAULT 'PENDING' COMMENT 'PENDING,ACTIVE',
  `intProblemResolutionRoleID` int(11) NOT NULL DEFAULT '0',
  `intProblemResolutionEntityID` int(11) NOT NULL DEFAULT '0',
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`intWFRuleID`),
  KEY `Entity` (`intWFRuleID`),
    KEY index_intRealmID (intRealmID, intSubRealmID)
) DEFAULT CHARSET=utf8 COMMENT='Defines the flow of approvals for a registration. One set of rules per Realm. Within Realm there is one row for each combination of PersonType, Level, Sport, Nature, AgeLevel';
