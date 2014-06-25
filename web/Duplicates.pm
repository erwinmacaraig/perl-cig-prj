#
# $Header: svn://svn/SWM/trunk/web/Duplicates.pm 11576 2014-05-15 08:00:42Z apurcell $
#

package Duplicates;
require Exporter;
@ISA =  qw(Exporter);
@EXPORT = qw(handleDuplicates isCheckDupl getDuplFields );
@EXPORT_OK = qw(handleDuplicates isCheckDupl getDuplFields );


use strict;
use Reg_common;
use CGI qw(unescape param Vars);
use Utils;
use DeQuote;
#use Member qw(updateMemberNotes);
#use AuditLog;
use Seasons;
# Load the system config Table from the Database 
# Return a reference to a hash containing the values
use MovePhoto;
use Notifications;

sub handleDuplicates {

	my ($action, $Data) = @_;

	my $body='';
	$action||='DUPL_L';
	if($action eq 'DUPL_U')	{
		$body=updateDuplicateProblems($Data) || '';	
		$action='DUPL_L';
	}
	if($action eq 'DUPL_L')	{
		$body.=displayDuplicateProblems($Data) || '';	
	}
	my $title='Duplicate Resolution';

	return ($body,$title);
}

sub displayDuplicateProblems	{
	my ($Data)=@_;
	my $db=$Data->{'db'};

	my $num_field=$Data->{'SystemConfig'}{'GenNumField'} || 'strNationalNum';

	my $realm=$Data->{'Realm'}||0;
	my $entityID= $Data->{'clientValues'}{'clubID'}; #getAssocID($Data->{'clientValues'}) || 0;

	return 'Invalid Option - No Entity' if !$entityID;

	my $duplcheck=isCheckDupl($Data);
	my @FieldsToCheck=getDuplFields($Data);

	return ('Duplicate Checking is not configured') if(!$duplcheck or !@FieldsToCheck);

	#my $st = qq[
	#	SELECT intAllowAutoDuplRes
	#	FROM tblEntity
	#	WHERE intAssocID = $assocID
	#];
	#my $query = $db->prepare($st) or query_error($st);
	#$query->execute or query_error($st);
	#my ($allowAutoDuplRes)=$query->fetchrow_array() || 0;
	
	
	my %SelectFields=(
        strLocalFirstname                => 1, 
        strLocalSurname                  => 1, 
        'tblPerson.strSuburb'       => 1, 
        'tblPerson.strState'        => 1, 
        'tblPerson.strCountry'      => 1, 
        'tblPerson.tTimeStamp'      => 1, 
        'tblPerson.strAddress1'     => 1, 
        'tblPerson.strAddress2'     => 1, 
        'tblPerson.strPostalCode'   => 1, 
        dtDOB                       => 1, 
        $num_field=>1
    );

	for my $k (@FieldsToCheck)	{ 
		$SelectFields{$k}=1; 
	}
	my $fieldlist=join(',',@FieldsToCheck);

	#<RE>
	my ($extraFrom, $extraWhere) = ('', '');
	#RE - added extraFrom, extraWhere to query
	my $selline=join(',',keys %SelectFields) || '';
	my $statement = qq[
		SELECT tblMember_Associations.intAssocID, tblPerson.intPersonID, tblPerson.intPhoto, tblClub.strName AS strClubName, tblMember_Associations.intRecStatus, COUNT(TXN.intTransactionID) as NumPaidTXN, $selline
		FROM tblPerson 
			INNER JOIN tblMember_Associations ON (tblPerson.intPersonID= tblMember_Associations.intPersonID)
			LEFT JOIN tblMember_Clubs ON (tblPerson.intPersonID=tblMember_Clubs.intPersonID AND tblMember_Clubs.intStatus = $Defs::RECSTATUS_ACTIVE) 
			LEFT JOIN tblAssoc_Clubs ON (tblPerson_Clubs.intClubID=tblAssoc_Clubs.intClubID and tblAssoc_Clubs.intAssocID= $assocID)
			LEFT JOIN tblClub ON (tblAssoc_Clubs.intClubID=tblClub.intClubID)
			LEFT JOIN tblTransactions as TXN ON (tblPerson.intPersonID = TXN.intID AND TXN.intTableType=$Defs::LEVEL_MEMBER AND TXN.intStatus=1)
			$extraFrom
		WHERE tblMember_Associations.intAssocID=$assocID
			AND tblPerson.intStatus=$Defs::MEMBERSTATUS_POSSIBLE_DUPLICATE
			AND tblPerson.intRealmID=$realm
			$extraWhere
		GROUP BY tblPerson.intPersonID
		ORDER BY strLocalSurname
	];
	#</RE>

	#Check for Duplicates
	my $wherestr='';

	$query = $db->prepare($statement) or query_error($statement);
	$query->execute or query_error($statement);
	my $where='';
	my %ProbRecords=();
	while(my $dref = $query->fetchrow_hashref())  {
		my $key='';
		my $w='';
		for my $k (@FieldsToCheck)	{ 
			## FIX HERE $dref->{$k} =~ s/\s*$//;
			$dref->{$k} =~ s/\s*$// if ($k =~ /^str/);
			$key.=$dref->{$k}.'|'; 
			$w.=" AND  " if $w;
			$w.=" $k = ".$db->quote($dref->{$k});
		}
		$key=uc($key);
		$ProbRecords{$key}=$dref;
	  $where.= ' OR ' if $where;
		$where.="($w)";
	}
	$query->finish;
	my $body='';
	my $auto_resolved_Count=0;
	my $noduplicates = 0;
	if(scalar(keys %ProbRecords))	{
		my $assocwhere=$duplcheck eq 'assoc' ? " AND tblAssoc.intAssocID=$assocID " : '';
		my $sort = $Data->{'SystemConfig'}{'DuplResSort'} ? $Data->{'SystemConfig'}{'DuplResSort'} : '';
		$sort ||= qq[tblMember_Associations.intRecStatus DESC, ClubStatus DESC, strLocalSurname, strLocalFirstname, dtDOB];
		$statement=qq[
			SELECT tblPerson.intPersonID AS intPersonID, IF(tblClub.intClubID IS NULL, NULL, tblMember_Clubs.intStatus) as ClubStatus, IF(tblClub.intClubID IS NULL, NULL, tblMember_Clubs.intClubID) as ClubID, tblAssoc.intAssocID, tblAssoc.strName, tblPerson.intPhoto, tblClub.strName AS strClubName, tblMember_Associations.intRecStatus, $selline
			FROM tblPerson 
				INNER JOIN tblMember_Associations ON (tblPerson.intPersonID=tblMember_Associations.intPersonID) 
				INNER JOIN tblAssoc ON (tblMember_Associations.intAssocID=tblAssoc.intAssocID)
				LEFT JOIN tblMember_Clubs ON (tblPerson.intPersonID=tblMember_Clubs.intPersonID AND tblMember_Clubs.intStatus = $Defs::RECSTATUS_ACTIVE) 
				LEFT JOIN tblAssoc_Clubs ON (tblMember_Clubs.intClubID=tblAssoc_Clubs.intClubID and tblAssoc_Clubs.intAssocID= tblMember_Associations.intAssocID)
				LEFT JOIN tblClub ON (tblAssoc_Clubs.intClubID=tblClub.intClubID)
			WHERE tblPerson.intRealmID=$realm
				$assocwhere
				AND tblPerson.intStatus <> $Defs::MEMBERSTATUS_POSSIBLE_DUPLICATE
				AND tblPerson.intStatus<>$Defs::MEMBERSTATUS_DELETED
				AND ( $where)
			ORDER BY $sort
		];
			#GROUP BY $fieldlist
#		print STDERR $statement;
				#AND tblPerson.intStatus<>$Defs::MEMBERSTATUS_DELETED
		my $query = $db->prepare($statement) or query_error($statement);
		$query->execute or query_error($statement);
		my $i=0;
		my $cl  = setClient($Data->{'clientValues'});

		my $count=0;
		while(my $orig = $query->fetchrow_hashref())  {
			my $key='';
			for my $k (@FieldsToCheck)	{ 
				$orig->{$k} =~ s/\s*$// if ($k =~ /^str/);
				$key.=$orig->{$k}.'|'; 
			}
			$key=uc($key);
			next if exists $ProbRecords{$key}{'MATCH_FOUND'};
			my $bgcol= $i++%2==0 ? 'ffffff' : 'eeeeee';
			my $origdob=$orig->{'dtDOB'};
			my $dupldob=$ProbRecords{$key}{'dtDOB'};
			my $origtimeStamp=$orig->{'tTimeStamp'};
			my $dupltimeStamp=$ProbRecords{$key}{'tTimeStamp'};

			$ProbRecords{$key}{'MATCH_FOUND'} = 1;
			$orig->{$num_field}||='';
			$ProbRecords{$key}{$num_field}||='';
			$origdob=~s/(\d\d\d\d)-(\d\d)-(\d\d)/$3\/$2\/$1/;
			$dupldob=~s/(\d\d\d\d)-(\d\d)-(\d\d)/$3\/$2\/$1/;
			$origdob='' if $origdob eq '00/00/0000';
			$dupldob='' if $dupldob eq '00/00/0000';

			$origtimeStamp=~s/\s.*$// if $origtimeStamp;
			$dupltimeStamp=~s/\s.*$// if $dupltimeStamp;
			$origtimeStamp=~s/(\d\d\d\d)-(\d\d)-(\d\d)/$3\/$2\/$1/ if $origtimeStamp;
			$dupltimeStamp=~s/(\d\d\d\d)-(\d\d)-(\d\d)/$3\/$2\/$1/ if $dupltimeStamp;
			$origtimeStamp='' if $origtimeStamp eq '00/00/0000';
			$dupltimeStamp='' if $dupltimeStamp eq '00/00/0000';

			my $duplicate_member_id=$ProbRecords{$key}{intPersonID};
			my $origphoto='';
			my $probphoto='';
			if($orig->{intPhoto})	{
				my %cv=%{$Data->{'clientValues'}};
				$cv{'currentLevel'}=$Defs::LEVEL_MEMBER;
				$cv{'personID'}=$orig->{intPersonID};
				my $c =setClient(\%cv);	
				$origphoto=qq[ <div><img width="200px;" src="getphoto.cgi?client=$c"></div> ];
			}
			if($ProbRecords{$key}{intPhoto})	{
				my %cv=%{$Data->{'clientValues'}};
				$cv{'currentLevel'}=$Defs::LEVEL_MEMBER;
				$cv{'personID'}=$duplicate_member_id;
				my $c =setClient(\%cv);	
				$probphoto=qq[ <div><img width="200px;" src="getphoto.cgi?client=$c&amp"></div> ];
			}			
					#<td class="label" style="padding:3px;background:#$bgcol;border-bottom:solid 1px #bbbbbb;vertical-align:top;font-family:Verdana">
			$ProbRecords{$key}{'strClubName'} ||='';
			$orig->{strClubName}||='';
			my %statuses=($Defs::RECSTATUS_ACTIVE=> 'Active', $Defs::RECSTATUS_INACTIVE => 'Inactive');
			if($Data->{'SystemConfig'}{'DuplResolveSameNatNum'})	{
				if(resolved_automatically($Data, $orig, $ProbRecords{$key}))	{
					$auto_resolved_Count++;
					next;
				}
			}

			$count++;
			next if $count >=300;
			my $rows_count=13;
			## Build up row span depending on which fields will show below
			$rows_count ++ if ($ProbRecords{$key}{'strAddress1'} or $orig->{strAddress1});
			$rows_count ++ if ($ProbRecords{$key}{'strAddress2'} or $orig->{strAddress2});
			$rows_count ++ if ($ProbRecords{$key}{'strPostalCode'} or $orig->{strPostalCode});

			my %cv=%{$Data->{'clientValues'}};
			$cv{'currentLevel'}=$Defs::LEVEL_MEMBER;
			$cv{'personID'}=$orig->{'intPersonID'};
			my $c =setClient(\%cv);	
			my $viewMoreLink = qq[viewdupl.cgi?client=$c&a=DUPL_more];
			my $viewMore = qq[<div><a href = "#" onclick = "dialogform('$viewMoreLink','View Duplicate Information');return false;">View more details...</a></div>];
			$body.=qq[
				<tr>
					<td style="padding:3px;background:#$bgcol;">&nbsp;</td>
					<td style="padding:3px;background:#$bgcol;border-bottom:solid 1px #000000"><b>Problem Record</b><br>(New Record)</td>
					<td style="padding:3px;background:#$bgcol;">&nbsp;</td>
					<td style="padding:3px;background:#$bgcol;border-bottom:solid 1px #000000"><b>Suggested Match</b><br>(Existing Online Data)$viewMore</td>
					<td style="padding:3px;background:#$bgcol;">&nbsp;</td>
				</tr>
				<tr>
					<td class="label" style="background:#$bgcol;">Firstname&nbsp;</td>
					<td class="value" style="background:#$bgcol;">$ProbRecords{$key}{'strLocalFirstname'}</td>
					<td style="padding:3px;background:#$bgcol;border-bottom:solid 1px #bbbbbb" rowspan="$rows_count"><span style="font-size:14px;padding:16px;">= ?</span></td>
					<td class="value" style="background:#$bgcol;">$orig->{strLocalFirstname}</td>
					<td style="padding:6px;padding-left:20px;background:#$bgcol;border-bottom:solid 1px #bbbbbb;vertical-align:top;" rowspan="$rows_count">
						<b>Choose option</b><br>
							<input type="hidden" name="matchNum$duplicate_member_id" value="$orig->{intPersonID}">
							<input type="radio" name="proboption$duplicate_member_id" value="matchusenew" onclick="return showwarning('matchusenew');" class="nb">This is the same person (Merge using new data as the base)<br>
							<input type="radio" name="proboption$duplicate_member_id" value="matchuseold" onclick="return showwarning('matchuseold');" class="nb">This is the same person (keep existing data)<br>
							<input type="radio" name="proboption$duplicate_member_id" value="new" onclick="return showwarning('new');" class="nb">This is a new person<br>
			];
			if ($ProbRecords{$key}{'NumPaidTXN'})	{
				$body .= qq[<br><i>Person has paid Transactions, cannot be deleted</i><br><br>];
			}
			else	{
				$body .= qq[
							<input type="radio" name="proboption$duplicate_member_id" value="del" onclick="return showwarning('del');" class="nb">Oops, delete this person<br>
				];
			}
			$body .= qq[
							<input type="radio" name="proboption$duplicate_member_id" checked value="ignore" onclick="return showwarning('ignore');" class="nb">Ignore this person for now<br>
							<br>
					</td>
				</tr>
				<tr>
					<td class="label" style="background:#$bgcol;">Surname&nbsp;</td>
					<td class="value" style="background:#$bgcol;">$ProbRecords{$key}{'strLocalSurname'}</td>
					<td class="value" style="background:#$bgcol;">$orig->{strLocalSurname}</td>
				</tr>
				<tr>
					<td class="label" style="background:#$bgcol;">Date of Birth&nbsp; </td>
					<td class="value" style="background:#$bgcol;">$dupldob </td>
					<td class="value" style="background:#$bgcol;">$origdob</td>
				</tr>
			];

			$body .= qq[
				<tr>
					<td class="label" style="background:#$bgcol;">Address 1&nbsp;</td>
					<td class="value" style="background:#$bgcol;">$ProbRecords{$key}{'strAddress1'}</td>
					<td class="value" style="background:#$bgcol;">$orig->{strAddress1}</td>
				</tr>
			] if ($ProbRecords{$key}{'strAddress1'} or $orig->{strAddress1});

			$body .= qq[
				<tr>
					<td class="label" style="background:#$bgcol;">Address 2&nbsp;</td>
					<td class="value" style="background:#$bgcol;">$ProbRecords{$key}{'strAddress2'}</td>
					<td class="value" style="background:#$bgcol;">$orig->{strAddress2}</td>
				</tr>
			] if ($ProbRecords{$key}{'strAddress2'} or $orig->{strAddress2});

			$body .= qq[
				<tr>
					<td class="label" style="background:#$bgcol;">Postal Code&nbsp;</td>
					<td class="value" style="background:#$bgcol;">$ProbRecords{$key}{'strPostalCode'}</td>
					<td class="value" style="background:#$bgcol;">$orig->{strPostalCode}</td>
				</tr>
			] if ($ProbRecords{$key}{'strPostalCode'} or $orig->{strPostalCode});

			$body .= qq[
				<tr>
					<td class="label" style="background:#$bgcol;">Suburb&nbsp;</td>
					<td class="value" style="background:#$bgcol;">$ProbRecords{$key}{'strSuburb'}</td>
					<td class="value" style="background:#$bgcol;">$orig->{strSuburb}</td>
				</tr>
				<tr>
					<td class="label" style="background:#$bgcol;">State&nbsp;</td>
					<td class="value" style="background:#$bgcol;">$ProbRecords{$key}{'strState'}</td>
					<td class="value" style="background:#$bgcol;">$orig->{strState}</td>
				</tr>
				<tr>
					<td class="label" style="background:#$bgcol;">Country&nbsp;</td>
					<td class="value" style="background:#$bgcol;">$ProbRecords{$key}{'strCountry'}</td>
					<td class="value" style="background:#$bgcol;">$orig->{strCountry}</td>
				</tr>
				<tr>
					<td class="label" style="background:#$bgcol;">$Data->{'LevelNames'}{$Defs::LEVEL_ASSOC}&nbsp;</td>
					<td class="value" style="background:#$bgcol;">&nbsp;</td>
					<td class="value" style="background:#$bgcol;">$orig->{strName}</td>
				</tr>
				<tr>
					<td class="label" style="background:#$bgcol;">Status&nbsp;</td>
					<td class="value" style="background:#$bgcol;">$statuses{$ProbRecords{$key}{'intRecStatus'}}</td>
					<td class="value" style="background:#$bgcol;">$statuses{$orig->{intRecStatus}}</td>
				</tr>
				<tr>
					<td class="label" style="background:#$bgcol;">$Data->{'LevelNames'}{$Defs::LEVEL_CLUB}&nbsp;</td>
					<td class="value" style="background:#$bgcol;">$ProbRecords{$key}{'strClubName'}</td>
					<td class="value" style="background:#$bgcol;">$orig->{strClubName}</td>
				</tr>
				<tr>
					<td class="label" style="background:#$bgcol;">Number&nbsp;</td> 
					<td class="value" style="background:#$bgcol;">$ProbRecords{$key}{$num_field}</td>
					<td class="value" style="background:#$bgcol;">$orig->{$num_field}</td>
				</tr>
				<tr>
					<td class="label" style="background:#$bgcol;border-bottom:solid 1px #bbbbbb;">&nbsp;</td> 
					<td class="value" style="background:#$bgcol;border-bottom:solid 1px #bbbbbb;">&nbsp;</td>
					<td class="value" style="background:#$bgcol;border-bottom:solid 1px #bbbbbb;">$origphoto</td>
				</tr>
			];
			#last if $count >=300;
		}
		my $resolved_Count = 0;
		foreach my $key (keys %ProbRecords)	{
			next if exists $ProbRecords{$key}{'MATCH_FOUND'} ;
			my $intPersonID_toResolve =$ProbRecords{$key}{intPersonID} || 0;
			$resolved_Count++;
			if ($intPersonID_toResolve)	{
				my $st = qq[
					UPDATE tblPerson
					SET intStatus = $Defs::MEMBERSTATUS_ACTIVE
					WHERE intStatus = $Defs::MEMBERSTATUS_POSSIBLE_DUPLICATE
						AND intPersonID = $intPersonID_toResolve
					LIMIT 1
				];
				my $qry_resolve = $db->prepare($st) or query_error($st);
				$qry_resolve->execute or query_error($st);
			}
		}
		my $Resolved_body = '';
		$Resolved_body .= qq[<p class="OKmsg"> $auto_resolved_Count member(s) were automatically resolved due to action based on the national identification scheme.</p>] if $auto_resolved_Count;
		$Resolved_body .= qq[<p class="OKmsg"> $resolved_Count member(s) were automatically resolved due to previously matching record being changed.</p>] if $resolved_Count;
		my $limit300 = ($count >= 299) ? qq[<p>This list has been limited to the first 300 duplicates.</p>] : '';

		my $autoBody = '';
		#$autoBody .= qq[
		#	<br>
		#	<b>This $Data->{'LevelNames'}{$Defs::LEVEL_ASSOC} allows Bulk Duplicate Resolution, please select an option below</b><br>
		#	<i>NOTE: This option only applies to individuals marked as <b>Ignore this person for now</b>.<br>Any option set against an individual duplicate will be applied.</i><br><br>
		#	<input type="radio" name="autooption" value="matchusenew" onclick="return showwarning('matchusenew');" class="nb">These are the same people as the Duplicate (Merge using new data as the base)<br>
		#	<input type="radio" name="autooption" value="matchuseold" onclick="return showwarning('matchuseold');" class="nb">These are the same people as the Duplicate (keep existing data)<br>
		#	<input type="radio" name="autooption" value="new" onclick="return showwarning('new');" class="nb">These are all new people<br>
		#	<input type="radio" name="autooption" value="del" onclick="return showwarning('del');" class="nb">Oops, delete all these people<br>
		#	<input type="radio" name="autooption" checked value="ignore" onclick="return showwarning('ignore');" class="nb">Don't bulk resolve<br>
		#] if ($allowAutoDuplRes); #'
			
	
		$body=qq[
			$Resolved_body
			<p>The list below is of people that have been added that match another person within the database. </p>
			<p> To resolve the problem you must choose one of the options beside each person and then press the 'Update Duplicates' button.</p>
			$limit300

			<form action="$Data->{'target'}" method="post" name="duplform">
			<script language="JavaScript1.2" type="text/javascript">
				function showwarning (type)	{
					var msg = "";
					if(!document['duplform'].showwarnings.checked) {
						return true;
					}
					switch(type)	{
						case "del":
							msg="This option will delete all information about this person from the system.  You will not be able to get it back.";
							break;
						case "matchusenew":
							msg="This option will merge the new member with the existing.  It will use data from the new record, unless blank where it will check for existing data."; 
							break;
						case "matchuseold":
							msg="This option will discard the new details of the duplicate and use the details of the matching person already online.";
							break;
					}
					if(msg != "") {
						return confirm(msg);
					}
					return true;
				}				
			</script>

							<input type="checkbox" name="showwarnings" checked><b> Show warnings</b>
							
<br>
$autoBody
<br>
							<input type="submit" value="Update Duplicates" class="button proceed-button">
	<div style="clear:both;"></div>		
	<table border="0" cellpadding="0" cellspacing="0">
				$body
			</table>
							<input type="hidden" name="client" value="].unescape($cl).qq[">
							<input type="hidden" name="a" value="DUPL_U"><br><br>
							<input type="submit" value="Update Duplicates" class="button proceed-button">
			</form>
		] if $body;
		$query->finish;
		$noduplicates = 1 if !$body;
		$body=qq[$Resolved_body<br><p>There are no possible duplicates that need to be resolved.</p>] if !$body;
	}
	else	{
		$noduplicates = 1;
		$body=qq[<p>There are no possible duplicates that need to be resolved.</p>];
	}
	if($noduplicates)	{
		deleteNotification(
			$Data,
			$Defs::LEVEL_ASSOC,
			$assocID,
			0,
			'duplicates',
			0,
		);
	}

	return $body;
}

