CREATE OR REPLACE VIEW viewEntity (intEntityTypeID, strEntityTypeName, intEntityID, intRealmID, intSubRealmID, strEntityName) AS 
    SELECT 3, tblEntityTypes.strEntityTypeName, tblClub.intClubID, tblAssoc.intRealmID, tblAssoc.intAssocTypeID, tblClub.strName 
    FROM tblClub 
    JOIN tblAssoc_Clubs ON (tblAssoc_Clubs.intClubID = tblClub.intClubID)
    JOIN tblAssoc ON (tblAssoc.intAssocID = tblAssoc_Clubs.intAssocID)
    JOIN tblEntityTypes ON (tblEntityTypes.intEntityTypeID = 3)
UNION
    SELECT 5, tblEntityTypes.strEntityTypeName, tblAssoc.intAssocID, tblAssoc.intRealmID, tblAssoc.intAssocTypeID, tblAssoc.strName
    FROM tblAssoc 
    JOIN tblEntityTypes ON (tblEntityTypes.intEntityTypeID = 5)
UNION 
    SELECT tblNode.intTypeID AS intTypeID, tblEntityTypes.strEntityTypeName, tblNode.intNodeID, tblNode.intRealmID, tblNode.intSubTypeID, tblNode.strName
    FROM tblNode 
    LEFT JOIN tblEntityTypes ON (tblEntityTypes.intEntityTypeID = tblNode.intTypeID);
