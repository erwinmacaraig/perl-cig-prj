-- tblSystemConfig
INSERT INTO `tblSystemConfig` VALUES (0,1,'menu_newperson_RAOFFICIAL_20','1',NOW(),1,0);
INSERT INTO `tblSystemConfig` VALUES (0,1,'menu_newperson_RAOFFICIAL_20_20','1',NOW(),1,0);

-- tblEntityTypeRoles
INSERT INTO `tblEntityTypeRoles` VALUES (0,1,0,'','RAOFFICIAL','RAREFOB','Referee Observer',NOW());

-- tblRegoAgeRestrictions
INSERT INTO `tblRegoAgeRestrictions` VALUES (0,1,0,'','RAOFFICIAL','','','','MINOR',18,18,NOW());
INSERT INTO `tblRegoAgeRestrictions` VALUES (0,1,0,'','RAOFFICIAL','','','','ADULT',19,99,NOW());




-- RA adding RA Official --

-- tblMatrix
INSERT INTO `tblMatrix` VALUES (0,1,0,20,'REGO','','RAOFFICIAL','NEW','','',20,'MINOR',1,NOW(),NOW(),1,'',0,NULL,NULL);
INSERT INTO `tblMatrix` VALUES (0,1,0,20,'REGO','','RAOFFICIAL','NEW','','',20,'ADULT',1,NOW(),NOW(),1,'',0,NULL,NULL);
INSERT INTO `tblMatrix` VALUES (0,1,0,20,'REGO','','RAOFFICIAL','RENEWAL','','',20,'MINOR',1,NOW(),NOW(),1,'',0,NULL,NULL);
INSERT INTO `tblMatrix` VALUES (0,1,0,20,'REGO','','RAOFFICIAL','RENEWAL','','',20,'ADULT',1,NOW(),NOW(),1,'',0,NULL,NULL);

-- tblRegistrationItem
INSERT INTO `tblRegistrationItem` VALUES (0,1,0,20,'REGO','',20,'RENEWAL','RAOFFICIAL','','','','DOCUMENT',68,1,1,NOW(),1,'','','|FI|',0,0);
INSERT INTO `tblRegistrationItem` VALUES (0,1,0,20,'REGO','',20,'NEW','RAOFFICIAL','','','','DOCUMENT',68,1,1,NOW(),1,'','','|FI|',0,0);
INSERT INTO `tblRegistrationItem` VALUES (0,1,0,20,'REGO','',20,'RENEWAL','RAOFFICIAL','','','','DOCUMENT',130,1,1,NOW(),1,'','|FI|','',0,0);
INSERT INTO `tblRegistrationItem` VALUES (0,1,0,20,'REGO','',20,'NEW','RAOFFICIAL','','','','DOCUMENT',130,1,1,NOW(),1,'','|FI|','',0,0);

-- tblWFRule
INSERT INTO `tblWFRule` VALUES (0,1,0,20,'REGO','',20,'NEW','RAOFFICIAL','','','MINOR',20,20,'APPROVAL','ACTIVE',NOW(),0,'','','');
INSERT INTO `tblWFRule` VALUES (0,1,0,20,'REGO','',20,'NEW','RAOFFICIAL','','','ADULT',20,20,'APPROVAL','ACTIVE',NOW(),0,'','','');
INSERT INTO `tblWFRule` VALUES (0,1,0,20,'REGO','',20,'RENEWAL','RAOFFICIAL','','','MINOR',20,20,'APPROVAL','ACTIVE',NOW(),0,'','','');
INSERT INTO `tblWFRule` VALUES (0,1,0,20,'REGO','',20,'RENEWAL','RAOFFICIAL','','','ADULT',20,20,'APPROVAL','ACTIVE',NOW(),0,'','','');

-- tblWFRuleDocuments (update 2nd column with intWFRuleID)
-- INSERT INTO `tblWFRuleDocuments` VALUES (0,1825,68,1,1,1,0,'2015-02-13 02:05:57');
-- INSERT INTO `tblWFRuleDocuments` VALUES (0,1825,130,1,1,1,0,'2015-02-24 04:09:45');
-- INSERT INTO `tblWFRuleDocuments` VALUES (0,1826,68,1,1,1,0,'2015-02-13 02:05:57');
-- INSERT INTO `tblWFRuleDocuments` VALUES (0,1826,130,1,1,1,0,'2015-02-24 04:09:45');
-- INSERT INTO `tblWFRuleDocuments` VALUES (0,1827,68,1,1,1,0,'2015-02-16 09:27:26');
-- INSERT INTO `tblWFRuleDocuments` VALUES (0,1827,130,1,1,1,0,'2015-02-24 04:09:45');
-- INSERT INTO `tblWFRuleDocuments` VALUES (0,1828,68,1,1,1,0,'2015-02-16 09:27:27');
-- INSERT INTO `tblWFRuleDocuments` VALUES (0,1828,130,1,1,1,0,'2015-02-24 04:09:45');





