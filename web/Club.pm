#
# $Header: svn://svn/SWM/trunk/web/Club.pm 10510 2014-01-22 02:48:49Z cgao $
#

package Club;
require Exporter;
@ISA = qw(Exporter);
@EXPORT=qw(handleClub loadClubDetails);
@EXPORT_OK=qw(handleClub loadClubDetails);

use strict;
use Reg_common;
use Utils;
use HTMLForm;
use AuditLog;
use CustomFields;
use Assoc qw(loadAssocDetails);
use ConfigOptions qw(ProcessPermissions);
use ClubCharacteristics;
use RecordTypeFilter;
use GridDisplay;

use ServicesContacts;
use Contacts;
use Logo;
use HomeClub;
use FieldCaseRule;
use DefCodes;

sub handleClub	{
	my ($action, $Data, $clubID, $typeID)=@_;

	my $resultHTML='';
	my $clubName=
	my $title='';
	$typeID=$Defs::LEVEL_CLUB if $typeID==$Defs::LEVEL_NONE;
	if ($action =~/^C_DT/) {
		#Club Details
			($resultHTML,$title)=club_details($action, $Data, $clubID, $typeID);
	}
	elsif ($action =~/C_CFG_/) {
		#Club Configuration
	}
	elsif ($action =~/^C_L/) {
		#List Club Children
			($resultHTML,$title)=listClubs($Data, $clubID, $typeID, $action);
	}
	elsif ($action =~/^C_PR/) {
		#List Club Children
			#($resultHTML,$title)=handle_products($Data,$action);
	}
	elsif ($action eq 'C_S') {
		#List Club Stats
	}
	elsif ($action=~/^C_HOME/) {
			($resultHTML,$title)=showClubHome($Data,$clubID);
	}


	return ($resultHTML,$title);
}


