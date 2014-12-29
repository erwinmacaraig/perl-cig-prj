CREATE TABLE tblITCMessagesLog (
	intITCMessagesLog int not null auto_increment,				 # primary key for storing sent email messages for ITC request
	intEntityFromID int,			       						 # The entity the requested the transfer
	intEntityToID int,   			     						 # The National ID on which to request ITC is being sent
	strFirstname varchar(50),								     # The player's first name
	strSurname varchar(100),								     # The player's last name
	dtDOB date,										             # Player's Date of Birth
	strNationality varchar(50),								     # Player's Naionality
	strPlayerID varchar(20),								     # Player's ID with the previous football club
	strClubCountry varchar(50),								     # Player's previous club country origin
	strClubName varchar(100),								     # Player's previous club name
	dtDateSent timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,	     # Date when the message was sent
	strMessage text DEFAULT NULL,	   							     # The actual message sent
	CONSTRAINT PRIMARY KEY (intITCMessagesLog)
)DEFAULT CHARSET=utf8;
