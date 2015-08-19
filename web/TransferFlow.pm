package TransferFlow;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = @EXPORT_OK = qw(
    handleTransferFlow
    handleIntTransferOutFlow
    handleIntTransferReturnFlow
);

use strict;
use lib '.', '..', "comp", 'RegoForm', "dashboard", "RegoFormBuilder",'PaymentSplit', "user";
use Reg_common;
use CGI qw(:cgi unescape);
use Flow_TransferBackend;
use Flow_IntTransferOutBackend;
use Flow_IntTransferReturnBackend;
use Data::Dumper;

sub handleTransferFlow {
    my ($action, $Data, $paramRef) = @_;

    $paramRef ||= undef;
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
    my $personID = param('personID') || param('pID') || getID($clientValues, $Defs::LEVEL_PERSON) || 0;
    $personID = 0 if $personID < 0;
    my $entityID = getLastEntityID($clientValues) || 0;
    my $entityLevel = getLastEntityLevel($clientValues) || 0;
    my $originLevel = $Data->{'clientValues'}{'authLevel'} || 0;
    my $defaultType = $params{'dtype'} || '';
    my $defaultRegistrationNature = $params{'dnat'} || '';
    my $internationalTransfer = $params{'itc'} || '';
    my $startingStep = $params{'ss'} || '';

    #specific to Transfers
    my $personRequestID = $params{'prid'} || '';

    #specific to Renewals
    my $renewalTargetRegoID = $params{'rpID'} || '';

    my $flow = new Flow_TransferBackend(
        db => $Data->{'db'},
        Data => $Data,
        Lang => $lang,
        CarryFields => {
            client => $client,
            a => $action,
            dtype => $defaultType,
            dnat => $defaultRegistrationNature,
            itc => $internationalTransfer,
            ss => $startingStep,
            prid => $personRequestID,

            rtargetid => $renewalTargetRegoID,
        },
        ID  => $personID || 0,
        SystemConfig => $Data->{'SystemConfig'},
        ClientValues => $clientValues,
        Target => $Data->{'target'},
        cgi => $cgi,
        DefaultTemplate => 'flow/transfer.templ',
    );
    my ($content,  undef) = $flow->run();
    return if ($paramRef->{'return'});

    return $content;
}


sub handleIntTransferOutFlow {
    my ($action, $Data, $paramRef) = @_;

    $paramRef ||= undef;
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
    my $personID = param('personID') || param('pID') || getID($clientValues, $Defs::LEVEL_PERSON) || 0;
    $personID = 0 if $personID < 0;
    my $entityID = getLastEntityID($clientValues) || 0;
    my $entityLevel = getLastEntityLevel($clientValues) || 0;
    my $originLevel = $Data->{'clientValues'}{'authLevel'} || 0;
    my $defaultType = $params{'dtype'} || '';
    my $defaultRegistrationNature = $params{'dnat'} || '';
    my $internationalTransfer = $params{'itc'} || '';
    my $startingStep = $params{'ss'} || '';

    #specific to Transfers
    my $personRequestID = $params{'prid'} || '';

    #specific to Renewals
    my $renewalTargetRegoID = $params{'rpID'} || '';

    my $flow = new Flow_IntTransferOutBackend(
        db => $Data->{'db'},
        Data => $Data,
        Lang => $lang,
        CarryFields => {
            client => $client,
            a => $action,
            dtype => $defaultType,
            dnat => $defaultRegistrationNature,
            itc => $internationalTransfer,
            ss => $startingStep,
            prid => $personRequestID,

            rtargetid => $renewalTargetRegoID,
        },
        ID  => $personID || 0,
        SystemConfig => $Data->{'SystemConfig'},
        ClientValues => $clientValues,
        Target => $Data->{'target'},
        cgi => $cgi,
        DefaultTemplate => 'flow/transfer.templ',
    );
    my ($content,  undef) = $flow->run();
    return if ($paramRef->{'return'});

    return $content;
}

sub handleIntTransferReturnFlow {
    my ($action, $Data, $paramRef) = @_;

    $paramRef ||= undef;
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
    my $personID = param('personID') || param('pID') || getID($clientValues, $Defs::LEVEL_PERSON) || 0;
    $personID = 0 if $personID < 0;
    my $entityID = getLastEntityID($clientValues) || 0;
    my $entityLevel = getLastEntityLevel($clientValues) || 0;
    my $originLevel = $Data->{'clientValues'}{'authLevel'} || 0;
    my $defaultType = $params{'dtype'} || '';
    my $defaultRegistrationNature = $params{'dnat'} || '';
    my $internationalTransfer = $params{'itc'} || '';
    my $startingStep = $params{'ss'} || '';

    #specific to Transfers
    my $personRequestID = $params{'prid'} || '';

    #specific to Renewals
    my $renewalTargetRegoID = $params{'rpID'} || '';

    my $flow = new Flow_IntTransferReturnBackend(
        db => $Data->{'db'},
        Data => $Data,
        Lang => $lang,
        CarryFields => {
            client => $client,
            a => $action,
            dtype => $defaultType,
            dnat => $defaultRegistrationNature,
            itc => $internationalTransfer,
            ss => $startingStep,
            prid => $personRequestID,

            rtargetid => $renewalTargetRegoID,
        },
        ID  => $personID || 0,
        SystemConfig => $Data->{'SystemConfig'},
        ClientValues => $clientValues,
        Target => $Data->{'target'},
        cgi => $cgi,
        DefaultTemplate => 'flow/transfer.templ',
    );
    my ($content,  undef) = $flow->run();
    return if ($paramRef->{'return'});

    return $content;
}
