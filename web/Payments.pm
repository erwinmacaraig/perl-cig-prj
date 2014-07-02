#
# $Header: svn://svn/SWM/trunk/web/Payments.pm 11041 2014-03-19 05:17:52Z cregnier $
#

package Payments;
require Exporter;
@ISA = qw(Exporter);
@EXPORT=qw(handlePayments checkoutConfirm getPaymentSettings processTransLogFailure invoiceNumToTXN TXNtoInvoiceNum invoiceNumForm getTXNDetails displayPaymentResult EmailPaymentConfirmation UpdateCart processTransLog getRegoFormID_transLog getSoftDescriptor checkForPaid);
@EXPORT_OK=qw(handlePayments checkoutConfirm getPaymentSettings processTransLogFailure invoiceNumToTXN TXNtoInvoiceNum invoiceNumForm getTXNDetails displayPaymentResult EmailPaymentConfirmation UpdateCart processTransLog getRegoFormID_transLog getSoftDescriptor checkForPaid);

use strict;
use CGI qw(param);
use Reg_common;
use Utils;
use MD5;
use DeQuote;
use SystemConfig;
use Email;
use PaymentSplitExport;
use ServicesContacts;
use TemplateEmail;
#use RegoForm::RegoFormFactory;
use RegoFormUtils;
use ContactsObj;

require Products;
require TransLog;
require PaymentSplitMoneyLog;
require RegoForm::RegoFormFactory;
  
#use RegoForm;

sub handlePayments	{

	my ($action, $Data, $external) = @_;
	$external ||= 0;

	my $body = '';
	if ($action =~ /DISPLAY/)	{
		my $intLogID = param('ci') || 0;
		$body = displayPaymentResult($Data, $intLogID, $external);
	}	
	if ($action =~ /LATER/)	{
		my $intLogID = param('ci') || 0;
		my $pl= param('pl') || 0;
		$body = displayPaymentLaterResult($Data, $intLogID, $pl, $external);
	}	
	return ($body, 'Payment Result');
}

sub checkForPaid	{

	my ($db, $txnID) = @_;
	
	my $st = qq[
		SELECT 
			intTransLogID
		FROM
			tblTransactions
		WHERE 
			intStatus<>0
			AND intTransactionID=?
	];
		
  my $query = $db->prepare($st);
  $query->execute($txnID);
  return $query->fetchrow_array() || 0;
}

sub getSoftDescriptor   {

    my ($Data, $paymentSettings, $entityTypeID, $entityID, $type) = @_;

    $type ||= 0;

    my $softDescriptor = "";
    if ($type ==1) { ## PAYPAL Setup page to display what it would be
        return "PP*SP " . $paymentSettings->{'gatewayCreditCardNoteRealm'};
    }

		#my $where = '';
		#$where = qq[ AND intPaymentType = $Defs::PAYMENT_ONLINEPAYPAL ] if ($paymentSettings->{'gatewayType'} == $Defs::GATEWAY_PAYPAL);
		#$where = qq[ AND intPaymentType = $Defs::PAYMENT_ONLINENAB] if ($paymentSettings->{'gatewayType'} == $Defs::GATEWAY_NAB);
    my $st = qq[
        SELECT
            strSoftDescriptor
        FROM
            tblPaymentApplication
        WHERE
            intEntityID=?
            AND intEntityTypeID=?
				ORDER BY intPaymentType DESC
				LIMIT 1
    ];
    my $query = $Data->{'db'}->prepare($st);
    $query->execute($entityID, $entityTypeID);
    return $query->fetchrow_array() || '';

}

sub checkMinFeeAmount	{

	my ($Data, $trans, $amount) = @_;

        my $st = qq[
        	SELECT T.intTableType, T.intID, T.intTempID, T.intAssocID, A.intAssocFeeAllocationType, intParentTXNID, strPayeeName
                FROM tblTransactions as T
                    INNER JOIN tblAssoc as A ON (A.intAssocID = T.intAssocID)
                WHERE T.intTransactionID = ?
                        AND A.intAllowPayment > 0
                        AND A.intAssocTypeID = $Data->{'RealmSubType'}
                        AND T.intRealmID = $Data->{'Realm'}
    	];
											##AND T.intStatus=0
                        #AND T.intRealmSubTypeID= $Data->{'RealmSubType'}

        my $qry = $Data->{'db'}->prepare($st);
	my $dref='';
        for my $transid (@{$trans})     {
                $transid || next;
                $qry->execute($transid);
                $dref = $qry->fetchrow_hashref();
		last;
        }
	return if ! $dref;
	#return if ! defined $dref;

	$st = qq[
		SELECT intMinFeeProductID, curMinFeePoint, intMinFeeType, curDefaultAmount, dblFactor, intFeeAllocationType, curAmount
		FROM tblPaymentSplitFees as PSF
			INNER JOIN tblProducts as P ON (P.intProductID = intMinFeeProductID)
		WHERE PSF.intRealmID = $Data->{'Realm'}
                        AND PSF.intSubTypeID IN (0,$Data->{'RealmSubType'})
		ORDER BY PSF.intSubTypeID DESC
		LIMIT 1
	];
	my $query = $Data->{'db'}->prepare($st);
 	$query->execute;
	my ($minFeeProductID, $minFeePoint, $minFeeType, $minFee, $factor, $feeType, $baseFee) = $query->fetchrow_array();	
	$factor = $Data->{'SystemConfig'}{'AssocConfig'}{'dblFactorOverride'} if ($Data->{'SystemConfig'}{'AssocConfig'}{'dblFactorOverride'});
	$minFeePoint = $Data->{'SystemConfig'}{'AssocConfig'}{'minFeeOverride'} if ($Data->{'SystemConfig'}{'AssocConfig'}{'minFeeOverride'});

    my $clubFeeAllocationType =0;
    if ($Data->{'RegoFormID'} or ($Data->{'clientValues'}{'clubID'} and  $Data->{'clientValues'}{'authLevel'} == $Defs::LEVEL_CLUB)) {
        my $st = '';
        $st = qq[
                SELECT
                        intClubFeeAllocationType
                FROM
                    tblClub as C
                    INNER JOIN tblRegoForm as RF ON (
                        (RF.intClubID = C.intClubID or RF.intAssocID=-1)
                        AND intRegoFormID = $Data->{'RegoFormID'}
                    )
		WHERE C.intClubID = $Data->{'clientValues'}{'clubID'}
		LIMIT 1;
        ] if $Data->{'RegoFormID'} and $Data->{'clientValues'}{'authLevel'} == $Defs::LEVEL_CLUB;

        $st = qq[
                SELECT
                        intClubFeeAllocationType
                FROM
                    tblClub as C
                WHERE intClubID= $Data->{'clientValues'}{'clubID'}
         ] if (!$Data->{'RegoFormID'} and  $Data->{'clientValues'}{'clubID'} and  $Data->{'clientValues'}{'authLevel'} == $Defs::LEVEL_CLUB);
        if ($st)    {
            my $qry = $Data->{'db'}->prepare($st) or query_error($st);
	        $qry->execute or query_error($st);
	        $clubFeeAllocationType = $qry->fetchrow_array() || 0;
        }
    }

	if (defined $dref and $dref)    {
		$feeType = $clubFeeAllocationType || $dref->{intAssocFeeAllocationType} || $feeType;
        ## If logged in as Club, or if a club form then check club setting
	}
	if (defined $dref and $dref and $minFeeProductID)	{
        my $whereID =qq[ AND intID = $dref->{intID} ];
        if($dref->{intID} == 0 and $dref->{intTempID} !=0 ){
            $whereID = qq[ AND intTempID = $dref->{intTempID} ];
        }
		$st = qq[
			UPDATE tblTransactions
			SET intStatus=-1
			WHERE intProductID = $minFeeProductID
                $whereID
				AND intTableType = $dref->{intTableType}
				AND intStatus=0
				AND intParentTXNID=0
		];
		$Data->{'db'}->do($st);
	}

	return if $amount == 0;
	if ($feeType == 1 and $minFeeProductID and $minFeePoint and $amount < $minFeePoint)	{

		if ($minFeeType ==2)	{
			## ROUND UP
			$minFee = $minFee - ($amount * $factor);
			$minFee = 0 if $minFee < 0;
		}
		if ($minFee and $minFee > 0)	{
			$st = qq[
				INSERT INTO tblTransactions
				(intProductID, intRealmID, intRealmSubTypeID, intID,intTempID, intTableType, curAmount, intStatus, intQty, intAssocID, intParentTXNID, strPayeeName)
				VALUES ($minFeeProductID,  $Data->{'Realm'}, $Data->{'RealmSubType'}, $dref->{intID}, $dref->{intTempID} , $dref->{intTableType}, $minFee, 0, 1, $dref->{intAssocID}, $dref->{'intParentTXNID'}, ? )
			];
			my $query = $Data->{'db'}->prepare($st);
 	       		$query->execute($dref->{'strPayeeName'});
        		return ($query->{mysql_insertid}, $amount + $minFee);
		}
	}
	elsif ($feeType == 2)	{
		### ADD Fee as separate product line (AUSKICK MODEL)
			my $fee= ($amount * $factor) + $baseFee;
			$fee = $minFee if $fee < $minFee;
			$st = qq[
				INSERT INTO tblTransactions
				(intProductID, intRealmID, intRealmSubTypeID, intID,intTempID, intTableType, curAmount, intStatus, intQty, intAssocID, intParentTXNID, strPayeeName)
				VALUES ($minFeeProductID,  $Data->{'Realm'}, $Data->{'RealmSubType'}, $dref->{intID},$dref->{intTempID},  $dref->{intTableType}, $fee, 0, 1, $dref->{intAssocID}, $dref->{'intParentTXNID'}, ?)
			];
			my $query = $Data->{'db'}->prepare($st);
 	       		$query->execute($dref->{'strPayeeName'});
        		return ($query->{mysql_insertid}, $amount + $fee);
	}
	return (0,0);

	
	

}