sub newRecord_TouchTables       {

        my ($Data, $personID) = @_;

        $personID || return;
	my $MStablename = "tblMember_Seasons_$Data->{'Realm'}";
        my @Tables = (qw(tblMember_Associations tblMember_Clubs tblClearance));
        foreach my $table (@Tables)     {
                my $st='';
                $st = qq[
                        UPDATE $table
                        SET tTimeStamp = NOW()
                        WHERE intPersonID = $personID
                ];
                $Data->{'db'}->do($st);
        }
	my $st = qq[
		UPDATE $MStablename
        	SET tTimeStamp = NOW()
        	WHERE intPersonID = $personID
        ];
        $Data->{'db'}->do($st);
        return;

}
sub updateDuplicateProblems	{
	my ($Data) = @_;
	my $num_field=$Data->{'SystemConfig'}{'GenNumField'} || 'strNationalNum';
	my %params=Vars();
	my $autoOption = $params{'autooption'} || 'ignore';
	for my $k (keys %params)	{
		if($k =~/^proboption/)	{
			my ($id_of_duplicate)=$k=~/proboption(\d+)/;
			my $option=$params{$k} || 'ignore';
			$option = $autoOption if ($option eq 'ignore' and $autoOption ne 'ignore'); #'

			#First we should check that this person is actually part of this associ
			my $inentity=checkEntity($Data->{'db'},$Data->{'Realm'}, $id_of_duplicate, $Data->{'clientValues'}{'clubID'}) || 0;

			return '<div class="warning">Invalid attempt to modify a Member </div>' if !$inentity;
			my $id_of_existing=$params{"matchNum$id_of_duplicate"} || 0;
			if($option eq 'new')	{
				my $st=qq[UPDATE tblPerson SET intStatus = $Defs::MEMBERSTATUS_ACTIVE WHERE intPersonID=$id_of_duplicate];
				$Data->{'db'}->do($st);
				newRecord_TouchTables($Data, $id_of_duplicate);
			}
			elsif($option eq 'del')	{
				processMemberChange($Data,$id_of_duplicate,0,'del');
			}
			elsif($option eq 'matchusenew')	{
				processMemberChange($Data,$id_of_duplicate,$id_of_existing,'change_usenew') if $id_of_existing;
			}
			elsif($option eq 'matchuseold')	{
				processMemberChange($Data,$id_of_duplicate,$id_of_existing,'change_useold') if $id_of_existing;
			}
		}
	}
	return '<div class="OKmsg">Records Updated</div>';
}