sub club_details	{
	my ($action, $Data, $clubID, $typeID)=@_;

	my $option='display';
	$option='edit' if $action eq 'C_DTE' and allowedAction($Data, 'c_e');
	$option='add' if $action eq 'C_DTA' and allowedAction($Data, 'c_a');
    $clubID=0 if $option eq 'add';
	my $field=loadClubDetails($Data->{'db'}, $clubID,$Data->{'clientValues'}{'assocID'}) || ();
  	my $client=setClient($Data->{'clientValues'}) || '';
	my $CustomFieldNames=getCustomFieldNames($Data, $field->{'intAssocTypeID'}) || '';

	my %EntityCategories=();
	{
  	my $aID= $Data->{'clientValues'}{'assocID'} || -1;
    my $subtypeID=$Data->{'RealmSubType'} || $field->{'intAssocTypeID'} || 0;

		my $st = qq[
			SELECT
				intEntityCategoryID,
				strCategoryName
			FROM
				tblEntityCategories
			WHERE
				intRealmID=?
				AND intSubRealmID IN (0,?)
				AND intAssocID IN (0,?)
				AND intEntityType = ?
		];
    my $qry = $Data->{'db'}->prepare($st);
    $qry->execute($Data->{'Realm'}, $subtypeID, $aID, $Defs::LEVEL_CLUB);
    while (my $dref = $qry->fetchrow_hashref())	{
			$EntityCategories{$dref->{'intEntityCategoryID'}} = $dref->{'strCategoryName'};
		}
	}

    my ($DefCodes, $DefCodesOrder) = getDefCodes(
        dbh        => $Data->{'db'}, 
        realmID    => $Data->{'Realm'},
        subRealmID => $Data->{'RealmSubType'} || $field->{'intAssocTypeID'},
        assocID    => $Data->{'clientValues'}{'assocID'},
    );

    my $AssocDetails = loadAssocDetails($Data->{'db'}, $Data->{'clientValues'}{'assocID'});
    my $intAllowSWOL = $AssocDetails->{'intSWOL'};
    
	my %develregions = ();
	if($Data->{'SystemConfig'}{'DevelRegions'})  {
		my @dr=split /\|/,$Data->{'SystemConfig'}{'DevelRegions'};
		if(@dr) {
			for my $i(@dr)  {$develregions{$i}=$i; }
		}
	}
	my %clubzones = ();
	if($Data->{'SystemConfig'}{'ClubZones'})  {
		my @cz=split /\|/,$Data->{'SystemConfig'}{'ClubZones'};
		if(@cz) {
			for my $i(@cz)  {$clubzones{$i}=$i; }
		}
	}

	my $club_chars = getClubCharacteristicsBlock($Data, $clubID) || '';

    my $field_case_rules = get_field_case_rules({dbh=>$Data->{'db'}, client=>$client, type=>'Club'});

	my %FieldDefinitions=(
		fields=>	{
			strName => {
				label =>  'Name',
				value => $field->{strName},
				type  => 'text',
				size  => '40',
				maxsize => '50',
				readonly =>($Data->{'clientValues'}{authLevel} < $Defs::LEVEL_ASSOC and allowedAction($Data, 'm_ne')) ? 1 : 0,
				compulsory => 1,
				sectionname => 'clubdetails',
			},
			intClubCategoryID => {
				label => (keys %EntityCategories) ? "$Data->{'LevelNames'}{$Defs::LEVEL_CLUB} Category" : '',
        value => $field->{intClubCategoryID},
        type  => 'lookup',
        options => \%EntityCategories,
        firstoption => [''," "],
        sectionname => 'clubdetails',
     	}, 
			Username=> {
				label =>  $field->{intClubID} ? 'Username' : '',
				value => "3".$field->{intClubID},
				readonly =>1,
				sectionname => 'clubdetails',
			},
			intRecStatus => {				## ADDED TC 31/10/06
        			label => $Data->{'SystemConfig'}{'AllowStatusChange'} ? 'Active?' : '',
				value => $field->{'intRecStatus'},
				tablename => 'AC',
				type => 'checkbox',
				default => 1,
				displaylookup => {1=>'Yes', 0=>'No'},
				noadd =>1,
				sectionname => 'clubdetails',
			},
			strAbbrev => {
				label => 'Abbreviation',
				posttext => '(Use the common abbreviation for your club eg. MUFC)',
				value => $field->{strAbbrev},
				type  => 'text',
				size  => '10',
				maxsize => '10',
				sectionname => 'clubdetails',
			},
			strContactTitle => {
				label => 'Title of Contact',
				value => $field->{strContactTitle},
				type  => 'text',
				size  => '30',
				maxsize => '50',
				sectionname => 'clubdetails',
			},
			strContact => {
				label => 'Contact Person',
				value => $field->{strContact},
				type  => 'text',
				size  => '30',
				maxsize => '50',
				sectionname => 'clubdetails',
			},
			strAddress1 => {
				label => 'Postal Address Line 1',
				value => $field->{strAddress1},
				type  => 'text',
				size  => '30',
				maxsize => '50',
				sectionname => 'clubdetails',
			},
			strAddress2 => {
				label => 'Postal Address Line 2',
				value => $field->{strAddress2},
				type  => 'text',
				size  => '30',
				maxsize => '50',
				sectionname => 'clubdetails',
			},
			strSuburb => {
				label => 'Suburb',
				value => $field->{strSuburb},
				type  => 'text',
				size  => '30',
				maxsize => '50',
				sectionname => 'clubdetails',
			},
			strState => {
				label => 'State',
				value => $field->{strState},
				type  => 'text',
				size  => '30',
				maxsize => '50',
				sectionname => 'clubdetails',
			},
			strCountry => {
				label => 'Country',
				value => $field->{strCountry},
				type  => 'text',
				size  => '30',
				maxsize => '50',
				sectionname => 'clubdetails',
			},
			strPostalCode => {
				label => 'Postal Code',
				value => $field->{strPostalCode},
				type  => 'text',
				size  => '15',
				maxsize => '15',
				sectionname => 'clubdetails',
			},
			strLGA => {
				label => 'Local Government Area',
				value => $field->{strLGA},
				type => 'text',
				size  => '40',
				maxsize => '150',
				validate => 'NOHTML',
				sectionname => 'clubdetails',
			},
			strDevelRegion => {
				label => $Data->{'SystemConfig'}{'DevelRegions'} ? 'Development Region' : '',
				value => $field->{strDevelRegion},
				type  => 'lookup',
				options => \%develregions,
				firstoption => [''," "],
				sectionname => 'clubdetails',
				readonly =>($Data->{'clientValues'}{authLevel} < $Defs::LEVEL_ASSOC) ? 1 : 0,
			},
			strClubZone => {
				label => $Data->{'SystemConfig'}{'ClubZones'} ? 'Zone' : '',
				value => $field->{strClubZone},
				type  => 'lookup',
				options => \%clubzones,
				firstoption => [''," "],
				sectionname => 'clubdetails',
				readonly =>($Data->{'clientValues'}{authLevel} < $Defs::LEVEL_ASSOC) ? 1 : 0,
			},
			strPhone => {
				label => "$Data->{'LevelNames'}{$Defs::LEVEL_CLUB} Phone",
				value => $field->{strPhone},
				type  => 'text',
				size  => '20',
				maxsize => '20',
				sectionname => 'clubdetails',
			},
			strFax => {
				label => "$Data->{'LevelNames'}{$Defs::LEVEL_CLUB} Fax",
				value => $field->{strFax},
				type  => 'text',
				size  => '20',
				maxsize => '20',
				sectionname => 'clubdetails',
			},
			strEmail => {
				label => "$Data->{'LevelNames'}{$Defs::LEVEL_CLUB} Email",
				value => $field->{strEmail},
				type  => 'text',
				size  => '35',
				maxsize => '200',
        		validate => 'EMAIL',
				sectionname => 'clubdetails',
			},
			SP1	=> {
				type =>'_SPACE_',
			},
			strGroundName => {
				label => 'Home Venue Name',
				value => $field->{strGroundName},
				type  => 'text',
				size  => '30',
				maxsize => '50',
				sectionname => 'clubdetails',
			},
			strGroundAddress => {
				label => 'Home Venue Address',
				value => $field->{strGroundAddress},
				type  => 'text',
				size  => '30',
				maxsize => '50',
				sectionname => 'clubdetails',
			},
			strGroundSuburb => {
				label => 'Home Venue Suburb',
				value => $field->{strGroundSuburb},
				type  => 'text',
				size  => '30',
				maxsize => '50',
				sectionname => 'clubdetails',
			},
			strGroundPostalCode => {
				label => 'Home Venue Post Code',
				value => $field->{strGroundPostalCode},
				type  => 'text',
				size  => '30',
				maxsize => '50',
				sectionname => 'clubdetails',
			},
			strIncNo => {
				label => 'Incorporation Number',
				value => $field->{strIncNo},
				type  => 'text',
				size  => '30',
				maxsize => '50',
				validate => 'NO HTML',
				sectionname => 'clubdetails',
			},
			strBusinessNo => {
				label => 'Business Number (ABN)',
				value => $field->{strBusinessNo},
				type  => 'text',
				size  => '30',
				maxsize => '50',
				validate => 'NO HTML',
				sectionname => 'clubdetails',
			},
			strColours => {
				label => 'Colours',
				value => $field->{strColours},
				type  => 'text',
				size  => '30',
				maxsize => '50',
				validate => 'NO HTML',
				sectionname => 'clubdetails',
			},
			intAgeTypeID => {
        			label => 'Age Type',
                    		value => $field->{intAgeTypeID},
                    		type  => 'lookup',
                    		options => \%Defs::AgeType,
                    		firstoption => [''," "],
				sectionname => 'clubdetails',
            		},
			intClubTypeID => {
        			label => 'Club Type',
                    		value => $field->{intClubTypeID},
                    		type  => 'lookup',
                    		options => \%Defs::ClubType,
                    		firstoption => [''," "],
				sectionname => 'clubdetails',
            		},
			intClubClassification => {
        		label => 'Accreditation Level',
                value => $field->{intClubClassification},
                type  => 'lookup',
                options => { 1 => '1 Star', 2 => '2 Star', 3 => '3 Star', 4 => '4 Star' },
                firstoption => [''," "],
				sectionname => 'clubdetails',
                SkipProcessing => 1,
           	},
            		strClubCustomCheckBox1 => {
                		label => $Data->{'SystemConfig'}{'FieldLabel_strClubCustomCheckBox1'} || '',
                		value => $field->{strClubCustomCheckBox1},
                		type => 'checkbox',
				displaylookup => {1 => 'Yes', 0 => 'No'},
				sectionname => 'clubdetails',
            		},
            		strClubCustomCheckBox2 => {
                		label => $Data->{'SystemConfig'}{'FieldLabel_strClubCustomCheckBox2'} || '',
                		value => $field->{strClubCustomCheckBox2},
                		type => 'checkbox',
				displaylookup => {1 => 'Yes', 0 => 'No'},
				sectionname => 'clubdetails',
            		},
            		strClubCustomText1 => {
                		label => $Data->{'SystemConfig'}{'FieldLabel_strClubCustomText1'} || '',
                		value => $field->{strClubCustomText1},
                		type => 'text',
                		size  => '40',
                		maxsize => '150',
                		validate => 'NOHTML',
				sectionname => 'clubdetails',
            		},
                        strNotes => {
                                label => 'Notes',
                                value => $field->{strNotes},
                                type => 'textarea',
                                rows => '5',
                                cols => '40',
                                     sectionname => 'clubdetails',
                        },
                     intExcludeClubChampionships => {
                                            label => $intAllowSWOL ? 'Exclude from Club Championships' : '',
                                            value => $field->{intExcludeClubChampionships},
                                            type  => 'checkbox',
                                            displaylookup=> {1=> 'Yes', 0 => 'No'},
                                            default => 0,
                                            sectionname => 'clubdetails',
                                        },
                     strContactTitle2 => {
                                label => 'Title of Contact 2',
                                value => $field->{strContactTitle2},
                                type  => 'text',
                                size  => '30',
                                maxsize => '50',
                                sectionname => 'contactdetails',
                        },
                        strContactName2 => {
                                label => 'Contact Person 2',
                                value => $field->{strContactName2},
                                type  => 'text',
                                size  => '30',
                                maxsize => '50',
                                sectionname => 'contactdetails',
                        },
                        strContactEmail2 => {
                                label => 'Contact Email 2',
                                value => $field->{strContactEmail2},
                                type  => 'text',
                                size  => '35',
                                maxsize => '200',
                                validate => 'EMAIL',
                                sectionname => 'contactdetails',
                        },
                        strContactPhone2 => {
                                label => 'Contact Phone 2',
                                value => $field->{strContactPhone2},
                                type  => 'text',
                                size  => '30',
                                maxsize => '50',
                                sectionname => 'contactdetails',
                        },
                        strContactTitle3 => {
                                label => 'Title of Contact 3',
                                value => $field->{strContactTitle3},
                                type  => 'text',
                                size  => '30',
                                maxsize => '50',
                                sectionname => 'contactdetails',
                        },
                        strContactName3 => {
                                label => 'Contact Person 3',
                                value => $field->{strContactName3},
                                type  => 'text',
                                size  => '30',
                                maxsize => '50',
                                sectionname => 'contactdetails',
                        },
                        strContactEmail3 => {
                                label => 'Contact Email 3',
                                value => $field->{strContactEmail3},
                                type  => 'text',
                                size  => '35',
                                maxsize => '200',
                                validate => 'EMAIL',
                                sectionname => 'contactdetails',
                        },
                        strContactPhone3 => {
                                label => 'Contact Phone 3',
                                value => $field->{strContactPhone3},
                                type  => 'text',
                                size  => '30',
                                maxsize => '50',
                                sectionname => 'contactdetails',
			},
                        strClubCustomStr1=> {
                                label => ($CustomFieldNames->{'strClubCustomStr1'}[0] =~ /Custom.*Text Field/) ? '' : $CustomFieldNames->{'strClubCustomStr1'}[0],
                                value => $field->{strClubCustomStr1},
                                type  => 'text',
                                size  => '30',
                                maxsize => '50',
                                sectionname => 'otherdetails',
			},
                        strClubCustomStr2=> {
                                label => ($CustomFieldNames->{'strClubCustomStr2'}[0] =~ /Custom.*Text Field/) ? '' : $CustomFieldNames->{'strClubCustomStr2'}[0],
                                value => $field->{strClubCustomStr2},
                                type  => 'text',
                                size  => '30',
                                maxsize => '50',
                                sectionname => 'otherdetails',
			},
                        strClubCustomStr3=> {
                                label => ($CustomFieldNames->{'strClubCustomStr3'}[0] =~ /Custom.*Text Field/) ? '' : $CustomFieldNames->{'strClubCustomStr3'}[0],
                                value => $field->{strClubCustomStr3},
                                type  => 'text',
                                size  => '30',
                                maxsize => '50',
                                sectionname => 'otherdetails',
			},
                        strClubCustomStr4=> {
                                label => ($CustomFieldNames->{'strClubCustomStr4'}[0] =~ /Custom.*Text Field/) ? '' : $CustomFieldNames->{'strClubCustomStr4'}[0],
                                value => $field->{strClubCustomStr4},
                                type  => 'text',
                                size  => '30',
                                maxsize => '50',
                                sectionname => 'otherdetails',
			},
                        strClubCustomStr5=> {
                                label => ($CustomFieldNames->{'strClubCustomStr5'}[0] =~ /Custom.*Text Field/) ? '' : $CustomFieldNames->{'strClubCustomStr5'}[0],
                                value => $field->{strClubCustomStr5},
                                type  => 'text',
                                size  => '30',
                                maxsize => '50',
                                sectionname => 'otherdetails',
			},
                        strClubCustomStr6=> {
                                label => ($CustomFieldNames->{'strClubCustomStr6'}[0] =~ /Custom.*Text Field/) ? '' : $CustomFieldNames->{'strClubCustomStr6'}[0],
                                value => $field->{strClubCustomStr6},
                                type  => 'text',
                                size  => '30',
                                maxsize => '50',
                                sectionname => 'otherdetails',
			},
                        strClubCustomStr7=> {
                                label => ($CustomFieldNames->{'strClubCustomStr7'}[0] =~ /Custom.*Text Field/) ? '' : $CustomFieldNames->{'strClubCustomStr7'}[0],
                                value => $field->{strClubCustomStr7},
                                type  => 'text',
                                size  => '30',
                                maxsize => '50',
                                sectionname => 'otherdetails',
			},
                        strClubCustomStr8=> {
                                label => ($CustomFieldNames->{'strClubCustomStr8'}[0] =~ /Custom.*Text Field/) ? '' : $CustomFieldNames->{'strClubCustomStr8'}[0],
                                value => $field->{strClubCustomStr8},
                                type  => 'text',
                                size  => '30',
                                maxsize => '50',
                                sectionname => 'otherdetails',
			},
                        strClubCustomStr9=> {
                                label => ($CustomFieldNames->{'strClubCustomStr9'}[0] =~ /Custom.*Text Field/) ? '' : $CustomFieldNames->{'strClubCustomStr9'}[0],
                                value => $field->{strClubCustomStr9},
                                type  => 'text',
                                size  => '30',
                                maxsize => '50',
                                sectionname => 'otherdetails',
			},
                        strClubCustomStr10=> {
                                label => ($CustomFieldNames->{'strClubCustomStr10'}[0] =~ /Custom.*Text Field/) ? '' : $CustomFieldNames->{'strClubCustomStr10'}[0],
                                value => $field->{strClubCustomStr10},
                                type  => 'text',
                                size  => '30',
                                maxsize => '50',
                                sectionname => 'otherdetails',
			},
                        strClubCustomStr11=> {
                                label => ($CustomFieldNames->{'strClubCustomStr11'}[0] =~ /Custom.*Text Field/) ? '' : $CustomFieldNames->{'strClubCustomStr11'}[0],
                                value => $field->{strClubCustomStr11},
                                type  => 'text',
                                size  => '30',
                                maxsize => '50',
                                sectionname => 'otherdetails',
			},
                        strClubCustomStr12=> {
                                label => ($CustomFieldNames->{'strClubCustomStr12'}[0] =~ /Custom.*Text Field/) ? '' : $CustomFieldNames->{'strClubCustomStr12'}[0],
                                value => $field->{strClubCustomStr12},
                                type  => 'text',
                                size  => '30',
                                maxsize => '50',
                                sectionname => 'otherdetails',
			},
                        strClubCustomStr13=> {
                                label => ($CustomFieldNames->{'strClubCustomStr13'}[0] =~ /Custom.*Text Field/) ? '' : $CustomFieldNames->{'strClubCustomStr13'}[0],
                                value => $field->{strClubCustomStr13},
                                type  => 'text',
                                size  => '30',
                                maxsize => '50',
                                sectionname => 'otherdetails',
			},
                        strClubCustomStr14=> {
                                label => ($CustomFieldNames->{'strClubCustomStr14'}[0] =~ /Custom.*Text Field/) ? '' : $CustomFieldNames->{'strClubCustomStr14'}[0],
                                value => $field->{strClubCustomStr14},
                                type  => 'text',
                                size  => '30',
                                maxsize => '50',
                                sectionname => 'otherdetails',
			},
                        strClubCustomStr15=> {
                                label => ($CustomFieldNames->{'strClubCustomStr15'}[0] =~ /Custom.*Text Field/) ? '' : $CustomFieldNames->{'strClubCustomStr15'}[0],
                                value => $field->{strClubCustomStr15},
                                type  => 'text',
                                size  => '30',
                                maxsize => '50',
                                sectionname => 'otherdetails',
			},
			dblClubCustomDbl1 => {
                                label => ($CustomFieldNames->{'dblClubCustomDbl1'}[0] =~ /Custom.*Number Field/) ? '' : $CustomFieldNames->{'dblClubCustomDbl1'}[0],
                                value => $field->{dblClubCustomDbl1},
                                type  => 'text',
                                size  => '10',
                                maxsize => '15',
                                sectionname => 'otherdetails',
                        },
			dblClubCustomDbl2 => {
                                label => ($CustomFieldNames->{'dblClubCustomDbl2'}[0] =~ /Custom.*Number Field/) ? '' : $CustomFieldNames->{'dblClubCustomDbl2'}[0],
                                value => $field->{dblClubCustomDbl2},
                                type  => 'text',
                                size  => '10',
                                maxsize => '15',
                                sectionname => 'otherdetails',
                        },
			dblClubCustomDbl3 => {
                                label => ($CustomFieldNames->{'dblClubCustomDbl3'}[0] =~ /Custom.*Number Field/) ? '' : $CustomFieldNames->{'dblClubCustomDbl3'}[0],
                                value => $field->{dblClubCustomDbl3},
                                type  => 'text',
                                size  => '10',
                                maxsize => '15',
                                sectionname => 'otherdetails',
                        },
			dblClubCustomDbl4 => {
                                label => ($CustomFieldNames->{'dblClubCustomDbl4'}[0] =~ /Custom.*Number Field/) ? '' : $CustomFieldNames->{'dblClubCustomDbl4'}[0],
                                value => $field->{dblClubCustomDbl4},
                                type  => 'text',
                                size  => '10',
                                maxsize => '15',
                                sectionname => 'otherdetails',
                        },
			dblClubCustomDbl5 => {
                                label => ($CustomFieldNames->{'dblClubCustomDbl5'}[0] =~ /Custom.*Number Field/) ? '' : $CustomFieldNames->{'dblClubCustomDbl5'}[0],
                                value => $field->{dblClubCustomDbl5},
                                type  => 'text',
                                size  => '10',
                                maxsize => '15',
                                sectionname => 'otherdetails',
                        },
			dblClubCustomDbl6 => {
                                label => ($CustomFieldNames->{'dblClubCustomDbl6'}[0] =~ /Custom.*Number Field/) ? '' : $CustomFieldNames->{'dblClubCustomDbl6'}[0],
                                value => $field->{dblClubCustomDbl6},
                                type  => 'text',
                                size  => '10',
                                maxsize => '15',
                                sectionname => 'otherdetails',
                        },
			dblClubCustomDbl7 => {
                                label => ($CustomFieldNames->{'dblClubCustomDbl7'}[0] =~ /Custom.*Number Field/) ? '' : $CustomFieldNames->{'dblClubCustomDbl7'}[0],
                                value => $field->{dblClubCustomDbl7},
                                type  => 'text',
                                size  => '10',
                                maxsize => '15',
                                sectionname => 'otherdetails',
                        },
			dblClubCustomDbl8 => {
                                label => ($CustomFieldNames->{'dblClubCustomDbl8'}[0] =~ /Custom.*Number Field/) ? '' : $CustomFieldNames->{'dblClubCustomDbl8'}[0],
                                value => $field->{dblClubCustomDbl8},
                                type  => 'text',
                                size  => '10',
                                maxsize => '15',
                                sectionname => 'otherdetails',
                        },
			dblClubCustomDbl9 => {
                                label => ($CustomFieldNames->{'dblClubCustomDbl9'}[0] =~ /Custom.*Number Field/) ? '' : $CustomFieldNames->{'dblClubCustomDbl9'}[0],
                                value => $field->{dblClubCustomDbl9},
                                type  => 'text',
                                size  => '10',
                                maxsize => '15',
                                sectionname => 'otherdetails',
                        },
			dblClubCustomDbl10 => {
                                label => ($CustomFieldNames->{'dblClubCustomDbl10'}[0] =~ /Custom.*Number Field/) ? '' : $CustomFieldNames->{'dblClubCustomDbl10'}[0],
                                value => $field->{dblClubCustomDbl10},
                                type  => 'text',
                                size  => '10',
                                maxsize => '15',
                                sectionname => 'otherdetails',
                        },
                        dtClubCustomDt1 => {
                                label => ($CustomFieldNames->{'dtClubCustomDt1'}[0] =~ /Custom.*Date Field/) ? '' : $CustomFieldNames->{'dtClubCustomDt1'}[0],
                                value => $field->{dtClubCustomDt1},
                                type  => 'date',
                                format => 'dd/mm/yyyy',
                                sectionname => 'otherdetails',
                                validate => 'DATE',
                        },
                        dtClubCustomDt2 => {
                                label => ($CustomFieldNames->{'dtClubCustomDt2'}[0] =~ /Custom.*Date Field/) ? '' : $CustomFieldNames->{'dtClubCustomDt2'}[0],
                                value => $field->{dtClubCustomDt2},
                                type  => 'date',
                                format => 'dd/mm/yyyy',
                                sectionname => 'otherdetails',
                                validate => 'DATE',
                        },
                        dtClubCustomDt3 => {
                                label => ($CustomFieldNames->{'dtClubCustomDt3'}[0] =~ /Custom.*Date Field/) ? '' : $CustomFieldNames->{'dtClubCustomDt3'}[0],
                                value => $field->{dtClubCustomDt3},
                                type  => 'date',
                                format => 'dd/mm/yyyy',
                                sectionname => 'otherdetails',
                                validate => 'DATE',
                        },
                        dtClubCustomDt4 => {
                                label => ($CustomFieldNames->{'dtClubCustomDt4'}[0] =~ /Custom.*Date Field/) ? '' : $CustomFieldNames->{'dtClubCustomDt4'}[0],
                                value => $field->{dtClubCustomDt4},
                                type  => 'date',
                                format => 'dd/mm/yyyy',
                                sectionname => 'otherdetails',
                                validate => 'DATE',
                        },
                        dtClubCustomDt5 => {
                                label => ($CustomFieldNames->{'dtClubCustomDt5'}[0] =~ /Custom.*Date Field/) ? '' : $CustomFieldNames->{'dtClubCustomDt5'}[0],
                                value => $field->{dtClubCustomDt5},
                                type  => 'date',
                                format => 'dd/mm/yyyy',
                                sectionname => 'otherdetails',
                                validate => 'DATE',
                        },
			intClubCustomLU1 => {
                                label => ($CustomFieldNames->{'intClubCustomLU1'}[0] =~ /Custom.*Lookup/) ? '' : $CustomFieldNames->{'intClubCustomLU1'}[0],
                                value => $field->{intClubCustomLU1},
                                type  => 'lookup',
                                options => $DefCodes->{-81},
                                order => $DefCodesOrder->{-81},
                                firstoption => [''," "],
                                sectionname => 'otherdetails',
                        }, 
			intClubCustomLU2 => {
                                label => ($CustomFieldNames->{'intClubCustomLU2'}[0] =~ /Custom.*Lookup/) ? '' : $CustomFieldNames->{'intClubCustomLU2'}[0],
                                value => $field->{intClubCustomLU2},
                                type  => 'lookup',
                                options => $DefCodes->{-82},
                                order => $DefCodesOrder->{-82},
                                firstoption => [''," "],
                                sectionname => 'otherdetails',
                        }, 
			intClubCustomLU3 => {
                                label => ($CustomFieldNames->{'intClubCustomLU3'}[0] =~ /Custom.*Lookup/) ? '' : $CustomFieldNames->{'intClubCustomLU3'}[0],
                                value => $field->{intClubCustomLU3},
                                type  => 'lookup',
                                options => $DefCodes->{-83},
                                order => $DefCodesOrder->{-83},
                                firstoption => [''," "],
                                sectionname => 'otherdetails',
                        }, 
			intClubCustomLU4 => {
                                label => ($CustomFieldNames->{'intClubCustomLU4'}[0] =~ /Custom.*Lookup/) ? '' : $CustomFieldNames->{'intClubCustomLU4'}[0],
                                value => $field->{intClubCustomLU4},
                                type  => 'lookup',
                                options => $DefCodes->{-84},
                                order => $DefCodesOrder->{-84},
                                firstoption => [''," "],
                                sectionname => 'otherdetails',
                        }, 
			intClubCustomLU5 => {
                                label => ($CustomFieldNames->{'intClubCustomLU5'}[0] =~ /Custom.*Lookup/) ? '' : $CustomFieldNames->{'intClubCustomLU5'}[0],
                                value => $field->{intClubCustomLU5},
                                type  => 'lookup',
                                options => $DefCodes->{-85},
                                order => $DefCodesOrder->{-85},
                                firstoption => [''," "],
                                sectionname => 'otherdetails',
                        }, 
			intClubCustomLU6 => {
                                label => ($CustomFieldNames->{'intClubCustomLU6'}[0] =~ /Custom.*Lookup/) ? '' : $CustomFieldNames->{'intClubCustomLU6'}[0],
                                value => $field->{intClubCustomLU6},
                                type  => 'lookup',
                                options => $DefCodes->{-86},
                                order => $DefCodesOrder->{-86},
                                firstoption => [''," "],
                                sectionname => 'otherdetails',
                        }, 
			intClubCustomLU7 => {
                                label => ($CustomFieldNames->{'intClubCustomLU7'}[0] =~ /Custom.*Lookup/) ? '' : $CustomFieldNames->{'intClubCustomLU7'}[0],
                                value => $field->{intClubCustomLU7},
                                type  => 'lookup',
                                options => $DefCodes->{-87},
                                order => $DefCodesOrder->{-87},
                                firstoption => [''," "],
                                sectionname => 'otherdetails',
                        }, 
			intClubCustomLU8 => {
                                label => ($CustomFieldNames->{'intClubCustomLU8'}[0] =~ /Custom.*Lookup/) ? '' : $CustomFieldNames->{'intClubCustomLU8'}[0],
                                value => $field->{intClubCustomLU8},
                                type  => 'lookup',
                                options => $DefCodes->{-88},
                                order => $DefCodesOrder->{-88},
                                firstoption => [''," "],
                                sectionname => 'otherdetails',
                        }, 
			intClubCustomLU9 => {
                                label => ($CustomFieldNames->{'intClubCustomLU9'}[0] =~ /Custom.*Lookup/) ? '' : $CustomFieldNames->{'intClubCustomLU9'}[0],
                                value => $field->{intClubCustomLU9},
                                type  => 'lookup',
                                options => $DefCodes->{-89},
                                order => $DefCodesOrder->{-89},
                                firstoption => [''," "],
                                sectionname => 'otherdetails',
                        }, 
			intClubCustomLU10 => {
                                label => ($CustomFieldNames->{'intClubCustomLU10'}[0] =~ /Custom.*Lookup/) ? '' : $CustomFieldNames->{'intClubCustomLU10'}[0],
                                value => $field->{intClubCustomLU10},
                                type  => 'lookup',
                                options => $DefCodes->{-90},
                                order => $DefCodesOrder->{-90},
                                firstoption => [''," "],
                                sectionname => 'otherdetails',
                        }, 
			intClubCustomBool1=> {
                                label => ($CustomFieldNames->{'intClubCustomBool1'}[0] =~ /Custom.*(?:True|Checkbox)/) ? '' : $CustomFieldNames->{'intClubCustomBool1'}[0],
                                value => $field->{intClubCustomBool1},
                                type  => 'checkbox',
                                sectionname => 'otherdetails',
                                displaylookup => {1 => 'Yes', 0 => 'No'},
                        }, 
			intClubCustomBool2=> {
                                label => ($CustomFieldNames->{'intClubCustomBool2'}[0] =~ /Custom.*(?:True|Checkbox)/) ? '' : $CustomFieldNames->{'intClubCustomBool2'}[0],
                                value => $field->{intClubCustomBool2},
                                type  => 'checkbox',
                                sectionname => 'otherdetails',
                                displaylookup => {1 => 'Yes', 0 => 'No'},
                        }, 
			intClubCustomBool3=> {
                                label => ($CustomFieldNames->{'intClubCustomBool3'}[0] =~ /Custom.*(?:True|Checkbox)/) ? '' : $CustomFieldNames->{'intClubCustomBool3'}[0],
                                value => $field->{intClubCustomBool3},
                                type  => 'checkbox',
                                sectionname => 'otherdetails',
                                displaylookup => {1 => 'Yes', 0 => 'No'},
                        }, 
			intClubCustomBool4=> {
                                label => ($CustomFieldNames->{'intClubCustomBool4'}[0] =~ /Custom.*(?:True|Checkbox)/) ? '' : $CustomFieldNames->{'intClubCustomBool4'}[0],
                                value => $field->{intClubCustomBool4},
                                type  => 'checkbox',
                                sectionname => 'otherdetails',
                                displaylookup => {1 => 'Yes', 0 => 'No'},
                        }, 
			intClubCustomBool5=> {
                                label => ($CustomFieldNames->{'intClubCustomBool5'}[0] =~ /Custom.*(?:True|Checkbox)/) ? '' : $CustomFieldNames->{'intClubCustomBool5'}[0],
                                value => $field->{intClubCustomBool5},
                                type  => 'checkbox',
                                sectionname => 'otherdetails',
                                displaylookup => {1 => 'Yes', 0 => 'No'},
                        }, 
			SPdetails    => { type =>'_SPACE_', sectionname => 'contactdetails'},
                        SPclub    => { type =>'_SPACE_', sectionname => 'clubdetails'},
                        SPother    => { type =>'_SPACE_', sectionname => 'otherdetails'},
			clubcharacteristics => {
				label => 'Which of the following are appropriate to your club?',
				value => $club_chars,
				type  => 'htmlblock',
				sectionname => 'clubdetails',
				SkipProcessing => 1,
				nodisplay => 1,
			},
},
		order => [qw(Username strName intRecStatus strAbbrev strAddress1 strAddress2 strSuburb strPostalCode strState strCountry strLGA strDevelRegion strClubZone strPhone strFax SP1 strEmail SP1 strIncNo strBusinessNo strColours intClubTypeID intClubClassification intClubCategoryID intAgeTypeID intExcludeClubChampionships strNotes strClubCustomCheckBox1 strClubCustomCheckBox2 strClubCustomStr1 strClubCustomStr2 strClubCustomStr3 strClubCustomStr4 strClubCustomStr5 strClubCustomStr6 strClubCustomStr7 strClubCustomStr8 strClubCustomStr9 strClubCustomStr10 strClubCustomStr11 strClubCustomStr12 strClubCustomStr13 strClubCustomStr14 strClubCustomStr15 dblClubCustomDbl1 dblClubCustomDbl2 dblClubCustomDbl3 dblClubCustomDbl4 dblClubCustomDbl5 dblClubCustomDbl6 dblClubCustomDbl7 dblClubCustomDbl8 dblClubCustomDbl9 dblClubCustomDbl10 dtClubCustomDt1 dtClubCustomDt2 dtClubCustomDt3 dtClubCustomDt4 dtClubCustomDt5 intClubCustomLU1 intClubCustomLU2 intClubCustomLU3 intClubCustomLU4 intClubCustomLU5 intClubCustomLU6 intClubCustomLU7 intClubCustomLU8 intClubCustomLU9 intClubCustomLU10 intClubCustomBool1 intClubCustomBool2 intClubCustomBool3 intClubCustomBool4 intClubCustomBool5 clubcharacteristics)],
        fieldtransform => {
            textcase => {
                strName => $field_case_rules->{'strName'} || '',
            }
        },
		 sections => [
                        ['clubdetails',"Organisational Details"],
                        ['contactdetails','Additional Contacts (online only)'],
                        ['otherdetails','Other Details'],
                ],
		options => {
			labelsuffix => ':',
			hideblank => 1,
			target => $Data->{'target'},
			formname => 'n_form',
      submitlabel => "Update $Data->{'LevelNames'}{$typeID}",
      introtext => 'auto',
			NoHTML => 1,
      updateSQL => qq[
        UPDATE tblClub C
		INNER JOIN tblAssoc_Clubs AS AC ON C.intClubID=AC.intClubID
          SET --VAL--, dtUpdated=NOW()
        WHERE C.intClubID=$clubID
		AND AC.intAssocID=$Data->{'clientValues'}{'assocID'}
        ],
      addSQL => qq[
        INSERT INTO tblClub
          ( --FIELDS-- )
					VALUES ( --VAL-- )
        ],
	  afteraddFunction => \&postClubAdd,
      afteraddParams => [$option,$Data,$Data->{'db'}],
      afterupdateFunction => \&postClubUpdate,
      afterupdateParams => [$option,$Data,$Data->{'db'}, $clubID],
      auditFunction=> \&auditLog,
      auditAddParams => [
        $Data,
        'Add',
        'Club'
      ],
      auditEditParams => [
        $clubID,
        $Data,
        'Update',
        'Club',
      ],
      LocaleMakeText => $Data->{'lang'},
		},
    carryfields =>  {
      client => $client,
      a=> $action,
    },
  );
	if($Data->{'SystemConfig'}{'LGADropDown'})  {
		my @lgas =split /\|/,$Data->{'SystemConfig'}{'LGADropDown'};
		if(@lgas) {
			my %LGAList=();
			for my $i(@lgas)  {$LGAList{$i}=$i; }
			$FieldDefinitions{'fields'}{'strLGA'}{'type'}='lookup';
			$FieldDefinitions{'fields'}{'strLGA'}{'size'}=1;
			$FieldDefinitions{'fields'}{'strLGA'}{'compulsory'}=1;
			$FieldDefinitions{'fields'}{'strLGA'}{'options'}=\%LGAList;
			$FieldDefinitions{'fields'}{'strLGA'}{'firstoption'} = [''," "];
		}
	}

  my $fieldperms=$Data->{'Permissions'};

  my $clubperms=ProcessPermissions(
    $fieldperms,
    \%FieldDefinitions,
    'Club',
  );
	$clubperms->{'clubcharacteristics'} = 1;

  my $resultHTML='';
  ($resultHTML, undef )=handleHTMLForm(\%FieldDefinitions, $clubperms, $option, '',$Data->{'db'});
  my $title=$field->{'strName'} || '';
   my $scMenu = (allowedAction($Data, 'c_e'))
	? getServicesContactsMenu($Data, $Defs::LEVEL_CLUB, $clubID, $Defs::SC_MENU_SHORT, $Defs::SC_MENU_CURRENT_OPTION_DETAILS)
    : '';
  my $logodisplay = '';
  my $editlink = (allowedAction($Data, 'c_e')) ? 1 : 0;
  if($option eq 'display')  {
    $resultHTML .= showContacts($Data,0, $editlink);
    my $chgoptions='';
    $chgoptions.=qq[<span class = "button-small generic-button"><a href="$Data->{'target'}?client=$client&amp;a=C_DTE">Edit $Data->{'LevelNames'}{$Defs::LEVEL_CLUB}</a></span>] if allowedAction($Data, 'c_e');

    $chgoptions=qq[<div class="changeoptions">$chgoptions</div>] if $chgoptions;
    $title=$chgoptions.$title;
    $logodisplay = showLogo(
      $Data,
      $Defs::LEVEL_CLUB,
      $clubID,
      $client,
      $editlink,
    );
	}
	$resultHTML = $scMenu.$logodisplay.$resultHTML;
	$title="Add New $Data->{'LevelNames'}{$typeID}" if $option eq 'add';
	$resultHTML .= loadClubExpiry($Data->{'db'},$clubID) if $Data->{'SystemConfig'}{'DisplayContractExpiry'};

	return ($resultHTML,$title);
}


