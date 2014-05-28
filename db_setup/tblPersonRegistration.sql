/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

DROP TABLE IF EXISTS tblPersonRegistration;
CREATE TABLE tblPersonRegistration (
    intPersonRegistrationID int(11) NOT NULL auto_increment,
    intPersonID int(11) default 0,
    intEntityID int(11) default 0,
    strPersonType varchar(20) default '', /* player, coach, referee */
    strPersonSubType varchar(50) default '', /*?? or ID */
    strPersonLevel varchar(10) DEFAULT '', /* pro, amateur */
    strPersonEntityRole varchar(50) DEFAULT '', /* Referee, Head Coach, Delegate, Other */
    
    strStatus varchar(20) default '', /*Pending, Active,Passive, Transferred */
    strSport varchar(20) default '',
    intCurrent tinyint default 0,
    intOriginLevel TINYINT DEFAULT 0, /* Self, club, Reg, MA */
    intOriginID INT DEFAULT 0, 
    intRegistrationNature int default 0, /*First, Subsequent -- We haev a count ? */

    dtFrom date,
    dtTo date,

    intRealmID  INT DEFAULT 0,
    intSubRealmID  INT DEFAULT 0,
    
    dtAdded datetime,
    dtLastUpdated datetime,
    intIsPaid tinyint default 0,
    intSeasonID INT NOT NULL DEFAULT 0,
    intAgeGroupID  INT NOT NULL DEFAULT 0,
    tTimeStamp timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  PRIMARY KEY  (intPersonRegistrationID),
  KEY index_intPersonID (intPersonID),
  KEY index_intEntityID (intEntityID),
  KEY index_intPersonType (intPersonType),
  KEY index_intStatus (intStatus),
  KEY index_IDs (intEntityID, intPersonID)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

