#
# $Header: svn://svn/SWM/trunk/web/HomeMember.pm 11630 2014-05-21 04:31:45Z sliu $
#

package HomeMember;
require Exporter;
@ISA = qw(Exporter);
@EXPORT=qw(showMemberHome);
@EXPORT_OK =qw(showMemberHome);

use strict;
use Reg_common;
use Utils;
use InstanceOf;

use Photo;
use TTTemplate;
use Notifications;
use FormHelpers;
use Seasons;
use UploadFiles;
use Log;
use Data::Dumper;

require AccreditationDisplay;

sub showMemberHome	{
	my ($Data, $memberID, $FieldDefinitions, $memperms)=@_;
	my $client = $Data->{'client'} || '';
	my $memberObj = getInstanceOf($Data, 'member');
	my $allowedit = allowedAction($Data, 'm_e') ? 1 : 0;
	my $notifications = [];
	my %configchanges = ();
	if ( $Data->{'SystemConfig'}{'MemberFormReLayout'} ) {
        	%configchanges = eval( $Data->{'SystemConfig'}{'MemberFormReLayout'} );
    	}

	my ($fields_grouped, $groupdata) = getMemFields($Data, $memberID, $FieldDefinitions, $memperms, $memberObj, \%configchanges);
	my ($photo,undef)=handle_photo('M_PH_s',$Data,$memberID);
	my $name = $memberObj->name();
	my $markduplicateURL = '';
	my $adddocumentURL = '';
	my $cardprintingURL = '';
	if(allowedAction($Data, 'm_e'))	{
		if(!$Data->{'SystemConfig'}{'LockMember'}){
			$adddocumentURL = "$Data->{'target'}?client=$client&amp;a=DOC_L";
			if(Duplicates::isCheckDupl($Data))	{
				$markduplicateURL = "$Data->{'target'}?client=$client&amp;a=M_DUP_";
			}
		}
		#if($Data->{'SystemConfig'}{'AllowCardPrinting'})	{
		#	$cardprintingURL = "$Data->{'target'}?client=$client&amp;a=MEMCARD_MLIST";
	#}
		if($Data->{'SystemConfig'}{'AllowCardPrinting'} and
			 ($Data->{'clientValues'}{'authLevel'} > $Defs::LEVEL_CLUB or 
				($Data->{'clientValues'}{'authLevel'} <= $Defs::LEVEL_CLUB and !$Data->{'SystemConfig'}{'AssocConfig'}->{'DisableClubCardPrinting'}))){
					
					$cardprintingURL = "$Data->{'target'}?client=$client&amp;a=MEMCARD_MLIST";
		}

	}
	my $accreditations = ($Data->{'SystemConfig'}{'NationalAccreditation'}) ? AccreditationDisplay::ActiveNationalAccredSummary($Data, $memberID) : '';#ActiveAccredSummary($Data, $memberID, $Data->{'clientValues'}{'assocID'});

  my $docs = getUploadedFiles(
    $Data,
    $Defs::LEVEL_MEMBER,
    $memberID,
    $Defs::UPLOADFILETYPE_DOC,
    $Data->{'client'},
  );

	my %TemplateData = (
		Name => $name,
		ReadOnlyLogin => $Data->{'ReadOnlyLogin'},
		EditDetailsLink => "$Data->{'target'}?client=$client&amp;a=M_DTE",
		Notifications => $notifications,
		Photo => $photo,
		MarkDuplicateURL => $markduplicateURL || '',
		AddDocumentURL => $adddocumentURL || '',
		CardPrintingURL => $cardprintingURL || '',
		UmpireLabel => $Data->{'SystemConfig'}{'UmpireLabel'} || 'Match Official',
		Documents => $docs,
		Accreditations => $accreditations,
		GroupData => $groupdata,
		Details => {
			Active => $Data->{'lang'}->txt(($memberObj->getValue('intRecStatus') || '') ? 'Yes' : 'No'),
			Address1 => $memberObj->getValue('strAddress1') || '',	
			Address2 => $memberObj->getValue('strAddress2') || '',	
			Suburb => $memberObj->getValue('strSuburb') || '',	
			State => $memberObj->getValue('strState') || '',	
			Country => $memberObj->getValue('strCountry') || '',	
			PostalCode => $memberObj->getValue('strPostalCode') || '',	
			PhoneHome => $memberObj->getValue('strPhoneHome') || '',	
			PhoneWork => $memberObj->getValue('strPhoneWork') || '',	
			PhoneMobile => $memberObj->getValue('strPhoneMobile') || '',	
			Email => $memberObj->getValue('strEmail') || '',	
			Gender => $Defs::genderInfo{$memberObj->getValue('intGender') || 0} || '',
			DOB => $memberObj->getValue('dtDOB') || '',
			NationalNum => $memberObj->getValue('strNationalNum') || '',
			SquadNum => $memberObj->getValue('dblCustomDbl10') || '',
			BirthCountry => $memberObj->getValue('strCountryOfBirth') || '',
			PassportNat => $memberObj->getValue('strPassportNationality') || '',
		},

	);
	my $memberSummary_ref = getSeasonStatus($Data, $memberID, $memberObj);
	for my $i (keys %{$memberSummary_ref})	{
		if(ref $memberSummary_ref->{$i} eq 'HASH')	{
			for my $j (keys %{$memberSummary_ref->{$i}} )	{
				$TemplateData{$i}{$j} = $memberSummary_ref->{$i}{$j};
			}
		}
		else	{
			$TemplateData{$i} = $memberSummary_ref->{$i};
		}
	}
	my $statuspanel= runTemplate(
		$Data,
		\%TemplateData,
		'dashboards/memberstatus.templ',
	);
	$TemplateData{'StatusPanel'} = $statuspanel || '';
	my $resultHTML = runTemplate(
		$Data,
		\%TemplateData,
		'dashboards/member.templ',
	);

  $Data->{'NoHeadingAd'} = 1;

	my $title = $name;
	return ($resultHTML, '');
}


