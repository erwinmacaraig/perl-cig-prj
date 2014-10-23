
-- intWFRuleID = 1115; MA can view and verify document 7, CLUB can view and add document 7 
INSERT INTO tblWFRuleDocuments(intWFRuleID, intDocumentTypeID, intAllowApprovalEntityAdd, intAllowApprovalEntityVerify, intAllowProblemResolutionEntityAdd, intAllowProblemResolutionEntityVerify, tTimeStamp) VALUES(1115, 7, 0, 1, 1, 0, NOW());

-- intWFRuleID = 1114; RA can view and verify document 7, CLUB can view and add document 7 
INSERT INTO tblWFRuleDocuments(intWFRuleID, intDocumentTypeID, intAllowApprovalEntityAdd, intAllowApprovalEntityVerify, intAllowProblemResolutionEntityAdd, intAllowProblemResolutionEntityVerify, tTimeStamp) VALUES(1114, 7, 0, 1, 1, 0, NOW());
