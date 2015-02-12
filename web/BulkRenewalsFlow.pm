package BulkRenewalsFlow;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = @EXPORT_OK = qw(
    handleBulkRenewalsFlow
);

use strict;
use lib '.', '..', "comp", 'RegoForm', "dashboard", "RegoFormBuilder",'PaymentSplit', "user";
use Reg_common;
use CGI qw(:cgi unescape);
use Flow_BulkRenewalsBackend;
use Data::Dumper;

sub handleBulkRenewalsFlow  {
    my ($action, $Data, $paramRef) = @_;

    my $paramRef ||= undef;
    my $body = '';
    my $title = '';
    my $client = $Data->{'client'};
    my $clientValues = $Data->{'clientValues'};
    my $cl = setClient($clientValues);
    my $rego_ref = {};
    my $cgi=new CGI;

    if (defined $paramRef && $paramRef->{'return'})  {
        foreach my $k (keys %{$paramRef})   {
            $cgi->param(-name=>$k, -value=>$paramRef->{$k});
        }
    }
    my %params=$cgi->Vars();
    my $lang = $Data->{'lang'};
    my $entityID = getLastEntityID($clientValues) || 0;
    my $entityLevel = getLastEntityLevel($clientValues) || 0;
    my $originLevel = $Data->{'clientValues'}{'authLevel'} || 0;
    my $defaultType = $params{'dtype'} || '';
    my $defaultRegistrationNature = $params{'dnat'} || '';
    my $startingStep = $params{'ss'} || '';

    #specific to Renewals
    my $renewalTargetRegoID = $params{'rpID'} || '';

    my $flow = new Flow_BulkRenewalsBackend(
        db => $Data->{'db'},
        Data => $Data,
        Lang => $lang,
        CarryFields => {
            client => $client,
            a => $action,
            dtype => $defaultType,
            dnat => $defaultRegistrationNature,
            ss => $startingStep,
            rtargetid => $renewalTargetRegoID,
        },
        SystemConfig => $Data->{'SystemConfig'},
        ClientValues => $clientValues,
        Target => $Data->{'target'},
        cgi => $cgi,
    );

    my ($content,  undef) = $flow->run();
    return if ($paramRef->{'return'});

    return $content;
}
