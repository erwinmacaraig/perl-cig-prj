#!/usr/bin/perl -w
use strict;
use warnings;
use lib ".", "..", "../..";
use CGI qw(param unescape escape); 
my $File_MaxSize = 4*1024*1024; #4Mb;

use ImageUpload;
use FileUpload;
use Utils;
use S3Upload;
my $dbh = connectDB(); 

my $fileType = param('Filetype');
my $EntityTypeID = param('EntityTypeID') || ''; 
my $EntityID = param('EntityID') || ''; 
my $intAddedByTypeID = param('AddedByTypeID') || '';
my $intAddedBy = param('AddedBy');
my $transferdocfilename = param('file') || '';
my $ClearanceID = param('ClearanceID') || '';

my $options ||= {}; 

$transferdocfilename =~s/.*\///g;
$transferdocfilename =~s/.*\\//g;
exit if !$transferdocfilename; 

 my $extension='';
{
    my @parts=split /\./,$transferdocfilename;
    $extension=$parts[$#parts];
}
my @imageextensions =(qw(jpg gif jpeg bmp png ));
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
my $q_u = $dbh->prepare($st_u); 

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
			1,
			NOW()
		)

	];
	my $q_a = $dbh->prepare($st_a);
	$q_a->execute($fileType,
	              $EntityTypeID,
	              $EntityID,
	              $intAddedByTypeID,
	              $intAddedBy,
	              $transferdocfilename,
	              $transferdocfilename,
	              );
	my $fileID = $q_a->{mysql_insertid} || 0;
	$q_a->finish();
    exit if !$fileID; 
    my $doc_st;
    my $doc_q; 
    $doc_st = qq[
                INSERT INTO tblDocuments ( 
                   intUploadFileID,                   
                   intEntityLevel,
                   intEntityID,                   
                   intPersonID,
                   intClearanceID,
                   dtAdded
                )
                VALUES (
                   ?,
                   ?,
                   ?,
                   ?,
                   ?,
                   NOW()
                 ) 
        ]; 
        $doc_q = $dbh->prepare($doc_st); 
        $doc_q->execute(
              $fileID,
              $EntityTypeID,
              $intAddedBy,
              $EntityID,
              $ClearanceID 
        );  
    
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
	if($isimage ){ #Image
    my $filename= "$Defs::fs_upload_dir/files/"."$path$fileID.jpg";
    my %field=();
    {
      my $dimensions=$options->{'dimensions'} || '800x600';
      my $img=new ImageUpload(
        fieldname=> 'file',
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
			
    }   ##end %field

  }
  ### here
  else { #File
    my $filename= "$Defs::fs_upload_dir/files/$path$fileID";
    my %field=();
    my $file=new FileUpload(
        fieldname => 'file',
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
  } #end else File
  ### ends here
	if($error)	{
		#Remove file
		#deleteFile( $Data, $fileID);
	}
	

	
    
    
print "Contenttype: text/html\n\n";
