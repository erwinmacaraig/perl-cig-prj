#
# $Header: svn://svn/SWM/trunk/web/MemberTypes.pm 9616 2013-09-26 02:07:54Z dhanslow $
#

package MemberTypes;

require Exporter;
@ISA =  qw(Exporter);
@EXPORT = qw(displayMemberTypes updateMemberTypes handleMemberTypes deregistration_check ActiveAccredSummary);
@EXPORT_OK = qw(displayMemberTypes updateMemberTypes handleMemberTypes deregistration_check ActiveAccredSummary);

use strict;
use CGI qw(param unescape escape);

use lib '.';
use Reg_common;
use Defs;
use Utils;
use FormHelpers;
use HTMLForm;
use SWSports;
use AuditLog;
use FieldLabels;
use MemberTypesBulk;
use MemberTypesCommon;
use GridDisplay;
use Data::Dumper;
# GET INFORMATION RELATING TO THIS MEMBERS TYPE (IE. COACH, PLAYER ETC)

sub handleMemberTypes {
	my($action, $Data, $memberID)=@_;
	my $ID=param("mtID") || 0;
	my $type=param("ty") || $Defs::MEMBER_TYPE_PLAYER;
	my $edit=param("e") || 0;
  my $resultHTML='';
	my $heading='';
  if ($action eq 'M_MT_EDIT') {
		($resultHTML,$heading) = displayMemberTypes($Data, $memberID, $ID, $type, 1);
  }
  elsif ($action eq 'M_MT_LIST') {
		($resultHTML,$heading) = displayMemberTypesAll($Data, $memberID, $ID, $type, $edit);
 	}
  elsif ($action eq 'M_MT_ADD') {
		($resultHTML,$heading) = displayMemberTypes($Data, $memberID, 0, $type, 1);
  }
	elsif ($action eq 'M_MT_LTYPES')  {
		#$resultHTML = showMemberTypes_Types($db, $ID, $type, $assocID, $client, $target, $assocConfig_ref);
	}
	elsif ($action eq 'M_MT_UPDATE')  {
		#$resultHTML = updateMemberTypes($db, $assocConfig_ref);
	}
  elsif ($action eq 'M_MT_BULK_EDIT') {
    ($resultHTML, $heading) = listBulkMemberTypes($Data, $memberID); 
  }
  elsif ($action eq 'M_MT_BULK_UPDATE') {
    ($resultHTML, $heading) = updateBulkMemberTypes($Data, $memberID);
  }
	$heading||='Member Types';
  return ($resultHTML,$heading);
}

sub displayMemberTypesAll {
	my($Data, $memberID, $id, $type, $edit) = @_;
	$type||=$Defs::MEMBER_TYPE_PLAYER;
	my $toplist='';
	my $cnt=0;
	my $activetab=0;
	my @taboptions;
	my $resultHTML='';
	for my $ty ((
    $Defs::MEMBER_TYPE_PLAYER,
    $Defs::MEMBER_TYPE_COACH,
    $Defs::MEMBER_TYPE_UMPIRE,
    $Defs::MEMBER_TYPE_OFFICIAL,
    $Defs::MEMBER_TYPE_MISC,
    $Defs::MEMBER_TYPE_VOLUNTEER
  ))	{
		$activetab=$cnt if $type == $ty;
		my ($dat,undef) = displayMemberTypes($Data, $memberID, $id, $ty, 0, $ty);
    my $tabname = ($Data->{'SystemConfig'}{'TYPE_NAME_' . $ty}) 
      ? $Data->{'SystemConfig'}{'TYPE_NAME_' . $ty} 
      : $Defs::memberTypeName{$ty};
		$dat||='';
		$resultHTML.=qq[<div id="memtype_dat$ty">$dat</div>];
		push @taboptions, ["memtype_dat$ty", $tabname];
		$cnt++;
	}

	my $tabheaders='';
	for my $i (@taboptions) {
		#$taboptions.="," if $taboptions;
		#$taboptions.="{contentEl:'$i->[0]', title:'$i->[1]'}";
	$tabheaders .= qq{<li><a href="#$i->[0]">$i->[1]</a></li>};
	}
	$tabheaders = qq[<ul>$tabheaders</ul>] if $tabheaders;
  $Data->{'AddToPage'}->add(
    'js_bottom',
    'inline',
    "jQuery('#membertypetabs').tabs({selected: $activetab});",
  );

	my $body=qq[
			<div id="membertypetabs" style="float:left;width:98%;">
				$tabheaders
				$resultHTML
			</div>
	];
	my $heading="Member Types";
	return ($body, $heading);
}

