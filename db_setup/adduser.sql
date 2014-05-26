## ADD NEW USER FOR UPLOADING

INSERT INTO tblAuth (strUsername, strPassword, intLevel, intID, intAssocID)
	VALUES ('tc','tc','5','6','6');

## ADD NEW REGION

INSERT INTO tblRegion (intRegionID, strName, strContact,strAddress1,strSuburb,strPostalCode,strPhone,strFax,strEmail,intDataAccess)
	VALUES ('1','Victoria','Ken Jacobs','86 Jolimont Street','Melbourne','3002','9653 1111','N/A','kjacobs@viccricket.asn.au','2');


## ADD NEW ZONE

INSERT INTO tblZone (intZoneID, intRegionID, strName, strContact,strAddress1,strSuburb,strPostalCode,strPhone,strFax,strEmail,intDataAccess)
	VALUES ('1','1','Outer East','Andrew Larratt','86 Jolimont Street','Melbourne','3002','9859 0357','9859 0357','alarratt@viccricket.asn.au','2');


## ADD NEW ASSOCIATION

INSERT INTO tblAssoc (intAssocID, strName, intZoneID, strContact,strManager,strSecretary,strPresident,strAddress1,strSuburb,strPostalCode,strPhone,strFax,strEmail,intDataAccess)
	VALUES ('1','RDCA','1','Lindsay Trollope ','N/A','Lindsay Trollope','Steve Pascoe','64 Woodville Avenue','Mooroolbark','3138','9727 1229','9727 1206','rdca@sme.com.au','2');
