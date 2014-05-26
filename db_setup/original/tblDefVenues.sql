DROP TABLE tblDefVenue;

#
# Table               : tblDefVenue
# Description         : Venues an Association has
#---------------------
# intAssocGradeID     : Automatic Venue ID
# intAssocID          : Associations ID
# strName	          : Venue Description
#
CREATE table tblDefVenue (
    intDefVenueID  INT NOT NULL AUTO_INCREMENT,
    intAssocID       INT NOT NULL,
    strName     VARCHAR(150),
    intRecStatus TINYINT(4) DEFAULT 0,
	tTimeStamp TIMESTAMP, 

PRIMARY KEY (intDefVenueID),
KEY index_intAssocID(intAssocID)
);
