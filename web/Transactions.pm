#
# $Header: svn://svn/SWM/trunk/web/Transactions.pm 10148 2013-12-03 23:01:55Z tcourt $
#

package Transactions;

require Exporter;
@ISA =  qw(Exporter);
@EXPORT = qw(handleTransactions checkExistingProduct);
@EXPORT_OK = qw(handleTransactions checkExistingProduct);

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

# GET INFORMATION RELATING TO THIS MEMBERS TYPE (IE. COACH, PLAYER ETC)

sub handleTransactions	{
	my($action, $Data, $intTableID, $entityID)=@_;

	## TABLEID is PersonID or TeamID etc

	my $ID=param("tID") || 0;

  	my $resultHTML='';
	my $heading='';
	my $lang = $Data->{'lang'};

  if ($action =~ /_TXN_EDIT/) {
		($resultHTML,$heading) = displayTransaction($Data, $intTableID, $ID, 1);
		$action =~ s/_EDIT/_LIST/ if (defined param("HF_subbutact"));
  }
  elsif ($action =~ /_TXN_ADD/) {
		($resultHTML,$heading) = displayTransaction($Data, $intTableID, 0, 1);
		$action =~ s/_ADD/_LIST/ if (defined param("HF_subbutact"));
  }
  elsif ($action =~ /_TXN_DEL/) {
		($resultHTML,$heading) = deleteTransaction($Data, $intTableID, $ID);
	}

  elsif ($action =~ /_TXN_PAY_INV/){
		($resultHTML,$heading) = queryBlkTXN($action, $Data, $intTableID); 
		#queryBlkTXNviaInvoice($action, $Data, $intTableID) if  ($action =~ /_step2/ && param('d_strInvoiceNumber')); 
		
		 if($action =~ /_step2/){
			my $value = param('d_strInvoiceNumber') ;
			$value =~ s/^\s+//;
			if(length($value) > 0 || $value ne ''){
				$resultHTML = $value;
			}
			else { 
				$resultHTML = '';
			}
			
 		 }
		
				
		
  }

  if ($action =~ /_TXN_LIST/) {
        $entityID = getLastEntityID($Data->{'clientValues'});		
	my $cl = setClient($Data->{'clientValues'});
        my %cv = getClient($cl);  
        my $ignoreUnpaidFlag = 1; # if set show only paid and on-hold transactions
	if ($Data->{'clientValues'}{'clubID'} > 0)   {
            $cv{'clubID'} = $entityID;
            $cv{'currentLevel'} = $Defs::LEVEL_CLUB;            
        }
       elsif ($Data->{'clientValues'}{'regionID'} > 0)    {
            $cv{'regionID'} = $entityID;
            $cv{'currentLevel'} = $Defs::LEVEL_REGION;            
        }
        elsif($Data->{'clientValues'}{'personID'} > 0){
            my $ignoreUnpaidFlag = 0;
        }
       else {
            $cv{'entityID'} = $entityID; ## As its getLastEntityID
            $cv{'currentLevel'} = $Defs::LEVEL_NATIONAL;
        }
 	my $clm = setClient(\%cv);
	my $resultHTML_ = '';
	($resultHTML_,$heading) = TransLog::handleTransLogs('list', $Data, $entityID, $intTableID,$ignoreUnpaidFlag);
	$heading = $Data->{'lang'}->txt('List Transactions');
	$resultHTML_ .= qq[<br />
            <div>
		<a href="$Data->{target}?client=$clm&amp;a=WF_" class="btn-main"> ] . $lang->txt('Go to your dashboard') . qq[ </a>
		<a href="$Data->{target}?client=$clm&amp;a=TXN_PAY_INV_QUERY_INFO" class="btn-main pull-right">]. $lang->txt('Return to Invoices') . qq[ </a>
            </div>
		];
			
		$resultHTML .= $resultHTML_;

  }
  if ($action =~ /_TXN_FAILURE/) {
	my $intLogID=param("ci") || '';
		Payments::processTransLogFailure($Data->{'db'}, $intLogID);
		($resultHTML,$heading) = ($lang->txt("There was an error processing the payment.  Please try again."), $lang->txt("Error with Payment"));
  }

	if (! $heading)	{
		$heading = ($Data->{'SystemConfig'}{'txns_link_name'}) ? $Data->{'SystemConfig'}{'txns_link_name'} :  $lang->txt('Transactions');
	}
    $heading = $Data->{'lang'}->txt($heading);
	#$heading ||= $Data->{'SystemConfig'}{'txns_link_name'} || 'Transactions';

	#$heading ||= 'Transactions';
  return ($resultHTML,$heading);

}

