#!/usr/bin/perl -w

use lib '.','..';
use Defs;
use CGI qw(:cgi escape unescape);

use Lang;
use Utils;
use Reg_common;
use DeQuote;
use UploadFiles;
use MD5;
use Data::Dumper;
use JSON;
use UploadFiles;
use strict;
print "Content-type: text/html \n\n"; 

my $client = param('client') || 0;
my $regoID = param('rID') || 0;
my $docTypeID = param('doctypeID') || 0; 
my $fileID = param('f') || 0;

my $db=connectDB();
my %Data=();
$Data{'db'}=$db;
my %clientValues = getClient($client);
$Data{'clientValues'} = \%clientValues;
( $Data{'Realm'}, $Data{'RealmSubType'} ) = getRealm( \%Data );
my $lang   = Lang->get_handle('', $Data{'SystemConfig'}) || die "Can't get a language handle!";

my %hash_message = ();
UploadFiles::deleteFile(\%Data,$fileID);






