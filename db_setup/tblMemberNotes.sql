CREATE TABLE `tblMemberNotes` (
  `intNotesMemberID` int(11) NOT NULL DEFAULT '0',
  `intNotesAssocID` int(11) NOT NULL DEFAULT '0',
  `strMemberNotes` text,
  `strMemberMedicalNotes` text,
  `strMemberCustomNotes1` text,
  `strMemberCustomNotes2` text,
  `strMemberCustomNotes3` text,
  `strMemberCustomNotes4` text,
  `strMemberCustomNotes5` text,
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`intNotesMemberID`,`intNotesAssocID`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

