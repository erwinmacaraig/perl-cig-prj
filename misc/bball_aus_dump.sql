-- Series of SQL statement to export data for Basketball Australia as csv.

-- tblMembers
(
SELECT 'intMemberID','strExtKey','strMemberNo','strFirstname','strMiddlename','strSurname','strAddress1','strAddress2','strSuburb','strState','strPostalCode','strCountry','strSalutation','dtDOB','intGender','strMaidenName','strPhoneHome','strPhoneWork','strPhoneMobile','strFax','strPager','strEmail','dtLastUpdate','intEthnicityID','intOccupationID','intStatus','strNotes','strPlaceofBirth','strCityOfResidence','strPassportNo','strPassportNationality','dtPassportExpiry','strEmergContName','strEmergContRel','strEmergContNo','strEyeColour','strHairColour','strHeight','strWeight','intDeceased','strP1FName','strP1SName','strP2FName','strP2SName','strBirthCertNo','strHealthCareNo','intIdentTypeID','strIdentNum','strNatCustomStr1','strNatCustomStr2','strNatCustomStr3','strNatCustomStr4','strNatCustomStr5','strNatCustomStr6','strNatCustomStr7','strNatCustomStr8','dblNatCustomDbl1','dblNatCustomDbl2','dblNatCustomDbl3','dblNatCustomDbl4','dtNatCustomDt1','dtNatCustomDt2','strNationalNum','dtSuspendedUntil','intPlayer','intCoach','intUmpire','intOfficial','intMisc','intPhoto','tTimeStamp','dtPoliceCheck','dtPoliceCheckExp','strPoliceCheckRef','intFavStateTeamID','intFavNationalTeamID','intNatCustomLU1','intNatCustomLU2','intNatCustomLU3','intSchoolID','intGradeID','intHowFoundOutID','strP1Email','strP2Email','strP1Phone','strP2Phone','intP1AssistAreaID','intP2AssistAreaID','intMedicalConditions','intAllergies','strMedicalNotes','intAllowMedicalTreatment','intConsentSignatureSighted','dtCreatedOnline','intCreatedFrom','intFavNationalTeamMember','intAttendSportCount','intWatchSportHowOftenID','strEmergContNo2','strP1Salutation','strP2Salutation','intP1Gender','intP2Gender','strP1Phone2','strP2Phone2','strP1PhoneMobile','strP2PhoneMobile','strP1Email2','strP2Email2','intDefaulter','intVolunteer','strNatCustomStr9','strNatCustomStr10','strNatCustomStr11','strNatCustomStr12','strNatCustomStr13','strNatCustomStr14','strNatCustomStr15','dblNatCustomDbl5','dblNatCustomDbl6','dblNatCustomDbl7','dblNatCustomDbl8','dblNatCustomDbl9','dblNatCustomDbl10','dtNatCustomDt3','dtNatCustomDt4','dtNatCustomDt5','intNatCustomLU4','intNatCustomLU5','intNatCustomLU6','intNatCustomLU7','intNatCustomLU8','intNatCustomLU9','intNatCustomLU10','intNatCustomBool1','intNatCustomBool2','intNatCustomBool3','intNatCustomBool4','intNatCustomBool5','strPreferredName','strEmail2','strPreferredLang','strPassportIssueCountry'
)
UNION
(
SELECT tblMember.intMemberID,tblMember.strExtKey,tblMember.strMemberNo,tblMember.strFirstname,tblMember.strMiddlename,tblMember.strSurname,tblMember.strAddress1,tblMember.strAddress2,tblMember.strSuburb,tblMember.strState,tblMember.strPostalCode,tblMember.strCountry,tblMember.strSalutation,tblMember.dtDOB,tblMember.intGender,tblMember.strMaidenName,tblMember.strPhoneHome,tblMember.strPhoneWork,tblMember.strPhoneMobile,tblMember.strFax,tblMember.strPager,tblMember.strEmail,tblMember.dtLastUpdate,tblMember.intEthnicityID,tblMember.intOccupationID,tblMember.intStatus,tblMember.strNotes,tblMember.strPlaceofBirth,tblMember.strCityOfResidence,tblMember.strPassportNo,tblMember.strPassportNationality,tblMember.dtPassportExpiry,tblMember.strEmergContName,tblMember.strEmergContRel,tblMember.strEmergContNo,tblMember.strEyeColour,tblMember.strHairColour,tblMember.strHeight,tblMember.strWeight,tblMember.intDeceased,tblMember.strP1FName,tblMember.strP1SName,tblMember.strP2FName,tblMember.strP2SName,tblMember.strBirthCertNo,tblMember.strHealthCareNo,tblMember.intIdentTypeID,tblMember.strIdentNum,tblMember.strNatCustomStr1,tblMember.strNatCustomStr2,tblMember.strNatCustomStr3,tblMember.strNatCustomStr4,tblMember.strNatCustomStr5,tblMember.strNatCustomStr6,tblMember.strNatCustomStr7,tblMember.strNatCustomStr8,tblMember.dblNatCustomDbl1,tblMember.dblNatCustomDbl2,tblMember.dblNatCustomDbl3,tblMember.dblNatCustomDbl4,tblMember.dtNatCustomDt1,tblMember.dtNatCustomDt2,tblMember.strNationalNum,tblMember.dtSuspendedUntil,tblMember.intPlayer,tblMember.intCoach,tblMember.intUmpire,tblMember.intOfficial,tblMember.intMisc,tblMember.intPhoto,tblMember.tTimeStamp,tblMember.dtPoliceCheck,tblMember.dtPoliceCheckExp,tblMember.strPoliceCheckRef,tblMember.intFavStateTeamID,tblMember.intFavNationalTeamID,tblMember.intNatCustomLU1,tblMember.intNatCustomLU2,tblMember.intNatCustomLU3,tblMember.intSchoolID,tblMember.intGradeID,tblMember.intHowFoundOutID,tblMember.strP1Email,tblMember.strP2Email,tblMember.strP1Phone,tblMember.strP2Phone,tblMember.intP1AssistAreaID,tblMember.intP2AssistAreaID,tblMember.intMedicalConditions,tblMember.intAllergies,tblMember.strMedicalNotes,tblMember.intAllowMedicalTreatment,tblMember.intConsentSignatureSighted,tblMember.dtCreatedOnline,tblMember.intCreatedFrom,tblMember.intFavNationalTeamMember,tblMember.intAttendSportCount,tblMember.intWatchSportHowOftenID,tblMember.strEmergContNo2,tblMember.strP1Salutation,tblMember.strP2Salutation,tblMember.intP1Gender,tblMember.intP2Gender,tblMember.strP1Phone2,tblMember.strP2Phone2,tblMember.strP1PhoneMobile,tblMember.strP2PhoneMobile,tblMember.strP1Email2,tblMember.strP2Email2,tblMember.intDefaulter,tblMember.intVolunteer,tblMember.strNatCustomStr9,tblMember.strNatCustomStr10,tblMember.strNatCustomStr11,tblMember.strNatCustomStr12,tblMember.strNatCustomStr13,tblMember.strNatCustomStr14,tblMember.strNatCustomStr15,tblMember.dblNatCustomDbl5,tblMember.dblNatCustomDbl6,tblMember.dblNatCustomDbl7,tblMember.dblNatCustomDbl8,tblMember.dblNatCustomDbl9,tblMember.dblNatCustomDbl10,tblMember.dtNatCustomDt3,tblMember.dtNatCustomDt4,tblMember.dtNatCustomDt5,tblMember.intNatCustomLU4,tblMember.intNatCustomLU5,tblMember.intNatCustomLU6,tblMember.intNatCustomLU7,tblMember.intNatCustomLU8,tblMember.intNatCustomLU9,tblMember.intNatCustomLU10,tblMember.intNatCustomBool1,tblMember.intNatCustomBool2,tblMember.intNatCustomBool3,tblMember.intNatCustomBool4,tblMember.intNatCustomBool5,tblMember.strPreferredName,tblMember.strEmail2,tblMember.strPreferredLang,tblMember.strPassportIssueCountry
INTO OUTFILE '/home/cchurchill/work/bball_aus_datadump/tblMembers.csv'
FIELDS TERMINATED BY '|'
ESCAPED BY '\\'
LINES TERMINATED BY '\r\n'
FROM tblMember 
INNER JOIN tblMember_Associations USING(intMemberID)       
INNER JOIN tblAssoc ON (tblAssoc.intAssocID = tblMember_Associations.intAssocID) 
WHERE tblAssoc.intRealmID = 13 
AND tblAssoc.intAssocTypeID = 6
);

