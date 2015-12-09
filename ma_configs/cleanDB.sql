#DELETE FROM tblEntity WHERE intEntityLevel<>100;
#DELETE FROM tblEntityLinks;
#DELETE FROM tblTempEntityStructure;
#DELETE FROM tblTempTreeStructure;
DELETE FROM tblEntityFields;

DELETE FROM tblUser;
DELETE FROM tblUserAuth;
DELETE FROM tblUserHash;

DELETE FROM tblPerson;
DELETE FROM tblPersonRegistration_1;
DELETE FROM tblPersonRegistrationStatusChangeLog;
DELETE FROM tblPersonEntity_1;
DELETE FROM tblPersonRequest;
DELETE FROM tblDocuments;
DELETE FROM tblTransactions;
DELETE FROM tblTXNLogs;
DELETE FROM tblTransLog;
DELETE FROM tblPersonCertifications;
DELETE FROM tblPersonNotes;
DELETE FROM tblPlayerPassport;
DELETE FROM tblTransLog_Retry;
DELETE FROM tblTransLog_Counts;
DELETE FROM tblOldSystemAccounts;

DELETE FROM tblWFTask;
DELETE FROM tblWFTaskNotes;
DELETE FROM tblWFTaskPreReq;
DELETE FROM tblAuditLog;

DELETE FROM tblUploadedFiles;
DELETE FROM tblDocuments;

DELETE FROM tblImportTrack;

DELETE FROM tblInvoice;
DELETE FROM tblWFTaskNotes;
DELETE FROM tblPayTry;
DELETE FROM tblITCMessagesLog;

DELETE FROM tblRegoState;
DELETE FROM tblSavedReports;

DELETE FROM tblSelfUser;
DELETE FROM tblSelfUserAuth;
DELETE FROM tblSelfUserHash;

DELETE FROM tblPersonDuplicates;
#DELETE FROM tblPersonCard;
#DELETE FROM tblPersonCardTypes;
DELETE FROM tblPersonCardBatch;
DELETE FROM tblPersonCardPrint;
DELETE FROM tblLogo;

