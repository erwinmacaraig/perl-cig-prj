
TRUNCATE tblEntitySports;

INSERT IGNORE INTO tblEntitySports (intEntityID, strSportType) SELECT intEntityID, 'FOOTBALL' FROM tblEntity WHERE strDiscipline = 'ALL';
INSERT IGNORE INTO tblEntitySports (intEntityID, strSportType) SELECT intEntityID, 'FUTSAL' FROM tblEntity WHERE strDiscipline = 'ALL';
INSERT IGNORE INTO tblEntitySports (intEntityID, strSportType) SELECT intEntityID, 'WOMENSFOOTBALL' FROM tblEntity WHERE strDiscipline = 'ALL';
INSERT IGNORE INTO tblEntitySports (intEntityID, strSportType) SELECT intEntityID, 'BEACHSOCCER' FROM tblEntity WHERE strDiscipline = 'ALL';
INSERT IGNORE INTO tblEntitySports (intEntityID, strSportType) SELECT intEntityID, 'RECREATIONAL' FROM tblEntity WHERE strDiscipline = 'ALL';

INSERT IGNORE INTO tblEntitySports (intEntityID, strSportType) SELECT intEntityID, 'FOOTBALL' FROM tblEntity WHERE strDiscipline = 'FOOTBALL';
INSERT IGNORE INTO tblEntitySports (intEntityID, strSportType) SELECT intEntityID, 'FUTSAL' FROM tblEntity WHERE strDiscipline = 'FUTSAL';
INSERT IGNORE INTO tblEntitySports (intEntityID, strSportType) SELECT intEntityID, 'WOMENSFOOTBALL' FROM tblEntity WHERE strDiscipline = 'WOMENSFOOTBALL';
INSERT IGNORE INTO tblEntitySports (intEntityID, strSportType) SELECT intEntityID, 'BEACHSOCCER' FROM tblEntity WHERE strDiscipline = 'BEACHSOCCER';
INSERT IGNORE INTO tblEntitySports (intEntityID, strSportType) SELECT intEntityID, 'RECREATIONAL' FROM tblEntity WHERE strDiscipline = 'RECREATIONAL';
INSERT IGNORE INTO tblEntitySports (intEntityID, strSportType) SELECT intEntityID, 'RECREATIONAL' FROM tblEntity WHERE strDiscipline = 'RECREATIONAL FOOTBALL';


-- MA
INSERT IGNORE INTO tblEntitySports (intEntityID, strSportType) SELECT intEntityID, 'FOOTBALL' FROM tblEntity WHERE intEntityLevel = 100;
INSERT IGNORE INTO tblEntitySports (intEntityID, strSportType) SELECT intEntityID, 'FUTSAL' FROM tblEntity WHERE intEntityLevel = 100;
INSERT IGNORE INTO tblEntitySports (intEntityID, strSportType) SELECT intEntityID, 'WOMENSFOOTBALL' FROM tblEntity WHERE intEntityLevel = 100;
INSERT IGNORE INTO tblEntitySports (intEntityID, strSportType) SELECT intEntityID, 'BEACHSOCCER' FROM tblEntity WHERE intEntityLevel = 100;
INSERT IGNORE INTO tblEntitySports (intEntityID, strSportType) SELECT intEntityID, 'RECREATIONAL' FROM tblEntity WHERE intEntityLevel = 100;

-- RA
INSERT IGNORE INTO tblEntitySports (intEntityID, strSportType) SELECT intEntityID, 'FOOTBALL' FROM tblEntity WHERE intEntityLevel = 20;
INSERT IGNORE INTO tblEntitySports (intEntityID, strSportType) SELECT intEntityID, 'FUTSAL' FROM tblEntity WHERE intEntityLevel = 20;
INSERT IGNORE INTO tblEntitySports (intEntityID, strSportType) SELECT intEntityID, 'WOMENSFOOTBALL' FROM tblEntity WHERE intEntityLevel = 20;
INSERT IGNORE INTO tblEntitySports (intEntityID, strSportType) SELECT intEntityID, 'BEACHSOCCER' FROM tblEntity WHERE intEntityLevel = 20;
INSERT IGNORE INTO tblEntitySports (intEntityID, strSportType) SELECT intEntityID, 'RECREATIONAL' FROM tblEntity WHERE intEntityLevel = 20;

