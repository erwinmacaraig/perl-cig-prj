#!/usr/bin/perl -w

#
# $Header: svn://svn/SWM/trunk/web/nabprocess.cgi 8249 2013-04-08 08:14:07Z rlee $
#

use lib '.', '..', "../web", "../web/user", "../web/PaymentSplit", "../web/RegoForm", "../web/dashboard", "../web/RegoFormBuilder","../web/user", "../web/Clearances";
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
use Localisation;
use WorkFlow;

use Digest::SHA qw(hmac_sha256_hex);

#use Crypt::CBC;

main();

sub main	{

    ## Need one of these PER gateway
print STDERR "IN checkOpenPayments\n";

    my $db=connectDB();
	my %Data=();
	$Data{'db'}=$db;
    my $lang   = Lang->get_handle('', $Data{'SystemConfig'}) || die "Can't get a language handle!";
    $Data{'lang'}=$lang;

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
            intLogID
        FROM
            tblTransLog as TL
            INNER JOIN tblPaymentConfig as PC ON (PC.intPaymentConfigID = TL.intPaymentConfigID)
        WHERE
            TL.intStatus IN (0,3)
            AND TL.intSentToGateway=1
            AND PC.strGatewayCode = 'checkoutfi'
    ];
    my $query = $db->prepare($st);
    $query->execute();
    while (my $dref = $query->fetchrow_hashref())   {
	    my $logID= $dref->{'intLogID'};

        ## LOOK UP tblPayTry
        my $payTry = payTryRead(\%Data, $logID, 0);

print STDERR "CHECK FOR $logID\n";
    next;
        my %APIResponse = ();
        
        $APIResponse{'sa'} = 1;
        $APIResponse{'pa'} = 1;
        $APIResponse{'ext'} = 0;
        $APIResponse{'VERSION'} = '';
        $APIResponse{'STAMP'} = '';
        $APIResponse{'REFERENCE'} = '';
        $APIResponse{'PAYMENT'} = '';
        $APIResponse{'STATUS'} = '';
        $APIResponse{'ALGORITHM'} = '';
        $APIResponse{'MAC'} = '';
    
	    my $submit_action= $APIResponse{'sa'} || '';
        my $process_action= $APIResponse{'pa'} || '';


        my $cgi=new CGI;
        my %params=$cgi->Vars();
        $Data{'clientValues'} = $payTry;
        my $client= setClient(\%{$payTry});
        $Data{'client'}=$client;

        $Data{'sessionKey'} = $payTry->{'session'};
        getDBConfig(\%Data);
        $Data{'SystemConfig'}=getSystemConfig(\%Data);
        initLocalisation(\%Data);

        # Do they update
        if ($submit_action eq '1') {
            my %returnVals = ();
            $returnVals{'ext'} = $APIResponse{'ext'} || 0;
            $returnVals{'chkv'} = $APIResponse{'chkv'} || 0;

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
            #markGatewayAsResponded(); ## Pass taskID ????
            my ($paymentSettings, undef) = getPaymentSettings(\%Data,$Order->{'PaymentType'}, $Order->{'PaymentConfigID'}, 1);
            ########

            my $str = "$Vals{'VERSION'}&$Vals{'STAMP'}&$Vals{'REFERENCE'}&$Vals{'PAYMENT'}&$Vals{'STATUS'}&$Vals{'ALGORITHM'}";
            my $digest=uc(hmac_sha256_hex($str, $paymentSettings->{'gatewayPassword'}));
            my $chkAction = 'FAILURE';
    print STDERR "$Vals{'MAC'} $str $digest |  $paymentSettings->{'gatewayPassword'}\n";
            if ($Vals{'MAC'} eq $digest)    {
                $chkAction = 'SUCCESS';
            }
    print STDERR "MAC ACTION IS $chkAction\n";

            $returnVals{'GATEWAY_TXN_ID'}= $APIResponse{'PAYMENT'} || '';
            $returnVals{'GATEWAY_AUTH_ID'}= $APIResponse{'REFERENCE'} || '';
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

           my $respTextCode = $FIN_coResponseText{$co_status} || '';
            $returnVals{'ResponseText'}= $respTextCode; 
            $returnVals{'Other1'} = $co_status || '';
            $returnVals{'Other2'} = $APIResponse{'MAC'} || '';
            gatewayProcess(\%Data, $logID, $client, \%returnVals, $chkAction);
        }

        if ($process_action eq '1')    {
            payTryContinueProcess(\%Data, $payTry, $client, $logID);
        }

    }
	disconnectDB($db);

}

1;
