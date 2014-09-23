DROP TABLE IF EXISTS tblWFTaskNotes;

CREATE TABLE `tblWFTaskNotes` (
    `intTaskNoteID` int(11) NOT NULL AUTO_INCREMENT,
    `intWFTaskID` int(11) NOT NULL,
    `strRejectionNotes` varchar(250) NOT NULL,
    `strResolveNotes` varchar(250) NOT NULL,
    `intCurrent` int(11) NOT NULL DEFAULT '1',
    `tTimeStampRejected` timestamp NULL DEFAULT NULL,
    `tTimeStampResolved` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`intTaskNoteID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1
