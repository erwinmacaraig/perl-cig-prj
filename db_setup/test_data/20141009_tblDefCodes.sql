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
) ENGINE=MyISAM AUTO_INCREMENT=558006 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tblDefCodes`
--

LOCK TABLES `tblDefCodes` WRITE;
/*!40000 ALTER TABLE `tblDefCodes` DISABLE KEYS */;
INSERT INTO `tblDefCodes` VALUES (557704,0,-8,'MALAY','2014-10-09 02:31:28',1,-1,0,0),(557705,0,-53,'Muslim','2014-10-09 02:34:47',1,1,0,0),(557706,0,-8,'INDIAN ','2014-10-09 02:31:28',1,-1,0,0),(557707,0,-64,'AB+','2014-10-09 02:35:08',1,1,0,0),(557708,0,-53,'Other','2014-10-09 02:34:47',1,1,0,0),(557709,0,-8,'CHINESE','2014-10-09 02:31:28',1,1,0,0),(557710,0,-8,'MALAY ','2014-10-09 02:31:28',1,1,0,0),(557713,0,-64,'B+','2014-10-09 02:35:08',1,1,0,0),(557714,0,-53,'Catholic','2014-10-09 02:34:47',1,1,0,0),(557715,0,-8,'CAUCASIAN','2014-10-09 02:31:28',1,1,0,0),(557716,0,-53,'Christian','2014-10-09 02:34:47',1,1,0,0),(557718,0,-8,'AFRICAN','2014-10-09 02:31:28',1,1,0,0),(557719,0,-64,'O+','2014-10-09 02:35:08',1,1,0,0),(557720,0,-8,'JAPANESE','2014-10-09 02:31:28',1,1,0,0),(557721,0,-53,'Hindi','2014-10-09 02:34:47',1,1,0,0),(557722,0,-8,'INDIAN','2014-10-09 02:31:28',1,1,0,0),(557723,0,-64,'A+','2014-10-09 02:35:08',1,1,0,0),(557726,0,-8,'BOYANESE','2014-10-09 02:31:28',1,1,0,0),(557727,0,-53,'Tao','2014-10-09 02:34:47',1,1,0,0),(557728,0,-64,'A-','2014-10-09 02:35:08',1,1,0,0),(557729,0,-8,'BRASILIAN','2014-10-09 02:31:28',1,-1,0,0),(557732,0,-8,'MALAY','2014-10-09 02:31:28',1,-1,0,0),(557733,0,-53,'Buddhist','2014-10-09 02:34:47',1,1,0,0),(557734,0,-8,'JAVANESE','2014-10-09 02:31:28',1,1,0,0),(557735,0,-64,'O-','2014-10-09 02:35:08',1,1,0,0),(557736,0,-8,'BOYANESE','2014-10-09 02:31:28',1,-1,0,0),(557737,0,-53,'None','2014-10-09 02:34:47',1,1,0,0),(557738,0,-64,'B-','2014-10-09 02:35:08',1,1,0,0),(557739,0,-64,'AB-','2014-10-09 02:35:08',1,1,0,0),(557740,0,-8,'NIGERIAN','2014-10-09 02:31:28',1,1,0,0),(557741,0,-8,'CAMEROONIAN','2014-10-09 02:31:28',1,1,0,0),(557742,0,-8,'SINGAPOREAN','2014-10-09 02:31:28',1,1,0,0),(557745,0,-8,'MALAY','2014-10-09 02:31:28',1,-1,0,0),(557746,0,-8,'INDIAN ','2014-10-09 02:31:28',1,-1,0,0),(557747,0,-8,'BRITISH','2014-10-09 02:31:28',1,1,0,0),(557748,0,-8,'MALAY ','2014-10-09 02:31:28',1,-1,0,0),(557749,0,-8,'THAI ','2014-10-09 02:31:28',1,-1,0,0),(557750,0,-8,'CHINESE','2014-10-09 02:31:28',1,-1,0,0),(557751,0,-8,'CHINESE ','2014-10-09 02:31:28',1,-1,0,0),(557752,0,-8,'CAUCASIAN','2014-10-09 02:31:28',1,-1,0,0),(557753,0,-8,'JAPANESE','2014-10-09 02:31:28',1,-1,0,0),(557754,0,-8,'KOREAN','2014-10-09 02:31:28',1,-1,0,0),(557755,0,-8,'BUGIS','2014-10-09 02:31:28',1,1,0,0),(557756,0,-8,'EURASIAN','2014-10-09 02:31:28',1,1,0,0),(557757,0,-8,'SINGAPOREAN','2014-10-09 02:31:28',1,-1,0,0),(557758,0,-8,'THAI','2014-10-09 02:31:28',1,-1,0,0),(557759,0,-8,'INDIAN','2014-10-09 02:31:28',1,-1,0,0),(557760,0,-8,'PAKISTANI','2014-10-09 02:31:28',1,-1,0,0),(557761,0,-8,'MALABARI','2014-10-09 02:31:28',1,1,0,0),(557762,0,-8,'BURNESE  ','2014-10-09 02:31:28',1,1,0,0),(557763,0,-8,'CHINESE  ','2014-10-09 02:31:28',1,-1,0,0),(557764,0,-8,'PAKISTAN INDIAN','2014-10-09 02:31:28',1,1,0,0),(557765,0,-8,'FILIPINO','2014-10-09 02:31:28',1,1,0,0),(557766,0,-8,'PAKISTAN','2014-10-09 02:31:28',1,-1,0,0),(557767,0,-8,'EURASIAN ','2014-10-09 02:31:28',1,-1,0,0),(557768,0,-8,'INDONESIAN','2014-10-09 02:31:28',1,1,0,0),(557769,0,-8,'SIKH','2014-10-09 02:31:28',1,-1,0,0),(557770,0,-8,'PAKISTANI','2014-10-09 02:31:28',1,1,0,0),(557771,0,-8,'THAI','2014-10-09 02:31:28',1,1,0,0),(557773,0,-8,'INDONESIAN','2014-10-09 02:31:28',1,-1,0,0),(557774,0,-8,'BRAZILIAN','2014-10-09 02:31:28',1,1,0,0),(557775,0,-8,'BARZILIAN','2014-10-09 02:31:28',1,-1,0,0),(557776,0,-8,'JAVANESE','2014-10-09 02:31:28',1,-1,0,0),(557777,0,-8,'AFRICAN','2014-10-09 02:31:28',1,-1,0,0),(557778,0,-8,'CHILEAN','2014-10-09 02:31:28',1,1,0,0),(557779,0,-8,'PUNJABI','2014-10-09 02:31:28',1,1,0,0),(557780,0,-8,'AMBONESE','2014-10-09 02:31:28',1,1,0,0),(557781,0,-8,'SIKH','2014-10-09 02:31:28',1,1,0,0),(557782,0,-8,'CHINESE','2014-10-09 02:31:28',1,-1,0,0),(557783,0,-8,'JAVANESE','2014-10-09 02:31:28',1,-1,0,0),(557784,0,-8,'INDIAN','2014-10-09 02:31:28',1,-1,0,0),(557785,0,-8,'BOYANESE','2014-10-09 02:31:28',1,-1,0,0),(557786,0,-8,'PUNJABI','2014-10-09 02:31:28',1,-1,0,0),(557787,0,-8,'INDIAH ','2014-10-09 02:31:28',1,-1,0,0),(557788,0,-8,'IGBO','2014-10-09 02:31:28',1,1,0,0),(557789,0,-8,'URBOBO','2014-10-09 02:31:28',1,1,0,0),(557790,0,-8,'TUNISIAN','2014-10-09 02:31:28',1,1,0,0),(557791,0,-8,'BAMILEKE','2014-10-09 02:31:28',1,1,0,0),(557792,0,-8,'DOUALA','2014-10-09 02:31:28',1,1,0,0),(557793,0,-8,'IMBO','2014-10-09 02:31:28',1,1,0,0),(557794,0,-8,'IND/MUS','2014-10-09 02:31:28',1,-1,0,0),(557795,0,-8,'ARAB','2014-10-09 02:31:28',1,1,0,0),(557796,0,-8,'EGYPTIAN','2014-10-09 02:31:28',1,1,0,0),(557797,0,-8,'IRANIAN','2014-10-09 02:31:28',1,1,0,0),(557798,0,-8,'SINGAPORE','2014-10-09 02:31:28',1,-1,0,0),(557799,0,-8,'KOREAN','2014-10-09 02:31:28',1,1,0,0),(557800,0,-8,'CEYLONESE','2014-10-09 02:31:28',1,1,0,0),(557801,0,-8,'NEPALESE','2014-10-09 02:31:28',1,-1,0,0),(557802,0,-8,'INDON','2014-10-09 02:31:28',1,-1,0,0),(557803,0,-8,'MALAYEE','2014-10-09 02:31:28',1,-1,0,0),(557804,0,-8,'EURASIAN','2014-10-09 02:31:28',1,-1,0,0),(557805,0,-8,'PUNJAB','2014-10-09 02:31:28',1,-1,0,0),(557806,0,-8,'VIETNAMESE','2014-10-09 02:31:28',1,1,0,0),(557807,0,-8,'NIGERIAN','2014-10-09 02:31:28',1,-1,0,0),(557808,0,-8,'DANISH','2014-10-09 02:31:28',1,1,0,0),(557809,0,-8,'OTHER','2014-10-09 02:31:28',1,1,0,0),(557810,0,-8,'CHINA','2014-10-09 02:31:28',1,-1,0,0),(557811,0,-8,'FRENCH','2014-10-09 02:31:28',1,1,0,0),(557812,0,-8,'FRANCE','2014-10-09 02:31:28',1,-1,0,0),(557813,0,-8,'CAUCIACIAN','2014-10-09 02:31:28',1,-1,0,0),(557814,0,-8,'MORROCO','2014-10-09 02:31:28',1,1,0,0),(557815,0,-8,'SWEDEN','2014-10-09 02:31:28',1,-1,0,0),(557816,0,-8,'SWEDEN','2014-10-09 02:31:28',1,1,0,0),(557817,0,-8,'SINGAPOREAN','2014-10-09 02:31:28',1,-1,0,0),(557818,0,-8,'FILIPPINO','2014-10-09 02:31:28',1,-1,0,0),(557819,0,-8,'LATIN','2014-10-09 02:31:28',1,1,0,0),(557820,0,-8,'INDIAN MUSLIM','2014-10-09 02:31:28',1,1,0,0),(557821,0,-53,'Sikh','2014-10-09 02:34:47',1,1,0,0),(557822,0,-8,'KOREA','2014-10-09 02:31:28',1,-1,0,0),(557823,0,-8,'GURKHA','2014-10-09 02:31:28',1,1,0,0),(557824,0,-8,'NEPALESE','2014-10-09 02:31:28',1,1,0,0),(557828,0,-8,'EUROPEAN','2014-10-09 02:31:28',1,1,0,0),(558004,0,-37,'Moving House','2014-06-25 05:13:57',1,1,0,1),(558005,0,-38,'Owe Money','2014-06-25 06:14:46',1,1,0,1);
/*!40000 ALTER TABLE `tblDefCodes` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2014-10-09 13:53:03
