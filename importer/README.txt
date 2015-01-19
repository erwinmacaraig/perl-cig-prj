mysql -u root XXX -p < ma_config/cleanDB.sql

#depends on the current MA and tblEntity.intEntityID; needed for linking Venue to MA if not in Club
UPDATE tblEntity SET strImportEntityCode = 'FAS' WHERE intEntityID = 1 LIMIT 1;

perl CSVReader.pl -directory=csv/singapore -format=csv -realmid=1 -notes=import test -national=0

UPDATE tblPersonRegistration_1 SET strSport='FOOTBALL' WHERE strPersonType='REFEREE';
UPDATE tblSystemConfig SET strValue ='myfashelpdesk@fas.org.sg' WHERE strOption ='ma_email';
INSERT INTO tblReports VALUES (0, 'Club Teamsheet', 'Check teamsheet', 1, 'SG_teamsheet.rpt', '', 'People', 0,0,'');
INSERT INTO tblReportEntity VALUES (100,1,0,0,0,3,3);

from importer/
./FIFA_3to2_ISO.pl
./importer_FixPRs.pl
./runAllPlayerPassport.pl
cd ../automatic -> ./tempEntityStructure.pl

UPDATE tblPerson SET strOtherPersonIdentifier=strPassportNo, intOtherPersonIdentifierTypeID=558019 WHERE (strOtherPersonIdentifier IS NULL or strOtherPersonIdentifier="") and (strPassportNo <> "" and strPassportNo IS NOT NULL) AND intRealmID=1;
UPDATE tblPersonRegistration_1 SET strPersonLevel ="" WHERE strPersonLevel IS NULL;
UPDATE tblPerson SET intSystemStatus =1;
UPDATE tblGenerate SET intCurrentNum=0 WHERE intGenerateID=2;
UPDATE tblProducts SET intProductNationalPeriodID=8;

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

