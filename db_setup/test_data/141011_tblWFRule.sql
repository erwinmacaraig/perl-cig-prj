UPDATE tblWFRule SET intProblemResolutionEntityLevel = 3 where intWFRuleID = 319;

INSERT INTO tblWFRule(intRealmID, intOriginLevel, strWFRuleFor, strEntityType, intEntityLevel, strRegistrationNature, strPersonType, strPersonLevel, strSport, strAgeLevel, intApprovalEntityLevel, intProblemResolutionEntityLevel, strTaskType, strTaskStatus) VALUES(1, 3, 'REGO', '', 3, 'NEW', 'PLAYER', 'PROFESSIONAL', 'FOOTBALL', 'ADULT', 100, 3, 'APPROVAL', 'ACTIVE');
