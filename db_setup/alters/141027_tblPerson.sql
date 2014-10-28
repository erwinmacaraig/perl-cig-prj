ALTER TABLE tblPerson ADD COLUMN (
strBirthCert varchar(20) DEFAULT '',
strBirthCertCountry varchar(6) DEFAULT '',
dtBirthCertValidityDateFrom date,
dtBirthCertValidityDateTo date,
strBirthCertDesc varchar(250) DEFAULT '',
strOtherPersonIdentifier varchar(20) DEFAULT '',
strOtherPersonIdentiferIssueCountry varchar(6) DEFAULT '',
dtOtherPersonIdentiferValidDateFrom date,
dtOtherPersonIdentiferValidDateTo date,
strOtherPersonIdentifierDesc varchar(250) DEFAULT ''
);