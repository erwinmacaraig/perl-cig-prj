package PayTry;
require Exporter;
@ISA = qw(Exporter);
@EXPORT=qw(payTryRead payTryRedirectBack payTryContinueProcess);
@EXPORT_OK=qw(payTryRead payTryRedirectBack payTryContinueProcess);

use lib '.', '..', "comp", 'RegoForm', "dashboard", "RegoFormBuilder",'PaymentSplit', "user" ;

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
use ClubFlow;
use PersonFlow;
use TransferFlow;
use BulkRenewalsFlow;

use Data::Dumper;

sub payTryContinueProcess {

    my ($Data, $payTry, $client, $logID) = @_;

    $payTry->{'return'} = 1;
    if ($payTry->{'strContinueAction'} eq 'CLUBFLOW')   {
        handleClubFlow($payTry->{'a'}, $Data, $payTry);
    }
    if ($payTry->{'strContinueAction'} eq 'REGOFLOW')   {
        handlePersonFlow($payTry->{'a'}, $Data, $payTry);
    }
    if ($payTry->{'strContinueAction'} eq 'TRANSFER')   {
        handleTransferFlow($payTry->{'a'}, $Data, $payTry);
    }
    if ($payTry->{'strContinueAction'} eq 'BULKRENEWALS')   {
        handleBulkRenewalsFlow($payTry->{'a'}, $Data, $payTry);
    }
    return;
}

sub payTryRedirectBack  {

    my ($Data, $payTry, $client, $logID, $autoRun) = @_;

    $autoRun ||= 0;
    my $a = $payTry->{'nextPayAction'} || $payTry->{'a'};
    #my $redirect_link = "main.cgi?client=$client&amp;a=$a&amp;run=1&tl=$logID";
    my $redirect_link = "main.cgi?client=$client&amp;a=$a&amp;paytry=1&amp;payMethod=now&amp;run=0&amp;tl=$logID";

    foreach my $k (keys %{$payTry}) {
        next if $k eq 'client';
        next if $k eq 'a';
        next if $k =~/clubID|teamID|userID|stateID|assocID|intzonID|regionID|zoneID|intregID|authLevel|natID|venueID|authLevel|currentLevel|interID/;
        next if $k =~/intAmount|dt_end_paid|strComments|paymentType|^act_|dtLog|dt_start_paid|paymentID|dd_|gatewayCount/;
        #next if $k =~/dtype/;
        next if $k =~/^ss$/;
        next if $k =~/^cc_submit/;
        next if $k =~/^pt_submit/;
        $redirect_link .= "&$k=".$payTry->{$k};
		
    }
print STDERR $redirect_link;
    return $redirect_link if ! $autoRun;

    print "Status: 302 Moved Temporarily\n";
    print "Location: $redirect_link\n\n";
    return;

     print qq[Content-type: text/html\n\n];
        print qq[
        <HTML>
        <BODY>
        <SCRIPT LANGUAGE="JavaScript1.2">
            parent.location.href="$redirect_link";
            noScript = 1;
        </SCRIPT>
        </BODY>
        </HTML>
        ];

}

sub payTryRead  {

    my ($Data, $logID, $try) = @_;

    my $where = qq[intTransLogID = ?];
    my $id = $logID;
    if ($logID and $try)  {
        $where = qq[strPayReference = ?];
        #$id = $try;
    }
    return undef if (! $logID and ! $try);
    my $st = qq[
        SELECT 
            * 
        FROM
            tblPayTry
        WHERE 
            $where
    ];
    my $query = $Data->{'db'}->prepare($st);
    $query->execute($id);
    my $href = $query->fetchrow_hashref();
    my $values = JSON::from_json($href->{'strLog'});
    $values->{'strContinueAction'} = $href->{'strContinueAction'};
    $values->{'intTransLogID'} = $href->{'intTransLogID'};
    $values->{'strPayReference'} = $href->{'strPayReference'};
    return $values;
}

1;
