#!/usr/bin/perl 

#
# $Header: svn://svn/SWM/trunk/web/photodownload.cgi 10128 2013-12-03 04:03:40Z tcourt $
#

use strict;
use warnings;
use CGI qw(param);
use lib "..",".";
use Defs;
use Reg_common;
use Utils;
use Lang;

main();	

sub main	{
	# GET INFO FROM URL
	my $memberID = param('m') || 0;
	my $username= param('u') || 0;
	my $password= param('p') || 0;
	$memberID=0 if $memberID=~/[^\d]/;
  my %Data=();
                                                                                                        
  # AUTHENTICATE
  my $db=connectDB();
	if($db
		and $memberID
		and $username
		and $password
	 )	{
		my $statement=qq[
			SELECT intPhoto
			FROM tblMember AS M
				INNER JOIN tblMember_Associations AS MA ON M.intMemberID=MA.intMemberID
				INNER JOIN tblAuth AS AT ON (AT.intID=MA.intAssocID AND AT.intLevel = $Defs::LEVEL_ASSOC)
			WHERE M.intMemberID= ?
				AND AT.strUsername = ?
				AND AT.strPassword= ?
		];
		my $query = $db->prepare($statement);
		$query->execute($memberID, $username, $password);
		my($hasphoto)=$query->fetchrow_array();
		$query->finish();
		disconnectDB($db);
		if($hasphoto)	{
			my $path='';
			{
				my $l=6 - length($memberID);
				my $pad_num=('0' x $l).$memberID;
				my (@nums)=$pad_num=~/(\d\d)/g;
				for my $i (0 .. $#nums-1) { $path.="$nums[$i]/"; }
			}
			my $filename="$Defs::fs_upload_dir/$path$memberID.jpg";
			open (FILE, "<$filename") || die("Can't open file $filename\n");
			my $img='';
			while(<FILE>)  { $img.= $_; }
			close (FILE);
			print "Content-type: image/jpeg\n\n";
			print $img;
		}
		else	{ print "Content-type: text/html\n\n";}
	}
	else	{ print "Content-type: text/html\n\n";}
}