sub processFeeDetails {
    my($Data)= @_;
    my $st = qq[
        SELECT 
             dblFactor
        FROM 
            tblPaymentSplitFees as PSF
            INNER JOIN tblProducts as P ON (P.intProductID = intMinFeeProductID)
        WHERE 
            PSF.intRealmID = $Data->{'Realm'}
            AND PSF.intSubTypeID IN (0,$Data->{'RealmSubType'})
        ORDER BY PSF.intSubTypeID DESC
        LIMIT 1
    ];
    my $query = $Data->{'db'}->prepare($st);
    $query->execute;
    my ($factor) = $query->fetchrow_array();
    $factor = $Data->{'SystemConfig'}{'AssocConfig'}{'dblFactorOverride'} if ($Data->{'SystemConfig'}{'AssocConfig'}{'dblFactorOverride'});
    $factor = $factor *100;
    $factor = 0 if ($factor <= 0);
    return $factor;

}

sub checkoutConfirm	{

	my($Data, $trans, $external)=@_;
	$external ||= 0; ## Pop CC in NEW window ?

	$Data->{'SystemConfig'}=getSystemConfig($Data);
	$Data->{'LocalConfig'}=getLocalConfig($Data);
	my $dollarSymbol = $Data->{'LocalConfig'}{'DollarSymbol'} || "\$";
    
    my $compulsory = 0;
	my $RegoFormObj = undef;
	my $passedClubID = $Data->{'clientValues'}{'clubID'};
	if($Data->{'RegoFormID'})	{
		$RegoFormObj = RegoForm::RegoFormFactory::getRegoFormObj(
			$Data->{'RegoFormID'},
			$Data,
			$Data->{'db'},
		);
        $compulsory = $RegoFormObj->getValue('intPaymentCompulsory') || 0;
	}
    my $formID = $Data->{'RegoFormID'} || 0;
	$Data->{'clientValues'}{'clubID'}= $passedClubID if $passedClubID;
	my $client=setClient($Data->{'clientValues'}) || '';
	#print STDERR "DDCHECKOUT CONFIRM: R:$Data->{'Realm'} RS:$Data->{'RealmSubType'} CL:$Data->{'clientValues'}{'currentLevel'} A:$Data->{'clientValues'}{'assocID'} C:$Data->{'clientValues'}{'clubID'}\n";
	my $db = $Data->{'db'};
	my $body;
	my ($count, $dollars, $cents) = getCheckoutAmount($Data, $trans);
	my $amount = "$dollars.$cents";
        my $m;
        $m = new MD5;
        $m->reset();
        $amount =  sprintf("%.2f", $amount);

	my $paymentSettings = getPaymentSettings($Data, $external);
	my $usePayPal = $paymentSettings->{'gatewayType'} == $Defs::GATEWAY_PAYPAL ? 1 : 0;
  my $useNAB = $paymentSettings->{'gatewayType'} == $Defs::GATEWAY_NAB ? 1 : 0;
	#$usePayPal=0 if ! $external;

	if ($usePayPal or $useNAB)	{
		my ($minFeeTrans, $fee) = (0,0);
		($minFeeTrans, $fee) = checkMinFeeAmount($Data, $trans, $amount) if ($amount>0);
		if ($minFeeTrans)	{
			push @{$trans}, $minFeeTrans;
			my ($count, $dollars, $cents) = getCheckoutAmount($Data, $trans);
			$amount = "$dollars.$cents";
        		$amount =  sprintf("%.2f", $amount);
		}
	}

		my $assocID=$Data->{'clientValues'}{'assocID'} || 0;
	# Need to create TransLog record
        my $intLogID = $count ? createTransLog($Data, $paymentSettings, $trans, $amount) : 0;
	my $payLater = '';
        if ($Data->{'RegoFormID'} and $Data->{'SystemConfig'}{'regoform_showPayLater'} and !$compulsory)   {
            my $m;
            my $chkvalue=$intLogID;
            $m = new MD5;
            $m->reset();
            $m->add($Defs::paylater_string, $chkvalue);
            $chkvalue = $m->hexdigest();
            $payLater = qq[<a href="paylater.cgi?a=PAY_LATER&amp;ci=$intLogID&amp;aID=$assocID&amp;formID=$Data->{'RegoFormID'}&amp;pl=$chkvalue">Click here to choose to pay later</a>];
        }


        my $values = $amount . $intLogID . $paymentSettings->{'paymentGatewayID'} . $paymentSettings->{'currency'};
        $m->add($paymentSettings->{'gateway_string'}, $values);
        $values = $m->hexdigest();
        my $cr = $paymentSettings->{'currency'} || 'AUD';


	# Need to show Pay button
		
		my $st = qq[
			SELECT intAllowPayment, intApproveClubPayment
			FROM tblAssoc
            WHERE intAssocID = ?
		];
        my $qry = $db->prepare($st) or query_error($st);
        $qry->execute($assocID) or query_error($st);
		my ($allowPayment , $approveClubPayments)= $qry->fetchrow_array();
        $allowPayment ||= 0;
        $approveClubPayments ||= 0;
		$allowPayment = 1 if ($external and $assocID == -1);

	if ($usePayPal and ! $external and $Data->{'clientValues'}{'authLevel'} <= $Defs::LEVEL_CLUB)	{
		#$allowPayment=0;	
		##$approveClubPayments=0;	
		#$usePayPal=0;
	}
        ## Lets check if the club payments have been turned on.
        if (
            ! $approveClubPayments
	    and ($usePayPal or $useNAB)
            and $allowPayment 
            and $Data->{'clientValues'}{'clubID'} 
            and $Data->{'clientValues'}{'clubID'} != $Defs::INVALID_ID 
            and (
                $external 
                or $Data->{'clientValues'}{'authLevel'} == $Defs::LEVEL_CLUB
                )
            )    {
                my $formOwner=$Defs::LEVEL_ASSOC;
                if ($external and $Data->{'RegoFormID'})  {
                    my $st = qq[
                        SELECT intClubID
                        FROM tblRegoForm
                        WHERE intRegoFormID = ?
                    ];
        	        my $qry = $db->prepare($st) or query_error($st);
                    $qry->execute($Data->{'RegoFormID'}) or query_error($st);
		            my ($clubFormID)= $qry->fetchrow_array() || 0;
                    $formOwner = $Defs::LEVEL_CLUB if $clubFormID > 0;
                }
                elsif ($Data->{'clientValues'}{'authLevel'} == $Defs::LEVEL_CLUB)   {
                    $formOwner = $Defs::LEVEL_CLUB;
                }

                if ($formOwner == $Defs::LEVEL_CLUB)    {
                    my $st = qq[
			            SELECT intApprovePayment, intApproveClubPayment
			            FROM tblClub
                            LEFT JOIN tblAssoc_Clubs as AC ON (AC.intClubID= tblClub.intClubID)
                            INNER JOIN tblAssoc as A ON (A.intAssocID=AC.intAssocID)
                        WHERE tblClub.intClubID = ?
		            ];
        	        my $qry = $db->prepare($st) or query_error($st);

                    $qry->execute($Data->{'clientValues'}{'clubID'})
                        or query_error($st);

		            my $approvePayments=0;
		            ($approvePayments, $approveClubPayments)= $qry->fetchrow_array();
                    $allowPayment = 0 if ! $approvePayments and ! $approveClubPayments; 
                }
        }
	my $session = $Data->{'sessionKey'};
		my $paymentURL = qq[$Defs::base_url/paypal.cgi?nh=$Data->{'noheader'}&amp;ext=$external&amp;a=P&amp;client=$client&amp;ci=$intLogID&amp;formID=$formID&amp;session=$session;compulsory=$compulsory];
		my $formTarget = $external ? qq[ target="other" onClick="window.open('$paymentURL','other','location=no,directories=no,menubar=no,statusbar=no,toolbar=no,scrollbars=yes,height=820,width=870,resizable=yes');return false;" ] : '';
		#<div><img src="https://www.paypal.com/en_AU/AU/i/bnr/horizontal_solution_PP.gif" border="0"></div><br>
	my $externalGateway= qq[
		<div><img src="images/PP-CC.jpg" border="0"></div><br>
		<br><a $formTarget id ="payment" href="$paymentURL"><img src="$Defs::PAYPAL_CHECKOUT_IMAGE" border="0"  alt="Pay Now"></a>
	];

  if ($useNAB)    {
    my $m;
    my $chkvalue= $amount . $intLogID . $paymentSettings->{'currency'};
    $m = new MD5;
    $m->reset();
    $m->add($Defs::NAB_SALT, $chkvalue);
    $chkvalue = $m->hexdigest();
        #$paymentURL = qq[$Defs::base_url/nabform.cgi?nh=$Data->{'noheader'}&amp;ext=$external&amp;a=P&amp;client=$client&amp;ci=$intLogID&amp;chkv=$chkvalue];
        $paymentURL = qq[$Defs::base_url/nabform.cgi?nh=$Data->{'noheader'}&amp;ext=$external&amp;a=P&amp;formID=$formID&amp;client=$client&amp;ci=$intLogID&amp;chkv=$chkvalue&amp;session=$session;compulsory=$compulsory];
		## Do we want to open the payments in a new window... ie: Has the summary screen already been opened in a new window ?
        #$external=1;
        my $formTarget = $external
                ? qq[ target="other" onClick="window.open('$paymentURL','other','location=no,directories=no,menubar=no,statusbar=no,toolbar=no,scrollbars=yes,height=820,width=870,resizable=yes');return false;" ]
                : '';
          $externalGateway= qq[
          	<div class="accepted">
							<p>We Accept:</p>
							<span class="visa-logo"><img src="images/visa_logo.png" border="0"></span>
							<span class="mcard-logo"><img src="images/mcard_logo.png" border="0"></span>
						</div>	
					];
	  		if (! $external)	{
    			#$externalGateway .= qq[ <img src="images/paynow.gif" alt="Pay Now"></a><img src="images/nab-logo-registrations.png" alt="NAB" style="float:right;padding:5px;" ><br><a href="$paymentURL" type="button" style="padding:2px 30px;font-size:16px;"><img src="images/paynow.gif" alt="Pay Now"></a>];
    			$externalGateway .= qq[ <a href="$paymentURL"  id ="payment" type="button" style="padding:2px 30px;font-size:16px;"><img src="images/paynow.gif" alt="Pay Now"></a>];
	  		}
	  		else	{
			#<p>We prefer Mastercard</p>
    			#$externalGateway .= qq[<input $formTarget href="$paymentURL" type="button" style="padding:2px 30px;" class = "button proceed-button" value = "Pay Now">];
    			$externalGateway .= qq[<span class="button proceed-button"><a href="$paymentURL">Proceed to Payment</a></span>];
	  		}
       }

	if (($useNAB or $usePayPal) and $amount eq '0.00')	{
		my $responsetext = 'Zero paid';
            	my $txn = 'Zero-' . time(); 
		processTransLog($Data->{'db'}, $txn, 'OK', $responsetext, $intLogID, $paymentSettings, undef, undef, '', '', '', '', '');
		UpdateCart($Data, undef, $Data->{'client'}, undef, undef, $intLogID);
        	EmailPaymentConfirmation($Data, $paymentSettings, $intLogID, $client, $RegoFormObj);
        	Products::product_apply_transaction($Data,$intLogID);
			return '';
	}


	my $invoiceList ='';
	if ($intLogID)	{
		#List the products this person is purchasing and their amounts
		my $assocID=$Data->{'clientValues'}{'assocID'} || 0;
		my $realmID=$Data->{'Realm'} || 0;
		my $product_confirmation='';
		my $txn_list = join (',',@{$trans});
        my $processFeeNote ='';
		{
			for my $transid (@{$trans})	{
				my $dref = getTXNDetails($Data, $transid,1);
			next if ! $dref->{intTransactionID};
                my $star ='';
				$count++;
				my $lamount=currency($dref->{'curAmount'} || 0);
				$invoiceList .= $invoiceList ? qq[,$dref->{'InvoiceNum'}] : $dref->{'InvoiceNum'};
                if($dref->{ProductName} =~ /PROCESSING FEE/i){ 
                    my $factor = processFeeDetails($Data);
                    my $dollar =qq[1];
                    #$processFeeNote =qq[* Payment processing fee is $factor% inc GST of total transaction(minimum of $dollarSymbol$dollar)];
                    $processFeeNote =qq[* Payment processing fee is $factor% inc GST of total transaction.];
                    $star = qq[*];
                }
				$product_confirmation.=qq[
					<tr>
						<td style="border:1px solid #cccccc;border-left:0px;">$dref->{'InvoiceNum'}</td>
						<td style="text-align:left;border:1px solid #cccccc;border-right:0px;">$dref->{ProductName}$star</td>
						<td style="text-align:left;border:1px solid #cccccc;border-right:0px;">$dref->{Name}</td>
						<td style="text-align:right;border:1px solid #cccccc;border-right:0px;">$dollarSymbol$lamount</td>
					</tr>
				];
			}
			my $camount=currency($amount||0);
			$product_confirmation=qq[
				<table class="permsTable">
					<tr>
						<th>Invoice Number</th>
						<th>Item</th>
						<th>Name</th>
						<th style="width:50px;">Price</th>
					</tr>
					$product_confirmation
					<tr>
						<th>Total</th>
						<th>&nbsp;</th>
						<th>&nbsp;</th>
						<td style="text-align:right;font-weight:bold;">$dollarSymbol$camount</td>
					</tr>
				</table>
                <div style= 'font-size:10pt'>$processFeeNote</div>
			] if $product_confirmation;
		}

		$body .= qq[
			<form method="POST" name="payform" action="$paymentSettings->{'gateway_url'}"  onsubmit="document.getElementById('submit_pay').disabled=true;return true;">
		] if (! $usePayPal and ! $useNAB);

		my $paymenttext  = $RegoFormObj
			? $RegoFormObj->getText('strPaymentText',1)
			: '';
		
		if ($allowPayment and $paymentSettings->{'paymentGatewayID'})	{
			if ($amount >= 0)	{
				$body .= qq[ 
					$product_confirmation 
					$paymenttext<br>
				];
				if (($useNAB or $usePayPal) and $externalGateway)	{
                    if (getVerifiedBankAccount($Data, $useNAB))   { 
						$body.=qq[<div class="payment_note"><p>Please confirm the details above, then click the <b>Pay Now</b> button to make an online payment.</p>] if ! $paymenttext;
						$body .=qq[ $externalGateway</div><p id ="final_msg"></p>];
						
                    }
                    else    {
					    $body.=qq[<p>Purchase cannot be made until this organisation fully configures their payment details</p>];
                    }
				}
				else	{
					$body.=qq[<p>Please confirm the details above, then click the <b>Continue to Credit Card Payment</b> button to make an online payment.</p>] if ! $paymenttext;
					$body .= qq[
						<input type="hidden" name="cr" value="$paymentSettings->{'currency'}">
						<input type="hidden" name="clientTransRefID" value="$intLogID">
						<input type="hidden" name="amount" value="$amount">
						<input type="hidden" name="client" value="$client">
						<input type="hidden" name="values" value="$values">
						<input type="hidden" name="return_url" value="$paymentSettings->{'return_url'}">
						<input type="hidden" name="return_failure_url" value="$paymentSettings->{'return_failure_url'}">
						<input type="hidden" name="email" value="">
						<input type="hidden" name="pgid" value="$paymentSettings->{'paymentGatewayID'}">
						<br><input type="submit" name="submit_pay" id="submit_pay" value="Continue to Credit Card Payment">
						</form>
					];
				}
			}
			else	{
				$body.=qq[
					$product_confirmation
					<p class="warningmsg" style="font-size:14px;">You cannot continue to Credit Card Payment whilst the amount is less than zero</p>
					</form>
					];

			}
		}
		else	{
			$body.=qq[
				$product_confirmation
				$paymenttext<br>
			];

		}
        $body .= $payLater if ($Data->{'RegoFormID'});
	}
	$body .=qq[<input type="hidden" id="clajax" value ="$client" /><input type="hidden" id="invoiceList" value ="$invoiceList" />];
	return $body;

}

