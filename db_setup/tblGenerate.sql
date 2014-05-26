DROP TABLE tblGenerate;
 
#
#

CREATE TABLE tblGenerate (
  intGenerateID int(11) NOT NULL auto_increment,
  intMemberLength int(11) DEFAULT '5',
  strMemberPrefix varchar(40) DEFAULT '' NOT NULL,
  strMemberSuffix varchar(40) DEFAULT '' NOT NULL,
  intMaxNum int(11) DEFAULT '10000',
  intCurrentNum int(11) DEFAULT '100' NOT NULL,
  intAlphaCheck int(11) DEFAULT '0',
  intGenType int(11) DEFAULT '0',
  intMinNum int(11) DEFAULT '0' NOT NULL,
  PRIMARY KEY (intGenerateID)
);

