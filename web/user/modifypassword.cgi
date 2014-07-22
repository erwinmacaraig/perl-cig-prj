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
my $body = '';
my $template = 'user/modify_user_password.templ';  

$body = runTemplate(
    \%Data,
    {'Errors' => 'errors'},
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
