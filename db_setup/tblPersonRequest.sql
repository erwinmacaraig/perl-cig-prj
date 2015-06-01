DROP TABLE IF EXISTS tblPersonRequest;
CREATE TABLE `tblPersonRequest` (
    `intPersonRequestID` INT NOT NULL AUTO_INCREMENT,
    `strRequestType` VARCHAR(20) NOT NULL COMMENT 'ACCESS, TRANSFER',
    `intPersonID` INT NOT NULL,
    intExistingPersonRegistrationID INT DEFAULT 0,
    `strSport` VARCHAR(20) NOT NULL COMMENT 'FOOTBALL, FUTSAL, BEACHSOCCER',
    `strPersonType` VARCHAR(20) NOT NULL COMMENT 'PLAYER, COACH, ETC',
    `strPersonLevel` VARCHAR(30) NULL COMMENT 'PROFESSIONAL, AMATEUR, (blank)',
    strNewPersonLevel VARCHAR(30) NULL COMMENT 'PROFESSIONAL, AMATEUR, (blank)',
    `strPersonEntityRole` VARCHAR(50) NULL COMMENT 'DOCTOR, ETC',
    `intRealmID` INT NULL,
    `intRequestFromEntityID` INT NOT NULL COMMENT 'What Entity is requesting the permission.',
    `intRequestToEntityID` INT NOT NULL COMMENT 'The Entity ID that the request goes to',
    `intRequestToMAOverride` INT NOT NULL DEFAULT 0 COMMENT 'Send request to Member Association level due to timeout',
    `strRequestNotes` VARCHAR(250) NULL COMMENT 'Any note about the request',
    `dtDateRequest` DATETIME NOT NULL 'Date the request was made',
    `strRequestResponse` VARCHAR(20) NULL COMMENT 'ACCEPTED/DENIED',
    `strResponseNotes` VARCHAR(250) NULL COMMENT 'Notes regarding the response',
    `intResponseBy` INT NOT NULL COMMENT 'Which level ended up giving the response',
    `tTimeStamp` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Tracking updates',
    PRIMARY KEY (`intPersonRequestID`),
    KEY `index_intPersonID` (`intPersonID` ASC),
    KEY `index_intFromEntityID` (`intRequestFromEntityID` ASC),
    KEY `index_intToEntityID` (`intRequestToEntityID` ASC)
) DEFAULT CHARACTER SET = utf8;

