ALTER TABLE tblUploadedFiles
    ADD COLUMN intOrigPersonRegoID INT default 0,
    ADD COLUMN intOrigDocumentTypeID INT default 0;

UPDATE tblUploadedFiles as UF INNER JOIN tblDocuments as D ON (D.intUploadFileID = UF.intFileID) SET intOrigPersonRegoID=intPersonRegistrationID, intOrigDocumentTypeID=intDocumentTypeID;


