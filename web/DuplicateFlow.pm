package DuplicateFlow;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = @EXPORT_OK = qw(
    handleDuplicateFlow
);

use strict;
use lib '.', '..', "comp", 'RegoForm', "dashboard", "RegoFormBuilder",'PaymentSplit', "user";
use Reg_common;
use CGI qw(:cgi unescape);
use Flow_DuplicateMarking;
use Data::Dumper;

sub handleDuplicateFlow {
    my ($action, $Data, $personID, $paramRef) = @_;

    $paramRef ||= undef;
    my $body = '';
    my $title = '';
    my $client = $Data->{'client'};
    my $clientValues = $Data->{'clientValues'};
    my $cl = setClient($clientValues);
    my $rego_ref = {};
    my $cgi=new CGI;
    my %params=$cgi->Vars();

my $startingStep = $params{'ss'} || '';

    if (defined $paramRef && $paramRef->{'return'})  {
        foreach my $k (keys %{$paramRef})   {
            $cgi->param(-name=>$k, -value=>$paramRef->{$k});
        }
    }

    my %params=$cgi->Vars();
    my $lang = $Data->{'lang'};

    my $flow = new Flow_DuplicateMarking(
        db => $Data->{'db'},
        Data => $Data,
        Lang => $lang,
        CarryFields => {
            client => $client,
            a => $action,
            ss => $startingStep,
        },
        ID  => $personID || 0,
        SystemConfig => $Data->{'SystemConfig'},
        ClientValues => $clientValues,
        Target => $Data->{'target'},
        cgi => $cgi,
        DefaultTemplate => 'flow/duplicate.templ',
    );
    my ($content,  undef) = $flow->run();
    return if ($paramRef->{'return'});

    return $content;
}
1;
