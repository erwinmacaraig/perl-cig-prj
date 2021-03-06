SELECT 
    DISTINCT 
    tblClub.intEntityID as ClubId,
    tblClub.strMAID as ClubMAID,
    UCASE(strISONationality) AS strISONationality, 
	CASE PR.strSport
                WHEN 'FOOTBALL' THEN 'Football'
                WHEN 'FUTSAL' THEN 'Futsal'
                ELSE ''
            END as Sport,

    PR.dtTo AS PRdtTo, 
    strLocalSurname, 
    tblRegion.strLocalName AS strRegionName, 
    tblPerson.dtDOB AS dtDOB, 
  IF(intGender=1, 'Male', IF(intGender=2, 'Female', '')) as gender,
	CASE PR.strPersonLevel
                WHEN 'PROFESSIONAL' THEN 'Professional'
                WHEN 'AMATEUR' THEN 'Amateur'
                WHEN 'HOBBY' THEN 'Hobby'
                WHEN 'AMATEUR_U_C' THEN 'Amateur (Under Contract)'
                ELSE ''
            END as PersonLevel,
    PR.dtFrom AS PRdtFrom, 
    strLocalFirstname, 
    tblClub.strLocalName AS strClubName, 
    strNationalNum,
    TX.dtPaid AS dtPaid
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
            LEFT JOIN tblTransactions AS TX ON (
                TX.intStatus = 1 
                AND tblPerson.intPersonID=TX.intID 
                AND TX.intTableType =1 
                AND TX.intPersonRegistrationID = PR.intPersonRegistrationID
            ) 
            LEFT JOIN tblProducts as P ON (P.intProductID=TX.intProductID and P.strProductType LIKE '%pass' and P.intProductNationalPeriodID = 121)
            LEFT JOIN tblTempEntityStructure as TempEnt ON (TempEnt.intChildID=PR.intEntityID)
        WHERE
            PR.strPersonType = 'PLAYER'  AND  PR.strStatus = 'ACTIVE'  AND  PR.intNationalPeriodID = '121'
            AND TempEnt.intParentID = 1
            AND (
                TX.intTransactionID IS NULL 
                OR P.intProductID>0
            )
