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


# 150326_tblRegoTypeLimits
ALTER TABLE tblRegoTypeLimits ADD COLUMN strEntityType varchar(30) default '' AFTER intSubRealmID;

# 150407_tblRegistrationItem
ALTER TABLE tblRegistrationItem
    ADD COLUMN intItemUsingActiveFilter tinyint default 0 COMMENT 'Using Active Periods filter',
    ADD COLUMN strItemActiveFilterPeriods varchar(10) default '' COMMENT 'Which Periods to check Active on',
    ADD COLUMN intItemActive tinyint default 0 COMMENT 'Active status if Active Periods filter on';


# 150407_tblPersonRequest
ALTER TABLE tblPersonRequest ADD COLUMN intExistingPersonRegistrationID INT DEFAULT 0 AFTER intPersonID;
ALTER TABLE tblPersonRequest ADD COLUMN strNewPersonLevel VARCHAR(30) NULL COMMENT 'PROFESSIONAL, AMATEUR, (blank)' AFTER strPersonLevel;
UPDATE tblPersonRequest SET strNewPersonLevel=strPersonLevel;

# 150408_tblWFRule, 150408_tblPersonRegistration.sql
ALTER TABLE tblPersonRegistration_1 
    ADD COLUMN intPersonLevelChanged TINYINT DEFAULT 0,
    ADD COLUMN strPreviousPersonLevel varchar(30) DEFAULT '';
ALTER TABLE tblWFRule
    ADD COLUMN intUsingPersonLevelChangeFilter tinyint default 0 COMMENT 'Using Person Level change filter',
    ADD COLUMN intPersonLevelChange tinyint default 0 COMMENT 'Was Person Level changed';


# 150421_tblPersonRegistration.sql - FC877
ALTER TABLE tblPersonRegistration_1
ADD COLUMN `intOnLoan` INT NULL DEFAULT 0 AFTER `strPreviousPersonLevel`;

# 150421_tblPersonRequest.sql - FC877
ALTER TABLE tblPersonRequest
ADD COLUMN `dtLoanFrom` DATETIME NULL AFTER `strRequestStatus`,
ADD COLUMN `dtLoanTo` DATETIME NULL AFTER `dtLoanFrom`,
ADD COLUMN `intOpenLoan` INT NULL DEFAULT 0 AFTER `dtLoanTo`,
ADD COLUMN `strTMSReference` VARCHAR(100) NULL AFTER `intOpenLoan`;

# 150421_tblPerson.sql - FC877
ALTER TABLE tblPerson
ADD COLUMN `strInternationalTransferSourceClub` VARCHAR(150) NULL DEFAULT NULL AFTER `strGuardianRelationship`,
ADD COLUMN `dtInternationalTransferDate` DATETIME NULL AFTER `strInternationalTransferSourceClub`,
ADD COLUMN `strInternationalTransferTMSRef` VARCHAR(100) NULL DEFAULT NULL AFTER `dtInternationalTransferDate`,
ADD COLUMN `strInternationalLoanSourceClub` VARCHAR(150) NULL DEFAULT NULL AFTER `strInternationalTransferTMSRef`,
ADD COLUMN `strInternationalLoanTMSRef` VARCHAR(100) NULL DEFAULT NULL AFTER `strInternationalLoanSourceClub`,
ADD COLUMN `dtInternationalLoanFromDate` DATETIME NULL AFTER `strInternationalLoanTMSRef`,
ADD COLUMN `dtInternationalLoanToDate` DATETIME NULL AFTER `dtInternationalLoanFromDate`,
ADD COLUMN `intInternationalLoan` INT NULL DEFAULT 0 AFTER `dtInternationalLoanToDate`;

# 150421_tblRegistrationItem.sql - FC965
ALTER TABLE tblRegistrationItem
    ADD COLUMN intItemUsingPaidProductFilter tinyint default 0 COMMENT 'Using Active Products filter',
    ADD COLUMN strItemActiveFilterPaidProducts varchar(100) default '' COMMENT 'Which Products to check Active on',
    ADD COLUMN intItemPaidProducts tinyint default 0 COMMENT 'Active status if Active Products filter on';

#150427_tblProducts.sql
ALTER TABLE tblProducts ADD COLUMN intMinAddSingleTXNLevel TINYINT DEFAULT 0;


ALTER TABLE tblEntity CHANGE COLUMN strAcceptSelfRego intAcceptSelfRego INT NULL DEFAULT 1 COMMENT 'Allow an Entity to determine if they accept self registration FC-231'; ## I’ve run against CITEST
# selfRego.sql
ALTER TABLE tblPayTry ADD COLUMN intSelfRego TINYINT default 0;

#150507_tblNationalPeriod.sql
ALTER TABLE tblNationalPeriod ADD COLUMN strImportPeriodCode varchar(30) default '';

# FC267
ALTER TABLE tblPersonRequest
ADD COLUMN `intSelfTriggered` TINYINT NOT NULL DEFAULT 0 COMMENT 'Flag to identify if the request has been initiated by self user' AFTER `strRequestStatus`,
ADD COLUMN `intRequestFromSelfUserID` INT NOT NULL DEFAULT 0 COMMENT 'Self User ID who initiated the request' AFTER `intSelfTriggered`;


# From PlayerLoans.sql
ALTER TABLE tblRegistrationItem
ADD COLUMN `intItemForInternationalTransfer` TINYINT NULL DEFAULT 0 AFTER `intItemPaidProducts`,
ADD COLUMN `intItemForInternationalLoan` TINYINT NULL DEFAULT 0 AFTER `intItemForInternationalTransfer`;

ALTER TABLE `tblMatrix`
ADD COLUMN `dtOpenFrom` DATE NULL DEFAULT NULL AFTER `dtTo`,
ADD COLUMN `dtOpenTo` DATE NULL DEFAULT NULL AFTER `dtOpenFrom`,
ADD COLUMN `intHonourOpenDates` TINYINT NULL DEFAULT 0 AFTER `dtOpenTo`;


ALTER TABLE tblNationalPeriod ADD COLUMN intDontUseForLoans TINYINT DEFAULT 0;

ALTER TABLE tblPersonRegistration_1 ADD COLUMN `intIsLoanedOut` TINYINT NULL DEFAULT 0 COMMENT 'Flag to identify that the person registration record is loaned out' AFTER `intOnLoan`;

ALTER TABLE tblPersonRegistration_1 ADD COLUMN `strPreLoanedStatus` VARCHAR(45) NULL DEFAULT '' COMMENT 'Used as temporary column to save status from imported data' AFTER `intIsLoanedOut`;