sub checkExistingProduct    {

    my ($Data, $productID, $tableType, $ID, $entityID, $checkType) = @_;

    my $prJoin='';
    my $prWhere='';
    if ($tableType == $Defs::LEVEL_PERSON)  {
        $prJoin = qq[
           LEFT JOIN tblPersonRegistration_$Data->{Realm} as pr ON (
                pr.intPersonID = t.intID
            )
        ];
        $prWhere = qq[ AND (t.intPersonRegistrationID =0 or pr.strStatus NOT IN ('INPROGRESS'))];
    }
        

    my $st = qq[
        SELECT
            COUNT(t.intTransactionID) as CountTXNs
        FROM
            tblTransactions as t
            $prJoin
        WHERE
            intID = ?
            $prWhere
            AND t.intRealmID = ?
            AND t.intTableType = ?
            AND t.intStatus IN ($Defs::TXN_PAID, $Defs::TXN_HOLD)
            AND t.intProductID=?
    ];
    my @values=(
        $ID,
        $Data->{'Realm'},
        $tableType,
        $productID
    );

    if ($checkType eq 'THIS_ENTITY') {
        $st .= qq[ AND t.intTXNEntityID = ?];
        push @values, $entityID;
    }

    my $q= $Data->{'db'}->prepare($st);
    $q->execute(@values) or query_error($st);
    my ($count) = $q->fetchrow_array();
    return $count || 0;
}

sub deleteTransaction	{
	my ($Data, $intPersonID, $id) = @_;
	my $db=$Data->{'db'} || undef;
	my $st = qq[
		DELETE FROM tblTransactions
		WHERE intID = $intPersonID
			AND intTransactionID = $id
			AND intTableType = $Data->{'clientValues'}{'currentLevel'}
	];
	my $query = $db->prepare($st);
	$query->execute;
	my $lang = $Data->{'lang'};
  auditLog($id, $Data, 'Delete', 'Transaction');
  return ($lang->txt("Transaction has been deleted"), $lang->txt("Transaction deleted"));	
}

