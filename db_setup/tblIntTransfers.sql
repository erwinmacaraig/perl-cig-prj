DROP TABLE IF EXISTS tblIntTransfer;
CREATE TABLE `tblIntTransfer` (
    `intIntTransferID` INT NOT NULL AUTO_INCREMENT,
    `intOldEntityID` INT NOT NULL COMMENT 'Entity ID of old club',
    `intPersonRequestID` INT NOT NULL COMMENT 'Link to tblPersonRequest',
    `intPersonID` INT DEFAULT 0 COMMENT 'Person ID',
    `strSport` VARCHAR(20) NOT NULL COMMENT 'FOOTBALL, FUTSAL, BEACHSOCCER',
    `strPersonType` VARCHAR(20) NOT NULL COMMENT 'PLAYER',
    `strPersonOutLevel` VARCHAR(30) NULL COMMENT 'Level the player left MA as',
    `dtTransferOut` DATETIME NOT NULL COMMENT '',
    `intTransferOut` TINYINT NOT NULL COMMENT 'Was person transferred OUT',
    `strMAOutTo` VARCHAR(250) NULL COMMENT 'Name of the MA that the Transfer OUT was to',
    `strClubOutTo` VARCHAR(250) NULL COMMENT 'Name of the Club that the Transfer OUT was to',
    `strTMSOutRef` VARCHAR(50) NULL COMMENT 'TMS reference of Int Transfer OUT record',
    `strOutNotes` VARCHAR(250) NULL COMMENT 'TMS reference of Int Transfer OUT record',
    `dtTransferReturn` DATETIME NULL COMMENT 'set once player marked as returned',
    `intTransferReturn` TINYINT NULL COMMENT 'Has person returned',
    `strMAReturnFrom` VARCHAR(250) NULL COMMENT 'Name of the MA that the transfer RETURN was from',
    `strClubReturnFrom` VARCHAR(250) NULL COMMENT 'Name of the club that the transfer RETURN was from',
    `strPersonReturnLevel` VARCHAR(30) NULL COMMENT 'Level they RETURNED to MA as',
    `strTMSReturnRef` VARCHAR(50) NULL COMMENT 'TMS reference of the Int Transfer OUT record',
    `strReturnNotes` VARCHAR(250) NULL COMMENT 'Free text notes field for Transfer RETURN record',
    `tTimeStamp` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Tracking updates',

    PRIMARY KEY (`intIntTransferID`),
    KEY `index_intPersonID` (`intPersonID` ASC),
    KEY `index_intOldEntityID` (`intOldEntityID` ASC),
    UNIQUE KEY `index_intPersonRequestID` (`intPersonRequestID`)
) DEFAULT CHARACTER SET = utf8;

