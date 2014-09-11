/** Set new Realm **/
SET @strRealmName="Philippines", 
	@strLocalShortName="PH";

/** Get the new Realm ID **/
SELECT @intRealmID:=intRealmID
FROM tblRealms
WHERE strRealmName = @strRealmName;

delete from tblUserAuth where entityId in(select intEntityID from tblEntity where intRealmID = @intRealmID);
delete from tblTempEntityStructure where intRealmID = @intRealmID;
delete from tblEntity where intRealmID = @intRealmID;
delete from tblRealms where intRealmID = @intRealmID;
SET @c = CONCAT("DROP TABLE IF EXISTS tblPersonRegistration_",@intRealmID);

PREPARE stmt from @c;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;