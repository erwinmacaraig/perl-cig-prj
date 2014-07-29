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

    my @values = (
        $realmID,
        $subRealmID,
        $originLevel,
    );
    my $where = '';
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
        $where .= " AND strAgeLevel = ? ";
    }

    my $st = qq[
        SELECT DISTINCT $lookingForField
        FROM tblWFRule
        WHERE
            intRealmID = ?
            AND intSubRealmID IN (0,?)
            AND strTaskType = 'APPROVAL'
            AND intOriginLevel  = ?
            AND strWFRuleFor = 'REGO'
            $where
    ];
    if($entityID)   {
        $st = qq[
            SELECT DISTINCT $lookingForField
            FROM tblEntityRegistrationAllowed
            WHERE
                intEntityID = ?
                intRealmID = ?
                AND intSubRealmID IN (0,?)
                AND strTaskType = 'APPROVAL'
                AND intOriginLevel  = ?
                AND strWFRuleFor = 'REGO'
                $where
        ];
        unshift @values, $entityID;
    }

    my $q = $Data->{'db'}->prepare($st);
    my @retdata = ();
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
#Still need to filter by entity
    return (\@retdata, '');
}

1;
