ALTER TABLE tblRegistrationItem
    ADD COLUMN intItemUsingPaidProductFilter tinyint default 0 COMMENT 'Using Active Products filter',
    ADD COLUMN strItemActiveFilterPaidProducts varchar(10) default '' COMMENT 'Which Products to check Active on',
    ADD COLUMN intItemPaidProducts tinyint default 0 COMMENT 'Active status if Active Products filter on';