sub getMemFields {
	my ($Data, $memberID, $FieldDefinitions, $memperms, $memberObj, $override_config) = @_;
	my %fields_grouped = ();
	my %fields = ();
	my %nolabelfields = (
		strAddress1 => 1,
		strAddress2 => 1,
		strSuburb => 1,
		strCityOfResidence => 1,
		strState => 1,
		strPostalCode => 1,
		strCountry => 1,
	);
	if(scalar($FieldDefinitions)>1){
	
	my @fieldorder=(defined $override_config and exists $override_config->{'order'} and $override_config->{'order'}) ? @{$override_config->{'order'}} : @{$FieldDefinitions->{'order'}};
	for my $f (@fieldorder) 	{
		next if (exists $memperms->{$f} and !$memperms->{$f});
		my $label = $FieldDefinitions->{'fields'}{$f}{'label'} || next;
		my $group=(defined $override_config and exists $override_config->{'sectionname'} and $override_config->{'sectionname'}{$f}) ? $override_config->{'sectionname'}{$f} ||''  : ($FieldDefinitions->{'fields'}{$f}{'sectionname'}  || 'main');
        my $is_header = ($FieldDefinitions->{'fields'}{$f}{'type'} eq 'header') ? 1 : 0;
        
		my $val = $FieldDefinitions->{'fields'}{$f}{'value'} || $memberObj->getValue($f) || '';
		if($FieldDefinitions->{'fields'}{$f}{'options'})	{
			$val = $FieldDefinitions->{'fields'}{$f}{'options'}{$val} || $val;
		}
		if($FieldDefinitions->{'fields'}{$f}{'displaylookup'})	{
			$val = $FieldDefinitions->{'fields'}{$f}{'displaylookup'}{$val} || $val;
		}
		push @{$fields_grouped{$group}}, [$f, $label];
		my $string = '';
		if (($val and $val ne '00/00/0000') or ($is_header))	{
			$string .= qq[<span class="details-row"><span class = "details-left">$label</span>] if !$nolabelfields{$f};
			$string .= '<span class="details-right">'.$val.'</span></span>';
			$fields{$group} .= $string;
		}
	}}
	return (\%fields_grouped, \%fields);
}

