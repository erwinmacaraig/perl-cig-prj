IMPORTANT STEP BEFORE LOADING DB:
##check latin1 & MyISAM

mysql -u root XXX -p < ma_config/cleanDB.sql


### JERVY UPDATE BELOW
perl CSVReader.pl -directory=csv/hongkong -format=csv -realmid=1 -notes=import test -national=0

###### TEMP TABLE IMPORT SCRIPTS
./import_Person.pl

###### check for empty dtFrom, dtTo, National Season for ACTIVE records
###### delete rows for name in registration csv files (not needed for importing rego records and somehow affects delimited values)
./import_PersonRego.pl

-- run after import_PersonRego.pl
UPDATE tmpPersonRego set strAgeLevel = '' where strAgeLevel not in ('ADULT','MINOR');
UPDATE tmpPersonRego set strAgeLevel = '' where strAgeLevel is null;

./import_PersonRegoCoaches.pl

#CLEAN
./import_cleanPersonRego.pl

# run if there's no existing dummy national period for PASSIVE record
INSERT INTO `tblNationalPeriod` (`intNationalPeriodID`, `strNationalPeriodName`, `strSport`, `intRealmID`, `intSubRealmID`, `dtFrom`, `dtTo`, `intCurrentNew`, `intCurrentRenewal`, `strPersonType`, `intCurrentTransfer`, `strImportPeriodCode`, `intDontUseForLoans`) VALUES (0,'Previous Coach Registrations','',1,0,'','',0,0,'',0,'',0);

# 37 must be the value of the inserted record above
UPDATE tmpPersonRego SET intNationalPeriodID = 37 WHERE intNationalPeriodID = 0 AND strStatus = 'PASSIVE' and strPersonType = 'COACH';

#INSERT INTO MAIN TABLES
./import_insertPerson.pl
./import_insertPR.pl


from importer/
./FIFA_3to2_ISO.pl
./importer_FixPRs.pl ##? Still needed Jervy ??
./runAllPlayerPassport.pl
cd ../automatic -> ./tempEntityStructure.pl ### Do we need this ?


#Below are locations of ISO codes that may need adjusting to 2 (in FIFA_3to2_ISO.pl)
SELECT DISTINCT strISOCountryOfBirth FROM tblPerson WHERE LENGTH(strISOCountryOfBirth) >2;
SELECT DISTINCT strISONationality FROM tblPerson WHERE LENGTH(strISONationality) >2;
SELECT DISTINCT strISOCountry FROM tblPerson WHERE LENGTH(strISOCountry) >2;

### EXTRA SQL
UPDATE tblSystemConfig SET strValue=0 WHERE strOption  LIKE '%Venue%';
UPDATE tblPersonRegistration_1 SET strPersonLevel ="" WHERE strPersonLevel IS NULL;
UPDATE tblPerson SET intSystemStatus =1;
UPDATE tblPersonRegistration_1 SET dtApproved=dtFrom;
UPDATE tblPersonRegistration_1 SET strShortNotes=CONCAT(IF(tmpPaymentRef, CONCAT(tmpPaymentRef, " "), ""), IF(tmpdtPaid, CONCAT(tmpdtPaid, " "), ""), tmpProductCode, " ",  tmpAmount, " ", tmpisPaid);
insert into tblOldSystemAccounts (intPersonID, strUsername, strPassword) select DISTINCT P.intPersonID, strNationalNum, DATE_FORMAT(dtDOB,"%y%m%d") from tblPerson as  P INNER JOIN tblPersonRegistration_1 as PR ON (PR.intPersonID=P.intPersonID) where strNationalNum <> ''
Update tblPersonRegistration_1 set strSport='' where strPersonType='MAOFFICIAL';
UPDATE tblPerson SET strStatus = 'REGISTERED' where strStatus = 'ACTIVE';
UPDATE tblEntity SET intRealmApproved = 1;


./importer_AuditLog.pl
./importer_assignNationalNumber.pl  ## May not be needed






## THEN:
mysqldump ...
gzip file
sftp to demo 1 or 2
gunzip...
mysql <

### REBUILDING SPHINX
sudo service searchd stop
sudo rm -rf /var/lib/sphinx/*
sudo service searchd start
sudo indexer --all --rotate
echo 'ATTACH INDEX FIFA_Persons_r1 TO RTINDEX FIFA_Persons_RT_r1; ATTACH INDEX FIFA_Entities_r1 TO RTINDEX FIFA_Entities_RT_r1' | mysql --host=127.0.0.1 --port=9306
#####

