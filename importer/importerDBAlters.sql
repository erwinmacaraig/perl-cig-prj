
ALTER TABLE tblEntity ADD KEY index_strImportEntityCode (strImportEntityCode);
ALTER TABLE tblPerson ADD KEY index_strImportPersonCode (strImportPersonCode);

ALTER TABLE tblPersonRegistration_1 ADD COLUMN tmpProductCode VARCHAR(30) DEFAULT '';
ALTER TABLE tblPersonRegistration_1 ADD COLUMN tmpProductID int default 0;
ALTER TABLE tblPersonRegistration_1 ADD COLUMN tmpAmount decimal(12,2) default 0.00;
ALTER TABLE tblPersonRegistration_1 ADD COLUMN tmpisPaid varchar(10) default '';
ALTER TABLE tblPersonRegistration_1 ADD COLUMN tmpPaymentRef varchar(30) default '';
ALTER TABLE tblPersonRegistration_1 ADD COLUMN tmpdtPaid date;

