package PersonRegisterWhat;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = @EXPORT_OK = qw(
	displayPersonRegisterWhat
    optionsPersonRegisterWhat
);

use lib '.', '..', "comp", 'RegoForm', "dashboard", "RegoFormBuilder",'PaymentSplit', "user";
use strict;
use Utils;
use Reg_common;
use TTTemplate;
use Log;
use EntityTypeRoles;
use Person;
use Entity;
use RegoAgeRestrictions;
use PersonRegistration;
use SystemConfig;
use RegistrationWindow;
use CGI qw(param);

use Data::Dumper;

sub displayPersonRegisterWhat   {
    my(
        $Data,
        $personID,
        $entityID,
        $dob,
        $gender,
        $originLevel,
        $continueURL,
        $bulk,
        $regoID,
        $entitySelection,
    ) = @_;
    #$transfer ||=0;
    $bulk ||= 0;
    $entitySelection ||= 0;

    my $defaultType = param('dtype') || '';
    my $defaultSport = param('dsport') || '';
    my $defaultEntityRole= param('dentityrole') || '';
    my $defaultNature= param('dnat') || '';
    my $defaultLevel= param('dlevel') || '';
    my $itc = param('itc') || '';
    my $preqtype = param('preqtype') || '';

    my $systemConfig = getSystemConfig($Data);

    my %templateData = (
        originLevel => $originLevel || 0,
        personID => $personID || 0,
        entityID => $entityID || 0,
        dob => $dob || '',
        gender => $gender || 0,
        client => $Data->{'client'} || '',
        realmID => $Data->{'Realm'} || 0,
        realmSubTypeID => $Data->{'RealmSubType'} || 0,
        continueURL => $continueURL || '',
        dtype=> $defaultType,
        dsport=> $defaultSport,
        dlevel=> $defaultLevel,
        dnat=>$defaultNature,
        dentityrole=> $defaultEntityRole,
        existingReg => $regoID || 0,
        SystemConfig => $systemConfig,
        EntitySelection => $entitySelection || 0,
        DefaultEntity => getLastEntityID($Data->{'clientValues'}) || 0,
        ClientID => getLastEntityID($Data->{'clientValues'}) || 0,
        ClientLevel => getLastEntityLevel($Data->{'clientValues'}) || 0,
        AllowMAComment => $systemConfig->{'personRegoAllowMAComment'},
        itc => $itc,
        preqtype => $preqtype,
    );
    if($entitySelection)    {
        $templateData{'entityID'} = 0;
    }
            #$templateData{'transfer'} = 0;
    if($regoID) {
		
		
        my $ref = getRegistrationDetail($Data, $regoID) || {};
        my $existing = {};
        if($ref and $ref->[0])    {
            $existing = $ref->[0];
        }
        my $role_ref = getEntityTypeRoles($Data, $existing->{'strSport'}, $existing->{'strPersonType'}, $defaultEntityRole);

        my %existingRego = (
            etype => $existing->{'intEntityLevel'} || '',
            etypeName => $Data->{'lang'}->txt($Data->{'LevelNames'}{$existing->{'intEntityLevel'}} || $Defs::LevelNames{$existing->{'intEntityLevel'}}) || '',
            entity => $existing->{'intEntityID'} || '',
            entityName => $existing->{'strLocalName'} || '',
            type => $existing->{'strPersonType'} || '',
            typeName => $Data->{'lang'}->txt($existing->{'PersonType'} || ''),
            sport => $existing->{'strSport'} || '',
            sportName => $Data->{'lang'}->txt($existing->{'Sport'}) || '',
            role => $existing->{'strPersonEntityRole'} || '',
            roleName => $Data->{'lang'}->txt($role_ref->{$existing->{'strPersonEntityRole'}} || ''),
            level => $existing->{'strPersonLevel'} || '',
            levelName => $Data->{'lang'}->txt($existing->{'PersonLevel'} || ''),
            age => $existing->{'strAgeLevel'} || '',
            ageName => $Data->{'lang'}->txt($existing->{'AgeLevel'} || ''),
            nature => $existing->{'strRegistrationNature'} || '',
            natureName => $Data->{'lang'}->txt($existing->{'RegistrationNature'} || ''),
            MAComment => $existing->{'strShortNotes'} || '',
            dnat=>$defaultNature,
        );
        $templateData{'existing'} = \%existingRego;
    }
    else    {
        if ($defaultNature eq 'TRANSFER')  {
            $templateData{'nat'} = 'TRANSFER';
            $templateData{'dsport'} = $defaultSport;
        }
    }

    my $template = "registration/what.templ";
    $template = "registration/whatbulk.templ" if $bulk;
    my $body = runTemplate(
        $Data, 
        \%templateData, 
        $template
    );
    return $body || '';
}



