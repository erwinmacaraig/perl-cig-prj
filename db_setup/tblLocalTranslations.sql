DROP TABLE IF EXISTS tblLocalTranslations;
CREATE TABLE tblLocalTranslations (
    strType VARCHAR(30) NOT NULL, /* Type of table SystemConfig, Document, Product */
    intID INT NOT NULL, /* ID from the type table */
    strLocale VARCHAR(10), /* Language locale eg. fi_FI or en_US */
    strString1 VARCHAR(100),
    strString2 VARCHAR(100),
    strString3 VARCHAR(100),
    strNote TEXT,

    PRIMARY KEY (strType, strLocale, intID)
);
