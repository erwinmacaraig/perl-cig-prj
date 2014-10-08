INSERT INTO tblProducts(
    strName,
    curDefaultAmount,
    intMinChangeLevel,
    intMinSellLevel,
    intCreatedLevel,
    intCreatedID,
    intEntityID,
    intRealmID,
    intAssocUnique,
    strGSTText,
    intAllowMultiPurchase,
    intMandatoryProductID,
    strGroup,
    strProductNotes,
    intInactive,
    intAllowQtys,
    intProductGender,
    intSetMemberActive,
    intSetMemberFinancial,
    intProductExpiryDays,
    intMemberExpiryDays,
    dtProductExpiry,
    dtMemberExpiry,
    intProductMemberPackageID,
    intPaymentSplitID,
    intProductType,
    intIsEvent,
    intProductSubRealmID,
    intSeasonPlayerFinancial,
    intSeasonCoachFinancial,
    intSeasonUmpireFinancial,
    intSeasonOther1Financial,
    intSeasonOther2Financial,
    intSeasonMemberPackageID,
    intProductNationalPeriodID,
    dtDateAvailableFrom,
    dtDateAvailableTo,
    strLMSCourseID,
    intMatchCreditsPerQty,
    intMatchCreditType,
    intPhoto,
    intCanResetPaymentRequired,
    strNationality_IN,
    strNationality_NOTIN,
    strProductCode,
    strProductType
)
SELECT
    "Transfer Fee",
    curDefaultAmount,
    intMinChangeLevel,
    intMinSellLevel,
    intCreatedLevel,
    intCreatedID,
    intEntityID,
    intRealmID,
    intAssocUnique,
    strGSTText,
    intAllowMultiPurchase,
    intMandatoryProductID,
    strGroup,
    strProductNotes,
    intInactive,
    intAllowQtys,
    intProductGender,
    intSetMemberActive,
    intSetMemberFinancial,
    intProductExpiryDays,
    intMemberExpiryDays,
    dtProductExpiry,
    dtMemberExpiry,
    intProductMemberPackageID,
    intPaymentSplitID,
    intProductType,
    intIsEvent,
    intProductSubRealmID,
    intSeasonPlayerFinancial,
    intSeasonCoachFinancial,
    intSeasonUmpireFinancial,
    intSeasonOther1Financial,
    intSeasonOther2Financial,
    intSeasonMemberPackageID,
    intProductNationalPeriodID,
    dtDateAvailableFrom,
    dtDateAvailableTo,
    strLMSCourseID,
    intMatchCreditsPerQty,
    intMatchCreditType,
    intPhoto,
    intCanResetPaymentRequired,
    strNationality_IN,
    strNationality_NOTIN,
    strProductCode,
    strProductType
FROM 
tblProducts
WHERE
    intProductID = 2
