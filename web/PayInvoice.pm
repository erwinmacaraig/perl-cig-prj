
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
use Data::Dumper;

use GridDisplay;

sub handlePayInvoice {
	my($action, $Data, $clubID)=@_;

	my $resultHTML = '';
	my %Flow = ();
  	my $title = 'Pay Invoice';
	my $invoiceNumber = param('strInvoiceNumber') || '';
	$invoiceNumber =~ s/^\s+//;
    $Flow{'TXN_PAY_INV_NUM_M'} = 'TXN_PAY_INV_INFO'; # 
    $Flow{'TXN_PAY_INV_INFO'} = 'TXN_PAY_INV_QUERY_INFO'; #
    $Flow{'TXN_PAY_INV_NUM'} = 'TXN_PAY_INV_CONFIRM'; 


    my $client = setClient($Data->{'clientValues'}) || '';
	$resultHTML = displayQueryByInvoiceField($Data, $clubID, $client);
    

	if($action eq 'TXN_PAY_INV_NUM'){
		
		if(length($invoiceNumber) > 0 || $invoiceNumber ne '' ){
			$a = $Flow{$action};
			$resultHTML = queryInvoiceByNumber($a, $Data, $clubID, $invoiceNumber, $client);
			#Query Transactions Here 
			#my @invoicearr = queryInvoiceByNumber($action, $Data, $clubID,$invoiceNumber);
			if(!$resultHTML){
				# found Invoice Number - Display Results

				$action = 'TXN_PAY_INV_INFO';
			}			
		}
		else {
			#$action = $Flow{'TXN_PAY_INV_INFO'}; 
			$resultHTML = displayQueryByOtherInfoFields($Data, $clubID, $client, $invoiceNumber);	
		}
	}
	if($action eq 'TXN_PAY_INV_INFO'){ 
		$resultHTML = displayQueryByOtherInfoFields($Data, $clubID, $client, $invoiceNumber);			
	}
	if($action eq 'TXN_PAY_INV_QUERY_INFO'){
		$resultHTML = queryInvoiceByOtherInfo($Data, $clubID, $client);
		if(!$resultHTML){
			$resultHTML = '<h3> No Results Found </h3>';
		}
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
	my ($Data, $clubID, $client, $invoiceNumber) = @_; 

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
      		a => 'TXN_PAY_INV_QUERY_INFO',
    	},
		invoiceNumber => $invoiceNumber,
	);

	my $body = runTemplate($Data,\%OtherFormFields,'payment/bulk_invoice_query_fields.templ');
	
	return $body;

	
	
}

