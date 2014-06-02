CREATE TABLE tblTask(
    intTaskID int NOT NULL AUTO_INCREMENT,
    intRealmID  INT DEFAULT 0,
    
    strTaskType VARCHAR(30) NOT NULL DEFAULT, /* APPROVEDOC, APPROVEMEMBER,APROVEVENUE, HANDLEREJECTION */
    intMatrixID INT NOT NULL,
    intApprovalStatus INT default 0, /* pending, Approved, Denied */
    strReviewNotes text, /* extended review notes */

    intEntityLevel TINYINT DEFAULT 0,
    intEntityID INT NOT NULL,
    intRoleID INT NOT NULL DEFAULT 0,

    intID INT NOT NULL, /* registrationID for APPROVEPERSON, documentID for approveDOC */

    dtAdded DATETIME, 
    dtCompleted DATETIME, 

    tTimeStamp timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,


  PRIMARY KEY (intTaskID),
) DEFAULT CHARSET=utf8;
