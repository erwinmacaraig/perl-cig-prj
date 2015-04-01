ALTER TABLE tblWFRule ADD COLUMN intLockTaskUntilGatewayResponse tinyint default 0 COMMENT 'Locks task until response from gateway' AFTER intRemoveTaskOnPayment;