sub loadClubDetails {
  my($db, $id, $assocID) = @_;
  return {} if !$id;
  my $statement=qq[
    SELECT C.*,AC.intRecStatus, A.intAssocTypeID, ASV.intClubClassification
    intClubClassification
    FROM tblClub AS C
    LEFT JOIN tblAssoc_Clubs AS AC ON AC.intClubID=C.intClubID
	LEFT JOIN tblAssoc as A ON A.intAssocID = $assocID
    LEFT JOIN tblAssocServices as ASV ON ( ASV.intAssocID = $assocID AND ASV.intClubID = C.intClubID )
    WHERE C.intClubID=$id
	AND AC.intAssocID=$assocID
  ];
  my $query = $db->prepare($statement);
  $query->execute;
	my $field=$query->fetchrow_hashref();
  $query->finish;
                                                                                                        
  foreach my $key (keys %{$field})  { if(!defined $field->{$key}) {$field->{$key}='';} }
  return $field;
}

sub postClubAdd {
  my($id,$params,$action,$Data,$db)=@_;
  return undef if !$db;
  if($action eq 'add')  {
    if($id) {
			my $st=qq[
				INSERT INTO tblAssoc_Clubs (intClubID,intAssocID)
				VALUES ($id,$Data->{'clientValues'}{'assocID'})
			];
			$db->do($st);
		}

		my %clubchars = ();
		for my $k (keys %{$params})	{
			if($k =~ /^cc_cb/)	{
				my $id = $k;
				$id =~s/^cc_cb//;
				$clubchars{$id} = 1;
			}
		}
		if(scalar(keys %clubchars))	{
			updateCharacteristics(
				$Data,
				$id,
				\%clubchars,
			);
		}
		{
			my $cl=setClient($Data->{'clientValues'}) || '';
			my %cv=getClient($cl);
			$cv{'clubID'}=$id;
			$cv{'currentLevel'} = $Defs::LEVEL_CLUB;
			my $clm=setClient(\%cv);
			return (0,qq[
				<div class="OKmsg"> $Data->{'LevelNames'}{$Defs::LEVEL_CLUB} Added Successfully</div><br>
				<a href="$Data->{'target'}?client=$clm&amp;a=C_DT">Display Details for $params->{'d_strName'}</a><br><br>
				<b>or</b><br><br>
				<a href="$Data->{'target'}?client=$cl&amp;a=C_DTA&amp;l=$Defs::LEVEL_CLUB">Add another $Data->{'LevelNames'}{$Defs::LEVEL_CLUB}</a>

			]);
		}
	}
}

