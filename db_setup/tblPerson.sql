DROP TABLE IF EXISTS tblPerson;
 
CREATE TABLE tblPerson (
    intPersonID int(11) NOT NULL AUTO_INCREMENT,
    strImportPersonCode VARCHAR(45) NULL AFTER `intPersonID`,
    intRealmID int(11) NOT NULL DEFAULT 0,
    strExtKey varchar(20) NOT NULL DEFAULT '',
    strPersonNo varchar(15) NOT NULL DEFAULT '',
    strNationalNum varchar(30) DEFAULT '',
    strFIFAID varchar(30) default '',
    intDataOrigin INT DEFAULT 0,

    strStatus varchar(20) DEFAULT '', /* ACTIVE/INACTIVE/PENDING/TRANSFERRED/DECEASED/SUSPENDED*/
    intSystemStatus TINYINT DEFAULT 0, /* for things like duplicate etc */
    intPhoto TINYINT DEFAULT 0, 

    strLocalTitle varchar(30) DEFAULT '',
    strLocalFirstname varchar(50) DEFAULT '',
    strLocalMiddlename varchar(50) DEFAULT '',
    strLocalSurname varchar(150) DEFAULT '',
    strISONationality varchar(50) DEFAULT '',
    strLocalSurname2 varchar(150) DEFAULT '',
    strISOLocalLanguage VARCHAR(20) DEFAULT '',
    strLatinTitle varchar(30) DEFAULT '',
    strLatinFirstname varchar(50) DEFAULT '',
    strLatinMiddlename varchar(50) DEFAULT '',
    strLatinSurname varchar(150) DEFAULT '',
    strLatinSurname2 varchar(150) DEFAULT '',

    intGender tinyint(4) DEFAULT 0,
    strGender varchar(50) DEFAULT '',
    dtDOB date DEFAULT '0000-00-00',
    strISOCountryOfBirth varchar(100) default '',
    strRegionOfBirth varchar(100) default '',
    strPlaceOfBirth varchar(100) default '',

    dtDeath date DEFAULT '0000-00-00',
    dtSuspendedUntil DATE DEFAULT '0000-00-00',

    strFirstClubName varchar(100) default '',

    strAddress1 varchar(100) DEFAULT '',
    strAddress2 varchar(100) DEFAULT '',
    strSuburb varchar(100) DEFAULT '',
    strState varchar(50) DEFAULT '',
    strPostalCode varchar(15) DEFAULT '',
    strISOCountry varchar(50) DEFAULT '',
    strMaidenName varchar(50) DEFAULT '',
    strPhoneHome varchar(30) DEFAULT '',
    strPhoneWork varchar(30) DEFAULT '',
    strPhoneMobile varchar(30) DEFAULT '',
    strFax varchar(30) DEFAULT '',
    strPager varchar(30) DEFAULT '',
    strEmail varchar(200) DEFAULT '',
    intEthnicityID int(11) DEFAULT 0,
    strPreferredName varchar(100) DEFAULT '',
    strPreferredLang varchar(50) DEFAULT '',

    tTimeStamp timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    strCityOfResidence varchar(50) DEFAULT '',
    strPassportNo varchar(50) DEFAULT '',
    strPassportNationality varchar(50) DEFAULT '',
    dtPassportExpiry date DEFAULT '0000-00-00',
    strISOPassportIssueCountry varchar(50) DEFAULT '',
    strEmergContName varchar(100) DEFAULT '',
    strEmergContRel varchar(100) DEFAULT '',
    strEmergContNo varchar(100) DEFAULT '',
    strEyeColour varchar(30) DEFAULT '',
    strHairColour varchar(30) DEFAULT '',
    strHeight varchar(20) DEFAULT '',
    strWeight varchar(20) DEFAULT '',
    dtPoliceCheck date DEFAULT '0000-00-00',
    dtPoliceCheckExp date DEFAULT '0000-00-00',
    strPoliceCheckRef varchar(30) DEFAULT '',
    strP1FName varchar(50) DEFAULT '',
    strP1SName varchar(50) DEFAULT '',
    strP2FName varchar(50) DEFAULT '',
    strP2SName varchar(50) DEFAULT '',
    strP1Email varchar(250) DEFAULT '',
    strP2Email varchar(250) DEFAULT '',
    strP1Phone varchar(30) DEFAULT '',
    strP2Phone varchar(30) DEFAULT '',
    strP1Salutation varchar(30) DEFAULT '',
    strP2Salutation varchar(30) DEFAULT '',
    intP1Gender tinyint(4) DEFAULT 0,
    intP2Gender tinyint(4) DEFAULT 0,
    strP1Phone2 varchar(30) DEFAULT '',
    strP2Phone2 varchar(30) DEFAULT '',
    strP1PhoneMobile varchar(30) DEFAULT '',
    strP2PhoneMobile varchar(30) DEFAULT '',
    strP1Email2 varchar(250) DEFAULT '',
    strP2Email2 varchar(250) DEFAULT '',
    intMedicalConditions tinyint(4) DEFAULT 0,
    intAllergies tinyint(4) DEFAULT 0,
    intAllowMedicalTreatment tinyint(4) DEFAULT 0,
    intConsentSignatureSighted tinyint(4) DEFAULT 0,
    strISOMotherCountry varchar(100) DEFAULT '',
    strISOFatherCountry varchar(100) DEFAULT '',

    strNatCustomStr1 varchar(50) DEFAULT '',
    strNatCustomStr2 varchar(50) DEFAULT '',
    strNatCustomStr3 varchar(50) DEFAULT '',
    strNatCustomStr4 varchar(50) DEFAULT '',
    strNatCustomStr5 varchar(50) DEFAULT '',
    strNatCustomStr6 varchar(50) DEFAULT '',
    strNatCustomStr7 varchar(30) DEFAULT '',
    strNatCustomStr8 varchar(30) DEFAULT '',
    strNatCustomStr9 varchar(50) DEFAULT '',
    strNatCustomStr10 varchar(50) DEFAULT '',
    strNatCustomStr11 varchar(50) DEFAULT '',
    strNatCustomStr12 varchar(50) DEFAULT '',
    strNatCustomStr13 varchar(50) DEFAULT '',
    strNatCustomStr14 varchar(50) DEFAULT '',
    strNatCustomStr15 varchar(50) DEFAULT '',
    dblNatCustomDbl1 double DEFAULT 0,
    dblNatCustomDbl2 double DEFAULT 0,
    dblNatCustomDbl3 double DEFAULT 0,
    dblNatCustomDbl4 double DEFAULT 0,
    dblNatCustomDbl5 double DEFAULT 0,
    dblNatCustomDbl6 double DEFAULT 0,
    dblNatCustomDbl7 double DEFAULT 0,
    dblNatCustomDbl8 double DEFAULT 0,
    dblNatCustomDbl9 double DEFAULT 0,
    dblNatCustomDbl10 double DEFAULT 0,
    dtNatCustomDt1 date DEFAULT '0000-00-00',
    dtNatCustomDt2 date DEFAULT '0000-00-00',
    dtNatCustomDt3 date DEFAULT '0000-00-00',
    dtNatCustomDt4 date DEFAULT '0000-00-00',
    dtNatCustomDt5 date DEFAULT '0000-00-00',
    intNatCustomLU1 int(11) DEFAULT 0,
    intNatCustomLU2 int(11) DEFAULT 0,
    intNatCustomLU3 int(11) DEFAULT 0,
    intNatCustomLU4 int(11) DEFAULT 0,
    intNatCustomLU5 int(11) DEFAULT 0,
    intNatCustomLU6 int(11) DEFAULT 0,
    intNatCustomLU7 int(11) DEFAULT 0,
    intNatCustomLU8 int(11) DEFAULT 0,
    intNatCustomLU9 int(11) DEFAULT 0,
    intNatCustomLU10 int(11) DEFAULT 0,
    intNatCustomBool1 tinyint(4) DEFAULT 0,
    intNatCustomBool2 tinyint(4) DEFAULT 0,
    intNatCustomBool3 tinyint(4) DEFAULT 0,
    intNatCustomBool4 tinyint(4) DEFAULT 0,
    intNatCustomBool5 tinyint(4) DEFAULT 0,
    strDemographicField1 VARCHAR(45) NULL COMMENT 'TBC' AFTER `dtSuspendedUntil`,
    strDemographicField2 VARCHAR(45) NULL COMMENT 'TBC' AFTER `strDemographicField1`,
    strDemographicField3 VARCHAR(45) NULL COMMENT 'TBC' AFTER `strDemographicField2`,
    strDemographicField4 VARCHAR(45) NULL COMMENT 'TBC' AFTER `strDemographicField3`,
    strDemographicField5 VARCHAR(45) NULL COMMENT 'TBC' AFTER `strDemographicField4`,
    strDemographicField6 VARCHAR(45) NULL COMMENT 'TBC' AFTER `strDemographicField5`,
  PRIMARY KEY (intPersonID),
  UNIQUE INDEX `strImportPersonCode_UNIQUE` (`strImportPersonCode` ASC),
  KEY index_strPersonNo (strPersonNo),
  KEY index_strStatus (strStatus),
  KEY index_strExtKey (strExtKey),
  KEY index_strLocalSurname (strLocalSurname),
  KEY index_strLocalFirstname (strLocalFirstname),
  KEY index_dtDOB (dtDOB),
  KEY index_intGender (intGender),
  KEY index_strNationalNum (strNationalNum),
  KEY index_intRealmID (intRealmID),
  KEY index_RealmStatus (intRealmID,strStatus),
  KEY index_RealmNameDOB (intRealmID,strLocalSurname,strLocalFirstname,dtDOB),
  KEY index_RealmEmail (intRealmID,strEmail),
  KEY index_FIFA (strFIFAID),
  KEY index_RealmNatNumMID (intRealmID,strNationalNum,intPersonID)
) DEFAULT CHARSET=utf8;
