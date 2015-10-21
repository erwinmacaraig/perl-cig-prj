package SelfUserExtraProductFlow;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = @EXPORT_OK = qw(
    handleSelfUserExtraProductFlow
);

use strict;
use CGI qw(param unescape escape cookie);

use lib '.', '..', '../..',"../registration", "../registration/user","../PaymentSplit",'../Clearances';
use Lang;
use Localisation;
use Reg_common;
use PageMain;
use Defs;
use Utils;
use SystemConfig;
use ConfigOptions;
use SelfUserSession;
use SelfUserObj;

use MCache;
use FieldConfig;
use TTTemplate;
use AddToPage;

use SelfUserHome;
use Flow_SelfRegExtraProduct;
use AccountActivation;

use Data::Dumper;

sub handleSelfUserExtraProductFlow  {

    my ($action, $Data, $paramRef) = @_;

    my $body = '';
    my $title = '';
    my $client = $Data->{'client'};
    my $clientValues = $Data->{'clientValues'};
    my $cl = setClient($clientValues);
    $paramRef ||= undef;
    my $rego_ref = {};
    my $cgi=new CGI;
    if (defined $paramRef && $paramRef->{'return'})  {
        foreach my $k (keys %{$paramRef})   {
            $cgi->param(-name=>$k, -value=>$paramRef->{$k});
        }
    }
    my %params=$cgi->Vars();

    my $user = new SelfUserSession(
        db    => $Data->{'db'},
        cache => $Data->{'cache'},
    );
    $user->load();
    my $userID = $user->id() || 0;
    $Data->{'UserName'} = $user->name();
    $Data->{'User'} = $user;


        my $lang = $Data->{'lang'};
        my $personID = $params{'pID'} || 0;
        $personID = 0 if $personID < 0;
        my $srp = $params{'srp'} || '';
        my $defaultType = $params{'dtype'} || '';
        my $defaultRegistrationNature = $params{'dnat'} || '';
        my $internationalTransfer = $params{'itc'} || '';
        my $startingStep = $params{'ss'} || '';
        my $minorRego = $params{'minorRego'} || '';
        my $entityID = 0;
        
        my $defaultSport = $params{'dsport'} || '';
        my $regoID = $params{'rID'} || 0;
        
        #specific to Transfers
        my $personRequestID = $params{'prid'} || '';

        #specific to Renewals
        my $renewalTargetRegoID = $params{'rtargetid'} || '';
        if($srp)    {
            my($s_type, $s_entity) = split /:/, $srp;
            $defaultType = $s_type if $s_type;
            $entityID = $s_entity if $s_entity;
        }

        my $flow = new Flow_SelfRegExtraProduct( 
            db => $Data->{'db'},
            Data => $Data,
            Lang => $lang,
            CarryFields => {
                client => $client,
                a => $action,
                dtype => $defaultType,
                dnat => $defaultRegistrationNature,
                itc => $internationalTransfer,
                minorRego => $minorRego,
                ss => $startingStep,
                prid => $personRequestID,
                rtargetid => $renewalTargetRegoID,
                de => $entityID,
                rID => $regoID,
            },
            ID  => $personID || 0,
            UserID  => $userID || 0,
            SystemConfig => $Data->{'SystemConfig'},
            ClientValues => $clientValues,
            Target => $Data->{'target'},
            cgi => $cgi,
        );

        my ($content,  undef) = $flow->run();
        return $content;
    }

