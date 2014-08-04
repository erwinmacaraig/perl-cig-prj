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
    );
    my %lfLabelTable = (
        type => \%Defs::personType,
        nature => \%Defs::registrationNature,
        level => \%Defs::personLevel,
        age => \%Defs::ageLevel,
        sport => \%Defs::sportType,
    );
    
    my $lookingForField = $lfTable{$lookingFor} || '';
    return (undef,'Invalid item to look for') if !$lookingForField;

    my @values = ();
        push @values, $originLevel;
        push @values, $realmID;
        push @values, $subRealmID;
    my $where = '';
    #if ($lookingForField eq 'strRegistrationNature')    {
        #push @values, $originLevel;
    #}
    if($sport)  {
        push @values, $sport;
        $where .= " AND strSport = ? ";
    }
    if($registrationNature)  {
        push @values, $registrationNature;
        $where .= " AND strRegistrationNature = ? ";
    }
    if($personType)  {
        push @values, $personType;
        $where .= " AND strPersonType = ? ";
    }
    if($personLevel)  {
        push @values, $personLevel;
        $where .= " AND strPersonLevel = ? ";
    }
    if($ageLevel)  {
        push @values, $ageLevel;
        $where .= " AND strAgeLevel IN ('ALL_AGES', ?) ";
    }

    my $st = qq[
        SELECT DISTINCT $lookingForField
    ];

    ## IF entityID then get strEntityType
    my $entityType = '';
    if ($entityID)  {
        my $stEntity = qq[
            SELECT
                strEntityType
            FROM
                tblEntity
            WHERE 
                intRealmID = ?
                AND intEntityID = ?
            LIMIT 1
        ];
        my $qEntity= $Data->{'db'}->prepare($stEntity);
        $qEntity->execute($Data->{'Realm'}, $entityID);
        $entityType = $qEntity->fetchrow_array() || '';
    }

    if (! $entityID and $lookingForField ne 'strRegistrationNature')    {
        $st = qq[
            SELECT COUNT(intWFRuleID) as CountNum
        ];
    }
    $st .= qq[
        FROM tblWFRule
        WHERE
            intOriginLevel  = ?
            AND intRealmID = ?
            AND intSubRealmID IN (0,?)
            AND strTaskType = 'APPROVAL'
            AND strWFRuleFor = 'REGO'
            $where
            AND strEntityType IN ('', ?)
    ];
    push @values, $entityType;
    my @retdata = ();
    if (! $entityID and $lookingForField ne 'strRegistrationNature')   {
        my $qCheck = $Data->{'db'}->prepare($st);
        $qCheck->execute(@values);
        my $ok = $qCheck->fetchrow_array() || 0;
       # warn ("OK IS $ok");
        if (! $ok)  {
            return (\@retdata, '');
        }
    }

    if($entityID and $lookingForField ne 'strRegistrationNature')   {
        shift @values; #Get rid of originLevel
        pop @values; #Get rid of EntityType
        $st = qq[
            SELECT DISTINCT $lookingForField
            FROM tblEntityRegistrationAllowed
            WHERE
                intEntityID = ?
                AND intRealmID = ?
                AND intSubRealmID IN (0,?)
                $where
        ];
        unshift @values, $entityID;
    }
warn($st);

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
