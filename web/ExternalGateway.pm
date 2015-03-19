#
# $Header: svn://svn/SWM/trunk/web/ExternalGateway.pm 9826 2013-10-30 00:28:36Z dhanslow $
#

package ExternalGateway;
require Exporter;
@ISA = qw(Exporter);
@EXPORT=qw(ExternalGatewayUpdate NABResponseCodes );
@EXPORT_OK=qw(ExternalGatewayUpdate NABResponseCodes );

use lib "RegoForm";
use strict;
use Reg_common;
use Utils;
use HTMLForm;
use MD5;
use DeQuote;
use CGI qw(param);
use Products qw(product_apply_transaction);
use TransLog qw(viewTransLog);
use SystemConfig;
use TTTemplate;
use Payments;
use Gateway_Common;

use HTTP::Request::Common qw(POST);
use LWP::UserAgent;
use CGI qw(param unescape escape);

use RegoForm_MemberFunctions qw(rego_addRealMember);
use RegoForm::RegoFormFactory;

use PageMain;
use Log;
use DisplayPayResult;

sub NABResponseCodes	{

	my ($responseCode) = @_;

	my $responseType1='APPROVED';
	my $responseType2='DENIED';
	my $responseType3='ERROR';

	my %codes = (
		"00"=>$responseType1,
		"11"=>$responseType1,
		"08"=>$responseType1,
		"16"=>$responseType1,
		"16"=>$responseType1,

		"01"=>$responseType2,
		"02"=>$responseType2,
		"03"=>$responseType2,
		"04"=>$responseType2,
		"05"=>$responseType2,
		"06"=>$responseType2,
		"09"=>$responseType2,
		"09"=>$responseType2,
		"10"=>$responseType2,
		"12"=>$responseType2,
		"13"=>$responseType2,
		"14"=>$responseType2,
		"15"=>$responseType2,
		"17"=>$responseType2,
		"18"=>$responseType2,
		"19"=>$responseType2,
		"20"=>$responseType2,
		"21"=>$responseType2,
		"22"=>$responseType2,
		"23"=>$responseType2,
		"24"=>$responseType2,
		"25"=>$responseType2,
		"26"=>$responseType2,
		"27"=>$responseType2,
		"28"=>$responseType2,
		"29"=>$responseType2,
		"30"=>$responseType2,
		"31"=>$responseType2,
		"32"=>$responseType2,
		"33"=>$responseType2,
		"34"=>$responseType2,
		"35"=>$responseType2,
		"36"=>$responseType2,
		"37"=>$responseType2,
		"38"=>$responseType2,
		"39"=>$responseType2,
		"40"=>$responseType2,
		"41"=>$responseType2,
		"42"=>$responseType2,
		"43"=>$responseType2,
		"44"=>$responseType2,
		"51"=>$responseType2,
		"52"=>$responseType2,
		"53"=>$responseType2,
		"54"=>$responseType2,
		"55"=>$responseType2,
		"56"=>$responseType2,
		"57"=>$responseType2,
		"58"=>$responseType2,
		"59"=>$responseType2,
		"60"=>$responseType2,
		"61"=>$responseType2,
		"62"=>$responseType2,
		"63"=>$responseType2,
		"64"=>$responseType2,
		"65"=>$responseType2,
		"66"=>$responseType2,
		"67"=>$responseType2,
		"68"=>$responseType2,
		"75"=>$responseType2,
		"86"=>$responseType2,
		"87"=>$responseType2,
		"88"=>$responseType2,
		"89"=>$responseType2,
		"90"=>$responseType2,
		"91"=>$responseType2,
		"92"=>$responseType2,
		"93"=>$responseType2,
		"94"=>$responseType2,
		"95"=>$responseType2,
		"96"=>$responseType2,
		"97"=>$responseType2,
		"98"=>$responseType2,
		"99"=>$responseType2,

		"504"=>$responseType3,
		"505"=>$responseType3,
		"510"=>$responseType3,
		"511"=>$responseType3,
		"512"=>$responseType3,
		"513"=>$responseType3,
		"514"=>$responseType3,
		"515"=>$responseType3,
		"516"=>$responseType3,
		"517"=>$responseType3,
		"524"=>$responseType3,
		"545"=>$responseType3,
		"550"=>$responseType3,
		"575"=>$responseType3,
		"577"=>$responseType3,
		"580"=>$responseType3,
		"595"=>$responseType3,
	);

	my $responseText = $codes{$responseCode} || $responseCode;

	## Handle Special cases eg: wrong expiry date etc
	$responseText = 'Invalid Credit Card Number' if ($responseCode == 101);

	return $responseText;

}
sub ExternalGatewayUpdate {

  my ($Data, $paymentSettings, $client, $returnVals, $logID, $assocID)= @_;

  $logID ||= 0;
  $assocID ||= 0;
  my $txn = $returnVals->{'GATEWAY_TXN_ID'} || '';
  my $settlement_date=$returnVals->{'GATEWAY_SETTLEMENT_DATE'} || '0000-00-00';
  my $otherRef1 = $returnVals->{'Other1'} || '';
  my $otherRef2 = $returnVals->{'Other2'} || '';
  my $otherRef3 = '';
  my $otherRef4 = '';
  my $responseText = $returnVals->{'ResponseText'} || '';

	my $exportOK = 0;
	$exportOK=1 if ($returnVals->{'ResponseCode'} eq 'OK');
  	processTransLog($Data->{'db'}, $txn, $returnVals->{'ResponseCode'}, $returnVals->{'GatewayResponseCode'}, $responseText, $logID, $paymentSettings, undef, $settlement_date, $otherRef1, $otherRef2, $otherRef3, $otherRef4, '', $returnVals->{'GATEWAY_AUTH_ID'}, $returnVals->{'GATEWAY_RESPONSE_TEXT'}, $exportOK);
  	my $template_ref = getPaymentTemplate($Data, $assocID);
  	my $templateBody = $template_ref->{'strFailureTemplate'} || 'payment_failure.templ';
    my $itemData; 
	open FH, ">dumpfile.txt";
	print FH "\n ================= \n returnVals->{'ResponseCode'} = $returnVals->{'ResponseCode'} \n ===========================";	
	use Data::Dumper;		
	#print FH "\n \$paymentSettings " . Dumper($paymentSettings); 	#if ($returnVals->{'ResponseCode'} =~/^00|08|OK$/)  {
  	if ($returnVals->{'ResponseCode'} eq 'OK')  {
    	UpdateCart($Data, $paymentSettings, $client, undef, 'OK', $logID);
    	product_apply_transaction($Data,$logID);
    	EmailPaymentConfirmation($Data, $paymentSettings, $logID, $client);
		print FH "\n \$paymentSettings \n ========================================== \n" . Dumper($paymentSettings);
    	$templateBody = $template_ref->{'strSuccessTemplate'} || 'payment_success.templ';
  	} 
    elsif ($returnVals->{'ResponseCode'} eq 'HOLD')  {
    	UpdateCart($Data, $paymentSettings, $client, undef, 'HOLD', $logID);
    }
    else    {
        #processTransLogFailure($db, $logID, $otherRef1, $otherRef2, $otherRef3, $otherRef4, $otherRef5, $authID, $text);
		
    }
}

1;
