-- MySQL dump 10.13  Distrib 5.5.24, for debian-linux-gnu (i686)
--
-- Host: localhost    Database: fifaconnectFinland
-- ------------------------------------------------------
-- Server version	5.5.24-0ubuntu0.12.04.1

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
) ENGINE=InnoDB AUTO_INCREMENT=48 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblEmailTemplates`
--

LOCK TABLES `tblEmailTemplates` WRITE;
/*!40000 ALTER TABLE `tblEmailTemplates` DISABLE KEYS */;
INSERT INTO `tblEmailTemplates` VALUES (1,1,'notification/workflow/html/','','WORK TASK ADDED: ',1,1,'2015-01-21 05:04:38'),(2,2,'notification/workflow/html/','','WORK TASK APPROVED: ',1,1,'2015-01-21 05:04:38'),(3,3,'notification/workflow/html/','','WORK TASK REJECTED: ',1,1,'2015-01-21 05:04:38'),(4,4,'notification/workflow/html/','','WORK TASK RESOLVED: ',1,1,'2015-01-21 05:04:38'),(5,5,'notification/workflow/html/','','WORK TASK HELD: ',1,1,'2015-01-21 05:04:38'),(6,6,'notification/workflow/html/','','WORK TASK RESUMED: ',1,1,'2015-01-21 05:04:38'),(7,7,'notification/personrequest/html/','','PERSON REQUEST ACCESS ACCEPTED: ',1,1,'2015-01-21 05:04:38'),(8,8,'notification/personrequest/html/','','PERSON REQUEST ACCESS DENIED: ',1,1,'2015-01-21 05:04:38'),(9,9,'notification/personrequest/html/','','PERSON REQUEST ACCESS OVERRIDDEN: ',1,1,'2015-01-21 05:04:38'),(10,10,'notification/personrequest/html/','','PERSON REQUEST ACCESS REJECTED: ',1,1,'2015-01-21 05:04:38'),(11,11,'notification/personrequest/html/','','PERSON REQUEST ACCESS COMPLETED: ',1,1,'2015-01-21 05:04:38'),(12,12,'notification/personrequest/html/','','PERSON REQUEST TRANSFER ACCEPTED: ',1,1,'2015-01-21 05:04:38'),(13,13,'notification/personrequest/html/','','PERSON REQUEST TRANSFER DENIED: ',1,1,'2015-01-21 05:04:38'),(14,14,'notification/personrequest/html/','','PERSON REQUEST TRANSFER OVERRIDDEN: ',1,1,'2015-01-21 05:04:38'),(15,15,'notification/personrequest/html/','','PERSON REQUEST TRANSFER REJECTED: ',1,1,'2015-01-21 05:04:38'),(16,16,'notification/personrequest/html/','','PERSON REQUEST TRANSFER COMPLETED: ',1,1,'2015-01-21 05:04:38'),(17,17,'notification/personrequest/html/','','PERSON REQUEST ACCESS SENT: ',1,1,'2015-01-21 05:04:38'),(18,18,'notification/personrequest/html/','','PERSON REQUEST TRANSFER SENT: ',1,1,'2015-01-21 05:04:38'),(19,19,'notification/personrequest/html/','','PERSON REQUEST ACCESS CANCELLED: ',1,1,'2015-01-21 05:04:38'),(20,20,'notification/personrequest/html/','','PERSON REQUEST TRANSFER CANCELLED: ',1,1,'2015-01-21 05:04:38'),(21,21,'notification/workflow/html/','','WORK TASK ADDED: ',1,1,'2015-02-12 09:29:15'),(22,22,'notification/workflow/html/','','WORK TASK APPROVED: ',1,1,'2015-02-12 09:29:15'),(23,23,'notification/workflow/html/','','WORK TASK REJECTED: ',1,1,'2015-02-12 09:29:15'),(24,24,'notification/workflow/html/','','WORK TASK RESOLVED: ',1,1,'2015-02-12 09:29:15'),(25,25,'notification/workflow/html/','','WORK TASK HELD: ',1,1,'2015-02-12 09:29:15'),(26,26,'notification/workflow/html/','','WORK TASK RESUMED: ',1,1,'2015-02-12 09:29:15'),(27,27,'notification/personrequest/html/','','PERSON REQUEST ACCESS ACCEPTED: ',1,1,'2015-02-12 09:29:15'),(28,28,'notification/personrequest/html/','','PERSON REQUEST ACCESS DENIED: ',1,1,'2015-02-12 09:29:15'),(29,29,'notification/personrequest/html/','','PERSON REQUEST ACCESS OVERRIDDEN: ',1,1,'2015-02-12 09:29:15'),(30,30,'notification/personrequest/html/','','PERSON REQUEST ACCESS REJECTED: ',1,1,'2015-02-12 09:29:15'),(31,31,'notification/personrequest/html/','','PERSON REQUEST ACCESS COMPLETED: ',1,1,'2015-02-12 09:29:15'),(32,32,'notification/personrequest/html/','','PERSON REQUEST TRANSFER ACCEPTED: ',1,1,'2015-02-12 09:29:15'),(33,33,'notification/personrequest/html/','','PERSON REQUEST TRANSFER DENIED: ',1,1,'2015-02-12 09:29:15'),(34,34,'notification/personrequest/html/','','PERSON REQUEST TRANSFER OVERRIDDEN: ',1,1,'2015-02-12 09:29:15'),(35,35,'notification/personrequest/html/','','PERSON REQUEST TRANSFER REJECTED: ',1,1,'2015-02-12 09:29:15'),(36,36,'notification/personrequest/html/','','PERSON REQUEST TRANSFER COMPLETED: ',1,1,'2015-02-12 09:29:15'),(37,37,'notification/personrequest/html/','','PERSON REQUEST ACCESS SENT: ',1,1,'2015-02-12 09:29:15'),(38,38,'notification/personrequest/html/','','PERSON REQUEST TRANSFER SENT: ',1,1,'2015-02-12 09:29:15'),(39,39,'notification/personrequest/html/','','PERSON REQUEST ACCESS CANCELLED: ',1,1,'2015-02-12 09:29:15'),(40,40,'notification/personrequest/html/','','PERSON REQUEST TRANSFER CANCELLED: ',1,1,'2015-02-12 09:29:15'),(41,42,'notification/personrequest/html/','','PERSON REQUEST LOAN ACCEPTED: ',1,1,'2015-04-21 03:28:38'),(42,43,'notification/personrequest/html/','','PERSON REQUEST LOAN CANCELLED:',1,1,'2015-04-21 03:28:38'),(43,44,'notification/personrequest/html/','','PERSON REQUEST LOAN COMPLETED:',1,1,'2015-04-21 03:28:38'),(44,45,'notification/personrequest/html/','','PERSON REQUEST LOAN DENIED:',1,1,'2015-04-21 03:28:38'),(45,46,'notification/personrequest/html/','','PERSON REQUEST LOAN OVERRIDDEN:',1,1,'2015-04-21 03:28:38'),(46,47,'notification/personrequest/html/','','PERSON REQUEST LOAN REJECTED:',1,1,'2015-04-21 03:28:38'),(47,48,'notification/personrequest/html/','','PERSON REQUEST LOAN SENT:',1,1,'2015-04-21 03:28:38');
/*!40000 ALTER TABLE `tblEmailTemplates` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2015-04-21 12:56:18
