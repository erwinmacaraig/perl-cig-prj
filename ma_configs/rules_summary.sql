SELECT 
    M.strPersonType, 
    M.strPersonLevel, 
    M.strSport, 
    M.strAgeLevel, 
    M.strRegistrationNature, 
    M.intOriginLevel, 
    M.intEntityLevel, 
    R.strISOCountry_IN, 
    R.strISOCountry_NOTIN, 
    R.intApprovalEntityLevel, 
    R.intProblemResolutionEntityLevel, 
    R.intAutoActivateOnPayment, 
    R.intUsingPersonLevelChangeFilter, 
    R.intPersonLevelChange, 
    R.intWFRuleID 
FROM 
    tblMatrix as M 
    LEFT JOIN tblWFRule as R ON (
        R.strPersonType=M.strPersonType 
        AND R.strSport = M.strSport 
        AND R.strAgeLevel=M.strAgeLevel 
        AND R.intOriginLevel=M.intOriginLevel 
        AND R.intEntityLevel=M.intEntityLevel 
        AND R.strRegistrationNature=M.strRegistrationNature 
        AND R.intRealmID=1
    ) 
WHERE 
    M.intRealmID=1 
    AND M.strPersonType = 'PLAYER' 
    AND M.strWFRuleFor <> 'BULKREGO' 
    AND M.intOriginLevel>=M.intEntityLevel
    AND M.intEntityLevel > 0;
