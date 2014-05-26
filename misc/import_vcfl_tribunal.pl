#!/usr/bin/perl -w

#
# $Header: svn://svn/SWM/trunk/misc/import_vcfl_tribunal.pl 9485 2013-09-10 04:51:37Z tcourt $
#

use lib  ".", "..", "../web", "../web/comp";
#use lib "..", ".", "/u/regonew_live/web/", "/u/regonew_live/";
#use lib "..", ".", "/u/rego_v6/web/", "/u/rego_v6/";
use strict;
use Defs;
use DBI;
use CGI qw(:standard escape);
use Utils;
use DeQuote;
use GenCode;
use Seasons;
                                                                                                    
main();
1;

sub main	{
my $db=connectDB();
#print STDERR "LIB, FILE NAME etc\n";
#exit;
#### SETTINGS #############
my $countOnly=0;
my $REALM_ID = 2;
my $infile='vcfl_090204_tribunal.csv';
###########################

my %Data=();
$Data{'Realm'} = $REALM_ID;
$Data{'db'}=$db;

open INFILE, "<$infile" or die "Can't open Input File";

my $count = 0;
                                                                                                        
seek(INFILE,0,0);
$count=0;
my $insCount=0;
my %members=();
my $st = qq[
	SELECT DISTINCT M.intMemberID, M.strSurname, M.strFirstname
	FROM tblMember as M
		INNER JOIN tblMember_Associations as MA ON (MA.intMemberID = M.intMemberID)
	WHERE MA.intAssocID>=12578
		AND MA.intAssocID<=12652
		AND M.intRealmID=$REALM_ID
];
	my $qry= $db->prepare($st) or query_error($st);
	$qry->execute() or query_error($st);
	while (my $dref=$qry->fetchrow_hashref())	{
		my $name = $dref->{strSurname} . "_" . $dref->{strFirstname};
		$members{$name} = $dref->{intMemberID};
	}

my $NOTinsCount = 0;

while (<INFILE>)	{
	my %parts = ();
	$count ++;
	#next if $count == 1;
	chomp;
	my $line=$_;
	$line=~s///g;
	$line=~s/,/\-/g;
	$line=~s/"//g;
	my @fields=split /\t/,$line;
	$parts{'ASSOCID'} = $fields[0] || 0;
	$parts{'CLUBID'} = $fields[1] || 0;
	$parts{'MEMBERNO'} = $fields[2] || 0;
	$parts{'FIRST_NAME'} = $fields[3] || "";
	$parts{'LAST_NAME'} = $fields[4] || "";
	$parts{'TRIBUNAL_DATE'} = $fields[5] || "";
	$parts{'OFFENCE'} = $fields[6] || "";
	$parts{'OUTCOME'} = $fields[7] || '';
	$parts{'PENALTYEXP_START'} = $fields[8] || "";
	$parts{'PENALTYEXP_END'} = $fields[9] || "";
	$parts{'PENALTY'} = $fields[10] || "";
	$parts{'COMP'} = $fields[11] || "";
	$parts{'APPEALED'} = $fields[12] || 0;
	$parts{'APPEALED_RESULT'} = $fields[13] || "";
	$parts{'NOTES'} = $fields[14] || "";
	$parts{'Appealed'}= ($parts{'APPEALED'} =~ /Y/) ? 1 : 0; 
	$parts{'AppealedResult'}= 0;
	$parts{'AppealedResult'}= 1 if ($parts{'APPEALED_RESULT'} eq 'UPHELD');

	$parts{'NOTES'} = qq[Comp: $parts{'COMP'}

Comments: $parts{'NOTES'}];

	my %tParts = %parts;
	deQuote($db, \%parts);

	my $clubID= $tParts{'CLUBID'} || 0;
	my $assocID = $tParts{'ASSOCID'} || 0;
	
	if (! $assocID or $parts{'FIRST_NAME'} eq "" or $parts{'LAST_NAME'} eq "")	{
		## LOG IN FILE
	}
	else	{
		my $name = $tParts{'LAST_NAME'} . "_" . $tParts{'FIRST_NAME'};
		my $memberID = $members{$name} || 0; #next;
		if (! $memberID)	{
			$NOTinsCount++;
			next;
		}
print STDERR "NAME: $name|$memberID\n";

		my ($error,$newdate)=fix_date($parts{'TRIBUNAL_DATE'});
		$newdate = "0000-00-00" if $error;
		my $Tnewdate = $tParts{'TRIBUNAL_DATE'};
		deQuote($db, \$newdate);

		my ($error2,$newdate_start)=fix_date($parts{'PENALTYEXP_START'});
		$newdate_start = "0000-00-00" if $error2;
		my $Tnewdate2 = $tParts{'PENALTYEXP_START'};
		deQuote($db, \$newdate_start);

		my ($error3,$newdate_end)=fix_date($parts{'PENALTYEXP_END'});
		$newdate_end = "0000-00-00" if $error3;
		my $Tnewdate3 = $tParts{'PENALTYEXP_END'};
		deQuote($db, \$newdate_end);


		if ($countOnly)	{
			$insCount++;
			next;
		}

		my $st = qq[
			INSERT INTO tblTribunal (
				intRecStatus,
				intMemberID,
				intRealmID,
				intAssocID,
				intClubID
				dtCharged,
				dtHearing,
				strOffence,
				strOutcome,
				dtPenaltyStartDate,
				dtPenaltyExp,
				intPenalty,
				strPenaltyType, 
				intAppealed,
				intrAppealedOutcomeID,
				strNotes,
				intCompID
			)
			VALUES (
				1,
				$memberID,
				2,	
				$parts{'ASSOCID'},
				$parts{'CLUBID'},
				$newdate,
				$newdate,
				$parts{'OFFENCE'}, 
				$parts{'OUTCOME'}, 
				$newdate_start,
				$newdate_end,
				$parts{'PENALTY'}, 
				'Weeks',
				$parts{'Appealed'}, 
				$parts{'AppealedResult'}, 
				$parts{'NOTES'},
				-1
			)
		];
#		my $query = $db->prepare($st) or query_error($st);
#	    	$query->execute() or query_error($st);
		print STDERR $st;
        }
	$insCount++;
}
$count --;
print STDERR "COUNT CHECK ONLY !!!\n" if $countOnly;
print STDERR "$insCount TRIBUNAL RECORDS INSERTED\n";
print STDERR "$NOTinsCount TRIBUNAL RECORDS NOT INSERTED\n";

close INFILE;

}
sub fix_date  {
  my($date)=@_;
  my($mm,$dd,$yyyy)=$date=~m:(\d+)/(\d+)/(\d+):;
  if(!$dd or !$mm or !$yyyy)  { return ("Invalid Date",'');}
  if($yyyy <100)  {$yyyy+=2000;}
  return ("","$yyyy-$mm-$dd");
}
