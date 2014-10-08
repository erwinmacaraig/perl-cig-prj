DELETE FROM tblMatrix WHERE strPersonType IN ('MAOFFICIAL', 'CLUBOFFICIAL', 'TEAMOFFICIAL') AND strRegistrationNature IN ('NEW', 'RENEWAL');
INSERT INTO tblMatrix VALUES (0,1,0,3,'REGO','','CLUBOFFICIAL','NEW', '','',3,'',0,NOW(),NOW(),1,'',0,NULL,NULL);
INSERT INTO tblMatrix VALUES (0,1,0,3,'REGO','','CLUBOFFICIAL','NEW', '','',20,'',0,NOW(),NOW(),1,'',0,NULL,NULL);
INSERT INTO tblMatrix VALUES (0,1,0,3,'REGO','','CLUBOFFICIAL','NEW', '','',100,'',0,NOW(),NOW(),1,'',0,NULL,NULL);
INSERT INTO tblMatrix VALUES (0,1,0,3,'REGO','','CLUBOFFICIAL','RENEWAL', '','',3,'',0,NOW(),NOW(),1,'',0,NULL,NULL);
INSERT INTO tblMatrix VALUES (0,1,0,3,'REGO','','CLUBOFFICIAL','RENEWAL', '','',20,'',0,NOW(),NOW(),1,'',0,NULL,NULL);
INSERT INTO tblMatrix VALUES (0,1,0,3,'REGO','','CLUBOFFICIAL','RENEWAL', '','',100,'',0,NOW(),NOW(),1,'',0,NULL,NULL);


INSERT INTO tblMatrix VALUES (0,1,0,3,'REGO','','TEAMOFFICIAL','NEW', '','',3,'',0,NOW(),NOW(),1,'',0,NULL,NULL);
INSERT INTO tblMatrix VALUES (0,1,0,3,'REGO','','TEAMOFFICIAL','NEW', '','',100,'',0,NOW(),NOW(),1,'',0,NULL,NULL);
INSERT INTO tblMatrix VALUES (0,1,0,3,'REGO','','TEAMOFFICIAL','NEW', '','',20,'',0,NOW(),NOW(),1,'',0,NULL,NULL);
INSERT INTO tblMatrix VALUES (0,1,0,3,'REGO','','TEAMOFFICIAL','RENEWAL', '','',3,'',0,NOW(),NOW(),1,'',0,NULL,NULL);
INSERT INTO tblMatrix VALUES (0,1,0,3,'REGO','','TEAMOFFICIAL','RENEWAL', '','',100,'',0,NOW(),NOW(),1,'',0,NULL,NULL);
INSERT INTO tblMatrix VALUES (0,1,0,3,'REGO','','TEAMOFFICIAL','RENEWAL', '','',20,'',0,NOW(),NOW(),1,'',0,NULL,NULL);

INSERT INTO tblMatrix VALUES (0,1,0,100,'REGO','','MAOFFICIAL','NEW', '','',100,'',0,NOW(),NOW(),1,'',0,NULL,NULL);
INSERT INTO tblMatrix VALUES (0,1,0,100,'REGO','','MAOFFICIAL','RENEWAL', '','',100,'',0,NOW(),NOW(),1,'',0,NULL,NULL);

DELETE FROM tblWFRule WHERE strPersonType IN ('MAOFFICIAL', 'CLUBOFFICIAL', 'TEAMOFFICIAL');
INSERT INTO tblWFRule(intRealmID, intOriginLevel, strWFRuleFor, strEntityType, intEntityLevel, strRegistrationNature, strPersonType, strPersonLevel, strSport, strAgeLevel, intApprovalEntityLevel, intProblemResolutionEntityLevel, strTaskType, strTaskStatus) VALUES(1,  3, 'REGO', '', 3, 'NEW', 'CLUBOFFICIAL', '', '', '', 100, 3, 'APPROVAL', 'ACTIVE');
INSERT INTO tblWFRule(intRealmID, intOriginLevel, strWFRuleFor, strEntityType, intEntityLevel, strRegistrationNature, strPersonType, strPersonLevel, strSport, strAgeLevel, intApprovalEntityLevel, intProblemResolutionEntityLevel, strTaskType, strTaskStatus) VALUES(1, 20, 'REGO', '', 3, 'NEW', 'CLUBOFFICIAL', '', '', '', 100, 3, 'APPROVAL', 'ACTIVE');
INSERT INTO tblWFRule(intRealmID, intOriginLevel, strWFRuleFor, strEntityType, intEntityLevel, strRegistrationNature, strPersonType, strPersonLevel, strSport, strAgeLevel, intApprovalEntityLevel, intProblemResolutionEntityLevel, strTaskType, strTaskStatus) VALUES(1,  3, 'REGO', '', 3, 'RENEWAL', 'CLUBOFFICIAL', '', '', '', 100, 3, 'APPROVAL', 'ACTIVE');
INSERT INTO tblWFRule(intRealmID, intOriginLevel, strWFRuleFor, strEntityType, intEntityLevel, strRegistrationNature, strPersonType, strPersonLevel, strSport, strAgeLevel, intApprovalEntityLevel, intProblemResolutionEntityLevel, strTaskType, strTaskStatus) VALUES(1, 20, 'REGO', '', 3, 'RENEWAL', 'CLUBOFFICIAL', '', '', '', 100, 3, 'APPROVAL', 'ACTIVE');

INSERT INTO tblWFRule(intRealmID, intOriginLevel, strWFRuleFor, strEntityType, intEntityLevel, strRegistrationNature, strPersonType, strPersonLevel, strSport, strAgeLevel, intApprovalEntityLevel, intProblemResolutionEntityLevel, strTaskType, strTaskStatus) VALUES(1,  3, 'REGO', '', 3, 'NEW', 'TEAMOFFICIAL', '', '', '', 100, 3, 'APPROVAL', 'ACTIVE');
INSERT INTO tblWFRule(intRealmID, intOriginLevel, strWFRuleFor, strEntityType, intEntityLevel, strRegistrationNature, strPersonType, strPersonLevel, strSport, strAgeLevel, intApprovalEntityLevel, intProblemResolutionEntityLevel, strTaskType, strTaskStatus) VALUES(1, 20, 'REGO', '', 3, 'NEW', 'TEAMOFFICIAL', '', '', '', 100, 3, 'APPROVAL', 'ACTIVE');
INSERT INTO tblWFRule(intRealmID, intOriginLevel, strWFRuleFor, strEntityType, intEntityLevel, strRegistrationNature, strPersonType, strPersonLevel, strSport, strAgeLevel, intApprovalEntityLevel, intProblemResolutionEntityLevel, strTaskType, strTaskStatus) VALUES(1,  3, 'REGO', '', 3, 'RENEWAL', 'TEAMOFFICIAL', '', '', '', 100, 3, 'APPROVAL', 'ACTIVE');
INSERT INTO tblWFRule(intRealmID, intOriginLevel, strWFRuleFor, strEntityType, intEntityLevel, strRegistrationNature, strPersonType, strPersonLevel, strSport, strAgeLevel, intApprovalEntityLevel, intProblemResolutionEntityLevel, strTaskType, strTaskStatus) VALUES(1, 20, 'REGO', '', 3, 'RENEWAL', 'TEAMOFFICIAL', '', '', '', 100, 3, 'APPROVAL', 'ACTIVE');
