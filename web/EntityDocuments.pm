package EntityDocuments;
require Exporter;
@ISA =  qw(Exporter);
@EXPORT = qw(handle_entity_documents);
@EXPORT_OK = qw(handle_entity_documents);

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

sub handle_entity_documents{ 
	my($action, $Data, $entityID, $typeID, $doc_for)=@_; 
	my $resultHTML = '';
	my $DocumentTypeID = param('doclisttype') || 0;
	my $client=setClient($Data->{'clientValues'}) || '';
	
	
	#by default list out all documents 
	$resultHTML = list_entity_docs($Data, $entityID, $client, $DocumentTypeID,$typeID, $doc_for);
	if($action eq 'C_DOCS_frm'){
		  $resultHTML =  new_doc_form($Data, $client, $DocumentTypeID); 
	}
	elsif($action eq 'C_DOCS_u'){
		my $retvalue = process_doc_upload( 
			$Data,
			$entityID, 
			$client,
		);
		$resultHTML = qq[<div class="warningmsg">$retvalue</div>] if $retvalue;
		my $type = 'Add Document'; 
	}
	return $resultHTML;
}

sub list_entity_docs{
	my($Data, $entityID, $client, $DocumentTypeID, $typeID, $doc_for )=@_;
	my $target=$Data->{'target'} || '';
	my $lang = $Data->{'lang'};
	my $db = $Data->{'db'};
        
	my $docs = getUploadedFiles(
		$Data,
		$typeID,	
		$entityID,
		$Defs::UPLOADFILETYPE_DOC,
		$client,
	); 
	
	my $title = $lang->txt('Files');
	my $body = qq[<br /><div class="pageHeading">$title</div>];
	my $options = '';
	my $count = 0;
	
	my $query = qq[
         SELECT strDocumentName, intDocumentTypeID FROM tblDocumentType WHERE strDocumentFor = ? AND intRealmID IN (0,?)
    ]; 
    my $sth = $db->prepare($query);
    $sth->execute($doc_for,$Data->{'Realm'});
    my $doclisttype = qq[  <form action="$Data->{'target'}">
                              <input type="hidden" name="client" value="$client" />
                              <input type="hidden" name="a" value="C_DOCS_frm" />
                              <label>Add File For</label>  
                              <select name="doclisttype" id="doclisttype">
                              <option value="0">Misc</option>  
                       ];
    while(my $dref = $sth->fetchrow_hashref()){
        $doclisttype .= qq[<option value="$dref->{'intDocumentTypeID'}">$dref->{'strDocumentName'}</option>];
    } 
   $doclisttype .= qq[     </select> 
                          
                           <input type="submit" class="button-small generic-button" value="Go" />
                           </form>
                    ];
	
	# <input type="hidden" value="$personRegistrationID" name="RegistrationID" />
	for my $doc (@{$docs})	{
    $count++;
    my $c = $count%2==0 ? 'class="rowshade"' : '';
		my $displayTitle = $doc->{'Title'} || 'Untitled Document';
		my $deleteURL = "$Data->{'target'}?client=$client&amp;a=DOC_d&amp;dID=$doc->{'ID'}";
    $options.=qq[
      <tr $c>
        <td><a href="$doc->{'URL'}" target="_doc">$displayTitle MemberID = $entityID</a></td>
        <td>$doc->{'Size'}Mb</td>
        <td>$doc->{'Ext'}</td>
        <td>$doc->{'DateAdded'}</td>
        <td>(<a href="$deleteURL" onclick="return confirm('Are you sure you want to delete this document?');">Delete</a>)</td>
      </tr>
    ];
	}

	if(!$body)	{
		$body .= $Data->{'lang'}->txt('There are no documents');
	}
	else	{
		
		
		
		$body .= qq[
		$doclisttype EntityID: $entityID
			<table class="listTable">
				$options
			</table>
		];
	}
	#$body .= new_doc_form($Data, $client,$DocumentTypeID,$RegistrationID); 
	
       return $body;
} #end sub

sub new_doc_form {
	my(
		$Data, 
		$client,
        $DocumentTypeID,
		$RegistrationID,
	)=@_;

	my $l = $Data->{'lang'};
	my $target=$Data->{'target'} || '';
    my $fileToReplace = param('f') || 0;    
	my $title = $l->txt('New Document'). "Current LEvel:  $Data->{'clientValues'}{'currentLevel'}";
	my $body = qq[
        <br />
	<div class="sectionheader">$title</div>
	<br />
         	<div id="docselect">
		<form action="$target" method="POST" enctype="multipart/form-data" class="dropzone">			

		<input type="hidden" name="client" value="].unescape($client).qq[">];
	if($DocumentTypeID){
		$body .= qq[
                <input type="hidden" name="DocumentTypeID" value="$DocumentTypeID" />];
        }

    if($fileToReplace){ 
    	$body .= qq[
    	       <input type="hidden" name="fileId" value="$fileToReplace" />
    	];
    }
	$body .=	qq[<input type="hidden" name="a" value="C_DOCS_u">
			
		</form> 
                <br />  
                <span class="button-small generic-button"><a href="$Data->{'target'}?client=$client&amp;a=C_DOCS">] . $Data->{'lang'}->txt('Continue').q[</a></span>
		</div>
	];
	return $body;
}


sub process_doc_upload	{
	my(
		$Data, 
		$entityID, 
		$client
	)=@_;

	my @files_to_process = ();

		my $name = param('file') || '';
		my $filefield = 'file' ;
		my $permission = param('docperms') || 1;
                              
                my $docTypeID = param('DocumentTypeID') || 0; 
                my $fileID = param('fileId') || 0;
                my $other_entity_info = {
                	docTypeID => $docTypeID,
                    replaceFileID => $fileID,    
               };
		push @files_to_process, [$name, $filefield, $permission];
                	
	my $retvalue = processUploadFile(
		$Data, 
		\@files_to_process,
                $Data->{'clientValues'}{'currentLevel'},
                $entityID,
                $Defs::UPLOADFILETYPE_DOC,
                $other_entity_info,
	);
	return $retvalue;
}

sub delete_doc {
	my($Data, $fileID, $client)=@_;

	my $response = deleteFile(
		$Data,
    $fileID,
  );

	return qq[
          <div class="OKmsg">Successfully deleted file.</div> 
          <br />  
          <span class="button-small generic-button"><a href="$Data->{'target'}?client=$client&amp;a=P_DOCS">] . $Data->{'lang'}->txt('Continue').q[</a></span>
       ];
}



1;