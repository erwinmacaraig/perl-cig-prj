CREATE TABLE tblDefVenueTimeSlots   (
  intTimeSlotID         INT NOT NULL AUTO_INCREMENT,
  intAssocID        	INT DEFAULT 0,
  intVenueID            INT DEFAULT 0,
  dtTimeSlot            TIME,
  tTimeStamp        	TIMESTAMP,
  intDayofWeek          TINYINT DEFAULT 0,

  PRIMARY KEY (intTimeSlotID),
    KEY index_intVenueID(intVenueID), 
  UNIQUE KEY index_intIDs (intVenueID, dtTimeSlot, intDayofWeek)
);