sub getCheckoutAmount 	{

        my ($Data, $trans) = @_;

	my $db = $Data->{'db'};
	my $amount = 0;
	my $count = 0;

	my $st = qq[
		SELECT curAmount, intTransactionID
		FROM tblTransactions
		WHERE  intStatus = 0
			AND intTransactionID = ?
	];
	 $st = qq[
        SELECT T.intTransactionID, T.curAmount
                FROM tblTransactions as T
                    INNER JOIN tblEntity as E ON (E.intEntityID = intTXNEntityID)
                WHERE T.intTransactionID = ?
                        AND T.intRealmID = $Data->{'Realm'}
                        AND T.intStatus=0
    ];
    	my $qry = $db->prepare($st);
	for my $transid (@{$trans})	{
		$transid || next;
    		$qry->execute($transid);
		my $dref = $qry->fetchrow_hashref();
		$count++ if $dref->{intTransactionID};
		$amount += $dref->{curAmount};
	}

	my ($intDollars, $intCents) = 0;
    	if ($amount=~/\./) {
        	($intDollars, $intCents)= split /\./,$amount;
        	if ($intCents < 10) {$intCents .= "0";}
    	}
    	else {
    	    $intDollars = "$amount";
    	    $intCents = "00";
    	}
        return ($count, $intDollars, $intCents);

}

