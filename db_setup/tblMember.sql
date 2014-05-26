DROP TABLE tblMember;
 
#
#
CREATE table tblMember (
    intMemberID     				INT NOT NULL AUTO_INCREMENT,
    strExtKey					VARCHAR(20) NOT NULL, 
    strMemberNo     				VARCHAR (15) NOT NULL,
    strFirstname   		 		VARCHAR (50),
    strMiddlename   		 		VARCHAR (50),
    strSurname    		 		VARCHAR (50),
    strAddress1     				VARCHAR (100),
    strAddress2   		  		VARCHAR (100),
    strSuburb     		  		VARCHAR (100),
    strState        				VARCHAR (50),
    strPostalCode   				VARCHAR (15),
    strCountry    		  		VARCHAR (100),
    strSalutation 				VARCHAR (10),
    dtDOB           				DATE,
    intGender       				TINYINT,
    strMaidenName           			VARCHAR (50),
    strPhoneHome    				VARCHAR (20),
    strPhoneWork    				VARCHAR (20),
    strPhoneMobile  				VARCHAR (20),
    strFax          				VARCHAR (20),
    strPager					VARCHAR (20),
    strEmail       		 		VARCHAR (200),
    strMemberPackage				VARCHAR(30),
    dtFirstRegistered    			DATE,
    dtLastRegistered    			DATE,
    dtLastUpdate				DATETIME,
    curMemberFinBal				DECIMAL(12,2),
    strLoyaltyNumber				VARCHAR(20),
    intEthnicityID				TINYINT,
    intOccupationID			  	VARCHAR (5),
    intMailingList			  	TINYINT DEFAULT 1,
    intLifeMember			  	TINYINT DEFAULT 0,
    intStatus       				INTEGER NOT NULL,
    strNotes					TEXT,
		strPlaceofBirth					VARCHAR(45),
		strCityOfResidence			VARCHAR(45),
		strPassportNo						VARCHAR(25),
		strPassportNationality	VARCHAR(100),
		dtPassportExpiry				DATE,
		strEmergContName				VARCHAR(100),
		strEmergContNo  				VARCHAR(100),
		strEyeColour  				VARCHAR(30),
		strHairColour  				VARCHAR(30),
		strHeight  						VARCHAR(20),
		strWeight  						VARCHAR(20),
    intDeceased				  	TINYINT,
		strP1FName						VARCHAR(50),
		strP1SName						VARCHAR(50),
		strP2FName						VARCHAR(50),
		strP2SName						VARCHAR(50),
		strBirthCertNo 				VARCHAR(50),
		strHealthCareNo 			VARCHAR(50),
		intIdentTypeID				INT,
		strIdentNum						VARCHAR(20),
		strCustomStr1					VARCHAR(30),
		strCustomStr2					VARCHAR(30),
		strCustomStr3					VARCHAR(30),
		strCustomStr4					VARCHAR(30),
		strCustomStr5					VARCHAR(30),
		strCustomStr6					VARCHAR(30),
		strCustomStr7					VARCHAR(30),
		strCustomStr8					VARCHAR(30),
		dblCustomDbl1					DOUBLE DEFAULT 0,
		dblCustomDbl2					DOUBLE DEFAULT 0,
		dblCustomDbl3					DOUBLE DEFAULT 0,
		dblCustomDbl4					DOUBLE DEFAULT 0,
		dtCustomDt1					DATE,
		dtCustomDt2					DATE,
		intCustomLU1					INT DEFAULT 0,
		intCustomLU2					INT DEFAULT 0,
		intCustomLU3					INT DEFAULT 0,
		strNationalNum				VARCHAR(30),
		dtSuspendedUntil			DATE,
		intActive							TINYINT DEFAULT 0,
		intPlayer							TINYINT DEFAULT 0,
		intCoach							TINYINT DEFAULT 0,
		intUmpire							TINYINT DEFAULT 0,
		intOfficial						TINYINT DEFAULT 0,
		intMisc 							TINYINT DEFAULT 0,
		intPhoto							TINYINT DEFAULT 0,

PRIMARY KEY (intMemberID),
	KEY index_strMemberNo(strMemberNo),
	KEY index_intStatus(intStatus),
	KEY index_strExtKey(strExtKey),
	KEY index_strSurname(strSurname),
	KEY index_strFirstname(strFirstname),
	KEY index_dtDOB(dtDOB),
	KEY index_intGender(intGender),
	KEY index_strNationalNum(strNationalNum),
	KEY index_intActive(intActive),
	KEY index_dtLastUpdate(dtLastUpdate),
	KEY index_intPhoto(intPhoto)
);
 
