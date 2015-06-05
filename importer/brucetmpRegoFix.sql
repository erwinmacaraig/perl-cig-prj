
DROP TABLE IF EXISTS tmpRegoFix;
CREATE TABLE tmpRegoFix (
    intID INT default 0,
    intPersonID int default 0,
    intEntityID int default 0,
    strStatus varchar(30) default '',
    strPersonType varchar(30) default '',
    strPersonLevel varchar(30) default '',
    strSport varchar(30) default '',
    intNationalPeriodID int default 0,
    
    UNIQUE KEY indexkeys (intPersonID, intEntityID, strPersonType, strSport, strPersonLevel)
) DEFAULT CHARACTER SET = utf8;


2mins
INSERT IGNORE tmpRegoFix SELECT intPersonRegistrationID , intPersonID, intEntityID, strStatus, strPersonType, strPersonLevel, strSport, intNationalPeriodID FROM tblPersonRegistration_1 WHERE strStatus IN ("PASSIVE", "ACTIVE") and intNationalPeriodID <=120 AND strPersonType IN ("COACH", "PLAYER", "REFEREE") ORDER BY intNationalPeriodID;

3mins
UPDATE tblPersonRegistration_1 SET strStatus='ROLLED_OVER' WHERE strStatus='PASSIVE' AND strPersonType IN ("COACH", "PLAYER", "REFEREE") and intNationalPeriodID <=120;


4:30
UPDATE tblPersonRegistration_1 as PR INNER JOIN tmpRegoFix as T ON (PR.intPersonRegistrationID = T.intID) SET PR.strStatus = T.strStatus;
