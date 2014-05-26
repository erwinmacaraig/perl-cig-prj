#!/usr/bin/perl

#
# $Header: svn://svn/SWM/trunk/misc/migrate_teamsheets.pl 8250 2013-04-08 08:24:36Z rlee $
#

use strict;

use lib "..","../web","../web/comp";

use Defs;
use Utils;
use DBI;
use LWP::UserAgent;
use CGI qw(unescape);
use DeQuote;
use Getopt::Long;

main();

sub main	{

	my %Data = ();
	my $db = connectDB();
	$Data{'db'} = $db;

	my $st = qq[
		SELECT
			DISTINCT
			intRealmID,
			C.intAssocID, 
			strValue,
			strKey
		FROM
			tblCompSWOLConfig as C
			INNER JOIN tblAssoc as A ON (C.intAssocID=A.intAssocID)
		WHERE
			strConfigArea = 'TEAM_SHEET'
			AND strKey IN ('1TEAM_NAME', '2TEAM_NAME')
			AND strValue<>''
			AND strValue IS NOT NULL
			AND strValue<>'1'
	];
	my $q = $db->prepare($st);
	$q->execute();

	my $st_teamsheet = qq[
		INSERT INTO tblTeamSheets
		(strName, intNumTeams, strFilename)
		VALUES (?,?,?)
	];
	my $q_ts = $db->prepare($st_teamsheet);

	my $st_entity= qq[
		INSERT INTO tblTeamSheetEntity
		(intTeamSheetID, intRealmID, intAssocID)
		VALUES (?,?,?)
	];
	my $q_e = $db->prepare($st_entity);

	my %TeamSheets=();
	while (my $dref = $q->fetchrow_hashref())	{

		my $tsID = 0;
		if (! exists $TeamSheets{$dref->{'strKey'}}{$dref->{'strValue'}})	{
			if ($dref->{'strKey'} eq '1TEAM_NAME')	{
				$q_ts->execute('Single team -- Teamsheet', 1, $dref->{'strValue'});
				$tsID = $q_ts->{mysql_insertid};
			}
			else	{
				$q_ts->execute('Both teams -- Teamsheet', 2, $dref->{'strValue'});
				$tsID = $q_ts->{mysql_insertid};
			}
			$TeamSheets{$dref->{'strKey'}}{$dref->{'strValue'}} = $tsID;
		}
		else	{
			$tsID = $TeamSheets{$dref->{'strKey'}}{$dref->{'strValue'}};
		}

		$q_e->execute($tsID, $dref->{'intRealmID'}, $dref->{'intAssocID'});
		
	}
	
	print "DONE";

}
1;
