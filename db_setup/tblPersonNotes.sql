CREATE TABLE `tblPersonNotes` (
  `intNotesPersonID` int(11) NOT NULL DEFAULT '0',
  `strPersonNotes` text,
  `strPersonMedicalNotes` text,
  `strPersonCustomNotes1` text,
  `strPersonCustomNotes2` text,
  `strPersonCustomNotes3` text,
  `strPersonCustomNotes4` text,
  `strPersonCustomNotes5` text,
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`intNotesPersonID`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