sub getPaymentSettings	{
	my ($Data, $external, $tempClientValues) = @_;
	$external ||= 0;
	my $db = $Data->{'db'};
	my $client='';
	my $clientValues = $tempClientValues || $Data->{'clientValues'};
	$client = setClient($clientValues) if ref $Data;
	my $PaymentOwnerClubID = 0;

	if ($Data->{'RegoFormID'})	{
		my $st = qq[
			SELECT intClubID FROM tblRegoForm WHERE intRegoFormID=? LIMIT 1
		];
    my $qry = $db->prepare($st);
    $qry->execute($Data->{'RegoFormID'});
		$PaymentOwnerClubID = $qry->fetchrow_array();
	}
	if ($Data->{'clientValues'}{'authLevel'} == $Defs::LEVEL_CLUB and $Data->{'clientValues'}{'clubID'} and $Data->{'clientValues'}{'clubID'} ne $Defs::INVALID_ID)	{
		$PaymentOwnerClubID = $Data->{'clientValues'}{'clubID'};
	}
	$PaymentOwnerClubID = 0 if ($PaymentOwnerClubID== -1);

	my $where = '';
	if ($Data->{'Realm'} or $Data->{'RealmSubType'})	{
		$where .= qq[ AND ] if $where;
		$where .= qq[ (];
		$where .= qq[
			intRealmID = $Data->{'Realm'}	
		] if $Data->{'Realm'};
		$where .= qq[ AND ] if ($Data->{'Realm'} and $Data->{'RealmSubType'});
		$where .= qq[
			intRealmSubTypeID IN (0, $Data->{'RealmSubType'})
		]if ($Data->{'RealmSubType'});
		$where .= qq[ AND intLevelID > 5];
		$where .= qq[) ];
	}

	if ($Data->{'SystemConfig'}{'PaymentConfigID'})	{
		$where = qq[intPaymentConfigID = $Data->{'SystemConfig'}{'PaymentConfigID'}];
	}
    my $softDescriptor='';
	if ($PaymentOwnerClubID and $clientValues->{'clubID'} and $clientValues->{'clubID'} >0)	{  #Use this if $PaymentOwnerClubID
		$where .= qq[ OR ] if $where;
		$where .= qq[
			 (intEntityID = $clientValues->{'clubID'}
                        AND intLevelID = $Defs::LEVEL_CLUB)
		];
        my $clubDescriptor = getSoftDescriptor($Data, undef, $Defs::LEVEL_CLUB, $clientValues->{'clubID'}, 0);
        $softDescriptor = $clubDescriptor if ($clubDescriptor);
	}
	my %settings = ();

	my $st = qq[
		SELECT * 
		FROM tblPaymentConfig
		WHERE $where
		ORDER BY intRealmSubTypeID DESC, intLevelID ASC, intGatewayType DESC
		LIMIT 1
	];
return \%settings if ! $where; 
    	my $qry = $db->prepare($st) or query_error($st);
	$qry->execute or query_error($st);
	my $dref = $qry->fetchrow_hashref();

	$settings{'intPaymentConfigID'} = $dref->{intPaymentConfigID} || 0;
	$settings{'paymentGatewayID'} = $dref->{intPaymentGatewayID} || 0;
	$settings{'gatewayType'} = $dref->{intGatewayType} || 0;
	$settings{'gatewayStatus'} = $dref->{intStatus} || 0;
	$settings{'gatewayPrefix'} = $dref->{strPrefix} || '';
	$settings{'gatewayCreditCardNoteRealm'} = $dref->{strCCNote} || '';
	$settings{'gatewayCreditCardNote'} = $dref->{strCCNote} || '';
	$settings{'gatewayCreditCardNote'} = qq[$softDescriptor] if $softDescriptor;
	$settings{'gateway_string'} = $dref->{strSalt};
	$settings{'gateway_url'} = $dref->{strGatewayURL};
	$settings{'gatewayLevel'} = $dref->{intLevelID} || 0;
	$settings{'gatewayRuleID'} = $dref->{intPaymentSplitRuleID} || 0;
	
	
	if ($external)	{
		$settings{'return_url'} = $dref->{strReturnExternalURL};
		$settings{'return_failure_url'} = $dref->{strReturnExternalFailureURL};
	}
	else	{
		$settings{'return_url'} = $dref->{strReturnURL};
		$settings{'return_failure_url'} = $dref->{strReturnFailureURL};
	}
	$settings{'return_url'} =~ s/XXAIDXX/$clientValues->{'assocID'}/g;
	$settings{'return_failure_url'} =~ s/XXAIDXX/$clientValues->{'assocID'}/g;

	$settings{'return_url'} .= qq[&amp;client=$client] if $client and $settings{'return_url'};
	$settings{'return_failure_url'} .= qq[&amp;client=$client] if $client and $settings{'return_failure_url'};
	$settings{'currency'} = $dref->{strCurrency} || 'AUD';
	$settings{'notification_address'} = $dref->{strNotificationAddress} || '';


	return \%settings;
}


sub createTransLog	{
        my ($Data, $paymentSettings, $trans, $amount) = @_;
	my $db = $Data->{'db'};
        my %fields=();
        $fields{amount} = $amount || 0;
 	my $assocID = $Data->{'clientValues'}{'assocID'} || 0;
	my $clubID = $Data->{'clientValues'}{'clubID'} || 0;
	$clubID = 0 if $clubID == $Defs::INVALID_ID;
	$assocID= 0 if $assocID == $Defs::INVALID_ID;

	if (! $assocID)	{
		my $tranID = 0;
		for my $k (@{$trans})	{
			$k || next;
    			$tranID = $k;
			last;
		}
		my $st = qq[
			SELECT intAssocID
			FROM tblTransactions
			WHERE intTransactionID = $tranID
		];
        	my $qry = $db->prepare($st) or query_error($st);
		$qry->execute or query_error($st);
        	$assocID = $qry->fetchrow_array() || 0;
	}
 	my $paymentConfigID= $paymentSettings->{'intPaymentConfigID'} || 0;
    deQuote($db, \%fields);
	my $paymentType = $paymentSettings->{'gatewayType'} == $Defs::GATEWAY_PAYPAL ? $Defs::PAYMENT_ONLINEPAYPAL : $Defs::PAYMENT_ONLINECREDITCARD;
	$paymentType = $Defs::PAYMENT_ONLINENAB if ($paymentSettings->{'gatewayType'} == $Defs::GATEWAY_NAB);
	my $intRegoFormID = $Data->{'RegoFormID'} || 0;
	my $authLevel = $Data->{'clientValues'}{'authLevel'} || 0;
    my $cgi = new CGI;
	if ($intRegoFormID and (! $clubID or $clubID == -1))	{
		my $stRegoForm =qq[
		SELECT
			intClubID
		FROM
			tblRegoForm
		WHERE 
			intRegoFormID = ?
		];
	    my $qryRegoForm = $db->prepare($stRegoForm);
		$qryRegoForm->execute($intRegoFormID);
	    my $regoFormClubID = $qryRegoForm->fetchrow_array() || 0;
		$clubID = $regoFormClubID if ($regoFormClubID and $regoFormClubID > 0);
	}

			
    my $sessionID = $cgi->cookie($Defs::COOKIE_REGFORMSESSION) || '';
        my $st= qq[
                INSERT INTO tblTransLog
                (dtLog, intAmount, intPaymentType, intRealmID, intAssocPaymentID, intClubPaymentID, intPaymentConfigUsedID, intRegoFormID, intSWMPaymentAuthLevel, strSessionKey)
                VALUES (SYSDATE(), $amount, $paymentType, $Data->{Realm}, $assocID, $clubID, $paymentConfigID, $intRegoFormID, $authLevel, ?)
        ];
        my $qry = $db->prepare($st) or query_error($st);
	$qry->execute($sessionID) or query_error($st);
        my $intLogID = $qry->{mysql_insertid};
	
        $st= qq[
       		INSERT INTO tblTXNLogs
       		(intTXNID, intTLogID)
		VALUES (?, $intLogID)
    	];
    	$qry = $db->prepare($st);
	for my $transid (@{$trans})	{
		$transid || next;
    		$qry->execute($transid);
	}
	return $intLogID;
}

