#!/usr/bin/perl 

use strict;
use warnings;
#use lib "..",".","../..";
use lib '.', '..', '../..',"../comp", '../RegoForm', "../dashboard", "../RegoFormBuilder",'../PaymentSplit', "../user", "../Clearances";
use CGI qw(param);
use Defs;
use Reg_common;
use Utils;
use JSON;
use Lang;
use PersonRegisterWhat;

main();	

sub main	{
	# GET INFO FROM URL
    my $client = param('client') || '';
    my $originLevel= param('ol') || 0;
    my $registrationNature = param('nat') || '';
    my $personType = param('pt') || '';
    my $personEntityRole= param('per') || '';
    my $personLevel = param('pl') || '';
    my $sport = param('sp') || '';
    my $ageLevel = param('ag') || '';
    my $personID = param('pID') || '';
    my $entityID = param('eID') || '';
    my $dob = param('dob') || '';
    my $gender = param('gender') || '';
    my $lookingFor = param('otype') || '';
    my $realmIN = param('r') || 1;
    my $subRealmIN = param('sr') || 0;
    my $bulk= param('bulk') || 0;
    my $defaultType = param('dtype') || '';
    my $defaultSport= param('dsport') || '';
    my $defaultLevel= param('dlevel') || '';
    my $defaultEntityRole= param('dentityrole') || '';
    my $defaultNature= param('dnat') || '';
    my $etype = param('etype') || '';
    my $itc = param('itc') || 0;
    my $preqType = param('preqtype') || '';

    $etype= '' if (! defined $etype or $etype eq 'null');
    $entityID= '' if (! defined $entityID or $entityID eq 'null');
    $registrationNature = '' if (! defined $registrationNature or $registrationNature eq 'null');
    $personType = '' if (! defined $personType or $personType eq 'null');
    $personEntityRole= '' if (! defined $personEntityRole or $personEntityRole eq 'null');
    $personLevel = '' if (! defined $personLevel or $personLevel eq 'null');
    $sport = '' if (! defined $sport or $sport eq 'null');
    $ageLevel = '' if (! defined $ageLevel or $ageLevel eq 'null');
    $defaultType = '' if (! defined $defaultType or $defaultType eq 'null');
    $defaultSport = '' if (! defined $defaultSport or $defaultSport eq 'null');
    $defaultLevel = '' if (! defined $defaultLevel or $defaultLevel eq 'null');
    $defaultEntityRole = '' if (! defined $defaultEntityRole or $defaultEntityRole eq 'null');
    $defaultNature = '' if (! defined $defaultNature or $defaultNature eq 'null');

    $registrationNature = 'TRANSFER' if ($defaultNature eq 'TRANSFER');
    $registrationNature = 'RENEWAL' if ($defaultNature eq 'RENEWAL' or $bulk);
    $registrationNature = $defaultNature if ($defaultNature eq $Defs::REGISTRATION_NATURE_DOMESTIC_LOAN or $defaultNature eq $Defs::REGISTRATION_NATURE_INTERNATIONAL_LOAN);
    $registrationNature = 'NEW' if (!$defaultNature and ! $bulk);
    $registrationNature ||= $defaultNature;

    my %Data=();
    my $target='aj_person_registerwhat.cgi';
    $Data{'target'}=$target;
    my %clientValues = getClient($client);
    $Data{'clientValues'} = \%clientValues;
    my $db=connectDB();
    $Data{'db'} = $db;
    my $lang= Lang->get_handle() || die "Can't get a language handle!";
    $Data{'lang'}=$lang;

    ($Data{'Realm'}, $Data{'RealmSubType'})=getRealm(\%Data);
    $Data{'Realm'} ||= 1;

    my $options = undef;
    my $error = '';
	if($db)	{

        ($options, $error) = optionsPersonRegisterWhat(
            \%Data,
            $Data{'Realm'} || $realmIN,
            $Data{'RealmSubType'} || $subRealmIN,
            $originLevel,
            $registrationNature,
            $personType,
            $defaultType,
            $personEntityRole,
            $defaultEntityRole,
            $personLevel,
            $defaultLevel,
            $sport,
            $defaultSport,
            $ageLevel,
            $personID,
            $entityID,
            $dob,
            $gender,
            $lookingFor,
            $bulk,
            $etype,
            getLastEntityLevel(\%clientValues),
            getLastEntityID(\%clientValues),
            $itc,
            $preqType,
        );
	}

  my %jsondata = ();
  if($error)    {
    %jsondata = (
        error => $error,
    );
  }
  else  {
    %jsondata = (
        options => $options || undef,
        results => scalar(@{$options}),
    );
  }
  my $json = to_json(\%jsondata);
  print "Content-type: application/x-javascript\n\n$json";
}

