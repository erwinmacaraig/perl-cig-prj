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
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8 COMMENT='Age restriction rules for PERSON REGO';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblRegoAgeRestrictions`
--

LOCK TABLES `tblRegoAgeRestrictions` WRITE;
/*!40000 ALTER TABLE `tblRegoAgeRestrictions` DISABLE KEYS */;
INSERT INTO `tblRegoAgeRestrictions` VALUES (1,1,0,'FOOTBALL','PLAYER','','AMATEUR','','MINOR',6,99,'2014-09-12 11:25:51'),(2,1,0,'FOOTBALL','PLAYER','','PROFESSIONAL','ADULT','',18,99,'2014-09-12 11:25:51'),(3,1,0,'FUTSAL','PLAYER','','','','',6,99,'2014-09-12 11:25:51'),(4,1,0,'FOOTBALL','TECHOFFICIAL','DOCTOR','','','ADULT',40,99,'2014-09-12 11:25:51'),(5,1,0,'','CLUBOFFICIAL','PRESIDENT','','','',18,99,'2014-09-12 11:25:51'),(6,1,0,'FOOTBALL','MAOFFICIAL','MATCHCOMMISIONER','','','ADULT',50,99,'2014-09-12 11:25:51'),(7,1,0,'FOOTBALL','PLAYER','','AMATEUR','','ADULT',18,99,'2014-09-14 22:39:59'),(8,1,0,'FOOTBALL','PLAYER','','AMATEUR','','MINOR',6,17,'2014-09-14 23:09:19'),(9,1,0,'FOOTBALL','PLAYER','','PROFESSIONAL','ADULT','',18,99,'2014-09-14 23:09:19'),(10,1,0,'FUTSAL','PLAYER','','','','',6,99,'2014-09-14 23:09:19'),(11,1,0,'FOOTBALL','TECHOFFICIAL','DOCTOR','','','ADULT',40,99,'2014-09-14 23:09:19'),(12,1,0,'','CLUBOFFICIAL','PRESIDENT','','','',18,99,'2014-09-14 23:09:19'),(13,1,0,'FOOTBALL','MAOFFICIAL','MATCHCOMMISIONER','','','ADULT',50,99,'2014-09-14 23:09:19'),(14,1,0,'FOOTBALL','PLAYER','','AMATEUR','','ADULT',18,99,'2014-09-14 23:09:20'),(15,1,0,'FOOTBALL','COACH','','','','ADULT',18,99,'2014-09-29 21:29:59');
/*!40000 ALTER TABLE `tblRegoAgeRestrictions` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2014-10-03 13:09:06
