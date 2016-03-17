package UploadFiles;
require Exporter;
@ISA =  qw(Exporter);
@EXPORT = qw(getUploadedFiles processUploadFile allowFileAccess deleteFile deleteAllFiles);
@EXPORT_OK = qw(getUploadedFiles processUploadFile allowFileAccess deleteFile deleteAllFiles);

use strict;
use lib "..",".";
use Defs;
use Utils;

use ImageUpload;
use FileUpload;
use CGI qw(:cgi param unescape escape);
use Reg_common;

use Data::Dumper;
use InstanceOf;
use S3Upload;

my $File_MaxSize = 25*1024*1024; #25Mb;

sub getUploadedFiles	{
	my (
    $Data,
    $entityTypeID,
    $entityID,
	$fileType,
	$client,
	$page,
    ) = @_;
    
    
	$client = $Data->{'client'};
    my %clientValues = getClient($client);
    my $currLoginID = $Data->{'clientValues'}{'_intID'};
	my $myCurrentLevelValue = $clientValues{'authLevel'};
	my $obj = getInstanceOf($Data, 'entity', $currLoginID);
	
    my $locale = $Data->{'lang'}->getLocale();
	my $st = qq[
	SELECT 
        *,
         COALESCE (LT_D.strString1,tblDocumentType.strDocumentName) as strDocumentName,
         UF.strOrigFilename,
         tblPersonRegistration_$Data->{'Realm'}.intEntityID AS owner,
         DATE_FORMAT(dtUploaded, "%d/%m/%Y %H:%i") AS DateAdded_FMT,
         tblDocuments.intDocumentTypeID,
        tblDocuments.intPersonRegistrationID as regoID,
         tblDocumentType.strLockAtLevel,
         E.intEntityID as DocoEntityID,
         E.intEntityLevel as DocoEntityLevel
    FROM  tblUploadedFiles AS UF LEFT JOIN tblDocuments ON UF.intFileID = tblDocuments.intUploadFileID 
	    LEFT JOIN tblPersonRegistration_$Data->{'Realm'} On tblPersonRegistration_$Data->{'Realm'}.intPersonRegistrationID = tblDocuments.intPersonRegistrationID 
        LEFT JOIN tblDocumentType ON tblDocuments.intDocumentTypeID = tblDocumentType.intDocumentTypeID
        LEFT JOIN tblEntity as E ON (E.intEntityID=tblPersonRegistration_$Data->{'Realm'}.intEntityID)
        LEFT JOIN tblLocalTranslations AS LT_D ON (
            LT_D.strType = 'DOCUMENT'
            AND LT_D.intID = tblDocuments.intDocumentTypeID
            AND LT_D.strLocale = '$locale'
        )

	WHERE UF.intEntityTypeID = ? AND UF.intEntityID = ? AND UF.intFileType = ?
	];
	
	
	#my $st = qq[
	#	SELECT 
	#		*,
	#		DATE_FORMAT(dtUploaded,"%d/%m/%Y %H:%i") AS DateAdded_FMT
	#	FROM tblUploadedFiles AS UF
	#	WHERE
	#		intEntityTypeID = ?
	#		AND intEntityID = ?
	#		AND intFileType = ?
	#];
	my $q = $Data->{'db'}->prepare($st);
	#print $st;
	$q->execute(
		$entityTypeID,
		$entityID,
		$fileType,
	);
	my $url;
	my $deleteURL;
	my $deleteURLButton;
	my $urlViewButton;

	my @rows = ();
	while(my $dref = $q->fetchrow_hashref())	{
        $dref->{'DateAdded_FMT'} = $Data->{'l10n'}{'date'}->TZformat($dref->{'dtUploaded'},'MEDIUM','SHORT');
          my $parentCheck= authstring($dref->{'intFileID'});
		$st = qq[SELECT intUseExistingThisEntity, intUseExistingAnyEntity FROM tblRegistrationItem WHERE tblRegistrationItem.intID = ? and tblRegistrationItem.intRealmID=? AND tblRegistrationItem.strItemType='DOCUMENT'];
		my $sth = $Data->{'db'}->prepare($st);
		$sth->execute($dref->{'intDocumentTypeID'}, $Data->{'Realm'});
		my $data = $sth->fetchrow_hashref();
		#check if strLockLevel is empty which means world access to the file
#        if($dref->{'strLockAtLevel'} eq '' || $data->{'intUseExistingThisEntity'} || $data->{'intUseExistingAnyEntity'} ||$dref->{'owner'} == $currLoginID){
			$url = "$Defs::base_url/viewfile.cgi?f=$dref->{'intFileID'}&amp;client=$client";
            $url .= "&chk=". $parentCheck;
		    $deleteURL = "$Data->{'target'}?client=$client&amp;a=DOC_d&amp;dID=$dref->{'intFileID'}";
            #$deleteURL.= "&chk=". $parentCheck;
			$deleteURL .= qq[&amp;dctid=$dref->{'intDocumentTypeID'}&amp;regoID=$dref->{'regoID'}] if($dref->{'intDocumentTypeID'});
	      	$deleteURLButton = qq[ <a class="btn-main btn-view-replace" href="$deleteURL&amp;retpage=$page">]. $Data->{'lang'}->txt('Delete'). q[</a>];
            $urlViewButton = qq[ <a class="btn-main btn-view-replace" href = "#" onclick="docViewer($dref->{'intFileID'}, 'client=$client&chk=$parentCheck');return false;">]. $Data->{'lang'}->txt('View'). q[</a>];
    #}

        if($dref->{'strLockAtLevel'})   {
            if($dref->{'strLockAtLevel'} =~ /\|$Data->{'clientValues'}{'authLevel'}\|/ and getLastEntityID($Data->{'clientValues'}) != $dref->{'DocoEntityID'}){
    			$deleteURLButton = qq[ <a class="HTdisabled btn-main btn-view-replace">]. $Data->{'lang'}->txt('Delete'). q[</a>]; 
               	$urlViewButton = qq[ <a class="HTdisabled btn-main btn-view-replace">].$Data->{'lang'}->txt('View'). q[</a>];    
            }
        }
        if ($dref->{'intEntityID'} != getLastEntityID($Data->{'clientValues'}) && $Data->{'clientValues'}{'authLevel'} == $Defs::LEVEL_CLUB)    {
    	$deleteURLButton = qq[ <a class="HTdisabled btn-main btn-view-replace">]. $Data->{'lang'}->txt('Delete'). q[</a>]; 
        }
        if ($Data->{'SystemConfig'}{'stopDeleteDocos_CLUB'} && $Data->{'clientValues'}{'authLevel'} == $Defs::LEVEL_CLUB)    {
    	    $deleteURLButton = qq[ <a class="HTdisabled btn-main btn-view-replace">]. $Data->{'lang'}->txt('Delete'). q[</a>]; 
        }
        if ($Data->{'SystemConfig'}{'stopDeleteDocos_ALL'}) {
    	    $deleteURLButton = qq[ <a class="HTdisabled btn-main btn-view-replace">]. $Data->{'lang'}->txt('Delete'). q[</a>]; 
        }

			#my @authorizedLevelsArr = split(/\|/,$dref->{'strLockAtLevel'});
			#my $ownerlevel = $obj->getValue('intEntityLevel');					
			#if(grep(/^$myCurrentLevelValue/,@authorizedLevelsArr) && $myCurrentLevelValue >  $ownerlevel ){
			#	$url = "$Defs::base_url/viewfile.cgi?f=$dref->{'intFileID'}&amp;client=$client";
		    #    $deleteURL = "$Data->{'target'}?client=$client&amp;a=DOC_d&amp;dID=$dref->{'intFileID'}";
			#	$deleteURL .= qq[&amp;dctid=$dref->{'intDocumentTypeID'}&amp;regoID=$dref->{'regoID'}] if($dref->{'intDocumentTypeID'});
	        # 	$deleteURLButton = qq[ <a class="btn-main btn-view-replace" href="$deleteURL&amp;retpage=$page">]. $Data->{'lang'}->txt('Delete'). q[</a>];
            #    $urlViewButton = qq[ <a class="btn-main btn-view-replace" href = "#" onclick="docViewer($dref->{'intFileID'}, 'client=$client');return false;">]. $Data->{'lang'}->txt('View'). q[</a>];
			#}
			
		#}
		push @rows, {
			id => $dref->{'intFileID'} || 0,
			SelectLink => ' ',
			Title => $dref->{'strTitle'} || '',
			DocumentType=> $Data->{'lang'}->txt($dref->{'strDocumentName'}) || '',
			URL => $url,
			Delete => $deleteURLButton, 
			View => $urlViewButton,
			Ext => $dref->{'strExtension'} || '',
			Size => sprintf("%0.2f",($dref->{'intBytes'} /1024/1024)),
			DateAdded => $dref->{'DateAdded_FMT'},
			DateAdded_RAW => $dref->{'dtUploaded'},
			Name => $dref->{'strDocumentName'} || 'Misc',
			OrigFilename => $dref->{'strOrigFilename'},
			DB => $dref,
		};	
	}
	$q->finish();

	return \@rows;
}


