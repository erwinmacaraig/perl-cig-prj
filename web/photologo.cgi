#!/usr/bin/perl 
use strict;
use warnings;
use CGI qw(param);
use lib "..",".";
use Defs;
use Reg_common;
use Utils;
use Lang;
use Logo;
use MCache;
use S3Upload;

main();	

sub main	{
	# GET INFO FROM URL
  my $client = param('client') || '';
  my $fileID = param('f') || 0;
                                                                                                        
  my %Data=();
  my $lang= Lang->get_handle() || die "Can't get a language handle!";
  $Data{'lang'}=$lang;
  my $target='main.cgi';
  $Data{'target'}=$target;
  $Data{'cache'}  = new MCache();
  my %clientValues = getClient($client);
  $Data{'clientValues'} = \%clientValues;

  # AUTHENTICATE
  my $db=allowedTo(\%Data);
	
	if($db)	{
        my $dref = getLogoData(
            \%Data,
            $clientValues{'currentLevel'},
            getID(\%clientValues)
        );
		if($dref)   {
            my $file='';
            if($Defs::aws_upload_bucket)    {
                my $key= "$dref->{'strPath'}$dref->{'strFilename'}.$dref->{'strExtension'}";
                $file = getFileFromS3($key);
            }
            else    {
                my $filename= "$Defs::fs_upload_dir/logo/$dref->{'strPath'}$dref->{'strFilename'}.$dref->{'strExtension'}";
                open (FILE, "<$filename");
                while(<FILE>)  { $file.= $_; }
                close (FILE);
            }
			my $size = length($file) || 0;
			my $contenttype ='';
			my $ext = $dref->{'strExtension'} || '';
			my $origfilename = 'logo.'.$ext;
			if($ext eq 'jpg') {
				$contenttype = 'image/jpeg';
			}
			elsif($ext eq 'png') {
				$contenttype = 'image/png';
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
			print qq[Content-disposition: attachement; filename = "$origfilename"\n\n];
			print $file;
		}
		else	{ print "Content-type: text/html\n\n";}
	}
	else	{ print "Content-type: text/html\n\n";}
}
