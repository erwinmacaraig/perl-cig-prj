mysql -u root XXX -p < ma_config/cleanDB.sql


### JERVY UPDATE BELOW
# NOTES before running CSVReader.pl
# - clean Organisations.csv and People.csv
# - convert url-encoded string for Latin characters;
# - double-up double quotes in csv file for allow_loose_quotes option to work;
# - when splitting data using excel, use Text as conversion for postal code or any fields with leading zeros
# - convert Gender, LocalLanguage etc depending on the system's value e.g. MALE - 1, FEMALE - 2
# - make sure csv/finland/tblEntity.organisation.csv and csv/finland/tblPerson.csv files exist
# - let me know if you need copies of the csv files as we cannot upload to Google Drive for confidentiality reasons - JE

perl CSVReader.pl -directory=csv/finland -format=csv -realmid=1 -notes=import test -national=0

UPDATE tblEntity SET strImportEntityCode='1248' WHERE intEntityLevel=100;

###### TEMP TABLE IMPORT SCRIPTS
./import_PersonRego.pl
./import_PersonRegoCoaches.pl
./import_LoansTransfers.pl
./import_ExtraPayments.pl

#CLEAN
./import_cleanPersonRego.pl
./import_cleanLoansTransfers.pl
./import_cleanExtraPayments.pl

#INSERT INTO MAIN TABLES
./import_insertPR.pl
./import_insertLoansTransfers.pl
cd ../automatic -> ./activatePlayerLoan.pl
cd ../automatic -> ./deactivatePlayerLoan.pl
./import_insertEP.pl

./import_PRTXNs.pl


from importer/
./FIFA_3to2_ISO.pl
./importer_FixPRs.pl ##? Still needed Jervy ??
./runAllPlayerPassport.pl
cd ../automatic -> ./tempEntityStructure.pl ###  we need to run this for the search module to work


#Below are locations of ISO codes that may need adjusting to 2 (in FIFA_3to2_ISO.pl)
SELECT DISTINCT strISOCountryOfBirth FROM tblPerson WHERE LENGTH(strISOCountryOfBirth) >2;
SELECT DISTINCT strISONationality FROM tblPerson WHERE LENGTH(strISONationality) >2;
SELECT DISTINCT strISOCountry FROM tblPerson WHERE LENGTH(strISOCountry) >2;

### EXTRA SQL
insert into tblOldSystemAccounts (intPersonID, strUsername, strPassword) select intPersonID, strNationalNum, DATE_FORMAT(dtDOB,"%y%m%d") from tblPerson where strNationalNum <> '';

UPDATE tblSystemConfig SET strValue=0 WHERE strOption  LIKE '%Venue%';
UPDATE tblPersonRegistration_1 SET strPersonLevel ="" WHERE strPersonLevel IS NULL;
UPDATE tblPerson SET intSystemStatus =1;
UPDATE tblPersonRegistration_1 SET dtApproved=dtFrom;
UPDATE tblPersonRegistration_1 SET strShortNotes=CONCAT(IF(tmpPaymentRef, CONCAT(tmpPaymentRef, " "), ""), IF(tmpdtPaid, CONCAT(tmpdtPaid, " "), ""), tmpProductCode, " ",  tmpAmount, " ", tmpisPaid);

SELECT DISTINCT strPersonLevel FROM tblPersonRegistration_1 WHERE strPersonType='PLAYER'; -- update to AMATEUR if there's empty string
UPDATE tblPersonRegistration_1 SET strPersonLevel='' WHERE strPersonType ='REFEREE'; ## They have AMATEUR but we need it blank
UPDATE tblPersonRegistration_1 SET strPersonEntityRole='' WHERE strPersonType ='REFEREE'; ## They have Some but we need it blank

UPDATE tblPersonRegistration_1 SET intCurrent=1 WHERE strStatus IN ('ACTIVE', 'PASSIVE');
#The above one I have changed so its not as important, but that could isn't live.  So best to run this for now.

UPDATE tblPersonRegistration_1 SET strPersonLevel='' WHERE strPersonType='MAOFFICIAL';

UPDATE tblPersonRegistration_1 SET strSport='FOOTBALL' WHERE strSport ='NULL'; # Bruce, do we need this?



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

