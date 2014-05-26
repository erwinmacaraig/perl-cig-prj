#
# $Header: svn://svn/SWM/trunk/web/Gateway_Common.pm 10598 2014-02-05 00:19:12Z dhanslow $
#

package Gateway_Common;
require Exporter;
@ISA = qw(Exporter);
@EXPORT=qw(gatewayTransactions gatewayTransLog getPaymentTemplate);
@EXPORT_OK=qw(gatewayTransactions gatewayTransLog getPaymentTemplate);

use strict;
use Utils;
use MD5;
use CGI qw(param);
use Payments;

use HTTP::Request::Common qw(POST);
use LWP::UserAgent;
use MD5;
use CGI qw(param unescape escape);


sub gatewayTransactions	{
	my ($Data, $logID) = @_;
	my $st = qq[
                SELECT T.intRealmSubTypeID, T.intRealmID, A.intPaymentConfigID, TL.intPaymentConfigUsedID, TL.intAmount as Amount, TL.intStatus, P.strName as ProductName, P.strGroup as ProductGroup, T.curAmount as TxnAmount, intQty, T.intTransactionID, A.strName as AssocName, strGSTText, strRealmName, T.curPerItem, T.intStatus as TXNStatus, T.intAssocID, intClubPaymentID, intAssocPaymentID, PC.strCurrency, RF.intAssocID as intAssocFormOwner, RF.intClubID as ClubFormOwner, TL.intRegoFormID, intSWMPaymentAuthLevel
                        FROM tblTransactions as T
                        INNER JOIN tblTXNLogs as TLogs ON (T.intTransactionID = TLogs.intTXNID and TLogs.intTLogID = $logID)
                        INNER JOIN tblAssoc as A ON (A.intAssocID = T.intAssocID)
                        INNER JOIN tblTransLog as TL ON (TL.intLogID = TLogs.intTLogID)
                        INNER JOIN tblProducts as P ON (P.intProductID = T.intProductID)
                        INNER JOIN tblRealms as R ON (R.intRealmID=T.intRealmID)
						LEFT JOIN tblPaymentConfig as PC ON (PC.intPaymentConfigID = TL.intPaymentConfigUsedID)
						LEFT JOIN tblRegoForm as RF ON (RF.intRegoFormID=TL.intRegoFormID)
        ];

        my $qry= $Data->{'db'}->prepare($st) or query_error($st);
#print STDERR $st;
        $qry->execute or query_error($st);
        my $count=0;
        my %Transactions = ();
        my %Order= ();
		my $totalAmount=0;
        while (my $dref=$qry->fetchrow_hashref())       {
                $Data->{'RealmSubType'} = $dref->{intRealmSubTypeID} || 0;
                $Data->{'Realm'} = $dref->{intRealmID} || 0;
                $Data->{'SystemConfig'}{'PaymentConfigID'} = $dref->{intPaymentConfigID} || 0;
                $Data->{'SystemConfig'}{'PaymentConfigUsedID'} = $dref->{intPaymentConfigUsedID} || 0;
		$Order{'TransLogStatus'}=$dref->{'intStatus'} || 0;
                $Order{'TotalAmount'} = $dref->{'Amount'};
                $Order{'Status'} = $dref->{'intStatus'};
                $Order{'TLStatus'} = $dref->{'intStatus'};
                $Order{'AssocID'} = $dref->{'intAssocID'};
                $Order{'Currency'} = $dref->{'strCurrency'};
		next if ($dref->{intStatus} >= 1);
                next if ($dref->{TXNStatus} == 1);
                $Transactions{$count}{'name'} = $dref->{'ProductName'} || next;
                $Transactions{$count}{'number'} =  Payments::TXNtoInvoiceNum($dref->{intTransactionID}); #$dref->{'intTransactionID'};
                $Transactions{$count}{'desc'} = $dref->{'ProductGroup'} . qq[ $dref->{strGSTText}];
                $Transactions{$count}{'amount'} = $dref->{'TxnAmount'};
                $Transactions{$count}{'amountPerItem'} = $dref->{'curPerItem'};
                $Transactions{$count}{'qty'} = $dref->{'intQty'};
		$totalAmount = $totalAmount + $dref->{'TxnAmount'};
                $Order{'AssocName'} = qq[$dref->{'AssocName'} ];
                $Order{'ClubID'} = $dref->{'intClubPaymentID'};
                $Order{'Realm'} = $dref->{'strRealmName'};
                $Order{'ClubFormOwner'} = 0;
				#Lets get the ID of the Club in RegoForm to see the form owner
                if ($dref->{'intRegoFormID'} and $dref->{'intRegoFormID'} >0  and $dref->{'intAssocFormOwner'}>0)	{
                	$Order{'ClubFormOwner'} = $dref->{'ClubFormOwner'}; 
				}
                else	{
				##clientvalues added in (very suspect)... bit scared it may influence other areas
					$Order{'ClubFormOwner'} = $Order{'ClubID'} if ($Data->{'clientValues'}{'authLevel'} == $Defs::LEVEL_CLUB or $dref->{'intSWMPaymentAuthLevel'} == $Defs::LEVEL_CLUB or $Data->{'clientValues'}{'clubID'});
				}
                $count ++;
        }
		$Order{'Status'}=-1 if ($Order{'TotalAmount'} != $totalAmount);
#print STDERR "LOGGGGG:$logID $Order{'ClubFormOwner'} | $Data->{'clientValues'}{'authLevel'}\n";
	return (\%Order, \%Transactions);

}

