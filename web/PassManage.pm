#
# $Header: svn://svn/SWM/trunk/web/PassManage.pm 11610 2014-05-20 01:42:16Z dhanslow $
#

package PassManage;
require Exporter;
@ISA = qw(Exporter);
@EXPORT=qw(handlePasswordManagement);
@EXPORT_OK=qw(handlePasswordManagement);

use strict;
use Reg_common;
use Utils;
use HTMLForm;
use CGI qw(unescape Vars param);
use ConfigOptions;
use FieldLabels;
use CustomFields;
use List qw(list_row list_headers);
use DeQuote;
use AuditLog;
use Log;
use Data::Dumper;


sub handlePasswordManagement	{
	my ($action, $Data, $typeID)=@_;

	my $resultHTML='';
	my $title='Password Management';
	my $client = setClient($Data->{'clientValues'});
	$typeID||=0;
	my $ret='';
	$action='PW_M' if !$typeID;
	if ($action =~/^PW_u/) {
		$resultHTML=update_passwords($action, $Data, $typeID, $client);
		$action='PW_D';
	}
	elsif ($action =~/^PW_Os/) {
		$resultHTML.=update_ownpassword($action,$Data, $typeID, $client);
		$action='';
	}
	if ($action =~/^PW_D/) {
		$resultHTML.=password_form($action,$Data, $typeID, $client);
	}
	elsif ($action =~/^PW_O/) {
		$resultHTML.=ownpass_form($action,$Data, $typeID, $client);
	}
	else	{
		$resultHTML.=passwordMenu($action, $Data, $client);
	}
	
	return ($resultHTML,$title);
}

sub passwordMenu {
	my ($action, $Data, $client)=@_;
	my $body=qq[
		<p>Choose the levels for which you wish to modify the passwords from the options below.</p>
		<ul>
	];
  my $currentLevel=$Data->{'clientValues'}{'currentLevel'} || $Defs::LEVEL_NONE;
	if($currentLevel > $Defs::LEVEL_CLUB and (allowedAction($Data, 'cu_a') or allowedAction($Data, 'cu_e')) and !$Data->{'SystemConfig'}{'NoClubs'})	{
		$body.=qq[ <li><a href="$Data->{'target'}?client=$client&amp;a=PW_D&amp;l=$Defs::LEVEL_CLUB">$Data->{'LevelNames'}{$Defs::LEVEL_CLUB}</a></li>] ;
	}
 if($currentLevel > $Defs::LEVEL_TEAM and ( allowedAction($Data, 'tu_a') or allowedAction($Data, 'tu_e')) and !$Data->{'SystemConfig'}{'NoTeams'})	{
		$body.=qq[ <li><a href="$Data->{'target'}?client=$client&amp;a=PW_D&amp;l=$Defs::LEVEL_TEAM">$Data->{'LevelNames'}{$Defs::LEVEL_TEAM}</a></li>];
		$body.=qq[ <li><a href="$Data->{'target'}?client=$client&amp;a=PW_D&amp;comp=1&amp;l=$Defs::LEVEL_TEAM">$Data->{'LevelNames'}{$Defs::LEVEL_TEAM.'_P'} in $Data->{'LevelNames'}{$Defs::LEVEL_COMP.'_P'}</a></li>] if !$Data->{'SystemConfig'}{'NoComps'};
	}
 if($currentLevel > $Defs::LEVEL_MEMBER and ( allowedAction($Data, 'mu_a') or allowedAction($Data, 'mu_e')))	{
		$body.=qq[<li><a href="$Data->{'target'}?client=$client&amp;a=PW_D&amp;l=$Defs::LEVEL_MEMBER">$Data->{'LevelNames'}{$Defs::LEVEL_MEMBER}</a></li>];
	}
	$body.=qq[
		</ul>
	];
	my %actprefix=($Defs::LEVEL_TEAM => 't', $Defs::LEVEL_CLUB => 'c', $Defs::LEVEL_MEMBER => 'm');
	if(allowedAction($Data, $actprefix{$currentLevel}.'u_e'))	{
		if($Data->{'clientValues'}{'authLevel'} == $currentLevel)	{
			$body.=qq[ <a href="$Data->{'target'}?client=$client&amp;a=PW_O&l=$currentLevel">My Own Password</a>];
		}
		else	{
			$body.=qq[ <a href="$Data->{'target'}?client=$client&amp;a=PW_O&l=$currentLevel">The password for this $Data->{'LevelNames'}{$currentLevel}</a>];

		}
	}
	return $body;
}



