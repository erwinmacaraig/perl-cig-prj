#
# $Header: svn://svn/SWM/trunk/web/Tags.pm 8251 2013-04-08 09:00:53Z rlee $
#

package Tags;
require Exporter;
@ISA = qw(Exporter);
@EXPORT=qw(handleTags resetTags);
@EXPORT_OK=qw(handleTags resetTags);

use strict;
use Reg_common;
use Utils;
use CGI qw(unescape param);
use AuditLog;

sub handleTags{
	my ($action, $Data,$memberID)=@_;
	my $resultHTML='';
	my $title='';
	my $ret='';
	if ($action =~/^M_TG_u/) {
		 ($ret,$title)=update_tags($action, $Data, $memberID);
		 $action='M_TG_l';
		 $resultHTML.=$ret;
	}
	if($action =~/^M_TG_E/) {
		#Assoc Details
		 ($ret,$title)=edit_tags($action, $Data, $memberID);
			$resultHTML.=$ret;
	}
	else	{
		 ($ret,$title)=listTags($Data, $memberID);
			$resultHTML.=$ret;
	}
	$title||=$Data->{'lang'}->txt('Member Tags');
	return ($resultHTML,$title);
}

sub edit_tags	{
	my ($action, $Data, $memberID)=@_;
	my $l=$Data->{'lang'};
	my $intro=$l->txt('FIELDS_intro');
	my $assocID=$Data->{'clientValues'}{'assocID'} || 0;
	my $realmID=$Data->{'Realm'} || 0;
	my $subBody=qq[
		<form action="$Data->{'target'}" method="POST">
		
		<table class="permsTable">
	];
	my $unescclient=unescape(setClient($Data->{'clientValues'}));
	my $CurrentTags	= getCurrentTags($Data->{'db'}, $assocID, $memberID, $realmID);
	my $st=qq[
		SELECT intCodeID, strName 
		FROM tblDefCodes
		WHERE (intAssocID=$assocID OR intAssocID=0 )
			AND intRealmID=$realmID
			AND intType= -24
			AND intRecStatus<>$Defs::RECSTATUS_DELETED
			AND (intSubTypeID = $Data->{'RealmSubType'} OR intSubTypeID=0)
		ORDER BY strName
	];
	my $q=$Data->{'db'}->prepare($st);
	$q->execute();
	my $found=0;
	while(my $dref=$q->fetchrow_hashref())	{
		next if !$dref->{'strName'};
		$found=1;
		my $checked= (exists $CurrentTags->{$dref->{'intCodeID'}} and $CurrentTags->{$dref->{'intCodeID'}}==$Defs::RECSTATUS_ACTIVE) ? ' CHECKED ' : '';
		$subBody.=qq[
			<tr>
				<td class="label">$dref->{'strName'}</td>
				<td><input type="checkbox" value="1" name="TG_$dref->{'intCodeID'}" $checked></td>
			</tr>
		];
  }
	$subBody.=qq[
		</table>
		<input type="submit" value="].$l->txt('Save').qq[" class = "button proceed-button">
			<input type="hidden" name="a" value="M_TG_u">
			<input type="hidden" name="client" value="$unescclient">
		</form>
	];
	if($found)	{ $subBody=qq[ <p>$intro</p>$subBody]; }
	else	{ $subBody=qq[<div class="warningmsg">There are no available Tags to assign</div>]; }

	return ($subBody,$l->txt('Member Tags'));

}

