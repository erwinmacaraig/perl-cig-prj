DROP TABLE IF EXISTS tblNewsletter;
CREATE TABLE tblNewsletter(
    intNewsletterID INT NOT NULL AUTO_INCREMENT,
    intEntityTypeID INT NOT NULL,
    intEntityID INT NOT NULL,
    strName VARCHAR(200) DEFAULT '',
    dtCreated DATETIME DEFAULT NULL,
    intStatus TINYINT(4) DEFAULT 0,

    PRIMARY KEY (intNewsletterID)
);
