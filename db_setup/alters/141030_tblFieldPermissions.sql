ALTER TABLE tblFieldPermissions CHANGE COLUMN strFieldName strFieldName VARCHAR(50) NOT NULL;
UPDATE tblFieldPermissions SET strFieldType= 'PersonChild' where strFieldType='MemberChild';
UPDATE tblFieldPermissions SET strFieldType= 'Person' where strFieldType='Member';
UPDATE tblFieldPermissions SET strFieldType= 'PersonRegoForm' where strFieldType='MemberRegoForm';
