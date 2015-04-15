#!/usr/bin/perl 

use strict;
use warnings;
use CGI qw(param escape);
#use lib "..","../..";
use lib '.', '..', '../..',"user","../PaymentSplit",'../Clearances';
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
use Localisation;
use S3Upload;
main();	

sub main	{
	# GET INFO FROM URL
    my $client=param('client') || '';
    my $action = safe_param('a','action') || 'view';
    my $fileID = safe_param('f','number') || 0;
    my %Data=();	
    my $target='viewer.cgi';
    my $db=connectDB();
    $Data{'db'}=$db;


    my $resultHTML = '';
	my $dref;
    if($fileID){
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
    $dref = $q->fetchrow_hashref();
    $q->finish();
	
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
		$dref->{'fileURL'} = 'selfregoviewfile.cgi?client='.$client.'&amp;f=' . $dref->{'intFileID'};
		$dref->{'fileURLescape'} = escape($Defs::base_url.'/registration/selfregoviewfile.cgi?client='.$client.'&amp;f=' . $dref->{'intFileID'});
    }
    
  }
  $dref->{'BaseURL'} = $Defs::base_url;
  
  $resultHTML = runTemplate(
          \%Data,
          $dref,
          'selfrego/selfregoviewdocs.templ',
    );
  $resultHTML ||= textMessage("An invalid Action Code has been passed to me.");
  printBasePage($resultHTML, 'Sportzware Membership');
  disconnectDB($db);


}
   


