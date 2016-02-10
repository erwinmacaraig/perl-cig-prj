
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
use PersonUtils;

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
		#check if Invoice Number is already been paid
		$resultHTML = displayQueryByOtherInfoFields($Data, $client, $invoiceNumber);			
	}
	if($action eq 'TXN_PAY_INV_QUERY_INFO'){
		$resultHTML = queryInvoiceByOtherInfo($Data, $clubID, $client);
		if(!$resultHTML){
			$resultHTML = $Data->{'lang'}->txt('
			<div class="col-md-12 error-alerts">
				<div class="alert">
					<div>
						<span class="fa fa-exclamation"></span>
						No Results Found.
					</div>
				</div>
		   </div>');
		}
	}

	if($action eq 'TXN_PAY_INV_RESULT_P'){
		use Payments;
		my $success;
		my $intTransLogID = param('tl') || 0;		
		($success, $resultHTML) = displayPaymentResult($Data, $intTransLogID, 0);
		my $st = qq[SELECT intID FROM tblTransactions WHERE intTransLogID = $intTransLogID AND intRealmID = $Data->{'Realm'}];
		my $query = $Data->{'db'}->prepare($st);
		$query->execute();
		my @intIDs = ();
		while(my $dref = $query->fetchrow_hashref()){
                    if(! grep /$dref->{'intID'}/,@intIDs){
			push @intIDs,$dref->{'intID'};
                    }
		}		
		my $receiptLink = "printreceipt.cgi?client=$client&ids=$intTransLogID&pID=" . join(",",@intIDs);
		
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
		else {
			$resultHTML .= qq[<br>
							 <br><a href="$receiptLink" target="receipt">]. $Data->{'lang'}->txt('Print Receipt') .qq[</a><br>
            ] if ($success == $Defs::TXNLOG_SUCCESS);
			$resultHTML .= qq[<br>
							 <br><a href="$Data->{'target'}?client=$client&amp;a=P_TXN_LIST">]. $Data->{'lang'}->txt('Return to Transactions') .
							qq[</a><br>
            ];
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
		my %sports = ();
		my %levels = ();
		my $query = qq[SELECT strInvoiceNumber FROM  tblInvoice INNER JOIN tblTransactions ON tblTransactions.intInvoiceID = tblInvoice.intInvoiceID WHERE intStatus = 1 AND intTransLogID <> 0 AND tblTransactions.intRealmID = $Data->{'Realm'} AND strInvoiceNumber = '$invoiceNumber'];	
		my $sth = $Data->{'db'}->prepare($query);
		$sth->execute();
		my $dref = $sth->fetchrow_hashref();
	
		$query = qq[SELECT DISTINCT strSport from tblMatrix Where strWFRuleFor='REGO' AND strSport <> '' AND intRealmID = $Data->{'Realm'}];
		$sth = $Data->{'db'}->prepare($query);
		$sth->execute();
		while(my $data = $sth->fetchrow_hashref()){
			$sports{$data->{'strSport'}} = $Defs::sportType{$data->{'strSport'}};
		}
		
		$query = qq[SELECT DISTINCT strPersonLevel from tblMatrix Where strWFRuleFor='REGO' AND strPersonLevel <> '' AND intRealmID = $Data->{'Realm'}];
		$sth = $Data->{'db'}->prepare($query);
		$sth->execute();
		while(my $data = $sth->fetchrow_hashref()){	
			$levels{$data->{'strPersonLevel'}} = $Defs::personLevel{$data->{'strPersonLevel'}};			
		}
	
	my $natPeriod = NationalReportingPeriod::getPeriods($Data);
	my %OtherFormFields = (
		PersonType => {
			options     => \%Defs::personType,
		},
		Sport => {
			options     => \%sports ,
		},	
		PersonLevel => {
			options     => \%levels,
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
		invoiceNumber => $dref->{'strInvoiceNumber'} || '',
		displayMessage => $invoiceNumber,
		Lang => $Data->{'lang'},
		Level => $Data->{'clientValues'}{'currentLevel'},
	);

	my $body = runTemplate($Data,\%OtherFormFields,'payment/bulk_invoice_query_fields.templ');
	
	return $body;

	
	
}

sub queryInvoiceByNumber { 
	my ($action, $Data, $invoiceNumber, $client) = @_;	
	my $convertedInvoiceNumberToTXNID = invoiceNumToTXN($invoiceNumber);
	my $totalAmount = 0;
	
	my $content = '';
	my $results = 0;
	my @rowdata = ();
	#
	my $intTXNEntityID = getEntityID($Data->{'clientValues'});
	#
	my $query = qq[
		SELECT 
			tblTransactions.intTransactionID,
			IF(tblTransactions.intSentToGateway=1 and tblTransactions.intPaymentGatewayResponded = 0, 1, 0) as GatewayLocked,
			tblInvoice.strInvoiceNumber, 
			tblInvoice.tTimeStamp as invoiceDate,
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
			LEFT JOIN tblEntityLinks ON tblEntityLinks.intChildEntityID = tblTransactions.intTXNEntityID 
			WHERE tblTransactions.intInvoiceID = $convertedInvoiceNumberToTXNID AND intStatus = 0 
			AND tblTransactions.intRealmID = $Data->{'Realm'} AND intTransLogID = 0 
			AND tblPersonRegistration_$Data->{'Realm'}.strStatus <> 'INPROGRESS'];
	
	#filtering scheme for FC-866
		#get authlevel
		if($Data->{'clientValues'}{'currentLevel'} == $Defs::LEVEL_CLUB){			
			$query .= qq[ AND tblTransactions.intTXNEntityID = $intTXNEntityID ];			
		}
		elsif($Data->{'clientValues'}{'currentLevel'} == $Defs::LEVEL_REGION){
			my $subquery = qq[SELECT intChildEntityID FROM tblEntityLinks WHERE intParentEntityID = $intTXNEntityID];
			my $st = $Data->{'db'}->prepare($subquery);
			my @clubs = ();
			push @clubs,$intTXNEntityID;
			$st->execute();
			while(my $dref = $st->fetchrow_hashref()){
				push @clubs, $dref->{'intChildEntityID'};
			}
			$query .= qq[ AND tblTransactions.intTXNEntityID IN ('', ] . join(',',@clubs) . q[)];
		}
	#
	my $sth = $Data->{'db'}->prepare($query);
	$sth->execute();
	my $cl=setClient($Data->{'clientValues'}) || '';
    my %cv=getClient($cl);    
    $cv{'currentLevel'} = $Defs::LEVEL_PERSON;
	my $selectPay;
	my $notLocked=0;
	while(my $dref = $sth->fetchrow_hashref()){
		$results = 1;
		$totalAmount += $dref->{'TotalAmount'};
		#my $selectPay = qq[<input type="checkbox" checked="checked" name="act_$dref->{'intTransactionID'}" class="paytxn_chk" />];
		if (! $dref->{'GatewayLocked'})	{
			$selectPay .= qq[<input type="hidden" name="act_$dref->{'intTransactionID'}" value="1" />];	
			$notLocked++;
		}
		$cv{'personID'} = $dref->{'intPersonID'};
        my $clm=setClient(\%cv);
		push @rowdata, {
			id => $dref->{'intTransactionID'},
			SelectLink => qq[$Data->{'target'}?client=$clm&amp;a=P_TXN_EDIT&personID=$dref->{'intPersonID'}&amp;tID=$dref->{intTransactionID}&amp;id=0],
			#selectpay => $selectPay,
			invoiceNum => $dref->{'strInvoiceNumber'},
			invoiceDate =>  $Data->{'l10n'}{'date'}->TZformat($dref->{'invoiceDate'},'MEDIUM','SHORT'), 
			item => $dref->{'strName'},
			person => $dref->{'strLocalFirstname'} . ' ' . $dref->{'strLocalSurname'},
			quantity => $dref->{'intQty'},
			amount => $Data->{'l10n'}{'currency'}->format($dref->{'TotalAmount'}),
			status => $dref->{'GatewayLocked'} ? $Data->{'lang'}->txt("Locked") : $Defs::TransactionStatus{$dref->{'intStatus'}},			
			gatewayLocked => $dref->{'GatewayLocked'} || 0,
			invoiceDateSortColumn => $dref->{'invoiceDate'},
		};
		
	}
 	if($results){
		#check if invoiceNumber is partially paid
		$query = qq[SELECT strInvoiceNumber FROM  tblInvoice INNER JOIN tblTransactions ON tblTransactions.intInvoiceID = tblInvoice.intInvoiceID WHERE intStatus = 1 AND intTransLogID <> 0 AND tblTransactions.intRealmID = $Data->{'Realm'} AND strInvoiceNumber = '$invoiceNumber'];
		$sth = $Data->{'db'}->prepare($query);
		$sth->execute();
	    my @darr = $sth->fetchrow_array();
		if(scalar @darr){
			$content = $Data->{'lang'}->txt('<div class="alert">
					<div>
						<span class="fa fa-exclamation"></span>
						Invoice Partially Paid.
					</div>
				</div>');
		}
		

	}


	#my $body = displayResults($Data,\@rowdata,$client);
my @headers = (
	{
      name => $Data->{'lang'}->txt('Invoice Number'),
      field => 'invoiceNum',
    },
	{
      name => $Data->{'lang'}->txt('Invoice Date'),
      field => 'invoiceDate',
	  sortdata => 'invoiceDateSortColumn',
      defaultShow => 1,
    },
    {
      name =>   $Data->{'lang'}->txt('Item'),
      field =>  'item',
    },
    {
      name =>   $Data->{'lang'}->txt('Person'),
      field =>  'person',
      defaultShow => 1,
    },
	{
		name => $Data->{'lang'}->txt('Quantity'),
		field => 'quantity',
	},
	{
		name => $Data->{'lang'}->txt('Amount'),
		field => 'amount',
      defaultShow => 1,
	},
	{
		name => $Data->{'lang'}->txt('Status'),
		field => 'status', 
	},
	{
		name => '', 
		field => 'SelectLink', 
	    type => 'Selector', 
	},
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
	$gateway_body = '' if ! $gatewayCount or ! $notLocked;
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
	#
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
   	#
	my $isManualPaymentAllowedAtThisLevel = 0;
	$isManualPaymentAllowedAtThisLevel = 1 if ($Data->{'clientValues'}{'authLevel'} >= $Data->{'SystemConfig'}{'allowManualPaymentsFromLevel'});
	#
	
	if ($allowMP and $notLocked and $isManualPaymentAllowedAtThisLevel){
	$gateway_body .= qq[<div  style="display:block;" id="payment_manual">
						<h3 class="panel-header sectionheader" id="manualpayment">].$Data->{'lang'}->txt('Manual Payment').qq[</h3>
				  		<div id="secmain2" class="panel-body fieldSectionGroup ">
				  			<fieldset>
				  				<div class="form-group">
				  					<label for="l_intAmount" class="col-md-4 control-label txtright"><span class="compulsory">*</span>].$Data->{'lang'}->txt('Amount (ddd.cc)').qq[</label>
				  					<div class="col-md-6">
										<input type="hidden" name="intAmount" value="] . sprintf('%.2f',$totalAmount) . qq[" id="l_intAmount" size="10" readonly />
										<span>].  $Data->{'l10n'}{'currency'}->format($totalAmount) .q[</span>
</div>
				  				</div>
				  				<div class="form-group">
				  					<label for="l_dtLog" class="col-md-4 control-label txtright"><span class="compulsory">*</span>].$Data->{'lang'}->txt('Date Paid').qq[</label>									
				  					<div class="col-md-6">
										<script type="text/javascript">
                 			  		 jQuery().ready(function() {
                    		   			 jQuery("#l_dtLog").datepicker({
										   maxDate: new Date,	
                        			 	   dateFormat: 'dd/mm/yy',
                        		  		   showButtonPanel: true
                     		 	 		 });            
                  	 				 });
               				 </script> 
									<input type="text" name="dtLog" value="$currentDate" id="l_dtLog" size="10" maxlength="10" /> <span class="HTdateformat">dd/mm/yyyy</span></div>
				  				</div>
				  				<div class="form-group">
				  					<label for="l_intPaymentType" class="col-md-4 control-label txtright"><span class="compulsory">*</span>].$Data->{'lang'}->txt('Payment Type').qq[</label>
				  					<div class="col-md-6">].drop_down('paymentType',\%Defs::manualPaymentTypes, undef, $paymentType, 1, 0,'','').qq[</div>
				  				</div>
				  				<div class="form-group">
				  					<label for="l_strComments" class="col-md-4 control-label txtright">].$Data->{'lang'}->txt('Comments').qq[</label>
				  					<div class="col-md-6"><textarea name="strComments" id="l_strComments" style="width: 100%; height: 200px;">$Data->{params}{strComments}</textarea></div>
				  				</div>
				  			</fieldset>
				  		</div>
					  	<div class="button-row">
							<div class="txtright" id="block-manualpay" style="display:block">
								<input onclick="clicked='main.cgi'" type="submit" name="subbut" value="Submit Manual Payment" class="btn-main" id = "btn-manualpay" >
								<input type="hidden" name="paymentID" value="">
								<input type="hidden" name="dt_start_paid" value="">
								<input type="hidden" name="dt_end_paid" value="">
							</div>
						</div>
					</div>
			] 

	}

#<span class="compulsory">*</span>]

	#
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
	 my $body = $content;
     $body .= runTemplate($Data, \%PageData, 'payment/bulkinvoicelisting.templ') || '';
	 return $body if($results);
	 return $results;
	
}

sub queryInvoiceByOtherInfo { 
	my ($Data, $clubID, $client) = @_;	
	
	my @whereClause = ();
	my $intTXNEntityID = getEntityID($Data->{'clientValues'});
	#PersonType is required 

	#get posted values 
	my $strPersonType = param('PersonType') || '';
	if($strPersonType){
		push @whereClause, " AND strPersonType = '$strPersonType' ";
	}
		
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
	tblInvoice.tTimeStamp as invoiceDate,
	tblTransactions.intStatus,
	tblTransactions.intQty, 
	tblProducts.strName, 
	tblPerson.strLocalFirstname,
	tblPerson.strLocalSurname,
	tblPerson.intPersonID,	
	IF(tblTransactions.intSentToGateway=1 and tblTransactions.intPaymentGatewayResponded = 0, 1, 0) as GatewayLocked,
	(tblTransactions.curAmount * tblTransactions.intQty) as TotalAmount 
	FROM tblTransactions INNER JOIN tblPersonRegistration_$Data->{'Realm'}
	ON (tblPersonRegistration_$Data->{'Realm'}.intPersonRegistrationID = tblTransactions.intPersonRegistrationID AND tblPersonRegistration_$Data->{'Realm'}.intPersonID = tblTransactions.intID)
	INNER JOIN tblInvoice ON tblInvoice.intInvoiceID = tblTransactions.intInvoiceID 
	INNER JOIN tblProducts ON tblProducts.intProductID = tblTransactions.intProductID
	INNER JOIN tblPerson ON tblPerson.intPersonID = tblTransactions.intID 
	WHERE intStatus = 0 AND tblPersonRegistration_$Data->{'Realm'}.strStatus <> 'INPROGRESS' 
	@whereClause ];	

	#filtering scheme for FC-866
		#get authlevel
		if($Data->{'clientValues'}{'currentLevel'} == $Defs::LEVEL_CLUB){			
			$query .= qq[ AND tblTransactions.intTXNEntityID = $intTXNEntityID ];			
		}
		elsif($Data->{'clientValues'}{'currentLevel'} == $Defs::LEVEL_REGION){
			my $subquery = qq[SELECT intChildEntityID FROM tblEntityLinks WHERE intParentEntityID = $intTXNEntityID];
			my $st = $Data->{'db'}->prepare($subquery);
			my @clubs = ();
			push @clubs,$intTXNEntityID;
			$st->execute();
			while(my $dref = $st->fetchrow_hashref()){
				push @clubs, $dref->{'intChildEntityID'};
			}
			
			$query .= qq[ AND tblTransactions.intTXNEntityID IN ('', ] . join(',',@clubs) . q[)];
		}

	$query .= qq[ORDER BY invoiceDate DESC];
	#
	# intStatus = 0 unpaid
	#  
	my $sth = $Data->{'db'}->prepare($query); 
	$sth->execute();

	 my $cl=setClient($Data->{'clientValues'}) || '';
     my %cv=getClient($cl);    
     $cv{'currentLevel'} = $Defs::LEVEL_PERSON;
	 

	my $results = 0;
	my @rowdata = ();
	my $isPaid = 0;
	while(my $dref = $sth->fetchrow_hashref()){		
		$results = 1;				
		my $selectPay = qq[<input type="checkbox" name="act_$dref->{'intTransactionID'}" class="paytxn_chk" value="$dref->{'TotalAmount'}" id="$dref->{'intTransactionID'}" />];	
		$selectPay = '' if ($dref->{'GatewayLocked'});
		$cv{'personID'} = $dref->{'intPersonID'};
                my $clm=setClient(\%cv);
                my $name = formatPersonName($Data, $dref->{'strLocalFirstname'}, $dref->{'strLocalSurname'}, '');
		push @rowdata, {
			id => $dref->{'intTransactionID'},
			SelectLink => qq[$Data->{'target'}?client=$clm&amp;a=P_TXN_EDIT&personID=$dref->{'intPersonID'}&amp;tID=$dref->{intTransactionID}&amp;id=0],
			selectpay => $selectPay,
			invoiceNum => $dref->{'strInvoiceNumber'},
			invoiceDate =>  $Data->{'l10n'}{'date'}->TZformat($dref->{'invoiceDate'},'MEDIUM','SHORT'), 
			item => $dref->{'strName'},
			person => $name,
			quantity => $dref->{'intQty'},
			amount => $Data->{'l10n'}{'currency'}->format($dref->{'TotalAmount'}),
			status => $dref->{'GatewayLocked'} ? $Data->{'lang'}->txt("Locked") : $Defs::TransactionStatus{$dref->{'intStatus'}},			
			gatewayLocked => $dref->{'GatewayLocked'} || 0,
			invoiceDateSortColumn => $dref->{'invoiceDate'},
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
	  name => 'Pay',
	  field => 'selectpay',
	  width => 20,
          type => 'HTML',
      defaultShow => 1,
    },
	{
      name => $Data->{'lang'}->txt('Invoice Number'),
      field => 'invoiceNum',
    },
	{
      name => $Data->{'lang'}->txt('Invoice Date'),
      field => 'invoiceDate',
	  sortdata => 'invoiceDateSortColumn',
    },
    {
      name =>   $Data->{'lang'}->txt('Item'),
      field =>  'item',
    },
    {
      name =>   $Data->{'lang'}->txt('Person'),
      field =>  'person',
      defaultShow => 1,
    },
	{
		name => $Data->{'lang'}->txt('Quantity'),
		field => 'quantity',
	},
	{
		name => $Data->{'lang'}->txt('Amount'),
		field => 'amount',
      defaultShow => 1,
	},
	{
		name => $Data->{'lang'}->txt('Status'),
		field => 'status', 
	},
	{
		name => '', 
		field => 'SelectLink', 
	    type => 'Selector', 
	},
	);
	 my $grid  = showGrid(
   		 Data => $Data,
     	 columns => \@headers,
   		 rowdata => $rowdata,   	    
   	     gridid => 'grid',
  	     width => '99%',
  	     instanceDestroy=>'true',
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

	#
	my $isManualPaymentAllowedAtThisLevel = 0;
	$isManualPaymentAllowedAtThisLevel = 1 if ($Data->{'clientValues'}{'authLevel'} >= $Data->{'SystemConfig'}{'allowManualPaymentsFromLevel'});
	#
    
    $allowMP = 0 if $Data->{'SystemConfig'}{'DontAllowManualPayments_Invoice'};
	
		
	 my $orstring = '';
     $orstring = qq[&nbsp; <b>].$Data->{'lang'}->txt('OR').qq[</b> &nbsp;] if $gateway_body and $allowMP;
     if($paymentType==0){ $paymentType='';}
   
	#
	$gateway_body .= qq[<input type="hidden" id="id_total" value="0" />
	
	];
	if ($allowMP and $isManualPaymentAllowedAtThisLevel){
	$gateway_body .= qq[<div  style="display:none;" id="payment_manual">
						<h3 class="panel-header sectionheader" id="manualpayment">].$Data->{'lang'}->txt('Manual Payment').qq[</h3>
				  		<div id="secmain2" class="panel-body fieldSectionGroup ">
				  			<fieldset>
				  				<div class="form-group">
				  					<label for="l_intAmount" class="col-md-4 control-label txtright"><span class="compulsory">*</span>].$Data->{'lang'}->txt('Amount (ddd.cc)').qq[</label>
				  					<div class="col-md-6">
									<span id="manualsum"></span>
									<input type="hidden" name="intAmount" value="" id="l_intAmount" /></div>
									<input type="hidden" id="clientstr" value="$client" />
				  				</div>
				  				<div class="form-group">
				  					<label for="l_dtLog" class="col-md-4 control-label txtright"><span class="compulsory">*</span>].$Data->{'lang'}->txt('Date Paid').qq[</label>
				  					<div class="col-md-6">
									<script type="text/javascript">
                 			   jQuery().ready(function() {
                    		    jQuery("#l_dtLog").datepicker({
									maxDate: new Date,
									dateFormat: 'dd/mm/yy',
                        		    showButtonPanel: true
                     		 	  });            
                  	 			 });
               				 </script> 

									<input type="text" name="dtLog" value="$currentDate" id="l_dtLog" size="10" maxlength="10" /> <span class="HTdateformat">dd/mm/yyyy</span></div>
				  				</div>
				  				<div class="form-group">
				  					<label for="l_intPaymentType" class="col-md-4 control-label txtright"><span class="compulsory">*</span>].$Data->{'lang'}->txt('Payment Type').qq[</label>
				  					<div class="col-md-6">].drop_down('paymentType',\%Defs::manualPaymentTypes, undef, $paymentType, 1, 0,'','').qq[</div>
				  				</div>
				  				<div class="form-group">
				  					<label for="l_strComments" class="col-md-4 control-label txtright">].$Data->{'lang'}->txt('Comments').qq[</label>
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
					</div>
			] 

	}

#<span class="compulsory">*</span>]
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
