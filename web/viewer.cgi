#!/usr/bin/perl 

#
# $Header: svn://svn/SWM/trunk/web/lookupmanage.cgi 10133 2013-12-03 04:08:21Z tcourt $
#

use strict;
use warnings;
use CGI qw(param);
use lib "..",".","PaymentSplit","RegoFormBuilder";
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
use PersonSummaryPanel;

main();	

sub main	{
	# GET INFO FROM URL
  my $client=param('client') || '';
  my $action = safe_param('a','action') || 'view';
  my $fileID = safe_param('f','number') || 0;

  my %Data=();
  my $target='viewer.cgi';
  $Data{'target'}=$target;
  my %clientValues = getClient($client);
  $Data{'clientValues'} = \%clientValues;
  $Data{'cache'}  = new MCache();

  $Data{'AddToPage'} = new AddToPage();

  my $db=allowedTo(\%Data);
  ($Data{'Realm'},$Data{'RealmSubType'})=getRealm(\%Data);

  getDBConfig(\%Data);
  $Data{'SystemConfig'}=getSystemConfig(\%Data);
  my $lang   = Lang->get_handle('', $Data{'SystemConfig'}) || die "Can't get a language handle!";
  $Data{'lang'}=$lang;
  $Data{'LocalConfig'}=getLocalConfig(\%Data);

  my $DataAccess_ref=getDataAccess(\%Data);
  $Data{'Permissions'}=GetPermissions(
    \%Data,
    $clientValues{'authLevel'},
    getID(\%clientValues, $clientValues{'authLevel'}),
    $Data{'Realm'},
    $Data{'RealmSubType'},
    $clientValues{'authLevel'},
    0,
  );

  $Data{'DataAccess'}=$DataAccess_ref;

  my $resultHTML = '';
  if($fileID)   {

    my $st = qq[
      SELECT 
          UF.*,
          DATE_FORMAT(dtUploaded,"%d/%m/%Y %H:%i") AS DateAdded_FMT, 
          tblDocuments.intDocumentTypeID,
		  tblDocuments.strApprovalStatus,
          tblDocumentType.strLockAtLevel,
          tblDocumentType.strDocumentName
      FROM  
          tblUploadedFiles AS UF 
          LEFT JOIN tblDocuments 
              ON UF.intFileID = tblDocuments.intUploadFileID 
          LEFT JOIN tblDocumentType 
              ON tblDocuments.intDocumentTypeID = tblDocumentType.intDocumentTypeID  
      WHERE 
          UF.intFileID = ?
    ];

    my $q = $Data{'db'}->prepare($st);
    $q->execute($fileID);
    my($dref) = $q->fetchrow_hashref();
    $q->finish();

    $client=setClient(\%clientValues);
    if($dref)   {
        my $extension = uc($dref->{'strExtension'});
        my %types = (
            'PDF' => 'pdf',
            'DOC' => 'file',
            'JPG' => 'image',
            'JPEG' => 'image',
            'PNG' => 'image',
        );
        $dref->{'doctype'} = $types{$extension} || 'file';
        $dref->{'fileURL'} = 'viewfile.cgi?client='.$client.'&amp;f=' . $dref->{'intFileID'};
    }

    if($dref->{'intEntityTypeID'} == 1)  {
        my $object = getInstanceOf(\%Data,'person',$dref->{'intEntityID'});
        my $isocountries = getISOCountriesHash();
        $dref->{'PersonSummaryPanel'} = personSummaryPanel(\%Data, $dref->{'intEntityID'}) || '';
    }
    elsif($dref->{'intEntityID'})  {
        my $object = getInstanceOf(\%Data,'entity',$dref->{'intEntityID'});
        $dref->{'entity'} = {
            name => $object->name(),
            strStatus => $object->getValue('strStatus'),
            maID => $object->getValue('strMAID'),
        };    
    }
    # BUILD PAGE
    my $TemplateData = $dref;
    #$TemplateData->{'showButtons'} = $action eq 'review' ? ($dref->{'strApprovalStatus'} eq 'PENDING' ? 1 : 0 ) : 0;
	$TemplateData->{'showButtons'} = $action eq 'view' ? 0 : 1;
	$TemplateData->{'showRejectButton'} = $dref->{'strApprovalStatus'} ne 'REJECTED' ? 1 : 0;
	$TemplateData->{'showApproveButton'} = $dref->{'strApprovalStatus'} ne 'APPROVED' ? 1 : 0;
	$TemplateData->{'client'} = $client;
    $resultHTML = runTemplate(
          \%Data,
          $TemplateData,
          'viewer/viewer.templ',
    );
  }

  $resultHTML ||= textMessage("An invalid Action Code has been passed to me.");
  printBasePage($resultHTML, 'Sportzware Membership');
  disconnectDB($db);

}