sub update_tags {
	my ($action, $Data, $memberID)=@_;
	my $realmID=$Data->{'Realm'} || 0;
	my $assocID=$Data->{'clientValues'}{'assocID'} || 0;

	my %AvailableTags=();
	{
		#Get Total List of Tags
		my $st=qq[
			SELECT intCodeID, strName
			FROM tblDefCodes
			WHERE (intAssocID=$assocID OR intAssocID=0 )
				AND intRealmID=$realmID
				AND intType= -24
				AND intRecStatus<>$Defs::RECSTATUS_DELETED
			ORDER BY strName
		];
		my $q=$Data->{'db'}->prepare($st);
		$q->execute();
		while(my $dref=$q->fetchrow_hashref())  {
			$AvailableTags{$dref->{'intCodeID'}}=$dref->{'strName'}||'';
		}
	}

	my $CurrentTags	= getCurrentTags($Data->{'db'}, $assocID, $memberID, $realmID);

	my $txt_prob=$Data->{'lang'}->txt('Problem updating Fields');
	return qq[<div class="warningmsg">$txt_prob (1)</div>] if $DBI::err;

	my $st_add=qq[
		INSERT INTO tblMemberTags(intRealmID, intAssocID, intTagID, intMemberID, intRecStatus)
			VALUES ($realmID, $assocID, ?, $memberID, $Defs::RECSTATUS_ACTIVE)
	];
	my $st_upd=qq[
		UPDATE tblMemberTags SET intRecStatus=?
			WHERE intRealmID=$realmID 
				AND intAssocID=$assocID 
				AND intMemberID= $memberID
				AND intTagID = ? 
	];
	my $q_add=$Data->{'db'}->prepare($st_add);
	my $q_upd=$Data->{'db'}->prepare($st_upd);
	for my $k (keys %AvailableTags)	{
		next if !param("TG_$k");
		if(exists $CurrentTags->{$k})	{
			if($CurrentTags->{$k} != $Defs::RECSTATUS_ACTIVE)	{
				$q_upd->execute($Defs::RECSTATUS_ACTIVE,$k);
			}
			delete $CurrentTags->{$k};	
		}
		else	{ 
      $q_add->execute($k); 
    } 
    return qq[<div class="warningmsg">$txt_prob (2)</div>] if $DBI::err;
	}
	#Now delete the non-active ones
	for my $k (keys %{$CurrentTags})	{ $q_upd->execute($Defs::RECSTATUS_DELETED, $k);}

  auditLog($memberID, $Data, 'Update', 'Tags');
	return '<div class="OKmsg">'.$Data->{'lang'}->txt('Tags Updated').'</div>';
}

sub getCurrentTags	{
	my($db, $assocID, $memberID, $realmID)=@_;
	my %CurrentTags=();
	return undef if !$db;
	$assocID||=0;
	$memberID||=0;
	$realmID||=0;
	#Get Current List of Active Tags
	my $st=qq[
		SELECT intTagID, intRecStatus
		FROM tblMemberTags
		WHERE intAssocID=$assocID
			AND intRealmID=$realmID
			AND intMemberID=$memberID
	];
	my $q=$db->prepare($st);
	$q->execute();
	while(my $dref=$q->fetchrow_hashref())  {
		$CurrentTags{$dref->{'intTagID'}}=$dref->{'intRecStatus'};
	}
	return \%CurrentTags;
}


## LIST TAGS ##
## Last Updated by TC - 11/9/2007
##
## This allows the user to set all tags to checked or
## unchecked. This will overite all existing selections
## previously made by the user.
##
## IN
## $Data - Contains generic data
## $memberID - The ID of the member for which the Tags are to be displayed
##
## OUT
## $subbody - HTML for page that is to be displayed
## $title - The title of the page that is to be displayed