sub processUploadFile	{
	my (
    $Data,
    $files_to_process,
    $EntityTypeID,
    $EntityID,
    $fileType,
    $other_info,
  ) = @_; 
      
	my $ret = '';
	my $fileID;
	for my $files (@{$files_to_process})	{ 
		 $fileID = _processUploadFile_single(
			$Data,
			$files->[0],
			$files->[1],
			$EntityTypeID,
			$EntityID,
			$fileType,
			$files->[2],
			$files->[3] || undef,
            $other_info,
		);
		#if($err)	{
		#	$ret .= "'$files->[0]' : $err<br>";
		#}
	}
	if($fileID =~ m/^(\d+)$/){
		return $1; # need to get the file id back for updating previously uploaded file
	}
  return $fileID; # contains error
}

sub _processUploadFile_single	{
	my (
		$Data,
		$title,
		$file_field,
		$EntityTypeID,
		$EntityID,
		$fileType,
		$permissions,
		$options,
        $other_info,
	) = @_;

	
	my $intFileAddedBy = $Data->{'clientValues'}{'_intID'} || getLastEntityID($Data->{'clientValues'});
	$options ||= {}; 
        my $DocumentTypeId = 0;
        my $regoID = 0; 
        my $oldFileId = 0;
        if(defined $other_info){
          $DocumentTypeId = $other_info->{'docTypeID'} || 0; 
          $regoID = $other_info->{'regoID'} || 0;
          $oldFileId = $other_info->{'replaceFileID'} || 0;                   
        }   
  
  my $origfilename=param($file_field) || '';
	$origfilename =~s/.*\///g;
	$origfilename =~s/.*\\//g;
  return ('Invalid filename',0) if !$origfilename;
  my $extension='';
  {
    my @parts=split /\./,$origfilename;
    $extension=$parts[$#parts];
  }
  my @imageextensions =(qw(jpg gif jpeg bmp png));
	my $isimage = 0;
  for my $i (@imageextensions)  {
    $isimage = 1 if $i eq lc $extension;
  }

	my $st_u = qq[
		UPDATE tblUploadedFiles
			SET 
				strFilename = ?,
				strPath = ?,
				intBytes = ?,
				strExtension = ?
			WHERE intFileID = ?
	];
	my $q_u = $Data->{'db'}->prepare($st_u);
		my $st_a = qq[
		INSERT INTO tblUploadedFiles
		(
			intFileType,
			intEntityTypeID,
			intEntityID,
			intAddedByTypeID,
			intAddedByID,
			strTitle,
			strOrigFilename,
			intPermissions,
			dtUploaded
		)
		VALUES (
			?,
			?,
			?,
			?,
			?,
			?,
			?,
			?,
			NOW()
		)

	];
	my $q_a = $Data->{'db'}->prepare($st_a);
	$q_a->execute(
		$fileType, 
        $EntityTypeID,
        $EntityID,
		$Data->{'clientValues'}{'authLevel'},
		$intFileAddedBy,
		$title,
		$origfilename,
		$permissions,
	); 
#Data->{'clientValues'}{'_intID'}
	my $fileID = $q_a->{mysql_insertid} || 0;
	$q_a->finish();
	return ('Invalid ID',0) if !$fileID; 
	my $doc_st;
	my $doc_q;
	#my $entitydocs = param('entitydocs') || 0; 
	my $entitydocs = $other_info->{'entitydocs'} if (exists $other_info->{'entitydocs'});
	# need to distinguish Person FROM other entity
	my $intPersonID = $EntityID;
	my $intEntityID = 0;
	
	if($entitydocs){ 
		$intPersonID = 0;	
		$intEntityID = $EntityID;	
		
	}
	    #### START OF INSERTING DATA IN tblDocuments ##
        if($DocumentTypeId && !$oldFileId){

		 
           $doc_st = qq[
                INSERT INTO tblDocuments ( 
                   intUploadFileID,
                   intDocumentTypeID,
                   intEntityLevel,
                   intEntityID, 
                   intPersonRegistrationID,
                   intPersonID,
                   dtLastUpdated,
                   dtAdded
                )
                VALUES (
                   ?,
                   ?,
                   ?,
                   ?,
                   ?,
                   ?,
                   NOW(),
                   NOW()
                 ) 
        ]; 
        $doc_q = $Data->{'db'}->prepare($doc_st); 
        $doc_q->execute(
              $fileID,
              $DocumentTypeId,
              $EntityTypeID,
              $intEntityID,
              $regoID,
              $intPersonID, 
        );  
        #$EntityID = memberID (this should be the case)
		 
        }
        else {
			#update for person  documents      	 
			$doc_st = qq[
        		UPDATE tblDocuments SET intUploadFileID = ?, dtLastUpdated = NOW(), strApprovalStatus = ? WHERE intUploadFileID = ?	
        	]; 

			#AND intPersonID = ?	- Remove this so entity documents can be handled accordingly since intUploadFileID will suffice

			#my $chkSQL = qq[SELECT count(intItemID) as tot FROM tblRegistrationItem INNER JOIN tblDocumentType ON tblRegistrationItem.intID = tblDocumentType.intDocumentTypeID INNER JOIN tblDocuments ON tblDocuments.intDocumentTypeID = tblDocumentType.intDocumentTypeID WHERE tblDocuments.intUploadFileID = $oldFileId AND strApprovalStatus = 'APPROVED' AND (intUseExistingThisEntity = 1 OR intUseExistingAnyEntity = 1) AND tblRegistrationItem.intRealmID=? AND tblRegistrationItem.strItemType='DOCUMENT'] ;		
			#my $newstat = 'PENDING';
			#$doc_q = $Data->{'db'}->prepare($chkSQL);
			#$doc_q->execute($Data->{'Realm'});
			#my $exists = $doc_q->fetchrow_hashref();
			#if($exists->{'tot'} > 0){
			#	 $newstat = 'APPROVED';
			#}
			
			#$doc_q->finish();

        	$doc_q = $Data->{'db'}->prepare($doc_st); 
        	$doc_q->execute(
              $fileID,    
			  'PENDING',          
              $oldFileId,              
        );
		#$intPersonID - Remove this so entity documents can be handled accordingly since intUploadFileID will suffice
        }
                
       $doc_q->finish();
       
      ##### END OF INSERTING DATA IN tblDocuments ####

      
	my $path='';
	{
		my $l=6 - length($fileID);
		my $pad_num=('0' x $l).$fileID;
		my (@nums)=$pad_num=~/(\d\d)/g;
		for my $i (0 .. $#nums-1) { 
			$path.="$nums[$i]/"; 
			if( !-d "$Defs::fs_upload_dir/files/$path") { mkdir "$Defs::fs_upload_dir/files/$path",0755; }
		}
	}
	
	my $error = '';
  if($isimage )  { #Image
    my $filename= "$Defs::fs_upload_dir/files/"."$path$fileID.jpg";
    warn("FN ".$filename);
    my %field=();
    {
      my $dimensions=$options->{'dimensions'} || '800x600';
      my $img=new ImageUpload(
        fieldname=> $file_field,
        filename=>$filename,
        maxsize=>$File_MaxSize,
        overwrite=>1,
      );
      my ($h, $w)=(0,0);
      if($img->Error()) {$error="Cannot create Upload object".$img->Error();}
      else  {
        my $ret=$img->ImageManip(Dimensions=>$dimensions);
        if($ret)  { $error=$img->Error(); }
        ($w, $h) =$img->Dimensions();
      }
			$q_u->execute(
				$fileID,
				$path,
				$img->Size(),
				'jpg',
				$fileID,
			);
      putFileToS3("$path$fileID".'.jpg',$filename);
    }
  }
  else { #File
    my $filename= "$Defs::fs_upload_dir/files/$path$fileID";
    my %field=();
    my $file=new FileUpload(
        fieldname => $file_field,
        filename => $filename,
        overwrite=>1,
        useextension=>1,
        maxsize=>$File_MaxSize,
    );
    my $ret=$file->get_upload();
    if($ret)  { $error=$file->Error(); }
    if(!$error) {
 			$q_u->execute(
				$fileID,
				$path,
				$file->Size(),
        $file->Ext(),
				$fileID,
			);
      putFileToS3("$path$fileID".'.'.$file->Ext(),$filename.'.'.$file->Ext());
    }
  }
	if($error)	{
		#Remove file
		deleteFile( $Data, $fileID);
		return $error;
	}
	return $fileID;
}

sub deleteAllFiles	{
	my(
		$Data,
		$entityTypeID,
		$entityID,
		$fileType,
	) = @_;

	my $st = qq[
		SELECT intFileID
		FROM tblUploadedFiles AS UF
		WHERE
			intEntityTypeID = ?
			AND intEntityID = ?
			AND intFileType = ?
	];
	my $q = $Data->{'db'}->prepare($st);
	$q->execute(
		$entityTypeID,
		$entityID,
		$fileType,
	);
	while(my $dref = $q->fetchrow_hashref())	{
		deleteFile($Data , $dref->{'intFileID'});
	}
}

sub deleteFile	{
	my(
		$Data,
		$fileID,
	) = @_;

    return 0 if (!$fileID);
	my $st = qq[
		SELECT * 
		FROM tblUploadedFiles
		WHERE intFileID = ?
	];
	my $q = $Data->{'db'}->prepare($st);
	$q->execute(
		$fileID,
	);
	my $dref = $q->fetchrow_hashref();
	$q->finish();

	my $allowedaccess = allowFileAccess($Data, $dref);
	if($allowedaccess)	{

		my @tobedeleted=();
    my $filename= "$Defs::fs_upload_dir/files/$dref->{'strPath'}$dref->{'strFilename'}.$dref->{'strExtension'}";
        my $key = "$dref->{'strPath'}$dref->{'strFilename'}.$dref->{'strExtension'}";
		push @tobedeleted, $filename;
		unlink @tobedeleted;
        deleteFromS3($key);
	
		my $st_d = qq[
			DELETE FROM tblUploadedFiles
			WHERE intFileID = ?
		];
		my $q_d = $Data->{'db'}->prepare($st_d);
		$q_d->execute(
			$fileID,
		);

                ### DELETE FROM tblDocuments ###
				
				    $st_d = qq[ DELETE FROM tblDocuments WHERE intUploadFileID = ?]; 
    	            $q_d = $Data->{'db'}->prepare($st_d);
    	            $q_d->execute( $fileID, );
    	            ## END DELETE FROM tblDocuments ### 
				
		$q_d->finish();
		return 1;
	}
	return 0;
}


sub allowFileAccess {
	my (
		$Data,
		$FileData,
	) = @_;

	my $LoginEntityTypeID = $Data->{'clientValues'}{'authLevel'};
	my $LoginEntityID = $Data->{'clientValues'}{'_intID'};
	my $permission = $FileData->{'intPermissions'} || 0;
	my $filetype = $FileData->{'intFileType'} || 0;
	if(
		$filetype == $Defs::UPLOADFILETYPE_PRODIMAGE
		or $filetype == $Defs::UPLOADFILETYPE_LOGO)	{
		return 1; #Not protected
	}
	#Permission options
	#1 = Available to Everyone
    #2 = Available to only the person adding it
    #3 = Available to all bodies at add level and above to which the entity is lnked
	return 1 if $permission == 1;
	if($permission == 2)	{
		return 1 if(
			$FileData->{'intAddedByTypeID'} == $LoginEntityTypeID	
			and $FileData->{'intAddedByID'} == $LoginEntityID	
		);	
		return 0;
	}
	if($permission == 3)	{
		return 1 if $LoginEntityTypeID >= $FileData->{'intAddedByTypeID'};
		return 0;
	}

	return 0;
}


1;