sub optionsPersonRegisterWhat {
    my (
        $Data,
        $realmID,
        $subRealmID,
        $originLevel,
        $registrationNature,
        $personType,
        $defaultType,
        $personEntityRole,
        $defaultEntityRole,
        $personLevel,
        $defaultLevel,
        $sport,
        $defaultSport,
        $ageLevel,
        $personID,
        $entityID,
        $dob,
        $gender,
        $lookingFor,
        $bulk,
        $etype,
        $currentLevel,
        $currentEntityID,
        $itc,
        $preqtype,
    ) = @_;
    $bulk ||= 0;

    my $pref= undef;
    $pref = loadPersonDetails($Data->{'db'}, $personID) if ($personID);

    #$registrationNature ||= '';
    #$registrationNature = '' if (! defined $registrationNature or $registrationNature eq 'null');
    #$registrationNature='TRANSFER' if ($transfer==1);
	my $bulkWHERE= qq[ AND strWFRuleFor='REGO'];
    $bulkWHERE = qq[ AND strWFRuleFor='BULKREGO'] if ($bulk);
    my $role_ref = getEntityTypeRoles($Data, $sport, $personType, $defaultEntityRole);
    my %lfTable = (
        type => 'strPersonType',
        nature => 'strRegistrationNature',
        level => 'strPersonLevel',
        age => 'strAgeLevel',
        sport => 'strSport',
        role => 'strPersonEntityRole',
        etype => 'entityType',
        eId => 'entityId',
    );
	
    #my %genderList = (
    #    0 => 'ALL',
    #    1 => %Defs->{$Defs::GENDER_MALE},
    #    2 => $Defs->{$Defs::GENDER_FEMALE},
    #);
    my %lfLabelTable = (
        type => \%Defs::personType,
        role=> $role_ref,
        nature => \%Defs::registrationNature,
        level => \%Defs::personLevel,
        age => \%Defs::ageLevel,
        sport => \%Defs::sportType,
    );
    
    my $lookingForField = $lfTable{$lookingFor} || '';
    return (undef,'Invalid item to look for') if !$lookingForField;
    my $step=1;
    $step=2 if ($lookingFor eq 'sport');
    $step=3 if ($lookingFor eq 'role');
    $step=4 if ($lookingFor eq 'level');
    $step=5 if ($lookingFor eq 'age');
    $step=6 if ($lookingFor eq 'nature');

    my @retdata = ();
    if ($bulk and $step==6)  {
        my $label = $Data->{'lang'}->txt($lfLabelTable{$lookingFor}{'RENEWAL'});
        push @retdata, {
            name => $label,
            value => 'RENEWAL',
        };
        return (\@retdata, '');
    }
    if (!$bulk and $step==6 and $pref->{'strStatus'} eq 'INPROGRESS' and !$registrationNature) {
        my $label = $Data->{'lang'}->txt($lfLabelTable{$lookingFor}{'NEW'});
        push @retdata, {
            name => $label,
            value => 'NEW',
        };
        return (\@retdata, '');
    }
    #if (!$bulk and $step==6 and $pref->{'strStatus'} eq 'INPROGRESS')  {
    #    my $label = $Data->{'lang'}->txt($lfLabelTable{$lookingFor}{'TRANSFER'});
    #    push @retdata, {
    #        name => $label,
    #        value => 'TRANSFER',
    #    };
    #    return (\@retdata, '');
    #}

    if($lookingFor eq 'etype' and $originLevel)  {
        my $id = getID($Data->{'clientValues'}, $originLevel);
        $id = 0 if $originLevel == $Defs::LEVEL_PERSON;

        my $levels = _entityTypeList($Data, $id);

        my @MTXparams = (
            $originLevel,
            $realmID,
            $subRealmID,
            $personType
        );

        my $allowedToEntityLevel = getAllowedToEntityLevelFromMatrix($Data, \@MTXparams);

        if($originLevel == $Defs::LEVEL_PERSON) {
            push @{$levels}, $Defs::LEVEL_NATIONAL;
        }
        else    {
            push @{$levels}, $originLevel;
        }
        foreach my $l (@{$levels})  {
            if($l ~~ @{$allowedToEntityLevel}){
                push @retdata, {
                    name => $Data->{'lang'}->txt($Data->{'LevelNames'}{$l} || $Defs::LevelNames{$l}),
                    value => $l,
                };
            }
        }
        return (\@retdata, '');
    }
    if($lookingFor eq 'eId' and $etype)  {
        my $levels = undef;
        if($originLevel == $Defs::LEVEL_PERSON) {
            $levels = _entityList($Data, $etype, 0, $originLevel);
        }
        else    {
            $levels = _entityList($Data, $etype, getID($Data->{'clientValues'}, $originLevel), $originLevel);
        }
        return ($levels,'');
    }

    my @values = ();
    my $st = '';
    my ($MATRIXwhere, $ERAwhere, $ENTITYAllowedwhere) = ('','','');
    my @MATRIXvalues = (
        $originLevel,
        $realmID,
        $subRealmID
    );
    my @ERAvalues = (
        $entityID,
        $realmID,
        $subRealmID
    );
    my @ENTITYAllowedValues = (
        $entityID,
        $realmID,
        $subRealmID
    );

    my @regWindowFields = (
        'intRealmID',
        'intSubRealmID',
    );

    my %regWindowFieldValues = (
        'intRealmID' => $realmID,
        'intSubRealmID' => $subRealmID,
    );

    ### LETS BUILD UP THE SQL WHERE STATEMENTS TO HELP NARROW SELECTION

    if($bulk) {
        push @regWindowFields, 'strWFRuleFor';
        $regWindowFieldValues{'strWFRuleFor'} = 'BULKREGO';
    }
    else {
        push @regWindowFields, 'strWFRuleFor';
        $regWindowFieldValues{'strWFRuleFor'} = 'REGO';
    }

    if($registrationNature) {
        push @regWindowFields, 'strRegistrationNature';
        $regWindowFieldValues{'strRegistrationNature'} = $registrationNature;
    }

    if($step > 2) {# and defined $sport)  {
        push @MATRIXvalues, $sport;
        push @ERAvalues, $sport;
        push @ENTITYAllowedValues, $sport;
        $MATRIXwhere .= " AND strSport = ? ";
        $ERAwhere .= " AND strSport = ? ";
        $ENTITYAllowedwhere .= " AND (strDiscipline in ('ALL', '', ?) OR strDiscipline IS NULL) ";

        push @regWindowFields, 'strSport';
        $regWindowFieldValues{'strSport'} = $sport;
    }
    if($step > 6 and defined $registrationNature)  {
        push @MATRIXvalues, $registrationNature;
        $MATRIXwhere .= " AND strRegistrationNature = ? ";

        push @regWindowFields, 'strRegistrationNature';
        $regWindowFieldValues{'strRegistrationNature'} = $registrationNature;
    }
    if($step > 1 and defined $personType)  {
        push @MATRIXvalues, $personType;
        push @ERAvalues, $personType;
        $MATRIXwhere .= " AND strPersonType = ? ";
        $ERAwhere .= " AND strPersonType = ? ";

        push @regWindowFields, 'strPersonType';
        $regWindowFieldValues{'strPersonType'} = $personType;
    }
    if($step > 3 and defined $personEntityRole)  {
        push @MATRIXvalues, $personEntityRole;
        $MATRIXwhere .= " AND strPersonEntityRole IN ('', ?) ";
    }
    if($step > 4 and defined $personLevel)  {
        push @MATRIXvalues, $personLevel;
        push @ERAvalues, $personLevel;
        $MATRIXwhere .= " AND strPersonLevel = ? ";
        $ERAwhere .= " AND strPersonLevel = ? ";

        push @regWindowFields, 'strPersonLevel';
        $regWindowFieldValues{'strPersonLevel'} = $personLevel;
    }
    if($step > 5 and defined $ageLevel)  {
        push @MATRIXvalues, $ageLevel;
        push @ERAvalues, $ageLevel;
        $MATRIXwhere .= " AND strAgeLevel IN ('ALL_AGES', ?) ";
        $ERAwhere .= " AND strAgeLevel IN ('ALL_AGES', ?) ";
    }
    if(defined $pref->{'intGender'})  {
        push @ERAvalues, $pref->{'intGender'} || 0;
        $ERAwhere .= " AND intGender IN (0, ?) ";

        #use Defs here
        my $personGender = ($pref->{'intGender'} == 0) ? "ALL" : ($pref->{'intGender'} == 1) ? "MALE" : "FEMALE";
        push @ENTITYAllowedValues, $personGender;
        $ENTITYAllowedwhere .= " AND (strGender in ('ALL', '', ?) or strGender IS NULL) ";
            

    }

    if ($entityID)  {
        my $eref= loadEntityDetails($Data->{'db'}, $entityID);
        my $entityType = $eref->{'strEntityType'} || '';
        my $entityLevel = $eref->{'intEntityLevel'} || 0;
        if ($entityLevel)  {
            push @MATRIXvalues, $entityLevel;
            $MATRIXwhere .= qq[ AND intEntityLevel = ?];
        }
        if ($entityType)    {
            push @MATRIXvalues, $entityType;
            $MATRIXwhere .= qq[ AND strEntityType IN ('', ?)];
        }
    }

    if (! checkMatrixOK($Data, $MATRIXwhere, \@MATRIXvalues, $bulk))   {
    #    return (\@retdata, '');
        return (\@retdata, $Data->{'lang'}->txt('This type of registration is not available'));
    }

    #if(!checkPersonRegistrationWindow($Data, \@regWindowFields, \%regWindowFieldValues)) {
    #    return (\@retdata, $Data->{'lang'}->txt('This type of registration is not within the window.'));
    #}

    ### ALL OK, LETS RETURN NEXT SET OF SELECTIONS
    if ($lookingForField eq 'strPersonEntityRole')  {
        my $roledata_ref = returnEntityRoles($role_ref, $Data);
        return ($roledata_ref, '');
    }
    elsif ($lookingForField eq 'strPersonType') {
        my @personTypeOptions = getPersonTypeFromMatrix($Data, $realmID, $subRealmID, $MATRIXwhere, \@MATRIXvalues, $defaultType, $bulk);

        if(!@personTypeOptions) {
            return (undef, 'List of Person Type not found for the current realm.');
        } else {
            return (\@personTypeOptions, '');
        }

        #return ($personTypeOptions, "");
    }

    elsif ($entityID and $lookingForField ne 'strRegistrationNature')   {
        #FC-181 - now check for allowed Sport and Gender
        #FC-181 - remove query to tblEntityRegistrationAllowed for now
        if($lookingForField eq 'strSport') {
            #identify the list if sports from tblEntity
            #include Gender check here (checkEntityAllowed will initially look for valid gender)
            my $entityAllowed = checkEntityAllowed($Data, $ENTITYAllowedwhere, \@ENTITYAllowedValues);
            return (undef, "Please check player's gender.") if(!$entityAllowed);
            if ($defaultSport)  {
                $MATRIXwhere .= " AND strSport = '$defaultSport'";
            }

            #based on strDiscipline value in tblEntity, identify the list to return
            #if strDiscipline == ALL, return selected distinct strSport from tblMatrix
            #otherwise check from tblMatrix if strDiscipline is allowed before returning any options

            if((defined $Defs::entitySportType{$entityAllowed->{'strDiscipline'}}) and $entityAllowed->{'strDiscipline'} ne 'ALL') {
                #include in WHERE the specific sport from tblEntity to narrow down search
                $MATRIXwhere .= " AND $lookingForField = '$entityAllowed->{'strDiscipline'}'";
            }

            $st = qq[
                SELECT DISTINCT $lookingForField, COUNT(intMatrixID) as CountNum
                FROM tblMatrix
                WHERE
                    intOriginLevel  = ?
                    AND intLocked=0
                    AND intRealmID = ?
                    AND intSubRealmID IN (0,?)
                    $bulkWHERE
                    $MATRIXwhere
                GROUP BY $lookingForField
            ];

            @values = @MATRIXvalues;
        }
        elsif ($lookingForField eq 'strPersonLevel') {
            #TODO
            #handle for other steps (person role, level, age group)

            if(defined $registrationNature and $registrationNature) {
                $MATRIXwhere .= qq[ AND strRegistrationNature = ? ];
                push @MATRIXvalues, $registrationNature;
            }

            my $internationalTransfer = ($itc and $preqtype eq $Defs::PERSON_REQUEST_TRANSFER) ? 1 : 0;
            my $internationalLoan = ($itc and $preqtype eq $Defs::PERSON_REQUEST_LOAN) ? 1 : 0;

            if($internationalLoan == 1) {
                $MATRIXwhere .= qq[ AND intUseForInternationalLoan = 1 ];
            }
            elsif($internationalTransfer == 1) {
                $MATRIXwhere .= qq[ AND intUseForInternationalTransfer = 1 ];
            }

            $Data->{'Realm'} = $Data->{'Realm'} || $realmID;
            my $personLevelFromMatrix = getPersonLevelFromMatrix($Data, $MATRIXwhere, \@MATRIXvalues, $bulk, $personType, $pref, $defaultLevel);
            return ($personLevelFromMatrix, '');
            #$st = qq[
            #    SELECT DISTINCT $lookingForField, COUNT(intMatrixID) as CountNum
            #    FROM tblMatrix
            #    WHERE
            #        intOriginLevel  = ?
            #        AND intLocked=0
            #        AND intRealmID = ?
            #        AND intSubRealmID IN (0,?)
            #        $bulkWHERE
            #        $MATRIXwhere
            #    GROUP BY $lookingForField
            #];

            #@values = @MATRIXvalues;
        }
        elsif ($lookingForField eq 'strAgeLevel') {
            #get age level from tblMatrix to narrow down selection in checkRegoAgeRestrictions
            my $ageLevelFromMatrix = getAgeLevelFromMatrix($Data, $MATRIXwhere, \@MATRIXvalues, $bulk);

            if(!$ageLevelFromMatrix) {
                return (undef, 'No age level defined.') 
            }
            else {
                #print STDERR Dumper @ageLevelFromMatrix;
                
                my @tempAgeLevel = @{$ageLevelFromMatrix};
                if ($bulk)  {
                    $st = qq[
                        SELECT DISTINCT $lookingForField, COUNT(intMatrixID) as CountNum
                        FROM tblMatrix
                        WHERE
                            intOriginLevel  = ?
                            AND intLocked=0
                            $bulkWHERE
                            AND intRealmID = ?
                            AND intSubRealmID IN (0,?)
                            $MATRIXwhere
                        GROUP BY $lookingForField
                    ];
                    @values = @MATRIXvalues;
                    my $q = $Data->{'db'}->prepare($st);
                    $q->execute(@values);
                    while(my ($val, $countNum) = $q->fetchrow_array())   {
                        if($val)    {
                            my $label = $lfLabelTable{$lookingFor}{$val};
                            $label = $Data->{'lang'}->txt($lfLabelTable{$lookingFor}{$val});
                            push @retdata, {
                                name => $label,
                                value => $val,
                            };
                        }
                        else    {
                            push @retdata, {
                                name => $Data->{'lang'}->txt('Selection Not Required'),
                                value => 0,
                            };
                       }
                    }
                    return (\@retdata, '');
                }

                if(scalar(@tempAgeLevel) == 1 and $tempAgeLevel[0] eq '' and ($personType ne $Defs::PERSON_TYPE_PLAYER and $personType ne $Defs::PERSON_TYPE_REFEREE and $personType ne $Defs::PERSON_TYPE_COACH)) {
                    my @retdata;
                    push @retdata, {
                        name => $Data->{'lang'}->txt('Selection Not Required'),
                        value => 0,
                    };

                    return (\@retdata, '');
                }
                else {
                    $Data->{'Realm'} = $Data->{'Realm'} || $realmID,
                    my $ageLevelOptions = checkRegoAgeRestrictions(
                        $Data,
                        $personID,
                        0,
                        $sport,
                        $personType,
                        $personEntityRole,
                        $personLevel,
                        @{$ageLevelFromMatrix},
                    );
                    if(!$ageLevelOptions) {
                        return (undef, 'Age Level/Person\'s age not defined.');
                    }
                    else {
                        return ($ageLevelOptions, '');
                    }
                }
            }
            #$Data->{'Realm'} = $Data->{'Realm'} || $realmID,
            #my @ageLevelOptions = checkRegoAgeRestrictions(
            #    $Data,
            #    $personID,
            #    0,
            #    $sport,
            #    $personType,
            #    $personEntityRole,
            #    $personLevel,
            #    $ageLevel,
            #);

            #print STDERR Dumper @ageLevelOptions;
            #if(!$inAgeRange) {
            #    return (undef, 'Age not in valid range.');
            #}


            #$st = qq[
            #    SELECT DISTINCT $lookingForField, COUNT(intMatrixID) as CountNum
            #    FROM tblMatrix
            #    WHERE
            #        intOriginLevel  = ?
            #        AND intLocked=0
            #        AND intRealmID = ?
            #        AND intSubRealmID IN (0,?)
            #        $MATRIXwhere
            #    GROUP BY $lookingForField
            #];

            #@values = @MATRIXvalues;
        }
    }
    else    {

        #my $NATUREwhere= qq[AND strRegistrationNature <> 'TRANSFER'];
        my $NATUREwhere= qq[AND strRegistrationNature = 'NEW'];
        if ($registrationNature eq 'TRANSFER' and $lookingForField eq 'strRegistrationNature')   {
            $NATUREwhere= qq[AND strRegistrationNature = 'TRANSFER'];
        }
        if ($registrationNature eq 'RENEWAL' and $lookingForField eq 'strRegistrationNature')   {
            $NATUREwhere= qq[AND strRegistrationNature = 'RENEWAL'];
        }
        if ($registrationNature eq 'NEW' and $lookingForField eq 'strRegistrationNature')   {
            $NATUREwhere= qq[AND strRegistrationNature = 'NEW'];
        }
        if ($registrationNature eq $Defs::REGISTRATION_NATURE_DOMESTIC_LOAN and $lookingForField eq 'strRegistrationNature')   {
            $NATUREwhere= qq[AND strRegistrationNature = 'DOMESTIC_LOAN'];
        }
        #if ($registrationNature eq $Defs::REGISTRATION_NATURE_INTERNATIONAL_LOAN and $lookingForField eq 'strRegistrationNature')   {
        #    $NATUREwhere= qq[AND strRegistrationNature = 'INTERNATIONAL_LOAN'];
        #}


        $st = qq[
            SELECT DISTINCT $lookingForField, COUNT(intMatrixID) as CountNum
            FROM tblMatrix
            WHERE
                intOriginLevel  = ?
                AND intLocked=0
                AND intRealmID = ?
                AND intSubRealmID IN (0,?)
                $MATRIXwhere
                $NATUREwhere
            GROUP BY $lookingForField
        ];

        @values = @MATRIXvalues;
    }
    

    my $q = $Data->{'db'}->prepare($st);
    $q->execute(@values);

    my $lookup = ();
    while(my ($val, $countNum) = $q->fetchrow_array())   {
        if($val)    {
            my $label = $lfLabelTable{$lookingFor}{$val};
            $label = $Data->{'lang'}->txt($lfLabelTable{$lookingFor}{$val});
            push @retdata, {
                name => $label,
                value => $val,
            };
        }
        else    {
            push @retdata, {
                name => $Data->{'lang'}->txt('Selection Not Required'),
                value => 0,
            };
       }
    }

    return (\@retdata, '');
}



