
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
			$resultHTML = queryInvoiceByNumber($a, $Data, $invoiceNumber, $client);
			
			if(!$resultHTML){				
				$action = 'TXN_PAY_INV_INFO';
			}			
		}
		else {
			
			$resultHTML = displayQueryByOtherInfoFields($Data, $client, $invoiceNumber);	
		}
	}
	if($action eq 'TXN_PAY_INV_INFO'){ 
		$resultHTML = displayQueryByOtherInfoFields($Data, $client, $invoiceNumber);			
	}
	if($action eq 'TXN_PAY_INV_QUERY_INFO'){
		$resultHTML = queryInvoiceByOtherInfo($Data, $clubID, $client);
		if(!$resultHTML){
			$resultHTML = '
			<div class="col-md-12 error-alerts">
				<div class="alert">
					<div>
						<span class="fa fa-exclamation"></span>
						No Results Found.
					</div>
				</div>
		   </div>';
		}
	}

	if($action eq 'TXN_PAY_INV_RESULT_P'){
		use Payments;
		my $success;
		my $intTransLogID = param('tl') || 0;
		($success, $resultHTML) = displayPaymentResult($Data, $intTransLogID, 0) ;
		if(!$success){
			use Gateway_Common;
			my $trans_ref = gatewayTransLog($Data, $intTransLogID);
			$trans_ref->{'Lang'} = $Data->{'lang'};
			$resultHTML .= runTemplate(
            $Data,
            $trans_ref,
            'payment/pay_invoice_payment_error.templ'
          );
		}		


	}
	
	return ($resultHTML,$title);
}

sub displayQueryByInvoiceField {
	my ($Data,$clubID, $client) = @_; 
	my %pagecontent = (
			client =>  $client, 
			a => 'TXN_PAY_INV_NUM', 
			Lang => $Data->{'lang'},
	);
	my $form = runTemplate($Data, \%pagecontent,'payment/invoicenum_frm.templ');	
   return $form;
	
} 

sub displayQueryByOtherInfoFields {  
	my ($Data, $client, $invoiceNumber) = @_; 

	#my $query = qq[SELECT intNationalPeriodID, strNationalPeriodName FROM tblNationalPeriod  WHERE intRealmID = ? ORDER BY strNationalPeriodName DESC];
	#my $sth = $Data->{'db'}->prepare($query);
	#$sth->execute($Data->{'Realm'});
	#my %natPeriod = ();
	#while(my $dref = $sth->fetchrow_hashref()){
	#	$natPeriod{$dref->{'intNationalPeriodID'}} = $dref->{'strNationalPeriodName'};
	#}
	#use NationalReportingPeriod;
	
	my $natPeriod = NationalReportingPeriod::getPeriods($Data);
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
			options     => $natPeriod,			
		},
		carryfields =>  {
    		client => $client,
      		a => 'TXN_PAY_INV_QUERY_INFO',
    	},
		invoiceNumber => $invoiceNumber,
		Lang => $Data->{'lang'},
	);

	my $body = runTemplate($Data,\%OtherFormFields,'payment/bulk_invoice_query_fields.templ');
	
	return $body;

	
	
}

sub queryInvoiceByNumber { 
	my ($action, $Data, $invoiceNumber, $client) = @_; 
	
	my $convertedInvoiceNumberToTXNID = invoiceNumToTXN($invoiceNumber);
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
			INNER JOIN tblPersonRegistration_$Data->{'Realm'} ON tblPersonRegistration_$Data->{'Realm'}.intPersonRegistrationID = tblTransactions.intPersonRegistrationID	
			INNER JOIN tblProducts ON tblProducts.intProductID = tblTransactions.intProductID
			INNER JOIN tblPerson ON tblPerson.intPersonID = tblTransactions.intID 
			WHERE tblTransactions.intInvoiceID = $convertedInvoiceNumberToTXNID AND intStatus = 0 
			AND tblTransactions.intRealmID = $Data->{'Realm'} AND intTransLogID = 0 
			AND tblPersonRegistration_$Data->{'Realm'}.strStatus <> 'INPROGRESS'			
	];
	my $sth = $Data->{'db'}->prepare($query);
	$sth->execute();
	my $cl=setClient($Data->{'clientValues'}) || '';
    my %cv=getClient($cl);    
    $cv{'currentLevel'} = $Defs::LEVEL_PERSON;
	my $selectPay;
	while(my $dref = $sth->fetchrow_hashref()){
		$results = 1;
		#my $selectPay = qq[<input type="checkbox" checked="checked" name="act_$dref->{'intTransactionID'}" class="paytxn_chk" />];
		$selectPay .= qq[<input type="hidden" name="act_$dref->{'intTransactionID'}" value="1" />];	
		$cv{'personID'} = $dref->{'intPersonID'};
        my $clm=setClient(\%cv);
		push @rowdata, {
			id => $dref->{'intTransactionID'},
			SelectLink => qq[$Data->{'target'}?client=$clm&amp;a=P_TXN_EDIT&personID=$dref->{'intPersonID'}&amp;tID=$dref->{intTransactionID}&amp;id=0],
			#selectpay => $selectPay,
			invoiceNum => $dref->{'strInvoiceNumber'},
			item => $dref->{'strName'},
			person => $dref->{'strLocalFirstname'} . ' ' . $dref->{'strLocalSurname'},
			quantity => $dref->{'intQty'},
			amount => $dref->{'TotalAmount'},
			status => $Defs::TransactionStatus{$dref->{'intStatus'}},			
		};
		
	}
 	
	#my $body = displayResults($Data,\@rowdata,$client);
