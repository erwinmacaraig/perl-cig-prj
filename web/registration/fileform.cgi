#!/usr/bin/perl -w

use strict;
use warnings;
use CGI qw(param);
use lib '.', '..', '../..';
use Defs;
use Reg_common;
use Utils;
use Lang;
use SystemConfig;
use ConfigOptions;
use PageMain;
use MCache;
use TTTemplate;
use InstanceOf;
use Countries;


my $client = param('client') || 0;
my $regoID = param('regoID') || 0;
my $docTypeID = param('doctype') || 0; 
my $personID = param('pID') || 0;
my $replaceFileID = param('f') || 0;
my $doctypename = param('doctypename') || '';
my $docDesc = param('desc') || '';
my $isForEntity = param('entitydocs') || 0;
my $fromFlow = param('nff') || 0;

  my %Data=();
  my $target='viewer.cgi';
  $Data{'target'}=$target;
  my %clientValues = getClient($client);
  $Data{'clientValues'} = \%clientValues;
  $Data{'cache'}  = new MCache();

  $Data{'AddToPage'} = new AddToPage();

  my $db=connectDB();
    $Data{'db'} = $db;
  ($Data{'Realm'},$Data{'RealmSubType'})=getRealm(\%Data);
    $Data{'Realm'} ||= 1;

  getDBConfig(\%Data);
  $Data{'SystemConfig'}=getSystemConfig(\%Data);
  my $lang   = Lang->get_handle('', $Data{'SystemConfig'}) || die "Can't get a language handle!";
  $Data{'lang'}=$lang;
  $Data{'LocalConfig'}=getLocalConfig(\%Data);

  my $resultHTML = '';

  my $TemplateData = {
			client 			=>	$client,
			url				=>	$Defs::base_url,
			doctype			=>	$doctypename,
			regoID 			=>	$regoID,
			docTypeID		=> 	$docTypeID,
			replaceFileID	=>	$replaceFileID,
			personID		=>	$personID,
			entitydocs		=> 	$isForEntity,
			description		=>	$docDesc,
			fromFlow		=>  $fromFlow,
			Lang			=>  $lang,
			
	};

$resultHTML = runTemplate(
          \%Data,
          $TemplateData,
          'workflow/view/document_upload.templ',
    );
  printBasePage($resultHTML, $Defs::page_title);

