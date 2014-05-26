#
# $Header: svn://svn/SWM/trunk/web/MemberHistory.pm 8251 2013-04-08 09:00:53Z rlee $
#

package MemberHistory;
require Exporter;
@ISA = qw(Exporter);
@EXPORT=qw(getMemberHistory delMemberHistory);
@EXPORT_OK=qw(getMemberHistory delMemberHistory);

use strict;
use Reg_common;
use Utils;
use CGI qw(param);


sub getMemberHistory	{

	my ($Data, $intMemberID) = @_;

	$intMemberID ||= 0;

	return '' if ! $intMemberID;

	my $db = $Data->{'db'};
	my $body;
	my $currentAssoc=$Data->{'clientValues'}{'assocID'} || 0;
	my $authlevel=$Data->{'clientValues'}{'authLevel'} || 0;

	my $st = qq[
		SELECT strSeasonName, strAssocName, strCompName, strClubName, strTeamName, strGradeName, intAssocID, 
		intMemberHistoryID, strReferenceNo
		FROM tblMemberHistory
		WHERE intMemberID=$intMemberID
		ORDER BY intMemberHistoryID
        ];
    	my $query = $db->prepare($st) or query_error($st);
    	$query->execute or query_error($st);

	my $gradeTitle= ($Data->{'SystemConfig'}{'AllowStatusChange'}) ? qq[<th>Grade</th>] : '';
	my $referencenoTitle= ($Data->{'SystemConfig'}{'AllowStatusChange'}) ? qq[<th>Ref No</th>] : '';
	
		#<div class="sectionheader">Member History</div>
	$body .= qq[
		<table class="listTable">
		<tr><th>Season</th>
		<th>$Data->{'LevelNames'}{$Defs::LEVEL_ASSOC}</th>
		<th>$Data->{'LevelNames'}{$Defs::LEVEL_COMP}</th>
		<th>$Data->{'LevelNames'}{$Defs::LEVEL_TEAM}</th>
		<th>$Data->{'LevelNames'}{$Defs::LEVEL_CLUB}</th>
		$gradeTitle
		$referencenoTitle
		</tr>
	];
	my $count=0;
	while (my $dref=$query->fetchrow_hashref())	{
		$count++;
		for my $k (keys %{$dref})	{$dref->{$k}||='&nbsp;';}
		$body .=qq[
			<tr>
				<td>$dref->{strSeasonName}</td>
				<td>$dref->{strAssocName}</td>
				<td>$dref->{strCompName}</td>
				<td>$dref->{strTeamName}</td>
				<td>$dref->{strClubName}</td>
		];
		$body .=qq[<td>$dref->{strGradeName}</td>] if $Data->{'SystemConfig'}{'AllowStatusChange'};
		$body .=qq[<td>$dref->{strReferenceNo}</td>] if $Data->{'SystemConfig'}{'AllowStatusChange'};
		my $dellink=qq[<a href="$Data->{'target'}?client=$Data->{'client'}&amp;a=M_HID&amp;h=$dref->{'intMemberHistoryID'}" onclick="return confirm('Are you sure you want to delete this historical record?');"><img src="images/sml_delete_icon.gif" border="0" alt="Delete Historical Record" title="Delete Historical Record"></a>];
		$dellink='' unless ($currentAssoc==$dref->{'intAssocID'} and $authlevel >= $Defs::LEVEL_ASSOC);
		$body .=qq[
				<td>$dellink</td>
			</tr>
		];
	}
	$body .= qq[</table>];
	$body ='' if ! $count;

	return $body;
}

sub delMemberHistory	{
	my ($Data, $intMemberID) = @_;

	$intMemberID ||= 0;

	return '' if ! $intMemberID;

	my $db = $Data->{'db'};
	my $body;
	my $currentAssoc=$Data->{'clientValues'}{'assocID'} || return '';
	my $authlevel=$Data->{'clientValues'}{'authLevel'} || return '';
	my $mhID=param('h') || return '';
	return '' if $mhID=~/[^\d]/;

	my $st=qq[
		DELETE FROM tblMemberHistory
		WHERE intMemberHistoryID=$mhID
			AND intMemberID=$intMemberID
			AND intAssocID=$currentAssoc
		LIMIT 1
	];
	$db->do($st);
}
1;
