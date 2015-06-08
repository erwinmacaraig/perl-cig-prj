UPDATE tblWFRule SET intCopiedFromRuleID=intCopiedFromRuleID*-1 WHERE intCopiedFromRuleID >0;

UPDATE tblWFRule SET intUsingITCFilter=1 WHERE intAutoActivateOnPayment=1 AND strPersonLevel NOT IN ('HOBBY') and strRegistrationNature='NEW';

INSERT INTO tblWFRule SELECT 0, intRealmID, intSubRealmID, intOriginLevel, strWFRuleFor, strEntityType, intEntityLevel, strRegistrationNature, strPersonType, strPersonLevel, strSport, strAgeLevel, intApprovalEntityLevel, intProblemResolutionEntityLevel, strTaskType, strTaskStatus, NOW(), intDocumentTypeID, 0, 0, 0,0,strPersonEntityRole, strISOCountry_IN, strISOCountry_NOTIN, 1, 1, intWFRuleID, intUsingPersonLevelChangeFilter, intPersonLevelChange FROM tblWFRule WHERE intAutoActivateOnPayment=1 AND strPersonLevel NOT IN ('HOBBY') and strRegistrationNature='NEW';

INSERT INTO tblWFRuleDocuments SELECT 0, R.intWFRuleID, D.intDocumentTypeID, D.intAllowApprovalEntityAdd, D.intAllowApprovalEntityVerify, D.intAllowProblemResolutionEntityAdd, D.intAllowProblemResolutionEntityVerify, NOW() FROM tblWFRuleDocuments as D INNER JOIN tblWFRule as R ON (D.intWFRuleID = intCopiedFromRuleID ) WHERE intCopiedFromRuleID >0;


