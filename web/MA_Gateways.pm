package MA_Gateways;
require Exporter;
@ISA = qw(Exporter);
@EXPORT=@EXPORT_OK=qw(MAGateway_FI_checkoutFI MAGateway_HKPayDollar);

use lib '.', '..', "comp", 'RegoForm', "dashboard", "RegoFormBuilder",'PaymentSplit', "user" ;

use strict;
use DBI;

use Lang;
use Utils;
use CGI qw(param unescape escape);

use Digest::SHA1  qw(sha1 sha1_hex); # sha1_hex sha1_base64);
use MD5;

sub MAGateway_FI_checkoutFI	{

	my ($MAGateway_ref, $paymentSettings) = @_;

	my $nh = $MAGateway_ref->{'nh'};
        my $client = $MAGateway_ref->{'client'};
        my $payRef = $MAGateway_ref->{'ci'};
        my $chkvalue = $MAGateway_ref->{'chkv'};
        my $session = $MAGateway_ref->{'session'};
        my $amount = $MAGateway_ref->{'amount'};
        my $logID= $MAGateway_ref->{'logID'};
        my $currentLang= $MAGateway_ref->{'currentLang'};
	
	my %gatewaySpecific = ();

	$gatewaySpecific{'paymentURL'} = $paymentSettings->{'gateway_url'} .qq[?nh=$nh&amp;a=P&amp;client=$client&amp;ci=$payRef&amp;chkv=$chkvalue&amp;session=$session];
        my $cents = $amount * 100;
        my ($Second, $Minute, $Hour, $Day, $Month, $Year, $WeekDay, $DayOfYear, $IsDST) = localtime(time);
        $Year+=1900;
        $Month++;
        $Month = sprintf("%02s", $Month);
        $Day = sprintf("%02s", $Day);
        my $DeliveryDate = "$Year$Month$Day";

        my $pa = $paymentSettings->{'gatewayProcessPreGateway'} ==1 ? 0 : 1;
        $gatewaySpecific{'delayedURL'}= $Defs::gatewayReturnDemo . qq[/gatewayprocess_cofi.cgi?sa=1&da=1&pa=$pa&ci=$payRef];
        $gatewaySpecific{'cancelURL'} = $Defs::gatewayReturnDemo . qq[/gatewayprocess_cofi.cgi?sa=1&da=1&ci=$payRef];
        $gatewaySpecific{'returnURL'} = $Defs::gatewayReturnDemo . qq[/gatewayprocess_cofi.cgi?sa=1&da=1&pa=$pa&ci=$payRef];
        $gatewaySpecific{'rejectURL'} = $Defs::gatewayReturnDemo . qq[/gatewayprocess_cofi.cgi?sa=1&da=1&pa=$pa&ci=$payRef];

        $gatewaySpecific{'VERSION'} = "0001";
        $gatewaySpecific{'STAMP'} = $payRef;
        $gatewaySpecific{'AMOUNT'} = $cents;
        $gatewaySpecific{'REFERENCE'} = $logID;
        $gatewaySpecific{'MESSAGE'} = "";
        $gatewaySpecific{'LANGUAGE'} = "FI";
        $gatewaySpecific{'LANGUAGE'} = "EN" if ($currentLang =~ /^en_/);

        $gatewaySpecific{'MERCHANT'} = $paymentSettings->{'gatewayUsername'};
        $gatewaySpecific{'RETURN'} = $gatewaySpecific{'returnURL'};
        $gatewaySpecific{'CANCEL'} = $gatewaySpecific{'cancelURL'};
        $gatewaySpecific{'REJECT'} = $gatewaySpecific{'rejectURL'};
        $gatewaySpecific{'DELAYED'} = $gatewaySpecific{'delayedURL'};
        $gatewaySpecific{'COUNTRY'} = "FIN";
        $gatewaySpecific{'CURRENCY'} = $paymentSettings->{'currency'};
        $gatewaySpecific{'DEVICE'} = 1;
        $gatewaySpecific{'CONTENT'} = 1;
        $gatewaySpecific{'TYPE'} = 0;
        $gatewaySpecific{'ALGORITHM'} = 3;

        $gatewaySpecific{'DELIVERY_DATE'} = $DeliveryDate;
        $gatewaySpecific{'FIRSTNAME'} = "";
        $gatewaySpecific{'FAMILYNAME'} = "";
        $gatewaySpecific{'ADDRESS'} = "";
        $gatewaySpecific{'POSTCODE'} = "";
        $gatewaySpecific{'POSTOFFICE'} = "";

        my $m = new MD5;
        my $coKey = $gatewaySpecific{'VERSION'} ."+". $gatewaySpecific{'STAMP'} ."+". $gatewaySpecific{'AMOUNT'} ."+". $gatewaySpecific{'REFERENCE'} ."+". $gatewaySpecific{'MESSAGE'} ."+". $gatewaySpecific{'LANGUAGE'} ."+". $gatewaySpecific{'MERCHANT'} ."+". $gatewaySpecific{'RETURN'} ."+". $gatewaySpecific{'CANCEL'} ."+". $gatewaySpecific{'REJECT'} ."+". $gatewaySpecific{'DELAYED'} ."+". $gatewaySpecific{'COUNTRY'} ."+". $gatewaySpecific{'CURRENCY'} ."+". $gatewaySpecific{'DEVICE'} ."+". $gatewaySpecific{'CONTENT'} ."+". $gatewaySpecific{'TYPE'} ."+". $gatewaySpecific{'ALGORITHM'} ."+". $gatewaySpecific{'DELIVERY_DATE'} ."+". $gatewaySpecific{'FIRSTNAME'} ."+". $gatewaySpecific{'FAMILYNAME'} ."+". $gatewaySpecific{'ADDRESS'} ."+". $gatewaySpecific{'POSTCODE'} ."+". $gatewaySpecific{'POSTOFFICE'} ."+". $paymentSettings->{'gatewayPassword'};

        $m->reset();
        $m->add($coKey);
        my $authKey= uc($m->hexdigest());
        $gatewaySpecific{'MAC'} = $authKey;

        $gatewaySpecific{'EMAIL'} = "";
        $gatewaySpecific{'PHONE'} = "";

	return \%gatewaySpecific;
}

