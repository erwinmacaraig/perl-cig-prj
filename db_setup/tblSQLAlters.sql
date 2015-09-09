DROP TABLE IF EXISTS tblSQLAlters;
CREATE TABLE IF NOT EXISTS tblSQLAlters (
    intSQLAlterID INT NOT NULL AUTO_INCREMENT,
    strFilename VARCHAR(100) default '',
    dtLog datetime,
    strErrors text,
    intStatus INT DEFAULT 0,
    PRIMARY KEY (intSQLAlterID)
) DEFAULT CHARSET=utf8;
