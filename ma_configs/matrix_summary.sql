SELECT 
    R.intWFRuleID, 
    R.strRegistrationNature, 
    R.intOriginLevel, 
    R.intEntityLevel, 
    R.strPersonLevel, 
    R.strAgeLevel,
    R.strPersonType, 
    R.strSport 
FROM 
    tblWFRule as R 
    LEFT JOIN tblMatrix as M ON (
        R.strPersonType=M.strPersonType 
        AND R.strSport=M.strSport 
        AND R.intOriginLevel=M.intOriginLevel 
        AND R.intEntityLevel=M.intEntityLevel 
        AND R.strAgeLevel=M.strAgeLevel 
        AND R.strRegistrationNature=M.strRegistrationNature 
        AND M.intRealmID=1 
        AND R.strPersonLevel=M.strPersonLevel
        AND M.strWFRuleFor <> 'BULKREGO'
    ) 
WHERE 
    R.intRealmID=1 
    AND M.intMatrixID IS NULL 
    AND R.strWFRuleFor='REGO';
