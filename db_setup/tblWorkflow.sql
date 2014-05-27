CREATE TABLE tblWorkflow (
    intWorkflowID int NOT NULL AUTO_INCREMENT,
    intRealmID  INT DEFAULT 0,
    
    intTaskID INT default 0,
    strTaskDetails varchar(250) default '',
    intTaskStatus TINYINT DEFAULT 0, /* Your turn, pending, had your turn */

    intWorkflowLevel INT default 0, /*System level who the task is assigned to */
    intWorkflowID INT default 0, /* ID of the level to do task.. eg: the Entity */
    intWorkflowUserID INT default 0, /* User ID (tblUser) */

    intBaseRecordType INT default 0, /*Person, PersonReg, Entity, Transfer */
    intBaseRecordID INT default 0,

    intApprovalStatus INT default 0, /* Approved, Denied, Rejected to lower level */
    strReview varchar(50) default '', /* review feedback */
    strReviewNotes text, /* extended review notes */

    intLastWorkflowID int default 0,
    intNextWorkflowID int default 0,
     
    tTimeStamp timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    dtAdded date,

  PRIMARY KEY (intWorkflowID),
  KEY index_intWorkflowLevel (intWorkflowLevel),
  KEY index_intWorkflowID (intWorkflowID),
  KEY index_intWorkflowUserID (intWorkflowUserID),
  KEY index_intRealmID (intRealmID),
  KEY index_intBaseRecordType (intBaseRecordType),
  KEY index_intBaseRecordID (intBaseRecordID)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
#
