DELETE FROM tblEntity WHERE intEntityID<>1;
DELETE FROM tblUserAuth WHERE entityId>1;
DELETE FROM tblPerson;
DELETE FROM tblPersonRegistration_1;
DELETE FROM tblPersonRequest;
DELETE FROM tblDocuments;
DELETE FROM tblTransactions;
DELETE FROM tblTXNLogs;
DELETE FROM tblTransLog;
DELETE FROM tblPersonCertifications;
DELETE FROM tblEntityFields;
DELETE FROM tblPersonNotes;
DELETE FROM tblPlayerPassport;
DELETE FROM tblTransLog_Retry;
DELETE FROM tblTransLog_Counts;

DELETE FROM tblWFTask;
DELETE FROM tblAuditLog;

DELETE FROM tblUploadedFiles;
DELETE FROM tblDocuments;

DELETE FROM tblImportTrack;

DELETE FROM tblEntityLinks;

DELETE FROM tblTempEntityStructure;
