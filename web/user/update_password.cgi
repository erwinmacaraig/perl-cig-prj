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
use DBI;
my $lang = Lang->get_handle() || die "Can't get a language handle!";
$Data{lang} = $lang;

#get posted values
my $newpasswd = param('new_passwd') || '';
my $confirm_passwd = param('confirm_passwd') || '';
my $uId = param('uId') || '';
my $error = undef;

#validate password again 
if($newpasswd ne $confirm_passwd){ 
	$error .= 'Passwords do not match.<br />';
}
if(length($newpasswd) < 6){
	$error .= 'Password should be atleast 6 characters long.<br />';
}
#update password
if(!defined($error)){ 
     my $dbh = connectDB(); 
     my %cfg = (id => $uId, db => $dbh);
     my $myUserObj = new UserObj(%cfg);	
     $myUserObj->setPassword($newpasswd);
     
}
$Data{'Errors'} = $error;



my $template = 'user/update_password_msg.templ';  

my $body = runTemplate(
    \%Data,
    {},
    $template,
); 

my $title = 'SportingPulse User Password Update'; 

pageForm(
	$title,
	$body,
	{},
	'',
	\%Data,
);