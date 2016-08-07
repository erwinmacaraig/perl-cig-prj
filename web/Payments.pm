#
# $Header: svn://svn/SWM/trunk/web/Payments.pm 11041 2014-03-19 05:17:52Z cregnier $
#

package Payments;
require Exporter;
@ISA = qw(Exporter);
@EXPORT=qw(handlePayments checkoutConfirm getPaymentSettings processTransLogFailure invoiceNumToTXN TXNtoTXNNumber TXNNumberToTXN TXNtoInvoiceNum invoiceNumForm getTXNDetails displayPaymentResult EmailPaymentConfirmation UpdateCart processTransLog getSoftDescriptor createTransLog getCheckoutAmount );
@EXPORT_OK=qw(handlePayments checkoutConfirm getPaymentSettings processTransLogFailure invoiceNumToTXN TXNtoTXNNumber TXNNumberToTXN TXNtoInvoiceNum invoiceNumForm getTXNDetails displayPaymentResult EmailPaymentConfirmation UpdateCart processTransLog getSoftDescriptor createTransLog getCheckoutAmount );

use lib '.', '..', "comp", 'RegoForm', "dashboard", "RegoFormBuilder",'PaymentSplit', "user";

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
#use RegoFormUtils;
use ContactsObj;
use Data::Dumper;
use TTTemplate;
require Products;
require TransLog;
require PaymentSplitMoneyLog;
require RegoForm::RegoFormFactory;
 
sub handlePayments	{

	my ($action, $Data, $external) = @_;
	$external ||= 0;
	my $body = '';
	if ($action =~ /DISPLAY/)	{
		my $intLogID = param('ci') || 0;
        my $payStatus =0 ;
		($payStatus, $body) = displayPaymentResult($Data, $intLogID, $external);
	}	
	if ($action =~ /LATER/)	{
		my $intLogID = param('ci') || 0;
		my $pl= param('pl') || 0;
		$body = displayPaymentLaterResult($Data, $intLogID, $pl, $external);
	}	
	return ($body, 'Payment Result');
}

