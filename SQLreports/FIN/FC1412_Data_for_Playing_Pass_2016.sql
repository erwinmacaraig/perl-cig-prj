SELECT 
    tblPerson.strPostalCode AS strPostalCode, 
    strPhoneHome, 
    tblPerson.strAddress2 AS strAddress2, 
	'ACTIVE' as PRStatus,
    strLocalSurname, 
    tblRegion.strLocalName AS strRegionName, 
    IF(intGender=1, 'Male', IF(intGender=2, 'Female', '')) as gender,
CASE PR.strPersonType
                WHEN 'PLAYER' THEN 'Player'
                WHEN 'COACH' THEN 'Coach'
                WHEN 'REFEREE' THEN 'Referee'
                WHEN 'MAOFFICIAL' THEN 'MA Official'
                WHEN 'RAOFFICIAL' THEN 'RA Official'
                WHEN 'CLUBOFFICIAL' THEN 'Club Official'
                WHEN 'TEAMOFFICIAL' THEN 'Team Official'
                ELSE ''
            END as PersonType,
	CASE PR.strSport
                WHEN 'FOOTBALL' THEN 'Football'
                WHEN 'FUTSAL' THEN 'Futsal'
                ELSE ''
            END as Sport,
    tblPerson.strSuburb AS strSuburb, 
    tblPerson.strAddress1 AS strAddress1, 
    tblPerson.strISOCountry AS strISOCountry, 
    tblPerson.strEmail AS strEmail, 
	CASE PR.strPersonLevel
                WHEN 'PROFESSIONAL' THEN 'Professional'
                WHEN 'AMATEUR' THEN 'Amateur'
                WHEN 'HOBBY' THEN 'Hobby'
                WHEN 'AMATEUR_U_C' THEN 'Amateur (Under Contract)'
                ELSE ''
            END as PersonLevel,
    tblPerson.dtDOB AS dtDOB, 
    strLocalFirstname, 
    strNationalNum, 
    tblClub.strLocalName AS strClubName
FROM

            tblPerson
            INNER JOIN tblPersonRegistration_1 as PR ON (
                tblPerson.intPersonID=PR.intPersonID
            )
            INNER JOIN tblEntity as E ON (
                E.intEntityID = PR.intEntityID
            )
            LEFT JOIN tblEntity as tblClub ON (
                PR.intEntityID = tblClub.intEntityID
                AND tblClub.intEntityLevel = 3
            )
            LEFT JOIN tblTempEntityStructure as RL ON (
                E.intEntityID = RL.intChildID
                AND RL.intParentLevel = 20
            )
            LEFT JOIN tblEntity as tblRegion ON (
                RL.intParentID = tblRegion.intEntityID
            )
            LEFT JOIN tblTempEntityStructure as TempEnt ON (TempEnt.intChildID=PR.intEntityID)
        WHERE
            tblPerson.strStatus = 'REGISTERED'  AND PR.strPersonType = 'PLAYER'  AND  PR.strStatus = 'ACTIVE'
            AND (
                TempEnt.intParentID = 1
                OR E.intEntityLevel=100
            )