sub displayMemberTypes	{
	my($Data, $memberID, $id, $type, $edit, $gridID) = @_;
	$gridID ||= '';
	my $db=$Data->{'db'} || undef;
	my $assocID= $Data->{'clientValues'}{'assocID'} || -1;
  my $client=setClient($Data->{'clientValues'}) || '';
	my $target=$Data->{'target'} || '';
	my $option=$edit ? ($id ? 'edit' : 'add')  :'display' ;
	my $type2=param("ty2") || 0;
  my $resultHTML = '';
	$type||=$Defs::MEMBER_TYPE_PLAYER;
	my $toplist='';


  my %member_type_names = ();
	for my $ty ((
    $Defs::MEMBER_TYPE_PLAYER,
    $Defs::MEMBER_TYPE_COACH,
    $Defs::MEMBER_TYPE_UMPIRE,
    $Defs::MEMBER_TYPE_OFFICIAL,
    $Defs::MEMBER_TYPE_MISC,
    $Defs::MEMBER_TYPE_VOLUNTEER
  ))	{
		my $active=$type == $ty ? ' class="activetab" ' : '';
		$toplist.=' / ' if $toplist;
    my $tabname = ($Data->{'SystemConfig'}{'TYPE_NAME_' . $ty}) 
      ? $Data->{'SystemConfig'}{'TYPE_NAME_' . $ty} 
      : $Defs::memberTypeName{$ty};
		$toplist.=qq[<a href="$target?a=M_MT_LIST&amp;ty=$ty&amp;client=$client" $active>$tabname</a>];
    $member_type_names{$ty} = $tabname || $Defs::memberTypeName{$ty};
	}


	my $aID=$Data->{'clientValues'}{'assocID'} || 0;
	$aID=0 if $aID==$Defs::INVALID_ID;
  my ($DefCodes, $DefCodesFull) = get_defcodes($Data, $option);
	my %DataVals=();
	my $statement=qq[
		SELECT * , DATE_FORMAT(dtDate1 ,"%d/%m/%Y") AS dtDate1, DATE_FORMAT(dtDate2,"%d/%m/%Y") AS dtDate2, DATE_FORMAT(dtDate3,"%d/%m/%Y") AS dtDate3
		FROM tblMember_Types
		WHERE intTypeID=$type
			AND intMemberID=$memberID
			AND intAssocID = $aID 
			AND intRecStatus <> $Defs::RECSTATUS_DELETED
		ORDER BY intSubTypeID ASC, tblMember_Types.dtDate1, tblMember_Types.dtDate2
	];
	my $query = $db->prepare($statement);
	my $RecordData={};
	$query->execute;
	while(my $dref=$query->fetchrow_hashref())	{
		push @{$DataVals{$dref->{intSubTypeID}}}, $dref;
		$RecordData=$dref if $dref->{intMemberTypeID} == $id;
	}
	my $mtupdate=qq[
		UPDATE tblMember_Types 
			SET intRecStatus = $Defs::RECSTATUS_ACTIVE, --VAL--
		WHERE intMemberTypeID=$id
	];
	my $mtadd=qq[
		INSERT INTO tblMember_Types (intAssocID, intMemberID,intTypeID, intSubTypeID, intRecStatus, --FIELDS--)
			VALUES ($aID, $memberID,$type,$type2, $Defs::RECSTATUS_ACTIVE, --VAL--)
	];
  my $st_grades=qq[ SELECT intAssocGradeID,strGradeDesc FROM tblAssoc_Grade WHERE intAssocID=$Data->{'clientValues'}{'assocID'}];
  my ($grades_vals,$grades_order)=getDBdrop_down_Ref($Data->{'db'},$st_grades,'');
	my $FieldLabels=FieldLabels::getFieldLabels($Data, $Defs::LEVEL_MEMBER);
  my @Accreditations_Order = getMT_AccreditationsOrder();
  my %Accreditations_fields = getMT_Accreditations($Data, $RecordData, $FieldLabels, $DefCodes, $type2);
  my @Positions_Order = getMT_PositionsOrder();
  my %Positions_fields = getMT_Positions($Data, $RecordData, $FieldLabels, $DefCodes, $type, $type2);
	my %FieldDefs = (
		PLAYER => {
			fields => {
				intActive => {
					label => '',
					#label => $FieldLabels->{'Player.intActive'} || 'Active?',
					type => 'checkbox',
					value => $DataVals{0}[0]{'intActive'},
					displaylookup => {1 => 'Yes', 0 => 'No'},
				},
				dtDate1 => {
					label => $FieldLabels->{'Player.dtDate1'} || 'Last Recorded Game',
					type => 'date',
					format => 'dd/mm/yyyy',
					value => $DataVals{0}[0]{'dtDate1'},
					readonly => 1,
				},
				intInt1 => {
					label => $FieldLabels->{'Player.intInt1'} || 'Career Games',
					type => 'text',
					size => 6,
					value => $DataVals{0}[0]{'intInt1'},
					readonly => 1,
				},
				intInt2 => {
					label => $FieldLabels->{'Player.intInt2'} || 'Junior?',
					type => 'checkbox',
					value => $DataVals{0}[0]{'intInt2'},
					displaylookup => {1 => 'Yes', 0 => 'No','' =>'No'},
				},
				intInt3 => {
					label => $FieldLabels->{'Player.intInt3'} || 'Senior?',
					type => 'checkbox',
					value => $DataVals{0}[0]{'intInt3'},
					displaylookup => {1 => 'Yes', 0 => 'No','' =>'No'},
				},
				intInt4 => {
					label => $FieldLabels->{'Player.intInt4'} || 'Veteran?',
					type => 'checkbox',
					value => $DataVals{0}[0]{'intInt4'},
					displaylookup => {1 => 'Yes', 0 => 'No','' =>'No'},
				},
				intInt5 => {
          label => $FieldLabels->{'Player.intInt5'} || 'Registered Grade',
          type => 'lookup',
          value => $DataVals{0}[0]{'intInt5'},
          options =>  $grades_vals,
        	firstoption => ['','Select Grade'],
        },
			},
			order => [qw(dtDate1 intInt1 intInt2 intInt3 intInt4 intInt5)],
			options => {
				labelsuffix => ':',
				hideblank => 1,
				target => $Data->{'target'},
				formname => 'mt_form',
				submitlabel => 'Update Player Member Type',
				introtext => 'auto',
				buttonloc => 'bottom',
				updateSQL => $mtupdate,
				addSQL => $mtadd,

        auditFunction=> \&auditLog,
        auditAddParams => [
          $Data,
          'Add',
          qq[Member Types: $member_type_names{$type}]
        ],
        auditEditParams => [
          $id,
          $Data,
          'Update',
          qq[Member Types: $member_type_names{$type}]
        ],

				stopAfterAction => 1,
				updateOKtext => qq[
					<div class="OKmsg">Record updated successfully</div> <br>
					<a href="$Data->{'target'}?client=$client&amp;a=M_MT_LIST&amp;ty=$type">Return to $member_type_names{$type} Member Type</a>
				],
				addOKtext => qq[
					<div class="OKmsg">Record updated successfully</div> <br>
					<a href="$Data->{'target'}?client=$client&amp;a=M_MT_LIST&amp;ty=$type">Return to $member_type_names{$type} Member Type</a>
				],
			},
			sections => [ ['main','Details'], ],
			carryfields =>  {
				client => $client,
				a=> 'M_MT_EDIT',
				ty => $type,
				mtID => $id,
			},
		},
		COACH => {
			fields => {
				intActive => {
					label => $FieldLabels->{'Coach.intActive'} || 'Active?',
					type => 'checkbox',
					value => $DataVals{0}[0]{'intActive'},
					displaylookup => {1 => 'Yes', 0 => 'No'},
				},
				strString1 => {
					label => $FieldLabels->{'Coach.strString1'} || 'Coach Registration No.',
					type => 'text',
					size => 12,
					value => $DataVals{0}[0]{'strString1'},
				},
				strString2 => {
					label => $FieldLabels->{'Coach.strString2'} || 'Instructor Registration No.',
					type => 'text',
					size => 12,
					value => $DataVals{0}[0]{'strString2'},
				},
				intInt1 => {
					label => $FieldLabels->{'Coach.intInt1'} || 'Deregistered?',
					type => 'checkbox',
					value => $DataVals{0}[0]{'intInt1'},
					displaylookup => {1 => 'Yes', 0 => 'No'},
				},
        intInt6 => {
          label => $Data->{'SystemConfig'}{'COACH_intInt6_Custom1'} || '',
          type => 'lookup',
          value => $DataVals{0}[0]{'intInt6'},
          options =>  $DefCodes->{-43},
          firstoption => ['','Select Type'],
          compulsory => $Data->{'SystemConfig'}{'COACH_intInt6_compulsory'} || 0,
        },
        intInt7 => {
          label => $Data->{'SystemConfig'}{'COACH_intInt7_Custom1'} || '',
          type => 'lookup',
          value => $DataVals{0}[0]{'intInt7'},
          options =>  $DefCodes->{-44},
          firstoption => ['','Select Type'],
          compulsory => $Data->{'SystemConfig'}{'COACH_intInt7_compulsory'} || 0,
        },
        intInt8 => {
          label => $Data->{'SystemConfig'}{'COACH_intInt8_Custom1'} || '',
          type => 'lookup',
          value => $DataVals{0}[0]{'intInt8'},
          options =>  $DefCodes->{-45},
          firstoption => ['','Select Type'],
          compulsory => $Data->{'SystemConfig'}{'COACH_intInt8_compulsory'} || 0,
        },
        strString3 => {
          label => $Data->{'SystemConfig'}{'COACH_strString3_Custom1'} || '',,
          type => 'text',
          size => 12,
          value => $DataVals{0}[0]{'strString3'},
          compulsory => $Data->{'SystemConfig'}{'COACH_strString3_compulsory'} || 0,
        }
			},
			order => [qw(strString1 strString2 intInt1 intInt6 intInt7 intInt8 strString3)],
			options => {
				labelsuffix => ':',
				hideblank => 1,
				target => $Data->{'target'},
				formname => 'mt_form',
				submitlabel => 'Update Coach Member Type',
				introtext => 'auto',
				buttonloc => 'bottom',
				updateSQL => $mtupdate,
				addSQL => $mtadd,

        auditFunction=> \&auditLog,
        auditAddParams => [
          $Data,
          'Add',
          qq[Member Types: $member_type_names{$type}]
        ],
        auditEditParams => [
          $id,
          $Data,
          'Update',
          qq[Member Types: $member_type_names{$type}]
        ],

				stopAfterAction => 1,
				updateOKtext => qq[
					<div class="OKmsg">Record updated successfully</div> <br>
					<a href="$Data->{'target'}?client=$client&amp;a=M_MT_LIST&amp;ty=$type">Return to $member_type_names{$type} Member Type</a>
				],
				addOKtext => qq[
					<div class="OKmsg">Record updated successfully</div> <br>
					<a href="$Data->{'target'}?client=$client&amp;a=M_MT_LIST&amp;ty=$type">Return to $member_type_names{$type} Member Type</a>
				],
			},
			sections => [ ['main','Details'], ],
			carryfields =>  {
				client => $client,
				a=> 'M_MT_EDIT',
				ty => $type,
				mtID => $id,
			},
		},
		UMPIRE => {
			fields => {
				intActive => {
					label => $FieldLabels->{'Umpire.intActive'} || 'Active?',
					type => 'checkbox',
					value => $DataVals{0}[0]{'intActive'},
					displaylookup => {1 => 'Yes', 0 => 'No'},
				},
				strString1 => {
					label => $Data->{'SystemConfig'}{'UMPIRE_strString1_HIDE'} ? '' : $FieldLabels->{'Umpire.strString1'},
					type => 'text',
					size => 12,
					value => $DataVals{0}[0]{'strString1'},
				},
        intInt1 => {
          label => $FieldLabels->{'Umpire.intInt1'} || 'Type1',
          type => 'lookup',
          value => $DataVals{0}[0]{'intInt1'},
          options =>  $DefCodes->{-17},
        	firstoption => ['','Select Type'],
		      compulsory => $Data->{'SystemConfig'}{'UMPIRE_intInt1_compulsory'} || 0,
        },
        intInt2 => {
          label => $FieldLabels->{'Umpire.intInt2'} || 'Deregistered?',
          type => 'checkbox',
          value => $DataVals{0}[0]{'intInt2'},
          displaylookup => {1 => 'Yes', 0 => 'No'},
      	},
        intInt6 => {
          label => $Data->{'SystemConfig'}{'UMPIRE_intInt6_Custom1'} || '',
          type => 'lookup',
          value => $DataVals{0}[0]{'intInt6'},
          options =>  $DefCodes->{-40},
          firstoption => ['','Select Type'],
          compulsory => $Data->{'SystemConfig'}{'UMPIRE_intInt6_compulsory'} || 0,
        },
        intInt7 => {
          label => $Data->{'SystemConfig'}{'UMPIRE_intInt7_Custom2'} || '',
          type => 'lookup',
          value => $DataVals{0}[0]{'intInt7'},
          options =>  $DefCodes->{-41},
          firstoption => ['','Select Type'],
          compulsory => $Data->{'SystemConfig'}{'UMPIRE_intInt7_compulsory'} || 0,
        },
        intInt8 => {
          label => $Data->{'SystemConfig'}{'UMPIRE_intInt8_Custom3'} || '',
          type => 'lookup',
          value => $DataVals{0}[0]{'intInt8'},
          options =>  $DefCodes->{-42},
          firstoption => ['','Select Type'],
          compulsory => $Data->{'SystemConfig'}{'UMPIRE_intInt8_compulsory'} || 0,
        },
        intInt9 => {
          label => $Data->{'SystemConfig'}{'UMPIRE_intInt9_Custom4'} || '',
          type => 'lookup',
          value => $DataVals{0}[0]{'intInt9'},
          options =>  $DefCodes->{-46},
          firstoption => ['','Select Type'],
          compulsory => $Data->{'SystemConfig'}{'UMPIRE_intInt9_compulsory'} || 0,
        },
        intInt10 => {
          label => $Data->{'SystemConfig'}{'UMPIRE_intInt10_Custom5'} || '',
          type => 'lookup',
          value => $DataVals{0}[0]{'intInt10'},
          options =>  $DefCodes->{-47},
          firstoption => ['','Select Type'],
          compulsory => $Data->{'SystemConfig'}{'UMPIRE_intInt10_compulsory'} || 0,
        },
			},
			order => [qw(strString1 intInt1 intInt2 intInt6 intInt7 intInt8 intInt9 intInt10)],
			options => {
				labelsuffix => ':',
				hideblank => 1,
				target => $Data->{'target'},
				formname => 'mt_form',
				submitlabel => 'Update ' . $member_type_names{$type} . ' Member Type',
				introtext => 'auto',
				buttonloc => 'bottom',
				updateSQL => $mtupdate,
				addSQL => $mtadd,

        auditFunction=> \&auditLog,
        auditAddParams => [
          $Data,
          'Add',
          qq[Member Types: $member_type_names{$type}]
        ],
        auditEditParams => [
          $id,
          $Data,
          'Update',
          qq[Member Types: $member_type_names{$type}]
        ],

				stopAfterAction => 1,
				updateOKtext => qq[
					<div class="OKmsg">Record updated successfully</div> <br>
					<a href="$Data->{'target'}?client=$client&amp;a=M_MT_LIST&amp;ty=$type">Return to $member_type_names{$type} Member Type</a>
				],
				addOKtext => qq[
					<div class="OKmsg">Record updated successfully</div> <br>
					<a href="$Data->{'target'}?client=$client&amp;a=M_MT_LIST&amp;ty=$type">Return to $member_type_names{$type} Member Type</a>
				],
			},
			carryfields =>  {
				client => $client,
				a=> 'M_MT_EDIT',
				ty => $type,
				mtID => $id,
			},
		},
		ACCRED => {
			fields => \%Accreditations_fields,
			order => \@Accreditations_Order,
			options => {
				labelsuffix => ':',
				hideblank => 1,
				target => $Data->{'target'},
				formname => 'mt_form',
				submitlabel => 'Update Accreditation',
				introtext => 'auto',
				buttonloc => 'bottom',
				updateSQL => $mtupdate,
				addSQL => $mtadd,
        auditFunction=> \&auditLog,
        auditAddParams => [
          $Data,
          'Add',
          qq[Member Types: $member_type_names{$type} Accred]
        ],
        auditEditParams => [
          $id,
          $Data,
          'Update',
          qq[Member Types: $member_type_names{$type} Accred]
        ],
				stopAfterAction => 1,
				updateOKtext => qq[
					<div class="OKmsg">Record updated successfully</div> <br>
					<a href="$Data->{'target'}?client=$client&amp;a=M_MT_LIST&amp;ty=$type">Return to $member_type_names{$type} Member Type</a>
				],
				addOKtext => qq[
					<div class="OKmsg">Record updated successfully</div> <br>
					<a href="$Data->{'target'}?client=$client&amp;a=M_MT_LIST&amp;ty=$type">Return to $member_type_names{$type} Member Type</a>
				],
			},
			carryfields =>  {
				client => $client,
				a=> 'M_MT_EDIT',
				ty => $type,
				ty2 => $type2,
				mtID => $id,
			},
		},
		POSITION => {
			fields => \%Positions_fields, 
			order => \@Positions_Order,
			options => {
				labelsuffix => ':',
				hideblank => 1,
				target => $Data->{'target'},
				formname => 'mt_form',
				submitlabel => 'Update Position',
				introtext => 'auto',
				buttonloc => 'bottom',
				updateSQL => $mtupdate,
				addSQL => $mtadd,
        auditFunction=> \&auditLog,
        auditAddParams => [
          $Data,
          'Add',
          qq[Member Types: $member_type_names{$type} Position]
        ],
        auditEditParams => [
          $id,
          $Data,
          'Update',
          qq[Member Types: $member_type_names{$type} Position]
        ],
				stopAfterAction => 1,
				updateOKtext => qq[
					<div class="OKmsg">Record updated successfully</div> <br>
					<a href="$Data->{'target'}?client=$client&amp;a=M_MT_LIST&amp;ty=$type">Return to $member_type_names{$type} Member Type</a>
				],
				addOKtext => qq[
					<div class="OKmsg">Record updated successfully</div> <br>
					<a href="$Data->{'target'}?client=$client&amp;a=M_MT_LIST&amp;ty=$type">Return to $member_type_names{$type} Member Type</a>
				],
			},
			carryfields =>  {
				client => $client,
				a=> 'M_MT_EDIT',
				ty => $type,
				ty2 => $type2,
				mtID => $id,
			},
		},
	);
	if($Data->{'SystemConfig'}{'OnlySport'})	{
		$FieldDefs{'ACCRED'}{'fields'}{'intInt4'}{'readonly'}=1;
	}

	$DataVals{0}[0]{'intMemberTypeID'}||=0;
	######### Member Type - Player #########
	if($type == $Defs::MEMBER_TYPE_PLAYER)	{
		if(($type2||0)==$Defs::MEMBER_SUBTYPE_PLAYER_DISCIPLINES)	{
			($resultHTML, undef )=handleHTMLForm($FieldDefs{'ACCRED'}, undef, $option, '',$db);
		}
		else	{
			($resultHTML, undef )=handleHTMLForm($FieldDefs{'PLAYER'}, undef, $option, '',$db);
		}

		if($option eq 'display')	{
			$resultHTML .= allowedAction($Data, 'mt_e') ? qq[<span class="button-small generic-button"><a href="$target?a=M_MT_EDIT&amp;ty=$type&amp;mtID=$DataVals{0}[0]{'intMemberTypeID'}&amp;client=$client">Edit Details</a></span> ] : '';
		}
	}


	######### Member Type - Coach #########

	if($type == $Defs::MEMBER_TYPE_COACH)	{
		if($type2 eq $Defs::MEMBER_SUBTYPE_ACCRED)	{
			($resultHTML, undef )=handleHTMLForm($FieldDefs{'ACCRED'}, undef, $option, '',$db);
		}
		else	{
			($resultHTML, undef )=handleHTMLForm($FieldDefs{'COACH'}, undef, $option, '',$db);
		}
		$resultHTML.=qq[
				<span class="button-small generic-button"><a href="$target?a=M_MT_EDIT&amp;ty=$type&amp;mtID=$DataVals{0}[0]{'intMemberTypeID'}&amp;client=$client">Edit Details</a></span>
		] if $option eq 'display' and allowedAction($Data, 'mt_e');

		my $teamIDlist='';
		my $teamID_to_Name='';
		for my $i (0 .. $#{$DataVals{2}})	{
			$teamIDlist.=',' if $teamIDlist;
			$teamIDlist.=$DataVals{2}[$i]{'intInt2'} || '';
		}	
		if($teamIDlist)	{
			my $statement_teams = qq[
				SELECT intTeamID, strName
				FROM tblTeam
				WHERE intTeamID IN ($teamIDlist) 
					AND intAssocID=$assocID
			];
			($teamID_to_Name,undef)=getDBdrop_down_Ref($db, $statement_teams, '');	
		}
		my $coached='';
		my @rowdata=();
		for my $i (0 .. $#{$DataVals{2}})	{
			next if !$DataVals{2}[$i];
			next if $DataVals{2}[$i]{'intSubType'} != 2;
			my $act=$DataVals{2}[$i]{'intActive'} ? 'Yes' : 'No';
			my $reg=$DataVals{2}[$i]{'intActive'} ? 'Yes' : 'No';
			my $tm=$teamID_to_Name ? $teamID_to_Name->{$DataVals{2}[$i]{'intInt2'}} : ''|| '&nbsp;';
			my $ct=$DefCodes->{$DataVals{2}[$i]{'intInt1'}} || '&nbsp;';
			my $sd=_fixDate($DataVals{2}[$i]{'dtDate1'}) || '&nbsp;';
			my $ed=_fixDate($DataVals{2}[$i]{'dtDate2'}) || '&nbsp;';
			push @rowdata, {
          id => $i,
					active=>$act,
					tm=>$tm,
					ct=>$ct,
					sd=>$sd,
					ed=>$ed,	
					
        };
		}
		if($option eq 'display')	{
			if($coached)	{
				my @headerdata = (
			    {
      			type => 'Selector',
      			field => 'SelectLink',
    			},
    			{
      			name => "Active",
      			field => 'active',
    			},
    			{
      			name => "Team",
      			field => 'tm',
    			},
    			{
      			name => "Coach Type",
      			field => 'ct',
    			},
    			{
      			name => "Start Date",
      			field => 'sd',
    			},
    			{
      			name => "End Date",
      			field => 'ed',
    			},
				);
$resultHTML .= showGrid(
      Data => $Data,
      columns => \@headerdata,
      rowdata => \@rowdata,
      gridid => 'gridcoach',
      width => '99%',
      height => 700,
			simple=>1,
    );
			}
			$resultHTML.="<br><br>".show_accred(3, \%DataVals, $DefCodesFull,0, $client, $target, $type, '', $Defs::MEMBER_SUBTYPE_ACCRED, $Data) || '';
			$resultHTML.="<br><br>".showOtherAccred($Data, $memberID, $aID, $type, $DefCodes);
		}
	}

	######### Member Type - Umpire #########


	if($type == $Defs::MEMBER_TYPE_UMPIRE)	{
		if($type2 eq $Defs::MEMBER_SUBTYPE_ACCRED)	{
			($resultHTML, undef )=handleHTMLForm($FieldDefs{'ACCRED'}, undef, $option, '',$db);
		}
		else	{
			($resultHTML, undef )=handleHTMLForm($FieldDefs{'UMPIRE'}, undef, $option, '',$db);
			if($option eq 'display')	{
				$resultHTML.=qq[
					<span class="button-small generic-button"><a href="$target?a=M_MT_EDIT&amp;ty=$type&amp;mtID=$DataVals{0}[0]{'intMemberTypeID'}&amp;client=$client">Edit Details</a></span>
				] if (allowedAction($Data, 'mt_e') and !$Data->{'SystemConfig'}{'HIDE_UMPIRE_ED_LINK'});
				$resultHTML.="<br><br>".show_accred(4, \%DataVals, $DefCodesFull,0, $client, $target, $type, '', $Defs::MEMBER_SUBTYPE_ACCRED, $Data) || '';
				$resultHTML.="<br><br>".showOtherAccred($Data, $memberID, $aID, $type, $DefCodes);
			}
		}

	}
	if(
    $type == $Defs::MEMBER_TYPE_OFFICIAL 
    or $type == $Defs::MEMBER_TYPE_MISC
    or $type == $Defs::MEMBER_TYPE_VOLUNTEER
  )	{

    $FieldDefs{'POSITION'}{'fields'}{'intInt2'}{'options'}=$DefCodes->{-16} if $type == $Defs::MEMBER_TYPE_MISC;
    $FieldDefs{'POSITION'}{'fields'}{'intInt2'}{'options'}=$DefCodes->{-14} if $type == $Defs::MEMBER_TYPE_OFFICIAL;
    $FieldDefs{'POSITION'}{'fields'}{'intInt2'}{'options'}=$DefCodes->{-56} if $type == $Defs::MEMBER_TYPE_VOLUNTEER;

		if($type2 eq $Defs::MEMBER_SUBTYPE_ACCRED)	{
			($resultHTML, undef )=handleHTMLForm($FieldDefs{'ACCRED'}, undef, $option, '',$db);
		}
		elsif($type2 eq $Defs::MEMBER_SUBTYPE_POS)	{
		  ($resultHTML, undef )=handleHTMLForm($FieldDefs{'POSITION'}, undef, $option, '',$db) if $option ne 'display';
		}
		if($option eq 'display')	{
      my $pos_position_label = ($Data->{'SystemConfig'}{'POS_Position_Label'} and $type == $Defs::MEMBER_TYPE_MISC) 
        ? $Data->{'SystemConfig'}{'POS_Position_Label'} 
        : "Position";
      my $pos_level_label = ($Data->{'SystemConfig'}{'POS_Level_Label'} and $type == $Defs::MEMBER_TYPE_MISC) 
        ? $Data->{'SystemConfig'}{'POS_Level_Label'} 
        : "Type";
      my $pos_pref_label = ($Data->{'SystemConfig'}{'POS_Preference_Label'} and $type == $Defs::MEMBER_TYPE_MISC) 
        ? $Data->{'SystemConfig'}{'POS_Preference_Label'} 
        : "&nbsp;";
      my $pos_natno_label = ($Data->{'SystemConfig'}{'POS_RegNo_Label'} and $type == $Defs::MEMBER_TYPE_MISC) 
        ? $Data->{'SystemConfig'}{'POS_RegNo_Label'} 
        : "Registration No.";
      my $pos_stateno_label = ($Data->{'SystemConfig'}{'POS_RegNo2_Label'} and $type == $Defs::MEMBER_TYPE_MISC) 
        ? $Data->{'SystemConfig'}{'POS_RegNo2_Label'} 
        : "&nbsp;";
			my @headerdata = (
    	{
    	  type => 'Selector',
    	  field => 'SelectLink',
    	},
    	{
    	  name => "Active",
    	  field => 'active',
    	},
    	{
    	  name => "$pos_position_label",
    	  field => 'ot',
    	},
    	{
      	name => "$pos_level_label",
      	field => 'eID',
    	},
		);
		if ($Data->{'SystemConfig'}{'POS_Preference_Label'})	{
			push @headerdata,
				{
					name=>$pos_position_label."s Held",
				field => 'prefID',
				};
		}
		push @headerdata,
			{
				name=>"$pos_natno_label",
				field=> 'rn',
			},
			{
				name=>"$pos_stateno_label",
				field=>'sn',
			},
			{
				name=>"Start Date",
				field=>'startdate',
			},
			{
				name=>"End Date",
				field=>'enddate',
		};
			
			my $st=$Defs::MEMBER_SUBTYPE_POS;
			my @rowdata=();
			for my $i (0 .. $#{$DataVals{$st}})	{
				my $act=$DataVals{$st}[$i]{'intActive'} ? 'Yes' : 'No';
					next if !defined $DataVals{$st}[$i]{'intMemberTypeID'};
					my $etID=$Defs::entityInfo{$DataVals{$st}[$i]{'intInt1'}} || '&nbsp;';
					my $ot=$DefCodesFull->{$DataVals{$st}[$i]{'intInt2'}} || '&nbsp;';
					my $eID=$DefCodesFull->{$DataVals{$st}[$i]{'intInt4'}} || '&nbsp;';
					my $prefID=$DefCodesFull->{$DataVals{$st}[$i]{'intInt5'}} || '&nbsp;';
					my $pID=$DataVals{$st}[$i]{'intInt7'} || '&nbsp;';
					my $rn=$DataVals{$st}[$i]{'strString1'} || '&nbsp;';
					my $sn=$DataVals{$st}[$i]{'strString2'} || '&nbsp;';
					my $sd=_fixDate($DataVals{$st}[$i]{'dtDate1'}) || '&nbsp;';
					my $ed=_fixDate($DataVals{$st}[$i]{'dtDate2'}) || '&nbsp;';
					my $edit= allowedAction($Data, 'mt_e') ? qq[<span class="button-small generic-button"><a href="$target?a=M_MT_EDIT&amp;ty=$type&amp;mtID=$DataVals{$st}[$i]{'intMemberTypeID'}&amp;client=$client&amp;ty2=$Defs::MEMBER_SUBTYPE_POS">Edit</a></span>] : '';
					my $selectLink_edit= allowedAction($Data, 'mt_e') ? "$target?a=M_MT_EDIT&amp;ty=$type&amp;mtID=$DataVals{$st}[$i]{'intMemberTypeID'}&amp;client=$client&amp;ty2=$Defs::MEMBER_SUBTYPE_POS" : '';
#BAFF
					push @rowdata, {
        	  id => $DataVals{$st}[$i]{'intMemberTypeID'},
						SelectLink=>$selectLink_edit,
  	        active => $act,
						prefID=>$prefID,
						pID=>$pID,
						eID=>$eID,
						ot=>$ot,
						rn=>$rn,
					sn=>$sn,
					startdate=>$sd,
					enddate=>$ed,
    };

				}
				my $bulk_edit = allowedAction($Data, 'mt_a') ? qq[<span class="button-small generic-button"><a href="$target?a=M_MT_BULK_EDIT&amp;ty=$type&amp;client=$client&amp;ty2=$st">Bulk Add/Edit</a></span>] : '';
				my $add=allowedAction($Data, 'mt_a') ? qq[<span class="button-small generic-button"><a href="$target?a=M_MT_ADD&amp;ty=$type&amp;client=$client&amp;ty2=$st">Add New</a></span> $bulk_edit] : '';
				my $list = showGrid(
      Data => $Data,
      columns => \@headerdata,
      rowdata => \@rowdata,
      gridid => "grid$gridID",
      width => '99%',
      height => 200,
			simple=>1,
    );
				$resultHTML.=qq[
					$add
					$list
				];
				$resultHTML.="<br><br>".show_accred(1, \%DataVals, $DefCodesFull,0, $client, $target, $type, '', $Defs::MEMBER_SUBTYPE_ACCRED, $Data) || '';
				$resultHTML.="<br><br>".showOtherAccred($Data, $memberID, $aID, $type, $DefCodes);
			}
		}

		$resultHTML=qq[
			<div>This member does not have any $Defs::memberTypeNames{$type} information to display.</div>
		] if !scalar(keys %DataVals);

		#<div class="alphaNav">$toplist</div>
		$resultHTML=qq[
				<div> 
					$resultHTML
				</div>
		];

  my $title = ($Data->{'SystemConfig'}{'TYPE_NAME_' . $type})
      ? $Data->{'SystemConfig'}{'TYPE_NAME_' . $type}
      : $Defs::memberTypeName{$type};

	#my $heading=qq[Member Types - ].uc($Defs::memberTypeName{$type});
	my $heading=qq[Member Types - ].uc($title);
	return ($resultHTML,$heading);
}

