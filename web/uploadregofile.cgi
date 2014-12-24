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
use strict;

my $client = param('client') || 0;
my $regoID = param('rID') || 0;
my $uploaded_filename = param('file') || ''; 
my $docTypeID = param('doctypeID') || 0; 
my $personID = param('pID') || 0;
my $isForEntity = param('entitydocs') || 0;
my $replaceFileID = param('f') || 0;
my $fromURL = param('u') || '';

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
    $other_person_info{'docTypeID'} = $docTypeID if ($docTypeID); 
    $other_person_info{'regoID'} = $regoID if ($regoID);   
 	$other_person_info{'entitydocs'} = $isForEntity if ($isForEntity); 
	$other_person_info{'replaceFileID'} = $replaceFileID if ($replaceFileID); 

    #UploadFiles::processUploadFile(\%Data,\@files,$Defs::LEVEL_PERSON,$personID,$Defs::UPLOADFILETYPE_DOC,\%other_person_info,);   
	my $fileID = UploadFiles::processUploadFile(\%Data,\@files, $Data{'clientValues'}{'currentLevel'}, $personID,$Defs::UPLOADFILETYPE_DOC,\%other_person_info,);   

	
	$other_person_info{'f'} = $fileID;  
    if($fromURL)    {
        my $cgi = new CGI;
        print $cgi->redirect($fromURL);
    }
    else    {
        print "Content-type: text/html \n\n"; 
        my $jFileData = JSON->new->utf8->encode(\%other_person_info);
        print $jFileData;       
    }
         
}

