

-- 1260 - FOOTBALL/AMATEUR/MINOR/TRANSFER -referenced to 1252
INSERT INTO tblWFRuleDocuments(intWFRuleDocumentID, intWFRuleID, intDocumentTypeID, intAllowApprovalEntityAdd, intAllowApprovalEntityVerify, intAllowProblemResolutionEntityAdd, intAllowProblemResolutionEntityVerify, tTimeStamp) SELECT 0, 1260, intDocumentTypeID, intAllowApprovalEntityAdd, intAllowApprovalEntityVerify, intAllowProblemResolutionEntityAdd, intAllowProblemResolutionEntityVerify, NOW() FROM tblWFRuleDocuments WHERE intWFRuleID = 1252;

-- 1264 - FOOTBALL/PROFESSIONAL/MINOR/TRANSFER - referenced to 1254
INSERT INTO tblWFRuleDocuments(intWFRuleDocumentID, intWFRuleID, intDocumentTypeID, intAllowApprovalEntityAdd, intAllowApprovalEntityVerify, intAllowProblemResolutionEntityAdd, intAllowProblemResolutionEntityVerify, tTimeStamp) SELECT 0, 1264, intDocumentTypeID, intAllowApprovalEntityAdd, intAllowApprovalEntityVerify, intAllowProblemResolutionEntityAdd, intAllowProblemResolutionEntityVerify, NOW() FROM tblWFRuleDocuments WHERE intWFRuleID = 1254;

-- 1262 - FOOTBALL/AMATEUR_U_C/MINOR/TRANSFER - referenced to 1256
INSERT INTO tblWFRuleDocuments(intWFRuleDocumentID, intWFRuleID, intDocumentTypeID, intAllowApprovalEntityAdd, intAllowApprovalEntityVerify, intAllowProblemResolutionEntityAdd, intAllowProblemResolutionEntityVerify, tTimeStamp) SELECT 0, 1262, intDocumentTypeID, intAllowApprovalEntityAdd, intAllowApprovalEntityVerify, intAllowProblemResolutionEntityAdd, intAllowProblemResolutionEntityVerify, NOW() FROM tblWFRuleDocuments WHERE intWFRuleID = 1256;


-- 1386 - FOOTBALL/AMATEUR/ADULT/TRANSFER - referenced to 1378
INSERT INTO tblWFRuleDocuments(intWFRuleDocumentID, intWFRuleID, intDocumentTypeID, intAllowApprovalEntityAdd, intAllowApprovalEntityVerify, intAllowProblemResolutionEntityAdd, intAllowProblemResolutionEntityVerify, tTimeStamp) SELECT 0, 1386, intDocumentTypeID, intAllowApprovalEntityAdd, intAllowApprovalEntityVerify, intAllowProblemResolutionEntityAdd, intAllowProblemResolutionEntityVerify, NOW() FROM tblWFRuleDocuments WHERE intWFRuleID = 1378;

-- 1390 - FOOTBALL/PROFESSIONAL/ADULT/TRANSFER - referenced to 1380
INSERT INTO tblWFRuleDocuments(intWFRuleDocumentID, intWFRuleID, intDocumentTypeID, intAllowApprovalEntityAdd, intAllowApprovalEntityVerify, intAllowProblemResolutionEntityAdd, intAllowProblemResolutionEntityVerify, tTimeStamp) SELECT 0, 1390, intDocumentTypeID, intAllowApprovalEntityAdd, intAllowApprovalEntityVerify, intAllowProblemResolutionEntityAdd, intAllowProblemResolutionEntityVerify, NOW() FROM tblWFRuleDocuments WHERE intWFRuleID = 1380;

-- 1388 - FOOTBALL/AMATEUR_U_C/ADULT/TRANSFER - referenced to 1382
INSERT INTO tblWFRuleDocuments(intWFRuleDocumentID, intWFRuleID, intDocumentTypeID, intAllowApprovalEntityAdd, intAllowApprovalEntityVerify, intAllowProblemResolutionEntityAdd, intAllowProblemResolutionEntityVerify, tTimeStamp) SELECT 0, 1388, intDocumentTypeID, intAllowApprovalEntityAdd, intAllowApprovalEntityVerify, intAllowProblemResolutionEntityAdd, intAllowProblemResolutionEntityVerify, NOW() FROM tblWFRuleDocuments WHERE intWFRuleID = 1382;