-- tblMember_Associations.
(
SELECT 'intMemberAssociationID','intMemberID','intAssocID','tTimeStamp','intRecStatus','strCustomStr1','strCustomStr2','strCustomStr3','strCustomStr4','strCustomStr5','strCustomStr6','strCustomStr7','strCustomStr8','dblCustomDbl1','dblCustomDbl2','dblCustomDbl3','dblCustomDbl4','dtCustomDt1','dtCustomDt2','intCustomLU1','intCustomLU2','intCustomLU3','dtExpiry','intFinancialActive','intMemberPackageID','dtFirstRegistered','dtLastRegistered','curMemberFinBal','strLoyaltyNumber','intLifeMember','intMailingList','dtRegisteredUntil','strCustomStr9','strCustomStr10','strCustomStr11','strCustomStr12','strCustomStr13','strCustomStr14','strCustomStr15','dblCustomDbl5','dblCustomDbl6','dblCustomDbl7','dblCustomDbl8','dblCustomDbl9','dblCustomDbl10','intCustomLU4','intCustomLU5','intCustomLU6','intCustomLU7','intCustomLU8','intCustomLU9','intCustomLU10','intCustomBool1','intCustomBool2','intCustomBool3','intCustomBool4','intCustomBool5','dtCustomDt3','dtCustomDt4','dtCustomDt5'
)
UNION
(
SELECT 
tblMember_Associations.intMemberAssociationID,tblMember_Associations.intMemberID,tblMember_Associations.intAssocID,tblMember_Associations.tTimeStamp,tblMember_Associations.intRecStatus,tblMember_Associations.strCustomStr1,tblMember_Associations.strCustomStr2,tblMember_Associations.strCustomStr3,tblMember_Associations.strCustomStr4,tblMember_Associations.strCustomStr5,tblMember_Associations.strCustomStr6,tblMember_Associations.strCustomStr7,tblMember_Associations.strCustomStr8,tblMember_Associations.dblCustomDbl1,tblMember_Associations.dblCustomDbl2,tblMember_Associations.dblCustomDbl3,tblMember_Associations.dblCustomDbl4,tblMember_Associations.dtCustomDt1,tblMember_Associations.dtCustomDt2,tblMember_Associations.intCustomLU1,tblMember_Associations.intCustomLU2,tblMember_Associations.intCustomLU3,tblMember_Associations.dtExpiry,tblMember_Associations.intFinancialActive,tblMember_Associations.intMemberPackageID,tblMember_Associations.dtFirstRegistered,tblMember_Associations.dtLastRegistered,tblMember_Associations.curMemberFinBal,tblMember_Associations.strLoyaltyNumber,tblMember_Associations.intLifeMember,tblMember_Associations.intMailingList,tblMember_Associations.dtRegisteredUntil,tblMember_Associations.strCustomStr9,tblMember_Associations.strCustomStr10,tblMember_Associations.strCustomStr11,tblMember_Associations.strCustomStr12,tblMember_Associations.strCustomStr13,tblMember_Associations.strCustomStr14,tblMember_Associations.strCustomStr15,tblMember_Associations.dblCustomDbl5,tblMember_Associations.dblCustomDbl6,tblMember_Associations.dblCustomDbl7,tblMember_Associations.dblCustomDbl8,tblMember_Associations.dblCustomDbl9,tblMember_Associations.dblCustomDbl10,tblMember_Associations.intCustomLU4,tblMember_Associations.intCustomLU5,tblMember_Associations.intCustomLU6,tblMember_Associations.intCustomLU7,tblMember_Associations.intCustomLU8,tblMember_Associations.intCustomLU9,tblMember_Associations.intCustomLU10,tblMember_Associations.intCustomBool1,tblMember_Associations.intCustomBool2,tblMember_Associations.intCustomBool3,tblMember_Associations.intCustomBool4,tblMember_Associations.intCustomBool5,tblMember_Associations.dtCustomDt3,tblMember_Associations.dtCustomDt4,tblMember_Associations.dtCustomDt5
INTO OUTFILE '/home/cchurchill/work/bball_aus_datadump/tblMembers_Associations.csv'
FIELDS TERMINATED BY '|'
ESCAPED BY '\\'
LINES TERMINATED BY '\r\n'
FROM tblMember_Associations
INNER JOIN tblAssoc ON (tblAssoc.intAssocID = tblMember_Associations.intAssocID) 
WHERE tblAssoc.intRealmID = 13 
AND tblAssoc.intAssocTypeID = 6
);

