#PEOPLE FILE
#SystemID;PalloID;Status;LocalFirstName;LocalLastName;LocalPreviousLastName;LocalLanguageCode;PreferedName;LatinFirstName;LatinLastName;LatinPreviousLastName;DateOfBirth;Gender;Nationality;CountryOfBirth;RegionOfBirth;PlaceOfBirth;Fax;Phone;Address1;Address2;PostalCode;Town;Suburb;Email;Identifier;IdentifierType;CountryIssued;DateFrom;DateTo


DROP TABLE IF EXISTS tmpPerson;
CREATE TABLE tmpPerson(
    intID INT NOT NULL AUTO_INCREMENT,
    strFileType varchar(30) default '',
    strPersonCode varchar(30) default '',
    strNationalNum varchar(30) default '',
    strStatus varchar(30) default '',
    strLocalFirstname varchar(100) default '',
    strLocalSurname varchar(100) default '',
    strLocalMaidenName varchar(100) default '',
    strLatinFirstname varchar(100) default '',
    strLatinSurname varchar(100) default '',
    strISONationality varchar(100) default '',
    strISOCountryOfBirth varchar(100) default '',
    strRegionOfBirth varchar(100) default '',
    strPlaceOfBirth varchar(100) default '',
    strFax varchar(100) default '',
    strPhone varchar(100) default '',
    strAddress1 varchar(100) default '',
    strAddress2 varchar(100) default '',
    strPostalCode varchar(15) default '',
    strSuburb varchar(100) default '',
    strEmail varchar(200) default '',
    strLocalLanguage varchar(100) default '',
    strGender varchar(10) default '',
    dtDOB date,

    strIdentifier varchar(100) default '',
    strIdentifierType varchar(100) default '',
    strIdentifierCountryIssued varchar(100) default '',
    dtIdentifierFrom date,
    dtIdentifierTo date,
    strNatCustomStr1 varchar(50) DEFAULT '',
    strNatCustomStr2 varchar(50) DEFAULT '',

    PRIMARY KEY (intID),
    INDEX index_strFileType (strFileType),
    INDEX index_personCode (strPersonCode)
) DEFAULT CHARACTER SET = utf8;
