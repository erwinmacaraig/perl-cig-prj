CREATE table tblEOI	(
    	intEOIID     				INT NOT NULL AUTO_INCREMENT,
    	strFirstname   		 		VARCHAR (50),
    	strSurname    		 		VARCHAR (50),
    	strPostalCode   			VARCHAR (15),
    	dtDOB           			DATE,
    	strPhone    				VARCHAR (20),
    	strEmail       		 		VARCHAR (200),
    	dtCreated				DATETIME,
	intRealmID				INT,

PRIMARY KEY (intEOIID),
	KEY index_intRealmID(intRealmID),
	KEY index_dtDOB(dtDOB)
);
 
