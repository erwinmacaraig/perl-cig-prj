#
# $Header: svn://svn/SWM/trunk/web/ConfigOptions.pm 11586 2014-05-16 04:19:10Z sliu $
#

package ConfigOptions;
require Exporter;
@ISA =  qw(Exporter);
@EXPORT = qw(GetPermissions ProcessPermissions AllowPermissionUpgrade getFieldsList);
@EXPORT_OK = qw(GetPermissions ProcessPermissions AllowPermissionUpgrade getAssocSubType getFieldsList);

use strict;
use Utils;
use DBUtils;
use Log;
use Data::Dumper;

#TypeID
#

sub GetPermissions {
    my ($Data, $EntityTypeID, $EntityID, $RealmID, $SubRealmID, $authLevel, $returnraw) = @_;

    my $db = $Data->{'db'};

    $EntityID ||= 0;
    $EntityTypeID ||= 0;
    $RealmID ||= 0;
    $returnraw ||= 0;
    $authLevel ||= $Data->{'clientValues'}{'authLevel'} || 0;

    my @fields=();
    my %permissions=();

    if($EntityTypeID =~ /[^\d\-]/ or $RealmID =~ /[^\d]/) {
        return \%permissions;
    }
    my $regoform = 0;
    if($authLevel eq 'regoform')	{
        $regoform = 1;
        $authLevel = 0;
    }

    my $fieldname = '';
    my $where = '';

    my $clubID = $Data->{'clientValues'}{'clubID'};
    $clubID = 0 if $clubID < 0;
    if(!$clubID and $EntityTypeID == $Defs::LEVEL_TEAM)	{
        $clubID = getTeamClubID($db,$EntityID) || 0;
    }

    my @structureIDs = ();
    my $levelID = $EntityID;
    my $assocID = $Data->{'clientValues'}{'assocID'} || 0;
    $assocID = 0 if $Data->{'clientValues'}{'assocID'} < 0;
    {
        #Get IDs from tblTempNodeStructure
        if($EntityTypeID == $Defs::LEVEL_NATIONAL)	{
            $fieldname = 'int100_ID';
        }
        elsif($EntityTypeID == $Defs::LEVEL_STATE)	{
            $fieldname = 'int30_ID';
        }
        elsif($EntityTypeID == $Defs::LEVEL_REGION)	{
            $fieldname = 'int20_ID';
        }
        elsif($EntityTypeID == $Defs::LEVEL_ZONE)	{
            $fieldname = 'int10_ID';
        }
        elsif($assocID)	{
            $fieldname = 'intAssocID';
            $levelID = $assocID;
        }
    }

    if($fieldname and $levelID)	{
        my $st = qq[
            SELECT
                int100_ID,
                int30_ID,
                int20_ID,
                int10_ID,
                intAssocID
            FROM
                tblTempNodeStructure AS T
            WHERE
                T.intRealmID = ? AND $fieldname = ?
            LIMIT 1
        ];
        my $q = $db->prepare($st);
        $q->execute($RealmID, $levelID);
        my ($dref) = $q->fetchrow_hashref();
        $q->finish;
        push @structureIDs, [$Defs::LEVEL_NATIONAL, $dref->{'int100_ID'}] if $dref->{'int100_ID'};
        push @structureIDs, [$Defs::LEVEL_STATE, $dref->{'int30_ID'}] if $dref->{'int30_ID'};
        push @structureIDs, [$Defs::LEVEL_REGION, $dref->{'int20_ID'}] if $dref->{'int20_ID'};
        push @structureIDs, [$Defs::LEVEL_ZONE, $dref->{'int10_ID'}] if $dref->{'int10_ID'};
    }

    my $structure_where = '';
    my @vals = ($RealmID, $assocID || 0);
    push @structureIDs, [$Defs::LEVEL_CLUB, $clubID] if $clubID;
    if($EntityTypeID < 0)	{
        push @structureIDs, [$EntityTypeID, $EntityID];
    }
    for my $r (@structureIDs)	{
        $structure_where .= qq{ OR ( intEntityTypeID = $r->[0] AND intEntityID = ?) };
        push @vals, $r->[1];
    }

    my $authRoleID = $Data->{'AuthRoleID'} || 0;
    my $st = qq[
        SELECT 
            intRealmID,
            intSubRealmID,
            intEntityTypeID,
            intEntityID,
            strFieldType,
            strFieldName,
            strPermission,
            intRoleID
        FROM 
            tblFieldPermissions
        WHERE
            intRealmID = ?
            AND ((intEntityTypeID = 0 AND intEntityID = 0) OR ( intEntityTypeID = $Defs::LEVEL_ASSOC AND intEntityID = ?) $structure_where)
            AND intRoleID IN (0,$authRoleID)
        ORDER BY intRoleID DESC
    ];
    my $q = $db->prepare($st);
    $q->execute(@vals);
    my %PermissionsRaw = ();
    my %fields_by_type = ();
    my $hasRoleID = 0;
    while(my $dref = $q->fetchrow_hashref())	{
        next if($dref->{'intSubRealmID'} and $dref->{'intSubRealmID'} != $SubRealmID);
        if($dref->{'intRoleID'})	{
            next if !$Data->{'AuthRoleID'}; #User does not have a role
            if($Data->{'AuthRoleID'} and $dref->{'intRoleID'} != $Data->{'AuthRoleID'} )	{
                next; #Not for my role
            }
            $hasRoleID = 1; #Some valid role records exist
            $PermissionsRaw
            {$dref->{'strFieldType'}."Child"}
            {$dref->{'intEntityTypeID'} || 'REALM'}
            {$dref->{'strFieldName'}}
            = $dref->{'strPermission'};

        }
        if($hasRoleID and !$dref->{'intRoleID'} and $Data->{'AuthRoleID'})	{
            next;
            #If there are some permissions with roleID - ignore the ones that
            #aren't defined by role
        }
        $PermissionsRaw
        {$dref->{'strFieldType'}}
        {$dref->{'intEntityTypeID'} || 'REALM'}
        {$dref->{'strFieldName'}} = $dref->{'strPermission'};
        my $fieldgroup = '';
        if( $dref->{'strFieldType'} eq 'Member' or $dref->{'strFieldType'} eq 'MemberChild')	{
            $fieldgroup = 'Member'; 
        }
        elsif( $dref->{'strFieldType'} eq 'Team' or $dref->{'strFieldType'} eq 'TeamChild')	{
            $fieldgroup = 'Team';
        }
        elsif( $dref->{'strFieldType'} eq 'Club' or $dref->{'strFieldType'} eq 'ClubChild')	{
            $fieldgroup = 'Club' ;
        }
        else {
            $fieldgroup = $dref->{'strFieldType'} || '';
        }

        $fields_by_type{$fieldgroup}{$dref->{'strFieldName'}} = 1;
    }
    return \%PermissionsRaw if $returnraw;

    #Check Permissions
    my @levels_to_check = (
        'REALM',
        $Defs::LEVEL_NATIONAL,
        $Defs::LEVEL_STATE,
        $Defs::LEVEL_REGION,
        $Defs::LEVEL_ZONE,
        $Defs::LEVEL_ASSOC,
    );
    push @levels_to_check, $Defs::LEVEL_CLUB if $clubID;

    my @fieldgroups = (qw(Member Team Club));
    if($regoform)	{
        @fieldgroups = (qw(MemberRegoForm TeamRegoForm));
    }
    for my $fieldgroup (@fieldgroups)	{
        for my $field (keys %{$fields_by_type{$fieldgroup}})	{
            my $above = 1;
            for my $level (@levels_to_check)	{
                my $type = $fieldgroup;
                $above = 0 if $level eq $EntityTypeID;
                $type .= 'Child' if($above and !$regoform);
                my $val_at_level = $PermissionsRaw{$type}{$level}{$field} || '';
                if($val_at_level and ((!$permissions{$fieldgroup}{$field} or $permissions{$fieldgroup}{$field} eq 'ChildDefine') or ($above and	AllowPermissionUpgrade($permissions{$fieldgroup}{$field},$val_at_level))))	{
                    $permissions{$fieldgroup}{$field} = $val_at_level;
                }
            }
        }
    }

    #OK we now have the field permissions sorted,
    #Let's load the other types of permissions

    if($assocID)	{
        my $sql = qq[
            SELECT   
                intEntityID,
                intLevelID,
                strType,
                strPerm,
                strValue,
                intSubTypeID
            FROM tblConfig
            WHERE 
                (intEntityID = ? OR intEntityID= 0)
                AND intLevelID = ?
                AND intRealmID = ?
                AND strType <> ''
            ORDER BY 
                intTypeID ASC, 
                intEntityID DESC, 
                intSubTypeID ASC
        ];
        my $data = query_data($sql, $assocID, $Defs::LEVEL_ASSOC, $RealmID);
        for my $dref (@$data) {
            next if($dref->{'intSubTypeID'} and $dref->{'intSubTypeID'} != $SubRealmID);

            $permissions{$dref->{'strType'}}{$dref->{'strPerm'}}=[$dref->{'strValue'},$dref->{'intLevelID'}, $dref->{'intEntityID'}];
        }
    }
    return \%permissions;
}

