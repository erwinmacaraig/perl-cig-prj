#
# $Header: svn://svn/SWM/trunk/web/Assoc.pm 11300 2014-04-14 23:14:41Z dhanslow $
#

package Assoc;
require Exporter;
@ISA = qw(Exporter);
@EXPORT=qw(handleAssoc getAssocTeams loadAssocDetails);
@EXPORT_OK=qw(handleAssoc getAssocTeams loadAssocDetails);

#use lib '/home/tcourt/src/regoSWM/statsprofiles/web/comp/sportstats';
use lib 'sportstats/', ".", "RegoFormBuilder";

use strict;
use Reg_common;
use Utils;
use ListAssocs;
use HTMLForm;
use AssocOptions;
use DefCodes;
use AuditLog;
use CustomFields;
use Welcome;
use MemberPackages;
use AssocServices;
use PaymentSplit;
use Seasons;
use Products;
use CGI qw(param unescape escape);
use TransLog;
use Countries;

use ServicesContacts;
use Contacts;

use HomeAssoc;

use RegoFormOptions;

sub handleAssoc {
    my ($action, $Data, $assocID, $typeID)=@_;
    my $resultHTML  = q{};
    my $title       = q{};
    my $breadcrumbs = q{};

    if ($action =~/^A_DT/) {
        #Assoc Details
         ($resultHTML,$title)=assoc_details($action, $Data, $assocID, $typeID);
    }
    elsif ($action =~/A_CFG_/) {
        #Assoc Configuration
    }
    elsif ($action eq "A_L" || $action eq "A_Lu" || $action eq "A_LE") {
        #List Assoc Children
      ($resultHTML,$title)=listAssocs($Data, $assocID, $typeID, '', 0, $action);
    }
    elsif ($action=~/^A_ORF_/) {
        #Handle Assoc Options
        ($resultHTML, $title, $breadcrumbs) =
            handle_regoform_options($action, $Data, $assocID, $typeID);
    }
    elsif ($action=~/^A_O_/ or $action=~/^A_OSYNC_/) {
        #Handle Assoc Options
        ($resultHTML, $title, $breadcrumbs) =
            handleAssocOptions($action, $Data, $assocID, $typeID);
    }
    elsif ($action=~/^A_LK_/) {
        ($resultHTML,$title)=handle_defcodes($Data,$action);
    }
    elsif ($action=~/^A_CF_/) {
        ($resultHTML,$title)=handle_customfields($Data,$action);
    }
    elsif ($action=~/^A_WEL_/) {
        ($resultHTML,$title)=handle_welcome($Data,$action);
    }
    elsif ($action=~/^A_MP_/) {
        ($resultHTML,$title)=handle_mempackages($Data,$action);
    }
    elsif ($action=~/^A_SV_/) {
        ($resultHTML,$title)=handleAssocServices($action, $Data,$assocID);
    }
    elsif ($action=~/^A_PS_/) {
        ($resultHTML,$title)=handlePaymentSplit($action, $Data, $assocID, $typeID);
    }
    elsif ($action=~/^A_PR_/) {
        ($resultHTML,$title, $breadcrumbs)=handle_products($Data,$action, $assocID, $typeID);
    }
    elsif ($action=~/^A_TXNLOG_LIST/) {
        ($resultHTML,$title)=listTransLog($Data,0, $assocID);
    }
    elsif ($action=~/^A_HOME/) {
        ($resultHTML,$title)=showAssocHome($Data,$assocID);
    }
    return ($resultHTML, $title, $breadcrumbs);
}



