DELETE FROM tblMatrix WHERE strPersonType IN ('MAOFFICIAL', 'CLUBOFFICIAL', 'TEAMOFFICIAL') AND strRegistrationNature IN ('NEW', 'RENEWAL');
INSERT INTO tblMatrix VALUES (0,1,0,3,'REGO','','CLUBOFFICIAL','NEW', '','FOOTBALL',3,'',0,NOW(),NOW(),1,'',0,NULL,NULL);
INSERT INTO tblMatrix VALUES (0,1,0,3,'REGO','','CLUBOFFICIAL','NEW', '','FOOTBALL',20,'',0,NOW(),NOW(),1,'',0,NULL,NULL);
INSERT INTO tblMatrix VALUES (0,1,0,3,'REGO','','CLUBOFFICIAL','NEW', '','FOOTBALL',100,'',0,NOW(),NOW(),1,'',0,NULL,NULL);
INSERT INTO tblMatrix VALUES (0,1,0,3,'REGO','','CLUBOFFICIAL','RENEWAL', '','FOOTBALL',3,'',0,NOW(),NOW(),1,'',0,NULL,NULL);
INSERT INTO tblMatrix VALUES (0,1,0,3,'REGO','','CLUBOFFICIAL','RENEWAL', '','FOOTBALL',20,'',0,NOW(),NOW(),1,'',0,NULL,NULL);
INSERT INTO tblMatrix VALUES (0,1,0,3,'REGO','','CLUBOFFICIAL','RENEWAL', '','FOOTBALL',100,'',0,NOW(),NOW(),1,'',0,NULL,NULL);

INSERT INTO tblMatrix VALUES (0,1,0,3,'REGO','','CLUBOFFICIAL','NEW', '','FUTSAL',3,'',0,NOW(),NOW(),1,'',0,NULL,NULL);
INSERT INTO tblMatrix VALUES (0,1,0,3,'REGO','','CLUBOFFICIAL','NEW', '','FUTSAL',20,'',0,NOW(),NOW(),1,'',0,NULL,NULL);
INSERT INTO tblMatrix VALUES (0,1,0,3,'REGO','','CLUBOFFICIAL','NEW', '','FUTSAL',100,'',0,NOW(),NOW(),1,'',0,NULL,NULL);
INSERT INTO tblMatrix VALUES (0,1,0,3,'REGO','','CLUBOFFICIAL','RENEWAL', '','FUTSAL',3,'',0,NOW(),NOW(),1,'',0,NULL,NULL);
INSERT INTO tblMatrix VALUES (0,1,0,3,'REGO','','CLUBOFFICIAL','RENEWAL', '','FUTSAL',20,'',0,NOW(),NOW(),1,'',0,NULL,NULL);
INSERT INTO tblMatrix VALUES (0,1,0,3,'REGO','','CLUBOFFICIAL','RENEWAL', '','FUTSAL',100,'',0,NOW(),NOW(),1,'',0,NULL,NULL);


INSERT INTO tblMatrix VALUES (0,1,0,3,'REGO','','TEAMOFFICIAL','NEW', '','FOOTBALL',3,'',0,NOW(),NOW(),1,'',0,NULL,NULL);
INSERT INTO tblMatrix VALUES (0,1,0,3,'REGO','','TEAMOFFICIAL','NEW', '','FOOTBALL',100,'',0,NOW(),NOW(),1,'',0,NULL,NULL);
INSERT INTO tblMatrix VALUES (0,1,0,3,'REGO','','TEAMOFFICIAL','NEW', '','FOOTBALL',20,'',0,NOW(),NOW(),1,'',0,NULL,NULL);
INSERT INTO tblMatrix VALUES (0,1,0,3,'REGO','','TEAMOFFICIAL','RENEWAL', '','FOOTBALL',3,'',0,NOW(),NOW(),1,'',0,NULL,NULL);
INSERT INTO tblMatrix VALUES (0,1,0,3,'REGO','','TEAMOFFICIAL','RENEWAL', '','FOOTBALL',100,'',0,NOW(),NOW(),1,'',0,NULL,NULL);
INSERT INTO tblMatrix VALUES (0,1,0,3,'REGO','','TEAMOFFICIAL','RENEWAL', '','FOOTBALL',20,'',0,NOW(),NOW(),1,'',0,NULL,NULL);

