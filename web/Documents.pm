#
# $Header: svn://svn/SWM/trunk/web/Documents.pm 9210 2013-08-13 07:53:00Z dhanslow $
#

package Documents;
require Exporter;
@ISA =  qw(Exporter);
@EXPORT = qw(handle_documents);
@EXPORT_OK = qw(handle_documents);

use strict;
use lib "..",".";
use Defs;
use Utils;

use ImageUpload;
use FileUpload;
use CGI qw(:cgi param unescape escape);
use Reg_common;
use AuditLog;
use UploadFiles;
use FormHelpers;
use GridDisplay;
use Data::Dumper;

sub handle_documents {
	my($action, $Data, $memberID, $DocumentTypeID,$RegistrationID)=@_;
  my $resultHTML='';
	
  my $assocID= $Data->{'clientValues'}{'assocID'} || -1;
	return ('No Member or Association Specified','','') if !$memberID or !$assocID;
	my $newaction='';
  my $client=setClient($Data->{'clientValues'}) || '';

  my $type = '';
       $DocumentTypeID ||= 0; 
       $RegistrationID ||= 0;
       
       $action ||= 'DOC_L';

   $resultHTML =  new_doc_form($Data, $client,$DocumentTypeID,$RegistrationID, $memberID); 
  if ($action eq 'DOC_u') {
		my $retvalue = process_doc_upload( 
			$Data,
			$memberID, 
			$client,
		);
		$resultHTML = qq[<div class="warningmsg">$retvalue</div>] if $retvalue;
		$type = 'Add Document'; 
                
	}
  elsif ($action eq 'DOC_d') {
		my $fileID = param('dID') || 0;	
		my $retpage = param('retpage') || "$Data->{'target'}?client=$client";
        $resultHTML = delete_doc($Data, $fileID,$client, $retpage);
		$type = 'Delete Document';
  }   
  
  
	#$resultHTML .= list_docs($Data,$memberID,$client,$DocumentTypeID,$RegistrationID);
       
  if ($type) {
    auditLog($memberID, $Data, $type, 'Document');
  }

	return ($resultHTML,'', $newaction);
}


sub list_docs {
	my($Data, $memberID, $client, $DocumentTypeID, $RegistrationID,$retpage)=@_;
	my $target=$Data->{'target'} || '';
	my $l = $Data->{'lang'};
    $DocumentTypeID ||= 0; 
    $RegistrationID ||= 0;
    $retpage ||= "P_DOCS";
	my $body = '';
	my $title = '';	
	my $docs = getUploadedFiles(
		$Data,
		$Defs::LEVEL_MEMBER,	
		$memberID,
		$Defs::UPLOADFILETYPE_DOC,
		$client,
		$retpage
	);
	##############################3
	 my $allfilesgrid = '';
	if(defined $docs->[0]->{'id'}){
		$body = qq[<br /><div class="pageHeading">$title</div>];
		my @headers2 = (
		{ 
            type => 'Selector',
            field => 'SelectLink',
        }, 
		{
			name => $Data->{'lang'}->txt('Title'),
			field => 'Title',
		},
       {
            name => $Data->{'lang'}->txt('Size'),
            field => 'Size',
        }, 
        {
            name => $Data->{'lang'}->txt('Extension Name'),
            field => 'Ext',
        },
        {
            name => $Data->{'lang'}->txt('Date Uploaded'),
            field => 'DateAdded',
        }, 
        {
            name => $Data->{'lang'}->txt('View'),
            field => 'View',
            type => 'HTML',
        },
         {
            name => $Data->{'lang'}->txt('Delete'),
            field => 'Delete',
            type => 'HTML',
        },
    ); 
   $allfilesgrid = showGrid(
        Data => $Data,
        columns => \@headers2,
        rowdata => $docs,
        gridid => 'allfilesgridid',
        width => '99%',
        
   ); 
   $body .= qq[
       
		<div class="sectionheader"> All Files </div> 
		$allfilesgrid
	];
    
}




   ########################################
	
	

	
	
	#my $options = '';
	#my $count = 0;
	#for my $doc (@{$docs})	{
    #$count++;
    #my $c = $count%2==0 ? 'class="rowshade"' : '';
	##	my $deleteURL = "$Data->{'target'}?client=$client&amp;a=DOC_d&amp;dID=$doc->{'ID'}";
    #$options.=qq[
    #  <tr $c>
    #   <td><a href="$doc->{'URL'}" target="_doc">$displayTitle</a></td>
    #    <td>$doc->{'Size'}Mb</td>
    #    <td>$doc->{'Ext'}</td>
    #    <td>$doc->{'DateAdded'}</td>
    #    <td>(<a href="$deleteURL" onclick="return confirm('Are you sure you want to delete this document?');">Delete</a>)</td>
    #  </tr>
    #];
	#}
	#if(!$body)	{
	#	$body .= $Data->{'lang'}->txt('There are no documents');
	#}
	#else	{
	#	$body .= qq[
	#		<table class="listTable">
	#			$options
	#		</table>
	#	];
	#}
	
	
       return $body;
}

