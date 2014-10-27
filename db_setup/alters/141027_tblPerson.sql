ALTER TABLE tblPerson ADD COLUMN (
strBirthCert varchar(20), 
strBirthCertCountry varchar(6),
dtBirthCertValidityDateFrom date,
dtBirthCertValidityDateTo date,
strBirthCertDesc varchar(250));