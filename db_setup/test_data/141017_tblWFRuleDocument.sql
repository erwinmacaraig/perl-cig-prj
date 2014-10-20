
-- intWFRuleID = 1140; MA can view, verify and add document 5, CLUB can view and add document 5
INSERT INTO tblWFRuleDocuments(intWFRuleID, intDocumentTypeID, intAllowApprovalEntityAdd, intAllowApprovalEntityVerify, intAllowProblemResolutionEntityAdd, intAllowProblemResolutionEntityVerify, tTimeStamp) VALUES(1140, 5, 0, 1, 1, 0, NOW());
