DELIMITER ;;
create procedure addcol(
	IN colTable VARCHAR(255),
	IN colName VARCHAR(255),
	IN colProperty VARCHAR(500),
	IN colComment VARCHAR(255)
)
begin
    IF NOT EXISTS(
		SELECT * FROM information_schema.COLUMNS 
		WHERE 
			COLUMN_NAME=colName AND 
			TABLE_NAME=colTable
	)
	THEN
		SET @c = CONCAT("ALTER TABLE ",colTable," ADD COLUMN ",colName," ",colProperty);
	ELSE
		SET @c = CONCAT("ALTER TABLE ",colTable," CHANGE COLUMN ",colName," ",colName," ",colProperty);

	END IF;
	IF colComment IS NOT NULL THEN
		SET @c = CONCAT( @c," COMMENT '",colComment,"'");
	END IF;
	PREPARE stmt from @c;
	EXECUTE stmt;
	DEALLOCATE PREPARE stmt;

END;;
