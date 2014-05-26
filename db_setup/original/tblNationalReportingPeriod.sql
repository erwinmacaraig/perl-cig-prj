CREATE TABLE tblNationalPeriod (
  intNationalPeriodID INT NOT NULL AUTO_INCREMENT,
  strPeriodName VARCHAR(100),
  intRealmID INT,
  intSubRealmID INT,
  dtStart DATE,
  dtEnd DATE,
  PRIMARY KEY (intNationalPeriodID),
  KEY index_intRealm(intRealmID, intSubRealmID)
)