sub new_doc_form {
	my(
		$Data, 
		$client,
        $DocumentTypeID,
		$RegistrationID,
        $memberID
	)=@_;

	my $l = $Data->{'lang'};
	my $target=$Data->{'target'} || '';
    my $fileToReplace = param('f') || 0;    
	#my $currentLevelName = $Data->{'LevelNames'}{$Data->{'clientValues'}{'authLevel'}} || 'organisation';
	#my %permoptions = (
	#    1 => $Data->{'lang'}->txt('All organisations to which this member is linked'),
	#    2 => $Data->{'lang'}->txt("Only to this $currentLevelName"),
	#    3 => $Data->{'lang'}->txt("Organisations ( $currentLevelName and above) to which this member is linked"),
	#);
	#	my $perms = drop_down("docperms",\%permoptions,undef,0,1,0);
		my $title = $l->txt('New Document');
	my $body = qq[
        <br />
	<div class="sectionheader">$title</div>
	<br />
         	<div id="docselect">
		<form action="$target" method="POST" enctype="multipart/form-data" class="dropzone">			

		<input type="hidden" name="client" value="].unescape($client).qq[">];
	if($DocumentTypeID){
		$body .= qq[
                <input type="hidden" name="DocumentTypeID" value="$DocumentTypeID" />
                <input type="hidden" name="RegistrationID" value="$RegistrationID" />];
        }

	if($memberID){
		$body .= qq[
                <input type="hidden" name="memberID" value="$memberID" />];
        }

    if($fileToReplace){ 
    	$body .= qq[
    	       <input type="hidden" name="fileId" value="$fileToReplace" />
    	];
    }
	$body .=	qq[<input type="hidden" name="a" value="DOC_u">
			
		</form> 
                <br />  
                <span class="button-small generic-button"><a href="$Data->{'target'}?client=$client&amp;a=P_DOCS">] . $Data->{'lang'}->txt('Continue').q[</a></span>
		</div>
	];
	return $body;
}


sub process_doc_upload	{
	my(
		$Data, 
		$memberID, 
		$client
	)=@_;
    
	my @files_to_process = ();
    my %clientValues = getClient($client);
	my $myCurrentValue = $clientValues{'authLevel'};
	
	my $name = param('file') || '';
	my $filefield = 'file' ;
	my $permission = param('docperms') || 1;
                              
    my $docTypeID = param('DocumentTypeID') || 0; 
    my $regoID = param('RegistrationID') || 0; 
    my $fileID = param('fileId') || 0;
   
    my $other_info = {
        docTypeID => $docTypeID,
        regoID    => $regoID,    
        replaceFileID => $fileID,    
    };
   
	push @files_to_process, [$name, $filefield, $permission];

	my $retvalue = processUploadFile(
		$Data, 
		\@files_to_process,
                $Defs::LEVEL_MEMBER,
                $memberID,
                $Defs::UPLOADFILETYPE_DOC,
                $other_info,
	);
	return $retvalue;
}

sub delete_doc {
	my($Data, $fileID, $client, $retpage)=@_;

	my $response = deleteFile(
	$Data,
    $fileID,
  );

	return qq[
          <div class="OKmsg">Successfully deleted file.</div> 
          <br />  
          <span class="button-small generic-button"><a href="$Data->{'target'}?client=$client&amp;a=$retpage">] . $Data->{'lang'}->txt('Continue').q[</a></span>
       ];
}

1;
