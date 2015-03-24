#! /usr/bin/perl -w

#
# $Header: svn://svn/SWM/trunk/web/printreceipt.cgi 10128 2013-12-03 04:03:40Z tcourt $
#

## LAST EDITED -> 18/7/2001 ##

use strict;
use CGI qw(param escape unescape);

use lib '.','..',"comp",'PaymentSplit','RegoFormBuilder';

use Reg_common;
use PageMain;
use Defs;
use Utils;
use SystemConfig;
use ConfigOptions;
use Lang;
use TTTemplate;
use Payments;
use Data::Dumper;
main();

sub main	{
	# GET INFO FROM URL
	my $action = param('a') || '';
	my $client = param('client') || '';
	my $txlogIDs= param('ids') || '';
	my $personID = param('pID') || '';

	my @intIDs = split(/,/,$personID);
	my %clientValues = getClient($client);
	my %Data=();
	my $target='printreceipt.cgi';
	$Data{'target'}=$target;
	$Data{'clientValues'} = \%clientValues;
	# AUTHENTICATE
        my $db=connectDB();
$Data{'db'}=$db;

  ($Data{'Realm'}, $Data{'RealmSubType'})=getRealm(\%Data);
  
 
	$Data{'SystemConfig'}=getSystemConfig(\%Data);
    my $lang   = Lang->get_handle('', $Data{'SystemConfig'}) || die "Can't get a language handle!";
  $Data{'lang'}=$lang;
	my $assocID=getAssocID(\%clientValues) || '';
	my $DataAccess_ref=getDataAccess(\%Data);
  $Data{'Permissions'}=GetPermissions(
    \%Data,
    $Data{'clientValues'}{'currentLevel'},
    getID($Data{'clientValues'}, $Data{'clientValues'}{'currentLevel'}),
    $Data{'Realm'},
    $Data{'RealmSubType'},
    $Data{'clientValues'}{'authLevel'},
    0,
  );

	my $pageHeading= '';
	my $resultHTML = '';
	my $bodyHTML = '';
	my $ID=getID(\%clientValues);
	$Data{'client'}=$client;
	
	my %receiptData= ();
	my %ContentData = ();
	my %htmlReceiptBody = ();
	if($txlogIDs)	{
		for my $intID (@intIDs){			
			my $st =qq[
				SELECT intTransLogID, T.intTransactionID, P.strName, P.strGroup, T.intQty, T.curAmount, T.intTableType, I.strInvoiceNumber, T.intStatus, P.curPriceTax, P.dblTaxRate, TL.intPaymentType,
				IF(T.intTableType = $Defs::LEVEL_CLUB, E.strLocalName, CONCAT(strLocalFirstname,' ',strLocalSurname)) as Name,
				DATE_FORMAT(TL.dtLog,'%d/%m/%Y %h:%i') as dtLog_FMT 
			FROM tblTransactions as T
			INNER JOIN tblTransLog as TL ON TL.intLogID = T.intTransLogID
				LEFT JOIN tblInvoice I on I.intInvoiceID = T.intInvoiceID
				LEFT JOIN tblPerson as M ON (M.intPersonID = T.intID and T.intTableType=$Defs::LEVEL_PERSON)
				LEFT JOIN tblProducts as P ON (P.intProductID = T.intProductID)
				LEFT JOIN tblEntity as E ON (E.intEntityID = T.intID and T.intTableType=$Defs::LEVEL_CLUB)
			WHERE intTransLogID IN (?) 
			AND T.intRealmID = ? AND T.intID = $intID	
			];
			# AND T.intID = ?  $personID,
			#AND T.intRealmID = ? AND T.intID = $personID
			#open FH, ">>dumpfile.txt";
			#print FH "\n \$st = $st\n   \n$txlogIDs";
			my $q= $db->prepare($st);
			$q->execute(
				$txlogIDs,			
				$Data{'Realm'},		
			);
		   	while (my $dref = $q->fetchrow_hashref()){
				$dref->{'paymentType'} = $Defs::paymentTypes{$dref->{intPaymentType}};
				push @{$ContentData{'receiptdetails'}}, $dref;
			}
			
			
			$bodyHTML .= runTemplate(
				\%Data, 
				\%ContentData,
		        "txn_receipt/receiptbody.templ",
			);			
			%ContentData = ();			
		} # end of for loop
		my $filename = $Data{'SystemConfig'}{'receiptFilename'} || 'standardreceipt';
		$htmlReceiptBody{'body'} = $bodyHTML;
		$resultHTML = runTemplate(
				\%Data, 
				\%htmlReceiptBody,
		        "txn_receipt/$filename.templ"
		);	
	}
	else	{
		$resultHTML = 'Invalid Transactions';
	}
	



	my $title=$lang->txt($Defs::page_title || 'Receipt');
	print "Content-type: text/html\n\n";
	print $resultHTML;

	disconnectDB($db);

}