sub getSeasonStatus	{
	my (
		$Data, 
		$memberID, 
		$memberObj
	)=@_;


	## To Do:
	## Handle read-only ?
	## Handle rollvoer lockdown ?

	my $assoc_obj = getInstanceOf($Data, 'assoc', $Data->{'clientValues'}{'assocID'});

	my $clubID = $Data->{'clientValues'}{'clubID'} || 0;
	$clubID=0 if $clubID == $Defs::INVALID_ID;

	my $assocSeasons = Seasons::getDefaultAssocSeasons($Data);
	my $status = 'notactive';

	my $defaulter = '';
	if(
		$Data->{'SystemConfig'}{'Defaulter'} 
		and $memberObj->getValue('intDefaulter'))	{
		$defaulter = $Data->{'SystemConfig'}{'Defaulter'} || '';
	}
	my %TemplateData = (
		assocSeasons => $assocSeasons,
		SameSeason => ($assocSeasons->{'currentSeasonID'} == $assocSeasons->{'newRegoSeasonID'}) ? 1: 0,
	  clubID => $clubID,
		Details => {
			isDeceased=> $memberObj->getValue('intDeceased'),
			isDeRegister => $memberObj->getValue('intDeRegister'),
			recStatus => $memberObj->getValue('intRecStatus'),
			Status => $memberObj->getValue('intStatus'),
			defaulter=> $defaulter,
		},
		registerInto_currentSeason=>0, ## Show the Register into Current Season button
		registerInto_newRegoSeason=>0, ## Show the Register into New Rego Season button
		MSThisClub_currentSeason => 0, ## hash ref of current season
		MSThisClub_currentSeason_MSID => 0, ## ID of tblMember_Season_X.intMemebrSeasonID for current Season for club
		MSThisClub_newRegoSeason => 0, ## hash ref of new rego season
		MSThisClub_newRegoSeason_MSID => 0, ## ID of tblMember_Season_X.intMemebrSeasonID for new rego season
		MSassoc_currentSeason => 0, ## has ref of assoc season record
		MSassoc_newRegoSeason => 0, ## has ref of assoc season record
		currentSeason_MSID => 0, ## current Season tblMember_Season_X.intMemberSeasonID
		newRegoSeason_MSID => 0, ## New rego Season tblMember_Season_X.intMemberSeasonID
		MSOtherClubs=> undef, ## Other Clubs (Other non-logged in clubs in same Assoc)
	);

	$TemplateData{'defaulter'} = $defaulter;
  $TemplateData{'txtSeason'} = $Data->{'SystemConfig'}{'txtSeason'} || 'Season';

 	getSeasonStuff_AssocLevel($Data, $memberID, $assocSeasons->{'currentSeasonID'}, 'current', \%TemplateData);
 	getSeasonStuff_AssocLevel($Data, $memberID, $assocSeasons->{'newRegoSeasonID'}, 'newRego', \%TemplateData);
	if ($clubID)	{
		$TemplateData{'registerInto_currentSeason'} = 0;
		$TemplateData{'registerInto_newRegoSeason'} = 0;
	}
 	getSeasonStuff_ClubLevel($Data, $clubID, 0, $memberID, $assocSeasons->{'currentSeasonID'}, 'current', \%TemplateData, $assoc_obj->getValue('intHideClubRollover') );
 	getSeasonStuff_ClubLevel($Data, $clubID, 0, $memberID, $assocSeasons->{'newRegoSeasonID'}, 'newRego', \%TemplateData, $assoc_obj->getValue('intHideClubRollover') );
 	getSeasonStuff_ClubLevel($Data, $clubID, 1, $memberID, $assocSeasons->{'currentSeasonID'}, 'current', \%TemplateData, undef);

	return \%TemplateData;

}

