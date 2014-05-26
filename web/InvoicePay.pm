#
# $Header: svn://svn/SWM/trunk/web/InvoicePay.pm 10037 2013-12-01 21:51:22Z tcourt $
#

package InvoicePay;
require Exporter;
@ISA = qw(Exporter);
@EXPORT=qw(getInvoiceTransactionsDetails createPartPayment getTXNPPTxnIDs getPartPayURL createPartPayURL);
@EXPORT_OK=qw(getInvoiceTransactionsDetails createPartPayment getTXNPPTxnIDs getPartPayURL createPartPayURL);

use strict;

use lib '.', '..', 'RegoForm';

use CGI qw(param);
use Defs;
use MD5;
#use RegoForm;
#use Products; #qw(getDefaultRegoProduct product_apply_transaction);
#use Reg_common;
#use Utils;
#use DeQuote;
#use TransLog qw(viewTransLog viewPayLaterTransLog);
#use SystemConfig;
#use Email;
#use PaymentSplitExport;
#use PaymentSplitMoneyLog;
#use ServicesContacts;
#use TemplateEmail;
#use RegoForm::RegoFormFactory;

sub createPartPayURL	{

	my ($Data, $assocID, $clubID, $txns_ref) = @_;
	$assocID || return;
	$clubID ||= 0;
	$clubID = 0 if ($clubID == $Defs::INVALID_ID);

	my $txnURL = join('|', @{$txns_ref});
	my $st = qq[
		INSERT INTO tblTXNPartPayURL
		(intRealmID, intAssocID, intClubID, strPartPayURL, dtAdded)
		VALUES (?,?,?,?,NOW())
	];
  my $qry = $Data->{'db'}->prepare($st);
  $qry->execute($Data->{'Realm'}, $assocID, $clubID, $txnURL);
	my $id = $Data->{'db'}->{mysql_insertid};
	$st = qq[
		INSERT INTO tblTXNPartPayURL_Transactions
		(intTXNURLID, intTXNID)
		VALUES (?, ?)
	];
  $qry = $Data->{'db'}->prepare($st);

	foreach my $txn (@{ $txns_ref}) {
  	$qry->execute($txn, $id);
	};
	return preparePartPayURL($id, $assocID);
}

sub preparePartPayURL	{

	my ($id, $assocID) = @_;
  return qq[$Defs::base_url/invoice_pay.cgi?aID=$assocID&t=$id];
}

sub getPartPayURL {

  my ($Data, $txnID) = @_;

  my $st = qq[
    SELECT
      TXNs.intTXNURLID,
      intClubID,
      strPartPayURL
    FROM
      tblTXNPartPayURL_Transactions as TXNs
      INNER JOIN tblTXNPartPayURL as TXNURL ON (
        TXNURL.intTXNURLID = TXNs.intTXNURLID
      )
    WHERE
      intTXNID = ?
    ORDER BY
      TXNs.intTXNURLID DESC
    LIMIT 1
  ];

  my $qry = $Data->{'db'}->prepare($st);
  $qry->execute($txnID);
  my $dref = $qry->fetchrow_hashref();

  return '' if ! $dref->{'intTXNURLID'};

		my $url = qq[$Defs::base_url/invoice_pay.cgi?aID=$Data->{'clientValues'}{'assocID'}&t=$dref->{'intTXNURLID'}];
		return preparePartPayURL($dref->{'intTXNURLID'}, $Data->{'clientValues'}{'assocID'});

}


