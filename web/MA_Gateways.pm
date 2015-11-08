package MA_Gateways;
require Exporter;
@ISA = qw(Exporter);
@EXPORT=@EXPORT_OK=qw(MAGateway_FI_checkoutFI MAGateway_HKPayDollar MAGateway_SGEasyPay calcuatePaymentCheckSum);

use lib '.', '..', "comp", 'RegoForm', "dashboard", "RegoFormBuilder",'PaymentSplit', "user" ;

use strict;
use DBI;

use Lang;
use Utils;
use CGI qw(param unescape escape);

use Digest::SHA1  qw(sha1 sha1_hex); # sha1_hex sha1_base64);
use Digest::SHA  qw(sha512_hex);
use MD5;
#use POSIX;

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
        my $reference = $logID . calcuatePaymentCheckSum($logID);
        $gatewaySpecific{'REFERENCE'} = $reference || $logID;
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
print STDERR "HK PAY GATEWAY -- NEED TO IMPLEMENT OTHER LANGS\n";

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

sub MAGateway_SGEasyPay {

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
    ## Check below

    use Date::Calc qw(Add_Delta_DHMS Today_and_Now);
    my ($Year,$Month,$Day,$Hr,$Min,$Sec) = Add_Delta_DHMS(Today_and_Now(), 0, 0, 10, 0);
    #$Year+=1900;
    #$Month++;
    $Hr= sprintf("%02s", $Hr);
    $Min= sprintf("%02s", $Min);
    $Sec= sprintf("%02s", $Sec);
    #$Year= sprintf("%04s", $Year);
    $Month = sprintf("%02s", $Month);
    $Day = sprintf("%02s", $Day);
    my $ValidityDate= "$Year-$Month-$Day $Hr:$Min:$Sec";

    my $pa = $paymentSettings->{'gatewayProcessPreGateway'} ==1 ? 0 : 1;

    $gatewaySpecific{'returnurl'} = $Defs::gatewayReturnDemo . qq[/gatewayprocess_sgEP.cgi?da=1&ci=$payRef];
    $gatewaySpecific{'statusurl'} = $Defs::gatewayReturnDemo . qq[/gatewayprocess_sgEP.cgi?sa=1&da=0&ci=$payRef];

    $gatewaySpecific{'mid'} = $paymentSettings->{'gatewayUsername'};
    $gatewaySpecific{'rcard'} = "04";
    $gatewaySpecific{'ref'} = $payRef;
    $gatewaySpecific{'cur'} = $paymentSettings->{'currency'};
    $gatewaySpecific{'amt'} = $amount;
    $gatewaySpecific{'transtype'} = 'SALE';
    $gatewaySpecific{'locale'} = "en_US" if ($currentLang =~ /^en_/);
    $gatewaySpecific{'version'} = $paymentSettings->{'gatewayVersion'};
    $gatewaySpecific{'userfield1'} = $payRef;
    #$gatewaySpecific{'validity'} = $ValidityDate;

    my $coKey = "$gatewaySpecific{'amt'}$gatewaySpecific{'ref'}$gatewaySpecific{'cur'}$gatewaySpecific{'mid'}$gatewaySpecific{'transtype'}";
    $gatewaySpecific{'signature'} = uc(sha512_hex($coKey, $paymentSettings->{'gatewayPassword'}));

    return \%gatewaySpecific;
}

sub calcuatePaymentCheckSum{
    my ($logID) = @_;

    my $len = length($logID);
    my $num = reverse($logID);

    my $total = 0;
    my @key = ();
    $key[1] = 7;
    $key[2] = 3;
    $key[3] = 1;
    my $keyCount = 1;
    for my $n (0 .. $len-1) {
        my $digit = substr $num, $n, 1;
        $keyCount = 1 if ($keyCount>3);
        my $calcDigit= $digit* $key[$keyCount];
#print "DIGIT $digit - ";
#print "MULTIPLIER $key[$keyCount] - ";
#print "equals $calcDigit\n";
        $keyCount++;
        $total = $total +  $calcDigit;
    }
#print "TOTAL $total\n";
    my $ceiling = round_up_tens($total);
    my $checksum = $ceiling - $total;
    return $checksum;
} 

sub round_up_tens {
        my $n = int shift;

        if(($n % 10) == 0) {
                return($n);
        } else {
                my $sign = 1;
                if($n < 0) { $sign = 0; }

                $n = int ($n / 10);
                $n *= 10;
                if($sign) {
                        $n += 10;
                }
                return($n);
        }
        return(-1);
}