sub displayTransaction	{

  my($Data, $TableID, $id, $edit) = @_;

    my $lang = $Data->{'lang'};
	my $db=$Data->{'db'} || undef;
    my $client=setClient($Data->{'clientValues'}) || '';
	
	my $target=$Data->{'target'} || '';
	my $option=$edit ? ($id ? 'edit' : 'add')  :'display' ;
	my $type2=param("ty2") || '';
#($Data->{'Realm'},$Data->{'RealmSubType'})=getRealm($Data);

	my $action = 'P_TXN_EDIT';
$action = 'C_TXN_EDIT' if $Data->{'clientValues'}{'currentLevel'} == $Defs::LEVEL_CLUB;
    my $resultHTML = '';
	my $toplist='';

	my $entityID= getLastEntityID($Data->{'clientValues'}) || 0; 
    $entityID=0 if ($entityID== $Defs::INVALID_ID);
	my %DataVals=();
	my $statement=qq[
		SELECT 
      P.strName, 
      T.* , 
      TL.intPaymentType,
	IF(T.intSentToGateway=1 and T.intPaymentGatewayResponded = 0, 1, 0) as GatewayLocked,
      DATE_FORMAT(T.dtTransaction ,"%d/%m/%Y") AS dtTransaction, 
      DATE_FORMAT(T.dtStart ,"%d/%m/%Y") AS dtStart, 
      DATE_FORMAT(T.dtEnd ,"%d/%m/%Y") AS dtEnd, 
      DATE_FORMAT(T.dtPaid ,"%d/%m/%Y") AS dtPaid,
			PParent.strName as ParentProductName,
			COUNT(tChildren.intTransactionID) as NumChildren,
			SUM(tChildren.curAmount) as AmountAlreadyPaid
		FROM tblTransactions as T INNER JOIN tblProducts as P ON (P.intProductID = T.intProductID)
		LEFT JOIN tblTransLog as TL ON T.intTransLogID = TL.intLogID 
		LEFT JOIN tblTransactions as tParent ON (tParent.intTransactionID= T.intParentTXNID)
		LEFT JOIN tblProducts as PParent ON (PParent.intProductID = tParent.intProductID)
		LEFT JOIN tblTransactions as tChildren ON (tChildren.intParentTXNID = T.intTransactionID and tChildren.intStatus=1 and tChildren.intProductID=T.intProductID)
		WHERE T.intID = $TableID
			
		AND T.intTransactionID = $id
		GROUP BY T.intTransactionID
	];
	#AND T.intTableType=$Data->{'clientValues'}{'currentLevel'} 
	
	my $query = $db->prepare($statement);
	my $RecordData={};
	$query->execute;
	my $dref=$query->fetchrow_hashref();
	$dref->{'NumChildren'} ||= 0;
	my $gatewayLocked = $dref->{'GatewayLocked'} || 0;
	my $txnupdate=qq[
		UPDATE tblTransactions
			SET --VAL--
		WHERE intTransactionID=$id
	];
	
	my $txnadd=qq[
		INSERT INTO tblTransactions (intTXNEntityID, intID, intTableType, intRealmID, intRealmSubTypeID, dtTransaction, --FIELDS--)
			VALUES ($entityID, $TableID, $Data->{'clientValues'}{'currentLevel'}, $Data->{'Realm'}, $Data->{'RealmSubType'}, SYSDATE(), --VAL--)
	];

        
       

	 my $authLevel = $Data->{'clientValues'}{'authLevel'}||=$Defs::INVALID_ID;

        my $WHEREClub = '';
        if ($entityID) { # and $authLevel == $Defs::LEVEL_CLUB)        {
                $WHEREClub = qq[
                        AND ((intCreatedLevel=0 or intCreatedLevel > 3) or (intCreatedLevel = $Defs::LEVEL_CLUB and intCreatedID = $entityID))
                ];
        }

  #my $prodSellLevel = qq[ AND (intMinSellLevel <= $Data->{'clientValues'}{'authLevel'} or intMinSellLevel=0)];
  #$prodSellLevel .= qq[ AND (intSellLevel =0 or intSellLevel = $Data->{'clientValues'}{'currentLevel'})];
 my $prodSellLevel = qq[ AND (intMinAddSingleTXNLevel <> 0 and $Data->{'clientValues'}{'authLevel'}>= intMinAddSingleTXNLevel) ];

  my $st_prods=qq[ SELECT intProductID, strName FROM tblProducts WHERE intProductType NOT IN ($Defs::PROD_TYPE_MINFEE) AND intRealmID = $Data->{'Realm'} and  intInactive = 0 $WHEREClub AND intProductSubRealmID IN (0, $Data->{'RealmSubType'}) $prodSellLevel ];

  my $st_paymenttypes=qq[ SELECT intPaymentTypeID, strPaymentType FROM tblPaymentTypes WHERE intRealmID = $Data->{'Realm'}];
  my ($prods_vals,$prods_order)=getDBdrop_down_Ref($Data->{'db'},$st_prods,'');
  my ($paytypes_vals,$paytypes_order)=getDBdrop_down_Ref($Data->{'db'},$st_paymenttypes,'');

    my $pr_count = 0;
    my %PR_vals=();
    if ($Data->{'clientValues'}{'currentLevel'} == $Defs::LEVEL_PERSON and $TableID)  {
        my @statusNOTIN = ();
        if ($id)    {
        @statusNOTIN = ($Defs::PERSONREGO_STATUS_INPROGRESS);
        }
        else    {
            ## ADD SO LESS VALUES
            @statusNOTIN = ($Defs::PERSONREGO_STATUS_INPROGRESS, $Defs::PERSONREGO_STATUS_ROLLED_OVER, $Defs::PERSONREGO_STATUS_DELETED);
        }
        my %Reg = (
            statusNOTIN => \@statusNOTIN,
        );
        my $regs='';
        ($pr_count, $regs) = PersonRegistration::getRegistrationData(
            $Data,
            $TableID,
            \%Reg
        );
        if ($pr_count) {
            foreach my $reg (@{$regs})   {
                my $sport = $lang->txt($Defs::sportType{$reg->{'strSport'}}) || '';
                my $personType= $lang->txt($Defs::personType{$reg->{'strPersonType'}}) || '';
                my $entityRole= $reg->{'strEntityRoleName'};
                my $personLevel= $lang->txt($Defs::personLevel{$reg->{'strPersonLevel'}}) || '';
                my $ageLevel= $lang->txt($Defs::ageLevel{$reg->{'strAgeLevel'}}) || '';
                my $entityLocalName= $reg->{'strLocalName'};
                my $nationalPeriodName= $reg->{'strNationalPeriodName'};
                my $entityLatinName= $reg->{'strLatinName'};
                my $status= $lang->txt($Defs::personRegoStatus{$reg->{'strStatus'}}) || '';
                my $text = $entityLocalName;
                $text .=  " ($entityLatinName)" if ($entityLatinName);
                $text .= " -$personType" if ($personType);
                $text .= " -$entityRole" if ($entityRole);
                $text .= " -$sport" if ($sport);
                $text .= " -$personLevel" if ($personLevel);
                $text .= " -$ageLevel" if ($ageLevel);
                $text .= " -$nationalPeriodName " if ($nationalPeriodName);
                $text .= " -$status" if ($status);
                $PR_vals{$reg->{'intPersonRegistrationID'}} = $text;
            }
        }
    }

    my $showPR = $pr_count ? 1 : 0;
        
	my $readonly = ($Data->{'SystemConfig'}{'TXNStatusChange_MinLevel'} > $Data->{'clientValues'}{'authLevel'} or $dref->{intStatus} == $Defs::TXN_UNPAID or $dref->{intStatus} == $Defs::TXN_HOLD or ( exists $Defs::paymentTypes{$dref->{'intPaymentType'}} and $dref->{intStatus} == $Defs::TXN_PAID)) ? 1 : 0;
	
	
	#my $amount_readonly = $Data->{'clientValues'}{'authLevel'} >= $Defs::LEVEL_ASSOC ? 0: 1;
	my $amount_readonly = ! $dref->{intStatus} ? 0: 1;
	$amount_readonly = 1 if ! $id;
	my $prod_readonly= $id ? 1: 0;
    my %PaymentStatusOptions = ();
    $PaymentStatusOptions{$Defs::TXN_CANCELLED} = $Defs::TransactionStatus{$Defs::TXN_CANCELLED};
    $PaymentStatusOptions{$Defs::TXN_PAID} = $Defs::TransactionStatus{$Defs::TXN_PAID} if ($dref->{'intStatus'} == $Defs::TXN_PAID);
    $PaymentStatusOptions{$Defs::TXN_HOLD} = $Defs::TransactionStatus{$Defs::TXN_HOLD} if ($dref->{'intStatus'} == $Defs::TXN_HOLD);
    my $PaymentStatus_readonly = 0;
    $PaymentStatus_readonly =1 if ($dref->{'intStatus'} == $Defs::TXN_HOLD);
    $PaymentStatus_readonly =1 if ($dref->{'intStatus'} == $Defs::TXN_CANCELLED);
    $PaymentStatus_readonly =1 if ($Data->{'clientValues'}{'authLevel'} < $Defs::LEVEL_NATIONAL);

	my %FieldDefs = (
		TXN => {
			fields => {
				intStatus=> {
			        label => $id ? $lang->txt("Paid ?") : '',
		            value => $dref->{'intStatus'},
                	type  => 'lookup',
                	options=> \%PaymentStatusOptions,
					readonly=>$PaymentStatus_readonly,
            	},
				intDelivered=> {
			        	label => $lang->txt("Delivered"),
		                	value => $dref->{'intDelivered'},
                			type  => 'checkbox',
                			displaylookup => {0=>'Undelivered', 1=>'Delivered'},
            			},
				dtPaid=> {
					label => $lang->txt('Date Paid'),
					type => 'text',
					readonly=>1,
					size => 30,
					value => $dref->{'dtPaid'},
				},
				PartPayment=> {
					label => $dref->{'intParentTXNID'} ? $lang->txt('Part Payment for') : '',
					type => 'text',
					readonly=>1,
					size => 30,
					value => Payments::TXNtoTXNNumber($dref->{intParentTXNID}) . qq[ - $dref->{'ParentProductName'}],
				},
				intQty=> {
					label => $lang->txt('Quantity'),
					type => 'text',
					size => 8,
					value => $dref->{'intQty'} || 1,
					readonly=>$prod_readonly,
				},
				curAmount=> {
					label => $id ? $lang->txt('Amount Due') : '',
					type => 'text',
					size => 8,
					value => $Data->{'l10n'}{'currency'}->format($dref->{'curAmount'}),
					readonly => 1,
					#readonly=>($amount_readonly or $gatewayLocked),
				},
				AmountAlreadyPaid=> {
					label => $dref->{'AmountAlreadyPaid'} ? $lang->txt('Amount Already Paid via Part Payments') : '',
					type => 'text',
					size => 8,
					value => $dref->{'AmountAlreadyPaid'},
					readonly=>1,
				},

        ## TC
        dtStart => {
          label => $Data->{'SystemConfig'}{'AllowTxnStartDateEdit'} ? $lang->txt('Start Date') : '',
          type => 'date',
          value => $dref->{'dtStart'},
					noadd => 1,
        },
       dtEnd => {
          label => $Data->{'SystemConfig'}{'AllowTxnEndDateEdit'} ? $lang->txt('End Date') : '',
          type => 'date',
          value => $dref->{'dtEnd'},
					noadd => 1,
        },
        ## TC
				strNotes=> {
					label => $lang->txt('Notes'),
					type => 'textarea',
					value => $dref->{'strNotes'},
					rows => 5,
		                	cols=> 45,
				},
				intPersonRegistrationID=> {
          				label => $showPR ? $lang->txt('Registration') : '',
          				type => 'lookup',
          				compulsory => $showPR ? 1 : '',
		          		value => $dref->{'intPersonRegistrationID'},
          				options =>  \%PR_vals,
		          		firstoption => ['',$lang->txt('Select Registration')],
					readonly=>$prod_readonly,
        			},
				intProductID => {
          				label => $lang->txt('Product'),
          				type => 'lookup',
          				compulsory => 1,
		          		value => $dref->{'intProductID'},
          				options =>  $prods_vals,
		          		firstoption => ['',$lang->txt('Select Product')],
					readonly=>$prod_readonly,
        			},
		},
		order => [qw(intProductID intPersonRegistrationID curAmount AmountAlreadyPaid dtPaid intQty intStatus intDelivered strNotes dtStart dtEnd PartPayment)],
			options => {
				labelsuffix => ':',
				hideblank => 1,
				target => $Data->{'target'},
				formname => 'txn_form',
				submitlabel => $lang->txt('Update Transaction'),
				buttonloc => 'bottom',
				updateSQL => $txnupdate,
				addSQL => $txnadd,
				afteraddFunction => \&checkTXNPricing,
				afteraddParams => [$Data,$Data->{'db'}, $TableID],
				beforeaddFunction => \&preTXNAddUpdate,
				beforeupdateFunction => \&preTXNAddUpdate,
				beforeaddParams => [$option,$Data,$Data->{'db'}, $client, $TableID, 0],
				beforeupdateParams => [$option,$Data,$Data->{'db'}, $client, $TableID, $id],

        auditFunction=> \&auditLog,
        auditAddParams => [
          $Data,
          'Add',
          'Transactions'
        ],
        auditEditParams => [
          $id,
          $Data,
          'Update',
          'Transactions'
        ],

				stopAfterAction => 1,
				updateOKtext => qq[
					<div class="OKmsg">] . $lang->txt('Record updated successfully') . qq[</div> <br>
					<!--<a href="$Data->{'target'}?client=$client&amp;a=P_TXN_LIST">].$lang->txt('Return to Transaction').qq[</a>-->
				], # M_TXN_LIST
				addOKtext => qq[
					<div class="OKmsg">]. $lang->txt('Record added successfully') . qq[</div> <br>
					<!--<a href="$Data->{'target'}?client=$client&amp;a=P_TXN_LIST">].$lang->txt('Return to Transaction').qq[</a>-->
				],
			},
			sections => [ ['main',$lang->txt('Details')], ],
			carryfields =>  {
				client => $client,
				a=> $action,
				tID => $id,
			},
		},
	);
	($resultHTML, undef )=handleHTMLForm($FieldDefs{'TXN'}, undef, $option, '',$db);
	my $url = getPartPayURL($Data, $id) if ($dref->{'NumChildren'});
	if ($url)	{
		$resultHTML.= qq[<a href=$url target="invoice_pay">].$lang->txt('Click to View Part Payment form').qq[</a><br><br>];
	}
	if ($gatewayLocked)	{
		$resultHTML = qq[<p class="warningmsg">]. $lang->txt("Record locked until Payment Gateway responds") . qq[</p>] . $resultHTML;
	}
	$resultHTML .= showTransactionChildren($Data, $id) if ($dref->{'NumChildren'});

	if($option eq 'display')	{
		$resultHTML .=allowedAction($Data, 'txn_e') ?qq[ <a href="$target?a=$action&amp;tID=$dref->{'intTransactionID'}&amp;client=$client">].$lang->txt('Edit Details').qq[</a> ] : '';
	}

		$resultHTML=qq[
			<div>].$lang->txt('No Transaction were found.').qq[</div>
		] if !ref $dref;

		$resultHTML=qq[
				<div class="alphaNav">$toplist</div>
				<div>
					$resultHTML
				</div>
		];
		my $heading = $Data->{'SystemConfig'}{'txns_link_name'}  || 'Transactions';
		return ($resultHTML,$Data->{'lang'}->txt($heading));
}

