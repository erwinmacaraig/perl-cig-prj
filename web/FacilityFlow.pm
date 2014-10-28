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

    my $flow = new Flow_FacilityBackend(
        db => $Data->{'db'},
        Data => $Data,
        Lang => $lang,
        CarryFields => {
            client => $client,
            a => $action,
        },
        SystemConfig => $Data->{'SystemConfig'},
        ClientValues => $clientValues,
        Target => $Data->{'target'},
        cgi => $cgi,
    );
    my ($content,  undef) = $flow->run();

    return $content;
}
