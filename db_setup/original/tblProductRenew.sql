DROP TABLE IF EXISTS tblProductRenew;
CREATE TABLE tblProductRenew(
	intProductID INT NOT NULL,
	strRenewText1 TEXT,
	strRenewText2 TEXT,
	strRenewText3 TEXT,
	strRenewText4 TEXT,
	strRenewText5 TEXT,
	intRenewDays1  INT DEFAULT 0,
	intRenewDays2  INT DEFAULT 0,
	intRenewDays3  INT DEFAULT 0,
	intRenewDays4  INT DEFAULT 0,
	intRenewDays5  INT DEFAULT 0,
	intRenewProductID INT NOT NULL DEFAULT 0,
	intRenewRegoFormID INT NOT NULL DEFAULT 0,

	PRIMARY KEY (intProductID),
	KEY index_renewproduct(intRenewProductID)
);