sub showTransactionChildren	{

	my ($Data, $id) = @_;

	my $st = qq[
		SELECT 
      T.* , 
      DATE_FORMAT(T.dtTransaction ,"%d/%m/%Y") AS dtTransaction, 
      DATE_FORMAT(T.dtStart ,"%d/%m/%Y") AS dtStart, 
      DATE_FORMAT(T.dtEnd ,"%d/%m/%Y") AS dtEnd, 
      DATE_FORMAT(T.dtPaid ,"%d/%m/%Y") AS dtPaid
		FROM 
			tblTransactions as T
			INNER JOIN tblProducts as P ON (
				P.intProductID = T.intProductID
			)
		WHERE 
			T.intParentTXNID = ?
			AND T.intTXNEntityID= ?
			AND T.intParentTXNID > 0
			AND T.intStatus=1
			AND P.intProductType<>2
	];

	my $qry = $Data->{'db'}->prepare($st);
    my $entityID = getLastEntityID($Data->{'clientValues'}) || 0;
	$qry->execute($id, $entityID);
	my $count=0;
	my $body = qq[
		<div class="pageHeading">Part Payment records</div>
		<p>Below is a list of the successful Part Payments for the selected Transaction.</p>
		<table class="listTable">
			<tr>
				<th>Transaction Number</th>
				<th>Payee</th>
				<th>Amount</th>
				<th>Payment Ref ID</th>
				<th>Paid Date</th>
				<th>Payee Notes</th>
			</tr>
	];
	while (my $dref=$qry->fetchrow_hashref())	{
		$count++;
		$body .= qq[
			<tr>
				<td>]. Payments::TXNtoTXNNumber($dref->{'intTransactionID'}) . qq[</td>
				<td>$dref->{'strPayeeName'}</td>
				<td>\$$dref->{'curAmount'}</td>
				<td>$dref->{'intTransLogID'}</td>
				<td>$dref->{'dtPaid'}</td>
				<td>$dref->{'strPayeeNotes'}</td>
			</tr>
		];
	};

	$body .= qq[</table>];

	$body = '' if ! $count;

	return $body;
}

