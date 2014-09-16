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
use GridDisplay;

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
	#replace documents here
	
	return $resultHTML;
}

sub list_entity_docs{
	my($Data, $entityID, $client, $DocumentTypeID, $typeID, $doc_for )=@_;
	my $target=$Data->{'target'} || '';
	my $lang = $Data->{'lang'};
	my $db = $Data->{'db'};
    my @rowdata = (); 
    my $query = qq[
        SELECT tblUploadedFiles.intFileID,
        tblDocumentType.strDocumentName,
        tblUploadedFiles.dtUploaded as DateUploaded, 
        tblDocuments.strApprovalStatus FROM tblDocuments 
        INNER JOIN tblUploadedFiles ON tblDocuments.intUploadFileID = tblUploadedFiles.intFileID 
        INNER JOIN tblDocumentType ON tblDocuments.intDocumentTypeID = tblDocumentType.intDocumentTypeID
        WHERE tblDocuments.intEntityID = ? AND intPersonID = 0 AND intClearanceID = 0
    ]; 
    my $sth = $db->prepare($query); 
    $sth->execute($entityID); 
    while(my $dref = $sth->fetchrow_hashref()){
    my $viewLink = qq[ <span class="button-small generic-button"><a href="$Defs::base_url/viewfile.cgi?f=$dref->{'intFileID'}" target="_blank">]. $lang->txt('Get File') . q[</a></span>];    
    my $replaceLink =   qq[ <span class="button-small generic-button"><a href="$Data->{'target'}?client=$client&amp;a=C_DOCS_frm&amp;f=$dref->{'intFileID'}">]. $lang->txt('Replace File'). q[</a></span>];    
     push @rowdata, {  
	        id => $dref->{'intFileID'} || 0,
	        SelectLink => ' ',
	        strDocumentName => $dref->{'strDocumentName'},
		    strApprovalStatus => $dref->{'strApprovalStatus'},
            DateUploaded => $dref->{'DateUploaded'}, 
            ViewDoc => $viewLink, 
            ReplaceFile => $replaceLink,              
       };
    }
    my @headers = (
        { 
            type => 'Selector',
            field => 'SelectLink',
        }, 
        {
            name => $lang->txt('Type'),
            field => 'strDocumentName',
        }, 
        {
            name => $lang->txt('Status'),
            field => 'strApprovalStatus',
        },
        {
            name => $lang->txt('Date Uploaded'),
            field => 'DateUploaded',
        }, 
        {
            name => $lang->txt('View'),
            field => 'ViewDoc',
            type => 'HTML', 
        },
        {
        	name => $lang->txt('Replace'),
        	field => 'ReplaceFile', 
        	type => 'HTML',
        },
    ); 
    my $filterfields = [
        {
            field     => 'strApprovalStatus',
            elementID => 'dd_actstatus',
            allvalue  => 'ALL',
        },
    ];
  
    #### GRID  #### 
    my $grid = showGrid(
        Data => $Data,
        columns => \@headers,
        rowdata => \@rowdata,
        gridid => 'grid',
        width => '99%',
        
   ); 
    
    
  
	
	my $title = $lang->txt('Documents');
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
	
	my $modoptions=qq[<div class="changeoptions"></div>];
	
	
	$body .= qq[ 
		$modoptions
		<div class="showrecoptions"> $doclisttype </div> 
		$grid
		
		];
	
	#device a lookup table for different entities - leave it as static (C_DOCS) for now
	
	my $docs = getUploadedFiles(
		$Data,
		$typeID,	
		$entityID,
		$Defs::UPLOADFILETYPE_DOC,
		$client,
		'C_DOCS',
	); 
    my $allfilesgrid = '';
	if(defined $docs->[0]->{'id'}){
		my @headers2 = (
		{ 
            type => 'Selector',
            field => 'SelectLink',
        }, 
		{
			name => $lang->txt('Title'),
			field => 'Title',
		},
       {
            name => $lang->txt('Size (MB)'),
            field => 'Size',
        }, 
        {
            name => $lang->txt('Extension Name'),
            field => 'Ext',
        },
        {
            name => $lang->txt('Date Uploaded'),
            field => 'DateAdded',
        }, 
        {
            name => $lang->txt('View'),
            field => 'View',
            type => 'HTML',
        },
         {
            name => $lang->txt('Delete'),
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
        <br /><br />
		<div class="sectionheader"> All Files </div> 
		$allfilesgrid
	];
} 
	
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
	my $title = $l->txt('New Document'); 
	#. "Current LEvel:  $Data->{'clientValues'}{'currentLevel'}"
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
	$body .=	qq[
	<input type="hidden" name="entitydocs" value=" " />
	<input type="hidden" name="a" value="C_DOCS_u">
			
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
   # REFER TO Defs file ACCESS LEVEL CODES section for implementing dynamic link
   # appropriate for the button for now leaving the link URL 
	return qq[
          <div class="OKmsg">Successfully deleted file.</div> 
          <br />  
          <span class="button-small generic-button"><a href="$Data->{'target'}?client=$client&amp;a=C_DOCS">] . $Data->{'lang'}->txt('Continue').q[</a></span>
       ];
}



1;