-- tblMember_Clubs
(
SELECT 'intMemberClubID','intMemberID','intClubID','intGradeID','tTimeStamp','intStatus','intPermit','dtPermitStart','dtPermitEnd','strContractNo','strContractYear','intPrimaryClub','dtContractEntered' 
)
UNION
(
SELECT tblMember_Clubs.intMemberClubID,tblMember_Clubs.intMemberID,tblMember_Clubs.intClubID,tblMember_Clubs.intGradeID,tblMember_Clubs.tTimeStamp,tblMember_Clubs.intStatus,tblMember_Clubs.intPermit,tblMember_Clubs.dtPermitStart,tblMember_Clubs.dtPermitEnd,tblMember_Clubs.strContractNo,tblMember_Clubs.strContractYear,tblMember_Clubs.intPrimaryClub,tblMember_Clubs.dtContractEntered
INTO OUTFILE '/home/cchurchill/work/bball_aus_datadump/tblMember_Clubs.csv'
FIELDS TERMINATED BY '|'
ESCAPED BY '\\'
LINES TERMINATED BY '\r\n'
FROM tblMember_Clubs
INNER JOIN tblAssoc_Clubs ON (tblAssoc_Clubs.intClubID = tblMember_Clubs.intClubID)
INNER JOIN tblAssoc ON (tblAssoc.intAssocID = tblAssoc_Clubs.intAssocID) 
WHERE tblAssoc.intRealmID = 13 
AND tblAssoc.intAssocTypeID = 6
);


