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
use PersonRegistration;

sub handlePersonFlow {
    my ($action, $Data, $paramRef) = @_;
print STDERR "ACTION $action\n";

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
    my $itc = $params{'itc'} || '';
    my $preqtype = $params{'preqtype'} || '';
    my $startingStep = $params{'ss'} || '';

    #specific to Transfers
    my $personRequestID = $params{'prid'} || '';

    #specific to Renewals
    my $renewalTargetRegoID = $params{'rtargetid'} || '';
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
    if($renewalTargetRegoID)    {
        my $rego = PersonRegistration::getRegistrationDetail($Data, $renewalTargetRegoID) || {};
        if($rego and $rego->[0] and $rego->[0]{'personType'} and !$defaultType)   {
            $defaultType = $rego->[0]{'personType'};
        }
    }


    my $flow = new Flow_PersonBackend(
        db => $Data->{'db'},
        Data => $Data,
        Lang => $lang,
        CarryFields => {
            client => $client,
            a => $action,
            dtype => $defaultType,
            dnat => $defaultRegistrationNature,
            itc => $itc,
            ss => $startingStep,
            prid => $personRequestID,
            preqtype => $preqtype,

            rtargetid => $renewalTargetRegoID,
        },
        ID  => $personID || 0,
        SystemConfig => $Data->{'SystemConfig'},
        ClientValues => $clientValues,
        Target => $Data->{'target'},
        AllowSaveState => 1,
        SavedFlowURL => $savedFlowURL,
        CancelFlowURL => $cancelFlowURL,
        cgi => $cgi,
    );
    my ($content,  undef) = $flow->run();
    return if ($paramRef->{'return'});

    return $content;
}
