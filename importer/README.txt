mysql -u root XXX -p < ma_config/cleanDB.sql
perl CSVReader.pl -directory=csv/singapore -format=csv -realmid=1 -notes=import test -national=0

from importer/
./FIFA_3to2_ISO.pl
./importer_FixPRs.pl
./runAllPlayerPassport.pl

UPDATE tblPerson SET strOtherPersonIdentifier=strPassportNo, intOtherPersonIdentifierTypeID=558019 WHERE (strOtherPersonIdentifier IS NULL or strOtherPersonIdentifier="") and (strPassportNo <> "" and strPassportNo IS NOT NULL) AND intRealmID=1;
UPDATE tblPersonRegistration_1 SET strPersonLevel ="" WHERE strPersonLevel IS NULL;

- ./importer_assignNationalNumber.pl