my @headers = (
	{
		name => '', 
		field => 'SelectLink', 
	    type => 'Selector', 
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
   		 rowdata => \@rowdata,   	    
   	     gridid => 'grid',
  	     width => '99%',
    );

	### payment settings ###
	my (undef, $paymentTypes) = getPaymentSettings($Data, 0, 0, $Data->{'clientValues'}); 
	my $gatewayCount = 0;
	my $paymentType = 0;
	my $gateway_body = qq[ <div id = "payment_cc" style= "display:block;"><br> ];
	foreach my $gateway (@{$paymentTypes})  {
    	$gatewayCount++;
     	 my $id = $gateway->{'intPaymentConfigID'};
   		 my $pType = $gateway->{'paymentType'};
    	 $paymentType = $pType;
      	 my $name = $gateway->{'gatewayName'};
  		 $gateway_body .= qq[
            <input type="submit" onclick="clicked='paytry.cgi'" name="cc_submit[$gatewayCount]" value="]. $Data->{'lang'}->txt("Pay Invoices Now").qq[" class = "btn-main"><br><br>
            <input type="hidden" name="pt_submit[$gatewayCount]" value="$paymentType">
        ];   		 
    	}
	 $gateway_body .= qq[
        <div style= "clear:both;"></div>
        </div>
    ];
	$gateway_body = '' if ! $gatewayCount;
    my %Hidden = (
        gatewayCount => $gatewayCount,		
    );

	my ($Second, $Minute, $Hour, $Day, $Month, $Year, $WeekDay, $DayOfYear, $IsDST) = localtime(time);
    $Year+=1900;
    $Month++;
    my $currentDate="$Day/$Month/$Year";
	$gateway_body = '' if ! $Data->{'SystemConfig'}{'AllowTXNs_CCs'};
	for my $i (qw(intAmount strBank strBSB strAccountNum strAccountName strResponseCode strResponseText strReceiptRef strComments intPartialPayment))	{
		  $Data->{params}{$i}='' if !defined $Data->{params}{$i};
	}
	my $target = 'paytry.cgi';#$Data->{'target'};

	## end payment settings
	my %PageData = (
		grid => $grid, 
		gateway_body => $gateway_body,
		nextAction => 'P_TXNLogstep2', 
        target => $target,
        Lang => $Data->{'lang'},
        client => $client,
        hidden_ref => \%Hidden,
		transactions => $selectPay,
	);
    my $body = runTemplate($Data, \%PageData, 'payment/bulkinvoicelisting.templ') || '';
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
	ON (tblPersonRegistration_$Data->{'Realm'}.intPersonRegistrationID = tblTransactions.intPersonRegistrationID AND tblPersonRegistration_$Data->{'Realm'}.intPersonID = tblTransactions.intID)
	INNER JOIN tblInvoice ON tblInvoice.intInvoiceID = tblTransactions.intInvoiceID 
	INNER JOIN tblProducts ON tblProducts.intProductID = tblTransactions.intProductID
	INNER JOIN tblPerson ON tblPerson.intPersonID = tblTransactions.intID 
	WHERE intStatus = 0 AND strPersonType = '$strPersonType'  
	AND tblPersonRegistration_$Data->{'Realm'}.strStatus <> 'INPROGRESS' 
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
		
		my $selectPay = qq[<input type="checkbox" name="act_$dref->{'intTransactionID'}" class="paytxn_chk" value="$dref->{'TotalAmount'}" />];	
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
	my($Data,$rowdata,$client,$personIDs_ref) = @_;

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
	my $gateway_body = qq[ <div id = "payment_cc" style= "display:none;"><br> ];
	foreach my $gateway (@{$paymentTypes})  {
    	$gatewayCount++;
     	 my $id = $gateway->{'intPaymentConfigID'};
   		 my $pType = $gateway->{'paymentType'};
    	 $paymentType = $pType;
      	 my $name = $gateway->{'gatewayName'};
  		 $gateway_body .= qq[
            <input type="submit" onclick="clicked='paytry.cgi'" name="cc_submit[$gatewayCount]" value="]. $Data->{'lang'}->txt("Pay Invoices Now").qq[" class = "btn-main"><br><br>
            <input type="hidden" name="pt_submit[$gatewayCount]" value="$paymentType">
        ];   		 
    	}
	 $gateway_body .= qq[
        <div style= "clear:both;"></div>
        </div>
    ];
	$gateway_body = '' if ! $gatewayCount;
    my %Hidden = (
        gatewayCount => $gatewayCount,
    );

	my ($Second, $Minute, $Hour, $Day, $Month, $Year, $WeekDay, $DayOfYear, $IsDST) = localtime(time);
    $Year+=1900;
    $Month++;
    my $currentDate="$Day/$Month/$Year";
	$gateway_body = '' if ! $Data->{'SystemConfig'}{'AllowTXNs_CCs'};
	for my $i (qw(intAmount strBank strBSB strAccountNum strAccountName strResponseCode strResponseText strReceiptRef strComments intPartialPayment))	{
		  $Data->{params}{$i}='' if !defined $Data->{params}{$i};
	}

	my $allowManualPayments = 1;
    $allowManualPayments = 0 if ($Data->{'clientValues'}{'authLevel'} == $Defs::LEVEL_CLUB and ! allowedAction($Data, 'm_mp'));
	$allowManualPayments = 0 if ($Data->{'clientValues'}{'authLevel'} == $Defs::LEVEL_CLUB and $Data->{'clientValues'}{'currentLevel'}  == $Defs::LEVEL_PERSON and ! allowedAction($Data, 'm_mp'));
	$allowManualPayments = 0 if ($Data->{'clientValues'}{'authLevel'} == $Defs::LEVEL_CLUB and $Data->{'clientValues'}{'currentLevel'}  == $Defs::LEVEL_CLUB  and ! allowedAction($Data, 't_tp'));
    $allowManualPayments = 0 if $Data->{'ReadOnlyLogin'};	

	my $allowMP = 1;
    $allowMP = 0 if !$allowManualPayments;
    $allowMP = 0 if $Data->{'SystemConfig'}{'DontAllowManualPayments_Invoice'};

	 my $orstring = '';
     $orstring = qq[&nbsp; <b>].$Data->{'lang'}->txt('OR').qq[</b> &nbsp;] if $gateway_body and $allowMP;
     if($paymentType==0){ $paymentType='';}
   
	
	if ($allowMP){
	$gateway_body .= qq[
						<h3 class="panel-header sectionheader" id="manualpayment">].$Data->{'lang'}->txt('Manual Payment').qq[</h3>
				  		<div id="secmain2" class="panel-body fieldSectionGroup ">
				  			<fieldset>
				  				<div class="form-group">
				  					<label for="l_intAmount" class="col-md-4 control-label txtright"><span class="compulsory">*</span>].$Data->{'lang'}->txt('Amount (ddd.cc)').qq[</label>
				  					<div class="col-md-6"><input type="text" name="intAmount" value="$Data->{params}{intAmount}" id="l_intAmount" size="10"  /></div>
				  				</div>
				  				<div class="form-group">
				  					<label for="l_dtLog" class="col-md-4 control-label txtright"><span class="compulsory">*</span>].$Data->{'lang'}->txt('Date Paid').qq[</label>
				  					<div class="col-md-6"><input type="text" name="dtLog" value="$currentDate" id="l_dtLog" size="10" maxlength="10" /> <span class="HTdateformat">dd/mm/yyyy</span></div>
				  				</div>
				  				<div class="form-group">
				  					<label for="l_intPaymentType" class="col-md-4 control-label txtright"><span class="compulsory">*</span>].$Data->{'lang'}->txt('Payment Type').qq[</label>
				  					<div class="col-md-6">].drop_down('paymentType',\%Defs::manualPaymentTypes, undef, $paymentType, 1, 0,'','').qq[</div>
				  				</div>
				  				<div class="form-group">
				  					<label for="l_strComments" class="col-md-4 control-label txtright"><span class="compulsory">*</span>].$Data->{'lang'}->txt('Comments').qq[</label>
				  					<div class="col-md-6"><textarea name="strComments" id="l_strComments" style="width: 100%; height: 200px;">$Data->{params}{strComments}</textarea></div>
				  				</div>
				  			</fieldset>
				  		</div>
					  	<div class="button-row">
							<div class="txtright" id="block-manualpay" style="display:none">
								<input onclick="clicked='main.cgi'" type="submit" name="subbut" value="Submit Manual Payment" class="btn-main" id = "btn-manualpay" >
								<input type="hidden" name="paymentID" value="">
								<input type="hidden" name="dt_start_paid" value="">
								<input type="hidden" name="dt_end_paid" value="">
							</div>
						</div>
			] 

	}

my $target = 'paytry.cgi';#$Data->{'target'};

	## end payment settings
	my %PageData = (
		grid => $grid, 
		gateway_body => $gateway_body,
		nextAction => 'P_TXNLogstep2', 
        target => $target,
        Lang => $Data->{'lang'},
        client => $client,
        hidden_ref => \%Hidden,
	);
    my $body = runTemplate($Data, \%PageData, 'payment/bulkinvoicelisting.templ') || '';

	return $body;
}
1;
