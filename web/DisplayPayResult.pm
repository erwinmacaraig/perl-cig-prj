package DisplayPayResult;
require Exporter;
@ISA = qw(Exporter);
@EXPORT=qw(displayPayResult);
@EXPORT_OK=qw(displayPayResult);

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

use NABGateway;
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
