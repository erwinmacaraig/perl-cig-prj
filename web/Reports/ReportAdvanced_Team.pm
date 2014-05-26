#
# $Header: svn://svn/SWM/trunk/web/Reports/ReportAdvanced_Team.pm 11220 2014-04-03 04:43:54Z dhanslow $
#

package Reports::ReportAdvanced_Team;

use strict;
use lib ".";
use ReportAdvanced_Common;
use Reports::ReportAdvanced;
our @ISA =qw(Reports::ReportAdvanced);


use strict;

sub _getConfiguration {
	my $self = shift;

	my $currentLevel = $self->{'EntityTypeID'} || 0;
	my $Data = $self->{'Data'};
	my $SystemConfig = $self->{'SystemConfig'};
	my $clientValues = $Data->{'clientValues'};
	my $CommonVals = getCommonValues(
		$Data,
		{
			SubRealms => 1,
      CustomFields => 1,
      Seasons => 1,
      FieldLabels => 1,
      DefCodes => 1,
      AgeGroups => 1,
      Products => 1,
      Grades => 1,
		},
	);
  my $hideSeasons = $CommonVals->{'Seasons'}{'Hide'} || 0;
  my $txt_SeasonName= $Data->{'SystemConfig'}{'txtSeason'} || 'Season';
  my $txt_SeasonNames= $Data->{'SystemConfig'}{'txtSeasons'} || 'Seasons';
  my $RealmLPF_Ids = ($Data->{'SystemConfig'}{'LPF_ids'})
    ? $Data->{'SystemConfig'}{'LPF_ids'}
    : 0;

  my %NRO=();
  $NRO{'Accreditation'}= (
    ($clientValues->{assocID} >0
      or $clientValues->{clubID} > 0)
    ? 1
    :0
    )
    || $SystemConfig->{'RepAccred'} || 0; #National Report Options 
  $NRO{'RepCompLevel'}= (
      ($clientValues->{assocID} >0
        or $clientValues->{clubID} > 0) ? 1 :0)
      || $SystemConfig->{'RepCompLevel'} || 0; #National Report Options


	my %config = (
		Name => 'Detailed Team Report',

		StatsReport => 0,
		MemberTeam => 0,
		ReportEntity => 2,
		ReportLevel => 0,
		Template => 'default_adv',
    TemplateEmail => 'default_adv_CSV',
		DistinctValues => 1,
    SQLBuilder => \&SQLBuilder,
    DefaultPermType => 'Team',


		Fields => {
			intRecStatus=> [
				'Active',
				{
					displaytype=>'lookup', 
					fieldtype=>'dropdown', 
					dropdownoptions=> {0=>'No', 1=>'Yes'}, 
					dbfield=>'tblTeam.intRecStatus', 
				  defaultcomp=>'equal', 
					defaultvalue=>'1', 
					active=>1,
				}
			],
			strName=> [
				"$Data->{'LevelNames'}{$Defs::LEVEL_TEAM} Name",
				{
					displaytype=>'text', 
					fieldtype=>'text', 
					active=>1, 
					allowgrouping=>1,
					allowsort=>1, 
					dbfield => 'tblTeam.strName',
				}
			],
			intLogins=> [
				'Number of Logins',
				{
					displaytype=>'text', 
					fieldtype=>'text', 
					allowsort=>1, 
					dbfrom=>"LEFT JOIN tblAuth ON (tblTeam.intTeamID = tblAuth.intID and tblAuth.intLevel=2)",
				}
			],
			strContact=> [
				'Contact Person',
				{
					displaytype=>'text', 
					fieldtype=>'text', 
					active=>1, 
					allowsort=>1, 
					dbfield => 'tblTeam.strContact',
				}
			],

			strNickname=> ["$Data->{'LevelNames'}{$Defs::LEVEL_TEAM} Nick Name",{displaytype=>'text', fieldtype=>'text', allowsort=>1, dbfield => 'tblTeam.strNickname'}],
			strAddress1=> [
				'Address Line 1',
				{
					displaytype=>'text', 
					fieldtype=>'text', 
					allowsort=>1, 
					dbfield => 'tblTeam.strAddress1',
				}
			],
			strAddress2=> [
				'Address Line 2',
				{
					displaytype=>'text', 
					fieldtype=>'text', 
					allowsort=>1, 
					dbfield => 'tblTeam.strAddress2',
				}
			],
			strSuburb=> [
				'Suburb',
				{
					displaytype=>'text', 
					fieldtype=>'text', 
					allowsort=>1, 
					dbfield => 'tblTeam.strSuburb',
				}
			],
			strState=> [
				'State',
				{
					displaytype=>'text', 
					fieldtype=>'text', 
					allowsort=>1, 
					dbfield => 'tblTeam.strState',
					allowgrouping=>1,
				}
			],
			strPostalCode=> [
				'Postal Code',
				{
					displaytype=>'text', 
					fieldtype=>'text', 
					allowsort=>1, 
					dbfield => 'tblTeam.strPostalCode',
				}
			],
			strPhone1 => [
				'Phone',
				{
					displaytype=>'text', 
					fieldtype=>'text', 
					allowsort=>1, 
					dbfield => 'tblTeam.strPhone1',
				}
			],
			strPhone2 => [
				'Phone 2',
				{
					displaytype=>'text', 
					fieldtype=>'text', 
					allowsort=>1, 
					dbfield => 'tblTeam.strPhone2',
				}
			],			
			strMobile => [
				'Mobile',
				{
					displaytype=>'text', 
					fieldtype=>'text', 
					allowsort=>1, 
					dbfield => 'tblTeam.strMobile',
				}
			],			
			strEmail=> [
				'Email',
				{
					displaytype=>'text', 
					fieldtype=>'text', 
					allowsort=>1, 
					dbfield => 'tblTeam.strEmail',
				}
			],
			strNotes=> [
                                'Team Notes',
                                {
                                        displaytype=>'text',
                                        fieldtype=>'text',
                                        allowsort=>0,
                                        dbfield => 'tblTeam.strTeamNotes',
                                }
                        ],

			strWebURL=> ['Website URL',
				{displaytype=>'text', fieldtype=>'text', allowsort=>1, dbfield => 'tblTeam.strWebURL'}],
			strUniformTopColour=> 
				['Uniform Top Colour',{displaytype=>'text', fieldtype=>'text', allowsort=>1, dbfield => 'tblTeam.strUniformTopColour', optiongroup => 'colours'}],
			strUniformBottomColour=> 
				['Uniform Bottom Colour',{displaytype=>'text', fieldtype=>'text', allowsort=>1, dbfield => 'tblTeam.strUniformBottomColour', optiongroup => 'colours'}],
       strUniformNumber=> ['Uniform Number Colour',{displaytype=>'text', fieldtype=>'text', allowsort=>1, dbfield => 'tblTeam.strUniformNumber', optiongroup => 'colours'}],
       strAltUniformTopColour=> ['Alternate Uniform Top Colour',{displaytype=>'text', fieldtype=>'text', allowsort=>1, dbfield => 'tblTeam.strAltUniformTopColour', optiongroup => 'colours'}],
       strAltUniformBottomColour=> ['Alternate Uniform Bottom Colour',{displaytype=>'text', fieldtype=>'text', allowsort=>1, dbfield => 'tblTeam.strAltUniformBottomColour', optiongroup => 'colours'}],
       strAltUniformNumber=> ['Alternate Uniform Number Colour',{displaytype=>'text', fieldtype=>'text', allowsort=>1, dbfield => 'tblTeam.strAltUniformNumber', optiongroup => 'colours'}],

        intTeamCreatedFrom=> ['Record creation',{displaytype=>'lookup', fieldtype=>'dropdown', dropdownoptions => \%Defs::CreatedBy, allowsort=>1, dbfield=>'IF(intTeamCreatedFrom NOT IN (0,1,200), -1, intTeamCreatedFrom)', allowgrouping=>1}],
        dtTeamCreatedOnline=> ['Date Created Online',{displaytype=>'date', fieldtype=>'datetime', allowsort=>1, dbformat=>' DATE_FORMAT(tblTeam.dtTeamCreatedOnline,"%d/%m/%Y")', dbfield=>'tblTeam.dtTeamCreatedOnline', allowgrouping=>1}],
        dtLastUpdate=> ['Last Updated',{displaytype=>'date', fieldtype=>'datetime', allowsort=>1, dbformat=>' DATE_FORMAT(tblTeam.tTimeStamp,"%d/%m/%Y")', dbfield=>'tblTeam.tTimeStamp'}],

        strTitle=> ["Competition Name",{displaytype=>'text', fieldtype=>'text', active=>1, allowgrouping=>1, allowsort=>1 , optiongroup => 'comp'}],
        CompintRecStatus=> ['Competition Active ?',{displaytype=>'lookup', fieldtype=>'dropdown', dropdownoptions=>{0=>'No', 1=>'Yes'}, dropdownorder=>[0,1], dbfield=>'tblAssoc_Comp.intRecStatus', optiongroup => 'comp'}],
        #intSeasonID=> ['Season',{displaytype=>'lookup', fieldtype=>'dropdown', dropdownoptions=>$CommonVals->{'DefCodes'}{-5}, allowgrouping=>1}],
  intNewSeasonID=> ["$txt_SeasonName",{displaytype=>'lookup', fieldtype=>'dropdown', dropdownoptions => $CommonVals->{'Seasons'}{'Options'},  dropdownorder=>$CommonVals->{'Seasons'}{'Order'}, allowsort=>1, active=>0, multiple=>1, size=>3, dbfield=>"intNewSeasonID", disable=>$hideSeasons , optiongroup => 'comp'}],
        #intCompLevelID=> [$NRO{'RepCompLevel'} ? 'Competition Level': '',{displaytype=>'lookup', fieldtype=>'dropdown', dropdownoptions=>$CommonVals->{'DefCodes'}{-21}, optiongroup => 'comp'}],
        intCompTypeID=> [$NRO{'RepCompLevel'} ? 'Competition Type': '',{displaytype=>'lookup', fieldtype=>'dropdown', dropdownoptions=>$CommonVals->{'DefCodes'}{-36}, optiongroup => 'comp', allowsort => 1, allowgrouping => 1,}],
        intGradeID=> ['Grade',{displaytype=>'lookup', fieldtype=>'dropdown',  dropdownoptions=>$CommonVals->{'Grades'}, optiongroup => 'comp', allowsort => 1, allowgrouping => 1,}],
        intCompGender=> ['Gender',{displaytype=>'lookup', fieldtype=>'dropdown', dropdownoptions=>\%Defs::genderInfo, optiongroup => 'comp', allowsort => 1, allowgrouping => 1,}],
        #strAgeLevel=> ['Age Level',{displaytype=>'lookup', fieldtype=>'dropdown', dropdownoptions=>\%Defs::CompAgeLevel, optiongroup => 'comp'}],
       intTeamFinancial=> ["$Data->{'LevelNames'}{$Defs::LEVEL_TEAM} Financial in $Data->{'LevelNames'}{$Defs::LEVEL_COMP}?",{displaytype=>'lookup', fieldtype=>'dropdown', dropdownoptions=>{0=>'No', 1=>'Yes'}, optiongroup => 'comp'}],
        intCompTypeID=> [$NRO{'RepCompLevel'} ? 'Competition Type': '',{displaytype=>'lookup', fieldtype=>'dropdown', dropdownoptions=>$CommonVals->{'DefCodes'}{-36}, optiongroup => 'comp', allowsort => 1, allowgrouping => 1,}],
        intGradeID=> ['Grade',{displaytype=>'lookup', fieldtype=>'dropdown', dropdownoptions=>$CommonVals->{'Grades'}, optiongroup => 'comp', allowsort => 1, allowgrouping => 1,}],
        intCompGender=> ['Gender',{displaytype=>'lookup', fieldtype=>'dropdown', dropdownoptions=>\%Defs::genderInfo, optiongroup => 'comp', allowsort => 1, allowgrouping => 1,}],
       intAgeGroupID=> ['Default Age Group' ,{displaytype=>'lookup', fieldtype=>'dropdown', dropdownoptions=>$CommonVals->{'AgeGroups'}{'Options'},  dropdownorder=>$CommonVals->{'AgeGroups'}{'Order'}, active=>1, optiongroup=>'comp', allowsort => 1, allowgrouping => 1,}],
        intTeamNum => ["Team Number in Competition",{displaytype=>'text', fieldtype=>'text', active=>1, allowgrouping=>1, allowsort=>1 , optiongroup => 'comp'}],


			strClubName=> [
				"$Data->{'LevelNames'}{$Defs::LEVEL_CLUB} Name",
				{
					displaytype=>'text', 
					fieldtype=>'text', 
					allowsort=>1, 
					allowgrouping => 1,
					dbfield => 'tblClub.strName', 
				  optiongroup => 'affiliations',
					dbfrom=>' LEFT JOIN tblClub ON tblTeam.intClubID=tblClub.intClubID'
				}
			],
			strAssocName => [
				$Data->{'LevelNames'}{$Defs::LEVEL_ASSOC}.' Name',
				{
					displaytype=>'text',
					fieldtype=>'text',
					allowsort=>1,
					active=>1,
				  optiongroup => 'affiliations',
					dbfield=>'tblAssoc.strName',
					enabled => $clientValues->{assocID}==-1,
					allowgrouping=>1,
				}
			],

			intAssocTypeID=> [
				$Data->{'LevelNames'}{$Defs::LEVEL_ASSOC}.' Type',
				{
					displaytype=>'lookup',
					fieldtype=>'dropdown',
					dropdownoptions=> $CommonVals->{'SubRealms'},
					allowsort=>1,
				  optiongroup => 'affiliations',
					enabled => (scalar(keys %{$CommonVals->{'SubRealms'}}) and  $currentLevel > $Defs::LEVEL_ASSOC),
					allowgrouping=>1,
				}
			],

			strZoneName=> [
				$Data->{'LevelNames'}{$Defs::LEVEL_ZONE}.' Name',
				{
					displaytype=>'text',
					fieldtype=>'text',
					allowsort=>1,
					dbfield => "IF(tblZone.intStatusID = $Defs::NODE_SHOW, tblZone.strName, '')",
					allowgrouping=>1,
					active=>1,
				  optiongroup => 'affiliations',
					enabled => $currentLevel > $Defs::LEVEL_ZONE,
				}
			],

			strRegionName=> [
				$Data->{'LevelNames'}{$Defs::LEVEL_REGION}.' Name',
				{
					displaytype=>'text',
					fieldtype=>'text',
					allowsort=>1,
					dbfield => "IF(tblRegion.intStatusID = $Defs::NODE_SHOW, tblRegion.strName, '')",
					allowgrouping=>1,
					active=>1,
				  optiongroup => 'affiliations',
					enabled => $currentLevel > $Defs::LEVEL_REGION,
				}
			],

			strStateName=> [
				$Data->{'LevelNames'}{$Defs::LEVEL_STATE}.' Name',
				{
					displaytype=>'text',
					fieldtype=>'text',
					allowsort=>1,
					dbfield => "IF(tblState.intStatusID = $Defs::NODE_SHOW, tblState.strName, '')",
					allowgrouping=>1,
					active=>1,
				  optiongroup => 'affiliations',
					enabled => $currentLevel > $Defs::LEVEL_STATE,
				}
			],

			strNationalName=> [
				$Data->{'LevelNames'}{$Defs::LEVEL_NATIONAL}.' Name',
				{
					displaytype=>'text',
					fieldtype=>'text',
					allowsort=>1,
					dbfield => "IF(tblNational.intStatusID = $Defs::NODE_SHOW, tblNational.strName, '')",
					allowgrouping=>1,
					active=>1,
				  optiongroup => 'affiliations',
					enabled => $currentLevel > $Defs::LEVEL_NATIONAL,
				}
			],

			strIntZoneName=> [
				$Data->{'LevelNames'}{$Defs::LEVEL_INTZONE}.' Name',
				{
					displaytype=>'text',
					fieldtype=>'text',
					allowsort=>1,
					dbfield => "IF(tblIntZone.intStatusID = $Defs::NODE_SHOW, tblIntZone.strName, '')" ,
					allowgrouping=>1,
					active=>1,
				  optiongroup => 'affiliations',
					enabled => $currentLevel > $Defs::LEVEL_INTZONE,
				}
			],

			strIntRegionName=> [
				$Data->{'LevelNames'}{$Defs::LEVEL_INTREGION}.' Name',
				{
					displaytype=>'text',
					fieldtype=>'text',
					allowsort=>1,
					dbfield => " IF(tblIntRegion.intStatusID = $Defs::NODE_SHOW, tblIntRegion.strName, '') ",
					allowgrouping=>1,
					active=>1,
				  optiongroup => 'affiliations',
					enabled => $currentLevel > $Defs::LEVEL_INTREGION,
				}
			],

    strTeamCustomStr1=> [($CommonVals->{'CustomFields'}->{'strTeamCustomStr1'}[0] !~ /^Custom Team Text/) ? $CommonVals->{'CustomFields'}->{'strTeamCustomStr1'}[0] : '',{displaytype=>'text', fieldtype=>'text', allowsort=>0, optiongroup=>'customfields'}],
    strTeamCustomStr2=> [($CommonVals->{'CustomFields'}->{'strTeamCustomStr2'}[0] !~ /^Custom Team Text/) ? $CommonVals->{'CustomFields'}->{'strTeamCustomStr2'}[0] : '',{displaytype=>'text', fieldtype=>'text', allowsort=>0, optiongroup=>'customfields'}],
    strTeamCustomStr3=> [($CommonVals->{'CustomFields'}->{'strTeamCustomStr3'}[0] !~ /^Custom Team Text/) ? $CommonVals->{'CustomFields'}->{'strTeamCustomStr3'}[0] : '',{displaytype=>'text', fieldtype=>'text', allowsort=>0, optiongroup=>'customfields'}],
    strTeamCustomStr4=> [($CommonVals->{'CustomFields'}->{'strTeamCustomStr4'}[0] !~ /^Custom Team Text/) ? $CommonVals->{'CustomFields'}->{'strTeamCustomStr4'}[0] : '',{displaytype=>'text', fieldtype=>'text', allowsort=>0, optiongroup=>'customfields'}],
    strTeamCustomStr5=> [($CommonVals->{'CustomFields'}->{'strTeamCustomStr5'}[0] !~ /^Custom Team Text/) ? $CommonVals->{'CustomFields'}->{'strTeamCustomStr5'}[0] : '',{displaytype=>'text', fieldtype=>'text', allowsort=>0, optiongroup=>'customfields'}],
    strTeamCustomStr6=> [($CommonVals->{'CustomFields'}->{'strTeamCustomStr6'}[0] !~ /^Custom Team Text/) ? $CommonVals->{'CustomFields'}->{'strTeamCustomStr6'}[0] : '',{displaytype=>'text', fieldtype=>'text', allowsort=>0, optiongroup=>'customfields'}],
    strTeamCustomStr7=> [($CommonVals->{'CustomFields'}->{'strTeamCustomStr7'}[0] !~ /^Custom Team Text/) ? $CommonVals->{'CustomFields'}->{'strTeamCustomStr7'}[0] : '',{displaytype=>'text', fieldtype=>'text', allowsort=>0, optiongroup=>'customfields'}],
    strTeamCustomStr8=> [($CommonVals->{'CustomFields'}->{'strTeamCustomStr8'}[0] !~ /^Custom Team Text/) ? $CommonVals->{'CustomFields'}->{'strTeamCustomStr8'}[0] : '',{displaytype=>'text', fieldtype=>'text', allowsort=>0, optiongroup=>'customfields'}],
    strTeamCustomStr9=> [($CommonVals->{'CustomFields'}->{'strTeamCustomStr9'}[0] !~ /^Custom Team Text/) ? $CommonVals->{'CustomFields'}->{'strTeamCustomStr9'}[0] : '',{displaytype=>'text', fieldtype=>'text', allowsort=>0, optiongroup=>'customfields'}],
    strTeamCustomStr10=> [($CommonVals->{'CustomFields'}->{'strTeamCustomStr10'}[0] !~ /^Custom Team Text/) ? $CommonVals->{'CustomFields'}->{'strTeamCustomStr10'}[0] : '',{displaytype=>'text', fieldtype=>'text', allowsort=>0, optiongroup=>'customfields'}],
    strTeamCustomStr11=> [($CommonVals->{'CustomFields'}->{'strTeamCustomStr11'}[0] !~ /^Custom Team Text/) ? $CommonVals->{'CustomFields'}->{'strTeamCustomStr11'}[0] : '',{displaytype=>'text', fieldtype=>'text', allowsort=>0, optiongroup=>'customfields'}],
    strTeamCustomStr12=> [($CommonVals->{'CustomFields'}->{'strTeamCustomStr12'}[0] !~ /^Custom Team Text/) ? $CommonVals->{'CustomFields'}->{'strTeamCustomStr12'}[0] : '',{displaytype=>'text', fieldtype=>'text', allowsort=>0, optiongroup=>'customfields'}],
    strTeamCustomStr13=> [($CommonVals->{'CustomFields'}->{'strTeamCustomStr13'}[0] !~ /^Custom Team Text/) ? $CommonVals->{'CustomFields'}->{'strTeamCustomStr13'}[0] : '',{displaytype=>'text', fieldtype=>'text', allowsort=>0, optiongroup=>'customfields'}],
    strTeamCustomStr14=> [($CommonVals->{'CustomFields'}->{'strTeamCustomStr14'}[0] !~ /^Custom Team Text/) ? $CommonVals->{'CustomFields'}->{'strTeamCustomStr14'}[0] : '',{displaytype=>'text', fieldtype=>'text', allowsort=>0, optiongroup=>'customfields'}],
    strTeamCustomStr15=> [($CommonVals->{'CustomFields'}->{'strTeamCustomStr15'}[0] !~ /^Custom Team Text/) ? $CommonVals->{'CustomFields'}->{'strTeamCustomStr15'}[0] : '',{displaytype=>'text', fieldtype=>'text', allowsort=>0, optiongroup=>'customfields'}],

    dblTeamCustomDbl1=> [($CommonVals->{'CustomFields'}->{'dblTeamCustomDbl1'}[0] !~ /^Custom Team Number/) ? $CommonVals->{'CustomFields'}->{'dblTeamCustomDbl1'}[0] : '',{displaytype=>'text', fieldtype=>'text', allowsort=>0, optiongroup=>'customfields'}],
    dblTeamCustomDbl2=> [($CommonVals->{'CustomFields'}->{'dblTeamCustomDbl2'}[0] !~ /^Custom Team Number/) ? $CommonVals->{'CustomFields'}->{'dblTeamCustomDbl2'}[0] : '',{displaytype=>'text', fieldtype=>'text', allowsort=>0, optiongroup=>'customfields'}],
    dblTeamCustomDbl3=> [($CommonVals->{'CustomFields'}->{'dblTeamCustomDbl3'}[0] !~ /^Custom Team Number/) ? $CommonVals->{'CustomFields'}->{'dblTeamCustomDbl3'}[0] : '',{displaytype=>'text', fieldtype=>'text', allowsort=>0, optiongroup=>'customfields'}],
    dblTeamCustomDbl4=> [($CommonVals->{'CustomFields'}->{'dblTeamCustomDbl4'}[0] !~ /^Custom Team Number/) ? $CommonVals->{'CustomFields'}->{'dblTeamCustomDbl4'}[0] : '',{displaytype=>'text', fieldtype=>'text', allowsort=>0, optiongroup=>'customfields'}],
    dblTeamCustomDbl5=> [($CommonVals->{'CustomFields'}->{'dblTeamCustomDbl5'}[0] !~ /^Custom Team Number/) ? $CommonVals->{'CustomFields'}->{'dblTeamCustomDbl5'}[0] : '',{displaytype=>'text', fieldtype=>'text', allowsort=>0, optiongroup=>'customfields'}],
    dblTeamCustomDbl6=> [($CommonVals->{'CustomFields'}->{'dblTeamCustomDbl6'}[0] !~ /^Custom Team Number/) ? $CommonVals->{'CustomFields'}->{'dblTeamCustomDbl6'}[0] : '',{displaytype=>'text', fieldtype=>'text', allowsort=>0, optiongroup=>'customfields'}],
    dblTeamCustomDbl7=> [($CommonVals->{'CustomFields'}->{'dblTeamCustomDbl7'}[0] !~ /^Custom Team Number/) ? $CommonVals->{'CustomFields'}->{'dblTeamCustomDbl7'}[0] : '',{displaytype=>'text', fieldtype=>'text', allowsort=>0, optiongroup=>'customfields'}],
    dblTeamCustomDbl8=> [($CommonVals->{'CustomFields'}->{'dblTeamCustomDbl8'}[0] !~ /^Custom Team Number/) ? $CommonVals->{'CustomFields'}->{'dblTeamCustomDbl8'}[0] : '',{displaytype=>'text', fieldtype=>'text', allowsort=>0, optiongroup=>'customfields'}],
    dblTeamCustomDbl9=> [($CommonVals->{'CustomFields'}->{'dblTeamCustomDbl9'}[0] !~ /^Custom Team Number/) ? $CommonVals->{'CustomFields'}->{'dblTeamCustomDbl9'}[0] : '',{displaytype=>'text', fieldtype=>'text', allowsort=>0, optiongroup=>'customfields'}],
    dblTeamCustomDbl10=> [($CommonVals->{'CustomFields'}->{'dblTeamCustomDbl10'}[0] !~ /^Custom Team Number/) ? $CommonVals->{'CustomFields'}->{'dblTeamCustomDbl10'}[0] : '',{displaytype=>'text', fieldtype=>'text', allowsort=>0, optiongroup=>'customfields'}],
    dtTeamCustomDt1=> [($CommonVals->{'CustomFields'}->{'dtTeamCustomDt1'}[0] !~ /^Custom Team Date/) ? $CommonVals->{'CustomFields'}->{'dtTeamCustomDt1'}[0] : '',{displaytype=>'text', fieldtype=>'text', allowsort=>0, optiongroup=>'customfields'}],
    dtTeamCustomDt2=> [($CommonVals->{'CustomFields'}->{'dtTeamCustomDt2'}[0] !~ /^Custom Team Date/) ? $CommonVals->{'CustomFields'}->{'dtTeamCustomDt2'}[0] : '',{displaytype=>'text', fieldtype=>'text', allowsort=>0, optiongroup=>'customfields'}],
    dtTeamCustomDt3=> [($CommonVals->{'CustomFields'}->{'dtTeamCustomDt3'}[0] !~ /^Custom Team Date/) ? $CommonVals->{'CustomFields'}->{'dtTeamCustomDt3'}[0] : '',{displaytype=>'text', fieldtype=>'text', allowsort=>0, optiongroup=>'customfields'}],
    dtTeamCustomDt4=> [($CommonVals->{'CustomFields'}->{'dtTeamCustomDt4'}[0] !~ /^Custom Team Date/) ? $CommonVals->{'CustomFields'}->{'dtTeamCustomDt4'}[0] : '',{displaytype=>'text', fieldtype=>'text', allowsort=>0, optiongroup=>'customfields'}],
    dtTeamCustomDt5=> [($CommonVals->{'CustomFields'}->{'dtTeamCustomDt5'}[0] !~ /^Custom Team Date/) ? $CommonVals->{'CustomFields'}->{'dtTeamCustomDt5'}[0] : '',{displaytype=>'text', fieldtype=>'text', allowsort=>0, optiongroup=>'customfields'}],

    intTeamCustomLU1=> [($CommonVals->{'CustomFields'}->{'intTeamCustomLU1'}[0] !~ /^Custom Team Look/) ? $CommonVals->{'CustomFields'}->{'intTeamCustomLU1'}[0] : '',{displaytype=>'lookup', fieldtype=>'dropdown', dropdownoptions=>$CommonVals->{'DefCodes'}{-71}, optiongroup=>'customfields', size=>3, multiple=>1}],
    intTeamCustomLU2=> [($CommonVals->{'CustomFields'}->{'intTeamCustomLU2'}[0] !~ /^Custom Team Look/) ? $CommonVals->{'CustomFields'}->{'intTeamCustomLU2'}[0] : '',{displaytype=>'lookup', fieldtype=>'dropdown', dropdownoptions=>$CommonVals->{'DefCodes'}{-72}, optiongroup=>'customfields', size=>3, multiple=>1}],
    intTeamCustomLU3=> [($CommonVals->{'CustomFields'}->{'intTeamCustomLU3'}[0] !~ /^Custom Team Look/) ? $CommonVals->{'CustomFields'}->{'intTeamCustomLU3'}[0] : '',{displaytype=>'lookup', fieldtype=>'dropdown', dropdownoptions=>$CommonVals->{'DefCodes'}{-73}, optiongroup=>'customfields', size=>3, multiple=>1}],
    intTeamCustomLU4=> [($CommonVals->{'CustomFields'}->{'intTeamCustomLU4'}[0] !~ /^Custom Team Look/) ? $CommonVals->{'CustomFields'}->{'intTeamCustomLU4'}[0] : '',{displaytype=>'lookup', fieldtype=>'dropdown', dropdownoptions=>$CommonVals->{'DefCodes'}{-74}, optiongroup=>'customfields', size=>3, multiple=>1}],
    intTeamCustomLU5=> [($CommonVals->{'CustomFields'}->{'intTeamCustomLU5'}[0] !~ /^Custom Team Look/) ? $CommonVals->{'CustomFields'}->{'intTeamCustomLU5'}[0] : '',{displaytype=>'lookup', fieldtype=>'dropdown', dropdownoptions=>$CommonVals->{'DefCodes'}{-75}, optiongroup=>'customfields', size=>3, multiple=>1}],
    intTeamCustomLU6=> [($CommonVals->{'CustomFields'}->{'intTeamCustomLU6'}[0] !~ /^Custom Team Look/) ? $CommonVals->{'CustomFields'}->{'intTeamCustomLU6'}[0] : '',{displaytype=>'lookup', fieldtype=>'dropdown', dropdownoptions=>$CommonVals->{'DefCodes'}{-76}, optiongroup=>'customfields', size=>3, multiple=>1}],
    intTeamCustomLU7=> [($CommonVals->{'CustomFields'}->{'intTeamCustomLU7'}[0] !~ /^Custom Team Look/) ? $CommonVals->{'CustomFields'}->{'intTeamCustomLU7'}[0] : '',{displaytype=>'lookup', fieldtype=>'dropdown', dropdownoptions=>$CommonVals->{'DefCodes'}{-77}, optiongroup=>'customfields', size=>3, multiple=>1}],
    intTeamCustomLU8=> [($CommonVals->{'CustomFields'}->{'intTeamCustomLU8'}[0] !~ /^Custom Team Look/) ? $CommonVals->{'CustomFields'}->{'intTeamCustomLU8'}[0] : '',{displaytype=>'lookup', fieldtype=>'dropdown', dropdownoptions=>$CommonVals->{'DefCodes'}{-78}, optiongroup=>'customfields', size=>3, multiple=>1}],
    intTeamCustomLU9=> [($CommonVals->{'CustomFields'}->{'intTeamCustomLU9'}[0] !~ /^Custom Team Look/) ? $CommonVals->{'CustomFields'}->{'intTeamCustomLU9'}[0] : '',{displaytype=>'lookup', fieldtype=>'dropdown', dropdownoptions=>$CommonVals->{'DefCodes'}{-79}, optiongroup=>'customfields', size=>3, multiple=>1}],
    intTeamCustomLU10=> [($CommonVals->{'CustomFields'}->{'intTeamCustomLU10'}[0] !~ /^Custom Team Look/) ? $CommonVals->{'CustomFields'}->{'intTeamCustomLU10'}[0] : '',{displaytype=>'lookup', fieldtype=>'dropdown', dropdownoptions=>$CommonVals->{'DefCodes'}{-80}, optiongroup=>'customfields', size=>3, multiple=>1}],
    intTeamCustomBool1=> [($CommonVals->{'CustomFields'}->{'intTeamCustomBool1'}[0] !~ /^Custom Team Check/) ? $CommonVals->{'CustomFields'}->{'intTeamCustomBool1'}[0] : '',{displaytype=>'text', fieldtype=>'text', allowsort=>0, optiongroup=>'customfields'}],
    intTeamCustomBool2=> [($CommonVals->{'CustomFields'}->{'intTeamCustomBool2'}[0] !~ /^Custom Team Check/) ? $CommonVals->{'CustomFields'}->{'intTeamCustomBool2'}[0] : '',{displaytype=>'text', fieldtype=>'text', allowsort=>0, optiongroup=>'customfields'}],
    intTeamCustomBool3=> [($CommonVals->{'CustomFields'}->{'intTeamCustomBool3'}[0] !~ /^Custom Team Check/) ? $CommonVals->{'CustomFields'}->{'intTeamCustomBool3'}[0] : '',{displaytype=>'text', fieldtype=>'text', allowsort=>0, optiongroup=>'customfields'}],
    intTeamCustomBool4=> [($CommonVals->{'CustomFields'}->{'intTeamCustomBool4'}[0] !~ /^Custom Team Check/) ? $CommonVals->{'CustomFields'}->{'intTeamCustomBool4'}[0] : '',{displaytype=>'text', fieldtype=>'text', allowsort=>0, optiongroup=>'customfields'}],
    intTeamCustomBool5=> [($CommonVals->{'CustomFields'}->{'intTeamCustomBool5'}[0] !~ /^Custom Team Check/) ? $CommonVals->{'CustomFields'}->{'intTeamCustomBool5'}[0] : '',{displaytype=>'text', fieldtype=>'text', allowsort=>0, optiongroup=>'customfields'}],
  #Transactions
      intTransactionID=> [$SystemConfig->{'AllowTXNrpts'} ? 'Transaction ID' : '',{displaytype=>'text', fieldtype=>'text', allowsort => 1, optiongroup => 'transactions'}],
#      intProductID=> [$SystemConfig->{'AllowTXNrpts'} ? 'Product' : '',{displaytype=>'lookup', fieldtype=>'dropdown', dropdownoptions => $CommonVals->{'Products'}{'Options'}, dropdownorder=> $CommonVals->{'Products'}{'Order'}, allowsort=>1, optiongroup => 'transactions'}],
      
   intProductID=> [$SystemConfig->{'AllowTXNrpts'} ? 'Product' : '',{displaytype=>'lookup', fieldtype=>'dropdown', dropdownoptions => $CommonVals->{'Products'}{'Options'},  dropdownorder=>$CommonVals->{'Products'}{'Order'}, allowsort=>1, optiongroup => 'transactions', multiple=>1, size=>6, dbfield=>'TX.intProductID'}],

intProductSeasonID=> ["Product Reporting $txt_SeasonName",{displaytype=>'lookup', fieldtype=>'dropdown', dropdownoptions => $CommonVals->{'Seasons'}{'Options'},  dropdownorder=>$CommonVals->{'Seasons'}{'Order'}, allowsort=>1, optiongroup => 'transactions', active=>0, multiple=>1, size=>3, disable=>$hideSeasons }],


curAmount => [$SystemConfig->{'AllowTXNrpts'} ? 'Line Item Amount':  '',{displaytype=>'currency', fieldtype=>'text', allowsort=>1, optiongroup=>'transactions', total=>1}],
      intQty=> [$SystemConfig->{'AllowTXNrpts'} ? 'Quantity' : '',{displaytype=>'text', fieldtype=>'text', allowsort => 1, optiongroup => 'transactions'}],
      TLstrReceiptRef => [$SystemConfig->{'AllowTXNrpts'} ? 'Manual Receipt Reference' : '',{displaytype=>'text', fieldtype=>'text', optiongroup => 'transactions', dbfield=>'TL.strReceiptRef'}],
      payment_type=> [$SystemConfig->{'AllowTXNrpts'} ? 'Payment Type' : '',{displaytype=>'lookup', fieldtype=>'dropdown', dropdownoptions => \%Defs::paymentTypes, allowsort=>1, optiongroup => 'transactions', dbfield=>'TL.intPaymentType', allowgrouping=>1}],
      strTXN=> [$SystemConfig->{'AllowTXNrpts'} ? 'Bank Reference Number' : '',{displaytype=>'text', fieldtype=>'text', optiongroup => 'transactions', dbfield=>'TL.strTXN'}],
      intLogID=> [$SystemConfig->{'AllowTXNrpts'} ? 'Payment Log ID' : '',{displaytype=>'text', fieldtype=>'text', optiongroup => 'transactions', dbfield=>'TL.intLogID'}],
      intAmount => [$SystemConfig->{'AllowTXNrpts'} ? 'Order Total':  '',{displaytype=>'currency', fieldtype=>'text', allowsort=>1, optiongroup=>'transactions', dbfield=>'TL.intAmount', total=>1}],
      dtTransaction=> [($SystemConfig->{'AllowTXNrpts'} ? 'Transaction Date' : ''),{displaytype=>'date', fieldtype=>'datetime', allowsort=>1, dbformat=>' DATE_FORMAT(TX.dtTransaction,"%d/%m/%Y %H:%i")', optiongroup => 'transactions', dbfield=>'TX.dtTransaction'}],
      dtPaid=> [($SystemConfig->{'AllowTXNrpts'} ? 'Payment Date' : ''),{displaytype=>'date', fieldtype=>'datetime', allowsort=>1, dbformat=>' DATE_FORMAT(TX.dtPaid,"%d/%m/%Y %H:%i")', optiongroup => 'transactions', dbfield=>'TX.dtPaid'}],
      dtSettlement=> [($SystemConfig->{'AllowTXNrpts'} ? 'Settlement Date' : ''),{displaytype=>'date', fieldtype=>'date', allowsort=>1, dbformat=>' DATE_FORMAT(TL.dtSettlement,"%d/%m/%Y")', optiongroup => 'transactions', dbfield=>'TL.dtSettlement', allowgrouping=>1, sortfield=>'TL.dtSettlement'}],
      intTransStatusID=> [$SystemConfig->{'AllowTXNrpts'} ? 'Transaction Status' : '',{displaytype=>'lookup', fieldtype=>'dropdown', dropdownoptions => \%Defs::TransactionStatus , allowsort=>1, optiongroup => 'transactions', dbfield=>'TX.intStatus'}],
      strTransNotes=> [$SystemConfig->{'AllowTXNrpts'} ? 'Transaction Notes' : '',{displaytype=>'text', fieldtype=>'text', optiongroup => 'transactions', dbfield=>'TX.strNotes'}],
     strTLNotes=> [$SystemConfig->{'AllowTXNrpts'} ? 'Payment Record Notes' : '',{displaytype=>'text', fieldtype=>'text', optiongroup => 'transactions', dbfield=>'TL.strComments'}],
      intExportAssocBankFileID=> [$SystemConfig->{'AllowTXNrpts'} ? 'Distribution ID' : '',{displaytype=>'text', fieldtype=>'text', optiongroup => 'transactions', dbfield=>'intExportAssocBankFileID'}],

        strContactTitle=> ['Contact Title',{displaytype=>'text', fieldtype=>'text', allowsort=>1, dbfield => 'tblTeam.strContactTitle', optiongroup => 'contacts'}],
        strContactTitle2=> ['Contact 2 Title',{displaytype=>'text', fieldtype=>'text', allowsort=>1, dbfield => 'tblTeam.strContactTitle2', optiongroup => 'contacts'}],
        strContactTitle3=> ['Contact 3 Title',{displaytype=>'text', fieldtype=>'text', allowsort=>1, dbfield => 'tblTeam.strContactTitle3', optiongroup => 'contacts'}],

        strContactName2=> ['Contact 2 Name',{displaytype=>'text', fieldtype=>'text', allowsort=>1, dbfield => 'tblTeam.strContactName2', optiongroup => 'contacts'}],
        strContactName3=> ['Contact 3 Name',{displaytype=>'text', fieldtype=>'text', allowsort=>1, dbfield => 'tblTeam.strContactName3', optiongroup => 'contacts'}],
        strContactEmail2=> ['Contact 2 Email',{displaytype=>'text', fieldtype=>'text', allowsort=>1, dbfield => 'tblTeam.strContactEmail2', optiongroup => 'contacts'}],
        strContactEmail3=> ['Contact 3 Email',{displaytype=>'text', fieldtype=>'text', allowsort=>1, dbfield => 'tblTeam.strContactEmail3', optiongroup => 'contacts'}],
        strContactPhone2=> ['Contact 2 Phone',{displaytype=>'text', fieldtype=>'text', allowsort=>1, dbfield => 'tblTeam.strContactPhone2', optiongroup => 'contacts'}],
        strContactPhone3=> ['Contact 3 Phone',{displaytype=>'text', fieldtype=>'text', allowsort=>1, dbfield => 'tblTeam.strContactPhone3', optiongroup => 'contacts'}],
        strContactMobile2=> ['Contact 2 Mobile',{displaytype=>'text', fieldtype=>'text', allowsort=>1, dbfield => 'tblTeam.strContactMobile2', optiongroup => 'contacts'}],
        strContactMobile3=> ['Contact 3 Mobile',{displaytype=>'text', fieldtype=>'text', allowsort=>1, dbfield => 'tblTeam.strContactMobile3', optiongroup => 'contacts'}],

		},

		Order => [qw(
			intRecStatus
			strName
			strNickname
			strContactTitle
			strContact
			intTeamCreatedFrom
			dtTeamCreatedOnline
			dtLastUpdate
			strAddress1
			strAddress2
			strSuburb
			strState
			strPostalCode
			strPhone1
			strPhone2
            strMobile
			strEmail
            strUsername
            strPassword
			strNotes
			strContactTitle2
			strContactName2
			strContactEmail2
			strContactPhone2
			strContactMobile2
			strContactTitle3
			strContactName3
			strContactEmail3
			strContactPhone3
			strContactMobile3

			strUniformTopColour
			strUniformBottomColour
			strUniformNumber
			strAltUniformTopColour
			strAltUniformBottomColour
			strAltUniformNumber
			strClubName
			strTitle
			CompintRecStatus
			intNewSeasonID
			intTeamNum
			intCompLevelID
			strAssocName
			intAssocTypeID
			intCompTypeID
			intGradeID
			intCompGender
			intAgeGroupID
			strAgeLevel
			intTeamFinancial
			strZoneName
			strRegionName
			strStateName
			strNationalName
			strIntZoneName
			strIntRegionName
			strTeamCustomStr1
			strTeamCustomStr2
			strTeamCustomStr3
			strTeamCustomStr4
			strTeamCustomStr5
			strTeamCustomStr6
			strTeamCustomStr7
			strTeamCustomStr8
			strTeamCustomStr9
			strTeamCustomStr10
			strTeamCustomStr11
			strTeamCustomStr12
			strTeamCustomStr13
			strTeamCustomStr14
			strTeamCustomStr15

			dblTeamCustomDbl1
			dblTeamCustomDbl2
			dblTeamCustomDbl3
			dblTeamCustomDbl4
			dblTeamCustomDbl5
			dblTeamCustomDbl6
			dblTeamCustomDbl7
			dblTeamCustomDbl8
			dblTeamCustomDbl9
			dblTeamCustomDbl10
			dtTeamCustomDt1
			dtTeamCustomDt2
			dtTeamCustomDt3
			dtTeamCustomDt4
			dtTeamCustomDt5
			intTeamCustomBool1
			intTeamCustomBool2
			intTeamCustomBool3
			intTeamCustomBool4
			intTeamCustomBool5
			intTeamCustomLU1
			intTeamCustomLU2
			intTeamCustomLU3
			intTeamCustomLU4
			intTeamCustomLU5
			intTeamCustomLU6
			intTeamCustomLU7
			intTeamCustomLU8
			intTeamCustomLU9
			intTeamCustomLU10
			intTransactionID
			intProductID
			intProductSeasonID			
			intQty
			curAmount
			dtTransaction
			intTransStatusID
			strTransNotes
			strTLNotes
			intLogID
			payment_type
			TLstrReceiptRef
			strTXN
			intAmount
			dtPaid
			dtSettlement

		)],
		OptionGroups => {
			default => ['Details',{}],
			contacts=> ['Contact People',{}],
			colours => ['Colours',{}],
			affiliations=> ['Affiliations',{}],
			comp => ['Competition',{
				from => $currentLevel == $Defs::LEVEL_COMP 
					? '' 
					:  qq[
					LEFT JOIN tblComp_Teams ON (
						tblTeam.intTeamID=tblComp_Teams.intTeamID 
						AND tblComp_Teams.intRecStatus=$Defs::RECSTATUS_ACTIVE
					) 
					LEFT JOIN tblAssoc_Comp ON (
						tblComp_Teams.intCompID=tblAssoc_Comp.intCompID 
						AND tblAssoc_Comp.intAssocID=tblAssoc.intAssocID 
						AND tblAssoc_Comp.intRecStatus <> $Defs::RECSTATUS_DELETED
					)
				],
			}],
			transactions => [
				'Transactions',
				{ 
					from => "	
						LEFT JOIN tblTransactions AS TX ON (
							NOT (
								TX.intProductID IN ($RealmLPF_Ids) 
								AND TX.intStatus IN (0,-1)) 
								AND tblTeam.intTeamID=TX.intID 
								AND TX.intTableType =2 AND TX.intAssocID = tblTeam.intAssocID
							) 
						LEFT JOIN tblTransLog as TL ON (
							TL.intLogID = TX.intTransLogID
						)",
			}],
			customfields=> ['Custom Fields',{}],
			

		},

		Config => {
			FormFieldPrefix => 'c',
			FormName => 'clubform_',
			EmailExport => 1,
			limitView  => 5000,
			EmailSenderAddress => $Defs::admin_email,
			SecondarySort => 1,
			RunButtonLabel => 'Run Report',
			ReturnProcessData => [qw(tblTeam.strEmail tblTeam.strName)],
		},
	);

        $config{'Fields'} = {
            %{$config{'Fields'}},
            strUsername => [
                'Team Code',
                {
                    displaytype=>'text', 
                    fieldtype=>'text', 
                    allowsort=>1, 
                    dbfield => "CONCAT('2', tblAuth.strUsername)", 
                    dbfrom=>"LEFT JOIN tblAuth ON (tblTeam.intTeamID = tblAuth.intID and tblAuth.intLevel=2)",
                }
            ],
        };
    if ($Data->{'SystemConfig'}{'AssocConfig'}{'ShowPassword'}) {
        $config{'Fields'} = {
            %{$config{'Fields'}},
            strPassword => [
                'Password',
                {
                    displaytype=>'text', 
                    fieldtype=>'text', 
                    allowsort=>1, 
                    dbfrom=>"LEFT JOIN tblAuth ON (tblTeam.intTeamID = tblAuth.intID and tblAuth.intLevel=2)",
                }
            ],
        };
    }
	$self->{'Config'} = \%config;
}

