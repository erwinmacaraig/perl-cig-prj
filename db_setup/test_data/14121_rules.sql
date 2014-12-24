UPDATE tblWFRule SET strAgeLevel='ADULT' WHERE strPersonType ='REFEREE' AND strAgeLevel='';

INSERT INTO tblWFRule SELECT 0,1,0,intOriginLevel, strWFRuleFor, strEntityType, intEntityLevel, strRegistrationNature, strPersonType, strPersonLevel, strSport, 'MINOR', intApprovalEntityLevel, intProblemResolutionEntityLevel, strTaskType, strTaskStatus, NOW(), 0,'','','' FROM tblWFRule WHERE strPersonType ='REFEREE' AND strAgeLevel='ADULT';
INSERT INTO tblWFRuleDocuments SELECT 0, 1433, intDocumentTypeID, intAllowApprovalEntityAdd, intAllowApprovalEntityVerify, intAllowProblemResolutionEntityAdd, intAllowProblemResolutionEntityVerify, NOW() FROM tblWFRuleDocuments WHERE intWFRuleID=1147;
INSERT INTO tblWFRuleDocuments SELECT 0, 1434, intDocumentTypeID, intAllowApprovalEntityAdd, intAllowApprovalEntityVerify, intAllowProblemResolutionEntityAdd, intAllowProblemResolutionEntityVerify, NOW() FROM tblWFRuleDocuments WHERE intWFRuleID=1148;

UPDATE tblWFRule SET strAgeLevel='ADULT' WHERE strPersonType ='COACH' AND strAgeLevel='';
INSERT INTO tblWFRule SELECT 0,1,0,intOriginLevel, strWFRuleFor, strEntityType, intEntityLevel, strRegistrationNature, strPersonType, strPersonLevel, strSport, 'MINOR', intApprovalEntityLevel, intProblemResolutionEntityLevel, strTaskType, strTaskStatus, NOW(), 0,'','','' FROM tblWFRule WHERE strPersonType ='COACH' AND strAgeLevel='ADULT';

INSERT INTO tblWFRuleDocuments SELECT 0, 1436, intDocumentTypeID, intAllowApprovalEntityAdd, intAllowApprovalEntityVerify, intAllowProblemResolutionEntityAdd, intAllowProblemResolutionEntityVerify, NOW() FROM tblWFRuleDocuments WHERE intWFRuleID=1200;
INSERT INTO tblWFRuleDocuments SELECT 0, 1437, intDocumentTypeID, intAllowApprovalEntityAdd, intAllowApprovalEntityVerify, intAllowProblemResolutionEntityAdd, intAllowProblemResolutionEntityVerify, NOW() FROM tblWFRuleDocuments WHERE intWFRuleID=1202;
INSERT INTO tblWFRuleDocuments SELECT 0, 1438, intDocumentTypeID, intAllowApprovalEntityAdd, intAllowApprovalEntityVerify, intAllowProblemResolutionEntityAdd, intAllowProblemResolutionEntityVerify, NOW() FROM tblWFRuleDocuments WHERE intWFRuleID=1204;
INSERT INTO tblWFRuleDocuments SELECT 0, 1439, intDocumentTypeID, intAllowApprovalEntityAdd, intAllowApprovalEntityVerify, intAllowProblemResolutionEntityAdd, intAllowProblemResolutionEntityVerify, NOW() FROM tblWFRuleDocuments WHERE intWFRuleID=1206;
INSERT INTO tblWFRuleDocuments SELECT 0, 1440, intDocumentTypeID, intAllowApprovalEntityAdd, intAllowApprovalEntityVerify, intAllowProblemResolutionEntityAdd, intAllowProblemResolutionEntityVerify, NOW() FROM tblWFRuleDocuments WHERE intWFRuleID=1220;
INSERT INTO tblWFRuleDocuments SELECT 0, 1441, intDocumentTypeID, intAllowApprovalEntityAdd, intAllowApprovalEntityVerify, intAllowProblemResolutionEntityAdd, intAllowProblemResolutionEntityVerify, NOW() FROM tblWFRuleDocuments WHERE intWFRuleID=1222;
INSERT INTO tblWFRuleDocuments SELECT 0, 1442, intDocumentTypeID, intAllowApprovalEntityAdd, intAllowApprovalEntityVerify, intAllowProblemResolutionEntityAdd, intAllowProblemResolutionEntityVerify, NOW() FROM tblWFRuleDocuments WHERE intWFRuleID=1423;
INSERT INTO tblWFRuleDocuments SELECT 0, 1443, intDocumentTypeID, intAllowApprovalEntityAdd, intAllowApprovalEntityVerify, intAllowProblemResolutionEntityAdd, intAllowProblemResolutionEntityVerify, NOW() FROM tblWFRuleDocuments WHERE intWFRuleID=1424;
INSERT INTO tblWFRuleDocuments SELECT 0, 1444, intDocumentTypeID, intAllowApprovalEntityAdd, intAllowApprovalEntityVerify, intAllowProblemResolutionEntityAdd, intAllowProblemResolutionEntityVerify, NOW() FROM tblWFRuleDocuments WHERE intWFRuleID=1426;
INSERT INTO tblWFRuleDocuments SELECT 0, 1445, intDocumentTypeID, intAllowApprovalEntityAdd, intAllowApprovalEntityVerify, intAllowProblemResolutionEntityAdd, intAllowProblemResolutionEntityVerify, NOW() FROM tblWFRuleDocuments WHERE intWFRuleID=1427;
INSERT INTO tblWFRuleDocuments SELECT 0, 1446, intDocumentTypeID, intAllowApprovalEntityAdd, intAllowApprovalEntityVerify, intAllowProblemResolutionEntityAdd, intAllowProblemResolutionEntityVerify, NOW() FROM tblWFRuleDocuments WHERE intWFRuleID=1428;
INSERT INTO tblWFRuleDocuments SELECT 0, 1447, intDocumentTypeID, intAllowApprovalEntityAdd, intAllowApprovalEntityVerify, intAllowProblemResolutionEntityAdd, intAllowProblemResolutionEntityVerify, NOW() FROM tblWFRuleDocuments WHERE intWFRuleID=1429;



