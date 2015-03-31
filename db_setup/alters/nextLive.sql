# 150219_tblPerson.sql
ALTER TABLE tblPerson ADD COLUMN strGuardianRelationship VARCHAR(50);

ALTER TABLE tblPayTry ADD COLUMN strContinueAction varchar(50) default '';
ALTER TABLE tblTransLog ADD COLUMN strGatewayResponseCode varchar(10) default '';

# 150308_tblWFRule.sql
ALTER TABLE tblWFRule
    ADD COLUMN intAutoActivateOnPayment tinyint default 0 COMMENT 'Auto Activate Person/Rego on Payment' AFTER intDocumentTypeID,
    ADD COLUMN intLockTaskUntilPaid tinyint default 0 COMMENT 'Locks task until paid' AFTER intDocumentTypeID,
    ADD COLUMN intRemoveTaskOnPayment tinyint default 0 COMMENT 'On Payment, remove task and either go to next one or approve person/Rego/Entity' AFTER intDocumentTypeID;

# 150308_tblPersonRego.sql
ALTER TABLE tblPersonRegistration_1 ADD COLUMN intWasActivatedByPayment tinyint default 0 COMMENT 'Debug flag for if record was auto activated by Payment';

# 150308_tblEntity.sql
ALTER TABLE tblEntity ADD COLUMN intWasActivatedByPayment tinyint default 0 COMMENT 'Debug flag for if record was auto activated by Payment';

# 150311_tblTransactions.sql
ALTER TABLE tblTransactions ADD COLUMN intSentToGateway TINYINT default 0;

# 150311_tblTransLog.sql
ALTER TABLE tblTransLog ADD COLUMN intSentToGateway TINYINT default 0;

# 150311_tblPaymentConfig.sql
ALTER TABLE tblPaymentConfig ADD COLUMN intProcessPreGateway TINYINT DEFAULT 0;

# 150317_tblWFTask.sql
ALTER TABLE tblWFTask ADD COLUMN intPaymentGatewayResponded tinyint default 0 COMMENT 'Has payment gateway responded';

# 150317_tblWFRule.sql
ALTER TABLE tblWFRule ADD COLUMN intLockTaskUntilGatewayResponse tinyint default 0 COMMENT 'Locks task until response from gateway' AFTER intRemoveTaskOnPayment;

# 150318_tblTransLog.sql
ALTER TABLE tblTransLog ADD COLUMN intPaymentGatewayResponded TINYINT default 0;

# 150318_tblTransactions.sql
ALTER TABLE tblTransactions ADD COLUMN intPaymentGatewayResponded TINYINT default 0;

ALTER TABLE tblProducts ADD COLUMN strDisplayName VARCHAR(100) NULL AFTER strName;

# 150320_tblTransLog
ALTER TABLE tblTransLog ADD COLUMN strOnlinePayReference varchar(100) default '' AFTER strTXN;

# 150323_tblWFRule
ALTER TABLE tblWFRule ADD COLUMN intNeededITC tinyint default 0 COMMENT 'Was an ITC needed';
ALTER TABLE tblWFRule ADD COLUMN intUsingITCFilter tinyint default 0 COMMENT 'Using ITC filter';

# 150325_tblWFRule
ALTER TABLE tblWFRule ADD COLUMN intCopiedFromRuleID INT DEFAULT 0 COMMENT 'The ID of the rule this record was copied from - used for tblWFRuleDocument setup';

#  150328_tblRegistrationItem
ALTER TABLE tblRegistrationItem ADD COLUMN intItemNeededITC tinyint default 0 COMMENT 'Was an ITC needed';
ALTER TABLE tblRegistrationItem ADD COLUMN intItemUsingITCFilter tinyint default 0 COMMENT 'Using ITC filter';


# 150401_tblRegoTypeLimits
ALTER TABLE tblRegoTypeLimits ADD COLUMN strEntityType varchar(30) default '' AFTER intSubRealmID;
