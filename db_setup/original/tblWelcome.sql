DROP TABLE tblWelcome;


CREATE table tblWelcome  (
    intWelcomeID      				 INTEGER NOT NULL AUTO_INCREMENT,
    intRealmID								 INTEGER NOT NULL,
    intAssocID                 INTEGER NOT NULL,
    strWelcomeText 						 MEDIUMTEXT,

PRIMARY KEY (intWelcomeID),
  KEY index_intRealmAssoc (intRealmID, intAssocID)
);