sub checkEntity {
	my ($db,$realmID, $personID, $assocID)=@_;
	$personID ||= 0;
	$assocID ||= 0;
	my $st=qq[
		SELECT intPersonID 
		FROM tblPersonRegistration_$realmID
		WHERE intEntityID=$entityID AND intPersonID=$personID
	];
	my $q=$db->prepare($st);
	$q->execute();
	my ($id)=$q->fetchrow_array();
	$q->finish();
	return $id||0;
}


sub processMemberChange	{
	my ($Data,$id_of_duplicate, $existingid, $option)=@_;

	my %StatusTables	=(
		#tblMember_Associations => 'intRecStatus',
		tblMember_Clubs => 'intStatus',
		tblAccreditation => 'intRecStatus',
	);
	for my $table (keys %StatusTables)	{
		my $st='';
#		if($option eq 'del')	{ 
#			$st=qq[UPDATE $table SET $StatusTables{$table}=$Defs::RECSTATUS_DELETED WHERE intPersonID=$id_of_duplicate];
#		}
		if($option =~ /^change/)	{ 
			#Update the extraneous tables
			$st=qq[UPDATE IGNORE $table SET intPersonID=$existingid WHERE intPersonID=$id_of_duplicate]; 
			
			if ($table eq 'tblMember_Clubs')	{
				$st = qq[UPDATE tblMember_Clubs as MC LEFT JOIN tblMember_Clubs as MC2 ON (MC2.intPersonID = $existingid and MC.intClubID = MC2.intClubID and MC.intStatus = MC2.intStatus) SET MC.intPersonID = $existingid WHERE MC.intPersonID = $id_of_duplicate and MC2.intMemberClubID IS NULL];
			}
			if ($table eq 'tblAccreditation')	{
				$st = qq[UPDATE IGNORE tblAccreditation SET intPersonID=$existingid WHERE intPersonID=$id_of_duplicate];
			}
			$Data->{'db'}->do($st);	
		}
			#$Data->{'db'}->do($st);	
	}
	my $natnum = '';
	my $dtCreatedOnline = '';
	my $umpirePassword= '';
	my $memberNo = '';
	my $DCO= '';
	my %USE_DATA=();
	$USE_DATA{'CreatedFrom'} = 0;
	if ($option =~ /^change/)	{
		my $st = qq[
			SELECT 
				strNationalNum,
				DATE_FORMAT(dtCreatedOnline, "%Y%m%d") as DCO,
                strMemberNo,
                intCreatedFrom
			FROM 
				tblPerson 
			WHERE 
				intPersonID IN ($id_of_duplicate, $existingid) 
			ORDER BY 
				intPersonID ASC 
		];	
		my $q=$Data->{'db'}->prepare($st);
		$q->execute();
		
		while (my $dref = $q->fetchrow_hashref())	{
			$natnum = $dref->{'strNationalNum'} if ! $natnum and $dref->{'strNationalNum'};
			$memberNo= $dref->{'strMemberNo'} if ! $memberNo and $dref->{'strMemberNo'};
			if (! $dtCreatedOnline and $dref->{'DCO'} and $dref->{'DCO'} > '00000000')	{
				$dtCreatedOnline = $dref->{'dtCreatedOnline'};
				$DCO= $dref->{'DCO'};
			}
			elsif ($DCO and $dref->{'DCO'}  and $dref->{'DCO'} > '00000000' and $dref->{'DCO'} < $DCO)	{
				$dtCreatedOnline = $dref->{'dtCreatedOnline'};
				$DCO= $dref->{'DCO'};
			}
			$USE_DATA{'CreatedFrom'} = $dref->{intCreatedFrom} if (
                $dref->{'intCreatedFrom'} > $USE_DATA{'CreatedFrom'} 
                and $USE_DATA{'CreatedFrom'} !=  $Defs::CREATED_BY_REGOFORM
            );
		}
		$USE_DATA{'MemberNo'} = $memberNo || '';

		$st = qq[
			SELECT 
				intPersonID,
				intRecStatus
			FROM 
				tblMember_Associations
			WHERE
				intPersonID IN ($id_of_duplicate, $existingid)
				AND intAssocID = $Data->{'clientValues'}{'assocID'}
		];	
		$q=$Data->{'db'}->prepare($st);
		$q->execute();
		while (my $dref= $q->fetchrow_hashref())	{
			$USE_DATA{'intRecStatus'} = $dref->{'intRecStatus'} if ! $USE_DATA{'intRecStatus'};
		}
		
	}

	if($option eq 'change_usenew')	{
		#Get the Data rom the new record
		my $st=qq[SELECT * FROM tblPerson where intPersonID=$id_of_duplicate LIMIT 1];
		my $q=$Data->{'db'}->prepare($st);
		$q->execute();
		my $dref=$q->fetchrow_hashref();
		$q->finish();
		deQuote($Data->{'db'},$dref);
		my $update_str='';	
		$dref->{'intStatus'}=$Defs::MEMBERSTATUS_ACTIVE;
		for my $k (keys %{$dref})	{

			next if !defined $dref->{$k};

next if ! $dref->{$k};
next if $dref->{$k} eq '';
next if $dref->{$k} eq "''";
next if $dref->{$k} eq "'0000-00-00'";

			next if $k eq 'intPersonID';
			next if $k eq 'strNationalNum';
			next if $k eq 'intPhoto' and ! $dref->{'intPhoto'};
			next if $k eq 'intPlayer' and ! $dref->{'intPlayer'};
			next if $k eq 'intCoach' and ! $dref->{'intCoach'};
			next if $k eq 'intUmpire' and ! $dref->{'intUmpire'};
			next if $k eq 'strMemberNo' and ! $dref->{'strMemberNo'};
			next if $k eq 'intCreatedFrom' and ! $dref->{'intCreatedFrom'};
			
			$dref->{'dtCreatedOnline'} = qq['$dtCreatedOnline'] if $dref->{'dtCreatedOnline'} ;

			next if $dref->{$k} eq 'NULL';
			$dref->{$k} ="''" if $dref->{$k} eq 'NULL';
			$update_str.=',' if $update_str;
			$update_str.= " $k = $dref->{$k} ";
		}
		
		#OK now set the Existing record with the new data from
		my $updst=qq[UPDATE tblPerson SET $update_str WHERE intPersonID=$existingid];
		$Data->{'db'}->do($updst);	
		
		{
                        ### FOR MEMBER_ASSOCIATIONS TABLE !!    
                my $intAssocID = $Data->{'clientValues'}{'assocID'} || 0;
                        my $st=qq[SELECT * FROM tblMember_Associations where intPersonID=$id_of_duplicate AND intAssocID = $intAssocID LIMIT 1];
                        my $q=$Data->{'db'}->prepare($st);
                        $q->execute();
                        my $dref=$q->fetchrow_hashref();
                        $q->finish();
                        deQuote($Data->{'db'},$dref);
                        my $update_str='';
                        #$dref->{'intStatus'}=$Defs::MEMBERSTATUS_ACTIVE;
                        my $recordFound=0;
                        for my $k (keys %{$dref})       {
                                $recordFound=1;
                                next if !defined $dref->{$k};

next if $dref->{$k} eq '';
next if $dref->{$k} eq "''";
next if $dref->{$k} eq "'0000-00-00'";
                                next if $k eq 'intPersonID';
                                next if $k eq 'intMemberAssociationID';
                                next if $k eq 'intAssocID';
                                next if $k eq 'intRecStatus';

                                next if $dref->{$k} eq 'NULL';
                                $dref->{$k}="''" if $dref->{$k} eq 'NULL';
                                $update_str.=',' if $update_str;
                                $update_str.= " $k = $dref->{$k} ";
                        }

                        #OK now set the Existing record with the new data from
                        if ($recordFound)       {
                                my $updst=qq[UPDATE tblMember_Associations SET $update_str WHERE intPersonID=$existingid AND intAssocID = $intAssocID LIMIT 1];
#print STDERR "UPDATE DUPLICATE $updst\n";
                                $Data->{'db'}->do($updst);
                        }
                }
	}
    
    my $memberNoUpdate = $USE_DATA{'MemberNo'} ? qq[ strMemberNo="$USE_DATA{'MemberNo'}", ] : '';
    my $createdFrom = $USE_DATA{'CreatedFrom'} ? qq[ intCreatedFrom =$USE_DATA{'CreatedFrom'}, ] : '';
	if ($option =~ /^change/ and $natnum)	{
		my $updst=qq[UPDATE tblPerson SET $memberNoUpdate $createdFrom strNationalNum = '$natnum' WHERE intPersonID=$existingid];
		$Data->{'db'}->do($updst);	
	}
	elsif ($option =~ /^change/ and ($memberNoUpdate or $createdFrom))	{
		my $updst=qq[UPDATE tblPerson SET $memberNoUpdate $createdFrom  WHERE intPersonID=$existingid];
		$Data->{'db'}->do($updst);	
	}

	if($option eq 'del')	{ 
		my $intAssocID = $Data->{'clientValues'}{'assocID'} || 0;
		$Data->{'db'}->do(qq[UPDATE tblMember_Clubs as MC INNER JOIN tblAssoc_Clubs as AC ON (AC.intClubID = MC.intClubID) SET MC.intStatus=$Defs::RECSTATUS_DELETED WHERE MC.intPersonID=$id_of_duplicate and AC.intAssocID = $intAssocID]);
		$Data->{'db'}->do(qq[UPDATE tblMember_Associations SET intRecStatus=$Defs::RECSTATUS_DELETED WHERE intPersonID=$id_of_duplicate and intAssocID = $intAssocID]);
#print STDERR "DELETE DUPLICATE: $id_of_duplicate and intAssocID = $intAssocID\n";
		$Data->{'db'}->do(qq[UPDATE tblPerson as M LEFT JOIN tblMember_Associations as MA ON (MA.intPersonID = M.intPersonID and MA.intAssocID <> $intAssocID) SET M.intStatus=$Defs::RECSTATUS_DELETED WHERE M.intPersonID=$id_of_duplicate and MA.intMemberAssociationID IS NULL]);
		$Data->{'db'}->do(qq[UPDATE tblPerson as M LEFT JOIN tblMember_Associations as MA ON (MA.intPersonID = M.intPersonID and MA.intAssocID <> $intAssocID) SET M.intStatus=$Defs::RECSTATUS_ACTIVE WHERE M.intPersonID=$id_of_duplicate and MA.intMemberAssociationID IS NOT NULL]);
	}
	elsif($option =~ /^change/)	{ 
        $Data->{'db'}->do(qq[UPDATE tblTempMember SET intRealID = $existingid WHERE intRealID=$id_of_duplicate]);
		$Data->{'db'}->do(qq[UPDATE tblTransactions SET intID = $existingid WHERE intID = $id_of_duplicate and intTableType=$Defs::LEVEL_MEMBER]);
		$Data->{'db'}->do(qq[UPDATE tblClearance SET intPersonID = $existingid WHERE intPersonID=$id_of_duplicate]);
		$Data->{'db'}->do(qq[UPDATE IGNORE tblAuth SET intID = $existingid WHERE intLevel=1 AND intID=$id_of_duplicate]);
		my $realmID = $Data->{'Realm'};

		$Data->{'db'}->do(qq[UPDATE tblMember_Associations SET intRecStatus=$Defs::RECSTATUS_ACTIVE WHERE intPersonID=$existingid and intAssocID = $Data->{'clientValues'}{'assocID'} and intRecStatus = $Defs::RECSTATUS_DELETED LIMIT 1]);
		$Data->{'db'}->do(qq[UPDATE tblUploadedFiles SET intEntityID = $existingid WHERE intEntityID=$id_of_duplicate and intEntityTypeID=1]);

		my @assoc=();
		my $assoc_st = qq[
			SELECT DISTINCT intAssocID
			FROM tblMember_Associations
			WHERE intPersonID = $id_of_duplicate
		];
		my $qry_assoc=$Data->{'db'}->prepare($assoc_st);
		$qry_assoc->execute();
		while (my $aref=$qry_assoc->fetchrow_hashref())	{
			push @assoc, $aref->{intAssocID};
			my $assocID =  $aref->{intAssocID};
		    $Data->{'db'}->do(qq[UPDATE tblMember_Associations SET intRecStatus=$Defs::RECSTATUS_ACTIVE WHERE intPersonID=$existingid and intAssocID = $assocID and intRecStatus = $Defs::RECSTATUS_DELETED LIMIT 1]);
		
			my $st = qq[
				SELECT intPersonID, intTypeID, COUNT(intMemberTypeID) as count
				FROM tblMember_Types
				WHERE intPersonID IN ($existingid)
					AND intAssocID = $assocID
					AND intSubTypeID = 0
					AND intRecStatus= $Defs::RECSTATUS_ACTIVE
				GROUP BY intPersonID, intTypeID
			];
			my $query = $Data->{'db'}->prepare($st) or query_error($st);
			$query->execute or query_error($st);
			my %MemberTypes = ();
			while(my $dref = $query->fetchrow_hashref())  {
				$MemberTypes{$dref->{intTypeID}} = $dref->{count} || 0;
			}
			for my $type (1..5)	{
				if ($MemberTypes{$type} > 0)	{
					$Data->{'db'}->do(qq[UPDATE tblMember_Types SET intRecStatus=$Defs::RECSTATUS_DELETED WHERE intPersonID=$id_of_duplicate AND intTypeID = $type AND intSubTypeID=0 AND intAssocID = $assocID]);
					$Data->{'db'}->do(qq[UPDATE tblMember_Types SET intRecStatus=$Defs::RECSTATUS_DELETED WHERE intPersonID=$existingid AND intTypeID = $type AND intSubTypeID=0 AND intAssocID = $assocID AND intRecStatus = $Defs::RECSTATUS_INACTIVE]);
				}
				else	{
					$Data->{'db'}->do(qq[UPDATE tblMember_Types SET intRecStatus=$Defs::RECSTATUS_DELETED WHERE intPersonID=$existingid AND intTypeID = $type AND intSubTypeID=0 AND intAssocID = $assocID AND intRecStatus = $Defs::RECSTATUS_INACTIVE]);
					$Data->{'db'}->do(qq[UPDATE tblMember_Types SET intPersonID = $existingid WHERE intPersonID=$id_of_duplicate AND intTypeID = $type AND intSubTypeID=0 AND intAssocID = $assocID AND intRecStatus = $Defs::RECSTATUS_ACTIVE]);
				}
			}
			Seasons::memberSeasonDuplicateResolution($Data, $assocID, $id_of_duplicate, $existingid);	
			$Data->{'db'}->do(qq[
          		      INSERT INTO tblDuplChanges (intAssocID, intNewID, intOldID)
                		VALUES ($assocID, $existingid, $id_of_duplicate)
        		]);

		}

		$Data->{'db'}->do(qq[UPDATE tblMember_Associations as MA LEFT JOIN tblMember_Associations as MA2 ON (MA2.intPersonID = $existingid and MA.intAssocID = MA2.intAssocID) SET MA.intPersonID=$existingid WHERE MA.intPersonID = $id_of_duplicate and MA2.intMemberAssociationID IS NULL AND MA.intAssocID=$Data->{'clientValues'}{'assocID'}]);

		$Data->{'db'}->do(qq[UPDATE IGNORE tblMember_Associations as MA LEFT JOIN tblMember_Associations as MA2 ON (MA2.intPersonID = $existingid and MA.intAssocID = MA2.intAssocID) SET MA.intPersonID=$existingid WHERE MA.intPersonID = $id_of_duplicate and MA2.intMemberAssociationID IS NULL AND MA.intAssocID<> $Data->{'clientValues'}{'assocID'}]);

	        $Data->{'db'}->do(qq[UPDATE IGNORE tblMember_Associations as MA SET MA.intRecStatus = $Defs::RECSTATUS_ACTIVE WHERE MA.intPersonID=$existingid  and MA.intRecStatus =$Defs::RECSTATUS_DELETED AND MA.intAssocID= $Data->{'clientValues'}{'assocID'}]);
		$Data->{'db'}->do(qq[DELETE FROM tblMember_Associations WHERE intPersonID=$id_of_duplicate AND intAssocID=$Data->{'clientValues'}{'assocID'}]);

		###### HANDLE dates IF USE EXISTING
		my $update_vals = '';
		### This is the fix for -1 in tblMember_Associations
		$USE_DATA{intRecStatus}=1 if ($USE_DATA{intRecStatus}<0);
		$update_vals .= qq[ intRecStatus = $USE_DATA{intRecStatus} ];

		if ($update_vals)	{
			my $st = qq[
				UPDATE tblMember_Associations SET $update_vals WHERE intPersonID = $existingid AND intAssocID = $Data->{'clientValues'}{'assocID'}
			];
			$Data->{'db'}->do($st);
		}
		######

		$Data->{'db'}->do(qq[DELETE M.* FROM tblPerson as M LEFT JOIN tblMember_Associations as MA ON (MA.intPersonID = M.intPersonID and MA.intAssocID <> $Data->{'clientValues'}{'assocID'}) WHERE M.intPersonID=$id_of_duplicate and MA.intMemberAssociationID IS NULL]);
		if ($option eq 'del')	{
			$Data->{'db'}->do(qq[UPDATE tblPerson SET intStatus=$Defs::RECSTATUS_ACTIVE WHERE intPersonID=$id_of_duplicate]);
		}
		$Data->{'db'}->do(qq[UPDATE tblPerson SET intStatus=$Defs::RECSTATUS_ACTIVE WHERE intPersonID=$existingid ]);
		movePhoto($Data->{'db'}, $existingid, $id_of_duplicate);
	}
  #auditLog(0, $Data, 'Resolve', 'Duplicates');
}