sub queryInvoiceByNumber { 
	my ($action, $Data, $clubID, $invoiceNumber, $client) = @_; 

	#convert invoice number to transaction 
	# 100000405
	my $convertedInvoiceNumberToTXNID = invoiceNumToTXN($invoiceNumber);
<<<<<<< HEAD
	#my $convertedInvoiceNumberToTXNID = TXNtoInvoiceNum($invoiceNumber);
=======
	#my $convertedInvoiceNumberToTXNID = TXNtoTXNNumber($invoiceNumber);
	
	return "<br /><h1> $convertedInvoiceNumberToTXNID </h1>";
	#my $query = qq[SELECT ];

>>>>>>> 210db9d45411a43198ee6827b0abcf3e0eddc9af

	my $content = '';
	my $results = 0;
	my @rowdata = ();
	my $query = qq[
		SELECT 
			tblTransactions.intTransactionID,
			tblInvoice.strInvoiceNumber, 
			tblTransactions.intQty, 
			tblTransactions.intStatus,
			tblProducts.strName, 
			tblPerson.strLocalFirstname,
			tblPerson.strLocalSurname,
			tblPerson.intPersonID, 
			(tblTransactions.curAmount * tblTransactions.intQty) as TotalAmount 
			FROM tblTransactions INNER JOIN tblInvoice ON tblInvoice.intInvoiceID = tblTransactions.intInvoiceID
			INNER JOIN tblProducts ON tblProducts.intProductID = tblTransactions.intProductID
			INNER JOIN tblPerson ON tblPerson.intPersonID = tblTransactions.intID 
			WHERE tblTransactions.intInvoiceID = $convertedInvoiceNumberToTXNID AND intStatus = 0 
			AND tblTransactions.intRealmID = $Data->{'Realm'} AND intTransLogID = 0 AND intTXNEntityID = $clubID
	];
	
	my $sth = $Data->{'db'}->prepare($query);
	$sth->execute();
	my $cl=setClient($Data->{'clientValues'}) || '';
    my %cv=getClient($cl);    
    $cv{'currentLevel'} = $Defs::LEVEL_PERSON;
	while(my $dref = $sth->fetchrow_hashref()){
		$results = 1;
		my $selectPay = qq[<input type="checkbox" name="act_$dref->{'intTransactionID'}" class="paytxn_chk" />];
		$cv{'personID'} = $dref->{'intPersonID'};
        my $clm=setClient(\%cv);
		push @rowdata, {
			id => $dref->{'intTransactionID'},
			SelectLink => qq[$Data->{'target'}?client=$clm&amp;a=P_TXN_EDIT&personID=$dref->{'intPersonID'}&amp;tID=$dref->{intTransactionID}&amp;id=0],
			selectpay => $selectPay,
			invoiceNum => $dref->{'strInvoiceNumber'},
			item => $dref->{'strName'},
			person => $dref->{'strLocalFirstname'} . ' ' . $dref->{'strLocalSurname'},
			quantity => $dref->{'intQty'},
			amount => $dref->{'TotalAmount'},
			status => $Defs::TransactionStatus{$dref->{'intStatus'}},
		};
	}
 	
	my $body = displayResults($Data,\@rowdata,$client);
	return $body if($results);
	return $results;
	
}

sub queryInvoiceByOtherInfo { 
	my ($Data, $clubID, $client) = @_;	
	
	my @whereClause = ();
	
	#PersonType is required 

	#get posted values 
	my $strPersonType = param('PersonType') || '';
		
	my $strSport = param('Sport') || ''; 
	if($strSport){
		push @whereClause, " AND strSport = '$strSport' ";
	}	
	my $strPersonLevel = param('PersonLevel') || '';

	if($strPersonLevel){
		push @whereClause, " AND strPersonLevel = '$strPersonLevel' "
	}
	my $strAgeLevel = param('AgeLevel') || ''; 
	if($strAgeLevel){
		push @whereClause, " AND strAgeLevel = '$strAgeLevel' "
	}
	my $intNationalPeriod = param('NationalPeriod') || 0;
	if($intNationalPeriod){
		push @whereClause, " AND intNationalPeriodID = $intNationalPeriod "
	}
	
	my $query = qq[
    SELECT 
	tblTransactions.intTransactionID,
	tblInvoice.strInvoiceNumber, 
	tblTransactions.intQty, 
	tblTransactions.intStatus,
	tblProducts.strName, 
	tblPerson.strLocalFirstname,
	tblPerson.strLocalSurname,
	tblPerson.intPersonID,
	(tblTransactions.curAmount * tblTransactions.intQty) as TotalAmount 
	FROM tblTransactions INNER JOIN tblPersonRegistration_$Data->{'Realm'}
	ON (tblPersonRegistration_1.intPersonRegistrationID = tblTransactions.intPersonRegistrationID AND tblPersonRegistration_$Data->{'Realm'}.intPersonID = tblTransactions.intID)
	INNER JOIN tblInvoice ON tblInvoice.intInvoiceID = tblTransactions.intInvoiceID 
	INNER JOIN tblProducts ON tblProducts.intProductID = tblTransactions.intProductID
	INNER JOIN tblPerson ON tblPerson.intPersonID = tblTransactions.intID 
	WHERE intStatus = 0 AND strPersonType = '$strPersonType' 
	@whereClause
	];	

	my $sth = $Data->{'db'}->prepare($query); 
	$sth->execute();

	 my $cl=setClient($Data->{'clientValues'}) || '';
     my %cv=getClient($cl);    
     $cv{'currentLevel'} = $Defs::LEVEL_PERSON;
	 

	my $results = 0;
	my @rowdata = ();
	while(my $dref = $sth->fetchrow_hashref()){
		$results = 1;
		my $selectPay = qq[<input type="checkbox" name="act_$dref->{'intTransactionID'}" class="paytxn_chk" />];	
		$cv{'personID'} = $dref->{'intPersonID'};
        my $clm=setClient(\%cv);	
		push @rowdata, {
			id => $dref->{'intTransactionID'},
			SelectLink => qq[$Data->{'target'}?client=$clm&amp;a=P_TXN_EDIT&personID=$dref->{'intPersonID'}&amp;tID=$dref->{intTransactionID}&amp;id=0],
			selectpay => $selectPay,
			invoiceNum => $dref->{'strInvoiceNumber'},
			item => $dref->{'strName'},
			person => $dref->{'strLocalFirstname'} . ' ' . $dref->{'strLocalSurname'},
			quantity => $dref->{'intQty'},
			amount => $dref->{'TotalAmount'},
			status => $Defs::TransactionStatus{$dref->{'intStatus'}},
		};
	}
 	my $body = displayResults($Data,\@rowdata,$client);
	return $body if($results);
	return $results;			
}

sub displayResults {
	my($Data,$rowdata,$client) = @_;

	my @headers = (
	{
		name => '', 
		field => 'SelectLink', 
	    type => 'Selector', 
	},
	{
	  name => 'Pay',
	  field => 'selectpay',
	  width => 20,
      type => 'HTML',
    },
    {
      name => $Data->{'lang'}->txt('Invoice Number'),
      field => 'invoiceNum',
    },
    {
      name =>   $Data->{'lang'}->txt('Item'),
      field =>  'item',
    },
    {
      name =>   $Data->{'lang'}->txt('Person'),
      field =>  'person',
    },
	{
		name => $Data->{'lang'}->txt('Quantity'),
		field => 'quantity',
	},
	{
		name => $Data->{'lang'}->txt('Amount'),
		field => 'amount',
	},
	{
		name => $Data->{'lang'}->txt('Status'),
		field => 'status', 
	}
	);
	 my $grid  = showGrid(
   		 Data => $Data,
     	 columns => \@headers,
   		 rowdata => $rowdata,   	    
   	     gridid => 'grid',
  	     width => '99%',
    );

	### payment settings ###
	my (undef, $paymentTypes) = getPaymentSettings($Data, 0, 0, $Data->{'clientValues'}); 
	my $gatewayCount = 0;
	my $paymentType = 0;
	my $gateway_body = qq[ <div id = "payment_cc" style= "display:hidden;"><br> ];
	foreach my $gateway (@{$paymentTypes})  {
    	$gatewayCount++;
     	 my $id = $gateway->{'intPaymentConfigID'};
   		 my $pType = $gateway->{'paymentType'};
    	 $paymentType = $pType;
      	 my $name = $gateway->{'gatewayName'};
   		 $gateway_body .= qq[
     	       <input type="submit" name="cc_submit[$gatewayCount]" value="]. $Data->{'lang'}->txt("Pay via").qq[ $name" class = "button proceed-button"><br><br>
     	       <input type="hidden" value="$pType" name="pt_submit[$gatewayCount]">
      	  ];
    	}
	$gateway_body .= qq[
        <input type="hidden" value="$gatewayCount" name="gatewayCount">
        <div style="clear:both;"></div>
        </div>
    ];
	$gateway_body = '' if ! $gatewayCount;
	## end payment settings
	my %PageData = (
		grid => $grid, 
		gateway_body => $gateway_body,
		nextAction => 'P_TXNLogstep2', 
        target => 'main.cgi',
        Lang => $Data->{'lang'},
        client => $client,
	);
    my $body = runTemplate($Data, \%PageData, 'payment/bulkinvoicelisting.templ') || '';

	return $body;
}




	
	








1;
