UPDATE tblEmailTemplates SET strHTMLTemplatePath = 'notification/workflow/html/' WHERE intEmailTemplateID IN (1,2,3,4,5,6);
UPDATE tblEmailTemplates SET strHTMLTemplatePath = 'notification/personrequest/html/' WHERE intEmailTemplateID IN (7,8,9,10,11,12,13,14,15,16,17,18);

UPDATE tblEmailTemplateTypes SET strStatus = 'PENDING' WHERE strTemplateType = 'NOTIFICATION_WFTASK_ADDED';
UPDATE tblEmailTemplateTypes SET strStatus = 'APPROVED' WHERE strTemplateType = 'NOTIFICATION_WFTASK_APPROVED';
UPDATE tblEmailTemplateTypes SET strStatus = 'REJECTED' WHERE strTemplateType = 'NOTIFICATION_WFTASK_REJECTED';
UPDATE tblEmailTemplateTypes SET strStatus = 'PENDING' WHERE strTemplateType = 'NOTIFICATION_WFTASK_RESOLVED';
UPDATE tblEmailTemplateTypes SET strStatus = 'PENDING' WHERE strTemplateType = 'NOTIFICATION_WFTASK_HELD';
UPDATE tblEmailTemplateTypes SET strStatus = 'PENDING' WHERE strTemplateType = 'NOTIFICATION_WFTASK_RESUMED';
UPDATE tblEmailTemplateTypes SET strStatus = 'APPROVED' WHERE strTemplateType = 'NOTIFICATION_REQUESTACCESS_ACCEPTED';
UPDATE tblEmailTemplateTypes SET strStatus = 'REJECTED' WHERE strTemplateType = 'NOTIFICATION_REQUESTACCESS_DENIED';
UPDATE tblEmailTemplateTypes SET strStatus = 'REASSIGNED' WHERE strTemplateType = 'NOTIFICATION_REQUESTACCESS_OVERRIDDEN';
UPDATE tblEmailTemplateTypes SET strStatus = 'REJECTED' WHERE strTemplateType = 'NOTIFICATION_REQUESTACCESS_REJECTED';
UPDATE tblEmailTemplateTypes SET strStatus = 'APPROVED' WHERE strTemplateType = 'NOTIFICATION_REQUESTACCESS_COMPLETED';
UPDATE tblEmailTemplateTypes SET strStatus = 'APPROVED' WHERE strTemplateType = 'NOTIFICATION_REQUESTTRANSFER_ACCEPTED';
UPDATE tblEmailTemplateTypes SET strStatus = 'REJECTED' WHERE strTemplateType = 'NOTIFICATION_REQUESTTRANSFER_DENIED';
UPDATE tblEmailTemplateTypes SET strStatus = 'REASSIGNED' WHERE strTemplateType = 'NOTIFICATION_REQUESTTRANSFER_OVERRIDDEN';
UPDATE tblEmailTemplateTypes SET strStatus = 'REJECTED' WHERE strTemplateType = 'NOTIFICATION_REQUESTTRANSFER_REJECTED';
UPDATE tblEmailTemplateTypes SET strStatus = 'APPROVED' WHERE strTemplateType = 'NOTIFICATION_REQUESTTRANSFER_COMPLETED';
UPDATE tblEmailTemplateTypes SET strStatus = 'PENDING' WHERE strTemplateType = 'NOTIFICATION_REQUESTACCESS_SENT';
UPDATE tblEmailTemplateTypes SET strStatus = 'PENDING' WHERE strTemplateType = 'NOTIFICATION_REQUESTTRANSFER_SENT';