sub listTags {
	my($Data, $memberID)=@_;
	my $realmID=$Data->{'Realm'} || 0;
	my $assocID=$Data->{'clientValues'}{'assocID'} || 0;
	$memberID||=0;
	my $st = qq[
		SELECT tblDefCodes.intCodeID, tblMemberTags.intRecStatus, tblDefCodes.strName, 
		if (tblMemberTags.intRecStatus=1,'Active','Inactive') AS Status
		FROM tblDefCodes
		LEFT JOIN tblMemberTags ON (tblMemberTags.intTagID=tblDefCodes.intCodeID AND tblMemberTags.intMemberID=$memberID)
		WHERE (tblDefCodes.intAssocID=$assocID OR tblDefCodes.intAssocID = 0 )
			AND tblDefCodes.intRealmID=$realmID
			AND tblDefCodes.intType= -24
			AND tblDefCodes.intRecStatus<>$Defs::RECSTATUS_DELETED
		ORDER BY strName
	];
	my $q=$Data->{'db'}->prepare($st);
	$q->execute();
	my ($activeTags,$inactiveTags)=('','');
	while(my $dref=$q->fetchrow_hashref())  {
		if ($dref->{'Status'} eq "Active") { 
			$activeTags .= "<li>$dref->{'strName'}";
		}
		else {
			$inactiveTags .= "<li>$dref->{'strName'}";
		}
	}
	my $txt=$Data->{'lang'}->txt('This member has been associated with the following tags.');
	my $subBody='';
	if ($activeTags || $inactiveTags) { 
		$activeTags ||= '<li>None</li>';
		$inactiveTags ||= '<li>None</li>';
		$subBody = qq[
			<b>Active</b>
			<ul>$activeTags</ul>
		];
		$subBody .= qq[
			<br>
			<b>Inactive</b>
			<ul>$inactiveTags</ul>
		] if ($Data->{'SystemConfig'}{'ShowInactiveTags'});
	}
	else {
         	$subBody='<div class="warningmsg">'.$Data->{'lang'}->txt('No Tags Found').'</div>';
        }
        my $client=setClient($Data->{'clientValues'});
        $subBody=qq[<p>$txt</p> $subBody ];
        my $chgoptions='';
        $chgoptions=qq[<span class="button-small generic-button"><a href="$Data->{'target'}?client=$client&amp;a=M_TG_E">Edit</a></span>] if allowedAction($Data, 'tag_e');
        $chgoptions=qq[<div class="changeoptions">$chgoptions</div>] if $chgoptions;
 	my $title=$chgoptions.$Data->{'lang'}->txt('Member Tags');
        return ($subBody, $title);

}


## RESET TAGS ##
## Created by TC - 11/9/2007
## Last Updated by TC - 11/9/2007
##
## This allows the user to set all tags to checked or
## unchecked. This will overite all existing selections
## previously made by the user.
##
## IN
## $Data - Contains generic data
## $type - Indicates the DefCodes Type which should be -24
## $action - Contains the current action to perform
## $client - Contains the Client String
##
## OUT
## $body - HTML for page that is to be displayed

