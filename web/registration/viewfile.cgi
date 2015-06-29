#!/usr/bin/perl 

#
# $Header: svn://svn/SWM/trunk/web/getfile.cgi 10409 2014-01-10 06:01:24Z dhanslow $
#

use strict;
use warnings;
use CGI qw(param);
use lib '.', '..', '../..';
use Defs;
use Reg_common;
use Utils;
use Lang;
use UploadFiles;
use S3Upload;

main();	

sub main {
	# GET INFO FROM URL
  my $client = param('client') || '';
  my $fileID = param('f') || 0;
  my $download = param('d') || 0;
                                                                                                        
  my %Data=();
  $fileID =~ /^(\d+)$/;
  $fileID = $1;	
  #my $db = connectDB();

  my %clientValues = getClient($client);
  $Data{'clientValues'} = \%clientValues;
  $Data{'cache'}  = new MCache();
  my $db=connectDB();
    $Data{'db'} = $db;
  ($Data{'Realm'},$Data{'RealmSubType'})=getRealm(\%Data);
    $Data{'Realm'} ||= 1;

  my $statement=qq[
	SELECT *
	FROM tblUploadedFiles
	WHERE intFileID = ?
  ];
  my $query = $db->prepare($statement);
  $query->execute($fileID);
  my $dref =$query->fetchrow_hashref();
  $query->finish();
  disconnectDB($db);
  my $file='';
  if($Defs::aws_upload_bucket)    {
      my $key= "$dref->{'strPath'}$dref->{'strFilename'}.$dref->{'strExtension'}";
      $file = getFileFromS3($key);
  }
  else    {
      my $filename= "$Defs::fs_upload_dir/files/$dref->{'strPath'}$dref->{'strFilename'}.$dref->{'strExtension'}";
      open (FILE, "<$filename");
      while(<FILE>)  { $file.= $_; }
      close (FILE);
  }

  my $size = $dref->{'intBytes'} || 0;
  my $contenttype ='';
  my $ext = $dref->{'strExtension'} || '';
  my $origfilename = $dref->{'strOrigFilename'} || '';
  if($ext eq 'jpg') {
	$contenttype = 'image/jpeg';
  }
  elsif($ext eq 'pdf') {
	$contenttype = 'application/pdf';
  }
  elsif($ext eq 'txt')  {
	$contenttype = 'text/html';
  }
  else  {
	$contenttype = 'application/download';
  }
  $origfilename =~s/.*\///g;
  $origfilename =~s/.*\\//g;
  print "Content-type: $contenttype\n";
  print "Content-length: $size\n";
  print "Content-transfer-encoding: $size\n";
  if($download) {
      print qq[Content-disposition: attachment; filename = "$origfilename"\n\n];
  }
  else  {
      print qq[Content-disposition: inline; filename = "$origfilename"\n\n];
  }
  print $file;
  
}
