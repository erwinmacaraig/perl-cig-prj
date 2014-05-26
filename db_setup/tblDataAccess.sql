drop table tblDataAccess;

CREATE table tblDataAccess	(
    intTypeID       		INT NOT NULL, 
    intEntityID     		INT NOT NULL,
    intDataAccess		INT NOT NULL DEFAULT 10,

PRIMARY KEY (intTypeID, intEntityID),
KEY index_TypeID (intTypeID)
);
 
 