sub displayPaymentLaterResult        {
    my ($Data, $intLogID, $pl,$external) = @_;
	$external ||= 0;

    my $m;
    my $chkvalue=$intLogID;
    $m = new MD5;
    $m->reset();
    $m->add($Defs::paylater_string, $chkvalue);
    $chkvalue = $m->hexdigest();

    if ($chkvalue ne $pl or ! $intLogID)   {
        return qq[There appears to a be a problem.];
    }
	my $client=setClient($Data->{'clientValues'}) || '';
	my $db = $Data->{'db'};
        $intLogID ||= 0;

	my $ID = $Data->{'clientValues'}{'personID'} || 0;
                my $EntityType=$Defs::LEVEL_PERSON;
                if ($Data->{'clientValues'}{'clubID'} and $Data->{'clientValues'}{'currentLevel'} == $Defs::LEVEL_CLUB) {
                        $ID = $Data->{'clientValues'}{'clubID'} || 0;
                        $EntityType = $Defs::LEVEL_CLUB;
                }
        my $st= qq[
                SELECT TL.*, E.intSubRealmID
                FRO tblTransLog as TL
					LEFT JOIN tblEntity as E ON (E.intEntityID = TL.intEntityPaymentID)
                WHERE TL.intLogID = ?
        ];
    	my $qry = $db->prepare($st) or query_error($st);
    	$qry->execute($intLogID) or query_error($st);
        my $transref = $qry->fetchrow_hashref();
	$Data->{'RegoFormID'} = $transref->{'intRegoFormID'} || 0;
	$Data->{'RealmSubType'} ||= $transref->{'intSubRealmID'} || 0;
	$Data->{'Realm'} ||= $transref->{'intRealmID'} || 0;
	$Data->{'clientValues'}{'assocID'} ||= $transref->{intAssocPaymentID} || 0;

        my $body = '';
		my $msg = qq[ <div class="warningmsg">Your transaction is confirmed, and marked as UNPAID</div><div style="clear:both;"></div> ];
        	$body .= qq[ $msg <br> ];
		if ($external)	{
			$st = qq[
				SELECT T.intTransactionID
				FROM tblTXNLogs as TXNLog
					INNER JOIN tblTransactions as T ON (T.intTransactionID = TXNLog.intTXNID)
				WHERE intTLogID= $intLogID
					AND T.intRealmID = $Data->{'Realm'}
					AND T.intStatus <> -1
			];
					#AND T.intID = $ID AND T.intTableType=$EntityType
			my @txns = ();
		
    			$qry = $db->prepare($st) or query_error($st);
    			$qry->execute or query_error($st);
			while (my $dref = $qry->fetchrow_hashref())	{
				push @txns, $dref->{intTransactionID};
				#$intPersonID = $dref->{intPersonID} || 0;
			}
		}
	my ($viewTLBody, $header) = TransLog::viewPayLaterTransLog($Data, $intLogID, $ID, $EntityType);
	$body .= $viewTLBody;
	return $body;
}
sub displayPaymentResult        {
    	my ($Data, $intLogID, $external, $msg) = @_;
	$external ||= 0;
	$msg ||= '';
	my $client=setClient($Data->{'clientValues'}) || '';
	my $db = $Data->{'db'};
        $intLogID ||= 0;

	my $ID = $Data->{'clientValues'}{'personID'} || 0;
                my $EntityType=$Defs::LEVEL_PERSON;
                if ($Data->{'clientValues'}{'clubID'} and $Data->{'clientValues'}{'currentLevel'} == $Defs::LEVEL_CLUB) {
                        $ID = $Data->{'clientValues'}{'clubID'} || 0;
                        $EntityType = $Defs::LEVEL_CLUB;
                }
        my $st= qq[
                SELECT TL.*, E.intSubRealmID
                FROM tblTransLog as TL
					LEFT JOIN tblEntity as E ON (E.intEntityID = TL.intEntityPaymentID)
                WHERE TL.intLogID = $intLogID
        ];
    	my $qry = $db->prepare($st) or query_error($st);
    	$qry->execute or query_error($st);
        my $transref = $qry->fetchrow_hashref();
	$Data->{'RegoFormID'} = $transref->{'intRegoFormID'} || 0;
	$Data->{'RealmSubType'} ||= $transref->{'intSubRealmID'} || 0;
	$Data->{'Realm'} ||= $transref->{'intRealmID'} || 0;

        my $body = '';
        my $re_pay_body = '';
	my $success=0;
        if ($transref->{strResponseCode} eq "1" or $transref->{strResponseCode} eq "OK" or $transref->{strResponseCode} eq "00" or $transref->{strResponseCode} eq "08" or $transref->{strResponseCode} eq 'Success')    {
                my $ttime = time();
        	$body .= qq[
                        <div align="center" class="OKmsg" style="font-size:14px;">Congratulations payment has been successful</div>
        	];
		$success=1;
        }
        else    {
		$msg = qq[ <div align="center" class="warningmsg" style="font-size:14px;">There was an error with your transaction</div> ] if ! $msg;
        	$body .= qq[
                	<center>
			$msg
                	<br>
                	</center>
            	];
		if ($external)	{
			$st = qq[
				SELECT T.intTransactionID
				FROM tblTXNLogs as TXNLog
					INNER JOIN tblTransactions as T ON (T.intTransactionID = TXNLog.intTXNID)
				WHERE intTLogID= $intLogID
					AND T.intRealmID = $Data->{'Realm'}
					AND T.intStatus <> -1
			];
					#AND T.intID = $ID AND T.intTableType=$EntityType
			my @txns = ();
		
    			$qry = $db->prepare($st) or query_error($st);
    			$qry->execute or query_error($st);
			while (my $dref = $qry->fetchrow_hashref())	{
				push @txns, $dref->{intTransactionID};
				#$intPersonID = $dref->{intPersonID} || 0;
			}
					
			$re_pay_body= checkoutConfirm($Data, \@txns, 1);
		}
        }
	my ($viewTLBody, $header) = TransLog::viewTransLog($Data, $intLogID, $ID, $EntityType);
	$body .= $viewTLBody;
	$body .= $re_pay_body;
	if ($success and ($transref->{'intPaymentType'} == $Defs::PAYMENT_ONLINEPAYPAL or $transref->{'intPaymentType'} == $Defs::PAYMENT_ONLINENAB) and $external) {
    my $RegoFormObj = RegoForm::RegoFormFactory::getRegoFormObj(
      $Data->{'RegoFormID'},
      $Data,
      $Data->{'db'},
    );
		my $RegoText=(defined $RegoFormObj) ? $RegoFormObj->getText('strSuccessText',1) : '';
		$body .= qq[<br><br>] . $RegoText || '';
	}
	return $body;
}

sub processTransLogFailure    {

    	my ($db, $intLogID, $otherRef1, $otherRef2, $otherRef3, $otherRef4, $otherRef5) = @_;
    	$intLogID ||= 0;
    
    my %fields=();
    $fields{otherRef1} = $otherRef1 || '';
    $fields{otherRef2} = $otherRef2 || '';
    $fields{otherRef3} = $otherRef3 || '';
    $fields{otherRef4} = $otherRef4 || '';
    $fields{otherRef5} = $otherRef5 || '';
    deQuote($db, \%fields);

    	my $st= qq[
        	UPDATE tblTransLog
        	SET strResponseCode = "-1", strResponseText = "FAILED", intStatus = $Defs::TXNLOG_FAILED, strOtherRef1 = $fields{otherRef1}, strOtherRef2 = $fields{otherRef2}, strOtherRef3 = $fields{otherRef3}, strOtherRef4 = $fields{otherRef4}, strOtherRef5 = $fields{otherRef5}
        	WHERE intLogID = $intLogID
			AND intStatus = $Defs::TXNLOG_PENDING
                        AND strResponseCode IS NULL
    	];
    	my $query = $db->prepare($st) or query_error($st);
    	$query->execute or query_error($st);
}
sub calcTXNInvoiceNum       {

        #return undef if (!$_[0] or (length($_[0]) != 8) or $_[0] =~ /^\d$/);
        return undef if (!$_[0] or $_[0] =~ /^\d$/);

        my ($count,$rt) = (0,0);

        foreach my $i (split //, $_[0]) {
                my $result = ($i * ($count++%2==0 ? 1 : 2)) || 0;
                $rt += ($result > 9) ? 1 + ($result % 10) : $result;
        }

        return (10 - ($rt % 10)) % 10;

}
sub invoiceNumToTXN	{

	my ($invoice_num) = @_;

	
	my $txnID = $invoice_num - 100000000; ## 1 more to handle checksum
	#my $checksum = substr($txnID, length($txnID)-1, 1);
	$txnID = substr($txnID, 0, length($txnID)-1);
	if ($invoice_num == TXNtoInvoiceNum($txnID))	{
		return $txnID;
	}
	else	{
		return -1;
	}
}

