-- MySQL dump 10.13  Distrib 5.5.34, for debian-linux-gnu (i686)
--
-- Host: localhost    Database: fifasponline
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
) ENGINE=MyISAM AUTO_INCREMENT=98 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblReports`
--

LOCK TABLES `tblReports` WRITE;
/*!40000 ALTER TABLE `tblReports` DISABLE KEYS */;
INSERT INTO `tblReports` VALUES (2,'Advanced Club','Set your own parameters etc for reporting on Clubs.',3,'','Reports::ReportAdvanced_Club','Clubs',1,0,'NoClubs=0'),(3,'Advanced People (My level)','Set your own parameters etc for reporting on Members.',3,'','Reports::ReportAdvanced_MyPeople','People',1,0,NULL),(97,'Advanced People (Below my level)','Set your own parameters etc for reporting on People',3,'','Reports::ReportAdvanced_BelowPeople','People',1,0,NULL),(6,'Advanced Transfers Report','Set your own parameters etc for reporting on Transfers',3,'','Reports::ReportAdvanced_Clearances','Transfers',1,0,'AllowClearances=1'),(9,'Retention Report','Set your own parameters etc for reporting on Member Retention',3,'','Reports::ReportAdvanced_Retention','People',1,0,'AllowSeasons=1'),(10,'Transactions (My People)','Set your own parameters etc for reporting on Transactions',3,'','Reports::ReportAdvanced_MyPeopleTransactions','Finance',1,0,'AllowTXNs=1'),(11,'Transactions Sold','Set your own parameters etc for reporting on Transactions that you have sold',3,'','Reports::ReportAdvanced_TXSold','Finance',1,0,'ReceiveFunds=1'),(13,'Duplicates Summary','Set your own parameters etc for reporting on how many duplicates there are in each organisation.',3,'','Reports::ReportAdvanced_Duplicates','People',1,0,NULL),(17,'Member Summary','Member Summary Report',3,'','Reports::ReportAdvanced_MemberSummary','People',1,0,NULL),(18,'Member Demographic','Member Demographic Report',3,'','Reports::ReportAdvanced_MemberDemographic','People',1,0,'AllowSeasons=1'),(32,'Transfers Below Report','Set your own parameters etc for reporting on Transfers',3,'','Reports::ReportAdvanced_ClearancesAllBelow','Transfers',1,0,'');
/*!40000 ALTER TABLE `tblReports` ENABLE KEYS */;
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
INSERT INTO `tblReportEntity` VALUES (2,0,0,0,0,5,500),(3,0,0,0,0,2,400),(10,0,0,0,0,3,400),(11,0,0,0,0,3,400),(13,0,0,0,0,5,400),(17,0,0,0,0,5,400),(97,0,0,0,0,10,400),(32,0,0,0,0,10,100),(6,0,0,0,0,2,400);
/*!40000 ALTER TABLE `tblReportEntity` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2014-11-11 11:16:05
