ALTER TABLE `tblRegistrationItem` 
ADD COLUMN `strISOCountry_IN` varchar(200) DEFAULT NULL,
ADD COLUMN `strISOCountry_NOTIN` varchar(200) DEFAULT NULL;