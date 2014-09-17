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
    ) = @_;
    $bulk ||= 0;
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
    );

    my $template = "registration/what.templ";
    $template = "registration/whatbulk.templ" if ($bulk);
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
        $personEntityRole,
        $personLevel,
        $sport,
        $ageLevel,
        $personID,
        $entityID,
        $dob,
        $gender,
        $lookingFor,
        $bulk
    ) = @_;
    $bulk ||= 0;


    my $pref= undef;
    $pref = loadPersonDetails($Data->{'db'}, $personID) if ($personID);

    my $role_ref = getEntityTypeRoles($Data, $sport, $personType);
    my %lfTable = (
        type => 'strPersonType',
        nature => 'strRegistrationNature',
        level => 'strPersonLevel',
        age => 'strAgeLevel',
        sport => 'strSport',
        role => 'strPersonEntityRole',
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

    ### LETS BUILD UP THE SQL WHERE STATEMENTS TO HELP NARROW SELECTION

    if($step > 2) {# and defined $sport)  {
        push @MATRIXvalues, $sport;
        push @ERAvalues, $sport;
        push @ENTITYAllowedValues, $sport;
        $MATRIXwhere .= " AND strSport = ? ";
        $ERAwhere .= " AND strSport = ? ";
        $ENTITYAllowedwhere .= " AND (strDiscipline in ('ALL', '', ?) OR strDiscipline IS NULL) ";
    }
    if($step > 6 and defined $registrationNature)  {
        push @MATRIXvalues, $registrationNature;
        $MATRIXwhere .= " AND strRegistrationNature = ? ";
    }
    if($step > 1 and defined $personType)  {
        push @MATRIXvalues, $personType;
        push @ERAvalues, $personType;
        $MATRIXwhere .= " AND strPersonType = ? ";
        $ERAwhere .= " AND strPersonType = ? ";
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
        return (\@retdata, '');
    }
    
    ### ALL OK, LETS RETURN NEXT SET OF SELECTIONS
    if ($lookingForField eq 'strPersonEntityRole')  {
        my $roledata_ref = returnEntityRoles($role_ref);
        return ($roledata_ref, '');
    }
    elsif ($lookingForField eq 'strPersonType') {
        my @personTypeOptions = getPersonTypeFromMatrix($Data, 1, $subRealmID, $MATRIXwhere, \@MATRIXvalues);

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
        if($step == 2) {
            #identify the list if sports from tblEntity
            #include Gender check here (checkEntityAllowed will initially look for valid gender)
            my $entityAllowed = checkEntityAllowed($Data, $ENTITYAllowedwhere, \@ENTITYAllowedValues);
            return (undef, "Please check player's gender.") if(!$entityAllowed);

            #based on strDiscipline value in tblEntity, identify the list to return
            #if strDiscipline == ALL, return selected distinct strSport from tblMatrix
            #otherwise check from tblMatrix if strDiscipline is allowed before returning any options

            if($entityAllowed->{'strDiscipline'} ne 'ALL') {
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
                    $MATRIXwhere
                GROUP BY $lookingForField
            ];

            @values = @MATRIXvalues;
        }
        else {
            #TODO
            #handle for other steps (person role, level, age group)
        }

        #$st = qq[
        #    SELECT DISTINCT $lookingForField, COUNT(intEntityRegistrationAllowedID) as CountNum
        #    FROM tblEntityRegistrationAllowed
        #    WHERE
        #        intEntityID = ?
        #        AND intRealmID = ?
        #        AND intSubRealmID IN (0,?)
        #        $ERAwhere
        #    GROUP BY $lookingForField
        #];
        #@values = @ERAvalues;
    }
    else    {

        $Data->{'Realm'} = $Data->{'Realm'} || $realmID,
        my $inAgeRange = checkRegoAgeRestrictions(
            $Data,
            $personID,
            0,
            $sport,
            $personType,
            $personEntityRole,
            $personLevel,
            $ageLevel,
        );

        if(!$inAgeRange) {
            return (undef, 'Age not in valid range.');
        }

        $st = qq[
            SELECT DISTINCT $lookingForField, COUNT(intMatrixID) as CountNum
            FROM tblMatrix
            WHERE
                intOriginLevel  = ?
                AND intLocked=0
                AND intRealmID = ?
                AND intSubRealmID IN (0,?)
                $MATRIXwhere
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
                name => '-',
                value => '',
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

    my ($role_ref) = @_;
    my @retdata=();
    foreach my $key (keys %{$role_ref})   {
        push @retdata, {
            name => $role_ref->{$key},
            value => $key,
        };
     }
     if (! @retdata) {
        push @retdata, {
            name => '-',
            value => '',
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
    my($Data, $realmID, $subRealmID, $where, $values_ref) = @_;
                       
    my $st=qq[
        SELECT DISTINCT strPersonType
        FROM tblMatrix
        WHERE
            intOriginLevel = ?
            AND intLocked = 0
            AND intRealmID IN (0, ?)
            AND intSubRealmID IN (0, ?)
            $where
    ];
    my $query = $Data->{'db'}->prepare($st);
    $query->execute(@{$values_ref});
    
    my $personTypeList = \%Defs::personType;
    my @retdata=();
    while (my $dref = $query->fetchrow_hashref())   {
        push @retdata, {
            name => $personTypeList->{$dref->{'strPersonType'}},
            value => $dref->{'strPersonType'},
        }
        #$values{$dref->{'strPersonType'}} = $personTypeList->{$dref->{'strPersonType'}};
    }

    #return 0 if(!@retdata);

    return @retdata;
}

sub getAllowedSports {
}

1;