sub MAGateway_HKPayDollar	{

	my ($MAGateway_ref, $paymentSettings) = @_;

	my $nh = $MAGateway_ref->{'nh'};
        my $client = $MAGateway_ref->{'client'};
        my $payRef = $MAGateway_ref->{'ci'};
        my $chkvalue = $MAGateway_ref->{'chkv'};
        my $session = $MAGateway_ref->{'session'};
        my $amount = $MAGateway_ref->{'amount'};
        my $logID= $MAGateway_ref->{'logID'};
        my $currentLang= $MAGateway_ref->{'currentLang'};
	
	my %gatewaySpecific = ();

	$gatewaySpecific{'paymentURL'} = $paymentSettings->{'gateway_url'} .qq[?nh=$nh&amp;a=P&amp;client=$client&amp;ci=$payRef&amp;chkv=$chkvalue&amp;session=$session];
        my $cents = $amount * 100;
        my ($Second, $Minute, $Hour, $Day, $Month, $Year, $WeekDay, $DayOfYear, $IsDST) = localtime(time);
        $Year+=1900;
        $Month++;
        $Month = sprintf("%02s", $Month);
        $Day = sprintf("%02s", $Day);
        my $DeliveryDate = "$Year$Month$Day";

        my $pa = $paymentSettings->{'gatewayProcessPreGateway'} ==1 ? 0 : 1;
	#$gatewaySpecific{'delayedURL'}= $Defs::gatewayReturnDemo . qq[/gatewayprocess_hkpay.cgi?sa=1&pa=$pa&ci=$payRef];
        $gatewaySpecific{'cancelUrl'} = $Defs::gatewayReturnDemo . qq[/gatewayprocess_hkpay.cgi?da=1&ci=$payRef];
        $gatewaySpecific{'failUrl'} = $Defs::gatewayReturnDemo . qq[/gatewayprocess_hkpay.cgi?da=1&ci=$payRef];
        $gatewaySpecific{'successUrl'} = $Defs::gatewayReturnDemo . qq[/gatewayprocess_hkpay.cgi?da=1&ci=$payRef];

        $gatewaySpecific{'orderRef'} = $payRef;
        $gatewaySpecific{'mpsMode'} = "NIL";
        $gatewaySpecific{'currCode'} = $paymentSettings->{'currency'};
        $gatewaySpecific{'amount'} = $amount;
        $gatewaySpecific{'lang'} = "C";
        $gatewaySpecific{'lang'} = "E" if ($currentLang =~ /^en_/);
print STDER "HK PAY GATEWAY -- NEED TO IMPLEMENT OTHER LANGS\n";

        $gatewaySpecific{'cancelUrl'} = $gatewaySpecific{'cancelUrl'};
        $gatewaySpecific{'failUrl'} = $gatewaySpecific{'failUrl'};
        $gatewaySpecific{'successUrl'} = $gatewaySpecific{'successUrl'};

        $gatewaySpecific{'merchantId'} = $paymentSettings->{'gatewayUsername'};
        $gatewaySpecific{'payType'} = "N";
        $gatewaySpecific{'payMethod'} = "ALL";

        $gatewaySpecific{'remark'} = "";
        $gatewaySpecific{'redirect'} = 3;
        $gatewaySpecific{'oriCountry'} = 344; #HK
        $gatewaySpecific{'destCountry'} = 344; #HK
	
        my $coKey = $gatewaySpecific{'merchantId'} ."|". $gatewaySpecific{'orderRef'} ."|". $gatewaySpecific{'currCode'} ."|". $gatewaySpecific{'amount'} ."|". $gatewaySpecific{'payType'} ."|". $paymentSettings->{'gatewayPassword'};

        $gatewaySpecific{'secureHash'} = sha1_hex($coKey);
#print STDERR "SECUREHASH PAYTRY: " . $gatewaySpecific{'secureHash'} . "\n\n\n";
#print STDERR "SECUREHASH PAYTRY: " . escape($gatewaySpecific{'secureHash'}) . "\n\n\n";
        
        #$gatewaySpecific{'secureHash'} = escape($gatewaySpecific{'secureHash'});
        $gatewaySpecific{'Ref'} = $payRef;


        return \%gatewaySpecific;



}