#### FUNCTIONS #####

sub getOptionsFromMatrix {
    #query to retrieve options from tblMatrix will be moved here for reusability
}
sub returnEntityRoles   {

    my ($role_ref, $Data) = @_;
    my @retdata=();
    foreach my $key (keys %{$role_ref})   {
        push @retdata, {
            name => $role_ref->{$key},
            value => $key,
        };
     }
     if (! @retdata) {
        push @retdata, {
            name => $Data->{'lang'}->txt('Selection Not Required'),
            value => 0,
        };
     }
     return \@retdata;
}

sub checkMatrixOK   {

    my ($Data, $where, $values_ref, $bulk) = @_;

    my $st = qq[
        SELECT COUNT(intMatrixID) as CountNum
        FROM tblMatrix
        WHERE
            intOriginLevel  = ?
            AND intLocked=0
            AND intRealmID = ?
            AND intSubRealmID IN (0,?)
            $where
    ];
    if ($bulk)  {
        $st .= qq[ AND strWFRuleFor ='BULKREGO'];
    }
#warn($st);
#print STDERR Dumper($values_ref);
    my $q = $Data->{'db'}->prepare($st);
    $q->execute(@{$values_ref});
    return $q->fetchrow_array() || 0;
}

sub checkEntityAllowed {
    my ($Data, $where, $values_ref) = @_;

    my $st = qq[
        SELECT
            strDiscipline,
            strGender
        FROM tblEntity
        WHERE
            intEntityID = ?
            AND intRealmID = ?
            AND intSubRealmID in (0, ?)
            $where
        LIMIT 1
    ];
    
    my $q = $Data->{'db'}->prepare($st);
    $q->execute(@{$values_ref});
    my $dref = $q->fetchrow_hashref();

    return 0 if !$dref;

    return $dref;
    #print STDERR Dumper $dref;
}

