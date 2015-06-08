
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







UPDATE tblPersonRegistration_1 SET strStatus='PASSIVE' WHERE strStatus='ROLLED_OVER' AND strPersonType IN ("COACH", "PLAYER", "REFEREE") and intNationalPeriodID <=120;


then

INSERT IGNORE tmpRegoFix SELECT intPersonRegistrationID , intPersonID, intEntityID, strStatus, strPersonType, strPersonLevel, strSport, intNationalPeriodID FROM tblPersonRegistration_1 WHERE strStatus IN ("PASSIVE", "ACTIVE") and intNationalPeriodID <=120 AND strPersonType IN ("COACH", "PLAYER", "REFEREE") ORDER BY dtFrom DESC, strStatus, tmpisPaid DESC;


UPDATE tblPersonRegistration_1 SET strStatus='ROLLED_OVER' WHERE strStatus='PASSIVE' AND strPersonType IN ("PLAYER") and intNationalPeriodID <=120 AND intOnLoan = 0 and intIsLoanedOut = 0;
UPDATE tblPersonRegistration_1 SET strStatus='ROLLED_OVER' WHERE strStatus='PASSIVE' AND strPersonType IN ("REFEREE") and intNationalPeriodID <=120 AND intOnLoan = 0 and intIsLoanedOut = 0;

UPDATE tblPersonRegistration_1 as PR INNER JOIN tmpRegoFix as T ON (PR.intPersonRegistrationID = T.intID) SET PR.strStatus = T.strStatus WHERE intOnLoan = 0 and intIsLoanedOut = 0;

UPDATE tblPersonRegistration_1 as PR INNER JOIN tmpRegoFix as T ON (PR.intPersonRegistrationID = T.intID) SET PR.strStatus = T.strStatus WHERE intOnLoan = 0 and intIsLoanedOut = 0 AND PR.strPersonType='REFEREE';



UPDATE tblPersonRegistration_1 SET strStatus='ROLLED_OVER' WHERE strStatus='PASSIVE' AND strPersonType IN ("PLAYER") and intNationalPeriodID <=120 AND intOnLoan = 0 and intIsLoanedOut = 0;
UPDATE tblPersonRegistration_1 as PR INNER JOIN tmpRegoFix as T ON (PR.intPersonRegistrationID = T.intID) SET PR.strStatus = T.strStatus WHERE and intOnLoan = 0 and intIsLoanedOut = 0;


#COACH
INSERT IGNORE tmpRegoFix SELECT intPersonRegistrationID , intPersonID, intEntityID, strStatus, strPersonType, strPersonLevel, strSport, intNationalPeriodID FROM tblPersonRegistration_1 WHERE strStatus IN ("PASSIVE", "ACTIVE") and intNationalPeriodID <=120 AND strPersonType IN ("COACH") ORDER BY dtFrom DESC, strStatus, tmpisPaid DESC;
UPDATE tblPersonRegistration_1 SET strStatus='ROLLED_OVER' WHERE strStatus='PASSIVE' AND strPersonType IN ("COACH") and intNationalPeriodID <=120 ;
UPDATE tblPersonRegistration_1 as PR INNER JOIN tmpRegoFix as T ON (PR.intPersonRegistrationID = T.intID) SET PR.strStatus = T.strStatus WHERE PR.strPersonType='COACH';


UPDATE tblPersonRegistration_FIN as FIN INNER JOIN tblPersonRegistration_1 as PR ON (PR.intPersonRegistrationID = FIN.intPersonRegistrationID) SET FIN.strStatus = PR.strStatus WHERE PR.strPersonType='COACH';


