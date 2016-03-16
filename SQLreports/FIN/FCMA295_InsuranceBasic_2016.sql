SELECT DISTINCT
    tblPerson.strNationalNum,
    tblPerson.strLocalFirstname,
    tblPerson.strLocalSurname,
    tblPerson.strEmail,
    NP.strNationalPeriodName,
    P.strName,
    P.strDisplayName,
    P.strProductType,
    TX.curAmount as LineItemAmount,
    TX.dtTransaction as TXOrderDate,
	CASE TX.intStatus
                WHEN '1' THEN 'Paid'
                WHEN '0' THEN 'Unpaid'
                WHEN '3' THEN 'On Hold'
                WHEN '2' THEN 'Cancelled'
                WHEN '-1' THEN 'Error'
                ELSE ''
            END as TransStatus,
    TL.strTXN,
    TL.strOnlinePayReference,
    TL.dtLog as PaymentDate
        FROM

            tblPerson
            INNER JOIN tblPersonRegistration_1 as PR ON (
                tblPerson.intPersonID=PR.intPersonID
            )
            LEFT JOIN tblTransactions AS TX ON (
                TX.intPersonRegistrationID = PR.intPersonRegistrationID
                AND tblPerson.intPersonID=TX.intID 
                AND TX.intTableType =1 
            ) 
            LEFT JOIN tblTransLog as TL ON (TL.intLogID = TX.intTransLogID)
            LEFT JOIN tblProducts as P ON (P.intProductID=TX.intProductID)
            LEFT JOIN tblTempEntityStructure as TempEnt ON (TempEnt.intChildID=PR.intEntityID)
            LEFT JOIN tblNationalPeriod as NP ON (NP.intNationalPeriodID = PR.intNationalPeriodID)
        WHERE
            tblPerson.strStatus = 'REGISTERED'   
            AND PR.intNationalPeriodID=121
            AND P.strProductType = 'Insurance'