-- tblMember_Teams
(
SELECT 'intMemberTeamID','intMemberID','intTeamID','tTimeStamp','intStatus','intCompID','intMTFinancial'
)
UNION
(
SELECT tblMember_Teams.intMemberTeamID,tblMember_Teams.intMemberID,tblMember_Teams.intTeamID,tblMember_Teams.tTimeStamp,tblMember_Teams.intStatus,tblMember_Teams.intCompID,tblMember_Teams.intMTFinancial
INTO OUTFILE '/home/cchurchill/work/bball_aus_datadump/tblMember_Teams.csv'
FIELDS TERMINATED BY '|'
ESCAPED BY '\\'
LINES TERMINATED BY '\r\n'
FROM tblMember_Teams
INNER JOIN tblTeam ON (tblTeam.intTeamID = tblMember_Teams.intTeamID)
INNER JOIN tblAssoc ON (tblAssoc.intAssocID = tblTeam.intAssocID) 
WHERE tblAssoc.intRealmID = 13 
AND tblAssoc.intAssocTypeID = 6
);


-- tblAssoc_Comps
(
SELECT 'intCompID','intAssocID','strTitle','strAbbrev','intCompGender','intGradeID','intCompTypeID','strAgeLevel','dtStart','strContact','intStatus','intCompLevelID','tTimeStamp','intRecStatus','intStarted','intNumTeams','intAgeGroupID','intNewSeasonID','strCompAltName','strCompGrouping','dtMaxDOB','dtMinDOB','tmDefaultStartTime','intNumFinalsEligibility','intOrder','intMatchInterval','intUpload','intNumRounds','intMatchDuration','dtFixtureLastTouched','dtLadderLastTouched','dtResultsLastTouched','strCompNotes','intPercentageOfVenue','intVenueRequiredMins','strCompLogo','intMon','intTue','intWed','intThu','intFri','intSat','intSun'
)
UNION
(
SELECT tblAssoc_Comp.intCompID,tblAssoc_Comp.intAssocID,tblAssoc_Comp.strTitle,tblAssoc_Comp.strAbbrev,tblAssoc_Comp.intCompGender,tblAssoc_Comp.intGradeID,tblAssoc_Comp.intCompTypeID,tblAssoc_Comp.strAgeLevel,tblAssoc_Comp.dtStart,tblAssoc_Comp.strContact,tblAssoc_Comp.intStatus,tblAssoc_Comp.intCompLevelID,tblAssoc_Comp.tTimeStamp,tblAssoc_Comp.intRecStatus,tblAssoc_Comp.intStarted,tblAssoc_Comp.intNumTeams,tblAssoc_Comp.intAgeGroupID,tblAssoc_Comp.intNewSeasonID,tblAssoc_Comp.strCompAltName,tblAssoc_Comp.strCompGrouping,tblAssoc_Comp.dtMaxDOB,tblAssoc_Comp.dtMinDOB,tblAssoc_Comp.tmDefaultStartTime,tblAssoc_Comp.intNumFinalsEligibility,tblAssoc_Comp.intOrder,tblAssoc_Comp.intMatchInterval,tblAssoc_Comp.intUpload,tblAssoc_Comp.intNumRounds,tblAssoc_Comp.intMatchDuration,tblAssoc_Comp.dtFixtureLastTouched,tblAssoc_Comp.dtLadderLastTouched,tblAssoc_Comp.dtResultsLastTouched,tblAssoc_Comp.strCompNotes,tblAssoc_Comp.intPercentageOfVenue,tblAssoc_Comp.intVenueRequiredMins,tblAssoc_Comp.strCompLogo,tblAssoc_Comp.intMon,tblAssoc_Comp.intTue,tblAssoc_Comp.intWed,tblAssoc_Comp.intThu,tblAssoc_Comp.intFri,tblAssoc_Comp.intSat,tblAssoc_Comp.intSun
INTO OUTFILE '/home/cchurchill/work/bball_aus_datadump/tblAssoc_Comps.csv'
FIELDS TERMINATED BY '|'
ESCAPED BY '\\'
LINES TERMINATED BY '\r\n'
FROM tblAssoc_Comp
INNER JOIN tblAssoc ON (tblAssoc.intAssocID = tblAssoc_Comp.intAssocID) 
WHERE tblAssoc.intRealmID = 13 
AND tblAssoc.intAssocTypeID = 6
);