sub resetTags {
  my ($Data, $type, $action,$client)=@_;
  my $codeID = param('lki') || -1;
  my $assocID = $Data->{'clientValues'}{'assocID'} || 0;
  my $realmID = $Data->{'Realm'} || 0;
  my $body='';
  my $db = $Data->{'db'};
  if ($codeID==-1 || $assocID==0 || $realmID==0) { return '<p>Error :: Invalid parameters passed in</p>' };
  if ($action eq "A_LK_STOK") {
    my $recstatus = 1;
    my $st = qq[
      UPDATE 
        tblMemberTags
      SET 
        intRecStatus = ?
      WHERE 
        intAssocID = ?
        AND intTagID = ?
        AND intRealmID = ?
    ];
    my $q = $db->prepare($st);
    $q->execute(-1, $assocID, $codeID, $realmID);
    my $st_update_tag = qq[
      UPDATE
        tblMemberTags
      SET
        intRecStatus = ?
      WHERE
        intMemberID = ?
        AND intAssocID = ?
        AND intTagID = ?
        AND intRealmID = ?
    ];
    my $q_update_tag = $db->prepare($st_update_tag);
    my $st_insert_tag = qq[
      INSERT INTO
        tblMemberTags
      (
        intMemberID,
        intRecStatus,
        intAssocID,
        intTagID,
        intRealmID
      )
      VALUES (
        ?,
        ?,
        ?,
        ?,
        ?
      )
    ];
    my $q_insert_tag = $db->prepare($st_insert_tag);
    my $st_select_member = qq[
      SELECT 
        M.intMemberID,
        MT.intTagID
      FROM tblMember AS M
      INNER JOIN tblMember_Associations AS MA ON (MA.intMemberID = M.intMemberID AND MA.intAssocID = ?)
      LEFT JOIN tblMemberTags AS MT ON (
        MT.intMemberID = M.intMemberID 
        AND MT.intTagID = ? 
        AND MT.intAssocID = ? 
        AND MT.intRealmID = ?
      )
      WHERE 
        M.intRealmID = ?
    ];
    my $q_select_member = $db->prepare($st_select_member);
    $q_select_member->execute($assocID, $codeID, $assocID, $realmID, $realmID);
    while (my ($memberID, $tagID) = $q_select_member->fetchrow_array()) {
      next if !$memberID;
      if ($tagID and $tagID == $codeID) {
        #print STDERR qq[UPDATE TAG (1, $memberID, $assocID, $codeID, $realmID)\n];
        $q_update_tag->execute(1, $memberID, $assocID, $codeID, $realmID);
      }
      else {
        #print STDERR qq[ADD TAG ($memberID, 1, $assocID, $codeID, $realmID)\n];
        $q_insert_tag->execute($memberID, 1, $assocID, $codeID, $realmID);
      }
    }
    $body = qq[
      <p>The selected tag has been checked.</p>
      <p><a href="main.cgi?client=$client&a=A_LK_L&t=-24">Back to Member Tags Admin</a></p>
    ];
    auditLog($codeID, $Data, 'Check All', 'Tags');
  }
  elsif ($action eq "A_LK_CTOK") {
    my $recstatus = -1;
    my $st = qq[
      UPDATE tblMemberTags
      SET intRecStatus = ?
      WHERE intAssocID = ?
        AND intTagID = ?
        AND intRealmID = ?
    ];
    my $q = $db->prepare($st);
    $q->execute(-1, $assocID, $codeID, $realmID);
    $body = qq[
      <p>The selected tag has been cleared.</p>
      <p><a href="main.cgi?client=$client&a=A_LK_L&t=-24">Back to Member Tags Admin</a></p>
    ];
    auditLog($codeID, $Data, 'Clear All', 'Tags');
  }
  else {
		my $text = ($action eq 'A_LK_CT') ? "clear" : "check";
		$action = ($action eq 'A_LK_CT') ? "A_LK_CTOK" : "A_LK_STOK";
    my $st = qq[
      SELECT tblDefCodes.strName AS TagName, tblAssoc.strName AS AssocName, tblDefCodes.intAssocID
      FROM tblDefCodes
      LEFT JOIN tblAssoc ON tblAssoc.intAssocID=tblDefCodes.intAssocID
      WHERE tblDefCodes.intCodeID=$codeID
        AND tblDefCodes.intAssocID IN ($assocID, 0)
        AND tblDefCodes.intType=$type
    ];
    my $q = $db->prepare($st);
    $q->execute();
    my ($tagName, $assocName, $assocID) = $q->fetchrow_array();
    return $body = qq[<p>Error :: Unable to identify Tag Name</p>] if (!$tagName);
    if (!$assocName) {
      if ($Data->{'clientValues'}{'authLevel'} < $Defs::LEVEL_ZONE and $assocID == 0) {
        return $body = qq[<p>Error :: You must be logged in a a higher level to use this option for this National Tag</p>];
      }
      elsif ($assocID > 0 or $assocID eq '') {
        return $body = qq[<p>Error :: Unable to identify Association Name</p>];
      }
      else {
        $assocName = "the whole database";
      }
    }
    $body = qq[
      <form method="post" action="main.cgi" name="cleartagfrm">
      <p>You are about to $text ALL the  <b>$tagName</b> tag records for <b>$assocName</b>.</p>
      <p>Once you have clicked on the confirm button there is no way to undo this action and all existing
      selections for this tag will be lost.</p>
      <p>Click on the confirm button to proceed with this action.</p>
      <p><input type="submit" name="submit_btn" value="Confirm"></p>
      <input type="hidden" name="lki" value="$codeID">
      <input type="hidden" name="type" value="$type">
      <input type="hidden" name="client" value="$client">
      <input type="hidden" name="a" value="$action">
      </form>
    ];
  }
  return $body;
}

1;
