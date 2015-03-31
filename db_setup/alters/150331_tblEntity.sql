ALTER TABLE tblEntity
CHANGE COLUMN `strAcceptSelfRego` `intAcceptSelfRego` INT NULL DEFAULT 0 COMMENT 'Allow an Entity to determine if they accept self registration FC-231' ;