sub TXNtoInvoiceNum	{

	my ($txnID) = @_;

	my $invoice_num =qq[1] . sprintf("%0*d",7, $txnID);
	$invoice_num = $invoice_num . calcTXNInvoiceNum($invoice_num);
	return $invoice_num;
}

sub invoiceNumForm      {

        my ($db, $Data) = @_;

        my $output=new CGI;
        my %fields = $output->Vars;

        my $last_num =$fields{invoice_num} || '';
        my $all_nums = $fields{all_nums};#. qq[|$last_num];
        my %txns = split /\|/,$all_nums;
        $all_nums .= qq[|$last_num] if ! exists $txns{$last_num};

        $all_nums =~ s/^\|//;
        $all_nums =~ s/\|$//g;
        $all_nums ||= '';
        my $all_nums_body='';
        my $all_nums_list='';
	my $count=0;
        if ($all_nums)  {
                my @txns = split /\|/,$all_nums;
                $all_nums_body = qq[
                        <p class="text" style="margin-left:10px;"><span style="font-size:11px"><b>Below is a list of Transactions that will be paid for if you proceed:</b></span><br>
                        <table style="margin-left:10px;" class="permsTable">
                        <tr>
                                <th>Invoice Number</th>
                                <th>Payment For</th>
                                <th>Amount Due</th>
                                <th>$Data->{'SystemConfig'}{'invoiceNumFormAssocName'}</th>
                        </tr>
                ];
		my $intPaymentConfigID = 0;
		my $firstAssocID=0;
                for my $id (@txns)      {
                        my $txnID = invoiceNumToTXN($id);
                        next if $txnID == -1;
			my $dref = getTXNDetails($Data, $txnID,1);
			$firstAssocID= $dref->{'intAssocID'} if ! $firstAssocID;
			next if $firstAssocID and $firstAssocID != $dref->{'intAssocID'};
			next if ! $dref->{intTransactionID};
			$intPaymentConfigID = $dref->{intPaymentConfigID} if ! $intPaymentConfigID;
			next if $intPaymentConfigID != $dref->{intPaymentConfigID} or ! $intPaymentConfigID;
                        if ($dref->{intTransactionID})  {
                                $all_nums_body .= qq[
                                        <tr>
 <td style="text-align:left;border:1px solid #cccccc;border-left:0px;">$id</td>
                                                <td style="text-align:left;border:1px solid #cccccc;border-right:0px;">$dref->{Name}</td>
                                                <td style="text-align:left;border:1px solid #cccccc;border-right:0px;">\$$dref->{curAmount}</td>
                                                <td style="text-align:left;border:1px solid #cccccc;border-right:0px;">$dref->{strName}</td>
                                        </tr>
                                ];
                                $all_nums_list .= qq[|] if $all_nums_list;
                                $all_nums_list .= TXNtoInvoiceNum($dref->{intTransactionID});
				$count++;
                        }
                }
                $all_nums_body .= qq[</table></p>];
        }

	my $body = '';
        $body .= qq[
                $Data->{'SystemConfig'}{'invoiceNumFormHeader'}<br>
	];
	$body .= qq[
                
                <form method="POST" action="$Data->{'SystemConfig'}{'invoiceNumFormPOST'}">
                <input type="hidden" name="a" value="PAY">
                <input type="hidden" name="intPersonID" value="$fields{'intPersonID'}">
                <input type="hidden" name="all_nums" value="$all_nums_list">
                 $all_nums_body<br>
                <!--<p style="margin-left:10px;font-size:14px;color:green">Once all invoices have been added, click <b>Continue to confirmation</b> button to view payment summary screen (prior to entering Credit Card details).<br><br><input type="submit" value="Continue to confirmation"></p>-->
                <p style="margin-left:10px;font-size:14px;color:green">Click <b>Continue to confirmation</b> button to view payment summary screen (prior to entering Payment details).<br><br><input type="submit" value="Continue to confirmation"></p>
                </form>
        ] if $all_nums and $count;

		#<p style="font-size:14px;margin-left:10px;"><b>OR</b> If you have additional Invoices to include:</p>
        #] if $all_nums and $count;
	
    if (! $count and ! $all_nums)   {
	$body .= qq[<form method="POST" action="$Data->{'SystemConfig'}{'invoiceNumFormPOST'}">
                <p class="text" style="margin-left:10px;">Please enter invoice number to include: <input type="text" name="invoice_num" value="" size="10">
                <input type="hidden" name="all_nums" value="$all_nums_list">
                <input type="hidden" name="intPersonID" value="$fields{'intPersonID'}">
	];
	$body .= $count ? qq[ <input type="submit" value="Add another Invoice"> ] : qq[ <input type="submit" value="Add Invoice"> ];
	$body .= qq[</p>
                <input type="hidden" name="a" value="">
                </form>
	];
    }

        return $body;
}

sub getTXNDetails	{

	my ($Data, $txnID, $statusCHECK) = @_;

	$statusCHECK ||= 0;
	my $db = $Data->{'db'};
	my $statusWHERE = $statusCHECK ? qq[ AND T.intStatus=0] : '';
	my $st = qq[
        	SELECT T.intTransactionID, T.intTableType, T.intID, T.curAmount, P.strName as ProductName, A.intPaymentConfigID, A.strPaymentReceiptBodyHTML,A.strPaymentReceiptBodyTEXT , P.strGSTText, T.intQty, P.strProductNotes, P.strGroup as ProductGroup, A.strBusinessNo, T.intAssocID
                FROM tblTransactions as T
                	INNER JOIN tblAssoc as A ON (A.intAssocID = T.intAssocID)
			INNER JOIN tblProducts as P ON (P.intProductID = T.intProductID)
                WHERE T.intTransactionID = $txnID
                        AND A.intAllowPayment > 0
                        AND A.intAssocTypeID = $Data->{'RealmSubType'}
                        AND T.intRealmID = $Data->{'Realm'}
			$statusWHERE
                LIMIT 1
        ];
                        #AND T.intRealmSubTypeID= $Data->{'RealmSubType'}
        my $qry = $db->prepare($st) or query_error($st);
        $qry->execute or query_error($st);
        my $dref = $qry->fetchrow_hashref();

	$dref->{'InvoiceNum'} = TXNtoInvoiceNum($dref->{intTransactionID});
	$dref->{ProductName} = qq[$dref->{ProductGroup} - $dref->{ProductName}] if ($dref->{ProductGroup});
	if ($dref->{intTableType} == 1)       {
        	my $st_mem = qq[
                	SELECT 
                        CONCAT(strFirstname,' ',strSurname) as Name, 
                        strEmail,
                        strP1Email,
                        strEmail2,
                        strP1Email2,
                        strP2Email,
                        strP2Email2
                	FROM tblPerson
                	WHERE intPersonID = $dref->{intID}
                		AND intRealmID = $Data->{'Realm'}
                ];
        	my $qry_mem = $db->prepare($st_mem) or query_error($st_mem);
        	$qry_mem->execute or query_error($st_mem);
        	my $mref = $qry_mem->fetchrow_hashref();
		$dref->{Name}     = $mref->{Name}        || '';
		$dref->{Email}    = $mref->{strEmail}    || '';
		$dref->{Email2}   = $mref->{strEmail2}   || '';
		$dref->{P1Email}  = $mref->{strP1Email}  || '';
		$dref->{P1Email2} = $mref->{strP1Email2} || '';
		$dref->{P2Email}  = $mref->{strP2Email}  || '';
		$dref->{P2Email2} = $mref->{strP2Email2} || '';
        }
        if ($dref->{intTableType} == 2) {
		my $st_team = qq[
                	SELECT strName, strEmail
                	FROM tblTeam
                	WHERE intTeamID = $dref->{intID}
                ];
        	my $qry_team= $db->prepare($st_team) or query_error($st_team);
        	$qry_team->execute or query_error($st_team);
        	my $tref = $qry_team->fetchrow_hashref();
		$dref->{Name} = $tref->{strName} || '';
		$dref->{Email} = $tref->{strEmail} || '';
        }
        if ($dref->{intTableType} == 3) {
		my $st_club = qq[
                	SELECT strName, strEmail
                	FROM tblClub
                	WHERE intClubID = $dref->{intID}
                ];
        	my $qry_club= $db->prepare($st_club) or query_error($st_club);
        	$qry_club->execute or query_error($st_club);
        	my $cref = $qry_club->fetchrow_hashref();
		$dref->{Name} = $cref->{strName} || '';
		$dref->{Email} = $cref->{strEmail} || '';
        }
	return $dref;
	
}

