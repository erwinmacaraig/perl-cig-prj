
package PayInvoice;

require Exporter;
@ISA =  qw(Exporter);
@EXPORT = qw(handePayInvoice displayQueryByInvoiceField);
@EXPORT_OK = qw(handlePayInvoice displayQueryByInvoiceField);

use strict;
use CGI qw(param unescape escape);

use lib '.';
use Reg_common;
use Defs;
use Utils;
use FormHelpers;
use HTMLForm;
use AuditLog;

use InvoicePay;
require Payments;
require TransLog;
require PersonRegistration;
use TTTemplate;
use Payments;

sub handlePayInvoice {
	my($action, $Data, $intTableID, $entityID)=@_;
	my $resultHTML = '';
	my %Flow = ();
  	my $title = 'Pay Invoice';

    $Flow{'TXN_PAY_INV_NUM_M'} = 'TXN_PAY_INV_INFO'; # 
    $Flow{'TXN_PAY_INV_INFO'} = 'TXN_PAY_INV_QUERY_INFO'; #
    $Flow{'TXN_PAY_INV_NUM'} = 'TXN_PAY_INV_QUERY_NUM'; 

    #$Flow{'PREGF_PU'} = 'PREGF_C'; #Documents3 
    my $client = setClient($Data->{'clientValues'}) || '';
	$resultHTML = displayQueryByInvoiceField($Data, $intTableID, $client);
    

	if($action eq 'TXN_PAY_INV_NUM'){
		my $invoiceNumber = param('strInvoiceNumber');
		$invoiceNumber =~ s/^\s+//;
		if(length($invoiceNumber) > 0 || $invoiceNumber ne '' ){
			$resultHTML = queryInvoiceByNumber($action, $Data, $intTableID,$invoiceNumber);
			#Query Transactions Here 
			#my @invoicearr = queryInvoiceByNumber($action, $Data, $intTableID,$invoiceNumber);
			if(!$resultHTML){
				# found Invoice Number - Display Results
			}
			#else {
			#	$action = $Flow{$action};
			#}
			
			
		}
		else {
			$action = $Flow{'TXN_PAY_INV_INFO'}; 
			$resultHTML = displayQueryByOtherInfoFields($Data, $intTableID, $client,$action);	
		}
	}
	elsif($action eq 'TXN_PAY_INV_INFO'){ 
		$resultHTML = displayQueryByOtherInfoFields($Data, $intTableID, $client);			
	}
	elsif($action eq 'TXN_PAY_INV_QUERY_INFO'){
		$resultHTML = queryInvoiceByOtherInfo($Data, $intTableID, $client); 
	}

	
	return ($resultHTML,$title);
}

sub displayQueryByInvoiceField {
	my ($Data,$clubID, $client) = @_; 
	my %pagecontent = (
			client =>  $client, 
			a => 'TXN_PAY_INV_NUM', 
	);
	my $form = runTemplate($Data, \%pagecontent,'payment/invoicenum_frm.templ');	
	return $form;
	
} 

sub displayQueryByOtherInfoFields {  
	my ($Data, $clubID, $client, $action) = @_; 
	
	my $query = qq[SELECT intNationalPeriodID, strNationalPeriodName FROM tblNationalPeriod  WHERE intRealmID = ?];
	my $sth = $Data->{'db'}->prepare($query);
	$sth->execute($Data->{'Realm'});
	my %natPeriod = ();
	while(my $dref = $sth->fetchrow_hashref()){
		$natPeriod{$dref->{'intNationalPeriodID'}} = $dref->{'strNationalPeriodName'};
	}

	my %OtherFormFields = (
		PersonType => {
			options     => \%Defs::personType,
		},
		Sport => {
			options     => \%Defs::sportType,
		},	
		PersonLevel => {
			options     => \%Defs::personLevel,
		},
		AgeLevel => {
			options     => \%Defs::ageLevel,
		}, 
		NationalPeriod => {
			options     => \%natPeriod,			
		},
		carryfields =>  {
    		client => $client,
      		a=> $action,
    	},
	);

	my $body = runTemplate($Data,\%OtherFormFields,'payment/bulk_invoice_query_fields.templ');
	
	return $body;

	
	
}

sub queryInvoiceByNumber { 
	my ($Data, $clubID, $client,$invoiceNumber) = @_; 
	#convert invoice number to transaction 
	# 100000405
	my $convertedInvoiceNumberToTXNID = invoiceNumToTXN($invoiceNumber);
	#my $convertedInvoiceNumberToTXNID = TXNtoTXNNumber($invoiceNumber);
	
	return "<br /><h1> $convertedInvoiceNumberToTXNID </h1>";
	#my $query = qq[SELECT ];


}

sub queryInvoiceByOtherInfo { 
	my ($Data, $clubID, $client) = @_;

	my $query = qq[SELECT ];
		
	
	#PersonType is required 
	

	#get posted values 
	my $strPersonType = param('PersonType') || '';
	my $strSport = param('Sport') || '';
	my $strPersonLevel = param('PersonLevel') || '';
	my $strAgeLevel = param('AgeLevel') || ''; 
	my $intNationalPeriod = param('NationalPeriod') || 0;
	
	my $body = "Person Type: " . $strPersonType . "<br />Sport: " . $strSport . "<br /> Person Level : " . $strPersonLevel . "<br />Age Level: " . $strAgeLevel . "<br />National Period: " . $intNationalPeriod; 
	return $body;
			
}

#sub displayResults




	
	








1;
