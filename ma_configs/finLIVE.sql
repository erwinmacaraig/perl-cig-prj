## FOR LIVE
UPDATE tblPaymentConfig SET strGatewayUsername="545178", strGatewayPassword="QbvzGnDAD2qFyywo3SSlEp9D8OiXNsEZK5Mb8EqGCJRi9KMZvZNXbaZPlUjSG2S9rnOcRaY16QtoSdQh" WHERE intPaymentConfigID=3;
UPDATE tblSystemConfig SET strValue=1 WHERE intSystemConfigID=3955;
UPDATE tblProducts SET curDefaultAmount=3 WHERE intProductID=59;
UPDATE tblEntity SET strImportEntityCode='1248' WHERE intEntityLevel=100;

UPDATE tblPayTry SET dtTry='2015-05-25 05:30:41' WHERE intTransLogID = XX LIMIT 1;

## FOR TESTING
UPDATE tblPaymentConfig SET strGatewayUsername="375917", strGatewayPassword="SAIPPUAKAUPPIAS" WHERE intPaymentConfigID=3;
UPDATE tblSystemConfig SET strValue=0 WHERE intSystemConfigID=3955;
UPDATE tblProducts SET curDefaultAmount=45 WHERE intProductID=59;

