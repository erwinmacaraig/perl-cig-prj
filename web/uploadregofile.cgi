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

use strict;
print "Content-type: text/html \n\n"; 

my $client = param('client') || 0;
my $regoID = param('rID') || 0;
my $uploaded_filename = param('file') || ''; 
my $docTypeID = param('doctypeID') || 0; 
my $personID = param('pID') || 0;
  

my $db=connectDB();
my %Data=();
$Data{'db'}=$db;

    my %clientValues = getClient($client);
    $Data{'clientValues'} = \%clientValues;
    ( $Data{'Realm'}, $Data{'RealmSubType'} ) = getRealm( \%Data );
     my $lang   = Lang->get_handle('', $Data{'SystemConfig'}) || die "Can't get a language handle!";



	if($uploaded_filename ne ''){  
		my $filefield = 'file';  
        my $permission = 1; 
        my @files = (
	        [$uploaded_filename, $filefield, $permission,],
    );  
    my %other_person_info = ();
    $other_person_info{'docTypeID'} = $docTypeID; 
    $other_person_info{'regoID'} = $regoID;    
    UploadFiles::processUploadFile(\%Data,\@files,$Defs::LEVEL_PERSON,$personID,$Defs::UPLOADFILETYPE_DOC,\%other_person_info,);             
         
}

