-- MySQL dump 10.13  Distrib 5.5.40, for debian-linux-gnu (x86_64)
--
-- Host: localhost    Database: fifasponline
-- ------------------------------------------------------
-- Server version	5.5.40-0ubuntu0.14.04.1-log

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
  PRIMARY KEY (`intCertificationTypeID`)
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblCertificationTypes`
--

LOCK TABLES `tblCertificationTypes` WRITE;
/*!40000 ALTER TABLE `tblCertificationTypes` DISABLE KEYS */;
INSERT INTO `tblCertificationTypes` VALUES (1,1,'COACH','AFC Professional Coaching Diploma','2014-10-22 03:02:08',1),(2,1,'COACH','AFC \'A\' Coaching Certificate','2014-10-22 03:02:31',1),(3,1,'COACH','AFC \'B\' Coaching Certificate','2014-10-22 03:02:47',1),(4,1,'COACH','AFC \'C\' Coaching Certificate','2014-10-22 03:02:53',1),(5,1,'COACH','AFC Goalkeeper Coach (Levels 1 - 3)','2014-10-22 03:03:05',1),(6,1,'COACH','AFC Conditioning Coach','2014-10-22 03:03:21',1),(7,1,'COACH','AFC Futsal Coach','2014-10-22 03:03:31',1),(8,1,'REFEREE','AFC (Elite) Referee','2014-10-22 03:03:46',1),(9,1,'REFEREE','AFC (Elite) Assistant Referee','2014-10-22 03:04:00',1),(10,1,'REFEREE','AFC Assistant Referee','2014-10-22 03:04:06',1),(11,1,'REFEREE','AFC Referee','2014-10-22 03:04:14',1),(12,1,'REFEREE','AFC Futsal Referee','2014-10-22 03:04:24',1),(13,1,'REFEREE','AFC (Elite) Futsal Referee','2014-10-22 03:04:28',1);
/*!40000 ALTER TABLE `tblCertificationTypes` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2014-10-22 15:16:01
