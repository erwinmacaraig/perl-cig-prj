DROP TABLE IF EXISTS tblWFTaskNotes;

CREATE TABLE `tblWFTaskNotes` (
  `intTaskNoteID` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `intParentNoteID` int(10) unsigned NOT NULL DEFAULT '0' COMMENT 'Used to track which rejection/toggle note a resolution note will be mapped.',
  `intWFTaskID` int(11) NOT NULL,
  `strNotes` varchar(250) NOT NULL,
  `strType` varchar(20) DEFAULT NULL COMMENT 'REJECT, RESOLVE, HOLD',
  `intCurrent` int(11) NOT NULL DEFAULT '1',
  `tTimeStamp` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`intTaskNoteID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
