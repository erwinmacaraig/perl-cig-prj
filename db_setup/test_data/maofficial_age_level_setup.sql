

-- add ADULT 
INSERT INTO tblMatrix(intMatrixID, intRealmID, intSubRealmID, intEntityLevel, strWFRuleFor, strEntityType, strPersonType, strRegistrationNature, strPersonLevel, strSport, intOriginLevel, strAgeLevel, intPaymentRequired, dtAdded, tTimeStamp, intOfEntityLevel, strPersonEntityRole, intLocked, dtFrom, dtTo) SELECT 0, intRealmID, intSubRealmID, intEntityLevel, strWFRuleFor, strEntityType, strPersonType, strRegistrationNature, strPersonLevel, strSport, intOriginLevel, 'ADULT', intPaymentRequired, dtAdded, tTimeStamp, intOfEntityLevel, strPersonEntityRole, intLocked, dtFrom, dtTo FROM tblMatrix WHERE intMatrixID = 126;

-- update to MINOR
UPDATE tblMatrix SET strAgeLevel = 'MINOR' WHERE intMatrixID = 126;
--Renew
INSERT INTO tblMatrix(intMatrixID, intRealmID, intSubRealmID, intEntityLevel, strWFRuleFor, strEntityType, strPersonType, strRegistrationNature, strPersonLevel, strSport, intOriginLevel, strAgeLevel, intPaymentRequired, dtAdded, tTimeStamp, intOfEntityLevel, strPersonEntityRole, intLocked, dtFrom, dtTo) SELECT 0, intRealmID, intSubRealmID, intEntityLevel, strWFRuleFor, strEntityType, strPersonType, strRegistrationNature, strPersonLevel, strSport, intOriginLevel, 'ADULT', intPaymentRequired, dtAdded, tTimeStamp, intOfEntityLevel, strPersonEntityRole, intLocked, dtFrom, dtTo FROM tblMatrix WHERE intMatrixID = 127;
-- update to MINOR
UPDATE tblMatrix SET strAgeLevel = 'MINOR' WHERE intMatrixID = 127;


-- below should satisfy age range of 16-45, including age level
INSERT INTO tblRegoAgeRestrictions(intRegoAgeRestrictionID, intRealmID, intSubRealmID, strSport, strPersonType, strPersonEntityRole, strPersonLevel, strRestrictionType, strAgeLevel, intFromAge, intToAge, tTimestamp) SELECT 0, intRealmID, intSubRealmID, strSport, strPersonType, strPersonEntityRole, strPersonLevel, strRestrictionType, 'ADULT', 21, 99, tTimestamp FROM tblRegoAgeRestrictions WHERE intRegoAgeRestrictionID = 13;

-- update to MINOR age range
UPDATE tblRegoAgeRestrictions SET intFromAge = 6, intToAge = 21, strAgeLevel = 'MINOR' WHERE intRegoAgeRestrictionID = 13;