sub getSeasonStuff_AssocLevel	{

	my ($Data, $memberID, $seasonID, $season, $td_ref) = @_;

	my $MStablename = "tblMember_Seasons_$Data->{'Realm'}";
 	my $st_assoc = qq[
    SELECT
      MS.intMemberSeasonID as MemberSeasonID,
      MS.intSeasonID as SeasonID,
      MS.intMSRecStatus as MSRecStatus,
      MS.intPlayerStatus as PlayerStatus,
      MS.intCoachStatus as CoachStatus,
      MS.intUmpireStatus as UmpireStatus,
      MS.intMiscStatus as MiscStatus,
      MS.intVolunteerStatus as VolunteerStatus,
      MS.intOther1Status as Other1Status,
      MS.intOther2Status as Other2Status,
      MS.intPlayerFinancialStatus as PlayerFinancialStatus,
      MS.intCoachFinancialStatus as CoachFinancialStatus,
      MS.intUmpireFinancialStatus as UmpireFinancialStatus,
      MS.intMiscFinancialStatus as MiscFinancialStatus,
      MS.intVolunteerFinancialStatus as VolunteerFinancialStatus,
      MS.intOther1FinancialStatus as Other1FinancialStatus,
      MS.intOther2FinancialStatus as Other2FinancialStatus
    FROM
      $MStablename as MS
    WHERE
        MS.intMemberID=?
        AND MS.intClubID=0
        AND MS.intAssocID=?
        AND MS.intSeasonID = ?
  ];
  my $qry_assoc = $Data->{'db'}->prepare($st_assoc);
  $qry_assoc->execute($memberID, $Data->{'clientValues'}{'assocID'}, $seasonID);

  my $aref=$qry_assoc->fetchrow_hashref();
  $td_ref->{'registerInto_'.$season . 'Season'} = 1 if (! defined $aref->{'MemberSeasonID'} or $aref->{'MSRecStatus'} < 1 );
  $td_ref->{$season.'Season_MSID'} = $aref->{'MemberSeasonID'} || 0;
	if ($aref->{'MemberSeasonID'} and $aref->{'MSRecStatus'} == 1)	{
  	$td_ref->{'MSassoc_'.$season.'Season'} = $aref;
	}
}

