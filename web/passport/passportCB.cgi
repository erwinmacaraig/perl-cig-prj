#!/usr/bin/perl -w

#
# $Header: svn://svn/SWM/trunk/web/passport/passportCB.cgi 8249 2013-04-08 08:14:07Z rlee $
#

use DBI;

use strict;

use lib "..",".","../..","../comp","../externallms";
use Defs;
use Utils;
use Lang;
use JSON;
use CGI qw(param);
use PassportList;
use PassportMemberCB;
use MCache;


#Passport Callback
main();

sub main	{

	my $action = param('a') || '';
	my $passportID = param('pID') || 0;
	my $passportKey = param('pk') || '';
	my $callbackKey = param('cbk') || '';

	my @errors = ();
	push @errors, 'Invalid Action' if !$action;
	push @errors, 'Invalid Passport Key' if !$passportKey;
	push @errors, 'Invalid Passport Key' if ($passportKey ne $Defs::PassportMembershipKey);

	my $outputdata = [];
	if(!@errors)	{
		my $db = connectDB();
		my %Data = (
			db => $db,
			cache => new MCache(),
		);
		if(!@errors)	{
			if($action eq 'logins')	{
				push @errors, 'Invalid PassportID' if !$passportID;
				($outputdata,undef) = getAuthOrgListsData(
					{ db => $db},			
					$passportID,
				);
			}
			elsif($action eq 'memberdetails')	{
				($outputdata,undef) = getMemberSignupDetails(
					\%Data,
					$callbackKey,
				);
			}
		}
	}

  print "Content-type: application/x-javascript\n\n";

	print genOutput($outputdata, \@errors);
}

sub genOutput {
  my($outputdata, $errors) = @_;
  my %output = (
    errors => $errors,
    data => $outputdata,
  );
  return to_json(\%output);
}

