-- ENTITY - ADDING CLUB ENTITY (origin level = REGION; approval level = REGION)
INSERT INTO tblWFRule(intRealmID, intSubRealmID, intOriginLevel, strWFRuleFor, strEntityType, intEntityLevel, strRegistrationNature, strPersonType, strPersonLevel, strSport, strAgeLevel, intApprovalEntityLevel, intProblemResolutionEntityLevel, strTaskType, strTaskStatus, tTimeStamp, intDocumentTypeID, strPersonEntityRole, strISOCountry_IN, strISOCountry_NOTIN) VALUES(1, 0, 20, 'ENTITY', '', 3, 'NEW', '', '', '', '', 20, 20, 'APPROVAL', 'ACTIVE', now(), 0, '', '', '');

-- ENTITY - ADDING CLUB ENTITY (origin level = REGION; approval level = NATIONAL)
INSERT INTO tblWFRule(intRealmID, intSubRealmID, intOriginLevel, strWFRuleFor, strEntityType, intEntityLevel, strRegistrationNature, strPersonType, strPersonLevel, strSport, strAgeLevel, intApprovalEntityLevel, intProblemResolutionEntityLevel, strTaskType, strTaskStatus, tTimeStamp, intDocumentTypeID, strPersonEntityRole, strISOCountry_IN, strISOCountry_NOTIN) VALUES(1, 0, 20, 'ENTITY', '', 3, 'NEW', '', '', '', '', 100, 20, 'APPROVAL', 'ACTIVE', now(), 0, '', '', '');

-- ENTITY - ADDING VENUE as ENTITY (origin level = REGION; approval level = REGION)
INSERT INTO tblWFRule(intRealmID, intSubRealmID, intOriginLevel, strWFRuleFor, strEntityType, intEntityLevel, strRegistrationNature, strPersonType, strPersonLevel, strSport, strAgeLevel, intApprovalEntityLevel, intProblemResolutionEntityLevel, strTaskType, strTaskStatus, tTimeStamp, intDocumentTypeID, strPersonEntityRole, strISOCountry_IN, strISOCountry_NOTIN) VALUES(1, 0, 20, 'ENTITY', '', -47, 'NEW', '', '', '', '', 20, 20, 'APPROVAL', 'ACTIVE', now(), 0, '', '', '');

-- ENTITY - ADDING VENUE as ENTITY (origin level = REGION; approval level = NATIONAL)
INSERT INTO tblWFRule(intRealmID, intSubRealmID, intOriginLevel, strWFRuleFor, strEntityType, intEntityLevel, strRegistrationNature, strPersonType, strPersonLevel, strSport, strAgeLevel, intApprovalEntityLevel, intProblemResolutionEntityLevel, strTaskType, strTaskStatus, tTimeStamp, intDocumentTypeID, strPersonEntityRole, strISOCountry_IN, strISOCountry_NOTIN) VALUES(1, 0, 20, 'ENTITY', '', -47, 'NEW', '', '', '', '', 100, 20, 'APPROVAL', 'ACTIVE', now(), 0, '', '', '');

-- ENTITY - ADDING VENUE as ENTITY (origin level = CLUB; approval level = REGION)
INSERT INTO tblWFRule(intRealmID, intSubRealmID, intOriginLevel, strWFRuleFor, strEntityType, intEntityLevel, strRegistrationNature, strPersonType, strPersonLevel, strSport, strAgeLevel, intApprovalEntityLevel, intProblemResolutionEntityLevel, strTaskType, strTaskStatus, tTimeStamp, intDocumentTypeID, strPersonEntityRole, strISOCountry_IN, strISOCountry_NOTIN) VALUES(1, 0, 3, 'ENTITY', '', -47, 'NEW', '', '', '', '', 20, 3, 'APPROVAL', 'ACTIVE', now(), 0, '', '', '');

-- ENTITY - ADDING VENUE as ENTITY (origin level = CLUB; approval level = NATIONAL)
INSERT INTO tblWFRule(intRealmID, intSubRealmID, intOriginLevel, strWFRuleFor, strEntityType, intEntityLevel, strRegistrationNature, strPersonType, strPersonLevel, strSport, strAgeLevel, intApprovalEntityLevel, intProblemResolutionEntityLevel, strTaskType, strTaskStatus, tTimeStamp, intDocumentTypeID, strPersonEntityRole, strISOCountry_IN, strISOCountry_NOTIN) VALUES(1, 0, 3, 'ENTITY', '', -47, 'NEW', '', '', '', '', 100, 3, 'APPROVAL', 'ACTIVE', now(), 0, '', '', '');