-- tblAssoc
(
SELECT 'intAssocID','strName','strContact','strManager','strSecretary','strPresident','strAddress1','strAddress2','strAddress3','strSuburb','strState','strPostalCode','strPhone','strFax','strEmail','dtRegistered','strAssocNo','strCountry','tTimeStamp','intRecStatus','strColours','strNotes','dtExpiry','strIncNo','strBusinessNo','strGroundName','strGroundAddress','strGroundSuburb','strGroundPostalCode','intCurrentSeasonID','intNewRegoSeasonID','strLGA','dtUpdated'
)
UNION
(
SELECT tblAssoc.intAssocID,tblAssoc.strName,tblAssoc.strContact,tblAssoc.strManager,tblAssoc.strSecretary,tblAssoc.strPresident,tblAssoc.strAddress1,tblAssoc.strAddress2,tblAssoc.strAddress3,tblAssoc.strSuburb,tblAssoc.strState,tblAssoc.strPostalCode,tblAssoc.strPhone,tblAssoc.strFax,tblAssoc.strEmail,tblAssoc.dtRegistered,tblAssoc.strAssocNo,tblAssoc.strCountry,tblAssoc.tTimeStamp,tblAssoc.intRecStatus,tblAssoc.strColours,REPLACE(tblAssoc.strNotes , CHR(13), '\CR\LF') as tblAssoc.strNotes,tblAssoc.dtExpiry,tblAssoc.strIncNo,tblAssoc.strBusinessNo,tblAssoc.strGroundName,tblAssoc.strGroundAddress,tblAssoc.strGroundSuburb,tblAssoc.strGroundPostalCode,tblAssoc.intCurrentSeasonID,tblAssoc.intNewRegoSeasonID,tblAssoc.strLGA,tblAssoc.dtUpdated
INTO OUTFILE '/home/cchurchill/work/bball_aus_datadump/tblAssoc.csv'
FIELDS TERMINATED BY '|'
ESCAPED BY '\\'
LINES TERMINATED BY '\r\n'
FROM tblAssoc
WHERE tblAssoc.intRealmID = 13 
AND tblAssoc.intAssocTypeID = 6
);



-- tblClub
(
SELECT 'intClubID','strName','strAbbrev','strClubNo','strContact','strAddress1','strAddress2','strSuburb','strPostalCode','strState','strPhone','strFax','strEmail','strExtKey','strCountry','tTimeStamp','intRecStatus','strIncNo','strBusinessNo','intAgeTypeID','intClubTypeID','strGroundName','strGroundAddress','strGroundSuburb','strGroundPostalCode','strColours','strNotes','strContactTitle','strContactTitle2','strContactName2','strContactEmail2','strContactPhone2','strContactTitle3','strContactName3','strContactEmail3','strContactPhone3','strClubCustomStr1','strClubCustomStr2','strClubCustomStr3','strClubCustomStr4','strClubCustomStr5','strClubCustomStr6','strClubCustomStr7','strClubCustomStr8','strClubCustomStr9','strClubCustomStr10','strClubCustomStr11','strClubCustomStr12','strClubCustomStr13','strClubCustomStr14','strClubCustomStr15','dblClubCustomDbl1','dblClubCustomDbl2','dblClubCustomDbl3','dblClubCustomDbl4','dblClubCustomDbl5','dblClubCustomDbl6','dblClubCustomDbl7','dblClubCustomDbl8','dblClubCustomDbl9','dblClubCustomDbl10','dtClubCustomDt1','dtClubCustomDt2','dtClubCustomDt3','dtClubCustomDt4','dtClubCustomDt5','intClubCustomLU1','intClubCustomLU2','intClubCustomLU3','intClubCustomLU4','intClubCustomLU5','intClubCustomLU6','intClubCustomLU7','intClubCustomLU8','intClubCustomLU9','intClubCustomLU10','intClubCustomBool1','intClubCustomBool2','intClubCustomBool3','intClubCustomBool4','intClubCustomBool5','strWebURL','strLGA','dtUpdated','strDevelRegion','strClubZone'
)
UNION
(
SELECT tblClub.intClubID,tblClub.strName,tblClub.strAbbrev,tblClub.strClubNo,tblClub.strContact,tblClub.strAddress1,tblClub.strAddress2,tblClub.strSuburb,tblClub.strPostalCode,tblClub.strState,tblClub.strPhone,tblClub.strFax,tblClub.strEmail,tblClub.strExtKey,tblClub.strCountry,tblClub.tTimeStamp,tblClub.intRecStatus,tblClub.strIncNo,tblClub.strBusinessNo,tblClub.intAgeTypeID,tblClub.intClubTypeID,tblClub.strGroundName,tblClub.strGroundAddress,tblClub.strGroundSuburb,tblClub.strGroundPostalCode,tblClub.strColours,tblClub.strNotes,tblClub.strContactTitle,tblClub.strContactTitle2,tblClub.strContactName2,tblClub.strContactEmail2,tblClub.strContactPhone2,tblClub.strContactTitle3,tblClub.strContactName3,tblClub.strContactEmail3,tblClub.strContactPhone3,tblClub.strClubCustomStr1,tblClub.strClubCustomStr2,tblClub.strClubCustomStr3,tblClub.strClubCustomStr4,tblClub.strClubCustomStr5,tblClub.strClubCustomStr6,tblClub.strClubCustomStr7,tblClub.strClubCustomStr8,tblClub.strClubCustomStr9,tblClub.strClubCustomStr10,tblClub.strClubCustomStr11,tblClub.strClubCustomStr12,tblClub.strClubCustomStr13,tblClub.strClubCustomStr14,tblClub.strClubCustomStr15,tblClub.dblClubCustomDbl1,tblClub.dblClubCustomDbl2,tblClub.dblClubCustomDbl3,tblClub.dblClubCustomDbl4,tblClub.dblClubCustomDbl5,tblClub.dblClubCustomDbl6,tblClub.dblClubCustomDbl7,tblClub.dblClubCustomDbl8,tblClub.dblClubCustomDbl9,tblClub.dblClubCustomDbl10,tblClub.dtClubCustomDt1,tblClub.dtClubCustomDt2,tblClub.dtClubCustomDt3,tblClub.dtClubCustomDt4,tblClub.dtClubCustomDt5,tblClub.intClubCustomLU1,tblClub.intClubCustomLU2,tblClub.intClubCustomLU3,tblClub.intClubCustomLU4,tblClub.intClubCustomLU5,tblClub.intClubCustomLU6,tblClub.intClubCustomLU7,tblClub.intClubCustomLU8,tblClub.intClubCustomLU9,tblClub.intClubCustomLU10,tblClub.intClubCustomBool1,tblClub.intClubCustomBool2,tblClub.intClubCustomBool3,tblClub.intClubCustomBool4,tblClub.intClubCustomBool5,tblClub.strWebURL,tblClub.strLGA,tblClub.dtUpdated,tblClub.strDevelRegion,tblClub.strClubZone
INTO OUTFILE '/home/cchurchill/work/bball_aus_datadump/tblClub.csv'
FIELDS TERMINATED BY '|'
ESCAPED BY '\\'
LINES TERMINATED BY '\r\n'
FROM tblClub
INNER JOIN tblAssoc_Clubs ON (tblAssoc_Clubs.intClubID = tblClub.intClubID)
INNER JOIN tblAssoc ON (tblAssoc.intAssocID = tblAssoc_Clubs.intAssocID) 
WHERE tblAssoc.intRealmID = 13 
AND tblAssoc.intAssocTypeID = 6
);