INSERT INTO tblMatrix VALUES (0,1,0,3,'REGO','','TEAMOFFICIAL','NEW', '','FUTSAL',3,'',0,NOW(),NOW(),1,'',0,NULL,NULL);
INSERT INTO tblMatrix VALUES (0,1,0,3,'REGO','','TEAMOFFICIAL','NEW', '','FUTSAL',100,'',0,NOW(),NOW(),1,'',0,NULL,NULL);
INSERT INTO tblMatrix VALUES (0,1,0,3,'REGO','','TEAMOFFICIAL','NEW', '','FUTSAL',20,'',0,NOW(),NOW(),1,'',0,NULL,NULL);
INSERT INTO tblMatrix VALUES (0,1,0,3,'REGO','','TEAMOFFICIAL','RENEWAL', '','FUTSAL',3,'',0,NOW(),NOW(),1,'',0,NULL,NULL);
INSERT INTO tblMatrix VALUES (0,1,0,3,'REGO','','TEAMOFFICIAL','RENEWAL', '','FUTSAL',100,'',0,NOW(),NOW(),1,'',0,NULL,NULL);
INSERT INTO tblMatrix VALUES (0,1,0,3,'REGO','','TEAMOFFICIAL','RENEWAL', '','FUTSAL',20,'',0,NOW(),NOW(),1,'',0,NULL,NULL);

INSERT INTO tblMatrix VALUES (0,1,0,100,'REGO','','MAOFFICIAL','NEW', '','',100,'',0,NOW(),NOW(),1,'',0,NULL,NULL);
INSERT INTO tblMatrix VALUES (0,1,0,100,'REGO','','MAOFFICIAL','RENEWAL', '','',100,'',0,NOW(),NOW(),1,'',0,NULL,NULL);

DELETE FROM tblWFRule WHERE strPersonType IN ('MAOFFICIAL', 'CLUBOFFICIAL', 'TEAMOFFICIAL');
INSERT INTO tblWFRule(intRealmID, intOriginLevel, strWFRuleFor, strEntityType, intEntityLevel, strRegistrationNature, strPersonType, strPersonLevel, strSport, strAgeLevel, intApprovalEntityLevel, intProblemResolutionEntityLevel, strTaskType, strTaskStatus) VALUES(1,  3, 'REGO', '', 3, 'NEW', 'CLUBOFFICIAL', '', 'FOOTBALL', '', 100, 3, 'APPROVAL', 'ACTIVE');
INSERT INTO tblWFRule(intRealmID, intOriginLevel, strWFRuleFor, strEntityType, intEntityLevel, strRegistrationNature, strPersonType, strPersonLevel, strSport, strAgeLevel, intApprovalEntityLevel, intProblemResolutionEntityLevel, strTaskType, strTaskStatus) VALUES(1, 20, 'REGO', '', 3, 'NEW', 'CLUBOFFICIAL', '', 'FOOTBALL', '', 100, 3, 'APPROVAL', 'ACTIVE');
INSERT INTO tblWFRule(intRealmID, intOriginLevel, strWFRuleFor, strEntityType, intEntityLevel, strRegistrationNature, strPersonType, strPersonLevel, strSport, strAgeLevel, intApprovalEntityLevel, intProblemResolutionEntityLevel, strTaskType, strTaskStatus) VALUES(1,  3, 'REGO', '', 3, 'RENEWAL', 'CLUBOFFICIAL', '', 'FOOTBALL', '', 100, 3, 'APPROVAL', 'ACTIVE');
INSERT INTO tblWFRule(intRealmID, intOriginLevel, strWFRuleFor, strEntityType, intEntityLevel, strRegistrationNature, strPersonType, strPersonLevel, strSport, strAgeLevel, intApprovalEntityLevel, intProblemResolutionEntityLevel, strTaskType, strTaskStatus) VALUES(1, 20, 'REGO', '', 3, 'RENEWAL', 'CLUBOFFICIAL', '', 'FOOTBALL', '', 100, 3, 'APPROVAL', 'ACTIVE');

INSERT INTO tblWFRule(intRealmID, intOriginLevel, strWFRuleFor, strEntityType, intEntityLevel, strRegistrationNature, strPersonType, strPersonLevel, strSport, strAgeLevel, intApprovalEntityLevel, intProblemResolutionEntityLevel, strTaskType, strTaskStatus) VALUES(1,  3, 'REGO', '', 3, 'NEW', 'CLUBOFFICIAL', '', 'FUTSAL', '', 100, 3, 'APPROVAL', 'ACTIVE');
INSERT INTO tblWFRule(intRealmID, intOriginLevel, strWFRuleFor, strEntityType, intEntityLevel, strRegistrationNature, strPersonType, strPersonLevel, strSport, strAgeLevel, intApprovalEntityLevel, intProblemResolutionEntityLevel, strTaskType, strTaskStatus) VALUES(1, 20, 'REGO', '', 3, 'NEW', 'CLUBOFFICIAL', '', 'FUTSAL', '', 100, 3, 'APPROVAL', 'ACTIVE');
INSERT INTO tblWFRule(intRealmID, intOriginLevel, strWFRuleFor, strEntityType, intEntityLevel, strRegistrationNature, strPersonType, strPersonLevel, strSport, strAgeLevel, intApprovalEntityLevel, intProblemResolutionEntityLevel, strTaskType, strTaskStatus) VALUES(1,  3, 'REGO', '', 3, 'RENEWAL', 'CLUBOFFICIAL', '', 'FUTSAL', '', 100, 3, 'APPROVAL', 'ACTIVE');
INSERT INTO tblWFRule(intRealmID, intOriginLevel, strWFRuleFor, strEntityType, intEntityLevel, strRegistrationNature, strPersonType, strPersonLevel, strSport, strAgeLevel, intApprovalEntityLevel, intProblemResolutionEntityLevel, strTaskType, strTaskStatus) VALUES(1, 20, 'REGO', '', 3, 'RENEWAL', 'CLUBOFFICIAL', '', 'FUTSAL', '', 100, 3, 'APPROVAL', 'ACTIVE');

