INSERT INTO tblEmailTemplateTypes (intEmailTemplateTypeID, intRealmID, intSubRealmID, strTemplateType, strFileNamePrefix, strStatus, intActive) VALUES
('49','1', '0', 'NOTIFICATION_INTERNATIONALPLAYERLOAN_SENT', 'wftask_added', 'PENDING', '1');

INSERT INTO tblEmailTemplates (intEmailTemplateTypeID, strHTMLTemplatePath, strSubjectPrefix, intLanguageID, intActive) VALUES 
('49', 'notification/workflow/html/', 'WORK TASK ADDED:  ', '1', '1');