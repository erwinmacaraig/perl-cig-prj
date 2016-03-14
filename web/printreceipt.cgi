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
use L10n::DateFormat;
use L10n::CurrencyFormat;
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
	my $currencyFormat = new L10n::CurrencyFormat(\%Data);
	my $dateFormat = new L10n::DateFormat(\%Data);

	$Data{'l10n'}{'currency'} = $currencyFormat;
	$Data{'l10n'}{'date'} = $dateFormat;

	my %receiptData= ();
	my %ContentData = ();
	my %htmlReceiptBody = ();
    my $locale = $Data{'lang'}->getLocale();
    
    my $stWHERE = '';
    my $stJOIN= '';
    if ($Data{'clientValues'}{'authLevel'} == $Defs::LEVEL_PERSON)  {
        $stWHERE = qq[ AND T.intID = $Data{'clientValues'}{'personID'}];
    }
    if ($Data{'clientValues'}{'authLevel'} >= $Defs::LEVEL_CLUB)  {
        ## Lets see if this level has access to the other people
        my $authID = getID($Data{'clientValues'}, $Data{'clientValues'}{'authLevel'});
        $stJOIN = qq[ 
            LEFT JOIN tblTempEntityStructure as TES ON (
                TES.intChildID = PR.intEntityID 
                AND TES.intParentLevel = $Data{'clientValues'}{'authLevel'} 
            ) 
        ];
        $stWHERE = qq[ AND (
            TES.intParentID = $authID
            OR PRE.intEntityID = $authID
        )
        ];
    }
    
	if($txlogIDs)	{
		for my $intID (@intIDs){			
			my $st =qq[
				SELECT 
                    DISTINCT
                intTransLogID,
                 T.intTransactionID,
                 COALESCE (LT_P.strString1,P.strName) as strName,
                 P.strGroup,
                 T.intQty,
                 T.curAmount,
                 T.intTableType,
                 I.strInvoiceNumber,
                 T.intStatus,
                 P.curPriceTax,
                 P.dblTaxRate,
                 TL.intPaymentType,
				IF(T.intTableType = $Defs::LEVEL_CLUB, E.strLocalName, CONCAT(strLocalFirstname, ' ', strLocalSurname)) as Name,
				TL.dtLog as dtLog_FMT 
			FROM tblTransactions as T
			INNER JOIN tblTransLog as TL ON TL.intLogID = T.intTransLogID
				LEFT JOIN tblInvoice I on I.intInvoiceID = T.intInvoiceID
				LEFT JOIN tblPerson as M ON (M.intPersonID = T.intID and T.intTableType=$Defs::LEVEL_PERSON)
				LEFT JOIN tblProducts as P ON (P.intProductID = T.intProductID)
				LEFT JOIN tblEntity as E ON (E.intEntityID = T.intID and T.intTableType=$Defs::LEVEL_CLUB)
                LEFT JOIN tblPersonRegistration_1 as PR ON (PR.intPersonRegistrationID = T.intPersonRegistrationID)
				LEFT JOIN tblEntity as PRE ON (PRE.intEntityID = PR.intEntityID)
                LEFT JOIN tblLocalTranslations AS LT_P ON (
                    LT_P.strType = 'PRODUCT'
                    AND LT_P.intID = P.intProductID
                    AND LT_P.strLocale = '$locale'
                )
                $stJOIN
			WHERE intTransLogID IN (?) 
			AND T.intRealmID = ? AND T.intID = $intID	
                $stWHERE
			];
			
			my $q= $db->prepare($st);
			$q->execute(
				$txlogIDs,			
				$Data{'Realm'},		
			);
		   	while (my $dref = $q->fetchrow_hashref()){
				$dref->{'paymentType'} = $Defs::paymentTypes{$dref->{intPaymentType}};
				$dref->{'curAmountFormatted'} =  $currencyFormat->format($dref->{'curAmount'});
				$dref->{'curPriceTaxFormatted'} =  $currencyFormat->format($dref->{'curPriceTax'});
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

