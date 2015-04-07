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
    my $realmIN = param('r') || 0;
    my $subRealmIN = param('sr') || 0;
    my $bulk= param('bulk') || 0;
    my $defaultType = param('dtype') || '';
    my $etype = param('etype') || '';
    my $transfer= param('transfer') || '';

    $registrationNature = 'TRANSFER' if ($transfer);

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
            $personLevel,
            $sport,
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
            $transfer
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

