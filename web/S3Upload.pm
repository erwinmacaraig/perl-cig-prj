package S3Upload;
require Exporter;
@ISA =  qw(Exporter);
@EXPORT = qw(putFileToS3 getFileFromS3 deleteFromS3 copyFileInS3);
@EXPORT_OK = qw(putFileToS3 getFileFromS3 deleteFromS3 copyFileInS3);

use strict;
use lib "..",".";
use Defs;
use Utils;

use Net::Amazon::S3;
use Net::Amazon::S3::Client;

sub _getS3 {

  return undef if !$Defs::aws_access_key_id;
  return undef if !$Defs::aws_secret_access_key;
  my $client = eval {
    my $s3 = Net::Amazon::S3->new(
      aws_access_key_id     => $Defs::aws_access_key_id,
      aws_secret_access_key => $Defs::aws_secret_access_key,
      host                  => $Defs::aws_s3_endpoint || 's3-eu-west-1.amazonaws.com',
      retry                 => 1,
    );
    return undef if !$s3;
    my $client = Net::Amazon::S3::Client->new( s3 => $s3 );
    return $client;
  };
  if($@)  {
    return undef;
  }
    return $client;
}

sub _getS3bucket {

  my $s3 = _getS3();
  return undef if !$s3;
  if($Defs::aws_upload_bucket) {
    my $bucket = eval {
      my $bucket = $s3->bucket( name => $Defs::aws_upload_bucket);
      return $bucket;
    };
    if($@)  {
      warn("bucket error".$@);
      return undef;
    }
    return $bucket if $bucket;
  }
  return undef;
}


sub putFileToS3 {
  my ($keyname, $localfile) = @_;

  my $s3 = _getS3();
  my $bucket = _getS3bucket();
  return undef if !$bucket;
  return undef if !$keyname;
  return undef if !$localfile;
  my ($extension) = $localfile =~/.*\.(.*?)/;
  my $contenttype = '';
  if(
    lc($extension) eq 'jpg'
    or lc($extension) eq 'jpeg'
    )   {
        $contenttype = 'image/jpeg';
  }
  elsif( lc($extension) eq 'png' )   {
        $contenttype = 'image/png';
  }
  elsif( lc($extension) eq 'pdf' )   {
        $contenttype = 'application/pdf';
  }
  eval {
    my $object = $bucket->object( 
          key => $keyname ,
          content_type => $contenttype,
    );
    $object->put_filename($localfile);
  };
  if($@)  {
    warn("Error in s3 put:".$@);
    return 0;
  }
  else  {
    #warn("file uploaded");
    eval {
      unlink($localfile); 
    };
    if($@)  {
      warn("Error in unlink:".$@);
    }
  }
  return 1;
}

sub getFileFromS3 {
  my ($keyname, $filename) = @_;

  $filename ||= '';
  my $s3 = _getS3();
  my $bucket = _getS3bucket();
  return undef if !$bucket;
  return undef if !$keyname;
  my $content = eval {
    my $object = $bucket->object( 
          key => $keyname,
    );
    if($filename)   {
        $object->get_filename($filename);
        return 1;
    }
    return $object->get();
  };
  if($@)  {
    warn("Error in s3 get:".$@);
    return 0;
  }
  else  {
    return $content || '';
  }
  return '';
}

sub deleteFromS3 {
  my ($keyname) = @_;

  my $s3 = _getS3();
  my $bucket = _getS3bucket();
  return undef if !$bucket;
  return undef if !$keyname;
  my $content = eval {
    my $object = $bucket->object( 
          key => $keyname,
    );
    return $object->delete();
  };
  if($@)  {
    warn("Error in s3 delete:".$@);
    return 0;
  }
  return '';
}

sub copyFileInS3 {
  my ($srcKeyname, $dstKeyname) = @_;

  my $s3 = _getS3();
  my $bucket = _getS3bucket();

  my $content = eval {
    my $srcObj = $bucket->object( 
          key => $srcKeyname,
    );
    my $dstObj = $bucket->object( 
          key => $dstKeyname,
    );
    $dstObj->put($srcObj->get());
  };
  if($@)  {
    warn("Error in s3 copy:".$@);
    return 0;
  }
  return 1;
}


1;
