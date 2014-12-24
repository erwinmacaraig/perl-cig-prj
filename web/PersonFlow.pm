package PersonFlow;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = @EXPORT_OK = qw(
    handlePersonFlow
);

use strict;
use lib '.', '..', "comp", 'RegoForm', "dashboard", "RegoFormBuilder",'PaymentSplit', "user";
use Reg_common;
use CGI qw(:cgi unescape);
use Flow_PersonBackend;
use Data::Dumper;

sub handlePersonFlow {
    my ($action, $Data) = @_;

    my $body = '';
    my $title = '';
    my $client = $Data->{'client'};
    my $clientValues = $Data->{'clientValues'};
    my $cl = setClient($clientValues);
    my $rego_ref = {};
    my $cgi=new CGI;
    my %params=$cgi->Vars();
    my $lang = $Data->{'lang'};
    my $personID = param('pID') || getID($clientValues, $Defs::LEVEL_PERSON) || 0;
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

    my $flow = new Flow_PersonBackend(
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
    );

    my ($content,  undef) = $flow->run();

    return $content;
}
