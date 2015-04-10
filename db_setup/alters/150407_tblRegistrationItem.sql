ALTER TABLE tblRegistrationItem
    ADD COLUMN intItemUsingActiveFilter tinyint default 0 COMMENT 'Using Active Periods filter',
    ADD COLUMN strItemActiveFilterPeriods varchar(10) default '' COMMENT 'Which Periods to check Active on',
    ADD COLUMN intItemActive tinyint default 0 COMMENT 'Active status if Active Periods filter on';
