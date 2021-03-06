SELECT 
    tblPerson.strPostalCode AS strPostalCode, 
    tblPerson.strAddress2 AS strAddress2, 
    TX.dtEnd AS dtEnd, 
    P.strDisplayName,
    strLocalSurname, 
    intTransactionID, 
    tblRegion.strLocalName AS strRegionName, 
    IF(intGender=1, 'Male', IF(intGender=2, 'Female', '')) as gender,
	CASE TX.intStatus
                WHEN '1' THEN 'Paid'
                WHEN '0' THEN 'Unpaid'
                WHEN '3' THEN 'On Hold'
                WHEN '2' THEN 'Cancelled'
                WHEN '-1' THEN 'Error'
                ELSE ''
            END as TransStatus,
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
    TX.dtPaid AS dtPaid, 
    TX.dtTransaction as TXOrderDate,
    UCASE(strISONationality) AS strISONationality, 
    TX.dtStart AS dtStart, 
    strOtherPersonIdentifier, 
    tblPerson.strSuburb AS strSuburb, 
    tblPerson.strAddress1 AS strAddress1, 
    tblPerson.strISOCountry AS strISOCountry, 
    tblPerson.dtDOB AS dtDOB, 
    curAmount, 
    strLocalFirstname, 
    tblClub.strLocalName AS strClubName, 
    strNationalNum
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
                TX.intPersonRegistrationID = PR.intPersonRegistrationID
                AND tblPerson.intPersonID=TX.intID 
                AND TX.intTableType =1 
            ) 
            LEFT JOIN tblTransLog as TL ON (TL.intLogID = TX.intTransLogID)
            LEFT JOIN tblProducts as P ON (P.intProductID=TX.intProductID)
            LEFT JOIN tblTempEntityStructure as TempEnt ON (TempEnt.intChildID=PR.intEntityID)
        WHERE
            tblPerson.strStatus = 'REGISTERED'   
            AND P.strProductType='Insurance' 
            AND PR.intNationalPeriodID = 121
            AND TempEnt.intParentID = 1
            AND P.intProductNationalPeriodID= 121