sub password_form	{
	my ($action, $Data, $typeID, $client)=@_;

	my $filter=param('f') || '';
	my $active_comp=param('comp') || 0;
	my $compwhere = $active_comp ? qq[ AND tblComp_Teams.intTeamID IS NOT NULL and tblAssoc_Comp.intCompID IS NOT NULL] : '';
	my $currentLevel=$Data->{'clientValues'}{'currentLevel'}||0;
	my $statement='';
	my $subBody='';
	if($currentLevel > $Defs::LEVEL_CLUB and $typeID==$Defs::LEVEL_CLUB)	{
		$statement=qq[
			SELECT tblClub.intClubID as ID, tblClub.strName, tblAuth.strPassword, tblAuth.strUsername, tblAuth.intAuthID, intReadOnly
			FROM tblClub JOIN tblAssoc_Clubs ON tblClub.intClubID=tblAssoc_Clubs.intClubID 
				LEFT JOIN tblAuth ON (intLevel=$Defs::LEVEL_CLUB AND intID=tblClub.intClubID )
			WHERE tblAssoc_Clubs.intAssocID=$Data->{'clientValues'}{'assocID'}
				AND tblClub.intRecStatus = $Defs::RECSTATUS_ACTIVE
				AND tblAssoc_Clubs.intRecStatus = $Defs::RECSTATUS_ACTIVE
			ORDER BY strName
		];
	}
	elsif($currentLevel >= $Defs::LEVEL_CLUB and $typeID==$Defs::LEVEL_TEAM)	{
		my $clubwhere=$currentLevel == $Defs::LEVEL_CLUB ? " AND tblTeam.intClubID= $Data->{'clientValues'}{'clubID'} ": '';
		$statement=qq[
			SELECT tblTeam.intTeamID as ID, tblAuth.strPassword, tblAuth.strUsername, tblAuth.intAuthID,  IF(tblAssoc_Comp.strTitle IS NOT NULL,CONCAT(tblTeam.strName, " (",tblAssoc_Comp.strTitle,")"),tblTeam.strName) AS strName, intReadOnly
			FROM tblTeam 
				LEFT JOIN tblComp_Teams ON (tblTeam.intTeamID = tblComp_Teams.intTeamID and tblComp_Teams.intRecStatus = $Defs::RECSTATUS_ACTIVE)
        LEFT JOIN tblAssoc_Comp ON (tblAssoc_Comp.intCompID = tblComp_Teams.intCompID and tblAssoc_Comp.intRecStatus = $Defs::RECSTATUS_ACTIVE)
				LEFT JOIN tblAuth ON (intLevel=$Defs::LEVEL_TEAM AND intID=tblTeam.intTeamID )

			WHERE tblTeam.intAssocID=$Data->{'clientValues'}{'assocID'}
        AND tblTeam.intRecStatus = $Defs::RECSTATUS_ACTIVE
				$clubwhere
				$compwhere
			GROUP BY tblTeam.intTeamID, tblAssoc_Comp.intCompID
			ORDER BY tblTeam.strName, tblAssoc_Comp.intCompID DESC
		];
	}
	elsif($typeID==$Defs::LEVEL_MEMBER)	{
		my $letterheader='';
		my $from_str='';
		my $where_str='';
		if($currentLevel == $Defs::LEVEL_ASSOC) {
			$where_str=qq[ 
				tblMember_Associations.intAssocID=$Data->{'clientValues'}{'assocID'} 
				AND tblMember_Associations.intRecStatus <> $Defs::RECSTATUS_DELETED
			];
		}
		elsif($currentLevel == $Defs::LEVEL_CLUB) {
			$from_str=qq[
				INNER JOIN tblMember_Clubs ON (tblMember.intMemberID=tblMember_Clubs.intMemberID) 
			];
			$from_str .= qq[
				LEFT JOIN tblMember_ClubsClearedOut as MCC ON (
					MCC.intMemberID = tblMember.intMemberID 
					AND MCC.intClubID = tblMember_Clubs.intClubID
				)
			] if ($Data->{'SystemConfig'}{'pwd_filter_clearedOut'});
			$where_str=qq[ 
				tblMember_Clubs.intClubID=$Data->{'clientValues'}{'clubID'}
						AND tblMember_Clubs.intStatus <> $Defs::RECSTATUS_DELETED
			];
			$where_str .= qq[
						AND MCC.intMemberID IS NULL
			] if ($Data->{'SystemConfig'}{'pwd_filter_clearedOut'});
		}
		elsif($currentLevel == $Defs::LEVEL_TEAM) {
			$from_str=' INNER JOIN tblMember_Teams ON (tblMember_Teams.intMemberID=tblMember.intMemberID)';
			$where_str=qq[ intTeamID=$Data->{'clientValues'}{'teamID'}
					AND tblMember_Teams.intStatus <> $Defs::RECSTATUS_DELETED
			];
			$filter='ALL';
		}
    $where_str.=" AND tblMember.intStatus = $Defs::RECSTATUS_ACTIVE ";

		if(!$filter)  {
			my $totalMembers;
			my $statement=qq[
				SELECT LEFT(tblMember.strSurname,1) as letter, COUNT(DISTINCT tblMember.intMemberID) as cnt
				FROM tblMember JOIN tblMember_Associations ON tblMember_Associations.intMemberID=tblMember.intMemberID $from_str
				WHERE $where_str
				GROUP BY letter
				ORDER BY letter
			];
			my $query = $Data->{'db'}->prepare($statement);
			$query->execute;
			my @numMembers=();
			while(my ($letter,$num)=$query->fetchrow_array()) {
				push @numMembers, [$letter,$num];
				$totalMembers+=$num;
			}
			push @numMembers, ['ALL',$totalMembers];
			return textMessage("No  $Data->{'LevelNames'}{$Defs::LEVEL_MEMBER.'_P'} can be found in the database for this $Data->{'LevelNames'}{$typeID}.") if !@numMembers;
			my $found=0;
			for my $row (@numMembers) {
				$found++;
				$subBody.=list_row({letter=>$row->[0],cnt=>$row->[1]}, [qw(letter cnt)],["$Data->{'target'}?client=$client&amp;a=PW_D&amp;l=$Defs::LEVEL_MEMBER&amp;;f=$row->[0]"],($found-1)%2);
			}
			my $headings=list_headers(['First Letter of Member Surname','No. of Members']) || '';
			if($totalMembers < 250) {
				$filter='ALL';
				$subBody='';
			}
			else  {
				return qq[
					<table class="listTable" style="width:50%;">
						$headings
						$subBody
					</table>
				];
			}
		}
		else  {
			my @alphabet= (qw(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z ALL));
			for my $letter (@alphabet)  {
				$letterheader.='/' if $letterheader;
				$letterheader.= qq[<a href="$Data->{'target'}?client=$client&amp;a=PW_D&amp;&amp;l=$Defs::LEVEL_MEMBER&amp;f=$letter"> $letter </a>];
			}
		}
		$filter ='' if $filter eq 'ALL';
		$statement=qq[
			SELECT DISTINCT tblMember.intMemberID AS ID, CONCAT(tblMember.strSurname, ", ", tblMember.strFirstname) AS strName, tblAuth.strPassword, tblAuth.strUsername, tblAuth.intAuthID, tblMember.strNationalNum, intReadOnly
			FROM tblMember JOIN tblMember_Associations ON tblMember_Associations.intMemberID=tblMember.intMemberID $from_str
			LEFT JOIN tblAuth ON (intLevel=$Defs::LEVEL_MEMBER AND intID=tblMember.intMemberID)
			WHERE $where_str
				AND strSurname LIKE "$filter%"
        AND tblMember_Associations.intAssocID = $Data->{'clientValues'}{'assocID'}
			ORDER BY strSurname, strFirstname
		];
	}
  my $query = $Data->{'db'}->prepare($statement);
  $query->execute;

	my $unescclient=unescape($client);
	my %actprefix=($Defs::LEVEL_TEAM => 't', $Defs::LEVEL_CLUB => 'c', $Defs::LEVEL_MEMBER => 'm');
	my $allowedits=allowedAction($Data, $actprefix{$typeID}.'u_e');
	my $allowadds=allowedAction($Data, $actprefix{$typeID}.'u_a');
	if($allowedits)	{
		$subBody=qq[
        <p>In order to update an existing password please enter the new password against the appropriate username. Only the passwords where a new password is entered will be updated. If you wish to only provide read only access to a user then check the <b>'Read Only'</b> check box and this will provide the user limited access to the database.  By pressing <b>"Automatically Generate Passwords"</b> passwords will be generated and saved for all Members who currently have blank passwords.

        After you have finished modifying the passwords you must press the <b>"Update Passwords"</b> button to save your changes.  </p>

			<form action="$Data->{'target'}" method="POST">
			<input type="submit" value="Update Passwords">
			<input type="submit" name="autogen" value="Automatically Generate Passwords">
			].q[
				<script type="JavaScript">
					function checkvalidpw(field)	{
						if(field.value.search(/^[\dA-Za-z]*$/)) {
							alert('Invalid characters : The password can only contains letters and numbers'); 
							field.focus()
							return false;
						}
						return true;
					}

				</script>
			];
		}#'
		
		my $natnumName = $Data->{'SystemConfig'}{'GenNumField'} ? qq[&nbsp;<i>($Data->{'SystemConfig'}{'NationalNumName'})</i>] : '';
		$natnumName = '' if ($typeID != $Defs::LEVEL_MEMBER) or ($Data->{'SystemConfig'}{'NationalNumName'} eq '');
		$subBody.=qq[
			<div class="sectionheader">$Data->{'LevelNames'}{$typeID} Passwords:</div>
		<table class="permsTable pwdsTable">
			<tr>
				<th>Name$natnumName</th>
				<th>Username/Code</th>
				<th>Password</th>
				<th>New Password</th>
				<th>Read Only</th>
			</tr>
	];
	my %IDUsed=();
    my $count = 0;
	while(my $dref=$query->fetchrow_hashref())	{
		next if exists $IDUsed{$dref->{'ID'}};
		$IDUsed{$dref->{'ID'}} = 1;
		$dref->{'strPassword'}||='';
		$dref->{'intReadOnly'}||=0;
		$dref->{'intAuthID'}||='';
        
		my $readonly= $dref->{'intReadOnly'} ? 'Yes' : 'No';
		my $checked= $dref->{'intReadOnly'} ? ' checked ' : '';
        my $disabled = $dref->{'strPassword'} ? '' : 'checked';
		my $natnum = '';
        $count++;
        my $shade_class = ($count%2 == 0)
            ? ' class="rowshade"'
            : '';
		if($typeID == $Defs::LEVEL_MEMBER)	{
			$natnum=$Data->{'SystemConfig'}{'GenNumField'} ? qq[&nbsp;<i>($dref->{$Data->{'SystemConfig'}{'GenNumField'}})</i>] : '';
		}

        my $username = "$typeID$dref->{'strUsername'}" || "$typeID$dref->{'ID'}";
		$subBody.=qq[
			<tr$shade_class>
				<td class="label" style="padding-top:8px;">$dref->{'strName'}$natnum</td>
				<td>$username</td>
		];

        my $password_text = $Data->{'SystemConfig'}{'AssocConfig'}{'ShowPassword'} ?  $dref->{'strPassword'} : "*" x length($dref->{'strPassword'});
        $password_text ||= "No Password Set";

		if(($allowedits and $dref->{'strPassword'}) or ($allowadds and $dref->{'strPassword'} eq ''))	{
			$subBody.=qq[
				<td>$password_text</td>
				<td><input type="password" name="pwi$dref->{'ID'}_$dref->{'intAuthID'}" value="" size="10" maxlength="10" onchange="return checkvalidpw(this);">
                </td>
				<td><input type="checkbox" name="roi$dref->{'ID'}_$dref->{'intAuthID'}" $checked value="1" class="nb"></td>
			];
		}
		else	{ 
			$subBody.=qq[
				<td>$password_text<td>
				<td>$readonly</td>
			]; 
		}
		$subBody.=qq[
			</tr>
		];
	}
	$subBody.=qq[
		</table>
		<br> <br>
	];
	$subBody.=qq[
		<input type="submit" value="Update Passwords">
		<input type="submit" name="autogen" value="Automatically Generate Passwords">
		<input type="hidden" name="client" value="$unescclient">
		<input type="hidden" name="a" value="PW_u">
		<input type="hidden" name="l" value="$typeID">
		<input type="hidden" name="comp" value="$active_comp">
		</form>
	] if $allowedits;
	
	return $subBody;

}