sub getSoftDescriptor   {
    my ($Data, $paymentSettings, $entityTypeID, $entityID) = @_;

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

	my ($Data, $paymentSettings, $entityID, $trans, $amount) = @_;

        my $st = qq[
        	SELECT T.intTableType, T.intID, T.intTempID
            FROM tblTransactions as T
            WHERE T.intTransactionID = ?
                AND T.intRealmID = $Data->{'Realm'}
    	];

        my $qry = $Data->{'db'}->prepare($st);
    	my $dref='';
        for my $transid (@{$trans})     {
            $transid || next;
            $qry->execute($transid);
            $dref = $qry->fetchrow_hashref();
		    last;
        }
	    return if ! $dref;
        return if ! $paymentSettings->{'allowPayment'};

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

	if (defined $dref and $dref)    {
		$feeType = $paymentSettings->{feeAllocationType};
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
				(intProductID, intRealmID, intRealmSubTypeID, intID,intTempID, intTableType, curAmount, intStatus, intQty, intParentTXNID, strPayeeName)
				VALUES ($minFeeProductID,  $Data->{'Realm'}, $Data->{'RealmSubType'}, $dref->{intID}, $dref->{intTempID} , $dref->{intTableType}, $minFee, 0, 1, $dref->{'intParentTXNID'}, ? )
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
				(intProductID, intRealmID, intRealmSubTypeID, intID,intTempID, intTableType, curAmount, intStatus, intQty, intParentTXNID, strPayeeName)
				VALUES ($minFeeProductID,  $Data->{'Realm'}, $Data->{'RealmSubType'}, $dref->{intID},$dref->{intTempID},  $dref->{intTableType}, $fee, 0, 1, $dref->{'intParentTXNID'}, ?)
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
    $factor = $factor *100;
    $factor = 0 if ($factor <= 0);
    return $factor;
}

sub checkoutConfirm	{
	my($Data, $paymentType, $trans, $external, $payTryReturn)=@_;
    $payTryReturn ||= 0;
	$external ||= 0; ## Pop CC in NEW window ?

    my $lang = $Data->{'lang'};
	$Data->{'SystemConfig'}=getSystemConfig($Data);
	$Data->{'LocalConfig'}=getLocalConfig($Data);
    my $authLevel = $Data->{'clientValues'}{'authLevel'}||=$Defs::INVALID_ID;
    my $entityID = getID($Data->{'clientValues'}, $authLevel);

	my $dollarSymbol = $Data->{'SystemConfig'}{'DollarSymbol'} || "\$";
    
    my $compulsory = 0;
	my $RegoFormObj = undef;

    my $formID = $Data->{'RegoFormID'} || 0;
	my $client=setClient($Data->{'clientValues'}) || '';
	my $db = $Data->{'db'};
	my $body;
	my ($count, $dollars, $cents) = getCheckoutAmount($Data, $trans);
	my $amount = "$dollars.$cents";
    my $m;
    $m = new MD5;
    $m->reset();
    $amount =  sprintf("%.2f", $amount);

    my ($paymentSettings, @PaymentSettings_array) = getPaymentSettings($Data, $paymentType, 0, $external);
    
    my $onlinePayment = $paymentSettings->{'onlinePayment'} || 0;
	if ($onlinePayment) {
	    my ($minFeeTrans, $fee) = (0,0);
		($minFeeTrans, $fee) = checkMinFeeAmount($Data, $paymentSettings, $entityID, $trans, $amount) if ($amount>0);
		if ($minFeeTrans)	{
		    push @{$trans}, $minFeeTrans;
			my ($count, $dollars, $cents) = getCheckoutAmount($Data, $trans);
			$amount = "$dollars.$cents";
        	$amount =  sprintf("%.2f", $amount);
		}
    }
	# Need to create TransLog record
    my $intLogID = $count ? createTransLog($Data, $paymentSettings, $entityID, $trans, $amount) : 0;
	my $payLater = '';

    my $values = $amount . $intLogID . $paymentSettings->{'paymentGatewayID'} . $paymentSettings->{'currency'};
    $m->add($paymentSettings->{'gatewaySalt'}, $values);
    $values = $m->hexdigest();
    my $cr = $paymentSettings->{'currency'} || '';

    my $allowPayment = $paymentSettings->{'allowPayment'} || 0;
	$allowPayment=0	if (! $external and $Data->{'clientValues'}{'authLevel'} < $Defs::LEVEL_CLUB);

    my $session = $Data->{'sessionKey'};
	my $paymentURL = qq[$Defs::base_url/paypal.cgi?nh=$Data->{'noheader'}&amp;ext=$external&amp;a=P&amp;client=$client&amp;ci=$intLogID&amp;formID=$formID&amp;session=$session;compulsory=$compulsory];
	my $formTarget = $external ;#? qq[ target="other" onClick="window.open('$paymentURL','other','location=no,directories=no,menubar=no,statusbar=no,toolbar=no,scrollbars=yes,height=820,width=870,resizable=yes');return false;" ] : '';
    my $gatewayImage = $paymentSettings->{'gatewayImage'} || '';
	my $externalGateway= qq[
	    <div><img src="images/PP-CC.jpg" border="0"></div><br>
		<br><a $formTarget id ="payment" href="$paymentURL"><img src="$gatewayImage" border="0"  alt="Pay Now"></a>
	];

    my $chkvalue= $amount . $intLogID . $paymentSettings->{'currency'};
    if ($paymentType == $Defs::PAYMENT_ONLINENAB or $paymentType == $Defs::PAYMENT_ONLINECREDITCARD)    {
        my $m;
#warn("AM:$amount $intLogID " . $paymentSettings->{'currency'} . "#######" . $paymentSettings->{'gatewaySalt'});
        $m = new MD5;
        $m->reset();
        $m->add($paymentSettings->{'gatewaySalt'}, $chkvalue);
        $chkvalue = $m->hexdigest();
#warn("################## SWM END $chkvalue");
        $paymentURL = $paymentSettings->{'gateway_url'} .qq[?nh=$Data->{'noheader'}&amp;ext=$external&amp;a=P&amp;formID=$formID&amp;client=$client&amp;ci=$intLogID&amp;chkv=$chkvalue&amp;session=$session;compulsory=$compulsory&amp;amount=$amount];
        my $formTarget = $external ? qq[ target="other" onClick="window.open('$paymentURL','other','location=no,directories=no,menubar=no,statusbar=no,toolbar=no,scrollbars=yes,height=820,width=870,resizable=yes');return false;" ] : '';
        $externalGateway= qq[
          	<div class="accepted">
							<p>]. $lang->txt('We Accept').qq[</p>
							<span class="visa-logo"><img src="images/visa_logo.png" border="0"></span>
							<span class="mcard-logo"><img src="images/mcard_logo.png" border="0"></span>
						</div>	
					];
	  	if (! $external)	{
    	    $externalGateway .= qq[ <a href="$paymentURL"  id ="payment" type="button" style="padding:2px 30px;font-size:16px;"><img src="images/paynow.gif" alt="Pay Now"></a>];
	  	}
	  	else	{
    	    $externalGateway .= qq[<span class="btn-main"><a ttarget="paywin" href="$paymentURL">Proceed to Payment</a></span>];
	  	}
    }

	if (($onlinePayment) and $amount eq '0.00')	{
	    my $responsetext = 'Zero paid';
        my $txn = 'Zero-' . time(); 
		processTransLog($Data->{'db'}, $txn, 'OK', 'OK', $responsetext, $intLogID, $paymentSettings, undef, undef, '', '', '', '', '', '','',1);
		UpdateCart($Data, undef, $Data->{'client'}, undef, undef, $intLogID);
#        EmailPaymentConfirmation($Data, $paymentSettings, $intLogID, $client, $RegoFormObj);
         Products::product_apply_transaction($Data,$intLogID);
        return ($intLogID, 0, '', undef) if $payTryReturn;
		return '';
	}

    return ($intLogID, $amount, $chkvalue, $session, $paymentSettings) if $payTryReturn;
    return;

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
				my $lamount=$dref->{'curAmount'} || 0;
				$invoiceList .= $invoiceList ? qq[,$dref->{'InvoiceNum'}] : $dref->{'InvoiceNum'};
				$product_confirmation.=qq[
					<tr>
						<td>$dref->{'InvoiceNum'}</td>
						<td>$dref->{ProductName}$star</td>
						<td>$dref->{Name}</td>
						<td class="align-right">$dollarSymbol$lamount</td>
					</tr>
				];
			}
			my $camount=$amount||0;
			$product_confirmation=qq[
				<table class="table" cellspacing="0" cellpadding="0" border="0">
					<thead>
						<tr>
							<td>].$lang->txt('Transaction Number').qq[</td>
							<td>].$lang->txt('Item').qq[</td>
							<td>].$lang->txt('Name').qq[</td>
							<td class="align-right">].$lang->txt('Price').qq[</td>
						</tr>
					</thead>
					$product_confirmation
					<tbody>
						<tr>
							<td>].$lang->txt('Total').qq[</td>
							<td>&nbsp;</td>
							<td>&nbsp;</td>
							<td class="align-right">$dollarSymbol$camount</td>
						</tr>
					</tbody>
				</table>
                <div style= 'font-size:10pt'>$processFeeNote</div>
			] if $product_confirmation;
		}

		$body .= qq[
			<form method="POST" name="payform" action="$paymentSettings->{'gateway_url'}"  onsubmit="document.getElementById('submit_pay').disabled=true;return true;">
		] if (! $onlinePayment);

		my $paymenttext  = $RegoFormObj
			? $RegoFormObj->getText('strPaymentText',1)
			: '';
		
		if ($allowPayment and $paymentSettings->{'paymentGatewayID'})	{
			if ($amount >= 0)	{
				$body .= qq[ 
					$product_confirmation 
					$paymenttext<br> 
				];
				if (($onlinePayment) and $externalGateway)	{
						$body.=qq[<div class="payment_note"><p>]. $lang->txt('Please confirm the details above, then click the <b>Pay Now</b> button to make an online payment').qq[</p>] if ! $paymenttext;
						$body .=qq[ $externalGateway</div><p id ="final_msg"></p>];
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

	my $amount = 0;
	my $count = 0;

	my $st = qq[
        SELECT T.intTransactionID, T.curAmount
        FROM tblTransactions as T
        WHERE 
            T.intTransactionID = ?
            AND T.intRealmID = $Data->{'Realm'}
            AND T.intStatus=0
    ];
    my $qry = $Data->{'db'}->prepare($st);
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
    my ($Data, $paymentType, $paymentConfigID, $external, $tempClientValues) = @_;
	$external ||= 0;
	my $db = $Data->{'db'};
	my $client='';
	my $clientValues = $tempClientValues || $Data->{'clientValues'};
	$client = setClient($clientValues) if ref $Data;

	my $where = '';
	if ($Data->{'RealmSubType'})	{
	    $where = qq[ AND intRealmSubTypeID IN (0, $Data->{'RealmSubType'}) ];
	}
    if ($paymentConfigID)   {
        $where .= qq[ AND intPaymentConfigID= $paymentConfigID];
    }
    if ($paymentType)   {
        $where .= qq[ AND intPaymentType = $paymentType ];
    }

    my $softDescriptor='';

	my $st = qq[
		SELECT * 
		FROM tblPaymentConfig
		WHERE   
            intRealmID = $Data->{'Realm'}
            $where
		ORDER BY intRealmSubTypeID DESC
	];
    my $qry = $db->prepare($st) or query_error($st);
	$qry->execute or query_error($st);
    my @Settings=();
    my %Setting=();
    my $count=0;
    while (my $dref = $qry->fetchrow_hashref()) {
	    my %settings = ();
        my $paymentConfigID = $dref->{intPaymentConfigID} || next;
	    $settings{'intPaymentConfigID'} = $dref->{intPaymentConfigID} || 0;
	    $settings{'gatewayCode'} = $dref->{strGatewayCode} || '';
	    $settings{'gatewayName'} = $dref->{strGatewayName} || '';
        $settings{'feeAllocationType'} = $dref->{'intFeeAllocationType'} || 0;
        $settings{'gatewayStatus'} = $dref->{'intGatewayStatus'} || 0;
        $settings{'paymentGatewayID'} = $dref->{intPaymentGatewayID} || 0;
        $settings{'paymentType'} = $dref->{intPaymentType} || 0;
        $settings{'gatewayType'} = $dref->{intGatewayType} || 0;
        $settings{'gatewayPrefix'} = $dref->{strPrefix} || '';
        $settings{'paymentBusinessNumber'} = $dref->{PaymentBusinessNumber} || '';
        $settings{'notification_address'} = $dref->{strNotificationAddress} || '';
        $settings{'gatewayCreditCardNoteRealm'} = $dref->{strCCNote} || '';
        $settings{'gatewayCreditCardNote'} = $dref->{strCCNote} || '';
        $settings{'gatewayCreditCardNote'} = qq[$softDescriptor] if $softDescriptor;
        $settings{'gatewaySalt'} = $dref->{strGatewaySalt};
        $settings{'gateway_url'} = $dref->{strGatewayURL1};
        $settings{'gateway_url2'} = $dref->{strGatewayURL2};
        $settings{'gateway_url3'} = $dref->{strGatewayURL3};
        $settings{'gatewayImage'} = $dref->{strGatewayImage} || '';
        $settings{'gatewayReturnURL'} = $dref->{strReturnURL};
        $settings{'gatewayCancelURL'} = $dref->{strCancelURL};
        $settings{'gatewayUsername'} = $dref->{strGatewayUsername} || '';
        $settings{'gatewayPassword'} = $dref->{strGatewayPassword} || '';
        $settings{'gatewaySignature'} = $dref->{strGatewaySignature} || '';
        $settings{'gatewayVersion'} = $dref->{strGatewayVersion} || '';
        $settings{'gatewayLevel'} = $dref->{intLevelID} || 0;
        $settings{'gatewayRuleID'} = $dref->{intPaymentSplitRuleID} || 0;
        $settings{'allowPayment'} = $dref->{intAllowPayment} || 0;
        $settings{'gatewayProcessPreGateway'} = $dref->{intProcessPreGateway} || 0;
        $settings{'onlinePayment'} = (exists $Defs::onlinePaymentTypes{$paymentType}) ? 1 : 0; 

        if ($external)	{
            $settings{'return_url'} = $dref->{strReturnExternalURL};
            $settings{'return_failure_url'} = $dref->{strReturnExternalFailureURL};
        }
        else	{
            $settings{'return_url'} = $dref->{strReturnURL};
            $settings{'return_failure_url'} = $dref->{strReturnFailureURL};
        }
        $settings{'return_url'} .= qq[&amp;client=$client] if $client and $settings{'return_url'};
        $settings{'return_failure_url'} .= qq[&amp;client=$client] if $client and $settings{'return_failure_url'};
        $settings{'currency'} = $dref->{strCurrency} || '';
        push @Settings, \%settings;
        %Setting = %settings;
        $count++;
    }
        

	return (\%Setting, \@Settings);
}


sub createTransLog	{
    my ($Data, $paymentSettings, $entityID, $trans, $amount) = @_;
	my $db = $Data->{'db'};
    my %fields=();
    $fields{amount} = $amount || 0;
    my $authLevel = $Data->{'clientValues'}{'authLevel'}||=$Defs::INVALID_ID;
    #if (! $entityID)    {
        $entityID = getID($Data->{'clientValues'}, $authLevel);
    #}
	$entityID= 0 if $entityID== $Defs::INVALID_ID;

 	my $paymentConfigID= $paymentSettings->{'intPaymentConfigID'} || 0;
    deQuote($db, \%fields);
	my $paymentType = $paymentSettings->{'paymentType'};
	my $intRegoFormID = $Data->{'RegoFormID'} || 0;
	$authLevel = $Data->{'clientValues'}{'authLevel'} || 0;
    my $cgi = new CGI;
	if ($intRegoFormID and (! $entityID or $entityID == -1))	{
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
		$entityID = $regoFormClubID if ($regoFormClubID and $regoFormClubID > 0);

	}

    my $sessionID = $cgi->cookie($Defs::COOKIE_REGFORMSESSION) || '';
        my $st= qq[
                INSERT INTO tblTransLog
                (dtLog, intAmount, intPaymentType, intRealmID, intEntityPaymentID, intPaymentConfigID, intRegoFormID, intSWMPaymentAuthLevel, intPaymentByLevel, strSessionKey)
                VALUES (SYSDATE(), $amount, $paymentType, $Data->{Realm}, $entityID, $paymentConfigID, $intRegoFormID, $authLevel,$authLevel, ?)
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

    my $st= qq[
        SELECT TL.*, E.intSubRealmID
        FROM tblTransLog as TL
		LEFT JOIN tblEntity as E ON (E.intEntityID = TL.intEntityPaymentID)
        WHERE TL.intLogID = ?
    ];
    my $qry = $db->prepare($st) or query_error($st);
    $qry->execute($intLogID) or query_error($st);
    my $transref = $qry->fetchrow_hashref();
	$Data->{'RegoFormID'} = $transref->{'intRegoFormID'} || 0;
	$Data->{'RealmSubType'} ||= $transref->{'intSubRealmID'} || 0;
	$Data->{'Realm'} ||= $transref->{'intRealmID'} || 0;

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
		my @txns = ();
		
    	$qry = $db->prepare($st) or query_error($st);
    	$qry->execute or query_error($st);
		while (my $dref = $qry->fetchrow_hashref())	{
		    push @txns, $dref->{intTransactionID};
		}
	}
	my ($viewTLBody, $header) = TransLog::viewPayLaterTransLog($Data, $intLogID);
	$body .= $viewTLBody;
	return $body;
}

sub displayPaymentResult        {
    my ($Data, $intLogID, $external, $msg, $minsValidFor) = @_;
	$external ||= 0;
	$msg ||= '';
    $minsValidFor ||= 0;
	my $client=setClient($Data->{'clientValues'}) || '';
	my $db = $Data->{'db'};
    $intLogID ||= 0;

    my $lang = $Data->{'lang'};
    my $st= qq[
        SELECT TL.*, E.intSubRealmID
        FROM tblTransLog as TL
		LEFT JOIN tblEntity as E ON (E.intEntityID = TL.intEntityPaymentID)
        WHERE TL.intLogID = $intLogID
            AND TL.intAmount > 0
    ];
    if ($minsValidFor and $minsValidFor > 0)  {
        $st .= qq[ AND TL.dtLog >= DATE_ADD(NOW(), INTERVAL -$minsValidFor MINUTE)];
    }
    my $qry = $db->prepare($st) or query_error($st);
    $qry->execute or query_error($st);
    my $transref = $qry->fetchrow_hashref();

    return (-1, '') if (! $transref); ## Don't display if no TLog found.... Note Amount must be > 0

	$Data->{'RegoFormID'} = $transref->{'intRegoFormID'} || 0;
	$Data->{'RealmSubType'} ||= $transref->{'intSubRealmID'} || 0;
	$Data->{'Realm'} ||= $transref->{'intRealmID'} || 0;
    my $paymentType = $transref->{'intPaymentType'};

    my $body = '';
	my $success=$transref->{'intStatus'};
    #if ($transref->{strResponseCode} eq "1" or $transref->{strResponseCode} eq "OK" or $transref->{strResponseCode} eq "00" or $transref->{strResponseCode} eq "08" or $transref->{strResponseCode} eq 'Success')    {
	
    if ($transref->{'intStatus'} == $Defs::TXNLOG_SUCCESS)   {
        my $ttime = time();
        $body .= qq[
            <div align="center" class="OKmsg" style="font-size:14px;">] . $lang->txt('Congratulations your payment has been successful') . qq[</div>
        ];
    }
    elsif ($transref->{'intStatus'} == $Defs::TXNLOG_HOLD)   {
        my $ttime = time();
        $body .= qq[
            <div align="center" class="OKmsg" style="font-size:14px;">] . $lang->txt('Your payment has been put on Hold') . qq[</div>
        ];
    }
    else    {
		$msg = qq[ <div align="center" class="warningmsg" style="font-size:14px;">] . $lang->txt('We are sorry, there was a problem with your payment.') . qq[</div> ] if (! $msg and $transref->{'intAmount'});
        $body .= qq[ <center>$msg<br></center> ];
		if ($external)	{
			$st = qq[
				SELECT T.intTransactionID
				FROM tblTXNLogs as TXNLog
					INNER JOIN tblTransactions as T ON (T.intTransactionID = TXNLog.intTXNID)
				WHERE intTLogID= $intLogID
					AND T.intRealmID = $Data->{'Realm'}
					AND T.intStatus <> -1
		    ];
			my @txns = ();
		
    	    $qry = $db->prepare($st) or query_error($st);
    	    $qry->execute or query_error($st);
			while (my $dref = $qry->fetchrow_hashref())	{
				push @txns, $dref->{intTransactionID};
			}
		}
    }
	my ($viewTLBody, $header) = TransLog::viewTransLog($Data, $intLogID);
	$body .= $viewTLBody if ($success);
	return ($success, $body);
}

sub processTransLogFailure    {

    my ($db, $intLogID, $gatewayResponseCode, $otherRef1, $otherRef2, $otherRef3, $otherRef4, $otherRef5, $authID, $text) = @_;
    $intLogID ||= 0;

    my %fields=();
    $fields{gatewayResponseCode} = $gatewayResponseCode || '';
    $fields{otherRef1} = $otherRef1 || '';
    $fields{otherRef2} = $otherRef2 || '';
    $fields{otherRef3} = $otherRef3 || '';
    $fields{otherRef4} = $otherRef4 || '';
    $fields{otherRef5} = $otherRef5 || '';
    $fields{GATEWAY_AUTH_ID} = $authID || '';
    $fields{GATEWAY_RESPONSE_TEXT} = $text || '';
    #deQuote($db, \%fields);

    my $st= qq[
        UPDATE tblTransLog
        SET strResponseCode = "-1", strResponseText = "PAYMENT_FAILED", intStatus = $Defs::TXNLOG_FAILED, strGatewayResponseCode = ?, strOtherRef1 = ?, strOtherRef2 = ?, strOtherRef3 = ?, strOtherRef4 = ?, strOtherRef5 = ?, strAuthID=?, strText=?
        WHERE intLogID = $intLogID
		    AND intStatus = $Defs::TXNLOG_PENDING
            AND strResponseCode IS NULL
    ];
    my $query = $db->prepare($st) or query_error($st);
    $query->execute($fields{'gatewayResponseCode'}, $fields{otherRef1}, $fields{otherRef2}, $fields{otherRef3}, $fields{otherRef4}, $fields{otherRef5}, $fields{GATEWAY_AUTH_ID}, $fields{GATEWAY_RESPONSE_TEXT}) or query_error($st);
}

sub calcTXNInvoiceNum       {

    return undef if (!$_[0] or $_[0] =~ /^\d$/);

    my ($count,$rt) = (0,0);

    foreach my $i (split //, $_[0]) {
        my $result = ($i * ($count++%2==0 ? 1 : 2)) || 0;
        $rt += ($result > 9) ? 1 + ($result % 10) : $result;
    }

    return (10 - ($rt % 10)) % 10;

}
sub TXNNumberToTXN	{

	my ($invoice_num) = @_;

	my $txnID = $invoice_num - 800000000; ## 1 more to handle checksum
	$txnID = substr($txnID, 0, length($txnID)-1);
	if ($invoice_num == TXNtoTXNNumber($txnID))	{
		return $txnID;
	}
	else	{
		return -1;
	}
}
sub invoiceNumToTXN	{

	my ($invoice_num) = @_;

	my $txnID = $invoice_num - 800000000; ## 1 more to handle checksum
	$txnID = substr($txnID, 0, length($txnID)-1);
	if ($invoice_num == TXNtoTXNNumber($txnID))	{
		return $txnID;
	}
	else	{
		return -1;
	}
}
sub TXNtoInvoiceNum {

	my ($txnID) = @_;

	my $invoice_num =qq[8] . sprintf("%0*d",7, $txnID);
	$invoice_num = $invoice_num . calcTXNInvoiceNum($invoice_num);
	return $invoice_num;
}
sub TXNtoTXNNumber	{

	my ($txnID) = @_;

	my $invoice_num =qq[8] . sprintf("%0*d",7, $txnID);
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
                    <th>Transaction Number</th>
                    <th>Payment For</th>
                    <th>Amount Due</th>
                    <th>$Data->{'SystemConfig'}{'invoiceNumFormAssocName'}</th>
                </tr>
        ];
		my $intPaymentConfigID = 0;
		my $firstAssocID=0;
        for my $id (@txns)      {
            my $txnID = TXNNumberToTXN($id);
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
                        <td>$id</td>
                        <td>$dref->{Name}</td>
                        <td>\$$dref->{curAmount}</td>
                        <td>$dref->{strName}</td>
                    </tr>
                ];
                $all_nums_list .= qq[|] if $all_nums_list;
                $all_nums_list .= TXNtoTXNNumber($dref->{intTransactionID});
				$count++;
            }
        }
        $all_nums_body .= qq[</table></p>];
    }

    my $body = '';
    $body = qq[
        $Data->{'SystemConfig'}{'invoiceNumFormHeader'}<br>
        <form method="POST" action="$Data->{'SystemConfig'}{'invoiceNumFormPOST'}">
        <input type="hidden" name="a" value="PAY">
        <input type="hidden" name="intPersonID" value="$fields{'intPersonID'}">
        <input type="hidden" name="all_nums" value="$all_nums_list">
        $all_nums_body<br>
        <p style="margin-left:10px;font-size:14px;color:green">Click <b>Continue to confirmation</b> button to view payment summary screen (prior to entering Payment details).<br><br><input type="submit" value="Continue to confirmation"></p>
        </form>
    ] if $all_nums and $count;

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
        	SELECT T.intTransactionID, I.strInvoiceNumber, T.intTableType, T.intID, T.curAmount, P.strName as ProductName, P.strGSTText, T.intQty, P.strProductNotes, P.strGroup as ProductGroup
                FROM tblTransactions as T
			LEFT JOIN tblInvoice I ON I.intInvoiceID = T.intInvoiceID
			INNER JOIN tblProducts as P ON (P.intProductID = T.intProductID)
                WHERE T.intTransactionID = $txnID
                        AND T.intRealmID = $Data->{'Realm'}
			            $statusWHERE
                LIMIT 1
    ];
    my $qry = $db->prepare($st) or query_error($st);
    $qry->execute or query_error($st);
    my $dref = $qry->fetchrow_hashref();

	
	#$dref->{'InvoiceNum'} = TXNtoInvoiceNum($dref->{intTransactionID}); 
	$dref->{'InvoiceNum'} = $dref->{'strInvoiceNumber'};

	#$dref->{'InvoiceNum'} = TXNtoTXNNumber($dref->{intTransactionID});# new

	$dref->{ProductName} = qq[$dref->{ProductGroup} - $dref->{ProductName}] if ($dref->{ProductGroup});
	if ($dref->{intTableType} == 1)       {
        	my $st_mem = qq[
                SELECT 
                    CONCAT(strLocalFirstname,' ',strLocalSurname) as Name, 
                    strEmail,
                    strP1Email,
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
		    $dref->{P1Email}  = $mref->{strP1Email}  || '';
		    $dref->{P1Email2} = $mref->{strP1Email2} || '';
		    $dref->{P2Email}  = $mref->{strP2Email}  || '';
		    $dref->{P2Email2} = $mref->{strP2Email2} || '';
    }
    if ($dref->{intTableType} > 1) {
	    my $st_entity= qq[
            SELECT strLocalName, strEmail
            FROM tblEntity
            WHERE intEntityID = $dref->{intID}
        ];
        my $qry_entity= $db->prepare($st_entity) or query_error($st_entity);
        $qry_entity->execute or query_error($st_entity);
        my $eref = $qry_entity->fetchrow_hashref();
		$dref->{Name} = $eref->{strLocalName} || '';
		$dref->{Email} = $eref->{strEmail} || '';
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
	my ($to_address, $cc_address, $bcc_address) = ('','','');
	my $count=0;
	my @txns = ();

    my $send_to_club     = '';

	my %EmailsUsed=();
	while (my $trans_ref = $qry_trans->fetchrow_hashref())	{
		$count++;
		my $txnRef = getTXNDetails($Data, $trans_ref->{intTXNID}, 0);
        
		$to_address .= check_email_address(\%EmailsUsed, $txnRef->{Email})   if $txnRef->{Email};
        #$cc_address .= check_email_address(\%EmailsUsed, $txnRef->{P1Email}) if $txnRef->{P1Email};
		$txnRef->{strProductNotes}=~s/\n/<br>/g;
		push @txns, $txnRef;
	}

	my %TransData = (
		#ReceiptHeader    => $Data->{'SystemConfig'}{'paymentReceiptHeaderHTML'} || '',
		TotalAmount      => $tref->{'intAmount'},
		BankRef          => $tref->{'strTXN'} || '',
		PaymentID        => $tref->{'intLogID'},
		DatePurchased    => $tref->{'dateLog'},
		Transactions     => \@txns,
		#ReceiptFooter    => $Data->{'SystemConfig'}{'paymentReceiptFooterHTML'} || '',
		PaymentAssocType => $Data->{'SystemConfig'}{'paymentAssocType'} || '',
		DollarSymbol     => $Data->{'SystemConfig'}{'DollarSymbol'} || "\$",
	);
	
	{
		my $st = qq[
			SELECT DISTINCT
                E.intEntityID,
				E.strLocalName as EntityName,
                E.strEmail as EntityEmail,
                E.strPaymentNotificationAddress as PaymentNotificationAddress,
                TL.intPaymentByLevel,
				IF(TL.intSWMPaymentAuthLevel = 3, 'CLUB', 'MA') as SoldBy
			FROM
				tblTransLog as TL
				INNER JOIN tblEntity as E ON (E.intEntityID = TL.intEntityPaymentID)
			WHERE
				TL.intLogID = ?
		];
		my $query= $Data->{db}->prepare($st);
		$query->execute($intLogID);

		my $orgname = '';
                my $from_email_to_use = '';
		my $dref = $query->fetchrow_hashref();
                if (defined $dref)  {
                    my $clubEmail = '';
                    if($dref->{'SoldBy'} eq 'CLUB')	{
                        $from_email_to_use = 'club';
                        $orgname = $dref->{'EntityName'} || '';
                        $clubEmail = $dref->{'EntityEmail'} || '';
                    }
                    if ($dref->{'intPaymentByLevel'} > $Defs::LEVEL_PERSON) {
                        $to_address = $dref->{'EntityEmail'};
                    }
            

                    $TransData{'OrgName'} = $orgname || '';
                    $paymentSettings->{notification_address} =$dref->{'PaymentNotificationAddress'} || $paymentSettings->{notification_address};
			
                }
                else {
                    $st = qq[SELECT DISTINCT CONCAT(tblSelfUser.strFamilyName, ' ', tblSelfUser.strFirstName) as EntityName, tblSelfUser.strEmail FROM tblSelfUser INNER JOIN tblSelfUserAuth ON tblSelfUser.intSelfUserID = tblSelfUserAuth.intSelfUserID INNER JOIN tblTransLog ON tblTransLog.intEntityPaymentID = tblSelfUserAuth.intEntityID WHERE tblTransLog.intLogID = ? AND intPaymentByLevel = $Defs::LEVEL_PERSON];
                    $query= $Data->{db}->prepare($st);
                    $query->execute($intLogID);
                    $dref = $query->fetchrow_hashref(); 
                    $TransData{'OrgName'} = $dref->{'EntityName'} || '';
                    $to_address = $dref->{'strEmail'};
                }
		$Data->{'SystemConfig'}=getSystemConfig($Data);
	}
	my $templateWrapper = $Data->{'SystemConfig'}{'EmailNotificationWrapperTemplate'};
	my $content = runTemplate(
	      			  $Data,
	       			 \%TransData,
	                 'emails/payments/payment_receipt.templ',
   			);

	my %emailTemplateContent = (
        content => $content,
        MA_PhoneNumber => $Data->{'SystemConfig'}{'ma_phone_number'},
        MA_HelpDeskPhone => $Data->{'SystemConfig'}{'help_desk_phone_number'},
        MA_HelpDeskEmail => $Data->{'SystemConfig'}{'help_desk_email'},
        MA_Website => $Data->{'SystemConfig'}{'ma_website'},
        MA_HeaderName => $Data->{'SystemConfig'}{'EmailNotificationSysName'},
	MA_PhoneNumber => $Data->{'SystemConfig'}{'ma_phone_number'},
    );
	sendTemplateEmail(
		$Data,
		$templateWrapper,
		\%emailTemplateContent,
        $to_address,
        'Payment Received',
        $paymentSettings->{'notification_address'},
        $cc_address,
        $bcc_address,
	);
	
	
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

    my $status = 1;
    $status = 3 if ($code eq 'HOLD');
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
            tblTransactions as T
            LEFT JOIN tblTransLog as TL ON (TL.intLogID=T.intTransLogID)
        SET
            T.intStatus = ?,
            T.dtPaid = SYSDATE(),
            T.intTransLogID = $intLogID
        WHERE
            T.intTransactionID=?
            AND T.intStatus <> 1
            AND (TL.intLogID IS NULL OR TL.intStatus<>1)
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
		if ($status == 1 and $dref->{'intStatus'} == 1 and $dref->{'intTransLogID'} != $intLogID)	{
			##OOPS , ALREADY PAID, LETS MAKE A COPY OF TRANSACTION FOR RECODS
			copyTransaction($Data, $dref->{'intTXNID'}, $intLogID);
		}
		else	{
   		    $qryUpdate->execute($status, $dref->{'intTXNID'});
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


	#PaymentSplitMoneyLog::calcMoneyLog($Data, $paymentSettings, $intLogID);
	
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
      intTXNEntityID,
      intRenewed,
        intPersonRegistrationID,
        intInvoiceID,
        intSentToGateway,
        intPaymentGatewayResponded
		)
		SELECT
			1,
      'Recreated',
      curAmount,
      intQty,
      dtTransaction,
      NOW(),
      intDelivered,
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
      intTXNEntityID,
      intRenewed,
        intPersonRegistrationID,
        intInvoiceID,
        intSentToGateway,
        intPaymentGatewayResponded
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

    my ($db, $txn, $responsecode, $gatewayresponsecode, $responsetext, $intLogID, $paymentSettings, $passedChkValue, $settlement_date, $otherRef1, $otherRef2, $otherRef3, $otherRef4, $otherRef5, $authID, $text, $exportOK) = @_;

	$exportOK ||= 0;
    my %fields=();
    $intLogID ||= 0;
    $fields{txn} = $txn || '';
    $fields{gatewayresponsecode} = $gatewayresponsecode || '';
    $fields{responsecode} = $responsecode || '';
    $fields{responsetext} = $responsetext || '';
    $fields{settlement_date} = $settlement_date || '';
    $fields{otherRef1} = $otherRef1 || '';
    $fields{otherRef2} = $otherRef2 || '';
    $fields{otherRef3} = $otherRef3 || '';
    $fields{otherRef4} = $otherRef4 || '';
    $fields{otherRef5} = $otherRef5 || '';

	my $intStatus = $Defs::TXNLOG_FAILED;
	#$intStatus = $Defs::TXNLOG_SUCCESS if ($responsecode eq "00" or $responsecode eq "08" or $responsecode eq "OK" or $responsecode eq "1" or $responsecode eq 'Success');
	$intStatus = $Defs::TXNLOG_SUCCESS if ($responsecode eq "OK");
	$intStatus = $Defs::TXNLOG_HOLD if ($responsecode eq "HOLD");
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

    $m->add($paymentSettings->{'gatewaySalt'}, $chkvalue);
    $chkvalue = $m->hexdigest();

#    deQuote($db, \%fields);
	if (! $responsecode)	{
		processTransLogFailure($db, $intLogID, $gatewayresponsecode, $otherRef1, $otherRef2, $otherRef3, $otherRef4, $otherRef5, $authID, $text);
	}
	else	{
	    if ($existingResponseCode and $existingResponseCode ne $fields{responsecode} and $existingLogID)	{
			logRetry($db, $intLogID);
		}
    	$statement = qq[
            UPDATE tblTransLog
        	SET dtLog=SYSDATE(), strTXN = ?, strResponseCode = ?, strResponseText = ?, intStatus = $intStatus, dtSettlement=?, strGatewayResponseCode = ?, strOtherRef1 = ?, strOtherRef2 = ?, strOtherRef3 = ?, strOtherRef4 = ?, strOtherRef5 = ? , intExportOK = $exportOK, strAuthID=?, strText=?
        	WHERE intLogID = $intLogID
			    AND intStatus<> 1
    	];
    	$query = $db->prepare($statement) or query_error($statement);
    	$query->execute(
            $fields{txn},
            $fields{responsecode},
            $fields{responsetext},
            $fields{settlement_date},
            $fields{gatewayresponsecode},
            $fields{otherRef1},
            $fields{otherRef2},
            $fields{otherRef3},
            $fields{otherRef4},
            $fields{otherRef5},
            $authID,
            $text
        )
         or query_error($statement);
	}

    return $intLogID;
	#$intLogID=0 if ($chkvalue ne $passedChkValue);
	#return $intLogID || 0;
}

sub getVerifiedBankAccount   {

    my ($Data, $paymentType) = @_;

    ## Set up the ID & EntityType fields for assoc or club
    my $entityType = ($Data->{'clientValues'}{'clubID'} and $Data->{'clientValues'}{'clubID'} != $Defs::INVALID_ID) ? $Defs::LEVEL_CLUB : $Defs::LEVEL_NATIONAL;
    my $intID = ($entityType == $Defs::LEVEL_CLUB) ?  $Data->{'clientValues'}{'clubID'} : $Data->{'clientValues'}{'assocID'} || 0;

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
                AND BA.intEntityTypeID = IF(RF.intAssocID>0,IF(RF.intClubID > 0, $Defs::LEVEL_CLUB, $Defs::LEVEL_NATIONAL),$entityType)
        ];
    }

	my $nabFilter = '';
	my $emailJOIN = qq[INNER];
	if ($paymentType == $Defs::PAYMENT_ONLINENAB)	{
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