-- tblTeam
(
SELECT 'intTeamID','strTeamNo','intClubID','strName','strContact','strAddress1','strAddress2','strSuburb','strPostalCode','strState','strPhone1','strPhone2','strEmail','strExtKey','strNickname','dtRegistered','strCountry','tTimeStamp','intAssocID','dtExpiry','intRecStatus','strContactTitle','strContactTitle2','strContactName2','strContactEmail2','strContactPhone2','strContactTitle3','strContactName3','strContactEmail3','strContactPhone3','intTeamCreatedFrom','dtTeamCreatedOnline','strTeamCustomStr1','strTeamCustomStr2','strTeamCustomStr3','strTeamCustomStr4','strTeamCustomStr5','strTeamCustomStr6','strTeamCustomStr7','strTeamCustomStr8','strTeamCustomStr9','strTeamCustomStr10','strTeamCustomStr11','strTeamCustomStr12','strTeamCustomStr13','strTeamCustomStr14','strTeamCustomStr15','dblTeamCustomDbl1','dblTeamCustomDbl2','dblTeamCustomDbl3','dblTeamCustomDbl4','dblTeamCustomDbl5','dblTeamCustomDbl6','dblTeamCustomDbl7','dblTeamCustomDbl8','dblTeamCustomDbl9','dblTeamCustomDbl10','dtTeamCustomDt1','dtTeamCustomDt2','dtTeamCustomDt3','dtTeamCustomDt4','dtTeamCustomDt5','intTeamCustomLU1','intTeamCustomLU2','intTeamCustomLU3','intTeamCustomLU4','intTeamCustomLU5','intTeamCustomLU6','intTeamCustomLU7','intTeamCustomLU8','intTeamCustomLU9','intTeamCustomLU10','intTeamCustomBool1','intTeamCustomBool2','intTeamCustomBool3','intTeamCustomBool4','intTeamCustomBool5','strWebURL','strUniformTopColour','strUniformBottomColour','strUniformNumber','strAltUniformTopColour','strAltUniformBottomColour','strAltUniformNumber','strTeamNotes','strLadderName','intVenue1ID','intVenue2ID','intVenue3ID','dtStartTime1','dtStartTime2','dtStartTime3'
)
UNION
(
SELECT 
tblTeam.intTeamID,tblTeam.strTeamNo,tblTeam.intClubID,tblTeam. strName,tblTeam.strContact,tblTeam.strAddress1,tblTeam.strAddress2,tblTeam.strSuburb,tblTeam.strPostalCode,tblTeam.strState,tblTeam.strPhone1,tblTeam.strPhone2,tblTeam.strEmail,tblTeam.strExtKey,tblTeam.strNickname,tblTeam.dtRegistered,tblTeam.strCountry,tblTeam.tTimeStamp,tblTeam.intAssocID,tblTeam.dtExpiry,tblTeam.intRecStatus,tblTeam.strContactTitle,tblTeam.strContactTitle2,tblTeam.strContactName2,tblTeam.strContactEmail2,tblTeam.strContactPhone2,tblTeam.strContactTitle3,tblTeam.strContactName3,tblTeam.strContactEmail3,tblTeam.strContactPhone3,tblTeam.intTeamCreatedFrom,tblTeam.dtTeamCreatedOnline,tblTeam.strTeamCustomStr1,tblTeam.strTeamCustomStr2,tblTeam.strTeamCustomStr3,tblTeam.strTeamCustomStr4,tblTeam.strTeamCustomStr5,tblTeam.strTeamCustomStr6,tblTeam.strTeamCustomStr7,tblTeam.strTeamCustomStr8,tblTeam.strTeamCustomStr9,tblTeam.strTeamCustomStr10,tblTeam.strTeamCustomStr11,tblTeam.strTeamCustomStr12,tblTeam.strTeamCustomStr13,tblTeam.strTeamCustomStr14,tblTeam.strTeamCustomStr15,tblTeam.dblTeamCustomDbl1,tblTeam.dblTeamCustomDbl2,tblTeam.dblTeamCustomDbl3,tblTeam.dblTeamCustomDbl4,tblTeam.dblTeamCustomDbl5,tblTeam.dblTeamCustomDbl6,tblTeam.dblTeamCustomDbl7,tblTeam.dblTeamCustomDbl8,tblTeam.dblTeamCustomDbl9,tblTeam.dblTeamCustomDbl10,tblTeam.dtTeamCustomDt1,tblTeam.dtTeamCustomDt2,tblTeam.dtTeamCustomDt3,tblTeam.dtTeamCustomDt4,tblTeam.dtTeamCustomDt5,tblTeam.intTeamCustomLU1,tblTeam.intTeamCustomLU2,tblTeam.intTeamCustomLU3,tblTeam.intTeamCustomLU4,tblTeam.intTeamCustomLU5,tblTeam.intTeamCustomLU6,tblTeam.intTeamCustomLU7,tblTeam.intTeamCustomLU8,tblTeam.intTeamCustomLU9,tblTeam.intTeamCustomLU10,tblTeam.intTeamCustomBool1,tblTeam.intTeamCustomBool2,tblTeam.intTeamCustomBool3,tblTeam.intTeamCustomBool4,tblTeam.intTeamCustomBool5,tblTeam.strWebURL,tblTeam.strUniformTopColour,tblTeam.strUniformBottomColour,tblTeam.strUniformNumber,tblTeam.strAltUniformTopColour,tblTeam.strAltUniformBottomColour,tblTeam.strAltUniformNumber,tblTeam.strTeamNotes,tblTeam.strLadderName,tblTeam.intVenue1ID,tblTeam.intVenue2ID,tblTeam.intVenue3ID,tblTeam.dtStartTime1,tblTeam.dtStartTime2,tblTeam.dtStartTime3
INTO OUTFILE '/home/cchurchill/work/bball_aus_datadump/tblTeam.csv'
FIELDS TERMINATED BY '|'
ESCAPED BY '\\'
LINES TERMINATED BY '\r\n'
FROM tblTeam
INNER JOIN tblAssoc ON (tblAssoc.intAssocID = tblTeam.intAssocID) 
WHERE tblAssoc.intRealmID = 13 
AND tblAssoc.intAssocTypeID = 6
);