sub assoc_details   {
  my ($action, $Data, $assocID, $typeID)=@_;

	my $field=loadAssocDetails($Data->{'db'}, $assocID) || ();
	my $option='display';
	my $intSWOL = $field->{'intSWOL'} ? 1 : 0;
	$option='edit' if $action eq 'A_DTE' and $Data->{'clientValues'}{'authLevel'} >= $Defs::LEVEL_ASSOC;
  my $client=setClient($Data->{'clientValues'}) || '';


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
    $qry->execute($Data->{'Realm'}, $subtypeID, $aID, $Defs::LEVEL_ASSOC);
    while (my $dref = $qry->fetchrow_hashref()) {
      $EntityCategories{$dref->{'intEntityCategoryID'}} = $dref->{'strCategoryName'};
    }
  }


	my (undef, $timezones) = TimeZones();
    my $txt_Clr = $Data->{'SystemConfig'}{'txtCLR'} || 'Clearance';
    my $assocClrStatus = ($field->{'intAllowClearances'} and $Data->{'SystemConfig'}{'AllowClearances'} and $Data->{'SystemConfig'}{'clrStatusAtDestinationAllowSetting'})
        ? qq[Incoming approved $txt_Clr $Data->{'LevelNames'}{$Defs::LEVEL_MEMBER} Status] : '';
				my $countryRO = ($field->{'strCountry'}) ? 1 : 0;
				my @countries=getCountriesArray();
				  my %countriesonly=();
					  for my $c (@countries)  {
						    $countriesonly{$c}=$c;
								  }
									  my $countries=getCountriesHash();
    my %FieldDefinitions=(
        fields=>    {
            strName => {
                label => 'Name',
                value => $field->{strName},
                type  => 'text',
                size  => '40',
                maxsize => '150',
                validate => 'NOHTML',
                readonly =>1,
            },
            intRecStatus => {               ## ADDED TC 31/10/06
                label => ($Data->{'SystemConfig'}{'AllowStatusChange'} ? 'Active?' : ''),
                value => $field->{intRecStatus},
                type => 'checkbox',
                default => 1,
                displaylookup => {1=>'Yes',0=>'No'},
                noadd=>1,
            },
            intAllowClubClrAccess=> {               
                label => ($Data->{'SystemConfig'}{'AllowClubClrAccess'} ? 'Allow Clubs to add/edit clearances' : ''),
                value => $field->{intAllowClubClrAccess},
                type => 'checkbox',
                default => 1,
                displaylookup => {1=>'Yes',0=>'No'},
                noadd=>1,
            },
						intAssocCategoryID => {
        			label => (keys %EntityCategories) ? "$Data->{'LevelNames'}{$Defs::LEVEL_ASSOC} Category" : '',
        			value => $field->{intAssocCategoryID},
        			type  => 'lookup',
							options => \%EntityCategories,
							firstoption => [''," "],
						},
            strAssocNo => {                 ## ADDED TC 08/11/06
                label => 'External ID',
                value => $field->{strAssocNo},
                type => 'text',
                size  => '40',
                maxsize => '150',
                readonly =>1,
            },
            strContact => {
                label => 'Contact Person',
                value => $field->{strContact},
                type  => 'text',
                size  => '30',
                maxsize => '50',
            },
            strManager => {
                label => 'Manager',
                value => $field->{strManager},
                type  => 'text',
                size  => '30',
                maxsize => '50',
            },
            strSecretary => {
                label => 'Secretary',
                value => $field->{strSecretary},
                type  => 'text',
                size  => '30',
                maxsize => '50',
            },
            strPresident => {
                label => 'President',
                value => $field->{strPresident},
                type  => 'text',
                size  => '30',
                maxsize => '50',
            },
            strAddress1 => {
                label => 'Postal Address Line 1',
                value => $field->{strAddress1},
                type  => 'text',
                size  => '30',
                maxsize => '50',
								compulsory => 1,
            },
            strAddress2 => {
                label => 'Postal Address Line 2',
                value => $field->{strAddress2},
                type  => 'text',
                size  => '30',
                maxsize => '50',
            },
            strSuburb => {
                label => 'Postal Suburb',
                value => $field->{strSuburb},
                type  => 'text',
                size  => '30',
                maxsize => '50',
								compulsory => 1,
            },
            strState => {
                label => 'State',
                value => $field->{strState},
                type  => 'text',
                size  => '30',
                maxsize => '50',
								compulsory => 1,
            },
						strCountry=> {
        			label => 'Country',
			        value => $field->{strCountry},
        			type  => 'lookup',
        			options => \%countriesonly,
        			firstoption => ['','Select Country'],
								compulsory => 1,
							class => 'chzn-select',
      			},
            strPostalCode => {
                label => 'Postal Code',
                value => $field->{strPostalCode},
                type  => 'text',
                size  => '15',
                maxsize => '15',
								compulsory => 1,
            },
            strPhone => {
                label => 'League Phone',
                value => $field->{strPhone},
                type  => 'text',
                size  => '20',
                maxsize => '20',
            },
            strFax => {
                label => 'League Fax',
                value => $field->{strFax},
                type  => 'text',
                size  => '20',
                maxsize => '20',
            },
            strEmail => {
                label => 'League Email',
                value => $field->{strEmail},
                type  => 'text',
                size  => '35',
                maxsize => '200',
                validate => 'EMAIL',
            },
            SP1 => {
                type =>'_SPACE_',
            },
                        strGroundName => {
                                label => 'Home Venue Name',
                                value => $field->{strGroundName},
                                type  => 'text',
                                size  => '30',
                                maxsize => '50',
                        },
                        strGroundAddress => {
                                label => 'Home Venue Address',
                                value => $field->{strGroundAddress},
                                type  => 'text',
                                size  => '30',
                                maxsize => '50',
                        },
                        strGroundSuburb => {
                                label => 'Home Venue Suburb',
                                value => $field->{strGroundSuburb},
                                type  => 'text',
                                size  => '30',
                                maxsize => '50',
                        },
                        strGroundPostalCode => {
                                label => 'Home Venue Post Code',
                                value => $field->{strGroundPostalCode},
                                type  => 'text',
                                size  => '30',
                                maxsize => '50',
                        },
            strIncNo => {                   ## ADDED TC 08/11/06
                label => 'Incorporation Number',
                value => $field->{strIncNo},
                type => 'text',
                size  => '40',
                maxsize => '150',
                validate => 'NOHTML',
            },
            strBusinessNo => {              ## ADDED TC 08/11/06
                label => 'Business Number',
                value => $field->{strBusinessNo},
                type => 'text',
                size  => '40',
                maxsize => '150',
                validate => 'NOHTML',
            },
            strColours => {                 ## ADDED TC 14/11/06
                label => 'Colours',
                value => $field->{strColours},
                type => 'text',
                size  => '40',
                maxsize => '150',
                validate => 'NOHTML',
            },
            intDisplayInActiveComps => {
                label => 'Display Inactive Comps in Clash Resolution & Fixture Grid?',
                value => $field->{intDisplayInActiveComps},
                type => 'checkbox',
                default => 1,
                displaylookup => {1=>'Yes',0=>'No'},
            },
            intAssocLevelID => {
                label => 'Level',
                value => $field->{intAssocLevelID},
                type  => 'lookup',
                options => \%Defs::AssocType,
                firstoption => [''," "],
            },
        strAssocCustomCheckBox1 => {
        label => $Data->{'SystemConfig'}{'FieldLabel_strAssocCustomCheckBox1'} || '',
        value => $field->{strAssocCustomCheckBox1},
        type => 'checkbox',
        displaylookup => {1 => 'Yes', 0 => 'No'},
        },
        strAssocCustomCheckBox2 => {
        label => $Data->{'SystemConfig'}{'FieldLabel_strAssocCustomCheckBox2'} || '',
        value => $field->{strAssocCustomCheckBox2},
        type => 'checkbox',
        displaylookup => {1 => 'Yes', 0 => 'No'},
        },
            strLGA => {              
                label => 'Local Government Area',
                value => $field->{strLGA},
                type => 'text',
                size  => '40',
                maxsize => '150',
                validate => 'NOHTML',
            },
            strNotes => {
                label => 'Notes',
                value => $field->{strNotes},
                type => 'textarea',
                rows => '15',
                cols => '40',
            },
                        strSWWUsername=> {
                                label => $intSWOL ? 'Sportingpulse.com Username' : '',
                                value => $field->{strSWWUsername},
                                type  => 'text',
                                size  => '30',
                                maxsize => '50',
				readonly=>'1',
                        },
                        strSWWPassword=> {
                                label => $intSWOL ? 'Sportingpulse.com Password' : '',
                                value => $field->{strSWWPassword},
                                type  => 'text',
                                size  => '30',
                                maxsize => '50',
				readonly=>'1',
                        },
                intAssocClrStatus=> {
                    label => $assocClrStatus,
                    value => $field->{'intAssocClrStatus'},
                    type  => 'lookup',
                    options => \%Defs::assocClrStatus,
                    firstoption => ['','Select Status'],
                },
                strTimeZone => {
                    label => 'Time Zone',
                    value => $field->{'strTimeZone'} || 'Australia/Melbourne',
                    type  => 'lookup',
                    options => $timezones,
										class => 'chzn-select',
                },
		},
		order => [qw(strName intRecStatus strAssocNo strAddress1 strAddress2 strSuburb strPostalCode strState strCountry strPhone strFax SP1 strEmail SP1 strIncNo strBusinessNo strColours intDisplayInActiveComps intAssocLevelID intAssocCategoryID strLGA strNotes strAssocCustomCheckBox1 strAssocCustomCheckBox2 intAllowClubClrAccess strSWWUsername strSWWPassword intAssocClrStatus intCareerStatsConfigID intDefaultCompStatsTemplateID intTeamMatchStatsID intPlayerStatsConfigID strTimeZone)],
		options => {
			labelsuffix => ':',
			hideblank => 1,
			target => $Data->{'target'},
			formname => 'n_form',
			submitlabel => $Data->{'lang'}->txt('Update Information'),
			introtext => $Data->{'lang'}->txt('HTMLFORM_INTROTEXT'),
      updateSQL => qq[
        UPDATE tblAssoc
          SET --VAL--, dtUpdated=NOW()
        WHERE intAssocID=$assocID
      ],
      NoHTML => 1,
      auditFunction=> \&auditLog,
      auditAddParams => [
        $Data,
        'Add',
        'Assoc'
      ],
      auditEditParams => [
        $assocID,
        $Data,
        'Update',
        'Assoc'
      ],
      LocaleMakeText => $Data->{'lang'},

      afterupdateFunction => \&postAssocUpdate,
      afterupdateParams => [$option,$Data,$Data->{'db'}, $assocID],
      afteraddFunction => \&postAssocUpdate,
      afteraddParams => [$option,$Data,$Data->{'db'}],
    },
    carryfields =>  {
      client => $client,
      a=> $action,
    },
    );
    if($Data->{'SystemConfig'}{'SystemForEvent'})   {
        $FieldDefinitions{'fields'}{'strManager'}{'readonly'}=1;
        $FieldDefinitions{'fields'}{'strPresident'}{'readonly'}=1;
        $FieldDefinitions{'fields'}{'strSecretary'}{'readonly'}=1;
    }
		if($Data->{'SystemConfig'}{'LGADropDown'})  {
			my @lgas =split /\|/,$Data->{'SystemConfig'}{'LGADropDown'};
			if(@lgas) {
				my %LGAList=();
				for my $i(@lgas)  {$LGAList{$i}=$i; }
				$FieldDefinitions{'fields'}{'strLGA'}{'type'}='lookup';
				$FieldDefinitions{'fields'}{'strLGA'}{'size'}=1;
				$FieldDefinitions{'fields'}{'strLGA'}{'options'}=\%LGAList;
				$FieldDefinitions{'fields'}{'strLGA'}{'firstoption'} = [''," "];
				$FieldDefinitions{'fields'}{'strLGA'}{'compulsory'} = 1;
			}
		}

    my $resultHTML='';
  ($resultHTML, undef )=handleHTMLForm(\%FieldDefinitions, undef, $option, '',$Data->{'db'});
    my $title=$field->{'strName'} || '';
    my $editlink = (allowedAction($Data, 'a_e')) ? 1 : 0;
  if($option eq 'display')  {
        my $chgoptions='';
    my $txt_edit=$Data->{'lang'}->txt('Edit');
        $chgoptions.=qq[<div class="changeoptions"><span class = "button-small generic-button"><a href="$Data->{'target'}?client=$client&amp;a=A_DTE">$txt_edit</a></span></div> ] if( $Data->{'clientValues'}{'authLevel'} >= $Defs::LEVEL_ASSOC and  allowedAction($Data, 'a_e'));
        $title=$chgoptions.$title;

  }

    return ($resultHTML,$title);
}