sub getTXNPPTxnIDs	{

	my ($db, $txnPPID, $assocID) = @_;

	my $st = qq[
		SELECT
			strPartPayURL,
			intClubID
		FROM
			tblTXNPartPayURL
		WHERE
			intTXNURLID	=?
			AND intAssocID = ?
	];

  my $qry = $db->prepare($st);
  $qry->execute($txnPPID, $assocID);
	my $dref = $qry->fetchrow_hashref();
			
	return ($dref->{'strPartPayURL'}, $dref->{'intClubID'});
}
sub getInvoiceTransactionsDetails {

	my ($db, $txns_ref) = @_;
	
	my $txnIN = join(',',@{ $txns_ref }) || q{};
	return undef if $txnIN =~ /[^\d,]/;
	return undef if ! ref $txns_ref or ! $txnIN;
	my $st = qq[
		SELECT 
			DISTINCT
			T.intTransactionID,
			T.curAmount,
			P.strName as productName,
			A.intRealmID as Realm,
			A.intAssocTypeID as RealmSubType,
			A.intAssocID,
			T.intTXNClubID,
			T.intStatus,
			T.intProductID,
			T.intID,
			T.intTableType,
			A.strName as AssocName,
			C.strName as ClubName,
			CONCAT(M.strSurname, ", ", M.strFirstname) as MemberForName,
			tblTeam.strName as TeamForName,
			SUM(TXNPaidParts.curAmount) as AmountAlreadyPaid
		FROM
			tblTransactions as T
			INNER JOIN tblProducts as P ON (
				P.intProductID = T.intProductID
			)
			INNER JOIN tblAssoc as A ON (
				A.intAssocID = T.intAssocID
			)
			LEFT JOIN tblTransactions as TXNPaidParts on (
				TXNPaidParts.intParentTXNID= T.intTransactionID
				AND TXNPaidParts.intStatus=1
				AND TXNPaidParts.intProductID=T.intProductID
			)
			LEFT JOIN tblClub as C ON (
				C.intClubID=T.intTXNClubID
			)
			LEFT JOIN tblTeam ON (
				tblTeam.intTeamID=T.intID AND T.intTableType=2
			)
			LEFT JOIN tblMember as M ON (
				M.intMemberID=T.intID AND T.intTableType=1
			)
		WHERE 
			T.intTransactionID IN ($txnIN)
		GROUP BY 
			T.intTransactionID
	];
		
  my $query = $db->prepare($st);
  $query->execute();
	my @TXNS = ();
	my %TransLog=();
	my $assocID = 0;
  while (my $dref = $query->fetchrow_hashref())	{
		next if $assocID and $dref->{'intAssocID'} != $assocID;
		$assocID = $dref->{'intAssocID'} if (!$assocID);
		my %Transaction = ();
		$Transaction{'intTransactionID'} = $dref->{'intTransactionID'} || next;
		$Transaction{'intID'} = $dref->{'intID'} || next;
		$Transaction{'intProductID'} = $dref->{'intProductID'} || next;
		$Transaction{'intTableType'} = $dref->{'intTableType'} || next;
		$Transaction{'curAmount'} = $dref->{'curAmount'} || 0;
		$Transaction{'AmountAlreadyPaid'} = $dref->{'AmountAlreadyPaid'} || 0;
		$Transaction{'productName'} = $dref->{'productName'};
		$Transaction{'PurchasingForName'} = $dref->{'TeamForName'} || $dref->{'MemberForName'} || '';
		$Transaction{'intStatus'} = $dref->{'intStatus'};
		$Transaction{'AmountOwing'} = $dref->{'curAmount'} - $Transaction{'AmountAlreadyPaid'};
		push @TXNS, \%Transaction;
		$TransLog{'intAmount'} = $dref->{'intAmount'};
		$TransLog{'Realm'} = $dref->{'Realm'};
		$TransLog{'RealmSubType'} = $dref->{'RealmSubType'};
		$TransLog{'assocID'} = $dref->{'intAssocID'};
		$TransLog{'clubID'} = $dref->{'intTXNClubID'};
		$TransLog{'AssocName'} = $dref->{'AssocName'};
		$TransLog{'ClubName'} = $dref->{'ClubName'};
		$TransLog{'ok'} = 1;
	}

	return (\%TransLog, \@TXNS);
}

sub createPartPayment	{

	my ($db, $transLog_ref, $txn_ref, $params_ref)= @_;

	#print STDERR "IN HERE\n";
	return undef if (! $txn_ref->{'intTransactionID'});
	#print STDERR "STILL IN HERE\n";
	return undef if (! $params_ref->{'amount_paying'} or $params_ref->{'amount_paying'} <0);
	#print STDERR "STILL STILL IN HERE\n";

	my $st = qq[
		INSERT INTO tblTransactions
		(
			intRealmID,
			intRealmSubTypeID,
			intAssocID,
			intProductID,
			intID,
			intTableType,
			intTXNClubID,
			curAmount,
			intQty,
			intParentTXNID,
			strPayeeName,
			strPayeeNotes,
			dtTransaction
		)
		VALUES (
			?,
			?,
			?,
			?,
			?,
			?,
			?,
			?,
			?,
			?,
			?,
			?,
			NOW()
		)
	];
  my $query = $db->prepare($st);
  $query->execute(
		$transLog_ref->{'Realm'},
		$transLog_ref->{'RealmSubType'},
		$transLog_ref->{'assocID'},
		$txn_ref->{'intProductID'},
		$txn_ref->{'intID'},
		$txn_ref->{'intTableType'},
		$transLog_ref->{'clubID'},
		$params_ref->{'amount_paying'},
		1,
		$txn_ref->{'intTransactionID'},
		$params_ref->{'payee'},
		$params_ref->{'payee_notes'}
	);
	my $txnID = $query->{mysql_insertid} || 0;
	#print STDERR "NEW $txnID\n";
	return $txnID;
}


1;