#FC-181 - tblMatrix will rule out (tblEntityRegistrationAllowed will not be used for now)
sub getPersonTypeFromMatrix {
    my($Data, $realmID, $subRealmID, $where, $values_ref, $defaultType, $bulk) = @_;

    $defaultType ||= '';
    my $defaultTypeWHERE = '';
    if ($defaultType)   {
        $defaultTypeWHERE = qq[ AND strPersonType = ? ];
        push @{$values_ref}, $defaultType;
    }
    my $bulkWHERE='';
    $bulkWHERE = qq[ AND strWFRuleFor='BULKREGO'] if ($bulk);
    my $st=qq[
        SELECT DISTINCT strPersonType
        FROM tblMatrix
        WHERE
            intOriginLevel = ?
            AND intLocked = 0
            AND intRealmID IN (0, ?)
            AND intSubRealmID IN (0, ?)
            $bulkWHERE
            $where
            $defaultTypeWHERE
    ];
    my $query = $Data->{'db'}->prepare($st);
    $query->execute(@{$values_ref});
    
    my $personTypeList = \%Defs::personType;
    my @retdata=();
    while (my $dref = $query->fetchrow_hashref())   {
        push @retdata, {
            name => $Data->{'lang'}->txt($personTypeList->{$dref->{'strPersonType'}}),
            value => $dref->{'strPersonType'},
        }
        #$values{$dref->{'strPersonType'}} = $personTypeList->{$dref->{'strPersonType'}};
    }

    #return 0 if(!@retdata);

    return @retdata;
}

