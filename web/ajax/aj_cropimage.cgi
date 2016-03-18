#!/usr/bin/perl 

use strict;
use warnings;
#use lib "..",".","../..";
use lib '.', '..', '../..',"../comp", '../RegoForm', "../dashboard", "../RegoFormBuilder",'../PaymentSplit', "../user", "../Clearances";
use CGI qw(param);
use Defs;
use Localisation;
use Reg_common;
use Utils;
use JSON;
use Lang;
use MCache;
use SystemConfig;
use Image::Magick;
use S3Upload;
use File::Temp qw/ tempfile /;

main();	

sub main	{
	# GET INFO FROM URL
    my $client = param('client') || '';
    my $fileID = param('f') || 0;
    my $height = param('height') || 0;
    my $width = param('width') || 0;
    my $rotate = param('rotate') || 0;
    my $scaleX = param('scaleX') || 0;
    my $scaleY = param('scaleY') || 0;
    my $box_x = param('x') || 0;
    my $box_y = param('y') || 0;

    my $check= param('chk') || 0;

    my $checkhash = authstring($fileID);
    if ($check ne $checkhash) {
      print "ERROR";
      return;
    }

    my %Data=();
    my $target='aj_cropimage.cgi';
    $Data{'target'}=$target;
    $Data{'cache'}  = new MCache();
    my %clientValues = getClient($client);
    $Data{'clientValues'} = \%clientValues;
    my $lang = Lang->get_handle('', $Data{'SystemConfig'}) || die "Can't get a language handle!";
    $Data{'lang'}=$lang;

    my $db = allowedTo( \%Data );
    $Data{'db'} = $db;
    ($Data{'Realm'}, $Data{'RealmSubType'}) = getRealm(\%Data);
    $Data{'Realm'} ||= 1;

    $Data{'SystemConfig'} = getSystemConfig( \%Data );

    my $options = undef;
    my $error = '';
	  if($db)	{
      my $fileInfo = getFileInfo(\%Data, $fileID);
      if($fileInfo) {
        my ($fh, $tempfilename) = tempfile();
        my $filekey = $fileInfo->{'strPath'} . $fileInfo->{'strFilename'} . '.' . $fileInfo->{'strExtension'};
        getFileFromS3($filekey,$tempfilename);
        close $fh;
        if($rotate) {
          $error = rotate_photo($tempfilename, $rotate);
        }
        if(!$error) {
          $error = crop_photo(
              $tempfilename,
              $height,
              $width,
              $box_x,
              $box_y,
              $scaleX,
              $scaleY,
              $fileID,
          );
        }
        if(!$error) {
          updateSize(\%Data, $fileID, (stat($tempfilename))[7]);
          putFileToS3($filekey,$tempfilename);
        }
        unlink $tempfilename;
      }
	}

  my %jsondata = ();
  if($error)    {
    %jsondata = (
        error => $error,
    );
  }
  else  {
    %jsondata = (
        success => 1,
        results => 1,
    );
  }
  my $json = to_json(\%jsondata);
  print "Content-type: application/x-javascript\n\n$json";
}

sub rotate_photo	{
	my($tempfilename, $rotation)=@_;

	my $error='';
	my $q = Image::Magick->new;
	{
		my $x= $q->Read($tempfilename);
		$error="Bad Image Type in Read :$x" if $x;
	}
	if(!$error)	{
		my $x = $q->Rotate(degrees => $rotation);
		$error="Bad Rotate:$x" if $x;
	}
	if(!$error)	{
		my $x = $q->Write($tempfilename);
		$error="Bad Write:$x" if $x;
	}
  return $error || '';
}

sub crop_photo	{
  my(
    $tempfilename,
    $height,
    $width,
    $box_x,
    $box_y,
    $scaleX,
    $scaleY,
    $fileID,
  ) = @_;

	my $error='';
	my $q = Image::Magick->new;
	{
		my $x= $q->Read($tempfilename);
		$error="Bad Image Type in Read :$x" if $x;
	}
	if(!$error)	{
		my $x = $q->Crop(geometry => $width.'x'.$height, x=>$box_x, y=>$box_y);
		$error="Bad Crop:$x" if $x;
	}
	if(!$error)	{
		my $x = $q->Write($tempfilename);
		$error="Bad Write:$x" if $x;
	}
  return $error || '';
}

sub updateSize  {
    my ($Data, $fileID, $size) = @_;

    my $st = qq[
        UPDATE 
            tblUploadedFiles
        SET 
            intBytes = ?
        WHERE
            intFileID = ?
    ];
    my $q = $Data->{'db'}->prepare($st);
    $size ||= 0;
    $q->execute(
        $size,
        $fileID,
    );
    $q->finish();

    return 1;
}


sub getFileInfo {
    my ($Data, $fileID) = @_;

    my $st = qq[
        SELECT
          intFileType,
          intEntityTypeID,
          intEntityID,
          strPath,
          strFilename,
          strExtension,
          intBytes
        FROM
            tblUploadedFiles
        WHERE
            intFileID = ?
    ];
    my $q = $Data->{'db'}->prepare($st);
    $q->execute(
        $fileID,
    );
    my $dref = $q->fetchrow_hashref();
    $q->finish();
    return ($dref || undef);
}
