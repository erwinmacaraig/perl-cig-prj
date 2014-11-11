
-- intWFRuleID = 1132; MA can view and verify documents 17; CLUB can view and add/replace document 17
INSERT INTO tblWFRuleDocuments(intWFRuleID, intDocumentTypeID, intAllowApprovalEntityAdd, intAllowApprovalEntityVerify, intAllowProblemResolutionEntityAdd, intAllowProblemResolutionEntityVerify, tTimeStamp) VALUES(1132, 17, 0, 1, 1, 0, NOW());
