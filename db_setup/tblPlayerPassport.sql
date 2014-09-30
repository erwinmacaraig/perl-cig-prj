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
     CONSTRAINT PRIMARY KEY (intPlayerPassportID)
); 