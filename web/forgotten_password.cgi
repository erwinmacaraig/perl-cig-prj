#!/usr/bin/perl -w
#
# $Header: svn://svn/SWM/trunk/web/index.cgi 10277 2013-12-15 21:15:06Z tcourt $
#

use strict;
use lib ".", "..";
use CGI qw(param unescape escape cookie);
use Defs;
use Lang;
use TTTemplate; 
use Utils;

use DBI;

my $lang= Lang->get_handle() || die "Can't get a language handle!";
# need this one for other languages 

my $title=$lang->txt('APPNAME') || 'SportingPulse Membership'; 

my %Data = (lang => $lang,);	
my $error = '';
my $action = param('a') || '';

if($action eq 'RESET_PASSWD'){ 
	my $email = param('email'); 
	my $dbh = connectDB(); 
	my $query = "SELECT email FROM tblUser WHERE email = ?";
	my $st = $dbh->prepare($query);
	$st->execute($email);
	my @row = $st->fetchrow_array; 
	if(!@row){
	 $error = "Sorry. Email address does not exist in our system."
	}
	else { 
		print "Location: user/modifypassword.cgi\n\n";
	}		
}
print "Content-type: text/html\n\n";
my $forgot_passwd_form = runTemplate(
   \%Data,
      {'Errors' => $error,},
    'user/forgot_password_form.templ',
  );    
print $forgot_passwd_form; 
  
  
  
  
  
     
