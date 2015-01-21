TRUNCATE TABLE tblEmailTemplates;

INSERT INTO tblEmailTemplates(intEmailTemplateTypeID, strHTMLTemplatePath, strTextTemplatePath, strSubjectPrefix, intLanguageID, intActive, tTimeStamp) VALUES(1, 'notification/workflow/html/', '', 'WORK TASK ADDED: ', 1, 1, NOW());
INSERT INTO tblEmailTemplates(intEmailTemplateTypeID, strHTMLTemplatePath, strTextTemplatePath, strSubjectPrefix, intLanguageID, intActive, tTimeStamp) VALUES(2, 'notification/workflow/html/', '', 'WORK TASK APPROVED: ', 1, 1, NOW());
INSERT INTO tblEmailTemplates(intEmailTemplateTypeID, strHTMLTemplatePath, strTextTemplatePath, strSubjectPrefix, intLanguageID, intActive, tTimeStamp) VALUES(3, 'notification/workflow/html/', '', 'WORK TASK REJECTED: ', 1, 1, NOW());
INSERT INTO tblEmailTemplates(intEmailTemplateTypeID, strHTMLTemplatePath, strTextTemplatePath, strSubjectPrefix, intLanguageID, intActive, tTimeStamp) VALUES(4, 'notification/workflow/html/', '', 'WORK TASK RESOLVED: ', 1, 1, NOW());
INSERT INTO tblEmailTemplates(intEmailTemplateTypeID, strHTMLTemplatePath, strTextTemplatePath, strSubjectPrefix, intLanguageID, intActive, tTimeStamp) VALUES(5, 'notification/workflow/html/', '', 'WORK TASK HELD: ', 1, 1, NOW());
INSERT INTO tblEmailTemplates(intEmailTemplateTypeID, strHTMLTemplatePath, strTextTemplatePath, strSubjectPrefix, intLanguageID, intActive, tTimeStamp) VALUES(6, 'notification/workflow/html/', '', 'WORK TASK RESUMED: ', 1, 1, NOW());
INSERT INTO tblEmailTemplates(intEmailTemplateTypeID, strHTMLTemplatePath, strTextTemplatePath, strSubjectPrefix, intLanguageID, intActive, tTimeStamp) VALUES(7, 'notification/personrequest/html/', '', 'PERSON REQUEST ACCESS ACCEPTED: ', 1, 1, NOW());
INSERT INTO tblEmailTemplates(intEmailTemplateTypeID, strHTMLTemplatePath, strTextTemplatePath, strSubjectPrefix, intLanguageID, intActive, tTimeStamp) VALUES(8, 'notification/personrequest/html/', '', 'PERSON REQUEST ACCESS DENIED: ', 1, 1, NOW());
INSERT INTO tblEmailTemplates(intEmailTemplateTypeID, strHTMLTemplatePath, strTextTemplatePath, strSubjectPrefix, intLanguageID, intActive, tTimeStamp) VALUES(9, 'notification/personrequest/html/', '', 'PERSON REQUEST ACCESS OVERRIDDEN: ', 1, 1, NOW());
INSERT INTO tblEmailTemplates(intEmailTemplateTypeID, strHTMLTemplatePath, strTextTemplatePath, strSubjectPrefix, intLanguageID, intActive, tTimeStamp) VALUES(10, 'notification/personrequest/html/', '', 'PERSON REQUEST ACCESS REJECTED: ', 1, 1, NOW());
INSERT INTO tblEmailTemplates(intEmailTemplateTypeID, strHTMLTemplatePath, strTextTemplatePath, strSubjectPrefix, intLanguageID, intActive, tTimeStamp) VALUES(11, 'notification/personrequest/html/', '', 'PERSON REQUEST ACCESS COMPLETED: ', 1, 1, NOW());
INSERT INTO tblEmailTemplates(intEmailTemplateTypeID, strHTMLTemplatePath, strTextTemplatePath, strSubjectPrefix, intLanguageID, intActive, tTimeStamp) VALUES(12, 'notification/personrequest/html/', '', 'PERSON REQUEST TRANSFER ACCEPTED: ', 1, 1, NOW());
INSERT INTO tblEmailTemplates(intEmailTemplateTypeID, strHTMLTemplatePath, strTextTemplatePath, strSubjectPrefix, intLanguageID, intActive, tTimeStamp) VALUES(13, 'notification/personrequest/html/', '', 'PERSON REQUEST TRANSFER DENIED: ', 1, 1, NOW());
INSERT INTO tblEmailTemplates(intEmailTemplateTypeID, strHTMLTemplatePath, strTextTemplatePath, strSubjectPrefix, intLanguageID, intActive, tTimeStamp) VALUES(14, 'notification/personrequest/html/', '', 'PERSON REQUEST TRANSFER OVERRIDDEN: ', 1, 1, NOW());
INSERT INTO tblEmailTemplates(intEmailTemplateTypeID, strHTMLTemplatePath, strTextTemplatePath, strSubjectPrefix, intLanguageID, intActive, tTimeStamp) VALUES(15, 'notification/personrequest/html/', '', 'PERSON REQUEST TRANSFER REJECTED: ', 1, 1, NOW());
INSERT INTO tblEmailTemplates(intEmailTemplateTypeID, strHTMLTemplatePath, strTextTemplatePath, strSubjectPrefix, intLanguageID, intActive, tTimeStamp) VALUES(16, 'notification/personrequest/html/', '', 'PERSON REQUEST TRANSFER COMPLETED: ', 1, 1, NOW());
INSERT INTO tblEmailTemplates(intEmailTemplateTypeID, strHTMLTemplatePath, strTextTemplatePath, strSubjectPrefix, intLanguageID, intActive, tTimeStamp) VALUES(17, 'notification/personrequest/html/', '', 'PERSON REQUEST ACCESS SENT: ', 1, 1, NOW());
INSERT INTO tblEmailTemplates(intEmailTemplateTypeID, strHTMLTemplatePath, strTextTemplatePath, strSubjectPrefix, intLanguageID, intActive, tTimeStamp) VALUES(18, 'notification/personrequest/html/', '', 'PERSON REQUEST TRANSFER SENT: ', 1, 1, NOW());
INSERT INTO tblEmailTemplates(intEmailTemplateTypeID, strHTMLTemplatePath, strTextTemplatePath, strSubjectPrefix, intLanguageID, intActive, tTimeStamp) VALUES(19, 'notification/personrequest/html/', '', 'PERSON REQUEST ACCESS CANCELLED: ', 1, 1, NOW());
INSERT INTO tblEmailTemplates(intEmailTemplateTypeID, strHTMLTemplatePath, strTextTemplatePath, strSubjectPrefix, intLanguageID, intActive, tTimeStamp) VALUES(20, 'notification/personrequest/html/', '', 'PERSON REQUEST TRANSFER CANCELLED: ', 1, 1, NOW());