sub postClubUpdate {
  my($id,$params,$action,$Data,$db, $clubID)=@_;
  return undef if !$db;
  $clubID ||= $id || 0;

	my %clubchars = ();
	for my $k (keys %{$params}) {
		if($k =~ /^cc_cb_/)  {
			my $id = $k;
			$id =~s/^cc_cb_//;
			$clubchars{$id} = 1;
		}

        if ( $k =~ /intClubClassification/ ) {
            my $assocID = $Data->{'clientValues'}->{'assocID'} || 0;
            my $st = qq/UPDATE tblAssocServices SET intClubClassification=? WHERE intClubID=? AND intAssocID=?/;
            my $q = $db->prepare($st);
            $q->execute( $params->{$k}, $clubID, $assocID );
        }
	}
	if(scalar(keys %clubchars)) {
		updateCharacteristics(
			$Data,
			$clubID,
			\%clubchars,
		);
	}

  $Data->{'cache'}->delete('swm',"ClubObj-$clubID") if $Data->{'cache'};

}


sub loadClubExpiry {
	my ($db, $clubID)=@_;
	my $st = qq[
		SELECT A.strName, AC.dtExpiry 
		FROM tblAssoc_Clubs AC
			INNER JOIN tblAssoc AS A ON AC.intAssocID=A.intAssocID
			INNER JOIN tblClub AS C ON AC.intClubID=C.intClubID
		WHERE AC.intClubID=$clubID
	];
	my $q=$db->prepare($st);
	$q->execute();
	my $html='';
	while (my ($strName, $dtExpiry) = $q->fetchrow_array()) {;
		if ($dtExpiry) {
			my ($year,$month,$day) = split /-/,$dtExpiry;
			$html = qq[<b>Contract Expiry Date:</b> $day/$month/$year ($strName)];
		}
	}
	return $html;
}