sub getAgeLevelFromMatrix {
    my($Data, $where, $values_ref, $bulk) = @_;
                       
    my $bulkWHERE='';
    $bulkWHERE = qq[ AND strWFRuleFor='BULKREGO'] if ($bulk);
    my $st=qq[
        SELECT DISTINCT strAgeLevel
        FROM tblMatrix
        WHERE
            intOriginLevel = ?
            AND intLocked = 0
            AND intRealmID IN (0, ?)
            AND intSubRealmID IN (0, ?)
            $bulkWHERE
            $where
    ];
    my $query = $Data->{'db'}->prepare($st);
    $query->execute(@{$values_ref});
    
    my @retdata=();
    my $count = 0;
    while (my $dref = $query->fetchrow_hashref())   {
        $count++;
        push @retdata, $dref->{'strAgeLevel'};
        #$values{$dref->{'strPersonType'}} = $personTypeList->{$dref->{'strPersonType'}};
    }

    return 0 if(!$count);
    return \@retdata;
}

sub getPersonLevelFromMatrix {
    my($Data, $where, $values_ref, $bulk, $personType, $pref, $defaultLevel) = @_;
                       
    my $systemConfig = getSystemConfig($Data);
    my $bulkWHERE='';
    my $defaultWHERE = '';

    $bulkWHERE = qq[ AND strWFRuleFor='BULKREGO'] if ($bulk);
    $defaultWHERE = qq[ AND strPersonLevel = '$defaultLevel'] if (defined $defaultLevel and $defaultLevel and $defaultLevel ne '');
    my $st = qq[
        SELECT DISTINCT strPersonLevel, COUNT(intMatrixID) as CountNum
        FROM tblMatrix
        WHERE
            intOriginLevel  = ?
            AND intLocked=0
            AND intRealmID = ?
            AND intSubRealmID IN (0,?)
            $defaultWHERE
            $bulkWHERE
            $where
        GROUP BY strPersonLevel
    ];
#print STDERR $st;
#print STDERR Dumper($values_ref);

    my $query = $Data->{'db'}->prepare($st);
    $query->execute(@{$values_ref});
    
    my @retdata=();
    my $count = 0;

    my $personLevelList = \%Defs::personLevel;
    while (my $dref = $query->fetchrow_hashref())   {
        #if the player is under 16, "PROFESSIONAL" should not be available (specific to MA - sys config entry)
        next if (
            defined $systemConfig->{'age_breakpoint_PLAYER_PROFESSIONAL'}
            and $personType eq $Defs::PERSON_TYPE_PLAYER
            and $dref->{'strPersonLevel'} eq $Defs::PERSON_LEVEL_PROFESSIONAL
            and $pref->{'currentAge'} < $systemConfig->{'age_breakpoint_PLAYER_PROFESSIONAL'}
        );

        #if the player is under 16, "AMATEUR_U_C" should not be available (specific to MA - sys config entry)
        next if (
            defined $systemConfig->{'age_breakpoint_PLAYER_AMATEUR_U_C'}
            and $personType eq $Defs::PERSON_TYPE_PLAYER
            and $dref->{'strPersonLevel'} eq $Defs::PERSON_LEVEL_AMATEUR_UNDER_CONTRACT
            and $pref->{'currentAge'} < $systemConfig->{'age_breakpoint_PLAYER_AMATEUR_U_C'}
        );

        if($dref->{'strPersonLevel'}){
            push @retdata, {
                name => $Data->{'lang'}->txt($personLevelList->{$dref->{'strPersonLevel'}}),
                value => $dref->{'strPersonLevel'},
            }
        }
        else {
            push @retdata, {
                name => $Data->{'lang'}->txt('Selection Not Required'),
                value => 0,
            }
        }
    }

    #return 0 if(!$count);
    return \@retdata;
}