sub update_passwords {
	my ($action, $Data, $typeID, $client)=@_;

	my $assocID=$Data->{'clientValues'}{'assocID'}||'';
	my $st_add=qq[
		INSERT INTO tblAuth (strUsername, strPassword, intLevel, intID, intAssocID, intReadOnly)
			VALUES(?,?,$typeID,?,$assocID, ?);
	];
	$assocID.=',0' if $typeID=$Defs::LEVEL_MEMBER;
	my $st_upd=qq[
		UPDATE tblAuth SET strPassword=?, intReadOnly=?
			WHERE intAuthID=?
 
	];
    	$st_upd .= qq[ AND intAssocID IN ($assocID) ] if ($typeID > $Defs::LEVEL_MEMBER);
    	$st_upd .= qq[ LIMIT 1];
	my $st_del=qq[
		DELETE FROM tblAuth 
			WHERE intAuthID=? AND intAssocID IN ($assocID)
	];
	my $q_add=$Data->{'db'}->prepare($st_add);
	my $q_upd=$Data->{'db'}->prepare($st_upd);
	my $q_del=$Data->{'db'}->prepare($st_del);

	my %params=Vars();
	my @values=();
	for my $key (keys %params)	{
		if($key=~/^pwi/)	{
			my($entityID,$authID)=$key=~/pwi(\d+)_(\d*)/;
			next if !$entityID;
			my $pw=$params{$key} ||'';
			$pw=~s/'/''/g;
			my $ro=$params{"roi$entityID"."_$authID"} || 0;
            my $disabled = 0; # this feature is removed for this moment
			push @values, [$entityID, $authID, $pw, $ro, $disabled];
		}
	}
	
	my $returnstr='';
	for my $row (@values)	{
			my $eID=$row->[0] ||'';
			my $authID=$row->[1] ||'';
			my $pw=$row->[2] ||'';
			my $ro=$row->[3] || 0;
			my $disabled=$row->[4] || 0; 
            if($authID and $disabled) { $q_del->execute($authID); }
			elsif($authID and $pw)	{ $q_upd->execute($pw,$ro, $authID); }
			elsif(!$authID and $pw)	{ $q_add->execute($eID, $pw, $eID, $ro); }
			elsif(!$authID and !$pw and $params{'autogen'})	{ $q_add->execute($eID, getpass(), $eID, $ro); }
			$returnstr.= qq[<div class="warningmsg">Problem updating password for $eID</div>] if $DBI::err;
	}
  auditLog($typeID, $Data, 'Update', 'Passwords');
	return qq[<div class="OKmsg">Passwords Updated</div>];
}
	

