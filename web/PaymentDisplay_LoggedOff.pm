package PaymentDisplay_LoggedOff;
require Exporter;
@ISA = qw(Exporter);
@EXPORT=@EXPORT_OK=qw(paymentDisplay_LoggedOff);

use lib '.', '..', "comp", 'RegoForm', "dashboard", "RegoFormBuilder",'PaymentSplit', "user" ;

use strict;
use DBI;

use Lang;
use Utils;
use Payments;
use SystemConfig;
use ConfigOptions;
use Reg_common;
use PageMain;
use CGI qw(param unescape escape);

use TTTemplate;

use Data::Dumper;

sub paymentDisplay_LoggedOff    {

    my ($Data, $logID) = @_;

    #PageMain::pageMain("TITLE", '', $paybody, \%clientValues, $client, $Data );
    my $title = $Data->{'lang'}->txt("Payment Summary");
    my ($payStatus, $paybody) = Payments::displayPaymentResult($Data, $Data->{'ptry'}, 0,'', 10);
    #PageMain::pageMain($title, '', $paybody, undef, '', $Data );
    PageMain::pageForm($title, $paybody, undef, '', $Data );
    return;
}