sub SQLBuilder  {
  my($self, $OptVals, $ActiveFields) =@_ ;
  my $currentLevel = $self->{'EntityTypeID'} || 0;
  my $Data = $self->{'Data'};
  my $clientValues = $Data->{'clientValues'};
  my $SystemConfig = $Data->{'SystemConfig'};

  my $from_levels = $OptVals->{'FROM_LEVELS'};
  my $from_list = $OptVals->{'FROM_LIST'};
  my $where_levels = $OptVals->{'WHERE_LEVELS'};
  my $where_list = $OptVals->{'WHERE_LIST'};
  my $current_from = $OptVals->{'CURRENT_FROM'};
  my $current_where = $OptVals->{'CURRENT_WHERE'};
  my $select_levels = $OptVals->{'SELECT_LEVELS'};

  my $sql = '';
  { #Work out SQL

    $where_list=' AND '.$where_list if $where_list and ($where_levels or $current_where);
    $where_list .= qq[ AND (tblAssoc_Comp.intRecStatus IS NULL OR tblAssoc_Comp.intRecStatus IN (0,1))] if ($from_list =~ /tblAssoc_Comp/);

    $sql = qq[
      SELECT ###SELECT###
      FROM $from_levels $current_from $from_list 
      WHERE  $where_levels $current_where $where_list
    ];
    return ($sql,'');
  }
}

1;
