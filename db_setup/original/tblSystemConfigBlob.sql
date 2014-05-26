DROP TABLE IF EXISTS tblSystemConfigBlob ;
 
CREATE table tblSystemConfigBlob (
	intSystemConfigID INT NOT NULL,
	strBlob	TEXT NOT NULL,
		
	PRIMARY KEY (intSystemConfigID)
);
 