sub postAssocUpdate {
  my($id,$params,$action,$Data,$db, $assocID)=@_;
  return undef if !$db;
  $assocID ||= $id || 0;

  $Data->{'cache'}->delete('swm',"AssocObj-$assocID") if $Data->{'cache'};

}

sub loadAssocDetails {
  my($db, $id) = @_;
                                                                                                        
  my $statement=qq[
    SELECT *
    FROM tblAssoc
    WHERE intAssocID=$id
  ];
  my $query = $db->prepare($statement);
  $query->execute;
    my $field=$query->fetchrow_hashref();
  $query->finish;
                                                                                                        
  foreach my $key (keys %{$field})  { if(!defined $field->{$key}) {$field->{$key}='';} }
  return $field;
}

sub loadAssocOfficials {
  my($db, $id) = @_;
  my $resultHTML='';

  my $statement = qq[
    SELECT MT.intMemberID, M.strFirstname, M.strSurname, D.strName 
    FROM tblMember_Types AS MT 
        LEFT JOIN tblMember AS M ON MT.intMemberID=M.intMemberID 
        LEFT JOIN tblDefCodes AS D ON MT.intInt2=D.intCodeID 
    WHERE MT.intTypeID=4 
        AND MT.intActive=1 
        AND MT.intAssocID=$id;
  ];
  my $query = $db->prepare($statement);
  $query->execute;

  while (my ($intMemberID, $strFirstname, $strSurname, $strPosition)=$query->fetchrow_array()) {
    $resultHTML.=qq[$strFirstname $strSurname ($strPosition) <br>];
  }

  $resultHTML = qq[<div class="sectionheader">Officials</div>].$resultHTML if ($resultHTML);

  return $resultHTML;
}