sub _entityList {
    my ($Data, $etype, $currentEntityID, $originLevel) = @_;

    my $st = '';
    my $q = undef;
    my $systemConfig = getSystemConfig($Data);
    my $acceptSelfRegoFilter = qq [ AND intAcceptSelfRego = 1 ] if ($originLevel == 1 and $systemConfig->{'allow_SelfRego'});

    if($currentEntityID)    {
        $st = qq[
            (
            SELECT
                E.strLocalName,
                E.intEntityID
            FROM
                tblTempEntityStructure AS TES
                INNER JOIN tblEntity AS E
                    ON TES.intChildID = E.intEntityID
            WHERE
                E.intRealmID = ?
                AND intParentID = ?
                AND intChildLevel = ?
                AND E.strStatus = 'ACTIVE'
            ORDER BY
                E.strLocalName
            )
            UNION
            (
            SELECT
                E.strLocalName,
                E.intEntityID
            FROM
                tblEntity AS E
            WHERE
                E.intRealmID = ?
                AND intEntityID = ?
                AND intEntityLevel = ?
                AND E.strStatus = 'ACTIVE'
            ORDER BY
                E.strLocalName
            )
        ];
        $q = $Data->{'db'}->prepare($st);
        $q->execute((
            $Data->{'Realm'},
            $currentEntityID,
            $etype,
            $Data->{'Realm'},
            $currentEntityID,
            $etype,
        ));
    }
    else    {
        $st = qq[
            (
            SELECT
                E.strLocalName,
                E.intEntityID
            FROM
                tblEntity AS E
            WHERE
                E.intRealmID = ?
                AND intEntityLevel = ?
                AND E.strStatus = 'ACTIVE'
                $acceptSelfRegoFilter
            ORDER BY 
                E.strLocalName
            )
        ];
        $q = $Data->{'db'}->prepare($st);
        $q->execute((
            $Data->{'Realm'},
            $etype,
        ));
    }
    my @vals = ();
    while(my ($name, $id) = $q->fetchrow_array())   {
        push @vals, {
            name => $name,
            value => $id,
        };
    }
    return \@vals;
}

