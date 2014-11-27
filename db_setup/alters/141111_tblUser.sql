ALTER TABLE tblUser
DROP INDEX index_email,
CHANGE COLUMN email username VARCHAR(50) NOT NULL,
ADD UNIQUE INDEX index_username(username);
