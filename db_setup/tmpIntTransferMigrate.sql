CREATE TABLE tmpIntTransferMigrate (
    intPersonID INT DEFAULT 0,
    intPersonRegistrationID INT DEFAULT 0,    
    intLastEntityID INT DEFAULT 0,
    strType VARCHAR(30) DEFAULT '',
    KEY index_PersonID (intPersonID),
    KEY index_PersonRegoID (intPersonRegistrationID)
) DEFAULT CHARSET=utf8;