sub _entityTypeList {
    my ($Data, $currentEntityID) = @_;

    my $st = '';
    my $q = undef;
    if($currentEntityID)    {
        $st = qq[
            SELECT
                DISTINCT intChildLevel
            FROM
                tblTempEntityStructure AS TES
            WHERE
                intRealmID = ?
                AND intParentID = ?
                AND intChildLevel > 0
        ];
        $q = $Data->{'db'}->prepare($st);
        $q->execute((
            $Data->{'Realm'},
            $currentEntityID,
        ));
    }
    else    {
        $st = qq[
            SELECT
                DISTINCT intChildLevel
            FROM
                tblTempEntityStructure AS TES
            WHERE
                intRealmID = ?
                AND intChildLevel > 0
        ];
        $q = $Data->{'db'}->prepare($st);
        $q->execute((
            $Data->{'Realm'}
        ));
    }
    my @vals = ();
    while(my ($level) = $q->fetchrow_array())   {
        push @vals, $level;
    }
    return \@vals;
}


sub getAllowedToEntityLevelFromMatrix {
    my ($Data, $values_ref) = @_;

    my $st = qq[
        SELECT DISTINCT intEntityLevel
        FROM tblMatrix
        WHERE
            intOriginLevel = ?
            AND intLocked = 0
            AND intRealmID = ?
            AND intSubRealmID IN (0, ?)
            AND strPersonType = ?
    ];

    my $query = $Data->{'db'}->prepare($st);
    $query->execute(@{$values_ref});
	
    my @vals=();
    while(my ($entityLevel) = $query->fetchrow_array())   {
        push @vals, $entityLevel;
    }

    return \@vals;
}


1;