sub AllowPermissionUpgrade	{
    my( $oldperm, $newperm,) = @_;

    return 1 if !$oldperm;
    return 0 if !$newperm;
    return 1 if $oldperm eq $newperm;
    my %AllowedUpgrades = (
        ReadOnly => { },	
        Hidden => { },	
        Editable => { 
            Compulsory => 1,
            AddOnlyCompulsory => 1,
        },	
        Compulsory => { 
            AddOnlyCompulsory => 1,
        },	
        AddOnlyCompulsory => { },	
        ChildDefine => { 
            Hidden => 1,
            Editable => 1,
            ReadOnly => 1,
            Compulsory => 1,
            AddOnlyCompulsory => 1,
        },	
    );
    return ($AllowedUpgrades{$oldperm} and $AllowedUpgrades{$oldperm}{$newperm}) ? 1 : 0;
}

sub ProcessPermissions	{
    my( $perms, $Fields, $display_type)=@_;
    my %newperms=();
    $display_type ||= 'Editable';

    for my $f (keys %{$perms->{$display_type}})	{
        if ( $f =~ /^(\w+)\.(\w+)$/ ){ #For groups of dynamic fields
            my $regex = '^' . $1;

            foreach my $field ( grep {/$regex/} keys %{$Fields->{fields}} ){

                my $v = $perms->{$display_type}{$f} || 'Editable';
                if( $v eq 'Hidden' or $v eq 'ChildDefine')   {
                    $newperms{$field}=0;    
                    next;   
                }
                elsif($field =~ '_header_') { 
                    #Hey relax guy, I'm just your average Joe. Take a rest. 
                }
                elsif($v eq 'ReadOnly') { $Fields->{'fields'}{$field}{'readonly'}=1; }
                elsif($v eq 'Compulsory')   { $Fields->{'fields'}{$field}{'compulsory'}=1; }
                elsif($v eq 'AddOnlyCompulsory')    { 
                    $Fields->{'fields'}{$field}{'noedit'}=1; 
                    $Fields->{'fields'}{$field}{'compulsory'}=1; 
                }

                $newperms{$field}=1;
            }
        }
        else{ # For individual fields
            my $v = $perms->{$display_type}{$f} || 'Editable';
            if( $v eq 'Hidden' or $v eq 'ChildDefine')   {
                $newperms{$f}=0;    
                next;   
            }
            elsif($v eq 'ReadOnly') { $Fields->{'fields'}{$f}{'readonly'}=1; }
            elsif($v eq 'Compulsory')   { $Fields->{'fields'}{$f}{'compulsory'}=1; }
            elsif($v eq 'AddOnlyCompulsory')    { 
                $Fields->{'fields'}{$f}{'noedit'}=1; 
                $Fields->{'fields'}{$f}{'compulsory'}=1; 
            }
            $newperms{$f}=1;
        }
    }
    return \%newperms;
}