INSERT INTO tblWFRule(intRealmID, intOriginLevel, strWFRuleFor, strEntityType, intEntityLevel, strRegistrationNature, strPersonType, strPersonLevel, strSport, strAgeLevel, intApprovalEntityLevel, intProblemResolutionEntityLevel, strTaskType, strTaskStatus) VALUES(1,  3, 'REGO', '', 3, 'NEW', 'TEAMOFFICIAL', '', 'FOOTBALL', '', 100, 3, 'APPROVAL', 'ACTIVE');
INSERT INTO tblWFRule(intRealmID, intOriginLevel, strWFRuleFor, strEntityType, intEntityLevel, strRegistrationNature, strPersonType, strPersonLevel, strSport, strAgeLevel, intApprovalEntityLevel, intProblemResolutionEntityLevel, strTaskType, strTaskStatus) VALUES(1, 20, 'REGO', '', 3, 'NEW', 'TEAMOFFICIAL', '', 'FOOTBALL', '', 100, 3, 'APPROVAL', 'ACTIVE');
INSERT INTO tblWFRule(intRealmID, intOriginLevel, strWFRuleFor, strEntityType, intEntityLevel, strRegistrationNature, strPersonType, strPersonLevel, strSport, strAgeLevel, intApprovalEntityLevel, intProblemResolutionEntityLevel, strTaskType, strTaskStatus) VALUES(1,  3, 'REGO', '', 3, 'RENEWAL', 'TEAMOFFICIAL', '', 'FOOTBALL', '', 100, 3, 'APPROVAL', 'ACTIVE');
INSERT INTO tblWFRule(intRealmID, intOriginLevel, strWFRuleFor, strEntityType, intEntityLevel, strRegistrationNature, strPersonType, strPersonLevel, strSport, strAgeLevel, intApprovalEntityLevel, intProblemResolutionEntityLevel, strTaskType, strTaskStatus) VALUES(1, 20, 'REGO', '', 3, 'RENEWAL', 'TEAMOFFICIAL', '', 'FOOTBALL', '', 100, 3, 'APPROVAL', 'ACTIVE');

INSERT INTO tblWFRule(intRealmID, intOriginLevel, strWFRuleFor, strEntityType, intEntityLevel, strRegistrationNature, strPersonType, strPersonLevel, strSport, strAgeLevel, intApprovalEntityLevel, intProblemResolutionEntityLevel, strTaskType, strTaskStatus) VALUES(1,  3, 'REGO', '', 3, 'NEW', 'TEAMOFFICIAL', '', 'FUTSAL', '', 100, 3, 'APPROVAL', 'ACTIVE');
INSERT INTO tblWFRule(intRealmID, intOriginLevel, strWFRuleFor, strEntityType, intEntityLevel, strRegistrationNature, strPersonType, strPersonLevel, strSport, strAgeLevel, intApprovalEntityLevel, intProblemResolutionEntityLevel, strTaskType, strTaskStatus) VALUES(1, 20, 'REGO', '', 3, 'NEW', 'TEAMOFFICIAL', '', 'FUTSAL', '', 100, 3, 'APPROVAL', 'ACTIVE');
INSERT INTO tblWFRule(intRealmID, intOriginLevel, strWFRuleFor, strEntityType, intEntityLevel, strRegistrationNature, strPersonType, strPersonLevel, strSport, strAgeLevel, intApprovalEntityLevel, intProblemResolutionEntityLevel, strTaskType, strTaskStatus) VALUES(1,  3, 'REGO', '', 3, 'RENEWAL', 'TEAMOFFICIAL', '', 'FUTSAL', '', 100, 3, 'APPROVAL', 'ACTIVE');
INSERT INTO tblWFRule(intRealmID, intOriginLevel, strWFRuleFor, strEntityType, intEntityLevel, strRegistrationNature, strPersonType, strPersonLevel, strSport, strAgeLevel, intApprovalEntityLevel, intProblemResolutionEntityLevel, strTaskType, strTaskStatus) VALUES(1, 20, 'REGO', '', 3, 'RENEWAL', 'TEAMOFFICIAL', '', 'FUTSAL', '', 100, 3, 'APPROVAL', 'ACTIVE');