sub checkTXNPricing	{
	my($id,$params, $Data,$db, $personID)=@_;
        $personID||=0;

    my $entityID = getLastEntityID($Data->{'clientValues'}) || 0;
	my $statement = qq[
        SELECT PP.curAmount, P.curDefaultAmount, T.intQty
	FROM tblTransactions as T
	        LEFT JOIN tblProducts as P ON (P.intProductID = T.intProductID)
			LEFT JOIN tblProductPricing as PP ON (PP.intProductID = P.intProductID AND PP.intRealmID = $Data->{'Realm'} AND ((PP.intID = T.intTXNEntityID AND intLevel >= $Defs::LEVEL_CLUB)
];          
    $statement .= qq[ OR (PP.intID = $entityID AND intLevel>=$Defs::LEVEL_CLUB)] if ($entityID and $entityID != $Defs::INVALID_ID);
    $statement .= qq[))
	WHERE T.intTransactionID = $id
    ];
    my $query = $db->prepare($statement) or query_error($statement);
    $query->execute or query_error($statement);

	my ($PPamount, $defaultAmount, $qty)= $query->fetchrow_array();
	$PPamount ||= 0;
        $defaultAmount ||=0;

    my $amount = $PPamount || $defaultAmount || 0;
	my $totalamount = $amount * $qty;

	
	#Generate invoice number 
		my $stt = qq[INSERT INTO tblInvoice (tTimeStamp, intRealmID) VALUES (NOW(), $Data->{'Realm'})];
		my $qryy=$Data->{'db'}->prepare($stt); 
 		$qryy->execute();
		my $invoiceID =  $qryy->{mysql_insertid} || 0;	
		#my $invoiceNumber = Payments::TXNtoInvoiceNum($invoiceID); 
		my $invoiceNumber = Payments::TXNtoTXNNumber($invoiceID);
		$stt = qq[UPDATE tblInvoice SET strInvoiceNumber = ? WHERE intInvoiceID = ?];		
		$qryy=$Data->{'db'}->prepare($stt); 
		$qryy->execute($invoiceNumber,$invoiceID); 


	$statement = qq[
		UPDATE tblTransactions
		SET curAmount = $totalamount, curPerItem=$amount, intInvoiceID=$invoiceID
		WHERE intTransactionID = $id
	];

    $query = $db->prepare($statement) or query_error($statement);
    $query->execute or query_error($statement);
	
}

