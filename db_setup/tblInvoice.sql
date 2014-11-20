CREATE TABLE tblInvoice (
    intInvoiceID int not null auto_increment,
	strInvoiceNumber varchar(15),
	tTimeStamp timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	constraint primary key(intInvoiceID) 
);
	