-- tblMember_Seasons
(
SELECT 'intMemberSeasonID','intMemberID','intAssocID','intClubID','intSeasonID','intMSRecStatus','intSeasonMemberPackageID','intPlayerAgeGroupID','intPlayerStatus','intPlayerFinancialStatus','intCoachStatus','intCoachFinancialStatus','intUmpireStatus','intUmpireFinancialStatus','intOther1Status','intOther1FinancialStatus','intOther2Status','intOther2FinancialStatus','dtInPlayer','dtOutPlayer','dtInCoach','dtOutCoach','dtInUmpire','dtOutUmpire','dtInOther1','dtOutOther1','dtInOther2','dtOutOther2','tTimeStamp','intUsedRegoForm','dtLastUsedRegoForm','intUsedRegoFormID'
)
UNION
(
SELECT tblMember_Seasons_13.intMemberSeasonID,tblMember_Seasons_13.intMemberID,tblMember_Seasons_13.intAssocID,tblMember_Seasons_13.intClubID,tblMember_Seasons_13.intSeasonID,tblMember_Seasons_13.intMSRecStatus,tblMember_Seasons_13.intSeasonMemberPackageID,tblMember_Seasons_13.intPlayerAgeGroupID,tblMember_Seasons_13.intPlayerStatus,tblMember_Seasons_13.intPlayerFinancialStatus,tblMember_Seasons_13.intCoachStatus,tblMember_Seasons_13.intCoachFinancialStatus,tblMember_Seasons_13.intUmpireStatus,tblMember_Seasons_13.intUmpireFinancialStatus,tblMember_Seasons_13.intOther1Status,tblMember_Seasons_13.intOther1FinancialStatus,tblMember_Seasons_13.intOther2Status,tblMember_Seasons_13.intOther2FinancialStatus,tblMember_Seasons_13.dtInPlayer,tblMember_Seasons_13.dtOutPlayer,tblMember_Seasons_13.dtInCoach,tblMember_Seasons_13.dtOutCoach,tblMember_Seasons_13.dtInUmpire,tblMember_Seasons_13.dtOutUmpire,tblMember_Seasons_13.dtInOther1,tblMember_Seasons_13.dtOutOther1,tblMember_Seasons_13.dtInOther2,tblMember_Seasons_13.dtOutOther2,tblMember_Seasons_13.tTimeStamp,tblMember_Seasons_13.intUsedRegoForm,tblMember_Seasons_13.dtLastUsedRegoForm,tblMember_Seasons_13.intUsedRegoFormID
INTO OUTFILE '/home/cchurchill/work/bball_aus_datadump/tblMember_Seasons.csv'
FIELDS TERMINATED BY '|'
ESCAPED BY '\\'
LINES TERMINATED BY '\r\n'
FROM tblMember_Seasons_13
INNER JOIN tblAssoc ON (tblAssoc.intAssocID = tblMember_Seasons_13.intAssocID)
WHERE tblAssoc.intRealmID = 13 
AND tblAssoc.intAssocTypeID = 6
);


