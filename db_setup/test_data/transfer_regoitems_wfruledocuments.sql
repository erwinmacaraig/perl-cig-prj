-- 1242 - FOOTBALL/AMATEUR/MINOR/TRANSFER -referenced to 1234
INSERT INTO tblWFRuleDocuments(intWFRuleDocumentID, intWFRuleID, intDocumentTypeID, intAllowApprovalEntityAdd, intAllowApprovalEntityVerify, intAllowProblemResolutionEntityAdd, intAllowProblemResolutionEntityVerify, tTimeStamp) SELECT 0, 1242, intDocumentTypeID, intAllowApprovalEntityAdd, intAllowApprovalEntityVerify, intAllowProblemResolutionEntityAdd, intAllowProblemResolutionEntityVerify, NOW() FROM tblWFRuleDocuments WHERE intWFRuleID = 1234;

-- 1246 - FOOTBALL/PROFESSIONAL/MINOR/TRANSFER - referenced to 1236
INSERT INTO tblWFRuleDocuments(intWFRuleDocumentID, intWFRuleID, intDocumentTypeID, intAllowApprovalEntityAdd, intAllowApprovalEntityVerify, intAllowProblemResolutionEntityAdd, intAllowProblemResolutionEntityVerify, tTimeStamp) SELECT 0, 1246, intDocumentTypeID, intAllowApprovalEntityAdd, intAllowApprovalEntityVerify, intAllowProblemResolutionEntityAdd, intAllowProblemResolutionEntityVerify, NOW() FROM tblWFRuleDocuments WHERE intWFRuleID = 1236;

-- 1244 - FOOTBALL/AMATEUR_U_C/MINOR/TRANSFER - referenced to 1238
INSERT INTO tblWFRuleDocuments(intWFRuleDocumentID, intWFRuleID, intDocumentTypeID, intAllowApprovalEntityAdd, intAllowApprovalEntityVerify, intAllowProblemResolutionEntityAdd, intAllowProblemResolutionEntityVerify, tTimeStamp) SELECT 0, 1244, intDocumentTypeID, intAllowApprovalEntityAdd, intAllowApprovalEntityVerify, intAllowProblemResolutionEntityAdd, intAllowProblemResolutionEntityVerify, NOW() FROM tblWFRuleDocuments WHERE intWFRuleID = 1238;


-- 1368 - FOOTBALL/AMATEUR/ADULT/TRANSFER - referenced to 1360
INSERT INTO tblWFRuleDocuments(intWFRuleDocumentID, intWFRuleID, intDocumentTypeID, intAllowApprovalEntityAdd, intAllowApprovalEntityVerify, intAllowProblemResolutionEntityAdd, intAllowProblemResolutionEntityVerify, tTimeStamp) SELECT 0, 1368, intDocumentTypeID, intAllowApprovalEntityAdd, intAllowApprovalEntityVerify, intAllowProblemResolutionEntityAdd, intAllowProblemResolutionEntityVerify, NOW() FROM tblWFRuleDocuments WHERE intWFRuleID = 1360;

-- 1372 - FOOTBALL/PROFESSIONAL/ADULT/TRANSFER - referenced to 1362
INSERT INTO tblWFRuleDocuments(intWFRuleDocumentID, intWFRuleID, intDocumentTypeID, intAllowApprovalEntityAdd, intAllowApprovalEntityVerify, intAllowProblemResolutionEntityAdd, intAllowProblemResolutionEntityVerify, tTimeStamp) SELECT 0, 1372, intDocumentTypeID, intAllowApprovalEntityAdd, intAllowApprovalEntityVerify, intAllowProblemResolutionEntityAdd, intAllowProblemResolutionEntityVerify, NOW() FROM tblWFRuleDocuments WHERE intWFRuleID = 1362;

-- 1370 - FOOTBALL/AMATEUR_U_C/ADULT/TRANSFER - referenced to 1364
INSERT INTO tblWFRuleDocuments(intWFRuleDocumentID, intWFRuleID, intDocumentTypeID, intAllowApprovalEntityAdd, intAllowApprovalEntityVerify, intAllowProblemResolutionEntityAdd, intAllowProblemResolutionEntityVerify, tTimeStamp) SELECT 0, 1370, intDocumentTypeID, intAllowApprovalEntityAdd, intAllowApprovalEntityVerify, intAllowProblemResolutionEntityAdd, intAllowProblemResolutionEntityVerify, NOW() FROM tblWFRuleDocuments WHERE intWFRuleID = 1364;



-- make all transfer documents in tblRegistrationItem to use existing
UPDATE tblRegistrationItem SET intUseExistingThisEntity = 1, intUseExistingAnyEntity = 1 where strRegistrationNature = 'TRANSFER' AND strItemType = 'DOCUMENT';

