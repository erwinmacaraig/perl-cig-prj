-- MySQL dump 10.9
--
-- Host: localhost    Database: regoSWM_live
-- ------------------------------------------------------
-- Server version	4.1.20

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `tblMember_Clubs`
--

DROP TABLE IF EXISTS `tblMember_Clubs`;
CREATE TABLE `tblMember_Clubs` (
  `intMemberClubID` int(11) NOT NULL auto_increment,
  `intMemberID` int(11) NOT NULL default '0',
  `intClubID` int(11) NOT NULL default '0',
  `intGradeID` int(11) default NULL,
  `tTimeStamp` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  `intStatus` int(11) NOT NULL default '0',
  `intPermit` tinyint(4) default '0',
  `dtPermitStart` datetime default NULL,
  `dtPermitEnd` datetime default NULL,
  `strContractNo` varchar(50) default NULL,
  `strContractYear` varchar(10) default NULL,
  `intPrimaryClub` int(11) default NULL,
  `dtContractEntered` date default NULL,
  PRIMARY KEY  (`intMemberClubID`),
  KEY `index_intMemberID` (`intMemberID`),
  KEY `index_intClubID` (`intClubID`),
  KEY `index_intStatus` (`intStatus`),
  KEY `index_ClubStatus` (`intClubID`,`intStatus`),
  KEY `index_ClubMemberStatus` (`intClubID`,`intMemberID`,`intStatus`),
  KEY `index_StatusGrade` (`intStatus`,`intGradeID`),
  KEY `index_GradeStatus` (`intGradeID`,`intStatus`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

