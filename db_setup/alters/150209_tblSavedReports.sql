ALTER TABLE tblSavedReports
    MODIFY COLUMN intSavedReportID INT UNSIGNED NOT NULL AUTO_INCREMENT,
    ADD COLUMN intTemporary  TINYINT DEFAULT 0,
    ADD COLUMN ts TIMESTAMP,
    ADD INDEX index_temporary (intTemporary, ts)
;

