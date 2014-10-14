-- MySQL dump 10.13  Distrib 5.5.38, for debian-linux-gnu (x86_64)
--
-- Host: localhost    Database: fifasponline
-- ------------------------------------------------------
-- Server version	5.5.38-0ubuntu0.14.04.1-log

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
INSERT INTO `tblGenerate` VALUES (1,1,0,0,'PERSON',6,999999,100000,'2014-10-14 22:27:42','%SEQUENCE%GENDER%YEAR','GENDER=$params->{\"gender\"} == 2 ? \"F\" : \"M\"#YEAR=substr($params->{\"dob\"},2,2)'),(2,1,0,0,'ENTITY',5,99999,10000,'2014-10-14 22:32:17','%SEQUENCE%ORGTYPE','ORGTYPE=uc(substr($params->{\"entityType\"},0,1))'),(3,1,0,0,'FACILITY',5,99999,10000,'2014-10-14 22:32:29','%SEQUENCE%ORGTYPE','ORGTYPE=uc(substr($params->{\"entityType\"},0,1))');
/*!40000 ALTER TABLE `tblGenerate` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2014-10-15  9:33:00