sub loadAssocExpiry {
    my ($db, $assocID)=@_;
    my $st = qq[
        SELECT dtExpiry
        FROM tblAssoc
        WHERE intAssocID=$assocID
    ];
    my $q=$db->prepare($st);
    $q->execute();
    my $html='';
    my ($dtExpiry) = $q->fetchrow_array();
        if ($dtExpiry) {
            my ($year,$month,$day) = split /-/,$dtExpiry;
            $html = qq[<b>Contract Expiry Date:</b> $day/$month/$year];
        }
    return $html;
}


sub getAssocTeams {
    my($Data,$assocID, $compID,$selected,$selectedClub, $hideInactive) = @_;
        
    my @Teams = ();
    my $dbh = $Data->{db};
	$hideInactive ||= 0;
 
    #my $selected = 'unassigned'; 
    
    my $season_query = "SELECT intNewSeasonID FROM tblAssoc_Comp WHERE intCompID = $compID";
    my $sth = $dbh->prepare($season_query);
    $sth->execute();
    my @row = $sth->fetchrow_array();
    my $seasonID = $row[0];
	my $inactive_WHERE = $hideInactive ? qq[ AND tblTeam.intRecStatus=1 ] : '';
        
     my $query = qq[
                   SELECT tblTeam.*, IF(tblTeam.intRecStatus=1, tblTeam.strName, CONCAT(tblTeam.strName , " (Inactive)")) as strName
                   FROM tblTeam
                   WHERE tblTeam.intAssocID = $assocID
                   AND tblTeam.intRecStatus != $Defs::RECSTATUS_DELETED
				   $inactive_WHERE
                  ];
 
    #INNER JOIN tblClub ON (tblClub.intClubID  = tblTeam.intClubID)

    if ($selectedClub =~/^\d+$/) {
        $query .= qq[ AND tblTeam.intClubID = $selectedClub ];
    }
    elsif ($selectedClub eq 'noclub') {
        $query .= qq[ AND tblTeam.intClubID < 1 ];
    }
    
    if ($selected eq 'unassigned' ) {
        $query .= qq[
                     AND tblTeam.intTeamID NOT IN
                     (
                      SELECT intTeamID FROM tblComp_Teams
                      INNER JOIN tblAssoc_Comp ON (tblAssoc_Comp.intCompID = tblComp_Teams.intCompID)
                      WHERE intAssocID = $assocID
                      AND intNewSeasonID = $seasonID
                      AND tblComp_Teams.intRecStatus = $Defs::RECSTATUS_ACTIVE
                     )
                 ];
    }
    
    $query .= qq[ ORDER BY tblTeam.strName]; 
    
    $sth = $dbh->prepare($query);
    $sth->execute();
     
    while (my $dref = $sth->fetchrow_hashref()) {
        my %team = ();
        foreach my $field( keys %{$dref}) {
            $team{$field} = $dref->{$field};
        }
        push (@Teams, \%team);
    }
    
    return \@Teams;
}

