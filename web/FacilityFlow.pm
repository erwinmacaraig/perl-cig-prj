package FacilityFlow;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = @EXPORT_OK = qw(
    handleFacilityFlow
);

use strict;
use lib '.', '..', "comp", 'RegoForm', "dashboard", "RegoFormBuilder",'PaymentSplit', "user";
use Reg_common;
use CGI qw(:cgi unescape);
use Flow_FacilityBackend;
use Data::Dumper;

sub handleFacilityFlow {
    my ($action, $Data) = @_;

    my $body = '';
    my $title = '';
    my $client = $Data->{'client'};
    my $clientValues = $Data->{'clientValues'};
    my $cl = setClient($clientValues);
    my $cgi=new CGI;
    my %params=$cgi->Vars();
    my $lang = $Data->{'lang'};
    my $entityID = getLastEntityID($clientValues) || 0;
    my $entityLevel = getLastEntityLevel($clientValues) || 0;
    my $originLevel = $Data->{'clientValues'}{'authLevel'} || 0;
    my $facilityID = param('vID') || 0;
    $facilityID = 0 if $facilityID < 0;

    my $savedFlowURL = '';
    my $cancelFlowURL = '';
    {
        my %tmpCv = %{$clientValues};
        $tmpCv{'currentLevel'} = $tmpCv{'authLevel'};
        my $tmpC = setClient(\%tmpCv);
        $savedFlowURL = "$Data->{'target'}?client=$tmpC&amp;a=INCOMPLPR_";
        $tmpCv{'currentLevel'} = $entityLevel;
        setClientValue(\%tmpCv, $entityLevel, $entityID);
        $tmpC = setClient(\%tmpCv);
        $cancelFlowURL = "$Data->{'target'}?client=$tmpC&amp;a=E_HOME";
    }

    my $flow = new Flow_FacilityBackend(
        db => $Data->{'db'},
        Data => $Data,
        Lang => $lang,
        CarryFields => {
            client => $client,
            a => $action,
        },
        ID  => $facilityID || 0,
        SystemConfig => $Data->{'SystemConfig'},
        ClientValues => $clientValues,
        Target => $Data->{'target'},
        AllowSaveState => 1,
        SavedFlowURL => $savedFlowURL,
        CancelFlowURL => $cancelFlowURL,
        cgi => $cgi,
    );
    my ($content,  undef) = $flow->run();

    return $content;
}
