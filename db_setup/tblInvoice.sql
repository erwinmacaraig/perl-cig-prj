CREATE TABLE tblInvoice (
    intInvoiceID int not null auto_increment,
	strInvoiceNumber varchar(15),
    intRealmID int,
	tTimeStamp timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	constraint primary key(intInvoiceID) 
)DEFAULT CHARACTER SET=utf8;
