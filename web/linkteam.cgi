#!/usr/bin/perl -w

#
# $Header: svn://svn/SWM/trunk/web/linkteam.cgi 10144 2013-12-03 21:36:47Z tcourt $
#

use DBI;
use CGI qw(:cgi escape unescape);

use strict;

use lib ".","..","../..","passport","comp";

use Defs;
use Utils;
use Passport;
use PageMain;
use Reg_common;
use Lang;
use PassportLink;
use InstanceOf;
use TTTemplate;

main();

sub	main	{

	my %Data=();
	my $teamkey = param('mk') || '';
	my $db = connectDB();
	$Data{'db'}=$db;
  my $lang= Lang->get_handle() || die "Can't get a language handle!";
  $Data{'lang'}=$lang;
  my $target='linkteam.cgi';
  $Data{'target'}=$target;
  $Data{'cache'}=new MCache();

	my $teamID = validateTeamKey($teamkey) || 0;

  my $passport = new Passport(
    db => $db,
    cache => $Data{'cache'},
  );
  $passport->loadSession();
  my $pID = $passport->id() || 0;

warn("GOT pID") if $pID;

	my $body = '';
	if($teamID)	{
		if($pID)	{
			$body = linkTeam(
				\%Data,
				$pID,
				$teamID,
			);
		}
		else	{
			$body = getTeamLinkPage(
				\%Data,
				$teamID,
			);
		}
	}
	else	{
		$body = 'Invalid Team Code';
	}

	my $title = 'Add Team to your Passport';


	$Data{'HTMLHead'} = '<link rel="stylesheet" type="text/css" href="css/passportstyle.css"> 
  <!--[if IE]>
    <link rel="stylesheet" type="text/css" href="css/passport_ie.css" />
  <![endif]-->

  <!--[if lt IE 9]>
    <link rel="stylesheet" type="text/css" href="css/passport_ie_old.css" />
  <![endif]-->
';
	pageForm(
		$title,
		$body,
		{},
		'',
		\%Data,
	);
}

sub validateTeamKey {
	my ($teamkey) = @_;

	my ($teamID, $code) = split /f/,$teamkey,2;

	return 0 if !$teamID;
	return 0 if !$code;

	my $newcode = getRegoPassword($teamID);
	return $teamID if $code eq $newcode;
	return 0;
}

sub getTeamLinkPage	{
	my (
		$Data,
		$teamID,
	) = @_;

  my $templateFile = 'passport/linkteam.templ';
	my $teamObj = getInstanceOf($Data,'team', $teamID);

	my $passportURL = passportURL(
    $Data,
    { },
		'',
		'',
    {
			cbs => 'swm',
			cbc => $teamID.'f'.getRegoPassword($teamID),
		},
  ) || '';
  my $body = runTemplate(
    $Data,
    {
      PassportLinkURL => $passportURL,
      Name => $teamObj->name(),
      FirstName => $teamObj->getValue('strFirstname') || '',
    },
    $templateFile,
  );

	return $body;
}

sub linkTeam	{
	my (
        $Data,
        $pID,
        $teamID,
	) = @_;

	my $error = '';
	my $success = 'Error with link';
	my $assocID = 0;
	{
		my $st = qq[
			SELECT intAssocID 
			FROM tblTeam
			WHERE intTeamID = ?
		];
    my $q = $Data->{'db'}->prepare($st);
    $q->execute(
      $teamID,
		);
		($assocID) = $q->fetchrow_array();
		$assocID ||= 0;
		$q->finish();
	}
	if($assocID)	{
    my $st = qq[
      INSERT IGNORE INTO tblPassportAuth (
        intPassportID, 
        intEntityTypeID,
        intEntityID,
        intAssocID,
        dtCreated
      )
      VALUES (
        ?,
        ?,
        ?,
        ?,
        NOW()
      )
    ];
    my $q = $Data->{'db'}->prepare($st);
    $q->execute(
      $pID,
      $Defs::LEVEL_TEAM,
      $teamID,
      $assocID,
    );
		$q->finish();
		$success = 'Team is now Linked';
	}

  my $templateFile = 'passport/linkteam_finish.templ';
  my $body = runTemplate(
    $Data,
    {
      Error => $error,
			Success => $success,
    },
    $templateFile,
  );


}