sub EmailPaymentConfirmation	{

	my ($Data, $paymentSettings, $intLogID, $client, $RegoFormObj) = @_;

	my $st = qq[
		SELECT 
			* , 
			DATE_FORMAT(dtLog,'%d/%m/%Y') AS dateLog
		FROM tblTransLog
		WHERE intLogID = ?
			AND intStatus = 1
	];
	my $qry = $Data->{db}->prepare($st);
	$qry->execute($intLogID);
	my $tref = $qry->fetchrow_hashref();
	return if ! ref $tref;

	my $st_trans = qq[
		SELECT intTXNID
		FROM tblTXNLogs
		WHERE intTLogID = ?
	];
	my $qry_trans = $Data->{db}->prepare($st_trans);
	$qry_trans->execute($intLogID);
	my $to_address  = '';
    my $cc_address  = '';
    my $bcc_address = '';
	my $count=0;
	my @txns = ();

    #used for regoform only
    my $send_to_assoc    = '';
    my $send_to_club     = '';

	my %EmailsUsed=();
	while (my $trans_ref = $qry_trans->fetchrow_hashref())	{
		$count++;
		my $txnRef = getTXNDetails($Data, $trans_ref->{intTXNID}, 0);

        if ($RegoFormObj) {
            my $send_to_team    = '';
            my $send_to_member  = '';
            my $send_to_parents = '';

            my $pay_char = $RegoFormObj->getValue('intPaymentBits') || '';
            ($send_to_assoc, $send_to_club, $send_to_team, $send_to_member, $send_to_parents) = get_notif_bits($pay_char) if $pay_char;

            if ($RegoFormObj->getValue('intRegoType') != 2) {
                if ($send_to_member) {
                    $to_address .= check_email_address(\%EmailsUsed, $txnRef->{Email})  if $txnRef->{Email};
                    $cc_address .= check_email_address(\%EmailsUsed, $txnRef->{Email2}) if $RegoFormObj and $txnRef->{Email2};
                }
                if ($send_to_parents) {
                    $cc_address .= check_email_address(\%EmailsUsed, $txnRef->{P1Email})  if $txnRef->{P1Email};
                    $cc_address .= check_email_address(\%EmailsUsed, $txnRef->{P1Email2}) if $txnRef->{P1Email2};
                    $cc_address .= check_email_address(\%EmailsUsed, $txnRef->{P2Email})  if $txnRef->{P2Email};
                    $cc_address .= check_email_address(\%EmailsUsed, $txnRef->{P2Email2}) if $txnRef->{P2Email2};
                }
            }
            elsif ($send_to_team) {
                $to_address .= check_email_address(\%EmailsUsed, $txnRef->{Email}) if $txnRef->{Email};
            }
        }
        else {
            $to_address .= check_email_address(\%EmailsUsed, $txnRef->{Email})   if $txnRef->{Email};
            $cc_address .= check_email_address(\%EmailsUsed, $txnRef->{P1Email}) if $txnRef->{P1Email};
        }

		$txnRef->{strProductNotes}=~s/\n/<br>/g;
		push @txns, $txnRef;
	}

	my %TransData = (
		ReceiptHeader    => $Data->{'SystemConfig'}{'paymentReceiptHeaderHTML'} || '',
		TotalAmount      => $tref->{'intAmount'},
		BankRef          => $tref->{'strTXN'} || '',
		PaymentID        => $tref->{'intLogID'},
		DatePurchased    => $tref->{'dateLog'},
		Transactions     => \@txns,
		ReceiptFooter    => $Data->{'SystemConfig'}{'paymentReceiptFooterHTML'} || '',
		PaymentAssocType => $Data->{'SystemConfig'}{'paymentAssocType'} || '',
		DollarSymbol     => $Data->{'LocalConfig'}{'DollarSymbol'} || "\$",
	);
	
	{
		my $st = qq[
			SELECT DISTINCT
				E.strLocalName as EntityName.
                E.strEmail as EntityEmail,
				intNoPMSEmail,
				IF(TL.intSWMPaymentAuthLevel = 3 OR RF.intClubID >0, 'CLUB', 'MA') as SoldBy
			FROM
				tblTransLog as TL
				INNER JOIN tblEntity as E ON (E.intEntityID = TL.intEntityPaymentID)
				LEFT JOIN tblRegoForm as RF ON (RF.intRegoFormID = TL.intRegoFormID)
			WHERE
				TL.intLogID = ?
		];
		my $qry_assoc= $Data->{db}->prepare($st);
		$qry_assoc->execute($intLogID);

		my $orgname = '';
		my $assocID=0;
		while (my $dref = $qry_assoc->fetchrow_hashref())   {
			my $clubEmail = '';
			if($dref->{'SoldBy'} eq 'CLUB')	{
				$from_email_to_use = 'club';
				$orgname = $dref->{'ClubName'} || '';
			}
			else	{
				$orgname = $dref->{'AssocName'} || '';
			}

            #don't upset the way non-regoform payemnt emails are handled
            if ($RegoFormObj) {
                my $dbh = $Data->{'db'};
                my $clubID = $dref->{'intClubID'};

                #assoc & club emails dupes will already be filtered out. however, still need to be checked against the rest.
                my $club_emails_aref  = ($send_to_club and $clubID)  ? get_emails_list(ContactsObj->getList(dbh=>$dbh, associd=>$assocID, clubid=>$clubID, getpayments=>1)) : ''; #will be false for a team to assoc (type 2) form
		
                if ($club_emails_aref) {
                    foreach my $email (@$club_emails_aref) {
                        $clubEmail .= check_email_address(\%EmailsUsed, $email) if $email;
                    }
                }
            }
			$TransData{'OrgName'} = $orgname || '';
			$TransData{'strBusinessNo'} = $dref->{'strBusinessNo'} ? qq[<b>ABN:</b> $dref->{'strBusinessNo'}<br>] : '';

            my $first_club_email  = ($clubEmail)  ? extract_first($clubEmail)  : '';
            my $first_assoc_email = ($assocEmail) ? extract_first($assocEmail) : '';
		

			$paymentSettings->{notification_address} =$first_assoc_email 
				|| $dref->{AssocEmail} 
				|| $paymentSettings->{notification_address};

		if($from_email_to_use eq 'club') {
			$paymentSettings->{notification_address} = $first_club_email 	 
				|| $dref->{ClubEmail} 
				|| $paymentSettings->{notification_address};
 		}
        #    $bcc_address .= $assocEmail.$clubEmail;
		}
		$Data->{'clientValues'}{'assocID'} = $assocID;
		$Data->{'SystemConfig'}=getSystemConfig($Data);
	}
	$TransData{'AssocPaymentExtraDetails'} = $Data->{'SystemConfig'}{'AssocConfig'}{'AssocPaymentExtraDetails'} || '';
	sendTemplateEmail(
        $Data,
        'payments/payment_receipt.templ',
        \%TransData,
        $to_address,
        'Payment Received',
        $paymentSettings->{'notification_address'},
        $cc_address,
        $bcc_address,
    ) ;
	return 1;
}

sub check_email_address {
    my ($EmailsUsedRef, $inEmail) = @_;
    my $retEmail = '';

    if ($inEmail and !exists $EmailsUsedRef->{$inEmail}) {
        $retEmail = qq[$inEmail;];	
        $EmailsUsedRef->{$inEmail} = 1;
    }
    return $retEmail;
}

sub extract_first {
    my ($str) = @_;
    my @arr = split(/;/, $str);
    my $first = $arr[0];
    return $first;
}

sub UpdateCart	{

    my ($Data, $paymentSettings, $client, $txn, $code, $intLogID) = @_;

    deQuote($Data->{'db'}, \$txn);

	my $st= qq[
  	SELECT 
			intTXNID, 
			intStatus, 
			intTransLogID,
            intTempID
		FROM
			tblTransactions as T 
			INNER JOIN tblTXNLogs as TXNLog ON (T.intTransactionID= TXNLog.intTXNID)
		WHERE 
			TXNLog.intTLogID= $intLogID
   ];
   my $qry = $Data->{'db'}->prepare($st) or query_error($st);
   $qry->execute or query_error($st);

my $stUpdate= qq[
  	UPDATE 
			tblTransactions 
    SET 
			intStatus = 1, 
			dtPaid = SYSDATE(), 
			intTransLogID = $intLogID
		WHERE 
			intTransactionID=?
    	AND intStatus <> 1
   ];
    my $qryUpdate = $Data->{'db'}->prepare($stUpdate) or query_error($stUpdate);
    my $stTempUpdate = qq[
        UPDATE tblTempMember
        SET 
            intTransLogID = $intLogID
        WHERE   
            intTempMemberID =?
        ];
   
   my $qryTempUpdate = $Data->{'db'}->prepare($stTempUpdate) or query_error($stTempUpdate);


	while (my $dref = $qry->fetchrow_hashref())	{
		if ($dref->{'intStatus'} >= 1 and $dref->{'intTransLogID'} != $intLogID)	{
			##OOPS , ALREADY PAID, LETS MAKE A COPY OF TRANSACTION FOR RECODS
			copyTransaction($Data, $dref->{'intTXNID'}, $intLogID);
		}
		else	{
   		    $qryUpdate->execute($dref->{'intTXNID'});
		}
        # if there is a intTempID associated with this transaction record then tblTempMember should be updated (set the intTransLogID for that intTempMemberID record)
        if($dref->{'intTempID'}){
   		    $qryTempUpdate->execute($dref->{'intTempID'});
        }
	}

    $st = qq[
        DELETE S.* FROM tblRegoFormSession as S
            INNER JOIN tblTransLog as TL ON (TL.strSessionKey=S.strSessionKey)
        WHERE TL.intLogID=$intLogID
    ];
    $Data->{'db'}->do($st);


	PaymentSplitMoneyLog::calcMoneyLog($Data, $paymentSettings, $intLogID);
	
}

