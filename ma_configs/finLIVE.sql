##### FOR LIVE
UPDATE tblPaymentConfig SET strGatewayUsername="545178", strGatewayPassword="QbvzGnDAD2qFyywo3SSlEp9D8OiXNsEZK5Mb8EqGCJRi9KMZvZNXbaZPlUjSG2S9rnOcRaY16QtoSdQh" WHERE intPaymentConfigID=3;
UPDATE tblSystemConfig SET strValue=1 WHERE intSystemConfigID=3955;
SELECT * FROM tblSystemConfig WHERE strOption  LIKE 'lockAp%'; ##


##### FOR TESTING
UPDATE tblPaymentConfig SET strGatewayUsername="375917", strGatewayPassword="SAIPPUAKAUPPIAS" WHERE intPaymentConfigID=3;
UPDATE tblSystemConfig SET strValue=0 WHERE intSystemConfigID=3955;

##### Update below per import run
DELETE FROM tblSystemConfig WHERE strOption = 'paymentPrefix';
INSERT INTO tblSystemConfig VALUES (0,1,'paymentPrefix', 'FAF2UAT', NOW(),1,0);
INSERT INTO tblSystemConfig VALUES (0,1,'paymentPrefix', 'FAF2TRN', NOW(),1,0);








##### CHECK THIS
INSERT INTO tblSystemConfig VALUES (0, 1, 'selfRego_RENEW_PLAYER', 1, NOW(),1,0);
INSERT INTO tblSystemConfig VALUES (0,1, 'allowFindPaymentMinLevel', 100, NOW(),1,0);

SELECT * FROM tblSystemConfig WHERE strOption = 'paymentPrefix';
INSERT INTO tblSystemConfig VALUES (0,1, 'paymentPrefix', 'FAF', NOW(),1,0); ###TEST

UPDATE tblGenerate SET intCurrentNum = (SELECT MAX(strNationalNum) + 1 FROM tblPerson) WHERE strGenType='PERSON';

SELECT DISTINCT strPersonType, strPersonEntityRole FROM tblPersonRegistration_1;

UPDATE tblPersonRegistration_1 SET strPersonLevel='' WHERE strPersonType ='REFEREE';
UPDATE tblPersonRegistration_1 SET strPersonLevel, '', strPersonEntityRole='' WHERE strPersonType ='REFEREE';
UPDATE tblPersonRegistration_1 SET strPersonLevel='' WHERE strPersonType='MAOFFICIAL';
UPDATE tblPersonRegistration_1 SET strSport='FOOTBALL' WHERE strSport ='NULL';


 UPDATE tblPersonRegistration_1 SET strPersonLevel='' WHERE strPersonType IN ('RAOFFICIAL', 'MAOFFICIAL');


### FIN UAT TO RUN:


INSERT INTO tblSystemConfig VALUES (0,1,'paymentPrefix', 'FAF', NOW(),1,0);
UPDATE  tblPersonRegistration_1 SET strPersonEntityRole='RAREFOBDIST' WHERE strPersonEntityRole='REFEREE OBSERVER' and strPersonType='RAOFFICIAL';
UPDATE  tblPersonRegistration_1 SET strPersonEntityRole='MAREFOBFAF' WHERE strPersonEntityRole='REFEREE OBSERVER' and strPersonType='MAOFFICIAL';
UPDATE tblPersonRegistration_1 SET strPersonLevel='' WHERE strPersonType IN ('RAOFFICIAL', 'MAOFFICIAL');


UPDATE tblProducts SET intRealmID=-99 WHERE strProductType ='insurance' and intRealmID=1;
UPDATE tblRegistrationItem SET intRealmID=-99 WHERE strItemType ='PRODUCT' AND intID IN (100,99,98,97,96,95,94, 93,92,91,90,89,88,87,86,84);


UPDATE tblProducts SET intRealmID=1 WHERE strProductType ='insurance' and intRealmID=-99;
UPDATE tblRegistrationItem SET intRealmID=1 WHERE strItemType ='PRODUCT' AND intID IN (100,99,98,97,96,95,94, 93,92,91,90,89,88,87,86,84) and intRealmID=-99;
