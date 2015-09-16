#!/usr/bin/perl -w

#
# $Header: svn://svn/SWM/trunk/web/nabprocess.cgi 8249 2013-04-08 08:14:07Z rlee $
#

use lib '.', '..', "../web", "../web/user", "../web/PaymentSplit", "../web/RegoForm", "../web/dashboard", "../web/RegoFormBuilder","../web/user", "../web/Clearances", "../web/registration", "../web/registration/user";
use DBI;
use CGI qw(:cgi escape unescape);

use strict;

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
use Data::Dumper;
use GatewayProcess;
use PayTry;
use Localisation;
use Products;

use Digest::SHA qw(hmac_sha256_hex);
use HTTP::Request::Common qw(POST);
use XML::Simple;

#use Crypt::CBC;

main();

sub main	{

    ## Need one of these PER gateway
print STDERR "IN checkOpenPayments\n";

    my $db=connectDB();

    my %FIN_coResponseText = (
            -10=>"PAYMENT_RETURNED",
            -4=>"PAYMENT_TXN_NOT_FOUND",
            -3 =>"PAYMENT_TIMEDOUT",
            -2 =>"PAYMENT_CANCELED",
            -1 =>"PAYMENT_CANCELED",
            1 => "PAYMENT_UNSUCCESSFUL",
            2=>"PAYMENT_SUCCESSFUL",
            3=>"PAYMENT_DELAYED",
            4=>"",
            5=>"PAYMENT_SUCCESSFUL",
            6=>"PAYMENT_SUCCESSFUL",
            7=>"PAYMENT_TO_THIRD_PARTY",
            8=>"PAYMENT_THIRD_PARTY_ACCEPTED",
            9=>"",
            10=>"PAYMENT_SENT_TO_MERCHANT",
        );
     
    my $st = qq[
        SELECT
	DISTINCT
            TL.intLogID,
            TL.intAmount,
            TL.strOnlinePayReference,
            PC.strGatewayUsername,
            PC.strGatewayPassword,
            PC.strCurrency,
			PC.intProcessPreGateway	,
            TL.strReceiptRef,
            TL.strTXN,
		PT.strPayReference
        FROM
            tblTransLog as TL
            INNER JOIN tblPaymentConfig as PC ON (PC.intPaymentConfigID = TL.intPaymentConfigID)
	    INNER JOIN tblPayTry as PT ON (PT.intTransLogID = TL.intLogID)
        WHERE
            TL.intStatus IN (0,3)
            AND PC.strGatewayCode = 'checkoutfi'
		    AND  TL.intSentToGateway = 1 
            AND TL.intPaymentGatewayResponded = 0
            AND NOW() >= DATE_ADD(PT.dtTry, INTERVAL 25 minute)
            AND TL.intCheckOnceDaily = 1
    ];
            #AND NOW() >= DATE_ADD(PT.dtTry, INTERVAL 5 minute)
            #AND NOW() >= DATE_ADD(PT.dtTry, INTERVAL 1 hour)
    my $checkURL = 'https://rpcapi.checkout.fi/poll';
    my $query = $db->prepare($st);
    $query->execute();
    while (my $dref = $query->fetchrow_hashref())   {
	my %Data=();
	$Data{'db'}=$db;
        $Data{'Realm'} = 1;
        $Data{'SystemConfig'}=getSystemConfig(\%Data);
        my $payTry = payTryRead(\%Data, $dref->{'strPayReference'}, 1);
	my $logID= $payTry->{'intTransLogID'};
	next if ! $logID;
        next if ! $dref->{'intAmount'};
        ## LOOK UP tblPayTry

        my $lang   = Lang->get_handle('', $Data{'SystemConfig'}) || die "Can't get a language handle!";
        $Data{'lang'}=$lang;
        getDBConfig(\%Data);
        ( $Data{'Realm'}, $Data{'RealmSubType'} ) = getRealm( \%Data );

        $Data{'clientValues'} = $payTry;
        my $client= setClient(\%{$payTry});
        $Data{'client'}=$client;

        $Data{'sessionKey'} = $payTry->{'session'};
        initLocalisation(\%Data);


        print STDERR "CHECK FOR $logID\n";
        my %APIResponse=();
        my $cents = $dref->{'intAmount'} * 100;
        $APIResponse{'VERSION'} = "0001";
        $APIResponse{'STAMP'} = $dref->{'strOnlinePayReference'}; #Data{'SystemConfig'}{'paymentPrefix'}.$logID;
        $APIResponse{'REFERENCE'} = $dref->{'strReceiptRef'}; #$logID;
        $APIResponse{'MERCHANT'} = $dref->{'strGatewayUsername'};
        $APIResponse{'AMOUNT'} = $cents;
        $APIResponse{'CURRENCY'} = $dref->{'strCurrency'};
        $APIResponse{'FORMAT'} = 1;
        $APIResponse{'ALGORITHM'} = 1;
        my $m = new MD5;
        my $coKey = $APIResponse{'VERSION'} ."+". $APIResponse{'STAMP'} ."+". $APIResponse{'REFERENCE'} ."+". $APIResponse{'MERCHANT'} ."+". $APIResponse{'AMOUNT'} ."+". $APIResponse{'CURRENCY'} ."+". $APIResponse{'FORMAT'} ."+". $APIResponse{'ALGORITHM'} . "+" . $dref->{'strGatewayPassword'};


        $m->reset();
        $m->add($coKey);
        my $authKey= uc($m->hexdigest());
        $APIResponse{'MAC'} = $authKey;
        my $req = POST $checkURL, \%APIResponse;
        my $ua = LWP::UserAgent->new();
        my $res= $ua->request($req);
        my $retval = $res->content() || '';
#print STDERR Dumper(\%APIResponse);
#print STDERR "--- $retval\n";
	#next if $retval =~/error/;
	#next if $retval !~/status/; 
	#my $dataIN= XMLin($retval);

    my $dataIN= {};
    if ($retval =~/error/)  {
        $dataIN->{'status'} = 1;
print STDERR "IN HERE for $logID\n";
    }
    else    {
	    next if $retval !~/status/; 
        $dataIN= XMLin($retval);
    }
        #print STDERR Dumper($dataIN);
        
        $APIResponse{'STATUS'} = $dataIN->{'status'}; 
#print STDERR Dumper(\%APIResponse);
print STDERR "API STATUS IS " . $APIResponse{'STATUS'};

        
        $APIResponse{'sa'} = 1;
        $APIResponse{'pa'} = 1;
        $APIResponse{'ext'} = 0;
    
	    my $submit_action= $APIResponse{'sa'} || '';
        my $process_action= $APIResponse{'pa'} || '';

        #my $cgi=new CGI;
        #my %params=$cgi->Vars();
                # Do they update
        if ($submit_action eq '1') {
            my %returnVals = ();
            $returnVals{'ext'} = $APIResponse{'ext'} || 0;
            $returnVals{'chkv'} = $APIResponse{'chkv'} || 0;
            $returnVals{'action'} = $APIResponse{'sa'} || 0;

            my %Vals = ();
            $Vals{'VERSION'}= $APIResponse{'VERSION'} || '';
            $Vals{'STAMP'}= $APIResponse{'STAMP'} || '';
            $Vals{'REFERENCE'}= $APIResponse{'REFERENCE'} || '';
            $Vals{'PAYMENT'}= $APIResponse{'PAYMENT'} || '';
            $Vals{'STATUS'}= $APIResponse{'STATUS'} || '';
            $Vals{'ALGORITHM'}= $APIResponse{'ALGORITHM'} || '';
            $Vals{'MAC'}= $APIResponse{'MAC'} || '';
            
            ########
            my ($Order, $Transactions) = gatewayTransactions(\%Data, $logID);
            my ($paymentSettings, undef) = getPaymentSettings(\%Data,$Order->{'PaymentType'}, $Order->{'PaymentConfigID'}, 1);
            ########

            my $chkAction = 'SUCCESS'; ## Otherwise it wpuldn't have gotten this far

            $returnVals{'GATEWAY_TXN_ID'}= $APIResponse{'PAYMENT'} || $dref->{'strTXN'} || '';
            $returnVals{'GATEWAY_AUTH_ID'}= $APIResponse{'REFERENCE'} || '';#$dref->{'strAuthID'} || '';
            my $co_status = $APIResponse{'STATUS'} || '';
            $returnVals{'GATEWAY_RESPONSE_CODE'}= "99";
            $returnVals{'GATEWAY_RESPONSE_CODE'}= "OK" if (
                $co_status eq "2" 
                or $co_status eq "5" 
                or $co_status eq "8"
                or $co_status eq "9"
                or $co_status eq "10"
            );
            $returnVals{'GATEWAY_RESPONSE_CODE'}= "HOLD" if (
                $co_status eq "3"  ## Delayed Payment
                or $co_status eq "6" 
                or $co_status eq "7" 
            );
            $returnVals{'GATEWAY_RESPONSE_TEXT'}= $APIResponse{'REFERENCE'} || '';
            $returnVals{'GatewayResponseCode'}= $co_status;
            $returnVals{'ResponseCode'}= $returnVals{'GATEWAY_RESPONSE_CODE'};
            markGatewayAsResponded(\%Data, $logID) if $returnVals{'GATEWAY_RESPONSE_CODE'} ne 'HOLD'; 

           my $respTextCode = $FIN_coResponseText{$co_status} || '';
            $returnVals{'ResponseText'}= $respTextCode; 
            $returnVals{'Other1'} = $co_status || '';
            $returnVals{'Other2'} = $APIResponse{'MAC'} || '';
            gatewayProcess(\%Data, $logID, $client, \%returnVals, $chkAction);
        }

        if ($process_action eq '1' and ! $dref->{'intProcessPreGateway'})    {
            payTryContinueProcess(\%Data, $payTry, $client, $logID);
        }

    }
}

1;
