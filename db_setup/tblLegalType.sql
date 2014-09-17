CREATE TABLE tblLegalType 
(intLegalType int(11) NOT NULL AUTO_INCREMENT, 
intRealmID int(11) DEFAULT 0,  
strLegalType varchar(255),
tTimeStamp timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
PRIMARY KEY (intLegalType))
ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=latin1