sub getSeasonStuff_ClubLevel	{

	my ($Data, $clubID, $otherClubs, $memberID, $seasonID, $season, $td_ref, $hideClubRollover) = @_;

	my $MStablename = "tblMember_Seasons_$Data->{'Realm'}";
	my $clubWHERE = qq[ AND MC.intClubID = $clubID AND MC.intStatus>-1];
	if ($otherClubs)	{
		$clubWHERE = qq[ AND MC.intStatus>-1 AND MC.intClubID <> $clubID];
	}
	my $st_clubs = qq[
		SELECT
			MC.intStatus as MemberClubStatus,
			C.strName as ClubName,
			C.intClubID as ClubID,
			MS.intMemberSeasonID as MemberSeasonID,
			MS.intSeasonID as SeasonID,
			MS.intMSRecStatus as MSRecStatus,
			MS.intPlayerStatus as PlayerStatus,
			MS.intCoachStatus as CoachStatus,
			MS.intUmpireStatus as UmpireStatus,
			MS.intMiscStatus as MiscStatus,
			MS.intVolunteerStatus as VolunteerStatus,
			MS.intOther1Status as Other1Status,
			MS.intOther2Status as Other2Status,
			MS.intPlayerFinancialStatus as PlayerFinancialStatus,
			MS.intCoachFinancialStatus as CoachFinancialStatus,
			MS.intUmpireFinancialStatus as UmpireFinancialStatus,
			MS.intMiscFinancialStatus as MiscFinancialStatus,
			MS.intVolunteerFinancialStatus as VolunteerFinancialStatus,
			MS.intOther1FinancialStatus as Other1FinancialStatus,
			MS.intOther2FinancialStatus as Other2FinancialStatus,
			IF(MCCO.intMemberID,1,0) as ClearedOut,
			MC.intPermit as MemberClubPermit,
			DATE_FORMAT(MC.dtPermitStart,'%d/%m/%Y') AS dtPermitStart,
			DATE_FORMAT(MC.dtPermitEnd,'%d/%m/%Y') AS dtPermitEnd,
			DATE_FORMAT(MC.dtPermitEnd,'%Y-%m-%d') AS dtPermitEnd_RAW
		FROM
			tblMember_Clubs as MC
			INNER JOIN tblAssoc_Clubs as AC ON (
				AC.intClubID=MC.intClubID
				AND AC.intAssocID= ?
			)
			INNER JOIN tblClub as C ON (
				C.intClubID=MC.intClubID
			)
			LEFT JOIN $MStablename as MS ON (
				MS.intMemberID=MC.intMemberID
				AND MS.intClubID=MC.intClubID
				AND MS.intAssocID=AC.intAssocID
				AND MS.intSeasonID = ?
			)
			LEFT JOIN tblMember_ClubsClearedOut as MCCO ON (
				MCCO.intMemberID = MC.intMemberID
				AND MCCO.intClubID=MC.intClubID
			)
		WHERE
			MC.intMemberID=?
			$clubWHERE
		ORDER BY 
			C.strName,
			C.intClubID,
			MC.intStatus ASC, 
			MC.intPermit DESC
	];
	my $qry_clubs = $Data->{'db'}->prepare($st_clubs);
	$qry_clubs->execute($Data->{'clientValues'}{'assocID'}, $seasonID, $memberID);

	my @MemberClubs=();
	my %OtherClubs=();
	my $ClubClrdOut = 0;
	my $ClubActive = 0;
	my $seasonStatus = 0;
	my($day, $month, $year)=(localtime)[3,4,5];
	my $date = ($year+1900)."-".($month+1)."-".$day;
	while (my $cref=$qry_clubs->fetchrow_hashref())	{
		$seasonStatus = $cref->{'MSRecStatus'} ;
		push @MemberClubs, $cref if ($cref->{'ClubID'} != $clubID and $OtherClubs{$cref->{'ClubID'}} != 1 and  $OtherClubs{$cref->{'ClubID'}} != 2);
		$OtherClubs{$cref->{'ClubID'}} = 2 if ($cref->{'ClubID'} != $clubID);
		$cref->{'SeasonID'} ||=0;
		$cref->{'MSRecStatus'} ||=0;
		$td_ref->{'registerInto_'.$season.'Season'} = 1 if ( (!$cref->{'MemberClubPermit'} or ($Data->{'SystemConfig'}{'AssocConfig'}->{'IgnorePermitReReg'} and $cref->{'dtPermitEnd_RAW'}>$date)) and $cref->{'ClubID'} == $clubID and (! $cref->{'SeasonID'} or ! $cref->{'MSRecStatus'} or $cref->{'MSRecStatus'} < 1) and ! $cref->{'ClearedOut'});
		$td_ref->{'MSThisClub_'.$season.'Season_MSID'} = $cref->{'MemberSeasonID'} if ($cref->{'ClubID'} == $clubID and $cref->{'SeasonID'});

		if ($cref->{'ClubID'} == $clubID)	{
			$ClubActive = $cref->{'MemberClubStatus'} || 0;
		}
		next unless $cref->{'MSRecStatus'} ==1;
		if ($cref->{'ClubID'} == $clubID and $cref->{'SeasonID'})	{
			$ClubClrdOut = $cref->{'ClearedOut'} || 0;
			$td_ref->{'MSThisClub_'.$season.'Season'} = $cref;
		}
	}
	$td_ref->{'MSOtherClubs'} = \@MemberClubs if ($otherClubs);
	return if $otherClubs;

  if (! allowedAction($Data, 'm_a') and ! allowedAction($Data, 'm_e'))	{
		$td_ref->{'registerInto_'.$season.'Season'} = 0;
	}

	if (
		($Data->{'SystemConfig'}{'LockSeasons'} and $Data->{'clientValues'}{'authLevel'} <= $Defs::LEVEL_ASSOC)
		or 
		($Data->{'SystemConfig'}{'LockSeasonsCRL'} and $Data->{'clientValues'}{'authLevel'} < $Defs::LEVEL_ASSOC)
		or
		($hideClubRollover and $Data->{'clientValues'}{'authLevel'} < $Defs::LEVEL_ASSOC)
	)	{
		
		$td_ref->{'registerInto_'.$season.'Season'} = 0;
	}

	if ($clubID)	{
	  if (
			($ClubClrdOut and $Data->{'clientValues'}{'authLevel'} <= $Defs::LEVEL_ASSOC)
			or 
		 	($Data->{'SystemConfig'}{'memberReReg_notInactive'} and (! $ClubActive or $ClubClrdOut))
			)	{
			$td_ref->{'registerInto_'.$season.'Season'} = 0;
		}
	}

		### Now lets work out the action & URL based on the IDs
			if ($td_ref->{'registerInto_'.$season.'Season'})	{
				my $action = '';
				my $msID=0;
				if ($clubID)	{
					$action = 'SN_MSviewCADD&d_intClubID='.$clubID;
					if ($td_ref->{'MSThisClub_'.$season.'Season_MSID'})	{
						$msID = $td_ref->{'MSThisClub_'.$season.'Season_MSID'};
						$action = 'SN_MSviewCEDIT';
					}
				}
				else	{
					$action = 'SN_MSviewADD';
					if ($td_ref->{$season.'Season_MSID'})	{
						$action = 'SN_MSviewCEDIT';
						$msID = $td_ref->{$season.'Season_MSID'};
					}
				}
				$td_ref->{'registerInto_'.$season.'Season_URL_edit'}='';
				$td_ref->{'registerInto_'.$season.'Season_URL_add'}='';
				$td_ref->{'registerInto_'.$season.'Season_ACTION'} = $action;
				if ($action =~ /ADD/)	{
                        $td_ref->{'registerInto_'.$season.'Season_URL_add'} = "$Data->{'target'}?client=$Data->{'client'}&amp;a=$action&amp;d_intSeasonID=$seasonID";
				}
				else	{
					    $td_ref->{'registerInto_'.$season.'Season_URL_edit'} = "$Data->{'target'}?client=$Data->{'client'}&amp;a=$action&amp;d_intSeasonID=$seasonID&msID=$msID";
				}
			}
	#if we have a season record and it has a minus one status and we have blocked season access it was incorrectly flagging people as registered
	if($td_ref->{'registerInto_'.$season.'Season'}==0 and $td_ref->{'MSThisClub_'.$season.'Season_MSID'} and $seasonStatus == -1)
	{
		$td_ref->{'MSThisClub_'.$season.'Season_MSID'} =0;
	}  

}
sub deregistration_check___duplicated {
        my ($memberID,$type,$Data)=@_;
        my $db=$Data->{'db'};
        my $st = qq[
                SELECT *
                FROM tblMember_Types
                WHERE intMemberID=$memberID
                        AND intTypeID=$type
                        AND intSubTypeID=0
        ];
        my $q = $db->prepare($st);
        $q->execute();
        my $dref = $q->fetchrow_hashref();
        if ($type == $Defs::MEMBER_TYPE_COACH && $dref->{intInt1}) {
                return qq[<div style="font-size:14px;color:red;"><b>WARNING:</b> COACH DEREGISTERED</div>];
        }
        elsif ($type == $Defs::MEMBER_TYPE_UMPIRE && $dref->{intInt2}) {
                return qq[<div style="font-size:14px;color:red;"><b>WARNING:</b> UMPIRE DEREGISTERED</div>];
        }
        elsif ($type == $Defs::MEMBER_TYPE_MISC && $dref->{intInt2}) {
                return qq[<div style="font-size:14px;color:red;"><b>WARNING:</b> MISC DEREGISTERED</div>];
        }
        elsif ($type == $Defs::MEMBER_TYPE_VOLUNTEER && $dref->{intInt2}) {
                return qq[<div style="font-size:14px;color:red;"><b>WARNING:</b> VOLUNTEER DEREGISTERED</div>];
        }
        else {
                return 0;
        }
}

1;
