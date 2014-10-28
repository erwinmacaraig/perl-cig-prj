ALTER TABLE tblPerson ADD COLUMN (
strBirthCert varchar(20) DEFAULT '',
strBirthCertCountry varchar(6) DEFAULT '',
dtBirthCertValidityDateFrom date,
dtBirthCertValidityDateTo date,
strBirthCertDesc varchar(250) DEFAULT '',
strOtherPersonIdentifier varchar(20) DEFAULT '',
strOtherPersonIdentifierIssueCountry varchar(6) DEFAULT '',
dtOtherPersonIdentifierValidDateFrom date,
dtOtherPersonIdentifierValidDateTo date,
strOtherPersonIdentifierDesc varchar(250) DEFAULT ''
);
