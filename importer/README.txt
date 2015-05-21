mysql -u root XXX -p < ma_config/cleanDB.sql

#depends on the current MA and tblEntity.intEntityID; needed for linking Venue to MA if not in Club
UPDATE tblEntity SET strImportEntityCode = 'FAS' WHERE intEntityID = 1 LIMIT 1;

perl CSVReader.pl -directory=csv/singapore -format=csv -realmid=1 -notes=import test -national=0

UPDATE tblPersonRegistration_1 SET strSport='FOOTBALL' WHERE strPersonType='REFEREE';


from importer/
./FIFA_3to2_ISO.pl
./importer_FixPRs.pl ##? Still needed Jervy ??
./runAllPlayerPassport.pl
cd ../automatic -> ./tempEntityStructure.pl


#Below are locations of ISO codes that may need adjusting to 2 (in FIFA_3to2_ISO.pl)
SELECT DISTINCT strISOCountryOfBirth FROM tblPerson WHERE LENGTH(strISOCountryOfBirth) >2;
SELECT DISTINCT strISONationality FROM tblPerson WHERE LENGTH(strISONationality) >2;
SELECT DISTINCT strISOCountry FROM tblPerson WHERE LENGTH(strISOCountry) >2;


UPDATE tblPersonRegistration_1 SET strPersonLevel ="" WHERE strPersonLevel IS NULL;
UPDATE tblPerson SET intSystemStatus =1;
UPDATE tblPersonRegistration_1 SET dtApproved=dtFrom;

./importer_AuditLog.pl
./importer_assignNationalNumber.pl
./importer_SG_ActiveProducts.pl


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

