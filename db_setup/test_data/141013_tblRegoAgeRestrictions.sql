UPDATE tblRegoAgeRestrictions set strRestrictionType = "", strAgeLevel = "ADULT" where intRegoAgeRestrictionID = 9;

INSERT INTO tblRegoAgeRestrictions(intRealmID, intSubRealmID, strSport, strPersonType, strPersonEntityRole, strPersonLevel, strRestrictionType, strAgeLevel, intFromAge, intToAge, tTimestamp) VALUES (1,0,'FOOTBALL','PLAYER','','AMATEUR_U_C','','MINOR',6,17,NOW());
INSERT INTO tblRegoAgeRestrictions(intRealmID, intSubRealmID, strSport, strPersonType, strPersonEntityRole, strPersonLevel, strRestrictionType, strAgeLevel, intFromAge, intToAge, tTimestamp) VALUES (1,0,'FOOTBALL','PLAYER','','AMATEUR_U_C','','ADULT',18,99,NOW());