UPDATE tblWFRule SET strAgeLevel='ADULT' WHERE strPersonType ='CLUBOFFICIAL' AND strAgeLevel='';
INSERT INTO tblWFRule SELECT 0,1,0,intOriginLevel, strWFRuleFor, strEntityType, intEntityLevel, strRegistrationNature, strPersonType, strPersonLevel, strSport, 'MINOR', intApprovalEntityLevel, intProblemResolutionEntityLevel, strTaskType, strTaskStatus, NOW(), 0,'','','' FROM tblWFRule WHERE strPersonType ='CLUBOFFICIAL' AND strAgeLevel='ADULT';
INSERT INTO tblWFRuleDocuments SELECT 0, 1451, intDocumentTypeID, intAllowApprovalEntityAdd, intAllowApprovalEntityVerify, intAllowProblemResolutionEntityAdd, intAllowProblemResolutionEntityVerify, NOW() FROM tblWFRuleDocuments WHERE intWFRuleID=1172;
INSERT INTO tblWFRuleDocuments SELECT 0, 1452, intDocumentTypeID, intAllowApprovalEntityAdd, intAllowApprovalEntityVerify, intAllowProblemResolutionEntityAdd, intAllowProblemResolutionEntityVerify, NOW() FROM tblWFRuleDocuments WHERE intWFRuleID=1173;
INSERT INTO tblWFRuleDocuments SELECT 0, 1453, intDocumentTypeID, intAllowApprovalEntityAdd, intAllowApprovalEntityVerify, intAllowProblemResolutionEntityAdd, intAllowProblemResolutionEntityVerify, NOW() FROM tblWFRuleDocuments WHERE intWFRuleID=1174;
INSERT INTO tblWFRuleDocuments SELECT 0, 1454, intDocumentTypeID, intAllowApprovalEntityAdd, intAllowApprovalEntityVerify, intAllowProblemResolutionEntityAdd, intAllowProblemResolutionEntityVerify, NOW() FROM tblWFRuleDocuments WHERE intWFRuleID=1175;
INSERT INTO tblWFRuleDocuments SELECT 0, 1455, intDocumentTypeID, intAllowApprovalEntityAdd, intAllowApprovalEntityVerify, intAllowProblemResolutionEntityAdd, intAllowProblemResolutionEntityVerify, NOW() FROM tblWFRuleDocuments WHERE intWFRuleID=1180;
INSERT INTO tblWFRuleDocuments SELECT 0, 1456, intDocumentTypeID, intAllowApprovalEntityAdd, intAllowApprovalEntityVerify, intAllowProblemResolutionEntityAdd, intAllowProblemResolutionEntityVerify, NOW() FROM tblWFRuleDocuments WHERE intWFRuleID=1182;


