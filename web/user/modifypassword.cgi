#!/usr/bin/perl -w
use DBI;
use CGI qw(:cgi escape unescape);

use strict;

use lib ".", "..", "../..", "user";

use Defs;
use Utils;
use PageMain;
use Lang;
use TTTemplate;
use UserObj;

my %Data = (); 
my $lang = Lang->get_handle() || die "Can't get a language handle!";
$Data{lang} = $lang;
my $target = 'modifypassword.cgi';
$Data{'target'} = $target;
$Data{'cache'}  = new MCache();
$Data{uId} = '';
my $body = '';

#check first for existing parameter 
my $url_key = param('url_key') || '';
my $uId = isURL_Key_Valid($url_key);
if(defined ($uId)){
     $Data{uId} = $uId;
}

my $template = 'user/modify_user_password.templ';  

$body = runTemplate(
    \%Data,
    {},
    $template,
); 

my $title = 'Modify Password'; 

pageForm(
	$title,
	$body,
	{},
	'',
	\%Data,
);
