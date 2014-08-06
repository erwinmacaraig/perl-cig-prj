package PersonRegisterWhat;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = @EXPORT_OK = qw(
	displayPersonRegisterWhat
    optionsPersonRegisterWhat
);

use strict;
use Utils;
use Reg_common;
use TTTemplate;
use Log;
use EntityTypeRoles;


sub displayPersonRegisterWhat   {
    my(
        $Data,
        $personID,
        $entityID,
        $dob,
        $gender,
        $originLevel,
        $continueURL,
    ) = @_;

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

    my $body = runTemplate(
        $Data, 
        \%templateData, 
        "registration/what.templ"
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
    ) = @_;

    my %lfTable = (
        type => 'strPersonType',
        nature => 'strRegistrationNature',
        level => 'strPersonLevel',
        age => 'strAgeLevel',
        sport => 'strSport',
        role => 'strPersonEntityRole',
    );
    my $role_ref = getEntityTypeRoles($Data, $sport, $personType);
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

    my @ERAvalues = ();
    my @MATRIXvalues = ();
    my $MATRIXwhere = '';
    my $ERAwhere = '';
    push @MATRIXvalues, $originLevel;
    push @MATRIXvalues, $realmID;
    push @MATRIXvalues, $subRealmID;
    push @ERAvalues, $entityID;
    push @ERAvalues, $realmID;
    push @ERAvalues, $subRealmID;

    if($sport)  {
        push @MATRIXvalues, $sport;
        push @ERAvalues, $sport;
        $MATRIXwhere .= " AND strSport = ? ";
        $ERAwhere .= " AND strSport = ? ";
    }
    if($registrationNature)  {
        push @MATRIXvalues, $registrationNature;
        $MATRIXwhere .= " AND strRegistrationNature = ? ";
    }
    if($personType)  {
        push @MATRIXvalues, $personType;
        push @ERAvalues, $personType;
        $MATRIXwhere .= " AND strPersonType = ? ";
        $ERAwhere .= " AND strPersonType = ? ";
    }
    if($personEntityRole)  {
        push @MATRIXvalues, $personEntityRole;
        $MATRIXwhere .= " AND strPersonEntityRole IN ('', ?) ";
    }
    if($personLevel)  {
        push @MATRIXvalues, $personLevel;
        push @ERAvalues, $personLevel;
        $MATRIXwhere .= " AND strPersonLevel = ? ";
        $ERAwhere .= " AND strPersonLevel = ? ";
    }
    if($ageLevel)  {
        push @MATRIXvalues, $ageLevel;
        push @ERAvalues, $ageLevel;
        $MATRIXwhere .= " AND strAgeLevel IN ('ALL_AGES', ?) ";
        $ERAwhere .= " AND strAgeLevel IN ('ALL_AGES', ?) ";
    }

    my $st = qq[
        SELECT DISTINCT $lookingForField
    ];

    ## IF entityID then get strEntityType
    my @retdata = ();
    my $entityType = '';
    my $entityLevel=0;
    if ($entityID)  {
        my $stEntity = qq[
            SELECT
                strEntityType,
                intEntityLevel
            FROM
                tblEntity
            WHERE 
                intRealmID = ?
                AND intEntityID = ?
            LIMIT 1
        ];
        my $qEntity= $Data->{'db'}->prepare($stEntity);
        $qEntity->execute($Data->{'Realm'}, $entityID);
        ($entityType, $entityLevel) = $qEntity->fetchrow_array() || '';
    }

    if ($lookingForField eq 'strPersonEntityRole')  {
warn("SHOULD THIS MOVE TO FUTHER DOWN ?");
        foreach my $key (keys %{$role_ref})   {
            push @retdata, {
                name => $role_ref->{$key},
                value => $key,
            };
        }
        if (! @retdata) {
            push @retdata, {
                name => '-',
                value => '-',
            };
        }
        return (\@retdata, '');
    }
    if (! $entityID and $lookingForField ne 'strRegistrationNature')    {
        $st = qq[
            SELECT COUNT(intMatrixID) as CountNum
        ];
    }
    $st .= qq[
        FROM tblMatrix
        WHERE
            intOriginLevel  = ?
            AND intRealmID = ?
            AND intSubRealmID IN (0,?)
            $MATRIXwhere
            AND strEntityType IN ('', ?)
    ];
    push @MATRIXvalues, $entityType;
warn($st);
    if ($entityLevel)  {
        $st .= qq[ AND intEntityLevel = ?];
        push @MATRIXvalues, $entityLevel;
    }
    if (! $entityID and $lookingForField ne 'strRegistrationNature')   {
        my $qCheck = $Data->{'db'}->prepare($st);
        $qCheck->execute(@MATRIXvalues);
        my $ok = $qCheck->fetchrow_array() || 0;
       # warn ("OK IS $ok");
        if (! $ok)  {
warn("NOT OK");
            return (\@retdata, '');
        }
    }

    my @values = ();
    if($entityID and $lookingForField ne 'strRegistrationNature')   {
        $st = qq[
            SELECT DISTINCT $lookingForField
            FROM tblEntityRegistrationAllowed
            WHERE
                intEntityID = ?
                AND intRealmID = ?
                AND intSubRealmID IN (0,?)
                $ERAwhere
        ];
        @values = @ERAvalues;
    }
    else    {
        @values = @MATRIXvalues;
    }
    

    my $q = $Data->{'db'}->prepare($st);
    $q->execute(@values);
    my $lookup = ();
    while(my $val = $q->fetchrow_array())   {
        if($val)    {
            my $label = $lfLabelTable{$lookingFor}{$val};
            $label = $Data->{'lang'}->txt($lfLabelTable{$lookingFor}{$val});
            push @retdata, {
                name => $label,
                value => $val,
            };
        }
    }
    return (\@retdata, '');
}

1;
