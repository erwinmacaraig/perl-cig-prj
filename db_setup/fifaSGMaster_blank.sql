-- MySQL dump 10.13  Distrib 5.5.34, for debian-linux-gnu (i686)
--
-- Host: localhost    Database: fifaSingaporeTest
-- ------------------------------------------------------
-- Server version	5.5.34-0ubuntu0.13.04.1

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `tblAccreditation`
--

DROP TABLE IF EXISTS `tblAccreditation`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblAccreditation` (
  `intAccreditationID` int(11) NOT NULL AUTO_INCREMENT,
  `intMemberID` int(11) DEFAULT NULL,
  `intQualificationID` int(11) DEFAULT NULL,
  `intRealmID` int(11) DEFAULT NULL,
  `intDataEntryPassportID` int(11) DEFAULT NULL,
  `intSport` int(11) DEFAULT NULL,
  `intLevel` int(11) DEFAULT NULL,
  `intProvider` int(11) DEFAULT NULL,
  `dtApplication` date DEFAULT NULL,
  `dtStart` date DEFAULT NULL,
  `dtExpiry` date DEFAULT NULL,
  `intReaccreditation` int(11) DEFAULT NULL,
  `intStatus` int(11) DEFAULT NULL,
  `strCourseNumber` varchar(50) DEFAULT NULL,
  `strParticipantNumber` varchar(50) DEFAULT NULL,
  `strNotes` varchar(200) DEFAULT NULL,
  `strCustomStr1` varchar(200) DEFAULT NULL,
  `intEducationID` int(11) DEFAULT NULL,
  `intRecStatus` int(11) DEFAULT '1',
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`intAccreditationID`),
  KEY `index_MemberRealmStatus` (`intMemberID`,`intRealmID`,`intRecStatus`)
) ENGINE=MyISAM AUTO_INCREMENT=339240 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblAccreditation`
--

LOCK TABLES `tblAccreditation` WRITE;
/*!40000 ALTER TABLE `tblAccreditation` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblAccreditation` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblAgeGroups`
--

DROP TABLE IF EXISTS `tblAgeGroups`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblAgeGroups` (
  `intAgeGroupID` int(11) NOT NULL AUTO_INCREMENT,
  `intRealmID` int(11) DEFAULT '0',
  `intRealmSubTypeID` int(11) DEFAULT '0',
  `intAssocID` int(11) DEFAULT '0',
  `strAgeGroupDesc` varchar(100) DEFAULT NULL,
  `intAgeGroupGender` int(11) DEFAULT '0',
  `intRecStatus` tinyint(4) DEFAULT '0',
  `dtDOBStart` date DEFAULT NULL,
  `dtDOBEnd` date DEFAULT NULL,
  `dtAdded` date DEFAULT NULL,
  `intCategoryID` int(11) DEFAULT '0',
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`intAgeGroupID`),
  KEY `index_intAssocID` (`intAssocID`),
  KEY `index_intRealm` (`intRealmID`,`intRealmSubTypeID`)
) ENGINE=MyISAM AUTO_INCREMENT=3596 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblAgeGroups`
--

LOCK TABLES `tblAgeGroups` WRITE;
/*!40000 ALTER TABLE `tblAgeGroups` DISABLE KEYS */;
INSERT INTO `tblAgeGroups` VALUES (3578,1,0,0,' U-05',3,1,'2010-01-01','2010-12-31','2014-01-20',0,'2015-01-06 22:39:05'),(3579,1,0,0,' U-06',3,1,'2009-01-01','2009-12-31',NULL,0,'2015-01-06 22:39:05'),(3580,1,0,0,' U-07',3,1,'2008-01-01','2008-12-31',NULL,0,'2015-01-06 22:39:05'),(3581,1,0,0,' U-08',3,1,'2007-01-01','2007-12-31',NULL,0,'2015-01-06 22:39:05'),(3582,1,0,0,' U-09',3,1,'2006-01-01','2006-12-31',NULL,0,'2015-01-06 22:39:05'),(3583,1,0,0,' U-10',3,1,'2005-01-01','2005-12-31',NULL,0,'2015-01-06 22:39:05'),(3584,1,0,0,' U-11',3,1,'2004-01-01','2004-12-31',NULL,0,'2015-01-06 22:39:05'),(3585,1,0,0,' U-12',3,1,'2003-01-01','2003-12-31',NULL,0,'2015-01-06 22:39:05'),(3586,1,0,0,' U-13',3,1,'2002-01-01','2002-12-31',NULL,0,'2015-01-06 22:39:05'),(3587,1,0,0,' U-14',3,1,'2001-01-01','2001-12-31',NULL,0,'2015-01-06 22:39:05'),(3588,1,0,0,' U-15',3,1,'2000-01-01','2000-12-31',NULL,0,'2015-01-06 22:39:05'),(3589,1,0,0,' U-16',3,1,'1999-01-01','1999-12-31',NULL,0,'2015-01-06 22:39:05'),(3590,1,0,0,' U-17',3,1,'1998-01-01','1998-12-31',NULL,0,'2015-01-06 22:39:05'),(3591,1,0,0,' U-18',3,1,'1997-01-01','1997-12-31',NULL,0,'2015-01-06 22:39:05'),(3592,1,0,0,' U-19',3,1,'1996-01-01','1996-12-31',NULL,0,'2015-01-12 05:12:32'),(3593,1,0,0,' U-20',3,1,'1995-01-01','1995-12-31','2015-01-12',0,'2015-01-12 05:12:37'),(3594,1,0,0,' U-21',3,1,'1994-01-01','1994-12-31','2015-01-12',0,'2015-01-12 05:12:40'),(3595,1,0,0,' Seniors',3,1,'1902-01-01','1993-12-31','2015-01-12',0,'2015-01-12 05:12:46');
/*!40000 ALTER TABLE `tblAgeGroups` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblAgreements`
--

DROP TABLE IF EXISTS `tblAgreements`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblAgreements` (
  `intAgreementID` int(11) NOT NULL AUTO_INCREMENT,
  `intEntityFor` int(11) NOT NULL,
  `strName` varchar(200) NOT NULL,
  `strAgreement` text,
  `dtExpiryDate` date DEFAULT NULL,
  `dtStartDate` date DEFAULT NULL,
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `intRealmID` int(11) NOT NULL,
  `intSubRealmID` int(11) DEFAULT '0',
  `intCountryID` int(11) DEFAULT '0',
  `intStateID` int(11) DEFAULT '0',
  `intRegionID` int(11) DEFAULT '0',
  `intZoneID` int(11) DEFAULT '0',
  `intAssocID` int(11) DEFAULT '0',
  `intCheckNewEntityOnly` tinyint(4) DEFAULT '0',
  PRIMARY KEY (`intAgreementID`),
  KEY `index_realm` (`intRealmID`),
  KEY `index_country` (`intCountryID`),
  KEY `index_state` (`intStateID`),
  KEY `index_region` (`intRegionID`),
  KEY `index_zone` (`intZoneID`),
  KEY `index_assoc` (`intAssocID`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblAgreements`
--

LOCK TABLES `tblAgreements` WRITE;
/*!40000 ALTER TABLE `tblAgreements` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblAgreements` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblAgreementsEntity`
--

DROP TABLE IF EXISTS `tblAgreementsEntity`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblAgreementsEntity` (
  `intEntityTypeID` int(11) NOT NULL,
  `intEntityID` int(11) NOT NULL,
  `intAgreementID` int(11) NOT NULL,
  `dtAgreed` datetime DEFAULT NULL,
  `strAgreedBy` varchar(200) DEFAULT '',
  PRIMARY KEY (`intEntityTypeID`,`intEntityID`,`intAgreementID`),
  KEY `index_agreement` (`intAgreementID`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblAgreementsEntity`
--

LOCK TABLES `tblAgreementsEntity` WRITE;
/*!40000 ALTER TABLE `tblAgreementsEntity` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblAgreementsEntity` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblAssoc`
--

DROP TABLE IF EXISTS `tblAssoc`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblAssoc` (
  `intAssocID` int(11) NOT NULL AUTO_INCREMENT,
  `strName` varchar(150) NOT NULL DEFAULT '',
  `strContact` varchar(50) DEFAULT NULL,
  `strManager` varchar(50) DEFAULT NULL,
  `strSecretary` varchar(50) DEFAULT NULL,
  `strPresident` varchar(50) DEFAULT NULL,
  `strAddress1` varchar(50) DEFAULT NULL,
  `strAddress2` varchar(50) DEFAULT NULL,
  `strAddress3` varchar(50) DEFAULT NULL,
  `strSuburb` varchar(50) DEFAULT NULL,
  `strState` varchar(50) DEFAULT NULL,
  `strPostalCode` varchar(15) DEFAULT NULL,
  `strPhone` varchar(20) DEFAULT NULL,
  `strFax` varchar(20) DEFAULT NULL,
  `strEmail` varchar(200) NOT NULL DEFAULT '',
  `dtRegistered` datetime DEFAULT NULL,
  `strAssocNo` varchar(30) DEFAULT '',
  `intDataAccess` int(11) NOT NULL DEFAULT '10',
  `strCountry` varchar(50) DEFAULT NULL,
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `intRealmID` int(11) NOT NULL DEFAULT '0',
  `intRecStatus` tinyint(4) DEFAULT '1',
  `strFirstSyncCode` varchar(30) DEFAULT NULL,
  `intAssocTypeID` int(11) NOT NULL DEFAULT '0',
  `intAlternateID` int(11) DEFAULT NULL,
  `intRegionalManager_tmp` int(11) DEFAULT NULL,
  `intDefaultRegoProductID` int(11) DEFAULT '0',
  `strColours` varchar(25) DEFAULT NULL,
  `strNotes` text,
  `intAssocLevelID` int(11) DEFAULT NULL,
  `dtExpiry` date DEFAULT NULL,
  `strIncNo` varchar(50) DEFAULT NULL,
  `strBusinessNo` varchar(50) DEFAULT NULL,
  `strAssocCustomCheckBox1` char(2) DEFAULT NULL,
  `strAssocCustomCheckBox2` char(2) DEFAULT NULL,
  `strGroundName` varchar(50) DEFAULT NULL,
  `strGroundAddress` varchar(50) DEFAULT NULL,
  `strGroundSuburb` varchar(20) DEFAULT NULL,
  `strGroundPostalCode` varchar(10) DEFAULT NULL,
  `intAllowPayment` int(11) NOT NULL DEFAULT '0',
  `intPaymentConfigID` int(11) DEFAULT '0',
  `strAssocPaymentABN` varchar(100) DEFAULT '',
  `strAssocPaymentInfo` text,
  `intDefaultTeamRegoProductID` int(11) DEFAULT '0',
  `intAllowClearances` tinyint(4) DEFAULT '1',
  `strPaymentReceiptBodyTEXT` text,
  `strPaymentReceiptBodyHTML` text,
  `intAllowRegoForm` int(11) DEFAULT '0',
  `intAllowClubClrAccess` int(11) DEFAULT '1',
  `intAllowAutoDuplRes` tinyint(4) DEFAULT '0',
  `intDefaultMemberTypeID` tinyint(4) DEFAULT '1',
  `intCurrentSeasonID` int(11) DEFAULT '0',
  `intNewRegoSeasonID` int(11) DEFAULT '0',
  `intAllowSeasons` tinyint(4) DEFAULT '0',
  `intSyncMS_records` tinyint(4) DEFAULT '0',
  `intForceSync` tinyint(4) DEFAULT '0',
  `intHideAllRolloverCheckbox` tinyint(4) DEFAULT '0',
  `intAllowFullTribunal` tinyint(4) DEFAULT '0',
  `intSWOL` tinyint(4) DEFAULT '0',
  `intSWOL_SportID` int(11) DEFAULT '0',
  `strSWWUsername` varchar(50) DEFAULT '',
  `strSWWPassword` varchar(50) DEFAULT '',
  `intSWWAssocID` int(11) DEFAULT '0',
  `intAssocFeeAllocationType` tinyint(4) DEFAULT '0',
  `intApproveClubPayment` tinyint(4) DEFAULT '0',
  `intHideRegoFormNew` tinyint(4) DEFAULT '0',
  `intCCPermits` tinyint(4) DEFAULT '0',
  `intAssocClrStatus` tinyint(4) DEFAULT '0',
  `strLGA` varchar(250) DEFAULT NULL,
  `dtUpdated` datetime DEFAULT NULL,
  `strExtKey` varchar(20) DEFAULT NULL,
  `intHideRollover` tinyint(4) DEFAULT '0',
  `intNoPMSEmail` tinyint(4) DEFAULT '0',
  `intSPAgreement_NewEntity` tinyint(4) DEFAULT '1',
  `intCCAssocOnClubPayments` tinyint(4) DEFAULT '0',
  `intUploadType` tinyint(4) DEFAULT '0',
  `intUploadUmpires` tinyint(4) DEFAULT '0',
  `intProcessLogNumber` int(11) DEFAULT '0',
  `intLocalisationID` int(11) DEFAULT '0',
  `strTimeZone` varchar(30) DEFAULT '',
  `intPlayerStatsConfigID` int(11) DEFAULT NULL,
  `intTeamMatchStatsID` int(11) DEFAULT NULL,
  `intCareerStatsConfigID` int(11) DEFAULT NULL,
  `intDefaultCompStatsTemplateID` int(11) DEFAULT NULL,
  `intQRStatsTemplateID` int(11) DEFAULT NULL,
  `intAssocCategoryID` int(11) DEFAULT '0',
  `intHideClubRollover` tinyint(4) DEFAULT '0',
  `intHideMembers` int(11) DEFAULT '0',
  `intDisplayInActiveComps` int(11) DEFAULT '0',
  `intExcludeFromNationalRego` int(11) DEFAULT '0',
  PRIMARY KEY (`intAssocID`),
  KEY `index_strName` (`strName`),
  KEY `index_intDataAccess` (`intDataAccess`),
  KEY `index_Realm` (`intRealmID`),
  KEY `index_triple` (`intAssocID`,`intRecStatus`,`intDataAccess`),
  KEY `index_intAllowRegoForm` (`intAllowRegoForm`)
) ENGINE=MyISAM AUTO_INCREMENT=20524 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblAssoc`
--

LOCK TABLES `tblAssoc` WRITE;
/*!40000 ALTER TABLE `tblAssoc` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblAssoc` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblAssocConfig`
--

DROP TABLE IF EXISTS `tblAssocConfig`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblAssocConfig` (
  `intAssocConfigID` int(11) NOT NULL AUTO_INCREMENT,
  `intAssocID` int(11) NOT NULL,
  `strOption` varchar(100) NOT NULL,
  `strValue` varchar(250) NOT NULL,
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`intAssocConfigID`),
  UNIQUE KEY `index_AssocOption` (`intAssocID`,`strOption`),
  KEY `index_AssocID` (`intAssocID`),
  KEY `index_strOption` (`strOption`)
) ENGINE=MyISAM AUTO_INCREMENT=15997 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblAssocConfig`
--

LOCK TABLES `tblAssocConfig` WRITE;
/*!40000 ALTER TABLE `tblAssocConfig` DISABLE KEYS */;
INSERT INTO `tblAssocConfig` VALUES (15996,13,'NoClubs','1','2014-01-23 21:47:16');
/*!40000 ALTER TABLE `tblAssocConfig` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblAssocServices`
--

DROP TABLE IF EXISTS `tblAssocServices`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblAssocServices` (
  `intAssocServicesID` int(11) NOT NULL AUTO_INCREMENT,
  `intAssocID` int(11) NOT NULL DEFAULT '0',
  `strContact1Name` varchar(100) DEFAULT NULL,
  `strContact1Title` varchar(50) DEFAULT NULL,
  `strContact1Phone` varchar(50) DEFAULT NULL,
  `strContact2Name` varchar(100) DEFAULT NULL,
  `strContact2Title` varchar(50) DEFAULT NULL,
  `strContact2Phone` varchar(50) DEFAULT NULL,
  `strVenueName` varchar(100) DEFAULT NULL,
  `strVenueAddress` varchar(100) DEFAULT NULL,
  `strVenueSuburb` varchar(100) DEFAULT NULL,
  `strVenueState` varchar(50) DEFAULT NULL,
  `strVenueCountry` varchar(60) DEFAULT NULL,
  `strVenuePostalCode` varchar(15) DEFAULT NULL,
  `intMon` tinyint(4) DEFAULT NULL,
  `intTue` tinyint(4) DEFAULT NULL,
  `intWed` tinyint(4) DEFAULT NULL,
  `intThu` tinyint(4) DEFAULT NULL,
  `intFri` tinyint(4) DEFAULT NULL,
  `intSat` tinyint(4) DEFAULT NULL,
  `intSun` tinyint(4) DEFAULT NULL,
  `strSessionDurations` varchar(100) DEFAULT NULL,
  `strTimes` varchar(100) DEFAULT NULL,
  `dtStart` date DEFAULT NULL,
  `dtFinish` date DEFAULT NULL,
  `strEmail` varchar(255) DEFAULT NULL,
  `strFax` varchar(20) DEFAULT NULL,
  `strVenueAddress2` varchar(100) DEFAULT NULL,
  `intPublicShow` tinyint(4) DEFAULT '1',
  `strNotes` text,
  `intAlternateAssocID_tmp` int(11) DEFAULT NULL,
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `strURL` varchar(255) DEFAULT '',
  `intRegisterID` int(11) DEFAULT '0',
  `intRegistrationFormID` int(11) DEFAULT NULL,
  `intClubID` int(11) DEFAULT '0',
  `strPresidentName` varchar(100) DEFAULT '',
  `strPresidentEmail` varchar(250) DEFAULT '',
  `strPresidentPhone` varchar(30) DEFAULT '',
  `strSecretaryName` varchar(100) DEFAULT '',
  `strSecretaryEmail` varchar(250) DEFAULT '',
  `strSecretaryPhone` varchar(30) DEFAULT '',
  `strTreasurerName` varchar(100) DEFAULT '',
  `strTreasurerEmail` varchar(250) DEFAULT '',
  `strTreasurerPhone` varchar(30) DEFAULT '',
  `strRegistrarName` varchar(100) DEFAULT '',
  `strRegistrarEmail` varchar(250) DEFAULT '',
  `strRegistrarPhone` varchar(30) DEFAULT '',
  `intShowPresident` tinyint(4) DEFAULT '0',
  `intShowSecretary` tinyint(4) DEFAULT '0',
  `intShowTreasurer` tinyint(4) DEFAULT '0',
  `intShowRegistrar` tinyint(4) DEFAULT '0',
  `dblLat` double DEFAULT NULL,
  `dblLong` double DEFAULT NULL,
  `strCompetitions` text,
  `strCompOrganizer` text,
  `strCompCosts` text,
  PRIMARY KEY (`intAssocServicesID`),
  KEY `intAssocID` (`intAssocID`),
  KEY `INDEX_intPublicShow` (`intPublicShow`),
  KEY `intClubID` (`intClubID`)
) ENGINE=MyISAM AUTO_INCREMENT=31582 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblAssocServices`
--

LOCK TABLES `tblAssocServices` WRITE;
/*!40000 ALTER TABLE `tblAssocServices` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblAssocServices` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblAssocServicesPostalCode`
--

DROP TABLE IF EXISTS `tblAssocServicesPostalCode`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblAssocServicesPostalCode` (
  `intAssocID` int(11) NOT NULL DEFAULT '0',
  `strPostalCode` varchar(15) NOT NULL DEFAULT '',
  `intOldAssocID_tmp` int(11) DEFAULT NULL,
  `intClubID` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`intAssocID`,`strPostalCode`,`intClubID`),
  KEY `index_strPostalCode` (`strPostalCode`),
  KEY `intClubID` (`intClubID`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblAssocServicesPostalCode`
--

LOCK TABLES `tblAssocServicesPostalCode` WRITE;
/*!40000 ALTER TABLE `tblAssocServicesPostalCode` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblAssocServicesPostalCode` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblAssoc_Clubs`
--

DROP TABLE IF EXISTS `tblAssoc_Clubs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblAssoc_Clubs` (
  `intAssocClubID` int(11) NOT NULL AUTO_INCREMENT,
  `intAssocID` int(11) NOT NULL DEFAULT '0',
  `intClubID` int(11) NOT NULL DEFAULT '0',
  `dtExpiry` date DEFAULT NULL,
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `intRecStatus` int(11) DEFAULT '1',
  PRIMARY KEY (`intAssocClubID`),
  KEY `index_intAssocID` (`intAssocID`),
  KEY `index_intClubID` (`intClubID`),
  KEY `index_AssocClub` (`intAssocID`,`intClubID`),
  KEY `index_intRecStatus` (`intRecStatus`)
) ENGINE=MyISAM AUTO_INCREMENT=210043 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblAssoc_Clubs`
--

LOCK TABLES `tblAssoc_Clubs` WRITE;
/*!40000 ALTER TABLE `tblAssoc_Clubs` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblAssoc_Clubs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblAssoc_Grade`
--

DROP TABLE IF EXISTS `tblAssoc_Grade`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblAssoc_Grade` (
  `intAssocGradeID` int(11) NOT NULL AUTO_INCREMENT,
  `intAssocID` int(11) NOT NULL DEFAULT '0',
  `strGradeDesc` varchar(150) DEFAULT NULL,
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `intRecStatus` tinyint(4) DEFAULT '0',
  PRIMARY KEY (`intAssocGradeID`),
  KEY `index_intAssocID` (`intAssocID`),
  KEY `INDEX_intRecStatus` (`intRecStatus`)
) ENGINE=MyISAM AUTO_INCREMENT=20105 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblAssoc_Grade`
--

LOCK TABLES `tblAssoc_Grade` WRITE;
/*!40000 ALTER TABLE `tblAssoc_Grade` DISABLE KEYS */;
INSERT INTO `tblAssoc_Grade` VALUES (20103,16,'A grade','2007-11-29 23:38:28',1),(20104,16,'B grade','2005-11-22 02:28:20',1);
/*!40000 ALTER TABLE `tblAssoc_Grade` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblAssoc_Node`
--

DROP TABLE IF EXISTS `tblAssoc_Node`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblAssoc_Node` (
  `intAssocID` int(11) NOT NULL DEFAULT '0',
  `intNodeID` int(11) NOT NULL DEFAULT '0',
  `intPrimary` tinyint(4) NOT NULL DEFAULT '1',
  `intSortOrder` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`intNodeID`,`intAssocID`),
  KEY `index_intAssocID` (`intAssocID`),
  KEY `index_intNodeID` (`intNodeID`),
  KEY `index_intPrimary` (`intPrimary`),
  KEY `index_triple` (`intNodeID`,`intAssocID`,`intPrimary`),
  KEY `index_intSortOrder` (`intSortOrder`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblAssoc_Node`
--

LOCK TABLES `tblAssoc_Node` WRITE;
/*!40000 ALTER TABLE `tblAssoc_Node` DISABLE KEYS */;
INSERT INTO `tblAssoc_Node` VALUES (1,4,1,0),(2,4,1,0),(3,4,1,0),(4,4,1,0),(5,4,1,0),(6,4,1,0),(7,4,1,0),(8,4,1,0),(9,4,1,0),(10,4,1,0),(11,4,1,0),(12,4,1,0),(13,4,1,0),(15,4,1,0),(16,8,1,0),(20522,4,1,0),(20523,4,1,0);
/*!40000 ALTER TABLE `tblAssoc_Node` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblAuditLog`
--

DROP TABLE IF EXISTS `tblAuditLog`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblAuditLog` (
  `intAuditLogID` int(11) NOT NULL AUTO_INCREMENT,
  `intID` int(11) NOT NULL DEFAULT '0',
  `strUsername` varchar(30) DEFAULT '',
  `strType` varchar(30) DEFAULT '',
  `strSection` varchar(30) DEFAULT '',
  `intEntityTypeID` int(11) DEFAULT NULL,
  `intEntityID` int(11) DEFAULT NULL,
  `intLoginEntityTypeID` int(11) DEFAULT NULL,
  `intLoginEntityID` int(11) DEFAULT NULL,
  `dtUpdated` datetime DEFAULT NULL,
  `intPassportID` int(11) NOT NULL DEFAULT '0',
  `intItemID` int(11) DEFAULT '0',
  `intUserID` int(11) DEFAULT '0',
  `strLocalName` varchar(150) DEFAULT '',
  PRIMARY KEY (`intAuditLogID`),
  KEY `index_intID` (`intID`),
  KEY `index_strUsername` (`strUsername`),
  KEY `index_AuditLog` (`intEntityTypeID`,`intEntityID`),
  KEY `index_passportID` (`intPassportID`)
) ENGINE=MyISAM AUTO_INCREMENT=17799504 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblAuditLog`
--

LOCK TABLES `tblAuditLog` WRITE;
/*!40000 ALTER TABLE `tblAuditLog` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblAuditLog` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblAuditLogDetails`
--

DROP TABLE IF EXISTS `tblAuditLogDetails`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblAuditLogDetails` (
  `intAuditLogDetailsID` int(11) NOT NULL AUTO_INCREMENT,
  `intAuditLogID` int(11) NOT NULL,
  `strField` varchar(30) DEFAULT '',
  `strPreviousValue` varchar(90) DEFAULT '',
  PRIMARY KEY (`intAuditLogDetailsID`),
  KEY `index_intAuditLogID` (`intAuditLogID`)
) ENGINE=MyISAM AUTO_INCREMENT=517 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblAuditLogDetails`
--

LOCK TABLES `tblAuditLogDetails` WRITE;
/*!40000 ALTER TABLE `tblAuditLogDetails` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblAuditLogDetails` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblAuth`
--

DROP TABLE IF EXISTS `tblAuth`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblAuth` (
  `intAuthID` int(11) NOT NULL AUTO_INCREMENT,
  `strUsername` varchar(12) NOT NULL DEFAULT '',
  `strPassword` varchar(12) NOT NULL DEFAULT '',
  `intLevel` int(11) NOT NULL DEFAULT '0',
  `intAssocID` int(11) NOT NULL DEFAULT '0',
  `intID` int(11) NOT NULL DEFAULT '0',
  `intLogins` int(11) DEFAULT NULL,
  `dtLastlogin` date DEFAULT NULL,
  `dtCreated` date DEFAULT NULL,
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `intReadOnly` tinyint(4) DEFAULT '0',
  `intRoleID` int(11) DEFAULT '0',
  PRIMARY KEY (`intAuthID`),
  UNIQUE KEY `index_username` (`strUsername`,`intID`,`intLevel`),
  KEY `index_intLevel` (`intLevel`,`strPassword`,`strUsername`),
  KEY `index_dual` (`intLevel`,`intID`)
) ENGINE=MyISAM AUTO_INCREMENT=3667386 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblAuth`
--

LOCK TABLES `tblAuth` WRITE;
/*!40000 ALTER TABLE `tblAuth` DISABLE KEYS */;
INSERT INTO `tblAuth` VALUES (3667360,'fifafi12','fsd09j454',5,12,12,0,'0000-00-00','2014-01-16','2014-01-16 22:33:01',0,0),(3667361,'fifasg16','sd98m49f5',5,16,16,0,'0000-00-00','2014-01-16','2014-01-16 22:33:29',0,0),(3667362,'10759023','25ij3jyo',1,0,10759023,NULL,NULL,'2014-01-20','2014-01-20 04:58:25',0,0),(3667363,'10759024','10qcwp8b',1,0,10759024,NULL,NULL,'2014-01-20','2014-01-20 06:37:07',0,0),(3667364,'10759025','49wlt38v',1,0,10759025,NULL,NULL,'2014-01-22','2014-01-22 02:21:50',0,0),(3667365,'10759026','991ocdqn',1,0,10759026,NULL,NULL,'2014-01-22','2014-01-22 23:11:12',0,0),(3667366,'10759027','20flnsix',1,0,10759027,NULL,NULL,'2014-01-23','2014-01-23 01:00:21',0,0),(3667367,'10759028','37woyhhm',1,0,10759028,NULL,NULL,'2014-01-23','2014-01-23 01:07:17',0,0),(3667368,'10759029','23windo4',1,0,10759029,NULL,NULL,'2014-01-23','2014-01-23 01:15:37',0,0),(3667369,'10759030','63qn48kz',1,0,10759030,NULL,NULL,'2014-01-23','2014-01-23 01:16:46',0,0),(3667370,'10759032','26hrmak9',1,0,10759032,NULL,NULL,'2014-01-23','2014-01-23 05:09:20',0,0),(3667371,'10759035','708rfx3a',1,0,10759035,NULL,NULL,'2014-01-23','2014-01-23 21:59:30',0,0),(3667372,'10759036','695aqdix',1,0,10759036,NULL,NULL,'2014-01-24','2014-01-24 02:51:49',0,0),(3667373,'10759037','73nrf1h9',1,0,10759037,NULL,NULL,'2014-01-24','2014-01-24 07:21:47',0,0),(3667374,'10759039','38zzhanq',1,0,10759039,NULL,NULL,'2014-01-25','2014-01-25 11:20:12',0,0),(3667375,'10759040','80bpgvrt',1,0,10759040,NULL,NULL,'2014-01-25','2014-01-25 11:44:06',0,0),(3667376,'10759042','82xytb6v',1,0,10759042,NULL,NULL,'2014-01-28','2014-01-28 03:55:22',0,0),(3667377,'10759043','87fnffii',1,0,10759043,NULL,NULL,'2014-01-28','2014-01-28 08:31:45',0,0),(3667378,'10759046','79jdmzq0',1,0,10759046,NULL,NULL,'2014-01-28','2014-01-28 09:19:41',0,0),(3667379,'10759050','46tse670',1,0,10759050,NULL,NULL,'2014-01-28','2014-01-28 10:14:27',0,0),(3667380,'10759051','46cb5cbl',1,0,10759051,NULL,NULL,'2014-01-28','2014-01-28 10:22:11',0,0),(3667381,'10759052','31f43zhu',1,0,10759052,NULL,NULL,'2014-05-01','2014-05-01 07:41:40',0,0),(3667382,'FIFAa20522','87sxrbiu',5,20522,20522,NULL,NULL,'2014-05-16','2014-05-16 01:33:55',0,0),(3667383,'FIFAa20523','31et1q68',5,20523,20523,NULL,NULL,'2014-05-16','2014-05-16 01:33:55',0,0),(3667384,'10759055','54f2lw1m',1,0,10759055,NULL,NULL,'2014-05-19','2014-05-19 02:50:16',0,0),(3667385,'10759056','278kw4l9',1,0,10759056,NULL,NULL,'2014-05-19','2014-05-19 04:49:01',0,0);
/*!40000 ALTER TABLE `tblAuth` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblBankAccount`
--

DROP TABLE IF EXISTS `tblBankAccount`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblBankAccount` (
  `intEntityTypeID` int(11) NOT NULL,
  `intEntityID` int(11) NOT NULL,
  `strBankCode` varchar(20) DEFAULT NULL,
  `strAccountNo` varchar(30) DEFAULT NULL,
  `strAccountName` varchar(250) DEFAULT NULL,
  `strMPEmail` varchar(127) DEFAULT '',
  `strMerchantAccUsername` varchar(100) DEFAULT '',
  `strMerchantAccPassword` varchar(100) DEFAULT '',
  `intNABPaymentOK` tinyint(4) DEFAULT '0',
  `intStopNABExport` tinyint(4) DEFAULT '0',
  `dtBankAccount` datetime DEFAULT NULL,
  PRIMARY KEY (`intEntityTypeID`,`intEntityID`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblBankAccount`
--

LOCK TABLES `tblBankAccount` WRITE;
/*!40000 ALTER TABLE `tblBankAccount` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblBankAccount` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblBankSplit`
--

DROP TABLE IF EXISTS `tblBankSplit`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblBankSplit` (
  `intSplitID` int(11) NOT NULL AUTO_INCREMENT,
  `strSplitName` varchar(100) DEFAULT '',
  `strFILE_Header_FinInst` varchar(10) DEFAULT '',
  `strFILE_Header_UserName` varchar(30) DEFAULT '',
  `strFILE_Header_UserNumber` varchar(30) DEFAULT '',
  `strFILE_Header_Desc` varchar(30) DEFAULT '',
  `intRealmID` int(11) DEFAULT NULL,
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `strFILE_Footer_BSB` varchar(10) DEFAULT '',
  `strFILE_Footer_AccountNum` varchar(10) DEFAULT '',
  `strFILE_Footer_Remitter` varchar(20) DEFAULT '',
  `strFILE_Footer_RefPrefix` varchar(10) DEFAULT '',
  PRIMARY KEY (`intSplitID`),
  KEY `index_realmID` (`intRealmID`)
) ENGINE=MyISAM AUTO_INCREMENT=4 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblBankSplit`
--

LOCK TABLES `tblBankSplit` WRITE;
/*!40000 ALTER TABLE `tblBankSplit` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblBankSplit` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblBulkRenewals`
--

DROP TABLE IF EXISTS `tblBulkRenewals`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblBulkRenewals` (
  `intBulkRenewalID` int(11) NOT NULL AUTO_INCREMENT,
  `intRenewalType` tinyint(4) DEFAULT '0',
  `strTemplate` varchar(200) DEFAULT NULL,
  `strFromAddress` varchar(200) DEFAULT NULL,
  `intEntityTypeID` int(11) NOT NULL,
  `intEntityID` int(11) NOT NULL,
  `dtAdded` datetime DEFAULT NULL,
  `dtSent` datetime DEFAULT NULL,
  PRIMARY KEY (`intBulkRenewalID`),
  KEY `index_dtSent` (`dtSent`)
) ENGINE=MyISAM AUTO_INCREMENT=1756 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblBulkRenewals`
--

LOCK TABLES `tblBulkRenewals` WRITE;
/*!40000 ALTER TABLE `tblBulkRenewals` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblBulkRenewals` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblBulkRenewalsRecipient`
--

DROP TABLE IF EXISTS `tblBulkRenewalsRecipient`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblBulkRenewalsRecipient` (
  `intBulkRenewalID` int(11) NOT NULL,
  `intEntityTypeID` int(11) NOT NULL,
  `intEntityID` int(11) NOT NULL,
  `strAddress` varchar(250) NOT NULL DEFAULT '',
  `dtAdded` datetime DEFAULT NULL,
  `strContent` text,
  PRIMARY KEY (`intBulkRenewalID`,`intEntityTypeID`,`intEntityID`,`strAddress`),
  KEY `index_person` (`intEntityTypeID`,`intEntityID`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblBulkRenewalsRecipient`
--

LOCK TABLES `tblBulkRenewalsRecipient` WRITE;
/*!40000 ALTER TABLE `tblBulkRenewalsRecipient` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblBulkRenewalsRecipient` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblBusinessRuleEntity`
--

DROP TABLE IF EXISTS `tblBusinessRuleEntity`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblBusinessRuleEntity` (
  `intBusinessRuleID` int(11) NOT NULL,
  `intRealmID` int(11) NOT NULL,
  `intSubRealmID` int(11) NOT NULL,
  `intEntityTypeID` int(11) NOT NULL,
  `intEntityID` int(11) NOT NULL,
  `intMinLevel` int(11) NOT NULL,
  `intMaxLevel` int(11) NOT NULL,
  PRIMARY KEY (`intBusinessRuleID`,`intRealmID`,`intSubRealmID`,`intEntityTypeID`,`intEntityID`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblBusinessRuleEntity`
--

LOCK TABLES `tblBusinessRuleEntity` WRITE;
/*!40000 ALTER TABLE `tblBusinessRuleEntity` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblBusinessRuleEntity` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblBusinessRuleSchedule`
--

DROP TABLE IF EXISTS `tblBusinessRuleSchedule`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblBusinessRuleSchedule` (
  `intBusinessRuleScheduleID` int(11) NOT NULL AUTO_INCREMENT,
  `intBusinessRuleID` int(11) DEFAULT '0',
  `strScheduleName` varchar(200) DEFAULT '',
  `intRealmID` int(11) DEFAULT '0',
  `intRealmSubTypeID` int(11) DEFAULT '0',
  `intScheduleByTableType` int(11) DEFAULT '0',
  `intScheduleByID` int(11) DEFAULT '0',
  `intDayToRun` tinyint(4) DEFAULT '0',
  `dtLastRun` datetime DEFAULT '0000-00-00 00:00:00',
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`intBusinessRuleScheduleID`),
  KEY `index_ruleID` (`intBusinessRuleID`),
  KEY `index_intScheduleByID` (`intScheduleByID`,`intScheduleByTableType`)
) ENGINE=MyISAM AUTO_INCREMENT=518 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblBusinessRuleSchedule`
--

LOCK TABLES `tblBusinessRuleSchedule` WRITE;
/*!40000 ALTER TABLE `tblBusinessRuleSchedule` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblBusinessRuleSchedule` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblBusinessRuleScheduleParams`
--

DROP TABLE IF EXISTS `tblBusinessRuleScheduleParams`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblBusinessRuleScheduleParams` (
  `intBusinessRuleParamID` int(11) NOT NULL AUTO_INCREMENT,
  `intBusinessRuleScheduleID` int(11) DEFAULT '0',
  `intParamTableType` int(11) DEFAULT '0',
  `intParamID` int(11) DEFAULT '0',
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`intBusinessRuleParamID`),
  KEY `index_scheduleID` (`intBusinessRuleScheduleID`),
  KEY `index_Params` (`intParamID`,`intParamTableType`)
) ENGINE=MyISAM AUTO_INCREMENT=301 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblBusinessRuleScheduleParams`
--

LOCK TABLES `tblBusinessRuleScheduleParams` WRITE;
/*!40000 ALTER TABLE `tblBusinessRuleScheduleParams` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblBusinessRuleScheduleParams` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblBusinessRules`
--

DROP TABLE IF EXISTS `tblBusinessRules`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblBusinessRules` (
  `intBusinessRuleID` int(11) NOT NULL AUTO_INCREMENT,
  `strRuleName` varchar(100) DEFAULT '',
  `strDescription` text,
  `strFunction` varchar(100) DEFAULT '',
  `intParamTableType` int(11) DEFAULT '0',
  `intNumParams` int(11) DEFAULT '0',
  `strNotificationHeaderText` text,
  `strNotificationRowsText` text,
  `strNotificationRowsURLs` text,
  `strRequiredOption` varchar(100) DEFAULT '',
  `strRuleOption` varchar(100) DEFAULT '',
  `intRuleOutcomeType` int(11) DEFAULT '0',
  `intOutcomeRows` tinyint(4) DEFAULT '0',
  `intAcknowledgeDtLastRun` int(11) DEFAULT '0',
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`intBusinessRuleID`)
) ENGINE=MyISAM AUTO_INCREMENT=9 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblBusinessRules`
--

LOCK TABLES `tblBusinessRules` WRITE;
/*!40000 ALTER TABLE `tblBusinessRules` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblBusinessRules` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblCardPrinted`
--

DROP TABLE IF EXISTS `tblCardPrinted`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblCardPrinted` (
  `intCardPrintedID` int(11) NOT NULL AUTO_INCREMENT,
  `intEventSelectionID` int(11) NOT NULL DEFAULT '0',
  `dtPrinted` datetime DEFAULT NULL,
  `strUsername` varchar(30) DEFAULT NULL,
  `intQty` int(11) DEFAULT '1',
  PRIMARY KEY (`intCardPrintedID`),
  KEY `key_intEventID` (`intEventSelectionID`)
) ENGINE=MyISAM AUTO_INCREMENT=37016 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblCardPrinted`
--

LOCK TABLES `tblCardPrinted` WRITE;
/*!40000 ALTER TABLE `tblCardPrinted` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblCardPrinted` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblCardToBePrinted`
--

DROP TABLE IF EXISTS `tblCardToBePrinted`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblCardToBePrinted` (
  `intMemberID` int(11) NOT NULL,
  `intMemberCardConfigID` int(11) NOT NULL,
  PRIMARY KEY (`intMemberID`,`intMemberCardConfigID`),
  KEY `index_cardtype` (`intMemberCardConfigID`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblCardToBePrinted`
--

LOCK TABLES `tblCardToBePrinted` WRITE;
/*!40000 ALTER TABLE `tblCardToBePrinted` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblCardToBePrinted` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblCertificationTypes`
--

DROP TABLE IF EXISTS `tblCertificationTypes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblCertificationTypes` (
  `intCertificationTypeID` int(11) NOT NULL AUTO_INCREMENT,
  `intRealmID` int(11) NOT NULL,
  `strCertificationType` varchar(50) NOT NULL,
  `strCertificationName` varchar(50) NOT NULL,
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `intActive` tinyint(4) NOT NULL DEFAULT '1',
  `intDisplayOrder` smallint(6) DEFAULT '0',
  PRIMARY KEY (`intCertificationTypeID`)
) ENGINE=InnoDB AUTO_INCREMENT=18 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblCertificationTypes`
--

LOCK TABLES `tblCertificationTypes` WRITE;
/*!40000 ALTER TABLE `tblCertificationTypes` DISABLE KEYS */;
INSERT INTO `tblCertificationTypes` VALUES (1,1,'COACH','AFC Professional Coaching Diploma','2014-12-16 22:48:19',1,1),(2,1,'COACH','AFC \'A\' Coaching Certificate','2014-12-16 22:48:19',1,2),(3,1,'COACH','AFC \'B\' Coaching Certificate','2014-12-16 22:48:19',1,3),(4,1,'COACH','AFC \'C\' Coaching Certificate','2014-12-16 22:48:19',1,4),(5,0,'COACH','AFC Goalkeeper Coach (Levels 1 - 3)','2014-12-16 22:48:19',1,5),(6,0,'COACH','AFC Conditioning Coach','2014-12-16 22:48:19',1,6),(7,0,'COACH','AFC Futsal Coach','2014-12-16 22:48:19',1,7),(8,1,'REFEREE','Class 3 Referee','2014-12-16 22:48:19',1,8),(9,1,'REFEREE','Class 2 Referee','2014-12-16 22:48:19',1,9),(10,1,'REFEREE','Class 1 Referee','2014-12-16 22:48:19',1,10),(11,1,'REFEREE','FIFA Referee','2014-12-19 04:38:26',1,12),(14,1,'COACH','FAS Grassroots Coaching Certificate','2014-12-17 03:06:10',1,10),(15,1,'COACH','Non-FAS/AFC Coaching Certification','2014-12-17 03:06:27',1,11),(16,1,'REFEREE','Grassroots Referee','2014-12-19 04:37:43',1,7),(17,1,'REFEREE','National Referee','2014-12-19 04:38:04',1,11);
/*!40000 ALTER TABLE `tblCertificationTypes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblClearance`
--

DROP TABLE IF EXISTS `tblClearance`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblClearance` (
  `intClearanceID` int(11) NOT NULL AUTO_INCREMENT,
  `intPersonID` int(11) NOT NULL DEFAULT '0',
  `intDestinationEntityID` int(11) NOT NULL DEFAULT '0',
  `strDestinationEntityName` varchar(100) DEFAULT NULL,
  `intSourceEntityID` int(11) NOT NULL DEFAULT '0',
  `strSourceEntityName` varchar(100) DEFAULT NULL,
  `intRealmID` int(11) NOT NULL DEFAULT '0',
  `intCurrentPathID` int(11) NOT NULL DEFAULT '0',
  `strPhoto` varchar(100) DEFAULT NULL,
  `dtApplied` datetime DEFAULT NULL,
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `strReasonForClearance` text,
  `strOtherNotes` text,
  `intClearanceStatus` int(11) DEFAULT NULL,
  `dtFinalised` datetime DEFAULT NULL,
  `intReasonForClearanceID` int(11) DEFAULT '0',
  `intCreatedFrom` int(11) DEFAULT '0',
  `strFilingNumber` varchar(20) DEFAULT '',
  `intClearancePriority` int(11) DEFAULT '0',
  `intRecStatus` int(11) DEFAULT '0',
  `intPlayerActive` tinyint(4) DEFAULT '0',
  `strReason` varchar(100) DEFAULT NULL,
  `intClearanceYear` int(11) DEFAULT '0',
  `dtReminder` date DEFAULT NULL,
  `strPersonType` varchar(20) DEFAULT '',
  `strPersonSubType` varchar(50) DEFAULT '',
  `strPersonLevel` varchar(10) DEFAULT '',
  `strPersonEntityRole` varchar(50) DEFAULT '',
  `strSport` varchar(20) DEFAULT '',
  `intOriginLevel` tinyint(4) DEFAULT '0',
  `strAgeLevel` varchar(100) DEFAULT '',
  PRIMARY KEY (`intClearanceID`),
  KEY `index_intPersonID` (`intPersonID`),
  KEY `index_intDestinationEntityID` (`intDestinationEntityID`),
  KEY `index_intSourceEntityID` (`intSourceEntityID`),
  KEY `index_intRealmID` (`intRealmID`),
  KEY `index_intClearanceStatus` (`intClearanceStatus`),
  KEY `index_intCurrentPathID` (`intCurrentPathID`),
  KEY `index_intClearanceYear` (`intClearanceYear`),
  KEY `index_FromYear` (`intCreatedFrom`,`intClearanceYear`),
  KEY `index_dtApplied` (`dtApplied`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblClearance`
--

LOCK TABLES `tblClearance` WRITE;
/*!40000 ALTER TABLE `tblClearance` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblClearance` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblClearanceDatesDue`
--

DROP TABLE IF EXISTS `tblClearanceDatesDue`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblClearanceDatesDue` (
  `intRealmID` int(11) DEFAULT '0',
  `intStateID` int(11) DEFAULT '0',
  `dtApplied` date DEFAULT NULL,
  `dtDue` date DEFAULT NULL,
  `dtReminder` date DEFAULT NULL,
  KEY `index_intStateIDRealmID` (`intStateID`,`intRealmID`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblClearanceDatesDue`
--

LOCK TABLES `tblClearanceDatesDue` WRITE;
/*!40000 ALTER TABLE `tblClearanceDatesDue` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblClearanceDatesDue` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblClearanceDevelopmentFees`
--

DROP TABLE IF EXISTS `tblClearanceDevelopmentFees`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblClearanceDevelopmentFees` (
  `intDevelopmentFeeID` int(11) NOT NULL AUTO_INCREMENT,
  `curDevelopmentFee` decimal(12,2) DEFAULT '0.00',
  `strTitle` varchar(100) DEFAULT '',
  `strNotes` text,
  `intRealmID` int(11) DEFAULT '0',
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `intCDRecStatus` tinyint(4) DEFAULT '1',
  PRIMARY KEY (`intDevelopmentFeeID`),
  KEY `index_intRealmID` (`intRealmID`)
) ENGINE=MyISAM AUTO_INCREMENT=108 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblClearanceDevelopmentFees`
--

LOCK TABLES `tblClearanceDevelopmentFees` WRITE;
/*!40000 ALTER TABLE `tblClearanceDevelopmentFees` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblClearanceDevelopmentFees` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblClearancePath`
--

DROP TABLE IF EXISTS `tblClearancePath`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblClearancePath` (
  `intClearancePathID` int(11) NOT NULL AUTO_INCREMENT,
  `intClearanceID` int(11) NOT NULL DEFAULT '0',
  `intTableType` int(11) DEFAULT NULL,
  `intTypeID` int(11) DEFAULT NULL,
  `intID` int(11) NOT NULL DEFAULT '0',
  `intOrder` int(11) DEFAULT '0',
  `intDirection` int(11) DEFAULT '0',
  `dtPathNodeStarted` datetime DEFAULT NULL,
  `dtPathNodeFinished` datetime DEFAULT NULL,
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `strReasonForClearance` text,
  `intClearanceStatus` int(11) DEFAULT NULL,
  `curPathFee` decimal(12,2) DEFAULT NULL,
  `strPathNotes` text,
  `strPathFilingNumber` varchar(30) DEFAULT '',
  `intClearanceDevelopmentFeeID` int(11) DEFAULT '0',
  `intPlayerFinancial` int(11) DEFAULT '0',
  `intPlayerSuspended` int(11) DEFAULT '0',
  `intDenialReasonID` int(11) DEFAULT '0',
  `strApprovedBy` varchar(100) DEFAULT NULL,
  `curDevelFee` decimal(12,2) DEFAULT '0.00',
  `strOtherDetails1` varchar(30) DEFAULT '',
  PRIMARY KEY (`intClearancePathID`),
  KEY `index_intTypeID` (`intTypeID`),
  KEY `index_intID` (`intID`),
  KEY `index_intClearanceStatus` (`intClearanceStatus`),
  KEY `index_intClearanceID` (`intClearanceID`)
) ENGINE=InnoDB AUTO_INCREMENT=56 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblClearancePath`
--

LOCK TABLES `tblClearancePath` WRITE;
/*!40000 ALTER TABLE `tblClearancePath` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblClearancePath` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblClearanceSettings`
--

DROP TABLE IF EXISTS `tblClearanceSettings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblClearanceSettings` (
  `intClearanceSettingID` int(11) NOT NULL AUTO_INCREMENT,
  `intID` int(11) NOT NULL DEFAULT '0',
  `intTypeID` int(11) NOT NULL DEFAULT '0',
  `intAssocTypeID` int(11) DEFAULT '0',
  `intAutoApproval` int(11) NOT NULL DEFAULT '0',
  `curDefaultFee` decimal(12,2) DEFAULT NULL,
  `dtDOBStart` datetime DEFAULT NULL,
  `dtDOBEnd` datetime DEFAULT NULL,
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `intRuleDirection` tinyint(4) DEFAULT '0',
  `intCheckAssocID` int(11) DEFAULT '0',
  `intPrimaryApprover` tinyint(4) DEFAULT '0',
  `intClearanceType` tinyint(4) DEFAULT '0',
  PRIMARY KEY (`intClearanceSettingID`),
  KEY `index_intID` (`intID`),
  KEY `index_intAssocTypeID` (`intAssocTypeID`),
  KEY `index_intTypeID` (`intTypeID`)
) ENGINE=MyISAM AUTO_INCREMENT=18269 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblClearanceSettings`
--

LOCK TABLES `tblClearanceSettings` WRITE;
/*!40000 ALTER TABLE `tblClearanceSettings` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblClearanceSettings` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblClub`
--

DROP TABLE IF EXISTS `tblClub`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblClub` (
  `intClubID` int(11) NOT NULL AUTO_INCREMENT,
  `strName` varchar(50) NOT NULL DEFAULT '',
  `strAbbrev` varchar(10) DEFAULT NULL,
  `strClubNo` varchar(50) DEFAULT NULL,
  `strContact` varchar(50) DEFAULT NULL,
  `strAddress1` varchar(50) DEFAULT NULL,
  `strAddress2` varchar(50) DEFAULT NULL,
  `strSuburb` varchar(50) DEFAULT NULL,
  `strPostalCode` varchar(15) DEFAULT NULL,
  `strState` varchar(20) DEFAULT NULL,
  `strPhone` varchar(20) DEFAULT NULL,
  `strFax` varchar(20) DEFAULT NULL,
  `strEmail` varchar(200) DEFAULT NULL,
  `strExtKey` varchar(20) DEFAULT NULL,
  `strCountry` varchar(50) DEFAULT NULL,
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `intRecStatus` tinyint(4) DEFAULT '1',
  `strIncNo` varchar(50) DEFAULT NULL,
  `strBusinessNo` varchar(50) DEFAULT NULL,
  `intAgeTypeID` int(11) DEFAULT NULL,
  `intClubTypeID` int(11) DEFAULT NULL,
  `strGroundName` varchar(50) DEFAULT NULL,
  `strGroundAddress` varchar(50) DEFAULT NULL,
  `strGroundSuburb` varchar(20) DEFAULT NULL,
  `strGroundPostalCode` varchar(10) DEFAULT NULL,
  `strColours` varchar(25) DEFAULT NULL,
  `strNotes` text,
  `strClubCustomCheckBox1` char(2) DEFAULT NULL,
  `strClubCustomCheckBox2` char(2) DEFAULT NULL,
  `strContactTitle` varchar(50) DEFAULT NULL,
  `strContactTitle2` varchar(50) DEFAULT NULL,
  `strContactName2` varchar(100) DEFAULT NULL,
  `strContactEmail2` varchar(200) DEFAULT NULL,
  `strContactPhone2` varchar(50) DEFAULT NULL,
  `strContactTitle3` varchar(50) DEFAULT NULL,
  `strContactName3` varchar(100) DEFAULT NULL,
  `strContactEmail3` varchar(200) DEFAULT NULL,
  `strContactPhone3` varchar(50) DEFAULT NULL,
  `strClubCustomStr1` varchar(50) DEFAULT '',
  `strClubCustomStr2` varchar(50) DEFAULT '',
  `strClubCustomStr3` varchar(50) DEFAULT '',
  `strClubCustomStr4` varchar(50) DEFAULT '',
  `strClubCustomStr5` varchar(50) DEFAULT '',
  `strClubCustomStr6` varchar(50) DEFAULT '',
  `strClubCustomStr7` varchar(50) DEFAULT '',
  `strClubCustomStr8` varchar(50) DEFAULT '',
  `strClubCustomStr9` varchar(50) DEFAULT '',
  `strClubCustomStr10` varchar(50) DEFAULT '',
  `strClubCustomStr11` varchar(50) DEFAULT '',
  `strClubCustomStr12` varchar(50) DEFAULT '',
  `strClubCustomStr13` varchar(50) DEFAULT '',
  `strClubCustomStr14` varchar(50) DEFAULT '',
  `strClubCustomStr15` varchar(50) DEFAULT '',
  `dblClubCustomDbl1` double DEFAULT '0',
  `dblClubCustomDbl2` double DEFAULT '0',
  `dblClubCustomDbl3` double DEFAULT '0',
  `dblClubCustomDbl4` double DEFAULT '0',
  `dblClubCustomDbl5` double DEFAULT '0',
  `dblClubCustomDbl6` double DEFAULT '0',
  `dblClubCustomDbl7` double DEFAULT '0',
  `dblClubCustomDbl8` double DEFAULT '0',
  `dblClubCustomDbl9` double DEFAULT '0',
  `dblClubCustomDbl10` double DEFAULT '0',
  `dtClubCustomDt1` date DEFAULT NULL,
  `dtClubCustomDt2` date DEFAULT NULL,
  `dtClubCustomDt3` date DEFAULT NULL,
  `dtClubCustomDt4` date DEFAULT NULL,
  `dtClubCustomDt5` date DEFAULT NULL,
  `intClubCustomLU1` int(11) DEFAULT '0',
  `intClubCustomLU2` int(11) DEFAULT '0',
  `intClubCustomLU3` int(11) DEFAULT '0',
  `intClubCustomLU4` int(11) DEFAULT '0',
  `intClubCustomLU5` int(11) DEFAULT '0',
  `intClubCustomLU6` int(11) DEFAULT '0',
  `intClubCustomLU7` int(11) DEFAULT '0',
  `intClubCustomLU8` int(11) DEFAULT '0',
  `intClubCustomLU9` int(11) DEFAULT '0',
  `intClubCustomLU10` int(11) DEFAULT '0',
  `intClubCustomBool1` tinyint(4) DEFAULT '0',
  `intClubCustomBool2` tinyint(4) DEFAULT '0',
  `intClubCustomBool3` tinyint(4) DEFAULT '0',
  `intClubCustomBool4` tinyint(4) DEFAULT '0',
  `intClubCustomBool5` tinyint(4) DEFAULT '0',
  `strWebURL` varchar(200) DEFAULT '',
  `intExcludeClubChampionships` tinyint(4) DEFAULT '0',
  `intApprovePayment` tinyint(4) DEFAULT '0',
  `intClubFeeAllocationType` tinyint(4) DEFAULT '0',
  `strLGA` varchar(250) DEFAULT NULL,
  `dtUpdated` datetime DEFAULT NULL,
  `strDevelRegion` varchar(250) DEFAULT NULL,
  `strClubZone` varchar(250) DEFAULT NULL,
  `intSPAgreement_NewEntity` tinyint(4) DEFAULT '1',
  `intClubCategoryID` int(11) DEFAULT '0',
  `intGoodSport` int(11) DEFAULT NULL,
  PRIMARY KEY (`intClubID`),
  KEY `index_strName` (`strName`),
  KEY `index_dual` (`intRecStatus`,`intClubID`)
) ENGINE=MyISAM AUTO_INCREMENT=208394 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblClub`
--

LOCK TABLES `tblClub` WRITE;
/*!40000 ALTER TABLE `tblClub` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblClub` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblClubCharacteristics`
--

DROP TABLE IF EXISTS `tblClubCharacteristics`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblClubCharacteristics` (
  `intCharacteristicID` int(11) NOT NULL,
  `intClubID` int(11) NOT NULL,
  PRIMARY KEY (`intCharacteristicID`,`intClubID`),
  KEY `index_club` (`intClubID`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblClubCharacteristics`
--

LOCK TABLES `tblClubCharacteristics` WRITE;
/*!40000 ALTER TABLE `tblClubCharacteristics` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblClubCharacteristics` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblClubGrades`
--

DROP TABLE IF EXISTS `tblClubGrades`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblClubGrades` (
  `intGradeID` int(11) NOT NULL AUTO_INCREMENT,
  `strGradeName` varchar(30) DEFAULT NULL,
  `intRealmID` int(11) DEFAULT NULL,
  `intSubRealmID` int(11) DEFAULT NULL,
  `intOrderID` int(11) DEFAULT '5',
  `intStatus` int(11) DEFAULT NULL,
  `intAge` int(11) DEFAULT NULL,
  PRIMARY KEY (`intGradeID`),
  KEY `index_intGradeID` (`intGradeID`)
) ENGINE=MyISAM AUTO_INCREMENT=15 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblClubGrades`
--

LOCK TABLES `tblClubGrades` WRITE;
/*!40000 ALTER TABLE `tblClubGrades` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblClubGrades` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblConfig`
--

DROP TABLE IF EXISTS `tblConfig`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblConfig` (
  `intConfigID` int(11) NOT NULL AUTO_INCREMENT,
  `intEntityID` int(11) NOT NULL DEFAULT '0',
  `intLevelID` int(11) NOT NULL DEFAULT '0',
  `intTypeID` int(11) NOT NULL DEFAULT '0',
  `strPerm` varchar(40) DEFAULT NULL,
  `strValue` varchar(250) DEFAULT NULL,
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `intRealmID` int(11) NOT NULL DEFAULT '0',
  `intSubTypeID` int(11) NOT NULL DEFAULT '0',
  `strType` varchar(20) DEFAULT '',
  PRIMARY KEY (`intConfigID`),
  KEY `index_Entity` (`intLevelID`,`intEntityID`),
  KEY `index_EntityType` (`intLevelID`,`intEntityID`,`intTypeID`),
  KEY `index_EntityTypePerm` (`intLevelID`,`intEntityID`,`intTypeID`,`strPerm`),
  KEY `index_intRealmID` (`intRealmID`),
  KEY `index_multi` (`intRealmID`,`intLevelID`,`intEntityID`,`intTypeID`)
) ENGINE=MyISAM AUTO_INCREMENT=3569546 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblConfig`
--

LOCK TABLES `tblConfig` WRITE;
/*!40000 ALTER TABLE `tblConfig` DISABLE KEYS */;
INSERT INTO `tblConfig` VALUES (3569534,1,5,0,'strPassportNationality','6','2014-05-01 07:53:27',1,0,'MemberList'),(3569533,1,5,0,'intGender','5','2014-05-01 07:53:27',1,0,'MemberList'),(3569532,1,5,0,'dtDOB','4','2014-05-01 07:53:27',1,0,'MemberList'),(3569531,1,5,0,'strSurname','3','2014-05-01 07:53:27',1,0,'MemberList'),(3569530,1,5,0,'strFirstname','2','2014-05-01 07:53:27',1,0,'MemberList'),(3569529,1,5,0,'intRecStatus','1','2014-05-01 07:53:27',1,0,'MemberList'),(3569516,12,5,0,'Seasons.intCoachStatus','9','2014-01-23 22:23:23',1,0,'MemberList'),(3569515,12,5,0,'Seasons.intPlayerStatus','8','2014-01-23 22:23:23',1,0,'MemberList'),(3569514,12,5,0,'intRecStatus','7','2014-01-23 22:23:23',1,0,'MemberList'),(3569513,12,5,0,'strPassportNationality','6','2014-01-23 22:23:23',1,0,'MemberList'),(3569512,12,5,0,'intGender','5','2014-01-23 22:23:23',1,0,'MemberList'),(3569511,12,5,0,'dtDOB','4','2014-01-23 22:23:23',1,0,'MemberList'),(3569510,12,5,0,'strSurname','3','2014-01-23 22:23:23',1,0,'MemberList'),(3569509,12,5,0,'strFirstname','2','2014-01-23 22:23:23',1,0,'MemberList'),(3569508,12,5,0,'strMemberNo','1','2014-01-23 22:23:23',1,0,'MemberList'),(3569498,13,5,0,'strMemberNo','1','2014-01-23 22:05:50',1,0,'MemberList'),(3569499,13,5,0,'intRecStatus','2','2014-01-23 22:05:50',1,0,'MemberList'),(3569500,13,5,0,'strFirstname','3','2014-01-23 22:05:50',1,0,'MemberList'),(3569501,13,5,0,'strSurname','4','2014-01-23 22:05:50',1,0,'MemberList'),(3569502,13,5,0,'dtDOB','5','2014-01-23 22:05:50',1,0,'MemberList'),(3569503,13,5,0,'intGender','6','2014-01-23 22:05:50',1,0,'MemberList'),(3569504,13,5,0,'strPassportNationality','7','2014-01-23 22:05:50',1,0,'MemberList'),(3569505,13,5,0,'Coach.intActive','8','2014-01-23 22:05:50',1,0,'MemberList'),(3569506,13,5,0,'Umpire.intActive','9','2014-01-23 22:05:50',1,0,'MemberList'),(3569507,13,5,0,'SORT','intRecStatus','2014-01-23 22:05:50',1,0,'MemberList'),(3569517,12,5,0,'Seasons.intUmpireStatus','10','2014-01-23 22:23:23',1,0,'MemberList'),(3569518,12,5,0,'SORT','intRecStatus','2014-01-23 22:23:23',1,0,'MemberList'),(3569519,16,5,0,'intRecStatus','1','2014-01-24 03:36:37',1,0,'MemberList'),(3569520,16,5,0,'strFirstname','2','2014-01-24 03:36:37',1,0,'MemberList'),(3569521,16,5,0,'strSurname','3','2014-01-24 03:36:37',1,0,'MemberList'),(3569522,16,5,0,'dtDOB','4','2014-01-24 03:36:37',1,0,'MemberList'),(3569523,16,5,0,'intGender','5','2014-01-24 03:36:37',1,0,'MemberList'),(3569524,16,5,0,'strPassportNationality','6','2014-01-24 03:36:37',1,0,'MemberList'),(3569525,16,5,0,'Seasons.intPlayerStatus','7','2014-01-24 03:36:37',1,0,'MemberList'),(3569526,16,5,0,'Seasons.intCoachStatus','8','2014-01-24 03:36:37',1,0,'MemberList'),(3569527,16,5,0,'Seasons.intUmpireStatus','9','2014-01-24 03:36:37',1,0,'MemberList'),(3569528,16,5,0,'SORT','intRecStatus','2014-01-24 03:36:37',1,0,'MemberList'),(3569535,1,5,0,'SORT','strSurname','2014-05-01 07:53:27',1,0,'MemberList');
/*!40000 ALTER TABLE `tblConfig` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblContactRoles`
--

DROP TABLE IF EXISTS `tblContactRoles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblContactRoles` (
  `intRoleID` int(11) NOT NULL AUTO_INCREMENT,
  `intRealmID` int(11) DEFAULT '0',
  `intRealmSubTypeID` int(11) DEFAULT '0',
  `intRoleOrder` int(11) DEFAULT '0',
  `intShowAtTop` int(11) DEFAULT '0',
  `intAllowMultiple` int(11) DEFAULT '0',
  `strRoleName` varchar(50) DEFAULT '',
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`intRoleID`),
  KEY `index_Realm` (`intRealmID`,`intRealmSubTypeID`)
) ENGINE=MyISAM AUTO_INCREMENT=42 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblContactRoles`
--

LOCK TABLES `tblContactRoles` WRITE;
/*!40000 ALTER TABLE `tblContactRoles` DISABLE KEYS */;
INSERT INTO `tblContactRoles` VALUES (39,1,0,1,1,1,'President','2014-08-04 06:33:39'),(40,1,0,1,1,1,'Secretary','2014-08-04 06:33:46'),(41,1,0,1,0,1,'Other','2014-08-04 06:33:53');
/*!40000 ALTER TABLE `tblContactRoles` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblContacts`
--

DROP TABLE IF EXISTS `tblContacts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblContacts` (
  `intContactID` int(11) NOT NULL AUTO_INCREMENT,
  `intContactRoleID` int(11) DEFAULT '0',
  `intRealmID` int(11) DEFAULT '0',
  `intAssocID` int(11) DEFAULT '0',
  `intClubID` int(11) DEFAULT '0',
  `intTeamID` int(11) DEFAULT '0',
  `intMemberID` int(11) DEFAULT '0',
  `strContactFirstname` varchar(50) DEFAULT '',
  `strContactSurname` varchar(50) DEFAULT '',
  `strContactEmail` varchar(100) DEFAULT '',
  `strContactMobile` varchar(20) DEFAULT '',
  `intReceiveOffers` tinyint(4) DEFAULT '0',
  `intProductUpdates` tinyint(4) DEFAULT '0',
  `intFnCompAdmin` tinyint(4) DEFAULT '0',
  `intFnSocial` tinyint(4) DEFAULT '0',
  `intFnWebsite` tinyint(4) DEFAULT '0',
  `intFnClearances` tinyint(4) DEFAULT '0',
  `intFnSponsorship` tinyint(4) DEFAULT '0',
  `intFnPayments` tinyint(4) DEFAULT '0',
  `intFnLegal` tinyint(4) DEFAULT '0',
  `intFnRegistrations` tinyint(4) DEFAULT '0',
  `intPrimaryContact` tinyint(4) DEFAULT '0',
  `intShowInLocator` tinyint(4) DEFAULT '0',
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `dtLastUpdated` datetime DEFAULT NULL,
  `intContactGender` tinyint(4) DEFAULT '0',
  PRIMARY KEY (`intContactID`),
  KEY `index_intRealmID` (`intRealmID`),
  KEY `index_intAssocID` (`intAssocID`),
  KEY `index_ClubID` (`intClubID`,`intAssocID`),
  KEY `index_teamID` (`intTeamID`)
) ENGINE=MyISAM AUTO_INCREMENT=495680 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblContacts`
--

LOCK TABLES `tblContacts` WRITE;
/*!40000 ALTER TABLE `tblContacts` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblContacts` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblCurrencies`
--

DROP TABLE IF EXISTS `tblCurrencies`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblCurrencies` (
  `intCurrencyID` int(11) NOT NULL AUTO_INCREMENT,
  `strCountryName` varchar(50) DEFAULT '',
  `strCurrencyName` varchar(100) DEFAULT '',
  `intRealmID` int(11) DEFAULT '0',
  `strCountryAbbrev` varchar(10) DEFAULT '',
  PRIMARY KEY (`intCurrencyID`)
) ENGINE=MyISAM AUTO_INCREMENT=1066 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblCurrencies`
--

LOCK TABLES `tblCurrencies` WRITE;
/*!40000 ALTER TABLE `tblCurrencies` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblCurrencies` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblCustomFields`
--

DROP TABLE IF EXISTS `tblCustomFields`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblCustomFields` (
  `intCustomFieldsID` int(11) NOT NULL AUTO_INCREMENT,
  `strDBFName` varchar(30) NOT NULL DEFAULT '',
  `strName` varchar(100) NOT NULL DEFAULT '',
  `intLocked` smallint(6) NOT NULL DEFAULT '0',
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `intRealmID` int(11) NOT NULL DEFAULT '0',
  `intRecStatus` tinyint(4) DEFAULT '0',
  `intSubTypeID` int(11) DEFAULT '0',
  PRIMARY KEY (`intCustomFieldsID`),
  KEY `index_intRealmID` (`intRealmID`),
  KEY `INDEX_intRecStatus` (`intRecStatus`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblCustomFields`
--

LOCK TABLES `tblCustomFields` WRITE;
/*!40000 ALTER TABLE `tblCustomFields` DISABLE KEYS */;
INSERT INTO `tblCustomFields` VALUES (1,'intNatCustomLU1','Religion',0,'2014-10-08 23:30:04',1,1,0),(2,'intNatCustomLU2','Highest Education Level',0,'2014-11-17 00:13:22',1,1,0),(3,'intNatCustomLU3','Occupation',0,'2014-10-08 23:30:34',1,1,0),(4,'intNatCustomLU4','Blood Type',0,'2014-10-09 02:35:44',1,1,0),(6,'intNatCustomLU5','Are you currently enlisted in SAF/SCDF/SPF ?',0,'2015-01-12 03:19:11',1,1,0);
/*!40000 ALTER TABLE `tblCustomFields` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblCustomReports`
--

DROP TABLE IF EXISTS `tblCustomReports`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblCustomReports` (
  `intCustomReportsID` int(11) NOT NULL AUTO_INCREMENT,
  `strName` varchar(30) DEFAULT NULL,
  `strSQL` text,
  `intTypeID` int(11) NOT NULL DEFAULT '0',
  `strConfig` text,
  `strTemplateFile` varchar(30) DEFAULT NULL,
  `intMinLevel` int(11) NOT NULL DEFAULT '0',
  `intMaxLevel` int(11) NOT NULL DEFAULT '0',
  `strDataRoutine` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`intCustomReportsID`),
  KEY `index_strName` (`strName`)
) ENGINE=MyISAM AUTO_INCREMENT=59 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblCustomReports`
--

LOCK TABLES `tblCustomReports` WRITE;
/*!40000 ALTER TABLE `tblCustomReports` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblCustomReports` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblCustomReportsUser`
--

DROP TABLE IF EXISTS `tblCustomReportsUser`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblCustomReportsUser` (
  `intCustomReportID` int(11) NOT NULL DEFAULT '0',
  `intUserID` int(11) NOT NULL DEFAULT '0',
  `intUserTypeID` int(11) NOT NULL DEFAULT '0',
  `intRealmID` int(11) NOT NULL DEFAULT '0',
  `intSubRealmID` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`intRealmID`,`intSubRealmID`,`intUserTypeID`,`intUserID`,`intCustomReportID`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblCustomReportsUser`
--

LOCK TABLES `tblCustomReportsUser` WRITE;
/*!40000 ALTER TABLE `tblCustomReportsUser` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblCustomReportsUser` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblDBLevelConfig`
--

DROP TABLE IF EXISTS `tblDBLevelConfig`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblDBLevelConfig` (
  `intDBConfigID` int(11) NOT NULL AUTO_INCREMENT,
  `intDBConfigGroupID` int(11) NOT NULL DEFAULT '0',
  `intLevelID` int(11) NOT NULL DEFAULT '0',
  `intPlural` tinyint(4) NOT NULL DEFAULT '0',
  `strName` varchar(150) DEFAULT NULL,
  `strAbbrev` varchar(100) DEFAULT NULL,
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `intSubTypeID` int(11) DEFAULT '0',
  PRIMARY KEY (`intDBConfigID`),
  KEY `index_intDBConfigGroupID` (`intDBConfigGroupID`),
  KEY `index_intLevelID` (`intLevelID`)
) ENGINE=MyISAM AUTO_INCREMENT=207 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblDBLevelConfig`
--

LOCK TABLES `tblDBLevelConfig` WRITE;
/*!40000 ALTER TABLE `tblDBLevelConfig` DISABLE KEYS */;
INSERT INTO `tblDBLevelConfig` VALUES (35,1,100,0,'National Body',NULL,'2005-11-15 02:55:59',0),(36,1,100,1,'National Bodies',NULL,'2005-11-15 02:55:59',0),(37,1,30,0,'State',NULL,'2005-11-15 02:55:59',0),(38,1,30,1,'States',NULL,'2005-11-15 02:55:59',0),(39,1,20,0,'Region',NULL,'2005-11-15 02:55:59',0),(40,1,20,1,'Regions',NULL,'2005-11-15 02:55:59',0),(41,1,10,1,'Zones',NULL,'2005-11-15 02:55:59',0),(42,1,10,0,'Zone',NULL,'2005-11-15 02:55:59',0),(43,1,5,0,'District',NULL,'2014-01-14 20:58:34',0),(44,1,5,1,'Districts',NULL,'2014-01-14 20:58:40',0),(45,1,3,1,'Clubs',NULL,'2005-11-15 02:55:59',0),(46,1,3,0,'Club',NULL,'2005-11-15 02:55:59',0),(47,1,2,0,'Team',NULL,'2005-11-15 02:55:59',0),(48,1,2,1,'Teams',NULL,'2005-11-15 02:55:59',0),(49,1,1,0,'Person',NULL,'2014-07-30 04:28:12',0),(50,1,1,1,'People',NULL,'2014-07-30 04:28:19',0),(51,1,4,1,'Competitions',NULL,'2005-11-15 02:55:59',0),(52,1,4,0,'Competition',NULL,'2005-11-15 02:55:59',0),(203,1,3,1,'Entities','Orgs','2014-04-15 06:59:50',2),(204,1,3,0,'Entity','Org','2014-04-15 06:59:37',2),(205,1,5,1,'Associations','','2014-01-16 23:03:46',2),(206,1,5,0,'Association','','2014-01-16 23:03:46',2);
/*!40000 ALTER TABLE `tblDBLevelConfig` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblDUPLICATE_MEMBERS`
--

DROP TABLE IF EXISTS `tblDUPLICATE_MEMBERS`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblDUPLICATE_MEMBERS` (
  `intDMemberID` int(11) DEFAULT '0',
  `strDFirstname` varchar(100) NOT NULL DEFAULT '',
  `strDSurname` varchar(100) NOT NULL DEFAULT '',
  PRIMARY KEY (`strDFirstname`,`strDSurname`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblDUPLICATE_MEMBERS`
--

LOCK TABLES `tblDUPLICATE_MEMBERS` WRITE;
/*!40000 ALTER TABLE `tblDUPLICATE_MEMBERS` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblDUPLICATE_MEMBERS` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblDashboardConfig`
--

DROP TABLE IF EXISTS `tblDashboardConfig`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblDashboardConfig` (
  `intDashboardConfigID` int(11) NOT NULL AUTO_INCREMENT,
  `intEntityTypeID` int(11) NOT NULL,
  `intEntityID` int(11) NOT NULL,
  `strDashboardItemType` varchar(50) DEFAULT NULL,
  `strDashboardItem` varchar(50) DEFAULT NULL,
  `intOrder` int(11) NOT NULL DEFAULT '5',
  PRIMARY KEY (`intDashboardConfigID`),
  KEY `index_entity` (`intEntityTypeID`,`intEntityID`)
) ENGINE=MyISAM AUTO_INCREMENT=20368 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblDashboardConfig`
--

LOCK TABLES `tblDashboardConfig` WRITE;
/*!40000 ALTER TABLE `tblDashboardConfig` DISABLE KEYS */;
INSERT INTO `tblDashboardConfig` VALUES (20355,100,1,'graph','playeragegroups_historical',8),(20356,100,1,'graph','playerages',9),(20354,100,1,'graph','newmembers_historical',7),(20353,100,1,'graph','umpire_historical',6),(20248,5,2,'graph','member_historical',1),(20249,5,2,'graph','playergenders',2),(20250,5,2,'graph','playergender_historical',3),(20251,5,2,'graph','player_historical',4),(20252,5,2,'graph','playeragegroups_historical',5),(20253,5,2,'graph','playerages',6),(20254,5,2,'graph','newmembers_historical',7),(20255,5,2,'graph','regoformembers_historical',8),(20256,5,2,'graph','clrout_historical',9),(20257,5,2,'graph','txnval_historical',10),(20351,100,1,'graph','player_historical',4),(20352,100,1,'graph','coach_historical',5),(20350,100,1,'graph','teams_historical',3),(20296,100,5,'graph','clrout_historical',9),(20295,100,5,'graph','playerages',8),(20294,100,5,'graph','newmembers_historical',7),(20293,100,5,'graph','umpire_historical',6),(20292,100,5,'graph','coach_historical',5),(20291,100,5,'graph','player_historical',4),(20290,100,5,'graph','playergender_historical',3),(20289,100,5,'graph','playergenders',2),(20288,100,5,'graph','member_historical',1),(20297,100,5,'graph','txnval_historical',10),(20325,5,16,'graph','regoformembers_historical',8),(20323,5,16,'graph','umpire_historical',6),(20324,5,16,'graph','newmembers_historical',7),(20322,5,16,'graph','coach_historical',5),(20321,5,16,'graph','player_historical',4),(20320,5,16,'graph','playergender_historical',3),(20319,5,16,'graph','playergenders',2),(20318,5,16,'graph','member_historical',1),(20326,5,16,'graph','clrout_historical',9),(20327,5,16,'graph','txnval_historical',10),(20349,100,1,'graph','txnval_historical',2),(20348,100,1,'graph','clrin_historical',1),(20338,20,14,'graph','member_historical',1),(20339,20,14,'graph','playergenders',2),(20340,20,14,'graph','teams_historical',3),(20341,20,14,'graph','player_historical',4),(20342,20,14,'graph','coach_historical',5),(20343,20,14,'graph','umpire_historical',6),(20344,20,14,'graph','newmembers_historical',7),(20345,20,14,'graph','regoformembers_historical',8),(20346,20,14,'graph','clrout_historical',9),(20347,20,14,'graph','txnval_historical',10),(20357,100,1,'graph','txnval_historical',10),(20358,3,35,'graph','other1_historical',1),(20359,3,35,'graph','playergenders',2),(20360,3,35,'graph','playergender_historical',3),(20361,3,35,'graph','player_historical',4),(20362,3,35,'graph','coach_historical',5),(20363,3,35,'graph','umpire_historical',6),(20364,3,35,'graph','newmembers_historical',7),(20365,3,35,'graph','regoformembers_historical',8),(20366,3,35,'graph','clrout_historical',9),(20367,3,35,'graph','txnval_historical',10);
/*!40000 ALTER TABLE `tblDashboardConfig` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblDefCodes`
--

DROP TABLE IF EXISTS `tblDefCodes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblDefCodes` (
  `intCodeID` int(11) NOT NULL AUTO_INCREMENT,
  `intAssocID` int(11) NOT NULL DEFAULT '0',
  `intType` int(11) DEFAULT NULL,
  `strName` varchar(100) DEFAULT '',
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `intRealmID` int(11) NOT NULL DEFAULT '0',
  `intRecStatus` tinyint(4) DEFAULT '0',
  `intSubTypeID` int(11) DEFAULT '0',
  `intDisplayOrder` smallint(6) DEFAULT '0',
  PRIMARY KEY (`intCodeID`),
  KEY `index_intAssocID` (`intAssocID`),
  KEY `index_intAssocIDTypeID` (`intAssocID`,`intType`),
  KEY `index_strName` (`strName`),
  KEY `index_Lookup` (`intAssocID`,`intType`),
  KEY `IDNEX_intRecStatus` (`intRecStatus`),
  KEY `index_intRealmAssoc` (`intRealmID`,`intAssocID`),
  KEY `index_intRealmAssocType` (`intRealmID`,`intAssocID`,`intType`)
) ENGINE=MyISAM AUTO_INCREMENT=558021 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblDefCodes`
--

LOCK TABLES `tblDefCodes` WRITE;
/*!40000 ALTER TABLE `tblDefCodes` DISABLE KEYS */;
INSERT INTO `tblDefCodes` VALUES (557705,0,-53,'Muslim','2014-10-09 02:34:47',1,1,0,0),(557707,0,-64,'AB+','2014-10-09 02:35:08',1,1,0,0),(557708,0,-53,'Other','2014-10-09 02:34:47',1,1,0,0),(557709,0,-8,'CHINESE','2014-12-05 07:35:50',1,1,0,1),(557710,0,-8,'MALAY ','2014-12-05 07:36:00',1,1,0,2),(557713,0,-64,'B+','2014-10-09 02:35:08',1,1,0,0),(557714,0,-53,'Catholic','2014-10-09 02:34:47',1,1,0,0),(557715,0,-8,'CAUCASIAN','2014-12-05 07:36:58',1,1,0,6),(557716,0,-53,'Christian','2014-10-09 02:34:47',1,1,0,0),(557718,0,-8,'AFRICAN','2014-12-05 10:07:26',0,-1,0,99),(557719,0,-64,'O+','2014-10-09 02:35:08',1,1,0,0),(557720,0,-8,'JAPANESE','2014-12-05 10:07:26',0,-1,0,99),(557721,0,-53,'Hindi','2014-10-09 02:34:47',1,1,0,0),(557722,0,-8,'INDIAN','2014-12-05 07:36:13',1,1,0,3),(557723,0,-64,'A+','2014-10-09 02:35:08',1,1,0,0),(557726,0,-8,'BOYANESE','2014-12-05 10:07:26',0,-1,0,99),(557727,0,-53,'Tao','2014-10-09 02:34:47',1,1,0,0),(557728,0,-64,'A-','2014-10-09 02:35:08',1,1,0,0),(557733,0,-53,'Buddhist','2014-10-09 02:34:47',1,1,0,0),(557734,0,-8,'JAVANESE','2014-12-05 10:07:26',0,-1,0,99),(557735,0,-64,'O-','2014-10-09 02:35:08',1,1,0,0),(557737,0,-53,'None','2014-10-09 02:34:47',1,1,0,0),(557738,0,-64,'B-','2014-10-09 02:35:08',1,1,0,0),(557739,0,-64,'AB-','2014-10-09 02:35:08',1,1,0,0),(557740,0,-8,'NIGERIAN','2014-12-05 10:07:26',0,-1,0,99),(557741,0,-8,'CAMEROONIAN','2014-12-05 10:07:26',0,-1,0,99),(557742,0,-8,'SINGAPOREAN','2014-12-05 10:07:26',0,-1,0,99),(557747,0,-8,'BRITISH','2014-12-05 10:07:26',0,-1,0,99),(557755,0,-8,'BUGIS','2014-12-05 10:07:26',0,-1,0,99),(557756,0,-8,'EURASIAN','2014-12-05 07:36:29',1,1,0,4),(557761,0,-8,'MALABARI','2014-12-05 10:07:26',0,-1,0,99),(557762,0,-8,'BURNESE  ','2014-12-05 10:07:26',0,-1,0,99),(557764,0,-8,'PAKISTAN INDIAN','2014-12-05 10:07:26',0,-1,0,99),(557765,0,-8,'FILIPINO','2014-12-05 10:07:26',0,-1,0,99),(557768,0,-8,'INDONESIAN','2014-12-05 10:07:26',0,-1,0,99),(558020,0,-54,'Other','2014-12-16 05:43:35',1,1,0,10),(557770,0,-8,'PAKISTANI','2014-12-05 10:07:26',0,-1,0,99),(557771,0,-8,'THAI','2014-12-05 10:07:26',0,-1,0,99),(557774,0,-8,'BRAZILIAN','2014-12-05 10:07:26',0,-1,0,99),(557778,0,-8,'CHILEAN','2014-12-05 10:07:26',0,-1,0,99),(557779,0,-8,'PUNJABI','2014-12-05 10:07:26',0,-1,0,99),(557780,0,-8,'AMBONESE','2014-12-05 10:07:26',0,-1,0,99),(557781,0,-8,'SIKH','2014-12-05 07:36:42',1,1,0,5),(557788,0,-8,'IGBO','2014-12-05 10:07:26',0,-1,0,99),(557789,0,-8,'URBOBO','2014-12-05 10:07:26',0,-1,0,99),(557790,0,-8,'TUNISIAN','2014-12-05 10:07:26',0,-1,0,99),(557791,0,-8,'BAMILEKE','2014-12-05 10:07:26',0,-1,0,99),(557792,0,-8,'DOUALA','2014-12-05 10:07:26',0,-1,0,99),(557793,0,-8,'IMBO','2014-12-05 10:07:26',0,-1,0,99),(557795,0,-8,'ARAB','2014-12-05 10:07:26',0,-1,0,99),(557796,0,-8,'EGYPTIAN','2014-12-05 10:07:26',0,-1,0,99),(557797,0,-8,'IRANIAN','2014-12-05 10:07:26',0,-1,0,99),(557799,0,-8,'KOREAN','2014-12-05 10:07:26',0,-1,0,99),(557800,0,-8,'CEYLONESE','2014-12-05 10:07:26',0,-1,0,99),(557806,0,-8,'VIETNAMESE','2014-12-05 10:07:26',0,-1,0,99),(557808,0,-8,'DANISH','2014-12-05 10:07:26',0,-1,0,99),(557809,0,-8,'OTHER','2014-12-05 10:07:59',1,1,0,99),(557811,0,-8,'FRENCH','2014-12-05 10:07:26',0,-1,0,99),(557814,0,-8,'MORROCO','2014-12-05 10:07:26',0,-1,0,99),(557816,0,-8,'SWEDEN','2014-12-05 10:07:26',0,-1,0,99),(557819,0,-8,'LATIN','2014-12-05 10:07:26',0,-1,0,99),(557820,0,-8,'INDIAN MUSLIM','2014-12-05 10:07:26',0,-1,0,99),(557821,0,-53,'Sikh','2014-10-09 02:34:47',1,1,0,0),(557823,0,-8,'GURKHA','2014-12-05 10:07:26',0,-1,0,99),(557824,0,-8,'NEPALESE','2014-12-05 10:07:26',0,-1,0,99),(557828,0,-8,'EUROPEAN','2014-12-05 10:07:26',0,-1,0,99),(558004,0,-37,'Moving House','2014-06-25 05:13:57',1,1,0,1),(558005,0,-38,'Owe Money','2014-06-25 06:14:46',1,1,0,1),(558006,0,-65,'No','2014-11-18 00:03:30',1,1,0,0),(558007,0,-65,'Yes','2014-11-18 00:03:38',1,1,0,0),(558008,0,-54,'PSLE / Primary School','2014-12-02 20:56:05',1,1,0,1),(558010,0,-54,'\'N\' Level / Secondary School','2014-12-02 20:56:12',1,1,0,2),(558011,0,-54,'\'O\' Level / Secondary School','2014-12-02 20:56:20',1,1,0,3),(558012,0,-54,'\'A\' Level / Junior College','2014-12-02 20:56:26',1,1,0,4),(558013,0,-54,'Diploma / Polytechnic','2014-12-02 20:56:34',1,1,0,5),(558014,0,-54,'Nitec / Institute of Technical Education','2014-12-02 20:56:40',1,1,0,6),(558015,0,-54,'Bachelor\'s Degree / University','2014-12-02 20:56:46',1,1,0,7),(558016,0,-54,'Master\'s Degree / University','2014-12-02 20:56:54',1,1,0,8),(558017,0,-54,'PHD / University','2014-12-02 20:57:02',1,1,0,9),(558018,0,-20,'NRIC','2014-12-10 06:49:14',1,1,0,1),(558019,0,-20,'Passport','2014-12-10 06:49:33',1,1,0,2);
/*!40000 ALTER TABLE `tblDefCodes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblDefVenue`
--

DROP TABLE IF EXISTS `tblDefVenue`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblDefVenue` (
  `intDefVenueID` int(11) NOT NULL AUTO_INCREMENT,
  `intAssocID` int(11) NOT NULL DEFAULT '0',
  `intVenueSubRealmID` int(11) NOT NULL DEFAULT '0',
  `strName` varchar(150) DEFAULT NULL,
  `intRecStatus` tinyint(4) DEFAULT '0',
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `strAbbrev` varchar(50) DEFAULT '',
  `intTypeID` tinyint(4) DEFAULT '0',
  `strAddress1` varchar(200) DEFAULT '',
  `strAddress2` varchar(200) DEFAULT '',
  `strSuburb` varchar(100) DEFAULT '',
  `strState` varchar(100) DEFAULT '',
  `strPostalCode` varchar(20) DEFAULT '',
  `strCountry` varchar(100) DEFAULT '',
  `strPhone` varchar(50) DEFAULT '',
  `strPhone2` varchar(50) DEFAULT '',
  `strFax` varchar(50) DEFAULT '',
  `strMapRef` varchar(20) DEFAULT '',
  `intMapNumber` int(11) DEFAULT '0',
  `dblLat` double DEFAULT '0',
  `dblLong` double DEFAULT '0',
  `strLGA` varchar(250) DEFAULT NULL,
  `strXCoord` varchar(25) DEFAULT '',
  `strYCoord` varchar(25) DEFAULT '',
  `strtFIFACountryCode` varchar(10) DEFAULT '',
  `strAlias` varchar(50) DEFAULT '',
  `strNativeName` varchar(100) DEFAULT '',
  `strNativeAlias` varchar(50) DEFAULT '',
  `strDescription` text,
  `intCapacity` int(11) DEFAULT '0',
  `intCoveredSeats` int(11) DEFAULT '0',
  `intUncoveredSeats` int(11) DEFAULT '0',
  `intCoveredStandingPlaces` int(11) DEFAULT '0',
  `intUncoveredStandingPlaces` int(11) DEFAULT '0',
  `intLightCapacity` int(11) DEFAULT '0',
  `strGround` varchar(30) DEFAULT '',
  `strVenueType` varchar(30) DEFAULT '',
  `intCourtsideVenueID` int(11) DEFAULT '0',
  PRIMARY KEY (`intDefVenueID`),
  KEY `index_intAssocID` (`intAssocID`),
  KEY `index_intVenueSubRealmID` (`intVenueSubRealmID`),
  KEY `index_intRecStatusAssoc` (`intRecStatus`,`intAssocID`)
) ENGINE=MyISAM AUTO_INCREMENT=50148 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblDefVenue`
--

LOCK TABLES `tblDefVenue` WRITE;
/*!40000 ALTER TABLE `tblDefVenue` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblDefVenue` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblDefVenueKeyValue`
--

DROP TABLE IF EXISTS `tblDefVenueKeyValue`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblDefVenueKeyValue` (
  `intVenueID` int(11) NOT NULL DEFAULT '0',
  `strKey` varchar(150) NOT NULL DEFAULT '',
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `strValue` varchar(50) DEFAULT '',
  PRIMARY KEY (`intVenueID`,`strKey`),
  KEY `index_strKey` (`strKey`)
) ENGINE=MyISAM AUTO_INCREMENT=49372 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblDefVenueKeyValue`
--

LOCK TABLES `tblDefVenueKeyValue` WRITE;
/*!40000 ALTER TABLE `tblDefVenueKeyValue` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblDefVenueKeyValue` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblDocumentType`
--

DROP TABLE IF EXISTS `tblDocumentType`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblDocumentType` (
  `intDocumentTypeID` int(11) NOT NULL AUTO_INCREMENT,
  `intRealmID` int(11) NOT NULL,
  `strDocumentName` varchar(100) DEFAULT '',
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `intActive` tinyint(4) DEFAULT '1',
  `strDocumentFor` varchar(255) DEFAULT NULL,
  `strLockAtLevel` varchar(15) DEFAULT '',
  `strDescription` varchar(255) DEFAULT '',
  `strActionPending` varchar(30) DEFAULT '',
  PRIMARY KEY (`intDocumentTypeID`),
  KEY `index_realm` (`intRealmID`)
) ENGINE=InnoDB AUTO_INCREMENT=64 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblDocumentType`
--

LOCK TABLES `tblDocumentType` WRITE;
/*!40000 ALTER TABLE `tblDocumentType` DISABLE KEYS */;
INSERT INTO `tblDocumentType` VALUES (32,1,'Passport Sized Photo','2015-01-04 21:47:01',1,'PERSON','','Upload a passport sized photo','PERSON'),(33,1,'NRIC/Passport','2015-01-04 21:47:01',1,'PERSON','','Upload a copy of the person\'s NRIC or Passport for foreign citizens','PERSON'),(34,1,'MOM Pass/Student Pass/Dependent Pass/Long Term Visit Pass','2015-01-04 21:47:01',1,'PERSON','','Any foreign person, who has residency status, must provide this document','PERSON'),(35,1,'Clearance Letter (SAFSA/PSA/HQSCDF) - Regular/Active NS','2015-01-04 21:47:01',1,'PERSON','','Any active member of the National Services (SAFSA, PSA or HQSCDF) whether on National Service or permanent enlistment must provide a letter of clearance','PERSON'),(36,1,'Code of Conduct (signed)','2015-01-04 21:47:01',1,'PERSON','','Please upload a signed copy of the FAS Code of Conduct','PERSON'),(37,1,'Parental Consent','2015-01-04 21:47:01',1,'PERSON','','If the registrant is under the age of 21, a signed parental consent form is to be provided','PERSON'),(38,1,'Player\'s Contract (Professional / Prime League)','2015-01-04 21:47:02',1,'PERSON','|3|','The Club must provide a copy of the players signed contract, for Professional or Prime League players','REGO'),(39,1,'Certificate of Medical Fitness','2015-01-04 21:47:02',1,'PERSON','','All players must provide a current certificate of medical fitness','REGO'),(40,1,'ITC','2015-01-04 21:47:02',1,'TRANSFERITC','','Players registered at one association may only be registered at a new association once the latter has received an International Transfer Certificate (hereinafter: ITC) from the former association','REGO'),(41,1,'Participation Questionnaire Declaration Form','2015-01-04 21:47:02',1,'PERSON','','All players over 35 or turning 35 during this competition period must provide a Participant Questionnaire Declaration Form','REGO'),(42,1,'Notification Letter to School','2015-01-04 21:47:02',1,'PERSON','','Any student enrolled in an education institution must provide a copy of the signed notification letter sent totheir place of enrolment','REGO'),(43,1,'First Aid or CPR Certificate','2015-01-04 21:47:02',1,'PERSON','','To be registered as a Coach, a person must hold either a valid First Aid or CPR Certificate','REGO'),(44,1,'FAS/AFC Coach Qualification Certificate','2015-01-04 21:47:02',1,'PERSON','','The most recent coaching certificate held by the Coach','REGO'),(45,1,'Coaches Contract','2015-01-04 21:47:02',1,'PERSON','|3|','Required only if the Coach is an S-League Coach','REGO'),(46,1,'Referee Qualification Certificate','2015-01-04 21:47:02',1,'PERSON','','The most recent referee certificate held by the Referee','REGO'),(47,1,'Foreign Referee Certificate (official from CONF or MA)','2015-01-04 21:47:02',1,'PERSON','','A refereeing certificate issued in a foreign country or by the Confederation  - only uploaded if applicable','REGO'),(48,1,'Verification letter from Previous MA','2015-01-04 21:47:02',1,'PERSON','',' letter from the Referee\'s previous Member Association, validating refereeing experience and qualifications in that Country','REGO'),(49,1,'Fitness Test Requirement (kept by referee dept) For ACTIVATION','2015-01-04 21:47:02',1,'PERSON','','','REGO'),(50,1,'Annual Refresher Course (kept by referee dept)  For ACTIVATION','2015-01-04 21:47:02',1,'PERSON','','','REGO'),(51,1,'Professional Qualification','2015-01-04 21:47:02',1,'PERSON','','If you are registering as a Team Doctor or Physiotherapist, you must upload a document that establishes this qualification','REGO'),(52,1,'Notification Letter to School','2015-01-04 21:47:02',1,'PERSON','','Any student enrolled in an education institution must provide a signed notification letter for their place of enrolment','REGO'),(53,1,'Membership Form','2014-11-27 03:54:14',1,'CLUB','','The official FAS membership form, completed and signed by the club',''),(54,1,'Certificate of Registration (ROS or ACRA)','2014-11-27 03:54:14',1,'CLUB','','Please provide the certificate of incorporation of the organisation (normally ROS or ACRA)',''),(55,1,'Copy of Bylaws (Constitution)-First Time + Update','2014-11-27 03:54:14',1,'CLUB','','Please provide the constitution or by-laws which provide governance of the organisation',''),(56,1,'Declaration letter for Affiliation','2014-11-27 03:54:14',1,'CLUB','','Letter of Declaration signed by the President/Chairman and one other authorised signatory',''),(57,1,'Proforma + Update','2015-01-15 00:10:56',1,'CLUB','','',''),(58,1,'Code of Conduct ','2014-11-27 03:54:14',1,'CLUB','','Please upload the official FAS code of conduct for Organisations signed by two office bearers',''),(59,1,'List of signatories','2015-01-15 00:11:50',1,'CLUB','','A list of Officials, specifying those who are authorised signatories with the right to enter into legally binding agreements with third parties',''),(60,1,'Latest Congress/Assembly Minutes','2014-11-27 03:54:14',1,'CLUB','','A copy of the minutes of the most recent meeting of the Congress or Assembly',''),(61,1,'Latest Financial Returns/ACRA & ROS Return','2015-01-15 03:42:04',1,'CLUB','','All clubs must upload the latest returns filed with ACRA/ROS',''),(62,1,'Certificate of Medical Fitness','2014-11-27 23:14:47',1,'PERSON','','Referees over 35 must provide a current certificate of medical fitness',''),(63,1,'Latest audited statement of accounts','2015-01-15 03:45:36',1,'CLUB','','All S.League and NFL clubs are required to submit their last audited financial accounts','');
/*!40000 ALTER TABLE `tblDocumentType` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblDocumentTypes`
--

DROP TABLE IF EXISTS `tblDocumentTypes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblDocumentTypes` (
  `intDocumentTypeID` int(11) NOT NULL AUTO_INCREMENT,
  `intRealmID` int(11) NOT NULL,
  `strDocumentName` varchar(100) DEFAULT '',
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `intActive` tinyint(4) DEFAULT '1',
  PRIMARY KEY (`intDocumentTypeID`),
  KEY `index_realm` (`intRealmID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblDocumentTypes`
--

LOCK TABLES `tblDocumentTypes` WRITE;
/*!40000 ALTER TABLE `tblDocumentTypes` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblDocumentTypes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblDocuments`
--

DROP TABLE IF EXISTS `tblDocuments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblDocuments` (
  `intDocumentID` int(11) NOT NULL AUTO_INCREMENT,
  `intDocumentTypeID` int(11) DEFAULT NULL,
  `intEntityLevel` tinyint(4) DEFAULT NULL,
  `intEntityID` int(11) NOT NULL DEFAULT '0',
  `intPersonID` int(11) NOT NULL DEFAULT '0',
  `intPersonRegistrationID` int(11) NOT NULL DEFAULT '0',
  `intClearanceID` int(11) NOT NULL,
  `strDeniedNotes` text,
  `strApprovalStatus` varchar(30) NOT NULL DEFAULT 'PENDING',
  `intUploadFileID` int(11) NOT NULL,
  `dtAdded` datetime DEFAULT NULL,
  `dtLastUpdated` datetime DEFAULT NULL,
  `tTimeStamp` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`intDocumentID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblDocuments`
--

LOCK TABLES `tblDocuments` WRITE;
/*!40000 ALTER TABLE `tblDocuments` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblDocuments` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblDuplChanges`
--

DROP TABLE IF EXISTS `tblDuplChanges`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblDuplChanges` (
  `intDuplChangesID` int(11) NOT NULL AUTO_INCREMENT,
  `intEntityID` int(11) NOT NULL DEFAULT '0',
  `intOldID` int(11) NOT NULL DEFAULT '0',
  `intNewID` int(11) NOT NULL DEFAULT '0',
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `intISSUE` int(11) DEFAULT '0',
  PRIMARY KEY (`intDuplChangesID`),
  KEY `index_intEntityIDtstamp` (`intEntityID`,`tTimeStamp`),
  KEY `index_intOldID` (`intOldID`),
  KEY `index_intNewID` (`intNewID`),
  KEY `index_intEntityIDtstampNew` (`intEntityID`,`tTimeStamp`,`intNewID`),
  KEY `index_intEntityIDtstampOld` (`intEntityID`,`tTimeStamp`,`intOldID`)
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblDuplChanges`
--

LOCK TABLES `tblDuplChanges` WRITE;
/*!40000 ALTER TABLE `tblDuplChanges` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblDuplChanges` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblEmailTemplateTypes`
--

DROP TABLE IF EXISTS `tblEmailTemplateTypes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblEmailTemplateTypes` (
  `intEmailTemplateTypeID` int(11) NOT NULL AUTO_INCREMENT,
  `intRealmID` int(11) NOT NULL,
  `intSubRealmID` int(11) NOT NULL,
  `strTemplateType` varchar(100) DEFAULT NULL,
  `strFileNamePrefix` varchar(100) DEFAULT NULL,
  `intActive` int(11) DEFAULT '1',
  `tTimestamp` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`intEmailTemplateTypeID`),
  UNIQUE KEY `realm_template_type` (`intRealmID`,`strTemplateType`)
) ENGINE=InnoDB AUTO_INCREMENT=19 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblEmailTemplateTypes`
--

LOCK TABLES `tblEmailTemplateTypes` WRITE;
/*!40000 ALTER TABLE `tblEmailTemplateTypes` DISABLE KEYS */;
INSERT INTO `tblEmailTemplateTypes` VALUES (1,1,0,'NOTIFICATION_WFTASK_ADDED','wftask_added',1,'2014-10-16 02:46:57'),(2,1,0,'NOTIFICATION_WFTASK_APPROVED','wftask_approved',1,'2014-10-16 02:46:57'),(3,1,0,'NOTIFICATION_WFTASK_REJECTED','wftask_rejected',1,'2014-10-16 02:46:57'),(4,1,0,'NOTIFICATION_WFTASK_RESOLVED','wftask_resolved',1,'2014-10-16 02:46:57'),(5,1,0,'NOTIFICATION_WFTASK_HELD','wftask_held',1,'2014-10-16 02:46:57'),(6,1,0,'NOTIFICATION_WFTASK_RESUMED','wftask_resumed',1,'2014-10-16 02:46:57'),(7,1,0,'NOTIFICATION_REQUESTACCESS_ACCEPTED','requestaccess_accepted',1,'2014-10-16 02:46:57'),(8,1,0,'NOTIFICATION_REQUESTACCESS_DENIED','requestaccess_denied',1,'2014-10-16 02:46:57'),(9,1,0,'NOTIFICATION_REQUESTACCESS_OVERRIDDEN','requestaccess_overridden',1,'2014-10-16 02:46:57'),(10,1,0,'NOTIFICATION_REQUESTACCESS_REJECTED','requestaccess_rejected',1,'2014-10-16 02:46:57'),(11,1,0,'NOTIFICATION_REQUESTACCESS_COMPLETED','requestaccess_completed',1,'2014-10-16 02:46:57'),(12,1,0,'NOTIFICATION_REQUESTTRANSFER_ACCEPTED','requesttransfer_accepted',1,'2014-10-16 02:46:57'),(13,1,0,'NOTIFICATION_REQUESTTRANSFER_DENIED','requesttransfer_denied',1,'2014-10-16 02:46:57'),(14,1,0,'NOTIFICATION_REQUESTTRANSFER_OVERRIDDEN','requesttransfer_overridden',1,'2014-10-16 02:46:57'),(15,1,0,'NOTIFICATION_REQUESTTRANSFER_REJECTED','requesttransfer_rejected',1,'2014-10-16 02:46:57'),(16,1,0,'NOTIFICATION_REQUESTTRANSFER_COMPLETED','requesttransfer_completed',1,'2014-10-16 02:46:57'),(17,1,0,'NOTIFICATION_REQUESTACCESS_SENT','requestaccess_sent',1,'2014-10-16 02:46:57'),(18,1,0,'NOTIFICATION_REQUESTTRANSFER_SENT','requesttransfer_sent',1,'2014-10-16 02:46:57');
/*!40000 ALTER TABLE `tblEmailTemplateTypes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblEmailTemplates`
--

DROP TABLE IF EXISTS `tblEmailTemplates`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblEmailTemplates` (
  `intEmailTemplateID` int(11) NOT NULL AUTO_INCREMENT,
  `intEmailTemplateTypeID` int(11) DEFAULT NULL,
  `strHTMLTemplatePath` varchar(100) DEFAULT NULL COMMENT 'html responsive web email template',
  `strTextTemplatePath` varchar(100) DEFAULT NULL COMMENT 'Plain Text Email Template incase client or reader does not support html',
  `strSubjectPrefix` varchar(100) DEFAULT NULL COMMENT 'Prefix Email Subject',
  `intLanguageID` int(11) NOT NULL COMMENT 'links to tblLanguages',
  `intActive` int(11) DEFAULT '1',
  `tTimestamp` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`intEmailTemplateID`)
) ENGINE=InnoDB AUTO_INCREMENT=19 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblEmailTemplates`
--

LOCK TABLES `tblEmailTemplates` WRITE;
/*!40000 ALTER TABLE `tblEmailTemplates` DISABLE KEYS */;
INSERT INTO `tblEmailTemplates` VALUES (1,1,'emails/notification/__REALMNAME__/workflow/html/','','WORK TASK ADDED: ',1,1,'2014-10-16 02:47:01'),(2,2,'emails/notification/__REALMNAME__/workflow/html/','','WORK TASK APPROVED: ',1,1,'2014-10-16 02:47:01'),(3,3,'emails/notification/__REALMNAME__/workflow/html/','','WORK TASK REJECTED: ',1,1,'2014-10-16 02:47:01'),(4,4,'emails/notification/__REALMNAME__/workflow/html/','','WORK TASK RESOLVED: ',1,1,'2014-10-16 02:47:01'),(5,5,'emails/notification/__REALMNAME__/workflow/html/','','WORK TASK HELD: ',1,1,'2014-10-16 02:47:01'),(6,6,'emails/notification/__REALMNAME__/workflow/html/','','WORK TASK RESUMED: ',1,1,'2014-10-16 02:47:01'),(7,7,'emails/notification/__REALMNAME__/personrequest/html/','','PERSON REQUEST ACCESS ACCEPTED: ',1,1,'2014-10-16 02:47:01'),(8,8,'emails/notification/__REALMNAME__/personrequest/html/','','PERSON REQUEST ACCESS DENIED: ',1,1,'2014-10-16 02:47:01'),(9,9,'emails/notification/__REALMNAME__/personrequest/html/','','PERSON REQUEST ACCESS OVERRIDDEN: ',1,1,'2014-10-16 02:47:01'),(10,10,'emails/notification/__REALMNAME__/personrequest/html/','','PERSON REQUEST ACCESS REJECTED: ',1,1,'2014-10-16 02:47:01'),(11,11,'emails/notification/__REALMNAME__/personrequest/html/','','PERSON REQUEST ACCESS COMPLETED: ',1,1,'2014-10-16 02:47:01'),(12,12,'emails/notification/__REALMNAME__/personrequest/html/','','PERSON REQUEST TRANSFER ACCEPTED: ',1,1,'2014-10-16 02:47:01'),(13,13,'emails/notification/__REALMNAME__/personrequest/html/','','PERSON REQUEST TRANSFER DENIED: ',1,1,'2014-10-16 02:47:01'),(14,14,'emails/notification/__REALMNAME__/personrequest/html/','','PERSON REQUEST TRANSFER OVERRIDDEN: ',1,1,'2014-10-16 02:47:01'),(15,15,'emails/notification/__REALMNAME__/personrequest/html/','','PERSON REQUEST TRANSFER REJECTED: ',1,1,'2014-10-16 02:47:01'),(16,16,'emails/notification/__REALMNAME__/personrequest/html/','','PERSON REQUEST TRANSFER COMPLETED: ',1,1,'2014-10-16 02:47:01'),(17,17,'emails/notification/__REALMNAME__/personrequest/html/','','PERSON REQUEST ACCESS SENT: ',1,1,'2014-10-16 02:47:01'),(18,18,'emails/notification/__REALMNAME__/personrequest/html/','','PERSON REQUEST TRANSFER SENT: ',1,1,'2014-10-16 02:47:01');
/*!40000 ALTER TABLE `tblEmailTemplates` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblEntity`
--

DROP TABLE IF EXISTS `tblEntity`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblEntity` (
  `intEntityID` int(11) NOT NULL AUTO_INCREMENT,
  `intEntityLevel` int(11) DEFAULT '0',
  `intRealmID` int(11) DEFAULT '0',
  `strEntityType` varchar(30) DEFAULT '',
  `strStatus` varchar(20) DEFAULT '',
  `intRealmApproved` tinyint(4) DEFAULT '0',
  `intCreatedByEntityID` int(11) DEFAULT '0',
  `strFIFAID` varchar(30) DEFAULT '',
  `strMAID` varchar(30) DEFAULT NULL,
  `strLocalName` varchar(100) DEFAULT '',
  `strLocalShortName` varchar(100) DEFAULT '',
  `strLocalFacilityName` varchar(150) DEFAULT '',
  `strLatinName` varchar(100) DEFAULT '',
  `strLatinShortName` varchar(100) DEFAULT '',
  `strLatinFacilityName` varchar(150) DEFAULT '',
  `dtFrom` date DEFAULT NULL,
  `dtTo` date DEFAULT NULL,
  `strISOCountry` varchar(10) DEFAULT '',
  `strRegion` varchar(50) DEFAULT '',
  `strPostalCode` varchar(15) DEFAULT '',
  `strTown` varchar(100) DEFAULT '',
  `strCity` varchar(100) DEFAULT NULL,
  `strState` varchar(100) DEFAULT NULL,
  `strAddress` varchar(200) DEFAULT '',
  `strAddress2` varchar(200) DEFAULT NULL COMMENT 'Secondary address detail',
  `strWebURL` varchar(200) DEFAULT '',
  `strEmail` varchar(200) DEFAULT '',
  `strPhone` varchar(20) DEFAULT '',
  `strFax` varchar(20) DEFAULT '',
  `strAssocNature` varchar(50) DEFAULT NULL,
  `strMANotes` varchar(250) DEFAULT NULL,
  `intLegalTypeID` int(11) DEFAULT NULL COMMENT 'Type of Legal ID provided as listed in the tblLegalType Table',
  `strContactTitle` varchar(50) DEFAULT NULL,
  `strContact` varchar(50) DEFAULT NULL,
  `strContactEmail` varchar(200) DEFAULT NULL,
  `strContactPhone` varchar(50) DEFAULT NULL,
  `strContactCity` varchar(100) DEFAULT NULL,
  `strContactISOCountry` varchar(10) DEFAULT NULL,
  `dtAdded` datetime DEFAULT NULL,
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `intCapacity` int(11) DEFAULT '0',
  `intCoveredSeats` int(11) DEFAULT '0',
  `intUncoveredSeats` int(11) DEFAULT '0',
  `intCoveredStandingPlaces` int(11) DEFAULT '0',
  `intUncoveredStandingPlaces` int(11) DEFAULT '0',
  `intLightCapacity` int(11) DEFAULT '0',
  `strGroundNature` varchar(100) DEFAULT '',
  `strDiscipline` varchar(100) DEFAULT '',
  `strGender` varchar(10) DEFAULT NULL,
  `strMapRef` varchar(20) DEFAULT '',
  `intMapNumber` int(11) DEFAULT '0',
  `dblLat` double DEFAULT '0',
  `dblLong` double DEFAULT '0',
  `strDescription` text,
  `intSubRealmID` int(11) NOT NULL DEFAULT '0',
  `intDataAccess` tinyint(4) NOT NULL DEFAULT '10',
  `strPaymentNotificationAddress` varchar(250) DEFAULT NULL,
  `strEntityPaymentBusinessNumber` varchar(100) DEFAULT '',
  `strEntityPaymentInfo` text,
  `intPaymentRequired` tinyint(4) DEFAULT '0',
  `intIsPaid` tinyint(4) DEFAULT '0',
  `intLocalLanguage` int(11) NOT NULL DEFAULT '0',
  `strLegalID` varchar(45) DEFAULT NULL COMMENT 'a field to type in the ID that corresponds to the LegalType',
  `strImportEntityCode` varchar(45) DEFAULT NULL COMMENT 'Reference to the imported records inputted by client',
  `intImportID` int(11) DEFAULT NULL COMMENT 'Tracking ID on which batch this record is included during import',
  `strAcceptSelfRego` varchar(15) DEFAULT NULL COMMENT 'Allow an Entity to determine if they accept self registration FC-231',
  `strShortNotes` varchar(255) DEFAULT NULL,
  `intNotifications` int(11) NOT NULL DEFAULT '1' COMMENT 'Flag to check whether to send notifications or not.',
  `strOrganisationLevel` varchar(45) DEFAULT NULL,
  `intFacilityTypeID` int(11) DEFAULT NULL,
  PRIMARY KEY (`intEntityID`),
  UNIQUE KEY `strImportEntityCode_UNIQUE` (`strImportEntityCode`),
  KEY `index_intRealmID` (`intRealmID`),
  KEY `index_intEntityLevel` (`intEntityLevel`),
  KEY `index_strFIFAID` (`strFIFAID`)
) ENGINE=InnoDB AUTO_INCREMENT=90 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblEntity`
--

LOCK TABLES `tblEntity` WRITE;
/*!40000 ALTER TABLE `tblEntity` DISABLE KEYS */;
INSERT INTO `tblEntity` VALUES (1,100,1,'','ACTIVE',0,0,'','','Football Association of Singapore','Singapore','','','','',NULL,NULL,'SG','','','',NULL,'','1 FAS Street','','','fspo001ma@gmail.com','','',NULL,NULL,NULL,'','','','','','SG',NULL,'2015-01-19 07:59:29',0,0,0,0,0,0,'','',NULL,'',0,0,0,NULL,0,10,NULL,'',NULL,0,0,2,NULL,'FAS',NULL,NULL,'',1,NULL,NULL);
/*!40000 ALTER TABLE `tblEntity` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblEntityCategories`
--

DROP TABLE IF EXISTS `tblEntityCategories`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblEntityCategories` (
  `intEntityCategoryID` int(11) NOT NULL AUTO_INCREMENT,
  `intRealmID` int(11) NOT NULL,
  `intSubRealmID` int(11) NOT NULL,
  `intAssocID` int(11) DEFAULT '0',
  `intEntityType` tinyint(4) DEFAULT NULL,
  `strCategoryName` varchar(100) DEFAULT NULL,
  `strCategoryDesc` text,
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`intEntityCategoryID`),
  KEY `index_intRealm` (`intRealmID`,`intSubRealmID`),
  KEY `index_intEntityType` (`intEntityType`)
) ENGINE=MyISAM AUTO_INCREMENT=19 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblEntityCategories`
--

LOCK TABLES `tblEntityCategories` WRITE;
/*!40000 ALTER TABLE `tblEntityCategories` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblEntityCategories` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblEntityFields`
--

DROP TABLE IF EXISTS `tblEntityFields`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblEntityFields` (
  `intEntityFieldID` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `intEntityID` int(11) NOT NULL COMMENT 'Entity (Venue/Facility) this Field is linked to',
  `intFieldOrderNumber` int(11) DEFAULT NULL,
  `strName` varchar(200) NOT NULL COMMENT 'Name of the field.',
  `strDiscipline` varchar(100) NOT NULL COMMENT 'FOOTBALL, FUTSAL etc (code level enumeration). The discipline/sport which is being played on the stadium.',
  `intCapacity` int(11) NOT NULL COMMENT 'The maximum number of people allowed as audience/spectators.',
  `strGroundNature` varchar(100) NOT NULL COMMENT 'The type of ground in the stadium, e.g. natural grass or artificial turf.',
  `dblLength` double DEFAULT NULL COMMENT 'The length of a field defined in meters (m).',
  `dblWidth` double DEFAULT NULL COMMENT 'The length of a field defined in meters (m).',
  `dblLat` double DEFAULT NULL,
  `dblLong` double DEFAULT NULL,
  `intCoveredSeats` int(11) DEFAULT NULL,
  `intUncoveredSeats` int(11) DEFAULT NULL,
  `intCoveredStandingPlaces` int(11) DEFAULT NULL,
  `intUncoveredStandingPlaces` int(11) DEFAULT NULL,
  `intLightCapacity` int(11) DEFAULT NULL,
  `intImportID` int(11) DEFAULT NULL,
  PRIMARY KEY (`intEntityFieldID`)
) ENGINE=InnoDB AUTO_INCREMENT=18 DEFAULT CHARSET=utf8 COMMENT='FacilityType as per FIFA FDS (additional fields moved from tblEntity)';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblEntityFields`
--

LOCK TABLES `tblEntityFields` WRITE;
/*!40000 ALTER TABLE `tblEntityFields` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblEntityFields` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblEntityIdentifier`
--

DROP TABLE IF EXISTS `tblEntityIdentifier`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblEntityIdentifier` (
  `intIdentifierId` int(11) NOT NULL AUTO_INCREMENT,
  `intEntityID` int(11) NOT NULL,
  `intRealmID` int(11) NOT NULL,
  `intIdentifierTypeID` int(11) NOT NULL,
  `strIdentifier` varchar(100) NOT NULL,
  `strContryIssued` varchar(100) NOT NULL DEFAULT '',
  `dtValidFrom` date DEFAULT NULL,
  `dtValidUntil` date DEFAULT NULL,
  `strDescription` varchar(250) DEFAULT NULL,
  `dtAdded` datetime DEFAULT NULL,
  `dtLastUpdated` datetime DEFAULT NULL,
  `tTimestamp` varchar(45) DEFAULT 'CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP',
  `intStatus` int(11) DEFAULT '1',
  PRIMARY KEY (`intIdentifierId`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblEntityIdentifier`
--

LOCK TABLES `tblEntityIdentifier` WRITE;
/*!40000 ALTER TABLE `tblEntityIdentifier` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblEntityIdentifier` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblEntityLinks`
--

DROP TABLE IF EXISTS `tblEntityLinks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblEntityLinks` (
  `intEntityLinksID` int(11) NOT NULL AUTO_INCREMENT,
  `intParentEntityID` int(11) NOT NULL,
  `intChildEntityID` int(11) NOT NULL,
  `intPrimary` tinyint(4) NOT NULL DEFAULT '1',
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `intImportID` int(11) DEFAULT NULL COMMENT 'Tracking ID on which batch this record is included during import',
  PRIMARY KEY (`intEntityLinksID`),
  UNIQUE KEY `index_IDs` (`intParentEntityID`,`intChildEntityID`),
  KEY `index_intParentEntityID` (`intParentEntityID`),
  KEY `index_intChildEntityID` (`intChildEntityID`),
  KEY `index_intPrimary` (`intPrimary`)
) ENGINE=InnoDB AUTO_INCREMENT=89 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblEntityLinks`
--

LOCK TABLES `tblEntityLinks` WRITE;
/*!40000 ALTER TABLE `tblEntityLinks` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblEntityLinks` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblEntityRegistrationAllowed`
--

DROP TABLE IF EXISTS `tblEntityRegistrationAllowed`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblEntityRegistrationAllowed` (
  `intEntityRegistrationAllowedID` int(11) NOT NULL AUTO_INCREMENT,
  `intEntityID` int(11) NOT NULL,
  `intRealmID` int(11) NOT NULL,
  `intSubRealmID` int(11) NOT NULL,
  `strPersonType` varchar(20) NOT NULL,
  `strSport` varchar(20) NOT NULL,
  `intGender` tinyint(4) DEFAULT '0',
  `strPersonLevel` varchar(20) NOT NULL,
  `strRegistrationNature` varchar(20) NOT NULL,
  `strAgeLevel` varchar(20) NOT NULL,
  `tTimestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`intEntityRegistrationAllowedID`),
  KEY `index_intRealmID` (`intRealmID`),
  KEY `index_intSubRealmID` (`intSubRealmID`)
) ENGINE=InnoDB AUTO_INCREMENT=30 DEFAULT CHARSET=utf8 COMMENT='This table shows which permuation and combination of players/coaches are available at each Entity';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblEntityRegistrationAllowed`
--

LOCK TABLES `tblEntityRegistrationAllowed` WRITE;
/*!40000 ALTER TABLE `tblEntityRegistrationAllowed` DISABLE KEYS */;
INSERT INTO `tblEntityRegistrationAllowed` VALUES (19,35,1,0,'PLAYER','FOOTBALL',1,'AMATEUR','','MINOR','2014-08-03 22:23:42'),(20,35,1,0,'COACH','FOOTBALL',1,'AMATEUR','','ADULT','2014-08-03 22:24:57'),(21,14,1,0,'COACH','FOOTBALL',1,'AMATEUR','','ADULT','2014-08-04 06:19:34'),(22,14,1,0,'COACH','BEACHSOCCER',2,'AMATEUR','','ADULT','2014-08-04 06:29:48'),(23,35,1,0,'PLAYER','FOOTBALL',1,'PROFESSIONAL','','ADULT','2014-08-04 23:30:05'),(24,35,1,0,'PLAYER','FOOTBALL',1,'AMATEUR','','ADULT','2014-08-06 00:04:21'),(25,35,1,0,'TECHOFFICIAL','',1,'','','','2014-08-06 00:24:34'),(26,19,1,0,'TECHOFFICIAL','',1,'','','','2014-08-09 22:23:06'),(27,19,1,0,'TECHOFFICIAL','',2,'','','','2014-08-09 22:25:10'),(28,35,1,0,'PLAYER','FUTSAL',1,'AMATEUR','','MINOR','2014-08-20 21:35:58'),(29,35,1,0,'PLAYER','FUTSAL',2,'AMATEUR','','MINOR','2014-09-03 00:33:00');
/*!40000 ALTER TABLE `tblEntityRegistrationAllowed` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblEntityTypeRoles`
--

DROP TABLE IF EXISTS `tblEntityTypeRoles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblEntityTypeRoles` (
  `intEntityTypeRoleID` int(11) NOT NULL AUTO_INCREMENT,
  `intRealmID` int(11) DEFAULT '0',
  `intSubRealmID` int(11) DEFAULT '0',
  `strSport` varchar(20) DEFAULT '',
  `strPersonType` varchar(30) DEFAULT '',
  `strEntityRoleKey` varchar(30) DEFAULT '',
  `strEntityRoleName` varchar(30) DEFAULT '',
  `tTimestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`intEntityTypeRoleID`),
  UNIQUE KEY `KEY_strEntityRoleKey` (`strEntityRoleKey`),
  KEY `index_intRealmID` (`intRealmID`),
  KEY `index_intSubRealmID` (`intSubRealmID`)
) ENGINE=InnoDB AUTO_INCREMENT=32 DEFAULT CHARSET=utf8 COMMENT='This table shows the strPersonEntityRole values available';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblEntityTypeRoles`
--

LOCK TABLES `tblEntityTypeRoles` WRITE;
/*!40000 ALTER TABLE `tblEntityTypeRoles` DISABLE KEYS */;
INSERT INTO `tblEntityTypeRoles` VALUES (1,0,0,'','MAOFFICIAL','COMMISSIONER','Commissioner','2014-10-06 05:10:23'),(2,0,0,'','MAOFFICIAL','OBSERVER','Referee Observer','2014-10-06 05:10:23'),(3,0,0,'','MAOFFICIAL','DELEGATE','Delegate','2014-10-06 05:10:23'),(4,0,0,'','.MAOFFICIAL','MAOTHER','Other','2014-10-06 05:10:23'),(5,0,0,'','TEAMOFFICIAL','PHYSICALTRN','Physical Trainer','2014-10-06 05:10:23'),(6,0,0,'','TEAMOFFICIAL','PHYSIO','Physiotherapist','2014-10-06 05:10:23'),(7,0,0,'','TEAMOFFICIAL','DOCTOR','Team Doctor','2014-10-06 05:10:23'),(8,0,0,'','TEAMOFFICIAL','KIT','Kit Manager','2014-10-06 05:10:23'),(9,0,0,'','TEAMOFFICIAL','TEAMOTHER','Other','2014-10-06 05:10:23'),(10,0,0,'','CLUBOFFICIAL','PRESIDENT','President','2014-10-06 05:10:23'),(11,0,0,'','CLUBOFFICIAL','VICEPRESIDENT','Vice President','2014-10-06 05:10:23'),(12,0,0,'','CLUBOFFICIAL','GNRLSECRETARY','General Secretary','2014-10-06 05:10:23'),(13,0,0,'','CLUBOFFICIAL','BOARDMBR','Board Member','2014-10-06 05:10:23'),(14,0,0,'','CLUBOFFICIAL','BOARDCHR','Board Chairman','2014-10-06 05:10:23'),(15,0,0,'','CLUBOFFICIAL','MEDIAOFF','Media Officer','2014-10-06 05:10:23'),(16,0,0,'','CLUBOFFICIAL','SPTDIR','Sports Director','2014-10-06 05:10:23'),(17,0,0,'','CLUBOFFICIAL','TECHDIR','Technical Director','2014-10-06 05:10:23'),(18,0,0,'','CLUBOFFICIAL','OWNER','Owner','2014-10-06 05:10:23'),(19,0,0,'','CLUBOFFICIAL','MANAGER','Manager','2014-10-06 05:10:25'),(20,0,0,'','.MAOFFICIAL','ASSISTREF','Assistant Referee','2014-11-27 22:44:00'),(21,0,0,'','.MAOFFICIAL','MAREF','Referee','2014-11-27 22:44:06'),(22,0,0,'','MAOFFICIAL','MAREFINSTRUCT','Referee Instructor','2014-11-27 22:44:12'),(23,0,0,'','TEAMOFFICIAL','TOHEADCOACH','Head Coach','2014-11-27 22:45:53'),(24,0,0,'','TEAMOFFICIAL','TOASSISTCOACH','Assistant Coach','2014-11-27 22:45:59'),(25,0,0,'','TEAMOFFICIAL','TOGOALCOACH','Goalkeeper Coach','2014-11-27 22:46:09'),(26,1,0,'','MAOFFICIAL','MAINSPECT','Match Inspector','2014-12-18 02:35:35'),(27,1,0,'','MAOFFICIAL','MAREFASSESS','Referee Assessor','2014-12-18 02:36:14'),(29,1,0,'','MAOFFICIAL','MAGENCOORD','MA General Coordinator','2014-12-18 02:37:16'),(30,1,0,'','MAOFFICIAL','MASAFETY','MA Safety Officer','2014-12-18 02:37:43'),(31,1,0,'','MAOFFICIAL','MAMEDIA','MA Media Officer','2014-12-18 02:37:57');
/*!40000 ALTER TABLE `tblEntityTypeRoles` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblExportAssocBankFile`
--

DROP TABLE IF EXISTS `tblExportAssocBankFile`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblExportAssocBankFile` (
  `intExportID` int(11) NOT NULL AUTO_INCREMENT,
  `intExportBankFileID` int(11) DEFAULT NULL,
  `intSplitID` int(11) DEFAULT NULL,
  `intRealmID` int(11) DEFAULT NULL,
  `intAssocID` int(11) DEFAULT NULL,
  `intProductID` int(11) DEFAULT NULL,
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `dtRun` datetime DEFAULT NULL,
  `intClubID` int(11) DEFAULT '0',
  PRIMARY KEY (`intExportID`),
  KEY `index_splitID` (`intSplitID`),
  KEY `index_exportBankFileID` (`intExportBankFileID`),
  KEY `index_assocID` (`intAssocID`),
  KEY `index_productID` (`intProductID`),
  KEY `index_realmID` (`intRealmID`)
) ENGINE=MyISAM AUTO_INCREMENT=5289 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblExportAssocBankFile`
--

LOCK TABLES `tblExportAssocBankFile` WRITE;
/*!40000 ALTER TABLE `tblExportAssocBankFile` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblExportAssocBankFile` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblExportBankFile`
--

DROP TABLE IF EXISTS `tblExportBankFile`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblExportBankFile` (
  `intExportBSID` int(11) NOT NULL AUTO_INCREMENT,
  `intBankSplitID` int(11) DEFAULT NULL,
  `intRealmID` int(11) DEFAULT NULL,
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `dtRun` datetime DEFAULT NULL,
  `strFilename` varchar(100) DEFAULT NULL,
  `intExportType` tinyint(4) DEFAULT '0',
  PRIMARY KEY (`intExportBSID`),
  KEY `index_banksplitID` (`intBankSplitID`),
  KEY `index_realmID` (`intRealmID`)
) ENGINE=MyISAM AUTO_INCREMENT=136355 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblExportBankFile`
--

LOCK TABLES `tblExportBankFile` WRITE;
/*!40000 ALTER TABLE `tblExportBankFile` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblExportBankFile` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblFacilityType`
--

DROP TABLE IF EXISTS `tblFacilityType`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblFacilityType` (
  `intFacilityTypeID` int(11) NOT NULL AUTO_INCREMENT,
  `intRealmID` int(11) NOT NULL,
  `intSubRealmID` int(11) DEFAULT NULL,
  `strName` varchar(100) NOT NULL DEFAULT '',
  `dtTimeStamp` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`intFacilityTypeID`),
  KEY `index_intRealmID` (`intRealmID`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8 COMMENT='High Level Types of Facility (Stadium, Football Pitch, Training Grounds, Venue, etc)';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblFacilityType`
--

LOCK TABLES `tblFacilityType` WRITE;
/*!40000 ALTER TABLE `tblFacilityType` DISABLE KEYS */;
INSERT INTO `tblFacilityType` VALUES (1,0,0,'Stadium','2014-11-25 05:46:26'),(2,0,0,'Football Pitch','2014-11-25 05:46:26'),(3,0,0,'Training Grounds','2014-11-25 05:46:26'),(4,0,0,'Venue','2014-11-25 05:46:26');
/*!40000 ALTER TABLE `tblFacilityType` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblFieldCaseRules`
--

DROP TABLE IF EXISTS `tblFieldCaseRules`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblFieldCaseRules` (
  `intFieldCaseRulesID` int(11) NOT NULL AUTO_INCREMENT,
  `intRealmID` int(11) NOT NULL DEFAULT '0',
  `intSubRealmID` int(11) NOT NULL DEFAULT '0',
  `strType` varchar(20) NOT NULL,
  `strDBFName` varchar(30) NOT NULL,
  `strCase` varchar(10) NOT NULL DEFAULT 'title',
  `intRecStatus` tinyint(4) NOT NULL DEFAULT '1',
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`intFieldCaseRulesID`),
  UNIQUE KEY `index_RealmSubRealmTypeID` (`intRealmID`,`intSubRealmID`,`strType`,`intFieldCaseRulesID`)
) ENGINE=MyISAM AUTO_INCREMENT=17 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblFieldCaseRules`
--

LOCK TABLES `tblFieldCaseRules` WRITE;
/*!40000 ALTER TABLE `tblFieldCaseRules` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblFieldCaseRules` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblFieldPermissions`
--

DROP TABLE IF EXISTS `tblFieldPermissions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblFieldPermissions` (
  `intRealmID` int(11) NOT NULL,
  `intSubRealmID` int(11) NOT NULL,
  `intEntityTypeID` int(11) NOT NULL DEFAULT '0',
  `intEntityID` int(11) NOT NULL DEFAULT '0',
  `strFieldType` varchar(20) NOT NULL DEFAULT '',
  `strFieldName` varchar(50) NOT NULL,
  `strPermission` varchar(20) DEFAULT '',
  `intRoleID` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`intEntityTypeID`,`intEntityID`,`intRealmID`,`strFieldType`,`strFieldName`,`intRoleID`),
  KEY `index_intRealm` (`intRealmID`,`intSubRealmID`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblFieldPermissions`
--

LOCK TABLES `tblFieldPermissions` WRITE;
/*!40000 ALTER TABLE `tblFieldPermissions` DISABLE KEYS */;
INSERT INTO `tblFieldPermissions` VALUES (1,0,5,20521,'PersonChild','strEmergContNo','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strEmergContNo','ChildDefine',0),(1,0,5,20521,'Person','strEmergContNo2','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strEmergContName','ChildDefine',0),(1,0,5,20521,'Person','strEmergContNo','ChildDefine',0),(1,0,5,20521,'PersonChild','strEmail2','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strEmail2','ChildDefine',0),(1,0,5,20521,'Person','strEmergContName','ChildDefine',0),(1,0,5,20521,'PersonChild','strEmergContName','ChildDefine',0),(1,0,5,20521,'Person','strEmail2','ChildDefine',0),(1,0,5,20521,'PersonChild','strState','ChildDefine',0),(1,0,5,20521,'Person','strState','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strHairColour','ChildDefine',0),(1,0,5,20521,'PersonChild','strNationalNum','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strNationalNum','ChildDefine',0),(1,0,5,20521,'Person','strMemberNo','ChildDefine',0),(1,0,5,20521,'PersonChild','strMemberNo','ChildDefine',0),(1,0,5,16,'Club','dblClubCustomDbl1','ChildDefine',0),(1,0,5,16,'ClubChild','dblClubCustomDbl1','ChildDefine',0),(1,0,5,16,'Club','dblClubCustomDbl2','ChildDefine',0),(1,0,5,16,'ClubChild','dblClubCustomDbl2','ChildDefine',0),(1,0,5,16,'Club','dblClubCustomDbl3','ChildDefine',0),(1,0,5,16,'ClubChild','dblClubCustomDbl3','ChildDefine',0),(1,0,5,16,'Club','dblClubCustomDbl4','ChildDefine',0),(1,0,5,16,'ClubChild','dblClubCustomDbl4','ChildDefine',0),(1,0,5,16,'Club','dblClubCustomDbl5','ChildDefine',0),(1,0,5,16,'ClubChild','dblClubCustomDbl5','ChildDefine',0),(1,0,5,16,'Club','dblClubCustomDbl6','ChildDefine',0),(1,0,5,16,'ClubChild','dblClubCustomDbl6','ChildDefine',0),(1,0,100,5,'PersonChild','dtLastRegistered','ReadOnly',0),(1,0,100,5,'PersonRegoForm','dtLastRegistered','ChildDefine',0),(1,0,100,5,'Person','dtLastUpdate','ReadOnly',0),(1,0,100,5,'PersonChild','dtLastUpdate','ReadOnly',0),(1,0,100,5,'PersonRegoForm','dtLastUpdate','ChildDefine',0),(1,0,100,5,'Person','dtRegisteredUntil','ReadOnly',0),(1,0,100,5,'PersonChild','dtRegisteredUntil','ReadOnly',0),(1,0,100,5,'PersonChild','strNotes','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strNotes','ChildDefine',0),(1,0,100,5,'Person','strMemberCustomNotes1','ChildDefine',0),(1,0,100,5,'PersonChild','strMemberCustomNotes1','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strMemberCustomNotes1','ChildDefine',0),(1,0,100,5,'Person','strMemberCustomNotes2','ChildDefine',0),(1,0,100,5,'PersonChild','strMemberCustomNotes2','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strMemberCustomNotes2','ChildDefine',0),(1,0,100,5,'Person','strMemberCustomNotes3','ChildDefine',0),(1,0,100,5,'PersonChild','strMemberCustomNotes3','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strMemberCustomNotes3','ChildDefine',0),(1,0,100,5,'Person','strMemberCustomNotes4','ChildDefine',0),(1,0,100,5,'PersonChild','strMemberCustomNotes4','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strMemberCustomNotes4','ChildDefine',0),(1,0,100,5,'Person','strMemberCustomNotes5','ChildDefine',0),(1,0,100,5,'PersonChild','strMemberCustomNotes5','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strMemberCustomNotes5','ChildDefine',0),(1,0,100,5,'Person','dtFirstRegistered','ReadOnly',0),(1,0,100,5,'PersonChild','dtFirstRegistered','ReadOnly',0),(1,0,100,5,'PersonRegoForm','dtFirstRegistered','ChildDefine',0),(1,0,100,5,'Person','dtLastRegistered','ReadOnly',0),(1,0,100,5,'PersonRegoForm','intCustomLU25','ChildDefine',0),(1,0,100,5,'Person','intCustomBool1','ChildDefine',0),(1,0,100,5,'PersonChild','intCustomBool1','ChildDefine',0),(1,0,100,5,'PersonRegoForm','dtCustomDt15','ChildDefine',0),(1,0,100,5,'Person','intCustomLU5','ChildDefine',0),(1,0,100,5,'PersonChild','intCustomLU5','ChildDefine',0),(1,0,100,5,'PersonRegoForm','intCustomLU5','ChildDefine',0),(1,0,100,5,'Person','intCustomLU6','ChildDefine',0),(1,0,100,5,'PersonChild','intCustomLU6','ChildDefine',0),(1,0,100,5,'PersonRegoForm','intCustomLU6','ChildDefine',0),(1,0,100,5,'Person','intCustomLU7','ChildDefine',0),(1,0,100,5,'PersonChild','intCustomLU7','ChildDefine',0),(1,0,100,5,'PersonRegoForm','intCustomLU7','ChildDefine',0),(1,0,100,5,'Person','intCustomLU8','ChildDefine',0),(1,0,100,5,'PersonChild','intCustomLU8','ChildDefine',0),(1,0,100,5,'PersonRegoForm','intCustomLU8','ChildDefine',0),(1,0,100,5,'Person','intCustomLU9','ChildDefine',0),(1,0,100,5,'PersonChild','intCustomLU9','ChildDefine',0),(1,0,100,5,'PersonRegoForm','intCustomLU9','ChildDefine',0),(1,0,100,5,'Person','intCustomLU10','ChildDefine',0),(1,0,100,5,'PersonChild','intCustomLU10','ChildDefine',0),(1,0,100,5,'PersonRegoForm','intCustomLU10','ChildDefine',0),(1,0,100,5,'Person','intCustomLU11','ChildDefine',0),(1,0,100,5,'PersonChild','intCustomLU11','ChildDefine',0),(1,0,100,5,'PersonRegoForm','intCustomLU11','ChildDefine',0),(1,0,100,5,'Person','intCustomLU12','ChildDefine',0),(1,0,100,5,'PersonChild','intCustomLU12','ChildDefine',0),(1,0,100,5,'PersonRegoForm','intCustomLU12','ChildDefine',0),(1,0,100,5,'Person','intCustomLU13','ChildDefine',0),(1,0,100,5,'PersonChild','intCustomLU13','ChildDefine',0),(1,0,100,5,'PersonRegoForm','intCustomLU13','ChildDefine',0),(1,0,100,5,'Person','intCustomLU14','ChildDefine',0),(1,0,100,5,'PersonChild','intCustomLU14','ChildDefine',0),(1,0,100,5,'PersonRegoForm','intCustomLU14','ChildDefine',0),(1,0,100,5,'Person','intCustomLU15','ChildDefine',0),(1,0,100,5,'PersonChild','intCustomLU15','ChildDefine',0),(1,0,100,5,'PersonRegoForm','intCustomLU15','ChildDefine',0),(1,0,100,5,'Person','intCustomLU16','ChildDefine',0),(1,0,100,5,'PersonChild','intCustomLU16','ChildDefine',0),(1,0,100,5,'PersonRegoForm','intCustomLU16','ChildDefine',0),(1,0,100,5,'Person','intCustomLU17','ChildDefine',0),(1,0,100,5,'PersonChild','intCustomLU17','ChildDefine',0),(1,0,100,5,'PersonRegoForm','intCustomLU17','ChildDefine',0),(1,0,100,5,'Person','intCustomLU18','ChildDefine',0),(1,0,100,5,'PersonChild','intCustomLU18','ChildDefine',0),(1,0,100,5,'PersonRegoForm','intCustomLU18','ChildDefine',0),(1,0,100,5,'Person','intCustomLU19','ChildDefine',0),(1,0,100,5,'PersonChild','intCustomLU19','ChildDefine',0),(1,0,100,5,'PersonRegoForm','intCustomLU19','ChildDefine',0),(1,0,100,5,'Person','intCustomLU20','ChildDefine',0),(1,0,100,5,'PersonChild','intCustomLU20','ChildDefine',0),(1,0,100,5,'PersonRegoForm','intCustomLU20','ChildDefine',0),(1,0,100,5,'Person','intCustomLU21','ChildDefine',0),(1,0,100,5,'PersonChild','intCustomLU21','ChildDefine',0),(1,0,100,5,'PersonRegoForm','intCustomLU21','ChildDefine',0),(1,0,100,5,'Person','intCustomLU22','ChildDefine',0),(1,0,100,5,'PersonChild','intCustomLU22','ChildDefine',0),(1,0,100,5,'PersonRegoForm','intCustomLU22','ChildDefine',0),(1,0,100,5,'Person','intCustomLU23','ChildDefine',0),(1,0,100,5,'PersonChild','intCustomLU23','ChildDefine',0),(1,0,100,5,'PersonRegoForm','intCustomLU23','ChildDefine',0),(1,0,100,5,'Person','intCustomLU24','ChildDefine',0),(1,0,100,5,'PersonChild','intCustomLU24','ChildDefine',0),(1,0,100,5,'PersonRegoForm','intCustomLU24','ChildDefine',0),(1,0,100,5,'Person','intCustomLU25','ChildDefine',0),(1,0,100,5,'PersonChild','intCustomLU25','ChildDefine',0),(1,0,100,5,'Person','strState','ChildDefine',0),(1,0,100,5,'PersonChild','strState','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strState','ChildDefine',0),(1,0,100,5,'Person','strCountry','Editable',0),(1,0,100,5,'PersonChild','strCountry','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strCountry','ChildDefine',0),(1,0,100,5,'Person','strPostalCode','Editable',0),(1,0,100,5,'PersonChild','strPostalCode','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strPostalCode','ChildDefine',0),(1,0,100,5,'Person','strPhoneHome','Editable',0),(1,0,100,5,'PersonChild','strPhoneHome','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strPhoneHome','ChildDefine',0),(1,0,100,5,'Person','strPhoneWork','Editable',0),(1,0,100,5,'PersonChild','strPhoneWork','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strPhoneWork','ChildDefine',0),(1,0,100,5,'Person','strPhoneMobile','Editable',0),(1,0,100,5,'PersonChild','strPhoneMobile','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strPhoneMobile','ChildDefine',0),(1,0,100,5,'Person','strFax','ChildDefine',0),(1,0,100,5,'PersonChild','strFax','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strFax','ChildDefine',0),(1,0,100,5,'Person','strEmail','Editable',0),(1,0,100,5,'PersonChild','strEmail','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strEmail','ChildDefine',0),(1,0,100,5,'Person','strEmail2','ChildDefine',0),(1,0,100,5,'PersonChild','strEmail2','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strEmail2','ChildDefine',0),(1,0,100,5,'Person','strEmergContName','ChildDefine',0),(1,0,100,5,'PersonChild','strEmergContName','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strEmergContName','ChildDefine',0),(1,0,100,5,'Person','strEmergContNo','ChildDefine',0),(1,0,100,5,'PersonChild','strEmergContNo','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strEmergContNo','ChildDefine',0),(1,0,100,5,'Person','strEmergContNo2','ChildDefine',0),(1,0,100,5,'PersonChild','strEmergContNo2','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strEmergContNo2','ChildDefine',0),(1,0,100,5,'Person','strEmergContRel','ChildDefine',0),(1,0,100,5,'PersonChild','strEmergContRel','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strEmergContRel','ChildDefine',0),(1,0,100,5,'Person','intPlayer','Editable',0),(1,0,100,5,'PersonChild','intPlayer','ChildDefine',0),(1,0,100,5,'PersonRegoForm','intPlayer','ChildDefine',0),(1,0,100,5,'Person','intCoach','Editable',0),(1,0,100,5,'PersonChild','intCoach','ChildDefine',0),(1,0,100,5,'PersonRegoForm','intCoach','ChildDefine',0),(1,0,100,5,'Person','intUmpire','Editable',0),(1,0,100,5,'PersonChild','intUmpire','ChildDefine',0),(1,0,100,5,'PersonRegoForm','intUmpire','ChildDefine',0),(1,0,100,5,'Person','intOfficial','ChildDefine',0),(1,0,100,5,'PersonChild','intOfficial','ChildDefine',0),(1,0,100,5,'PersonRegoForm','intOfficial','ChildDefine',0),(1,0,100,5,'Person','intMisc','ChildDefine',0),(1,0,100,5,'PersonChild','intMisc','ChildDefine',0),(1,0,100,5,'PersonRegoForm','intMisc','ChildDefine',0),(1,0,100,5,'Person','intVolunteer','ChildDefine',0),(1,0,100,5,'PersonChild','intVolunteer','ChildDefine',0),(1,0,100,5,'PersonRegoForm','intVolunteer','ChildDefine',0),(1,0,100,5,'Person','intPlayerPending','Editable',0),(1,0,100,5,'PersonChild','intPlayerPending','ChildDefine',0),(1,0,100,5,'PersonRegoForm','intPlayerPending','ChildDefine',0),(1,0,100,5,'Person','strPreferredLang','ChildDefine',0),(1,0,100,5,'PersonChild','strPreferredLang','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strPreferredLang','ChildDefine',0),(1,0,100,5,'Person','strPassportNationality','Compulsory',0),(1,0,100,5,'PersonChild','strPassportNationality','Compulsory',0),(1,0,100,5,'PersonRegoForm','strPassportNationality','Compulsory',0),(1,0,100,1,'Person','intNatCustomLU2','Editable',0),(1,0,100,1,'PersonChild','intNatCustomLU2','Editable',0),(1,0,100,5,'Person','strPassportIssueCountry','ChildDefine',0),(1,0,100,5,'PersonChild','strPassportIssueCountry','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strPassportIssueCountry','ChildDefine',0),(1,0,100,5,'Person','dtPassportExpiry','Editable',0),(1,0,100,5,'PersonChild','dtPassportExpiry','ChildDefine',0),(1,0,100,5,'PersonRegoForm','dtPassportExpiry','ChildDefine',0),(1,0,100,5,'Person','strBirthCertNo','ChildDefine',0),(1,0,100,5,'PersonChild','strBirthCertNo','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strBirthCertNo','ChildDefine',0),(1,0,100,5,'Person','strHealthCareNo','ChildDefine',0),(1,0,100,5,'PersonChild','strHealthCareNo','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strHealthCareNo','ChildDefine',0),(1,0,100,5,'Person','intIdentTypeID','Editable',0),(1,0,100,5,'PersonChild','intIdentTypeID','ChildDefine',0),(1,0,100,5,'PersonRegoForm','intIdentTypeID','ChildDefine',0),(1,0,100,5,'Person','strIdentNum','Editable',0),(1,0,100,5,'PersonChild','strIdentNum','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strIdentNum','ChildDefine',0),(1,0,100,5,'Person','dtPoliceCheck','ChildDefine',0),(1,0,100,5,'PersonChild','dtPoliceCheck','ChildDefine',0),(1,0,100,5,'PersonRegoForm','dtPoliceCheck','ChildDefine',0),(1,0,100,5,'Person','dtPoliceCheckExp','ChildDefine',0),(1,0,100,5,'PersonChild','dtPoliceCheckExp','ChildDefine',0),(1,0,100,5,'PersonRegoForm','dtPoliceCheckExp','ChildDefine',0),(1,0,100,5,'Person','strPoliceCheckRef','ChildDefine',0),(1,0,100,5,'PersonChild','strPoliceCheckRef','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strPoliceCheckRef','ChildDefine',0),(1,0,100,5,'Person','intP1Gender','ChildDefine',0),(1,0,100,5,'PersonChild','intP1Gender','ChildDefine',0),(1,0,100,5,'PersonRegoForm','intP1Gender','ChildDefine',0),(1,0,100,5,'Person','strP1Salutation','ChildDefine',0),(1,0,100,5,'PersonChild','strP1Salutation','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strP1Salutation','ChildDefine',0),(1,0,100,5,'Person','strP1FName','ChildDefine',0),(1,0,100,5,'PersonChild','strP1FName','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strP1FName','ChildDefine',0),(1,0,100,5,'Person','strP1SName','ChildDefine',0),(1,0,100,5,'PersonChild','strP1SName','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strP1SName','ChildDefine',0),(1,0,100,5,'Person','strP1Phone','ChildDefine',0),(1,0,100,5,'PersonChild','strP1Phone','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strP1Phone','ChildDefine',0),(1,0,100,5,'Person','strP1Phone2','ChildDefine',0),(1,0,100,5,'PersonChild','strP1Phone2','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strP1Phone2','ChildDefine',0),(1,0,100,5,'Person','strP1PhoneMobile','ChildDefine',0),(1,0,100,5,'PersonChild','strP1PhoneMobile','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strP1PhoneMobile','ChildDefine',0),(1,0,100,5,'Person','strP1Email','ChildDefine',0),(1,0,100,5,'PersonChild','strP1Email','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strP1Email','ChildDefine',0),(1,0,100,5,'Person','strP1Email2','ChildDefine',0),(1,0,100,5,'PersonChild','strP1Email2','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strP1Email2','ChildDefine',0),(1,0,100,5,'Person','intP1AssistAreaID','ChildDefine',0),(1,0,100,5,'PersonChild','intP1AssistAreaID','ChildDefine',0),(1,0,100,5,'PersonRegoForm','intP1AssistAreaID','ChildDefine',0),(1,0,100,5,'Person','intP2Gender','ChildDefine',0),(1,0,100,5,'PersonChild','intP2Gender','ChildDefine',0),(1,0,100,5,'PersonRegoForm','intP2Gender','ChildDefine',0),(1,0,100,5,'Person','strP2Salutation','ChildDefine',0),(1,0,100,5,'PersonChild','strP2Salutation','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strP2Salutation','ChildDefine',0),(1,0,100,5,'Person','strP2FName','ChildDefine',0),(1,0,100,5,'PersonChild','strP2FName','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strP2FName','ChildDefine',0),(1,0,100,5,'Person','strP2SName','ChildDefine',0),(1,0,100,5,'PersonChild','strP2SName','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strP2SName','ChildDefine',0),(1,0,100,5,'Person','strP2Phone','ChildDefine',0),(1,0,100,5,'PersonChild','strP2Phone','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strP2Phone','ChildDefine',0),(1,0,100,5,'Person','strP2Phone2','ChildDefine',0),(1,0,100,5,'PersonChild','strP2Phone2','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strP2Phone2','ChildDefine',0),(1,0,100,5,'Person','strP2PhoneMobile','ChildDefine',0),(1,0,100,5,'PersonChild','strP2PhoneMobile','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strP2PhoneMobile','ChildDefine',0),(1,0,100,5,'Person','strP2Email','ChildDefine',0),(1,0,100,5,'PersonChild','strP2Email','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strP2Email','ChildDefine',0),(1,0,100,5,'Person','strP2Email2','ChildDefine',0),(1,0,100,5,'PersonChild','strP2Email2','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strP2Email2','ChildDefine',0),(1,0,100,5,'Person','intP2AssistAreaID','ChildDefine',0),(1,0,100,5,'PersonChild','intP2AssistAreaID','ChildDefine',0),(1,0,100,5,'PersonRegoForm','intP2AssistAreaID','ChildDefine',0),(1,0,100,5,'Person','intFinancialActive','ChildDefine',0),(1,0,100,5,'PersonChild','intFinancialActive','ChildDefine',0),(1,0,100,5,'PersonRegoForm','intFinancialActive','ChildDefine',0),(1,0,100,5,'Person','intMemberPackageID','ChildDefine',0),(1,0,100,5,'PersonChild','intMemberPackageID','ChildDefine',0),(1,0,100,5,'PersonRegoForm','intMemberPackageID','ChildDefine',0),(1,0,100,5,'Person','intLifeMember','ChildDefine',0),(1,0,100,5,'PersonChild','intLifeMember','ChildDefine',0),(1,0,100,5,'PersonRegoForm','intLifeMember','ChildDefine',0),(1,0,100,5,'Person','intMedicalConditions','Editable',0),(1,0,100,5,'PersonChild','intMedicalConditions','ChildDefine',0),(1,0,100,5,'PersonRegoForm','intMedicalConditions','ChildDefine',0),(1,0,100,5,'Person','intAllergies','ChildDefine',0),(1,0,100,5,'PersonChild','intAllergies','ChildDefine',0),(1,0,100,5,'PersonRegoForm','intAllergies','ChildDefine',0),(1,0,100,5,'Person','intAllowMedicalTreatment','ChildDefine',0),(1,0,100,5,'PersonChild','intAllowMedicalTreatment','ChildDefine',0),(1,0,100,5,'PersonRegoForm','intAllowMedicalTreatment','ChildDefine',0),(1,0,100,5,'Person','strMedicalNotes','Editable',0),(1,0,100,5,'PersonChild','strMedicalNotes','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strMedicalNotes','ChildDefine',0),(1,0,100,5,'Person','intOccupationID','ChildDefine',0),(1,0,100,5,'PersonChild','intOccupationID','ChildDefine',0),(1,0,100,5,'PersonRegoForm','intOccupationID','ChildDefine',0),(1,0,100,5,'Person','strLoyaltyNumber','ChildDefine',0),(1,0,100,5,'PersonChild','strLoyaltyNumber','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strLoyaltyNumber','ChildDefine',0),(1,0,100,5,'Person','intMailingList','ChildDefine',0),(1,0,100,5,'PersonChild','intMailingList','ChildDefine',0),(1,0,100,5,'PersonRegoForm','intMailingList','ChildDefine',0),(1,0,100,5,'Person','strCustomStr1','ChildDefine',0),(1,0,100,5,'PersonChild','strCustomStr1','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strCustomStr1','ChildDefine',0),(1,0,100,5,'Person','strCustomStr2','ChildDefine',0),(1,0,100,5,'PersonChild','strCustomStr2','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strCustomStr2','ChildDefine',0),(1,0,100,5,'Person','strCustomStr3','ChildDefine',0),(1,0,100,5,'PersonChild','strCustomStr3','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strCustomStr3','ChildDefine',0),(1,0,100,5,'Person','strCustomStr4','ChildDefine',0),(1,0,100,5,'PersonChild','strCustomStr4','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strCustomStr4','ChildDefine',0),(1,0,100,5,'Person','strCustomStr5','ChildDefine',0),(1,0,100,5,'PersonChild','strCustomStr5','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strCustomStr5','ChildDefine',0),(1,0,100,5,'Person','strCustomStr6','ChildDefine',0),(1,0,100,5,'PersonChild','strCustomStr6','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strCustomStr6','ChildDefine',0),(1,0,100,5,'Person','strCustomStr7','ChildDefine',0),(1,0,100,5,'PersonChild','strCustomStr7','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strCustomStr7','ChildDefine',0),(1,0,100,5,'Person','strCustomStr8','ChildDefine',0),(1,0,100,5,'PersonChild','strCustomStr8','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strCustomStr8','ChildDefine',0),(1,0,100,5,'Person','strCustomStr9','ChildDefine',0),(1,0,100,5,'PersonChild','strCustomStr9','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strCustomStr9','ChildDefine',0),(1,0,100,5,'Person','strCustomStr10','ChildDefine',0),(1,0,100,5,'PersonChild','strCustomStr10','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strCustomStr10','ChildDefine',0),(1,0,100,5,'Person','strCustomStr11','ChildDefine',0),(1,0,100,5,'PersonChild','strCustomStr11','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strCustomStr11','ChildDefine',0),(1,0,100,5,'Person','strCustomStr12','ChildDefine',0),(1,0,100,5,'PersonChild','strCustomStr12','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strCustomStr12','ChildDefine',0),(1,0,100,5,'Person','strCustomStr13','ChildDefine',0),(1,0,100,5,'PersonChild','strCustomStr13','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strCustomStr13','ChildDefine',0),(1,0,100,5,'Person','strCustomStr14','ChildDefine',0),(1,0,100,5,'PersonChild','strCustomStr14','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strCustomStr14','ChildDefine',0),(1,0,100,5,'Person','strCustomStr15','ChildDefine',0),(1,0,100,5,'PersonChild','strCustomStr15','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strCustomStr15','ChildDefine',0),(1,0,100,5,'Person','strCustomStr16','ChildDefine',0),(1,0,100,5,'PersonChild','strCustomStr16','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strCustomStr16','ChildDefine',0),(1,0,100,5,'Person','strCustomStr17','ChildDefine',0),(1,0,100,5,'PersonChild','strCustomStr17','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strCustomStr17','ChildDefine',0),(1,0,100,5,'Person','strCustomStr18','ChildDefine',0),(1,0,100,5,'PersonChild','strCustomStr18','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strCustomStr18','ChildDefine',0),(1,0,100,5,'Person','strCustomStr19','ChildDefine',0),(1,0,100,5,'PersonChild','strCustomStr19','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strCustomStr19','ChildDefine',0),(1,0,100,5,'Person','strCustomStr20','ChildDefine',0),(1,0,100,5,'PersonChild','strCustomStr20','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strCustomStr20','ChildDefine',0),(1,0,100,5,'Person','strCustomStr21','ChildDefine',0),(1,0,100,5,'PersonChild','strCustomStr21','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strCustomStr21','ChildDefine',0),(1,0,100,5,'Person','strCustomStr22','ChildDefine',0),(1,0,100,5,'PersonChild','strCustomStr22','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strCustomStr22','ChildDefine',0),(1,0,100,5,'Person','strCustomStr23','ChildDefine',0),(1,0,100,5,'PersonChild','strCustomStr23','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strCustomStr23','ChildDefine',0),(1,0,100,5,'Person','strCustomStr24','ChildDefine',0),(1,0,100,5,'PersonChild','strCustomStr24','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strCustomStr24','ChildDefine',0),(1,0,100,5,'Person','strCustomStr25','ChildDefine',0),(1,0,100,5,'PersonChild','strCustomStr25','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strCustomStr25','ChildDefine',0),(1,0,100,5,'Person','dblCustomDbl1','ChildDefine',0),(1,0,100,5,'PersonChild','dblCustomDbl1','ChildDefine',0),(1,0,100,5,'PersonRegoForm','dblCustomDbl1','ChildDefine',0),(1,0,100,5,'Person','dblCustomDbl2','ChildDefine',0),(1,0,100,5,'PersonChild','dblCustomDbl2','ChildDefine',0),(1,0,100,5,'PersonRegoForm','dblCustomDbl2','ChildDefine',0),(1,0,100,5,'Person','dblCustomDbl3','ChildDefine',0),(1,0,100,5,'PersonChild','dblCustomDbl3','ChildDefine',0),(1,0,100,5,'PersonRegoForm','dblCustomDbl3','ChildDefine',0),(1,0,100,5,'Person','dblCustomDbl4','ChildDefine',0),(1,0,100,5,'PersonChild','dblCustomDbl4','ChildDefine',0),(1,0,100,5,'PersonRegoForm','dblCustomDbl4','ChildDefine',0),(1,0,100,5,'Person','dblCustomDbl5','ChildDefine',0),(1,0,100,5,'PersonChild','dblCustomDbl5','ChildDefine',0),(1,0,100,5,'PersonRegoForm','dblCustomDbl5','ChildDefine',0),(1,0,100,5,'Person','dblCustomDbl6','ChildDefine',0),(1,0,100,5,'PersonChild','dblCustomDbl6','ChildDefine',0),(1,0,100,5,'PersonRegoForm','dblCustomDbl6','ChildDefine',0),(1,0,100,5,'Person','dblCustomDbl7','ChildDefine',0),(1,0,100,5,'PersonChild','dblCustomDbl7','ChildDefine',0),(1,0,100,5,'PersonRegoForm','dblCustomDbl7','ChildDefine',0),(1,0,100,5,'Person','dblCustomDbl8','ChildDefine',0),(1,0,100,5,'PersonChild','dblCustomDbl8','ChildDefine',0),(1,0,100,5,'PersonRegoForm','dblCustomDbl8','ChildDefine',0),(1,0,100,5,'Person','dblCustomDbl9','ChildDefine',0),(1,0,100,5,'PersonChild','dblCustomDbl9','ChildDefine',0),(1,0,100,5,'PersonRegoForm','dblCustomDbl9','ChildDefine',0),(1,0,100,5,'Person','dblCustomDbl10','ChildDefine',0),(1,0,100,5,'PersonChild','dblCustomDbl10','ChildDefine',0),(1,0,100,5,'PersonRegoForm','dblCustomDbl10','ChildDefine',0),(1,0,100,5,'Person','dblCustomDbl11','ChildDefine',0),(1,0,100,5,'PersonChild','dblCustomDbl11','ChildDefine',0),(1,0,100,5,'PersonRegoForm','dblCustomDbl11','ChildDefine',0),(1,0,100,5,'Person','dblCustomDbl12','ChildDefine',0),(1,0,100,5,'PersonChild','dblCustomDbl12','ChildDefine',0),(1,0,100,5,'PersonRegoForm','dblCustomDbl12','ChildDefine',0),(1,0,100,5,'Person','dblCustomDbl13','ChildDefine',0),(1,0,100,5,'PersonChild','dblCustomDbl13','ChildDefine',0),(1,0,100,5,'PersonRegoForm','dblCustomDbl13','ChildDefine',0),(1,0,100,5,'Person','dblCustomDbl14','ChildDefine',0),(1,0,100,5,'PersonChild','dblCustomDbl14','ChildDefine',0),(1,0,100,5,'PersonRegoForm','dblCustomDbl14','ChildDefine',0),(1,0,100,5,'Person','dblCustomDbl15','ChildDefine',0),(1,0,100,5,'PersonChild','dblCustomDbl15','ChildDefine',0),(1,0,100,5,'PersonRegoForm','dblCustomDbl15','ChildDefine',0),(1,0,100,5,'Person','dblCustomDbl16','ChildDefine',0),(1,0,100,5,'PersonChild','dblCustomDbl16','ChildDefine',0),(1,0,100,5,'PersonRegoForm','dblCustomDbl16','ChildDefine',0),(1,0,100,5,'Person','dblCustomDbl17','ChildDefine',0),(1,0,100,5,'PersonChild','dblCustomDbl17','ChildDefine',0),(1,0,100,5,'PersonRegoForm','dblCustomDbl17','ChildDefine',0),(1,0,100,5,'Person','dblCustomDbl18','ChildDefine',0),(1,0,100,5,'PersonChild','dblCustomDbl18','ChildDefine',0),(1,0,100,5,'PersonRegoForm','dblCustomDbl18','ChildDefine',0),(1,0,100,5,'Person','dblCustomDbl19','ChildDefine',0),(1,0,100,5,'PersonChild','dblCustomDbl19','ChildDefine',0),(1,0,100,5,'PersonRegoForm','dblCustomDbl19','ChildDefine',0),(1,0,100,5,'Person','dblCustomDbl20','ChildDefine',0),(1,0,100,5,'PersonChild','dblCustomDbl20','ChildDefine',0),(1,0,100,5,'PersonRegoForm','dblCustomDbl20','ChildDefine',0),(1,0,100,5,'Person','dtCustomDt1','ChildDefine',0),(1,0,100,5,'PersonChild','dtCustomDt1','ChildDefine',0),(1,0,100,5,'PersonRegoForm','dtCustomDt1','ChildDefine',0),(1,0,100,5,'Person','dtCustomDt2','ChildDefine',0),(1,0,100,5,'PersonChild','dtCustomDt2','ChildDefine',0),(1,0,100,5,'PersonRegoForm','dtCustomDt2','ChildDefine',0),(1,0,100,5,'Person','dtCustomDt3','ChildDefine',0),(1,0,100,5,'PersonChild','dtCustomDt3','ChildDefine',0),(1,0,100,5,'PersonRegoForm','dtCustomDt3','ChildDefine',0),(1,0,100,5,'Person','dtCustomDt4','ChildDefine',0),(1,0,100,5,'PersonChild','dtCustomDt4','ChildDefine',0),(1,0,100,5,'PersonRegoForm','dtCustomDt4','ChildDefine',0),(1,0,100,5,'Person','dtCustomDt5','ChildDefine',0),(1,0,100,5,'PersonChild','dtCustomDt5','ChildDefine',0),(1,0,100,5,'PersonRegoForm','dtCustomDt5','ChildDefine',0),(1,0,100,5,'Person','dtCustomDt6','ChildDefine',0),(1,0,100,5,'PersonChild','strAddress2','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strAddress2','ChildDefine',0),(1,0,100,5,'Person','strSuburb','Editable',0),(1,0,100,5,'PersonChild','strSuburb','Editable',0),(1,0,100,5,'PersonRegoForm','strSuburb','Editable',0),(1,0,100,5,'Person','strCityOfResidence','ChildDefine',0),(1,0,100,5,'PersonChild','strCityOfResidence','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strCityOfResidence','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strFatherCountry','ChildDefine',0),(1,0,100,5,'Person','strPreferredName','ChildDefine',0),(1,0,100,5,'PersonChild','strPreferredName','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strPreferredName','ChildDefine',0),(1,0,100,5,'Person','dtDOB','Compulsory',0),(1,0,100,5,'PersonChild','dtDOB','Compulsory',0),(1,0,100,5,'PersonRegoForm','dtDOB','Compulsory',0),(1,0,100,5,'Person','strPlaceofBirth','ChildDefine',0),(1,0,100,5,'PersonChild','strPlaceofBirth','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strPlaceofBirth','ChildDefine',0),(1,0,100,5,'Person','strCountryOfBirth','Editable',0),(1,0,100,5,'PersonChild','strCountryOfBirth','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strCountryOfBirth','ChildDefine',0),(1,0,100,5,'Person','intGender','Compulsory',0),(1,0,100,5,'PersonChild','intGender','Compulsory',0),(1,0,100,5,'PersonRegoForm','intGender','Compulsory',0),(1,0,100,5,'Person','intDeceased','ChildDefine',0),(1,0,100,5,'PersonChild','intDeceased','ChildDefine',0),(1,0,100,5,'PersonRegoForm','intDeceased','ChildDefine',0),(1,0,100,5,'Person','strEyeColour','ChildDefine',0),(1,0,100,5,'PersonChild','strEyeColour','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strEyeColour','ChildDefine',0),(1,0,100,5,'Person','strHairColour','ChildDefine',0),(1,0,100,5,'PersonChild','strHairColour','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strHairColour','ChildDefine',0),(1,0,100,5,'Person','intEthnicityID','ChildDefine',0),(1,0,100,5,'PersonChild','intEthnicityID','ChildDefine',0),(1,0,100,5,'PersonRegoForm','intEthnicityID','ChildDefine',0),(1,0,100,5,'Person','strHeight','ChildDefine',0),(1,0,100,5,'PersonChild','strHeight','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strHeight','ChildDefine',0),(1,0,100,5,'Person','strWeight','ChildDefine',0),(1,0,100,5,'PersonChild','strWeight','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strWeight','ChildDefine',0),(1,0,100,5,'Person','strAddress1','Editable',0),(1,0,100,5,'PersonChild','strAddress1','Editable',0),(1,0,100,5,'PersonRegoForm','strAddress1','Editable',0),(1,0,100,5,'Person','strAddress2','Editable',0),(1,0,5,20521,'PersonChild','strFirstname','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strSalutation','ChildDefine',0),(1,0,5,20521,'Person','strFirstname','ChildDefine',0),(1,0,5,20521,'Person','strSalutation','ChildDefine',0),(1,0,5,20521,'PersonChild','strSalutation','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','intRecStatus','ChildDefine',0),(1,0,5,20521,'Person','intRecStatus','ChildDefine',0),(1,0,5,20521,'PersonChild','intRecStatus','ChildDefine',0),(1,0,100,5,'Club','intClubCustomBool5','ChildDefine',0),(1,0,100,5,'ClubChild','intClubCustomBool5','ChildDefine',0),(1,0,100,5,'Club','intClubCustomBool4','ChildDefine',0),(1,0,100,5,'ClubChild','intClubCustomBool4','ChildDefine',0),(1,0,100,5,'Club','intClubCustomBool3','ChildDefine',0),(1,0,100,5,'ClubChild','intClubCustomBool3','ChildDefine',0),(1,0,100,5,'Club','intClubCustomBool2','ChildDefine',0),(1,0,100,5,'ClubChild','intClubCustomBool2','ChildDefine',0),(1,0,100,5,'Club','intClubCustomBool1','ChildDefine',0),(1,0,100,5,'ClubChild','intClubCustomBool1','ChildDefine',0),(1,0,100,5,'Club','intClubCustomLU10','ChildDefine',0),(1,0,100,5,'ClubChild','intClubCustomLU10','ChildDefine',0),(1,0,100,5,'Club','intClubCustomLU9','ChildDefine',0),(1,0,100,5,'ClubChild','intClubCustomLU9','ChildDefine',0),(1,0,100,5,'Club','intClubCustomLU8','ChildDefine',0),(1,0,100,5,'ClubChild','intClubCustomLU8','ChildDefine',0),(1,0,100,5,'Club','dblClubCustomDbl7','ChildDefine',0),(1,0,100,5,'ClubChild','dblClubCustomDbl7','ChildDefine',0),(1,0,100,5,'Club','dblClubCustomDbl8','ChildDefine',0),(1,0,100,5,'ClubChild','dblClubCustomDbl8','ChildDefine',0),(1,0,100,5,'Club','dblClubCustomDbl9','ChildDefine',0),(1,0,100,5,'ClubChild','dblClubCustomDbl9','ChildDefine',0),(1,0,100,5,'Club','dblClubCustomDbl10','ChildDefine',0),(1,0,100,5,'ClubChild','dblClubCustomDbl10','ChildDefine',0),(1,0,100,5,'Club','dtClubCustomDt1','ChildDefine',0),(1,0,100,5,'ClubChild','dtClubCustomDt1','ChildDefine',0),(1,0,100,5,'Club','dtClubCustomDt2','ChildDefine',0),(1,0,100,5,'ClubChild','dtClubCustomDt2','ChildDefine',0),(1,0,100,5,'Club','dtClubCustomDt3','ChildDefine',0),(1,0,100,5,'ClubChild','dtClubCustomDt3','ChildDefine',0),(1,0,100,5,'Club','dtClubCustomDt4','ChildDefine',0),(1,0,100,5,'ClubChild','dtClubCustomDt4','ChildDefine',0),(1,0,100,5,'Club','dtClubCustomDt5','ChildDefine',0),(1,0,100,5,'ClubChild','dtClubCustomDt5','ChildDefine',0),(1,0,100,5,'Club','intClubCustomLU1','ChildDefine',0),(1,0,100,5,'ClubChild','intClubCustomLU1','ChildDefine',0),(1,0,100,5,'Club','intClubCustomLU2','ChildDefine',0),(1,0,100,5,'ClubChild','intClubCustomLU2','ChildDefine',0),(1,0,100,5,'Club','intClubCustomLU3','ChildDefine',0),(1,0,100,5,'ClubChild','intClubCustomLU3','ChildDefine',0),(1,0,100,5,'Club','intClubCustomLU4','ChildDefine',0),(1,0,100,5,'ClubChild','intClubCustomLU4','ChildDefine',0),(1,0,100,5,'Club','intClubCustomLU5','ChildDefine',0),(1,0,100,5,'ClubChild','intClubCustomLU5','ChildDefine',0),(1,0,100,5,'Club','intClubCustomLU6','ChildDefine',0),(1,0,100,5,'ClubChild','intClubCustomLU6','ChildDefine',0),(1,0,100,5,'Club','intClubCustomLU7','ChildDefine',0),(1,0,100,5,'ClubChild','intClubCustomLU7','ChildDefine',0),(1,0,100,5,'Club','dblClubCustomDbl6','ChildDefine',0),(1,0,100,5,'ClubChild','dblClubCustomDbl6','ChildDefine',0),(1,0,100,5,'Club','dblClubCustomDbl5','ChildDefine',0),(1,0,100,5,'ClubChild','dblClubCustomDbl5','ChildDefine',0),(1,0,100,5,'Club','dblClubCustomDbl4','ChildDefine',0),(1,0,100,5,'ClubChild','dblClubCustomDbl4','ChildDefine',0),(1,0,100,5,'Club','dblClubCustomDbl3','ChildDefine',0),(1,0,100,5,'ClubChild','dblClubCustomDbl3','ChildDefine',0),(1,0,100,5,'ClubChild','strClubCustomStr10','ChildDefine',0),(1,0,100,5,'Club','strClubCustomStr11','ChildDefine',0),(1,0,100,5,'ClubChild','strClubCustomStr11','ChildDefine',0),(1,0,100,5,'Club','strClubCustomStr12','ChildDefine',0),(1,0,100,5,'ClubChild','strClubCustomStr12','ChildDefine',0),(1,0,100,5,'Club','strClubCustomStr13','ChildDefine',0),(1,0,100,5,'ClubChild','strClubCustomStr13','ChildDefine',0),(1,0,100,5,'Club','strClubCustomStr14','ChildDefine',0),(1,0,100,5,'ClubChild','strClubCustomStr14','ChildDefine',0),(1,0,100,5,'Club','strClubCustomStr15','ChildDefine',0),(1,0,100,5,'ClubChild','strClubCustomStr15','ChildDefine',0),(1,0,100,5,'Club','dblClubCustomDbl1','ChildDefine',0),(1,0,100,5,'ClubChild','dblClubCustomDbl1','ChildDefine',0),(1,0,100,5,'Club','dblClubCustomDbl2','ChildDefine',0),(1,0,100,5,'ClubChild','dblClubCustomDbl2','ChildDefine',0),(1,0,100,5,'ClubChild','strClubCustomStr6','ChildDefine',0),(1,0,100,5,'Club','strClubCustomStr7','ChildDefine',0),(1,0,100,5,'ClubChild','strClubCustomStr7','ChildDefine',0),(1,0,100,5,'Club','strClubCustomStr8','ChildDefine',0),(1,0,100,5,'ClubChild','strClubCustomStr8','ChildDefine',0),(1,0,100,5,'Club','strClubCustomStr9','ChildDefine',0),(1,0,100,5,'ClubChild','strClubCustomStr9','ChildDefine',0),(1,0,100,5,'Club','strClubCustomStr10','ChildDefine',0),(1,0,100,5,'ClubChild','strEmail','ChildDefine',0),(1,0,100,5,'Club','strIncNo','ChildDefine',0),(1,0,100,5,'ClubChild','strIncNo','ChildDefine',0),(1,0,100,5,'Club','strBusinessNo','ChildDefine',0),(1,0,100,5,'ClubChild','strBusinessNo','ChildDefine',0),(1,0,100,5,'Club','strColours','ChildDefine',0),(1,0,100,5,'ClubChild','strColours','ChildDefine',0),(1,0,100,5,'Club','intClubTypeID','Editable',0),(1,0,100,5,'ClubChild','intClubTypeID','Editable',0),(1,0,100,5,'Club','intAgeTypeID','ChildDefine',0),(1,0,100,5,'ClubChild','intAgeTypeID','ChildDefine',0),(1,0,100,5,'Club','intClubCategoryID','Editable',0),(1,0,100,5,'ClubChild','intClubCategoryID','Editable',0),(1,0,100,5,'Club','strNotes','ChildDefine',0),(1,0,100,5,'ClubChild','strNotes','ChildDefine',0),(1,0,100,5,'Club','Username','ChildDefine',0),(1,0,100,5,'ClubChild','Username','ChildDefine',0),(1,0,100,5,'Club','strClubCustomStr1','ChildDefine',0),(1,0,100,5,'ClubChild','strClubCustomStr1','ChildDefine',0),(1,0,100,5,'Club','strClubCustomStr2','ChildDefine',0),(1,0,100,5,'ClubChild','strClubCustomStr2','ChildDefine',0),(1,0,100,5,'Club','strClubCustomStr3','ChildDefine',0),(1,0,100,5,'ClubChild','strClubCustomStr3','ChildDefine',0),(1,0,100,5,'Club','strClubCustomStr4','ChildDefine',0),(1,0,100,5,'ClubChild','strClubCustomStr4','ChildDefine',0),(1,0,100,5,'Club','strClubCustomStr5','ChildDefine',0),(1,0,100,5,'ClubChild','strClubCustomStr5','ChildDefine',0),(1,0,100,5,'Club','strClubCustomStr6','ChildDefine',0),(1,0,100,5,'Club','strName','Editable',0),(1,0,100,5,'ClubChild','strName','Editable',0),(1,0,100,5,'Club','intRecStatus','Editable',0),(1,0,100,5,'ClubChild','intRecStatus','ReadOnly',0),(1,0,100,5,'Club','strAbbrev','ChildDefine',0),(1,0,100,5,'ClubChild','strAbbrev','ChildDefine',0),(1,0,100,5,'Club','strAddress1','Editable',0),(1,0,100,5,'ClubChild','strAddress1','Editable',0),(1,0,100,5,'Club','strAddress2','ChildDefine',0),(1,0,100,5,'ClubChild','strAddress2','ChildDefine',0),(1,0,100,5,'Club','strSuburb','Editable',0),(1,0,100,5,'ClubChild','strSuburb','Editable',0),(1,0,100,5,'Club','strPostalCode','Editable',0),(1,0,100,5,'ClubChild','strPostalCode','Editable',0),(1,0,100,5,'Club','strState','Editable',0),(1,0,100,5,'ClubChild','strState','Editable',0),(1,0,100,5,'Club','strCountry','Editable',0),(1,0,100,5,'ClubChild','strCountry','Editable',0),(1,0,100,5,'Club','strLGA','ChildDefine',0),(1,0,100,5,'ClubChild','strLGA','ChildDefine',0),(1,0,100,5,'Club','strPhone','ChildDefine',0),(1,0,100,5,'ClubChild','strPhone','ChildDefine',0),(1,0,100,5,'Club','strFax','ChildDefine',0),(1,0,100,5,'ClubChild','strFax','ChildDefine',0),(1,0,100,5,'Club','strEmail','ChildDefine',0),(1,0,100,5,'PersonRegoForm','dtRegisteredUntil','ChildDefine',0),(1,0,100,5,'Person','dtCreatedOnline','ReadOnly',0),(1,0,100,5,'PersonChild','dtCreatedOnline','ReadOnly',0),(1,0,100,5,'PersonRegoForm','dtCreatedOnline','ChildDefine',0),(1,0,100,5,'Person','intConsentSignatureSighted','ChildDefine',0),(1,0,100,5,'PersonChild','intConsentSignatureSighted','ChildDefine',0),(1,0,100,5,'PersonRegoForm','intConsentSignatureSighted','ChildDefine',0),(1,0,100,5,'Person','intDefaulter','ChildDefine',0),(1,0,100,5,'PersonChild','intDefaulter','ChildDefine',0),(1,0,100,5,'PersonRegoForm','intDefaulter','ChildDefine',0),(1,0,100,5,'Person','PlayerNumberClub.strJumperNum','ChildDefine',0),(1,0,100,5,'PersonChild','PlayerNumberClub.strJumperNum','ChildDefine',0),(1,0,100,5,'Person','intPhotoUseApproval','ChildDefine',0),(1,0,100,5,'PersonChild','intPhotoUseApproval','ChildDefine',0),(1,0,100,5,'PersonRegoForm','intPhotoUseApproval','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strFirstname','ChildDefine',0),(1,0,5,20521,'Person','strMiddlename','ChildDefine',0),(1,0,5,20521,'PersonChild','strMiddlename','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strMiddlename','ChildDefine',0),(1,0,5,20521,'Person','strSurname','Editable',0),(1,0,5,20521,'PersonChild','strSurname','Editable',0),(1,0,5,20521,'PersonRegoForm','strSurname','Editable',0),(1,0,5,20521,'Person','strMaidenName','ChildDefine',0),(1,0,5,20521,'PersonChild','strMaidenName','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strMaidenName','ChildDefine',0),(1,0,5,20521,'Person','strMotherCountry','ChildDefine',0),(1,0,5,20521,'PersonChild','strMotherCountry','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strMotherCountry','ChildDefine',0),(1,0,5,20521,'Person','strFatherCountry','ChildDefine',0),(1,0,5,20521,'PersonChild','strFatherCountry','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strFatherCountry','ChildDefine',0),(1,0,5,20521,'Person','strPreferredName','ChildDefine',0),(1,0,5,20521,'PersonChild','strPreferredName','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strPreferredName','ChildDefine',0),(1,0,5,20521,'Person','dtDOB','ChildDefine',0),(1,0,5,20521,'PersonChild','dtDOB','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','dtDOB','ChildDefine',0),(1,0,5,20521,'Person','strPlaceofBirth','ChildDefine',0),(1,0,5,20521,'PersonChild','strPlaceofBirth','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strPlaceofBirth','ChildDefine',0),(1,0,5,20521,'Person','strCountryOfBirth','ChildDefine',0),(1,0,5,20521,'PersonChild','strCountryOfBirth','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strCountryOfBirth','ChildDefine',0),(1,0,5,20521,'Person','intGender','ChildDefine',0),(1,0,5,20521,'PersonChild','intGender','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','intGender','ChildDefine',0),(1,0,5,20521,'Person','intDeceased','ChildDefine',0),(1,0,5,20521,'PersonChild','intDeceased','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','intDeceased','ChildDefine',0),(1,0,5,20521,'Person','strEyeColour','ChildDefine',0),(1,0,5,20521,'PersonChild','strEyeColour','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strEyeColour','ChildDefine',0),(1,0,5,20521,'Person','strHairColour','ChildDefine',0),(1,0,5,20521,'PersonChild','strHairColour','ChildDefine',0),(1,0,100,5,'PersonRegoForm','intCustomBool1','ChildDefine',0),(1,0,100,5,'Person','intCustomBool2','ChildDefine',0),(1,0,100,5,'PersonChild','intCustomBool2','ChildDefine',0),(1,0,100,5,'PersonRegoForm','intCustomBool2','ChildDefine',0),(1,0,100,5,'Person','intCustomBool3','ChildDefine',0),(1,0,100,5,'PersonChild','intCustomBool3','ChildDefine',0),(1,0,100,5,'PersonRegoForm','intCustomBool3','ChildDefine',0),(1,0,100,5,'Person','intCustomBool4','ChildDefine',0),(1,0,100,5,'PersonChild','intCustomBool4','ChildDefine',0),(1,0,100,5,'PersonRegoForm','intCustomBool4','ChildDefine',0),(1,0,100,5,'Person','intCustomBool5','ChildDefine',0),(1,0,100,5,'PersonChild','intCustomBool5','ChildDefine',0),(1,0,100,5,'PersonRegoForm','intCustomBool5','ChildDefine',0),(1,0,100,5,'Person','intCustomBool6','ChildDefine',0),(1,0,100,5,'PersonChild','intCustomBool6','ChildDefine',0),(1,0,100,5,'PersonRegoForm','intCustomBool6','ChildDefine',0),(1,0,100,5,'Person','intCustomBool7','ChildDefine',0),(1,0,100,5,'PersonChild','intCustomBool7','ChildDefine',0),(1,0,100,5,'PersonRegoForm','intCustomBool7','ChildDefine',0),(1,0,100,5,'Person','intFavStateTeamID','ChildDefine',0),(1,0,100,5,'PersonChild','intFavStateTeamID','ChildDefine',0),(1,0,100,5,'PersonRegoForm','intFavStateTeamID','ChildDefine',0),(1,0,100,5,'Person','intFavNationalTeamID','ChildDefine',0),(1,0,100,5,'PersonChild','intFavNationalTeamID','ChildDefine',0),(1,0,100,5,'PersonRegoForm','intFavNationalTeamID','ChildDefine',0),(1,0,100,5,'Person','intFavNationalTeamMember','ChildDefine',0),(1,0,100,5,'PersonChild','intFavNationalTeamMember','ChildDefine',0),(1,0,100,5,'PersonRegoForm','intFavNationalTeamMember','ChildDefine',0),(1,0,100,5,'Person','intAttendSportCount','ChildDefine',0),(1,0,100,5,'PersonChild','intAttendSportCount','ChildDefine',0),(1,0,100,5,'PersonRegoForm','intAttendSportCount','ChildDefine',0),(1,0,100,5,'Person','intWatchSportHowOftenID','ChildDefine',0),(1,0,100,5,'PersonChild','intWatchSportHowOftenID','ChildDefine',0),(1,0,100,5,'PersonRegoForm','intWatchSportHowOftenID','ChildDefine',0),(1,0,100,5,'Person','strNotes','ChildDefine',0),(1,0,100,5,'PersonChild','dtCustomDt6','ChildDefine',0),(1,0,100,5,'PersonRegoForm','dtCustomDt6','ChildDefine',0),(1,0,100,5,'Person','dtCustomDt7','ChildDefine',0),(1,0,100,5,'PersonChild','dtCustomDt7','ChildDefine',0),(1,0,100,5,'PersonRegoForm','dtCustomDt7','ChildDefine',0),(1,0,100,5,'Person','dtCustomDt8','ChildDefine',0),(1,0,100,5,'PersonChild','dtCustomDt8','ChildDefine',0),(1,0,100,5,'PersonRegoForm','dtCustomDt8','ChildDefine',0),(1,0,100,5,'Person','dtCustomDt9','ChildDefine',0),(1,0,100,5,'PersonChild','dtCustomDt9','ChildDefine',0),(1,0,100,5,'PersonRegoForm','dtCustomDt9','ChildDefine',0),(1,0,100,5,'Person','dtCustomDt10','ChildDefine',0),(1,0,100,5,'PersonChild','dtCustomDt10','ChildDefine',0),(1,0,100,5,'PersonRegoForm','dtCustomDt10','ChildDefine',0),(1,0,100,5,'Person','dtCustomDt11','ChildDefine',0),(1,0,100,5,'PersonChild','dtCustomDt11','ChildDefine',0),(1,0,100,5,'PersonRegoForm','dtCustomDt11','ChildDefine',0),(1,0,100,5,'Person','dtCustomDt12','ChildDefine',0),(1,0,100,5,'PersonChild','dtCustomDt12','ChildDefine',0),(1,0,100,5,'PersonRegoForm','dtCustomDt12','ChildDefine',0),(1,0,100,5,'Person','dtCustomDt13','ChildDefine',0),(1,0,100,5,'PersonChild','dtCustomDt13','ChildDefine',0),(1,0,100,5,'PersonRegoForm','dtCustomDt13','ChildDefine',0),(1,0,100,5,'Person','dtCustomDt14','ChildDefine',0),(1,0,100,5,'PersonChild','dtCustomDt14','ChildDefine',0),(1,0,100,5,'PersonRegoForm','dtCustomDt14','ChildDefine',0),(1,0,100,5,'Person','dtCustomDt15','ChildDefine',0),(1,0,100,5,'PersonChild','dtCustomDt15','ChildDefine',0),(1,0,100,5,'Person','strNationalNum','ReadOnly',0),(1,0,100,5,'PersonChild','strNationalNum','ReadOnly',0),(1,0,100,5,'PersonRegoForm','strNationalNum','ChildDefine',0),(1,0,100,5,'Person','strMemberNo','ReadOnly',0),(1,0,100,5,'PersonChild','strMemberNo','ReadOnly',0),(1,0,100,5,'PersonRegoForm','strMemberNo','ChildDefine',0),(1,0,100,5,'Person','intRecStatus','Editable',0),(1,0,100,5,'PersonChild','intRecStatus','ChildDefine',0),(1,0,100,5,'PersonRegoForm','intRecStatus','ChildDefine',0),(1,0,100,5,'Person','strSalutation','ChildDefine',0),(1,0,100,5,'PersonChild','strSalutation','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strSalutation','ChildDefine',0),(1,0,100,5,'Person','strFirstname','Compulsory',0),(1,0,100,5,'PersonChild','strFirstname','Compulsory',0),(1,0,100,5,'PersonRegoForm','strFirstname','Compulsory',0),(1,0,100,5,'Person','strMiddlename','ChildDefine',0),(1,0,100,5,'PersonChild','strMiddlename','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strMiddlename','ChildDefine',0),(1,0,100,5,'Person','strSurname','Compulsory',0),(1,0,100,5,'PersonChild','strSurname','Compulsory',0),(1,0,100,5,'PersonRegoForm','strSurname','Compulsory',0),(1,0,100,5,'Person','strMaidenName','ChildDefine',0),(1,0,100,5,'PersonChild','strMaidenName','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strMaidenName','ChildDefine',0),(1,0,100,5,'Person','strMotherCountry','ChildDefine',0),(1,0,100,5,'PersonChild','strMotherCountry','ChildDefine',0),(1,0,100,5,'PersonRegoForm','strMotherCountry','ChildDefine',0),(1,0,100,5,'Person','strFatherCountry','ChildDefine',0),(1,0,100,5,'PersonChild','strFatherCountry','ChildDefine',0),(1,0,5,20521,'Person','strNationalNum','ChildDefine',0),(1,0,5,16,'PersonRegoForm','dtLastRegistered','ChildDefine',0),(1,0,5,16,'Person','dtLastUpdate','ReadOnly',0),(1,0,5,16,'PersonChild','dtLastUpdate','ReadOnly',0),(1,0,5,16,'PersonRegoForm','dtLastUpdate','ChildDefine',0),(1,0,5,16,'PersonRegoForm','dtFirstRegistered','ChildDefine',0),(1,0,5,16,'Person','dtLastRegistered','ReadOnly',0),(1,0,5,16,'PersonChild','dtLastRegistered','ReadOnly',0),(1,0,5,16,'Person','strCustomStr1','ChildDefine',0),(1,0,5,16,'PersonChild','strCustomStr1','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strCustomStr1','ChildDefine',0),(1,0,5,16,'Person','strCustomStr2','Editable',0),(1,0,5,16,'PersonChild','strCustomStr2','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strCustomStr2','ChildDefine',0),(1,0,5,16,'Person','strCustomStr3','Editable',0),(1,0,5,16,'PersonChild','strCustomStr3','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strCustomStr3','ChildDefine',0),(1,0,5,16,'Person','strCustomStr4','Editable',0),(1,0,5,16,'PersonChild','strCustomStr4','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strCustomStr4','ChildDefine',0),(1,0,5,16,'Person','strCustomStr5','Editable',0),(1,0,5,16,'PersonChild','strCustomStr5','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strCustomStr5','ChildDefine',0),(1,0,5,16,'Person','strCustomStr6','Editable',0),(1,0,5,16,'PersonChild','strCustomStr6','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strCustomStr6','ChildDefine',0),(1,0,5,16,'Person','strCustomStr7','Editable',0),(1,0,5,16,'PersonChild','strCustomStr7','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strCustomStr7','ChildDefine',0),(1,0,5,16,'Person','strCustomStr8','ReadOnly',0),(1,0,5,16,'PersonChild','strCustomStr8','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strCustomStr8','ChildDefine',0),(1,0,5,16,'Person','strCustomStr9','ReadOnly',0),(1,0,5,16,'PersonChild','strCustomStr9','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strCustomStr9','ChildDefine',0),(1,0,5,16,'Person','strCustomStr10','ReadOnly',0),(1,0,5,16,'PersonChild','strCustomStr10','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strCustomStr10','ChildDefine',0),(1,0,5,16,'Person','strCustomStr11','ChildDefine',0),(1,0,5,16,'PersonChild','strCustomStr11','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strCustomStr11','ChildDefine',0),(1,0,5,16,'Person','strCustomStr12','ChildDefine',0),(1,0,5,16,'PersonChild','strCustomStr12','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strCustomStr12','ChildDefine',0),(1,0,5,16,'Person','strCustomStr13','ChildDefine',0),(1,0,5,16,'PersonChild','strCustomStr13','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strCustomStr13','ChildDefine',0),(1,0,5,16,'Person','strCustomStr14','ChildDefine',0),(1,0,5,16,'PersonChild','strCustomStr14','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strCustomStr14','ChildDefine',0),(1,0,5,16,'Person','strCustomStr15','ChildDefine',0),(1,0,5,16,'PersonChild','strCustomStr15','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strCustomStr15','ChildDefine',0),(1,0,5,16,'Person','strCustomStr16','ChildDefine',0),(1,0,5,16,'PersonChild','strCustomStr16','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strCustomStr16','ChildDefine',0),(1,0,5,16,'Person','strCustomStr17','ChildDefine',0),(1,0,5,16,'PersonChild','strCustomStr17','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strCustomStr17','ChildDefine',0),(1,0,5,16,'Person','strCustomStr18','ChildDefine',0),(1,0,5,16,'PersonChild','strCustomStr18','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strCustomStr18','ChildDefine',0),(1,0,5,16,'Person','strCustomStr19','ChildDefine',0),(1,0,5,16,'PersonChild','strCustomStr19','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strCustomStr19','ChildDefine',0),(1,0,5,16,'Person','strCustomStr20','ChildDefine',0),(1,0,5,16,'PersonChild','strCustomStr20','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strCustomStr20','ChildDefine',0),(1,0,5,16,'Person','strCustomStr21','ChildDefine',0),(1,0,5,16,'PersonChild','strCustomStr21','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strCustomStr21','ChildDefine',0),(1,0,5,16,'Person','strCustomStr22','ChildDefine',0),(1,0,5,16,'PersonChild','strCustomStr22','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strCustomStr22','ChildDefine',0),(1,0,5,16,'Person','strCustomStr23','ChildDefine',0),(1,0,5,16,'PersonChild','strCustomStr23','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strCustomStr23','ChildDefine',0),(1,0,5,16,'Person','strCustomStr24','ChildDefine',0),(1,0,5,16,'PersonChild','strCustomStr24','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strCustomStr24','ChildDefine',0),(1,0,5,16,'Person','strCustomStr25','ChildDefine',0),(1,0,5,16,'PersonChild','strCustomStr25','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strCustomStr25','ChildDefine',0),(1,0,5,16,'Person','dblCustomDbl1','ChildDefine',0),(1,0,5,16,'PersonChild','dblCustomDbl1','ChildDefine',0),(1,0,5,16,'PersonRegoForm','dblCustomDbl1','ChildDefine',0),(1,0,5,16,'Person','dblCustomDbl2','ChildDefine',0),(1,0,5,16,'PersonChild','dblCustomDbl2','ChildDefine',0),(1,0,5,16,'PersonRegoForm','dblCustomDbl2','ChildDefine',0),(1,0,5,16,'Person','dblCustomDbl3','ChildDefine',0),(1,0,5,16,'PersonChild','dblCustomDbl3','ChildDefine',0),(1,0,5,16,'PersonRegoForm','dblCustomDbl3','ChildDefine',0),(1,0,5,16,'Person','dblCustomDbl4','ChildDefine',0),(1,0,5,16,'PersonChild','dblCustomDbl4','ChildDefine',0),(1,0,5,16,'PersonRegoForm','dblCustomDbl4','ChildDefine',0),(1,0,5,16,'Person','dblCustomDbl5','ChildDefine',0),(1,0,5,16,'PersonChild','dblCustomDbl5','ChildDefine',0),(1,0,5,16,'PersonRegoForm','dblCustomDbl5','ChildDefine',0),(1,0,5,16,'Person','dblCustomDbl6','ChildDefine',0),(1,0,5,16,'PersonChild','dblCustomDbl6','ChildDefine',0),(1,0,5,16,'PersonRegoForm','dblCustomDbl6','ChildDefine',0),(1,0,5,16,'Person','dblCustomDbl7','ChildDefine',0),(1,0,5,16,'PersonChild','dblCustomDbl7','ChildDefine',0),(1,0,5,16,'PersonRegoForm','dblCustomDbl7','ChildDefine',0),(1,0,5,16,'Person','dblCustomDbl8','ChildDefine',0),(1,0,5,16,'PersonChild','dblCustomDbl8','ChildDefine',0),(1,0,5,16,'PersonRegoForm','dblCustomDbl8','ChildDefine',0),(1,0,5,16,'Person','dblCustomDbl9','ChildDefine',0),(1,0,5,16,'PersonChild','dblCustomDbl9','ChildDefine',0),(1,0,5,16,'PersonRegoForm','dblCustomDbl9','ChildDefine',0),(1,0,5,16,'Person','dblCustomDbl10','ChildDefine',0),(1,0,5,16,'PersonChild','dblCustomDbl10','ChildDefine',0),(1,0,5,16,'PersonRegoForm','dblCustomDbl10','ChildDefine',0),(1,0,5,16,'Person','dblCustomDbl11','ChildDefine',0),(1,0,5,16,'PersonChild','dblCustomDbl11','ChildDefine',0),(1,0,5,16,'PersonRegoForm','dblCustomDbl11','ChildDefine',0),(1,0,5,16,'Person','dblCustomDbl12','ChildDefine',0),(1,0,5,16,'PersonChild','dblCustomDbl12','ChildDefine',0),(1,0,5,16,'PersonRegoForm','dblCustomDbl12','ChildDefine',0),(1,0,5,16,'Person','dblCustomDbl13','ChildDefine',0),(1,0,5,16,'PersonChild','dblCustomDbl13','ChildDefine',0),(1,0,5,16,'PersonRegoForm','dblCustomDbl13','ChildDefine',0),(1,0,5,16,'Person','dblCustomDbl14','ChildDefine',0),(1,0,5,16,'PersonChild','dblCustomDbl14','ChildDefine',0),(1,0,5,16,'PersonRegoForm','dblCustomDbl14','ChildDefine',0),(1,0,5,16,'Person','dblCustomDbl15','ChildDefine',0),(1,0,5,16,'PersonChild','dblCustomDbl15','ChildDefine',0),(1,0,5,16,'PersonRegoForm','dblCustomDbl15','ChildDefine',0),(1,0,5,16,'Person','dblCustomDbl16','ChildDefine',0),(1,0,5,16,'PersonChild','dblCustomDbl16','ChildDefine',0),(1,0,5,16,'PersonRegoForm','dblCustomDbl16','ChildDefine',0),(1,0,5,16,'Person','dblCustomDbl17','ChildDefine',0),(1,0,5,16,'PersonChild','dblCustomDbl17','ChildDefine',0),(1,0,5,16,'PersonRegoForm','dblCustomDbl17','ChildDefine',0),(1,0,5,16,'Person','dblCustomDbl18','ChildDefine',0),(1,0,5,16,'PersonChild','dblCustomDbl18','ChildDefine',0),(1,0,5,16,'PersonRegoForm','dblCustomDbl18','ChildDefine',0),(1,0,5,16,'Person','dblCustomDbl19','ChildDefine',0),(1,0,5,16,'PersonChild','dblCustomDbl19','ChildDefine',0),(1,0,5,16,'PersonRegoForm','dblCustomDbl19','ChildDefine',0),(1,0,5,16,'Person','dblCustomDbl20','ChildDefine',0),(1,0,5,16,'PersonChild','dblCustomDbl20','ChildDefine',0),(1,0,5,16,'PersonRegoForm','dblCustomDbl20','ChildDefine',0),(1,0,5,16,'Person','dtCustomDt1','ChildDefine',0),(1,0,5,16,'PersonChild','dtCustomDt1','ChildDefine',0),(1,0,5,16,'PersonRegoForm','dtCustomDt1','ChildDefine',0),(1,0,5,16,'Person','dtCustomDt2','ChildDefine',0),(1,0,5,16,'PersonChild','dtCustomDt2','ChildDefine',0),(1,0,5,16,'PersonRegoForm','dtCustomDt2','ChildDefine',0),(1,0,5,16,'Person','dtCustomDt3','ChildDefine',0),(1,0,5,16,'PersonChild','dtCustomDt3','ChildDefine',0),(1,0,5,16,'PersonRegoForm','dtCustomDt3','ChildDefine',0),(1,0,5,16,'Person','dtCustomDt4','ChildDefine',0),(1,0,5,16,'PersonChild','dtCustomDt4','ChildDefine',0),(1,0,5,16,'PersonRegoForm','dtCustomDt4','ChildDefine',0),(1,0,5,16,'Person','dtCustomDt5','ChildDefine',0),(1,0,5,16,'PersonChild','dtCustomDt5','ChildDefine',0),(1,0,5,16,'PersonRegoForm','dtCustomDt5','ChildDefine',0),(1,0,5,16,'Person','dtCustomDt6','ChildDefine',0),(1,0,5,16,'PersonChild','dtCustomDt6','ChildDefine',0),(1,0,5,16,'PersonRegoForm','dtCustomDt6','ChildDefine',0),(1,0,5,16,'Person','dtCustomDt7','ChildDefine',0),(1,0,5,16,'PersonChild','dtCustomDt7','ChildDefine',0),(1,0,5,16,'PersonRegoForm','dtCustomDt7','ChildDefine',0),(1,0,5,16,'Person','dtCustomDt8','ChildDefine',0),(1,0,5,16,'PersonChild','dtCustomDt8','ChildDefine',0),(1,0,5,16,'PersonRegoForm','dtCustomDt8','ChildDefine',0),(1,0,5,16,'Person','dtCustomDt9','ChildDefine',0),(1,0,5,16,'PersonChild','dtCustomDt9','ChildDefine',0),(1,0,5,16,'PersonRegoForm','dtCustomDt9','ChildDefine',0),(1,0,5,16,'Person','dtCustomDt10','ChildDefine',0),(1,0,5,16,'PersonChild','dtCustomDt10','ChildDefine',0),(1,0,5,16,'PersonRegoForm','dtCustomDt10','ChildDefine',0),(1,0,5,16,'Person','dtCustomDt11','ChildDefine',0),(1,0,5,16,'PersonChild','dtCustomDt11','ChildDefine',0),(1,0,5,16,'PersonRegoForm','dtCustomDt11','ChildDefine',0),(1,0,5,16,'Person','dtCustomDt12','ChildDefine',0),(1,0,5,16,'PersonChild','dtCustomDt12','ChildDefine',0),(1,0,5,16,'PersonRegoForm','dtCustomDt12','ChildDefine',0),(1,0,5,16,'Person','dtCustomDt13','ChildDefine',0),(1,0,5,16,'PersonChild','dtCustomDt13','ChildDefine',0),(1,0,5,16,'PersonRegoForm','dtCustomDt13','ChildDefine',0),(1,0,5,16,'Person','dtCustomDt14','ChildDefine',0),(1,0,5,16,'PersonChild','dtCustomDt14','ChildDefine',0),(1,0,5,16,'PersonRegoForm','dtCustomDt14','ChildDefine',0),(1,0,5,16,'Person','dtCustomDt15','ChildDefine',0),(1,0,5,16,'PersonChild','dtCustomDt15','ChildDefine',0),(1,0,5,16,'PersonRegoForm','dtCustomDt15','ChildDefine',0),(1,0,5,16,'Person','intCustomLU5','ChildDefine',0),(1,0,5,16,'PersonChild','intCustomLU5','ChildDefine',0),(1,0,5,16,'PersonRegoForm','intCustomLU5','ChildDefine',0),(1,0,5,16,'Person','intCustomLU6','ChildDefine',0),(1,0,5,16,'PersonChild','intCustomLU6','ChildDefine',0),(1,0,5,16,'PersonRegoForm','intCustomLU6','ChildDefine',0),(1,0,5,16,'Person','intCustomLU7','ChildDefine',0),(1,0,5,16,'PersonChild','intCustomLU7','ChildDefine',0),(1,0,5,16,'PersonRegoForm','intCustomLU7','ChildDefine',0),(1,0,5,16,'Person','intCustomLU8','ChildDefine',0),(1,0,5,16,'PersonChild','intCustomLU8','ChildDefine',0),(1,0,5,16,'PersonRegoForm','intCustomLU8','ChildDefine',0),(1,0,5,16,'Person','intCustomLU9','ChildDefine',0),(1,0,5,16,'PersonChild','intCustomLU9','ChildDefine',0),(1,0,5,16,'PersonRegoForm','intCustomLU9','ChildDefine',0),(1,0,5,16,'Person','intCustomLU10','ChildDefine',0),(1,0,5,16,'PersonChild','intCustomLU10','ChildDefine',0),(1,0,5,16,'PersonRegoForm','intCustomLU10','ChildDefine',0),(1,0,5,16,'Person','intCustomLU11','ChildDefine',0),(1,0,5,16,'PersonChild','intCustomLU11','ChildDefine',0),(1,0,5,16,'PersonRegoForm','intCustomLU11','ChildDefine',0),(1,0,5,16,'Person','intCustomLU12','ChildDefine',0),(1,0,5,16,'PersonChild','intCustomLU12','ChildDefine',0),(1,0,5,16,'PersonRegoForm','intCustomLU12','ChildDefine',0),(1,0,5,16,'Person','intCustomLU13','ChildDefine',0),(1,0,5,16,'PersonChild','intCustomLU13','ChildDefine',0),(1,0,5,16,'PersonRegoForm','intCustomLU13','ChildDefine',0),(1,0,5,16,'Person','intCustomLU14','ChildDefine',0),(1,0,5,16,'PersonChild','intCustomLU14','ChildDefine',0),(1,0,5,16,'PersonRegoForm','intCustomLU14','ChildDefine',0),(1,0,5,16,'Person','intCustomLU15','ChildDefine',0),(1,0,5,16,'PersonChild','intCustomLU15','ChildDefine',0),(1,0,5,16,'PersonRegoForm','intCustomLU15','ChildDefine',0),(1,0,5,16,'Person','intCustomLU16','ChildDefine',0),(1,0,5,16,'PersonChild','intCustomLU16','ChildDefine',0),(1,0,5,16,'PersonRegoForm','intCustomLU16','ChildDefine',0),(1,0,5,16,'Person','intCustomLU17','ChildDefine',0),(1,0,5,16,'PersonChild','intCustomLU17','ChildDefine',0),(1,0,5,16,'PersonRegoForm','intCustomLU17','ChildDefine',0),(1,0,5,16,'Person','intCustomLU18','ChildDefine',0),(1,0,5,16,'PersonChild','intCustomLU18','ChildDefine',0),(1,0,5,16,'PersonRegoForm','intCustomLU18','ChildDefine',0),(1,0,5,16,'Person','intCustomLU19','ChildDefine',0),(1,0,5,16,'PersonChild','intCustomLU19','ChildDefine',0),(1,0,5,16,'PersonRegoForm','intCustomLU19','ChildDefine',0),(1,0,5,16,'Person','intCustomLU20','ChildDefine',0),(1,0,5,16,'PersonChild','intCustomLU20','ChildDefine',0),(1,0,5,16,'PersonRegoForm','intCustomLU20','ChildDefine',0),(1,0,5,16,'Person','intCustomLU21','ChildDefine',0),(1,0,5,16,'PersonChild','intCustomLU21','ChildDefine',0),(1,0,5,16,'PersonRegoForm','intCustomLU21','ChildDefine',0),(1,0,5,16,'Person','intCustomLU22','ChildDefine',0),(1,0,5,16,'PersonChild','intCustomLU22','ChildDefine',0),(1,0,5,16,'PersonRegoForm','intCustomLU22','ChildDefine',0),(1,0,5,16,'Person','intCustomLU23','ChildDefine',0),(1,0,5,16,'PersonChild','intCustomLU23','ChildDefine',0),(1,0,5,16,'PersonRegoForm','intCustomLU23','ChildDefine',0),(1,0,5,16,'Person','intCustomLU24','ChildDefine',0),(1,0,5,16,'PersonChild','intCustomLU24','ChildDefine',0),(1,0,5,16,'PersonRegoForm','intCustomLU24','ChildDefine',0),(1,0,5,16,'Person','intCustomLU25','ChildDefine',0),(1,0,5,16,'PersonChild','intCustomLU25','ChildDefine',0),(1,0,5,16,'PersonRegoForm','intCustomLU25','ChildDefine',0),(1,0,5,16,'Person','intCustomBool1','ChildDefine',0),(1,0,5,16,'PersonChild','intCustomBool1','ChildDefine',0),(1,0,5,16,'PersonRegoForm','intCustomBool1','ChildDefine',0),(1,0,5,16,'Person','intCustomBool2','ChildDefine',0),(1,0,5,16,'PersonChild','intCustomBool2','ChildDefine',0),(1,0,5,16,'PersonRegoForm','intCustomBool2','ChildDefine',0),(1,0,5,16,'Person','intCustomBool3','ChildDefine',0),(1,0,5,16,'PersonChild','intCustomBool3','ChildDefine',0),(1,0,5,16,'PersonRegoForm','intCustomBool3','ChildDefine',0),(1,0,5,16,'Person','intCustomBool4','ChildDefine',0),(1,0,5,16,'PersonChild','intCustomBool4','ChildDefine',0),(1,0,5,16,'PersonRegoForm','intCustomBool4','ChildDefine',0),(1,0,5,16,'Person','intCustomBool5','ChildDefine',0),(1,0,5,16,'PersonChild','intCustomBool5','ChildDefine',0),(1,0,5,16,'PersonRegoForm','intCustomBool5','ChildDefine',0),(1,0,5,16,'Person','intCustomBool6','ChildDefine',0),(1,0,5,16,'PersonChild','intCustomBool6','ChildDefine',0),(1,0,5,16,'PersonRegoForm','intCustomBool6','ChildDefine',0),(1,0,5,16,'Person','intCustomBool7','ChildDefine',0),(1,0,5,16,'PersonChild','intCustomBool7','ChildDefine',0),(1,0,5,16,'PersonRegoForm','intCustomBool7','ChildDefine',0),(1,0,5,16,'Person','intFavStateTeamID','ChildDefine',0),(1,0,5,16,'PersonChild','intFavStateTeamID','ChildDefine',0),(1,0,5,16,'PersonRegoForm','intFavStateTeamID','ChildDefine',0),(1,0,5,16,'Person','intFavNationalTeamID','ChildDefine',0),(1,0,5,16,'PersonChild','intFavNationalTeamID','ChildDefine',0),(1,0,5,16,'PersonRegoForm','intFavNationalTeamID','ChildDefine',0),(1,0,5,16,'Person','intFavNationalTeamMember','ChildDefine',0),(1,0,5,16,'PersonChild','intFavNationalTeamMember','ChildDefine',0),(1,0,5,16,'PersonRegoForm','intFavNationalTeamMember','ChildDefine',0),(1,0,5,16,'Person','intAttendSportCount','ChildDefine',0),(1,0,5,16,'PersonChild','intAttendSportCount','ChildDefine',0),(1,0,5,16,'PersonRegoForm','intAttendSportCount','ChildDefine',0),(1,0,5,16,'Person','intWatchSportHowOftenID','ChildDefine',0),(1,0,5,16,'PersonChild','intWatchSportHowOftenID','ChildDefine',0),(1,0,5,16,'PersonRegoForm','intWatchSportHowOftenID','ChildDefine',0),(1,0,5,16,'Person','strNotes','ChildDefine',0),(1,0,5,16,'PersonChild','strNotes','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strNotes','ChildDefine',0),(1,0,5,16,'Person','strMemberCustomNotes1','ChildDefine',0),(1,0,5,16,'PersonChild','strMemberCustomNotes1','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strMemberCustomNotes1','ChildDefine',0),(1,0,5,16,'Person','strMemberCustomNotes2','ChildDefine',0),(1,0,5,16,'PersonChild','strMemberCustomNotes2','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strMemberCustomNotes2','ChildDefine',0),(1,0,5,16,'Person','strMemberCustomNotes3','ChildDefine',0),(1,0,5,16,'PersonChild','strMemberCustomNotes3','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strMemberCustomNotes3','ChildDefine',0),(1,0,5,16,'Person','strMemberCustomNotes4','ChildDefine',0),(1,0,5,16,'PersonChild','strMemberCustomNotes4','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strMemberCustomNotes4','ChildDefine',0),(1,0,5,16,'Person','strMemberCustomNotes5','ChildDefine',0),(1,0,5,16,'PersonChild','strMemberCustomNotes5','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strMemberCustomNotes5','ChildDefine',0),(1,0,5,16,'Person','dtFirstRegistered','ReadOnly',0),(1,0,5,16,'PersonChild','dtFirstRegistered','ReadOnly',0),(1,0,5,16,'Person','strP2PhoneMobile','ChildDefine',0),(1,0,5,16,'PersonChild','strP2PhoneMobile','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strP2PhoneMobile','ChildDefine',0),(1,0,5,16,'PersonChild','strP2SName','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strP2SName','ChildDefine',0),(1,0,5,16,'Person','strP2Phone','ChildDefine',0),(1,0,5,16,'PersonChild','strP2Phone','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strP2Phone','ChildDefine',0),(1,0,5,16,'Person','strP2Phone2','ChildDefine',0),(1,0,5,16,'PersonChild','strP2Phone2','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strP2Phone2','ChildDefine',0),(1,0,5,16,'PersonRegoForm','intOfficial','ChildDefine',0),(1,0,5,16,'Person','intMisc','ChildDefine',0),(1,0,5,16,'PersonChild','intMisc','ChildDefine',0),(1,0,5,16,'PersonRegoForm','intMisc','ChildDefine',0),(1,0,5,16,'Person','intVolunteer','ChildDefine',0),(1,0,5,16,'PersonChild','intVolunteer','ChildDefine',0),(1,0,5,16,'PersonRegoForm','intVolunteer','ChildDefine',0),(1,0,5,16,'Person','intPlayerPending','Editable',0),(1,0,5,16,'PersonChild','intPlayerPending','Editable',0),(1,0,5,16,'PersonRegoForm','intPlayerPending','ChildDefine',0),(1,0,5,16,'Person','strPreferredLang','ChildDefine',0),(1,0,5,16,'PersonChild','strPreferredLang','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strPreferredLang','ChildDefine',0),(1,0,5,16,'Person','strPassportNationality','Compulsory',0),(1,0,5,16,'PersonChild','strPassportNationality','Compulsory',0),(1,0,5,16,'PersonRegoForm','strPassportNationality','Compulsory',0),(1,0,100,1,'PersonChild','intNatCustomLU4','ChildDefine',0),(1,0,100,1,'PersonRegoForm','strOtherPersonIdentifier','Compulsory',0),(1,0,5,16,'Person','strPassportIssueCountry','ChildDefine',0),(1,0,5,16,'PersonChild','strPassportIssueCountry','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strPassportIssueCountry','ChildDefine',0),(1,0,5,16,'Person','dtPassportExpiry','Editable',0),(1,0,5,16,'PersonChild','dtPassportExpiry','Editable',0),(1,0,5,16,'PersonRegoForm','dtPassportExpiry','ChildDefine',0),(1,0,5,16,'Person','strBirthCertNo','ChildDefine',0),(1,0,5,16,'PersonChild','strBirthCertNo','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strBirthCertNo','ChildDefine',0),(1,0,5,16,'Person','strHealthCareNo','ChildDefine',0),(1,0,5,16,'PersonChild','strHealthCareNo','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strHealthCareNo','ChildDefine',0),(1,0,5,16,'Person','intIdentTypeID','ChildDefine',0),(1,0,5,16,'PersonChild','intIdentTypeID','ChildDefine',0),(1,0,5,16,'PersonRegoForm','intIdentTypeID','ChildDefine',0),(1,0,5,16,'Person','strIdentNum','ChildDefine',0),(1,0,5,16,'PersonChild','strIdentNum','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strIdentNum','ChildDefine',0),(1,0,5,16,'Person','dtPoliceCheck','ChildDefine',0),(1,0,5,16,'PersonChild','dtPoliceCheck','ChildDefine',0),(1,0,5,16,'PersonRegoForm','dtPoliceCheck','ChildDefine',0),(1,0,5,16,'Person','dtPoliceCheckExp','ChildDefine',0),(1,0,5,16,'PersonChild','dtPoliceCheckExp','ChildDefine',0),(1,0,5,16,'PersonRegoForm','dtPoliceCheckExp','ChildDefine',0),(1,0,5,16,'Person','strPoliceCheckRef','ChildDefine',0),(1,0,5,16,'PersonChild','strPoliceCheckRef','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strPoliceCheckRef','ChildDefine',0),(1,0,5,16,'Person','intP1Gender','ChildDefine',0),(1,0,5,16,'PersonChild','intP1Gender','ChildDefine',0),(1,0,5,16,'PersonRegoForm','intP1Gender','ChildDefine',0),(1,0,5,16,'Person','strP1Salutation','ChildDefine',0),(1,0,5,16,'PersonChild','strP1Salutation','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strP1Salutation','ChildDefine',0),(1,0,5,16,'Person','strP1FName','ChildDefine',0),(1,0,5,16,'PersonChild','strP1FName','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strP1FName','ChildDefine',0),(1,0,5,16,'Person','strP1SName','ChildDefine',0),(1,0,5,16,'PersonChild','strP1SName','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strP1SName','ChildDefine',0),(1,0,5,16,'Person','strP1Phone','ChildDefine',0),(1,0,5,16,'PersonChild','strP1Phone','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strP1Phone','ChildDefine',0),(1,0,5,16,'Person','strP1Phone2','ChildDefine',0),(1,0,5,16,'PersonChild','strP1Phone2','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strP1Phone2','ChildDefine',0),(1,0,5,16,'Person','strP1PhoneMobile','ChildDefine',0),(1,0,5,16,'PersonChild','strP1PhoneMobile','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strP1PhoneMobile','ChildDefine',0),(1,0,5,16,'Person','strP1Email','ChildDefine',0),(1,0,5,16,'PersonChild','strP1Email','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strP1Email','ChildDefine',0),(1,0,5,16,'Person','strP1Email2','ChildDefine',0),(1,0,5,16,'PersonChild','strP1Email2','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strP1Email2','ChildDefine',0),(1,0,5,16,'Person','intP1AssistAreaID','ChildDefine',0),(1,0,5,16,'PersonChild','intP1AssistAreaID','ChildDefine',0),(1,0,5,16,'PersonRegoForm','intP1AssistAreaID','ChildDefine',0),(1,0,5,16,'Person','intP2Gender','ChildDefine',0),(1,0,5,16,'PersonChild','intP2Gender','ChildDefine',0),(1,0,5,16,'PersonRegoForm','intP2Gender','ChildDefine',0),(1,0,5,16,'Person','strP2Salutation','ChildDefine',0),(1,0,5,16,'PersonChild','strP2Salutation','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strP2Salutation','ChildDefine',0),(1,0,5,16,'Person','strP2FName','ChildDefine',0),(1,0,5,16,'PersonChild','strP2FName','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strP2FName','ChildDefine',0),(1,0,5,16,'Person','strP2SName','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strFax','ChildDefine',0),(1,0,5,16,'Person','strEmail','ChildDefine',0),(1,0,5,16,'PersonChild','strEmail','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strEmail','ChildDefine',0),(1,0,5,16,'Person','strEmail2','ChildDefine',0),(1,0,5,16,'PersonChild','strEmail2','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strEmail2','ChildDefine',0),(1,0,5,16,'Person','strEmergContName','ChildDefine',0),(1,0,5,16,'PersonChild','strEmergContName','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strEmergContName','ChildDefine',0),(1,0,5,16,'Person','strEmergContNo','ChildDefine',0),(1,0,5,16,'PersonChild','strEmergContNo','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strEmergContNo','ChildDefine',0),(1,0,5,16,'Person','strEmergContNo2','ChildDefine',0),(1,0,5,16,'PersonChild','strEmergContNo2','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strEmergContNo2','ChildDefine',0),(1,0,5,16,'Person','strEmergContRel','ChildDefine',0),(1,0,5,16,'PersonChild','strEmergContRel','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strEmergContRel','ChildDefine',0),(1,0,5,16,'Person','intPlayer','Editable',0),(1,0,5,16,'PersonChild','intPlayer','Editable',0),(1,0,5,16,'PersonRegoForm','intPlayer','ChildDefine',0),(1,0,5,16,'Person','intCoach','Editable',0),(1,0,5,16,'PersonChild','intCoach','Editable',0),(1,0,5,16,'PersonRegoForm','intCoach','ChildDefine',0),(1,0,5,16,'Person','intUmpire','Editable',0),(1,0,5,16,'PersonChild','intUmpire','Editable',0),(1,0,5,16,'PersonRegoForm','intUmpire','ChildDefine',0),(1,0,5,16,'Person','intOfficial','ChildDefine',0),(1,0,5,16,'PersonChild','intOfficial','ChildDefine',0),(1,0,5,16,'PersonChild','intGender','Compulsory',0),(1,0,5,16,'PersonRegoForm','intGender','Compulsory',0),(1,0,5,16,'Person','intDeceased','ChildDefine',0),(1,0,5,16,'PersonChild','intDeceased','ChildDefine',0),(1,0,5,16,'PersonRegoForm','intDeceased','ChildDefine',0),(1,0,5,16,'Person','strEyeColour','ChildDefine',0),(1,0,5,16,'PersonChild','strEyeColour','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strEyeColour','ChildDefine',0),(1,0,5,16,'Person','strHairColour','ChildDefine',0),(1,0,5,16,'PersonChild','strHairColour','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strHairColour','ChildDefine',0),(1,0,5,16,'Person','intEthnicityID','ChildDefine',0),(1,0,5,16,'PersonChild','intEthnicityID','ChildDefine',0),(1,0,5,16,'PersonRegoForm','intEthnicityID','ChildDefine',0),(1,0,5,16,'Person','strHeight','ChildDefine',0),(1,0,5,16,'PersonChild','strHeight','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strHeight','ChildDefine',0),(1,0,5,16,'Person','strWeight','ChildDefine',0),(1,0,5,16,'PersonChild','strWeight','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strWeight','ChildDefine',0),(1,0,5,16,'Person','strAddress1','Editable',0),(1,0,5,16,'PersonChild','strAddress1','Editable',0),(1,0,5,16,'PersonRegoForm','strAddress1','Editable',0),(1,0,5,16,'Person','strAddress2','ChildDefine',0),(1,0,5,16,'PersonChild','strAddress2','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strAddress2','ChildDefine',0),(1,0,5,16,'Person','strSuburb','Editable',0),(1,0,5,16,'PersonChild','strSuburb','Editable',0),(1,0,5,16,'PersonRegoForm','strSuburb','Editable',0),(1,0,5,16,'Person','strCityOfResidence','ChildDefine',0),(1,0,5,16,'PersonChild','strCityOfResidence','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strCityOfResidence','ChildDefine',0),(1,0,5,16,'Person','strState','ChildDefine',0),(1,0,5,16,'PersonChild','strState','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strState','ChildDefine',0),(1,0,5,16,'Person','strCountry','Editable',0),(1,0,5,16,'PersonChild','strCountry','Editable',0),(1,0,5,16,'PersonRegoForm','strCountry','ChildDefine',0),(1,0,5,16,'Person','strPostalCode','ChildDefine',0),(1,0,5,16,'PersonChild','strPostalCode','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strPostalCode','ChildDefine',0),(1,0,5,16,'Person','strPhoneHome','ChildDefine',0),(1,0,5,16,'PersonChild','strPhoneHome','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strPhoneHome','ChildDefine',0),(1,0,5,16,'Person','strPhoneWork','ChildDefine',0),(1,0,5,16,'PersonChild','strPhoneWork','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strPhoneWork','ChildDefine',0),(1,0,5,16,'Person','strPhoneMobile','ChildDefine',0),(1,0,5,16,'PersonChild','strPhoneMobile','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strPhoneMobile','ChildDefine',0),(1,0,5,16,'Person','strFax','ChildDefine',0),(1,0,5,16,'PersonChild','strFax','ChildDefine',0),(1,0,5,16,'PersonChild','strNationalNum','ReadOnly',0),(1,0,5,16,'PersonRegoForm','strNationalNum','ChildDefine',0),(1,0,5,16,'Person','strMemberNo','ReadOnly',0),(1,0,5,16,'PersonChild','strMemberNo','ReadOnly',0),(1,0,5,16,'PersonRegoForm','strMemberNo','ChildDefine',0),(1,0,5,16,'Person','intRecStatus','Editable',0),(1,0,5,16,'PersonChild','intRecStatus','Editable',0),(1,0,5,16,'PersonRegoForm','intRecStatus','ChildDefine',0),(1,0,5,16,'Person','strSalutation','ChildDefine',0),(1,0,5,16,'PersonChild','strSalutation','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strSalutation','ChildDefine',0),(1,0,5,16,'Person','strFirstname','Compulsory',0),(1,0,5,16,'PersonChild','strFirstname','Compulsory',0),(1,0,5,16,'PersonRegoForm','strFirstname','Compulsory',0),(1,0,5,16,'Person','strMiddlename','ChildDefine',0),(1,0,5,16,'PersonChild','strMiddlename','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strMiddlename','ChildDefine',0),(1,0,5,16,'Person','strSurname','Compulsory',0),(1,0,5,16,'PersonChild','strSurname','Compulsory',0),(1,0,5,16,'PersonRegoForm','strSurname','Compulsory',0),(1,0,5,16,'Person','strMaidenName','ChildDefine',0),(1,0,5,16,'PersonChild','strMaidenName','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strMaidenName','ChildDefine',0),(1,0,5,16,'Person','strMotherCountry','ChildDefine',0),(1,0,5,16,'PersonChild','strMotherCountry','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strMotherCountry','ChildDefine',0),(1,0,5,16,'Person','strFatherCountry','ChildDefine',0),(1,0,5,16,'PersonChild','strFatherCountry','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strFatherCountry','ChildDefine',0),(1,0,5,16,'Person','strPreferredName','ChildDefine',0),(1,0,5,16,'PersonChild','strPreferredName','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strPreferredName','ChildDefine',0),(1,0,5,16,'Person','dtDOB','Compulsory',0),(1,0,5,16,'PersonChild','dtDOB','Compulsory',0),(1,0,5,16,'PersonRegoForm','dtDOB','Compulsory',0),(1,0,5,16,'Person','strPlaceofBirth','ChildDefine',0),(1,0,5,16,'PersonChild','strPlaceofBirth','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strPlaceofBirth','ChildDefine',0),(1,0,5,16,'Person','strCountryOfBirth','Editable',0),(1,0,5,16,'PersonChild','strCountryOfBirth','Editable',0),(1,0,5,16,'PersonRegoForm','strCountryOfBirth','ChildDefine',0),(1,0,5,16,'Person','intGender','Compulsory',0),(1,0,5,16,'Person','strNationalNum','ReadOnly',0),(1,0,5,16,'Club','intClubCustomBool5','ChildDefine',0),(1,0,5,16,'ClubChild','dtClubCustomDt4','ChildDefine',0),(1,0,5,16,'Club','dtClubCustomDt5','ChildDefine',0),(1,0,5,16,'ClubChild','dtClubCustomDt5','ChildDefine',0),(1,0,5,16,'Club','intClubCustomLU1','ChildDefine',0),(1,0,5,16,'ClubChild','intClubCustomLU1','ChildDefine',0),(1,0,5,16,'Club','intClubCustomLU2','ChildDefine',0),(1,0,5,16,'ClubChild','intClubCustomLU2','ChildDefine',0),(1,0,5,16,'Club','intClubCustomLU3','ChildDefine',0),(1,0,5,16,'ClubChild','intClubCustomLU3','ChildDefine',0),(1,0,5,16,'Club','intClubCustomLU4','ChildDefine',0),(1,0,5,16,'ClubChild','intClubCustomLU4','ChildDefine',0),(1,0,5,16,'Club','intClubCustomLU5','ChildDefine',0),(1,0,5,16,'ClubChild','intClubCustomLU5','ChildDefine',0),(1,0,5,16,'Club','intClubCustomLU6','ChildDefine',0),(1,0,5,16,'ClubChild','intClubCustomLU6','ChildDefine',0),(1,0,5,16,'Club','intClubCustomLU7','ChildDefine',0),(1,0,5,16,'ClubChild','intClubCustomLU7','ChildDefine',0),(1,0,5,16,'Club','intClubCustomLU8','ChildDefine',0),(1,0,5,16,'ClubChild','intClubCustomLU8','ChildDefine',0),(1,0,5,16,'Club','intClubCustomLU9','ChildDefine',0),(1,0,5,16,'ClubChild','intClubCustomLU9','ChildDefine',0),(1,0,5,16,'Club','intClubCustomLU10','ChildDefine',0),(1,0,5,16,'ClubChild','intClubCustomLU10','ChildDefine',0),(1,0,5,16,'Club','intClubCustomBool1','ChildDefine',0),(1,0,5,16,'ClubChild','intClubCustomBool1','ChildDefine',0),(1,0,5,16,'Club','intClubCustomBool2','ChildDefine',0),(1,0,5,16,'ClubChild','intClubCustomBool2','ChildDefine',0),(1,0,5,16,'Club','intClubCustomBool3','ChildDefine',0),(1,0,5,16,'ClubChild','intClubCustomBool3','ChildDefine',0),(1,0,5,16,'Club','intClubCustomBool4','ChildDefine',0),(1,0,5,16,'ClubChild','intClubCustomBool4','ChildDefine',0),(1,0,5,16,'ClubChild','dtClubCustomDt3','ChildDefine',0),(1,0,5,16,'Club','dtClubCustomDt4','ChildDefine',0),(1,0,5,16,'ClubChild','dtClubCustomDt2','ChildDefine',0),(1,0,5,16,'Club','dtClubCustomDt3','ChildDefine',0),(1,0,5,16,'ClubChild','dtClubCustomDt1','ChildDefine',0),(1,0,5,16,'Club','dtClubCustomDt2','ChildDefine',0),(1,0,5,16,'ClubChild','dblClubCustomDbl10','ChildDefine',0),(1,0,5,16,'Club','dtClubCustomDt1','ChildDefine',0),(1,0,5,16,'Club','dblClubCustomDbl10','ChildDefine',0),(1,0,5,16,'Club','dblClubCustomDbl9','ChildDefine',0),(1,0,5,16,'ClubChild','dblClubCustomDbl9','ChildDefine',0),(1,0,5,16,'Club','dblClubCustomDbl8','ChildDefine',0),(1,0,5,16,'ClubChild','dblClubCustomDbl8','ChildDefine',0),(1,0,5,16,'Club','dblClubCustomDbl7','ChildDefine',0),(1,0,5,16,'ClubChild','dblClubCustomDbl7','ChildDefine',0),(1,0,5,16,'Club','strClubCustomStr15','ChildDefine',0),(1,0,5,16,'ClubChild','strClubCustomStr15','ChildDefine',0),(1,0,5,16,'Club','strClubCustomStr14','ChildDefine',0),(1,0,5,16,'ClubChild','strClubCustomStr14','ChildDefine',0),(1,0,5,16,'Club','strClubCustomStr13','ChildDefine',0),(1,0,5,16,'ClubChild','strClubCustomStr13','ChildDefine',0),(1,0,5,16,'Club','strClubCustomStr12','ChildDefine',0),(1,0,5,16,'ClubChild','strClubCustomStr12','ChildDefine',0),(1,0,5,16,'Club','strClubCustomStr11','ChildDefine',0),(1,0,5,16,'ClubChild','strClubCustomStr11','ChildDefine',0),(1,0,5,16,'ClubChild','strClubCustomStr9','ChildDefine',0),(1,0,5,16,'Club','strClubCustomStr10','ChildDefine',0),(1,0,5,16,'ClubChild','strClubCustomStr10','ChildDefine',0),(1,0,5,16,'ClubChild','strClubCustomStr8','ChildDefine',0),(1,0,5,16,'Club','strClubCustomStr9','ChildDefine',0),(1,0,5,16,'Club','strClubCustomStr8','ChildDefine',0),(1,0,5,16,'Club','strClubCustomStr7','ChildDefine',0),(1,0,5,16,'ClubChild','strClubCustomStr7','ChildDefine',0),(1,0,5,16,'ClubChild','strClubCustomStr5','ChildDefine',0),(1,0,5,16,'Club','strClubCustomStr6','ChildDefine',0),(1,0,5,16,'ClubChild','strClubCustomStr6','ChildDefine',0),(1,0,5,16,'Club','strClubCustomStr5','ChildDefine',0),(1,0,5,16,'Club','strNotes','ChildDefine',0),(1,0,5,16,'ClubChild','strNotes','ChildDefine',0),(1,0,5,16,'Club','Username','ChildDefine',0),(1,0,5,16,'ClubChild','Username','ChildDefine',0),(1,0,5,16,'Club','strClubCustomStr1','ChildDefine',0),(1,0,5,16,'ClubChild','strClubCustomStr1','ChildDefine',0),(1,0,5,16,'Club','strClubCustomStr2','ChildDefine',0),(1,0,5,16,'ClubChild','strClubCustomStr2','ChildDefine',0),(1,0,5,16,'Club','strClubCustomStr3','ChildDefine',0),(1,0,5,16,'ClubChild','strClubCustomStr3','ChildDefine',0),(1,0,5,16,'Club','strClubCustomStr4','ChildDefine',0),(1,0,5,16,'ClubChild','strClubCustomStr4','ChildDefine',0),(1,0,5,16,'ClubChild','intClubCategoryID','Editable',0),(1,0,5,16,'Club','strName','Editable',0),(1,0,5,16,'ClubChild','strName','Editable',0),(1,0,5,16,'Club','intRecStatus','ReadOnly',0),(1,0,5,16,'ClubChild','intRecStatus','ReadOnly',0),(1,0,5,16,'Club','strAbbrev','ChildDefine',0),(1,0,5,16,'ClubChild','strAbbrev','ChildDefine',0),(1,0,5,16,'Club','strAddress1','Editable',0),(1,0,5,16,'ClubChild','strAddress1','Editable',0),(1,0,5,16,'Club','strAddress2','ChildDefine',0),(1,0,5,16,'ClubChild','strAddress2','ChildDefine',0),(1,0,5,16,'Club','strSuburb','Editable',0),(1,0,5,16,'ClubChild','strSuburb','Editable',0),(1,0,5,16,'Club','strPostalCode','Editable',0),(1,0,5,16,'ClubChild','strPostalCode','Editable',0),(1,0,5,16,'Club','strState','Editable',0),(1,0,5,16,'ClubChild','strState','Editable',0),(1,0,5,16,'Club','strCountry','Editable',0),(1,0,5,16,'ClubChild','strCountry','Editable',0),(1,0,5,16,'Club','strLGA','ChildDefine',0),(1,0,5,16,'ClubChild','strLGA','ChildDefine',0),(1,0,5,16,'Club','strPhone','ChildDefine',0),(1,0,5,16,'ClubChild','strPhone','ChildDefine',0),(1,0,5,16,'Club','strFax','ChildDefine',0),(1,0,5,16,'ClubChild','strFax','ChildDefine',0),(1,0,5,16,'Club','strEmail','ChildDefine',0),(1,0,5,16,'ClubChild','strEmail','ChildDefine',0),(1,0,5,16,'Club','strIncNo','ChildDefine',0),(1,0,5,16,'ClubChild','strIncNo','ChildDefine',0),(1,0,5,16,'Club','strBusinessNo','ChildDefine',0),(1,0,5,16,'ClubChild','strBusinessNo','ChildDefine',0),(1,0,5,16,'Club','strColours','ChildDefine',0),(1,0,5,16,'ClubChild','strColours','ChildDefine',0),(1,0,5,16,'Club','intClubTypeID','Editable',0),(1,0,5,16,'ClubChild','intClubTypeID','Editable',0),(1,0,5,16,'Club','intAgeTypeID','ChildDefine',0),(1,0,5,16,'ClubChild','intAgeTypeID','ChildDefine',0),(1,0,5,16,'Club','intClubCategoryID','Editable',0),(1,0,5,20521,'PersonRegoForm','strFax','ChildDefine',0),(1,0,5,20521,'Person','strEmail','ChildDefine',0),(1,0,5,20521,'PersonChild','strEmail','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strEmail','ChildDefine',0),(1,0,100,1,'Club','strPostalCode','Editable',0),(1,0,100,1,'Person','intNatCustomLU4','ChildDefine',0),(1,0,100,1,'ClubChild','intNotifications','Editable',0),(1,0,100,1,'Club','strAddress','Editable',0),(1,0,100,1,'ClubChild','strAddress','Editable',0),(1,0,100,1,'Club','strAddress2','Editable',0),(1,0,100,1,'ClubChild','strAddress2','Editable',0),(1,0,100,1,'Club','strContactCity','Editable',0),(1,0,100,1,'PersonChild','intNatCustomLU3','Hidden',0),(1,0,100,1,'PersonRegoForm','intNatCustomLU1','ChildDefine',0),(1,0,100,1,'Person','strP2Email','ChildDefine',0),(1,0,100,1,'PersonChild','strP2Email','ChildDefine',0),(1,0,100,1,'Person','strP2Phone2','ChildDefine',0),(1,0,100,1,'PersonChild','strP2Phone2','ChildDefine',0),(1,0,100,1,'PersonRegoForm','strP2Phone2','ChildDefine',0),(1,0,100,1,'Person','strP2PhoneMobile','ChildDefine',0),(1,0,100,1,'PersonChild','strP2PhoneMobile','ChildDefine',0),(1,0,100,1,'PersonRegoForm','strP2PhoneMobile','ChildDefine',0),(1,0,100,1,'Person','strP1Salutation','ChildDefine',0),(1,0,100,1,'PersonChild','strP1Salutation','ChildDefine',0),(1,0,100,1,'PersonRegoForm','strP1Salutation','ChildDefine',0),(1,0,100,1,'Person','strP1FName','ChildDefine',0),(1,0,100,1,'PersonChild','strP1FName','ChildDefine',0),(1,0,100,1,'PersonRegoForm','strP1FName','ChildDefine',0),(1,0,100,1,'Person','strP1SName','ChildDefine',0),(1,0,100,1,'PersonChild','strP1SName','ChildDefine',0),(1,0,100,1,'PersonRegoForm','strP1SName','ChildDefine',0),(1,0,100,1,'Person','intP1Gender','ChildDefine',0),(1,0,100,1,'PersonChild','intP1Gender','ChildDefine',0),(1,0,100,1,'PersonRegoForm','intP1Gender','ChildDefine',0),(1,0,100,1,'Person','strP1Phone','ChildDefine',0),(1,0,100,1,'Person','dtPoliceCheckExp','ChildDefine',0),(1,0,100,1,'PersonChild','dtPoliceCheckExp','ChildDefine',0),(1,0,100,1,'PersonRegoForm','dtPoliceCheckExp','ChildDefine',0),(1,0,100,1,'Person','strPoliceCheckRef','ChildDefine',0),(1,0,100,1,'PersonChild','strPoliceCheckRef','ChildDefine',0),(1,0,100,1,'PersonRegoForm','strPoliceCheckRef','ChildDefine',0),(1,0,100,1,'Person','strEmergContName','Editable',0),(1,0,100,1,'PersonChild','strEmergContName','Editable',0),(1,0,100,1,'PersonRegoForm','strEmergContName','Editable',0),(1,0,100,1,'Person','strEmergContNo','Editable',0),(1,0,100,1,'PersonChild','strEmergContNo','Editable',0),(1,0,100,1,'PersonRegoForm','strEmergContNo','Editable',0),(1,0,100,1,'Person','strEmergContNo2','ChildDefine',0),(1,0,100,1,'PersonChild','strEmergContNo2','ChildDefine',0),(1,0,100,1,'PersonRegoForm','strEmergContNo2','ChildDefine',0),(1,0,100,1,'Person','strEmergContRel','Editable',0),(1,0,100,1,'PersonChild','strEmergContRel','Editable',0),(1,0,100,1,'PersonRegoForm','strEmergContRel','Editable',0),(1,0,100,1,'Person','strPager','ChildDefine',0),(1,0,100,1,'PersonChild','strPager','ChildDefine',0),(1,0,100,1,'PersonRegoForm','strPager','ChildDefine',0),(1,0,100,1,'Person','strFax','ChildDefine',0),(1,0,100,1,'PersonChild','strFax','ChildDefine',0),(1,0,100,1,'PersonRegoForm','strFax','ChildDefine',0),(1,0,100,1,'Person','strEmail','Editable',0),(1,0,100,1,'PersonChild','strEmail','Editable',0),(1,0,100,1,'PersonRegoForm','strEmail','Editable',0),(1,0,100,1,'Person','strEmail2','ChildDefine',0),(1,0,100,1,'PersonChild','strEmail2','ChildDefine',0),(1,0,100,1,'PersonRegoForm','strEmail2','ChildDefine',0),(1,0,100,1,'Person','intDeceased','ChildDefine',0),(1,0,5,20521,'Person','strFax','ChildDefine',0),(1,0,5,20521,'PersonChild','strFax','ChildDefine',0),(1,0,100,1,'ClubChild','strMAID','Editable',0),(1,0,100,1,'ClubChild','strDiscipline','Editable',0),(1,0,100,1,'Club','strOrganisationLevel','Compulsory',0),(1,0,100,1,'ClubChild','strLegalID','Editable',0),(1,0,100,1,'Club','strDiscipline','Editable',0),(1,0,100,1,'ClubChild','strMANotes','Editable',0),(1,0,100,1,'Club','intLegalTypeID','Editable',0),(1,0,100,1,'ClubChild','intLegalTypeID','Editable',0),(1,0,100,1,'ClubChild','strFax','Editable',0),(1,0,100,1,'Club','strContact','Editable',0),(1,0,100,1,'ClubChild','strRegion','Editable',0),(1,0,100,1,'Club','strISOCountry','Editable',0),(1,0,100,1,'ClubChild','strISOCountry','Editable',0),(1,0,100,1,'Club','intLocalLanguage','ChildDefine',0),(1,0,100,1,'ClubChild','intLocalLanguage','ChildDefine',0),(1,0,100,1,'PersonChild','intNatCustomLU5','Compulsory',0),(1,0,100,1,'Person','intNatCustomLU3','Hidden',0),(1,0,100,1,'PersonChild','intNatCustomLU1','ChildDefine',0),(1,0,100,1,'PersonRegoForm','strISOCountryOfBirth','AddOnlyCompulsory',0),(1,0,100,1,'Person','strRegionOfBirth','Editable',0),(1,0,100,1,'PersonChild','strRegionOfBirth','Editable',0),(1,0,100,1,'PersonRegoForm','strRegionOfBirth','Editable',0),(1,0,100,1,'PersonRegoForm','strNotes','Editable',0),(1,0,5,20521,'PersonRegoForm','strPhoneMobile','ChildDefine',0),(1,0,5,20521,'Person','strPhoneMobile','ChildDefine',0),(1,0,5,20521,'PersonChild','strPhoneMobile','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strCountry','ChildDefine',0),(1,0,5,20521,'Person','strPostalCode','ChildDefine',0),(1,0,5,20521,'PersonChild','strPostalCode','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strPostalCode','ChildDefine',0),(1,0,5,20521,'Person','strPhoneHome','ChildDefine',0),(1,0,5,20521,'PersonChild','strPhoneHome','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strPhoneHome','ChildDefine',0),(1,0,5,20521,'Person','strPhoneWork','ChildDefine',0),(1,0,5,20521,'PersonChild','strPhoneWork','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strPhoneWork','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strState','ChildDefine',0),(1,0,5,20521,'Person','strCountry','ChildDefine',0),(1,0,5,20521,'PersonChild','strCountry','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strCityOfResidence','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strSuburb','ChildDefine',0),(1,0,5,20521,'Person','strCityOfResidence','ChildDefine',0),(1,0,5,20521,'PersonChild','strCityOfResidence','ChildDefine',0),(1,0,5,20521,'PersonChild','strSuburb','ChildDefine',0),(1,0,5,20521,'Person','strSuburb','ChildDefine',0),(1,0,5,20521,'Person','strAddress2','ChildDefine',0),(1,0,5,20521,'PersonChild','strAddress2','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strAddress2','ChildDefine',0),(1,0,5,20521,'Person','strAddress1','ChildDefine',0),(1,0,5,20521,'PersonChild','strAddress1','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strAddress1','ChildDefine',0),(1,0,5,20521,'Person','strWeight','ChildDefine',0),(1,0,5,20521,'PersonChild','strWeight','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strWeight','ChildDefine',0),(1,0,5,20521,'Person','intEthnicityID','ChildDefine',0),(1,0,5,20521,'PersonChild','intEthnicityID','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','intEthnicityID','ChildDefine',0),(1,0,5,20521,'Person','strHeight','ChildDefine',0),(1,0,5,20521,'PersonChild','strHeight','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strHeight','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strMemberNo','ChildDefine',0),(1,0,5,16,'Person','intPhotoUseApproval','ChildDefine',0),(1,0,5,16,'PersonChild','intPhotoUseApproval','ChildDefine',0),(1,0,5,16,'PersonRegoForm','intPhotoUseApproval','ChildDefine',0),(1,0,5,16,'ClubChild','intClubCustomBool5','ChildDefine',0),(1,0,5,16,'PersonRegoForm','intDefaulter','ChildDefine',0),(1,0,5,16,'Person','PlayerNumberClub.strJumperNum','ChildDefine',0),(1,0,5,16,'PersonChild','PlayerNumberClub.strJumperNum','ChildDefine',0),(1,0,5,16,'Person','dtRegisteredUntil','ReadOnly',0),(1,0,5,16,'PersonChild','dtRegisteredUntil','ReadOnly',0),(1,0,5,16,'PersonRegoForm','dtRegisteredUntil','ChildDefine',0),(1,0,5,16,'Person','dtCreatedOnline','ReadOnly',0),(1,0,5,16,'PersonChild','dtCreatedOnline','ReadOnly',0),(1,0,5,16,'PersonRegoForm','dtCreatedOnline','ChildDefine',0),(1,0,5,16,'Person','intConsentSignatureSighted','ChildDefine',0),(1,0,5,16,'PersonChild','intConsentSignatureSighted','ChildDefine',0),(1,0,5,16,'PersonRegoForm','intConsentSignatureSighted','ChildDefine',0),(1,0,5,16,'Person','intDefaulter','ChildDefine',0),(1,0,5,16,'PersonChild','intDefaulter','ChildDefine',0),(1,0,5,16,'Person','strP2Email','ChildDefine',0),(1,0,5,16,'PersonChild','strP2Email','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strP2Email','ChildDefine',0),(1,0,5,16,'Person','strP2Email2','ChildDefine',0),(1,0,5,16,'PersonChild','strP2Email2','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strP2Email2','ChildDefine',0),(1,0,5,16,'Person','intP2AssistAreaID','ChildDefine',0),(1,0,5,16,'PersonChild','intP2AssistAreaID','ChildDefine',0),(1,0,5,16,'PersonRegoForm','intP2AssistAreaID','ChildDefine',0),(1,0,5,16,'Person','intFinancialActive','ChildDefine',0),(1,0,5,16,'PersonChild','intFinancialActive','ChildDefine',0),(1,0,5,16,'PersonRegoForm','intFinancialActive','ChildDefine',0),(1,0,5,16,'Person','intMemberPackageID','ChildDefine',0),(1,0,5,16,'PersonChild','intMemberPackageID','ChildDefine',0),(1,0,5,16,'PersonRegoForm','intMemberPackageID','ChildDefine',0),(1,0,5,16,'Person','intLifeMember','ChildDefine',0),(1,0,5,16,'PersonChild','intLifeMember','ChildDefine',0),(1,0,5,16,'PersonRegoForm','intLifeMember','ChildDefine',0),(1,0,5,16,'Person','intMedicalConditions','ChildDefine',0),(1,0,5,16,'PersonChild','intMedicalConditions','ChildDefine',0),(1,0,5,16,'PersonRegoForm','intMedicalConditions','ChildDefine',0),(1,0,5,16,'Person','intAllergies','ChildDefine',0),(1,0,5,16,'PersonChild','intAllergies','ChildDefine',0),(1,0,5,16,'PersonRegoForm','intAllergies','ChildDefine',0),(1,0,5,16,'Person','intAllowMedicalTreatment','ChildDefine',0),(1,0,5,16,'PersonChild','intAllowMedicalTreatment','ChildDefine',0),(1,0,5,16,'PersonRegoForm','intAllowMedicalTreatment','ChildDefine',0),(1,0,5,16,'Person','strMedicalNotes','ChildDefine',0),(1,0,5,16,'PersonChild','strMedicalNotes','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strMedicalNotes','ChildDefine',0),(1,0,5,16,'Person','intOccupationID','ChildDefine',0),(1,0,5,16,'PersonChild','intOccupationID','ChildDefine',0),(1,0,5,16,'PersonRegoForm','intOccupationID','ChildDefine',0),(1,0,5,16,'Person','strLoyaltyNumber','ChildDefine',0),(1,0,5,16,'PersonChild','strLoyaltyNumber','ChildDefine',0),(1,0,5,16,'PersonRegoForm','strLoyaltyNumber','ChildDefine',0),(1,0,5,16,'Person','intMailingList','ChildDefine',0),(1,0,5,16,'PersonChild','intMailingList','ChildDefine',0),(1,0,5,16,'PersonRegoForm','intMailingList','ChildDefine',0),(1,0,5,20521,'PersonChild','strEmergContNo2','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strEmergContNo2','ChildDefine',0),(1,0,5,20521,'Person','strEmergContRel','ChildDefine',0),(1,0,5,20521,'PersonChild','strEmergContRel','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strEmergContRel','ChildDefine',0),(1,0,5,20521,'Person','intPlayer','ChildDefine',0),(1,0,5,20521,'PersonChild','intPlayer','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','intPlayer','ChildDefine',0),(1,0,5,20521,'Person','intCoach','ChildDefine',0),(1,0,5,20521,'PersonChild','intCoach','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','intCoach','ChildDefine',0),(1,0,5,20521,'Person','intUmpire','ChildDefine',0),(1,0,5,20521,'PersonChild','intUmpire','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','intUmpire','ChildDefine',0),(1,0,5,20521,'Person','intOfficial','ChildDefine',0),(1,0,5,20521,'PersonChild','intOfficial','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','intOfficial','ChildDefine',0),(1,0,5,20521,'Person','intMisc','ChildDefine',0),(1,0,5,20521,'PersonChild','intMisc','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','intMisc','ChildDefine',0),(1,0,5,20521,'Person','intVolunteer','ChildDefine',0),(1,0,5,20521,'PersonChild','intVolunteer','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','intVolunteer','ChildDefine',0),(1,0,5,20521,'Person','intPlayerPending','ChildDefine',0),(1,0,5,20521,'PersonChild','intPlayerPending','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','intPlayerPending','ChildDefine',0),(1,0,5,20521,'Person','strPreferredLang','ChildDefine',0),(1,0,5,20521,'PersonChild','strPreferredLang','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strPreferredLang','ChildDefine',0),(1,0,5,20521,'Person','strPassportNationality','ChildDefine',0),(1,0,5,20521,'PersonChild','strPassportNationality','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strPassportNationality','ChildDefine',0),(1,0,100,1,'Club','intFacilityTypeID','Editable',0),(1,0,100,1,'PersonRegoForm','intNatCustomLU3','Hidden',0),(1,0,5,20521,'Person','strPassportIssueCountry','ChildDefine',0),(1,0,5,20521,'PersonChild','strPassportIssueCountry','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strPassportIssueCountry','ChildDefine',0),(1,0,5,20521,'Person','dtPassportExpiry','ChildDefine',0),(1,0,5,20521,'PersonChild','dtPassportExpiry','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','dtPassportExpiry','ChildDefine',0),(1,0,5,20521,'Person','strBirthCertNo','ChildDefine',0),(1,0,5,20521,'PersonChild','strBirthCertNo','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strBirthCertNo','ChildDefine',0),(1,0,5,20521,'Person','strHealthCareNo','ChildDefine',0),(1,0,5,20521,'PersonChild','strHealthCareNo','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strHealthCareNo','ChildDefine',0),(1,0,5,20521,'Person','intIdentTypeID','ChildDefine',0),(1,0,5,20521,'PersonChild','intIdentTypeID','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','intIdentTypeID','ChildDefine',0),(1,0,5,20521,'Person','strIdentNum','ChildDefine',0),(1,0,5,20521,'PersonChild','strIdentNum','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strIdentNum','ChildDefine',0),(1,0,5,20521,'Person','dtPoliceCheck','ChildDefine',0),(1,0,5,20521,'PersonChild','dtPoliceCheck','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','dtPoliceCheck','ChildDefine',0),(1,0,5,20521,'Person','dtPoliceCheckExp','ChildDefine',0),(1,0,5,20521,'PersonChild','dtPoliceCheckExp','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','dtPoliceCheckExp','ChildDefine',0),(1,0,5,20521,'Person','strPoliceCheckRef','ChildDefine',0),(1,0,5,20521,'PersonChild','strPoliceCheckRef','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strPoliceCheckRef','ChildDefine',0),(1,0,5,20521,'Person','intP1Gender','ChildDefine',0),(1,0,5,20521,'PersonChild','intP1Gender','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','intP1Gender','ChildDefine',0),(1,0,5,20521,'Person','strP1Salutation','ChildDefine',0),(1,0,5,20521,'PersonChild','strP1Salutation','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strP1Salutation','ChildDefine',0),(1,0,5,20521,'Person','strP1FName','ChildDefine',0),(1,0,5,20521,'PersonChild','strP1FName','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strP1FName','ChildDefine',0),(1,0,5,20521,'Person','strP1SName','ChildDefine',0),(1,0,5,20521,'PersonChild','strP1SName','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strP1SName','ChildDefine',0),(1,0,5,20521,'Person','strP1Phone','ChildDefine',0),(1,0,5,20521,'PersonChild','strP1Phone','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strP1Phone','ChildDefine',0),(1,0,5,20521,'Person','strP1Phone2','ChildDefine',0),(1,0,5,20521,'PersonChild','strP1Phone2','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strP1Phone2','ChildDefine',0),(1,0,5,20521,'Person','strP1PhoneMobile','ChildDefine',0),(1,0,5,20521,'PersonChild','strP1PhoneMobile','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strP1PhoneMobile','ChildDefine',0),(1,0,5,20521,'Person','strP1Email','ChildDefine',0),(1,0,5,20521,'PersonChild','strP1Email','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strP1Email','ChildDefine',0),(1,0,5,20521,'Person','strP1Email2','ChildDefine',0),(1,0,5,20521,'PersonChild','strP1Email2','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strP1Email2','ChildDefine',0),(1,0,5,20521,'Person','intP1AssistAreaID','ChildDefine',0),(1,0,5,20521,'PersonChild','intP1AssistAreaID','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','intP1AssistAreaID','ChildDefine',0),(1,0,5,20521,'Person','intP2Gender','ChildDefine',0),(1,0,5,20521,'PersonChild','intP2Gender','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','intP2Gender','ChildDefine',0),(1,0,5,20521,'Person','strP2Salutation','ChildDefine',0),(1,0,5,20521,'PersonChild','strP2Salutation','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strP2Salutation','ChildDefine',0),(1,0,5,20521,'Person','strP2FName','ChildDefine',0),(1,0,5,20521,'PersonChild','strP2FName','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strP2FName','ChildDefine',0),(1,0,5,20521,'Person','strP2SName','ChildDefine',0),(1,0,5,20521,'PersonChild','strP2SName','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strP2SName','ChildDefine',0),(1,0,5,20521,'Person','strP2Phone','ChildDefine',0),(1,0,5,20521,'PersonChild','strP2Phone','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strP2Phone','ChildDefine',0),(1,0,5,20521,'Person','strP2Phone2','ChildDefine',0),(1,0,5,20521,'PersonChild','strP2Phone2','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strP2Phone2','ChildDefine',0),(1,0,5,20521,'Person','strP2PhoneMobile','ChildDefine',0),(1,0,5,20521,'PersonChild','strP2PhoneMobile','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strP2PhoneMobile','ChildDefine',0),(1,0,5,20521,'Person','strP2Email','ChildDefine',0),(1,0,5,20521,'PersonChild','strP2Email','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strP2Email','ChildDefine',0),(1,0,5,20521,'Person','strP2Email2','ChildDefine',0),(1,0,5,20521,'PersonChild','strP2Email2','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strP2Email2','ChildDefine',0),(1,0,5,20521,'Person','intP2AssistAreaID','ChildDefine',0),(1,0,5,20521,'PersonChild','intP2AssistAreaID','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','intP2AssistAreaID','ChildDefine',0),(1,0,5,20521,'Person','intFinancialActive','ChildDefine',0),(1,0,5,20521,'PersonChild','intFinancialActive','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','intFinancialActive','ChildDefine',0),(1,0,5,20521,'Person','intMemberPackageID','ChildDefine',0),(1,0,5,20521,'PersonChild','intMemberPackageID','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','intMemberPackageID','ChildDefine',0),(1,0,5,20521,'Person','intLifeMember','ChildDefine',0),(1,0,5,20521,'PersonChild','intLifeMember','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','intLifeMember','ChildDefine',0),(1,0,5,20521,'Person','intMedicalConditions','ChildDefine',0),(1,0,5,20521,'PersonChild','intMedicalConditions','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','intMedicalConditions','ChildDefine',0),(1,0,5,20521,'Person','intAllergies','ChildDefine',0),(1,0,5,20521,'PersonChild','intAllergies','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','intAllergies','ChildDefine',0),(1,0,5,20521,'Person','intAllowMedicalTreatment','ChildDefine',0),(1,0,5,20521,'PersonChild','intAllowMedicalTreatment','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','intAllowMedicalTreatment','ChildDefine',0),(1,0,5,20521,'Person','strMedicalNotes','ChildDefine',0),(1,0,5,20521,'PersonChild','strMedicalNotes','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strMedicalNotes','ChildDefine',0),(1,0,5,20521,'Person','intOccupationID','ChildDefine',0),(1,0,5,20521,'PersonChild','intOccupationID','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','intOccupationID','ChildDefine',0),(1,0,5,20521,'Person','strLoyaltyNumber','ChildDefine',0),(1,0,5,20521,'PersonChild','strLoyaltyNumber','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strLoyaltyNumber','ChildDefine',0),(1,0,5,20521,'Person','intMailingList','ChildDefine',0),(1,0,5,20521,'PersonChild','intMailingList','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','intMailingList','ChildDefine',0),(1,0,5,20521,'Person','strCustomStr1','ChildDefine',0),(1,0,5,20521,'PersonChild','strCustomStr1','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strCustomStr1','ChildDefine',0),(1,0,5,20521,'Person','strCustomStr2','ChildDefine',0),(1,0,5,20521,'PersonChild','strCustomStr2','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strCustomStr2','ChildDefine',0),(1,0,5,20521,'Person','strCustomStr3','ChildDefine',0),(1,0,5,20521,'PersonChild','strCustomStr3','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strCustomStr3','ChildDefine',0),(1,0,5,20521,'Person','strCustomStr4','ChildDefine',0),(1,0,5,20521,'PersonChild','strCustomStr4','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strCustomStr4','ChildDefine',0),(1,0,5,20521,'Person','strCustomStr5','ChildDefine',0),(1,0,5,20521,'PersonChild','strCustomStr5','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strCustomStr5','ChildDefine',0),(1,0,5,20521,'Person','strCustomStr6','ChildDefine',0),(1,0,5,20521,'PersonChild','strCustomStr6','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strCustomStr6','ChildDefine',0),(1,0,5,20521,'Person','strCustomStr7','ChildDefine',0),(1,0,5,20521,'PersonChild','strCustomStr7','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strCustomStr7','ChildDefine',0),(1,0,5,20521,'Person','strCustomStr8','ChildDefine',0),(1,0,5,20521,'PersonChild','strCustomStr8','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strCustomStr8','ChildDefine',0),(1,0,5,20521,'Person','strCustomStr9','ChildDefine',0),(1,0,5,20521,'PersonChild','strCustomStr9','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strCustomStr9','ChildDefine',0),(1,0,5,20521,'Person','strCustomStr10','ChildDefine',0),(1,0,5,20521,'PersonChild','strCustomStr10','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strCustomStr10','ChildDefine',0),(1,0,5,20521,'Person','strCustomStr11','ChildDefine',0),(1,0,5,20521,'PersonChild','strCustomStr11','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strCustomStr11','ChildDefine',0),(1,0,5,20521,'Person','strCustomStr12','ChildDefine',0),(1,0,5,20521,'PersonChild','strCustomStr12','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strCustomStr12','ChildDefine',0),(1,0,5,20521,'Person','strCustomStr13','ChildDefine',0),(1,0,5,20521,'PersonChild','strCustomStr13','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strCustomStr13','ChildDefine',0),(1,0,5,20521,'Person','strCustomStr14','ChildDefine',0),(1,0,5,20521,'PersonChild','strCustomStr14','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strCustomStr14','ChildDefine',0),(1,0,5,20521,'Person','strCustomStr15','ChildDefine',0),(1,0,5,20521,'PersonChild','strCustomStr15','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strCustomStr15','ChildDefine',0),(1,0,5,20521,'Person','strCustomStr16','ChildDefine',0),(1,0,5,20521,'PersonChild','strCustomStr16','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strCustomStr16','ChildDefine',0),(1,0,5,20521,'Person','strCustomStr17','ChildDefine',0),(1,0,5,20521,'PersonChild','strCustomStr17','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strCustomStr17','ChildDefine',0),(1,0,5,20521,'Person','strCustomStr18','ChildDefine',0),(1,0,5,20521,'PersonChild','strCustomStr18','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strCustomStr18','ChildDefine',0),(1,0,5,20521,'Person','strCustomStr19','ChildDefine',0),(1,0,5,20521,'PersonChild','strCustomStr19','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strCustomStr19','ChildDefine',0),(1,0,5,20521,'Person','strCustomStr20','ChildDefine',0),(1,0,5,20521,'PersonChild','strCustomStr20','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strCustomStr20','ChildDefine',0),(1,0,5,20521,'Person','strCustomStr21','ChildDefine',0),(1,0,5,20521,'PersonChild','strCustomStr21','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strCustomStr21','ChildDefine',0),(1,0,5,20521,'Person','strCustomStr22','ChildDefine',0),(1,0,5,20521,'PersonChild','strCustomStr22','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strCustomStr22','ChildDefine',0),(1,0,5,20521,'Person','strCustomStr23','ChildDefine',0),(1,0,5,20521,'PersonChild','strCustomStr23','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strCustomStr23','ChildDefine',0),(1,0,5,20521,'Person','strCustomStr24','ChildDefine',0),(1,0,5,20521,'PersonChild','strCustomStr24','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strCustomStr24','ChildDefine',0),(1,0,5,20521,'Person','strCustomStr25','ChildDefine',0),(1,0,5,20521,'PersonChild','strCustomStr25','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strCustomStr25','ChildDefine',0),(1,0,5,20521,'Person','dblCustomDbl1','ChildDefine',0),(1,0,5,20521,'PersonChild','dblCustomDbl1','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','dblCustomDbl1','ChildDefine',0),(1,0,5,20521,'Person','dblCustomDbl2','ChildDefine',0),(1,0,5,20521,'PersonChild','dblCustomDbl2','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','dblCustomDbl2','ChildDefine',0),(1,0,5,20521,'Person','dblCustomDbl3','ChildDefine',0),(1,0,5,20521,'PersonChild','dblCustomDbl3','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','dblCustomDbl3','ChildDefine',0),(1,0,5,20521,'Person','dblCustomDbl4','ChildDefine',0),(1,0,5,20521,'PersonChild','dblCustomDbl4','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','dblCustomDbl4','ChildDefine',0),(1,0,5,20521,'Person','dblCustomDbl5','ChildDefine',0),(1,0,5,20521,'PersonChild','dblCustomDbl5','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','dblCustomDbl5','ChildDefine',0),(1,0,5,20521,'Person','dblCustomDbl6','ChildDefine',0),(1,0,5,20521,'PersonChild','dblCustomDbl6','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','dblCustomDbl6','ChildDefine',0),(1,0,5,20521,'Person','dblCustomDbl7','ChildDefine',0),(1,0,5,20521,'PersonChild','dblCustomDbl7','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','dblCustomDbl7','ChildDefine',0),(1,0,5,20521,'Person','dblCustomDbl8','ChildDefine',0),(1,0,5,20521,'PersonChild','dblCustomDbl8','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','dblCustomDbl8','ChildDefine',0),(1,0,5,20521,'Person','dblCustomDbl9','ChildDefine',0),(1,0,5,20521,'PersonChild','dblCustomDbl9','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','dblCustomDbl9','ChildDefine',0),(1,0,5,20521,'Person','dblCustomDbl10','ChildDefine',0),(1,0,5,20521,'PersonChild','dblCustomDbl10','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','dblCustomDbl10','ChildDefine',0),(1,0,5,20521,'Person','dblCustomDbl11','ChildDefine',0),(1,0,5,20521,'PersonChild','dblCustomDbl11','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','dblCustomDbl11','ChildDefine',0),(1,0,5,20521,'Person','dblCustomDbl12','ChildDefine',0),(1,0,5,20521,'PersonChild','dblCustomDbl12','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','dblCustomDbl12','ChildDefine',0),(1,0,5,20521,'Person','dblCustomDbl13','ChildDefine',0),(1,0,5,20521,'PersonChild','dblCustomDbl13','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','dblCustomDbl13','ChildDefine',0),(1,0,5,20521,'Person','dblCustomDbl14','ChildDefine',0),(1,0,5,20521,'PersonChild','dblCustomDbl14','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','dblCustomDbl14','ChildDefine',0),(1,0,5,20521,'Person','dblCustomDbl15','ChildDefine',0),(1,0,5,20521,'PersonChild','dblCustomDbl15','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','dblCustomDbl15','ChildDefine',0),(1,0,5,20521,'Person','dblCustomDbl16','ChildDefine',0),(1,0,5,20521,'PersonChild','dblCustomDbl16','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','dblCustomDbl16','ChildDefine',0),(1,0,5,20521,'Person','dblCustomDbl17','ChildDefine',0),(1,0,5,20521,'PersonChild','dblCustomDbl17','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','dblCustomDbl17','ChildDefine',0),(1,0,5,20521,'Person','dblCustomDbl18','ChildDefine',0),(1,0,5,20521,'PersonChild','dblCustomDbl18','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','dblCustomDbl18','ChildDefine',0),(1,0,5,20521,'Person','dblCustomDbl19','ChildDefine',0),(1,0,5,20521,'PersonChild','dblCustomDbl19','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','dblCustomDbl19','ChildDefine',0),(1,0,5,20521,'Person','dblCustomDbl20','ChildDefine',0),(1,0,5,20521,'PersonChild','dblCustomDbl20','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','dblCustomDbl20','ChildDefine',0),(1,0,5,20521,'Person','dtCustomDt1','ChildDefine',0),(1,0,5,20521,'PersonChild','dtCustomDt1','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','dtCustomDt1','ChildDefine',0),(1,0,5,20521,'Person','dtCustomDt2','ChildDefine',0),(1,0,5,20521,'PersonChild','dtCustomDt2','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','dtCustomDt2','ChildDefine',0),(1,0,5,20521,'Person','dtCustomDt3','ChildDefine',0),(1,0,5,20521,'PersonChild','dtCustomDt3','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','dtCustomDt3','ChildDefine',0),(1,0,5,20521,'Person','dtCustomDt4','ChildDefine',0),(1,0,5,20521,'PersonChild','dtCustomDt4','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','dtCustomDt4','ChildDefine',0),(1,0,5,20521,'Person','dtCustomDt5','ChildDefine',0),(1,0,5,20521,'PersonChild','dtCustomDt5','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','dtCustomDt5','ChildDefine',0),(1,0,5,20521,'Person','dtCustomDt6','ChildDefine',0),(1,0,5,20521,'PersonChild','dtCustomDt6','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','dtCustomDt6','ChildDefine',0),(1,0,5,20521,'Person','dtCustomDt7','ChildDefine',0),(1,0,5,20521,'PersonChild','dtCustomDt7','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','dtCustomDt7','ChildDefine',0),(1,0,5,20521,'Person','dtCustomDt8','ChildDefine',0),(1,0,5,20521,'PersonChild','dtCustomDt8','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','dtCustomDt8','ChildDefine',0),(1,0,5,20521,'Person','dtCustomDt9','ChildDefine',0),(1,0,5,20521,'PersonChild','dtCustomDt9','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','dtCustomDt9','ChildDefine',0),(1,0,5,20521,'Person','dtCustomDt10','ChildDefine',0),(1,0,5,20521,'PersonChild','dtCustomDt10','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','dtCustomDt10','ChildDefine',0),(1,0,5,20521,'Person','dtCustomDt11','ChildDefine',0),(1,0,5,20521,'PersonChild','dtCustomDt11','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','dtCustomDt11','ChildDefine',0),(1,0,5,20521,'Person','dtCustomDt12','ChildDefine',0),(1,0,5,20521,'PersonChild','dtCustomDt12','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','dtCustomDt12','ChildDefine',0),(1,0,5,20521,'Person','dtCustomDt13','ChildDefine',0),(1,0,5,20521,'PersonChild','dtCustomDt13','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','dtCustomDt13','ChildDefine',0),(1,0,5,20521,'Person','dtCustomDt14','ChildDefine',0),(1,0,5,20521,'PersonChild','dtCustomDt14','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','dtCustomDt14','ChildDefine',0),(1,0,5,20521,'Person','dtCustomDt15','ChildDefine',0),(1,0,5,20521,'PersonChild','dtCustomDt15','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','dtCustomDt15','ChildDefine',0),(1,0,5,20521,'Person','intCustomLU5','ChildDefine',0),(1,0,5,20521,'PersonChild','intCustomLU5','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','intCustomLU5','ChildDefine',0),(1,0,5,20521,'Person','intCustomLU6','ChildDefine',0),(1,0,5,20521,'PersonChild','intCustomLU6','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','intCustomLU6','ChildDefine',0),(1,0,5,20521,'Person','intCustomLU7','ChildDefine',0),(1,0,5,20521,'PersonChild','intCustomLU7','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','intCustomLU7','ChildDefine',0),(1,0,5,20521,'Person','intCustomLU8','ChildDefine',0),(1,0,5,20521,'PersonChild','intCustomLU8','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','intCustomLU8','ChildDefine',0),(1,0,5,20521,'Person','intCustomLU9','ChildDefine',0),(1,0,5,20521,'PersonChild','intCustomLU9','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','intCustomLU9','ChildDefine',0),(1,0,5,20521,'Person','intCustomLU10','ChildDefine',0),(1,0,5,20521,'PersonChild','intCustomLU10','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','intCustomLU10','ChildDefine',0),(1,0,5,20521,'Person','intCustomLU11','ChildDefine',0),(1,0,5,20521,'PersonChild','intCustomLU11','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','intCustomLU11','ChildDefine',0),(1,0,5,20521,'Person','intCustomLU12','ChildDefine',0),(1,0,5,20521,'PersonChild','intCustomLU12','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','intCustomLU12','ChildDefine',0),(1,0,5,20521,'Person','intCustomLU13','ChildDefine',0),(1,0,5,20521,'PersonChild','intCustomLU13','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','intCustomLU13','ChildDefine',0),(1,0,5,20521,'Person','intCustomLU14','ChildDefine',0),(1,0,5,20521,'PersonChild','intCustomLU14','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','intCustomLU14','ChildDefine',0),(1,0,5,20521,'Person','intCustomLU15','ChildDefine',0),(1,0,5,20521,'PersonChild','intCustomLU15','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','intCustomLU15','ChildDefine',0),(1,0,5,20521,'Person','intCustomLU16','ChildDefine',0),(1,0,5,20521,'PersonChild','intCustomLU16','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','intCustomLU16','ChildDefine',0),(1,0,5,20521,'Person','intCustomLU17','ChildDefine',0),(1,0,5,20521,'PersonChild','intCustomLU17','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','intCustomLU17','ChildDefine',0),(1,0,5,20521,'Person','intCustomLU18','ChildDefine',0),(1,0,5,20521,'PersonChild','intCustomLU18','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','intCustomLU18','ChildDefine',0),(1,0,5,20521,'Person','intCustomLU19','ChildDefine',0),(1,0,5,20521,'PersonChild','intCustomLU19','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','intCustomLU19','ChildDefine',0),(1,0,5,20521,'Person','intCustomLU20','ChildDefine',0),(1,0,5,20521,'PersonChild','intCustomLU20','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','intCustomLU20','ChildDefine',0),(1,0,5,20521,'Person','intCustomLU21','ChildDefine',0),(1,0,5,20521,'PersonChild','intCustomLU21','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','intCustomLU21','ChildDefine',0),(1,0,5,20521,'Person','intCustomLU22','ChildDefine',0),(1,0,5,20521,'PersonChild','intCustomLU22','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','intCustomLU22','ChildDefine',0),(1,0,5,20521,'Person','intCustomLU23','ChildDefine',0),(1,0,5,20521,'PersonChild','intCustomLU23','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','intCustomLU23','ChildDefine',0),(1,0,5,20521,'Person','intCustomLU24','ChildDefine',0),(1,0,5,20521,'PersonChild','intCustomLU24','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','intCustomLU24','ChildDefine',0),(1,0,5,20521,'Person','intCustomLU25','ChildDefine',0),(1,0,5,20521,'PersonChild','intCustomLU25','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','intCustomLU25','ChildDefine',0),(1,0,5,20521,'Person','intCustomBool1','ChildDefine',0),(1,0,5,20521,'PersonChild','intCustomBool1','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','intCustomBool1','ChildDefine',0),(1,0,5,20521,'Person','intCustomBool2','ChildDefine',0),(1,0,5,20521,'PersonChild','intCustomBool2','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','intCustomBool2','ChildDefine',0),(1,0,5,20521,'Person','intCustomBool3','ChildDefine',0),(1,0,5,20521,'PersonChild','intCustomBool3','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','intCustomBool3','ChildDefine',0),(1,0,5,20521,'Person','intCustomBool4','ChildDefine',0),(1,0,5,20521,'PersonChild','intCustomBool4','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','intCustomBool4','ChildDefine',0),(1,0,5,20521,'Person','intCustomBool5','ChildDefine',0),(1,0,5,20521,'PersonChild','intCustomBool5','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','intCustomBool5','ChildDefine',0),(1,0,5,20521,'Person','intCustomBool6','ChildDefine',0),(1,0,5,20521,'PersonChild','intCustomBool6','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','intCustomBool6','ChildDefine',0),(1,0,5,20521,'Person','intCustomBool7','ChildDefine',0),(1,0,5,20521,'PersonChild','intCustomBool7','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','intCustomBool7','ChildDefine',0),(1,0,5,20521,'Person','intFavStateTeamID','ChildDefine',0),(1,0,5,20521,'PersonChild','intFavStateTeamID','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','intFavStateTeamID','ChildDefine',0),(1,0,5,20521,'Person','intFavNationalTeamID','ChildDefine',0),(1,0,5,20521,'PersonChild','intFavNationalTeamID','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','intFavNationalTeamID','ChildDefine',0),(1,0,5,20521,'Person','intFavNationalTeamMember','ChildDefine',0),(1,0,5,20521,'PersonChild','intFavNationalTeamMember','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','intFavNationalTeamMember','ChildDefine',0),(1,0,5,20521,'Person','intAttendSportCount','ChildDefine',0),(1,0,5,20521,'PersonChild','intAttendSportCount','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','intAttendSportCount','ChildDefine',0),(1,0,5,20521,'Person','intWatchSportHowOftenID','ChildDefine',0),(1,0,5,20521,'PersonChild','intWatchSportHowOftenID','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','intWatchSportHowOftenID','ChildDefine',0),(1,0,5,20521,'Person','strNotes','ChildDefine',0),(1,0,5,20521,'PersonChild','strNotes','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strNotes','ChildDefine',0),(1,0,5,20521,'Person','strMemberCustomNotes1','ChildDefine',0),(1,0,5,20521,'PersonChild','strMemberCustomNotes1','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strMemberCustomNotes1','ChildDefine',0),(1,0,5,20521,'Person','strMemberCustomNotes2','ChildDefine',0),(1,0,5,20521,'PersonChild','strMemberCustomNotes2','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strMemberCustomNotes2','ChildDefine',0),(1,0,5,20521,'Person','strMemberCustomNotes3','ChildDefine',0),(1,0,5,20521,'PersonChild','strMemberCustomNotes3','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strMemberCustomNotes3','ChildDefine',0),(1,0,5,20521,'Person','strMemberCustomNotes4','ChildDefine',0),(1,0,5,20521,'PersonChild','strMemberCustomNotes4','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strMemberCustomNotes4','ChildDefine',0),(1,0,5,20521,'Person','strMemberCustomNotes5','ChildDefine',0),(1,0,5,20521,'PersonChild','strMemberCustomNotes5','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','strMemberCustomNotes5','ChildDefine',0),(1,0,5,20521,'Person','dtFirstRegistered','ChildDefine',0),(1,0,5,20521,'PersonChild','dtFirstRegistered','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','dtFirstRegistered','ChildDefine',0),(1,0,5,20521,'Person','dtLastRegistered','ChildDefine',0),(1,0,5,20521,'PersonChild','dtLastRegistered','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','dtLastRegistered','ChildDefine',0),(1,0,5,20521,'Person','dtLastUpdate','ChildDefine',0),(1,0,5,20521,'PersonChild','dtLastUpdate','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','dtLastUpdate','ChildDefine',0),(1,0,5,20521,'Person','dtRegisteredUntil','ChildDefine',0),(1,0,5,20521,'PersonChild','dtRegisteredUntil','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','dtRegisteredUntil','ChildDefine',0),(1,0,5,20521,'Person','dtCreatedOnline','ChildDefine',0),(1,0,5,20521,'PersonChild','dtCreatedOnline','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','dtCreatedOnline','ChildDefine',0),(1,0,5,20521,'Person','intConsentSignatureSighted','ChildDefine',0),(1,0,5,20521,'PersonChild','intConsentSignatureSighted','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','intConsentSignatureSighted','ChildDefine',0),(1,0,5,20521,'Person','intDefaulter','ChildDefine',0),(1,0,5,20521,'PersonChild','intDefaulter','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','intDefaulter','ChildDefine',0),(1,0,5,20521,'Person','PlayerNumberClub.strJumperNum','ChildDefine',0),(1,0,5,20521,'PersonChild','PlayerNumberClub.strJumperNum','ChildDefine',0),(1,0,5,20521,'Person','intPhotoUseApproval','ChildDefine',0),(1,0,5,20521,'PersonChild','intPhotoUseApproval','ChildDefine',0),(1,0,5,20521,'PersonRegoForm','intPhotoUseApproval','ChildDefine',0),(1,0,5,20521,'Club','strName','ChildDefine',0),(1,0,5,20521,'ClubChild','strName','ChildDefine',0),(1,0,5,20521,'Club','intRecStatus','ChildDefine',0),(1,0,5,20521,'ClubChild','intRecStatus','ChildDefine',0),(1,0,5,20521,'Club','strAbbrev','ChildDefine',0),(1,0,5,20521,'ClubChild','strAbbrev','ChildDefine',0),(1,0,5,20521,'Club','strAddress1','ChildDefine',0),(1,0,5,20521,'ClubChild','strAddress1','ChildDefine',0),(1,0,5,20521,'Club','strAddress2','ChildDefine',0),(1,0,5,20521,'ClubChild','strAddress2','ChildDefine',0),(1,0,5,20521,'Club','strSuburb','ChildDefine',0),(1,0,5,20521,'ClubChild','strSuburb','ChildDefine',0),(1,0,5,20521,'Club','strPostalCode','ChildDefine',0),(1,0,5,20521,'ClubChild','strPostalCode','ChildDefine',0),(1,0,5,20521,'Club','strState','ChildDefine',0),(1,0,5,20521,'ClubChild','strState','ChildDefine',0),(1,0,5,20521,'Club','strCountry','ChildDefine',0),(1,0,5,20521,'ClubChild','strCountry','ChildDefine',0),(1,0,5,20521,'Club','strLGA','ChildDefine',0),(1,0,5,20521,'ClubChild','strLGA','ChildDefine',0),(1,0,5,20521,'Club','strPhone','ChildDefine',0),(1,0,5,20521,'ClubChild','strPhone','ChildDefine',0),(1,0,5,20521,'Club','strFax','ChildDefine',0),(1,0,5,20521,'ClubChild','strFax','ChildDefine',0),(1,0,5,20521,'Club','strEmail','ChildDefine',0),(1,0,5,20521,'ClubChild','strEmail','ChildDefine',0),(1,0,5,20521,'Club','strIncNo','ChildDefine',0),(1,0,5,20521,'ClubChild','strIncNo','ChildDefine',0),(1,0,5,20521,'Club','strBusinessNo','ChildDefine',0),(1,0,5,20521,'ClubChild','strBusinessNo','ChildDefine',0),(1,0,5,20521,'Club','strColours','ChildDefine',0),(1,0,5,20521,'ClubChild','strColours','ChildDefine',0),(1,0,5,20521,'Club','intClubTypeID','ChildDefine',0),(1,0,5,20521,'ClubChild','intClubTypeID','ChildDefine',0),(1,0,5,20521,'Club','intAgeTypeID','ChildDefine',0),(1,0,5,20521,'ClubChild','intAgeTypeID','ChildDefine',0),(1,0,5,20521,'Club','intClubCategoryID','ChildDefine',0),(1,0,5,20521,'ClubChild','intClubCategoryID','ChildDefine',0),(1,0,5,20521,'Club','strNotes','ChildDefine',0),(1,0,5,20521,'ClubChild','strNotes','ChildDefine',0),(1,0,5,20521,'Club','Username','ChildDefine',0),(1,0,5,20521,'ClubChild','Username','ChildDefine',0),(1,0,5,20521,'Club','strClubCustomStr1','ChildDefine',0),(1,0,5,20521,'ClubChild','strClubCustomStr1','ChildDefine',0),(1,0,5,20521,'Club','strClubCustomStr2','ChildDefine',0),(1,0,5,20521,'ClubChild','strClubCustomStr2','ChildDefine',0),(1,0,5,20521,'Club','strClubCustomStr3','ChildDefine',0),(1,0,5,20521,'ClubChild','strClubCustomStr3','ChildDefine',0),(1,0,5,20521,'Club','strClubCustomStr4','ChildDefine',0),(1,0,5,20521,'ClubChild','strClubCustomStr4','ChildDefine',0),(1,0,5,20521,'Club','strClubCustomStr5','ChildDefine',0),(1,0,5,20521,'ClubChild','strClubCustomStr5','ChildDefine',0),(1,0,5,20521,'Club','strClubCustomStr6','ChildDefine',0),(1,0,5,20521,'ClubChild','strClubCustomStr6','ChildDefine',0),(1,0,5,20521,'Club','strClubCustomStr7','ChildDefine',0),(1,0,5,20521,'ClubChild','strClubCustomStr7','ChildDefine',0),(1,0,5,20521,'Club','strClubCustomStr8','ChildDefine',0),(1,0,5,20521,'ClubChild','strClubCustomStr8','ChildDefine',0),(1,0,5,20521,'Club','strClubCustomStr9','ChildDefine',0),(1,0,5,20521,'ClubChild','strClubCustomStr9','ChildDefine',0),(1,0,5,20521,'Club','strClubCustomStr10','ChildDefine',0),(1,0,5,20521,'ClubChild','strClubCustomStr10','ChildDefine',0),(1,0,5,20521,'Club','strClubCustomStr11','ChildDefine',0),(1,0,5,20521,'ClubChild','strClubCustomStr11','ChildDefine',0),(1,0,5,20521,'Club','strClubCustomStr12','ChildDefine',0),(1,0,5,20521,'ClubChild','strClubCustomStr12','ChildDefine',0),(1,0,5,20521,'Club','strClubCustomStr13','ChildDefine',0),(1,0,5,20521,'ClubChild','strClubCustomStr13','ChildDefine',0),(1,0,5,20521,'Club','strClubCustomStr14','ChildDefine',0),(1,0,5,20521,'ClubChild','strClubCustomStr14','ChildDefine',0),(1,0,5,20521,'Club','strClubCustomStr15','ChildDefine',0),(1,0,5,20521,'ClubChild','strClubCustomStr15','ChildDefine',0),(1,0,5,20521,'Club','dblClubCustomDbl1','ChildDefine',0),(1,0,5,20521,'ClubChild','dblClubCustomDbl1','ChildDefine',0),(1,0,5,20521,'Club','dblClubCustomDbl2','ChildDefine',0),(1,0,5,20521,'ClubChild','dblClubCustomDbl2','ChildDefine',0),(1,0,5,20521,'Club','dblClubCustomDbl3','ChildDefine',0),(1,0,5,20521,'ClubChild','dblClubCustomDbl3','ChildDefine',0),(1,0,5,20521,'Club','dblClubCustomDbl4','ChildDefine',0),(1,0,5,20521,'ClubChild','dblClubCustomDbl4','ChildDefine',0),(1,0,5,20521,'Club','dblClubCustomDbl5','ChildDefine',0),(1,0,5,20521,'ClubChild','dblClubCustomDbl5','ChildDefine',0),(1,0,5,20521,'Club','dblClubCustomDbl6','ChildDefine',0),(1,0,5,20521,'ClubChild','dblClubCustomDbl6','ChildDefine',0),(1,0,5,20521,'Club','dblClubCustomDbl7','ChildDefine',0),(1,0,5,20521,'ClubChild','dblClubCustomDbl7','ChildDefine',0),(1,0,5,20521,'Club','dblClubCustomDbl8','ChildDefine',0),(1,0,5,20521,'ClubChild','dblClubCustomDbl8','ChildDefine',0),(1,0,5,20521,'Club','dblClubCustomDbl9','ChildDefine',0),(1,0,5,20521,'ClubChild','dblClubCustomDbl9','ChildDefine',0),(1,0,5,20521,'Club','dblClubCustomDbl10','ChildDefine',0),(1,0,5,20521,'ClubChild','dblClubCustomDbl10','ChildDefine',0),(1,0,5,20521,'Club','dtClubCustomDt1','ChildDefine',0),(1,0,5,20521,'ClubChild','dtClubCustomDt1','ChildDefine',0),(1,0,5,20521,'Club','dtClubCustomDt2','ChildDefine',0),(1,0,5,20521,'ClubChild','dtClubCustomDt2','ChildDefine',0),(1,0,5,20521,'Club','dtClubCustomDt3','ChildDefine',0),(1,0,5,20521,'ClubChild','dtClubCustomDt3','ChildDefine',0),(1,0,5,20521,'Club','dtClubCustomDt4','ChildDefine',0),(1,0,5,20521,'ClubChild','dtClubCustomDt4','ChildDefine',0),(1,0,5,20521,'Club','dtClubCustomDt5','ChildDefine',0),(1,0,5,20521,'ClubChild','dtClubCustomDt5','ChildDefine',0),(1,0,5,20521,'Club','intClubCustomLU1','ChildDefine',0),(1,0,5,20521,'ClubChild','intClubCustomLU1','ChildDefine',0),(1,0,5,20521,'Club','intClubCustomLU2','ChildDefine',0),(1,0,5,20521,'ClubChild','intClubCustomLU2','ChildDefine',0),(1,0,5,20521,'Club','intClubCustomLU3','ChildDefine',0),(1,0,5,20521,'ClubChild','intClubCustomLU3','ChildDefine',0),(1,0,5,20521,'Club','intClubCustomLU4','ChildDefine',0),(1,0,5,20521,'ClubChild','intClubCustomLU4','ChildDefine',0),(1,0,5,20521,'Club','intClubCustomLU5','ChildDefine',0),(1,0,5,20521,'ClubChild','intClubCustomLU5','ChildDefine',0),(1,0,5,20521,'Club','intClubCustomLU6','ChildDefine',0),(1,0,5,20521,'ClubChild','intClubCustomLU6','ChildDefine',0),(1,0,5,20521,'Club','intClubCustomLU7','ChildDefine',0),(1,0,5,20521,'ClubChild','intClubCustomLU7','ChildDefine',0),(1,0,5,20521,'Club','intClubCustomLU8','ChildDefine',0),(1,0,5,20521,'ClubChild','intClubCustomLU8','ChildDefine',0),(1,0,5,20521,'Club','intClubCustomLU9','ChildDefine',0),(1,0,5,20521,'ClubChild','intClubCustomLU9','ChildDefine',0),(1,0,5,20521,'Club','intClubCustomLU10','ChildDefine',0),(1,0,5,20521,'ClubChild','intClubCustomLU10','ChildDefine',0),(1,0,5,20521,'Club','intClubCustomBool1','ChildDefine',0),(1,0,5,20521,'ClubChild','intClubCustomBool1','ChildDefine',0),(1,0,5,20521,'Club','intClubCustomBool2','ChildDefine',0),(1,0,5,20521,'ClubChild','intClubCustomBool2','ChildDefine',0),(1,0,5,20521,'Club','intClubCustomBool3','ChildDefine',0),(1,0,5,20521,'ClubChild','intClubCustomBool3','ChildDefine',0),(1,0,5,20521,'Club','intClubCustomBool4','ChildDefine',0),(1,0,5,20521,'ClubChild','intClubCustomBool4','ChildDefine',0),(1,0,5,20521,'Club','intClubCustomBool5','ChildDefine',0),(1,0,5,20521,'ClubChild','intClubCustomBool5','ChildDefine',0),(1,0,100,1,'ClubChild','intFacilityTypeID','Editable',0),(1,0,100,1,'ClubChild','dtTo','Editable',0),(1,0,100,1,'Club','strFax','Editable',0),(1,0,100,1,'Person','intNatCustomLU5','Compulsory',0),(1,0,100,1,'PersonRegoForm','intNatCustomLU2','Editable',0),(1,0,100,1,'PersonChild','strOtherPersonIdentifierDesc','ChildDefine',0),(1,0,100,1,'PersonRegoForm','strOtherPersonIdentifierDesc','ChildDefine',0),(1,0,100,1,'Person','intOtherPersonIdentifierTypeID','Compulsory',0),(1,0,100,1,'Person','strBirthCert','ChildDefine',0),(1,0,100,1,'PersonChild','strBirthCert','ChildDefine',0),(1,0,100,1,'PersonRegoForm','strBirthCert','ChildDefine',0),(1,0,100,1,'Person','strBirthCertCountry','ChildDefine',0),(1,0,100,1,'PersonChild','strBirthCertCountry','ChildDefine',0),(1,0,100,1,'PersonRegoForm','strBirthCertCountry','ChildDefine',0),(1,0,100,1,'PersonChild','intDeceased','ChildDefine',0),(1,0,100,1,'PersonRegoForm','intDeceased','ChildDefine',0),(1,0,100,1,'Person','intEthnicityID','Editable',0),(1,0,100,1,'PersonChild','intEthnicityID','Editable',0),(1,0,100,1,'ClubChild','strEntityType','Compulsory',0),(1,0,100,1,'Club','strMAID','Editable',0),(1,0,100,1,'Club','strEntityType','Compulsory',0),(1,0,100,5,'Person','dtDeath','Editable',0),(1,0,100,5,'PersonChild','dtDeath','Editable',0),(1,0,100,5,'PersonRegoForm','dtDeath','Editable',0),(1,0,100,1,'PersonRegoForm','intNatCustomLU5','Compulsory',0),(1,0,100,5,'Person','dtSuspendedUntil','Editable',0),(1,0,100,5,'PersonChild','dtSuspendedUntil','Editable',0),(1,0,100,5,'PersonRegoForm','dtSuspendedUntil','Editable',0),(1,0,3,773,'PersonRegoForm','strNationalNum','ReadOnly',0),(1,0,3,773,'Person','strNationalNum','ReadOnly',0),(1,0,100,1,'Club','dtTo','Editable',0),(1,0,100,1,'ClubChild','strEmail','Editable',0),(1,0,100,1,'Club','strPhone','Editable',0),(1,0,100,1,'ClubChild','strPhone','Editable',0),(1,0,3,773,'PersonChild','strNationalNum','ReadOnly',0),(1,0,100,1,'Club','strLegalID','Editable',0),(1,0,100,1,'PersonRegoForm','strOtherPersonIdentifierIssueCountry','ChildDefine',0),(1,0,100,1,'Person','dtOtherPersonIdentifierValidDateFrom','ChildDefine',0),(1,0,100,1,'PersonChild','dtOtherPersonIdentifierValidDateFrom','ChildDefine',0),(1,0,100,1,'PersonRegoForm','dtBirthCertValidityDateFrom','ChildDefine',0),(1,0,100,1,'Person','dtBirthCertValidityDateTo','ChildDefine',0),(1,0,100,1,'PersonChild','dtBirthCertValidityDateTo','ChildDefine',0),(1,0,100,1,'PersonRegoForm','dtBirthCertValidityDateTo','ChildDefine',0),(1,0,100,1,'Person','strBirthCertDesc','ChildDefine',0),(1,0,100,1,'PersonChild','strBirthCertDesc','ChildDefine',0),(1,0,100,1,'PersonRegoForm','strBirthCertDesc','ChildDefine',0),(1,0,100,1,'Person','strOtherPersonIdentifier','Compulsory',0),(1,0,100,1,'PersonChild','strOtherPersonIdentifier','Compulsory',0),(1,0,100,1,'Person','dtBirthCertValidityDateFrom','ChildDefine',0),(1,0,100,1,'PersonChild','dtBirthCertValidityDateFrom','ChildDefine',0),(1,0,100,1,'PersonRegoForm','strP2Phone','ChildDefine',0),(1,0,100,1,'ClubChild','dtFrom','Editable',0),(1,0,100,1,'Club','dtFrom','Editable',0),(1,0,100,1,'ClubChild','strPostalCode','Editable',0),(1,0,100,1,'Club','strContactISOCountry','Compulsory',0),(1,0,100,1,'ClubChild','strContactISOCountry','Compulsory',0),(1,0,100,1,'Club','strWebURL','Editable',0),(1,0,100,1,'ClubChild','strWebURL','Editable',0),(1,0,100,1,'Club','strEmail','Editable',0),(1,0,100,1,'Club','strGender','Editable',0),(1,0,100,1,'ClubChild','strGender','Editable',0),(1,0,100,1,'Person','strOtherPersonIdentifierIssueCountry','ChildDefine',0),(1,0,100,1,'PersonChild','strOtherPersonIdentifierIssueCountry','ChildDefine',0),(1,0,100,1,'Person','strISONationality','Editable',0),(1,0,100,1,'PersonChild','strISONationality','Compulsory',0),(1,0,100,1,'PersonRegoForm','strISONationality','AddOnlyCompulsory',0),(1,0,100,1,'Person','strISOCountryOfBirth','Editable',0),(1,0,100,1,'PersonChild','strISOCountryOfBirth','AddOnlyCompulsory',0),(1,0,100,1,'ClubChild','strContact','Editable',0),(1,0,100,1,'Club','strAssocNature','Editable',0),(1,0,100,1,'ClubChild','strAssocNature','Editable',0),(1,0,100,1,'Club','strMANotes','Editable',0),(1,0,100,1,'PersonRegoForm','dtOtherPersonIdentifierValidDateFrom','ChildDefine',0),(1,0,100,1,'Person','dtOtherPersonIdentifierValidDateTo','ChildDefine',0),(1,0,100,1,'PersonChild','dtOtherPersonIdentifierValidDateTo','ChildDefine',0),(1,0,100,1,'PersonRegoForm','dtOtherPersonIdentifierValidDateTo','ChildDefine',0),(1,0,100,1,'Person','strOtherPersonIdentifierDesc','ChildDefine',0),(1,0,100,1,'Person','strNationalNum','ReadOnly',0),(1,0,100,1,'PersonChild','strNationalNum','ReadOnly',0),(1,0,100,1,'PersonRegoForm','strNationalNum','ReadOnly',0),(1,0,100,1,'Person','strStatus','Editable',0),(1,0,100,1,'PersonChild','strStatus','ReadOnly',0),(1,0,100,1,'PersonRegoForm','strStatus','ReadOnly',0),(1,0,100,1,'Person','strSalutation','Editable',0),(1,0,100,1,'PersonChild','strSalutation','Editable',0),(1,0,100,1,'PersonRegoForm','strSalutation','Editable',0),(1,0,100,1,'Person','strPreferredName','ChildDefine',0),(1,0,100,1,'PersonChild','strPreferredName','ChildDefine',0),(1,0,100,1,'PersonRegoForm','strPreferredName','ChildDefine',0),(1,0,100,1,'Person','intLocalLanguage','Editable',0),(1,0,100,1,'PersonChild','intLocalLanguage','AddOnlyCompulsory',0),(1,0,100,1,'PersonRegoForm','intLocalLanguage','AddOnlyCompulsory',0),(1,0,100,1,'Person','strLocalFirstname','Editable',0),(1,0,100,1,'PersonChild','strLocalFirstname','Editable',0),(1,0,100,1,'PersonRegoForm','strLocalFirstname','Editable',0),(1,0,100,1,'Person','strLocalSurname','Editable',0),(1,0,100,1,'PersonChild','strLocalSurname','Compulsory',0),(1,0,100,1,'PersonRegoForm','strLocalSurname','AddOnlyCompulsory',0),(1,0,100,1,'Person','strLatinFirstname','Editable',0),(1,0,100,1,'PersonChild','strLatinFirstname','Editable',0),(1,0,100,1,'PersonRegoForm','strLatinFirstname','Editable',0),(1,0,100,1,'Person','strLatinSurname','Editable',0),(1,0,100,1,'PersonChild','strLatinSurname','Editable',0),(1,0,100,1,'PersonRegoForm','strLatinSurname','Editable',0),(1,0,100,1,'Person','strMaidenName','Editable',0),(1,0,100,1,'PersonChild','strMaidenName','Editable',0),(1,0,100,1,'PersonRegoForm','strMaidenName','Editable',0),(1,0,100,1,'Person','dtDOB','Editable',0),(1,0,100,1,'PersonChild','dtDOB','AddOnlyCompulsory',0),(1,0,100,1,'PersonRegoForm','dtDOB','AddOnlyCompulsory',0),(1,0,100,1,'Person','strPlaceOfBirth','Editable',0),(1,0,100,1,'PersonChild','strPlaceOfBirth','AddOnlyCompulsory',0),(1,0,100,1,'PersonRegoForm','strPlaceOfBirth','AddOnlyCompulsory',0),(1,0,100,1,'Person','strMotherCountry','ChildDefine',0),(1,0,100,1,'PersonChild','strMotherCountry','ChildDefine',0),(1,0,100,1,'PersonRegoForm','strMotherCountry','ChildDefine',0),(1,0,100,1,'Person','strFatherCountry','ChildDefine',0),(1,0,100,1,'PersonChild','strFatherCountry','ChildDefine',0),(1,0,100,1,'PersonRegoForm','strFatherCountry','ChildDefine',0),(1,0,100,1,'Person','intGender','Editable',0),(1,0,100,1,'PersonChild','intGender','AddOnlyCompulsory',0),(1,0,100,1,'PersonRegoForm','intGender','AddOnlyCompulsory',0),(1,0,100,1,'Person','strAddress1','Compulsory',0),(1,0,100,1,'PersonChild','strAddress1','Compulsory',0),(1,0,100,1,'PersonRegoForm','strAddress1','Compulsory',0),(1,0,100,1,'Person','strAddress2','Editable',0),(1,0,100,1,'PersonChild','strAddress2','Editable',0),(1,0,100,1,'PersonRegoForm','strAddress2','Editable',0),(1,0,100,1,'Person','strSuburb','Compulsory',0),(1,0,100,1,'PersonChild','strSuburb','Compulsory',0),(1,0,100,1,'PersonRegoForm','strSuburb','Compulsory',0),(1,0,100,1,'Person','strState','Editable',0),(1,0,100,1,'PersonChild','strState','Editable',0),(1,0,100,1,'PersonRegoForm','strState','Editable',0),(1,0,100,1,'Person','strPostalCode','Editable',0),(1,0,100,1,'PersonChild','strPostalCode','Editable',0),(1,0,100,1,'PersonRegoForm','strPostalCode','Editable',0),(1,0,100,1,'Person','strISOCountry','Editable',0),(1,0,100,1,'PersonChild','strISOCountry','Editable',0),(1,0,100,1,'PersonRegoForm','strISOCountry','Editable',0),(1,0,100,1,'Person','strPhoneHome','Compulsory',0),(1,0,100,1,'PersonChild','strPhoneHome','Compulsory',0),(1,0,100,1,'PersonRegoForm','strPhoneHome','Compulsory',0),(1,0,100,1,'Person','strPhoneWork','Editable',0),(1,0,100,1,'PersonChild','strPhoneWork','Editable',0),(1,0,100,1,'PersonRegoForm','strPhoneWork','Editable',0),(1,0,100,1,'Person','strPhoneMobile','Editable',0),(1,0,100,1,'PersonChild','strPhoneMobile','Editable',0),(1,0,100,1,'PersonRegoForm','strPhoneMobile','Editable',0),(1,0,3,773,'Person','strStatus','ReadOnly',0),(1,0,3,773,'PersonChild','strStatus','ReadOnly',0),(1,0,3,773,'PersonRegoForm','strStatus','ReadOnly',0),(1,0,3,773,'Person','strSalutation','Editable',0),(1,0,3,773,'PersonChild','strSalutation','Editable',0),(1,0,3,773,'PersonRegoForm','strSalutation','Editable',0),(1,0,3,773,'Person','strPreferredName','ChildDefine',0),(1,0,3,773,'PersonChild','strPreferredName','ChildDefine',0),(1,0,3,773,'PersonRegoForm','strPreferredName','ChildDefine',0),(1,0,3,773,'Person','intLocalLanguage','Editable',0),(1,0,3,773,'PersonChild','intLocalLanguage','Editable',0),(1,0,3,773,'PersonRegoForm','intLocalLanguage','Editable',0),(1,0,3,773,'Person','strLocalFirstname','Editable',0),(1,0,3,773,'PersonChild','strLocalFirstname','Editable',0),(1,0,3,773,'PersonRegoForm','strLocalFirstname','Editable',0),(1,0,3,773,'Person','strLocalSurname','Editable',0),(1,0,3,773,'PersonChild','strLocalSurname','Editable',0),(1,0,3,773,'PersonRegoForm','strLocalSurname','Editable',0),(1,0,3,773,'Person','strLatinFirstname','ChildDefine',0),(1,0,3,773,'PersonChild','strLatinFirstname','ChildDefine',0),(1,0,3,773,'PersonRegoForm','strLatinFirstname','ChildDefine',0),(1,0,3,773,'Person','strLatinSurname','ChildDefine',0),(1,0,3,773,'PersonChild','strLatinSurname','ChildDefine',0),(1,0,3,773,'PersonRegoForm','strLatinSurname','ChildDefine',0),(1,0,3,773,'Person','strMaidenName','Hidden',0),(1,0,3,773,'PersonChild','strMaidenName','Hidden',0),(1,0,3,773,'PersonRegoForm','strMaidenName','Hidden',0),(1,0,3,773,'Person','dtDOB','Compulsory',0),(1,0,3,773,'PersonChild','dtDOB','Compulsory',0),(1,0,3,773,'PersonRegoForm','dtDOB','Compulsory',0),(1,0,3,773,'Person','strPlaceOfBirth','Compulsory',0),(1,0,3,773,'PersonChild','strPlaceOfBirth','Compulsory',0),(1,0,3,773,'PersonRegoForm','strPlaceOfBirth','Compulsory',0),(1,0,3,773,'Person','strMotherCountry','ChildDefine',0),(1,0,3,773,'PersonChild','strMotherCountry','ChildDefine',0),(1,0,3,773,'PersonRegoForm','strMotherCountry','ChildDefine',0),(1,0,3,773,'Person','strFatherCountry','ChildDefine',0),(1,0,3,773,'PersonChild','strFatherCountry','ChildDefine',0),(1,0,3,773,'PersonRegoForm','strFatherCountry','ChildDefine',0),(1,0,3,773,'Person','intGender','Editable',0),(1,0,3,773,'PersonChild','intGender','Editable',0),(1,0,3,773,'PersonRegoForm','intGender','Editable',0),(1,0,3,773,'Person','strAddress1','Compulsory',0),(1,0,3,773,'PersonChild','strAddress1','Compulsory',0),(1,0,3,773,'PersonRegoForm','strAddress1','Compulsory',0),(1,0,3,773,'Person','strAddress2','Editable',0),(1,0,3,773,'PersonChild','strAddress2','Editable',0),(1,0,3,773,'PersonRegoForm','strAddress2','Editable',0),(1,0,3,773,'Person','strSuburb','Compulsory',0),(1,0,3,773,'PersonChild','strSuburb','Compulsory',0),(1,0,3,773,'PersonRegoForm','strSuburb','Compulsory',0),(1,0,3,773,'Person','strState','Editable',0),(1,0,3,773,'PersonChild','strState','Editable',0),(1,0,3,773,'PersonRegoForm','strState','Editable',0),(1,0,3,773,'Person','strPostalCode','Editable',0),(1,0,3,773,'PersonChild','strPostalCode','Editable',0),(1,0,3,773,'PersonRegoForm','strPostalCode','Editable',0),(1,0,3,773,'Person','strCountry','Compulsory',0),(1,0,3,773,'PersonChild','strCountry','Compulsory',0),(1,0,3,773,'PersonRegoForm','strCountry','Compulsory',0),(1,0,3,773,'Person','strPhoneHome','Editable',0),(1,0,3,773,'PersonChild','strPhoneHome','Editable',0),(1,0,3,773,'PersonRegoForm','strPhoneHome','Editable',0),(1,0,3,773,'Person','strPhoneWork','Editable',0),(1,0,3,773,'PersonChild','strPhoneWork','Editable',0),(1,0,3,773,'PersonRegoForm','strPhoneWork','Editable',0),(1,0,3,773,'Person','strPhoneMobile','Editable',0),(1,0,3,773,'PersonChild','strPhoneMobile','Editable',0),(1,0,3,773,'PersonRegoForm','strPhoneMobile','Editable',0),(1,0,3,773,'Person','strPager','ChildDefine',0),(1,0,3,773,'PersonChild','strPager','ChildDefine',0),(1,0,3,773,'PersonRegoForm','strPager','ChildDefine',0),(1,0,3,773,'Person','strFax','ChildDefine',0),(1,0,3,773,'PersonChild','strFax','ChildDefine',0),(1,0,3,773,'PersonRegoForm','strFax','ChildDefine',0),(1,0,3,773,'Person','strEmail','Editable',0),(1,0,3,773,'PersonChild','strEmail','Editable',0),(1,0,3,773,'PersonRegoForm','strEmail','Editable',0),(1,0,3,773,'Person','strEmail2','ChildDefine',0),(1,0,3,773,'PersonChild','strEmail2','ChildDefine',0),(1,0,3,773,'PersonRegoForm','strEmail2','ChildDefine',0),(1,0,3,773,'Person','intDeceased','ChildDefine',0),(1,0,3,773,'PersonChild','intDeceased','ChildDefine',0),(1,0,3,773,'PersonRegoForm','intDeceased','ChildDefine',0),(1,0,3,773,'Person','intEthnicityID','ChildDefine',0),(1,0,3,773,'PersonChild','intEthnicityID','ChildDefine',0),(1,0,3,773,'PersonRegoForm','intEthnicityID','ChildDefine',0),(1,0,3,773,'Person','strPreferredLang','ChildDefine',0),(1,0,3,773,'PersonChild','strPreferredLang','ChildDefine',0),(1,0,3,773,'PersonRegoForm','strPreferredLang','ChildDefine',0),(1,0,3,773,'Person','strPassportIssueCountry','Editable',0),(1,0,3,773,'PersonChild','strPassportIssueCountry','Editable',0),(1,0,3,773,'PersonRegoForm','strPassportIssueCountry','Editable',0),(1,0,3,773,'Person','strPassportNationality','Editable',0),(1,0,3,773,'PersonChild','strPassportNationality','Editable',0),(1,0,3,773,'PersonRegoForm','strPassportNationality','Editable',0),(1,0,3,773,'Person','dtPassportExpiry','Editable',0),(1,0,3,773,'PersonChild','dtPassportExpiry','Editable',0),(1,0,3,773,'PersonRegoForm','dtPassportExpiry','Editable',0),(1,0,3,773,'Person','dtPoliceCheck','ChildDefine',0),(1,0,3,773,'PersonChild','dtPoliceCheck','ChildDefine',0),(1,0,3,773,'PersonRegoForm','dtPoliceCheck','ChildDefine',0),(1,0,3,773,'Person','dtPoliceCheckExp','ChildDefine',0),(1,0,3,773,'PersonChild','dtPoliceCheckExp','ChildDefine',0),(1,0,3,773,'PersonRegoForm','dtPoliceCheckExp','ChildDefine',0),(1,0,3,773,'Person','strPoliceCheckRef','ChildDefine',0),(1,0,3,773,'PersonChild','strPoliceCheckRef','ChildDefine',0),(1,0,3,773,'PersonRegoForm','strPoliceCheckRef','ChildDefine',0),(1,0,3,773,'Person','strEmergContName','Editable',0),(1,0,3,773,'PersonChild','strEmergContName','Editable',0),(1,0,3,773,'PersonRegoForm','strEmergContName','Editable',0),(1,0,3,773,'Person','strEmergContNo','Editable',0),(1,0,3,773,'PersonChild','strEmergContNo','Editable',0),(1,0,3,773,'PersonRegoForm','strEmergContNo','Editable',0),(1,0,3,773,'Person','strEmergContNo2','ChildDefine',0),(1,0,3,773,'PersonChild','strEmergContNo2','ChildDefine',0),(1,0,3,773,'PersonRegoForm','strEmergContNo2','ChildDefine',0),(1,0,3,773,'Person','strEmergContRel','Editable',0),(1,0,3,773,'PersonChild','strEmergContRel','Editable',0),(1,0,3,773,'PersonRegoForm','strEmergContRel','Editable',0),(1,0,3,773,'Person','strP1Salutation','ChildDefine',0),(1,0,3,773,'PersonChild','strP1Salutation','ChildDefine',0),(1,0,3,773,'PersonRegoForm','strP1Salutation','ChildDefine',0),(1,0,3,773,'Person','strP1FName','ChildDefine',0),(1,0,3,773,'PersonChild','strP1FName','ChildDefine',0),(1,0,3,773,'PersonRegoForm','strP1FName','ChildDefine',0),(1,0,3,773,'Person','strP1SName','ChildDefine',0),(1,0,3,773,'PersonChild','strP1SName','ChildDefine',0),(1,0,3,773,'PersonRegoForm','strP1SName','ChildDefine',0),(1,0,3,773,'Person','intP1Gender','ChildDefine',0),(1,0,3,773,'PersonChild','intP1Gender','ChildDefine',0),(1,0,3,773,'PersonRegoForm','intP1Gender','ChildDefine',0),(1,0,3,773,'Person','strP1Phone','ChildDefine',0),(1,0,3,773,'PersonChild','strP1Phone','ChildDefine',0),(1,0,3,773,'PersonRegoForm','strP1Phone','ChildDefine',0),(1,0,3,773,'Person','strP1Phone2','ChildDefine',0),(1,0,3,773,'PersonChild','strP1Phone2','ChildDefine',0),(1,0,3,773,'PersonRegoForm','strP1Phone2','ChildDefine',0),(1,0,3,773,'Person','strP1PhoneMobile','ChildDefine',0),(1,0,3,773,'PersonChild','strP1PhoneMobile','ChildDefine',0),(1,0,3,773,'PersonRegoForm','strP1PhoneMobile','ChildDefine',0),(1,0,3,773,'Person','strP1Email','ChildDefine',0),(1,0,3,773,'PersonChild','strP1Email','ChildDefine',0),(1,0,3,773,'PersonRegoForm','strP1Email','ChildDefine',0),(1,0,3,773,'Person','strP1Email2','ChildDefine',0),(1,0,3,773,'PersonChild','strP1Email2','ChildDefine',0),(1,0,3,773,'PersonRegoForm','strP1Email2','ChildDefine',0),(1,0,3,773,'Person','strP2Salutation','ChildDefine',0),(1,0,3,773,'PersonChild','strP2Salutation','ChildDefine',0),(1,0,3,773,'PersonRegoForm','strP2Salutation','ChildDefine',0),(1,0,3,773,'Person','strP2FName','ChildDefine',0),(1,0,3,773,'PersonChild','strP2FName','ChildDefine',0),(1,0,3,773,'PersonRegoForm','strP2FName','ChildDefine',0),(1,0,3,773,'Person','strP2SName','ChildDefine',0),(1,0,3,773,'PersonChild','strP2SName','ChildDefine',0),(1,0,3,773,'PersonRegoForm','strP2SName','ChildDefine',0),(1,0,3,773,'Person','intP2Gender','ChildDefine',0),(1,0,3,773,'PersonChild','intP2Gender','ChildDefine',0),(1,0,3,773,'PersonRegoForm','intP2Gender','ChildDefine',0),(1,0,3,773,'Person','strP2Phone','ChildDefine',0),(1,0,3,773,'PersonChild','strP2Phone','ChildDefine',0),(1,0,3,773,'PersonRegoForm','strP2Phone','ChildDefine',0),(1,0,3,773,'Person','strP2Phone2','ChildDefine',0),(1,0,3,773,'PersonChild','strP2Phone2','ChildDefine',0),(1,0,3,773,'PersonRegoForm','strP2Phone2','ChildDefine',0),(1,0,3,773,'Person','strP2PhoneMobile','ChildDefine',0),(1,0,3,773,'PersonChild','strP2PhoneMobile','ChildDefine',0),(1,0,3,773,'PersonRegoForm','strP2PhoneMobile','ChildDefine',0),(1,0,3,773,'Person','strP2Email','ChildDefine',0),(1,0,3,773,'PersonChild','strP2Email','ChildDefine',0),(1,0,3,773,'PersonRegoForm','strP2Email','ChildDefine',0),(1,0,3,773,'Person','strP2Email2','ChildDefine',0),(1,0,3,773,'PersonChild','strP2Email2','ChildDefine',0),(1,0,3,773,'PersonRegoForm','strP2Email2','ChildDefine',0),(1,0,3,773,'Person','strNotes','Editable',0),(1,0,3,773,'PersonChild','strNotes','Editable',0),(1,0,3,773,'PersonRegoForm','strNotes','Editable',0),(1,0,3,773,'Person','strISONationality','Editable',0),(1,0,3,773,'PersonChild','strISONationality','Editable',0),(1,0,3,773,'PersonRegoForm','strISONationality','Editable',0),(1,0,3,773,'Person','strISOCountryOfBirth','Editable',0),(1,0,3,773,'PersonChild','strISOCountryOfBirth','Editable',0),(1,0,3,773,'PersonRegoForm','strISOCountryOfBirth','ChildDefine',0),(1,0,3,773,'Person','strRegionOfBirth','Compulsory',0),(1,0,3,773,'PersonChild','strRegionOfBirth','Compulsory',0),(1,0,3,773,'PersonRegoForm','strRegionOfBirth','Compulsory',0),(1,0,3,773,'Person','strBirthCert','ChildDefine',0),(1,0,3,773,'PersonChild','strBirthCert','ChildDefine',0),(1,0,3,773,'PersonRegoForm','strBirthCert','ChildDefine',0),(1,0,3,773,'Person','strBirthCertCountry','ChildDefine',0),(1,0,3,773,'PersonChild','strBirthCertCountry','ChildDefine',0),(1,0,3,773,'PersonRegoForm','strBirthCertCountry','ChildDefine',0),(1,0,3,773,'Person','dtBirthCertValidityDateFrom','ChildDefine',0),(1,0,3,773,'PersonChild','dtBirthCertValidityDateFrom','ChildDefine',0),(1,0,3,773,'PersonRegoForm','dtBirthCertValidityDateFrom','ChildDefine',0),(1,0,3,773,'Person','dtBirthCertValidityDateTo','ChildDefine',0),(1,0,3,773,'PersonChild','dtBirthCertValidityDateTo','ChildDefine',0),(1,0,3,773,'PersonRegoForm','dtBirthCertValidityDateTo','ChildDefine',0),(1,0,3,773,'Person','strBirthCertDesc','ChildDefine',0),(1,0,3,773,'PersonChild','strBirthCertDesc','ChildDefine',0),(1,0,3,773,'PersonRegoForm','strBirthCertDesc','ChildDefine',0),(1,0,3,773,'Person','strOtherPersonIdentifier','Editable',0),(1,0,3,773,'PersonChild','strOtherPersonIdentifier','Editable',0),(1,0,3,773,'PersonRegoForm','strOtherPersonIdentifier','Editable',0),(1,0,3,773,'Person','strOtherPersonIdentifierIssueCountry','ChildDefine',0),(1,0,3,773,'PersonChild','strOtherPersonIdentifierIssueCountry','ChildDefine',0),(1,0,3,773,'PersonRegoForm','strOtherPersonIdentifierIssueCountry','ChildDefine',0),(1,0,3,773,'Person','dtOtherPersonIdentifierValidDateFrom','ChildDefine',0),(1,0,3,773,'PersonChild','dtOtherPersonIdentifierValidDateFrom','ChildDefine',0),(1,0,3,773,'PersonRegoForm','dtOtherPersonIdentifierValidDateFrom','ChildDefine',0),(1,0,3,773,'Person','dtOtherPersonIdentifierValidDateTo','ChildDefine',0),(1,0,3,773,'PersonChild','dtOtherPersonIdentifierValidDateTo','ChildDefine',0),(1,0,3,773,'PersonRegoForm','dtOtherPersonIdentifierValidDateTo','ChildDefine',0),(1,0,3,773,'Person','strOtherPersonIdentifierDesc','ChildDefine',0),(1,0,3,773,'PersonChild','strOtherPersonIdentifierDesc','ChildDefine',0),(1,0,3,773,'PersonRegoForm','strOtherPersonIdentifierDesc','ChildDefine',0),(1,0,3,773,'Person','intMinorMoveOtherThanFootball','Editable',0),(1,0,3,773,'PersonChild','intMinorMoveOtherThanFootball','Editable',0),(1,0,3,773,'PersonRegoForm','intMinorMoveOtherThanFootball','Editable',0),(1,0,3,773,'Person','intMinorDistance','Editable',0),(1,0,3,773,'PersonChild','intMinorDistance','Editable',0),(1,0,3,773,'PersonRegoForm','intMinorDistance','Editable',0),(1,0,3,773,'Person','intMinorEU','Editable',0),(1,0,3,773,'PersonChild','intMinorEU','Editable',0),(1,0,3,773,'PersonRegoForm','intMinorEU','Editable',0),(1,0,3,773,'Person','intMinorNone','Editable',0),(1,0,3,773,'PersonChild','intMinorNone','Editable',0),(1,0,3,773,'PersonRegoForm','intMinorNone','Editable',0),(1,0,3,773,'Person','intNatCustomLU1','ChildDefine',0),(1,0,3,773,'PersonChild','intNatCustomLU1','ChildDefine',0),(1,0,3,773,'PersonRegoForm','intNatCustomLU1','ChildDefine',0),(1,0,3,773,'Person','intNatCustomLU2','Editable',0),(1,0,3,773,'PersonChild','intNatCustomLU2','Editable',0),(1,0,3,773,'PersonRegoForm','intNatCustomLU2','Editable',0),(1,0,3,773,'Person','intNatCustomLU3','Editable',0),(1,0,3,773,'PersonChild','intNatCustomLU3','Editable',0),(1,0,3,773,'PersonRegoForm','intNatCustomLU3','Editable',0),(1,0,3,773,'Person','intNatCustomLU4','ChildDefine',0),(1,0,3,773,'PersonChild','intNatCustomLU4','ChildDefine',0),(1,0,3,773,'PersonRegoForm','intNatCustomLU4','ChildDefine',0),(1,0,100,1,'Club','intNotifications','Editable',0),(1,0,100,1,'PersonRegoForm','intNatCustomLU4','ChildDefine',0),(1,0,100,1,'Person','intMinorProtection','Editable',0),(1,0,100,1,'PersonChild','intMinorProtection','Editable',0),(1,0,100,1,'PersonRegoForm','intMinorProtection','Editable',0),(1,0,100,1,'Person','intNatCustomLU1','ChildDefine',0),(1,0,100,1,'PersonChild','intOtherPersonIdentifierTypeID','Compulsory',0),(1,0,100,1,'PersonRegoForm','intOtherPersonIdentifierTypeID','Compulsory',0),(1,0,100,1,'PersonRegoForm','strP2Email2','ChildDefine',0),(1,0,100,1,'Person','strNotes','Editable',0),(1,0,100,1,'PersonChild','strNotes','Editable',0),(1,0,100,1,'PersonRegoForm','strP2Email','ChildDefine',0),(1,0,100,1,'Person','strP2Email2','ChildDefine',0),(1,0,100,1,'PersonChild','strP2Email2','ChildDefine',0),(1,0,100,1,'PersonChild','strP1Phone','ChildDefine',0),(1,0,100,1,'PersonRegoForm','strP1Phone','ChildDefine',0),(1,0,100,1,'Person','strP1Phone2','ChildDefine',0),(1,0,100,1,'PersonChild','strP1Phone2','ChildDefine',0),(1,0,100,1,'PersonRegoForm','strP1Phone2','ChildDefine',0),(1,0,100,1,'Person','strP1PhoneMobile','ChildDefine',0),(1,0,100,1,'PersonChild','strP1PhoneMobile','ChildDefine',0),(1,0,100,1,'PersonRegoForm','strP1PhoneMobile','ChildDefine',0),(1,0,100,1,'Person','strP1Email','ChildDefine',0),(1,0,100,1,'PersonChild','strP1Email','ChildDefine',0),(1,0,100,1,'PersonRegoForm','strP1Email','ChildDefine',0),(1,0,100,1,'Person','strP1Email2','ChildDefine',0),(1,0,100,1,'PersonChild','strP1Email2','ChildDefine',0),(1,0,100,1,'PersonRegoForm','strP1Email2','ChildDefine',0),(1,0,100,1,'Person','strP2Salutation','ChildDefine',0),(1,0,100,1,'PersonChild','strP2Salutation','ChildDefine',0),(1,0,100,1,'PersonRegoForm','strP2Salutation','ChildDefine',0),(1,0,100,1,'Person','strP2FName','ChildDefine',0),(1,0,100,1,'PersonChild','strP2FName','ChildDefine',0),(1,0,100,1,'PersonRegoForm','strP2FName','ChildDefine',0),(1,0,100,1,'Person','strP2SName','ChildDefine',0),(1,0,100,1,'PersonChild','strP2SName','ChildDefine',0),(1,0,100,1,'PersonRegoForm','strP2SName','ChildDefine',0),(1,0,100,1,'Person','intP2Gender','ChildDefine',0),(1,0,100,1,'PersonChild','intP2Gender','ChildDefine',0),(1,0,100,1,'PersonRegoForm','intP2Gender','ChildDefine',0),(1,0,100,1,'Person','strP2Phone','ChildDefine',0),(1,0,100,1,'PersonChild','strP2Phone','ChildDefine',0),(1,0,100,1,'PersonRegoForm','intEthnicityID','Editable',0),(1,0,100,1,'Person','strPreferredLang','ChildDefine',0),(1,0,100,1,'PersonChild','strPreferredLang','ChildDefine',0),(1,0,100,1,'PersonRegoForm','strPreferredLang','ChildDefine',0),(1,0,100,1,'Person','strPassportIssueCountry','ChildDefine',0),(1,0,100,1,'PersonChild','strPassportIssueCountry','ChildDefine',0),(1,0,100,1,'PersonRegoForm','strPassportIssueCountry','ChildDefine',0),(1,0,100,1,'Person','strPassportNationality','ChildDefine',0),(1,0,100,1,'PersonChild','strPassportNationality','ChildDefine',0),(1,0,100,1,'PersonRegoForm','strPassportNationality','ChildDefine',0),(1,0,100,1,'Person','strPassportNo','ChildDefine',0),(1,0,100,1,'PersonChild','strPassportNo','ChildDefine',0),(1,0,100,1,'PersonRegoForm','strPassportNo','ChildDefine',0),(1,0,100,1,'Person','dtPassportExpiry','ChildDefine',0),(1,0,100,1,'PersonChild','dtPassportExpiry','ChildDefine',0),(1,0,100,1,'PersonRegoForm','dtPassportExpiry','ChildDefine',0),(1,0,100,1,'Person','dtPoliceCheck','ChildDefine',0),(1,0,100,1,'PersonChild','dtPoliceCheck','ChildDefine',0),(1,0,100,1,'PersonRegoForm','dtPoliceCheck','ChildDefine',0),(1,0,100,1,'ClubChild','strOrganisationLevel','Compulsory',0),(1,0,100,1,'ClubChild','strContactCity','Editable',0),(1,0,100,1,'Club','strState','Editable',0),(1,0,100,1,'ClubChild','strState','Editable',0),(1,0,100,1,'Club','strFIFAID','ReadOnly',0),(1,0,100,1,'ClubChild','strFIFAID','ReadOnly',0),(1,0,100,1,'Club','strLocalName','Compulsory',0),(1,0,100,1,'ClubChild','strLocalName','Compulsory',0),(1,0,100,1,'Club','strLocalShortName','Compulsory',0),(1,0,100,1,'ClubChild','strLocalShortName','Compulsory',0),(1,0,100,1,'Club','strLatinName','Editable',0),(1,0,100,1,'ClubChild','strLatinName','Editable',0),(1,0,100,1,'Club','strLatinShortName','Editable',0),(1,0,100,1,'ClubChild','strLatinShortName','Editable',0),(1,0,100,1,'Club','strStatus','Editable',0),(1,0,100,1,'ClubChild','strStatus','ReadOnly',0),(1,0,100,1,'Club','strCity','ChildDefine',0),(1,0,100,1,'ClubChild','strCity','ChildDefine',0),(1,0,100,1,'Club','strRegion','Editable',0);
/*!40000 ALTER TABLE `tblFieldPermissions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblGenerate`
--

DROP TABLE IF EXISTS `tblGenerate`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblGenerate` (
  `intGenerateID` int(11) NOT NULL AUTO_INCREMENT,
  `intRealmID` int(11) NOT NULL DEFAULT '0',
  `intSubRealmID` int(11) NOT NULL DEFAULT '0',
  `intEntityID` int(11) NOT NULL DEFAULT '0',
  `strGenType` varchar(30) NOT NULL DEFAULT '',
  `intLength` int(11) DEFAULT '5',
  `intMaxNum` int(11) DEFAULT '10000',
  `intCurrentNum` int(11) NOT NULL DEFAULT '100',
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `strFormat` varchar(250) NOT NULL DEFAULT '',
  `strValues` text NOT NULL,
  PRIMARY KEY (`intGenerateID`),
  KEY `index_type` (`intRealmID`,`strGenType`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblGenerate`
--

LOCK TABLES `tblGenerate` WRITE;
/*!40000 ALTER TABLE `tblGenerate` DISABLE KEYS */;
INSERT INTO `tblGenerate` VALUES (1,1,0,0,'PERSON',6,999999,100000,'2015-01-19 07:58:53','%SEQUENCE%GENDER%YEAR','GENDER=$params->{\"gender\"} == 2 ? \"F\" : \"M\"#YEAR=substr($params->{\"dob\"},2,2)'),(2,1,0,0,'ENTITY',4,5000,0,'2015-01-19 00:01:44','%SEQUENCE%ORGTYPE','ORGTYPE=uc(substr($params->{\"entityType\"},0,1))'),(3,1,0,0,'FACILITY',4,9999,5000,'2015-01-19 07:59:00','%SEQUENCE%ORGTYPE','ORGTYPE=uc(substr($params->{\"entityType\"},0,1))');
/*!40000 ALTER TABLE `tblGenerate` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblGlobalAuth`
--

DROP TABLE IF EXISTS `tblGlobalAuth`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblGlobalAuth` (
  `intUserID` int(11) NOT NULL,
  PRIMARY KEY (`intUserID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblGlobalAuth`
--

LOCK TABLES `tblGlobalAuth` WRITE;
/*!40000 ALTER TABLE `tblGlobalAuth` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblGlobalAuth` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblITCMessagesLog`
--

DROP TABLE IF EXISTS `tblITCMessagesLog`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblITCMessagesLog` (
  `intITCMessagesLog` int(11) NOT NULL AUTO_INCREMENT,
  `intEntityFromID` int(11) DEFAULT NULL,
  `intEntityToID` int(11) DEFAULT NULL,
  `strFirstname` varchar(50) DEFAULT NULL,
  `strSurname` varchar(100) DEFAULT NULL,
  `dtDOB` date DEFAULT NULL,
  `strNationality` varchar(50) DEFAULT NULL,
  `strPlayerID` varchar(20) DEFAULT NULL,
  `strClubCountry` varchar(50) DEFAULT NULL,
  `strClubName` varchar(100) DEFAULT NULL,
  `dtDateSent` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `strMessage` text,
  PRIMARY KEY (`intITCMessagesLog`)
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblITCMessagesLog`
--

LOCK TABLES `tblITCMessagesLog` WRITE;
/*!40000 ALTER TABLE `tblITCMessagesLog` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblITCMessagesLog` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblImportTrack`
--

DROP TABLE IF EXISTS `tblImportTrack`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblImportTrack` (
  `intImportID` int(11) NOT NULL AUTO_INCREMENT COMMENT 'This will be use to track all related record imported.',
  `strNotes` varchar(250) DEFAULT NULL COMMENT 'Specific notes or justification of the said import',
  `tTimeStamp` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`intImportID`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblImportTrack`
--

LOCK TABLES `tblImportTrack` WRITE;
/*!40000 ALTER TABLE `tblImportTrack` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblImportTrack` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblInvoice`
--

DROP TABLE IF EXISTS `tblInvoice`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblInvoice` (
  `intInvoiceID` int(11) NOT NULL AUTO_INCREMENT,
  `strInvoiceNumber` varchar(15) DEFAULT NULL,
  `intRealmID` int(11) DEFAULT NULL,
  `tTimeStamp` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`intInvoiceID`)
) ENGINE=InnoDB AUTO_INCREMENT=844 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblInvoice`
--

LOCK TABLES `tblInvoice` WRITE;
/*!40000 ALTER TABLE `tblInvoice` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblInvoice` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblLanguages`
--

DROP TABLE IF EXISTS `tblLanguages`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblLanguages` (
  `intLanguageID` int(11) NOT NULL AUTO_INCREMENT,
  `intRealmID` int(11) NOT NULL,
  `intSubRealmID` int(11) NOT NULL,
  `strName` varchar(100) DEFAULT '',
  `strNameLocal` varchar(100) DEFAULT '',
  `strLocale` varchar(10) DEFAULT '',
  `intNonLatin` tinyint(4) DEFAULT '0',
  PRIMARY KEY (`intLanguageID`),
  KEY `index_intRealmID` (`intRealmID`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblLanguages`
--

LOCK TABLES `tblLanguages` WRITE;
/*!40000 ALTER TABLE `tblLanguages` DISABLE KEYS */;
INSERT INTO `tblLanguages` VALUES (1,1,0,'English','English','en_US',0);
/*!40000 ALTER TABLE `tblLanguages` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblLegalType`
--

DROP TABLE IF EXISTS `tblLegalType`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblLegalType` (
  `intLegalTypeID` int(11) NOT NULL AUTO_INCREMENT,
  `intRealmID` int(11) DEFAULT '0',
  `strLegalType` varchar(255) CHARACTER SET latin1 DEFAULT NULL,
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`intLegalTypeID`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblLegalType`
--

LOCK TABLES `tblLegalType` WRITE;
/*!40000 ALTER TABLE `tblLegalType` DISABLE KEYS */;
INSERT INTO `tblLegalType` VALUES (1,1,'Association','2014-11-05 09:02:52'),(2,1,'Private Ltd','2014-11-05 09:02:52'),(3,1,'Incorporated','2014-11-05 09:02:52'),(4,1,'Foundation','2014-11-05 09:02:52'),(5,1,'Other','2014-11-05 09:02:52');
/*!40000 ALTER TABLE `tblLegalType` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblLocalConfig`
--

DROP TABLE IF EXISTS `tblLocalConfig`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblLocalConfig` (
  `intLocalConfigID` int(11) NOT NULL AUTO_INCREMENT,
  `intLocalisationID` int(11) NOT NULL,
  `strOption` varchar(100) NOT NULL,
  `strValue` varchar(250) NOT NULL,
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`intLocalConfigID`),
  UNIQUE KEY `index_LocalOption` (`intLocalisationID`,`strOption`),
  KEY `index_LocalisationID` (`intLocalisationID`),
  KEY `index_strOption` (`strOption`)
) ENGINE=MyISAM AUTO_INCREMENT=6 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblLocalConfig`
--

LOCK TABLES `tblLocalConfig` WRITE;
/*!40000 ALTER TABLE `tblLocalConfig` DISABLE KEYS */;
INSERT INTO `tblLocalConfig` VALUES (4,1,'CurrencySymbol','&euro;','2014-01-20 06:17:16'),(5,1,'DollarSymbol','&euro;','2014-01-24 21:37:35');
/*!40000 ALTER TABLE `tblLocalConfig` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblMatrix`
--

DROP TABLE IF EXISTS `tblMatrix`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblMatrix` (
  `intMatrixID` int(11) NOT NULL AUTO_INCREMENT,
  `intRealmID` int(11) DEFAULT '0',
  `intSubRealmID` int(11) DEFAULT '0',
  `intEntityLevel` tinyint(4) DEFAULT '0',
  `strWFRuleFor` varchar(30) DEFAULT '',
  `strEntityType` varchar(30) DEFAULT '',
  `strPersonType` varchar(30) DEFAULT '',
  `strRegistrationNature` varchar(30) DEFAULT '',
  `strPersonLevel` varchar(30) DEFAULT '',
  `strSport` varchar(20) DEFAULT '',
  `intOriginLevel` int(11) DEFAULT '0',
  `strAgeLevel` varchar(20) NOT NULL DEFAULT 'ALL',
  `intPaymentRequired` tinyint(4) DEFAULT '0',
  `dtAdded` date DEFAULT NULL,
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `intOfEntityLevel` tinyint(4) DEFAULT '0',
  `strPersonEntityRole` varchar(50) DEFAULT '',
  `intLocked` tinyint(4) DEFAULT '0',
  `dtFrom` date DEFAULT NULL,
  `dtTo` date DEFAULT NULL,
  PRIMARY KEY (`intMatrixID`),
  KEY `index_intRealmID` (`intRealmID`,`intSubRealmID`),
  KEY `index_strWFRuleFor` (`strWFRuleFor`),
  KEY `index_intPersonType` (`strPersonType`)
) ENGINE=InnoDB AUTO_INCREMENT=241 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblMatrix`
--

LOCK TABLES `tblMatrix` WRITE;
/*!40000 ALTER TABLE `tblMatrix` DISABLE KEYS */;
INSERT INTO `tblMatrix` VALUES (18,1,0,3,'REGO','','PLAYER','RENEWAL','AMATEUR','FOOTBALL',3,'ADULT',1,'2014-08-12','2014-11-26 23:43:27',1,'',0,NULL,NULL),(21,1,0,3,'REGO','','PLAYER','RENEWAL','AMATEUR','FOOTBALL',3,'MINOR',1,'2014-08-12','2014-11-26 23:43:27',1,'',0,NULL,NULL),(30,1,0,3,'REGO','','PLAYER','RENEWAL','PROFESSIONAL','FOOTBALL',3,'ADULT',1,'2014-08-12','2014-11-26 23:43:27',1,'',0,NULL,NULL),(33,1,0,3,'REGO','','PLAYER','RENEWAL','PROFESSIONAL','FOOTBALL',3,'MINOR',1,'2014-08-12','2014-11-26 23:43:27',1,'',0,NULL,NULL),(42,1,0,3,'REGO','','PLAYER','NEW','AMATEUR','FOOTBALL',3,'ADULT',1,'2014-08-12','2014-11-26 23:42:46',1,'',0,NULL,NULL),(45,1,0,3,'REGO','','PLAYER','NEW','AMATEUR','FOOTBALL',3,'MINOR',1,'2014-08-12','2014-11-26 23:42:46',1,'',0,NULL,NULL),(54,1,0,3,'REGO','','PLAYER','NEW','PROFESSIONAL','FOOTBALL',3,'ADULT',1,'2014-08-12','2014-11-26 23:43:27',1,'',0,NULL,NULL),(57,1,0,3,'REGO','','PLAYER','NEW','PROFESSIONAL','FOOTBALL',3,'MINOR',1,'2014-08-12','2014-11-26 23:43:27',1,'',0,NULL,NULL),(71,1,0,3,'REGO','','PLAYER','NEW','AMATEUR_U_C','FOOTBALL',3,'ADULT',1,'2014-09-05','2014-11-26 23:43:27',1,'',0,NULL,NULL),(74,1,0,3,'REGO','','PLAYER','NEW','AMATEUR_U_C','FOOTBALL',3,'MINOR',1,'2014-09-05','2014-11-26 23:43:27',1,'',0,NULL,NULL),(83,1,0,3,'REGO','','PLAYER','RENEWAL','AMATEUR_U_C','FOOTBALL',3,'ADULT',1,'2014-09-05','2014-11-26 23:43:27',1,'',0,NULL,NULL),(86,1,0,3,'REGO','','PLAYER','RENEWAL','AMATEUR_U_C','FOOTBALL',3,'MINOR',1,'2014-09-05','2014-11-26 23:43:27',1,'',0,NULL,NULL),(97,1,0,100,'REGO','','REFEREE','NEW','','FOOTBALL',100,'MINOR',1,'2014-10-07','2014-12-17 19:36:54',1,'',0,NULL,NULL),(98,1,0,100,'REGO','','REFEREE','RENEWAL','','FOOTBALL',100,'MINOR',1,'2014-10-07','2014-12-17 19:36:54',1,'',0,NULL,NULL),(102,1,0,3,'REGO','','CLUBOFFICIAL','NEW','','FOOTBALL',3,'MINOR',1,'2014-10-08','2014-12-17 19:51:19',1,'',0,NULL,NULL),(104,1,0,3,'REGO','','CLUBOFFICIAL','NEW','','FOOTBALL',100,'MINOR',1,'2014-10-08','2014-12-17 19:51:19',1,'',0,NULL,NULL),(105,1,0,3,'REGO','','CLUBOFFICIAL','RENEWAL','','FOOTBALL',3,'MINOR',1,'2014-10-08','2014-12-17 19:51:19',1,'',0,NULL,NULL),(107,1,0,3,'REGO','','CLUBOFFICIAL','RENEWAL','','FOOTBALL',100,'MINOR',1,'2014-10-08','2014-12-17 19:51:19',1,'',0,NULL,NULL),(114,1,0,3,'REGO','','TEAMOFFICIAL','NEW','','FOOTBALL',3,'MINOR',1,'2014-10-08','2014-12-17 19:49:07',1,'',0,NULL,NULL),(115,1,0,3,'REGO','','TEAMOFFICIAL','NEW','','FOOTBALL',100,'MINOR',1,'2014-10-08','2014-12-17 19:49:07',1,'',0,NULL,NULL),(117,1,0,3,'REGO','','TEAMOFFICIAL','RENEWAL','','FOOTBALL',3,'MINOR',1,'2014-10-08','2014-12-17 19:49:07',1,'',0,NULL,NULL),(118,1,0,3,'REGO','','TEAMOFFICIAL','RENEWAL','','FOOTBALL',100,'MINOR',1,'2014-10-08','2014-12-17 19:49:07',1,'',0,NULL,NULL),(126,1,0,100,'REGO','','MAOFFICIAL','NEW','','',100,'MINOR',1,'2014-10-08','2014-12-17 19:40:01',1,'',0,NULL,NULL),(127,1,0,100,'REGO','','MAOFFICIAL','RENEWAL','','',100,'MINOR',1,'2014-10-08','2014-12-17 19:40:01',1,'',0,NULL,NULL),(143,1,0,3,'REGO','','COACH','NEW','PROFESSIONAL','FOOTBALL',3,'MINOR',1,'2014-10-27','2014-12-17 19:55:55',1,'',0,NULL,NULL),(144,1,0,3,'REGO','','COACH','NEW','AMATEUR','FOOTBALL',3,'MINOR',1,'2014-10-27','2014-12-17 19:55:55',1,'',0,NULL,NULL),(145,1,0,3,'REGO','','COACH','RENEWAL','PROFESSIONAL','FOOTBALL',3,'MINOR',1,'2014-10-27','2014-12-17 19:55:55',1,'',0,NULL,NULL),(146,1,0,3,'REGO','','COACH','RENEWAL','AMATEUR','FOOTBALL',3,'MINOR',1,'2014-10-27','2014-12-17 19:55:55',1,'',0,NULL,NULL),(159,1,0,100,'REGO','','COACH','NEW','PROFESSIONAL','FOOTBALL',100,'MINOR',1,'2014-11-26','2014-12-17 19:55:55',1,'',0,NULL,NULL),(160,1,0,100,'REGO','','COACH','NEW','AMATEUR','FOOTBALL',100,'MINOR',1,'2014-11-26','2014-12-17 19:55:55',1,'',0,NULL,NULL),(161,1,0,100,'REGO','','COACH','RENEWAL','PROFESSIONAL','FOOTBALL',100,'MINOR',1,'2014-11-26','2014-12-17 19:55:55',1,'',0,NULL,NULL),(162,1,0,100,'REGO','','COACH','RENEWAL','AMATEUR','FOOTBALL',100,'MINOR',1,'2014-11-26','2014-12-17 19:55:55',1,'',0,NULL,NULL),(166,0,0,0,'REGO_off','','PLAYER','TRANSFER','AMATEUR','FOOTBALL',3,'MINOR',1,'2014-11-26','2014-12-02 21:31:57',1,'',0,NULL,NULL),(167,1,0,0,'REGO','','PLAYER','TRANSFER','AMATEUR','FOOTBALL',3,'ADULT',1,'2014-11-26','2014-11-26 23:45:13',1,'',0,NULL,NULL),(168,0,0,0,'REGO_off','','PLAYER','TRANSFER','AMATEUR_U_C','FOOTBALL',3,'MINOR',1,'2014-11-26','2014-12-02 21:31:57',1,'',0,NULL,NULL),(169,1,0,0,'REGO','','PLAYER','TRANSFER','AMATEUR_U_C','FOOTBALL',3,'ADULT',1,'2014-11-26','2014-11-26 23:45:37',1,'',0,NULL,NULL),(170,0,0,0,'REGO_off','','PLAYER','TRANSFER','PROFESSIONAL','FOOTBALL',3,'MINOR',1,'2014-11-26','2014-12-02 21:31:57',1,'',0,NULL,NULL),(171,1,0,0,'REGO','','PLAYER','TRANSFER','PROFESSIONAL','FOOTBALL',3,'ADULT',1,'2014-11-26','2014-11-26 23:45:59',1,'',0,NULL,NULL),(172,1,0,3,'REGO','','PLAYER','RENEWAL','AMATEUR','FOOTBALL',100,'ADULT',1,'2014-11-26','2014-11-26 23:46:10',1,'',0,NULL,NULL),(173,1,0,3,'REGO','','PLAYER','RENEWAL','AMATEUR','FOOTBALL',100,'MINOR',1,'2014-11-26','2014-11-26 23:46:10',1,'',0,NULL,NULL),(174,1,0,3,'REGO','','PLAYER','RENEWAL','PROFESSIONAL','FOOTBALL',100,'ADULT',1,'2014-11-26','2014-11-26 23:46:10',1,'',0,NULL,NULL),(175,1,0,3,'REGO','','PLAYER','RENEWAL','PROFESSIONAL','FOOTBALL',100,'MINOR',1,'2014-11-26','2014-11-26 23:46:10',1,'',0,NULL,NULL),(176,1,0,3,'REGO','','PLAYER','NEW','AMATEUR','FOOTBALL',100,'ADULT',1,'2014-11-26','2014-11-26 23:46:10',1,'',0,NULL,NULL),(177,1,0,3,'REGO','','PLAYER','NEW','AMATEUR','FOOTBALL',100,'MINOR',1,'2014-11-26','2014-11-26 23:46:10',1,'',0,NULL,NULL),(178,1,0,3,'REGO','','PLAYER','NEW','PROFESSIONAL','FOOTBALL',100,'ADULT',1,'2014-11-26','2014-11-26 23:46:10',1,'',0,NULL,NULL),(179,1,0,3,'REGO','','PLAYER','NEW','PROFESSIONAL','FOOTBALL',100,'MINOR',1,'2014-11-26','2014-11-26 23:46:10',1,'',0,NULL,NULL),(180,1,0,3,'REGO','','PLAYER','NEW','AMATEUR_U_C','FOOTBALL',100,'ADULT',1,'2014-11-26','2014-11-26 23:46:10',1,'',0,NULL,NULL),(181,1,0,3,'REGO','','PLAYER','NEW','AMATEUR_U_C','FOOTBALL',100,'MINOR',1,'2014-11-26','2014-11-26 23:46:10',1,'',0,NULL,NULL),(182,1,0,3,'REGO','','PLAYER','RENEWAL','AMATEUR_U_C','FOOTBALL',100,'ADULT',1,'2014-11-26','2014-11-26 23:46:10',1,'',0,NULL,NULL),(183,1,0,3,'REGO','','PLAYER','RENEWAL','AMATEUR_U_C','FOOTBALL',100,'MINOR',1,'2014-11-26','2014-11-26 23:46:10',1,'',0,NULL,NULL),(184,0,0,3,'REGO_off','','PLAYER','TRANSFER','AMATEUR','FOOTBALL',100,'MINOR',1,'2014-11-26','2014-12-02 21:31:57',1,'',0,NULL,NULL),(185,1,0,3,'REGO','','PLAYER','TRANSFER','AMATEUR','FOOTBALL',100,'ADULT',1,'2014-11-26','2014-11-26 23:46:10',1,'',0,NULL,NULL),(186,0,0,3,'REGO_off','','PLAYER','TRANSFER','AMATEUR_U_C','FOOTBALL',100,'MINOR',1,'2014-11-26','2014-12-02 21:31:57',1,'',0,NULL,NULL),(187,1,0,3,'REGO','','PLAYER','TRANSFER','AMATEUR_U_C','FOOTBALL',100,'ADULT',1,'2014-11-26','2014-11-26 23:46:10',1,'',0,NULL,NULL),(188,0,0,3,'REGO_off','','PLAYER','TRANSFER','PROFESSIONAL','FOOTBALL',100,'MINOR',1,'2014-11-26','2014-12-02 21:31:57',1,'',0,NULL,NULL),(189,1,0,3,'REGO','','PLAYER','TRANSFER','PROFESSIONAL','FOOTBALL',100,'ADULT',1,'2014-11-26','2014-11-26 23:46:10',1,'',0,NULL,NULL),(210,1,0,3,'REGO','','COACH','NEW','PROFESSIONAL','FOOTBALL',100,'MINOR',1,'2014-12-02','2014-12-17 19:55:55',1,'',0,NULL,NULL),(211,1,0,3,'REGO','','COACH','NEW','AMATEUR','FOOTBALL',100,'MINOR',1,'2014-12-02','2014-12-17 19:55:55',1,'',0,NULL,NULL),(212,1,0,3,'REGO','','COACH','RENEWAL','PROFESSIONAL','FOOTBALL',100,'MINOR',1,'2014-12-02','2014-12-17 19:55:55',1,'',0,NULL,NULL),(213,1,0,3,'REGO','','COACH','RENEWAL','AMATEUR','FOOTBALL',100,'MINOR',1,'2014-12-02','2014-12-17 19:55:55',1,'',0,NULL,NULL),(217,1,0,100,'REGO','','REFEREE','NEW','','FOOTBALL',100,'ADULT',1,'2014-10-07','2014-11-26 23:43:27',1,'',0,NULL,NULL),(218,1,0,100,'REGO','','MAOFFICIAL','NEW','','',100,'ADULT',1,'2014-10-08','2014-11-26 23:43:27',1,'',0,NULL,NULL),(219,1,0,3,'REGO','','TEAMOFFICIAL','NEW','','FOOTBALL',3,'ADULT',1,'2014-10-08','2014-11-26 23:43:27',1,'',0,NULL,NULL),(220,1,0,3,'REGO','','TEAMOFFICIAL','NEW','','FOOTBALL',100,'ADULT',1,'2014-10-08','2014-11-26 23:43:27',1,'',0,NULL,NULL),(221,1,0,3,'REGO','','TEAMOFFICIAL','RENEWAL','','FOOTBALL',100,'ADULT',1,'2014-10-08','2014-11-26 23:43:27',1,'',0,NULL,NULL),(222,1,0,3,'REGO','','CLUBOFFICIAL','NEW','','FOOTBALL',3,'ADULT',1,'2014-10-08','2014-11-26 23:43:27',1,'',0,NULL,NULL),(223,1,0,3,'REGO','','CLUBOFFICIAL','NEW','','FOOTBALL',100,'ADULT',1,'2014-10-08','2014-11-26 23:43:27',1,'',0,NULL,NULL),(224,1,0,3,'REGO','','CLUBOFFICIAL','RENEWAL','','FOOTBALL',100,'ADULT',1,'2014-10-08','2014-11-26 23:43:27',1,'',0,NULL,NULL),(225,1,0,3,'REGO','','COACH','NEW','PROFESSIONAL','FOOTBALL',3,'ADULT',1,'2014-10-27','2014-12-01 13:34:47',1,'',0,NULL,NULL),(226,1,0,3,'REGO','','COACH','NEW','AMATEUR','FOOTBALL',3,'ADULT',1,'2014-10-27','2014-12-01 13:34:59',1,'',0,NULL,NULL),(227,1,0,3,'REGO','','COACH','RENEWAL','PROFESSIONAL','FOOTBALL',3,'ADULT',1,'2014-10-27','2014-12-01 13:34:47',1,'',0,NULL,NULL),(228,1,0,3,'REGO','','COACH','RENEWAL','AMATEUR','FOOTBALL',3,'ADULT',1,'2014-10-27','2014-12-01 13:34:59',1,'',0,NULL,NULL),(229,1,0,100,'REGO','','COACH','NEW','PROFESSIONAL','FOOTBALL',100,'ADULT',1,'2014-11-26','2014-12-02 12:24:26',1,'',0,NULL,NULL),(230,1,0,100,'REGO','','COACH','NEW','AMATEUR','FOOTBALL',100,'ADULT',1,'2014-11-26','2014-12-02 12:25:07',1,'',0,NULL,NULL),(231,1,0,100,'REGO','','COACH','RENEWAL','PROFESSIONAL','FOOTBALL',100,'ADULT',1,'2014-11-26','2014-12-02 12:25:19',1,'',0,NULL,NULL),(232,1,0,100,'REGO','','COACH','RENEWAL','AMATEUR','FOOTBALL',100,'ADULT',1,'2014-11-26','2014-12-02 12:25:28',1,'',0,NULL,NULL),(233,1,0,3,'REGO','','COACH','NEW','PROFESSIONAL','FOOTBALL',100,'ADULT',1,'2014-12-02','2014-12-02 21:29:17',1,'',0,NULL,NULL),(234,1,0,3,'REGO','','COACH','NEW','AMATEUR','FOOTBALL',100,'ADULT',1,'2014-12-02','2014-12-02 21:29:17',1,'',0,NULL,NULL),(235,1,0,3,'REGO','','COACH','RENEWAL','PROFESSIONAL','FOOTBALL',100,'ADULT',1,'2014-12-02','2014-12-02 21:29:17',1,'',0,NULL,NULL),(236,1,0,3,'REGO','','COACH','RENEWAL','AMATEUR','FOOTBALL',100,'ADULT',1,'2014-12-02','2014-12-02 21:29:17',1,'',0,NULL,NULL),(237,1,0,100,'REGO','','REFEREE','RENEWAL','','FOOTBALL',100,'ADULT',1,'2014-12-18','2014-12-18 16:58:05',1,'',0,NULL,NULL),(238,1,0,3,'REGO','','CLUBOFFICIAL','RENEWAL','','FOOTBALL',3,'ADULT',1,'2014-12-18','2014-12-18 17:03:17',1,'',0,NULL,NULL),(239,1,0,3,'REGO','','TEAMOFFICIAL','RENEWAL','','FOOTBALL',3,'ADULT',1,'2014-12-18','2014-12-18 17:03:50',1,'',0,NULL,NULL),(240,1,0,100,'REGO','','MAOFFICIAL','RENEWAL','','',100,'ADULT',1,'2015-01-08','2015-01-08 09:34:59',1,'',0,NULL,NULL);
/*!40000 ALTER TABLE `tblMatrix` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblMember`
--

DROP TABLE IF EXISTS `tblMember`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblMember` (
  `intMemberID` int(11) NOT NULL AUTO_INCREMENT,
  `strExtKey` varchar(20) NOT NULL DEFAULT '',
  `strMemberNo` varchar(15) NOT NULL DEFAULT '',
  `strFirstname` varchar(50) DEFAULT NULL,
  `strMiddlename` varchar(50) DEFAULT NULL,
  `strSurname` varchar(50) DEFAULT NULL,
  `strAddress1` varchar(100) DEFAULT NULL,
  `strAddress2` varchar(100) DEFAULT NULL,
  `strSuburb` varchar(100) DEFAULT NULL,
  `strState` varchar(50) DEFAULT NULL,
  `strPostalCode` varchar(15) DEFAULT NULL,
  `strCountry` varchar(50) DEFAULT NULL,
  `strSalutation` varchar(30) DEFAULT NULL,
  `dtDOB` date DEFAULT NULL,
  `intGender` tinyint(4) DEFAULT NULL,
  `strMaidenName` varchar(50) DEFAULT NULL,
  `strPhoneHome` varchar(30) DEFAULT NULL,
  `strPhoneWork` varchar(30) DEFAULT NULL,
  `strPhoneMobile` varchar(30) DEFAULT NULL,
  `strFax` varchar(30) DEFAULT NULL,
  `strPager` varchar(30) DEFAULT NULL,
  `strEmail` varchar(200) DEFAULT NULL,
  `dtLastUpdate` datetime DEFAULT NULL,
  `intEthnicityID` int(11) DEFAULT NULL,
  `intOccupationID` int(11) DEFAULT NULL,
  `intStatus` int(11) NOT NULL DEFAULT '1',
  `strNotes` text,
  `strPhotoFilename` varchar(100) DEFAULT NULL,
  `strPlaceofBirth` varchar(50) DEFAULT NULL,
  `strCountryOfBirth` varchar(50) DEFAULT NULL,
  `strCityOfResidence` varchar(50) DEFAULT NULL,
  `strPassportNo` varchar(50) DEFAULT NULL,
  `strPassportNationality` varchar(50) DEFAULT NULL,
  `dtPassportExpiry` date DEFAULT NULL,
  `strEmergContName` varchar(100) DEFAULT NULL,
  `strEmergContRel` varchar(100) DEFAULT NULL,
  `strEmergContNo` varchar(100) DEFAULT NULL,
  `strEyeColour` varchar(30) DEFAULT NULL,
  `strHairColour` varchar(30) DEFAULT NULL,
  `strHeight` varchar(20) DEFAULT NULL,
  `strWeight` varchar(20) DEFAULT NULL,
  `intDeceased` tinyint(4) DEFAULT NULL,
  `strP1FName` varchar(50) DEFAULT NULL,
  `strP1SName` varchar(50) DEFAULT NULL,
  `strP2FName` varchar(50) DEFAULT NULL,
  `strP2SName` varchar(50) DEFAULT NULL,
  `strBirthCertNo` varchar(50) DEFAULT NULL,
  `strHealthCareNo` varchar(50) DEFAULT NULL,
  `intIdentTypeID` int(11) DEFAULT NULL,
  `strIdentNum` varchar(20) DEFAULT NULL,
  `strNatCustomStr1` varchar(50) DEFAULT NULL,
  `strNatCustomStr2` varchar(50) DEFAULT NULL,
  `strNatCustomStr3` varchar(50) DEFAULT NULL,
  `strNatCustomStr4` varchar(50) DEFAULT NULL,
  `strNatCustomStr5` varchar(50) DEFAULT NULL,
  `strNatCustomStr6` varchar(50) DEFAULT NULL,
  `strNatCustomStr7` varchar(30) DEFAULT NULL,
  `strNatCustomStr8` varchar(30) DEFAULT NULL,
  `dblNatCustomDbl1` double DEFAULT '0',
  `dblNatCustomDbl2` double DEFAULT '0',
  `dblNatCustomDbl3` double DEFAULT '0',
  `dblNatCustomDbl4` double DEFAULT '0',
  `dtNatCustomDt1` date DEFAULT NULL,
  `dtNatCustomDt2` date DEFAULT NULL,
  `strNationalNum` varchar(30) DEFAULT NULL,
  `dtSuspendedUntil` date DEFAULT NULL,
  `intPlayer` tinyint(4) DEFAULT '0',
  `intCoach` tinyint(4) DEFAULT '0',
  `intUmpire` tinyint(4) DEFAULT '0',
  `intOfficial` tinyint(4) DEFAULT '0',
  `intMisc` tinyint(4) DEFAULT '0',
  `intPhoto` tinyint(4) DEFAULT '0',
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `intRealmID` int(11) NOT NULL DEFAULT '0',
  `dtPoliceCheck` date DEFAULT NULL,
  `dtPoliceCheckExp` date DEFAULT NULL,
  `strPoliceCheckRef` varchar(30) DEFAULT NULL,
  `intFavStateTeamID` int(11) DEFAULT '0',
  `intFavNationalTeamID` int(11) DEFAULT '0',
  `intNatCustomLU1` int(11) DEFAULT NULL,
  `intNatCustomLU2` int(11) DEFAULT NULL,
  `intNatCustomLU3` int(11) DEFAULT NULL,
  `intSchoolID` int(11) DEFAULT '0',
  `intGradeID` int(11) DEFAULT '0',
  `intHowFoundOutID` int(11) DEFAULT '0',
  `strP1Email` varchar(250) DEFAULT '',
  `strP2Email` varchar(250) DEFAULT '',
  `strP1Phone` varchar(30) DEFAULT '',
  `strP2Phone` varchar(30) DEFAULT '',
  `intP1AssistAreaID` int(11) DEFAULT '0',
  `intP2AssistAreaID` int(11) DEFAULT '0',
  `intMedicalConditions` tinyint(4) DEFAULT '0',
  `intAllergies` tinyint(4) DEFAULT '0',
  `strMedicalNotes` text,
  `intAllowMedicalTreatment` tinyint(4) DEFAULT '0',
  `intConsentSignatureSighted` tinyint(4) DEFAULT '0',
  `dtCreatedOnline` date DEFAULT NULL,
  `intCreatedFrom` int(11) DEFAULT '0',
  `intFavNationalTeamMember` tinyint(4) DEFAULT '0',
  `intAttendSportCount` int(11) DEFAULT '0',
  `intWatchSportHowOftenID` int(11) DEFAULT '0',
  `strEmergContNo2` varchar(100) DEFAULT '',
  `strP1Salutation` varchar(30) DEFAULT '',
  `strP2Salutation` varchar(30) DEFAULT '',
  `intP1Gender` tinyint(4) DEFAULT '0',
  `intP2Gender` tinyint(4) DEFAULT '0',
  `strP1Phone2` varchar(30) DEFAULT '',
  `strP2Phone2` varchar(30) DEFAULT '',
  `strP1PhoneMobile` varchar(30) DEFAULT '',
  `strP2PhoneMobile` varchar(30) DEFAULT '',
  `strP1Email2` varchar(250) DEFAULT '',
  `strP2Email2` varchar(250) DEFAULT '',
  `intDefaulter` tinyint(4) DEFAULT '0',
  `intVolunteer` tinyint(4) DEFAULT '0',
  `strNatCustomStr9` varchar(50) DEFAULT '',
  `strNatCustomStr10` varchar(50) DEFAULT '',
  `strNatCustomStr11` varchar(50) DEFAULT '',
  `strNatCustomStr12` varchar(50) DEFAULT '',
  `strNatCustomStr13` varchar(50) DEFAULT '',
  `strNatCustomStr14` varchar(50) DEFAULT '',
  `strNatCustomStr15` varchar(50) DEFAULT '',
  `dblNatCustomDbl5` double DEFAULT '0',
  `dblNatCustomDbl6` double DEFAULT '0',
  `dblNatCustomDbl7` double DEFAULT '0',
  `dblNatCustomDbl8` double DEFAULT '0',
  `dblNatCustomDbl9` double DEFAULT '0',
  `dblNatCustomDbl10` double DEFAULT '0',
  `dtNatCustomDt3` date DEFAULT NULL,
  `dtNatCustomDt4` date DEFAULT NULL,
  `dtNatCustomDt5` date DEFAULT NULL,
  `intNatCustomLU4` int(11) DEFAULT '0',
  `intNatCustomLU5` int(11) DEFAULT '0',
  `intNatCustomLU6` int(11) DEFAULT '0',
  `intNatCustomLU7` int(11) DEFAULT '0',
  `intNatCustomLU8` int(11) DEFAULT '0',
  `intNatCustomLU9` int(11) DEFAULT '0',
  `intNatCustomLU10` int(11) DEFAULT '0',
  `intNatCustomBool1` tinyint(4) DEFAULT '0',
  `intNatCustomBool2` tinyint(4) DEFAULT '0',
  `intNatCustomBool3` tinyint(4) DEFAULT '0',
  `intNatCustomBool4` tinyint(4) DEFAULT '0',
  `intNatCustomBool5` tinyint(4) DEFAULT '0',
  `strPreferredName` varchar(100) DEFAULT '',
  `strEmail2` varchar(200) DEFAULT '',
  `strPreferredLang` varchar(50) DEFAULT '',
  `strPassportIssueCountry` varchar(50) DEFAULT NULL,
  `strUmpirePassword` varchar(10) DEFAULT NULL,
  `strMotherCountry` varchar(100) DEFAULT '',
  `strFatherCountry` varchar(100) DEFAULT '',
  `intDeRegister` int(11) DEFAULT '0',
  `intPhotoUseApproval` tinyint(4) DEFAULT '0',
  `intSINGFIX_ClubID` int(11) DEFAULT '0',
  `strSING_EXT` varchar(15) DEFAULT '',
  PRIMARY KEY (`intMemberID`),
  KEY `index_strMemberNo` (`strMemberNo`),
  KEY `index_intStatus` (`intStatus`),
  KEY `index_strExtKey` (`strExtKey`),
  KEY `index_strSurname` (`strSurname`),
  KEY `index_strFirstname` (`strFirstname`),
  KEY `index_dtDOB` (`dtDOB`),
  KEY `index_intGender` (`intGender`),
  KEY `index_strNationalNum` (`strNationalNum`),
  KEY `index_dtLastUpdate` (`dtLastUpdate`),
  KEY `index_intRealmID` (`intRealmID`),
  KEY `index_RealmStatus` (`intRealmID`,`intStatus`),
  KEY `index_RealmNameDOB` (`intRealmID`,`strSurname`,`strFirstname`,`dtDOB`),
  KEY `index_RealmEmail` (`intRealmID`,`strEmail`),
  KEY `index_RealmNatNumMID` (`intRealmID`,`strNationalNum`,`intMemberID`),
  KEY `index_strUmpirePassword` (`strUmpirePassword`)
) ENGINE=MyISAM AUTO_INCREMENT=10759058 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblMember`
--

LOCK TABLES `tblMember` WRITE;
/*!40000 ALTER TABLE `tblMember` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblMember` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblMemberCardConfig`
--

DROP TABLE IF EXISTS `tblMemberCardConfig`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblMemberCardConfig` (
  `intMemberCardConfigID` int(11) NOT NULL AUTO_INCREMENT,
  `strName` varchar(200) DEFAULT NULL,
  `intRealmID` int(11) NOT NULL,
  `intSubRealmID` int(11) NOT NULL DEFAULT '0',
  `intAssocID` int(11) NOT NULL DEFAULT '0',
  `intPrintFromLevelID` int(11) DEFAULT '0',
  `intBulkPrintFromLevelID` int(11) DEFAULT '0',
  `strFilename` varchar(200) DEFAULT NULL,
  `strMemberCard` text,
  `intMemberCardTemplateID` int(11) DEFAULT NULL,
  PRIMARY KEY (`intMemberCardConfigID`),
  KEY `index_realm` (`intRealmID`,`intAssocID`),
  KEY `index_assoc` (`intAssocID`)
) ENGINE=MyISAM AUTO_INCREMENT=357 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblMemberCardConfig`
--

LOCK TABLES `tblMemberCardConfig` WRITE;
/*!40000 ALTER TABLE `tblMemberCardConfig` DISABLE KEYS */;
INSERT INTO `tblMemberCardConfig` VALUES (356,'Finland',1,1,0,5,5,'','        [% USE date %]\r\n        [% varDate =  date.format(date.now(), \'%d/%m/%Y\') %]\r\n\r\n\r\n        <style type=\"text/css\">\r\n                .line {\r\n                        margin-bottom:10px;\r\n                        font-size: 12px;\r\n                }\r\n        </style>\r\n\r\n        [% FOREACH m = Members %]\r\n\r\n                <!-- [% m.intMemberID %] -->\r\n                [% varClub = \'\' %]\r\n                [% varDefaultClub = \'\' %]\r\n                [% FOREACH c = m.Clubs %]\r\n                        [% NEXT IF c.intStatus != 1 %]\r\n                        [% varDefaultClub = c.strName %]\r\n                        [% NEXT IF c.intPrimaryClub == 1 %]\r\n                        [% varClub = c.strName %]\r\n                [% END %]\r\n\r\n                [% IF varClub == \'\' %]\r\n                        [% varClub = varDefaultClub %]\r\n                [% END %]\r\n\r\n                <div style=\"font-size:12px;width:319px;height:175px;\">\r\n                <table border=\"0\" style=\"width:319px;\">\r\n                        <tr>\r\n                                <td valign=\"top\" style=\"width:120px;text-align:center;\">\r\n                                        <img src=\"http://reg.sportingpulseinternational.com/getphoto.cgi?client=[% m.client %]\" alt=\"\" height=\"130\">\r\n                                        [% m.strMemberNo %]\r\n                                </td>\r\n                                <td valign=\"top\" style=\"text-align:center;\">\r\n                                        <img src=\"/formsimg/football_finland.png\" border=\"0\" height=\"70\">\r\n                                        <div class=\"line\"><b>[% varClub %]</b></div>\r\n                                        <div class=\"line\"><b>[% m.strFirstname %] [% m.strSurname %]</b></div>\r\n                                        <div class=\"line\">DOB: [% m.dtDOB %]</div>\r\n                                </td>\r\n                </table>\r\n                </div>\r\n\r\n\r\n        [% END %]',0);
/*!40000 ALTER TABLE `tblMemberCardConfig` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblMemberCardConfigMemberTypes`
--

DROP TABLE IF EXISTS `tblMemberCardConfigMemberTypes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblMemberCardConfigMemberTypes` (
  `intMemberCardConfigID` int(11) NOT NULL AUTO_INCREMENT,
  `intTypeID` int(11) NOT NULL,
  `intActive` tinyint(4) DEFAULT '1',
  PRIMARY KEY (`intMemberCardConfigID`,`intTypeID`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblMemberCardConfigMemberTypes`
--

LOCK TABLES `tblMemberCardConfigMemberTypes` WRITE;
/*!40000 ALTER TABLE `tblMemberCardConfigMemberTypes` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblMemberCardConfigMemberTypes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblMemberCardConfigProducts`
--

DROP TABLE IF EXISTS `tblMemberCardConfigProducts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblMemberCardConfigProducts` (
  `intMemberCardConfigID` int(11) NOT NULL,
  `intProductID` int(11) NOT NULL,
  `intTXNStatus` tinyint(4) DEFAULT '1',
  PRIMARY KEY (`intMemberCardConfigID`,`intProductID`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblMemberCardConfigProducts`
--

LOCK TABLES `tblMemberCardConfigProducts` WRITE;
/*!40000 ALTER TABLE `tblMemberCardConfigProducts` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblMemberCardConfigProducts` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblMemberCardPrinted`
--

DROP TABLE IF EXISTS `tblMemberCardPrinted`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblMemberCardPrinted` (
  `intMemberCardPrintedID` int(11) NOT NULL AUTO_INCREMENT,
  `intMemberCardConfigID` int(11) NOT NULL,
  `intMemberID` int(11) NOT NULL,
  `dtPrinted` datetime DEFAULT NULL,
  `strUsername` varchar(30) DEFAULT NULL,
  `intQty` int(11) DEFAULT '1',
  `intCount` int(11) DEFAULT '1',
  PRIMARY KEY (`intMemberCardPrintedID`),
  KEY `key_intMemberID` (`intMemberID`,`intMemberCardConfigID`),
  KEY `key_intCardType` (`intMemberCardConfigID`)
) ENGINE=MyISAM AUTO_INCREMENT=357215 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblMemberCardPrinted`
--

LOCK TABLES `tblMemberCardPrinted` WRITE;
/*!40000 ALTER TABLE `tblMemberCardPrinted` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblMemberCardPrinted` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblMemberCardTemplates`
--

DROP TABLE IF EXISTS `tblMemberCardTemplates`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblMemberCardTemplates` (
  `intMemberCardTemplateID` int(11) NOT NULL AUTO_INCREMENT,
  `strMemberCardTemplateName` varchar(30) DEFAULT NULL,
  `strMemberCardTemplate` text,
  PRIMARY KEY (`intMemberCardTemplateID`)
) ENGINE=MyISAM AUTO_INCREMENT=24 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblMemberCardTemplates`
--

LOCK TABLES `tblMemberCardTemplates` WRITE;
/*!40000 ALTER TABLE `tblMemberCardTemplates` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblMemberCardTemplates` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblMemberHidePublic`
--

DROP TABLE IF EXISTS `tblMemberHidePublic`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblMemberHidePublic` (
  `intMemberToHideID` int(11) DEFAULT '0',
  `intAssocToHideID` int(11) DEFAULT '0',
  KEY `intMemberToHideID` (`intMemberToHideID`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblMemberHidePublic`
--

LOCK TABLES `tblMemberHidePublic` WRITE;
/*!40000 ALTER TABLE `tblMemberHidePublic` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblMemberHidePublic` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblMemberNotes`
--

DROP TABLE IF EXISTS `tblMemberNotes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
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

--
-- Dumping data for table `tblMemberNotes`
--

LOCK TABLES `tblMemberNotes` WRITE;
/*!40000 ALTER TABLE `tblMemberNotes` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblMemberNotes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblMemberPackages`
--

DROP TABLE IF EXISTS `tblMemberPackages`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblMemberPackages` (
  `intMemberPackagesID` int(11) NOT NULL AUTO_INCREMENT,
  `intRealmID` int(11) NOT NULL DEFAULT '0',
  `intAssocID` int(11) NOT NULL DEFAULT '0',
  `strPackageName` varchar(50) DEFAULT NULL,
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`intMemberPackagesID`),
  KEY `index_intRealmAssoc` (`intRealmID`,`intAssocID`)
) ENGINE=MyISAM AUTO_INCREMENT=4403 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblMemberPackages`
--

LOCK TABLES `tblMemberPackages` WRITE;
/*!40000 ALTER TABLE `tblMemberPackages` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblMemberPackages` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblMemberTags`
--

DROP TABLE IF EXISTS `tblMemberTags`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblMemberTags` (
  `intMemberTagID` int(11) NOT NULL AUTO_INCREMENT,
  `intAssocID` int(11) NOT NULL DEFAULT '0',
  `intRealmID` int(11) NOT NULL DEFAULT '0',
  `intMemberID` int(11) NOT NULL DEFAULT '0',
  `intTagID` int(11) NOT NULL DEFAULT '0',
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `intRecStatus` tinyint(4) DEFAULT '0',
  PRIMARY KEY (`intMemberTagID`),
  KEY `index_intAssocID` (`intAssocID`),
  KEY `IDNEX_intRecStatus` (`intRecStatus`),
  KEY `index_intRealmAssoc` (`intRealmID`,`intAssocID`),
  KEY `index_intRealmAssocMember` (`intRealmID`,`intAssocID`,`intMemberID`),
  KEY `index_intMemberID` (`intMemberID`)
) ENGINE=MyISAM AUTO_INCREMENT=337158 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblMemberTags`
--

LOCK TABLES `tblMemberTags` WRITE;
/*!40000 ALTER TABLE `tblMemberTags` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblMemberTags` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblMember_Associations`
--

DROP TABLE IF EXISTS `tblMember_Associations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblMember_Associations` (
  `intMemberAssociationID` int(11) NOT NULL AUTO_INCREMENT,
  `intMemberID` int(11) NOT NULL DEFAULT '0',
  `intAssocID` int(11) NOT NULL DEFAULT '0',
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `intRecStatus` tinyint(4) DEFAULT NULL,
  `strCustomStr1` varchar(50) DEFAULT NULL,
  `strCustomStr2` varchar(50) DEFAULT NULL,
  `strCustomStr3` varchar(50) DEFAULT NULL,
  `strCustomStr4` varchar(50) DEFAULT NULL,
  `strCustomStr5` varchar(50) DEFAULT NULL,
  `strCustomStr6` varchar(50) DEFAULT NULL,
  `strCustomStr7` varchar(30) DEFAULT NULL,
  `strCustomStr8` varchar(30) DEFAULT NULL,
  `dblCustomDbl1` double DEFAULT '0',
  `dblCustomDbl2` double DEFAULT '0',
  `dblCustomDbl3` double DEFAULT '0',
  `dblCustomDbl4` double DEFAULT '0',
  `dtCustomDt1` date DEFAULT NULL,
  `dtCustomDt2` date DEFAULT NULL,
  `intCustomLU1` int(11) DEFAULT NULL,
  `intCustomLU2` int(11) DEFAULT NULL,
  `intCustomLU3` int(11) DEFAULT NULL,
  `dtExpiry` date DEFAULT NULL,
  `intFinancialActive` tinyint(4) DEFAULT '0',
  `intMemberPackageID` int(11) DEFAULT '0',
  `dtFirstRegistered` date DEFAULT NULL,
  `dtLastRegistered` date DEFAULT NULL,
  `curMemberFinBal` decimal(12,2) DEFAULT '0.00',
  `strLoyaltyNumber` varchar(20) DEFAULT NULL,
  `intLifeMember` tinyint(4) DEFAULT '0',
  `intMailingList` tinyint(4) DEFAULT NULL,
  `dtRegisteredUntil` date DEFAULT NULL,
  `strCustomStr9` varchar(50) DEFAULT '',
  `strCustomStr10` varchar(50) DEFAULT '',
  `strCustomStr11` varchar(50) DEFAULT '',
  `strCustomStr12` varchar(50) DEFAULT '',
  `strCustomStr13` varchar(50) DEFAULT '',
  `strCustomStr14` varchar(50) DEFAULT '',
  `strCustomStr15` varchar(50) DEFAULT '',
  `dblCustomDbl5` double DEFAULT '0',
  `dblCustomDbl6` double DEFAULT '0',
  `dblCustomDbl7` double DEFAULT '0',
  `dblCustomDbl8` double DEFAULT '0',
  `dblCustomDbl9` double DEFAULT '0',
  `dblCustomDbl10` double DEFAULT '0',
  `intCustomLU4` int(11) DEFAULT '0',
  `intCustomLU5` int(11) DEFAULT '0',
  `intCustomLU6` int(11) DEFAULT '0',
  `intCustomLU7` int(11) DEFAULT '0',
  `intCustomLU8` int(11) DEFAULT '0',
  `intCustomLU9` int(11) DEFAULT '0',
  `intCustomLU10` int(11) DEFAULT '0',
  `intCustomLU11` int(11) DEFAULT NULL,
  `intCustomLU12` int(11) DEFAULT NULL,
  `intCustomLU13` int(11) DEFAULT NULL,
  `intCustomLU14` int(11) DEFAULT NULL,
  `intCustomLU15` int(11) DEFAULT NULL,
  `intCustomLU16` int(11) DEFAULT NULL,
  `intCustomLU17` int(11) DEFAULT NULL,
  `intCustomLU18` int(11) DEFAULT NULL,
  `intCustomLU19` int(11) DEFAULT NULL,
  `intCustomLU20` int(11) DEFAULT NULL,
  `intCustomLU21` int(11) DEFAULT NULL,
  `intCustomLU22` int(11) DEFAULT NULL,
  `intCustomLU23` int(11) DEFAULT NULL,
  `intCustomLU24` int(11) DEFAULT NULL,
  `intCustomLU25` int(11) DEFAULT NULL,
  `intCustomBool1` tinyint(4) DEFAULT '0',
  `intCustomBool2` tinyint(4) DEFAULT '0',
  `intCustomBool3` tinyint(4) DEFAULT '0',
  `intCustomBool4` tinyint(4) DEFAULT '0',
  `intCustomBool5` tinyint(4) DEFAULT '0',
  `dtCustomDt3` date DEFAULT NULL,
  `dtCustomDt4` date DEFAULT NULL,
  `dtCustomDt5` date DEFAULT NULL,
  `strCustomStr16` varchar(50) DEFAULT '',
  `strCustomStr17` varchar(50) DEFAULT '',
  `strCustomStr18` varchar(50) DEFAULT '',
  `strCustomStr19` varchar(50) DEFAULT '',
  `strCustomStr20` varchar(50) DEFAULT '',
  `strCustomStr21` varchar(50) DEFAULT '',
  `strCustomStr22` varchar(50) DEFAULT '',
  `strCustomStr23` varchar(50) DEFAULT '',
  `strCustomStr24` varchar(50) DEFAULT '',
  `strCustomStr25` varchar(50) DEFAULT '',
  `dblCustomDbl11` double DEFAULT '0',
  `dblCustomDbl12` double DEFAULT '0',
  `dblCustomDbl13` double DEFAULT '0',
  `dblCustomDbl14` double DEFAULT '0',
  `dblCustomDbl15` double DEFAULT '0',
  `dblCustomDbl16` double DEFAULT '0',
  `dblCustomDbl17` double DEFAULT '0',
  `dblCustomDbl18` double DEFAULT '0',
  `dblCustomDbl19` double DEFAULT '0',
  `dblCustomDbl20` double DEFAULT '0',
  `dtCustomDt6` date DEFAULT NULL,
  `dtCustomDt7` date DEFAULT NULL,
  `dtCustomDt8` date DEFAULT NULL,
  `dtCustomDt9` date DEFAULT NULL,
  `dtCustomDt10` date DEFAULT NULL,
  `dtCustomDt11` date DEFAULT NULL,
  `dtCustomDt12` date DEFAULT NULL,
  `dtCustomDt13` date DEFAULT NULL,
  `dtCustomDt14` date DEFAULT NULL,
  `dtCustomDt15` date DEFAULT NULL,
  `intCustomBool6` tinyint(4) DEFAULT '0',
  `intCustomBool7` tinyint(4) DEFAULT '0',
  PRIMARY KEY (`intMemberAssociationID`),
  UNIQUE KEY `index_AssocMember` (`intAssocID`,`intMemberID`),
  KEY `index_intMemberID` (`intMemberID`),
  KEY `index_intAssociationID` (`intAssocID`),
  KEY `index_intStatus` (`intRecStatus`),
  KEY `index_AssocStatus` (`intAssocID`,`intRecStatus`),
  KEY `index_AssocMemberStatus` (`intAssocID`,`intMemberID`,`intRecStatus`)
) ENGINE=MyISAM AUTO_INCREMENT=11821947 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblMember_Associations`
--

LOCK TABLES `tblMember_Associations` WRITE;
/*!40000 ALTER TABLE `tblMember_Associations` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblMember_Associations` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblMember_Clubs`
--

DROP TABLE IF EXISTS `tblMember_Clubs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblMember_Clubs` (
  `intMemberClubID` int(11) NOT NULL AUTO_INCREMENT,
  `intMemberID` int(11) NOT NULL DEFAULT '0',
  `intClubID` int(11) NOT NULL DEFAULT '0',
  `intGradeID` int(11) DEFAULT NULL,
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `intStatus` int(11) NOT NULL DEFAULT '0',
  `intPermit` tinyint(4) DEFAULT '0',
  `dtPermitStart` datetime DEFAULT NULL,
  `dtPermitEnd` datetime DEFAULT NULL,
  `strContractNo` varchar(50) DEFAULT NULL,
  `strContractYear` varchar(10) DEFAULT NULL,
  `intPrimaryClub` int(11) DEFAULT NULL,
  `dtContractEntered` date DEFAULT NULL,
  PRIMARY KEY (`intMemberClubID`),
  KEY `index_intMemberID` (`intMemberID`),
  KEY `index_intClubID` (`intClubID`),
  KEY `index_intStatus` (`intStatus`),
  KEY `index_ClubStatus` (`intClubID`,`intStatus`),
  KEY `index_ClubMemberStatus` (`intClubID`,`intMemberID`,`intStatus`),
  KEY `index_StatusGrade` (`intStatus`,`intGradeID`),
  KEY `index_GradeStatus` (`intGradeID`,`intStatus`)
) ENGINE=MyISAM AUTO_INCREMENT=10518555 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblMember_Clubs`
--

LOCK TABLES `tblMember_Clubs` WRITE;
/*!40000 ALTER TABLE `tblMember_Clubs` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblMember_Clubs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblMember_ClubsClearedOut`
--

DROP TABLE IF EXISTS `tblMember_ClubsClearedOut`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblMember_ClubsClearedOut` (
  `intMemberID` int(11) NOT NULL DEFAULT '0',
  `intRealmID` int(11) NOT NULL DEFAULT '0',
  `intAssocID` int(11) NOT NULL DEFAULT '0',
  `intClubID` int(11) NOT NULL DEFAULT '0',
  `intClearanceID` int(11) DEFAULT '0',
  `intCurrentSeasonID` int(11) DEFAULT '0',
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`intMemberID`,`intRealmID`,`intAssocID`,`intClubID`),
  KEY `index_intClubID` (`intClubID`),
  KEY `index_intAssocID` (`intAssocID`),
  KEY `index_intClearanceID` (`intClearanceID`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblMember_ClubsClearedOut`
--

LOCK TABLES `tblMember_ClubsClearedOut` WRITE;
/*!40000 ALTER TABLE `tblMember_ClubsClearedOut` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblMember_ClubsClearedOut` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblMember_Seasons_1`
--

DROP TABLE IF EXISTS `tblMember_Seasons_1`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblMember_Seasons_1` (
  `intMemberSeasonID` int(11) NOT NULL AUTO_INCREMENT,
  `intMemberID` int(11) NOT NULL DEFAULT '0',
  `intAssocID` int(11) NOT NULL DEFAULT '0',
  `intClubID` int(11) NOT NULL DEFAULT '0',
  `intSeasonID` int(11) NOT NULL DEFAULT '0',
  `intMSRecStatus` int(11) NOT NULL DEFAULT '1',
  `intSeasonMemberPackageID` int(11) DEFAULT '0',
  `intPlayerAgeGroupID` int(11) DEFAULT '0',
  `intPlayerStatus` tinyint(4) DEFAULT '0',
  `intPlayerFinancialStatus` tinyint(4) DEFAULT '0',
  `intCoachStatus` tinyint(4) DEFAULT '0',
  `intCoachFinancialStatus` tinyint(4) DEFAULT '0',
  `intUmpireStatus` tinyint(4) DEFAULT '0',
  `intUmpireFinancialStatus` tinyint(4) DEFAULT '0',
  `intOther1Status` tinyint(4) DEFAULT '0',
  `intOther1FinancialStatus` tinyint(4) DEFAULT '0',
  `intOther2Status` tinyint(4) DEFAULT '0',
  `intOther2FinancialStatus` tinyint(4) DEFAULT '0',
  `dtInPlayer` date DEFAULT NULL,
  `dtOutPlayer` date DEFAULT NULL,
  `dtInCoach` date DEFAULT NULL,
  `dtOutCoach` date DEFAULT NULL,
  `dtInUmpire` date DEFAULT NULL,
  `dtOutUmpire` date DEFAULT NULL,
  `dtInOther1` date DEFAULT NULL,
  `dtOutOther1` date DEFAULT NULL,
  `dtInOther2` date DEFAULT NULL,
  `dtOutOther2` date DEFAULT NULL,
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `intUsedRegoForm` tinyint(4) DEFAULT '0',
  `dtLastUsedRegoForm` datetime DEFAULT NULL,
  `intUsedRegoFormID` int(11) DEFAULT '0',
  `intNatReportingGroupID` int(11) NOT NULL DEFAULT '0',
  `dtCreated` datetime DEFAULT NULL,
  `intPlayerPending` tinyint(4) DEFAULT '0',
  PRIMARY KEY (`intMemberSeasonID`),
  UNIQUE KEY `index_intIDs` (`intMemberID`,`intAssocID`,`intSeasonID`,`intClubID`),
  KEY `index_intMAs` (`intMemberID`,`intClubID`,`intAssocID`),
  KEY `index_intSeasonID` (`intSeasonID`),
  KEY `index_intMSRecStatus` (`intMSRecStatus`),
  KEY `index_intAssocID` (`intAssocID`),
  KEY `index_intClubID` (`intClubID`),
  KEY `index_intNatReportingGroupID` (`intNatReportingGroupID`,`intMemberID`),
  KEY `intPlayerPending` (`intPlayerPending`)
) ENGINE=MyISAM AUTO_INCREMENT=1085401 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblMember_Seasons_1`
--

LOCK TABLES `tblMember_Seasons_1` WRITE;
/*!40000 ALTER TABLE `tblMember_Seasons_1` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblMember_Seasons_1` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblMember_Types`
--

DROP TABLE IF EXISTS `tblMember_Types`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblMember_Types` (
  `intMemberTypeID` int(11) NOT NULL AUTO_INCREMENT,
  `intMemberID` int(11) NOT NULL DEFAULT '0',
  `intTypeID` int(11) NOT NULL DEFAULT '0',
  `intSubTypeID` int(11) NOT NULL DEFAULT '0',
  `intActive` tinyint(4) NOT NULL DEFAULT '0',
  `strString1` varchar(100) DEFAULT NULL,
  `strString2` varchar(100) DEFAULT NULL,
  `strString3` varchar(100) DEFAULT NULL,
  `strString4` varchar(100) DEFAULT NULL,
  `strString5` varchar(100) DEFAULT NULL,
  `strString6` varchar(100) DEFAULT NULL,
  `intInt1` int(11) DEFAULT '0',
  `intInt2` int(11) DEFAULT '0',
  `intInt3` int(11) DEFAULT '0',
  `intInt4` int(11) DEFAULT '0',
  `intInt5` int(11) DEFAULT '0',
  `intInt6` int(11) DEFAULT '0',
  `intInt7` int(11) DEFAULT '0',
  `intInt8` int(11) DEFAULT '0',
  `intInt9` int(11) DEFAULT '0',
  `intInt10` int(11) DEFAULT '0',
  `dtDate1` date DEFAULT NULL,
  `dtDate2` date DEFAULT NULL,
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `intAssocID` int(11) NOT NULL DEFAULT '0',
  `intRecStatus` tinyint(4) DEFAULT '0',
  `dtDate3` datetime DEFAULT NULL,
  PRIMARY KEY (`intMemberTypeID`),
  KEY `index_intMemberID` (`intMemberID`),
  KEY `index_intTypeID` (`intTypeID`),
  KEY `index_intSubTypeID` (`intSubTypeID`),
  KEY `index_intAssocID` (`intAssocID`),
  KEY `IDNEX_intRecStatus` (`intRecStatus`),
  KEY `index_MemberTypeSub` (`intMemberID`,`intTypeID`,`intSubTypeID`),
  KEY `index_MemberAssocTypeSub` (`intMemberID`,`intAssocID`,`intTypeID`,`intSubTypeID`),
  KEY `index_intAssocIDTypeSubTstamp` (`intAssocID`,`intTypeID`,`intSubTypeID`,`tTimeStamp`)
) ENGINE=MyISAM AUTO_INCREMENT=9169921 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblMember_Types`
--

LOCK TABLES `tblMember_Types` WRITE;
/*!40000 ALTER TABLE `tblMember_Types` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblMember_Types` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblMoneyLog`
--

DROP TABLE IF EXISTS `tblMoneyLog`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblMoneyLog` (
  `intMoneyLogID` int(11) NOT NULL AUTO_INCREMENT,
  `curMoney` decimal(16,2) DEFAULT NULL,
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `intRealmID` int(11) DEFAULT '0',
  `intRealmSubTypeID` int(11) DEFAULT '0',
  `intAssocID` int(11) DEFAULT '0',
  `intClubID` int(11) DEFAULT '0',
  `intTransactionID` int(11) DEFAULT '0',
  `intTransLogID` int(11) DEFAULT '0',
  `strFrom` varchar(100) DEFAULT '',
  `dtEntered` date DEFAULT NULL,
  `strMPEmail` varchar(255) DEFAULT '',
  `intExportBankFileID` int(11) DEFAULT '0',
  `intMYOBExportID` int(11) DEFAULT '0',
  `intEntityType` int(11) DEFAULT '0',
  `intEntityID` int(11) DEFAULT '0',
  `intLogType` int(11) DEFAULT '0',
  `strBankCode` varchar(100) DEFAULT '',
  `strAccountNo` varchar(100) DEFAULT '',
  `strAccountName` varchar(100) DEFAULT '',
  `intRuleID` int(11) DEFAULT '0',
  `intSplitID` int(11) DEFAULT '0',
  `intSplitItemID` int(11) DEFAULT '0',
  `strCurrencyCode` varchar(10) DEFAULT '',
  `dblGSTRate` double DEFAULT '0',
  PRIMARY KEY (`intMoneyLogID`),
  UNIQUE KEY `index_Unique` (`intLogType`,`intTransLogID`,`intTransactionID`,`intEntityID`,`intEntityType`,`curMoney`),
  KEY `index_realmID` (`intRealmID`),
  KEY `index_logType` (`intLogType`),
  KEY `index_txnIDs` (`intTransLogID`,`intTransactionID`),
  KEY `index_assocClubIDs` (`intAssocID`,`intClubID`)
) ENGINE=MyISAM AUTO_INCREMENT=2749061 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblMoneyLog`
--

LOCK TABLES `tblMoneyLog` WRITE;
/*!40000 ALTER TABLE `tblMoneyLog` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblMoneyLog` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblNationalPeriod`
--

DROP TABLE IF EXISTS `tblNationalPeriod`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblNationalPeriod` (
  `intNationalPeriodID` int(11) NOT NULL AUTO_INCREMENT,
  `strNationalPeriodName` varchar(100) DEFAULT NULL,
  `strSport` varchar(20) DEFAULT '',
  `intRealmID` int(11) DEFAULT NULL,
  `intSubRealmID` int(11) DEFAULT NULL,
  `dtFrom` date DEFAULT NULL,
  `dtTo` date DEFAULT NULL,
  `intCurrentNew` tinyint(4) DEFAULT '0',
  `intCurrentRenewal` tinyint(4) DEFAULT '0',
  `strPersonType` varchar(20) DEFAULT '',
  `intCurrentTransfer` tinyint(4) DEFAULT '0',
  PRIMARY KEY (`intNationalPeriodID`),
  KEY `index_intRealm` (`intRealmID`,`intSubRealmID`,`strSport`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblNationalPeriod`
--

LOCK TABLES `tblNationalPeriod` WRITE;
/*!40000 ALTER TABLE `tblNationalPeriod` DISABLE KEYS */;
INSERT INTO `tblNationalPeriod` VALUES (1,'2008','',1,0,'2008-01-01','2008-11-30',0,0,'',0),(2,'2009','',1,0,'2009-01-01','2009-11-30',0,0,'',0),(3,'2010','',1,0,'2010-01-01','2010-11-30',0,0,'',0),(4,'2011','',1,0,'2011-01-01','2011-11-30',0,0,'',0),(5,'2012','',1,0,'2012-01-01','2012-11-30',0,0,'',0),(6,'2013','',1,0,'2013-01-01','2013-11-30',0,0,'',0),(7,'2014','',1,0,'2014-01-01','2014-11-30',0,0,'',0),(8,'2015','',1,0,'2015-01-01','2015-11-30',1,1,'',1),(9,'2016','',1,0,'2016-01-01','2016-11-30',0,0,'',0);
/*!40000 ALTER TABLE `tblNationalPeriod` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblNode`
--

DROP TABLE IF EXISTS `tblNode`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblNode` (
  `intNodeID` int(11) NOT NULL AUTO_INCREMENT,
  `intTypeID` int(11) NOT NULL DEFAULT '0',
  `intStatusID` tinyint(4) NOT NULL DEFAULT '1',
  `strName` varchar(150) NOT NULL DEFAULT '',
  `strNameAbbrev` varchar(50) DEFAULT NULL,
  `strContact` varchar(50) DEFAULT NULL,
  `strAddress1` varchar(50) DEFAULT NULL,
  `strAddress2` varchar(50) DEFAULT NULL,
  `strSuburb` varchar(50) DEFAULT NULL,
  `strState` varchar(50) DEFAULT NULL,
  `strCountry` varchar(50) DEFAULT NULL,
  `strPostalCode` varchar(15) DEFAULT NULL,
  `strPhone` varchar(20) DEFAULT NULL,
  `strFax` varchar(20) DEFAULT NULL,
  `strEmail` varchar(250) NOT NULL DEFAULT '',
  `strNotes` text,
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `intDataAccess` int(11) NOT NULL DEFAULT '10',
  `intRealmID` int(11) NOT NULL DEFAULT '0',
  `intSubTypeID` int(11) NOT NULL DEFAULT '0',
  `intAlternateID_tmp` int(11) DEFAULT NULL,
  `intRegionalManagerID_tmp` int(11) DEFAULT NULL,
  `intHideClearances` tinyint(4) DEFAULT '0',
  `intEstParticipants` int(11) DEFAULT '0',
  `intEstRegPlayers` int(11) DEFAULT '0',
  `intEstUnRegPlayers` int(11) DEFAULT '0',
  PRIMARY KEY (`intNodeID`),
  KEY `index_strName` (`strName`),
  KEY `index_intStatusID` (`intStatusID`),
  KEY `index_intTypeID` (`intTypeID`),
  KEY `index_intDataAccess` (`intDataAccess`),
  KEY `index_IDDataAccess` (`intNodeID`,`intDataAccess`),
  KEY `index_Type_ID` (`intNodeID`,`intTypeID`),
  KEY `index_Type_IDAccess` (`intNodeID`,`intTypeID`,`intDataAccess`),
  KEY `index_RealmID` (`intRealmID`)
) ENGINE=MyISAM AUTO_INCREMENT=7327 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblNode`
--

LOCK TABLES `tblNode` WRITE;
/*!40000 ALTER TABLE `tblNode` DISABLE KEYS */;
INSERT INTO `tblNode` VALUES (1,100,1,'Finland',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'',NULL,'2014-01-15 23:37:22',10,1,1,NULL,NULL,0,0,0,0),(2,30,0,'Finland',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'',NULL,'2014-01-15 23:37:22',10,1,1,NULL,NULL,0,0,0,0),(3,20,0,'Finland',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'',NULL,'2014-01-15 23:37:22',10,1,1,NULL,NULL,0,0,0,0),(4,10,0,'Finland',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'',NULL,'2014-01-15 23:37:22',10,1,1,NULL,NULL,0,0,0,0),(5,100,1,'Singapore',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'',NULL,'2014-01-15 23:37:22',10,1,2,NULL,NULL,0,0,0,0),(6,30,0,'Singapore',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'',NULL,'2014-01-15 23:37:22',10,1,2,NULL,NULL,0,0,0,0),(7,20,0,'Singapore',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'',NULL,'2014-01-15 23:37:22',10,1,2,NULL,NULL,0,0,0,0),(8,10,0,'Singapore',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'',NULL,'2014-01-15 23:37:22',10,1,2,NULL,NULL,0,0,0,0),(7324,30,0,'',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'',NULL,'2014-05-16 01:33:55',10,1,1,NULL,NULL,0,0,0,0),(7325,20,0,'',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'',NULL,'2014-05-16 01:33:55',10,1,1,NULL,NULL,0,0,0,0),(7326,10,0,'',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'',NULL,'2014-05-16 01:33:55',10,1,1,NULL,NULL,0,0,0,0);
/*!40000 ALTER TABLE `tblNode` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblNodeLinks`
--

DROP TABLE IF EXISTS `tblNodeLinks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblNodeLinks` (
  `intNodeLinksID` int(11) NOT NULL AUTO_INCREMENT,
  `intParentNodeID` int(11) NOT NULL DEFAULT '0',
  `intChildNodeID` int(11) NOT NULL DEFAULT '0',
  `intPrimary` tinyint(4) NOT NULL DEFAULT '1',
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`intNodeLinksID`),
  KEY `index_intParentNodeID` (`intParentNodeID`),
  KEY `index_intChildNodeID` (`intChildNodeID`),
  KEY `index_intPrimary` (`intPrimary`),
  KEY `index_Both` (`intParentNodeID`,`intChildNodeID`),
  KEY `index_triple` (`intParentNodeID`,`intChildNodeID`,`intPrimary`)
) ENGINE=MyISAM AUTO_INCREMENT=7163 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblNodeLinks`
--

LOCK TABLES `tblNodeLinks` WRITE;
/*!40000 ALTER TABLE `tblNodeLinks` DISABLE KEYS */;
INSERT INTO `tblNodeLinks` VALUES (7154,1,2,1,'2014-01-15 23:37:22'),(7155,2,3,1,'2014-01-15 23:37:22'),(7156,3,4,1,'2014-01-15 23:37:22'),(7157,5,6,1,'2014-01-15 23:37:22'),(7158,6,7,1,'2014-01-15 23:37:22'),(7159,7,8,1,'2014-01-15 23:37:22'),(7160,1,7324,1,'2014-05-16 01:33:55'),(7161,7324,7325,1,'2014-05-16 01:33:55'),(7162,7325,7326,1,'2014-05-16 01:33:55');
/*!40000 ALTER TABLE `tblNodeLinks` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblNotifications`
--

DROP TABLE IF EXISTS `tblNotifications`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblNotifications` (
  `intNotificationID` int(11) NOT NULL AUTO_INCREMENT,
  `intEntityTypeID` int(11) NOT NULL,
  `intEntityID` int(11) NOT NULL,
  `dtDateTime` datetime DEFAULT NULL,
  `strNotificationType` varchar(30) DEFAULT '',
  `strTitle` varchar(100) DEFAULT '',
  `intReferenceID` int(11) NOT NULL DEFAULT '0',
  `strMoreInfo` text,
  `strURL` varchar(250) NOT NULL DEFAULT '',
  `intNotificationStatus` tinyint(4) DEFAULT '0',
  `strMoreInfoURLs` text,
  `strNotes` text,
  PRIMARY KEY (`intNotificationID`),
  UNIQUE KEY `index_unique` (`intEntityTypeID`,`intEntityID`,`strNotificationType`,`intReferenceID`)
) ENGINE=MyISAM AUTO_INCREMENT=544502 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblNotifications`
--

LOCK TABLES `tblNotifications` WRITE;
/*!40000 ALTER TABLE `tblNotifications` DISABLE KEYS */;
INSERT INTO `tblNotifications` VALUES (544501,5,16,'2014-06-04 10:25:07','duplicates','You have 723 duplicates to resolve.',0,'','main.cgi?client=XXX_CLIENT_XXX&amp;a=DUPL_L',0,'',NULL);
/*!40000 ALTER TABLE `tblNotifications` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblOrgCharacteristics`
--

DROP TABLE IF EXISTS `tblOrgCharacteristics`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblOrgCharacteristics` (
  `intCharacteristicID` int(11) NOT NULL AUTO_INCREMENT,
  `intRealmID` int(11) NOT NULL DEFAULT '0',
  `intSubRealmID` int(11) NOT NULL DEFAULT '0',
  `intEntityLevel` int(11) NOT NULL DEFAULT '0',
  `strName` varchar(200) DEFAULT NULL,
  `strAbbrev` varchar(20) DEFAULT NULL,
  `intLocator` tinyint(4) DEFAULT '0',
  `intOrder` tinyint(3) unsigned DEFAULT '50',
  `intRecStatus` tinyint(4) DEFAULT '1',
  PRIMARY KEY (`intCharacteristicID`),
  KEY `index_realm` (`intRealmID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblOrgCharacteristics`
--

LOCK TABLES `tblOrgCharacteristics` WRITE;
/*!40000 ALTER TABLE `tblOrgCharacteristics` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblOrgCharacteristics` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblPMSHold`
--

DROP TABLE IF EXISTS `tblPMSHold`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblPMSHold` (
  `intPMSHoldingBayID` int(11) NOT NULL AUTO_INCREMENT,
  `strMassPayEmail` varchar(200) DEFAULT '',
  `intRealmID` int(11) DEFAULT '0',
  `intTransLogOnHoldID` int(11) DEFAULT '0',
  `intMassPayReturnedOnID` int(11) DEFAULT '0',
  `intHoldStatus` tinyint(4) DEFAULT '0',
  `curAmountToHold` decimal(16,2) DEFAULT '0.00',
  `curBalanceToHold` decimal(16,2) DEFAULT '0.00',
  `dtHeld` datetime DEFAULT NULL,
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `strHeldComments` text,
  `strBSB` varchar(50) DEFAULT '',
  `strAccNum` varchar(50) DEFAULT '',
  `strAccName` varchar(50) DEFAULT '',
  PRIMARY KEY (`intPMSHoldingBayID`),
  UNIQUE KEY `index_unique` (`strMassPayEmail`,`intTransLogOnHoldID`),
  KEY `index_strMassPayEmail` (`strMassPayEmail`),
  KEY `index_intTransLogID` (`intTransLogOnHoldID`),
  KEY `index_intRealmID` (`intRealmID`)
) ENGINE=MyISAM AUTO_INCREMENT=4795 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblPMSHold`
--

LOCK TABLES `tblPMSHold` WRITE;
/*!40000 ALTER TABLE `tblPMSHold` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblPMSHold` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblPMS_MassPayHolds`
--

DROP TABLE IF EXISTS `tblPMS_MassPayHolds`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblPMS_MassPayHolds` (
  `intHoldID` int(11) NOT NULL AUTO_INCREMENT,
  `intPMSHoldingBayID` int(11) NOT NULL,
  `curHold` decimal(16,2) DEFAULT '0.00',
  `intMassPayHeldOnID` int(11) DEFAULT '0',
  `intRealmID` int(11) DEFAULT '0',
  `intHoldStatus` tinyint(4) DEFAULT '0',
  `dtHeld` datetime DEFAULT NULL,
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`intHoldID`),
  KEY `index_intID` (`intPMSHoldingBayID`)
) ENGINE=MyISAM AUTO_INCREMENT=2666 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblPMS_MassPayHolds`
--

LOCK TABLES `tblPMS_MassPayHolds` WRITE;
/*!40000 ALTER TABLE `tblPMS_MassPayHolds` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblPMS_MassPayHolds` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblPassportAuth`
--

DROP TABLE IF EXISTS `tblPassportAuth`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblPassportAuth` (
  `intPassportID` int(11) NOT NULL,
  `intEntityTypeID` int(11) NOT NULL,
  `intEntityID` int(11) NOT NULL,
  `intAssocID` int(11) NOT NULL DEFAULT '0',
  `intLogins` int(11) DEFAULT '0',
  `intReadOnly` tinyint(4) DEFAULT '0',
  `intRoleID` int(11) NOT NULL DEFAULT '0',
  `dtLastlogin` datetime DEFAULT NULL,
  `dtCreated` datetime DEFAULT NULL,
  PRIMARY KEY (`intPassportID`,`intEntityTypeID`,`intEntityID`),
  KEY `index_entity` (`intEntityTypeID`,`intEntityID`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblPassportAuth`
--

LOCK TABLES `tblPassportAuth` WRITE;
/*!40000 ALTER TABLE `tblPassportAuth` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblPassportAuth` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblPassportMember`
--

DROP TABLE IF EXISTS `tblPassportMember`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblPassportMember` (
  `intPassportID` int(11) NOT NULL,
  `intMemberID` int(11) NOT NULL,
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`intPassportID`,`intMemberID`),
  KEY `index_member` (`intMemberID`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblPassportMember`
--

LOCK TABLES `tblPassportMember` WRITE;
/*!40000 ALTER TABLE `tblPassportMember` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblPassportMember` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblPayPalEmailLog`
--

DROP TABLE IF EXISTS `tblPayPalEmailLog`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblPayPalEmailLog` (
  `intPayPalEmailLogID` int(11) NOT NULL AUTO_INCREMENT,
  `intEntityTypeID` int(11) NOT NULL,
  `intEntityID` int(11) NOT NULL,
  `tTimestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `strEmail` varchar(250) DEFAULT NULL,
  `strUsername` varchar(30) NOT NULL,
  `intLoginEntityTypeID` int(11) NOT NULL,
  `intLoginEntityID` int(11) NOT NULL,
  PRIMARY KEY (`intPayPalEmailLogID`),
  KEY `index_entity` (`intEntityTypeID`,`intEntityID`)
) ENGINE=MyISAM AUTO_INCREMENT=126 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblPayPalEmailLog`
--

LOCK TABLES `tblPayPalEmailLog` WRITE;
/*!40000 ALTER TABLE `tblPayPalEmailLog` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblPayPalEmailLog` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblPayTry`
--

DROP TABLE IF EXISTS `tblPayTry`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblPayTry` (
  `intTryID` int(11) NOT NULL AUTO_INCREMENT,
  `intRealmID` int(11) DEFAULT '0',
  `strPayReference` varchar(100) DEFAULT '',
  `intTransLogID` int(11) DEFAULT '0',
  `strLog` text,
  `dtTry` datetime DEFAULT NULL,
  `tTimeStamp` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`intTryID`),
  KEY `index_realmID` (`intRealmID`),
  KEY `index_transLogID` (`intTransLogID`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblPayTry`
--

LOCK TABLES `tblPayTry` WRITE;
/*!40000 ALTER TABLE `tblPayTry` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblPayTry` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblPaymentApplication`
--

DROP TABLE IF EXISTS `tblPaymentApplication`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblPaymentApplication` (
  `intApplicationID` int(11) NOT NULL AUTO_INCREMENT,
  `intEntityTypeID` int(11) NOT NULL,
  `intEntityID` int(11) NOT NULL,
  `intRealmID` int(11) NOT NULL,
  `strOrgName` varchar(200) DEFAULT NULL,
  `strACN` varchar(50) DEFAULT NULL,
  `strABN` varchar(50) DEFAULT NULL,
  `strContact` varchar(200) DEFAULT NULL,
  `strContactPhone` varchar(50) DEFAULT NULL,
  `strMailingAddress` varchar(255) DEFAULT NULL,
  `strSuburb` varchar(200) DEFAULT NULL,
  `strPostalCode` varchar(20) DEFAULT NULL,
  `strOrgPhone` varchar(50) DEFAULT NULL,
  `strOrgFax` varchar(50) DEFAULT NULL,
  `strOrgEmail` varchar(255) DEFAULT NULL,
  `strPaymentEmail` varchar(255) DEFAULT NULL,
  `strAgreedBy` varchar(255) DEFAULT NULL,
  `dtCreated` datetime DEFAULT NULL,
  `strState` varchar(100) DEFAULT NULL,
  `strSoftDescriptor` varchar(20) DEFAULT '',
  `tPATimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `intPaymentType` int(11) DEFAULT '0',
  `strApplicantTitle` varchar(5) DEFAULT '',
  `strApplicantFirstName` varchar(50) DEFAULT '',
  `strApplicantInitial` varchar(50) DEFAULT '',
  `strApplicantFamilyName` varchar(50) DEFAULT '',
  `strApplicantPosition` varchar(50) DEFAULT '',
  `strShortBusName` varchar(50) DEFAULT '',
  `strStreetAddress1` varchar(150) DEFAULT '',
  `strStreetAddress2` varchar(150) DEFAULT '',
  `strURL` varchar(250) DEFAULT '',
  `intIncorpStatus` tinyint(4) DEFAULT '0',
  `intGST` tinyint(4) DEFAULT '0',
  `intNumberTxns` int(11) DEFAULT '0',
  `intAvgCost` int(11) DEFAULT '0',
  `intTotalTurnover` int(11) DEFAULT '0',
  `strOB1_FirstName` varchar(50) DEFAULT '',
  `strOB1_FamilyName` varchar(50) DEFAULT '',
  `strOB1_Position` varchar(50) DEFAULT '',
  `strOB1_Phone` varchar(50) DEFAULT '',
  `strOB2_FirstName` varchar(50) DEFAULT '',
  `strOB2_FamilyName` varchar(50) DEFAULT '',
  `strOB2_Position` varchar(50) DEFAULT '',
  `strOB2_Phone` varchar(50) DEFAULT '',
  `intApplicationStatus` tinyint(4) DEFAULT '0',
  `strApplicantEmail` varchar(255) DEFAULT '',
  `strApplicantPhone` varchar(50) DEFAULT '',
  `strOB1_Email` varchar(255) DEFAULT '',
  `strOB2_Email` varchar(255) DEFAULT '',
  `intHasBankAccount` tinyint(4) DEFAULT '0',
  `strBSB` varchar(10) DEFAULT '',
  `strAccountNum` varchar(10) DEFAULT '',
  `strARBN` varchar(50) DEFAULT '',
  `strOrgType` varchar(150) DEFAULT '',
  `intLocked` tinyint(4) DEFAULT '1',
  `strOrgTypeOther` varchar(150) DEFAULT '',
  `intPreviousApplication` tinyint(4) DEFAULT '0',
  `strApplicationNotes` text,
  `strParentCode` varchar(10) DEFAULT '',
  `strShortLegalName` varchar(40) DEFAULT NULL,
  `strVoucherCode` varchar(30) DEFAULT '',
  `strShortBankName` varchar(18) DEFAULT '',
  `strParentMerchantCode` varchar(255) DEFAULT NULL,
  `strParentMerchantName` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`intApplicationID`),
  UNIQUE KEY `intIDs` (`intEntityTypeID`,`intEntityID`,`intPaymentType`),
  KEY `index_entity` (`intEntityTypeID`,`intEntityID`),
  KEY `index_realm` (`intRealmID`)
) ENGINE=MyISAM AUTO_INCREMENT=15087 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblPaymentApplication`
--

LOCK TABLES `tblPaymentApplication` WRITE;
/*!40000 ALTER TABLE `tblPaymentApplication` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblPaymentApplication` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblPaymentConfig`
--

DROP TABLE IF EXISTS `tblPaymentConfig`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblPaymentConfig` (
  `intPaymentConfigID` int(11) NOT NULL AUTO_INCREMENT,
  `intRealmID` int(11) DEFAULT '0',
  `intRealmSubTypeID` int(11) DEFAULT '0',
  `intPaymentType` tinyint(4) DEFAULT '0',
  `intAllowPaymentBackend` tinyint(4) DEFAULT '0',
  `intAllowPaymentRegoForm` tinyint(4) DEFAULT '0',
  `intAllowPayment` tinyint(4) DEFAULT '0',
  `intGatewayStatus` tinyint(4) DEFAULT '0',
  `intFeeAllocationType` tinyint(4) DEFAULT '0',
  `strCurrency` char(5) DEFAULT 'AUD',
  `intPaymentGatewayID` int(11) DEFAULT '0',
  `strGatewayURL1` varchar(200) DEFAULT '',
  `strGatewayURL2` varchar(200) DEFAULT '',
  `strGatewayURL3` varchar(200) DEFAULT '',
  `strReturnURL` varchar(150) NOT NULL,
  `strReturnExternalURL` varchar(150) NOT NULL,
  `strReturnFailureURL` varchar(150) NOT NULL,
  `strReturnExternalFailureURL` varchar(150) NOT NULL,
  `strGatewayUsername` varchar(100) DEFAULT '',
  `strGatewayPassword` varchar(100) DEFAULT '',
  `strGatewaySignature` varchar(100) DEFAULT '',
  `strGatewaySalt` varchar(50) DEFAULT '',
  `strNotificationAddress` varchar(250) DEFAULT NULL,
  `strPaymentBusinessNumber` varchar(100) DEFAULT '',
  `strPaymentInfo` text,
  `strPaymentReceiptBodyTEXT` text,
  `strPaymentReceiptBodyHTML` text,
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `strGatewayName` varchar(100) DEFAULT '',
  `strGatewayVersion` varchar(50) DEFAULT '',
  `strCancelURL` varchar(150) DEFAULT '',
  `strGatewayImage` varchar(150) DEFAULT '',
  `strGatewayCode` varchar(20) DEFAULT '',
  PRIMARY KEY (`intPaymentConfigID`),
  UNIQUE KEY `intRealmID` (`intRealmID`,`intRealmSubTypeID`,`intPaymentType`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblPaymentConfig`
--

LOCK TABLES `tblPaymentConfig` WRITE;
/*!40000 ALTER TABLE `tblPaymentConfig` DISABLE KEYS */;
INSERT INTO `tblPaymentConfig` VALUES (1,0,0,11,1,1,1,0,1,'NZD',1,'https://api-3t.sandbox.paypal.com/nvp','https://www.sandbox.paypal.com/cgi-bin/webscr?cmd=_express-checkout','https://api-3t.sandbox.paypal.com/nvp','/paypal.cgi?a=S','','','','viking_1249435445_biz_api1.sportingpulse.com','ZKHXCXW5CLB64TYD','AKYuXVkhF40sNXmNNcLlWmaJDyVGARqyuo3ZsCtrPCYJAJsrcypjK5n2','1234A','bruce@antembo.com','1234','','','','2014-10-16 06:00:05','PayPal Gateway','58.0','/paypal.cgi?a=C','https://fpdbs.paypal.com/dynamicimagesweb?cmd=_dynamic-image',''),(2,1,0,13,1,1,1,1,1,'NZD',1,'http://fspotest.sportingpulseinternational.com/ExternalGateways/NAB/nabform.cgi','','','','','','','','','','1234A','bruce@antembo.com','1234','','','','2014-11-20 03:03:40','NAB Gateway','58.0','','','NABExt1');
/*!40000 ALTER TABLE `tblPaymentConfig` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblPaymentExclusions`
--

DROP TABLE IF EXISTS `tblPaymentExclusions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblPaymentExclusions` (
  `intPaymentExclusionID` int(11) NOT NULL AUTO_INCREMENT,
  `strHoliday` varchar(100) DEFAULT NULL,
  `strDate` date DEFAULT NULL,
  PRIMARY KEY (`intPaymentExclusionID`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblPaymentExclusions`
--

LOCK TABLES `tblPaymentExclusions` WRITE;
/*!40000 ALTER TABLE `tblPaymentExclusions` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblPaymentExclusions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblPaymentSplit`
--

DROP TABLE IF EXISTS `tblPaymentSplit`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblPaymentSplit` (
  `intSplitID` int(11) NOT NULL AUTO_INCREMENT,
  `intRuleID` int(11) NOT NULL,
  `intEntityTypeID` int(11) NOT NULL,
  `intEntityID` int(11) NOT NULL,
  `strSplitName` varchar(100) NOT NULL,
  PRIMARY KEY (`intSplitID`),
  KEY `intThing_key` (`intEntityTypeID`,`intEntityID`)
) ENGINE=MyISAM AUTO_INCREMENT=19277 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblPaymentSplit`
--

LOCK TABLES `tblPaymentSplit` WRITE;
/*!40000 ALTER TABLE `tblPaymentSplit` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblPaymentSplit` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblPaymentSplitFees`
--

DROP TABLE IF EXISTS `tblPaymentSplitFees`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblPaymentSplitFees` (
  `intFeesID` int(11) NOT NULL AUTO_INCREMENT,
  `intRealmID` int(11) NOT NULL,
  `intSubTypeID` int(11) NOT NULL DEFAULT '0',
  `intFeesType` tinyint(4) NOT NULL,
  `strBankCode` varchar(20) DEFAULT NULL,
  `strAccountNo` varchar(30) DEFAULT NULL,
  `strAccountName` varchar(250) DEFAULT NULL,
  `curAmount` decimal(10,2) DEFAULT NULL,
  `dblFactor` double DEFAULT NULL,
  `strMPEmail` varchar(127) DEFAULT '',
  `curMinFeePoint` decimal(10,2) DEFAULT '0.00',
  `intMinFeeProductID` int(11) DEFAULT '0',
  `curMaxFeePoint` decimal(10,2) DEFAULT NULL,
  `curMaxFee` decimal(10,2) DEFAULT NULL,
  `intMinFeeType` int(11) DEFAULT '0',
  `intFeeAllocationType` tinyint(4) DEFAULT '0',
  PRIMARY KEY (`intFeesID`),
  KEY `index_intRealm` (`intRealmID`,`intSubTypeID`)
) ENGINE=MyISAM AUTO_INCREMENT=125 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblPaymentSplitFees`
--

LOCK TABLES `tblPaymentSplitFees` WRITE;
/*!40000 ALTER TABLE `tblPaymentSplitFees` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblPaymentSplitFees` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblPaymentSplitItem`
--

DROP TABLE IF EXISTS `tblPaymentSplitItem`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblPaymentSplitItem` (
  `intItemID` int(11) NOT NULL AUTO_INCREMENT,
  `intSplitID` int(11) NOT NULL,
  `intLevelID` smallint(6) NOT NULL DEFAULT '0',
  `strOtherBankCode` varchar(20) DEFAULT NULL,
  `strOtherAccountNo` varchar(30) DEFAULT NULL,
  `strOtherAccountName` varchar(250) DEFAULT NULL,
  `curAmount` decimal(10,2) DEFAULT NULL,
  `dblFactor` double DEFAULT NULL,
  `intRemainder` tinyint(4) NOT NULL DEFAULT '0',
  `strMPEmail` varchar(127) DEFAULT '',
  PRIMARY KEY (`intItemID`),
  KEY `index_intSplitID` (`intSplitID`)
) ENGINE=MyISAM AUTO_INCREMENT=20172 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblPaymentSplitItem`
--

LOCK TABLES `tblPaymentSplitItem` WRITE;
/*!40000 ALTER TABLE `tblPaymentSplitItem` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblPaymentSplitItem` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblPaymentSplitLog`
--

DROP TABLE IF EXISTS `tblPaymentSplitLog`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblPaymentSplitLog` (
  `intLogID` int(11) NOT NULL AUTO_INCREMENT,
  `intExportBankFileID` int(11) NOT NULL,
  `intEntityTypeID` int(11) NOT NULL,
  `intEntityID` int(11) NOT NULL,
  `intAssocID` int(11) NOT NULL,
  `intClubID` int(11) NOT NULL,
  `strBankCode` varchar(20) DEFAULT NULL,
  `strAccountNo` varchar(30) DEFAULT NULL,
  `strAccountName` varchar(250) DEFAULT NULL,
  `strMPEmail` varchar(127) DEFAULT NULL,
  `curAmount` decimal(10,2) DEFAULT NULL,
  `intFeesType` tinyint(4) NOT NULL DEFAULT '0',
  `intMyobExportID` int(11) DEFAULT '0',
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`intLogID`),
  KEY `index_intIDs` (`intExportBankFileID`,`intLogID`),
  KEY `intThing_key` (`intEntityTypeID`,`intEntityID`),
  KEY `index_intMyobExportID` (`intMyobExportID`)
) ENGINE=MyISAM AUTO_INCREMENT=7518 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblPaymentSplitLog`
--

LOCK TABLES `tblPaymentSplitLog` WRITE;
/*!40000 ALTER TABLE `tblPaymentSplitLog` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblPaymentSplitLog` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblPaymentSplitMyobExport`
--

DROP TABLE IF EXISTS `tblPaymentSplitMyobExport`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblPaymentSplitMyobExport` (
  `intMyobExportID` int(11) NOT NULL AUTO_INCREMENT,
  `intPaymentType` tinyint(4) NOT NULL DEFAULT '0',
  `dtIncludeTo` date DEFAULT NULL,
  `intTotalInvs` int(11) DEFAULT '0',
  `curTotalAmount` decimal(10,2) DEFAULT '0.00',
  `dtRun` datetime DEFAULT NULL,
  `strCurrencyRun` varchar(10) DEFAULT '',
  `strRunName` varchar(50) DEFAULT '',
  PRIMARY KEY (`intMyobExportID`)
) ENGINE=MyISAM AUTO_INCREMENT=229 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblPaymentSplitMyobExport`
--

LOCK TABLES `tblPaymentSplitMyobExport` WRITE;
/*!40000 ALTER TABLE `tblPaymentSplitMyobExport` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblPaymentSplitMyobExport` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblPaymentSplitRule`
--

DROP TABLE IF EXISTS `tblPaymentSplitRule`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblPaymentSplitRule` (
  `intRuleID` int(11) NOT NULL AUTO_INCREMENT,
  `strRuleName` varchar(100) DEFAULT '',
  `strFinInst` varchar(10) DEFAULT '',
  `strUserName` varchar(30) DEFAULT '',
  `strUserNo` varchar(30) DEFAULT '',
  `strFileDesc` varchar(30) DEFAULT '',
  `intRealmID` int(11) DEFAULT NULL,
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `strBSB` varchar(10) DEFAULT '',
  `strAccountNo` varchar(10) DEFAULT '',
  `strRemitter` varchar(20) DEFAULT '',
  `strRefPrefix` varchar(10) DEFAULT '',
  `strTransCode` char(3) NOT NULL DEFAULT '',
  `intSubTypeID` int(11) NOT NULL DEFAULT '0',
  `strEmailSubject` varchar(255) DEFAULT NULL,
  `strCurrencyCode` char(3) DEFAULT NULL,
  `strMPEmail` varchar(127) DEFAULT '',
  `strMYOBJobCode` varchar(100) DEFAULT '',
  PRIMARY KEY (`intRuleID`),
  KEY `index_realmID` (`intRealmID`)
) ENGINE=MyISAM AUTO_INCREMENT=70 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblPaymentSplitRule`
--

LOCK TABLES `tblPaymentSplitRule` WRITE;
/*!40000 ALTER TABLE `tblPaymentSplitRule` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblPaymentSplitRule` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblPaymentTypes`
--

DROP TABLE IF EXISTS `tblPaymentTypes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblPaymentTypes` (
  `intPaymentTypeID` int(11) NOT NULL AUTO_INCREMENT,
  `intRealmID` int(11) DEFAULT '0',
  `intAssocID` int(11) DEFAULT '0',
  `strPaymentType` varchar(100) DEFAULT '',
  PRIMARY KEY (`intPaymentTypeID`),
  KEY `index_intAssocID` (`intAssocID`),
  KEY `index_intRealmID` (`intRealmID`)
) ENGINE=MyISAM AUTO_INCREMENT=4 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblPaymentTypes`
--

LOCK TABLES `tblPaymentTypes` WRITE;
/*!40000 ALTER TABLE `tblPaymentTypes` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblPaymentTypes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblPayment_MassPayReply`
--

DROP TABLE IF EXISTS `tblPayment_MassPayReply`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblPayment_MassPayReply` (
  `intReplyID` int(11) NOT NULL AUTO_INCREMENT,
  `intBankFileID` int(11) NOT NULL,
  `strResult` varchar(20) DEFAULT NULL,
  `tmTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `strText` text,
  `strMassPaySend` text,
  PRIMARY KEY (`intReplyID`),
  KEY `index_intBankFileID` (`intBankFileID`)
) ENGINE=MyISAM AUTO_INCREMENT=15453 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblPayment_MassPayReply`
--

LOCK TABLES `tblPayment_MassPayReply` WRITE;
/*!40000 ALTER TABLE `tblPayment_MassPayReply` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblPayment_MassPayReply` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblPayment_Templates`
--

DROP TABLE IF EXISTS `tblPayment_Templates`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblPayment_Templates` (
  `intPaymentTemplateID` int(11) NOT NULL AUTO_INCREMENT,
  `intRealmID` int(11) DEFAULT '0',
  `intRealmSubTypeID` int(11) DEFAULT '0',
  `intAssocID` int(11) DEFAULT '0',
  `strSuccessTemplate` text,
  `strErrorTemplate` text,
  `strFailureTemplate` text,
  `strHeaderHTML` text,
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`intPaymentTemplateID`),
  KEY `index_realmIDs` (`intRealmID`,`intRealmSubTypeID`)
) ENGINE=MyISAM AUTO_INCREMENT=6 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblPayment_Templates`
--

LOCK TABLES `tblPayment_Templates` WRITE;
/*!40000 ALTER TABLE `tblPayment_Templates` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblPayment_Templates` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblPerson`
--

DROP TABLE IF EXISTS `tblPerson`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblPerson` (
  `intPersonID` int(11) NOT NULL AUTO_INCREMENT,
  `strImportPersonCode` varchar(45) DEFAULT NULL,
  `intRealmID` int(11) NOT NULL DEFAULT '0',
  `strExtKey` varchar(20) DEFAULT '',
  `strPersonNo` varchar(15) NOT NULL DEFAULT '',
  `strNationalNum` varchar(30) DEFAULT '',
  `strFIFAID` varchar(30) DEFAULT '',
  `intDataOrigin` int(11) DEFAULT '0',
  `strStatus` varchar(20) DEFAULT '',
  `strLocalTitle` varchar(30) DEFAULT '',
  `strLocalFirstname` varchar(150) DEFAULT '' COMMENT 'The firstname of a person in local language (the language specified by LocalNameLanguage attribute).',
  `strLocalMiddlename` varchar(150) DEFAULT '',
  `strLocalSurname` varchar(150) DEFAULT '' COMMENT 'The lastname of a person in local language (the language specified by LocalNameLanguage attribute).',
  `strISONationality` varchar(50) DEFAULT NULL,
  `strLocalSurname2` varchar(150) DEFAULT '',
  `strLatinTitle` varchar(30) DEFAULT '',
  `strLatinFirstname` varchar(50) DEFAULT '',
  `strLatinMiddlename` varchar(50) DEFAULT '',
  `strLatinSurname` varchar(150) DEFAULT '',
  `strLatinSurname2` varchar(150) DEFAULT '',
  `strPreferredName` varchar(100) DEFAULT NULL,
  `intLocalLanguage` int(11) NOT NULL DEFAULT '0',
  `intGender` tinyint(4) DEFAULT '0',
  `dtDOB` date DEFAULT '0000-00-00',
  `strISOCountryOfBirth` varchar(100) DEFAULT '',
  `strRegionOfBirth` varchar(100) DEFAULT '',
  `strPlaceOfBirth` varchar(100) DEFAULT '',
  `dtDeath` date DEFAULT '0000-00-00',
  `strFirstClubName` varchar(100) DEFAULT '',
  `strAddress1` varchar(100) DEFAULT '',
  `strAddress2` varchar(100) DEFAULT '',
  `strSuburb` varchar(100) DEFAULT '',
  `strState` varchar(50) DEFAULT '',
  `strPostalCode` varchar(15) DEFAULT '',
  `strISOCountry` varchar(50) DEFAULT '',
  `strMaidenName` varchar(50) DEFAULT '',
  `strPhoneHome` varchar(30) DEFAULT '',
  `strPhoneWork` varchar(30) DEFAULT '',
  `strPhoneMobile` varchar(30) DEFAULT '',
  `strFax` varchar(30) DEFAULT '',
  `strPager` varchar(30) DEFAULT '',
  `strEmail` varchar(200) DEFAULT '',
  `intEthnicityID` int(11) DEFAULT '0',
  `strPreferredLang` varchar(50) DEFAULT '',
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `strCityOfResidence` varchar(50) DEFAULT '',
  `strPassportNo` varchar(50) DEFAULT '',
  `strPassportNationality` varchar(50) DEFAULT '',
  `dtPassportExpiry` date DEFAULT '0000-00-00',
  `strPassportIssueCountry` varchar(50) DEFAULT '',
  `strEmergContName` varchar(100) DEFAULT '',
  `strEmergContRel` varchar(100) DEFAULT '',
  `strEmergContNo` varchar(100) DEFAULT '',
  `strEyeColour` varchar(30) DEFAULT '',
  `strHairColour` varchar(30) DEFAULT '',
  `strHeight` varchar(20) DEFAULT '',
  `strWeight` varchar(20) DEFAULT '',
  `dtPoliceCheck` date DEFAULT '0000-00-00',
  `dtPoliceCheckExp` date DEFAULT '0000-00-00',
  `strPoliceCheckRef` varchar(30) DEFAULT '',
  `strP1FName` varchar(50) DEFAULT '',
  `strP1SName` varchar(50) DEFAULT '',
  `strP2FName` varchar(50) DEFAULT '',
  `strP2SName` varchar(50) DEFAULT '',
  `strP1Email` varchar(250) DEFAULT '',
  `strP2Email` varchar(250) DEFAULT '',
  `strP1Phone` varchar(30) DEFAULT '',
  `strP2Phone` varchar(30) DEFAULT '',
  `strP1Salutation` varchar(30) DEFAULT '',
  `strP2Salutation` varchar(30) DEFAULT '',
  `intP1Gender` tinyint(4) DEFAULT '0',
  `intP2Gender` tinyint(4) DEFAULT '0',
  `strP1Phone2` varchar(30) DEFAULT '',
  `strP2Phone2` varchar(30) DEFAULT '',
  `strP1PhoneMobile` varchar(30) DEFAULT '',
  `strP2PhoneMobile` varchar(30) DEFAULT '',
  `strP1Email2` varchar(250) DEFAULT '',
  `strP2Email2` varchar(250) DEFAULT '',
  `intMedicalConditions` tinyint(4) DEFAULT '0',
  `intAllergies` tinyint(4) DEFAULT '0',
  `intAllowMedicalTreatment` tinyint(4) DEFAULT '0',
  `intConsentSignatureSighted` tinyint(4) DEFAULT '0',
  `strMotherCountry` varchar(100) DEFAULT '',
  `strFatherCountry` varchar(100) DEFAULT '',
  `strNatCustomStr1` varchar(50) DEFAULT '',
  `strNatCustomStr2` varchar(50) DEFAULT '',
  `strNatCustomStr3` varchar(50) DEFAULT '',
  `strNatCustomStr4` varchar(50) DEFAULT '',
  `strNatCustomStr5` varchar(50) DEFAULT '',
  `strNatCustomStr6` varchar(50) DEFAULT '',
  `strNatCustomStr7` varchar(30) DEFAULT '',
  `strNatCustomStr8` varchar(30) DEFAULT '',
  `strNatCustomStr9` varchar(50) DEFAULT '',
  `strNatCustomStr10` varchar(50) DEFAULT '',
  `strNatCustomStr11` varchar(50) DEFAULT '',
  `strNatCustomStr12` varchar(50) DEFAULT '',
  `strNatCustomStr13` varchar(50) DEFAULT '',
  `strNatCustomStr14` varchar(50) DEFAULT '',
  `strNatCustomStr15` varchar(50) DEFAULT '',
  `dblNatCustomDbl1` double DEFAULT '0',
  `dblNatCustomDbl2` double DEFAULT '0',
  `dblNatCustomDbl3` double DEFAULT '0',
  `dblNatCustomDbl4` double DEFAULT '0',
  `dblNatCustomDbl5` double DEFAULT '0',
  `dblNatCustomDbl6` double DEFAULT '0',
  `dblNatCustomDbl7` double DEFAULT '0',
  `dblNatCustomDbl8` double DEFAULT '0',
  `dblNatCustomDbl9` double DEFAULT '0',
  `dblNatCustomDbl10` double DEFAULT '0',
  `dtNatCustomDt1` date DEFAULT '0000-00-00',
  `dtNatCustomDt2` date DEFAULT '0000-00-00',
  `dtNatCustomDt3` date DEFAULT '0000-00-00',
  `dtNatCustomDt4` date DEFAULT '0000-00-00',
  `dtNatCustomDt5` date DEFAULT '0000-00-00',
  `intNatCustomLU1` int(11) DEFAULT '0',
  `intNatCustomLU2` int(11) DEFAULT '0',
  `intNatCustomLU3` int(11) DEFAULT '0',
  `intNatCustomLU4` int(11) DEFAULT '0',
  `intNatCustomLU5` int(11) DEFAULT '0',
  `intNatCustomLU6` int(11) DEFAULT '0',
  `intNatCustomLU7` int(11) DEFAULT '0',
  `intNatCustomLU8` int(11) DEFAULT '0',
  `intNatCustomLU9` int(11) DEFAULT '0',
  `intNatCustomLU10` int(11) DEFAULT '0',
  `intNatCustomBool1` tinyint(4) DEFAULT '0',
  `intNatCustomBool2` tinyint(4) DEFAULT '0',
  `intNatCustomBool3` tinyint(4) DEFAULT '0',
  `intNatCustomBool4` tinyint(4) DEFAULT '0',
  `intNatCustomBool5` tinyint(4) DEFAULT '0',
  `intSystemStatus` tinyint(4) DEFAULT '0',
  `intPhoto` tinyint(4) DEFAULT '0',
  `dtSuspendedUntil` date DEFAULT NULL,
  `intImportID` int(11) DEFAULT NULL COMMENT 'Tracking ID on which batch this record is included during import',
  `strISOMotherCountry` varchar(150) DEFAULT '',
  `strISOFatherCountry` varchar(150) DEFAULT '',
  `intInternationalTransfer` int(11) DEFAULT '0' COMMENT 'Column to check if new person flow is an international transfer',
  `strBirthCert` varchar(20) DEFAULT '',
  `strBirthCertCountry` varchar(6) DEFAULT '',
  `dtBirthCertValidityDateFrom` date DEFAULT NULL,
  `dtBirthCertValidityDateTo` date DEFAULT NULL,
  `strBirthCertDesc` varchar(250) DEFAULT '',
  `strOtherPersonIdentifier` varchar(20) DEFAULT '',
  `strOtherPersonIdentifierIssueCountry` varchar(6) DEFAULT '',
  `dtOtherPersonIdentifierValidDateFrom` date DEFAULT NULL,
  `dtOtherPersonIdentifierValidDateTo` date DEFAULT NULL,
  `strOtherPersonIdentifierDesc` varchar(250) DEFAULT '',
  `intOtherPersonIdentifierTypeID` int(11) DEFAULT '0',
  `intMinorProtection` tinyint(4) NOT NULL DEFAULT '0',
  PRIMARY KEY (`intPersonID`),
  KEY `index_strPersonNo` (`strPersonNo`),
  KEY `index_strStatus` (`strStatus`),
  KEY `index_strExtKey` (`strExtKey`),
  KEY `index_strLocalSurname` (`strLocalSurname`),
  KEY `index_strLocalFirstname` (`strLocalFirstname`),
  KEY `index_dtDOB` (`dtDOB`),
  KEY `index_intGender` (`intGender`),
  KEY `index_strNationalNum` (`strNationalNum`),
  KEY `index_intRealmID` (`intRealmID`),
  KEY `index_RealmStatus` (`intRealmID`,`strStatus`),
  KEY `index_RealmNameDOB` (`intRealmID`,`strLocalSurname`,`strLocalFirstname`,`dtDOB`),
  KEY `index_RealmEmail` (`intRealmID`,`strEmail`),
  KEY `index_FIFA` (`strFIFAID`),
  KEY `index_RealmNatNumMID` (`intRealmID`,`strNationalNum`,`intPersonID`)
) ENGINE=InnoDB AUTO_INCREMENT=2134 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblPerson`
--

LOCK TABLES `tblPerson` WRITE;
/*!40000 ALTER TABLE `tblPerson` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblPerson` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblPersonCertifications`
--

DROP TABLE IF EXISTS `tblPersonCertifications`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblPersonCertifications` (
  `intCertificationID` int(11) NOT NULL AUTO_INCREMENT,
  `intPersonID` int(11) NOT NULL,
  `intRealmID` int(11) NOT NULL,
  `intCertificationTypeID` int(11) DEFAULT NULL,
  `dtValidFrom` date DEFAULT NULL,
  `dtValidUntil` date DEFAULT NULL,
  `strDescription` varchar(250) DEFAULT NULL,
  `strStatus` varchar(45) NOT NULL DEFAULT 'ACTIVE',
  PRIMARY KEY (`intCertificationID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblPersonCertifications`
--

LOCK TABLES `tblPersonCertifications` WRITE;
/*!40000 ALTER TABLE `tblPersonCertifications` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblPersonCertifications` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblPersonEntity_1`
--

DROP TABLE IF EXISTS `tblPersonEntity_1`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblPersonEntity_1` (
  `intPersonEntityID` int(11) NOT NULL AUTO_INCREMENT,
  `intPersonID` int(11) DEFAULT '0',
  `intEntityID` int(11) DEFAULT '0',
  `strPEImportPersonCode` varchar(45) DEFAULT '',
  `strPEPersonType` varchar(20) DEFAULT '' COMMENT 'The match official role type, e.g. Player, Coach, Referee',
  `strPEPersonLevel` varchar(30) DEFAULT '' COMMENT 'The level the person was playing on for the club, i.e. amateur, amateur with contract and professional.',
  `strPEPersonEntityRole` varchar(50) DEFAULT '' COMMENT 'The team official role type, e.g. Coach or Team Doctor.',
  `strPESport` varchar(20) DEFAULT '' COMMENT 'The sport/discipline this registration is valid for, e.g. a football player registration is distinct from a beach soccer player registration. FOOTBALL, FUTSAL, BEACH SOCCER.',
  `strPEStatus` varchar(20) DEFAULT '' COMMENT 'The status of the registration, i.e.. Pending, Active, Passive, Transferred.',
  `dtPEFrom` date DEFAULT '0000-00-00' COMMENT 'The date when the validity of this registration starts, e.g. when a player joins and officially registers for a club.',
  `dtPETo` date DEFAULT '0000-00-00' COMMENT 'The date when the validity of the registration ends, e.g. when a player officially leaves a club.',
  `intRealmID` int(11) DEFAULT '0',
  `dtPEAdded` datetime DEFAULT NULL,
  `dtPELastUpdated` datetime DEFAULT NULL,
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`intPersonEntityID`),
  KEY `index_intPersonID` (`intPersonID`),
  KEY `index_intEntityID` (`intEntityID`),
  KEY `index_strPEPersonType` (`strPEPersonType`),
  KEY `index_strPEStatus` (`strPEStatus`),
  KEY `index_IDs` (`intEntityID`,`intPersonID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblPersonEntity_1`
--

LOCK TABLES `tblPersonEntity_1` WRITE;
/*!40000 ALTER TABLE `tblPersonEntity_1` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblPersonEntity_1` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblPersonNotes`
--

DROP TABLE IF EXISTS `tblPersonNotes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblPersonNotes` (
  `intPersonID` int(11) NOT NULL,
  `strNotes` text,
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`intPersonID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblPersonNotes`
--

LOCK TABLES `tblPersonNotes` WRITE;
/*!40000 ALTER TABLE `tblPersonNotes` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblPersonNotes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblPersonRegistration_1`
--

DROP TABLE IF EXISTS `tblPersonRegistration_1`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblPersonRegistration_1` (
  `intPersonRegistrationID` int(11) NOT NULL AUTO_INCREMENT,
  `intPersonID` int(11) DEFAULT '0',
  `strImportPersonCode` varchar(45) DEFAULT NULL,
  `intEntityID` int(11) DEFAULT '0',
  `strPersonType` varchar(20) DEFAULT '',
  `strPersonLevel` varchar(30) DEFAULT '',
  `strPersonEntityRole` varchar(50) DEFAULT '',
  `strStatus` varchar(20) DEFAULT '',
  `strSport` varchar(20) DEFAULT '',
  `intCurrent` tinyint(4) DEFAULT '0',
  `intOriginLevel` tinyint(4) DEFAULT '0',
  `intOriginID` int(11) DEFAULT '0',
  `dtFrom` date DEFAULT '0000-00-00',
  `dtTo` date DEFAULT '0000-00-00',
  `intRealmID` int(11) DEFAULT '0',
  `intSubRealmID` int(11) DEFAULT '0',
  `dtAdded` datetime DEFAULT NULL,
  `dtLastUpdated` datetime DEFAULT NULL,
  `intIsPaid` tinyint(4) DEFAULT '0',
  `intNationalPeriodID` int(11) NOT NULL DEFAULT '0',
  `intAgeGroupID` int(11) NOT NULL DEFAULT '0',
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `strAgeLevel` varchar(100) DEFAULT '',
  `strRegistrationNature` varchar(30) DEFAULT '',
  `intPaymentRequired` tinyint(4) DEFAULT '0',
  `intCreatedByUserID` int(11) DEFAULT '0',
  `strPersonSubType` varchar(30) DEFAULT '',
  `strOldStatus` varchar(30) DEFAULT '',
  `strPreTransferredStatus` varchar(30) DEFAULT '',
  `intClearanceID` int(11) DEFAULT '0',
  `intPersonRequestID` int(11) NOT NULL DEFAULT '0' COMMENT 'For tracking purposes if entry came from Person Request (TRANSFER or ACCESS)',
  `strShortNotes` varchar(250) DEFAULT NULL COMMENT 'can only be added/edited/viewed by MA level',
  `intNewBaseRecord` tinyint(4) NOT NULL DEFAULT '0',
  `dtApproved` datetime DEFAULT '0000-00-00 00:00:00',
  `intImportID` int(11) DEFAULT NULL,
  PRIMARY KEY (`intPersonRegistrationID`),
  KEY `index_intPersonID` (`intPersonID`),
  KEY `index_intEntityID` (`intEntityID`),
  KEY `index_strPersonType` (`strPersonType`),
  KEY `index_strStatus` (`strStatus`),
  KEY `index_IDs` (`intEntityID`,`intPersonID`)
) ENGINE=InnoDB AUTO_INCREMENT=3219 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblPersonRegistration_1`
--

LOCK TABLES `tblPersonRegistration_1` WRITE;
/*!40000 ALTER TABLE `tblPersonRegistration_1` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblPersonRegistration_1` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblPersonRequest`
--

DROP TABLE IF EXISTS `tblPersonRequest`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblPersonRequest` (
  `intPersonRequestID` int(11) NOT NULL AUTO_INCREMENT,
  `strRequestType` varchar(20) NOT NULL COMMENT 'ACCESS, TRANSFER',
  `intPersonID` int(11) NOT NULL,
  `strSport` varchar(20) NOT NULL COMMENT 'FOOTBALL, FUTSAL, BEACHSOCCER',
  `strPersonType` varchar(20) NOT NULL COMMENT 'PLAYER, COACH, ETC',
  `strPersonLevel` varchar(30) DEFAULT NULL COMMENT 'PROFESSIONAL, AMATEUR, (blank)',
  `strPersonEntityRole` varchar(50) DEFAULT NULL COMMENT 'DOCTOR, ETC',
  `intRealmID` int(11) DEFAULT NULL,
  `intRequestFromEntityID` int(11) NOT NULL COMMENT 'What Entity is requesting the permission.',
  `intRequestToEntityID` int(11) NOT NULL COMMENT 'The Entity ID that the request goes to',
  `intRequestToMAOverride` int(11) NOT NULL DEFAULT '0' COMMENT 'Send request to Member Association level due to timeout',
  `intParentMAEntityID` int(11) NOT NULL DEFAULT '0' COMMENT 'Populated by cron job (set to requestToEntity MA parent)',
  `strRequestNotes` varchar(250) DEFAULT NULL COMMENT 'Any note about the request',
  `dtDateRequest` datetime NOT NULL COMMENT 'Date the request was made',
  `strRequestResponse` varchar(20) DEFAULT NULL COMMENT 'ACCEPTED/DENIED',
  `strResponseNotes` varchar(250) DEFAULT NULL COMMENT 'Notes regarding the response',
  `intResponseBy` int(11) NOT NULL COMMENT 'Which level ended up giving the response',
  `strRequestStatus` varchar(20) DEFAULT NULL,
  `tTimeStamp` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`intPersonRequestID`),
  KEY `index_intPersonID` (`intPersonID`),
  KEY `index_intFromEntityID` (`intRequestFromEntityID`),
  KEY `index_intToEntityID` (`intRequestToEntityID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblPersonRequest`
--

LOCK TABLES `tblPersonRequest` WRITE;
/*!40000 ALTER TABLE `tblPersonRequest` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblPersonRequest` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblPlayerPassport`
--

DROP TABLE IF EXISTS `tblPlayerPassport`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblPlayerPassport` (
  `intPlayerPassportID` int(11) NOT NULL AUTO_INCREMENT,
  `intPersonID` int(11) DEFAULT NULL,
  `strOrigin` varchar(20) DEFAULT NULL,
  `strPersonLevel` varchar(20) DEFAULT NULL,
  `intEntityID` int(11) DEFAULT NULL,
  `strEntityName` varchar(200) DEFAULT NULL,
  `strMAName` varchar(200) DEFAULT NULL,
  `dtFrom` date DEFAULT NULL,
  `dtTo` date DEFAULT NULL,
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`intPlayerPassportID`),
  KEY `INDEX_intPersonID` (`intPersonID`)
) ENGINE=InnoDB AUTO_INCREMENT=2392 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblPlayerPassport`
--

LOCK TABLES `tblPlayerPassport` WRITE;
/*!40000 ALTER TABLE `tblPlayerPassport` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblPlayerPassport` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblPostCodeData`
--

DROP TABLE IF EXISTS `tblPostCodeData`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblPostCodeData` (
  `strPostalCode1` char(4) NOT NULL DEFAULT '',
  `strPostalCode2` char(4) NOT NULL DEFAULT '',
  `intDistance` int(11) DEFAULT NULL,
  PRIMARY KEY (`strPostalCode1`,`strPostalCode2`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblPostCodeData`
--

LOCK TABLES `tblPostCodeData` WRITE;
/*!40000 ALTER TABLE `tblPostCodeData` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblPostCodeData` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblPostCodes_LatLong`
--

DROP TABLE IF EXISTS `tblPostCodes_LatLong`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblPostCodes_LatLong` (
  `strPostalCode` varchar(20) DEFAULT NULL,
  `strSuburb` varchar(200) DEFAULT NULL,
  `strState` varchar(20) DEFAULT NULL,
  `strComments` varchar(100) DEFAULT NULL,
  `strDeliveryOffice` varchar(100) DEFAULT NULL,
  `intPreSort` int(11) DEFAULT NULL,
  `strParcelZone` varchar(20) DEFAULT NULL,
  `intBSPnumber` int(11) DEFAULT NULL,
  `strBSPname` varchar(100) DEFAULT NULL,
  `strCategory` varchar(100) DEFAULT NULL,
  `strLat` varchar(100) DEFAULT NULL,
  `strLong` varchar(100) DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblPostCodes_LatLong`
--

LOCK TABLES `tblPostCodes_LatLong` WRITE;
/*!40000 ALTER TABLE `tblPostCodes_LatLong` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblPostCodes_LatLong` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblPostcodes`
--

DROP TABLE IF EXISTS `tblPostcodes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblPostcodes` (
  `intPostcodeID` int(11) NOT NULL AUTO_INCREMENT,
  `strPostcode` varchar(8) DEFAULT '',
  `strSuburb` varchar(30) NOT NULL DEFAULT '',
  `strState` varchar(10) NOT NULL DEFAULT '',
  `strLongitude` varchar(30) NOT NULL DEFAULT '0',
  `strLatitude` varchar(30) NOT NULL DEFAULT '0',
  PRIMARY KEY (`intPostcodeID`),
  KEY `index_strPostcode` (`strPostcode`),
  KEY `index_strSuburb` (`strSuburb`)
) ENGINE=MyISAM AUTO_INCREMENT=16398 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblPostcodes`
--

LOCK TABLES `tblPostcodes` WRITE;
/*!40000 ALTER TABLE `tblPostcodes` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblPostcodes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblProdTransactions`
--

DROP TABLE IF EXISTS `tblProdTransactions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblProdTransactions` (
  `intTransactionID` int(11) NOT NULL AUTO_INCREMENT,
  `intStatus` tinyint(4) DEFAULT '0',
  `strNotes` text,
  `intPaymentType` int(11) DEFAULT '0',
  `curAmountPaid` decimal(12,2) DEFAULT '0.00',
  `curAmountDue` decimal(12,2) DEFAULT '0.00',
  `strReceiptRef` varchar(100) DEFAULT '',
  `intProductID` int(11) DEFAULT '0',
  `intQty` int(11) DEFAULT '0',
  `dtTransaction` datetime DEFAULT NULL,
  `dtPaid` datetime DEFAULT NULL,
  `tLastUpdated` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `intDelivered` tinyint(11) DEFAULT '0',
  `intMemberID` int(11) DEFAULT '0',
  `intAssocID` int(11) DEFAULT '0',
  PRIMARY KEY (`intTransactionID`),
  KEY `index_intStatus` (`intStatus`),
  KEY `index_intPaymentType` (`intPaymentType`),
  KEY `index_intProductID` (`intProductID`),
  KEY `index_intMemberID` (`intMemberID`),
  KEY `index_intAssocID` (`intAssocID`)
) ENGINE=MyISAM AUTO_INCREMENT=169337 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblProdTransactions`
--

LOCK TABLES `tblProdTransactions` WRITE;
/*!40000 ALTER TABLE `tblProdTransactions` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblProdTransactions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblProductAttributes`
--

DROP TABLE IF EXISTS `tblProductAttributes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblProductAttributes` (
  `intProductAttributeID` int(11) NOT NULL AUTO_INCREMENT,
  `intProductID` int(11) NOT NULL,
  `intAttributeType` int(11) NOT NULL,
  `strAttributeValue` varchar(50) NOT NULL,
  `intRealmID` int(11) DEFAULT '0',
  `intID` int(11) DEFAULT '0',
  `intLevel` int(11) DEFAULT '0',
  PRIMARY KEY (`intProductAttributeID`),
  KEY `index_intRealmID` (`intRealmID`),
  KEY `index_intIDLevel` (`intID`,`intLevel`),
  KEY `index_intProductID` (`intProductID`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblProductAttributes`
--

LOCK TABLES `tblProductAttributes` WRITE;
/*!40000 ALTER TABLE `tblProductAttributes` DISABLE KEYS */;
INSERT INTO `tblProductAttributes` VALUES (1,37135,0,'100',1,35,3),(3,37134,0,'100',1,35,3);
/*!40000 ALTER TABLE `tblProductAttributes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblProductDependencies`
--

DROP TABLE IF EXISTS `tblProductDependencies`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblProductDependencies` (
  `intProductDependencyID` int(11) NOT NULL AUTO_INCREMENT,
  `intProductID` int(11) NOT NULL,
  `intDependentProductID` int(11) NOT NULL,
  `intRealmID` int(11) DEFAULT '0',
  `intID` int(11) DEFAULT '0',
  `intLevel` int(11) DEFAULT '0',
  PRIMARY KEY (`intProductDependencyID`),
  KEY `index_intRealmID` (`intRealmID`),
  KEY `index_intIDLevel` (`intID`,`intLevel`),
  KEY `index_intProductID` (`intProductID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblProductDependencies`
--

LOCK TABLES `tblProductDependencies` WRITE;
/*!40000 ALTER TABLE `tblProductDependencies` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblProductDependencies` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblProductPriceRange`
--

DROP TABLE IF EXISTS `tblProductPriceRange`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblProductPriceRange` (
  `intProductPriceRangeID` int(11) NOT NULL AUTO_INCREMENT,
  `intProductID` int(11) NOT NULL,
  `curAmountMin` decimal(12,2) DEFAULT '0.00',
  `curAmountMax` decimal(12,2) DEFAULT '0.00',
  PRIMARY KEY (`intProductPriceRangeID`),
  UNIQUE KEY `index_product_id` (`intProductID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblProductPriceRange`
--

LOCK TABLES `tblProductPriceRange` WRITE;
/*!40000 ALTER TABLE `tblProductPriceRange` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblProductPriceRange` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblProductPricing`
--

DROP TABLE IF EXISTS `tblProductPricing`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblProductPricing` (
  `intProductPricingID` int(11) NOT NULL AUTO_INCREMENT,
  `curAmount` decimal(12,2) DEFAULT '0.00',
  `intProductID` int(11) DEFAULT '0',
  `intRealmID` int(11) DEFAULT '0',
  `intID` int(11) DEFAULT '0',
  `intLevel` int(11) DEFAULT '0',
  `intPricingType` tinyint(4) DEFAULT '0',
  `curAmount_Adult1` decimal(12,2) DEFAULT '0.00',
  `curAmount_Adult2` decimal(12,2) DEFAULT '0.00',
  `curAmount_Adult3` decimal(12,2) DEFAULT '0.00',
  `curAmount_AdultPlus` decimal(12,2) DEFAULT '0.00',
  `curAmount_Child1` decimal(12,2) DEFAULT '0.00',
  `curAmount_Child2` decimal(12,2) DEFAULT '0.00',
  `curAmount_Child3` decimal(12,2) DEFAULT '0.00',
  `curAmount_ChildPlus` decimal(12,2) DEFAULT '0.00',
  PRIMARY KEY (`intProductPricingID`),
  UNIQUE KEY `index_Dupe` (`intProductID`,`intID`,`intLevel`),
  KEY `index_intRealmID` (`intRealmID`),
  KEY `index_intID` (`intID`),
  KEY `index_intProductID` (`intProductID`),
  KEY `index_intLevel` (`intLevel`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblProductPricing`
--

LOCK TABLES `tblProductPricing` WRITE;
/*!40000 ALTER TABLE `tblProductPricing` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblProductPricing` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblProductRenew`
--

DROP TABLE IF EXISTS `tblProductRenew`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblProductRenew` (
  `intProductID` int(11) NOT NULL,
  `strRenewText1` text,
  `strRenewText2` text,
  `strRenewText3` text,
  `strRenewText4` text,
  `strRenewText5` text,
  `intRenewDays1` int(11) DEFAULT '0',
  `intRenewDays2` int(11) DEFAULT '0',
  `intRenewDays3` int(11) DEFAULT '0',
  `intRenewDays4` int(11) DEFAULT '0',
  `intRenewDays5` int(11) DEFAULT '0',
  `intRenewProductID` int(11) NOT NULL DEFAULT '0',
  `intRenewRegoFormID` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`intProductID`),
  KEY `index_renewproduct` (`intRenewProductID`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblProductRenew`
--

LOCK TABLES `tblProductRenew` WRITE;
/*!40000 ALTER TABLE `tblProductRenew` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblProductRenew` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblProducts`
--

DROP TABLE IF EXISTS `tblProducts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblProducts` (
  `intProductID` int(11) NOT NULL AUTO_INCREMENT,
  `strName` varchar(100) DEFAULT '',
  `curDefaultAmount` decimal(12,2) DEFAULT '0.00',
  `intMinChangeLevel` int(11) DEFAULT '0',
  `intMinSellLevel` int(11) DEFAULT '0',
  `intCreatedLevel` int(11) DEFAULT '0',
  `intCreatedID` int(11) DEFAULT '0',
  `intEntityID` int(11) DEFAULT '0',
  `intRealmID` int(11) DEFAULT '0',
  `intAssocUnique` int(11) DEFAULT '0',
  `strGSTText` varchar(200) DEFAULT '',
  `intAllowMultiPurchase` int(11) DEFAULT '0',
  `intMandatoryProductID` int(11) DEFAULT '0',
  `strGroup` varchar(100) DEFAULT '',
  `strProductNotes` text,
  `intInactive` int(11) DEFAULT '0',
  `intAllowQtys` tinyint(4) DEFAULT '0',
  `intProductGender` tinyint(4) DEFAULT '0',
  `intSetMemberActive` tinyint(4) DEFAULT '0',
  `intSetMemberFinancial` tinyint(4) DEFAULT '0',
  `intProductExpiryDays` smallint(6) DEFAULT '0',
  `intMemberExpiryDays` smallint(6) DEFAULT '0',
  `dtProductExpiry` datetime DEFAULT NULL,
  `dtMemberExpiry` datetime DEFAULT NULL,
  `intProductMemberPackageID` int(11) DEFAULT '0',
  `intPaymentSplitID` int(11) NOT NULL DEFAULT '0',
  `intProductType` int(11) DEFAULT '0',
  `intIsEvent` tinyint(4) DEFAULT NULL,
  `intProductSubRealmID` int(11) DEFAULT '0',
  `intSeasonPlayerFinancial` tinyint(4) DEFAULT '0',
  `intSeasonCoachFinancial` tinyint(4) DEFAULT '0',
  `intSeasonUmpireFinancial` tinyint(4) DEFAULT '0',
  `intSeasonOther1Financial` tinyint(4) DEFAULT '0',
  `intSeasonOther2Financial` tinyint(4) DEFAULT '0',
  `intSeasonMemberPackageID` int(11) DEFAULT '0',
  `intProductNationalPeriodID` int(11) DEFAULT '0',
  `dtDateAvailableFrom` datetime DEFAULT NULL,
  `dtDateAvailableTo` datetime DEFAULT NULL,
  `strLMSCourseID` varchar(20) DEFAULT '0',
  `intMatchCreditsPerQty` int(11) DEFAULT '0',
  `intMatchCreditType` int(11) DEFAULT '0',
  `intPhoto` tinyint(4) DEFAULT '0',
  `intCanResetPaymentRequired` tinyint(4) DEFAULT '0',
  `strNationality_IN` varchar(200) DEFAULT NULL,
  `strNationality_NOTIN` varchar(200) DEFAULT NULL,
  `strProductCode` varchar(20) DEFAULT '',
  `strProductType` varchar(20) DEFAULT '',
  `curPriceTax` decimal(12,2) DEFAULT NULL,
  `dblTaxRate` double DEFAULT NULL,
  `intSellLevel` tinyint(4) DEFAULT '0',
  PRIMARY KEY (`intProductID`),
  KEY `index_intRealmID` (`intRealmID`),
  KEY `index_intInactive` (`intInactive`),
  KEY `index_intProductType` (`intProductType`),
  KEY `index_productSeasonID` (`intProductNationalPeriodID`),
  KEY `index_intEntityID` (`intEntityID`)
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblProducts`
--

LOCK TABLES `tblProducts` WRITE;
/*!40000 ALTER TABLE `tblProducts` DISABLE KEYS */;
INSERT INTO `tblProducts` VALUES (1,'Coach License',0.00,0,0,100,1,1,1,0,'Inc',0,0,'','',0,0,0,0,0,0,0,NULL,'0000-00-00 00:00:00',0,0,0,NULL,0,0,0,0,0,0,0,8,'0000-00-00 00:00:00','0000-00-00 00:00:00','0',0,0,0,1,'',NULL,'','',NULL,NULL,1),(2,'Referee License',0.00,0,0,0,1,1,1,0,'',0,0,'',NULL,0,0,0,0,0,0,0,NULL,NULL,0,0,0,NULL,0,0,0,0,0,0,0,8,NULL,NULL,'0',0,0,0,1,'',NULL,'','',NULL,NULL,1),(3,'Professional Player',0.00,0,0,0,1,1,1,0,'',0,0,'',NULL,0,0,0,0,0,0,0,NULL,NULL,0,0,0,NULL,0,0,0,0,0,0,0,8,NULL,NULL,'0',0,0,0,1,'',NULL,'','',NULL,NULL,1),(4,'Amateur Player License',0.00,0,0,0,1,1,1,0,'',0,0,'',NULL,0,0,0,0,0,0,0,NULL,NULL,0,0,0,NULL,0,0,0,0,0,0,0,8,NULL,NULL,'0',0,0,0,1,'',NULL,'','',NULL,NULL,1),(5,'Amateur Youth',0.00,0,0,0,1,1,1,0,'',0,0,'',NULL,0,0,0,0,0,0,0,NULL,NULL,0,0,0,NULL,0,0,0,0,0,0,0,8,NULL,NULL,'0',0,0,0,1,'',NULL,'','',NULL,NULL,1),(6,'Local Transfer Fee',0.00,0,0,0,1,1,1,0,'',0,0,'',NULL,0,0,0,0,0,0,0,NULL,NULL,0,0,0,NULL,0,0,0,0,0,0,0,8,NULL,NULL,'0',0,0,0,1,'',NULL,'','',NULL,NULL,1),(7,'International Transfer',0.00,0,0,0,1,1,1,0,'',0,0,'',NULL,0,0,0,0,0,0,0,NULL,NULL,0,0,0,NULL,0,0,0,0,0,0,0,8,NULL,NULL,'0',0,0,0,1,'',NULL,'','',NULL,NULL,1),(8,'Women\'s Player License',0.00,0,0,0,1,1,1,0,'',0,0,'',NULL,0,0,0,0,0,0,0,NULL,NULL,0,0,0,NULL,0,0,0,0,0,0,0,8,NULL,NULL,'0',0,0,0,1,'',NULL,'','',NULL,NULL,1),(9,'Ordinary Member - Annual Membership',107.00,0,0,0,1,1,1,0,'',0,0,'',NULL,0,0,0,0,0,0,0,NULL,NULL,0,0,0,NULL,0,0,0,0,0,0,0,8,NULL,NULL,'0',0,0,0,1,'',NULL,'','',NULL,NULL,3),(10,'Ordinary Member - Joining Fee',160.50,0,0,0,1,1,1,0,'',1,0,'','',0,0,0,0,0,0,0,NULL,NULL,0,0,0,NULL,0,0,0,0,0,0,0,8,NULL,NULL,'0',0,0,0,1,'',NULL,'','licence',NULL,NULL,3),(11,'Associate Member - Annual Membership',53.50,0,0,0,1,1,1,0,'',0,0,'',NULL,0,0,0,0,0,0,0,NULL,NULL,0,0,0,NULL,0,0,0,0,0,0,0,8,NULL,NULL,'0',0,0,0,1,'',NULL,'','',NULL,NULL,3),(12,'Associate Member - Joining Fee',107.00,0,0,0,1,1,1,0,'',1,0,'','',0,0,0,0,0,0,0,NULL,NULL,0,0,0,NULL,0,0,0,0,0,0,0,8,NULL,NULL,'0',0,0,0,1,'',NULL,'','',NULL,NULL,3),(13,'Professional Club - Annual Membership',107.00,0,0,0,1,1,1,0,'',0,0,'','',1,0,0,0,0,0,0,NULL,NULL,0,0,0,NULL,0,0,0,0,0,0,0,8,NULL,NULL,'0',0,0,0,1,'',NULL,'','',NULL,NULL,3),(14,'Professional Club - Joining Fee',53.50,0,0,0,1,1,1,0,'',1,0,'','',1,0,0,0,0,0,0,NULL,NULL,0,0,0,NULL,0,0,0,0,0,0,0,8,NULL,NULL,'0',0,0,0,1,'',NULL,'','',NULL,NULL,3);
/*!40000 ALTER TABLE `tblProducts` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblQualification`
--

DROP TABLE IF EXISTS `tblQualification`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblQualification` (
  `intQualificationID` int(11) NOT NULL AUTO_INCREMENT,
  `strName` varchar(150) DEFAULT NULL,
  `intType` int(11) DEFAULT NULL,
  `intDefaultLength` int(11) DEFAULT NULL,
  `intMinLevel` int(11) DEFAULT NULL,
  `intRealmID` int(11) DEFAULT NULL,
  `intEntityType` int(11) DEFAULT NULL,
  `intEntityID` int(11) DEFAULT NULL,
  `intEducationID` int(11) DEFAULT NULL,
  `intRecStatus` int(11) DEFAULT '1',
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`intQualificationID`),
  KEY `index_realm` (`intRealmID`),
  KEY `index_RealmStatus` (`intRealmID`,`intRecStatus`)
) ENGINE=MyISAM AUTO_INCREMENT=74 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblQualification`
--

LOCK TABLES `tblQualification` WRITE;
/*!40000 ALTER TABLE `tblQualification` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblQualification` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblRealmSubTypes`
--

DROP TABLE IF EXISTS `tblRealmSubTypes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblRealmSubTypes` (
  `intSubTypeID` int(11) NOT NULL AUTO_INCREMENT,
  `intRealmID` int(11) NOT NULL DEFAULT '0',
  `strSubTypeName` varchar(100) NOT NULL DEFAULT '',
  PRIMARY KEY (`intSubTypeID`),
  KEY `index_realm` (`intRealmID`)
) ENGINE=MyISAM AUTO_INCREMENT=127 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblRealmSubTypes`
--

LOCK TABLES `tblRealmSubTypes` WRITE;
/*!40000 ALTER TABLE `tblRealmSubTypes` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblRealmSubTypes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblRealms`
--

DROP TABLE IF EXISTS `tblRealms`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblRealms` (
  `intRealmID` int(11) NOT NULL AUTO_INCREMENT,
  `strRealmName` varchar(200) NOT NULL DEFAULT '',
  `strRealmAdType` varchar(25) DEFAULT NULL,
  PRIMARY KEY (`intRealmID`)
) ENGINE=MyISAM AUTO_INCREMENT=63 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblRealms`
--

LOCK TABLES `tblRealms` WRITE;
/*!40000 ALTER TABLE `tblRealms` DISABLE KEYS */;
INSERT INTO `tblRealms` VALUES (1,'Singapore','');
/*!40000 ALTER TABLE `tblRealms` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblRegistrationItem`
--

DROP TABLE IF EXISTS `tblRegistrationItem`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblRegistrationItem` (
  `intItemID` int(11) NOT NULL AUTO_INCREMENT,
  `intRealmID` int(11) NOT NULL DEFAULT '0',
  `intSubRealmID` int(11) NOT NULL DEFAULT '0',
  `intOriginLevel` int(11) DEFAULT '0',
  `strRuleFor` varchar(30) DEFAULT '' COMMENT 'REGO, ENTITY',
  `strEntityType` varchar(30) DEFAULT '',
  `intEntityLevel` int(11) DEFAULT '0',
  `strRegistrationNature` varchar(20) NOT NULL DEFAULT '0' COMMENT 'NEW,RENEWAL,AMENDMENT,TRANSFER,',
  `strPersonType` varchar(20) NOT NULL DEFAULT '' COMMENT 'PLAYER, COACH, REFEREE',
  `strPersonLevel` varchar(20) NOT NULL DEFAULT '' COMMENT 'AMATEUR,PROFESSIONAL',
  `strSport` varchar(20) NOT NULL DEFAULT '' COMMENT 'FOOTBALL,FUTSAL,BEACHSOCCER',
  `strAgeLevel` varchar(20) NOT NULL DEFAULT '' COMMENT 'SENIOR,JUNIOR',
  `strItemType` varchar(20) DEFAULT '' COMMENT 'DOCUMENT, PRODUCT',
  `intID` int(11) DEFAULT '0' COMMENT 'ID of strItemType',
  `intUseExistingThisEntity` tinyint(4) DEFAULT '0',
  `intUseExistingAnyEntity` tinyint(4) DEFAULT '0',
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `intRequired` tinyint(4) DEFAULT '0' COMMENT '0=Optional, 1 =Required',
  `strPersonEntityRole` varchar(50) DEFAULT '',
  `strISOCountry_IN` varchar(200) DEFAULT NULL,
  `strISOCountry_NOTIN` varchar(200) DEFAULT NULL,
  `intFilterFromAge` int(11) DEFAULT '0',
  `intFilterToAge` int(11) DEFAULT '0',
  PRIMARY KEY (`intItemID`),
  KEY `index_Realms` (`intRealmID`,`intSubRealmID`),
  KEY `strRuleFor` (`strRuleFor`)
) ENGINE=InnoDB AUTO_INCREMENT=489 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblRegistrationItem`
--

LOCK TABLES `tblRegistrationItem` WRITE;
/*!40000 ALTER TABLE `tblRegistrationItem` DISABLE KEYS */;
INSERT INTO `tblRegistrationItem` VALUES (81,1,0,3,'REGO','',3,'NEW','','','','','DOCUMENT',32,1,1,'2014-12-01 21:11:07',1,'','','',0,0),(82,1,0,3,'REGO','',3,'NEW','','','','','DOCUMENT',33,1,1,'2014-12-01 21:11:07',1,'','','',0,0),(83,1,0,3,'REGO','',3,'NEW','','','','','DOCUMENT',34,1,1,'2014-12-16 00:04:41',1,'','','|SG|',0,0),(84,1,0,3,'REGO','',3,'NEW','','','','','DOCUMENT',35,1,1,'2014-12-01 21:11:07',0,'','','',0,0),(85,1,0,3,'REGO','',3,'NEW','','','','','DOCUMENT',36,1,1,'2014-12-01 21:11:07',1,'','','',0,0),(86,1,0,3,'REGO','',3,'NEW','','','','MINOR','DOCUMENT',37,1,1,'2014-12-01 21:11:07',1,'','','',0,0),(88,1,0,100,'REGO','',3,'NEW','','','','','DOCUMENT',32,1,1,'2014-12-01 21:11:07',1,'','','',0,0),(89,1,0,100,'REGO','',3,'NEW','','','','','DOCUMENT',33,1,1,'2014-12-01 21:11:07',1,'','','',0,0),(90,1,0,100,'REGO','',3,'NEW','','','','','DOCUMENT',34,1,1,'2014-12-16 00:04:41',1,'','','|SG|',0,0),(91,1,0,100,'REGO','',3,'NEW','','','','','DOCUMENT',35,1,1,'2014-12-01 21:11:07',0,'','','',0,0),(92,1,0,100,'REGO','',3,'NEW','','','','','DOCUMENT',36,1,1,'2014-12-01 21:11:07',1,'','','',0,0),(93,1,0,100,'REGO','',3,'NEW','','','','MINOR','DOCUMENT',37,1,1,'2014-12-01 21:11:07',1,'','','',0,0),(95,1,0,100,'REGO','',100,'NEW','','','','','DOCUMENT',32,1,1,'2014-12-01 21:11:07',1,'','','',0,0),(96,1,0,100,'REGO','',100,'NEW','','','','','DOCUMENT',33,1,1,'2014-12-01 21:11:07',1,'','','',0,0),(97,1,0,100,'REGO','',100,'NEW','','','','','DOCUMENT',34,1,1,'2014-12-16 00:04:41',1,'','','|SG|',0,0),(98,1,0,100,'REGO','',100,'NEW','','','','','DOCUMENT',35,1,1,'2014-12-01 21:11:07',0,'','','',0,0),(99,1,0,100,'REGO','',100,'NEW','','','','','DOCUMENT',36,1,1,'2014-12-01 21:11:07',1,'','','',0,0),(100,1,0,100,'REGO','',100,'NEW','','','','MINOR','DOCUMENT',37,1,1,'2014-12-01 21:11:07',1,'','','',0,0),(102,1,0,3,'REGO','',3,'NEW','PLAYER','PROFESSIONAL','','','DOCUMENT',38,0,0,'2014-12-01 08:54:38',1,'','','',0,0),(103,1,0,3,'REGO','',3,'NEW','PLAYER','AMATEUR_U_C','','','DOCUMENT',38,0,0,'2014-12-01 08:54:38',1,'','','',0,0),(104,1,0,100,'REGO','',3,'NEW','PLAYER','PROFESSIONAL','','','DOCUMENT',38,0,0,'2014-12-01 08:54:38',1,'','','',0,0),(105,1,0,100,'REGO','',3,'NEW','PLAYER','AMATEUR_U_C','','','DOCUMENT',38,0,0,'2014-12-01 08:54:38',1,'','','',0,0),(106,1,0,100,'REGO','',100,'NEW','PLAYER','PROFESSIONAL','','','DOCUMENT',38,0,0,'2014-12-01 08:54:38',1,'','','',0,0),(107,1,0,100,'REGO','',100,'NEW','PLAYER','AMATEUR_U_C','','','DOCUMENT',38,0,0,'2014-12-01 08:54:38',1,'','','',0,0),(109,1,0,3,'REGO','',3,'NEW','PLAYER','PROFESSIONAL','','','DOCUMENT',39,0,0,'2014-12-01 08:54:38',1,'','','',0,0),(110,1,0,3,'REGO','',3,'NEW','PLAYER','AMATEUR_U_C','','','DOCUMENT',39,0,0,'2014-12-01 08:54:38',1,'','','',0,0),(111,1,0,100,'REGO','',3,'NEW','PLAYER','PROFESSIONAL','','','DOCUMENT',39,0,0,'2014-12-01 08:54:38',1,'','','',0,0),(112,1,0,100,'REGO','',3,'NEW','PLAYER','AMATEUR_U_C','','','DOCUMENT',39,0,0,'2014-12-01 08:54:38',1,'','','',0,0),(113,1,0,100,'REGO','',100,'NEW','PLAYER','PROFESSIONAL','','','DOCUMENT',39,0,0,'2014-12-01 08:54:38',1,'','','',0,0),(114,1,0,100,'REGO','',100,'NEW','PLAYER','AMATEUR_U_C','','','DOCUMENT',39,0,0,'2014-12-01 08:54:38',1,'','','',0,0),(116,1,0,3,'REGO','',3,'NEW','PLAYER','','','','DOCUMENT',40,0,0,'2014-12-29 04:36:41',1,'','','|SG|',0,0),(117,1,0,100,'REGO','',3,'NEW','PLAYER','','','','DOCUMENT',40,0,0,'2014-12-29 04:36:41',1,'','','|SG|',0,0),(118,1,0,100,'REGO','',100,'NEW','PLAYER','','','','DOCUMENT',40,0,0,'2014-12-29 04:36:41',1,'','','|SG|',0,0),(119,1,0,3,'REGO','',3,'NEW','PLAYER','','','ADULT','DOCUMENT',41,0,0,'2015-01-13 23:42:51',1,'','','',35,0),(120,1,0,100,'REGO','',3,'NEW','PLAYER','','','ADULT','DOCUMENT',41,0,0,'2015-01-13 23:42:51',1,'','','',35,0),(121,1,0,100,'REGO','',100,'NEW','PLAYER','','','ADULT','DOCUMENT',41,0,0,'2015-01-13 23:42:51',1,'','','',35,0),(122,1,0,3,'REGO','',3,'NEW','PLAYER','','','','DOCUMENT',42,0,0,'2014-12-01 08:54:38',0,'','','',0,0),(123,1,0,100,'REGO','',3,'NEW','PLAYER','','','','DOCUMENT',42,0,0,'2014-12-01 08:54:38',0,'','','',0,0),(124,1,0,100,'REGO','',100,'NEW','PLAYER','','','','DOCUMENT',42,0,0,'2014-12-01 08:54:38',0,'','','',0,0),(125,1,0,3,'REGO','',3,'NEW','COACH','','','','DOCUMENT',43,0,0,'2014-12-01 08:54:38',1,'','','',0,0),(126,1,0,100,'REGO','',3,'NEW','COACH','','','','DOCUMENT',43,0,0,'2014-12-01 08:54:38',1,'','','',0,0),(127,1,0,100,'REGO','',100,'NEW','COACH','','','','DOCUMENT',43,0,0,'2014-12-01 08:54:38',1,'','','',0,0),(128,1,0,3,'REGO','',3,'NEW','COACH','','','','DOCUMENT',44,0,0,'2014-12-01 08:54:38',1,'','','',0,0),(129,1,0,100,'REGO','',3,'NEW','COACH','','','','DOCUMENT',44,0,0,'2014-12-01 08:54:38',1,'','','',0,0),(130,1,0,100,'REGO','',100,'NEW','COACH','','','','DOCUMENT',44,0,0,'2014-12-01 08:54:38',1,'','','',0,0),(131,1,0,3,'REGO','',3,'NEW','COACH','','','','DOCUMENT',45,0,0,'2014-12-01 08:54:38',0,'','','',0,0),(132,1,0,100,'REGO','',3,'NEW','COACH','','','','DOCUMENT',45,0,0,'2014-12-01 08:54:38',0,'','','',0,0),(133,1,0,100,'REGO','',100,'NEW','COACH','','','','DOCUMENT',45,0,0,'2014-12-01 08:54:38',0,'','','',0,0),(134,1,0,100,'REGO','',100,'NEW','REFEREE','','','','DOCUMENT',46,0,0,'2014-12-05 04:09:10',1,'','','',0,0),(136,1,0,100,'REGO','',100,'NEW','REFEREE','','','','DOCUMENT',48,0,0,'2014-12-05 04:09:10',0,'','','',0,0),(137,1,0,100,'REGO','',100,'NEW','REFEREE','','','','DOCUMENT',49,0,0,'2014-12-05 04:09:10',0,'','','',0,0),(138,1,0,100,'REGO','',100,'NEW','REFEREE','','','','DOCUMENT',50,0,0,'2014-12-05 04:09:10',0,'','','',0,0),(140,1,0,100,'REGO','',100,'NEW','REFEREE','','','ADULT','DOCUMENT',62,0,0,'2014-12-18 04:46:02',1,'','','',35,0),(141,1,0,100,'REGO','',100,'NEW','MAOFFICIAL','','','','DOCUMENT',52,0,0,'2014-12-01 08:54:38',0,'',NULL,NULL,0,0),(142,1,0,3,'REGO','',3,'NEW','CLUBOFFICIAL','','','','DOCUMENT',52,0,0,'2014-12-01 08:54:38',0,'',NULL,NULL,0,0),(143,1,0,100,'REGO','',3,'NEW','CLUBOFFICIAL','','','','DOCUMENT',52,0,0,'2014-12-01 08:54:38',0,'',NULL,NULL,0,0),(144,1,0,100,'REGO','',100,'NEW','CLUBOFFICIAL','','','','DOCUMENT',52,0,0,'2014-12-01 08:54:38',0,'',NULL,NULL,0,0),(145,1,0,3,'REGO','',3,'NEW','TEAMOFFICIAL','','','','DOCUMENT',52,0,0,'2014-12-01 08:54:38',0,'',NULL,NULL,0,0),(146,1,0,100,'REGO','',3,'NEW','TEAMOFFICIAL','','','','DOCUMENT',52,0,0,'2014-12-01 08:54:38',0,'',NULL,NULL,0,0),(147,1,0,100,'REGO','',100,'NEW','TEAMOFFICIAL','','','','DOCUMENT',52,0,0,'2014-12-01 08:54:38',0,'',NULL,NULL,0,0),(148,1,0,3,'REGO','',3,'NEW','TEAMOFFICIAL','','','','DOCUMENT',51,0,0,'2014-12-17 23:02:11',1,'DOCTOR',NULL,NULL,0,0),(149,1,0,100,'REGO','',3,'NEW','TEAMOFFICIAL','','','','DOCUMENT',51,0,0,'2014-12-17 23:02:11',1,'DOCTOR',NULL,NULL,0,0),(150,1,0,100,'REGO','',100,'NEW','TEAMOFFICIAL','','','','DOCUMENT',51,0,0,'2014-12-17 23:02:11',1,'DOCTOR',NULL,NULL,0,0),(151,1,0,3,'REGO','',3,'NEW','TEAMOFFICIAL','','','','DOCUMENT',51,0,0,'2014-12-17 23:02:11',1,'PHYSIO',NULL,NULL,0,0),(152,1,0,100,'REGO','',3,'NEW','TEAMOFFICIAL','','','','DOCUMENT',51,0,0,'2014-12-17 23:02:11',1,'PHYSIO',NULL,NULL,0,0),(153,1,0,100,'REGO','',100,'NEW','TEAMOFFICIAL','','','','DOCUMENT',51,0,0,'2014-12-17 23:02:11',1,'PHYSIO',NULL,NULL,0,0),(154,1,0,100,'ENTITY','',3,'NEW','','','','','DOCUMENT',53,0,0,'2014-12-04 09:50:02',1,'',NULL,NULL,0,0),(155,1,0,100,'ENTITY','',3,'NEW','','','','','DOCUMENT',54,0,0,'2014-12-04 09:50:02',1,'',NULL,NULL,0,0),(156,1,0,100,'ENTITY','',3,'NEW','','','','','DOCUMENT',55,0,0,'2014-12-04 09:50:02',1,'',NULL,NULL,0,0),(157,1,0,100,'ENTITY','',3,'NEW','','','','','DOCUMENT',56,0,0,'2014-12-04 09:50:02',1,'',NULL,NULL,0,0),(158,1,0,100,'ENTITY','',3,'NEW','','','','','DOCUMENT',57,0,0,'2014-12-04 09:50:02',1,'',NULL,NULL,0,0),(160,1,0,100,'ENTITY','',3,'NEW','','','','','DOCUMENT',59,0,0,'2014-12-04 09:50:02',1,'',NULL,NULL,0,0),(161,1,0,100,'ENTITY','',3,'NEW','','','','','DOCUMENT',60,0,0,'2015-01-09 07:23:11',1,'',NULL,NULL,0,0),(169,1,0,100,'ENTITY','',3,'NEW','','','','','DOCUMENT',61,0,0,'2015-01-09 07:23:11',1,'',NULL,NULL,0,0),(170,1,0,3,'ENTITY','',3,'RENEWAL','','','','','DOCUMENT',54,0,0,'2014-11-28 00:36:39',1,'',NULL,NULL,0,0),(171,1,0,3,'ENTITY','',3,'RENEWAL','','','','','DOCUMENT',55,0,0,'2014-11-28 00:36:39',1,'',NULL,NULL,0,0),(172,1,0,3,'ENTITY','',3,'RENEWAL','','','','','DOCUMENT',57,0,0,'2014-11-28 00:36:39',1,'',NULL,NULL,0,0),(173,1,0,100,'ENTITY','',3,'RENEWAL','','','','','DOCUMENT',54,0,0,'2014-11-28 00:36:40',1,'',NULL,NULL,0,0),(174,1,0,100,'ENTITY','',3,'RENEWAL','','','','','DOCUMENT',55,0,0,'2014-11-28 00:36:40',1,'',NULL,NULL,0,0),(175,1,0,100,'ENTITY','',3,'RENEWAL','','','','','DOCUMENT',57,0,0,'2014-11-28 00:36:40',1,'',NULL,NULL,0,0),(176,1,0,3,'REGO','',3,'NEW','PLAYER','PROFESSIONAL','FOOTBALL','ADULT','PRODUCT',3,0,0,'2014-12-01 08:00:07',1,'',NULL,NULL,0,0),(177,1,0,3,'REGO','',3,'NEW','PLAYER','AMATEUR','FOOTBALL','ADULT','PRODUCT',4,0,0,'2014-12-01 09:11:08',1,'',NULL,NULL,0,0),(178,1,0,3,'REGO','',3,'NEW','PLAYER','AMATEUR_U_C','FOOTBALL','ADULT','PRODUCT',4,0,0,'2014-12-01 09:25:28',1,'',NULL,NULL,0,0),(179,1,0,3,'REGO','',3,'NEW','PLAYER','AMATEUR','FOOTBALL','MINOR','PRODUCT',5,0,0,'2014-12-01 10:00:11',1,'',NULL,NULL,0,0),(180,1,0,100,'REGO','',3,'NEW','PLAYER','PROFESSIONAL','FOOTBALL','ADULT','PRODUCT',3,0,0,'2014-12-01 12:10:35',1,'',NULL,NULL,0,0),(181,1,0,100,'REGO','',3,'NEW','PLAYER','AMATEUR','FOOTBALL','ADULT','PRODUCT',4,0,0,'2014-12-01 12:10:35',1,'',NULL,NULL,0,0),(182,1,0,100,'REGO','',3,'NEW','PLAYER','AMATEUR_U_C','FOOTBALL','ADULT','PRODUCT',4,0,0,'2014-12-01 12:10:36',1,'',NULL,NULL,0,0),(183,1,0,100,'REGO','',3,'NEW','PLAYER','AMATEUR','FOOTBALL','MINOR','PRODUCT',5,0,0,'2014-12-01 12:10:36',1,'',NULL,NULL,0,0),(184,1,0,3,'REGO','',3,'NEW','COACH','','','','PRODUCT',1,0,0,'2014-12-01 12:14:46',1,'',NULL,NULL,0,0),(185,1,0,100,'REGO','',3,'NEW','COACH','','','','PRODUCT',1,0,0,'2014-12-01 12:14:46',1,'',NULL,NULL,0,0),(186,1,0,100,'REGO','',100,'NEW','COACH','','','','PRODUCT',1,0,0,'2014-12-01 12:14:46',1,'',NULL,NULL,0,0),(187,1,0,100,'REGO','',100,'NEW','REFEREE','','FOOTBALL','','PRODUCT',2,0,0,'2014-12-09 03:03:25',1,'','','',0,0),(188,1,0,3,'REGO','',3,'TRANSFER','PLAYER','','','','PRODUCT',6,0,0,'2014-12-10 10:37:57',1,'',NULL,NULL,0,0),(225,1,0,3,'REGO','',3,'TRANSFER','','','','','DOCUMENT',32,1,1,'2014-12-15 12:08:45',1,'','','',0,0),(226,1,0,100,'REGO','',3,'TRANSFER','','','','','DOCUMENT',32,1,1,'2014-12-15 12:08:45',1,'','','',0,0),(227,1,0,100,'REGO','',100,'TRANSFER','','','','','DOCUMENT',32,1,1,'2014-12-15 12:08:45',1,'','','',0,0),(228,1,0,3,'REGO','',3,'TRANSFER','','','','','DOCUMENT',33,1,1,'2014-12-15 12:08:45',1,'','','',0,0),(229,1,0,100,'REGO','',3,'TRANSFER','','','','','DOCUMENT',33,1,1,'2014-12-15 12:08:45',1,'','','',0,0),(230,1,0,100,'REGO','',100,'TRANSFER','','','','','DOCUMENT',33,1,1,'2014-12-15 12:08:45',1,'','','',0,0),(231,1,0,3,'REGO','',3,'TRANSFER','','','','','DOCUMENT',34,1,1,'2014-12-15 12:08:45',1,'','','|SG|',0,0),(232,1,0,100,'REGO','',3,'TRANSFER','','','','','DOCUMENT',34,1,1,'2014-12-15 12:08:45',1,'','','|SG|',0,0),(233,1,0,100,'REGO','',100,'TRANSFER','','','','','DOCUMENT',34,1,1,'2014-12-15 12:08:45',1,'','','|SG|',0,0),(234,1,0,3,'REGO','',3,'TRANSFER','','','','','DOCUMENT',35,1,1,'2014-12-15 12:08:45',0,'','','',0,0),(235,1,0,100,'REGO','',3,'TRANSFER','','','','','DOCUMENT',35,1,1,'2014-12-15 12:08:45',0,'','','',0,0),(236,1,0,100,'REGO','',100,'TRANSFER','','','','','DOCUMENT',35,1,1,'2014-12-15 12:08:45',0,'','','',0,0),(237,1,0,3,'REGO','',3,'TRANSFER','','','','','DOCUMENT',36,1,1,'2014-12-15 12:08:45',1,'','','',0,0),(238,1,0,100,'REGO','',3,'TRANSFER','','','','','DOCUMENT',36,1,1,'2014-12-15 12:08:45',1,'','','',0,0),(239,1,0,100,'REGO','',100,'TRANSFER','','','','','DOCUMENT',36,1,1,'2014-12-15 12:08:45',1,'','','',0,0),(240,1,0,3,'REGO','',3,'TRANSFER','','','','MINOR','DOCUMENT',37,1,1,'2014-12-15 12:08:45',1,'','','',0,0),(241,1,0,100,'REGO','',3,'TRANSFER','','','','MINOR','DOCUMENT',37,1,1,'2014-12-15 12:08:45',1,'','','',0,0),(242,1,0,100,'REGO','',100,'TRANSFER','','','','MINOR','DOCUMENT',37,1,1,'2014-12-15 12:08:45',1,'','','',0,0),(243,1,0,3,'REGO','',3,'TRANSFER','PLAYER','PROFESSIONAL','','','DOCUMENT',38,0,0,'2014-12-16 21:03:23',1,'','','',0,0),(244,1,0,3,'REGO','',3,'TRANSFER','PLAYER','AMATEUR_U_C','','','DOCUMENT',38,0,0,'2014-12-16 21:03:23',1,'','','',0,0),(245,1,0,100,'REGO','',3,'TRANSFER','PLAYER','PROFESSIONAL','','','DOCUMENT',38,0,0,'2014-12-16 21:03:23',1,'','','',0,0),(246,1,0,100,'REGO','',3,'TRANSFER','PLAYER','AMATEUR_U_C','','','DOCUMENT',38,0,0,'2014-12-16 21:03:23',1,'','','',0,0),(247,1,0,100,'REGO','',100,'TRANSFER','PLAYER','PROFESSIONAL','','','DOCUMENT',38,0,0,'2014-12-16 21:03:23',1,'','','',0,0),(248,1,0,100,'REGO','',100,'TRANSFER','PLAYER','AMATEUR_U_C','','','DOCUMENT',38,0,0,'2014-12-16 21:03:23',1,'','','',0,0),(249,1,0,3,'REGO','',3,'TRANSFER','PLAYER','PROFESSIONAL','','','DOCUMENT',39,1,1,'2014-12-16 20:57:07',1,'','','',0,0),(250,1,0,3,'REGO','',3,'TRANSFER','PLAYER','AMATEUR_U_C','','','DOCUMENT',39,1,1,'2014-12-16 20:57:07',1,'','','',0,0),(251,1,0,100,'REGO','',3,'TRANSFER','PLAYER','PROFESSIONAL','','','DOCUMENT',39,1,1,'2014-12-16 20:57:07',1,'','','',0,0),(252,1,0,100,'REGO','',3,'TRANSFER','PLAYER','AMATEUR_U_C','','','DOCUMENT',39,1,1,'2014-12-16 20:57:07',1,'','','',0,0),(253,1,0,100,'REGO','',100,'TRANSFER','PLAYER','PROFESSIONAL','','','DOCUMENT',39,1,1,'2014-12-16 20:57:07',1,'','','',0,0),(254,1,0,100,'REGO','',100,'TRANSFER','PLAYER','AMATEUR_U_C','','','DOCUMENT',39,1,1,'2014-12-16 20:57:07',1,'','','',0,0),(258,1,0,3,'REGO','',3,'TRANSFER','PLAYER','','','ADULT','DOCUMENT',41,0,0,'2015-01-13 23:42:51',1,'','','',35,0),(259,1,0,100,'REGO','',3,'TRANSFER','PLAYER','','','ADULT','DOCUMENT',41,0,0,'2015-01-13 23:42:51',1,'','','',35,0),(260,1,0,100,'REGO','',100,'TRANSFER','PLAYER','','','ADULT','DOCUMENT',41,0,0,'2015-01-13 23:42:51',1,'','','',35,0),(261,1,0,3,'REGO','',3,'TRANSFER','PLAYER','','','','DOCUMENT',42,1,1,'2014-12-16 20:57:07',0,'','','',0,0),(262,1,0,100,'REGO','',3,'TRANSFER','PLAYER','','','','DOCUMENT',42,1,1,'2014-12-16 20:57:07',0,'','','',0,0),(263,1,0,100,'REGO','',100,'TRANSFER','PLAYER','','','','DOCUMENT',42,1,1,'2014-12-16 20:57:07',0,'','','',0,0),(264,1,0,100,'REGO','',100,'TRANSFER','PLAYER','','','','DOCUMENT',42,1,1,'2014-12-16 20:57:07',0,'','','',0,0),(305,1,0,3,'REGO','',3,'RENEWAL','','','','','DOCUMENT',32,1,1,'2014-12-01 21:11:07',1,'','','',0,0),(306,1,0,3,'REGO','',3,'RENEWAL','','','','','DOCUMENT',33,1,1,'2014-12-01 21:11:07',1,'','','',0,0),(307,1,0,3,'REGO','',3,'RENEWAL','','','','','DOCUMENT',34,1,1,'2014-12-16 00:04:41',1,'','','|SG|',0,0),(308,1,0,3,'REGO','',3,'RENEWAL','','','','','DOCUMENT',35,1,1,'2014-12-01 21:11:07',0,'','','',0,0),(309,1,0,3,'REGO','',3,'RENEWAL','','','','','DOCUMENT',36,1,1,'2014-12-01 21:11:07',1,'','','',0,0),(310,1,0,3,'REGO','',3,'RENEWAL','','','','MINOR','DOCUMENT',37,1,1,'2014-12-01 21:11:07',1,'','','',0,0),(311,1,0,100,'REGO','',3,'RENEWAL','','','','','DOCUMENT',32,1,1,'2014-12-01 21:11:07',1,'','','',0,0),(312,1,0,100,'REGO','',3,'RENEWAL','','','','','DOCUMENT',33,1,1,'2014-12-01 21:11:07',1,'','','',0,0),(313,1,0,100,'REGO','',3,'RENEWAL','','','','','DOCUMENT',34,1,1,'2014-12-16 00:04:41',1,'','','|SG|',0,0),(314,1,0,100,'REGO','',3,'RENEWAL','','','','','DOCUMENT',35,1,1,'2014-12-01 21:11:07',0,'','','',0,0),(315,1,0,100,'REGO','',3,'RENEWAL','','','','','DOCUMENT',36,1,1,'2014-12-01 21:11:07',1,'','','',0,0),(316,1,0,100,'REGO','',3,'RENEWAL','','','','MINOR','DOCUMENT',37,1,1,'2014-12-01 21:11:07',1,'','','',0,0),(317,1,0,100,'REGO','',100,'RENEWAL','','','','','DOCUMENT',32,1,1,'2014-12-01 21:11:07',1,'','','',0,0),(318,1,0,100,'REGO','',100,'RENEWAL','','','','','DOCUMENT',33,1,1,'2014-12-01 21:11:07',1,'','','',0,0),(319,1,0,100,'REGO','',100,'RENEWAL','','','','','DOCUMENT',34,1,1,'2014-12-16 00:04:41',1,'','','|SG|',0,0),(320,1,0,100,'REGO','',100,'RENEWAL','','','','','DOCUMENT',35,1,1,'2014-12-01 21:11:07',0,'','','',0,0),(321,1,0,100,'REGO','',100,'RENEWAL','','','','','DOCUMENT',36,1,1,'2014-12-01 21:11:07',1,'','','',0,0),(322,1,0,100,'REGO','',100,'RENEWAL','','','','MINOR','DOCUMENT',37,1,1,'2014-12-01 21:11:07',1,'','','',0,0),(323,1,0,3,'REGO','',3,'RENEWAL','PLAYER','PROFESSIONAL','','','DOCUMENT',38,0,0,'2014-12-01 08:54:38',1,'','','',0,0),(324,1,0,3,'REGO','',3,'RENEWAL','PLAYER','AMATEUR_U_C','','','DOCUMENT',38,0,0,'2014-12-01 08:54:38',1,'','','',0,0),(325,1,0,100,'REGO','',3,'RENEWAL','PLAYER','PROFESSIONAL','','','DOCUMENT',38,0,0,'2014-12-01 08:54:38',1,'','','',0,0),(326,1,0,100,'REGO','',3,'RENEWAL','PLAYER','AMATEUR_U_C','','','DOCUMENT',38,0,0,'2014-12-01 08:54:38',1,'','','',0,0),(327,1,0,100,'REGO','',100,'RENEWAL','PLAYER','PROFESSIONAL','','','DOCUMENT',38,0,0,'2014-12-01 08:54:38',1,'','','',0,0),(328,1,0,100,'REGO','',100,'RENEWAL','PLAYER','AMATEUR_U_C','','','DOCUMENT',38,0,0,'2014-12-01 08:54:38',1,'','','',0,0),(329,1,0,3,'REGO','',3,'RENEWAL','PLAYER','PROFESSIONAL','','','DOCUMENT',39,0,0,'2014-12-01 08:54:38',1,'','','',0,0),(330,1,0,3,'REGO','',3,'RENEWAL','PLAYER','AMATEUR_U_C','','','DOCUMENT',39,0,0,'2014-12-01 08:54:38',1,'','','',0,0),(331,1,0,100,'REGO','',3,'RENEWAL','PLAYER','PROFESSIONAL','','','DOCUMENT',39,0,0,'2014-12-01 08:54:38',1,'','','',0,0),(332,1,0,100,'REGO','',3,'RENEWAL','PLAYER','AMATEUR_U_C','','','DOCUMENT',39,0,0,'2014-12-01 08:54:38',1,'','','',0,0),(333,1,0,100,'REGO','',100,'RENEWAL','PLAYER','PROFESSIONAL','','','DOCUMENT',39,0,0,'2014-12-01 08:54:38',1,'','','',0,0),(334,1,0,100,'REGO','',100,'RENEWAL','PLAYER','AMATEUR_U_C','','','DOCUMENT',39,0,0,'2014-12-01 08:54:38',1,'','','',0,0),(338,1,0,3,'REGO','',3,'RENEWAL','PLAYER','','','ADULT','DOCUMENT',41,0,0,'2015-01-13 23:42:51',1,'','','',35,0),(339,1,0,100,'REGO','',3,'RENEWAL','PLAYER','','','ADULT','DOCUMENT',41,0,0,'2015-01-13 23:42:51',1,'','','',35,0),(340,1,0,100,'REGO','',100,'RENEWAL','PLAYER','','','ADULT','DOCUMENT',41,0,0,'2015-01-13 23:42:51',1,'','','',35,0),(341,1,0,3,'REGO','',3,'RENEWAL','PLAYER','','','','DOCUMENT',42,0,0,'2014-12-01 08:54:38',0,'','','',0,0),(342,1,0,100,'REGO','',3,'RENEWAL','PLAYER','','','','DOCUMENT',42,0,0,'2014-12-01 08:54:38',0,'','','',0,0),(343,1,0,100,'REGO','',100,'RENEWAL','PLAYER','','','','DOCUMENT',42,0,0,'2014-12-01 08:54:38',0,'','','',0,0),(344,1,0,3,'REGO','',3,'RENEWAL','COACH','','','','DOCUMENT',43,0,0,'2014-12-01 08:54:38',1,'','','',0,0),(345,1,0,100,'REGO','',3,'RENEWAL','COACH','','','','DOCUMENT',43,0,0,'2014-12-01 08:54:38',1,'','','',0,0),(346,1,0,100,'REGO','',100,'RENEWAL','COACH','','','','DOCUMENT',43,0,0,'2014-12-01 08:54:38',1,'','','',0,0),(347,1,0,3,'REGO','',3,'RENEWAL','COACH','','','','DOCUMENT',44,0,0,'2014-12-01 08:54:38',1,'','','',0,0),(348,1,0,100,'REGO','',3,'RENEWAL','COACH','','','','DOCUMENT',44,0,0,'2014-12-01 08:54:38',1,'','','',0,0),(349,1,0,100,'REGO','',100,'RENEWAL','COACH','','','','DOCUMENT',44,0,0,'2014-12-01 08:54:38',1,'','','',0,0),(350,1,0,3,'REGO','',3,'RENEWAL','COACH','','','','DOCUMENT',45,0,0,'2014-12-01 08:54:38',0,'','','',0,0),(351,1,0,100,'REGO','',3,'RENEWAL','COACH','','','','DOCUMENT',45,0,0,'2014-12-01 08:54:38',0,'','','',0,0),(352,1,0,100,'REGO','',100,'RENEWAL','COACH','','','','DOCUMENT',45,0,0,'2014-12-01 08:54:38',0,'','','',0,0),(353,1,0,100,'REGO','',100,'RENEWAL','REFEREE','','','','DOCUMENT',46,0,0,'2014-12-05 04:09:10',1,'','','',0,0),(355,1,0,100,'REGO','',100,'RENEWAL','REFEREE','','','','DOCUMENT',48,0,0,'2014-12-05 04:09:10',0,'','','',0,0),(356,1,0,100,'REGO','',100,'RENEWAL','REFEREE','','','','DOCUMENT',49,0,0,'2014-12-05 04:09:10',0,'','','',0,0),(357,1,0,100,'REGO','',100,'RENEWAL','REFEREE','','','','DOCUMENT',50,0,0,'2014-12-05 04:09:10',0,'','','',0,0),(358,1,0,100,'REGO','',100,'RENEWAL','REFEREE','','','ADULT','DOCUMENT',62,0,0,'2014-12-18 04:46:02',1,'','','',35,0),(359,1,0,100,'REGO','',100,'RENEWAL','MAOFFICIAL','','','','DOCUMENT',52,0,0,'2014-12-01 08:54:38',0,'',NULL,NULL,0,0),(360,1,0,3,'REGO','',3,'RENEWAL','CLUBOFFICIAL','','','','DOCUMENT',52,0,0,'2014-12-01 08:54:38',0,'',NULL,NULL,0,0),(361,1,0,100,'REGO','',3,'RENEWAL','CLUBOFFICIAL','','','','DOCUMENT',52,0,0,'2014-12-01 08:54:38',0,'',NULL,NULL,0,0),(362,1,0,100,'REGO','',100,'RENEWAL','CLUBOFFICIAL','','','','DOCUMENT',52,0,0,'2014-12-01 08:54:38',0,'',NULL,NULL,0,0),(363,1,0,3,'REGO','',3,'RENEWAL','TEAMOFFICIAL','','','','DOCUMENT',52,0,0,'2014-12-01 08:54:38',0,'',NULL,NULL,0,0),(364,1,0,100,'REGO','',3,'RENEWAL','TEAMOFFICIAL','','','','DOCUMENT',52,0,0,'2014-12-01 08:54:38',0,'',NULL,NULL,0,0),(365,1,0,100,'REGO','',100,'RENEWAL','TEAMOFFICIAL','','','','DOCUMENT',52,0,0,'2014-12-01 08:54:38',0,'',NULL,NULL,0,0),(366,1,0,3,'REGO','',3,'RENEWAL','TEAMOFFICIAL','','','','DOCUMENT',51,0,0,'2014-12-17 23:02:11',1,'DOCTOR',NULL,NULL,0,0),(367,1,0,100,'REGO','',3,'RENEWAL','TEAMOFFICIAL','','','','DOCUMENT',51,0,0,'2014-12-17 23:02:11',1,'DOCTOR',NULL,NULL,0,0),(368,1,0,100,'REGO','',100,'RENEWAL','TEAMOFFICIAL','','','','DOCUMENT',51,0,0,'2014-12-17 23:02:11',1,'DOCTOR',NULL,NULL,0,0),(369,1,0,3,'REGO','',3,'RENEWAL','TEAMOFFICIAL','','','','DOCUMENT',51,0,0,'2014-12-17 23:02:11',1,'PHYSIO',NULL,NULL,0,0),(370,1,0,100,'REGO','',3,'RENEWAL','TEAMOFFICIAL','','','','DOCUMENT',51,0,0,'2014-12-17 23:02:11',1,'PHYSIO',NULL,NULL,0,0),(371,1,0,100,'REGO','',100,'RENEWAL','TEAMOFFICIAL','','','','DOCUMENT',51,0,0,'2014-12-17 23:02:11',1,'PHYSIO',NULL,NULL,0,0),(432,1,0,100,'ENTITY','',3,'NEW','','','','','PRODUCT',9,0,0,'2014-12-17 22:37:47',0,'','','',0,0),(433,1,0,100,'ENTITY','',3,'NEW','','','','','PRODUCT',10,0,0,'2014-12-17 22:37:47',0,'','','',0,0),(434,1,0,100,'ENTITY','',3,'NEW','','','','','PRODUCT',11,0,0,'2014-12-17 22:37:47',0,'','','',0,0),(435,1,0,100,'ENTITY','',3,'NEW','','','','','PRODUCT',12,0,0,'2014-12-17 22:37:47',0,'','','',0,0),(438,1,0,3,'REGO','',3,'RENEWAL','COACH','','','','PRODUCT',1,0,0,'2014-12-23 00:57:49',1,'',NULL,NULL,0,0),(439,1,0,100,'REGO','',3,'RENEWAL','COACH','','','','PRODUCT',1,0,0,'2014-12-23 00:57:49',1,'',NULL,NULL,0,0),(440,1,0,100,'REGO','',100,'RENEWAL','COACH','','','','PRODUCT',1,0,0,'2014-12-23 00:57:49',1,'',NULL,NULL,0,0),(441,1,0,100,'REGO','',100,'RENEWAL','REFEREE','','FOOTBALL','','PRODUCT',2,0,0,'2014-12-23 00:58:24',1,'','','',0,0),(442,1,0,3,'REGO','',3,'RENEWAL','PLAYER','PROFESSIONAL','FOOTBALL','ADULT','PRODUCT',3,0,0,'2014-12-23 00:58:50',1,'',NULL,NULL,0,0),(443,1,0,100,'REGO','',3,'RENEWAL','PLAYER','PROFESSIONAL','FOOTBALL','ADULT','PRODUCT',3,0,0,'2014-12-23 00:58:50',1,'',NULL,NULL,0,0),(445,1,0,3,'REGO','',3,'RENEWAL','PLAYER','AMATEUR','FOOTBALL','ADULT','PRODUCT',4,0,0,'2014-12-23 00:59:28',1,'',NULL,NULL,0,0),(446,1,0,3,'REGO','',3,'RENEWAL','PLAYER','AMATEUR_U_C','FOOTBALL','ADULT','PRODUCT',4,0,0,'2014-12-23 00:59:28',1,'',NULL,NULL,0,0),(447,1,0,100,'REGO','',3,'RENEWAL','PLAYER','AMATEUR','FOOTBALL','ADULT','PRODUCT',4,0,0,'2014-12-23 00:59:28',1,'',NULL,NULL,0,0),(448,1,0,100,'REGO','',3,'RENEWAL','PLAYER','AMATEUR_U_C','FOOTBALL','ADULT','PRODUCT',4,0,0,'2014-12-23 00:59:28',1,'',NULL,NULL,0,0),(452,1,0,3,'REGO','',3,'RENEWAL','PLAYER','AMATEUR','FOOTBALL','MINOR','PRODUCT',5,0,0,'2014-12-23 01:00:14',1,'',NULL,NULL,0,0),(453,1,0,100,'REGO','',3,'RENEWAL','PLAYER','AMATEUR','FOOTBALL','MINOR','PRODUCT',5,0,0,'2014-12-23 01:00:14',1,'',NULL,NULL,0,0),(455,1,0,3,'REGO','',3,'TRANSFER','PLAYER','PROFESSIONAL','FOOTBALL','ADULT','PRODUCT',3,0,0,'2014-12-23 01:03:41',1,'',NULL,NULL,0,0),(456,1,0,3,'REGO','',3,'TRANSFER','PLAYER','AMATEUR','FOOTBALL','ADULT','PRODUCT',4,0,0,'2014-12-23 01:03:41',1,'',NULL,NULL,0,0),(457,1,0,3,'REGO','',3,'TRANSFER','PLAYER','AMATEUR_U_C','FOOTBALL','ADULT','PRODUCT',4,0,0,'2014-12-23 01:03:41',1,'',NULL,NULL,0,0),(458,1,0,3,'REGO','',3,'TRANSFER','PLAYER','AMATEUR','FOOTBALL','MINOR','PRODUCT',5,0,0,'2014-12-23 01:03:41',1,'',NULL,NULL,0,0),(459,1,0,100,'REGO','',3,'TRANSFER','PLAYER','PROFESSIONAL','FOOTBALL','ADULT','PRODUCT',3,0,0,'2014-12-23 01:03:41',1,'',NULL,NULL,0,0),(460,1,0,100,'REGO','',3,'TRANSFER','PLAYER','AMATEUR','FOOTBALL','ADULT','PRODUCT',4,0,0,'2014-12-23 01:03:41',1,'',NULL,NULL,0,0),(461,1,0,100,'REGO','',3,'TRANSFER','PLAYER','AMATEUR_U_C','FOOTBALL','ADULT','PRODUCT',4,0,0,'2014-12-23 01:03:41',1,'',NULL,NULL,0,0),(462,1,0,100,'REGO','',3,'TRANSFER','PLAYER','AMATEUR','FOOTBALL','MINOR','PRODUCT',5,0,0,'2014-12-23 01:03:41',1,'',NULL,NULL,0,0),(470,1,0,3,'PERSON','',3,'AMENDMENT','','','','','DOCUMENT',32,1,1,'2014-12-28 21:49:12',1,'','','',0,0),(471,1,0,3,'PERSON','',3,'AMENDMENT','','','','','DOCUMENT',33,1,1,'2014-12-28 21:49:12',1,'','','',0,0),(472,1,0,3,'PERSON','',3,'AMENDMENT','','','','','DOCUMENT',34,1,1,'2014-12-28 21:49:12',1,'','','|SG|',0,0),(473,1,0,3,'PERSON','',3,'AMENDMENT','','','','','DOCUMENT',35,1,1,'2014-12-29 01:49:40',0,'','','',0,0),(474,1,0,3,'PERSON','',3,'AMENDMENT','','','','','DOCUMENT',36,1,1,'2014-12-28 21:49:12',1,'','','',0,0),(475,1,0,3,'PERSON','',3,'AMENDMENT','','','','','DOCUMENT',37,1,1,'2014-12-29 01:53:02',1,'','','',6,21),(476,1,0,100,'PERSON','',3,'AMENDMENT','','','','','DOCUMENT',32,1,1,'2014-12-28 21:49:12',1,'','','',0,0),(477,1,0,100,'PERSON','',3,'AMENDMENT','','','','','DOCUMENT',33,1,1,'2014-12-28 21:49:12',1,'','','',0,0),(478,1,0,100,'PERSON','',3,'AMENDMENT','','','','','DOCUMENT',34,1,1,'2014-12-28 21:49:12',1,'','','|SG|',0,0),(479,1,0,100,'PERSON','',3,'AMENDMENT','','','','','DOCUMENT',35,1,1,'2014-12-29 01:49:40',0,'','','',0,0),(480,1,0,100,'PERSON','',3,'AMENDMENT','','','','','DOCUMENT',36,1,1,'2014-12-28 21:49:12',1,'','','',0,0),(481,1,0,100,'PERSON','',3,'AMENDMENT','','','','','DOCUMENT',37,1,1,'2014-12-29 01:53:02',1,'','','',6,21),(482,1,0,100,'PERSON','',100,'AMENDMENT','','','','','DOCUMENT',32,1,1,'2014-12-28 21:49:12',1,'','','',0,0),(483,1,0,100,'PERSON','',100,'AMENDMENT','','','','','DOCUMENT',33,1,1,'2014-12-28 21:49:12',1,'','','',0,0),(484,1,0,100,'PERSON','',100,'AMENDMENT','','','','','DOCUMENT',34,1,1,'2014-12-28 21:49:12',1,'','','|SG|',0,0),(485,1,0,100,'PERSON','',100,'AMENDMENT','','','','','DOCUMENT',35,1,1,'2014-12-29 01:49:40',0,'','','',0,0),(486,1,0,100,'PERSON','',100,'AMENDMENT','','','','','DOCUMENT',36,1,1,'2014-12-28 21:49:12',1,'','','',0,0),(487,1,0,100,'PERSON','',100,'AMENDMENT','','','','','DOCUMENT',37,1,1,'2014-12-29 01:53:02',1,'','','',6,21),(488,1,0,100,'ENTITY','',3,'NEW','','','','','DOCUMENT',63,0,0,'2015-01-15 03:48:11',0,'','','',0,0);
/*!40000 ALTER TABLE `tblRegistrationItem` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblRegoAgeRestrictions`
--

DROP TABLE IF EXISTS `tblRegoAgeRestrictions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblRegoAgeRestrictions` (
  `intRegoAgeRestrictionID` int(11) NOT NULL AUTO_INCREMENT,
  `intRealmID` int(11) DEFAULT '0',
  `intSubRealmID` int(11) DEFAULT '0',
  `strSport` varchar(20) DEFAULT '',
  `strPersonType` varchar(30) DEFAULT '',
  `strPersonEntityRole` varchar(30) DEFAULT '',
  `strPersonLevel` varchar(30) DEFAULT '',
  `strRestrictionType` varchar(20) DEFAULT '',
  `strAgeLevel` varchar(30) DEFAULT '',
  `intFromAge` int(11) DEFAULT '0',
  `intToAge` int(11) DEFAULT '0',
  `tTimestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`intRegoAgeRestrictionID`),
  KEY `index_intRealmID` (`intRealmID`),
  KEY `index_intSubRealmID` (`intSubRealmID`)
) ENGINE=InnoDB AUTO_INCREMENT=27 DEFAULT CHARSET=utf8 COMMENT='Age restriction rules for PERSON REGO';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblRegoAgeRestrictions`
--

LOCK TABLES `tblRegoAgeRestrictions` WRITE;
/*!40000 ALTER TABLE `tblRegoAgeRestrictions` DISABLE KEYS */;
INSERT INTO `tblRegoAgeRestrictions` VALUES (7,1,0,'','PLAYER','','','','ADULT',21,99,'2014-09-14 22:39:59'),(8,1,0,'','PLAYER','','','','MINOR',6,21,'2014-09-14 23:09:19'),(12,1,0,'','CLUBOFFICIAL','','','','MINOR',6,21,'2014-09-14 23:09:19'),(13,1,0,'','MAOFFICIAL','','','','MINOR',6,21,'2014-09-14 23:09:19'),(16,1,0,'','TEAMOFFICIAL','','','','MINOR',6,21,'2014-10-06 05:57:23'),(19,1,0,'','COACH','','','','MINOR',18,21,'2014-11-26 22:24:06'),(20,1,0,'','REFEREE','','','','MINOR',16,21,'2014-11-26 22:24:15'),(21,1,0,'','PLAYER','','PROFESSIONAL','','',16,99,'2014-12-02 21:20:45'),(22,1,0,'','REFEREE','','','','ADULT',21,45,'2014-11-26 22:24:15'),(23,1,0,'','MAOFFICIAL','','','','ADULT',21,99,'2014-09-14 23:09:19'),(24,1,0,'','TEAMOFFICIAL','','','','ADULT',21,99,'2014-10-06 05:57:23'),(25,1,0,'','CLUBOFFICIAL','','','','ADULT',21,99,'2014-09-14 23:09:19'),(26,1,0,'','COACH','','','','ADULT',21,99,'2014-11-26 22:24:06');
/*!40000 ALTER TABLE `tblRegoAgeRestrictions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblRegoForm`
--

DROP TABLE IF EXISTS `tblRegoForm`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblRegoForm` (
  `intRegoFormID` int(11) NOT NULL AUTO_INCREMENT,
  `intAssocID` int(11) NOT NULL DEFAULT '0',
  `intRealmID` int(11) NOT NULL DEFAULT '0',
  `intSubRealmID` int(11) NOT NULL DEFAULT '0',
  `intClubID` int(11) DEFAULT NULL,
  `strRegoFormName` text,
  `intRegoType` int(11) NOT NULL DEFAULT '0',
  `intRegoTypeLevel` int(11) DEFAULT '0',
  `intNewRegosAllowed` int(11) NOT NULL DEFAULT '0',
  `ynPlayer` char(1) DEFAULT NULL,
  `ynCoach` char(1) DEFAULT NULL,
  `ynMatchOfficial` char(1) DEFAULT NULL,
  `ynOfficial` char(1) DEFAULT NULL,
  `ynMisc` char(1) DEFAULT NULL,
  `intStatus` tinyint(4) DEFAULT '1',
  `intLinkedFormID` int(11) DEFAULT '0',
  `intAllowMultipleAdult` tinyint(4) DEFAULT '0',
  `intAllowMultipleChild` tinyint(4) DEFAULT '0',
  `intPreventTypeChange` tinyint(4) DEFAULT '0',
  `intAllowClubSelection` tinyint(4) DEFAULT '0',
  `intClubMandatory` tinyint(4) DEFAULT '0',
  `dtCreated` datetime DEFAULT NULL,
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `intTemplate` tinyint(4) DEFAULT '0',
  `intTemplateLevel` tinyint(4) DEFAULT '0',
  `intTemplateSourceID` int(11) DEFAULT '0',
  `intTemplateAssocID` int(11) DEFAULT '0',
  `intTemplateEntityID` int(11) DEFAULT '0',
  `dtTemplateExpiry` datetime DEFAULT NULL,
  `strTitle` varchar(100) DEFAULT '',
  `ynOther1` char(1) DEFAULT 'N',
  `ynOther2` char(1) DEFAULT 'N',
  `intNewBits` smallint(6) DEFAULT NULL,
  `intRenewalBits` smallint(6) DEFAULT NULL,
  `intPaymentBits` smallint(6) DEFAULT NULL,
  `intPaymentCompulsory` tinyint(4) DEFAULT '0',
  `intCreatedLevel` tinyint(3) unsigned DEFAULT '0',
  `intParentBodyFormID` int(11) DEFAULT '0',
  `intCreatedID` int(3) DEFAULT '0',
  PRIMARY KEY (`intRegoFormID`),
  KEY `index_intAssocID` (`intAssocID`),
  KEY `index_intClubID` (`intClubID`),
  KEY `index_intRegoType` (`intRegoType`)
) ENGINE=MyISAM AUTO_INCREMENT=36491 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblRegoForm`
--

LOCK TABLES `tblRegoForm` WRITE;
/*!40000 ALTER TABLE `tblRegoForm` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblRegoForm` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblRegoFormAdded`
--

DROP TABLE IF EXISTS `tblRegoFormAdded`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblRegoFormAdded` (
  `intRegoFormAddedID` int(11) NOT NULL AUTO_INCREMENT,
  `intRegoFormID` int(11) NOT NULL DEFAULT '0',
  `intEntityTypeID` tinyint(3) unsigned DEFAULT '0',
  `intEntityID` int(11) NOT NULL DEFAULT '0',
  `intPaymentCompulsory` tinyint(4) DEFAULT '0',
  PRIMARY KEY (`intRegoFormAddedID`),
  KEY `index_regoFormEntityTypeEntityID` (`intRegoFormID`,`intEntityTypeID`,`intEntityID`)
) ENGINE=MyISAM AUTO_INCREMENT=15 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblRegoFormAdded`
--

LOCK TABLES `tblRegoFormAdded` WRITE;
/*!40000 ALTER TABLE `tblRegoFormAdded` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblRegoFormAdded` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblRegoFormComps`
--

DROP TABLE IF EXISTS `tblRegoFormComps`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblRegoFormComps` (
  `intRegoFormCompID` int(11) NOT NULL AUTO_INCREMENT,
  `intRegoFormID` int(11) DEFAULT NULL,
  `intAssocID` int(11) NOT NULL DEFAULT '0',
  `intRealmID` int(11) NOT NULL DEFAULT '0',
  `intSubRealmID` int(11) NOT NULL DEFAULT '0',
  `intCompID` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`intRegoFormCompID`),
  KEY `index_intRealmID` (`intRealmID`,`intSubRealmID`),
  KEY `index_intAssocID` (`intAssocID`),
  KEY `index_intCompID` (`intCompID`)
) ENGINE=MyISAM AUTO_INCREMENT=35469 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblRegoFormComps`
--

LOCK TABLES `tblRegoFormComps` WRITE;
/*!40000 ALTER TABLE `tblRegoFormComps` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblRegoFormComps` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblRegoFormConfig`
--

DROP TABLE IF EXISTS `tblRegoFormConfig`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblRegoFormConfig` (
  `intRegoFormConfigID` int(11) NOT NULL AUTO_INCREMENT,
  `intRegoFormID` int(11) DEFAULT NULL,
  `intAssocID` int(11) NOT NULL DEFAULT '0',
  `intRealmID` int(11) NOT NULL DEFAULT '0',
  `intSubRealmID` int(11) NOT NULL DEFAULT '0',
  `strPageOneText` text,
  `strTopText` text,
  `strBottomText` text,
  `strSuccessText` text,
  `strAuthEmailText` text,
  `strIndivRegoSelect` text,
  `strTeamRegoSelect` text,
  `strPaymentText` text,
  `strTermsCondHeader` varchar(100) DEFAULT NULL,
  `strTermsCondText` text,
  `intTC_AgreeBox` tinyint(4) DEFAULT '0',
  PRIMARY KEY (`intRegoFormConfigID`),
  KEY `index_intRealmID` (`intRealmID`,`intSubRealmID`),
  KEY `index_intAssocID` (`intAssocID`)
) ENGINE=MyISAM AUTO_INCREMENT=68454 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblRegoFormConfig`
--

LOCK TABLES `tblRegoFormConfig` WRITE;
/*!40000 ALTER TABLE `tblRegoFormConfig` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblRegoFormConfig` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblRegoFormConfigAdded`
--

DROP TABLE IF EXISTS `tblRegoFormConfigAdded`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblRegoFormConfigAdded` (
  `intRegoFormConfigAddedID` int(11) NOT NULL AUTO_INCREMENT,
  `intRegoFormID` int(11) NOT NULL DEFAULT '0',
  `intEntityTypeID` tinyint(3) unsigned DEFAULT '0',
  `intEntityID` int(11) NOT NULL DEFAULT '0',
  `strTermsCondHeader` varchar(100) DEFAULT NULL,
  `strTermsCondText` text,
  `intTC_AgreeBox` tinyint(3) unsigned DEFAULT '0',
  PRIMARY KEY (`intRegoFormConfigAddedID`),
  KEY `index_regoFormEntityTypeEntityID` (`intRegoFormID`,`intEntityTypeID`,`intEntityID`)
) ENGINE=MyISAM AUTO_INCREMENT=67 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblRegoFormConfigAdded`
--

LOCK TABLES `tblRegoFormConfigAdded` WRITE;
/*!40000 ALTER TABLE `tblRegoFormConfigAdded` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblRegoFormConfigAdded` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblRegoFormFields`
--

DROP TABLE IF EXISTS `tblRegoFormFields`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblRegoFormFields` (
  `intRegoFormFieldID` int(11) NOT NULL AUTO_INCREMENT,
  `intRegoFormID` int(11) NOT NULL DEFAULT '0',
  `strFieldName` text,
  `intType` int(11) NOT NULL DEFAULT '0',
  `intDisplayOrder` int(11) NOT NULL DEFAULT '0',
  `strText` text,
  `intStatus` tinyint(4) DEFAULT '1',
  `strPerm` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`intRegoFormFieldID`),
  KEY `index_intRegoFormID` (`intRegoFormID`)
) ENGINE=MyISAM AUTO_INCREMENT=159670602 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblRegoFormFields`
--

LOCK TABLES `tblRegoFormFields` WRITE;
/*!40000 ALTER TABLE `tblRegoFormFields` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblRegoFormFields` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblRegoFormFieldsAdded`
--

DROP TABLE IF EXISTS `tblRegoFormFieldsAdded`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblRegoFormFieldsAdded` (
  `intRegoFormFieldAddedID` int(11) NOT NULL AUTO_INCREMENT,
  `intRegoFormID` int(11) NOT NULL DEFAULT '0',
  `intEntityTypeID` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `intEntityID` int(11) NOT NULL DEFAULT '0',
  `intAssocID` int(11) NOT NULL DEFAULT '0',
  `intClubID` int(11) NOT NULL DEFAULT '0',
  `strFieldName` text,
  `intType` int(11) NOT NULL DEFAULT '0',
  `intDisplayOrder` int(11) NOT NULL DEFAULT '0',
  `strText` text,
  `intStatus` tinyint(4) DEFAULT '1',
  `strPerm` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`intRegoFormFieldAddedID`),
  KEY `index_regoFormAssocClubID` (`intRegoFormID`,`intAssocID`,`intClubID`),
  KEY `index_regoFormEntityTypeEntity` (`intRegoFormID`,`intEntityTypeID`,`intEntityID`)
) ENGINE=MyISAM AUTO_INCREMENT=1128 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblRegoFormFieldsAdded`
--

LOCK TABLES `tblRegoFormFieldsAdded` WRITE;
/*!40000 ALTER TABLE `tblRegoFormFieldsAdded` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblRegoFormFieldsAdded` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblRegoFormOrder`
--

DROP TABLE IF EXISTS `tblRegoFormOrder`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblRegoFormOrder` (
  `intRegoFormOrderID` int(11) NOT NULL AUTO_INCREMENT,
  `intRegoFormID` int(11) NOT NULL DEFAULT '0',
  `intEntityTypeID` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `intEntityID` int(11) NOT NULL DEFAULT '0',
  `intDisplayOrder` int(11) DEFAULT '0',
  `intSource` tinyint(3) unsigned NOT NULL DEFAULT '1' COMMENT '1=>node & normal form fields, 2=>linked, 3=>added (tblRegoFormFieldsAdded), 4=block (tblRegoFormBlock)',
  `intFieldID` int(11) NOT NULL DEFAULT '0' COMMENT 'intSource will indicate where from',
  `tTimestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`intRegoFormOrderID`),
  UNIQUE KEY `index_regoFormEntityTypeEntitySourceField` (`intRegoFormID`,`intEntityTypeID`,`intEntityID`,`intSource`,`intFieldID`),
  KEY `index_regoFormEntityTypeEntity` (`intRegoFormID`,`intEntityTypeID`,`intEntityID`)
) ENGINE=MyISAM AUTO_INCREMENT=43521 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblRegoFormOrder`
--

LOCK TABLES `tblRegoFormOrder` WRITE;
/*!40000 ALTER TABLE `tblRegoFormOrder` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblRegoFormOrder` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblRegoFormPrimary`
--

DROP TABLE IF EXISTS `tblRegoFormPrimary`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblRegoFormPrimary` (
  `intRegoFormPrimaryID` int(11) NOT NULL AUTO_INCREMENT,
  `intEntityTypeID` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `intEntityID` int(11) NOT NULL DEFAULT '0',
  `intRegoFormID` int(11) NOT NULL DEFAULT '0',
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`intRegoFormPrimaryID`),
  UNIQUE KEY `index_entityTypeEntityID` (`intEntityTypeID`,`intEntityID`)
) ENGINE=MyISAM AUTO_INCREMENT=505 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblRegoFormPrimary`
--

LOCK TABLES `tblRegoFormPrimary` WRITE;
/*!40000 ALTER TABLE `tblRegoFormPrimary` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblRegoFormPrimary` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblRegoFormProducts`
--

DROP TABLE IF EXISTS `tblRegoFormProducts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblRegoFormProducts` (
  `intRegoFormProductsID` int(11) NOT NULL AUTO_INCREMENT,
  `intRegoFormID` int(11) DEFAULT NULL,
  `intAssocID` int(11) NOT NULL DEFAULT '0',
  `intRealmID` int(11) NOT NULL DEFAULT '0',
  `intSubRealmID` int(11) NOT NULL DEFAULT '0',
  `intProductID` int(11) NOT NULL DEFAULT '0',
  `intRegoTypeLevel` int(11) DEFAULT '0',
  `intIsMandatory` tinyint(4) DEFAULT '0',
  `intSequence` smallint(6) DEFAULT '0',
  PRIMARY KEY (`intRegoFormProductsID`),
  KEY `index_intRealmID` (`intRealmID`,`intSubRealmID`),
  KEY `index_intAssocID` (`intAssocID`),
  KEY `index_intRegoTypeLevel` (`intRegoTypeLevel`),
  KEY `index_formID` (`intRegoFormID`),
  KEY `index_product` (`intProductID`,`intRegoFormID`)
) ENGINE=MyISAM AUTO_INCREMENT=159099 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblRegoFormProducts`
--

LOCK TABLES `tblRegoFormProducts` WRITE;
/*!40000 ALTER TABLE `tblRegoFormProducts` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblRegoFormProducts` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblRegoFormProductsAdded`
--

DROP TABLE IF EXISTS `tblRegoFormProductsAdded`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblRegoFormProductsAdded` (
  `intRegoFormProductAddedID` int(11) NOT NULL AUTO_INCREMENT,
  `intRegoFormID` int(11) DEFAULT NULL,
  `intAssocID` int(11) NOT NULL DEFAULT '0',
  `intClubID` int(11) NOT NULL DEFAULT '0',
  `intProductID` int(11) NOT NULL DEFAULT '0',
  `intRegoTypeLevel` int(11) DEFAULT '0',
  `intIsMandatory` tinyint(4) DEFAULT '0',
  `intSequence` smallint(6) DEFAULT '0',
  PRIMARY KEY (`intRegoFormProductAddedID`),
  KEY `index_regoFormAssocClubID` (`intRegoFormID`,`intAssocID`,`intClubID`)
) ENGINE=MyISAM AUTO_INCREMENT=78 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblRegoFormProductsAdded`
--

LOCK TABLES `tblRegoFormProductsAdded` WRITE;
/*!40000 ALTER TABLE `tblRegoFormProductsAdded` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblRegoFormProductsAdded` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblRegoFormRules`
--

DROP TABLE IF EXISTS `tblRegoFormRules`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblRegoFormRules` (
  `intRegoFormRuleID` int(11) NOT NULL AUTO_INCREMENT,
  `intRegoFormID` int(11) NOT NULL DEFAULT '0',
  `intRegoFormFieldID` int(11) DEFAULT NULL,
  `strFieldName` text,
  `strGender` char(1) DEFAULT NULL,
  `dtMinDOB` date DEFAULT NULL,
  `dtMaxDOB` date DEFAULT NULL,
  `ynPlayer` char(1) NOT NULL DEFAULT 'N',
  `ynCoach` char(1) NOT NULL DEFAULT 'N',
  `ynMatchOfficial` char(1) NOT NULL DEFAULT 'N',
  `ynOfficial` char(1) NOT NULL DEFAULT 'N',
  `ynMisc` char(1) NOT NULL DEFAULT 'N',
  `intStatus` tinyint(4) DEFAULT '1',
  PRIMARY KEY (`intRegoFormRuleID`),
  KEY `index_intRegoFormID` (`intRegoFormID`)
) ENGINE=MyISAM AUTO_INCREMENT=40148 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblRegoFormRules`
--

LOCK TABLES `tblRegoFormRules` WRITE;
/*!40000 ALTER TABLE `tblRegoFormRules` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblRegoFormRules` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblRegoFormRulesAdded`
--

DROP TABLE IF EXISTS `tblRegoFormRulesAdded`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblRegoFormRulesAdded` (
  `intRegoFormRuleAddedID` int(11) NOT NULL AUTO_INCREMENT,
  `intRegoFormID` int(11) NOT NULL DEFAULT '0',
  `intAssocID` int(11) NOT NULL DEFAULT '0',
  `intClubID` int(11) NOT NULL DEFAULT '0',
  `intRegoFormFieldAddedID` int(11) DEFAULT NULL,
  `strFieldName` text,
  `strGender` char(1) DEFAULT NULL,
  `dtMinDOB` date DEFAULT NULL,
  `dtMaxDOB` date DEFAULT NULL,
  `ynPlayer` char(1) NOT NULL DEFAULT 'N',
  `ynCoach` char(1) NOT NULL DEFAULT 'N',
  `ynMatchOfficial` char(1) NOT NULL DEFAULT 'N',
  `ynOfficial` char(1) NOT NULL DEFAULT 'N',
  `ynMisc` char(1) NOT NULL DEFAULT 'N',
  `intStatus` tinyint(4) DEFAULT '1',
  PRIMARY KEY (`intRegoFormRuleAddedID`),
  KEY `index_regoFormAssocClubID` (`intRegoFormID`,`intAssocID`,`intClubID`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblRegoFormRulesAdded`
--

LOCK TABLES `tblRegoFormRulesAdded` WRITE;
/*!40000 ALTER TABLE `tblRegoFormRulesAdded` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblRegoFormRulesAdded` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblRegoFormSession`
--

DROP TABLE IF EXISTS `tblRegoFormSession`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblRegoFormSession` (
  `intRegoFormSessionID` int(11) NOT NULL AUTO_INCREMENT,
  `strSessionKey` char(40) NOT NULL,
  `intMemberID` int(11) NOT NULL,
  `intTempID` int(11) DEFAULT '0',
  `intFormID` int(11) NOT NULL,
  `intNumber` tinyint(4) DEFAULT '1',
  `intChild` tinyint(4) DEFAULT '0',
  `tTimestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `strTransactions` varchar(255) DEFAULT '',
  `intStatus` tinyint(4) DEFAULT '0',
  `intTotalAdult` int(11) DEFAULT '0',
  `intTotalChild` int(11) DEFAULT '0',
  PRIMARY KEY (`intRegoFormSessionID`),
  KEY `index_session` (`strSessionKey`)
) ENGINE=MyISAM AUTO_INCREMENT=2044515 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblRegoFormSession`
--

LOCK TABLES `tblRegoFormSession` WRITE;
/*!40000 ALTER TABLE `tblRegoFormSession` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblRegoFormSession` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblRegoTypeLimits`
--

DROP TABLE IF EXISTS `tblRegoTypeLimits`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblRegoTypeLimits` (
  `intLimitID` int(11) NOT NULL AUTO_INCREMENT,
  `intRealmID` int(11) DEFAULT '0',
  `intSubRealmID` int(11) DEFAULT '0',
  `strSport` varchar(20) DEFAULT '',
  `strPersonType` varchar(30) DEFAULT '',
  `strPersonEntityRole` varchar(30) DEFAULT '',
  `strPersonLevel` varchar(30) DEFAULT '',
  `strAgeLevel` varchar(30) DEFAULT '',
  `intLimit` int(11) DEFAULT '0',
  `tTimestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `strLimitType` varchar(20) DEFAULT '',
  PRIMARY KEY (`intLimitID`),
  KEY `index_intRealmID` (`intRealmID`),
  KEY `index_intSubRealmID` (`intSubRealmID`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8 COMMENT='This table contains the registration limits';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblRegoTypeLimits`
--

LOCK TABLES `tblRegoTypeLimits` WRITE;
/*!40000 ALTER TABLE `tblRegoTypeLimits` DISABLE KEYS */;
INSERT INTO `tblRegoTypeLimits` VALUES (1,1,0,'FOOTBALL','PLAYER','','','',1,'2014-08-06 03:17:19','PERSONENTITY_UNIQUE'),(6,0,0,'FOOTBALL','PLAYER','','PROFESSIONAL','',1,'2014-10-20 09:24:53','PERSONENTITY_UNIQUE'),(7,0,0,'FOOTBALL','PLAYER','','AMATEUR','',1,'2014-10-20 09:24:53','PERSONENTITY_UNIQUE');
/*!40000 ALTER TABLE `tblRegoTypeLimits` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblReportEntity`
--

DROP TABLE IF EXISTS `tblReportEntity`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblReportEntity` (
  `intReportID` int(11) NOT NULL,
  `intRealmID` int(11) NOT NULL,
  `intSubRealmID` int(11) NOT NULL,
  `intEntityTypeID` int(11) NOT NULL,
  `intEntityID` int(11) NOT NULL,
  `intMinLevel` int(11) NOT NULL,
  `intMaxLevel` int(11) NOT NULL,
  PRIMARY KEY (`intReportID`,`intRealmID`,`intSubRealmID`,`intEntityTypeID`,`intEntityID`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblReportEntity`
--

LOCK TABLES `tblReportEntity` WRITE;
/*!40000 ALTER TABLE `tblReportEntity` DISABLE KEYS */;
INSERT INTO `tblReportEntity` VALUES (2,0,0,0,0,5,500),(3,0,0,0,0,2,400),(10,0,0,0,0,3,400),(11,0,0,0,0,3,400),(99,1,0,0,0,100,100),(97,0,0,0,0,10,400),(98,1,0,0,0,100,100),(100,1,0,0,0,3,3);
/*!40000 ALTER TABLE `tblReportEntity` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblReports`
--

DROP TABLE IF EXISTS `tblReports`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblReports` (
  `intReportID` int(11) NOT NULL AUTO_INCREMENT,
  `strName` varchar(255) NOT NULL,
  `strDescription` text,
  `intType` tinyint(4) DEFAULT NULL,
  `strFilename` varchar(200) DEFAULT NULL,
  `strFunction` varchar(200) DEFAULT NULL,
  `strGroup` varchar(100) DEFAULT NULL,
  `intParameters` tinyint(4) DEFAULT '0',
  `intOrder` int(11) DEFAULT '1',
  `strRequiredOptions` text,
  PRIMARY KEY (`intReportID`)
) ENGINE=MyISAM AUTO_INCREMENT=103 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblReports`
--

LOCK TABLES `tblReports` WRITE;
/*!40000 ALTER TABLE `tblReports` DISABLE KEYS */;
INSERT INTO `tblReports` VALUES (2,'Advanced Club','Set your own parameters etc for reporting on Clubs.',3,'','Reports::ReportAdvanced_Club','Clubs',1,0,'NoClubs=0'),(3,'Advanced People (My level)','Set your own parameters etc for reporting on Members.',3,'','Reports::ReportAdvanced_MyPeople','People',1,0,NULL),(97,'Advanced People (Below my level)','Set your own parameters etc for reporting on People',3,'','Reports::ReportAdvanced_BelowPeople','People',1,0,NULL),(6,'Advanced Transfers Report','Set your own parameters etc for reporting on Transfers',3,'','Reports::ReportAdvanced_Clearances','Transfers',1,0,'AllowClearances=1'),(9,'Retention Report','Set your own parameters etc for reporting on Member Retention',3,'','Reports::ReportAdvanced_Retention','People',1,0,'AllowSeasons=1'),(10,'Transactions (My People)','Set your own parameters etc for reporting on Transactions',3,'','Reports::ReportAdvanced_MyPeopleTransactions','Finance',1,0,'AllowTXNs=1'),(11,'Transactions Sold','Set your own parameters etc for reporting on Transactions that you have sold',3,'','Reports::ReportAdvanced_TXSold','Finance',1,0,'ReceiveFunds=1'),(13,'Duplicates Summary','Set your own parameters etc for reporting on how many duplicates there are in each organisation.',3,'','Reports::ReportAdvanced_Duplicates','People',1,0,NULL),(17,'Member Summary','Member Summary Report',3,'','Reports::ReportAdvanced_MemberSummary','People',1,0,NULL),(18,'Member Demographic','Member Demographic Report',3,'','Reports::ReportAdvanced_MemberDemographic','People',1,0,'AllowSeasons=1'),(32,'Transfers Below Report','Set your own parameters etc for reporting on Transfers',3,'','Reports::ReportAdvanced_ClearancesAllBelow','Transfers',1,0,''),(98,'Par Q Audit','Check all players 35 or over who do not have a verified Par Q Form against their record',1,'SG_parq.rpt','','People',0,0,''),(99,'National Service Audit','Check all People who require National Service Clearance have approved document',1,'SG_ns.rpt','','People',0,0,''),(100,'Club Teamsheet','Club custom teamsheet',1,'SG_teamsheet.rpt','','People',0,0,'');
/*!40000 ALTER TABLE `tblReports` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblRole`
--

DROP TABLE IF EXISTS `tblRole`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblRole` (
  `intRoleID` int(11) NOT NULL AUTO_INCREMENT,
  `intEntityID` int(11) NOT NULL DEFAULT '0',
  `intRealmID` int(11) NOT NULL DEFAULT '0',
  `strTitle` varchar(100) NOT NULL DEFAULT '',
  `dtDeletedDate` datetime DEFAULT NULL,
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`intRealmID`,`intRoleID`),
  KEY `index_intEntityID` (`intRoleID`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblRole`
--

LOCK TABLES `tblRole` WRITE;
/*!40000 ALTER TABLE `tblRole` DISABLE KEYS */;
INSERT INTO `tblRole` VALUES (1,1,1,'Administrator',NULL,'2014-07-24 21:46:02'),(2,14,1,'Administrator',NULL,'2014-07-24 21:46:02'),(3,35,1,'Registrar',NULL,'2014-07-24 21:46:02');
/*!40000 ALTER TABLE `tblRole` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblRolePerson`
--

DROP TABLE IF EXISTS `tblRolePerson`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblRolePerson` (
  `intRolePersonID` int(11) NOT NULL AUTO_INCREMENT,
  `intPersonID` int(11) NOT NULL,
  `intRoleID` int(11) NOT NULL,
  `intEntityID` int(11) NOT NULL,
  `dtDeletedDate` datetime DEFAULT NULL,
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`intPersonID`,`intRolePersonID`),
  KEY `index_intRolePersonID` (`intRolePersonID`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblRolePerson`
--

LOCK TABLES `tblRolePerson` WRITE;
/*!40000 ALTER TABLE `tblRolePerson` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblRolePerson` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblSavedReports`
--

DROP TABLE IF EXISTS `tblSavedReports`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblSavedReports` (
  `intSavedReportID` int(11) NOT NULL AUTO_INCREMENT,
  `strReportName` varchar(50) NOT NULL DEFAULT '',
  `intLevelID` int(11) NOT NULL DEFAULT '0',
  `intID` int(11) NOT NULL DEFAULT '0',
  `strReportType` varchar(50) DEFAULT NULL,
  `strReportData` text,
  `intReportID` int(11) DEFAULT '0',
  PRIMARY KEY (`intSavedReportID`),
  KEY `index_user` (`intLevelID`,`intID`,`strReportType`)
) ENGINE=MyISAM AUTO_INCREMENT=129225 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblSavedReports`
--

LOCK TABLES `tblSavedReports` WRITE;
/*!40000 ALTER TABLE `tblSavedReports` DISABLE KEYS */;
INSERT INTO `tblSavedReports` VALUES (129205,'Number of members per club',100,5,NULL,'{\"options\":{\"OutputEmail\":\"\",\"SortBy2\":\"\",\"RecordFilter\":\"DISTINCT\",\"SortByDir2\":\"ASC\",\"SortByDir1\":\"ASC\",\"GroupBy\":\"\",\"SortBy1\":\"intSeasonID\",\"OutputType\":\"screen\"},\"fields\":[{\"v1\":\"\",\"comp\":\"\",\"v2\":\"\",\"name\":\"strClubName\",\"display\":\"1\"},{\"v1\":\"\",\"comp\":\"\",\"v2\":\"\",\"name\":\"numMembers\",\"display\":\"1\"}]}',17),(129207,'Number of members by District',100,1,NULL,'{\"options\":{\"OutputEmail\":\"\",\"SortBy2\":\"\",\"RecordFilter\":\"DISTINCT\",\"SortByDir2\":\"ASC\",\"SortByDir1\":\"ASC\",\"GroupBy\":\"strAssocName\",\"SortBy1\":\"intSeasonID\",\"OutputType\":\"screen\"},\"fields\":[{\"v1\":\"\",\"comp\":\"\",\"v2\":\"\",\"name\":\"strAssocName\",\"display\":\"1\"},{\"v1\":\"\",\"comp\":\"\",\"v2\":\"\",\"name\":\"numMembers\",\"display\":\"1\"}]}',17),(129208,'Member Demographics',100,1,NULL,'{\"options\":{\"OutputEmail\":\"\",\"SortBy2\":\"\",\"RecordFilter\":\"DISTINCT\",\"SortByDir2\":\"ASC\",\"SortByDir1\":\"ASC\",\"GroupBy\":\"\",\"SortBy1\":\"intSeasonID\",\"OutputType\":\"screen\"},\"fields\":[{\"v1\":\"2\",\"comp\":\"equal\",\"v2\":null,\"name\":\"intSeasonID\",\"display\":\"1\"},{\"v1\":\"\",\"comp\":\"\",\"v2\":\"\",\"name\":\"strAssocName\",\"display\":\"1\"}]}',18),(129217,'Coaches Report',5,16,NULL,'{\"options\":{\"OutputEmail\":\"\",\"SortBy2\":\"\",\"RecordFilter\":\"DISTINCT\",\"SortByDir2\":\"ASC\",\"SortByDir1\":\"ASC\",\"GroupBy\":\"\",\"SortBy1\":\"strNationalNum\",\"OutputType\":\"screen\"},\"fields\":[{\"v1\":\"\",\"comp\":\"\",\"v2\":\"\",\"name\":\"strSurname\",\"display\":\"1\"},{\"v1\":null,\"comp\":\"\",\"v2\":null,\"name\":\"intNatCustomLU8\",\"display\":\"1\"},{\"v1\":\"2\",\"comp\":\"equal\",\"v2\":null,\"name\":\"intSeasonID\",\"display\":\"1\"}]}',3),(129214,'Coaches with AFC C Certificates',5,16,NULL,'{\"options\":{\"OutputEmail\":\"\",\"SortBy2\":\"\",\"RecordFilter\":\"DISTINCT\",\"SortByDir2\":\"ASC\",\"SortByDir1\":\"ASC\",\"GroupBy\":\"\",\"SortBy1\":\"strSurname\",\"OutputType\":\"screen\"},\"fields\":[{\"v1\":\"\",\"comp\":\"\",\"v2\":\"\",\"name\":\"strFirstname\",\"display\":\"1\"},{\"v1\":\"\",\"comp\":\"\",\"v2\":\"\",\"name\":\"strSurname\",\"display\":\"1\"},{\"v1\":\"\",\"comp\":\"\",\"v2\":\"\",\"name\":\"strSuburb\",\"display\":\"1\"},{\"v1\":\"\",\"comp\":\"\",\"v2\":\"\",\"name\":\"strPostalCode\",\"display\":\"1\"},{\"v1\":\"\",\"comp\":\"\",\"v2\":\"\",\"name\":\"strEmail\",\"display\":\"1\"},{\"v1\":\"557888\",\"comp\":\"equal\",\"v2\":null,\"name\":\"intCustomLU2\",\"display\":\"1\"}]}',3),(129218,'test 1',3,35,NULL,'{\"options\":{\"OutputEmail\":\"\",\"SortBy2\":\"\",\"RecordFilter\":\"DISTINCT\",\"SortByDir2\":\"ASC\",\"SortByDir1\":\"ASC\",\"GroupBy\":\"\",\"SortBy1\":\"intTransactionID\",\"OutputType\":\"screen\"},\"fields\":[]}',10),(129223,'Michael\'s Report',3,847,NULL,'{\"options\":{\"OutputEmail\":\"\",\"SortBy2\":\"\",\"RecordFilter\":\"DISTINCT\",\"SortByDir2\":\"ASC\",\"SortByDir1\":\"ASC\",\"GroupBy\":\"\",\"SortBy1\":\"strNationalNum\",\"OutputType\":\"screen\"},\"fields\":[{\"v1\":\"\",\"comp\":\"\",\"v2\":\"\",\"name\":\"strNationalNum\",\"display\":\"1\"},{\"v1\":\"\",\"comp\":\"\",\"v2\":\"\",\"name\":\"strLocalFirstname\",\"display\":\"1\"},{\"v1\":\"\",\"comp\":\"\",\"v2\":\"\",\"name\":\"strLocalSurname\",\"display\":\"1\"},{\"v1\":\"AF\",\"comp\":\"\",\"v2\":null,\"name\":\"strISONationality\",\"display\":\"1\"},{\"v1\":\"\",\"comp\":\"\",\"v2\":\"\",\"name\":\"dtYOB\",\"display\":\"1\"}]}',3),(129224,'FAS Report',100,1,NULL,'{\"options\":{\"OutputEmail\":\"\",\"SortBy2\":\"\",\"RecordFilter\":\"DISTINCT\",\"SortByDir2\":\"ASC\",\"SortByDir1\":\"ASC\",\"GroupBy\":\"\",\"SortBy1\":\"strNationalNum\",\"OutputType\":\"screen\"},\"fields\":[{\"v1\":\"\",\"comp\":\"\",\"v2\":\"\",\"name\":\"strLocalFirstname\",\"display\":\"1\"},{\"v1\":\"\",\"comp\":\"\",\"v2\":\"\",\"name\":\"strLocalSurname\",\"display\":\"1\"},{\"v1\":\"\",\"comp\":\"\",\"v2\":\"\",\"name\":\"dtYOB\",\"display\":\"1\"},{\"v1\":\"CLUBOFFICIAL\",\"comp\":\"\",\"v2\":null,\"name\":\"PRstrPersonType\",\"display\":\"1\"},{\"v1\":\"\",\"comp\":\"\",\"v2\":\"\",\"name\":\"PRstrPersonEntityRole\",\"display\":\"1\"}]}',3);
/*!40000 ALTER TABLE `tblSavedReports` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblSeason`
--

DROP TABLE IF EXISTS `tblSeason`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblSeason` (
  `intSeasonID` int(11) NOT NULL AUTO_INCREMENT,
  `strSeasonName` varchar(100) DEFAULT NULL,
  `intRealmID` int(11) DEFAULT '0',
  `intSubRealmID` int(11) DEFAULT '0',
  `intAssocID` int(11) DEFAULT '0',
  `dtStartSeason` date NOT NULL DEFAULT '0000-00-00',
  `dtEndSeason` date NOT NULL DEFAULT '0000-00-00',
  PRIMARY KEY (`intSeasonID`),
  KEY `index_start` (`dtStartSeason`),
  KEY `index_end` (`dtEndSeason`)
) ENGINE=MyISAM AUTO_INCREMENT=21 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblSeason`
--

LOCK TABLES `tblSeason` WRITE;
/*!40000 ALTER TABLE `tblSeason` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblSeason` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblSeasons`
--

DROP TABLE IF EXISTS `tblSeasons`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblSeasons` (
  `intSeasonID` int(11) NOT NULL AUTO_INCREMENT,
  `intRealmID` int(11) DEFAULT '0',
  `intRealmSubTypeID` int(11) DEFAULT '0',
  `intAssocID` int(11) DEFAULT '0',
  `strSeasonName` varchar(100) DEFAULT NULL,
  `intSeasonOrder` int(11) DEFAULT '0',
  `intArchiveSeason` tinyint(4) DEFAULT '0',
  `dtAdded` date DEFAULT NULL,
  `dtClearanceStart` date DEFAULT NULL,
  `dtClearanceEnd` date DEFAULT NULL,
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `intLocked` tinyint(4) DEFAULT '0',
  PRIMARY KEY (`intSeasonID`),
  KEY `index_intAssocID` (`intAssocID`),
  KEY `index_intRealm` (`intRealmID`,`intRealmSubTypeID`)
) ENGINE=MyISAM AUTO_INCREMENT=7260 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblSeasons`
--

LOCK TABLES `tblSeasons` WRITE;
/*!40000 ALTER TABLE `tblSeasons` DISABLE KEYS */;
INSERT INTO `tblSeasons` VALUES (1,1,0,0,'2012',0,0,NULL,NULL,NULL,'2014-01-24 10:41:03',0),(2,1,0,0,'2013',0,0,NULL,NULL,NULL,'2014-01-24 10:41:03',0),(3,1,0,0,'2014',0,0,NULL,NULL,NULL,'2014-01-24 10:41:03',0),(7258,1,1,0,'2015',4,0,'2014-01-20',NULL,NULL,'2014-01-24 10:41:03',0),(7259,1,0,16,'Default Season',0,0,NULL,NULL,NULL,'2008-10-13 21:08:02',0);
/*!40000 ALTER TABLE `tblSeasons` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblSnapShotEntityCounts_1`
--

DROP TABLE IF EXISTS `tblSnapShotEntityCounts_1`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblSnapShotEntityCounts_1` (
  `intEntityTypeID` int(11) NOT NULL,
  `intEntityID` int(11) NOT NULL,
  `intYear` int(11) NOT NULL,
  `intMonth` tinyint(4) NOT NULL,
  `intSeasonID` int(11) NOT NULL DEFAULT '0',
  `intClubs` int(11) NOT NULL DEFAULT '0',
  `intComps` int(11) NOT NULL DEFAULT '0',
  `intCompTeams` int(11) NOT NULL DEFAULT '0',
  `intTotalTeams` int(11) NOT NULL DEFAULT '0',
  `intClrIn` int(11) NOT NULL DEFAULT '0',
  `intClrOut` int(11) NOT NULL DEFAULT '0',
  `intClrPermitIn` int(11) NOT NULL DEFAULT '0',
  `intClrPermitOut` int(11) NOT NULL DEFAULT '0',
  `intTxns` int(11) NOT NULL DEFAULT '0',
  `curTxnValue` decimal(10,2) DEFAULT '0.00',
  `intNewTribunal` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`intYear`,`intMonth`,`intEntityTypeID`,`intEntityID`),
  KEY `index_Entity` (`intEntityTypeID`,`intEntityID`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblSnapShotEntityCounts_1`
--

LOCK TABLES `tblSnapShotEntityCounts_1` WRITE;
/*!40000 ALTER TABLE `tblSnapShotEntityCounts_1` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblSnapShotEntityCounts_1` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblSnapShotMemberCounts_1`
--

DROP TABLE IF EXISTS `tblSnapShotMemberCounts_1`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblSnapShotMemberCounts_1` (
  `intEntityTypeID` int(11) NOT NULL,
  `intEntityID` int(11) NOT NULL,
  `intYear` int(11) NOT NULL,
  `intMonth` tinyint(4) NOT NULL,
  `intSeasonID` int(11) NOT NULL DEFAULT '0',
  `intGender` tinyint(4) NOT NULL DEFAULT '0',
  `intAgeGroupID` int(11) NOT NULL DEFAULT '0',
  `intMembers` int(11) NOT NULL DEFAULT '0',
  `intNewMembers` int(11) NOT NULL DEFAULT '0',
  `intRegoFormMembers` int(11) NOT NULL DEFAULT '0',
  `intPermitMembers` int(11) NOT NULL DEFAULT '0',
  `intPlayer` int(11) NOT NULL DEFAULT '0',
  `intCoach` int(11) NOT NULL DEFAULT '0',
  `intUmpire` int(11) NOT NULL DEFAULT '0',
  `intOther1` int(11) NOT NULL DEFAULT '0',
  `intOther2` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`intYear`,`intMonth`,`intEntityTypeID`,`intEntityID`,`intGender`,`intAgeGroupID`),
  KEY `index_Entity` (`intEntityTypeID`,`intEntityID`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblSnapShotMemberCounts_1`
--

LOCK TABLES `tblSnapShotMemberCounts_1` WRITE;
/*!40000 ALTER TABLE `tblSnapShotMemberCounts_1` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblSnapShotMemberCounts_1` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblSnapShotRuns`
--

DROP TABLE IF EXISTS `tblSnapShotRuns`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblSnapShotRuns` (
  `dtLastRun` datetime DEFAULT NULL,
  `intYear` int(11) DEFAULT '0',
  `intMonth` int(11) DEFAULT '0'
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblSnapShotRuns`
--

LOCK TABLES `tblSnapShotRuns` WRITE;
/*!40000 ALTER TABLE `tblSnapShotRuns` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblSnapShotRuns` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblSystemConfig`
--

DROP TABLE IF EXISTS `tblSystemConfig`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblSystemConfig` (
  `intSystemConfigID` int(11) NOT NULL AUTO_INCREMENT,
  `intTypeID` smallint(6) NOT NULL DEFAULT '0',
  `strOption` varchar(100) NOT NULL DEFAULT '',
  `strValue` varchar(250) NOT NULL DEFAULT '',
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `intRealmID` int(11) DEFAULT NULL,
  `intSubTypeID` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`intSystemConfigID`),
  KEY `index_TypeID` (`intTypeID`),
  KEY `index_strOption` (`strOption`),
  KEY `index_TypeOption` (`intTypeID`,`strOption`),
  KEY `index_intRealm` (`intRealmID`),
  KEY `index_RealmOption` (`intRealmID`,`strOption`)
) ENGINE=MyISAM AUTO_INCREMENT=3787 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblSystemConfig`
--

LOCK TABLES `tblSystemConfig` WRITE;
/*!40000 ALTER TABLE `tblSystemConfig` DISABLE KEYS */;
INSERT INTO `tblSystemConfig` VALUES (3679,1,'UmpireLabel','Referee','2014-01-16 22:44:06',1,0),(3656,1,'AllowOnlineRego_node','1','2014-01-16 22:02:06',1,0),(3657,1,'AllowProdTXNs','1','2014-01-16 22:02:06',1,0),(3658,1,'AllowClearances','1','2014-01-16 22:02:06',1,0),(3659,1,'AllowOnlineRego','1','2014-01-16 22:02:06',1,0),(3660,1,'NoTeams','1','2014-01-16 22:02:06',1,0),(3661,1,'NoComps','1','2014-01-16 22:02:06',1,0),(3685,1,'NotAllowCommunicator','1','2014-01-22 04:19:20',1,0),(3663,1,'AllowTXNs','1','2014-01-16 22:02:06',1,0),(3664,1,'AllowClearances','1','2014-04-14 17:11:24',1,0),(3665,1,'AllowSeasons','1','2014-01-16 22:02:06',1,0),(3666,1,'DuplCheck','1','2014-01-16 22:02:06',1,0),(3667,1,'AllowCardPrinting','1','2014-01-16 22:02:06',1,0),(3668,1,'NoAds','1','2014-01-16 22:02:06',1,0),(3669,1,'AllowStatusChange','1','2014-01-16 22:02:06',1,0),(3670,1,'Header','<img src=\"/headers/finland_football.jpg\" alt=\"\" border=\"0\" style = \"width:100%;\">','2014-01-16 22:02:06',1,1),(3671,1,'Header','<img src=\"/headers/singapore_football.jpg\" alt=\"\" border=\"0\" style = \"width:100%;\">','2014-01-16 22:02:06',1,2),(3672,1,'AllowPendingRegistration','1','2014-01-16 22:02:06',1,0),(3673,1,'txtRequestCLR','Request a Transfer','2014-01-16 22:04:28',1,0),(3674,1,'txtCLR','Transfer','2014-01-16 22:04:46',1,0),(3678,1,'GenMemberNo','1','2014-01-16 22:41:52',1,0),(3681,1,'clrAuthSurnameSearch','1','2014-01-20 05:06:25',1,0),(3680,1,'AllowNABSignup','0','2014-04-14 17:06:30',1,0),(3682,1,'clrDOBSurnameSearch','1','2014-01-20 05:06:49',1,0),(3683,1,'AllowTXNrpts','1','2014-01-20 05:47:35',1,0),(3684,1,'HeaderBG','#spheader {height:150px;}','2014-01-21 20:55:28',1,0),(3694,1,'FieldLabel_strMemberNo','PalloID','2014-01-23 03:27:48',1,1),(3690,1,'..AllowedRegoCountries',';FINLAND;SWEDEN;NORWAY;','2014-11-26 22:00:36',1,1),(3689,1,'DefaultCountry','SG','2014-12-07 23:44:29',1,0),(3692,1,'DefaultNationality','SG','2014-12-07 23:44:29',1,2),(3693,1,'DefaultNationality','FINLAND','2014-01-22 23:07:10',1,1),(3695,1,'NoMemberTags','1','2014-01-23 00:58:42',1,0),(3696,1,'NoMemberTypes','1','2014-01-23 00:59:22',1,0),(3697,1,'txtClrs','Transfers','2014-01-23 01:00:01',1,0),(3698,1,'txtCLRs','Transfers','2014-01-23 01:00:16',1,0),(3699,1,'clrHide_intPlayerFinancial','1','2014-01-24 03:23:35',1,0),(3700,1,'clrHide_intPlayerSuspended','1','2014-01-24 03:23:54',1,0),(3701,1,'clrHide_clearanceFee','1','2014-01-24 03:24:08',1,0),(3705,1,'clrClearanceYear','2014','2014-01-24 03:27:44',1,0),(3703,1,'clrHide_intClearanceDevelopmentFeeID','1','2014-01-24 03:24:43',1,0),(3704,1,'clrHide_curDevelFee','1','2014-01-24 03:25:11',1,0),(3706,1,'clrHide_dtAlert','1','2014-01-24 03:31:36',1,0),(3707,1,'.DollarSymbol','&euro;','2014-12-08 23:44:09',0,1),(3708,1,'---DuplicateFields','strLocalSurname|strLocalFirstname|dtDOB','2014-06-25 22:45:38',1,0),(3709,1,'AllowClubTXNs','1','2014-06-29 23:44:08',1,0),(3710,1,'AllowTXNs_CCs','0','2014-12-05 06:42:39',1,0),(3711,1,'TestPay','1','2014-07-03 01:47:07',1,0),(3712,1,'clrReasonSelfInitiatedID','558004','2014-07-29 03:34:10',1,0),(3713,1,'entity_strLatinNames','1','2014-09-23 00:38:26',1,0),(3714,1,'AdultAge','21-100','2014-11-26 21:58:20',1,0),(3715,1,'personRequestTimeout','7','2014-10-03 01:14:02',1,0),(3716,1,'allowPersonRequest','1','2014-12-12 07:21:19',1,0),(3717,1,'menu_newperson_PLAYER_3','1','2014-10-09 03:50:03',1,0),(3718,1,'menu_newperson_PLAYER_20','1','2014-10-09 03:50:03',1,0),(3719,1,'menu_newperson_PLAYER_100','1','2014-10-09 03:50:03',1,0),(3720,1,'menu_newperson_COACH_3','1','2014-10-09 03:50:04',1,0),(3721,1,'menu_newperson_COACH_20','1','2014-10-09 03:50:04',1,0),(3722,1,'menu_newperson_COACH_100','1','2014-10-09 03:50:04',1,0),(3723,1,'menu_newperson_REFEREE_3','1','2014-10-09 03:50:04',1,0),(3724,1,'menu_newperson_REFEREE_20','1','2014-10-09 03:50:04',1,0),(3725,1,'menu_newperson_REFEREE_100','1','2014-10-09 03:50:04',1,0),(3726,1,'menu_newperson_TEAMOFFICIAL_3','1','2014-10-09 03:50:04',1,0),(3727,1,'menu_newperson_TEAMOFFICIAL_20','1','2014-10-09 03:50:04',1,0),(3728,1,'menu_newperson_TEAMOFFICIAL_100','1','2014-10-09 03:50:04',1,0),(3729,1,'menu_newperson_CLUBOFFICIAL_3','1','2014-10-09 03:50:04',1,0),(3730,1,'menu_newperson_CLUBOFFICIAL_20','1','2014-10-09 03:50:04',1,0),(3731,1,'menu_newperson_CLUBOFFICIAL_100','1','2014-10-09 03:50:04',1,0),(3732,1,'menu_newperson_MAOFFICIAL_100','1','2014-10-09 03:50:05',1,0),(3733,1,'maxFacilityFieldCount','50','2014-10-28 22:40:32',1,0),(3734,1,'lockApproval_PaymentRequired_REGO','1','2014-11-07 05:45:02',1,0),(3735,1,'lockApproval_PaymentRequired_CLUB','1','2014-11-07 05:45:02',1,0),(3736,1,'lockApproval_PaymentRequired_VENUE','1','2014-11-07 05:45:02',1,0),(3737,1,'lockApproval_PaymentRequired_PERSON','1','2014-11-07 05:45:04',1,0),(3739,1,'menu_newclub_20','1','2014-11-10 05:44:52',1,0),(3740,1,'menu_newclub_100','1','2014-11-10 05:44:52',1,0),(3741,1,'menu_newvenue_100','1','2014-11-10 05:44:52',1,0),(3742,1,'menu_newvenue_20','1','2014-11-10 05:44:52',1,0),(3743,1,'menu_newvenue_3','1','2014-11-10 05:44:53',1,0),(3744,1,'menu_searchpeople_3','1','2014-11-10 20:22:24',1,0),(3745,1,'menu_searchpeople_20','1','2014-11-10 20:22:24',1,0),(3746,1,'menu_searchpeople_100','1','2014-11-10 20:22:24',1,0),(3747,1,'AllowTXNs_CCs_roleFlow','0','2014-12-05 06:42:39',1,0),(3748,1,'AllowTXNs_Manual_roleFlow','0','2014-12-03 01:48:40',1,0),(3750,1,'strOtherPersonIdentifier_Text','NRIC or Passport Number','2014-12-12 11:39:26',1,0),(3751,1,'dtOtherPersonIdentifierValidDateFrom_Text','NRIC Number Valid From','2014-11-17 04:39:23',1,0),(3752,1,'dtOtherPersonIdentifierValidDateTo_Text','NRIC Number Valid To','2014-11-17 04:39:30',1,0),(3753,1,'strOtherPersonIdentifierIssueCountry_Text','NRIC Number Issue Country','2014-11-17 04:40:15',1,0),(3754,1,'NationalNumName','FAS Identification Number','2014-11-17 05:57:34',1,0),(3755,1,'entity_strLatinNames','1','2014-11-17 05:59:07',1,0),(3756,1,'triggerWorkFlowPersonDataUpdate','dtDOB|strLocalFirstname|strLocalSurname|strISONationality','2014-11-21 21:09:27',1,0),(3757,1,'cleanPlayerPersonRecords','1','2014-11-30 20:09:55',1,0),(3758,1,'menu_newperson_REFEREE_100_100','1','2014-12-02 12:20:41',1,0),(3759,1,'menu_newperson_PLAYER_100_3','1','2014-12-02 12:20:52',1,0),(3760,1,'menu_newperson_COACH_100_3','1','2014-12-02 12:21:44',1,0),(3761,1,'menu_newperson_COACH_3_3','1','2014-12-02 12:21:44',1,0),(3762,1,'menu_newperson_PLAYER_3_3','1','2014-12-02 12:21:46',1,0),(3763,1,'age_breakpoint_PLAYER_PROFESSIONAL','16','2014-12-03 06:50:10',1,0),(3764,1,'intOtherPersonIdentifierTypeID_Text','Document Type','2014-12-03 19:59:22',1,0),(3765,1,'strOtherPersonIdentifierDesc_Text','NRIC Number Description','2014-12-04 21:41:01',1,0),(3766,1,'ma_phone_number','(65) 6348 3477 / 6293 1477','2014-12-05 06:17:42',1,0),(3767,1,'ma_website','http://www.fas.org.sg','2014-12-05 06:17:42',1,0),(3768,1,'ma_email','myfashelpdesk@fas.org.sg','2015-01-19 05:53:07',1,0),(3769,1,'help_desk_email','myfashelpdesk@fas.org.sg','2014-12-05 06:17:42',1,0),(3770,1,'help_desk_phone_number','(65) 68803118','2014-12-05 06:17:42',1,0),(3771,1,'DefaultNationality','SG','2014-12-07 23:44:29',1,0),(3772,1,'DefaultCity','SINGAPORE','2014-12-07 21:34:51',1,0),(3773,1,'age_breakpoint_PLAYER_AMATEUR_U_C','16','2014-12-08 04:12:51',1,0),(3774,1,'MA_allowTransfer','0','2014-12-08 05:53:25',1,0),(3775,1,'allowVenues','1','2014-12-22 05:38:20',1,0),(3776,1,'DontAllowManualPayments','1','2014-12-17 03:02:26',1,0),(3777,1,'FOOTBALL_FIELD_LENGTH_RANGE','90~120','2015-01-06 04:45:07',1,0),(3778,1,'FOOTBALL_FIELD_WIDTH_RANGE','45~90','2015-01-06 04:45:07',1,0),(3779,1,'Timezone','Asia/Singapore','2014-12-21 21:58:48',1,0),(3780,1,'PP_UseDOBasFrom','1','2014-12-22 07:43:39',1,0),(3781,1,'allowBulkRenewals','0','2014-12-22 23:51:36',1,0),(3782,1,'allowReports','1','2015-01-02 03:58:16',1,0),(3783,1,'stopDeleteDocos_CLUB','1','2015-01-04 22:06:04',1,0),(3784,1,'stopDeleteDocos_ALL','1','2015-01-04 22:06:22',1,0),(3785,1,'FUTSAL_FIELD_LENGTH_RANGE','25~42','2015-01-06 05:50:00',1,0),(3786,1,'FUTSAL_FIELD_WIDTH_RANGE','16~25','2015-01-06 05:50:01',1,0);
/*!40000 ALTER TABLE `tblSystemConfig` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblSystemConfigBlob`
--

DROP TABLE IF EXISTS `tblSystemConfigBlob`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblSystemConfigBlob` (
  `intSystemConfigID` int(11) NOT NULL DEFAULT '0',
  `strBlob` text NOT NULL,
  PRIMARY KEY (`intSystemConfigID`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblSystemConfigBlob`
--

LOCK TABLES `tblSystemConfigBlob` WRITE;
/*!40000 ALTER TABLE `tblSystemConfigBlob` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblSystemConfigBlob` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblTXNLogs`
--

DROP TABLE IF EXISTS `tblTXNLogs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblTXNLogs` (
  `intTXNID` int(11) NOT NULL DEFAULT '0',
  `intTLogID` int(11) NOT NULL DEFAULT '0',
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`intTXNID`,`intTLogID`),
  KEY `index_Ids` (`intTLogID`,`intTXNID`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblTXNLogs`
--

LOCK TABLES `tblTXNLogs` WRITE;
/*!40000 ALTER TABLE `tblTXNLogs` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblTXNLogs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblTXNPartPayURL`
--

DROP TABLE IF EXISTS `tblTXNPartPayURL`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblTXNPartPayURL` (
  `intTXNURLID` int(11) NOT NULL AUTO_INCREMENT,
  `intRealmID` int(11) DEFAULT '0',
  `intAssocID` int(11) DEFAULT '0',
  `intClubID` int(11) DEFAULT '0',
  `strPartPayURL` varchar(200) DEFAULT '',
  `dtAdded` datetime DEFAULT NULL,
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`intTXNURLID`),
  KEY `index_intAssocID` (`intAssocID`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblTXNPartPayURL`
--

LOCK TABLES `tblTXNPartPayURL` WRITE;
/*!40000 ALTER TABLE `tblTXNPartPayURL` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblTXNPartPayURL` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblTXNPartPayURL_Transactions`
--

DROP TABLE IF EXISTS `tblTXNPartPayURL_Transactions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblTXNPartPayURL_Transactions` (
  `intTXNPPID` int(11) NOT NULL AUTO_INCREMENT,
  `intTXNURLID` int(11) DEFAULT '0',
  `intTXNID` int(11) NOT NULL,
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`intTXNPPID`),
  UNIQUE KEY `index_TXNID` (`intTXNURLID`,`intTXNID`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblTXNPartPayURL_Transactions`
--

LOCK TABLES `tblTXNPartPayURL_Transactions` WRITE;
/*!40000 ALTER TABLE `tblTXNPartPayURL_Transactions` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblTXNPartPayURL_Transactions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblTempEntityStructure`
--

DROP TABLE IF EXISTS `tblTempEntityStructure`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblTempEntityStructure` (
  `intRealmID` int(11) NOT NULL DEFAULT '0',
  `intParentID` int(11) NOT NULL DEFAULT '0',
  `intParentLevel` int(11) NOT NULL DEFAULT '0',
  `intChildID` int(11) NOT NULL DEFAULT '0',
  `intChildLevel` int(11) NOT NULL DEFAULT '0',
  `intDirect` tinyint(4) NOT NULL DEFAULT '0',
  `intDataAccess` tinyint(4) NOT NULL DEFAULT '10',
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `intPrimary` tinyint(4) NOT NULL DEFAULT '1',
  PRIMARY KEY (`intParentID`,`intChildID`),
  KEY `index_intRealmID` (`intRealmID`),
  KEY `index_parentclevel` (`intParentID`,`intChildLevel`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblTempEntityStructure`
--

LOCK TABLES `tblTempEntityStructure` WRITE;
/*!40000 ALTER TABLE `tblTempEntityStructure` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblTempEntityStructure` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblTempMember`
--

DROP TABLE IF EXISTS `tblTempMember`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblTempMember` (
  `intTempMemberID` int(11) NOT NULL AUTO_INCREMENT,
  `intRealID` int(11) DEFAULT '0',
  `strSessionKey` char(40) NOT NULL,
  `strJson` text NOT NULL,
  `strTransactions` varchar(255) DEFAULT '',
  `intFormID` int(11) NOT NULL,
  `intAssocID` int(11) NOT NULL,
  `intClubID` int(11) NOT NULL,
  `intTeamID` int(11) NOT NULL,
  `intNum` int(11) NOT NULL,
  `intStatus` tinyint(4) DEFAULT '0',
  `intLevel` tinyint(4) DEFAULT '0',
  `intTransLogID` int(11) NOT NULL,
  `tTimestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`intTempMemberID`)
) ENGINE=MyISAM AUTO_INCREMENT=5227 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblTempMember`
--

LOCK TABLES `tblTempMember` WRITE;
/*!40000 ALTER TABLE `tblTempMember` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblTempMember` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblTempNodeStructure`
--

DROP TABLE IF EXISTS `tblTempNodeStructure`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblTempNodeStructure` (
  `intRealmID` int(11) DEFAULT '0',
  `int100_ID` int(11) DEFAULT '0',
  `int30_ID` int(11) DEFAULT '0',
  `int20_ID` int(11) DEFAULT '0',
  `int10_ID` int(11) DEFAULT '0',
  `intAssocID` int(11) DEFAULT '0',
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `indexIDs` (`int100_ID`,`int30_ID`,`int20_ID`,`int10_ID`,`intAssocID`),
  KEY `index_intAssoc_100_ID` (`intAssocID`,`int100_ID`),
  KEY `index_intAssoc_10_ID` (`intAssocID`,`int10_ID`),
  KEY `index_int10_20ID` (`int10_ID`,`int20_ID`),
  KEY `index_int20_30ID` (`int20_ID`,`int30_ID`),
  KEY `index_int30_100ID` (`int30_ID`,`int100_ID`),
  KEY `index_intRealmID` (`intRealmID`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblTempNodeStructure`
--

LOCK TABLES `tblTempNodeStructure` WRITE;
/*!40000 ALTER TABLE `tblTempNodeStructure` DISABLE KEYS */;
INSERT INTO `tblTempNodeStructure` VALUES (1,5,6,7,8,16,'2014-05-16 01:38:04'),(1,1,2,3,4,20523,'2014-05-16 01:38:04'),(1,1,2,3,4,20522,'2014-05-16 01:38:04'),(1,1,2,3,4,15,'2014-05-16 01:38:04'),(1,1,2,3,4,13,'2014-05-16 01:38:04'),(1,1,2,3,4,12,'2014-05-16 01:38:04'),(1,1,2,3,4,11,'2014-05-16 01:38:04'),(1,1,2,3,4,10,'2014-05-16 01:38:04'),(1,1,2,3,4,9,'2014-05-16 01:38:04'),(1,1,2,3,4,8,'2014-05-16 01:38:04'),(1,1,2,3,4,7,'2014-05-16 01:38:04'),(1,1,2,3,4,6,'2014-05-16 01:38:04'),(1,1,2,3,4,5,'2014-05-16 01:38:04'),(1,1,2,3,4,4,'2014-05-16 01:38:04'),(1,1,2,3,4,3,'2014-05-16 01:38:04'),(1,1,2,3,4,2,'2014-05-16 01:38:04'),(1,1,2,3,4,1,'2014-05-16 01:38:04');
/*!40000 ALTER TABLE `tblTempNodeStructure` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblTempTransLogIDs`
--

DROP TABLE IF EXISTS `tblTempTransLogIDs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblTempTransLogIDs` (
  `intTransactionID` int(11) NOT NULL DEFAULT '0',
  `intTempTransLogID` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`intTransactionID`,`intTempTransLogID`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblTempTransLogIDs`
--

LOCK TABLES `tblTempTransLogIDs` WRITE;
/*!40000 ALTER TABLE `tblTempTransLogIDs` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblTempTransLogIDs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblTempTreeStructure`
--

DROP TABLE IF EXISTS `tblTempTreeStructure`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblTempTreeStructure` (
  `intRealmID` int(11) DEFAULT '0',
  `int100_ID` int(11) DEFAULT '0',
  `int30_ID` int(11) DEFAULT '0',
  `int20_ID` int(11) DEFAULT '0',
  `int10_ID` int(11) DEFAULT '0',
  `int3_ID` int(11) DEFAULT '0',
  `tTimeStamp` timestamp NULL DEFAULT NULL,
  KEY `index_100_ID` (`int100_ID`),
  KEY `index_10_ID` (`int10_ID`),
  KEY `index_int10_20ID` (`int10_ID`,`int20_ID`),
  KEY `index_int20_30ID` (`int20_ID`,`int30_ID`),
  KEY `index_int30_100ID` (`int30_ID`,`int100_ID`),
  KEY `index_int3_100ID` (`int3_ID`,`int100_ID`),
  KEY `index_intRealmID` (`intRealmID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblTempTreeStructure`
--

LOCK TABLES `tblTempTreeStructure` WRITE;
/*!40000 ALTER TABLE `tblTempTreeStructure` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblTempTreeStructure` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblTransLog`
--

DROP TABLE IF EXISTS `tblTransLog`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblTransLog` (
  `intLogID` int(11) NOT NULL AUTO_INCREMENT,
  `dtLog` datetime DEFAULT NULL,
  `intAmount` decimal(16,2) DEFAULT '0.00',
  `strTXN` varchar(200) DEFAULT NULL,
  `strResponseCode` varchar(10) DEFAULT NULL,
  `strResponseText` varchar(100) DEFAULT NULL,
  `strComments` text,
  `intPaymentType` int(11) DEFAULT NULL,
  `strBSB` varchar(50) DEFAULT NULL,
  `strBank` varchar(100) DEFAULT NULL,
  `strAccountName` varchar(100) DEFAULT NULL,
  `strAccountNum` varchar(100) DEFAULT NULL,
  `intRealmID` int(11) DEFAULT NULL,
  `intCurrencyID` int(11) DEFAULT '0',
  `strReceiptRef` varchar(100) DEFAULT NULL,
  `intStatus` tinyint(4) DEFAULT '0',
  `intPartialPayment` tinyint(4) DEFAULT '0',
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `dtSettlement` date DEFAULT NULL,
  `intEntityPaymentID` int(11) DEFAULT '0',
  `intPaymentConfigID` int(11) DEFAULT '0',
  `strOtherRef1` varchar(100) DEFAULT '',
  `strOtherRef2` varchar(100) DEFAULT '',
  `strOtherRef3` varchar(100) DEFAULT '',
  `strOtherRef4` varchar(100) DEFAULT '',
  `strOtherRef5` varchar(100) DEFAULT '',
  `curGatewayFees` decimal(16,2) DEFAULT '0.00',
  `intRegoFormID` int(11) DEFAULT '0',
  `intExportOK` tinyint(4) DEFAULT '0',
  `intSWMPaymentAuthLevel` tinyint(4) DEFAULT '0',
  `strSessionKey` varchar(40) DEFAULT '',
  `strAuthID` varchar(50) DEFAULT '',
  `strText` varchar(150) DEFAULT '',
  `intPaymentByLevel` int(11) DEFAULT '0',
  PRIMARY KEY (`intLogID`),
  KEY `index_realmID` (`intRealmID`),
  KEY `index_paymentType` (`intPaymentType`),
  KEY `intEntityPaymentID` (`intEntityPaymentID`),
  KEY `intCurrencyID` (`intCurrencyID`),
  KEY `intStatus` (`intStatus`),
  KEY `intPartialPayment` (`intPartialPayment`)
) ENGINE=InnoDB AUTO_INCREMENT=24 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblTransLog`
--

LOCK TABLES `tblTransLog` WRITE;
/*!40000 ALTER TABLE `tblTransLog` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblTransLog` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblTransLog_Counts`
--

DROP TABLE IF EXISTS `tblTransLog_Counts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblTransLog_Counts` (
  `intTLogID` int(11) NOT NULL DEFAULT '0',
  `dtLog` datetime DEFAULT NULL,
  `strResponseCode` varchar(10) DEFAULT NULL,
  KEY `index_logID` (`intTLogID`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblTransLog_Counts`
--

LOCK TABLES `tblTransLog_Counts` WRITE;
/*!40000 ALTER TABLE `tblTransLog_Counts` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblTransLog_Counts` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblTransLog_Retry`
--

DROP TABLE IF EXISTS `tblTransLog_Retry`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblTransLog_Retry` (
  `intRetryLogID` int(11) NOT NULL AUTO_INCREMENT,
  `intLogID` int(11) NOT NULL DEFAULT '0',
  `dtLog` datetime DEFAULT NULL,
  `intAmount` decimal(16,2) DEFAULT NULL,
  `strTXN` varchar(200) DEFAULT NULL,
  `strResponseCode` varchar(10) DEFAULT NULL,
  `strResponseText` varchar(100) DEFAULT NULL,
  `intPaymentType` int(11) DEFAULT NULL,
  `strBSB` varchar(50) DEFAULT NULL,
  `strBank` varchar(100) DEFAULT NULL,
  `strAccountName` varchar(100) DEFAULT NULL,
  `strAccountNum` varchar(100) DEFAULT NULL,
  `strReceiptRef` varchar(100) DEFAULT NULL,
  `intStatus` tinyint(4) DEFAULT '0',
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`intRetryLogID`),
  KEY `index_logID` (`intLogID`),
  KEY `index_paymentType` (`intPaymentType`),
  KEY `intStatus` (`intStatus`)
) ENGINE=MyISAM AUTO_INCREMENT=15363 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblTransLog_Retry`
--

LOCK TABLES `tblTransLog_Retry` WRITE;
/*!40000 ALTER TABLE `tblTransLog_Retry` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblTransLog_Retry` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblTransactions`
--

DROP TABLE IF EXISTS `tblTransactions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblTransactions` (
  `intTransactionID` int(11) NOT NULL AUTO_INCREMENT,
  `intStatus` tinyint(4) DEFAULT '0',
  `strNotes` text,
  `curAmount` decimal(12,2) DEFAULT '0.00',
  `intQty` int(11) DEFAULT '0',
  `dtTransaction` datetime DEFAULT NULL,
  `dtPaid` datetime DEFAULT NULL,
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `intDelivered` tinyint(11) DEFAULT '0',
  `intRealmID` int(11) DEFAULT '0',
  `intRealmSubTypeID` int(11) DEFAULT '0',
  `intID` int(11) DEFAULT '0',
  `intTableType` tinyint(4) DEFAULT '0',
  `intTXNEntityID` int(11) DEFAULT '0',
  `intProductID` int(11) DEFAULT NULL,
  `intTransLogID` int(11) DEFAULT '0',
  `intCurrencyID` int(11) DEFAULT '0',
  `intTempLogID` int(11) DEFAULT '0',
  `intExportAssocBankFileID` int(11) DEFAULT '0',
  `dtStart` datetime DEFAULT NULL,
  `dtEnd` datetime DEFAULT NULL,
  `curPerItem` decimal(12,2) DEFAULT '0.00',
  `intRenewed` tinyint(4) DEFAULT '0',
  `intParentTXNID` int(11) DEFAULT '0',
  `strPayeeName` varchar(100) DEFAULT '',
  `strPayeeNotes` text,
  `intTempID` int(11) DEFAULT '0',
  `intPersonRegistrationID` int(11) DEFAULT '0',
  `intInvoiceID` int(11) DEFAULT '0',
  PRIMARY KEY (`intTransactionID`),
  KEY `index_intStatus` (`intStatus`),
  KEY `index_intTXNEntityID` (`intTXNEntityID`),
  KEY `transLogID` (`intTransLogID`),
  KEY `index_intRealmIDintRealmSubTypeID` (`intRealmID`,`intRealmSubTypeID`),
  KEY `intRealmSubTypeID` (`intRealmSubTypeID`),
  KEY `index_intIDintTableType` (`intID`,`intTableType`),
  KEY `intTableType` (`intTableType`),
  KEY `intProductID` (`intProductID`)
) ENGINE=InnoDB AUTO_INCREMENT=24 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblTransactions`
--

LOCK TABLES `tblTransactions` WRITE;
/*!40000 ALTER TABLE `tblTransactions` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblTransactions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblUploadedFiles`
--

DROP TABLE IF EXISTS `tblUploadedFiles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblUploadedFiles` (
  `intFileID` int(11) NOT NULL AUTO_INCREMENT,
  `intFileType` tinyint(4) DEFAULT '0',
  `intEntityTypeID` int(11) NOT NULL,
  `intEntityID` int(11) NOT NULL,
  `intAddedByTypeID` int(11) NOT NULL,
  `intAddedByID` int(11) NOT NULL,
  `strTitle` varchar(200) NOT NULL,
  `strPath` varchar(50) NOT NULL,
  `strFilename` varchar(50) NOT NULL,
  `strOrigFilename` varchar(250) NOT NULL,
  `strExtension` char(4) DEFAULT NULL,
  `intBytes` int(11) DEFAULT '1',
  `dtUploaded` datetime DEFAULT NULL,
  `intPermissions` tinyint(4) DEFAULT '1',
  PRIMARY KEY (`intFileID`),
  KEY `entity_key` (`intEntityTypeID`,`intEntityID`,`intFileType`)
) ENGINE=MyISAM AUTO_INCREMENT=64653 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblUploadedFiles`
--

LOCK TABLES `tblUploadedFiles` WRITE;
/*!40000 ALTER TABLE `tblUploadedFiles` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblUploadedFiles` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblUser`
--

DROP TABLE IF EXISTS `tblUser`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblUser` (
  `userId` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `username` varchar(50) NOT NULL,
  `status` tinyint(4) DEFAULT '0',
  `firstName` varchar(100) DEFAULT NULL,
  `familyName` varchar(100) DEFAULT NULL,
  `confirmKey` varchar(20) DEFAULT '',
  `created` datetime DEFAULT NULL,
  `confirmed` datetime DEFAULT NULL,
  `ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`userId`),
  UNIQUE KEY `index_username` (`username`)
) ENGINE=InnoDB AUTO_INCREMENT=144 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblUser`
--

LOCK TABLES `tblUser` WRITE;
/*!40000 ALTER TABLE `tblUser` DISABLE KEYS */;
INSERT INTO `tblUser` VALUES (1,'w.rodie@sportingpulseinternational.com',2,'Warren','Rodie','','2014-06-03 10:48:36','2014-11-14 02:08:05','2014-11-14 02:08:05'),(2,'Email',2,'First name','Family name','2HpPf81543916ac21735','2014-06-04 13:00:56','2014-11-14 02:08:05','2014-11-14 02:08:05'),(3,'t@t.com',2,'test','test','QM4IuP238c4e9da6afd7','2014-06-04 13:02:01','2014-11-14 02:08:05','2014-11-14 02:08:05'),(4,'t@3t.com',2,'test','test','7Kn4Lb6b1348a31b18a2','2014-06-04 13:02:54','2014-11-14 02:08:05','2014-11-14 02:08:05'),(5,'bruce.g.irvine@gmail.com',2,'baaaa','iaaaa','dwUPG467382c717dff4b','2014-06-24 15:07:09','2014-11-14 02:08:05','2014-11-14 02:08:05'),(6,'chris@symplicit.com.au',2,'Chris','Michelle-Wells','6vI7p4062be6b807da40','2014-08-21 23:42:12','2014-11-14 02:08:05','2014-11-14 02:08:05'),(7,'jamie@symplicit.com.au',2,'Jamie','Chin','LSNY603ac82227891508','2014-08-21 23:45:30','2014-11-14 02:08:05','2014-11-14 02:08:05'),(8,'cameron@symplicit.com.au',2,'Cameron','Owens','y8zmW3bdafd10324e0e8','2014-08-21 23:45:55','2014-11-14 02:08:05','2014-11-14 02:08:05'),(9,'james@symplicit.com.au',2,'James','Duggan','0AvOBf6d9ab9afcf1dd5','2014-08-21 23:46:16','2014-11-14 02:08:05','2014-11-14 02:08:05'),(11,'m.pocklington@sportingpulseinternational.com',2,'Michael','Pocklington','JrCS8m7dc9cfdb3a1e0c','2014-08-21 23:48:08','2014-11-14 02:08:05','2014-11-14 02:08:05'),(12,'tania@symplicit.com.au',2,'Tania','Fox','ta3af7850cd79a4ceb7d','2014-09-10 01:48:53','2014-11-14 02:08:05','2014-11-14 02:08:05'),(13,'fox.tania@gmail.com',2,'Tania','Fox','dfca882c2c5c27345d68','2014-09-10 02:16:47','2014-11-14 02:08:05','2014-11-14 02:08:05'),(14,'j.escoto@sportingpulseinternational.com',2,'jervy','escoto','YmBs855e09d885a3f4e5','2014-10-06 03:38:07','2014-11-14 02:08:05','2014-11-14 02:08:05'),(15,'antonio.camacho@bluewin.ch',2,'Antonio','Camacho','KSEfrc3e791231390b6b','2014-10-14 06:08:36','2014-11-14 02:08:05','2014-11-14 02:08:05'),(16,'m.cowling@sportingpulseinternational.com',2,'Matthew','Cowling','FJWEmT3965d7cf5e8892','2014-10-14 06:11:12','2014-11-14 02:08:05','2014-11-14 02:08:05'),(17,'e.macaraig@sportingpulseinternational.com',2,'Erwin','Macaraig','csjKIPe6f77828d38f10','2014-11-07 05:03:58','2014-11-14 02:08:05','2014-11-14 02:08:05'),(18,'d.maakaroun@sportingpulseinternational.com',2,'Daniel','Maakaroun','GYC6RFbd4a5edca0c758','2014-11-09 22:23:40','2014-11-14 02:08:05','2014-11-14 02:08:05'),(19,'DM0001',2,'Daniel','Maakaroun','','2014-11-13 00:56:02','2014-11-14 02:08:05','2014-11-14 02:08:05'),(20,'DM0002',2,'Daniel','Maakaroun','','2014-11-13 00:56:33','2014-11-14 02:08:05','2014-11-14 02:08:05'),(21,'DM0003',2,'Daniel','Maakaroun','','2014-11-13 00:57:24','2014-11-14 02:08:05','2014-11-14 02:08:05'),(22,'DM0004',2,'Daniel','Maakaroun','','2014-11-13 03:51:09','2014-11-14 02:08:05','2014-11-14 02:08:05'),(23,'DM0005',2,'Daniel','Maakaroun','','2014-11-13 22:50:02','2014-11-14 02:13:55','2014-11-14 02:13:55'),(24,'DM0006',2,'Daniel','Maakaroun','','2014-11-13 22:50:50','2014-11-14 02:13:55','2014-11-14 02:13:55'),(25,'MP0001',2,'Michael','Pocklington','','2014-11-14 00:48:31','2014-11-14 02:13:55','2014-11-14 02:13:55'),(26,'MP0002',2,'Michael','Pocklington','','2014-11-14 00:48:50','2014-11-14 02:13:55','2014-11-14 02:13:55'),(27,'MP0003',2,'Michael','Pocklington','','2014-11-14 00:49:14','2014-11-14 02:13:55','2014-11-14 02:13:55'),(28,'baffMA',2,'Baff','MA','','2014-11-17 03:51:19','2014-11-17 03:51:19','2014-11-17 03:51:19'),(29,'MP0004',2,'Michael','Pocklington','','2014-11-19 04:49:16','2014-11-19 04:49:16','2014-11-19 04:49:16'),(30,'MP0005',2,'Michael','Pocklington','','2014-11-21 00:18:57','2014-11-21 00:18:57','2014-11-21 00:18:57'),(31,'mpocklington',2,'Michael','Pocklington','','2014-11-28 01:32:26','2014-11-28 01:32:26','2014-11-28 01:32:26'),(32,'MP0010',2,'Michael','Pocklington','','2014-12-01 03:37:57','2014-12-01 03:37:57','2014-12-01 03:37:57'),(37,'DM2000',2,'Daniel','Maakaroun','','2014-12-01 03:44:26','2014-12-01 03:44:26','2014-12-01 03:44:26'),(38,'DM3000',2,'Daniel','Maakaroun','','2014-12-01 03:46:41','2014-12-01 03:46:41','2014-12-01 03:46:41'),(39,'MP3000',2,'Michael','Pocklington','','2014-12-01 03:53:57','2014-12-01 03:53:57','2014-12-01 03:53:57'),(40,'MC1000',2,'Matthew','Cowling','','2014-12-02 05:46:16','2014-12-02 05:46:16','2014-12-02 05:46:16'),(41,'MC2000',2,'Matthew','Cowling','','2014-12-02 05:47:57','2014-12-02 05:47:57','2014-12-02 05:47:57'),(42,'JE0001',2,'Jervy','Escoto','','2014-12-02 10:53:37','2014-12-02 10:53:37','2014-12-02 10:53:37'),(43,'JE0001W',2,'jervy','escoto','','2014-12-02 23:50:18','2014-12-02 23:50:18','2014-12-02 23:50:18'),(44,'JE0001MA',2,'jervy','escoto','','2014-12-02 23:53:26','2014-12-02 23:53:26','2014-12-02 23:53:26'),(45,'JE0001A',2,'jervy','escoto','','2014-12-03 10:41:25','2014-12-03 10:41:25','2014-12-03 10:41:25'),(46,'AC1000',2,'Antonio','Camacho','','2014-12-04 07:47:27','2014-12-04 07:47:27','2014-12-04 07:47:27'),(47,'AC2000',2,'Antonio','Camacho','','2014-12-04 09:36:20','2014-12-04 09:36:20','2014-12-04 09:36:20'),(48,'BT1000',2,'Ben','Turner','','2014-12-05 03:01:25','2014-12-05 03:01:25','2014-12-05 03:01:25'),(49,'Nazeer@fas.org.sg',2,'Nazeer','Nazeer','','2014-12-09 12:00:41','2014-12-09 12:00:41','2014-12-09 12:00:41'),(50,'visva@fas.org.sg',2,'Visva','Visva','','2014-12-09 12:08:22','2014-12-09 12:08:22','2014-12-09 12:08:22'),(51,'vickneswaran@fas.org.sg',2,'Vickneswaren','Vickneswaren','','2014-12-09 12:08:42','2014-12-09 12:08:42','2014-12-09 12:08:42'),(52,'romzi@fas.org.sg',2,'Romzi','Romzi','','2014-12-09 12:09:00','2014-12-09 12:09:00','2014-12-09 12:09:00'),(53,'Ashley@fas.org.sg',2,'Ashley','Ashley','','2014-12-09 12:09:19','2014-12-09 12:09:19','2014-12-09 12:09:19'),(54,'sangeetha@fas.org.sg',2,'Sangeetha','Sangeetha','','2014-12-09 12:09:40','2014-12-09 12:09:40','2014-12-09 12:09:40'),(55,'Taufiq@fas.org.sg',2,'Taufiq','Taufiq','','2014-12-09 12:10:00','2014-12-09 12:10:00','2014-12-09 12:10:00'),(56,'rani@fas.org.sg',2,'Rani','Rani','','2014-12-09 12:10:15','2014-12-09 12:10:15','2014-12-09 12:10:15'),(57,'herman@fas.org.sg',2,'Herman','Herman','','2014-12-09 12:10:33','2014-12-09 12:10:33','2014-12-09 12:10:33'),(58,'rajan@fas.org.sg',2,'Rajan','Rajan','','2014-12-09 12:10:51','2014-12-09 12:10:51','2014-12-09 12:10:51'),(59,'Gordon@fas.org.sg',2,'Gordon','Gordon','','2014-12-09 12:11:12','2014-12-09 12:11:12','2014-12-09 12:11:12'),(60,'chinkok@fas.org.sg',2,'Chincok','Chincok','','2014-12-09 12:11:57','2014-12-09 12:11:57','2014-12-09 12:11:57'),(61,'club1000',2,'Michael','A','','2014-12-10 00:16:47','2014-12-10 00:16:47','2014-12-10 00:16:47'),(62,'club2000',2,'Steve','B','','2014-12-10 00:17:39','2014-12-10 00:17:39','2014-12-10 00:17:39'),(63,'club3000',2,'Kevin','N','','2014-12-10 00:18:13','2014-12-10 00:18:13','2014-12-10 00:18:13'),(64,'club4000',2,'Mark','D','','2014-12-10 00:18:49','2014-12-10 00:18:49','2014-12-10 00:18:49'),(65,'club5000',2,'Andy','C','','2014-12-10 00:19:11','2014-12-10 00:19:11','2014-12-10 00:19:11'),(66,'club6000',2,'Sam','A','','2014-12-10 00:19:45','2014-12-10 00:19:45','2014-12-10 00:19:45'),(68,'DM02',2,'Daniel','Maakaroun','','2014-12-10 00:45:19','2014-12-10 00:45:19','2014-12-10 00:45:19'),(69,'DM03',2,'Daniel','Maakaroun','','2014-12-10 00:46:48','2014-12-10 00:46:48','2014-12-10 00:46:48'),(70,'MP1966',2,'Michael','Pocklington','','2014-12-10 01:45:31','2014-12-10 01:45:31','2014-12-10 01:45:31'),(71,'syke',2,'syke','santos','','2014-12-10 06:11:14','2014-12-10 06:11:14','2014-12-10 06:11:14'),(72,'CM1000',2,'Christian','Michels','','2014-12-10 11:06:33','2014-12-10 11:06:33','2014-12-10 11:06:33'),(73,'EE1000',2,'Elizabeth','Eastman','','2014-12-10 11:07:52','2014-12-10 11:07:52','2014-12-10 11:07:52'),(74,'SM1000',2,'Sujit','Manjuran','','2014-12-10 11:09:15','2014-12-10 11:09:15','2014-12-10 11:09:15'),(75,'DG1000',2,'Daniel','Gonteri','','2014-12-10 11:10:12','2014-12-10 11:10:12','2014-12-10 11:10:12'),(76,'KS1000',2,'Kaita','Sugihara','','2014-12-10 11:11:46','2014-12-10 11:11:46','2014-12-10 11:11:46'),(77,'CM2000',2,'Christian','Michels','','2014-12-10 11:17:42','2014-12-10 11:17:42','2014-12-10 11:17:42'),(78,'EE2000',2,'Elizabeth','Eastman','','2014-12-10 11:18:01','2014-12-10 11:18:01','2014-12-10 11:18:01'),(79,'SM2000',2,'Sujit','Manjuran','','2014-12-10 11:18:29','2014-12-10 11:18:29','2014-12-10 11:18:29'),(80,'DG2000',2,'Daniel','Gonteri','','2014-12-10 11:18:52','2014-12-10 11:18:52','2014-12-10 11:18:52'),(81,'KS2000',2,'Kaita','Sugihara','','2014-12-10 11:19:11','2014-12-10 11:19:11','2014-12-10 11:19:11'),(82,'DM04',2,'Daniel','Maakaroun','','2014-12-11 01:02:28','2014-12-11 01:02:28','2014-12-11 01:02:28'),(83,'DM05',2,'Daniel','Maakaroun','','2014-12-11 02:07:35','2014-12-11 02:07:35','2014-12-11 02:07:35'),(84,'MP1980',2,'Michael','Pocklington','','2014-12-13 06:09:29','2014-12-13 06:09:29','2014-12-13 06:09:29'),(85,'baffA',2,'baff','AAA','','2014-12-13 20:59:04','2014-12-13 20:59:04','2014-12-13 20:59:04'),(86,'MP1981',2,'Michael','Pocklington','','2014-12-13 21:08:39','2014-12-13 21:08:39','2014-12-13 21:08:39'),(87,'HT2000',2,'Hans','Thies','','2014-12-14 23:23:16','2014-12-14 23:23:16','2014-12-14 23:23:16'),(88,'HT1000',2,'Hans','Thies','','2014-12-14 23:24:05','2014-12-14 23:24:05','2014-12-14 23:24:05'),(89,'CM3000',2,'Christian','Michels','','2014-12-14 23:24:46','2014-12-14 23:24:46','2014-12-14 23:24:46'),(90,'EE3000',2,'Elizabeth','Eastman','','2014-12-14 23:25:12','2014-12-14 23:25:12','2014-12-14 23:25:12'),(91,'SM3000',2,'Sujit','Manjuran','','2014-12-14 23:25:40','2014-12-14 23:25:40','2014-12-14 23:25:40'),(92,'DG3000',2,'Daniel','Gonteri','','2014-12-14 23:26:05','2014-12-14 23:26:05','2014-12-14 23:26:05'),(93,'KS3000',2,'Kaita','Sugihara','','2014-12-14 23:26:34','2014-12-14 23:26:34','2014-12-14 23:26:34'),(94,'AM3000',2,'Antonio','Camacho','','2014-12-14 23:27:12','2014-12-14 23:27:12','2014-12-14 23:27:12'),(95,'HT3000',2,'Hans','Thies','','2014-12-14 23:27:36','2014-12-14 23:27:36','2014-12-14 23:27:36'),(96,'DM06',2,'Daniel','Maakaroun','','2014-12-15 02:15:02','2014-12-15 02:15:02','2014-12-15 02:15:02'),(97,'MP2000',2,'Michael','Pocklington','','2014-12-15 07:10:19','2014-12-15 07:10:19','2014-12-15 07:10:19'),(98,'FAS3000',2,'FAS','Test','','2014-12-16 01:24:04','2014-12-16 01:24:04','2014-12-16 01:24:04'),(99,'FAS4000',2,'FAS','Test','','2014-12-16 01:24:22','2014-12-16 01:24:22','2014-12-16 01:24:22'),(100,'FAS5000',2,'FAS','Test','','2014-12-16 01:24:38','2014-12-16 01:24:38','2014-12-16 01:24:38'),(101,'FAS6000',2,'FAS','Test','','2014-12-16 01:24:57','2014-12-16 01:24:57','2014-12-16 01:24:57'),(102,'FAS7000',2,'FAS','Test','','2014-12-16 01:25:19','2014-12-16 01:25:19','2014-12-16 01:25:19'),(103,'FAS8000',2,'FAS','test','','2014-12-16 01:33:11','2014-12-16 01:33:11','2014-12-16 01:33:11'),(104,'FAS9000',2,'FAS','Test','','2014-12-16 02:02:47','2014-12-16 02:02:47','2014-12-16 02:02:47'),(105,'Coach1000',2,'Coach','Test','','2014-12-16 03:35:05','2014-12-16 03:35:05','2014-12-16 03:35:05'),(106,'Coach3000',2,'Coach','Test','','2014-12-16 03:36:28','2014-12-16 03:36:28','2014-12-16 03:36:28'),(107,'Coach4000',2,'Coaching','Test','','2014-12-16 03:36:58','2014-12-16 03:36:58','2014-12-16 03:36:58'),(108,'Adrian28',2,'Adrian','Chan','','2014-12-16 03:37:43','2014-12-16 03:37:43','2014-12-16 03:37:43'),(109,'Coach2000',2,'FAS','Coach','','2014-12-16 03:39:36','2014-12-16 03:39:36','2014-12-16 03:39:36'),(110,'Adrian30',2,'Adrian','Chan','','2014-12-16 03:39:57','2014-12-16 03:39:57','2014-12-16 03:39:57'),(111,'Coach5000',2,'FAS','Coach','','2014-12-16 03:41:27','2014-12-16 03:41:27','2014-12-16 03:41:27'),(112,'Coach6000',2,'Coaching','Test','','2014-12-16 03:43:08','2014-12-16 03:43:08','2014-12-16 03:43:08'),(113,'ref1000',2,'Referee','Test','','2014-12-16 06:22:56','2014-12-16 06:22:56','2014-12-16 06:22:56'),(114,'ref2000',2,'Referee','Test','','2014-12-16 06:23:16','2014-12-16 06:23:16','2014-12-16 06:23:16'),(115,'ref3000',2,'Referee','Testing','','2014-12-16 06:29:55','2014-12-16 06:29:55','2014-12-16 06:29:55'),(116,'ref4000',2,'Testing','Referee','','2014-12-16 06:31:40','2014-12-16 06:31:40','2014-12-16 06:31:40'),(117,'SNG1000',2,'test','test','','2014-12-16 23:23:09','2014-12-16 23:23:09','2014-12-16 23:23:09'),(118,'SNG2000',2,'test','test','','2014-12-16 23:23:19','2014-12-16 23:23:19','2014-12-16 23:23:19'),(119,'SNG3000',2,'test','test','','2014-12-16 23:23:28','2014-12-16 23:23:28','2014-12-16 23:23:28'),(120,'SNG4000',2,'test','test','','2014-12-16 23:23:37','2014-12-16 23:23:37','2014-12-16 23:23:37'),(121,'SNG5000',2,'test','test','','2014-12-16 23:23:45','2014-12-16 23:23:45','2014-12-16 23:23:45'),(122,'SNG6000',2,'test','test','','2014-12-16 23:23:54','2014-12-16 23:23:54','2014-12-16 23:23:54'),(123,'SNG7000',2,'test','test','','2014-12-16 23:24:01','2014-12-16 23:24:01','2014-12-16 23:24:01'),(124,'SNG8000',2,'test','test','','2014-12-16 23:24:10','2014-12-16 23:24:10','2014-12-16 23:24:10'),(125,'SING10',2,'test','test','','2014-12-16 23:24:31','2014-12-16 23:24:31','2014-12-16 23:24:31'),(126,'SING20',2,'test','test','','2014-12-16 23:24:39','2014-12-16 23:24:39','2014-12-16 23:24:39'),(127,'SING30',2,'test','test','','2014-12-16 23:24:48','2014-12-16 23:24:48','2014-12-16 23:24:48'),(128,'SING40',2,'test','test','','2014-12-16 23:24:55','2014-12-16 23:24:55','2014-12-16 23:24:55'),(129,'SING50',2,'test','test','','2014-12-16 23:25:04','2014-12-16 23:25:04','2014-12-16 23:25:04'),(130,'SING60',2,'test','test','','2014-12-16 23:25:12','2014-12-16 23:25:12','2014-12-16 23:25:12'),(131,'SING70',2,'test','test','','2014-12-16 23:25:20','2014-12-16 23:25:20','2014-12-16 23:25:20'),(132,'SING80',2,'test','test','','2014-12-16 23:25:29','2014-12-16 23:25:29','2014-12-16 23:25:29'),(133,'FAS2222',2,'Fas ','coach','','2014-12-17 03:09:58','2014-12-17 03:09:58','2014-12-17 03:09:58'),(134,'DM07',2,'Daniel','Maakaroun','','2014-12-17 22:40:34','2014-12-17 22:40:34','2014-12-17 22:40:34'),(135,'DM08',2,'Daniel','Maakaroun','','2014-12-21 22:57:45','2014-12-21 22:57:45','2014-12-21 22:57:45'),(136,'baffclube',2,'baffclube','Baff','','2014-12-24 06:16:43','2014-12-24 06:16:43','2014-12-24 06:16:43'),(137,'clube',2,'Club','E','','2014-12-28 19:53:56','2014-12-28 19:53:56','2014-12-28 19:53:56'),(138,'baffclubf',2,'baffclubf','baffclubf','','2015-01-02 09:20:03','2015-01-02 09:20:03','2015-01-02 09:20:03'),(139,'FAS500',2,'FAS','Test','','2015-01-05 00:44:36','2015-01-05 00:44:36','2015-01-05 00:44:36'),(140,'FAS600',2,'FAS','Test','','2015-01-05 00:45:05','2015-01-05 00:45:05','2015-01-05 00:45:05'),(141,'FAS700',2,'FAS','Test','','2015-01-05 00:46:06','2015-01-05 00:46:06','2015-01-05 00:46:06'),(142,'FAS2015',2,'FAS','Test','','2015-01-06 22:24:23','2015-01-06 22:24:23','2015-01-06 22:24:23'),(143,'tttt',2,'tttt','tttt','','2015-01-11 21:27:35','2015-01-11 21:27:35','2015-01-11 21:27:35');
/*!40000 ALTER TABLE `tblUser` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblUserAuth`
--

DROP TABLE IF EXISTS `tblUserAuth`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblUserAuth` (
  `userId` int(10) unsigned NOT NULL,
  `entityTypeId` int(11) NOT NULL,
  `entityId` int(11) NOT NULL,
  `lastLogin` datetime DEFAULT NULL,
  `readOnly` tinyint(4) DEFAULT '0',
  PRIMARY KEY (`userId`,`entityTypeId`,`entityId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblUserAuth`
--

LOCK TABLES `tblUserAuth` WRITE;
/*!40000 ALTER TABLE `tblUserAuth` DISABLE KEYS */;
INSERT INTO `tblUserAuth` VALUES (5,100,1,'2015-01-19 16:43:44',0),(6,100,1,'2014-12-17 21:28:36',0),(7,100,1,NULL,0),(8,100,1,NULL,0),(9,100,1,NULL,0),(11,100,1,'2014-11-14 02:14:29',0),(15,100,1,'2015-01-09 07:37:28',0),(16,100,1,'2014-12-01 13:02:35',0),(17,100,1,'2015-01-12 02:12:51',0),(19,100,1,'2015-01-12 03:44:19',0),(25,100,1,'2015-01-12 03:17:43',0),(28,100,1,'2015-01-11 21:28:31',0),(40,100,1,'2015-01-06 03:26:11',0),(44,100,1,'2014-12-25 23:36:39',0),(48,100,1,'2014-12-07 23:32:55',0),(49,100,1,'2014-12-10 05:15:03',0),(50,100,1,'2014-12-10 02:32:24',0),(51,100,1,NULL,0),(52,100,1,'2014-12-10 03:39:48',0),(53,100,1,'2015-01-11 13:21:34',0),(54,100,1,'2014-12-19 03:46:20',0),(55,100,1,'2015-01-09 03:57:23',0),(56,100,1,'2015-01-09 10:08:20',0),(57,100,1,'2015-01-02 09:53:06',0),(58,100,1,NULL,0),(59,100,1,'2015-01-09 06:50:01',0),(60,100,1,'2015-01-08 08:24:19',0),(72,100,1,'2014-12-29 07:47:24',0),(73,100,1,'2014-12-29 19:18:39',0),(74,100,1,'2015-01-08 08:12:45',0),(75,100,1,'2014-12-15 10:27:22',0),(76,100,1,NULL,0),(88,100,1,NULL,0),(98,100,1,'2015-01-08 07:35:16',0),(99,100,1,'2014-12-31 03:38:56',0),(100,100,1,'2015-01-08 06:35:37',0),(101,100,1,'2015-01-08 07:12:30',0),(102,100,1,'2015-01-08 07:37:41',0),(103,100,1,'2014-12-19 03:49:54',0),(104,100,1,'2015-01-08 07:47:35',0),(105,100,1,NULL,0),(109,100,1,NULL,0),(110,100,1,NULL,0),(113,100,1,'2014-12-17 05:46:27',0),(114,100,1,'2015-01-06 02:42:27',0),(115,100,1,'2015-01-09 05:17:04',0),(116,100,1,'2014-12-23 06:59:07',0);
/*!40000 ALTER TABLE `tblUserAuth` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblUserAuthRole`
--

DROP TABLE IF EXISTS `tblUserAuthRole`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblUserAuthRole` (
  `userId` int(10) unsigned NOT NULL,
  `entityTypeId` int(11) NOT NULL,
  `entityId` int(11) NOT NULL,
  `roleId` int(11) NOT NULL,
  PRIMARY KEY (`userId`,`entityTypeId`,`entityId`,`roleId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblUserAuthRole`
--

LOCK TABLES `tblUserAuthRole` WRITE;
/*!40000 ALTER TABLE `tblUserAuthRole` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblUserAuthRole` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblUserAuthRoles`
--

DROP TABLE IF EXISTS `tblUserAuthRoles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblUserAuthRoles` (
  `userId` int(10) unsigned NOT NULL,
  `entityTypeId` int(11) NOT NULL,
  `entityId` int(11) NOT NULL,
  `roleId` int(11) NOT NULL,
  PRIMARY KEY (`userId`,`entityTypeId`,`entityId`,`roleId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblUserAuthRoles`
--

LOCK TABLES `tblUserAuthRoles` WRITE;
/*!40000 ALTER TABLE `tblUserAuthRoles` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblUserAuthRoles` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblUserHash`
--

DROP TABLE IF EXISTS `tblUserHash`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblUserHash` (
  `userId` int(10) unsigned NOT NULL,
  `passwordHash` varchar(100) DEFAULT NULL,
  `ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `strPasswordChangeKey` varchar(50) NOT NULL,
  PRIMARY KEY (`userId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblUserHash`
--

LOCK TABLES `tblUserHash` WRITE;
/*!40000 ALTER TABLE `tblUserHash` DISABLE KEYS */;
INSERT INTO `tblUserHash` VALUES (1,'cneB0Q9004f760acc6c42bd5abc0d81c86d853','2014-10-21 01:18:26','39JNgaGhmjJO'),(2,'zvcYr&4607f11e3b969b493731e43e9b72e393','2014-06-04 03:00:56',''),(3,'ThL;!E115b581ef6d5cf27ed3ef17e8922c2bd','2014-06-04 03:02:01',''),(4,'i^JP?V990f0d1897cb648ea52d3dba6c80bf57','2014-06-04 03:02:54',''),(5,'AMYzCl8c8ac95ec13e042c81059fda124a4d62','2014-06-24 05:07:09',''),(6,'y4&z6P93db51a3ec4b8d91f302797d0dc15ada','2014-08-21 23:42:12',''),(7,'UqnCaOd543f09e3e5dd5dd7f604314eaad4844','2014-08-21 23:45:30',''),(8,'!%tJ5I0810fb8b2e6737ade9339dbcec9cf566','2014-08-21 23:45:55',''),(9,'e*FkSj7b9638b366b75d1f8b73421142c8a89c','2014-08-21 23:46:16',''),(10,'Nbw5~Oaa0500968453d70b0530018b71ce24ce','2014-08-21 23:47:38',''),(11,'@Bjd?h75b15eab8bda67a78987c4c01029bbee','2014-08-21 23:48:09',''),(12,'R1wudle554c3910f3b2fc85e91e5964528ff60','2014-09-10 01:48:53',''),(13,'lBg1TZ5c7bb0825d0cc70bffe690e9a09e5cf7','2014-09-10 02:16:47',''),(14,'gTYhn43dea687dce0fe033def1267cea572bcc','2014-10-06 03:38:07',''),(15,'GHhJ^s0cd91158b0466b7d40ab0a5387d40a58','2014-10-14 06:08:36',''),(16,';KLD:2fe4d193deb6aff38dc2b1512b87a81bf','2014-10-14 06:11:12',''),(17,'djcLC2b5ac162338a741bd663d99bcbc018d2a','2014-11-08 17:04:19','41vDx98yTcEo'),(18,'U1db2Ge87c13209f7495348c691d76344d3430','2014-11-09 22:23:40',''),(19,'*IPo8hfd5e694e8dd49f1c758098e1340c924c','2014-11-13 00:56:02',''),(20,'vC9iLY7cfc6125592a01d33bf7752a860eb33a','2014-11-13 00:56:33',''),(21,'j@JcdF555287c4eb76758069d6c804fed5758a','2014-11-13 00:57:24',''),(22,'nWBd0j3411073bb58b6abfb96562eae4c8c429','2014-11-13 03:51:09',''),(23,'XpAiSPa4c42bd17d1c0961fea56266f835de18','2014-11-13 22:50:02',''),(24,'ry^LT8eed66f449f163be733326c4827305567','2014-11-13 22:50:50',''),(25,'Gj;Sl&d6cb78ffd66a81006e5fb7f677ef4d6b','2014-11-14 00:48:31',''),(26,'CHAJ6i593ec0ca125f26ed3018ddc92dfa3121','2014-11-14 00:48:50',''),(27,'*RoCcJe1b5d8bdd44eedc42af8e91edf0ec428','2014-11-14 00:49:14',''),(28,'Fg%aGt71e77470e63b7a4e31007a8d76e484b7','2014-11-17 03:51:19',''),(29,'q%b4L1771eccc19c67d81c8f698e29ddc93dba','2014-11-19 04:49:16',''),(30,'R~4IDhbf1894887d74722cddd79761e88ab6b0','2014-11-21 00:18:57',''),(31,'6Q~5Pj552900e7a0eea9d5ca78f6f8521892bd','2014-11-28 01:32:26',''),(32,'6TYvZxd0b149cada7fbd3313c9a79044aa00fa','2014-12-01 03:37:57',''),(37,'OC3hRN4ecef58c55c0ed6a74be31e14e67a9ad','2014-12-01 03:51:03',''),(38,'P5x7y;deb7952ef14fe9b49378cc5097fa4fb1','2014-12-01 03:49:30',''),(39,'cNv4oZ842534749793d57375712ed477260fae','2014-12-01 03:53:57',''),(40,'EIBf?41b1a63148d26a197ae85e4bf410613e3','2014-12-12 07:25:01',''),(41,'BkQMmW009c9adc4a4aa05c45be804752391c05','2014-12-02 05:47:57',''),(42,'9SwZXvacea1932efb811927463808d41bdc788','2014-12-02 10:53:37',''),(43,'Lu;V2*0869b059f448fddb7482c1504f6df8b9','2014-12-02 23:50:18',''),(44,'&CnaYU5bea0884fcbbe9efb98780c60bacaa3d','2014-12-02 23:53:26',''),(45,'X48u1O9bd08c4d2159d2db82bcfb5969869406','2014-12-03 10:41:25',''),(46,'hWXo0xcd6ebf83a3bfe6a741e43b2c680a1160','2014-12-04 07:47:27',''),(47,'sLgoE66009df35feb5543db0274ee86aae86ec','2014-12-04 09:36:20',''),(48,'0Epbthe39cf7f145a15694f93d5b52b80194fc','2014-12-05 03:01:25',''),(49,'jK1y&r21c6723468ee0fd213eb7dd7b131626b','2014-12-09 12:00:41',''),(50,'l6^~3db35821a86f852986dee49c905c2aaa04','2014-12-09 12:08:22',''),(51,'6r2X:8475313359a90f070e7eed1e0e7dfabdb','2014-12-09 12:08:42',''),(52,'RhGDKv13d398c2ae48313ac5fb81678f759740','2014-12-09 12:09:00',''),(53,':;ij8^29365e60cf946f87205a7b35b1a5ad59','2014-12-16 01:50:49',''),(54,'*vp@TWb0742d8b423a07b64516b40357a7df55','2014-12-19 03:46:09',''),(55,'zxyiDKcf811007291df1cacc0da8d02e07e069','2014-12-09 12:10:00',''),(56,'Tlyigqcaaaf294951a886170f1ee1f8d9253a3','2014-12-09 12:10:15',''),(57,'1u?:a~8e065a6541904a276126a2887fa36a4c','2014-12-09 12:10:33',''),(58,'3CeqiK0b67e699c86fe4c863c15bf69aaaadee','2014-12-09 12:10:51',''),(59,'dfK4*^6d7a375815e052124abfc15e90896b8a','2014-12-09 12:11:12',''),(60,'2WOAKP8c406eea024cc9fd5e2982a45dd89ca7','2014-12-17 06:55:21',''),(61,'GCqWm$8b0d322205b7657929795176bc0b99f1','2014-12-10 00:16:47',''),(62,'c5Y*sJeca170be0944e819c41e0e7091f12572','2014-12-10 00:17:39',''),(63,'8mcHy254e85032ab2e7b4896fb212a45f92956','2014-12-10 00:18:13',''),(64,'vN7^4$8fc443ccffd7293b97ac3a69966e4136','2014-12-10 00:18:49',''),(65,'BCRfY5237a0d6dece4d11593da438c14221344','2014-12-10 00:19:11',''),(66,'yr8t%!bda6eb94395946e1cceac859c22f0baf','2014-12-10 00:19:45',''),(68,'3n7hrfccae812a5bdde60263dec845a6e3177d','2014-12-10 00:45:19',''),(69,'eARXa38408dda3788446fbccce70e56b124c6a','2014-12-10 00:46:48',''),(70,'sC60IV960a7265319fcb18b096b222823e241f','2014-12-10 01:45:31',''),(71,'WJE?9zdb1e0e52f452371fa41000ee2a1d5e55','2014-12-10 06:11:14',''),(72,'7&lq*35c3248b6a49b73f0003ba2b49d55f2c7','2014-12-10 11:06:33',''),(73,'bEGAjw824c6b2f3ad5173b19c358f2610a9442','2014-12-10 11:07:52',''),(74,'mNI;U9ed9e41fdb37698a8817056de0ce88c96','2014-12-10 11:09:15',''),(75,'img4^o5af5ee5a73b19d8567a1ea41c30858b9','2014-12-10 11:10:12',''),(76,';GFvU05e967fdc21548d62628980b3e38eb016','2014-12-10 11:11:46',''),(77,':O!xrk8af9b5f4bfa01d06ba3c668af6708b9f','2014-12-10 11:17:42',''),(78,'1Rpk$Ke838ae82ec5f57945be85954acce6c18','2014-12-10 11:18:01',''),(79,'rbeFzl1e981153d26ac3abab589737ba8463bd','2014-12-10 11:18:29',''),(80,'ry7aG2169e85537f4bfad5725c5823ab618b3a','2014-12-10 11:18:52',''),(81,'LZ0meHb6679bb3af3c7dff86506219889fc614','2014-12-10 11:19:11',''),(82,'JK1sO*cdfdd77e8e9cb0478925bb6ef0d3b797','2014-12-11 01:02:28',''),(83,'aZT0uzfdd40435c4ace6d1850908b84c9d9c8f','2014-12-11 02:07:35',''),(84,'XZa7YSe40c7706c52b6d4e0f045466756f36ba','2014-12-13 06:09:29',''),(85,'nI4?hV145a815cada9ae44c82200a2d05b5c4c','2014-12-13 20:59:04',''),(86,'bS~oVE5f58ef896f152517129d8f782a2a8c88','2014-12-15 02:08:53',''),(87,'!nDOzK8b331172bf32b945e1339cb04b11f589','2014-12-14 23:23:16',''),(88,'STY7!55686067ecd85ebb44c6659c1f362722f','2014-12-14 23:24:05',''),(89,'N7&Wds7c1d41c6ef0b1df237781064891816ff','2014-12-14 23:24:46',''),(90,'iGv0AXd3b53921c0b7ff25518e8cb1f896abe3','2014-12-14 23:25:12',''),(91,'*jzBx?59663fbb05bd86f74e76f7672feaa1ca','2014-12-14 23:25:40',''),(92,'BHRFCE77de0c538fcd4cf1b13b28d7e43716ff','2014-12-14 23:26:05',''),(93,'2&:!Ji3b9d06cc9a3ced3bed5520c7b6b7c584','2014-12-14 23:26:34',''),(94,'E&v710588bcfc520323597e7e2e767d57eb144','2014-12-14 23:27:12',''),(95,'Fgl%m1822fe28c9ba8872be507b1a4d617abbe','2014-12-14 23:27:36',''),(96,'!jUe:A3b97c4eea790e638d8a5ff4e5e0340d1','2014-12-15 02:15:02',''),(97,'b;MWSIdd4fa3dbf6d53be16aa9fa0241053700','2014-12-15 07:10:19',''),(98,'dRCDV461d10da8a1ff68f0bb24cfb9dbc9c262','2014-12-16 01:24:04',''),(99,'y6QaOh50edb29ace23450ce90884921fe7dc3b','2014-12-16 01:24:22',''),(100,'v4MFKpbc705980709cdad1ef3c8254e81de6f1','2014-12-16 01:24:38',''),(101,'@mi2DG52669f622f1b699ace2ca50d26ca076a','2014-12-16 01:24:57',''),(102,'jZGaW7ae5ce8b5f9d14ccfc42ea39b05f9c57b','2014-12-16 01:25:19',''),(103,'PSO~n6d661a02cdc1ddcd26d387102b3aff038','2014-12-16 01:33:11',''),(104,'P;9J$j0b7e6f9958ace26312f8fc2b3069f62d','2014-12-16 02:02:47',''),(105,'c%sL9e63f59430b97848c749848c905713ee9c','2014-12-16 03:35:05',''),(106,'?4&ZRF5c4d7d71097a1227c3928a0603ace7f8','2014-12-16 03:36:28',''),(107,'UyvCJG593b2cf4e0ca42de641c01c42711fb5e','2014-12-16 03:36:58',''),(108,'st?Ei%94f949378ba9ad82d1edb64af60bc94f','2014-12-16 03:37:43',''),(109,'YJ?nFBb4e735051504aa752b6f268d6c1c7290','2014-12-16 03:39:36',''),(110,'SLKVrkc43c9b43ae4ff11e1da4d45210e903a6','2014-12-16 03:39:57',''),(111,'Nhtc?m150132f014aabaf609e1e80519ae5668','2014-12-16 03:41:27',''),(112,'AZXJ?U52d265e79201370905c44af6f62e3552','2014-12-16 03:49:14',''),(113,'FtVxwv3aa49f6936e17b87229e2d7e49ed6afb','2014-12-16 06:22:56',''),(114,'9MxpJTafa6fd6e45a888ddb80b8f794abb33f8','2014-12-16 06:23:16',''),(115,'o%02j177b6cd3c3f06de27978d96d58933c063','2014-12-16 06:29:55',''),(116,'YKobtTbd30b3abea3807e587a6c73a4d150d90','2014-12-16 06:31:40',''),(117,'EL:X0c8184e31a8f20dd269271c77691c993e8','2014-12-16 23:23:09',''),(118,'InOdz%b31c938f2036239e37da23c930acc2a4','2014-12-16 23:23:19',''),(119,'&BoHOed62e161c923a81578b9281ec30ac84b6','2014-12-16 23:23:28',''),(120,'CYc&aub503f655b590b9713a71e8f0eea35ad1','2014-12-16 23:23:37',''),(121,'*ieUp?9d0c6f07307fd483a1e146a18474d156','2014-12-16 23:23:45',''),(122,'KkIE5u020dcae7ea9a82ca164b7855ac8c5a8b','2014-12-16 23:23:54',''),(123,':UIt4i4028283a63509bdf9764304d54297b76','2014-12-16 23:24:02',''),(124,'3BanmT4558747db9ab1ae7bfcc06f8759d22b3','2014-12-16 23:24:10',''),(125,'a&:*!W52e0e732629db080256e902ee00bec74','2014-12-16 23:24:31',''),(126,'j~ES^qdd20763384025f1a4ecd0c512081e82b','2014-12-16 23:24:39',''),(127,'qm7IQ89dbea4954333f5134baeeda59084610b','2014-12-16 23:24:48',''),(128,'%6m02Lcd0e52f618a874f21c175e453229095f','2014-12-16 23:24:55',''),(129,'6%Xo9~7c135cdf30ea0685518ab4a73cbc3d05','2014-12-16 23:25:04',''),(130,'!VJbK&4d03234e8e56c4e9d8fdcef1f1ed32bb','2014-12-16 23:25:12',''),(131,'smXRTZ5102f1eadc525c336f278043b40de6ea','2014-12-16 23:25:20',''),(132,'tVTGrXf2bd019744a47f3d342786e788c3cb76','2014-12-16 23:25:29',''),(133,'vAtYC$c736efc2f03f8c5733458185abbdb5c2','2014-12-17 03:09:58',''),(134,'$4ZAS7a22c8ece49d451dc7850a7f767a1250e','2014-12-17 22:40:34',''),(135,'e*7@s40c47019936fc9a4e85884609d659e174','2014-12-21 22:57:45',''),(136,'RXFOTb39064e024b7165440726e1cb27403886','2014-12-24 06:16:43',''),(137,'!TVbuq264bc0007f397fd4b5efc7e5c8ce4479','2014-12-28 19:53:56',''),(138,'UdzHD%35110d6c048096ec1d5eaa9fc7780964','2015-01-02 09:20:03',''),(139,'vO$5%15b73ead56b0d9bc61b827d39bc3582e8','2015-01-05 00:44:36',''),(140,'qFa3Dmc635bc03fb331ff0cd7ebe983050455b','2015-01-05 00:45:05',''),(141,'lVRgj!02291fb08c02db8d85784a598d3ea0e9','2015-01-05 00:46:06',''),(142,'bIMOK9a15b0f0cf49cc786917cf0a666af2b98','2015-01-06 22:24:23',''),(143,'Rg19IZ5b708d4b686db26b71ddc219d83dc2a8','2015-01-11 21:27:35','');
/*!40000 ALTER TABLE `tblUserHash` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblVerifiedEmail`
--

DROP TABLE IF EXISTS `tblVerifiedEmail`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblVerifiedEmail` (
  `strEmail` varchar(255) NOT NULL DEFAULT '',
  `dtVerified` datetime DEFAULT NULL,
  `strKey` varchar(20) DEFAULT NULL,
  PRIMARY KEY (`strEmail`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblVerifiedEmail`
--

LOCK TABLES `tblVerifiedEmail` WRITE;
/*!40000 ALTER TABLE `tblVerifiedEmail` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblVerifiedEmail` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblVersions`
--

DROP TABLE IF EXISTS `tblVersions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblVersions` (
  `intVersionID` int(11) NOT NULL AUTO_INCREMENT,
  `strText` text NOT NULL,
  `dtDate` date NOT NULL DEFAULT '0000-00-00',
  PRIMARY KEY (`intVersionID`),
  KEY `indexDate` (`dtDate`)
) ENGINE=MyISAM AUTO_INCREMENT=4 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblVersions`
--

LOCK TABLES `tblVersions` WRITE;
/*!40000 ALTER TABLE `tblVersions` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblVersions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblWFRule`
--

DROP TABLE IF EXISTS `tblWFRule`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblWFRule` (
  `intWFRuleID` int(11) NOT NULL AUTO_INCREMENT,
  `intRealmID` int(11) NOT NULL DEFAULT '0',
  `intSubRealmID` int(11) NOT NULL DEFAULT '0',
  `intOriginLevel` int(11) DEFAULT '0',
  `strWFRuleFor` varchar(30) DEFAULT '' COMMENT 'PERSON, REGO, ENTITY, DOCUMENT',
  `strEntityType` varchar(30) DEFAULT '',
  `intEntityLevel` int(11) DEFAULT '0',
  `strRegistrationNature` varchar(20) NOT NULL DEFAULT '0' COMMENT 'NEW,RENEWAL,AMENDMENT,TRANSFER,',
  `strPersonType` varchar(20) NOT NULL DEFAULT '' COMMENT 'PLAYER, COACH, REFEREE',
  `strPersonLevel` varchar(20) NOT NULL DEFAULT '' COMMENT 'AMATEUR,PROFESSIONAL',
  `strSport` varchar(20) NOT NULL DEFAULT '' COMMENT 'FOOTBALL,FUTSAL,BEACHSOCCER',
  `strAgeLevel` varchar(20) NOT NULL DEFAULT '' COMMENT 'SENIOR,JUNIOR',
  `intApprovalEntityLevel` int(11) NOT NULL DEFAULT '0' COMMENT 'Which Entity level has to approve this rule',
  `intProblemResolutionEntityLevel` int(11) NOT NULL DEFAULT '0' COMMENT 'Which Entity Level to solve issues',
  `strTaskType` varchar(20) NOT NULL DEFAULT 'APPROVAL' COMMENT 'APPROVAL,DOCUMENT',
  `strTaskStatus` varchar(20) NOT NULL DEFAULT 'PENDING' COMMENT 'PENDING,ACTIVE',
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `intDocumentTypeID` int(11) DEFAULT '0',
  `strPersonEntityRole` varchar(50) DEFAULT '',
  `strISOCountry_IN` varchar(200) DEFAULT '',
  `strISOCountry_NOTIN` varchar(200) DEFAULT '',
  PRIMARY KEY (`intWFRuleID`),
  KEY `Entity` (`intWFRuleID`),
  KEY `index_intRealmID` (`intRealmID`,`intSubRealmID`),
  KEY `index_RuleFor` (`strWFRuleFor`)
) ENGINE=InnoDB AUTO_INCREMENT=1470 DEFAULT CHARSET=utf8 COMMENT='Defines the flow of approvals for a registration. One set of rules per Realm. Within Realm there is one row for each combination of PersonType, Level, Sport, Nature, AgeLevel';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblWFRule`
--

LOCK TABLES `tblWFRule` WRITE;
/*!40000 ALTER TABLE `tblWFRule` DISABLE KEYS */;
INSERT INTO `tblWFRule` VALUES (1115,1,0,3,'ENTITY','',-47,'NEW','','','','',100,3,'APPROVAL','ACTIVE','2014-09-11 04:12:52',0,'','',''),(1144,1,0,3,'PERSON','',3,'INVALID_NEW','','','','',100,3,'APPROVAL','ACTIVE','2014-11-21 09:58:49',0,'','',''),(1145,1,0,3,'PERSON','',3,'AMENDMENT','','','','',100,3,'APPROVAL','ACTIVE','2014-11-21 09:58:49',0,'','',''),(1146,1,0,100,'ENTITY','',-47,'NEW','','','','',100,100,'APPROVAL','ACTIVE','2014-11-27 00:14:16',0,'','',''),(1147,1,0,100,'REGO','',100,'NEW','REFEREE','','FOOTBALL','ADULT',100,100,'APPROVAL','ACTIVE','2014-11-27 00:16:09',0,'','',''),(1148,1,0,100,'REGO','',100,'RENEWAL','REFEREE','','FOOTBALL','ADULT',100,100,'APPROVAL','ACTIVE','2014-11-27 00:16:29',0,'','',''),(1149,1,0,100,'REGO','',100,'NEW','MAOFFICIAL','','','ADULT',100,100,'APPROVAL','ACTIVE','2014-11-27 00:18:46',0,'','',''),(1150,1,0,100,'REGO','',100,'RENEWAL','MAOFFICIAL','','','ADULT',100,100,'APPROVAL','ACTIVE','2014-11-27 00:19:02',0,'','',''),(1172,1,0,3,'REGO','',3,'NEW','CLUBOFFICIAL','','FOOTBALL','ADULT',100,3,'APPROVAL','ACTIVE','2014-11-27 00:25:36',0,'','',''),(1173,1,0,100,'REGO','',3,'NEW','CLUBOFFICIAL','','FOOTBALL','ADULT',100,3,'APPROVAL','ACTIVE','2014-11-27 00:25:36',0,'','',''),(1174,1,0,3,'REGO','',3,'RENEWAL','CLUBOFFICIAL','','FOOTBALL','ADULT',100,3,'APPROVAL','ACTIVE','2014-11-27 00:25:36',0,'','',''),(1175,1,0,100,'REGO','',3,'RENEWAL','CLUBOFFICIAL','','FOOTBALL','ADULT',100,3,'APPROVAL','ACTIVE','2014-11-27 00:25:36',0,'','',''),(1180,1,0,100,'REGO','',100,'NEW','CLUBOFFICIAL','','FOOTBALL','ADULT',100,100,'APPROVAL','ACTIVE','2014-11-27 00:25:58',0,'','',''),(1182,1,0,100,'REGO','',100,'RENEWAL','CLUBOFFICIAL','','FOOTBALL','ADULT',100,100,'APPROVAL','ACTIVE','2014-11-27 00:25:58',0,'','',''),(1186,1,0,3,'REGO','',3,'NEW','TEAMOFFICIAL','','FOOTBALL','ADULT',100,3,'APPROVAL','ACTIVE','2014-11-27 00:26:07',0,'','',''),(1187,1,0,100,'REGO','',3,'NEW','TEAMOFFICIAL','','FOOTBALL','ADULT',100,3,'APPROVAL','ACTIVE','2014-11-27 00:26:07',0,'','',''),(1188,1,0,3,'REGO','',3,'RENEWAL','TEAMOFFICIAL','','FOOTBALL','ADULT',100,3,'APPROVAL','ACTIVE','2014-11-27 00:26:07',0,'','',''),(1189,1,0,100,'REGO','',3,'RENEWAL','TEAMOFFICIAL','','FOOTBALL','ADULT',100,3,'APPROVAL','ACTIVE','2014-11-27 00:26:07',0,'','',''),(1194,1,0,100,'REGO','',100,'NEW','TEAMOFFICIAL','','FOOTBALL','ADULT',100,100,'APPROVAL','ACTIVE','2014-11-27 00:26:14',0,'','',''),(1196,1,0,100,'REGO','',100,'RENEWAL','TEAMOFFICIAL','','FOOTBALL','ADULT',100,100,'APPROVAL','ACTIVE','2014-11-27 00:26:14',0,'','',''),(1200,1,0,3,'REGO','',3,'NEW','COACH','PROFESSIONAL','FOOTBALL','ADULT',100,3,'APPROVAL','ACTIVE','2014-11-27 00:30:11',0,'','',''),(1202,1,0,3,'REGO','',3,'RENEWAL','COACH','PROFESSIONAL','FOOTBALL','ADULT',100,3,'APPROVAL','ACTIVE','2014-11-27 00:30:11',0,'','',''),(1204,1,0,100,'REGO','',3,'NEW','COACH','AMATEUR','FOOTBALL','ADULT',100,3,'APPROVAL','ACTIVE','2014-11-27 00:30:11',0,'','',''),(1206,1,0,100,'REGO','',3,'RENEWAL','COACH','AMATEUR','FOOTBALL','ADULT',100,3,'APPROVAL','ACTIVE','2014-11-27 00:30:11',0,'','',''),(1220,1,0,100,'REGO','',100,'NEW','COACH','AMATEUR','FOOTBALL','ADULT',100,100,'APPROVAL','ACTIVE','2014-11-27 00:30:33',0,'','',''),(1222,1,0,100,'REGO','',100,'RENEWAL','COACH','AMATEUR','FOOTBALL','ADULT',100,100,'APPROVAL','ACTIVE','2014-11-27 00:30:33',0,'','',''),(1230,1,0,3,'REGO','',3,'RENEWAL','PLAYER','AMATEUR','FOOTBALL','MINOR',100,3,'APPROVAL','ACTIVE','2014-11-27 00:34:29',0,'','',''),(1232,1,0,3,'REGO','',3,'RENEWAL','PLAYER','PROFESSIONAL','FOOTBALL','MINOR',100,3,'APPROVAL','ACTIVE','2014-11-27 00:34:29',0,'','',''),(1234,1,0,3,'REGO','',3,'NEW','PLAYER','AMATEUR','FOOTBALL','MINOR',100,3,'APPROVAL','ACTIVE','2014-11-27 00:34:29',0,'','',''),(1236,1,0,3,'REGO','',3,'NEW','PLAYER','PROFESSIONAL','FOOTBALL','MINOR',100,3,'APPROVAL','ACTIVE','2014-11-27 00:34:29',0,'','',''),(1238,1,0,3,'REGO','',3,'NEW','PLAYER','AMATEUR_U_C','FOOTBALL','MINOR',100,3,'APPROVAL','ACTIVE','2014-11-27 00:34:29',0,'','',''),(1240,1,0,3,'REGO','',3,'RENEWAL','PLAYER','AMATEUR_U_C','FOOTBALL','MINOR',100,3,'APPROVAL','ACTIVE','2014-11-27 00:34:29',0,'','',''),(1242,1,0,3,'REGO','',3,'TRANSFER','PLAYER','AMATEUR','FOOTBALL','MINOR',100,3,'APPROVAL','ACTIVE','2014-11-27 00:34:29',0,'','',''),(1244,1,0,3,'REGO','',3,'TRANSFER','PLAYER','AMATEUR_U_C','FOOTBALL','MINOR',100,3,'APPROVAL','ACTIVE','2014-11-27 00:34:29',0,'','',''),(1246,1,0,3,'REGO','',3,'TRANSFER','PLAYER','PROFESSIONAL','FOOTBALL','MINOR',100,3,'APPROVAL','ACTIVE','2014-11-27 00:34:29',0,'','',''),(1248,1,0,100,'REGO','',3,'RENEWAL','PLAYER','AMATEUR','FOOTBALL','MINOR',100,3,'APPROVAL','ACTIVE','2014-11-27 00:34:29',0,'','',''),(1250,1,0,100,'REGO','',3,'RENEWAL','PLAYER','PROFESSIONAL','FOOTBALL','MINOR',100,3,'APPROVAL','ACTIVE','2014-11-27 00:34:29',0,'','',''),(1252,1,0,100,'REGO','',3,'NEW','PLAYER','AMATEUR','FOOTBALL','MINOR',100,3,'APPROVAL','ACTIVE','2014-11-27 00:34:29',0,'','',''),(1254,1,0,100,'REGO','',3,'NEW','PLAYER','PROFESSIONAL','FOOTBALL','MINOR',100,3,'APPROVAL','ACTIVE','2014-11-27 00:34:29',0,'','',''),(1256,1,0,100,'REGO','',3,'NEW','PLAYER','AMATEUR_U_C','FOOTBALL','MINOR',100,3,'APPROVAL','ACTIVE','2014-11-27 00:34:29',0,'','',''),(1258,1,0,100,'REGO','',3,'RENEWAL','PLAYER','AMATEUR_U_C','FOOTBALL','MINOR',100,3,'APPROVAL','ACTIVE','2014-11-27 00:34:29',0,'','',''),(1260,1,0,100,'REGO','',3,'TRANSFER','PLAYER','AMATEUR','FOOTBALL','MINOR',100,3,'APPROVAL','ACTIVE','2014-11-27 00:34:29',0,'','',''),(1262,1,0,100,'REGO','',3,'TRANSFER','PLAYER','AMATEUR_U_C','FOOTBALL','MINOR',100,3,'APPROVAL','ACTIVE','2014-11-27 00:34:29',0,'','',''),(1264,1,0,100,'REGO','',3,'TRANSFER','PLAYER','PROFESSIONAL','FOOTBALL','MINOR',100,3,'APPROVAL','ACTIVE','2014-11-27 00:34:29',0,'','',''),(1312,1,0,100,'REGO','',100,'RENEWAL','PLAYER','AMATEUR','FOOTBALL','MINOR',100,100,'APPROVAL','ACTIVE','2014-11-27 00:34:40',0,'','',''),(1314,1,0,100,'REGO','',100,'RENEWAL','PLAYER','PROFESSIONAL','FOOTBALL','MINOR',100,100,'APPROVAL','ACTIVE','2014-11-27 00:34:40',0,'','',''),(1316,1,0,100,'REGO','',100,'NEW','PLAYER','AMATEUR','FOOTBALL','MINOR',100,100,'APPROVAL','ACTIVE','2014-11-27 00:34:40',0,'','',''),(1318,1,0,100,'REGO','',100,'NEW','PLAYER','PROFESSIONAL','FOOTBALL','MINOR',100,100,'APPROVAL','ACTIVE','2014-11-27 00:34:40',0,'','',''),(1320,1,0,100,'REGO','',100,'NEW','PLAYER','AMATEUR_U_C','FOOTBALL','MINOR',100,100,'APPROVAL','ACTIVE','2014-11-27 00:34:40',0,'','',''),(1322,1,0,100,'REGO','',100,'RENEWAL','PLAYER','AMATEUR_U_C','FOOTBALL','MINOR',100,100,'APPROVAL','ACTIVE','2014-11-27 00:34:40',0,'','',''),(1324,1,0,100,'REGO','',100,'TRANSFER','PLAYER','AMATEUR','FOOTBALL','MINOR',100,100,'APPROVAL','ACTIVE','2014-11-27 00:34:40',0,'','',''),(1326,1,0,100,'REGO','',100,'TRANSFER','PLAYER','AMATEUR_U_C','FOOTBALL','MINOR',100,100,'APPROVAL','ACTIVE','2014-11-27 00:34:40',0,'','',''),(1328,1,0,100,'REGO','',100,'TRANSFER','PLAYER','PROFESSIONAL','FOOTBALL','MINOR',100,100,'APPROVAL','ACTIVE','2014-11-27 00:34:40',0,'','',''),(1356,1,0,3,'REGO','',3,'RENEWAL','PLAYER','AMATEUR','FOOTBALL','ADULT',100,3,'APPROVAL','ACTIVE','2014-11-27 23:32:43',0,'','',''),(1358,1,0,3,'REGO','',3,'RENEWAL','PLAYER','PROFESSIONAL','FOOTBALL','ADULT',100,3,'APPROVAL','ACTIVE','2014-11-27 23:32:43',0,'','',''),(1360,1,0,3,'REGO','',3,'NEW','PLAYER','AMATEUR','FOOTBALL','ADULT',100,3,'APPROVAL','ACTIVE','2014-11-27 23:32:43',0,'','',''),(1362,1,0,3,'REGO','',3,'NEW','PLAYER','PROFESSIONAL','FOOTBALL','ADULT',100,3,'APPROVAL','ACTIVE','2014-11-27 23:32:43',0,'','',''),(1364,1,0,3,'REGO','',3,'NEW','PLAYER','AMATEUR_U_C','FOOTBALL','ADULT',100,3,'APPROVAL','ACTIVE','2014-11-27 23:32:43',0,'','',''),(1366,1,0,3,'REGO','',3,'RENEWAL','PLAYER','AMATEUR_U_C','FOOTBALL','ADULT',100,3,'APPROVAL','ACTIVE','2014-11-27 23:32:43',0,'','',''),(1368,1,0,3,'REGO','',3,'TRANSFER','PLAYER','AMATEUR','FOOTBALL','ADULT',100,3,'APPROVAL','ACTIVE','2014-11-27 23:32:43',0,'','',''),(1370,1,0,3,'REGO','',3,'TRANSFER','PLAYER','AMATEUR_U_C','FOOTBALL','ADULT',100,3,'APPROVAL','ACTIVE','2014-11-27 23:32:43',0,'','',''),(1372,1,0,3,'REGO','',3,'TRANSFER','PLAYER','PROFESSIONAL','FOOTBALL','ADULT',100,3,'APPROVAL','ACTIVE','2014-11-27 23:32:43',0,'','',''),(1374,1,0,100,'REGO','',3,'RENEWAL','PLAYER','AMATEUR','FOOTBALL','ADULT',100,3,'APPROVAL','ACTIVE','2014-11-27 23:32:43',0,'','',''),(1376,1,0,100,'REGO','',3,'RENEWAL','PLAYER','PROFESSIONAL','FOOTBALL','ADULT',100,3,'APPROVAL','ACTIVE','2014-11-27 23:32:43',0,'','',''),(1378,1,0,100,'REGO','',3,'NEW','PLAYER','AMATEUR','FOOTBALL','ADULT',100,3,'APPROVAL','ACTIVE','2014-11-27 23:32:43',0,'','',''),(1380,1,0,100,'REGO','',3,'NEW','PLAYER','PROFESSIONAL','FOOTBALL','ADULT',100,3,'APPROVAL','ACTIVE','2014-11-27 23:32:43',0,'','',''),(1382,1,0,100,'REGO','',3,'NEW','PLAYER','AMATEUR_U_C','FOOTBALL','ADULT',100,3,'APPROVAL','ACTIVE','2014-11-27 23:32:43',0,'','',''),(1384,1,0,100,'REGO','',3,'RENEWAL','PLAYER','AMATEUR_U_C','FOOTBALL','ADULT',100,3,'APPROVAL','ACTIVE','2014-11-27 23:32:43',0,'','',''),(1386,1,0,100,'REGO','',3,'TRANSFER','PLAYER','AMATEUR','FOOTBALL','ADULT',100,3,'APPROVAL','ACTIVE','2014-11-27 23:32:43',0,'','',''),(1388,1,0,100,'REGO','',3,'TRANSFER','PLAYER','AMATEUR_U_C','FOOTBALL','ADULT',100,3,'APPROVAL','ACTIVE','2014-11-27 23:32:43',0,'','',''),(1390,1,0,100,'REGO','',3,'TRANSFER','PLAYER','PROFESSIONAL','FOOTBALL','ADULT',100,3,'APPROVAL','ACTIVE','2014-11-27 23:32:43',0,'','',''),(1392,1,0,100,'REGO','',100,'RENEWAL','PLAYER','AMATEUR','FOOTBALL','ADULT',100,100,'APPROVAL','ACTIVE','2014-11-27 23:32:43',0,'','',''),(1394,1,0,100,'REGO','',100,'RENEWAL','PLAYER','PROFESSIONAL','FOOTBALL','ADULT',100,100,'APPROVAL','ACTIVE','2014-11-27 23:32:43',0,'','',''),(1396,1,0,100,'REGO','',100,'NEW','PLAYER','AMATEUR','FOOTBALL','ADULT',100,100,'APPROVAL','ACTIVE','2014-11-27 23:32:43',0,'','',''),(1398,1,0,100,'REGO','',100,'NEW','PLAYER','PROFESSIONAL','FOOTBALL','ADULT',100,100,'APPROVAL','ACTIVE','2014-11-27 23:32:43',0,'','',''),(1400,1,0,100,'REGO','',100,'NEW','PLAYER','AMATEUR_U_C','FOOTBALL','ADULT',100,100,'APPROVAL','ACTIVE','2014-11-27 23:32:43',0,'','',''),(1402,1,0,100,'REGO','',100,'RENEWAL','PLAYER','AMATEUR_U_C','FOOTBALL','ADULT',100,100,'APPROVAL','ACTIVE','2014-11-27 23:32:43',0,'','',''),(1404,1,0,100,'REGO','',100,'TRANSFER','PLAYER','AMATEUR','FOOTBALL','ADULT',100,100,'APPROVAL','ACTIVE','2014-11-27 23:32:43',0,'','',''),(1406,1,0,100,'REGO','',100,'TRANSFER','PLAYER','AMATEUR_U_C','FOOTBALL','ADULT',100,100,'APPROVAL','ACTIVE','2014-11-27 23:32:43',0,'','',''),(1408,1,0,100,'REGO','',100,'TRANSFER','PLAYER','PROFESSIONAL','FOOTBALL','ADULT',100,100,'APPROVAL','ACTIVE','2014-11-27 23:32:43',0,'','',''),(1420,1,0,100,'ENTITY','',3,'NEW','','','','',100,100,'APPROVAL','ACTIVE','2014-11-28 00:29:31',0,'','',''),(1421,1,0,100,'ENTITY','',3,'RENEWAL','','','','',100,100,'APPROVAL','ACTIVE','2014-11-28 00:30:58',0,'','',''),(1422,1,0,3,'ENTITY','',3,'RENEWAL','','','','',100,100,'APPROVAL','ACTIVE','2014-11-28 00:31:07',0,'','',''),(1423,1,0,3,'REGO','',3,'NEW','COACH','AMATEUR','FOOTBALL','ADULT',100,3,'APPROVAL','ACTIVE','2014-11-27 00:30:11',0,'','',''),(1424,1,0,3,'REGO','',3,'RENEWAL','COACH','AMATEUR','FOOTBALL','ADULT',100,3,'APPROVAL','ACTIVE','2014-11-27 00:30:11',0,'','',''),(1426,1,0,100,'REGO','',3,'NEW','COACH','PROFESSIONAL','FOOTBALL','ADULT',100,3,'APPROVAL','ACTIVE','2014-12-05 00:01:09',0,'','',''),(1427,1,0,100,'REGO','',3,'RENEWAL','COACH','PROFESSIONAL','FOOTBALL','ADULT',100,3,'APPROVAL','ACTIVE','2014-12-05 00:01:09',0,'','',''),(1428,1,0,100,'REGO','',100,'NEW','COACH','PROFESSIONAL','FOOTBALL','ADULT',100,100,'APPROVAL','ACTIVE','2014-12-05 00:01:09',0,'','',''),(1429,1,0,100,'REGO','',100,'RENEWAL','COACH','PROFESSIONAL','FOOTBALL','ADULT',100,100,'APPROVAL','ACTIVE','2014-12-05 00:01:09',0,'','',''),(1433,1,0,100,'REGO','',100,'NEW','REFEREE','','FOOTBALL','MINOR',100,100,'APPROVAL','ACTIVE','2014-12-18 02:57:35',0,'','',''),(1434,1,0,100,'REGO','',100,'RENEWAL','REFEREE','','FOOTBALL','MINOR',100,100,'APPROVAL','ACTIVE','2014-12-18 02:57:35',0,'','',''),(1436,1,0,3,'REGO','',3,'NEW','COACH','PROFESSIONAL','FOOTBALL','MINOR',100,3,'APPROVAL','ACTIVE','2014-12-18 03:02:33',0,'','',''),(1437,1,0,3,'REGO','',3,'RENEWAL','COACH','PROFESSIONAL','FOOTBALL','MINOR',100,3,'APPROVAL','ACTIVE','2014-12-18 03:02:33',0,'','',''),(1438,1,0,100,'REGO','',3,'NEW','COACH','AMATEUR','FOOTBALL','MINOR',100,3,'APPROVAL','ACTIVE','2014-12-18 03:02:33',0,'','',''),(1439,1,0,100,'REGO','',3,'RENEWAL','COACH','AMATEUR','FOOTBALL','MINOR',100,3,'APPROVAL','ACTIVE','2014-12-18 03:02:33',0,'','',''),(1440,1,0,100,'REGO','',100,'NEW','COACH','AMATEUR','FOOTBALL','MINOR',100,100,'APPROVAL','ACTIVE','2014-12-18 03:02:33',0,'','',''),(1441,1,0,100,'REGO','',100,'RENEWAL','COACH','AMATEUR','FOOTBALL','MINOR',100,100,'APPROVAL','ACTIVE','2014-12-18 03:02:33',0,'','',''),(1442,1,0,3,'REGO','',3,'NEW','COACH','AMATEUR','FOOTBALL','MINOR',100,3,'APPROVAL','ACTIVE','2014-12-18 03:02:33',0,'','',''),(1443,1,0,3,'REGO','',3,'RENEWAL','COACH','AMATEUR','FOOTBALL','MINOR',100,3,'APPROVAL','ACTIVE','2014-12-18 03:02:33',0,'','',''),(1444,1,0,100,'REGO','',3,'NEW','COACH','PROFESSIONAL','FOOTBALL','MINOR',100,3,'APPROVAL','ACTIVE','2014-12-18 03:02:33',0,'','',''),(1445,1,0,100,'REGO','',3,'RENEWAL','COACH','PROFESSIONAL','FOOTBALL','MINOR',100,3,'APPROVAL','ACTIVE','2014-12-18 03:02:33',0,'','',''),(1446,1,0,100,'REGO','',100,'NEW','COACH','PROFESSIONAL','FOOTBALL','MINOR',100,100,'APPROVAL','ACTIVE','2014-12-18 03:02:33',0,'','',''),(1447,1,0,100,'REGO','',100,'RENEWAL','COACH','PROFESSIONAL','FOOTBALL','MINOR',100,100,'APPROVAL','ACTIVE','2014-12-18 03:02:33',0,'','',''),(1451,1,0,3,'REGO','',3,'NEW','CLUBOFFICIAL','','FOOTBALL','MINOR',100,3,'APPROVAL','ACTIVE','2014-12-18 03:07:29',0,'','',''),(1452,1,0,100,'REGO','',3,'NEW','CLUBOFFICIAL','','FOOTBALL','MINOR',100,3,'APPROVAL','ACTIVE','2014-12-18 03:07:29',0,'','',''),(1453,1,0,3,'REGO','',3,'RENEWAL','CLUBOFFICIAL','','FOOTBALL','MINOR',100,3,'APPROVAL','ACTIVE','2014-12-18 03:07:29',0,'','',''),(1454,1,0,100,'REGO','',3,'RENEWAL','CLUBOFFICIAL','','FOOTBALL','MINOR',100,3,'APPROVAL','ACTIVE','2014-12-18 03:07:29',0,'','',''),(1455,1,0,100,'REGO','',100,'NEW','CLUBOFFICIAL','','FOOTBALL','MINOR',100,100,'APPROVAL','ACTIVE','2014-12-18 03:07:29',0,'','',''),(1456,1,0,100,'REGO','',100,'RENEWAL','CLUBOFFICIAL','','FOOTBALL','MINOR',100,100,'APPROVAL','ACTIVE','2014-12-18 03:07:29',0,'','',''),(1458,1,0,3,'REGO','',3,'NEW','TEAMOFFICIAL','','FOOTBALL','MINOR',100,3,'APPROVAL','ACTIVE','2014-12-18 03:13:13',0,'','',''),(1459,1,0,100,'REGO','',3,'NEW','TEAMOFFICIAL','','FOOTBALL','MINOR',100,3,'APPROVAL','ACTIVE','2014-12-18 03:13:13',0,'','',''),(1460,1,0,3,'REGO','',3,'RENEWAL','TEAMOFFICIAL','','FOOTBALL','MINOR',100,3,'APPROVAL','ACTIVE','2014-12-18 03:13:13',0,'','',''),(1461,1,0,100,'REGO','',3,'RENEWAL','TEAMOFFICIAL','','FOOTBALL','MINOR',100,3,'APPROVAL','ACTIVE','2014-12-18 03:13:13',0,'','',''),(1462,1,0,100,'REGO','',100,'NEW','TEAMOFFICIAL','','FOOTBALL','MINOR',100,100,'APPROVAL','ACTIVE','2014-12-18 03:13:13',0,'','',''),(1463,1,0,100,'REGO','',100,'RENEWAL','TEAMOFFICIAL','','FOOTBALL','MINOR',100,100,'APPROVAL','ACTIVE','2014-12-18 03:13:13',0,'','',''),(1465,1,0,100,'REGO','',100,'NEW','MAOFFICIAL','','','MINOR',100,100,'APPROVAL','ACTIVE','2014-12-18 03:15:22',0,'','',''),(1466,1,0,100,'REGO','',100,'RENEWAL','MAOFFICIAL','','','MINOR',100,100,'APPROVAL','ACTIVE','2014-12-18 03:15:22',0,'','',''),(1469,1,0,100,'PERSON','',100,'AMENDMENT','','','','',100,100,'APPROVAL','ACTIVE','2014-12-28 22:27:08',0,'','','');
/*!40000 ALTER TABLE `tblWFRule` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblWFRuleDocuments`
--

DROP TABLE IF EXISTS `tblWFRuleDocuments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblWFRuleDocuments` (
  `intWFRuleDocumentID` int(11) NOT NULL AUTO_INCREMENT,
  `intWFRuleID` int(11) NOT NULL COMMENT 'The intApprovalEntityID will also approve/verify the document',
  `intDocumentTypeID` int(11) NOT NULL COMMENT 'To be checked against intDocumentTypeID in tblDocuments',
  `intAllowApprovalEntityAdd` int(11) NOT NULL COMMENT 'Allow Approval Entity to add document',
  `intAllowApprovalEntityVerify` int(11) NOT NULL COMMENT 'Allow Approval Entity to verify document',
  `intAllowProblemResolutionEntityAdd` int(11) NOT NULL COMMENT 'Allow Problem Resolution Entity to add document',
  `intAllowProblemResolutionEntityVerify` int(11) NOT NULL COMMENT 'Allow Problem Resolution Entity to verify document',
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`intWFRuleDocumentID`),
  KEY `KEY` (`intWFRuleID`)
) ENGINE=InnoDB AUTO_INCREMENT=2158 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblWFRuleDocuments`
--

LOCK TABLES `tblWFRuleDocuments` WRITE;
/*!40000 ALTER TABLE `tblWFRuleDocuments` DISABLE KEYS */;
INSERT INTO `tblWFRuleDocuments` VALUES (25,1234,32,1,1,1,0,'2014-11-27 23:51:01'),(27,1236,32,1,1,1,0,'2014-11-27 23:51:01'),(29,1238,32,1,1,1,0,'2014-11-27 23:51:01'),(31,1252,32,1,1,1,0,'2014-11-27 23:51:01'),(33,1254,32,1,1,1,0,'2014-11-27 23:51:01'),(35,1256,32,1,1,1,0,'2014-11-27 23:51:01'),(38,1316,32,1,1,1,0,'2014-11-27 23:51:01'),(40,1318,32,1,1,1,0,'2014-11-27 23:51:01'),(42,1320,32,1,1,1,0,'2014-11-27 23:51:01'),(43,1360,32,1,1,1,0,'2014-11-27 23:51:01'),(45,1362,32,1,1,1,0,'2014-11-27 23:51:01'),(47,1364,32,1,1,1,0,'2014-11-27 23:51:01'),(49,1378,32,1,1,1,0,'2014-11-27 23:51:01'),(51,1380,32,1,1,1,0,'2014-11-27 23:51:01'),(53,1382,32,1,1,1,0,'2014-11-27 23:51:01'),(55,1396,32,1,1,1,0,'2014-11-27 23:51:01'),(57,1398,32,1,1,1,0,'2014-11-27 23:51:01'),(59,1400,32,1,1,1,0,'2014-11-27 23:51:01'),(88,1234,33,1,1,1,0,'2014-11-27 23:51:16'),(90,1236,33,1,1,1,0,'2014-11-27 23:51:16'),(92,1238,33,1,1,1,0,'2014-11-27 23:51:16'),(94,1252,33,1,1,1,0,'2014-11-27 23:51:16'),(96,1254,33,1,1,1,0,'2014-11-27 23:51:16'),(98,1256,33,1,1,1,0,'2014-11-27 23:51:16'),(101,1316,33,1,1,1,0,'2014-11-27 23:51:16'),(103,1318,33,1,1,1,0,'2014-11-27 23:51:16'),(105,1320,33,1,1,1,0,'2014-11-27 23:51:16'),(106,1360,33,1,1,1,0,'2014-11-27 23:51:16'),(108,1362,33,1,1,1,0,'2014-11-27 23:51:16'),(110,1364,33,1,1,1,0,'2014-11-27 23:51:16'),(112,1378,33,1,1,1,0,'2014-11-27 23:51:16'),(114,1380,33,1,1,1,0,'2014-11-27 23:51:16'),(116,1382,33,1,1,1,0,'2014-11-27 23:51:16'),(118,1396,33,1,1,1,0,'2014-11-27 23:51:16'),(120,1398,33,1,1,1,0,'2014-11-27 23:51:16'),(122,1400,33,1,1,1,0,'2014-11-27 23:51:16'),(151,1234,34,1,1,1,0,'2014-11-28 00:05:33'),(153,1236,34,1,1,1,0,'2014-11-28 00:05:33'),(155,1238,34,1,1,1,0,'2014-11-28 00:05:33'),(157,1252,34,1,1,1,0,'2014-11-28 00:05:33'),(159,1254,34,1,1,1,0,'2014-11-28 00:05:33'),(161,1256,34,1,1,1,0,'2014-11-28 00:05:33'),(164,1316,34,1,1,1,0,'2014-11-28 00:05:33'),(166,1318,34,1,1,1,0,'2014-11-28 00:05:33'),(168,1320,34,1,1,1,0,'2014-11-28 00:05:33'),(169,1360,34,1,1,1,0,'2014-11-28 00:05:33'),(171,1362,34,1,1,1,0,'2014-11-28 00:05:33'),(173,1364,34,1,1,1,0,'2014-11-28 00:05:33'),(175,1378,34,1,1,1,0,'2014-11-28 00:05:33'),(177,1380,34,1,1,1,0,'2014-11-28 00:05:33'),(179,1382,34,1,1,1,0,'2014-11-28 00:05:33'),(181,1396,34,1,1,1,0,'2014-11-28 00:05:33'),(183,1398,34,1,1,1,0,'2014-11-28 00:05:33'),(185,1400,34,1,1,1,0,'2014-11-28 00:05:33'),(214,1234,35,1,1,1,0,'2014-11-28 00:05:43'),(216,1236,35,1,1,1,0,'2014-11-28 00:05:43'),(218,1238,35,1,1,1,0,'2014-11-28 00:05:43'),(220,1252,35,1,1,1,0,'2014-11-28 00:05:43'),(222,1254,35,1,1,1,0,'2014-11-28 00:05:43'),(224,1256,35,1,1,1,0,'2014-11-28 00:05:43'),(227,1316,35,1,1,1,0,'2014-11-28 00:05:43'),(229,1318,35,1,1,1,0,'2014-11-28 00:05:43'),(231,1320,35,1,1,1,0,'2014-11-28 00:05:43'),(232,1360,35,1,1,1,0,'2014-11-28 00:05:43'),(234,1362,35,1,1,1,0,'2014-11-28 00:05:43'),(236,1364,35,1,1,1,0,'2014-11-28 00:05:43'),(238,1378,35,1,1,1,0,'2014-11-28 00:05:43'),(240,1380,35,1,1,1,0,'2014-11-28 00:05:43'),(242,1382,35,1,1,1,0,'2014-11-28 00:05:43'),(244,1396,35,1,1,1,0,'2014-11-28 00:05:43'),(246,1398,35,1,1,1,0,'2014-11-28 00:05:43'),(248,1400,35,1,1,1,0,'2014-11-28 00:05:43'),(277,1234,36,1,1,1,0,'2014-11-28 00:05:43'),(279,1236,36,1,1,1,0,'2014-11-28 00:05:43'),(281,1238,36,1,1,1,0,'2014-11-28 00:05:43'),(283,1252,36,1,1,1,0,'2014-11-28 00:05:43'),(285,1254,36,1,1,1,0,'2014-11-28 00:05:43'),(287,1256,36,1,1,1,0,'2014-11-28 00:05:43'),(290,1316,36,1,1,1,0,'2014-11-28 00:05:43'),(292,1318,36,1,1,1,0,'2014-11-28 00:05:43'),(294,1320,36,1,1,1,0,'2014-11-28 00:05:43'),(295,1360,36,1,1,1,0,'2014-11-28 00:05:43'),(297,1362,36,1,1,1,0,'2014-11-28 00:05:43'),(299,1364,36,1,1,1,0,'2014-11-28 00:05:43'),(301,1378,36,1,1,1,0,'2014-11-28 00:05:43'),(303,1380,36,1,1,1,0,'2014-11-28 00:05:43'),(305,1382,36,1,1,1,0,'2014-11-28 00:05:43'),(307,1396,36,1,1,1,0,'2014-11-28 00:05:43'),(309,1398,36,1,1,1,0,'2014-11-28 00:05:43'),(311,1400,36,1,1,1,0,'2014-11-28 00:05:43'),(340,1234,37,1,1,1,0,'2014-11-28 00:05:43'),(342,1236,37,1,1,1,0,'2014-11-28 00:05:43'),(344,1238,37,1,1,1,0,'2014-11-28 00:05:43'),(346,1252,37,1,1,1,0,'2014-11-28 00:05:43'),(348,1254,37,1,1,1,0,'2014-11-28 00:05:43'),(350,1256,37,1,1,1,0,'2014-11-28 00:05:43'),(353,1316,37,1,1,1,0,'2014-11-28 00:05:43'),(355,1318,37,1,1,1,0,'2014-11-28 00:05:43'),(357,1320,37,1,1,1,0,'2014-11-28 00:05:43'),(371,1236,38,1,1,1,0,'2014-11-28 00:05:43'),(373,1238,38,1,1,1,0,'2014-11-28 00:05:43'),(375,1254,38,1,1,1,0,'2014-11-28 00:05:43'),(377,1256,38,1,1,1,0,'2014-11-28 00:05:43'),(380,1318,38,1,1,1,0,'2014-11-28 00:05:43'),(382,1320,38,1,1,1,0,'2014-11-28 00:05:43'),(383,1362,38,1,1,1,0,'2014-11-28 00:05:43'),(385,1364,38,1,1,1,0,'2014-11-28 00:05:43'),(387,1380,38,1,1,1,0,'2014-11-28 00:05:43'),(389,1382,38,1,1,1,0,'2014-11-28 00:05:43'),(391,1398,38,1,1,1,0,'2014-11-28 00:05:43'),(393,1400,38,1,1,1,0,'2014-11-28 00:05:43'),(402,1236,39,1,1,1,0,'2014-11-28 00:05:43'),(404,1238,39,1,1,1,0,'2014-11-28 00:05:43'),(406,1254,39,1,1,1,0,'2014-11-28 00:05:43'),(408,1256,39,1,1,1,0,'2014-11-28 00:05:43'),(411,1318,39,1,1,1,0,'2014-11-28 00:05:43'),(413,1320,39,1,1,1,0,'2014-11-28 00:05:43'),(414,1362,39,1,1,1,0,'2014-11-28 00:05:43'),(416,1364,39,1,1,1,0,'2014-11-28 00:05:43'),(418,1380,39,1,1,1,0,'2014-11-28 00:05:43'),(420,1382,39,1,1,1,0,'2014-11-28 00:05:43'),(422,1398,39,1,1,1,0,'2014-11-28 00:05:43'),(424,1400,39,1,1,1,0,'2014-11-28 00:05:43'),(433,-1234,-40,1,1,1,0,'2014-11-28 00:05:44'),(435,-1236,-40,1,1,1,0,'2014-11-28 00:05:44'),(437,-1238,-40,1,1,1,0,'2014-11-28 00:05:44'),(439,-1252,-40,1,1,1,0,'2014-11-28 00:05:44'),(441,-1254,-40,1,1,1,0,'2014-11-28 00:05:44'),(443,-1256,-40,1,1,1,0,'2014-11-28 00:05:44'),(446,-1316,-40,1,1,1,0,'2014-11-28 00:05:44'),(448,-1318,-40,1,1,1,0,'2014-11-28 00:05:44'),(450,-1320,-40,1,1,1,0,'2014-11-28 00:05:44'),(451,-1360,-40,1,1,1,0,'2014-11-28 00:05:44'),(453,-1362,-40,1,1,1,0,'2014-11-28 00:05:44'),(455,-1364,-40,1,1,1,0,'2014-11-28 00:05:44'),(457,-1378,-40,1,1,1,0,'2014-11-28 00:05:44'),(459,-1380,-40,1,1,1,0,'2014-11-28 00:05:44'),(461,-1382,-40,1,1,1,0,'2014-11-28 00:05:44'),(463,-1396,-40,1,1,1,0,'2014-11-28 00:05:44'),(465,-1398,-40,1,1,1,0,'2014-11-28 00:05:44'),(467,-1400,-40,1,1,1,0,'2014-11-28 00:05:44'),(496,1234,41,1,1,1,0,'2014-11-28 00:05:44'),(498,1236,41,1,1,1,0,'2014-11-28 00:05:44'),(500,1238,41,1,1,1,0,'2014-11-28 00:05:44'),(502,1252,41,1,1,1,0,'2014-11-28 00:05:44'),(504,1254,41,1,1,1,0,'2014-11-28 00:05:44'),(506,1256,41,1,1,1,0,'2014-11-28 00:05:44'),(509,1316,41,1,1,1,0,'2014-11-28 00:05:44'),(511,1318,41,1,1,1,0,'2014-11-28 00:05:44'),(513,1320,41,1,1,1,0,'2014-11-28 00:05:44'),(514,1360,41,1,1,1,0,'2014-11-28 00:05:44'),(516,1362,41,1,1,1,0,'2014-11-28 00:05:44'),(518,1364,41,1,1,1,0,'2014-11-28 00:05:44'),(520,1378,41,1,1,1,0,'2014-11-28 00:05:44'),(522,1380,41,1,1,1,0,'2014-11-28 00:05:44'),(524,1382,41,1,1,1,0,'2014-11-28 00:05:44'),(526,1396,41,1,1,1,0,'2014-11-28 00:05:44'),(528,1398,41,1,1,1,0,'2014-11-28 00:05:44'),(530,1400,41,1,1,1,0,'2014-11-28 00:05:44'),(559,1234,42,1,1,1,0,'2014-11-28 00:05:46'),(561,1236,42,1,1,1,0,'2014-11-28 00:05:46'),(563,1238,42,1,1,1,0,'2014-11-28 00:05:46'),(565,1252,42,1,1,1,0,'2014-11-28 00:05:46'),(567,1254,42,1,1,1,0,'2014-11-28 00:05:46'),(569,1256,42,1,1,1,0,'2014-11-28 00:05:46'),(572,1316,42,1,1,1,0,'2014-11-28 00:05:46'),(574,1318,42,1,1,1,0,'2014-11-28 00:05:46'),(576,1320,42,1,1,1,0,'2014-11-28 00:05:46'),(577,1360,42,1,1,1,0,'2014-11-28 00:05:46'),(579,1362,42,1,1,1,0,'2014-11-28 00:05:46'),(581,1364,42,1,1,1,0,'2014-11-28 00:05:46'),(583,1378,42,1,1,1,0,'2014-11-28 00:05:46'),(585,1380,42,1,1,1,0,'2014-11-28 00:05:46'),(587,1382,42,1,1,1,0,'2014-11-28 00:05:46'),(589,1396,42,1,1,1,0,'2014-11-28 00:05:46'),(591,1398,42,1,1,1,0,'2014-11-28 00:05:46'),(593,1400,42,1,1,1,0,'2014-11-28 00:05:46'),(622,1200,32,1,1,1,0,'2014-11-28 00:08:21'),(624,1204,32,1,1,1,0,'2014-11-28 00:08:21'),(627,1220,32,1,1,1,0,'2014-11-28 00:08:21'),(629,1200,33,1,1,1,0,'2014-11-28 00:08:21'),(631,1204,33,1,1,1,0,'2014-11-28 00:08:21'),(634,1220,33,1,1,1,0,'2014-11-28 00:08:21'),(636,1200,34,1,1,1,0,'2014-11-28 00:08:21'),(638,1204,34,1,1,1,0,'2014-11-28 00:08:21'),(641,1220,34,1,1,1,0,'2014-11-28 00:08:21'),(643,1200,35,1,1,1,0,'2014-11-28 00:08:21'),(645,1204,35,1,1,1,0,'2014-11-28 00:08:21'),(648,1220,35,1,1,1,0,'2014-11-28 00:08:21'),(650,1200,36,1,1,1,0,'2014-11-28 00:08:21'),(652,1204,36,1,1,1,0,'2014-11-28 00:08:21'),(655,1220,36,1,1,1,0,'2014-11-28 00:08:21'),(657,1200,43,1,1,1,0,'2014-11-28 00:08:21'),(659,1204,43,1,1,1,0,'2014-11-28 00:08:21'),(662,1220,43,1,1,1,0,'2014-11-28 00:08:21'),(664,1200,44,1,1,1,0,'2014-11-28 00:08:21'),(666,1204,44,1,1,1,0,'2014-11-28 00:08:21'),(669,1220,44,1,1,1,0,'2014-11-28 00:08:21'),(671,1200,45,1,1,1,0,'2014-11-28 00:08:22'),(673,1204,45,1,1,1,0,'2014-11-28 00:08:22'),(676,1220,45,1,1,1,0,'2014-11-28 00:08:22'),(678,1147,32,1,1,1,0,'2014-11-28 00:11:59'),(679,1147,33,1,1,1,0,'2014-11-28 00:11:59'),(680,1147,34,1,1,1,0,'2014-11-28 00:11:59'),(681,1147,35,1,1,1,0,'2014-11-28 00:11:59'),(682,1147,36,1,1,1,0,'2014-11-28 00:11:59'),(683,1147,46,1,1,1,0,'2014-11-28 00:11:59'),(685,1147,48,1,1,1,0,'2014-11-28 00:11:59'),(686,1147,49,1,1,1,0,'2014-11-28 00:11:59'),(687,1147,50,1,1,1,0,'2014-11-28 00:11:59'),(688,1149,32,1,1,1,0,'2014-11-28 00:19:16'),(689,1149,33,1,1,1,0,'2014-11-28 00:19:16'),(690,1149,34,1,1,1,0,'2014-11-28 00:19:16'),(691,1149,35,1,1,1,0,'2014-11-28 00:19:16'),(692,1149,36,1,1,1,0,'2014-11-28 00:19:16'),(693,1149,52,1,1,1,0,'2014-11-28 00:19:16'),(694,1186,32,1,1,1,0,'2014-11-28 00:19:16'),(695,1187,32,1,1,1,0,'2014-11-28 00:19:16'),(696,1194,32,1,1,1,0,'2014-11-28 00:19:16'),(697,1186,33,1,1,1,0,'2014-11-28 00:19:16'),(698,1187,33,1,1,1,0,'2014-11-28 00:19:16'),(699,1194,33,1,1,1,0,'2014-11-28 00:19:16'),(700,1186,34,1,1,1,0,'2014-11-28 00:19:16'),(701,1187,34,1,1,1,0,'2014-11-28 00:19:16'),(702,1194,34,1,1,1,0,'2014-11-28 00:19:16'),(703,1186,35,1,1,1,0,'2014-11-28 00:19:16'),(704,1187,35,1,1,1,0,'2014-11-28 00:19:16'),(705,1194,35,1,1,1,0,'2014-11-28 00:19:16'),(706,1186,36,1,1,1,0,'2014-11-28 00:19:16'),(707,1187,36,1,1,1,0,'2014-11-28 00:19:16'),(708,1194,36,1,1,1,0,'2014-11-28 00:19:16'),(709,1186,52,1,1,1,0,'2014-11-28 00:19:16'),(710,1187,52,1,1,1,0,'2014-11-28 00:19:16'),(711,1194,52,1,1,1,0,'2014-11-28 00:19:16'),(712,1172,32,1,1,1,0,'2014-11-28 00:19:16'),(713,1173,32,1,1,1,0,'2014-11-28 00:19:16'),(714,1180,32,1,1,1,0,'2014-11-28 00:19:16'),(715,1172,33,1,1,1,0,'2014-11-28 00:19:16'),(716,1173,33,1,1,1,0,'2014-11-28 00:19:16'),(717,1180,33,1,1,1,0,'2014-11-28 00:19:16'),(718,1172,34,1,1,1,0,'2014-11-28 00:19:16'),(719,1173,34,1,1,1,0,'2014-11-28 00:19:16'),(720,1180,34,1,1,1,0,'2014-11-28 00:19:16'),(721,1172,35,1,1,1,0,'2014-11-28 00:19:16'),(722,1173,35,1,1,1,0,'2014-11-28 00:19:16'),(723,1180,35,1,1,1,0,'2014-11-28 00:19:16'),(724,1172,36,1,1,1,0,'2014-11-28 00:19:16'),(725,1173,36,1,1,1,0,'2014-11-28 00:19:16'),(726,1180,36,1,1,1,0,'2014-11-28 00:19:16'),(727,1172,52,1,1,1,0,'2014-11-28 00:19:18'),(728,1173,52,1,1,1,0,'2014-11-28 00:19:18'),(729,1180,52,1,1,1,0,'2014-11-28 00:19:18'),(730,1200,37,1,1,1,0,'2014-11-28 00:20:23'),(732,1204,37,1,1,1,0,'2014-11-28 00:20:23'),(735,1220,37,1,1,1,0,'2014-11-28 00:20:23'),(737,1147,37,1,1,1,0,'2014-11-28 00:20:33'),(738,1149,37,1,1,1,0,'2014-11-28 00:20:39'),(739,1186,37,1,1,1,0,'2014-11-28 00:20:44'),(740,1187,37,1,1,1,0,'2014-11-28 00:20:44'),(741,1194,37,1,1,1,0,'2014-11-28 00:20:44'),(742,1172,37,1,1,1,0,'2014-11-28 00:20:51'),(743,1173,37,1,1,1,0,'2014-11-28 00:20:51'),(744,1180,37,1,1,1,0,'2014-11-28 00:20:51'),(745,1147,62,1,1,1,0,'2014-11-28 00:21:20'),(746,1186,51,1,1,1,0,'2014-11-28 00:26:22'),(747,1187,51,1,1,1,0,'2014-11-28 00:26:22'),(748,1194,51,1,1,1,0,'2014-11-28 00:26:22'),(749,1420,54,1,1,1,0,'2014-11-28 00:39:07'),(750,1421,54,1,1,1,0,'2014-11-28 00:39:07'),(751,1422,54,1,1,1,0,'2014-11-28 00:39:07'),(752,1420,55,1,1,1,0,'2014-11-28 00:39:07'),(753,1421,55,1,1,1,0,'2014-11-28 00:39:07'),(754,1422,55,1,1,1,0,'2014-11-28 00:39:07'),(755,1420,56,1,1,1,0,'2014-11-28 00:39:07'),(756,1420,57,1,1,1,0,'2014-11-28 00:39:07'),(757,1421,57,1,1,1,0,'2014-11-28 00:39:07'),(758,1422,57,1,1,1,0,'2014-11-28 00:39:07'),(760,1420,59,1,1,1,0,'2014-11-28 00:39:07'),(761,1420,60,1,1,1,0,'2014-11-28 00:39:07'),(762,1420,61,1,1,1,0,'2014-11-28 00:39:09'),(763,1420,53,1,1,1,0,'2014-11-28 00:39:15'),(764,1423,32,1,1,1,0,'2014-11-28 00:08:21'),(765,1423,33,1,1,1,0,'2014-11-28 00:08:21'),(766,1423,34,1,1,1,0,'2014-11-28 00:08:21'),(767,1423,35,1,1,1,0,'2014-11-28 00:08:21'),(768,1423,36,1,1,1,0,'2014-11-28 00:08:21'),(769,1423,43,1,1,1,0,'2014-11-28 00:08:21'),(770,1423,44,1,1,1,0,'2014-11-28 00:08:21'),(771,1423,45,1,1,1,0,'2014-11-28 00:08:22'),(772,1423,37,1,1,1,0,'2014-11-28 00:20:23'),(781,1426,32,1,1,1,0,'2014-12-05 00:02:12'),(782,1426,33,1,1,1,0,'2014-12-05 00:02:12'),(783,1426,34,1,1,1,0,'2014-12-05 00:02:12'),(784,1426,35,1,1,1,0,'2014-12-05 00:02:12'),(785,1426,36,1,1,1,0,'2014-12-05 00:02:12'),(786,1426,43,1,1,1,0,'2014-12-05 00:02:12'),(787,1426,44,1,1,1,0,'2014-12-05 00:02:12'),(788,1426,45,1,1,1,0,'2014-12-05 00:02:12'),(789,1426,37,1,1,1,0,'2014-12-05 00:02:12'),(796,1428,32,1,1,1,0,'2014-12-05 00:02:39'),(797,1428,33,1,1,1,0,'2014-12-05 00:02:39'),(798,1428,34,1,1,1,0,'2014-12-05 00:02:39'),(799,1428,35,1,1,1,0,'2014-12-05 00:02:39'),(800,1428,36,1,1,1,0,'2014-12-05 00:02:39'),(801,1428,43,1,1,1,0,'2014-12-05 00:02:39'),(802,1428,44,1,1,1,0,'2014-12-05 00:02:39'),(803,1428,45,1,1,1,0,'2014-12-05 00:02:39'),(804,1428,37,1,1,1,0,'2014-12-05 00:02:39'),(811,1429,32,1,1,1,0,'2014-12-05 00:03:19'),(812,1429,33,1,1,1,0,'2014-12-05 00:03:19'),(813,1429,34,1,1,1,0,'2014-12-05 00:03:19'),(814,1429,35,1,1,1,0,'2014-12-05 00:03:19'),(815,1429,36,1,1,1,0,'2014-12-05 00:03:19'),(816,1429,43,1,1,1,0,'2014-12-05 00:03:19'),(817,1429,44,1,1,1,0,'2014-12-05 00:03:19'),(818,1429,45,1,1,1,0,'2014-12-05 00:03:19'),(819,1429,37,1,1,1,0,'2014-12-05 00:03:19'),(826,1222,32,1,1,1,0,'2014-12-05 00:03:28'),(827,1222,33,1,1,1,0,'2014-12-05 00:03:28'),(828,1222,34,1,1,1,0,'2014-12-05 00:03:28'),(829,1222,35,1,1,1,0,'2014-12-05 00:03:28'),(830,1222,36,1,1,1,0,'2014-12-05 00:03:28'),(831,1222,43,1,1,1,0,'2014-12-05 00:03:28'),(832,1222,44,1,1,1,0,'2014-12-05 00:03:28'),(833,1222,45,1,1,1,0,'2014-12-05 00:03:28'),(834,1222,37,1,1,1,0,'2014-12-05 00:03:28'),(841,1242,32,1,1,1,0,'2014-12-16 20:57:07'),(842,1242,33,1,1,1,0,'2014-12-16 20:57:07'),(843,1242,34,1,1,1,0,'2014-12-16 20:57:07'),(844,1242,35,1,1,1,0,'2014-12-16 20:57:07'),(845,1242,36,1,1,1,0,'2014-12-16 20:57:07'),(846,1242,37,1,1,1,0,'2014-12-16 20:57:07'),(847,-1242,40,1,1,1,0,'2014-12-16 20:57:07'),(848,1242,41,1,1,1,0,'2014-12-16 20:57:07'),(849,1242,42,1,1,1,0,'2014-12-16 20:57:07'),(856,1246,32,1,1,1,0,'2014-12-16 20:57:07'),(857,1246,33,1,1,1,0,'2014-12-16 20:57:07'),(858,1246,34,1,1,1,0,'2014-12-16 20:57:07'),(859,1246,35,1,1,1,0,'2014-12-16 20:57:07'),(860,1246,36,1,1,1,0,'2014-12-16 20:57:07'),(861,1246,37,1,1,1,0,'2014-12-16 20:57:07'),(862,1246,38,1,1,1,0,'2014-12-16 20:57:07'),(863,1246,39,1,1,1,0,'2014-12-16 20:57:07'),(864,-1246,40,1,1,1,0,'2014-12-16 20:57:07'),(865,1246,41,1,1,1,0,'2014-12-16 20:57:07'),(866,1246,42,1,1,1,0,'2014-12-16 20:57:07'),(871,1244,32,1,1,1,0,'2014-12-16 20:57:07'),(872,1244,33,1,1,1,0,'2014-12-16 20:57:07'),(873,1244,34,1,1,1,0,'2014-12-16 20:57:07'),(874,1244,35,1,1,1,0,'2014-12-16 20:57:07'),(875,1244,36,1,1,1,0,'2014-12-16 20:57:07'),(876,1244,37,1,1,1,0,'2014-12-16 20:57:07'),(877,1244,38,1,1,1,0,'2014-12-16 20:57:07'),(878,1244,39,1,1,1,0,'2014-12-16 20:57:07'),(879,-1244,40,1,1,1,0,'2014-12-16 20:57:07'),(880,1244,41,1,1,1,0,'2014-12-16 20:57:07'),(881,1244,42,1,1,1,0,'2014-12-16 20:57:07'),(886,1368,32,1,1,1,0,'2014-12-16 20:57:07'),(887,1368,33,1,1,1,0,'2014-12-16 20:57:07'),(888,1368,34,1,1,1,0,'2014-12-16 20:57:07'),(889,1368,35,1,1,1,0,'2014-12-16 20:57:07'),(890,1368,36,1,1,1,0,'2014-12-16 20:57:07'),(891,-1368,40,1,1,1,0,'2014-12-16 20:57:07'),(892,1368,41,1,1,1,0,'2014-12-16 20:57:07'),(893,1368,42,1,1,1,0,'2014-12-16 20:57:07'),(901,1372,32,1,1,1,0,'2014-12-16 20:57:07'),(902,1372,33,1,1,1,0,'2014-12-16 20:57:07'),(903,1372,34,1,1,1,0,'2014-12-16 20:57:07'),(904,1372,35,1,1,1,0,'2014-12-16 20:57:07'),(905,1372,36,1,1,1,0,'2014-12-16 20:57:07'),(906,1372,38,1,1,1,0,'2014-12-16 20:57:07'),(907,1372,39,1,1,1,0,'2014-12-16 20:57:07'),(908,-1372,40,1,1,1,0,'2014-12-16 20:57:07'),(909,1372,41,1,1,1,0,'2014-12-16 20:57:07'),(910,1372,42,1,1,1,0,'2014-12-16 20:57:07'),(916,1370,32,1,1,1,0,'2014-12-16 20:57:07'),(917,1370,33,1,1,1,0,'2014-12-16 20:57:07'),(918,1370,34,1,1,1,0,'2014-12-16 20:57:07'),(919,1370,35,1,1,1,0,'2014-12-16 20:57:07'),(920,1370,36,1,1,1,0,'2014-12-16 20:57:07'),(921,1370,38,1,1,1,0,'2014-12-16 20:57:07'),(922,1370,39,1,1,1,0,'2014-12-16 20:57:07'),(923,-1370,40,1,1,1,0,'2014-12-16 20:57:07'),(924,1370,41,1,1,1,0,'2014-12-16 20:57:07'),(925,1370,42,1,1,1,0,'2014-12-16 20:57:07'),(931,1260,32,1,1,1,0,'2014-12-17 06:06:34'),(932,1260,33,1,1,1,0,'2014-12-17 06:06:34'),(933,1260,34,1,1,1,0,'2014-12-17 06:06:34'),(934,1260,35,1,1,1,0,'2014-12-17 06:06:34'),(935,1260,36,1,1,1,0,'2014-12-17 06:06:34'),(936,1260,37,1,1,1,0,'2014-12-17 06:06:34'),(937,-1260,40,1,1,1,0,'2014-12-17 06:06:34'),(938,1260,41,1,1,1,0,'2014-12-17 06:06:34'),(939,1260,42,1,1,1,0,'2014-12-17 06:06:34'),(946,1264,32,1,1,1,0,'2014-12-17 06:06:34'),(947,1264,33,1,1,1,0,'2014-12-17 06:06:34'),(948,1264,34,1,1,1,0,'2014-12-17 06:06:34'),(949,1264,35,1,1,1,0,'2014-12-17 06:06:34'),(950,1264,36,1,1,1,0,'2014-12-17 06:06:34'),(951,1264,37,1,1,1,0,'2014-12-17 06:06:34'),(952,1264,38,1,1,1,0,'2014-12-17 06:06:34'),(953,1264,39,1,1,1,0,'2014-12-17 06:06:34'),(954,-1264,40,1,1,1,0,'2014-12-17 06:06:34'),(955,1264,41,1,1,1,0,'2014-12-17 06:06:34'),(956,1264,42,1,1,1,0,'2014-12-17 06:06:34'),(961,1262,32,1,1,1,0,'2014-12-17 06:06:34'),(962,1262,33,1,1,1,0,'2014-12-17 06:06:34'),(963,1262,34,1,1,1,0,'2014-12-17 06:06:34'),(964,1262,35,1,1,1,0,'2014-12-17 06:06:34'),(965,1262,36,1,1,1,0,'2014-12-17 06:06:34'),(966,1262,37,1,1,1,0,'2014-12-17 06:06:34'),(967,1262,38,1,1,1,0,'2014-12-17 06:06:34'),(968,1262,39,1,1,1,0,'2014-12-17 06:06:34'),(969,-1262,40,1,1,1,0,'2014-12-17 06:06:34'),(970,1262,41,1,1,1,0,'2014-12-17 06:06:34'),(971,1262,42,1,1,1,0,'2014-12-17 06:06:34'),(976,1386,32,1,1,1,0,'2014-12-17 06:06:34'),(977,1386,33,1,1,1,0,'2014-12-17 06:06:34'),(978,1386,34,1,1,1,0,'2014-12-17 06:06:34'),(979,1386,35,1,1,1,0,'2014-12-17 06:06:34'),(980,1386,36,1,1,1,0,'2014-12-17 06:06:34'),(981,-1386,40,1,1,1,0,'2014-12-17 06:06:34'),(982,1386,41,1,1,1,0,'2014-12-17 06:06:34'),(983,1386,42,1,1,1,0,'2014-12-17 06:06:34'),(991,1390,32,1,1,1,0,'2014-12-17 06:06:34'),(992,1390,33,1,1,1,0,'2014-12-17 06:06:34'),(993,1390,34,1,1,1,0,'2014-12-17 06:06:34'),(994,1390,35,1,1,1,0,'2014-12-17 06:06:34'),(995,1390,36,1,1,1,0,'2014-12-17 06:06:34'),(996,1390,38,1,1,1,0,'2014-12-17 06:06:34'),(997,1390,39,1,1,1,0,'2014-12-17 06:06:34'),(998,-1390,40,1,1,1,0,'2014-12-17 06:06:34'),(999,1390,41,1,1,1,0,'2014-12-17 06:06:34'),(1000,1390,42,1,1,1,0,'2014-12-17 06:06:34'),(1006,1388,32,1,1,1,0,'2014-12-17 06:06:36'),(1007,1388,33,1,1,1,0,'2014-12-17 06:06:36'),(1008,1388,34,1,1,1,0,'2014-12-17 06:06:36'),(1009,1388,35,1,1,1,0,'2014-12-17 06:06:36'),(1010,1388,36,1,1,1,0,'2014-12-17 06:06:36'),(1011,1388,38,1,1,1,0,'2014-12-17 06:06:36'),(1012,1388,39,1,1,1,0,'2014-12-17 06:06:36'),(1013,-1388,40,1,1,1,0,'2014-12-17 06:06:36'),(1014,1388,41,1,1,1,0,'2014-12-17 06:06:36'),(1015,1388,42,1,1,1,0,'2014-12-17 06:06:36'),(1021,1150,32,1,1,1,0,'2014-12-17 09:06:18'),(1022,1150,33,1,1,1,0,'2014-12-17 09:06:18'),(1023,1150,34,1,1,1,0,'2014-12-17 09:06:18'),(1024,1150,35,1,1,1,0,'2014-12-17 09:06:18'),(1025,1150,36,1,1,1,0,'2014-12-17 09:06:18'),(1026,1150,52,1,1,1,0,'2014-12-17 09:06:18'),(1027,1150,37,1,1,1,0,'2014-12-17 09:06:18'),(1036,1174,32,1,1,1,0,'2014-12-17 09:06:18'),(1037,1174,33,1,1,1,0,'2014-12-17 09:06:18'),(1038,1174,34,1,1,1,0,'2014-12-17 09:06:18'),(1039,1174,35,1,1,1,0,'2014-12-17 09:06:18'),(1040,1174,36,1,1,1,0,'2014-12-17 09:06:18'),(1041,1174,52,1,1,1,0,'2014-12-17 09:06:18'),(1042,1174,37,1,1,1,0,'2014-12-17 09:06:18'),(1043,1175,32,1,1,1,0,'2014-12-17 09:06:18'),(1044,1175,33,1,1,1,0,'2014-12-17 09:06:18'),(1045,1175,34,1,1,1,0,'2014-12-17 09:06:18'),(1046,1175,35,1,1,1,0,'2014-12-17 09:06:18'),(1047,1175,36,1,1,1,0,'2014-12-17 09:06:18'),(1048,1175,52,1,1,1,0,'2014-12-17 09:06:18'),(1049,1175,37,1,1,1,0,'2014-12-17 09:06:18'),(1050,1182,32,1,1,1,0,'2014-12-17 09:06:18'),(1051,1182,33,1,1,1,0,'2014-12-17 09:06:18'),(1052,1182,34,1,1,1,0,'2014-12-17 09:06:18'),(1053,1182,35,1,1,1,0,'2014-12-17 09:06:18'),(1054,1182,36,1,1,1,0,'2014-12-17 09:06:18'),(1055,1182,52,1,1,1,0,'2014-12-17 09:06:18'),(1056,1182,37,1,1,1,0,'2014-12-17 09:06:18'),(1064,1188,32,1,1,1,0,'2014-12-17 09:06:18'),(1065,1188,33,1,1,1,0,'2014-12-17 09:06:18'),(1066,1188,34,1,1,1,0,'2014-12-17 09:06:18'),(1067,1188,35,1,1,1,0,'2014-12-17 09:06:18'),(1068,1188,36,1,1,1,0,'2014-12-17 09:06:18'),(1069,1188,52,1,1,1,0,'2014-12-17 09:06:18'),(1070,1188,37,1,1,1,0,'2014-12-17 09:06:18'),(1071,1188,51,1,1,1,0,'2014-12-17 09:06:18'),(1079,1189,32,1,1,1,0,'2014-12-17 09:06:18'),(1080,1189,33,1,1,1,0,'2014-12-17 09:06:18'),(1081,1189,34,1,1,1,0,'2014-12-17 09:06:18'),(1082,1189,35,1,1,1,0,'2014-12-17 09:06:18'),(1083,1189,36,1,1,1,0,'2014-12-17 09:06:18'),(1084,1189,52,1,1,1,0,'2014-12-17 09:06:18'),(1085,1189,37,1,1,1,0,'2014-12-17 09:06:18'),(1086,1189,51,1,1,1,0,'2014-12-17 09:06:18'),(1094,1196,32,1,1,1,0,'2014-12-17 09:06:18'),(1095,1196,33,1,1,1,0,'2014-12-17 09:06:18'),(1096,1196,34,1,1,1,0,'2014-12-17 09:06:18'),(1097,1196,35,1,1,1,0,'2014-12-17 09:06:18'),(1098,1196,36,1,1,1,0,'2014-12-17 09:06:18'),(1099,1196,52,1,1,1,0,'2014-12-17 09:06:18'),(1100,1196,37,1,1,1,0,'2014-12-17 09:06:18'),(1101,1196,51,1,1,1,0,'2014-12-17 09:06:18'),(1109,1202,32,1,1,1,0,'2014-12-17 09:06:18'),(1110,1202,33,1,1,1,0,'2014-12-17 09:06:18'),(1111,1202,34,1,1,1,0,'2014-12-17 09:06:18'),(1112,1202,35,1,1,1,0,'2014-12-17 09:06:18'),(1113,1202,36,1,1,1,0,'2014-12-17 09:06:18'),(1114,1202,43,1,1,1,0,'2014-12-17 09:06:18'),(1115,1202,44,1,1,1,0,'2014-12-17 09:06:18'),(1116,1202,45,1,1,1,0,'2014-12-17 09:06:18'),(1117,1202,37,1,1,1,0,'2014-12-17 09:06:18'),(1124,1206,32,1,1,1,0,'2014-12-17 09:06:18'),(1125,1206,33,1,1,1,0,'2014-12-17 09:06:18'),(1126,1206,34,1,1,1,0,'2014-12-17 09:06:18'),(1127,1206,35,1,1,1,0,'2014-12-17 09:06:18'),(1128,1206,36,1,1,1,0,'2014-12-17 09:06:18'),(1129,1206,43,1,1,1,0,'2014-12-17 09:06:18'),(1130,1206,44,1,1,1,0,'2014-12-17 09:06:18'),(1131,1206,45,1,1,1,0,'2014-12-17 09:06:18'),(1132,1206,37,1,1,1,0,'2014-12-17 09:06:18'),(1139,1230,32,1,1,1,0,'2014-12-17 09:06:18'),(1140,1230,33,1,1,1,0,'2014-12-17 09:06:18'),(1141,1230,34,1,1,1,0,'2014-12-17 09:06:18'),(1142,1230,35,1,1,1,0,'2014-12-17 09:06:18'),(1143,1230,36,1,1,1,0,'2014-12-17 09:06:18'),(1144,1230,37,1,1,1,0,'2014-12-17 09:06:18'),(1145,-1230,40,1,1,1,0,'2014-12-17 09:06:18'),(1146,1230,41,1,1,1,0,'2014-12-17 09:06:18'),(1147,1230,42,1,1,1,0,'2014-12-17 09:06:18'),(1154,1232,32,1,1,1,0,'2014-12-17 09:06:18'),(1155,1232,33,1,1,1,0,'2014-12-17 09:06:18'),(1156,1232,34,1,1,1,0,'2014-12-17 09:06:18'),(1157,1232,35,1,1,1,0,'2014-12-17 09:06:18'),(1158,1232,36,1,1,1,0,'2014-12-17 09:06:18'),(1159,1232,37,1,1,1,0,'2014-12-17 09:06:18'),(1160,1232,38,1,1,1,0,'2014-12-17 09:06:18'),(1161,1232,39,1,1,1,0,'2014-12-17 09:06:18'),(1162,-1232,40,1,1,1,0,'2014-12-17 09:06:18'),(1163,1232,41,1,1,1,0,'2014-12-17 09:06:18'),(1164,1232,42,1,1,1,0,'2014-12-17 09:06:18'),(1169,1240,32,1,1,1,0,'2014-12-17 09:06:18'),(1170,1240,33,1,1,1,0,'2014-12-17 09:06:18'),(1171,1240,34,1,1,1,0,'2014-12-17 09:06:18'),(1172,1240,35,1,1,1,0,'2014-12-17 09:06:18'),(1173,1240,36,1,1,1,0,'2014-12-17 09:06:18'),(1174,1240,37,1,1,1,0,'2014-12-17 09:06:18'),(1175,1240,38,1,1,1,0,'2014-12-17 09:06:18'),(1176,1240,39,1,1,1,0,'2014-12-17 09:06:18'),(1177,-1240,40,1,1,1,0,'2014-12-17 09:06:18'),(1178,1240,41,1,1,1,0,'2014-12-17 09:06:18'),(1179,1240,42,1,1,1,0,'2014-12-17 09:06:18'),(1184,1248,32,1,1,1,0,'2014-12-17 09:06:18'),(1185,1248,33,1,1,1,0,'2014-12-17 09:06:18'),(1186,1248,34,1,1,1,0,'2014-12-17 09:06:18'),(1187,1248,35,1,1,1,0,'2014-12-17 09:06:18'),(1188,1248,36,1,1,1,0,'2014-12-17 09:06:18'),(1189,1248,37,1,1,1,0,'2014-12-17 09:06:18'),(1190,-1248,40,1,1,1,0,'2014-12-17 09:06:18'),(1191,1248,41,1,1,1,0,'2014-12-17 09:06:18'),(1192,1248,42,1,1,1,0,'2014-12-17 09:06:18'),(1199,1250,32,1,1,1,0,'2014-12-17 09:06:18'),(1200,1250,33,1,1,1,0,'2014-12-17 09:06:18'),(1201,1250,34,1,1,1,0,'2014-12-17 09:06:18'),(1202,1250,35,1,1,1,0,'2014-12-17 09:06:18'),(1203,1250,36,1,1,1,0,'2014-12-17 09:06:18'),(1204,1250,37,1,1,1,0,'2014-12-17 09:06:18'),(1205,1250,38,1,1,1,0,'2014-12-17 09:06:18'),(1206,1250,39,1,1,1,0,'2014-12-17 09:06:18'),(1207,-1250,40,1,1,1,0,'2014-12-17 09:06:18'),(1208,1250,41,1,1,1,0,'2014-12-17 09:06:18'),(1209,1250,42,1,1,1,0,'2014-12-17 09:06:18'),(1214,1258,32,1,1,1,0,'2014-12-17 09:06:18'),(1215,1258,33,1,1,1,0,'2014-12-17 09:06:18'),(1216,1258,34,1,1,1,0,'2014-12-17 09:06:18'),(1217,1258,35,1,1,1,0,'2014-12-17 09:06:18'),(1218,1258,36,1,1,1,0,'2014-12-17 09:06:18'),(1219,1258,37,1,1,1,0,'2014-12-17 09:06:18'),(1220,1258,38,1,1,1,0,'2014-12-17 09:06:18'),(1221,1258,39,1,1,1,0,'2014-12-17 09:06:18'),(1222,-1258,40,1,1,1,0,'2014-12-17 09:06:18'),(1223,1258,41,1,1,1,0,'2014-12-17 09:06:18'),(1224,1258,42,1,1,1,0,'2014-12-17 09:06:18'),(1229,1312,32,1,1,1,0,'2014-12-17 09:06:18'),(1230,1312,33,1,1,1,0,'2014-12-17 09:06:18'),(1231,1312,34,1,1,1,0,'2014-12-17 09:06:18'),(1232,1312,35,1,1,1,0,'2014-12-17 09:06:18'),(1233,1312,36,1,1,1,0,'2014-12-17 09:06:18'),(1234,1312,37,1,1,1,0,'2014-12-17 09:06:18'),(1235,-1312,40,1,1,1,0,'2014-12-17 09:06:18'),(1236,1312,41,1,1,1,0,'2014-12-17 09:06:18'),(1237,1312,42,1,1,1,0,'2014-12-17 09:06:18'),(1244,1314,32,1,1,1,0,'2014-12-17 09:06:18'),(1245,1314,33,1,1,1,0,'2014-12-17 09:06:18'),(1246,1314,34,1,1,1,0,'2014-12-17 09:06:18'),(1247,1314,35,1,1,1,0,'2014-12-17 09:06:18'),(1248,1314,36,1,1,1,0,'2014-12-17 09:06:18'),(1249,1314,37,1,1,1,0,'2014-12-17 09:06:18'),(1250,1314,38,1,1,1,0,'2014-12-17 09:06:18'),(1251,1314,39,1,1,1,0,'2014-12-17 09:06:18'),(1252,-1314,40,1,1,1,0,'2014-12-17 09:06:18'),(1253,1314,41,1,1,1,0,'2014-12-17 09:06:18'),(1254,1314,42,1,1,1,0,'2014-12-17 09:06:18'),(1259,1356,32,1,1,1,0,'2014-12-17 09:06:18'),(1260,1356,33,1,1,1,0,'2014-12-17 09:06:18'),(1261,1356,34,1,1,1,0,'2014-12-17 09:06:18'),(1262,1356,35,1,1,1,0,'2014-12-17 09:06:18'),(1263,1356,36,1,1,1,0,'2014-12-17 09:06:18'),(1264,-1356,40,1,1,1,0,'2014-12-17 09:06:18'),(1265,1356,41,1,1,1,0,'2014-12-17 09:06:18'),(1266,1356,42,1,1,1,0,'2014-12-17 09:06:18'),(1274,1358,32,1,1,1,0,'2014-12-17 09:06:18'),(1275,1358,33,1,1,1,0,'2014-12-17 09:06:18'),(1276,1358,34,1,1,1,0,'2014-12-17 09:06:18'),(1277,1358,35,1,1,1,0,'2014-12-17 09:06:18'),(1278,1358,36,1,1,1,0,'2014-12-17 09:06:18'),(1279,1358,38,1,1,1,0,'2014-12-17 09:06:18'),(1280,1358,39,1,1,1,0,'2014-12-17 09:06:18'),(1281,-1358,40,1,1,1,0,'2014-12-17 09:06:18'),(1282,1358,41,1,1,1,0,'2014-12-17 09:06:18'),(1283,1358,42,1,1,1,0,'2014-12-17 09:06:18'),(1289,1366,32,1,1,1,0,'2014-12-17 09:06:18'),(1290,1366,33,1,1,1,0,'2014-12-17 09:06:18'),(1291,1366,34,1,1,1,0,'2014-12-17 09:06:18'),(1292,1366,35,1,1,1,0,'2014-12-17 09:06:18'),(1293,1366,36,1,1,1,0,'2014-12-17 09:06:18'),(1294,1366,38,1,1,1,0,'2014-12-17 09:06:18'),(1295,1366,39,1,1,1,0,'2014-12-17 09:06:18'),(1296,-1366,40,1,1,1,0,'2014-12-17 09:06:18'),(1297,1366,41,1,1,1,0,'2014-12-17 09:06:18'),(1298,1366,42,1,1,1,0,'2014-12-17 09:06:18'),(1304,1374,32,1,1,1,0,'2014-12-17 09:06:18'),(1305,1374,33,1,1,1,0,'2014-12-17 09:06:18'),(1306,1374,34,1,1,1,0,'2014-12-17 09:06:18'),(1307,1374,35,1,1,1,0,'2014-12-17 09:06:18'),(1308,1374,36,1,1,1,0,'2014-12-17 09:06:18'),(1309,-1374,40,1,1,1,0,'2014-12-17 09:06:18'),(1310,1374,41,1,1,1,0,'2014-12-17 09:06:18'),(1311,1374,42,1,1,1,0,'2014-12-17 09:06:18'),(1319,1376,32,1,1,1,0,'2014-12-17 09:06:18'),(1320,1376,33,1,1,1,0,'2014-12-17 09:06:18'),(1321,1376,34,1,1,1,0,'2014-12-17 09:06:18'),(1322,1376,35,1,1,1,0,'2014-12-17 09:06:18'),(1323,1376,36,1,1,1,0,'2014-12-17 09:06:18'),(1324,1376,38,1,1,1,0,'2014-12-17 09:06:18'),(1325,1376,39,1,1,1,0,'2014-12-17 09:06:18'),(1326,-1376,40,1,1,1,0,'2014-12-17 09:06:18'),(1327,1376,41,1,1,1,0,'2014-12-17 09:06:18'),(1328,1376,42,1,1,1,0,'2014-12-17 09:06:18'),(1334,1384,32,1,1,1,0,'2014-12-17 09:06:18'),(1335,1384,33,1,1,1,0,'2014-12-17 09:06:18'),(1336,1384,34,1,1,1,0,'2014-12-17 09:06:18'),(1337,1384,35,1,1,1,0,'2014-12-17 09:06:18'),(1338,1384,36,1,1,1,0,'2014-12-17 09:06:18'),(1339,1384,38,1,1,1,0,'2014-12-17 09:06:18'),(1340,1384,39,1,1,1,0,'2014-12-17 09:06:18'),(1341,-1384,40,1,1,1,0,'2014-12-17 09:06:18'),(1342,1384,41,1,1,1,0,'2014-12-17 09:06:18'),(1343,1384,42,1,1,1,0,'2014-12-17 09:06:18'),(1349,1392,32,1,1,1,0,'2014-12-17 09:06:18'),(1350,1392,33,1,1,1,0,'2014-12-17 09:06:18'),(1351,1392,34,1,1,1,0,'2014-12-17 09:06:18'),(1352,1392,35,1,1,1,0,'2014-12-17 09:06:18'),(1353,1392,36,1,1,1,0,'2014-12-17 09:06:18'),(1354,-1392,40,1,1,1,0,'2014-12-17 09:06:18'),(1355,1392,41,1,1,1,0,'2014-12-17 09:06:18'),(1356,1392,42,1,1,1,0,'2014-12-17 09:06:18'),(1364,1394,32,1,1,1,0,'2014-12-17 09:06:18'),(1365,1394,33,1,1,1,0,'2014-12-17 09:06:18'),(1366,1394,34,1,1,1,0,'2014-12-17 09:06:18'),(1367,1394,35,1,1,1,0,'2014-12-17 09:06:18'),(1368,1394,36,1,1,1,0,'2014-12-17 09:06:18'),(1369,1394,38,1,1,1,0,'2014-12-17 09:06:18'),(1370,1394,39,1,1,1,0,'2014-12-17 09:06:18'),(1371,-1394,40,1,1,1,0,'2014-12-17 09:06:18'),(1372,1394,41,1,1,1,0,'2014-12-17 09:06:18'),(1373,1394,42,1,1,1,0,'2014-12-17 09:06:18'),(1379,1402,32,1,1,1,0,'2014-12-17 09:06:18'),(1380,1402,33,1,1,1,0,'2014-12-17 09:06:18'),(1381,1402,34,1,1,1,0,'2014-12-17 09:06:18'),(1382,1402,35,1,1,1,0,'2014-12-17 09:06:18'),(1383,1402,36,1,1,1,0,'2014-12-17 09:06:18'),(1384,1402,38,1,1,1,0,'2014-12-17 09:06:18'),(1385,1402,39,1,1,1,0,'2014-12-17 09:06:18'),(1386,-1402,40,1,1,1,0,'2014-12-17 09:06:18'),(1387,1402,41,1,1,1,0,'2014-12-17 09:06:18'),(1388,1402,42,1,1,1,0,'2014-12-17 09:06:18'),(1394,1424,32,1,1,1,0,'2014-12-17 09:06:18'),(1395,1424,33,1,1,1,0,'2014-12-17 09:06:18'),(1396,1424,34,1,1,1,0,'2014-12-17 09:06:18'),(1397,1424,35,1,1,1,0,'2014-12-17 09:06:18'),(1398,1424,36,1,1,1,0,'2014-12-17 09:06:18'),(1399,1424,43,1,1,1,0,'2014-12-17 09:06:18'),(1400,1424,44,1,1,1,0,'2014-12-17 09:06:18'),(1401,1424,45,1,1,1,0,'2014-12-17 09:06:18'),(1402,1424,37,1,1,1,0,'2014-12-17 09:06:18'),(1409,1427,32,1,1,1,0,'2014-12-17 09:06:18'),(1410,1427,33,1,1,1,0,'2014-12-17 09:06:18'),(1411,1427,34,1,1,1,0,'2014-12-17 09:06:18'),(1412,1427,35,1,1,1,0,'2014-12-17 09:06:18'),(1413,1427,36,1,1,1,0,'2014-12-17 09:06:18'),(1414,1427,43,1,1,1,0,'2014-12-17 09:06:18'),(1415,1427,44,1,1,1,0,'2014-12-17 09:06:18'),(1416,1427,45,1,1,1,0,'2014-12-17 09:06:18'),(1417,1427,37,1,1,1,0,'2014-12-17 09:06:18'),(1424,1433,32,1,1,1,0,'2014-12-18 02:58:57'),(1425,1433,33,1,1,1,0,'2014-12-18 02:58:57'),(1426,1433,34,1,1,1,0,'2014-12-18 02:58:57'),(1427,1433,35,1,1,1,0,'2014-12-18 02:58:57'),(1428,1433,36,1,1,1,0,'2014-12-18 02:58:57'),(1429,1433,46,1,1,1,0,'2014-12-18 02:58:57'),(1431,1433,48,1,1,1,0,'2014-12-18 02:58:57'),(1432,1433,49,1,1,1,0,'2014-12-18 02:58:57'),(1433,1433,50,1,1,1,0,'2014-12-18 02:58:57'),(1434,1433,37,1,1,1,0,'2014-12-18 02:58:57'),(1435,1433,62,1,1,1,0,'2014-12-18 02:58:57'),(1619,1436,32,1,1,1,0,'2014-12-18 03:05:08'),(1620,1436,33,1,1,1,0,'2014-12-18 03:05:08'),(1621,1436,34,1,1,1,0,'2014-12-18 03:05:08'),(1622,1436,35,1,1,1,0,'2014-12-18 03:05:08'),(1623,1436,36,1,1,1,0,'2014-12-18 03:05:08'),(1624,1436,43,1,1,1,0,'2014-12-18 03:05:08'),(1625,1436,44,1,1,1,0,'2014-12-18 03:05:08'),(1626,1436,45,1,1,1,0,'2014-12-18 03:05:08'),(1627,1436,37,1,1,1,0,'2014-12-18 03:05:08'),(1634,1437,32,1,1,1,0,'2014-12-18 03:05:08'),(1635,1437,33,1,1,1,0,'2014-12-18 03:05:08'),(1636,1437,34,1,1,1,0,'2014-12-18 03:05:08'),(1637,1437,35,1,1,1,0,'2014-12-18 03:05:08'),(1638,1437,36,1,1,1,0,'2014-12-18 03:05:08'),(1639,1437,43,1,1,1,0,'2014-12-18 03:05:08'),(1640,1437,44,1,1,1,0,'2014-12-18 03:05:08'),(1641,1437,45,1,1,1,0,'2014-12-18 03:05:08'),(1642,1437,37,1,1,1,0,'2014-12-18 03:05:08'),(1649,1438,32,1,1,1,0,'2014-12-18 03:05:08'),(1650,1438,33,1,1,1,0,'2014-12-18 03:05:08'),(1651,1438,34,1,1,1,0,'2014-12-18 03:05:08'),(1652,1438,35,1,1,1,0,'2014-12-18 03:05:08'),(1653,1438,36,1,1,1,0,'2014-12-18 03:05:08'),(1654,1438,43,1,1,1,0,'2014-12-18 03:05:08'),(1655,1438,44,1,1,1,0,'2014-12-18 03:05:08'),(1656,1438,45,1,1,1,0,'2014-12-18 03:05:08'),(1657,1438,37,1,1,1,0,'2014-12-18 03:05:08'),(1664,1439,32,1,1,1,0,'2014-12-18 03:05:08'),(1665,1439,33,1,1,1,0,'2014-12-18 03:05:08'),(1666,1439,34,1,1,1,0,'2014-12-18 03:05:08'),(1667,1439,35,1,1,1,0,'2014-12-18 03:05:08'),(1668,1439,36,1,1,1,0,'2014-12-18 03:05:08'),(1669,1439,43,1,1,1,0,'2014-12-18 03:05:08'),(1670,1439,44,1,1,1,0,'2014-12-18 03:05:08'),(1671,1439,45,1,1,1,0,'2014-12-18 03:05:08'),(1672,1439,37,1,1,1,0,'2014-12-18 03:05:08'),(1679,1440,32,1,1,1,0,'2014-12-18 03:05:08'),(1680,1440,33,1,1,1,0,'2014-12-18 03:05:08'),(1681,1440,34,1,1,1,0,'2014-12-18 03:05:08'),(1682,1440,35,1,1,1,0,'2014-12-18 03:05:08'),(1683,1440,36,1,1,1,0,'2014-12-18 03:05:08'),(1684,1440,43,1,1,1,0,'2014-12-18 03:05:08'),(1685,1440,44,1,1,1,0,'2014-12-18 03:05:08'),(1686,1440,45,1,1,1,0,'2014-12-18 03:05:08'),(1687,1440,37,1,1,1,0,'2014-12-18 03:05:08'),(1694,1441,32,1,1,1,0,'2014-12-18 03:05:08'),(1695,1441,33,1,1,1,0,'2014-12-18 03:05:08'),(1696,1441,34,1,1,1,0,'2014-12-18 03:05:08'),(1697,1441,35,1,1,1,0,'2014-12-18 03:05:08'),(1698,1441,36,1,1,1,0,'2014-12-18 03:05:08'),(1699,1441,43,1,1,1,0,'2014-12-18 03:05:08'),(1700,1441,44,1,1,1,0,'2014-12-18 03:05:08'),(1701,1441,45,1,1,1,0,'2014-12-18 03:05:08'),(1702,1441,37,1,1,1,0,'2014-12-18 03:05:08'),(1709,1442,32,1,1,1,0,'2014-12-18 03:05:08'),(1710,1442,33,1,1,1,0,'2014-12-18 03:05:08'),(1711,1442,34,1,1,1,0,'2014-12-18 03:05:08'),(1712,1442,35,1,1,1,0,'2014-12-18 03:05:08'),(1713,1442,36,1,1,1,0,'2014-12-18 03:05:08'),(1714,1442,43,1,1,1,0,'2014-12-18 03:05:08'),(1715,1442,44,1,1,1,0,'2014-12-18 03:05:08'),(1716,1442,45,1,1,1,0,'2014-12-18 03:05:08'),(1717,1442,37,1,1,1,0,'2014-12-18 03:05:08'),(1724,1443,32,1,1,1,0,'2014-12-18 03:05:08'),(1725,1443,33,1,1,1,0,'2014-12-18 03:05:08'),(1726,1443,34,1,1,1,0,'2014-12-18 03:05:08'),(1727,1443,35,1,1,1,0,'2014-12-18 03:05:08'),(1728,1443,36,1,1,1,0,'2014-12-18 03:05:08'),(1729,1443,43,1,1,1,0,'2014-12-18 03:05:08'),(1730,1443,44,1,1,1,0,'2014-12-18 03:05:08'),(1731,1443,45,1,1,1,0,'2014-12-18 03:05:08'),(1732,1443,37,1,1,1,0,'2014-12-18 03:05:08'),(1739,1444,32,1,1,1,0,'2014-12-18 03:05:08'),(1740,1444,33,1,1,1,0,'2014-12-18 03:05:08'),(1741,1444,34,1,1,1,0,'2014-12-18 03:05:08'),(1742,1444,35,1,1,1,0,'2014-12-18 03:05:08'),(1743,1444,36,1,1,1,0,'2014-12-18 03:05:08'),(1744,1444,43,1,1,1,0,'2014-12-18 03:05:08'),(1745,1444,44,1,1,1,0,'2014-12-18 03:05:08'),(1746,1444,45,1,1,1,0,'2014-12-18 03:05:08'),(1747,1444,37,1,1,1,0,'2014-12-18 03:05:08'),(1754,1445,32,1,1,1,0,'2014-12-18 03:05:08'),(1755,1445,33,1,1,1,0,'2014-12-18 03:05:08'),(1756,1445,34,1,1,1,0,'2014-12-18 03:05:08'),(1757,1445,35,1,1,1,0,'2014-12-18 03:05:08'),(1758,1445,36,1,1,1,0,'2014-12-18 03:05:08'),(1759,1445,43,1,1,1,0,'2014-12-18 03:05:08'),(1760,1445,44,1,1,1,0,'2014-12-18 03:05:08'),(1761,1445,45,1,1,1,0,'2014-12-18 03:05:08'),(1762,1445,37,1,1,1,0,'2014-12-18 03:05:08'),(1769,1446,32,1,1,1,0,'2014-12-18 03:05:08'),(1770,1446,33,1,1,1,0,'2014-12-18 03:05:08'),(1771,1446,34,1,1,1,0,'2014-12-18 03:05:08'),(1772,1446,35,1,1,1,0,'2014-12-18 03:05:08'),(1773,1446,36,1,1,1,0,'2014-12-18 03:05:08'),(1774,1446,43,1,1,1,0,'2014-12-18 03:05:08'),(1775,1446,44,1,1,1,0,'2014-12-18 03:05:08'),(1776,1446,45,1,1,1,0,'2014-12-18 03:05:08'),(1777,1446,37,1,1,1,0,'2014-12-18 03:05:08'),(1784,1447,32,1,1,1,0,'2014-12-18 03:05:11'),(1785,1447,33,1,1,1,0,'2014-12-18 03:05:11'),(1786,1447,34,1,1,1,0,'2014-12-18 03:05:11'),(1787,1447,35,1,1,1,0,'2014-12-18 03:05:11'),(1788,1447,36,1,1,1,0,'2014-12-18 03:05:11'),(1789,1447,43,1,1,1,0,'2014-12-18 03:05:11'),(1790,1447,44,1,1,1,0,'2014-12-18 03:05:11'),(1791,1447,45,1,1,1,0,'2014-12-18 03:05:11'),(1792,1447,37,1,1,1,0,'2014-12-18 03:05:11'),(1799,1451,32,1,1,1,0,'2014-12-18 03:09:08'),(1800,1451,33,1,1,1,0,'2014-12-18 03:09:08'),(1801,1451,34,1,1,1,0,'2014-12-18 03:09:08'),(1802,1451,35,1,1,1,0,'2014-12-18 03:09:08'),(1803,1451,36,1,1,1,0,'2014-12-18 03:09:08'),(1804,1451,52,1,1,1,0,'2014-12-18 03:09:08'),(1805,1451,37,1,1,1,0,'2014-12-18 03:09:08'),(1806,1452,32,1,1,1,0,'2014-12-18 03:09:08'),(1807,1452,33,1,1,1,0,'2014-12-18 03:09:08'),(1808,1452,34,1,1,1,0,'2014-12-18 03:09:08'),(1809,1452,35,1,1,1,0,'2014-12-18 03:09:08'),(1810,1452,36,1,1,1,0,'2014-12-18 03:09:08'),(1811,1452,52,1,1,1,0,'2014-12-18 03:09:08'),(1812,1452,37,1,1,1,0,'2014-12-18 03:09:08'),(1813,1453,32,1,1,1,0,'2014-12-18 03:09:08'),(1814,1453,33,1,1,1,0,'2014-12-18 03:09:08'),(1815,1453,34,1,1,1,0,'2014-12-18 03:09:08'),(1816,1453,35,1,1,1,0,'2014-12-18 03:09:08'),(1817,1453,36,1,1,1,0,'2014-12-18 03:09:08'),(1818,1453,52,1,1,1,0,'2014-12-18 03:09:08'),(1819,1453,37,1,1,1,0,'2014-12-18 03:09:08'),(1820,1454,32,1,1,1,0,'2014-12-18 03:09:08'),(1821,1454,33,1,1,1,0,'2014-12-18 03:09:08'),(1822,1454,34,1,1,1,0,'2014-12-18 03:09:08'),(1823,1454,35,1,1,1,0,'2014-12-18 03:09:08'),(1824,1454,36,1,1,1,0,'2014-12-18 03:09:08'),(1825,1454,52,1,1,1,0,'2014-12-18 03:09:08'),(1826,1454,37,1,1,1,0,'2014-12-18 03:09:08'),(1827,1455,32,1,1,1,0,'2014-12-18 03:09:08'),(1828,1455,33,1,1,1,0,'2014-12-18 03:09:08'),(1829,1455,34,1,1,1,0,'2014-12-18 03:09:08'),(1830,1455,35,1,1,1,0,'2014-12-18 03:09:08'),(1831,1455,36,1,1,1,0,'2014-12-18 03:09:08'),(1832,1455,52,1,1,1,0,'2014-12-18 03:09:08'),(1833,1455,37,1,1,1,0,'2014-12-18 03:09:08'),(1834,1456,32,1,1,1,0,'2014-12-18 03:09:08'),(1835,1456,33,1,1,1,0,'2014-12-18 03:09:08'),(1836,1456,34,1,1,1,0,'2014-12-18 03:09:08'),(1837,1456,35,1,1,1,0,'2014-12-18 03:09:08'),(1838,1456,36,1,1,1,0,'2014-12-18 03:09:08'),(1839,1456,52,1,1,1,0,'2014-12-18 03:09:08'),(1840,1456,37,1,1,1,0,'2014-12-18 03:09:08'),(1849,1458,32,1,1,1,0,'2014-12-18 03:14:20'),(1850,1458,33,1,1,1,0,'2014-12-18 03:14:20'),(1851,1458,34,1,1,1,0,'2014-12-18 03:14:20'),(1852,1458,35,1,1,1,0,'2014-12-18 03:14:20'),(1853,1458,36,1,1,1,0,'2014-12-18 03:14:20'),(1854,1458,52,1,1,1,0,'2014-12-18 03:14:20'),(1855,1458,37,1,1,1,0,'2014-12-18 03:14:20'),(1856,1458,51,1,1,1,0,'2014-12-18 03:14:20'),(1864,1459,32,1,1,1,0,'2014-12-18 03:14:20'),(1865,1459,33,1,1,1,0,'2014-12-18 03:14:20'),(1866,1459,34,1,1,1,0,'2014-12-18 03:14:20'),(1867,1459,35,1,1,1,0,'2014-12-18 03:14:20'),(1868,1459,36,1,1,1,0,'2014-12-18 03:14:20'),(1869,1459,52,1,1,1,0,'2014-12-18 03:14:20'),(1870,1459,37,1,1,1,0,'2014-12-18 03:14:20'),(1871,1459,51,1,1,1,0,'2014-12-18 03:14:20'),(1879,1460,32,1,1,1,0,'2014-12-18 03:14:20'),(1880,1460,33,1,1,1,0,'2014-12-18 03:14:20'),(1881,1460,34,1,1,1,0,'2014-12-18 03:14:20'),(1882,1460,35,1,1,1,0,'2014-12-18 03:14:20'),(1883,1460,36,1,1,1,0,'2014-12-18 03:14:20'),(1884,1460,52,1,1,1,0,'2014-12-18 03:14:20'),(1885,1460,37,1,1,1,0,'2014-12-18 03:14:20'),(1886,1460,51,1,1,1,0,'2014-12-18 03:14:20'),(1894,1461,32,1,1,1,0,'2014-12-18 03:14:20'),(1895,1461,33,1,1,1,0,'2014-12-18 03:14:20'),(1896,1461,34,1,1,1,0,'2014-12-18 03:14:20'),(1897,1461,35,1,1,1,0,'2014-12-18 03:14:20'),(1898,1461,36,1,1,1,0,'2014-12-18 03:14:20'),(1899,1461,52,1,1,1,0,'2014-12-18 03:14:20'),(1900,1461,37,1,1,1,0,'2014-12-18 03:14:20'),(1901,1461,51,1,1,1,0,'2014-12-18 03:14:20'),(1909,1462,32,1,1,1,0,'2014-12-18 03:14:20'),(1910,1462,33,1,1,1,0,'2014-12-18 03:14:20'),(1911,1462,34,1,1,1,0,'2014-12-18 03:14:20'),(1912,1462,35,1,1,1,0,'2014-12-18 03:14:20'),(1913,1462,36,1,1,1,0,'2014-12-18 03:14:20'),(1914,1462,52,1,1,1,0,'2014-12-18 03:14:20'),(1915,1462,37,1,1,1,0,'2014-12-18 03:14:20'),(1916,1462,51,1,1,1,0,'2014-12-18 03:14:20'),(1924,1463,32,1,1,1,0,'2014-12-18 03:14:22'),(1925,1463,33,1,1,1,0,'2014-12-18 03:14:22'),(1926,1463,34,1,1,1,0,'2014-12-18 03:14:22'),(1927,1463,35,1,1,1,0,'2014-12-18 03:14:22'),(1928,1463,36,1,1,1,0,'2014-12-18 03:14:22'),(1929,1463,52,1,1,1,0,'2014-12-18 03:14:22'),(1930,1463,37,1,1,1,0,'2014-12-18 03:14:22'),(1931,1463,51,1,1,1,0,'2014-12-18 03:14:22'),(1939,1465,32,1,1,1,0,'2014-12-18 03:15:55'),(1940,1465,33,1,1,1,0,'2014-12-18 03:15:55'),(1941,1465,34,1,1,1,0,'2014-12-18 03:15:55'),(1942,1465,35,1,1,1,0,'2014-12-18 03:15:55'),(1943,1465,36,1,1,1,0,'2014-12-18 03:15:55'),(1944,1465,52,1,1,1,0,'2014-12-18 03:15:55'),(1945,1465,37,1,1,1,0,'2014-12-18 03:15:55'),(1954,1466,32,1,1,1,0,'2014-12-18 03:15:55'),(1955,1466,33,1,1,1,0,'2014-12-18 03:15:55'),(1956,1466,34,1,1,1,0,'2014-12-18 03:15:55'),(1957,1466,35,1,1,1,0,'2014-12-18 03:15:55'),(1958,1466,36,1,1,1,0,'2014-12-18 03:15:55'),(1959,1466,52,1,1,1,0,'2014-12-18 03:15:55'),(1960,1466,37,1,1,1,0,'2014-12-18 03:15:55'),(1969,1148,32,1,1,1,0,'2014-12-18 22:55:51'),(1970,1148,33,1,1,1,0,'2014-12-18 22:55:51'),(1971,1148,34,1,1,1,0,'2014-12-18 22:55:51'),(1972,1148,35,1,1,1,0,'2014-12-18 22:55:51'),(1973,1148,36,1,1,1,0,'2014-12-18 22:55:51'),(1974,1148,46,1,1,1,0,'2014-12-18 22:55:51'),(1976,1148,48,1,1,1,0,'2014-12-18 22:55:51'),(1977,1148,49,1,1,1,0,'2014-12-18 22:55:51'),(1978,1148,50,1,1,1,0,'2014-12-18 22:55:51'),(1979,1148,37,1,1,1,0,'2014-12-18 22:55:51'),(1980,1148,62,1,1,1,0,'2014-12-18 22:55:51'),(1984,1434,32,1,1,1,0,'2014-12-18 22:57:14'),(1985,1434,33,1,1,1,0,'2014-12-18 22:57:14'),(1986,1434,34,1,1,1,0,'2014-12-18 22:57:14'),(1987,1434,35,1,1,1,0,'2014-12-18 22:57:14'),(1988,1434,36,1,1,1,0,'2014-12-18 22:57:14'),(1989,1434,46,1,1,1,0,'2014-12-18 22:57:14'),(1991,1434,48,1,1,1,0,'2014-12-18 22:57:14'),(1992,1434,49,1,1,1,0,'2014-12-18 22:57:14'),(1993,1434,50,1,1,1,0,'2014-12-18 22:57:14'),(1994,1434,37,1,1,1,0,'2014-12-18 22:57:14'),(1995,1434,62,1,1,1,0,'2014-12-18 22:57:14'),(1999,1322,32,1,1,1,0,'2014-12-18 23:00:33'),(2000,1322,33,1,1,1,0,'2014-12-18 23:00:33'),(2001,1322,34,1,1,1,0,'2014-12-18 23:00:33'),(2002,1322,35,1,1,1,0,'2014-12-18 23:00:33'),(2003,1322,36,1,1,1,0,'2014-12-18 23:00:33'),(2004,1322,37,1,1,1,0,'2014-12-18 23:00:33'),(2005,1322,38,1,1,1,0,'2014-12-18 23:00:33'),(2006,1322,39,1,1,1,0,'2014-12-18 23:00:33'),(2007,-1322,40,1,1,1,0,'2014-12-18 23:00:33'),(2008,1322,41,1,1,1,0,'2014-12-18 23:00:33'),(2009,1322,42,1,1,1,0,'2014-12-18 23:00:33'),(2014,1326,32,1,1,1,0,'2014-12-18 23:03:49'),(2015,1326,33,1,1,1,0,'2014-12-18 23:03:49'),(2016,1326,34,1,1,1,0,'2014-12-18 23:03:49'),(2017,1326,35,1,1,1,0,'2014-12-18 23:03:49'),(2018,1326,36,1,1,1,0,'2014-12-18 23:03:49'),(2019,1326,37,1,1,1,0,'2014-12-18 23:03:49'),(2020,1326,38,1,1,1,0,'2014-12-18 23:03:49'),(2021,1326,39,1,1,1,0,'2014-12-18 23:03:49'),(2022,-1326,40,1,1,1,0,'2014-12-18 23:03:49'),(2023,1326,41,1,1,1,0,'2014-12-18 23:03:49'),(2024,1326,42,1,1,1,0,'2014-12-18 23:03:49'),(2029,1406,32,1,1,1,0,'2014-12-18 23:07:52'),(2030,1406,33,1,1,1,0,'2014-12-18 23:07:52'),(2031,1406,34,1,1,1,0,'2014-12-18 23:07:52'),(2032,1406,35,1,1,1,0,'2014-12-18 23:07:52'),(2033,1406,36,1,1,1,0,'2014-12-18 23:07:52'),(2034,1406,38,1,1,1,0,'2014-12-18 23:07:52'),(2035,1406,39,1,1,1,0,'2014-12-18 23:07:52'),(2036,-1406,40,1,1,1,0,'2014-12-18 23:07:52'),(2037,1406,41,1,1,1,0,'2014-12-18 23:07:52'),(2038,1406,42,1,1,1,0,'2014-12-18 23:07:52'),(2044,1408,32,1,1,1,0,'2014-12-18 23:08:09'),(2045,1408,33,1,1,1,0,'2014-12-18 23:08:09'),(2046,1408,34,1,1,1,0,'2014-12-18 23:08:09'),(2047,1408,35,1,1,1,0,'2014-12-18 23:08:09'),(2048,1408,36,1,1,1,0,'2014-12-18 23:08:09'),(2049,1408,38,1,1,1,0,'2014-12-18 23:08:09'),(2050,1408,39,1,1,1,0,'2014-12-18 23:08:09'),(2051,-1408,40,1,1,1,0,'2014-12-18 23:08:09'),(2052,1408,41,1,1,1,0,'2014-12-18 23:08:09'),(2053,1408,42,1,1,1,0,'2014-12-18 23:08:09'),(2059,1404,32,1,1,1,0,'2014-12-18 23:11:44'),(2060,1404,33,1,1,1,0,'2014-12-18 23:11:44'),(2061,1404,34,1,1,1,0,'2014-12-18 23:11:44'),(2062,1404,35,1,1,1,0,'2014-12-18 23:11:44'),(2063,1404,36,1,1,1,0,'2014-12-18 23:11:44'),(2064,-1404,40,1,1,1,0,'2014-12-18 23:11:44'),(2065,1404,41,1,1,1,0,'2014-12-18 23:11:44'),(2066,1404,42,1,1,1,0,'2014-12-18 23:11:44'),(2074,1324,32,1,1,1,0,'2014-12-18 23:12:44'),(2075,1324,33,1,1,1,0,'2014-12-18 23:12:44'),(2076,1324,34,1,1,1,0,'2014-12-18 23:12:44'),(2077,1324,35,1,1,1,0,'2014-12-18 23:12:44'),(2078,1324,36,1,1,1,0,'2014-12-18 23:12:44'),(2079,1324,37,1,1,1,0,'2014-12-18 23:12:44'),(2080,-1324,40,1,1,1,0,'2014-12-18 23:12:44'),(2081,1324,41,1,1,1,0,'2014-12-18 23:12:44'),(2082,1324,42,1,1,1,0,'2014-12-18 23:12:44'),(2089,1328,32,1,1,1,0,'2014-12-18 23:13:45'),(2090,1328,33,1,1,1,0,'2014-12-18 23:13:45'),(2091,1328,34,1,1,1,0,'2014-12-18 23:13:45'),(2092,1328,35,1,1,1,0,'2014-12-18 23:13:45'),(2093,1328,36,1,1,1,0,'2014-12-18 23:13:45'),(2094,1328,37,1,1,1,0,'2014-12-18 23:13:45'),(2095,1328,38,1,1,1,0,'2014-12-18 23:13:45'),(2096,1328,39,1,1,1,0,'2014-12-18 23:13:45'),(2097,-1328,40,1,1,1,0,'2014-12-18 23:13:45'),(2098,1328,41,1,1,1,0,'2014-12-18 23:13:45'),(2099,1328,42,1,1,1,0,'2014-12-18 23:13:45'),(2104,1234,40,1,1,1,0,'2014-12-29 04:58:05'),(2105,1236,40,1,1,1,0,'2014-12-29 04:58:05'),(2106,1238,40,1,1,1,0,'2014-12-29 04:58:05'),(2107,1252,40,1,1,1,0,'2014-12-29 04:58:05'),(2108,1254,40,1,1,1,0,'2014-12-29 04:58:05'),(2109,1256,40,1,1,1,0,'2014-12-29 04:58:05'),(2110,1316,40,1,1,1,0,'2014-12-29 04:58:05'),(2111,1318,40,1,1,1,0,'2014-12-29 04:58:05'),(2112,1320,40,1,1,1,0,'2014-12-29 04:58:05'),(2113,1360,40,1,1,1,0,'2014-12-29 04:58:05'),(2114,1362,40,1,1,1,0,'2014-12-29 04:58:05'),(2115,1364,40,1,1,1,0,'2014-12-29 04:58:05'),(2116,1378,40,1,1,1,0,'2014-12-29 04:58:05'),(2117,1380,40,1,1,1,0,'2014-12-29 04:58:05'),(2118,1382,40,1,1,1,0,'2014-12-29 04:58:05'),(2119,1396,40,1,1,1,0,'2014-12-29 04:58:05'),(2120,1398,40,1,1,1,0,'2014-12-29 04:58:05'),(2121,1400,40,1,1,1,0,'2014-12-29 04:58:05'),(2135,1145,32,1,1,1,1,'2014-12-29 06:29:39'),(2136,1145,33,1,1,1,1,'2014-12-29 06:29:58'),(2137,1145,34,1,1,1,1,'2014-12-29 06:30:10'),(2138,1145,35,1,1,1,1,'2014-12-29 06:30:29'),(2139,1145,36,1,1,1,1,'2014-12-29 06:30:50'),(2140,1145,37,1,1,1,1,'2014-12-29 06:31:01'),(2148,1469,32,1,1,1,1,'2014-12-29 06:32:55'),(2149,1469,33,1,1,1,1,'2014-12-29 06:32:55'),(2150,1469,34,1,1,1,1,'2014-12-29 06:32:55'),(2151,1469,35,1,1,1,1,'2014-12-29 06:32:55'),(2152,1469,36,1,1,1,1,'2014-12-29 06:32:55'),(2153,1469,37,1,1,1,1,'2014-12-29 06:32:55'),(2157,1420,63,1,1,1,0,'2015-01-15 03:47:08');
/*!40000 ALTER TABLE `tblWFRuleDocuments` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblWFRulePreReq`
--

DROP TABLE IF EXISTS `tblWFRulePreReq`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblWFRulePreReq` (
  `intWFRulePreReqID` int(11) NOT NULL AUTO_INCREMENT,
  `intWFRuleID` int(11) NOT NULL,
  `intPreReqWFRuleID` int(11) NOT NULL,
  `dtDeletedDate` datetime DEFAULT NULL,
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`intWFRulePreReqID`),
  KEY `index_intEntityID` (`intWFRuleID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblWFRulePreReq`
--

LOCK TABLES `tblWFRulePreReq` WRITE;
/*!40000 ALTER TABLE `tblWFRulePreReq` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblWFRulePreReq` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblWFTask`
--

DROP TABLE IF EXISTS `tblWFTask`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblWFTask` (
  `intWFTaskID` int(11) NOT NULL AUTO_INCREMENT,
  `intWFRuleID` int(11) NOT NULL DEFAULT '0',
  `intRealmID` int(11) NOT NULL DEFAULT '0',
  `intSubRealmID` int(11) NOT NULL DEFAULT '0',
  `intApprovalEntityID` int(11) NOT NULL DEFAULT '0' COMMENT 'Which entity has to approve this task',
  `strTaskType` varchar(20) NOT NULL COMMENT 'From tblWFRule',
  `strWFRuleFor` varchar(30) DEFAULT '' COMMENT 'PERSON, REGO, ENTITY, DOCUMENT',
  `strTaskStatus` varchar(20) NOT NULL DEFAULT 'ACTIVE' COMMENT 'From tblWFRule',
  `strRegistrationNature` varchar(20) NOT NULL DEFAULT '0' COMMENT 'NEW,RENEWAL,AMENDMENT,TRANSFER,',
  `intProblemResolutionEntityID` int(11) DEFAULT NULL COMMENT 'From tblWFRule',
  `dtActivateDate` datetime DEFAULT NULL COMMENT 'What date did this task first appear on a person''s list',
  `intApprovalUserID` int(11) DEFAULT NULL COMMENT 'Who approved this task',
  `dtApprovalDate` datetime DEFAULT NULL COMMENT 'What date was this task approved',
  `intRejectedUserID` int(11) DEFAULT NULL,
  `dtRejectedDate` datetime DEFAULT NULL,
  `intDocumentTypeID` int(11) NOT NULL DEFAULT '0' COMMENT 'From tblWFRule',
  `intEntityID` int(11) NOT NULL DEFAULT '0' COMMENT 'The entity who is registering',
  `intPersonID` int(11) NOT NULL DEFAULT '0' COMMENT 'The person who is registering',
  `intPersonRegistrationID` int(11) NOT NULL DEFAULT '0' COMMENT 'Foreign key to the registration that triggered this task',
  `intDocumentID` int(11) NOT NULL DEFAULT '0' COMMENT 'The document to check - for a particular document',
  `intOnHold` int(11) NOT NULL DEFAULT '0',
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `intCreatedByUserID` int(11) DEFAULT '0',
  `strTaskNotes` varchar(250) DEFAULT '',
  PRIMARY KEY (`intWFTaskID`),
  KEY `index_intEntityID` (`intApprovalEntityID`),
  KEY `index_intProbEntityID` (`intProblemResolutionEntityID`),
  KEY `index_WFRule` (`intWFRuleID`),
  KEY `index_intRealmID` (`intRealmID`,`intSubRealmID`),
  KEY `index_RuleFor` (`strWFRuleFor`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='A list of tasks associated with a Role at an Entity. For a single registration there could be multiple tasks. tblWFTask rows are inserted on a one to one ration with rows from tblWFRule';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblWFTask`
--

LOCK TABLES `tblWFTask` WRITE;
/*!40000 ALTER TABLE `tblWFTask` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblWFTask` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblWFTaskNotes`
--

DROP TABLE IF EXISTS `tblWFTaskNotes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblWFTaskNotes` (
  `intTaskNoteID` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `intParentNoteID` int(10) unsigned NOT NULL DEFAULT '0' COMMENT 'Used to track which rejection note a resolution note will be mapped.',
  `intWFTaskID` int(11) NOT NULL,
  `strNotes` varchar(250) CHARACTER SET latin1 NOT NULL,
  `strType` varchar(20) CHARACTER SET latin1 DEFAULT NULL COMMENT 'REJECT, RESOLVE, HOLD',
  `intCurrent` int(11) NOT NULL DEFAULT '1',
  `tTimeStamp` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`intTaskNoteID`)
) ENGINE=InnoDB AUTO_INCREMENT=204 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblWFTaskNotes`
--

LOCK TABLES `tblWFTaskNotes` WRITE;
/*!40000 ALTER TABLE `tblWFTaskNotes` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblWFTaskNotes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblWFTaskPreReq`
--

DROP TABLE IF EXISTS `tblWFTaskPreReq`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblWFTaskPreReq` (
  `intWFTaskPreReqID` int(11) NOT NULL AUTO_INCREMENT,
  `intWFTaskID` int(11) NOT NULL DEFAULT '0',
  `intWFRuleID` int(11) NOT NULL DEFAULT '0',
  `intPreReqWFRuleID` int(11) NOT NULL DEFAULT '0',
  `dtDeletedDate` datetime DEFAULT NULL,
  `tTimeStamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`intWFTaskPreReqID`),
  KEY `index_WFRule` (`intWFRuleID`),
  KEY `index_intEntityID` (`intWFTaskID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblWFTaskPreReq`
--

LOCK TABLES `tblWFTaskPreReq` WRITE;
/*!40000 ALTER TABLE `tblWFTaskPreReq` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblWFTaskPreReq` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tblWelcome`
--

DROP TABLE IF EXISTS `tblWelcome`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tblWelcome` (
  `intWelcomeID` int(11) NOT NULL AUTO_INCREMENT,
  `intRealmID` int(11) NOT NULL DEFAULT '0',
  `intEntityID` int(11) NOT NULL DEFAULT '0',
  `strWelcomeText` mediumtext,
  `intRealmSubTypeID` int(11) DEFAULT '0',
  PRIMARY KEY (`intWelcomeID`),
  KEY `index_intRealmAssoc` (`intRealmID`,`intEntityID`)
) ENGINE=MyISAM AUTO_INCREMENT=3874 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblWelcome`
--

LOCK TABLES `tblWelcome` WRITE;
/*!40000 ALTER TABLE `tblWelcome` DISABLE KEYS */;
/*!40000 ALTER TABLE `tblWelcome` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2015-01-20  9:30:18
