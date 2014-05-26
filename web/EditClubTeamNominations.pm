#
# $Header: svn://svn/SWM/trunk/web/EditClubTeamNominations.pm 8251 2013-04-08 09:00:53Z rlee $
#

package EditClubTeamNominations;
require Exporter;
@ISA = qw(Exporter);
@EXPORT=qw(handleClubTeamNominations);
@EXPORT_OK=qw(handleClubTeamNominations);

use strict;
use Reg_common;
use Utils;
use CGI qw(unescape param);

sub handleClubTeamNominations {
	my ($action, $Data,$clubID)=@_;

	my $resultHTML='';
	my $title='';
	my $ret='';
	if ($action =~/^C_ECT_U/) {
		 ($ret,$title)=update_teams($action, $Data, $clubID);
		 $resultHTML.=$ret;
	}
	else	{
		 ($ret,$title)=edit_teams($action, $Data, $clubID);
		 $resultHTML.=$ret;
	}
	$title||=$Data->{'lang'}->txt('Teams');
	
	return ($resultHTML,$title);
}

sub edit_teams	{
	my ($action, $Data, $clubID)=@_;

	my $l=$Data->{'lang'};
	my $intro=$l->txt('FIELDS_intro');

	my $assocID=$Data->{'clientValues'}{'assocID'} || 0;
	my $realmID=$Data->{'Realm'} || 0;
	my $subBody=qq[
		<form action="$Data->{'target'}" method="POST">
		<input type="submit" value="].$l->txt("Save Teams").qq[">
		
		<table class="permsTable">
	];
	my $unescclient=unescape(setClient($Data->{'clientValues'}));

	## GET GRADES
	my $st=qq[
		SELECT CG.intGradeID, CG.strGradeName, IF(CTN.strTeamNominations IS NULL,0, CTN.strTeamNominations) AS strTeamNominations, CTN.intClubTeamNominationsID
                FROM tblClubGrades AS CG
                LEFT JOIN tblClubTeamNominations AS CTN ON (CG.intGradeID=CTN.intGradeID AND CTN.intClubID=$clubID)
                WHERE CG.intRealmID=$realmID
                ORDER BY CG.intGradeID DESC;
	];
	my $q=$Data->{'db'}->prepare($st);

        my $st_noteams=qq[
                SELECT CG.intGradeID, CG.strGradeName
                FROM tblClubGrades AS CG
                WHERE CG.intRealmID=$realmID
                ORDER BY CG.intGradeID DESC;
        ];
        my $q_noteams=$Data->{'db'}->prepare($st_noteams);


	## HEADER INFORMATION
	$subBody .= qq[
		<tr>
			<th>Grade</th>
			<th>Teams</th>
		</tr>
	];

	my $found=0;
	$q->execute();
	while(my $dref=$q->fetchrow_hashref())	{
		next if !$dref->{'strGradeName'};
		$found=1;

		$subBody.=qq[
			<tr>
				<td class="label">$dref->{strGradeName}</td>
				<td align="center"><input type="text" value="$dref->{strTeamNominations}" name="CTN_$dref->{intGradeID}"><input type="hidden" name="CTN_ID_$dref->{intGradeID}" value="$dref->{intClubTeamNominationsID}"></td>
			</tr>
		];
  	}

	if(!$found)	{ 
		$q_noteams->execute();
		while(my $dref=$q_noteams->fetchrow_hashref())	{
			next if !$dref->{'strGradeName'};
			$found=1;

			$subBody.=qq[
				<tr>
					<td class="label">$dref->{strGradeName}</td>
					<td align="center"><input type="text" value="" name="CTN_$dref->{intGradeID}"><input type="hidden" name="CTN_ID_$dref->{intGradeID}" value=""</td>
				</tr>
			];
  		}
	}

	$subBody.=qq[
		</table>
			<input type="submit" value="].$l->txt('Save Teams').qq[">
			<input type="hidden" name="a" value="C_ECT_U">
			<input type="hidden" name="client" value="$unescclient">
		</form>
	];

	if($found)	{ 
		$subBody=qq[ <p>$intro</p>$subBody]; 
	} else {
		$subBody=qq[<div class="warningmsg">There are no available Teams to assign</div>] if $found < 1; 
	}


	return ($subBody,$l->txt('Edit Teams'));

}

sub update_teams {
	my ($action, $Data, $clubID)=@_;
	my $realmID=$Data->{'Realm'} || 0;
	my $update_st = qq[
		UPDATE tblClubTeamNominations
		SET strTeamNominations=?
		WHERE intClubID=$clubID
			AND intGradeID=?
			AND intClubTeamNominationsID=?
	];

	my $insert_st = qq[
		INSERT INTO tblClubTeamNominations
		(intClubID, intGradeID, strTeamNominations,intRealmID)
		VALUES ($clubID,?,?,$realmID)
	];

 	my $cgi=new CGI;
 	my %params=$cgi->Vars();

        for my $k (keys %params)        {
        	next if $k=~/^CTN_ID/;
        	next if $k=~/a/;
        	next if $k=~/client/;

                my $id=$k;
                $id=~s/.*_//;
                return  if $id=~/[^\d]/;

                # CHECK FOR EXISTING RECORD
		if ($params{"CTN_ID_$id"} ne "") {
			## UPDATE
			my $q=$Data->{'db'}->prepare($update_st);
                	$q->execute($params{"CTN_$id"}, $id, $params{"CTN_ID_$id"});
		}
		else {
			## INSERT
			my $q=$Data->{'db'}->prepare($insert_st);
                	$q->execute($id, $params{"CTN_$id"});
		}
        }

	return '<div class="OKmsg">'.$Data->{'lang'}->txt('Club Teams Updated').'</div>';
}

1;