sub TimeZones	{

my @tz=qw(
Africa/Abidjan
Africa/Accra
Africa/Addis_Ababa
Africa/Algiers
Africa/Asmera
Africa/Bamako
Africa/Bangui
Africa/Banjul
Africa/Bissau
Africa/Blantyre
Africa/Brazzaville
Africa/Bujumbura
Africa/Cairo
Africa/Casablanca
Africa/Ceuta
Africa/Conakry
Africa/Dakar
Africa/Dar_es_Salaam
Africa/Djibouti
Africa/Douala
Africa/El_Aaiun
Africa/Freetown
Africa/Gaborone
Africa/Harare
Africa/Johannesburg
Africa/Kampala
Africa/Khartoum
Africa/Kigali
Africa/Kinshasa
Africa/Lagos
Africa/Libreville
Africa/Lome
Africa/Luanda
Africa/Lubumbashi
Africa/Lusaka
Africa/Malabo
Africa/Maputo
Africa/Maseru
Africa/Mbabane
Africa/Mogadishu
Africa/Monrovia
Africa/Nairobi
Africa/Ndjamena
Africa/Niamey
Africa/Nouakchott
Africa/Ouagadougou
Africa/Porto_Novo
Africa/Sao_Tome
Africa/Timbuktu
Africa/Tripoli
Africa/Tunis
Africa/Windhoek
America/Adak
America/Anchorage
America/Anguilla
America/Antigua
America/Araguaina
America/Aruba
America/Asuncion
America/Bahia
America/Barbados
America/Belem
America/Belize
America/Boa_Vista
America/Bogota
America/Boise
America/Buenos_Aires
America/Cambridge_Bay
America/Campo_Grande
America/Cancun
America/Caracas
America/Catamarca
America/Cayenne
America/Cayman
America/Chicago
America/Chihuahua
America/Cordoba
America/Costa_Rica
America/Cuiaba
America/Curacao
America/Danmarkshavn
America/Dawson
America/Dawson_Creek
America/Denver
America/Detroit
America/Dominica
America/Edmonton
America/Eirunepe
America/El_Salvador
America/Fortaleza
America/Glace_Bay
America/Godthab
America/Goose_Bay
America/Grand_Turk
America/Grenada
America/Guadeloupe
America/Guatemala
America/Guayaquil
America/Guyana
America/Halifax
America/Havana
America/Hermosillo
America/Indiana
America/Indiana/Knox
America/Indiana/Marengo
America/Indiana/Vevay
America/Indianapolis
America/Inuvik
America/Iqaluit
America/Jamaica
America/Jujuy
America/Juneau
America/Kentucky
America/Kentucky/Monticello
America/La_Paz
America/Lima
America/Los_Angeles
America/Louisville
America/Maceio
America/Managua
America/Manaus
America/Martinique
America/Mazatlan
America/Mendoza
America/Menominee
America/Merida
America/Mexico_City
America/Miquelon
America/Monterrey
America/Montevideo
America/Montreal
America/Montserrat
America/Nassau
America/New_York
America/Nipigon
America/Nome
America/Noronha
America/North_Dakota
America/North_Dakota/Center
America/Panama
America/Pangnirtung
America/Paramaribo
America/Phoenix
America/Port_au_Prince
America/Port_of_Spain
America/Porto_Velho
America/Puerto_Rico
America/Rainy_River
America/Rankin_Inlet
America/Recife
America/Regina
America/Rio_Branco
America/Santiago
America/Santo_Domingo
America/Sao_Paulo
America/Scoresbysund
America/St_Johns
America/St_Kitts
America/St_Lucia
America/St_Thomas
America/St_Vincent
America/Swift_Current
America/Tegucigalpa
America/Thule
America/Thunder_Bay
America/Tijuana
America/Toronto
America/Tortola
America/Vancouver
America/Whitehorse
America/Winnipeg
America/Yakutat
America/Yellowknife
Antarctica/Casey
Antarctica/Davis
Antarctica/DumontDUrville
Antarctica/Mawson
Antarctica/McMurdo
Antarctica/Palmer
Antarctica/Rothera
Antarctica/Syowa
Antarctica/Vostok
Asia/Aden
Asia/Almaty
Asia/Amman
Asia/Anadyr
Asia/Aqtau
Asia/Aqtobe
Asia/Ashgabat
Asia/Baghdad
Asia/Bahrain
Asia/Baku
Asia/Bangkok
Asia/Beirut
Asia/Bishkek
Asia/Brunei
Asia/Calcutta
Asia/Choibalsan
Asia/Chongqing
Asia/Colombo
Asia/Damascus
Asia/Dhaka
Asia/Dili
Asia/Dubai
Asia/Dushanbe
Asia/Gaza
Asia/Harbin
Asia/Hong_Kong
Asia/Hovd
Asia/Irkutsk
Asia/Jakarta
Asia/Jayapura
Asia/Jerusalem
Asia/Kabul
Asia/Kamchatka
Asia/Karachi
Asia/Kashgar
Asia/Katmandu
Asia/Krasnoyarsk
Asia/Kuala_Lumpur
Asia/Kuching
Asia/Kuwait
Asia/Macau
Asia/Magadan
Asia/Makassar
Asia/Manila
Asia/Muscat
Asia/Nicosia
Asia/Novosibirsk
Asia/Omsk
Asia/Oral
Asia/Phnom_Penh
Asia/Pontianak
Asia/Pyongyang
Asia/Qatar
Asia/Qyzylorda
Asia/Rangoon
Asia/Riyadh
Asia/Saigon
Asia/Sakhalin
Asia/Samarkand
Asia/Seoul
Asia/Shanghai
Asia/Singapore
Asia/Taipei
Asia/Tashkent
Asia/Tbilisi
Asia/Tehran
Asia/Thimphu
Asia/Tokyo
Asia/Ulaanbaatar
Asia/Urumqi
Asia/Vientiane
Asia/Vladivostok
Asia/Yakutsk
Asia/Yekaterinburg
Asia/Yerevan
Atlantic/Azores
Atlantic/Bermuda
Atlantic/Canary
Atlantic/Cape_Verde
Atlantic/Faeroe
Atlantic/Madeira
Atlantic/Reykjavik
Atlantic/South_Georgia
Atlantic/St_Helena
Atlantic/Stanley
Australia/Adelaide
Australia/Brisbane
Australia/Broken_Hill
Australia/Darwin
Australia/Hobart
Australia/Lindeman
Australia/Lord_Howe
Australia/Melbourne
Australia/Perth
Australia/Sydney
Europe/Amsterdam
Europe/Andorra
Europe/Athens
Europe/Belfast
Europe/Belgrade
Europe/Berlin
Europe/Brussels
Europe/Bucharest
Europe/Budapest
Europe/Chisinau
Europe/Copenhagen
Europe/Dublin
Europe/Gibraltar
Europe/Helsinki
Europe/Istanbul
Europe/Kaliningrad
Europe/Kiev
Europe/Lisbon
Europe/London
Europe/Luxembourg
Europe/Madrid
Europe/Malta
Europe/Minsk
Europe/Monaco
Europe/Moscow
Europe/Oslo
Europe/Paris
Europe/Prague
Europe/Riga
Europe/Rome
Europe/Samara
Europe/Simferopol
Europe/Sofia
Europe/Stockholm
Europe/Tallinn
Europe/Tirane
Europe/Uzhgorod
Europe/Vaduz
Europe/Vienna
Europe/Vilnius
Europe/Warsaw
Europe/Zaporozhye
Europe/Zurich
Indian/Antananarivo
Indian/Chagos
Indian/Christmas
Indian/Cocos
Indian/Comoro
Indian/Kerguelen
Indian/Mahe
Indian/Maldives
Indian/Mauritius
Indian/Mayotte
Indian/Reunion
Pacific/Apia
Pacific/Auckland
Pacific/Chatham
Pacific/Easter
Pacific/Efate
Pacific/Enderbury
Pacific/Fakaofo
Pacific/Fiji
Pacific/Funafuti
Pacific/Galapagos
Pacific/Gambier
Pacific/Guadalcanal
Pacific/Guam
Pacific/Honolulu
Pacific/Johnston
Pacific/Kiritimati
Pacific/Kosrae
Pacific/Kwajalein
Pacific/Majuro
Pacific/Marquesas
Pacific/Midway
Pacific/Nauru
Pacific/Niue
Pacific/Norfolk
Pacific/Noumea
Pacific/Pago_Pago
Pacific/Palau
Pacific/Pitcairn
Pacific/Ponape
Pacific/Port_Moresby
Pacific/Rarotonga
Pacific/Saipan
Pacific/Tahiti
Pacific/Tarawa
Pacific/Tongatapu
Pacific/Truk
Pacific/Wake
Pacific/Wallis
Pacific/Yap
	);
	my %tz = ();
	for my $t (@tz)	{
		$tz{$t} = $t;
	}
	return (\@tz, \%tz);
}

1;