sub preTXNAddUpdate	{

	my($params, $action, $Data, $db, $client, $personID, $transID)=@_;

	$personID ||= 0;
	$transID ||=0;
	my $prodID = $params->{'d_intProductID'} || 0;
	
	my $st = qq[
		SELECT T.intTransactionID
		FROM tblTransactions as T INNER JOIN tblProducts as P ON (T.intProductID = P.intProductID)
		WHERE T.intID = $personID
			AND T.intTableType=$Defs::LEVEL_PERSON
			AND T.intProductID = $prodID
			AND P.intAssocUnique = 1
	];
	$st .= qq[ AND T.intTransactionID <> $transID] if $transID;
	$st .= qq[
		LIMIT 1
	];
    	my $query = $db->prepare($st) or query_error($st);
    	$query->execute or query_error($st);
    	my ($intExistingTransactionID) = $query->fetchrow_array();
	$intExistingTransactionID ||= 0;

	my $error_text = qq[
		<div class="warningmsg">You are only allowed to have one instance of the selected product</div>
		<a href="$Data->{'target'}?client=$client&amp;a=P_TXN_LIST">Return to Transaction</a>
	];
	return (0,$error_text) if $intExistingTransactionID;
	return (1,'');
}

sub queryBlkTXN {
	my ($action, $Data, $intTableID) = @_;
    my $client = setClient($Data->{'clientValues'}) || '';
	
	my %FormElements = ( 
		 fields=>  {				
			strInvoiceNumber => {
				label	=> 'Invoice Number',
				value	=> '',
				type	=> 'text',
				size  => '30',
       			maxsize => '50',
			}
		}, #end of fields	
		order => [qw(
			strInvoiceNumber
		)],  #end of order 
		options => {
			labelsuffix => ':',
		    hideblank => 1,
      		target => $Data->{'target'},
      		formname => 'n_form',
      		submitlabel => $Data->{'lang'}->txt('Continue'),
			 NoHTML => 1,
		}, #end of options
		carryfields =>  {
    		client => $client,
      		a=> $action."_step2",
    	},
	);
 
	#my $formcontent = runTemplate($Data, \%FormElements, 'payment/bulkinvoicelisting.templ'); 
	my $content;
	my $title = 'Pay Invoice';
	($content, undef )=handleHTMLForm(\%FormElements, undef, 'add', '', $Data->{'db'});

	return ($content,$title);

}
  





1;