sub listClubs {

  my($Data, $clubID, $typeID, $action) = @_;

  my $resultHTML = '';
  my $client = $Data->{client};

	my $lang = $Data->{'lang'};

	my $clubRecStatus = !$Data->{'SystemConfig'}{'AllowStatusChange'} 
		? qq[AND tblAssoc_Clubs.intRecStatus = $Defs::RECSTATUS_ACTIVE AND tblClub.intRecStatus = $Defs::RECSTATUS_ACTIVE ] 
		: '';
	$typeID=$Defs::LEVEL_CLUB;
	my $statement=qq[
		SELECT 
			DISTINCT
			tblClub.intClubID, 
			tblClub.strName, 
			tblClub.strContact, 
			tblClub.strPhone, 
			tblClub.strEmail, 
			tblAssoc.strName as strAssocName, 
			tblAssoc_Clubs.intRecStatus as intRecStatus,
			CONCAT(CON.strContactFirstname, ' ', CON.strContactSurname) AS DefContact
		FROM 
			tblClub 
				JOIN tblAssoc_Clubs ON tblClub.intClubID=tblAssoc_Clubs.intClubID
				JOIN tblAssoc ON tblAssoc.intAssocID=tblAssoc_Clubs.intAssocID
			LEFT JOIN tblContacts AS CON ON (
				CON.intClubID = tblClub.intClubID 
				AND CON.intAssocID = tblAssoc.intAssocID
				AND CON.intPrimaryContact = 1
			)
		WHERE tblAssoc_Clubs.intAssocID = ?
			AND tblClub.intRecStatus <> $Defs::RECSTATUS_DELETED
			$clubRecStatus
		ORDER BY strName
	];

	my $query = $Data->{'db'}->prepare($statement);
	$query->execute($Data->{'clientValues'}{'assocID'});

 	my $rectype_options = $Data->{'SystemConfig'}{'AllowStatusChange'} 
		? show_recordtypes($Data, $Defs::LEVEL_CLUB,0, undef, 'Name') 
		: '';

	my $found = 0;
	my %tempClientValues = getClient($client);
	my $currentname='';

	my @rowdata = ();
	while (my $dref= $query->fetchrow_hashref()) {
		$dref->{'DefContact'} ||= $dref->{'strContact'} || '';
		$found++;
		$currentname||=$dref->{strAssocName};
		setClientValue(\%tempClientValues, $typeID, $dref->{intClubID});
		$tempClientValues{currentLevel} = $typeID;
		my $tempClient = setClient(\%tempClientValues);
		my $action=$Data->{'SystemConfig'}{'DefaultListAction'} || 'HOME';
		if($action eq 'SUMM')	{$action='M_L';}
		else	{$action='C_'.$action;}

    push @rowdata, {
      id => $dref->{'intClubID'} || next,
      strName => $dref->{'strName'},
      DefContact => $dref->{'DefContact'},
      strPhone => $dref->{'strPhone'},
      strEmail => $dref->{'strEmail'},
      intRecStatus => $dref->{'intRecStatus'},
      SelectLink => "$Data->{'target'}?client=$tempClient&amp;a=$action",
    };
	}

	my $addlink='';
	my $title="$Data->{'LevelNames'}{$Defs::LEVEL_CLUB.'_P'} ".$lang->txt('in')." $Data->{'LevelNames'}{$Data->{'clientValues'}{'currentLevel'}}"; 

	{
		setClientValue(\%tempClientValues, $typeID, 0);
		$tempClientValues{currentLevel} = $typeID;
		my $tempClient = setClient(\%tempClientValues);

		my $addclub_txt = $lang->txt('Add');
		$addlink=qq[<span class = "button-small generic-button"><a href="$Data->{'target'}?client=$tempClient&amp;a=C_DTA">$addclub_txt</a></span>] if allowedAction($Data, 'c_a');
    $addlink = '' if $Data->{'SystemConfig'}{'LockClub'};
    $addlink = '' if ($Data->{'SystemConfig'}{'LockClubARLD'} and $Data->{'clientValues'}{'authLevel'} <= $Defs::LEVEL_ASSOC);

	}
	my $list_instruction= $Data->{'SystemConfig'}{"ListInstruction_$Defs::LEVEL_CLUB"} 
		? qq[<div class="listinstruction">$Data->{'SystemConfig'}{"ListInstruction_$Defs::LEVEL_CLUB"}</div>] 
		: '';
	my $modoptions=qq[<div class="changeoptions">$addlink </div>]; 
	$title=$modoptions.$title;                                    

  my @headers = (
    {
      type => 'Selector',
      field => 'SelectLink',
    },
    {
      name =>   $Data->{'lang'}->txt('Name'),
      field =>  'strName',
    },
		{
      name =>   $Data->{'lang'}->txt('Contact'),
      field =>  'DefContact',
    },
    {
      name =>   $Data->{'lang'}->txt('Phone'),
      field =>  'strPhone',
      width => 30,
    },
    {
      name =>   $Data->{'lang'}->txt('Email'),
      field =>  'strEmail',
    },
  );

  if($Data->{'SystemConfig'}{'AllowStatusChange'})  {
    push @headers, {
      name =>   $Data->{'lang'}->txt('Active?'),
      field =>  'intRecStatus',
      type => 'tick',
      editor => 'checkbox',
      width => 20,
    };
  }

  my $filterfields = [
    {
      field => 'strName',
      elementID => 'id_textfilterfield',
      type => 'regex',
    },
  ];
	if($rectype_options)	{
		push @{$filterfields}, {
      field => 'intRecStatus',
      elementID => 'dd_actstatus',
      allvalue => '2',
    };
	}

  my $grid  = showGrid(
    Data => $Data,
    columns => \@headers,
    rowdata => \@rowdata,
    filters => $filterfields,
    gridid => 'grid',
    width => '99%',
    height => 700,
    client => $client,
    saveurl => 'ajax/aj_grid_update.cgi',
    ajax_keyfield => 'intClubID',
    saveaction => 'edit_stat_club',
  );

	$resultHTML = qq[
		<div class="grid-filter-wrap">
			<div style="width:99%;">$rectype_options</div>
			$list_instruction
			$grid
		</div>
	];

  return ($resultHTML,$title);

}

1;