-- MA adding RA Official on RA's behalf --

-- tblMatrix
INSERT INTO `tblMatrix` VALUES (0,1,0,20,'REGO','','RAOFFICIAL','NEW','','',100,'MINOR',1,NOW(),NOW(),1,'',0,NULL,NULL);
INSERT INTO `tblMatrix` VALUES (0,1,0,20,'REGO','','RAOFFICIAL','NEW','','',100,'ADULT',1,NOW(),NOW(),1,'',0,NULL,NULL);
INSERT INTO `tblMatrix` VALUES (0,1,0,20,'REGO','','RAOFFICIAL','RENEWAL','','',100,'MINOR',1,NOW(),NOW(),1,'',0,NULL,NULL);
INSERT INTO `tblMatrix` VALUES (0,1,0,20,'REGO','','RAOFFICIAL','RENEWAL','','',100,'ADULT',1,NOW(),NOW(),1,'',0,NULL,NULL);

-- tblSystemConfig
INSERT INTO `tblSystemConfig` VALUES (0,1,'menu_newperson_RAOFFICIAL_100_20','1',NOW(),1,0);

-- tblRegistrationItem
INSERT INTO `tblRegistrationItem` VALUES (0,1,0,100,'REGO','',20,'RENEWAL','RAOFFICIAL','','','','DOCUMENT',68,1,1,NOW(),1,'','','|FI|',0,0);
INSERT INTO `tblRegistrationItem` VALUES (0,1,0,100,'REGO','',20,'NEW','RAOFFICIAL','','','','DOCUMENT',68,1,1,NOW(),1,'','','|FI|',0,0);
INSERT INTO `tblRegistrationItem` VALUES (0,1,0,100,'REGO','',20,'RENEWAL','RAOFFICIAL','','','','DOCUMENT',130,1,1,NOW(),1,'','|FI|','',0,0);
INSERT INTO `tblRegistrationItem` VALUES (0,1,0,100,'REGO','',20,'NEW','RAOFFICIAL','','','','DOCUMENT',130,1,1,NOW(),1,'','|FI|','',0,0);

-- tblWFRule
INSERT INTO `tblWFRule` VALUES (0,1,0,100,'REGO','',20,'NEW','RAOFFICIAL','','','MINOR',20,20,'APPROVAL','ACTIVE',NOW(),0,'','','');
INSERT INTO `tblWFRule` VALUES (0,1,0,100,'REGO','',20,'NEW','RAOFFICIAL','','','ADULT',20,20,'APPROVAL','ACTIVE',NOW(),0,'','','');
INSERT INTO `tblWFRule` VALUES (0,1,0,100,'REGO','',20,'RENEWAL','RAOFFICIAL','','','MINOR',20,20,'APPROVAL','ACTIVE',NOW(),0,'','','');
INSERT INTO `tblWFRule` VALUES (0,1,0,100,'REGO','',20,'RENEWAL','RAOFFICIAL','','','ADULT',20,20,'APPROVAL','ACTIVE',NOW(),0,'','','');

-- tblWFRuleDocuments (update 2nd column with intWFRuleID)
-- INSERT INTO `tblWFRuleDocuments` VALUES (0,1825,68,1,1,1,0,'2015-02-13 02:05:57');
-- INSERT INTO `tblWFRuleDocuments` VALUES (0,1825,130,1,1,1,0,'2015-02-24 04:09:45');
-- INSERT INTO `tblWFRuleDocuments` VALUES (0,1826,68,1,1,1,0,'2015-02-13 02:05:57');
-- INSERT INTO `tblWFRuleDocuments` VALUES (0,1826,130,1,1,1,0,'2015-02-24 04:09:45');
-- INSERT INTO `tblWFRuleDocuments` VALUES (0,1827,68,1,1,1,0,'2015-02-16 09:27:26');
-- INSERT INTO `tblWFRuleDocuments` VALUES (0,1827,130,1,1,1,0,'2015-02-24 04:09:45');
-- INSERT INTO `tblWFRuleDocuments` VALUES (0,1828,68,1,1,1,0,'2015-02-16 09:27:27');
-- INSERT INTO `tblWFRuleDocuments` VALUES (0,1828,130,1,1,1,0,'2015-02-24 04:09:45');


