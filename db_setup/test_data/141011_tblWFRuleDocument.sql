

-- intWFRuleID = 319; RA can view, verify and add document 3, CLUB can view and add document 3
INSERT INTO tblWFRuleDocuments(intWFRuleID, intDocumentTypeID, intAllowApprovalEntityAdd, intAllowApprovalEntityVerify, intAllowProblemResolutionEntityAdd, intAllowProblemResolutionEntityVerify, tTimeStamp) VALUES(319, 3, 1, 1, 1, 0, NOW());

-- intWFRuleID = 319; RA can only view document 4, CLUB can view and add document 4 
INSERT INTO tblWFRuleDocuments(intWFRuleID, intDocumentTypeID, intAllowApprovalEntityAdd, intAllowApprovalEntityVerify, intAllowProblemResolutionEntityAdd, intAllowProblemResolutionEntityVerify, tTimeStamp) VALUES(319, 4, 0, 0, 1, 0, NOW());

-- intWFRuleID = 1140; MA can view, verify and add document 4, CLUB can view and add document 4
INSERT INTO tblWFRuleDocuments(intWFRuleID, intDocumentTypeID, intAllowApprovalEntityAdd, intAllowApprovalEntityVerify, intAllowProblemResolutionEntityAdd, intAllowProblemResolutionEntityVerify, tTimeStamp) VALUES(1140, 4, 1, 1, 1, 0, NOW());

-- intWFRuleID = 1140; MA can view, verify and add document 3, CLUB can view and add document 3
INSERT INTO tblWFRuleDocuments(intWFRuleID, intDocumentTypeID, intAllowApprovalEntityAdd, intAllowApprovalEntityVerify, intAllowProblemResolutionEntityAdd, intAllowProblemResolutionEntityVerify, tTimeStamp) VALUES(1140, 3, 0, 0, 1, 0, NOW());
