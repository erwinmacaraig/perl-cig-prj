## FOR LIVE
UPDATE tblPaymentConfig SET strGatewayUsername="545178", strGatewayPassword="QbvzGnDAD2qFyywo3SSlEp9D8OiXNsEZK5Mb8EqGCJRi9KMZvZNXbaZPlUjSG2S9rnOcRaY16QtoSdQh" WHERE intPaymentConfigID=3;
UPDATE tblSystemConfig SET strValue=1 WHERE intSystemConfigID=3955;
SELECT * FROM tblSystemConfig WHERE strOption  LIKE 'lockAp%'; ##
UPDATE tblEntity SET strImportEntityCode='1248' WHERE intEntityLevel=100; 
UPDATE tblSystemConfig SET strValue=0 WHERE strOption  LIKE '%Venue%';

## CHECK THIS
INSERT INTO tblSystemConfig VALUES (0, 1, 'selfRego_RENEW_PLAYER', 1, NOW(),1,0);
INSERT INTO tblSystemConfig VALUES (0,1, 'allowFindPaymentMinLevel', 100, NOW(),1,0);
INSERT INTO tblSystemConfig VALUES (0,1, 'paymentPrefix', 'FAF15-', NOW(),1,0); ###TEST
UPDATE tblGenerate SET intCurrentNum = (SELECT MAX(strNationalNum) + 1 FROM tblPerson) WHERE strGenType='PERSON';





## FOR TESTING
UPDATE tblPaymentConfig SET strGatewayUsername="375917", strGatewayPassword="SAIPPUAKAUPPIAS" WHERE intPaymentConfigID=3;
UPDATE tblSystemConfig SET strValue=0 WHERE intSystemConfigID=3955;
UPDATE tblSystemConfig SET strValue=0 WHERE strOption  LIKE '%Venue%';


INSERT INTO tblSystemConfig VALUES (0,1,'paymentPrefix', 'FAFUAT-', NOW(),1,0);
INSERT INTO tblSystemConfig VALUES (0,1,'paymentPrefix', 'FAFTRN-', NOW(),1,0);
