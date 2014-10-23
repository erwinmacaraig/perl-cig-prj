
-- intWFRuleID = 1111; MA can view and verify document 6, RA can view and add/replace document 6 
INSERT INTO tblWFRuleDocuments(intWFRuleID, intDocumentTypeID, intAllowApprovalEntityAdd, intAllowApprovalEntityVerify, intAllowProblemResolutionEntityAdd, intAllowProblemResolutionEntityVerify, tTimeStamp) VALUES(1111, 6, 0, 1, 1, 0, NOW());
