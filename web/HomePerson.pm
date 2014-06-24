package HomePerson;
require Exporter;
@ISA = qw(Exporter);
@EXPORT=qw(showPersonHome);
@EXPORT_OK =qw(showPersonHome);

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

sub showPersonHome	{
	my ($Data, $personID, $FieldDefinitions, $memperms)=@_;
	my $client = $Data->{'client'} || '';
	my $personObj = getInstanceOf($Data, 'person');
	my $allowedit = allowedAction($Data, 'p_e') ? 1 : 0;
	my $notifications = [];
	my %configchanges = ();
	if ( $Data->{'SystemConfig'}{'PersonFormReLayout'} ) {
        	%configchanges = eval( $Data->{'SystemConfig'}{'PersonFormReLayout'} );
    	}

	my ($fields_grouped, $groupdata) = getMemFields($Data, $personID, $FieldDefinitions, $memperms, $personObj, \%configchanges);
	my ($photo,undef)=handle_photo('P_PH_s',$Data,$personID);
	my $name = $personObj->name();
	my $markduplicateURL = '';
	my $adddocumentURL = '';
	my $cardprintingURL = '';
	if(allowedAction($Data, 'm_e'))	{
		if(!$Data->{'SystemConfig'}{'LockPerson'}){
			$adddocumentURL = "$Data->{'target'}?client=$client&amp;a=DOC_L";
			if(Duplicates::isCheckDupl($Data))	{
				$markduplicateURL = "$Data->{'target'}?client=$client&amp;a=P_DUP_";
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
	my $accreditations = ($Data->{'SystemConfig'}{'NationalAccreditation'}) ? AccreditationDisplay::ActiveNationalAccredSummary($Data, $personID) : '';#ActiveAccredSummary($Data, $personID, $Data->{'clientValues'}{'assocID'});

  my $docs = getUploadedFiles(
    $Data,
    $Defs::LEVEL_PERSON,
    $personID,
    $Defs::UPLOADFILETYPE_DOC,
    $Data->{'client'},
  );

	my %TemplateData = (
		Name => $name,
		ReadOnlyLogin => $Data->{'ReadOnlyLogin'},
		EditDetailsLink => "$Data->{'target'}?client=$client&amp;a=P_DTE",
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
			Active => $Data->{'lang'}->txt(($personObj->getValue('intRecStatus') || '') ? 'Yes' : 'No'),
			Address1 => $personObj->getValue('strAddress1') || '',	
			Address2 => $personObj->getValue('strAddress2') || '',	
			Suburb => $personObj->getValue('strSuburb') || '',	
			State => $personObj->getValue('strState') || '',	
			Country => $personObj->getValue('strCountry') || '',	
			PostalCode => $personObj->getValue('strPostalCode') || '',	
			PhoneHome => $personObj->getValue('strPhoneHome') || '',	
			PhoneWork => $personObj->getValue('strPhoneWork') || '',	
			PhoneMobile => $personObj->getValue('strPhoneMobile') || '',	
			Email => $personObj->getValue('strEmail') || '',	
			Gender => $Defs::genderInfo{$personObj->getValue('intGender') || 0} || '',
			DOB => $personObj->getValue('dtDOB') || '',
			NationalNum => $personObj->getValue('strNationalNum') || '',
			SquadNum => $personObj->getValue('dblCustomDbl10') || '',
			BirthCountry => $personObj->getValue('strCountryOfBirth') || '',
			PassportNat => $personObj->getValue('strPassportNationality') || '',
		},

	);
	my $personSummary_ref = undef;#getSeasonStatus($Data, $personID, $personObj);
	for my $i (keys %{$personSummary_ref})	{
		if(ref $personSummary_ref->{$i} eq 'HASH')	{
			for my $j (keys %{$personSummary_ref->{$i}} )	{
				$TemplateData{$i}{$j} = $personSummary_ref->{$i}{$j};
			}
		}
		else	{
			$TemplateData{$i} = $personSummary_ref->{$i};
		}
	}
	my $statuspanel= runTemplate(
		$Data,
		\%TemplateData,
		'dashboards/personstatus.templ',
	);
	$TemplateData{'StatusPanel'} = $statuspanel || '';
	my $resultHTML = runTemplate(
		$Data,
		\%TemplateData,
		'dashboards/person.templ',
	);

  $Data->{'NoHeadingAd'} = 1;

	my $title = $name;
	return ($resultHTML, '');
}


sub getMemFields {
	my ($Data, $personID, $FieldDefinitions, $memperms, $personObj, $override_config) = @_;
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
        
		my $val = $FieldDefinitions->{'fields'}{$f}{'value'} || $personObj->getValue($f) || '';
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


sub getSeasonStuff_ClubLevel	{

	my ($Data, $clubID, $otherClubs, $personID, $seasonID, $season, $td_ref, $hideClubRollover) = @_;

	my $MStablename = "tblPerson_Seasons_$Data->{'Realm'}";
	my $clubWHERE = qq[ AND MC.intClubID = $clubID AND MC.intStatus>-1];
	if ($otherClubs)	{
		$clubWHERE = qq[ AND MC.intStatus>-1 AND MC.intClubID <> $clubID];
	}
	my $st_clubs = qq[
		SELECT
			MC.intStatus as PersonClubStatus,
			C.strName as ClubName,
			C.intClubID as ClubID,
			MS.intPersonSeasonID as PersonSeasonID,
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
			IF(MCCO.intPersonID,1,0) as ClearedOut,
			MC.intPermit as PersonClubPermit,
			DATE_FORMAT(MC.dtPermitStart,'%d/%m/%Y') AS dtPermitStart,
			DATE_FORMAT(MC.dtPermitEnd,'%d/%m/%Y') AS dtPermitEnd,
			DATE_FORMAT(MC.dtPermitEnd,'%Y-%m-%d') AS dtPermitEnd_RAW
		FROM
			tblPerson_Clubs as MC
			INNER JOIN tblAssoc_Clubs as AC ON (
				AC.intClubID=MC.intClubID
				AND AC.intAssocID= ?
			)
			INNER JOIN tblClub as C ON (
				C.intClubID=MC.intClubID
			)
			LEFT JOIN $MStablename as MS ON (
				MS.intPersonID=MC.intPersonID
				AND MS.intClubID=MC.intClubID
				AND MS.intAssocID=AC.intAssocID
				AND MS.intSeasonID = ?
			)
			LEFT JOIN tblPerson_ClubsClearedOut as MCCO ON (
				MCCO.intPersonID = MC.intPersonID
				AND MCCO.intClubID=MC.intClubID
			)
		WHERE
			MC.intPersonID=?
			$clubWHERE
		ORDER BY 
			C.strName,
			C.intClubID,
			MC.intStatus ASC, 
			MC.intPermit DESC
	];
	my $qry_clubs = $Data->{'db'}->prepare($st_clubs);
	$qry_clubs->execute($Data->{'clientValues'}{'assocID'}, $seasonID, $personID);

	my @PersonClubs=();
	my %OtherClubs=();
	my $ClubClrdOut = 0;
	my $ClubActive = 0;
	my $seasonStatus = 0;
	my($day, $month, $year)=(localtime)[3,4,5];
	my $date = ($year+1900)."-".($month+1)."-".$day;
	while (my $cref=$qry_clubs->fetchrow_hashref())	{
		$seasonStatus = $cref->{'MSRecStatus'} ;
		push @PersonClubs, $cref if ($cref->{'ClubID'} != $clubID and $OtherClubs{$cref->{'ClubID'}} != 1 and  $OtherClubs{$cref->{'ClubID'}} != 2);
		$OtherClubs{$cref->{'ClubID'}} = 2 if ($cref->{'ClubID'} != $clubID);
		$cref->{'SeasonID'} ||=0;
		$cref->{'MSRecStatus'} ||=0;
		$td_ref->{'registerInto_'.$season.'Season'} = 1 if ( (!$cref->{'PersonClubPermit'} or ($Data->{'SystemConfig'}{'AssocConfig'}->{'IgnorePermitReReg'} and $cref->{'dtPermitEnd_RAW'}>$date)) and $cref->{'ClubID'} == $clubID and (! $cref->{'SeasonID'} or ! $cref->{'MSRecStatus'} or $cref->{'MSRecStatus'} < 1) and ! $cref->{'ClearedOut'});
		$td_ref->{'MSThisClub_'.$season.'Season_MSID'} = $cref->{'PersonSeasonID'} if ($cref->{'ClubID'} == $clubID and $cref->{'SeasonID'});

		if ($cref->{'ClubID'} == $clubID)	{
			$ClubActive = $cref->{'PersonClubStatus'} || 0;
		}
		next unless $cref->{'MSRecStatus'} ==1;
		if ($cref->{'ClubID'} == $clubID and $cref->{'SeasonID'})	{
			$ClubClrdOut = $cref->{'ClearedOut'} || 0;
			$td_ref->{'MSThisClub_'.$season.'Season'} = $cref;
		}
	}
	$td_ref->{'MSOtherClubs'} = \@PersonClubs if ($otherClubs);
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
		 	($Data->{'SystemConfig'}{'personReReg_notInactive'} and (! $ClubActive or $ClubClrdOut))
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
        my ($personID,$type,$Data)=@_;
        my $db=$Data->{'db'};
        my $st = qq[
                SELECT *
                FROM tblPerson_Types
                WHERE intPersonID=$personID
                        AND intTypeID=$type
                        AND intSubTypeID=0
        ];
        my $q = $db->prepare($st);
        $q->execute();
        my $dref = $q->fetchrow_hashref();
        if ($type == $Defs::PERSON_TYPE_COACH && $dref->{intInt1}) {
                return qq[<div style="font-size:14px;color:red;"><b>WARNING:</b> COACH DEREGISTERED</div>];
        }
        elsif ($type == $Defs::PERSON_TYPE_UMPIRE && $dref->{intInt2}) {
                return qq[<div style="font-size:14px;color:red;"><b>WARNING:</b> UMPIRE DEREGISTERED</div>];
        }
        elsif ($type == $Defs::PERSON_TYPE_MISC && $dref->{intInt2}) {
                return qq[<div style="font-size:14px;color:red;"><b>WARNING:</b> MISC DEREGISTERED</div>];
        }
        elsif ($type == $Defs::PERSON_TYPE_VOLUNTEER && $dref->{intInt2}) {
                return qq[<div style="font-size:14px;color:red;"><b>WARNING:</b> VOLUNTEER DEREGISTERED</div>];
        }
        else {
                return 0;
        }
}

1;