sub genLine	{
	my($line, $editline)=@_;
	my $str='';
	for my $val (@{$line})	{
		$str.=qq[<td>$val</td>\n];
	}
	$str.=qq[<td>$editline</td>\n] if $editline;
	if($str)	{
		$str=qq[
		<tr>
			$str
		</tr>
		];
	}
	return $str || '';
}


sub show_accred	{
	my($gridID, $DataVals, $DefCodes, $disc, $client, $target, $type, $header, $type2, $Data, $readonly, $assocname)=@_;
	$disc||=0;
	$readonly||=0;
	$assocname||='';
	my $name= $disc ? 'Disciplines' : 'Accreditations';
	$name.=" - $assocname" if $assocname;
	$header||='';
	my $cl=$disc ? ' <th>Class</th>' : '';
	my $SWSports=getSWSports();
	my $noSport = $Data->{'SystemConfig'}{'OnlySport'} || 0;
	my $sline=$noSport ? '' : '<th>Sport</th>';
	## DEFINE FIELD LABELS
 	my $FieldLabels=FieldLabels::getFieldLabels($Data, $Defs::LEVEL_MEMBER);
	my $active_title = ($FieldLabels->{'Accred.intActive'}) ? $FieldLabels->{'Accred.intActive'} : 'Active';
	my $type_title = ($FieldLabels->{'Accred.intInt1'}) ? $FieldLabels->{'Accred.intInt1'} : 'Type';
	my $level_title = ($FieldLabels->{'Accred.intInt2'}) ? $FieldLabels->{'Accred.intInt2'} : 'Level';
	my $accreditation_provider_title = ($FieldLabels->{'Accred.intInt5'}) ? $FieldLabels->{'Accred.intInt5'} : 'Accreditation Provider';
	my $start_date_title = ($FieldLabels->{'Accred.dtDate1'}) ? $FieldLabels->{'Accred.dtDate1'} : 'Start Date';
	my $end_date_title = ($FieldLabels->{'Accred.dtDate2'}) ? $FieldLabels->{'Accred.dtDate2'} : 'End Date';
	##

	my @headerdata = (
    {
      type => 'Selector',
      field => 'SelectLink',
    },
    {
      name => "$active_title",
      field => 'active',
    },
	);
	unless ($noSport)	{
		push @headerdata,	
			{
				name=>'Sport',
				field=>'sport',
			};
	}
	push @headerdata, 	
		{
			name=>"$type_title",
			field=>'type',
		},
		{
			name=>"$level_title",
			field=>'level',
		};
	if ($disc)	{
		push @headerdata,
			{
				name=>'Class',
				field=>'class',
			};
	}
	push @headerdata,
		{
			name=>"$start_date_title",
			field=>'startdate',
		},
		{
			name=>"$end_date_title",
			field=>'enddate',
		},
		{
			name=>"$accreditation_provider_title",
			field=>'ap',
		},
		{
			name=>'&nbsp;',
			field=>'reaccred',
		};

	my @rowdata=();
	for my $i (0 .. $#{$DataVals->{$Defs::MEMBER_SUBTYPE_ACCRED}})	{
		next if !defined $DataVals->{$Defs::MEMBER_SUBTYPE_ACCRED}[$i]{'intMemberTypeID'};
		my $act=$DataVals->{$Defs::MEMBER_SUBTYPE_ACCRED}[$i]{'intActive'} ? 'Yes' : 'No';
		my $reaccred=$DataVals->{$Defs::MEMBER_SUBTYPE_ACCRED}[$i]{'intInt7'} ? '*' : '';
		my $tID=$DefCodes->{$DataVals->{$Defs::MEMBER_SUBTYPE_ACCRED}[$i]{'intInt1'}} || '';
		my $lID=$DefCodes->{$DataVals->{$Defs::MEMBER_SUBTYPE_ACCRED}[$i]{'intInt2'}} || '';
		my $cID=$DefCodes->{$DataVals->{$Defs::MEMBER_SUBTYPE_ACCRED}[$i]{'intInt3'}} || '';
		my $sID=$SWSports->{$DataVals->{$Defs::MEMBER_SUBTYPE_ACCRED}[$i]{'intInt4'}} || '';
		my $apID=$DefCodes->{$DataVals->{$Defs::MEMBER_SUBTYPE_ACCRED}[$i]{'intInt5'}} || '';
		my $sd=_fixDate($DataVals->{$Defs::MEMBER_SUBTYPE_ACCRED}[$i]{'dtDate1'}) || '';
		my $ed=_fixDate($DataVals->{$Defs::MEMBER_SUBTYPE_ACCRED}[$i]{'dtDate2'}) || '';
		$sd='' if $sd eq '00/00/00';
		$ed='' if $ed eq '00/00/00';
		next if($apID eq '' and $lID eq ''  and $tID eq '');
		my $edit= allowedAction($Data, 'mt_e') ? qq~<span class="button-small generic-button"><a href="$target?a=M_MT_EDIT&amp;ty=$type&amp;mtID=$DataVals->{1}[$i]{'intMemberTypeID'}&amp;client=$client&amp;ty2=$type2">Edit</a></span>~ : '';
		my $selectLink_edit = allowedAction($Data, 'mt_e') ? "$target?a=M_MT_EDIT&amp;ty=$type&amp;mtID=$DataVals->{1}[$i]{'intMemberTypeID'}&amp;client=$client&amp;ty2=$type2": '';
		$selectLink_edit='' if $readonly;
		push @rowdata, {
          id => $DataVals->{$Defs::MEMBER_SUBTYPE_ACCRED}[$i]{'intMemberTypeID'},
					SelectLink=>$selectLink_edit,
          active => $act,
					sport=>$sID,
					type=>$tID,
					level=>$lID,
					class=>$cID,
					startdate=>$sd,
					enddate=>$ed,
					ap=>$apID,
					reaccred=>$reaccred,
    };
	}
	my $cs=8;
	if($disc)	{ $cs=9;	}
	my $bulk_edit = allowedAction($Data, 'mt_a') ? qq[<span class="button-small generic-button"><a href="$target?a=M_MT_BULK_EDIT&amp;ty=$type&amp;client=$client&amp;ty2=$type2">Bulk Add/Edit</a></span>] : '';
	my $add=allowedAction($Data, 'mt_a') ? qq[<span class="button-small generic-button"><a href="$target?a=M_MT_ADD&amp;ty=$type&amp;client=$client&amp;ty2=$type2">Add New</a></span> $bulk_edit] : '';
	$add='' if $readonly;
	my $list = showGrid(
      Data => $Data,
      columns => \@headerdata,
      rowdata => \@rowdata,
      gridid => "agrid$gridID",
      width => '99%',
      height => 200,
			simple=>1,
    );
	my $resultHTML.=qq[
		$add
		$list
	];
	return $resultHTML;
}