UPDATE tblWFRule SET strAgeLevel='ADULT' WHERE strPersonType ='TEAMOFFICIAL' AND strAgeLevel='';
INSERT INTO tblWFRule SELECT 0,1,0,intOriginLevel, strWFRuleFor, strEntityType, intEntityLevel, strRegistrationNature, strPersonType, strPersonLevel, strSport, 'MINOR', intApprovalEntityLevel, intProblemResolutionEntityLevel, strTaskType, strTaskStatus, NOW(), 0,'','','' FROM tblWFRule WHERE strPersonType ='TEAMOFFICIAL' AND strAgeLevel='ADULT';
INSERT INTO tblWFRuleDocuments SELECT 0, 1458, intDocumentTypeID, intAllowApprovalEntityAdd, intAllowApprovalEntityVerify, intAllowProblemResolutionEntityAdd, intAllowProblemResolutionEntityVerify, NOW() FROM tblWFRuleDocuments WHERE intWFRuleID=1186;
INSERT INTO tblWFRuleDocuments SELECT 0, 1459, intDocumentTypeID, intAllowApprovalEntityAdd, intAllowApprovalEntityVerify, intAllowProblemResolutionEntityAdd, intAllowProblemResolutionEntityVerify, NOW() FROM tblWFRuleDocuments WHERE intWFRuleID=1187;
INSERT INTO tblWFRuleDocuments SELECT 0, 1460, intDocumentTypeID, intAllowApprovalEntityAdd, intAllowApprovalEntityVerify, intAllowProblemResolutionEntityAdd, intAllowProblemResolutionEntityVerify, NOW() FROM tblWFRuleDocuments WHERE intWFRuleID=1188;
INSERT INTO tblWFRuleDocuments SELECT 0, 1461, intDocumentTypeID, intAllowApprovalEntityAdd, intAllowApprovalEntityVerify, intAllowProblemResolutionEntityAdd, intAllowProblemResolutionEntityVerify, NOW() FROM tblWFRuleDocuments WHERE intWFRuleID=1189;
INSERT INTO tblWFRuleDocuments SELECT 0, 1462, intDocumentTypeID, intAllowApprovalEntityAdd, intAllowApprovalEntityVerify, intAllowProblemResolutionEntityAdd, intAllowProblemResolutionEntityVerify, NOW() FROM tblWFRuleDocuments WHERE intWFRuleID=1194;
INSERT INTO tblWFRuleDocuments SELECT 0, 1463, intDocumentTypeID, intAllowApprovalEntityAdd, intAllowApprovalEntityVerify, intAllowProblemResolutionEntityAdd, intAllowProblemResolutionEntityVerify, NOW() FROM tblWFRuleDocuments WHERE intWFRuleID=1196;

UPDATE tblWFRule SET strAgeLevel='ADULT' WHERE strPersonType ='MAOFFICIAL' AND strAgeLevel='';
INSERT INTO tblWFRule SELECT 0,1,0,intOriginLevel, strWFRuleFor, strEntityType, intEntityLevel, strRegistrationNature, strPersonType, strPersonLevel, strSport, 'MINOR', intApprovalEntityLevel, intProblemResolutionEntityLevel, strTaskType, strTaskStatus, NOW(), 0,'','','' FROM tblWFRule WHERE strPersonType ='MAOFFICIAL' AND strAgeLevel='ADULT';
INSERT INTO tblWFRuleDocuments SELECT 0, 1465, intDocumentTypeID, intAllowApprovalEntityAdd, intAllowApprovalEntityVerify, intAllowProblemResolutionEntityAdd, intAllowProblemResolutionEntityVerify, NOW() FROM tblWFRuleDocuments WHERE intWFRuleID=1149;
INSERT INTO tblWFRuleDocuments SELECT 0, 1466, intDocumentTypeID, intAllowApprovalEntityAdd, intAllowApprovalEntityVerify, intAllowProblemResolutionEntityAdd, intAllowProblemResolutionEntityVerify, NOW() FROM tblWFRuleDocuments WHERE intWFRuleID=1150;
