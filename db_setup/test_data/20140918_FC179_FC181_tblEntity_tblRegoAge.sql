UPDATE tblEntity set strDiscipline = 'ALL', strGender = 'ALL' where intEntityID = 35;

TRUNCATE TABLE tblRegoAgeRestrictions;
INSERT INTO tblRegoAgeRestrictions(intRealmID,intSubRealmID,strSport,strPersonType,strPersonEntityRole,strPersonLevel,strRestrictionType,strAgeLevel,intFromAge,intToAge,tTimestamp) VALUES (1,0,'FOOTBALL','PLAYER','','AMATEUR','','ADULT',6,99,'2014-09-12 07:38:42');
INSERT INTO tblRegoAgeRestrictions(intRealmID,intSubRealmID,strSport,strPersonType,strPersonEntityRole,strPersonLevel,strRestrictionType,strAgeLevel,intFromAge,intToAge,tTimestamp) VALUES (1,0,'FOOTBALL','PLAYER','','PROFESSIONAL','','',18,99,'2014-09-12 07:38:42');
INSERT INTO tblRegoAgeRestrictions(intRealmID,intSubRealmID,strSport,strPersonType,strPersonEntityRole,strPersonLevel,strRestrictionType,strAgeLevel,intFromAge,intToAge,tTimestamp) VALUES (1,0,'FUTSAL','PLAYER','','','','',6,99,'2014-09-12 07:38:42');
INSERT INTO tblRegoAgeRestrictions(intRealmID,intSubRealmID,strSport,strPersonType,strPersonEntityRole,strPersonLevel,strRestrictionType,strAgeLevel,intFromAge,intToAge,tTimestamp) VALUES (1,0,'FOOTBALL','TECHOFFICIAL','DOCTOR','','','ADULT',40,99,'2014-09-12 07:38:42');
INSERT INTO tblRegoAgeRestrictions(intRealmID,intSubRealmID,strSport,strPersonType,strPersonEntityRole,strPersonLevel,strRestrictionType,strAgeLevel,intFromAge,intToAge,tTimestamp) VALUES (1,0,'','CLUBOFFICIAL','PRESIDENT','','','',20,99,'2014-09-12 07:38:42');
INSERT INTO tblRegoAgeRestrictions(intRealmID,intSubRealmID,strSport,strPersonType,strPersonEntityRole,strPersonLevel,strRestrictionType,strAgeLevel,intFromAge,intToAge,tTimestamp) VALUES (1,0,'FOOTBALL','MAOFFICIAL','MATCHCOMMISIONER','','','ADULT',50,99,'2014-09-12 07:38:42');

INSERT INTO tblRegoAgeRestrictions(intRealmID, intSubRealmID, strSport, strPersonType, strPersonEntityRole, strPersonLevel, strRestrictionType, strAgeLevel, intFromAge, intToAge, tTimestamp) VALUES (1,0,'FOOTBALL','PLAYER','','AMATEUR','','ADULT',18,99,NOW());
