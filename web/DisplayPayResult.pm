package DisplayPayResult;
require Exporter;
@ISA = qw(Exporter);
@EXPORT=qw(displayPayResult displayTXNToPay);
@EXPORT_OK=qw(displayPayResult displayTXNToPay);

use lib '.', '..', "comp", 'RegoForm', "dashboard", "RegoFormBuilder",'PaymentSplit', "user";

use strict;
use DBI;

use Lang;
use Utils;
use Payments;
use SystemConfig;
use ConfigOptions;
use Reg_common;
use Products;
use PageMain;
use CGI qw(param unescape escape);

use ExternalGateway;
use Gateway_Common;
use TTTemplate;
use Data::Dumper;


sub displayPayResult    {

    my ($Data, $logID) = @_;

    my $st = qq[
        SELECT 
            intStatus
        FROM
            tblTransLog
        WHERE
            intLogID = ?
    ];
     my $qry= $Data->{'db'}->prepare($st) or query_error($st);
     $qry->execute($logID) or query_error($st);
    my $status = $qry->fetchrow_array() || 0;

    my $template_ref = getPaymentTemplate($Data,0);
    my $templateBody = $template_ref->{'strFailureTemplate'} || 'payment_failure.templ';
    if ($status == 1)   {
        $templateBody = $template_ref->{'strSuccessTemplate'} || 'payment_success.templ';
    }
    my $trans_ref = gatewayTransLog($Data, $logID);
    $trans_ref->{'headerImage'}= $template_ref->{'strHeaderHTML'} || '';

    my ($html_head, $page_header, $page_navigator, $paypal, $powered) = getPageCustomization($Data);
    $trans_ref->{'title'} = '';
    $trans_ref->{'head'} = $html_head;
    $trans_ref->{'page_begin'} = qq[
        <div id="global-nav-wrap">
        $page_navigator
        </div>
    ];
    my $body = '';
    $trans_ref->{'page_header'} = $page_header;
    $trans_ref->{'page_content'} = '';
    $trans_ref->{'page_footer'} = qq [
        $paypal
        $powered
    ];
    $trans_ref->{'page_end'} = '';

    my $result = runTemplate(
            undef,
            $trans_ref, ,
            'payment/'.$templateBody
          );
    $templateBody= $result if($result);
    return $templateBody;
}

###########

sub displayTXNToPay {

    my ($Data, $trans, $paymentSettings) = @_;
    my @transactions= split /:/, $trans;

    my $external = 0;
    my $lang = $Data->{'lang'};
    my ($count, $dollars, $cents) = getCheckoutAmount($Data, \@transactions);
    my $amount = "$dollars.$cents";
    my $invoiceList ='';
     my $allowPayment = $paymentSettings->{'allowPayment'} || 0;
    $allowPayment=0 if (! $external and $Data->{'clientValues'}{'authLevel'} < $Defs::LEVEL_CLUB);
    my $dollarSymbol = $Data->{'SystemConfig'}{'DollarSymbol'} || "\$";
    my $client=setClient($Data->{'clientValues'}) || '';

    #List the products this person is purchasing and their amounts
    my $assocID=$Data->{'clientValues'}{'assocID'} || 0;
    my $realmID=$Data->{'Realm'} || 0;
    my $product_confirmation='';
    my $txn_list = join (',',@transactions);
    my @templateTXNs = ();
    for my $transid (@transactions)	{
        my $dref = getTXNDetails($Data, $transid,1);
        next if ! $dref->{intTransactionID};
        $count++;
        my $lamount=$dref->{'curAmount'} || 0;
        $invoiceList .= $invoiceList ? qq[,$dref->{'InvoiceNum'}] : $dref->{'InvoiceNum'};
        my %TXN = ();
        $TXN{'InvoiceNum'} = $dref->{'InvoiceNum'};
        $TXN{'ProductName'} = $dref->{'ProductName'};
        $TXN{'Name'} = $dref->{'Name'};
        $TXN{'LineAmount'} = $lamount;
        push @templateTXNs, \%TXN;
    }
    my $camount=$amount||0;
    my %PageData = (
        target => $Data->{'target'},
        Lang => $Data->{'lang'},
        client=>$client,
        TXNs => \@templateTXNs,
        dollarSymbol => $dollarSymbol,
        camount => $camount,
    );

    my $body = runTemplate($Data, \%PageData, 'payment/txn_list.templ') || '';

	return $body;

}
1;
