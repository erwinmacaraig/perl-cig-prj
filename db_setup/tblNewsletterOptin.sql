DROP TABLE IF EXISTS tblNewsletterOptin;
CREATE TABLE tblNewsletterOptin(
    intNewsletterOptinID INT NOT NULL AUTO_INCREMENT,
    intNewsletterID INT NOT NULL,
    strEmail VARCHAR(200) NOT NULL,
    intMemberID INT DEFAULT NULL,
    dtOptIn DATETIME NOT NULL,
    dtOptOut DATETIME DEFAULT NULL,

    PRIMARY KEY (intNewsletterOptinID)
);
