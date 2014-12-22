drop table if exists tblPlayerPassport;
CREATE TABLE tblPlayerPassport (
     intPlayerPassportID INT NOT NULL AUTO_INCREMENT, 
     intPersonID INT, 
     strOrigin VARCHAR(20), 
     strPersonLevel VARCHAR(20), 
     intEntityID INT, 
     strEntityName VARCHAR(200), 
     strMAName VARCHAR(200), 
     dtFrom DATE, 
     dtTo DATE,
    tTimeStamp timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT PRIMARY KEY (intPlayerPassportID),
    KEY INDEX_intPersonID (intPersonID)
    
)  DEFAULT CHARSET=utf8; 
