DELETE FROM tblWFRule WHERE intWFRuleID > 0;
INSERT INTO tblWFRule(intWFRuleID,intRealmID,intSubRealmID,intEntityID,intEntityLevel,strEntityType,strPersonType,strPersonLevel,strSport,strRegistrationType,intRegistrationNature,strAgeLevel,intSeasonID,intNationalPeriodID,intRoleID,intVersionID,intOriginLevel,strTaskType,intDocumentTypeID,strTaskStatus,intOriginID,intProblemResolutionLevel) VALUES (1,1,2,35,2,'CLUB','PLAYER','AMATEUR','FOOTBALL','REGISTRATION',0,'SENIOR',0,0,3,0,0,'DOCUMENT',1,'ACTIVE',0,0);
INSERT INTO tblWFRule(intWFRuleID,intRealmID,intSubRealmID,intEntityID,intEntityLevel,strEntityType,strPersonType,strPersonLevel,strSport,strRegistrationType,intRegistrationNature,strAgeLevel,intSeasonID,intNationalPeriodID,intRoleID,intVersionID,intOriginLevel,strTaskType,intDocumentTypeID,strTaskStatus,intOriginID,intProblemResolutionLevel) VALUES (2,1,2,35,2,'CLUB','PLAYER','AMATEUR','FOOTBALL','REGISTRATION',0,'SENIOR',0,0,3,0,0,'DOCUMENT',2,'ACTIVE',0,0);
INSERT INTO tblWFRule(intWFRuleID,intRealmID,intSubRealmID,intEntityID,intEntityLevel,strEntityType,strPersonType,strPersonLevel,strSport,strRegistrationType,intRegistrationNature,strAgeLevel,intSeasonID,intNationalPeriodID,intRoleID,intVersionID,intOriginLevel,strTaskType,intDocumentTypeID,strTaskStatus,intOriginID,intProblemResolutionLevel) VALUES (3,1,2,35,2,'CLUB','PLAYER','AMATEUR','FOOTBALL','REGISTRATION',0,'SENIOR',0,0,3,0,0,'DOCUMENT',3,'ACTIVE',0,0);
INSERT INTO tblWFRule(intWFRuleID,intRealmID,intSubRealmID,intEntityID,intEntityLevel,strEntityType,strPersonType,strPersonLevel,strSport,strRegistrationType,intRegistrationNature,strAgeLevel,intSeasonID,intNationalPeriodID,intRoleID,intVersionID,intOriginLevel,strTaskType,intDocumentTypeID,strTaskStatus,intOriginID,intProblemResolutionLevel) VALUES (4,1,2,35,2,'CLUB','PLAYER','AMATEUR','FOOTBALL','REGISTRATION',0,'SENIOR',0,0,3,0,0,'APPROVAL',0,'PENDING',0,0);
INSERT INTO tblWFRule(intWFRuleID,intRealmID,intSubRealmID,intEntityID,intEntityLevel,strEntityType,strPersonType,strPersonLevel,strSport,strRegistrationType,intRegistrationNature,strAgeLevel,intSeasonID,intNationalPeriodID,intRoleID,intVersionID,intOriginLevel,strTaskType,intDocumentTypeID,strTaskStatus,intOriginID,intProblemResolutionLevel) VALUES (5,1,2,35,2,'CLUB','PLAYER','AMATEUR','FOOTBALL','REGISTRATION',0,'SENIOR',0,0,2,0,0,'APPROVAL',0,'PENDING',0,0);
INSERT INTO tblWFRule(intWFRuleID,intRealmID,intSubRealmID,intEntityID,intEntityLevel,strEntityType,strPersonType,strPersonLevel,strSport,strRegistrationType,intRegistrationNature,strAgeLevel,intSeasonID,intNationalPeriodID,intRoleID,intVersionID,intOriginLevel,strTaskType,intDocumentTypeID,strTaskStatus,intOriginID,intProblemResolutionLevel) VALUES (6,1,2,35,2,'CLUB','PLAYER','AMATEUR','FOOTBALL','REGISTRATION',0,'SENIOR',0,0,1,0,0,'APPROVAL',0,'PENDING',0,0);


DELETE FROM tblWFRulePreReq WHERE intWFRulePreReqID > 0;
INSERT INTO tblWFRulePreReq(intWFRulePreReqID,intWFRuleID,intPreReqWFRuleID) VALUES (1,4,1);
INSERT INTO tblWFRulePreReq(intWFRulePreReqID,intWFRuleID,intPreReqWFRuleID) VALUES (2,4,2);
INSERT INTO tblWFRulePreReq(intWFRulePreReqID,intWFRuleID,intPreReqWFRuleID) VALUES (3,4,3);
INSERT INTO tblWFRulePreReq(intWFRulePreReqID,intWFRuleID,intPreReqWFRuleID) VALUES (4,5,4);
INSERT INTO tblWFRulePreReq(intWFRulePreReqID,intWFRuleID,intPreReqWFRuleID) VALUES (5,6,5);

DELETE FROM tblRolePerson WHERE intRolePersonID > 0;
INSERT INTO tblRolePerson(intRolePersonID,intPersonID,intRoleID,intEntityID) VALUES (1,10759048,1,1);
INSERT INTO tblRolePerson(intRolePersonID,intPersonID,intRoleID,intEntityID) VALUES (2,10759049,2,14);
INSERT INTO tblRolePerson(intRolePersonID,intPersonID,intRoleID,intEntityID) VALUES (3,10759057,3,35);

DELETE FROM tblRole WHERE intRoleID > 0;
INSERT INTO tblRole(intRoleID,intRealmID, intEntityID,strTitle) VALUES (1,1,1,'Administrator');
INSERT INTO tblRole(intRoleID,intRealmID, intEntityID,strTitle) VALUES (2,1,14,'Administrator');
INSERT INTO tblRole(intRoleID,intRealmID, intEntityID,strTitle) VALUES (3,1,35,'Registrar');


DELETE FROM tblDocumentType WHERE intDocumentTypeID > 0;
INSERT INTO tblDocumentType(intDocumentTypeID,intRealmID,strDocumentName,intActive) VALUES (1,1,'Medical Certificate',NULL);
INSERT INTO tblDocumentType(intDocumentTypeID,intRealmID,strDocumentName,intActive) VALUES (2,1,'Clearance Document',NULL);
INSERT INTO tblDocumentType(intDocumentTypeID,intRealmID,strDocumentName,intActive) VALUES (3,1,'Note from your Mum',NULL);
