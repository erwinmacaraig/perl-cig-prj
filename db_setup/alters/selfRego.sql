


ALTER TABLE tblEntity CHANGE COLUMN strAcceptSelfRego intAcceptSelfRego INT NULL DEFAULT 1 COMMENT 'Allow an Entity to determine if they accept self registration FC-231'; ## I’ve run against CITEST
ALTER TABLE tblPayTry ADD COLUMN intSelfRego TINYINT default 0;

DELETE FROM tblSystemConfig WHERE strOption IN ('allow_SelfRego', 'selfRego_RENEW_PLAYER', 'SelfRego_PaymentOn', 'selfRego_AMATEUR_allowTransfer');

INSERT INTO tblSystemConfig VALUES (0, 1,'allow_SelfRego', 1, NOW(),1,0);
INSERT INTO tblSystemConfig VALUES (0, 1,'selfRego_RENEW_PLAYER', 1, NOW(),1,0);
INSERT INTO tblSystemConfig VALUES (0, 1,'SelfRego_PaymentOn', 1, NOW(),1,0);
#INSERT INTO tblSystemConfig VALUES (0, 1,'selfRego_allowTransfer', 1, NOW(),1,0);
INSERT INTO tblSystemConfig VALUES (0,1,'selfRego_AMATEUR_allowTransfer', 1, NOW(),1,0);