sub copyTransaction	{
	my ($Data, $txnID, $logID) = @_;
    
	my $st = qq[
		INSERT INTO tblTransactions	(
			intStatus,
      strNotes,
      curAmount,
      intQty,
      dtTransaction,
      dtPaid,
      intDelivered,
      intAssocID,
      intRealmID,
      intRealmSubTypeID,
      intID,
      intTempID,
      intTableType,
      intProductID,
      intTransLogID,
      intCurrencyID,
      intTempLogID,
			intExportAssocBankFileID,
      dtStart,
      dtEnd,
      curPerItem,
      intTXNClubID,
      intTXNTeamID,
      intRenewed
		)
		SELECT
			1,
      'Recreated',
      curAmount,
      intQty,
      dtTransaction,
      NOW(),
      intDelivered,
      intAssocID,
      intRealmID,
      intRealmSubTypeID,
      intID,
      intTempID,
      intTableType,
      intProductID,
      $logID,
      intCurrencyID,
      intTempLogID,
			intExportAssocBankFileID,
      dtStart,
      dtEnd,
      curPerItem,
      intTXNClubID,
      intTXNTeamID,
      intRenewed
		FROM
			tblTransactions
		WHERE
			intStatus<>0
			AND intTransactionID=$txnID
	];
    
	my $qry = $Data->{'db'}->prepare($st);
	$qry->execute();
	my $insert_txnID = $qry->{mysql_insertid};
 	$st= qq[
 		INSERT INTO tblTXNLogs
		(intTXNID, intTLogID)
		VALUES (?, ?)
	];
	$qry = $Data->{'db'}->prepare($st);

	$qry->execute($insert_txnID, $logID);
}

sub logRetry	{

	my ($db, $logID) = @_;

	my $st = qq[
		INSERT INTO tblTransLog_Retry (
			intLogID,
  		dtLog,
  		intAmount, 
  		strTXN, 
  		strResponseCode, 
  		strResponseText,
  		intPaymentType,
 			strBSB, 
  		strBank, 
  		strAccountName, 
  		strAccountNum, 
  		strReceiptRef,
  		intStatus 
		)
		SELECT
			intLogID,
  		dtLog,
  		intAmount, 
  		strTXN, 
  		strResponseCode, 
  		strResponseText,
  		intPaymentType,
 			strBSB, 
  		strBank, 
  		strAccountName, 
  		strAccountNum, 
  		strReceiptRef,
  		intStatus 
		FROM
			tblTransLog
		WHERE
			intLogID = ?
	];
  my $qry = $db->prepare($st);
  $qry->execute($logID);

}

sub processTransLog    {

    my ($db, $txn, $responsecode, $responsetext, $intLogID, $paymentSettings, $passedChkValue, $settlement_date, $otherRef1, $otherRef2, $otherRef3, $otherRef4, $otherRef5, $exportOK) = @_;

	$exportOK ||= 0;
    my %fields=();
    $intLogID ||= 0;
    $fields{txn} = $txn || '';
    $fields{responsecode} = $responsecode || '';
    $fields{responsetext} = $responsetext || '';
    $fields{settlement_date} = $settlement_date || '';
    $fields{otherRef1} = $otherRef1 || '';
    $fields{otherRef2} = $otherRef2 || '';
    $fields{otherRef3} = $otherRef3 || '';
    $fields{otherRef4} = $otherRef4 || '';
    $fields{otherRef5} = $otherRef5 || '';

	my $intStatus = $Defs::TXNLOG_FAILED;
	$intStatus = $Defs::TXNLOG_SUCCESS if ($responsecode eq "00" or $responsecode eq "08" or $responsecode eq "OK" or $responsecode eq "1" or $responsecode eq 'Success');

	my $statement = qq[
		SELECT intAmount, strResponseCode, intLogID
		FROM tblTransLog
		WHERE intLogID = $intLogID
	];
    my $query = $db->prepare($statement) or query_error($statement);
    $query->execute or query_error($statement);

	my ($amount, $existingResponseCode, $existingLogID)=$query->fetchrow_array();
	$amount ||= 0;
	$amount= sprintf("%.2f", $amount);
	$amount = 0 if $existingResponseCode;
	my $chkvalue = $amount . $intLogID . $responsecode;
    my $m;
    $m = new MD5;
    $m->reset();

    $m->add($paymentSettings->{'gateway_string'}, $chkvalue);
    $chkvalue = $m->hexdigest();

    deQuote($db, \%fields);
	if (! $responsecode)	{
		processTransLogFailure($db, $intLogID, $otherRef1, $otherRef2, $otherRef3, $otherRef4, $otherRef5);
	}
	else	{
		if ($existingResponseCode and $existingLogID)	{
			logRetry($db, $intLogID);
		}
    		$statement = qq[
        		UPDATE tblTransLog
        		SET dtLog=SYSDATE(), strTXN = $fields{txn}, strResponseCode = $fields{responsecode}, strResponseText = $fields{responsetext}, intStatus = $intStatus, dtSettlement=$fields{settlement_date}, strOtherRef1 = $fields{otherRef1}, strOtherRef2 = $fields{otherRef2}, strOtherRef3 = $fields{otherRef3}, strOtherRef4 = $fields{otherRef4}, strOtherRef5 = $fields{otherRef5} , intExportOK = $exportOK
        		WHERE intLogID = $intLogID
						and intStatus<> 1
    		];
    		$query = $db->prepare($statement) or query_error($statement);
    		$query->execute or query_error($statement);
	}

	$intLogID=0 if ($chkvalue ne $passedChkValue);

	return $intLogID || 0;
}

sub getRegoFormID_transLog  {

    my ($db, $logID) = @_;

    return 0 unless $logID;

    my $st = <<"EOS";
SELECT intRegoFormID FROM tblTransLog WHERE intLogID = $logID
EOS

  ## Query stuff
  my $qry = $db->prepare($st);
  $qry->execute or query_error($st);
  return $qry->fetchrow_array() || 0;
}

sub getVerifiedBankAccount   {

    my ($Data, $useNAB) = @_;

    ## Set up the ID & EntityType fields for assoc or club
    my $entityType = ($Data->{'clientValues'}{'clubID'} and $Data->{'clientValues'}{'clubID'} != $Defs::INVALID_ID) 
        ? $Defs::LEVEL_CLUB 
        : $Defs::LEVEL_ASSOC;

    my $intID = ($entityType == $Defs::LEVEL_CLUB) 
        ?  $Data->{'clientValues'}{'clubID'} 
        : $Data->{'clientValues'}{'assocID'} || 0;

    ## the where statement is to be the above ids by default
    my $where = qq[
        BA.intEntityID = $intID
        AND BA.intEntityTypeID = $entityType
    ];

    my $rfJoin = '';
	#REGOFORMS NOW CONTAIN clientValues.
    if ($Data->{'RegoFormID'})  {
        ## If the RegoFormID is passed, then override the where statement with the tblRegoForm
        $rfJoin = qq[
            LEFT JOIN tblRegoForm as RF ON (
                RF.intRegoFormID= $Data->{'RegoFormID'}
            )
        ];
        ## Check the owner of the regoform
        $where = qq[
                BA.intEntityID = IF(RF.intAssocID>0,IF(RF.intClubID > 0, RF.intClubID, RF.intAssocID),$intID)
                AND BA.intEntityTypeID = IF(RF.intAssocID>0,IF(RF.intClubID > 0, $Defs::LEVEL_CLUB, $Defs::LEVEL_ASSOC),$entityType)
        ];
    }

	my $nabFilter = '';
	my $emailJOIN = qq[INNER];
	if ($useNAB)	{
		$nabFilter = qq[ AND BA.intNABPaymentOK=1];
		$emailJOIN = qq[LEFT];
	}
    my $st = qq[
        SELECT
            BA.intEntityID
        FROM
            tblBankAccount as BA
            $emailJOIN JOIN tblVerifiedEmail as VE ON (
                VE.strEmail = BA.strMPEmail
                AND dtVerified IS NOT NULL
            )
            $rfJoin
        WHERE $where
			$nabFilter
        LIMIT 1
    ];

    my $query = $Data->{'db'}->prepare($st) or query_error($st);
    $query->execute or query_error($st);
    return $query->fetchrow_hashref() || '';
}
1;
