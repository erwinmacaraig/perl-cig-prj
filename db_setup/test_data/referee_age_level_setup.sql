

-- add ADULT REFEREE
INSERT INTO tblMatrix(intMatrixID, intRealmID, intSubRealmID, intEntityLevel, strWFRuleFor, strEntityType, strPersonType, strRegistrationNature, strPersonLevel, strSport, intOriginLevel, strAgeLevel, intPaymentRequired, dtAdded, tTimeStamp, intOfEntityLevel, strPersonEntityRole, intLocked, dtFrom, dtTo) SELECT 0, intRealmID, intSubRealmID, intEntityLevel, strWFRuleFor, strEntityType, strPersonType, strRegistrationNature, strPersonLevel, strSport, intOriginLevel, 'ADULT', intPaymentRequired, dtAdded, tTimeStamp, intOfEntityLevel, strPersonEntityRole, intLocked, dtFrom, dtTo FROM tblMatrix WHERE intMatrixID = 97;

-- update to MINOR
UPDATE tblMatrix SET strAgeLevel = 'MINOR' WHERE intMatrixID = 97;
--Renew
INSERT INTO tblMatrix(intMatrixID, intRealmID, intSubRealmID, intEntityLevel, strWFRuleFor, strEntityType, strPersonType, strRegistrationNature, strPersonLevel, strSport, intOriginLevel, strAgeLevel, intPaymentRequired, dtAdded, tTimeStamp, intOfEntityLevel, strPersonEntityRole, intLocked, dtFrom, dtTo) SELECT 0, intRealmID, intSubRealmID, intEntityLevel, strWFRuleFor, strEntityType, strPersonType, strRegistrationNature, strPersonLevel, strSport, intOriginLevel, 'ADULT', intPaymentRequired, dtAdded, tTimeStamp, intOfEntityLevel, strPersonEntityRole, intLocked, dtFrom, dtTo FROM tblMatrix WHERE intMatrixID = 98;
-- update to MINOR
UPDATE tblMatrix SET strAgeLevel = 'MINOR' WHERE intMatrixID = 98;


-- below should satisfy REFEREE age range of 16-45, including age level
-- add MINOR REFEREE with age from 16-20 
INSERT INTO tblRegoAgeRestrictions(intRegoAgeRestrictionID, intRealmID, intSubRealmID, strSport, strPersonType, strPersonEntityRole, strPersonLevel, strRestrictionType, strAgeLevel, intFromAge, intToAge, tTimestamp) SELECT 0, intRealmID, intSubRealmID, strSport, strPersonType, strPersonEntityRole, strPersonLevel, strRestrictionType, 'ADULT', 21, 45, tTimestamp FROM tblRegoAgeRestrictions WHERE intRegoAgeRestrictionID = 20;

-- update to MINOR age range
UPDATE tblRegoAgeRestrictions SET intFromAge = 16, intToAge = 21, strAgeLevel = 'MINOR' WHERE intRegoAgeRestrictionID = 20;