-- tblSeasons

(
SELECT 'intSeasonID','intAssocID','strSeasonName','intSeasonOrder','intArchiveSeason','dtAdded','tTimeStamp','intLocked' 
)
UNION
(
SELECT intSeasonID,intAssocID,strSeasonName,intSeasonOrder,intArchiveSeason,dtAdded,tTimeStamp,intLocked 
INTO OUTFILE '/home/cchurchill/work/bball_aus_datadump/tblSeasons.csv'
FIELDS TERMINATED BY '|'
ESCAPED BY '\\'
LINES TERMINATED BY '\r\n'
FROM tblSeasons
WHERE tblSeasons.intRealmID = 13 
AND tblSeasons.intRealmSubTypeID = 6
);


-- tblComp_Teams

(
SELECT 'intCompNO','intCompID','intTeamID','tTimeStamp','intRecStatus','intTeamFinancial','intTeamNum' 
)
UNION
(
SELECT tblComp_Teams.intCompNO,tblComp_Teams.intCompID,tblComp_Teams.intTeamID,tblComp_Teams.tTimeStamp,tblComp_Teams.intRecStatus,tblComp_Teams.intTeamFinancial,tblComp_Teams.intTeamNum 
INTO OUTFILE '/home/cchurchill/work/bball_aus_datadump/tblComp_Teams.csv'
FIELDS TERMINATED BY '|'
ESCAPED BY '\\'
LINES TERMINATED BY '\r\n'
FROM tblComp_Teams
INNER JOIN tblAssoc_Comp ON (tblAssoc_Comp.intCompID = tblComp_Teams.intCompID)
INNER JOIN tblAssoc ON (tblAssoc.intAssocID = tblAssoc_Comp.intAssocID)
WHERE tblAssoc.intRealmID = 13 
AND tblAssoc.intAssocTypeID = 6
);


-- tblMember_Types;
(
SELECT 'intMemberTypeID','intMemberID','intTypeID','intSubTypeID','intActive','strString1','strString2','strString3','strString4','strString5','strString6','intInt1','intInt2','intInt3','intInt4','intInt5','intInt6','intInt7','intInt8','intInt9','intInt10','dtDate1','dtDate2','tTimeStamp','intAssocID','intRecStatus','dtDate3'
)
UNION
(
SELECT tblMember_Types.intMemberTypeID,tblMember_Types.intMemberID,tblMember_Types.intTypeID,tblMember_Types.intSubTypeID,tblMember_Types.intActive,tblMember_Types.strString1,tblMember_Types.strString2,tblMember_Types.strString3,tblMember_Types.strString4,tblMember_Types.strString5,tblMember_Types.strString6,tblMember_Types.intInt1,tblMember_Types.intInt2,tblMember_Types.intInt3,tblMember_Types.intInt4,tblMember_Types.intInt5,tblMember_Types.intInt6,tblMember_Types.intInt7,tblMember_Types.intInt8,tblMember_Types.intInt9,tblMember_Types.intInt10,tblMember_Types.dtDate1,tblMember_Types.dtDate2,tblMember_Types.tTimeStamp,tblMember_Types.intAssocID,tblMember_Types.intRecStatus,tblMember_Types.dtDate3
INTO OUTFILE '/home/cchurchill/work/bball_aus_datadump/tblMember_Types.csv'
FIELDS TERMINATED BY '|'
ESCAPED BY '\\'
LINES TERMINATED BY '\r\n'
FROM tblMember_Types
INNER JOIN tblAssoc ON (tblAssoc.intAssocID = tblMember_Types.intAssocID)
WHERE tblAssoc.intRealmID = 13 
AND tblAssoc.intAssocTypeID = 6
);





