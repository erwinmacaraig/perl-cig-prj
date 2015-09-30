#PEOPLE FILE
#SystemID;PalloID;Status;LocalFirstName;LocalLastName;LocalPreviousLastName;LocalLanguageCode;PreferedName;LatinFirstName;LatinLastName;LatinPreviousLastName;DateOfBirth;Gender;Nationality;CountryOfBirth;RegionOfBirth;PlaceOfBirth;Fax;Phone;Address1;Address2;PostalCode;Town;Suburb;Email;Identifier;IdentifierType;CountryIssued;DateFrom;DateTo


DROP TABLE IF EXISTS tmpEntity;
CREATE TABLE tmpEntity (
    intID INT NOT NULL AUTO_INCREMENT,
    strFileType varchar(30) default '',
    strEntityCode varchar(30) default '',
    strNationalNum varchar(30) default '',
    strStatus varchar(30) default '',
    strLocalName varchar(100) default '',
    strISOCountry varchar(100) default '',
    strFax varchar(100) default '',
    strPhone varchar(100) default '',
    strAddress1 varchar(100) default '',
    strAddress2 varchar(100) default '',
    strPostalCode varchar(15) default '',
    strSuburb varchar(100) default '',
    strEmail varchar(200) default '',
    strLocalLanguage varchar(100) default '',

    strIdentifier varchar(100) default '',
    strIdentifierType varchar(100) default '',
    strIdentifierCountryIssued varchar(100) default '',
    dtIdentifierFrom date,
    dtIdentifierTo date,
    
    PRIMARY KEY (intID),
    INDEX index_strFileType (strFileType),
    INDEX index_entityCode (strEntityCode)
) DEFAULT CHARACTER SET = utf8;