sub isCheckDupl	{
	my($Data)=@_;
    return '' if ($Data->{'ReadOnlyLogin'} and !$Data->{'SystemConfig'}{'ShowDCWhenRO'});
	my $check_dupl='';

	#Duplicates should also be checked for unless specifically disabled
	if (exists $Data->{'SystemConfig'}{'DuplCheck'}) {
        return 'realm' if $Data->{'SystemConfig'}{'DuplCheck'} eq '1'; 
        return ''      if $Data->{'SystemConfig'}{'DuplCheck'} eq '-1'; #Don't check dup; 
	}
	if (exists $Data->{'Permissions'}{'OtherOptions'} and 
        exists $Data->{'Permissions'}{'OtherOptions'}{'DuplCheck'} and 
        $Data->{'Permissions'}{'OtherOptions'}{'DuplCheck'}[0] eq '-1')	{
		    return ''; #Explicitly turned off
	}
	return 'assoc';
}

sub getDuplFields	{
    my($Data)=@_;
    my $duplfields=$Data->{'SystemConfig'}{'DuplicateFields'} 
        || $Data->{'Permissions'}{'OtherOptions'}{'DuplFields'} 
        || 'strLocalSurname|strLocalFirstname|dtDOB';
    my @FieldsToCheck=split /\|/,$duplfields;
    return @FieldsToCheck;
}

