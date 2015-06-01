ALTER TABLE tblWFRule ADD COLUMN intCopiedFromRuleID INT DEFAULT 0 COMMENT 'The ID of the rule this record was copied from - used for tblWFRuleDocument setup';
