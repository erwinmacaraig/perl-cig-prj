INSERT INTO
tblWFRule
(intRealmID,intSubRealmID,intOriginLevel,strWFRuleFor,strEntityType,intEntityLevel,strRegistrationNature,strPersonType,strPersonLevel,strPersonEntityRole,strSport,strAgeLevel,intApprovalEntityLevel,intProblemResolutionEntityLevel,strTaskType,strTaskStatus,intDocumentTypeID,tTimeStamp,strISOCountry_IN,strISOCountry_NOTIN)
VALUES
(1,0,3,'REGO','',3,'NEW','PLAYER','PROFESSIONAL','','FOOTBALL','ADULT',20,3,'APPROVAL','ACTIVE',0,NOW(),'',''),
(1,0,3,'REGO','',3,'NEW','PLAYER','PROFESSIONAL','','FOOTBALL','ADULT',100,3,'APPROVAL','ACTIVE',0,NOW(),'','');
