DROP TABLE IF EXISTS tblFieldMessages;
CREATE TABLE tblFieldMessages(
    strFieldType VARCHAR(30) NOT NULL, /* Type of Field: person, club, entity */
    strFieldname VARCHAR(50) NOT NULL, /* eg. strLocalSurname, intGender */
    strType VARCHAR(30) NOT NULL DEFAULT 'info', /* Type of message: pre, post, info */
    strLocale VARCHAR(10), /* Language locale eg. fi_FI or en_US */
    strMessage TEXT,

    PRIMARY KEY (strFieldType, strFieldname, strLocale)
) DEFAULT CHARSET=utf8;
