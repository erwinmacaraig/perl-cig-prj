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
use Data::Dumper;

sub handle_entity_documents{ 
	my($action, $Data, $entityID, $typeID, $doc_for)=@_; 
	my $resultHTML = '';
	my $DocumentTypeID = param('doclisttype') || 0;
	my $client=setClient($Data->{'clientValues'}) || '';
	
	
	#by default list out all documents 
	$resultHTML = list_entity_docs($Data, $entityID, $client, $DocumentTypeID,$typeID, $doc_for);
	if($action eq 'C_DOCS_frm'){
		  $resultHTML =  new_doc_form($Data, $client, $entityID, $DocumentTypeID); 
	}
	elsif($action eq 'C_DOCS_u' || $action eq 'VENUE_DOCS_u'){
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
	my %clientValues = getClient($client);
	my $myCurrentValue = $clientValues{'authLevel'};
  	
    my @rowdata = (); 
    my $query = qq[
        SELECT tblUploadedFiles.intFileID,
        tblDocumentType.strDocumentName,
        tblDocumentType.strLockAtLevel,
        tblUploadedFiles.dtUploaded as DateUploaded, 
        tblDocuments.strApprovalStatus FROM tblDocuments 
        INNER JOIN tblUploadedFiles ON tblDocuments.intUploadFileID = tblUploadedFiles.intFileID 
        INNER JOIN tblDocumentType ON tblDocuments.intDocumentTypeID = tblDocumentType.intDocumentTypeID
        WHERE tblDocuments.intEntityID = ? AND intPersonID = 0 AND intClearanceID = 0
    ]; 
# 

    my $sth = $db->prepare($query); 
    $sth->execute($entityID); 	
    my $urlViewButton;
	my $viewLink;
    my $replaceLink;
	# $replaceLink =   qq[ <a class="btn-main btn-view-replace" href="$Data->{'target'}?client=$client&amp;a=C_DOCS_frm&amp;f=$dref->{'intFileID'}">]. $lang->txt('Replace File'). q[</a>];
    while(my $dref = $sth->fetchrow_hashref()){
		my $url = "$Defs::base_url/viewfile.cgi?f=$dref->{'intFileID'}&amp;client=$client";
    	#check if strLockLevel is empty which means world access to the file
    	if($dref->{'strLockAtLevel'} eq ''){
    		 $urlViewButton = qq[ <a class="btn-main btn-view-replace" href = "#" onclick="docViewer($dref->{'intFileID'}, 'client=$client');return false;">]. $Data->{'lang'}->txt('View'). q[</a>];
    		#$replaceLink =   qq[ <span class="btn-inside-panels"><a href="$Data->{'target'}?client=$client&amp;a=C_DOCS_frm&amp;f=$dref->{'intFileID'}">]. $lang->txt('Replace File'). q[</a></span>]; 
			$replaceLink =   qq[ <a class="btn-main btn-view-replace" href="$Data->{'target'}?client=$client&amp;a=C_DOCS_frm&amp;f=$dref->{'intFileID'}">]. $lang->txt('Replace File'). q[</a>]    		 
    	}
    	else {
    	    my @authorizedLevelsArr = split(/\|/,$dref->{'strLockAtLevel'});
    	    if(grep(/^$myCurrentValue/,@authorizedLevelsArr)){
               	$viewLink = qq[ <span class="btn-inside-panels"><a href="$Defs::base_url/viewfile.cgi?f=$dref->{'intFileID'}&amp;client=$client" target="_blank">]. $lang->txt('Get File') . q[</a></span>];    
                $replaceLink =   qq[ <span class="btn-inside-panels"><a href="$Data->{'target'}?client=$client&amp;a=C_DOCS_frm&amp;f=$dref->{'intFileID'}">]. $lang->txt('Replace File'). q[</a></span>];
            }
            else{
            	$viewLink = qq[ <a class\"HTdisabled btn-main btn-view-replace\">]. $lang->txt('Get File') . q[</a>];    
                $replaceLink =   qq[ <a class\"HTdisabled btn-main btn-view-replace\">]. $lang->txt('Replace File'). q[</a>];
            }
    	}
    	
    	
        
   
    push @rowdata, {  
	        id => $dref->{'intFileID'} || 0,
	        strDocumentName => $dref->{'strDocumentName'},
		    strApprovalStatus => $dref->{'strApprovalStatus'},
            DateUploaded => $dref->{'DateUploaded'}, 
            ViewDoc => $urlViewButton, 
            ReplaceFile => $replaceLink,              
       };
    }
    my @headers = (
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
	
	$query = qq[
         SELECT strDocumentName, intDocumentTypeID FROM tblDocumentType WHERE strDocumentFor = ? AND intRealmID IN (0,?)
    ]; 
    $sth = $db->prepare($query);
    $sth->execute($doc_for,$Data->{'Realm'});
    my $doclisttype = qq[  <form action="$Data->{'target'}">
                              <input type="hidden" name="client" value="$client" />
                              <input type="hidden" name="a" value="C_DOCS_frm" /><label>] . $lang->txt('Add a new document to this club')
							. qq[
                              <select name="doclisttype" id="doclisttype">
                              <option value="0">Misc</option>  
                       ];
    while(my $dref = $sth->fetchrow_hashref()){
        $doclisttype .= qq[<option value="$dref->{'intDocumentTypeID'}">$dref->{'strDocumentName'}</option>];
    } 
   $doclisttype .= qq[     </select>                           
                           <input type="submit" class="btn-inside-panels pull-right" value="Go" />
                           </form>
                    ];
	
	my $modoptions=qq[<div class="changeoptions"></div>];
	
	
	$body .= qq[ 
		$modoptions	<div class="showrecoptions"> $doclisttype </div><br />
		 
		$grid 
		
		];
		
	
	# <div class="showrecoptions"> $doclisttype </div> 
	
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
		$entityID,
        $DocumentTypeID		
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
		<form action="uploadregofile.cgi" method="POST" enctype="multipart/form-data" class="dropzone">			

		<input type="hidden" name="client" value="].unescape($client).qq[">];
	if($DocumentTypeID){
		$body .= qq[
                <input type="hidden" name="doctypeID" value="$DocumentTypeID" />];
        }

    if($fileToReplace){ 
    	$body .= qq[
    	       <input type="hidden" name="f" value="$fileToReplace" />
    	]; 
    }
	$body .=	qq[
	<input type="hidden" name="entitydocs" value="1" />
	<input type="hidden" name="a" value="C_DOCS_u" />
	<input type="hidden" name="pID" value="$entityID" />
			
		</form> 
                <br />  
                <span class="btn-inside-panels"><a href="$Data->{'target'}?client=$client&amp;a=C_DOCS">] . $Data->{'lang'}->txt('Continue').q[</a></span>
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
          <span class="btn-inside-panels"><a href="$Data->{'target'}?client=$client&amp;a=C_DOCS">] . $Data->{'lang'}->txt('Continue').q[</a></span>
       ];
}

sub checkUploadedEntityDocuments {
    my ($Data, $entityID, $documents, $ctrl) = @_;   

	
	#1 check for uploaded documents present for a particular entity (required and optional)
	my $query = qq[
		SELECT distinct(tblDocuments.intDocumentTypeID), tblDocumentType.strDocumentName 
		FROM tblDocuments INNER JOIN tblDocumentType
		ON tblDocuments.intDocumentTypeID = tblDocumentType.intDocumentTypeID
		INNER JOIN tblRegistrationItem 
		ON tblDocumentType.intDocumentTypeID = tblRegistrationItem.intID
		WHERE tblDocuments.intEntityID = ?
            AND tblRegistrationItem.intRealmID=?
	];
   # ;	
	if($ctrl){
		$query .= qq[ AND tblRegistrationItem.intRequired = 1];
	}
	my $sth = $Data->{'db'}->prepare($query);
	$sth->execute($entityID, $Data->{'Realm'});
	my @uploaded_docs = ();
	while(my $dref = $sth->fetchrow_hashref()){
		push @uploaded_docs, $dref->{'intDocumentTypeID'};		
	}
	
	my @validdocsforallrego = ();
	$query = qq[SELECT tblDocuments.intDocumentTypeID FROM tblDocuments INNER JOIN tblDocumentType
				ON tblDocuments.intDocumentTypeID = tblDocumentType.intDocumentTypeID INNER JOIN tblRegistrationItem 
				ON tblDocumentType.intDocumentTypeID = tblRegistrationItem.intID 
				WHERE strApprovalStatus = 'APPROVED' AND tblDocuments.intEntityID = ? AND tblRegistrationItem.intRealmID=? AND 
				(tblRegistrationItem.intUseExistingThisEntity = 1 OR tblRegistrationItem.intUseExistingAnyEntity = 1) 
				GROUP BY intDocumentTypeID];
	$sth = $Data->{'db'}->prepare($query);
	$sth->execute($entityID, $Data->{'Realm'});

	while(my $dref = $sth->fetchrow_hashref()){
		push @validdocsforallrego, $dref->{'intDocumentTypeID'};
	}
	my @diff = ();	
	my @docos = ();	

	#2 compare whats in the system and what is required
	foreach my $doc_ref (@{$documents}){	
		next if(grep /$doc_ref->{'ID'}/, @validdocsforallrego);	
		if(!grep /$doc_ref->{'ID'}/,@uploaded_docs){
			push @diff,$doc_ref;	
			print FH "\nPushing: " . Dumper($doc_ref) . "\n";
		}		
	}
	#need to filter required docs in @diff
	return \@diff;
}


1;
