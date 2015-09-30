DROP TABLE IF EXISTS tblLogo;
CREATE TABLE tblLogo (
    intEntityTypeID INT NOT NULL,
    intEntityID INT NOT NULL,
    strPath VARCHAR(50) NOT NULL,
    strFilename VARCHAR(50) NOT NULL,
    strExtension CHAR(4),
    intBytes INT DEFAULT 1,

PRIMARY KEY (intEntityTypeID,intEntityID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