sub	resolved_automatically	{
	my($Data, $orig, $dupl)=@_;

	return 0 if !$Data->{'SystemConfig'}{'DuplResolveSameNatNum'};
 	my $num_field=$Data->{'SystemConfig'}{'GenNumField'} || 'strNationalNum';

	#this only works if both records have the same national ID
	# Check that first
	return 0 if !$orig->{$num_field};
	return 0 if !$dupl->{$num_field};
	return 0 if $dupl->{$num_field} ne $orig->{$num_field};
	
	#OK both have the same national id 

	my $id_of_duplicate=$dupl->{'intPersonID'} || 0;
	my $id_of_existing=$orig->{'intPersonID'} || 0;
	my $option='';
	if($Data->{'SystemConfig'}{'DuplLowPriorityAssoc'})	{
		my @lowAssocs=split /\|/,$Data->{'SystemConfig'}{'DuplLowPriorityAssoc'} || '';
		my %LowAssocs=();
		for my $i (@lowAssocs) {$LowAssocs{$i}=1; }

		if($LowAssocs{$orig->{'intAssocID'}})	{$option = 'usenew';	}
		elsif($LowAssocs{$dupl->{'intAssocID'}})	{$option = 'useold';	}
	}
	if(!$option)	{
		#is one active and one inactive
		my $newactive= $dupl->{'intRecStatus'} == $Defs::RECSTATUS_ACTIVE ? 1 : 0;
		my $oldactive= $orig->{'intRecStatus'} == $Defs::RECSTATUS_ACTIVE ? 1 : 0;
		return 0 if ($newactive and $oldactive);
		if($newactive)	{$option = 'usenew';	}
		elsif($oldactive)	{$option = 'useold';	}
	}
	if($option eq 'usenew')	{
		processMemberChange($Data,$id_of_duplicate,$id_of_existing,'change_usenew') if $id_of_existing;
		return 1;
	}
	elsif($option eq 'useold')	{
		processMemberChange($Data,$id_of_duplicate,$id_of_existing,'change_useold') if $id_of_existing;
		return 1;
	}
	return 0;
}


1;