sub showOtherAccred	{
	my ($Data, $memberID, $aID, $type)=@_;

	my %DataVals=();

	#Get the assoc ID's that we are allowed to expose
	my %exposedAssocIDs=();
	if($Data->{'SystemConfig'}{'AccredExpose'})	{
		my @assocs=split /\|/,$Data->{'SystemConfig'}{'AccredExpose'};
		for my $i (@assocs)	{$exposedAssocIDs{$i}=1;}
	}
	else	{ return ''; }
	my $statement=qq[
		SELECT tblAssoc.strName, tblAssoc.intAssocID, tblMember_Types.* , DATE_FORMAT(dtDate1 ,"%d/%m/%Y") AS dtDate1, DATE_FORMAT(dtDate2,"%d/%m/%Y") AS dtDate2
		FROM tblMember_Types INNER JOIN tblAssoc ON (tblMember_Types.intAssocID=tblAssoc.intAssocID)
		WHERE intTypeID=$type
			AND intMemberID=$memberID
			AND tblMember_Types.intAssocID <>  $aID 
		ORDER BY intSubTypeID ASC, tblMember_Types.dtDate1, tblMember_Types.dtDate2
	];

	my $query = $Data->{'db'}->prepare($statement);
	$query->execute;
	my %otherassocs=();
	while(my $dref=$query->fetchrow_hashref())	{
		$otherassocs{$dref->{'intAssocID'}}=$dref->{'strName'};
		push @{$DataVals{$dref->{'intAssocID'}}{$dref->{intSubTypeID}}}, $dref;
	}

	my $subBody='';
	
	for my $a (sort {$otherassocs{$a} cmp $otherassocs{$b}} keys %DataVals)	{
		next if !($exposedAssocIDs{$a} or $exposedAssocIDs{'ALL'});
		my $st=qq[
			SELECT intCodeID, strName
			FROM tblDefCodes
      			WHERE intRealmID=$Data->{'Realm'}
        		AND (intAssocID = $a OR intAssocID = 0)
		];
		my ($dc,undef)=getDBdrop_down_Ref($Data->{'db'}, $st);	
		$subBody.=show_accred(2, $DataVals{$a}, $dc, 0, '', '', '', 1, 0, $Data, 1, $otherassocs{$a});
	}
	return $subBody;

}