sub getpass {
    srand();
    #srand(time() ^ ($$ + ($$ << 15)) );
    my $salt=(rand()*100000);
    my $salt2=(rand()*100000);
    my $k=crypt($salt2,$salt);
    #Clean out some rubbish in the key
    $k=~s /['\/\.\%\&]//g;
    $k=substr($k,0,8);
    $k=lc $k;

  return $k;
}

sub ownpass_form	{
	my ($action, $Data, $typeID, $client)=@_;
	my $unescclient=unescape($client);
	return 'Invalid attempt to change password' if($Data->{'clientValues'}{'authLevel'} < $Data->{'clientValues'}{'currentLevel'});

	my $own = $Data->{'clientValues'}{'authLevel'} == $Data->{'clientValues'}{'currentLevel'} ? 1 : 0;

	my $title= $own ? 'Change My Password' : "Change $Data->{'LevelNames'}{$Data->{'clientValues'}{'currentLevel'}} Password";
	my $expln= qq[Fill in your old password and then enter your new password twice.];
	$expln='Enter the new password twice in the boxes provided.' if !$own;
	my $myID=getID($Data->{'clientValues'});
    my $username =$typeID==5 ? $myID : qq[$typeID$myID];
    my $Username =$typeID==5 ? qq[ID] : qq[Username];
	my $subBody=qq[
			<div class="sectionheader">$title</div>
		<p>$expln  Press the <b>'Update My Password'</b> button to save the changes.
		</p>
		<form action="$Data->{'target'}" method="POST">
			<table>
				<tr>
					<td class="label">$Username</td>
					<td class="value">$username</td>
				</tr>
				<tr><td colspan="2"><br><br></td></tr>
	];
	$subBody.=qq[
				<tr>
					<td class="label">Old Password</td>
					<td class="value"><input type="password" name="mypass" size="12" maxlength="12"></td>
				</tr>
				<tr><td colspan="2"><br><br></td></tr>
	] if $own;
	$subBody.=qq[
				<tr>
					<td class="label">New Password</td>
					<td class="value"><input type="password" name="newpass1" size="12" maxlength="12"></td>
				</tr>
				<tr>
					<td class="label">New Password - Confirmation</td>
					<td class="value"><input type="password" name="newpass2" size="12" maxlength="12"></td>
				</tr>
			</table>
			<br> <br> <br>
			<input type="submit" value="Update My Password">
			<input type="hidden" name="client" value="$unescclient">
			<input type="hidden" name="a" value="PW_Os">
			<input type="hidden" name="l" value="$typeID">
		</form>
	];
	return $subBody;
}

sub update_ownpassword {
	my ($action, $Data, $typeID, $client)=@_;

	my $newp1=param('newpass1') || '';
	my $newp2=param('newpass2') || '';
	my $oldpass=param('mypass') || '';

	my $assocID=$Data->{'clientValues'}{'assocID'}||'';

	my $own = $Data->{'clientValues'}{'authLevel'} == $Data->{'clientValues'}{'currentLevel'} ? 1 : 0;

	return '<div class="warningmsg">You must enter all fields</div>' if (!$newp1 or !$newp2 );
	return '<div class="warningmsg">You must enter all fields</div>' if (!$oldpass and $own);
	return '<div class="warningmsg">New passwords do not match</div>' if ($newp1 ne $newp2);

	my $id=getID($Data->{'clientValues'});
	deQuote($Data->{'db'},\$oldpass);
	my $authID=0;
	{
		my $st=qq[
			SELECT intAuthID
			FROM tblAuth 
			WHERE intAssocID=$assocID
				AND intID=$id
				AND intLevel=$Data->{'clientValues'}{'currentLevel'}
		];
		$st.=" AND strPassword=$oldpass" if $own;
		my $query = $Data->{'db'}->prepare($st);
		$query->execute;
		$authID=$query->fetchrow_array() || 0;
		$query->finish();
	}
	if(!$authID and $own)	{
		return '<div class="warningmsg">Incorrect Password</div>';
	}
	deQuote($Data->{'db'},\$newp1);
	if(!$authID and !$own)	{
		my $st=qq[INSERT INTO tblAuth (strUsername, strPassword, intLevel, intAssocID, intID)
			VALUES($id, $newp1, $Data->{'clientValues'}{'currentLevel'}, $assocID ,$id)
		];
		$Data->{'db'}->do($st);
	}
	else	{
		my $st_upd=qq[
			UPDATE tblAuth SET strPassword=$newp1
				WHERE intAuthID=$authID
		];
		$Data->{'db'}->do($st_upd);
	}

	return qq[<div class="warningmsg">Problem updating password</div>] if $DBI::err;
  auditLog($own, $Data, 'Update', 'Own Password');

	my $str=' <div class="OKmsg">Password Updated</div>';
	$str=qq[
		<p>To continue you must logout and then log back in again</p>
		<p><a href="$Defs::base_url" class="help">Logout</a> </p>
	] if $own;
	return $str;
}
	

1;
