ALTER TABLE tblProducts ADD COLUMN strProductCode varchar(20) default '', ADD COLUMN strProductType varchar(20) default '', CHANGE COLUMN intProductSeasonID intProductNationalPeriodID INT DEFAULT 0;
