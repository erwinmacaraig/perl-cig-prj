ALTER TABLE tblPerson 
ADD COLUMN intMinorMoveOtherThanFootball INT NOT NULL DEFAULT 0 COMMENT 'Flag for minor protection checks. Has the person moved to the country for reasons other than football',
ADD COLUMN intMinorDistance INT NOT NULL DEFAULT 0 COMMENT 'Flag for minor protection checks. Is the distance from the players domicile more than a specified amount',
ADD COLUMN intMinorEU INT NOT NULL DEFAULT 0 COMMENT 'Flag for minor protection checks. Transfer within EU',
ADD COLUMN intMinorNone INT NOT NULL DEFAULT 0 COMMENT 'Flag for minor protection checks. None of the Above'



;
