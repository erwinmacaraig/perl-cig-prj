## FOR LIVE
UPDATE tblPaymentConfig SET strGatewayUsername="545178", strGatewayPassword="QbvzGnDAD2qFyywo3SSlEp9D8OiXNsEZK5Mb8EqGCJRi9KMZvZNXbaZPlUjSG2S9rnOcRaY16QtoSdQh" WHERE intPaymentConfigID=3;
UPDATE tblSystemConfig SET strValue=1 WHERE intSystemConfigID=3955;

UPDATE tblEntity SET strImportEntityCode='1248' WHERE intEntityLevel=100; 

INSERT INTO tblSystemConfig VALUES (0, 1, 'selfRego_RENEW_PLAYER', 1, NOW(),1,0);
INSERT INTO tblSystemConfig VALUES (0,1, 'allowFindPaymentMinLevel', 100, NOW(),1,0);
INSERT INTO tblSystemConfig VALUES (0,1, 'paymentPrefix', 'FAF15-', NOW(),1,0); ###TEST

## CHECK THIS
UPDATE tblGenerate SET intCurrentNum = (SELECT MAX(strNationalNum) + 1 FROM tblPerson) WHERE strGenType='PERSON';


UPDATE tblProducts SET curDefaultAmount=3 WHERE intProductID=59;
## FOR TESTING
UPDATE tblPaymentConfig SET strGatewayUsername="375917", strGatewayPassword="SAIPPUAKAUPPIAS" WHERE intPaymentConfigID=3;
UPDATE tblSystemConfig SET strValue=0 WHERE intSystemConfigID=3955;
UPDATE tblProducts SET curDefaultAmount=45 WHERE intProductID=59;