TRUNCATE TABLE tblEmailTemplateTypes;

INSERT INTO tblEmailTemplateTypes(strStatus, intRealmID, intSubRealmID, strTemplateType, strFileNamePrefix, intActive, tTimeStamp) VALUES('PENDING', 1, 0, 'NOTIFICATION_WFTASK_ADDED', 'wftask_added', 1, NOW());
INSERT INTO tblEmailTemplateTypes(strStatus, intRealmID, intSubRealmID, strTemplateType, strFileNamePrefix, intActive, tTimeStamp) VALUES('APPROVED', 1, 0, 'NOTIFICATION_WFTASK_APPROVED', 'wftask_approved', 1, NOW());
INSERT INTO tblEmailTemplateTypes(strStatus, intRealmID, intSubRealmID, strTemplateType, strFileNamePrefix, intActive, tTimeStamp) VALUES('REJECTED', 1, 0, 'NOTIFICATION_WFTASK_REJECTED', 'wftask_rejected', 1, NOW());
INSERT INTO tblEmailTemplateTypes(strStatus, intRealmID, intSubRealmID, strTemplateType, strFileNamePrefix, intActive, tTimeStamp) VALUES('PENDING', 1, 0, 'NOTIFICATION_WFTASK_RESOLVED', 'wftask_resolved', 1, NOW());
INSERT INTO tblEmailTemplateTypes(strStatus, intRealmID, intSubRealmID, strTemplateType, strFileNamePrefix, intActive, tTimeStamp) VALUES('PENDING', 1, 0, 'NOTIFICATION_WFTASK_HELD', 'wftask_held', 1, NOW());
INSERT INTO tblEmailTemplateTypes(strStatus, intRealmID, intSubRealmID, strTemplateType, strFileNamePrefix, intActive, tTimeStamp) VALUES('PENDING', 1, 0, 'NOTIFICATION_WFTASK_RESUMED', 'wftask_resumed', 1, NOW());
INSERT INTO tblEmailTemplateTypes(strStatus, intRealmID, intSubRealmID, strTemplateType, strFileNamePrefix, intActive, tTimeStamp) VALUES('APPROVED', 1, 0, 'NOTIFICATION_REQUESTACCESS_ACCEPTED', 'requestaccess_accepted', 1, NOW());
INSERT INTO tblEmailTemplateTypes(strStatus, intRealmID, intSubRealmID, strTemplateType, strFileNamePrefix, intActive, tTimeStamp) VALUES('REJECTED', 1, 0, 'NOTIFICATION_REQUESTACCESS_DENIED', 'requestaccess_denied', 1, NOW());
INSERT INTO tblEmailTemplateTypes(strStatus, intRealmID, intSubRealmID, strTemplateType, strFileNamePrefix, intActive, tTimeStamp) VALUES('REASSIGNED', 1, 0, 'NOTIFICATION_REQUESTACCESS_OVERRIDDEN', 'requestaccess_overridden', 1, NOW());
INSERT INTO tblEmailTemplateTypes(strStatus, intRealmID, intSubRealmID, strTemplateType, strFileNamePrefix, intActive, tTimeStamp) VALUES('REJECTED', 1, 0, 'NOTIFICATION_REQUESTACCESS_REJECTED', 'requestaccess_rejected', 1, NOW());
INSERT INTO tblEmailTemplateTypes(strStatus, intRealmID, intSubRealmID, strTemplateType, strFileNamePrefix, intActive, tTimeStamp) VALUES('APPROVED', 1, 0, 'NOTIFICATION_REQUESTACCESS_COMPLETED', 'requestaccess_completed', 1, NOW());
INSERT INTO tblEmailTemplateTypes(strStatus, intRealmID, intSubRealmID, strTemplateType, strFileNamePrefix, intActive, tTimeStamp) VALUES('APPROVED', 1, 0, 'NOTIFICATION_REQUESTTRANSFER_ACCEPTED', 'requesttransfer_accepted', 1, NOW());
INSERT INTO tblEmailTemplateTypes(strStatus, intRealmID, intSubRealmID, strTemplateType, strFileNamePrefix, intActive, tTimeStamp) VALUES('REJECTED', 1, 0, 'NOTIFICATION_REQUESTTRANSFER_DENIED', 'requesttransfer_denied', 1, NOW());
INSERT INTO tblEmailTemplateTypes(strStatus, intRealmID, intSubRealmID, strTemplateType, strFileNamePrefix, intActive, tTimeStamp) VALUES('REASSIGNED', 1, 0, 'NOTIFICATION_REQUESTTRANSFER_OVERRIDDEN', 'requesttransfer_overridden', 1, NOW());
INSERT INTO tblEmailTemplateTypes(strStatus, intRealmID, intSubRealmID, strTemplateType, strFileNamePrefix, intActive, tTimeStamp) VALUES('REJECTED', 1, 0, 'NOTIFICATION_REQUESTTRANSFER_REJECTED', 'requesttransfer_rejected', 1, NOW());
INSERT INTO tblEmailTemplateTypes(strStatus, intRealmID, intSubRealmID, strTemplateType, strFileNamePrefix, intActive, tTimeStamp) VALUES('APPROVED', 1, 0, 'NOTIFICATION_REQUESTTRANSFER_COMPLETED', 'requesttransfer_completed', 1, NOW());
INSERT INTO tblEmailTemplateTypes(strStatus, intRealmID, intSubRealmID, strTemplateType, strFileNamePrefix, intActive, tTimeStamp) VALUES('PENDING', 1, 0, 'NOTIFICATION_REQUESTACCESS_SENT', 'requestaccess_sent', 1, NOW());
INSERT INTO tblEmailTemplateTypes(strStatus, intRealmID, intSubRealmID, strTemplateType, strFileNamePrefix, intActive, tTimeStamp) VALUES('PENDING', 1, 0, 'NOTIFICATION_REQUESTTRANSFER_SENT', 'requesttransfer_sent', 1, NOW());
INSERT INTO tblEmailTemplateTypes(strStatus, intRealmID, intSubRealmID, strTemplateType, strFileNamePrefix, intActive, tTimeStamp) VALUES('CANCELLED', 1, 0, 'NOTIFICATION_REQUESTACCESS_CANCELLED', 'requestaccess_cancelled', 1, NOW());
INSERT INTO tblEmailTemplateTypes(strStatus, intRealmID, intSubRealmID, strTemplateType, strFileNamePrefix, intActive, tTimeStamp) VALUES('CANCELLED', 1, 0, 'NOTIFICATION_REQUESTTRANSFER_CANCELLED', 'requesttransfer_cancelled', 1, NOW());