sub gatewayTransLog	{

	my ($Data, $logID) = @_;

	my %Payment=();
	my $st = qq[
		SELECT
			TL.*,
			A.strName as AssocName,
			C.strName as ClubName
		FROM
			tblTransLog as TL
			LEFT JOIN tblAssoc as A ON (A.intAssocID = TL.intAssocPaymentID)
			LEFT JOIN tblClub as C ON (C.intClubID = intClubPaymentID)
		WHERE 
			TL.intLogID=?
	];
  	my $qry= $Data->{'db'}->prepare($st) or query_error($st);
  	$qry->execute($logID) or query_error($st);

  	my $ref = $qry->fetchrow_hashref();

	$st = qq[
		SELECT
			T.* ,
			P.strName as ProductName,
			M.strFirstname,
			M.strSurname,
			Team.strName as TeamName
		FROM
			tblTransactions as T
			INNER JOIN tblProducts as P ON (P.intProductID = T.intProductID)
			LEFT JOIN tblTeam as Team ON (
				Team.intTeamID = T.intID
				AND T.intTableType=2
			)
			LEFT JOIN tblMember as M ON (
				M.intMemberID= T.intID
				AND T.intTableType=1
			)
		WHERE
			intTransLogID= ?
	];
  	my $qry_trans= $Data->{'db'}->prepare($st) or query_error($st);
  	$qry_trans->execute($logID) or query_error($st);
	my @TXNs=();

	while (my $tref = $qry_trans->fetchrow_hashref())	{
		$tref->{'InvoiceNum'} = Payments::TXNtoInvoiceNum($tref->{intTransactionID});
         $tref->{'QtyAmount'} = $tref->{'intQty'};
		if ($tref->{'intQty'}>1)	{
         $tref->{'QtyAmount'} = qq[$tref->{'intQty'} @ \$$tref->{'curPerItem'}];
		}
		$tref->{'MemberTeamFor'} = qq[$tref->{'strFirstname'} $tref->{'strSurname'}];
		if ($tref->{'intTableType'} == 2)	{
			$tref->{'MemberTeamFor'} = $tref->{'TeamName'}
		}

		push @TXNs, $tref;
	}
	$ref->{'TXNs'} = \@TXNs;

	return $ref;

}
sub getPaymentTemplate  {

  my ($Data, $assocID, $templateType) = @_;

  $assocID ||= 0;
  my $realmID = $Data->{'Realm'} || 0;
  my $realmSubTypeID = $Data->{'RealmSubType'} || 0;

  my $st = qq[
    SELECT
		*
    FROM
      tblPayment_Templates
    WHERE
      intRealmID IN (0, $realmID)
      AND intRealmSubTypeID IN (0, $realmSubTypeID)
      AND intAssocID IN (0, $assocID)
    ORDER BY
      intAssocID DESC, intRealmSubTypeID DESC, intRealmID DESC
    LIMIT 1
  ];
  my $qry= $Data->{'db'}->prepare($st) or query_error($st);
  $qry->execute or query_error($st);

  my $dref = $qry->fetchrow_hashref();

  return $dref;

}

1;

