call addcol("tblPerson","strLocalFirstname","VARCHAR(150) NULL DEFAULT ''","The firstname of a person in local language (the language specified by LocalNameLanguage attribute).");
call addcol("tblPerson","strLocalMiddlename","VARCHAR(150) NULL DEFAULT ''",NULL);
call addcol("tblPerson","strLocalSurname","VARCHAR(150) NULL DEFAULT ''","The lastname of a person in local language (the language specified by LocalNameLanguage attribute).");
call addcol("tblPerson","strISOMotherCountry","VARCHAR(150) NULL DEFAULT ''",NULL);
call addcol("tblPerson","strISOFatherCountry","VARCHAR(150) NULL DEFAULT ''",NULL);
call addcol("tblPerson","intPhoto","TINYINT NULL DEFAULT 0",NULL);