CREATE TABLE tblMemberNotes	(
  intNotesMemberID		INT DEFAULT 0,
  intNotesAssocID        	INT DEFAULT 0,
  strMemberNotes	TEXT default '',
  strMemberMedicalNotes	TEXT default '',
  strMemberCustomNotes1	TEXT default '',
  strMemberCustomNotes2	TEXT default '',
  strMemberCustomNotes3	TEXT default '',
  strMemberCustomNotes4	TEXT default '',
  strMemberCustomNotes5	TEXT default '',
  tTimeStamp        	TIMESTAMP,

  PRIMARY KEY (intNotesMemberID, intNotesAssocID)
);
