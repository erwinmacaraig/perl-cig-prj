ALTER TABLE tblWFRule 
    ADD COLUMN intAutoActivateOnPayment tinyint default 0 COMMENT 'Auto Activate Person/Rego on Payment' AFTER intDocumentTypeID,
    ADD COLUMN intLockTaskUntilPaid tinyint default 0 COMMENT 'Locks task until paid' AFTER intDocumentTypeID,
    ADD COLUMN intRemoveTaskOnPayment tinyint default 0 COMMENT 'On Payment, remove task and either go to next one or approve person/Rego/Entity' AFTER intDocumentTypeID;