## DEREGISTRATION CHECK ##
## Created by TC - 12/9/2007
## Last Updated by TC - 12/9/2007
##
## Checks to see if the member is a deregistered coach
## or umpire. Will only display if the summary accreditation 
## details are displayed on the member details screen
##
## IN
## $memberID - The id of the member
## $type - Whether the check is for a coach or umpire
## $Data - Contains generic data
##
## OUT
## Return text to be displayed if dregistered otherwise
## retuens null 

sub deregistration_check {
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
	else {
		return 0;
	}
}

sub _fixDate {
  my ($date)=@_;
  $date||='';
  $date=~ s/(\d\d\d\d)-(\d\d)-(\d\d)(.*)/$3\/$2\/$1/;
  $date='' if $date eq '00/00/0000';
  return $date;
}

sub ActiveAccredSummary {
	my ($Data, $memberID, $aID)=@_;

	my %DataVals=();

	#Get the assoc ID's that we are allowed to expose
	my %exposedAssocIDs=();
	if($Data->{'SystemConfig'}{'AccredExpose'})	{
		my @assocs=split /\|/,$Data->{'SystemConfig'}{'AccredExpose'};
		for my $i (@assocs)	{$exposedAssocIDs{$i}=1;}
	}
	else	{ return []; }
	my $assoclist = join(',',keys %exposedAssocIDs, $aID);
	my $st=qq[
		SELECT intCodeID, strName
		FROM tblDefCodes
		WHERE intRealmID=$Data->{'Realm'}
		AND intAssocID IN ($assoclist,0)
	];
	my ($dc,undef)=getDBdrop_down_Ref($Data->{'db'}, $st);	

	my $statement=qq[
		SELECT 
			tblAssoc.strName, 
			tblAssoc.intAssocID, 
			tblMember_Types.* , 
			DATE_FORMAT(dtDate1 ,"%d/%m/%Y") AS dtDate1, 
			DATE_FORMAT(dtDate2,"%d/%m/%Y") AS dtDate2
		FROM tblMember_Types 
			INNER JOIN tblAssoc ON (tblMember_Types.intAssocID=tblAssoc.intAssocID)
		WHERE intSubTypeID = $Defs::MEMBER_SUBTYPE_ACCRED
			AND intActive = 1
			AND intMemberID = ?
			AND tblAssoc.intAssocID IN ($assoclist)
			AND dtDate1 <= SYSDATE()
			AND dtDate2 >= SYSDATE()
		ORDER BY tblMember_Types.dtDate1, tblMember_Types.dtDate2
	];
	my $query = $Data->{'db'}->prepare($statement);
	$query->execute($memberID);
	my @rowdata = ();
	while(my $dref=$query->fetchrow_hashref())	{
		$dref->{'AccredType'} = 'Coach' if $dref->{'intTypeID'} == $Defs::MEMBER_TYPE_COACH;
		$dref->{'AccredType'} = ($Data->{'SystemConfig'}{'UmpireLabel'} || 'Match Official') if $dref->{'intTypeID'} == $Defs::MEMBER_TYPE_UMPIRE;

		$dref->{'Level'} = $dc->{$dref->{'intInt2'}} || '';
		push @rowdata, $dref;
	}

	return \@rowdata;
}

1;