sub getAssocSubType {
    my($db, $assocID)=@_;

    return 0 unless $assocID =~ /^\d+$/;

    my $query = $db->prepare(qq[
        SELECT intAssocTypeID
        FROM tblAssoc
        WHERE intAssocID = ?
        LIMIT 1
    ]);
    $query->execute($assocID);
    my($subtype)= $query->fetchrow_array();
    $query->finish;
    return $subtype||0;
}

sub getFieldsList	{
    my ($data, $fieldtype) = @_;

    my @memberFields =(qw(
        strNationalNum
        strMemberNo
        intRecStatus
        strSalutation
        strFirstname
        strMiddlename
        strSurname
        strMaidenName
        strMotherCountry
        strFatherCountry
        strPreferredName
        dtDOB
        strPlaceofBirth
        strCountryOfBirth
        intGender
        intDeceased
        strEyeColour
        strHairColour
        intEthnicityID
        strHeight
        strWeight
        strAddress1
        strAddress2
        strSuburb
        strCityOfResidence
        strState
        strCountry
        strPostalCode
        strPhoneHome
        strPhoneWork
        strPhoneMobile
        strPager
        strFax
        strEmail
        strEmail2
        strEmergContName
        strEmergContNo
        strEmergContNo2
        strEmergContRel
        intPlayer
        intCoach
        intUmpire
        intOfficial
        intMisc
        intVolunteer
        intPlayerPending
        strPreferredLang
        strPassportNationality
        strPassportNo
        strPassportIssueCountry
        dtPassportExpiry
        strBirthCertNo
        strHealthCareNo
        intIdentTypeID
        strIdentNum
        dtPoliceCheck
        dtPoliceCheckExp
        strPoliceCheckRef
        intP1Gender
        strP1Salutation
        strP1FName
        strP1SName
        strP1Phone
        strP1Phone2
        strP1PhoneMobile
        strP1Email
        strP1Email2
        intP1AssistAreaID
        intP2Gender
        strP2Salutation
        strP2FName
        strP2SName
        strP2Phone
        strP2Phone2
        strP2PhoneMobile
        strP2Email
        strP2Email2
        intP2AssistAreaID
        intFinancialActive
        intMemberPackageID
        curMemberFinBal
        intLifeMember
        intMedicalConditions
        intAllergies
        intAllowMedicalTreatment
        strMedicalNotes
        intOccupationID
        strLoyaltyNumber
        intMailingList
        strNatCustomStr1
        strNatCustomStr2
        strNatCustomStr3
        strNatCustomStr4
        strNatCustomStr5
        strNatCustomStr6
        strNatCustomStr7
        strNatCustomStr8
        strNatCustomStr9
        strNatCustomStr10
        strNatCustomStr11
        strNatCustomStr12
        strNatCustomStr13
        strNatCustomStr14
        strNatCustomStr15
        dblNatCustomDbl1
        dblNatCustomDbl2
        dblNatCustomDbl3
        dblNatCustomDbl4
        dblNatCustomDbl5
        dblNatCustomDbl6
        dblNatCustomDbl7
        dblNatCustomDbl8
        dblNatCustomDbl9
        dblNatCustomDbl10
        dtNatCustomDt1
        dtNatCustomDt2
        dtNatCustomDt3
        dtNatCustomDt4
        dtNatCustomDt5
        intNatCustomLU1
        intNatCustomLU2
        intNatCustomLU3
        intNatCustomLU4
        intNatCustomLU5
        intNatCustomLU6
        intNatCustomLU7
        intNatCustomLU8
        intNatCustomLU9
        intNatCustomLU10
        intNatCustomBool1
        intNatCustomBool2
        intNatCustomBool3
        intNatCustomBool4
        intNatCustomBool5
        strCustomStr1
        strCustomStr2
        strCustomStr3
        strCustomStr4
        strCustomStr5
        strCustomStr6
        strCustomStr7
        strCustomStr8
        strCustomStr9
        strCustomStr10
        strCustomStr11
        strCustomStr12
        strCustomStr13
        strCustomStr14
        strCustomStr15
        strCustomStr16
        strCustomStr17
        strCustomStr18
        strCustomStr19
        strCustomStr20
        strCustomStr21
        strCustomStr22
        strCustomStr23
        strCustomStr24
        strCustomStr25
        dblCustomDbl1
        dblCustomDbl2
        dblCustomDbl3
        dblCustomDbl4
        dblCustomDbl5
        dblCustomDbl6
        dblCustomDbl7
        dblCustomDbl8
        dblCustomDbl9
        dblCustomDbl10
        dblCustomDbl11
        dblCustomDbl12
        dblCustomDbl13
        dblCustomDbl14
        dblCustomDbl15
        dblCustomDbl16
        dblCustomDbl17
        dblCustomDbl18
        dblCustomDbl19
        dblCustomDbl20
        dtCustomDt1
        dtCustomDt2
        dtCustomDt3
        dtCustomDt4
        dtCustomDt5
        dtCustomDt6
        dtCustomDt7
        dtCustomDt8
        dtCustomDt9
        dtCustomDt10
        dtCustomDt11
        dtCustomDt12
        dtCustomDt13
        dtCustomDt14
        dtCustomDt15
        intCustomLU1
        intCustomLU2
        intCustomLU3
        intCustomLU4
        intCustomLU5
        intCustomLU6
        intCustomLU7
        intCustomLU8
        intCustomLU9
        intCustomLU10
        intCustomLU11
        intCustomLU12
        intCustomLU13
        intCustomLU14
        intCustomLU15
        intCustomLU16
        intCustomLU17
        intCustomLU18
        intCustomLU19
        intCustomLU20
        intCustomLU21
        intCustomLU22
        intCustomLU23
        intCustomLU24
        intCustomLU25
        intCustomBool1
        intCustomBool2
        intCustomBool3
        intCustomBool4
        intCustomBool5
        intCustomBool6
        intCustomBool7
        intFavStateTeamID
        intFavNationalTeamID
        intFavNationalTeamMember
        intAttendSportCount
        intWatchSportHowOftenID
        strNotes
        strMemberCustomNotes1
        strMemberCustomNotes2
        strMemberCustomNotes3
        strMemberCustomNotes4
        strMemberCustomNotes5
        dtFirstRegistered
        dtLastRegistered
        dtLastUpdate
        dtRegisteredUntil
        dtCreatedOnline
        intHowFoundOutID
        intConsentSignatureSighted
        intDefaulter
        PlayerNumberTeam.strJumperNum
        PlayerNumberClub.strJumperNum
        intPhotoUseApproval
        ));
    push @memberFields, ('intSchoolID', 'intGradeID') if $data->{'SystemConfig'}{'Schools'};
    return \@memberFields if $fieldtype eq 'Member';

    my @teamFields =(qw(
        intClubID
        TeamCode
        strName
        ClubName
        intCompID
        intRecStatus
        strNickname
        strCode
        strContactTitle
        strContact
        strAddress1
        strAddress2
        strSuburb
        strState
        strCountry
        strPostalCode
        strPhone1
        strPhone2
        strMobile
        strEmail
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
        strWebURL
        strUniformTopColour
        strUniformBottomColour
        strUniformNumber
        strAltUniformTopColour
        strAltUniformBottomColour
        strAltUniformNumber
        strTeamNotes
        intCoachID
        intManagerID
        intExcludeClubChampionships
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
        intTeamCustomBool1
        intTeamCustomBool2
        intTeamCustomBool3
        intTeamCustomBool4
        intTeamCustomBool5
        intVenue1ID
        intVenue2ID
        intVenue3ID
        dtStartTime1
        dtStartTime2
        dtStartTime3
        ));

    return \@teamFields if $fieldtype eq 'Team';

    my @clubFields = (qw(
        strName
        intRecStatus
        strAbbrev
        strAddress1
        strAddress2
        strSuburb
        strPostalCode
        strState
        strCountry
        strLGA
        strDevelRegion
        strClubZone
        strPhone
        strFax
        strEmail
        strIncNo
        strBusinessNo
        strColours
        intClubTypeID
        intAgeTypeID
        intClubCategoryID
        strNotes
        intClubClassification
        Username
        strClubCustomCheckBox1
        strClubCustomCheckBox2
        strClubCustomStr1
        strClubCustomStr2
        strClubCustomStr3
        strClubCustomStr4
        strClubCustomStr5
        strClubCustomStr6
        strClubCustomStr7
        strClubCustomStr8
        strClubCustomStr9
        strClubCustomStr10
        strClubCustomStr11
        strClubCustomStr12
        strClubCustomStr13
        strClubCustomStr14
        strClubCustomStr15
        dblClubCustomDbl1
        dblClubCustomDbl2
        dblClubCustomDbl3
        dblClubCustomDbl4
        dblClubCustomDbl5
        dblClubCustomDbl6
        dblClubCustomDbl7
        dblClubCustomDbl8
        dblClubCustomDbl9
        dblClubCustomDbl10
        dtClubCustomDt1
        dtClubCustomDt2
        dtClubCustomDt3
        dtClubCustomDt4
        dtClubCustomDt5
        intClubCustomLU1
        intClubCustomLU2
        intClubCustomLU3
        intClubCustomLU4
        intClubCustomLU5
        intClubCustomLU6
        intClubCustomLU7
        intClubCustomLU8
        intClubCustomLU9
        intClubCustomLU10
        intClubCustomBool1
        intClubCustomBool2
        intClubCustomBool3
        intClubCustomBool4
        intClubCustomBool5
        ));

    return \@clubFields if $fieldtype eq 'Club';

    my %readonlyfields =( #These fields can only be Read only or hidden
        dtLastUpdate => 1,
        dtRegisteredUntil=> 1,
        strNationalNum => 1,
        #strMemberNo => 1,
        dtCreatedOnline => 1,
        Username => 1,
        ClubName => 1,
        TeamCode => 1,
    );

    my @hiddenfields	= (qw(
        strSchoolName
        strSchoolSuburb
    ));
}

sub getTeamClubID	{
    my( $db, $teamID,) = @_;
    return 0 if !$db;
    return 0 if !$teamID;
    my $st = qq[
        SELECT intClubID
        FROM tblTeam
        WHERE intTeamID = ?
    ];
    my $q = $db->prepare($st);
    $q->execute($teamID);
    my ($clubID) = $q->fetchrow_array();
    $q->finish();
    return $clubID || 0;

}

1;
# vim: set et sw=4 ts=4:
