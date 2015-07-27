package ListPersons;

require Exporter;
@ISA =    qw(Exporter);
@EXPORT = qw(listPersons);
@EXPORT_OK = qw(listPersons);

use strict;
use CGI qw(param unescape escape);

use lib '.', "..";
use InstanceOf;
use Defs;
use Reg_common;
use FieldLabels;
use Utils;
use DBUtils;
use CustomFields;
use RecordTypeFilter;
use GridDisplay;
use AgeGroups;
use FormHelpers;
use AuditLog;
use Log;
use TTTemplate;
use PersonUtils;

sub listPersons {
    my ($Data, $entityID, $action) = @_; 

    my $db            = $Data->{'db'};
    my $resultHTML    = '';
    my $client        = unescape($Data->{client});
    my $type          = $Data->{'clientValues'}{'currentLevel'};
    my $levelName     = $Data->{'LevelNames'}{$type} || '';
    my $action_IN     = $action || '';
    my $target        = $Data->{'target'} || '';
    my $realm_id      = $Data->{'Realm'};
    my $title = '';
    my $lang = $Data->{'lang'};
    #checks begins here
    #check if the entity viewing the list > LEVEL_NATIONAL

    my $unlockInactiveLevel = $Data->{'SystemConfig'}{'unlockListPeople_level'} || $Defs::LEVEL_NATIONAL;
    my $entityChecks = Entity::loadEntityDetails($db, $entityID); 
    if($Data->{'clientValues'}{'authLevel'} < $unlockInactiveLevel){    	
    	if($entityChecks->{'strStatus'} ne 'ACTIVE'){ 
    		$resultHTML =qq[
    		<div class="warningmsg">]. $lang->txt('Entity Not Allowed To View List') .q[</div>
    		];
    		$title = $lang->txt('Error');
            return ($resultHTML,$title);
    	}
    }
    ### End checks here    
    
    my ($AgeGroups, undef) = AgeGroups::getAgeGroups($Data);

    return textMessage($lang->txt('Invalid page requested')) if !$type;

    my $memfieldlabels=FieldLabels::getFieldLabels($Data,$Defs::LEVEL_PERSON);
    my $CustomFieldNames=CustomFields::getCustomFieldNames($Data, $Data->{'SubRealm'} || 0) || '';

    my $statement=qq[
        SELECT DISTINCT 
            P.intPersonID,
            P.strStatus,
            P.intSystemStatus,
            P.strLocalSurname,
            P.strLocalFirstname,
            P.strNationalNum,
            P.strFIFAID,
            P.dtDOB,
            P.intGender as PersonGender,
            PR.strPersonType AS PRstrPersonType,
            PR.strStatus AS PRStatus,
            PR.strPersonSubType AS PRstrPersonSubType,
            PR.strPersonEntityRole AS PRstrPersonEntityRole,
            ETR.strEntityRoleName AS PRstrPersonEntityRoleName,
            PR.strPersonLevel AS PRstrPersonLevel,
            PC.intCertificationTypeID,
            CT.strCertificationName
        FROM tblPerson  AS P
            INNER JOIN tblPersonRegistration_$realm_id AS PR ON ( 
                P.intPersonID = PR.intPersonID
                AND PR.strStatus NOT IN ('ROLLED_OVER')
                AND PR.intEntityID = ?
            )
            LEFT JOIN tblEntityTypeRoles as ETR ON (
                ETR.strEntityRoleKey = PR.strPersonEntityRole
            ) 
            LEFT JOIN tblPersonCertifications as PC ON (
                P.intPersonID = PC.intPersonID
                AND PC.strStatus = 'ACTIVE'
            ) 
            LEFT JOIN tblCertificationTypes as CT ON (
                PC.intCertificationTypeID = CT.intCertificationTypeID
            ) 
        WHERE 
            P.strStatus <> 'DELETED' 
            AND (PR.strStatus IN ('ACTIVE', 'PASSIVE') OR (PR.intOnLoan = 1 AND PR.dtTo > NOW()))
            AND P.intRealmID = $realm_id
        ORDER BY 
            strLocalSurname, 
            strLocalFirstname,
            P.intPersonID
    ];
            #AND PR.strStatus <> 'INPROGRESS'

    my $query = $Data->{'db'}->prepare($statement);
    $query->execute(
        $entityID, 
    );
    my $found = 0;
    my @rowdata = ();
    my $newaction='P_HOME';
    my $lookupfields = personList_lookupVals($Data);

    my %tempClientValues = getClient($client);
    $tempClientValues{currentLevel} = $Defs::LEVEL_PERSON;
    my %PersonSeen=();
    my %PersonRegos = ();
    my %UsedTypes = ();
    my %UsedSubRoles = ();
    my %UsedLevels = ();
    my %subRoleNames = ();
    my %certNames = ();
    my %UsedCerts = ();
    while (my $dref = $query->fetchrow_hashref()) {
        next if (defined $dref->{intSystemStatus} and $dref->{intSystemStatus} == $Defs::PERSONSTATUS_DELETED);
        next if (
            (
                $dref->{'PRStatus'} eq $Defs::PERSONREGO_STATUS_DELETED
                or $dref->{'PRStatus'} eq $Defs::PERSONREGO_STATUS_TRANSFERRED 
                or $dref->{'PRStatus'} eq $Defs::PERSONREGO_STATUS_INPROGRESS
                or $dref->{'strStatus'} eq $Defs::PERSON_STATUS_DELETED
                or $dref->{'strStatus'} eq $Defs::PERSON_STATUS_SUSPENDED
            )
            and $Data->{'clientValues'}{'authLevel'} < $Defs::LEVEL_NATIONAL
        );

        $dref->{'strNationalNum'} ||= $Defs::personStatus{$dref->{'strStatus'}} || '';
        $dref->{'PRStatus'} = $dref->{'PRActiveStatus'} if ($dref->{'PRActiveStatus'});
        $dref->{'PRStatus'} = ($dref->{'PRStatus'} eq $Defs::PERSONREGO_STATUS_ACTIVE and $dref->{'PRintPaymentRequired'}) ? $Defs::PERSONREGO_STATUS_ACTIVE_PENDING_PAYMENT : $Defs::PERSONREGO_STATUS_ACTIVE;

        $dref->{'PRStatus'} = $lang->txt('SUSPENDED') if ($dref->{'strStatus'} eq 'SUSPENDED');
        $dref->{'strStatus'} = $lang->txt($Defs::personStatus{$dref->{'strStatus'}}); ## Lets use PR status
        
        push @{$PersonRegos{$dref->{'intPersonID'}}}, {
            type => $dref->{'PRstrPersonType'},
            status => $dref->{'PRStatus'},
            subtype => $dref->{'PRstrPersonSubType'},
            level => $dref->{'PRstrPersonLevel'},
            entityrole => $dref->{'PRstrPersonEntityRole'},
            certType => $dref->{'intCertificationTypeID'} || 0,
        };
        if($dref->{'PRstrPersonEntityRole'})    {
            $UsedSubRoles{$dref->{'PRstrPersonEntityRole'}} =  1;
            $subRoleNames{$dref->{'PRstrPersonEntityRole'}} = $dref->{'PRstrPersonEntityRoleName'} || '';
        }
        $UsedLevels{$dref->{'PRstrPersonLevel'}} =  1 if $dref->{'PRstrPersonLevel'};
        if($dref->{'PRstrPersonType'})  {
            $UsedTypes{$dref->{'PRstrPersonType'}} =  1;
        }
        if($dref->{'intCertificationTypeID'})  {
            $certNames{$dref->{'intCertificationTypeID'}} =  $dref->{'strCertificationName'} || '';
            $UsedCerts{$dref->{'intCertificationTypeID'}} =  1;
        }
        next if exists $PersonSeen{$dref->{'intPersonID'}};
        $PersonSeen{$dref->{'intPersonID'}} = 1;

        $dref->{'intGender'} ||= 0;
        $dref->{'strLocalFirstname'} ||= '';
        $dref->{'strLocalSurname'} ||= '-';
        for my $k (keys %{$lookupfields})    {
            if($k and $dref->{$k} and $lookupfields->{$k} and $lookupfields->{$k}{$dref->{$k}}) {
                $dref->{$k} = $lookupfields->{$k}{$dref->{$k}};
            }
        }

        if($dref->{'intSystemStatus'} ==$Defs::PERSONSTATUS_POSSIBLE_DUPLICATE )    {
            my %keepduplicatefields = (
                intPersonID => 1,
                strLocalSurname => 1,
                strLocalFirstname=> 1,
                intPersonID=> 1,
                strStatus=> 1,
            );
            for my $k (keys %{$dref})    {
                if(!$keepduplicatefields{$k})    {
                    delete $dref->{$k};
                }
            }
            $dref->{'strStatus'}=$lang->txt('DUPLICATE');
        }
        $tempClientValues{personID} = $dref->{intPersonID};
        my $tempClient = setClient(\%tempClientValues);
        $dref->{'link'} = "$target?client=$tempClient&amp;a=$newaction";
        $dref->{'name'} = formatPersonName($Data, $dref->{'strLocalFirstname'}, $dref->{'strLocalSurname'}, $dref->{'PersonGender'});
        
        push @rowdata, $dref;
        $found++;
    }
    foreach my $row (@rowdata)  {
        my $id = $row->{'intPersonID'} || next;
        my %types = ();
        my %subtypes = ();
        my %levels = ();
        my %entityroles = ();
        my %certs = ();
        foreach my $reg (@{$PersonRegos{$id}}) {
            my $type = $reg->{'type'} || '';
            my $status = $reg->{'status'} || 'PASSIVE';
            my $subtype = $reg->{'subtype'} || '';
            my $level = $reg->{'level'} || '';
            my $entityrole = $reg->{'entityrole'} || '';
            my $cert = $reg->{'certType'} || '';
            if(
                !exists $types{$type}
                or (exists $types{$type} and $status eq 'ACTIVE')
            ) {
                $types{$type} = $status;
            }
            if(
                !exists $subtypes{$subtype}
                or (exists $subtypes{$subtype} and $status eq 'ACTIVE')
            ) {
                $subtypes{$subtype} = $status;
            }
            if(
                !exists $levels{$level}
                or (exists $levels{$level} and $status eq 'ACTIVE')
            ) {
                $levels{$level} = $status;
            }
            if(
                !exists $entityroles{$entityrole}
                or (exists $entityroles{$entityrole} and $status eq 'ACTIVE')
            ) {
                $entityroles{$entityrole} = $status;
            }
            if(
                !exists $certs{$cert}
                or (exists $certs{$cert} and $status eq 'ACTIVE')
            ) {
                $certs{$cert} = $status;
            }
        } 
        my $types_str = '';
        for my $t (keys %types) {
            next if !$t;
            my $status = $types{$t} || 'PASSIVE';
            $types_str .= '/' if $types_str;
            $types_str .= qq[<span class = "TYPE_STATUS_$status"><span class = "hidden-col-val">$t</span>].$lang->txt($Defs::personType{$t}).qq[</span>];
        }
        my $subtypes_str = '';
        for my $st (keys %subtypes) {
            next if !$st;
            my $status = $subtypes{$st} || 'PASSIVE';
            $subtypes_str .= '/' if $subtypes_str;
            $subtypes_str .= qq[<span class = "SUBTYPE_STATUS_$status"><span class = "hidden-col-val">$st</span>].$lang->txt($subRoleNames{$st}).qq[</span>];
        }
        for my $er (keys %entityroles) {
            next if !$er;
            my $status = $entityroles{$er} || 'PASSIVE';
            $subtypes_str .= '/' if $subtypes_str;
            $subtypes_str .= qq[<span class = "SUBTYPE_STATUS_$status"><span class = "hidden-col-val">$er</span>].$lang->txt($subRoleNames{$er}).qq[</span>];
        }
        my $levels_str = '';
        for my $l (keys %levels) {
            next if !$l;
            my $status = $levels{$l} || 'PASSIVE';
            $levels_str .= '/' if $levels_str;
            $levels_str .= qq[<span class = "LEVEL_STATUS_$status"><span class = "hidden-col-val">$l</span>].$lang->txt($Defs::personLevel{$l}).qq[</span>];
        }
        my $certs_str = '';
        for my $l (keys %certs) {
            next if !$l;
            my $status = $certs{$l} || 'PASSIVE';
            $certs_str .= '/' if $certs_str;
            $certs_str .= qq[<span class = "CERT_STATUS_$status"><span class = "hidden-col-val">$l</span>].$lang->txt($certNames{$l}).qq[</span>];
        }
        $row->{'types'} = $types_str;
        $row->{'subtypes'} = $subtypes_str;
        $row->{'levels'} = $levels_str;
        $row->{'certs'} = $certs_str;
    }


    $title = $lang->txt("Persons in [_1]",$Data->{'LevelNames'}{$type});
    if ($type == $Defs::LEVEL_NATIONAL) {
        $title = $lang->txt("List of people registered directly with the Member Association");
    }
    if ($type == $Defs::LEVEL_REGION) {
        $title = $lang->txt("List of people registered directly with the Region");
    }
    if ($type == $Defs::LEVEL_CLUB) {
        $title = $lang->txt("List of people registered with the Club");
    }

    my %typeValues = (); 
    my %subRoleValues = ();
    my %levelValues = ();
    my %certValues = ();

    for my $i (keys %UsedTypes) {
        $typeValues{$i} =  $Defs::personType{$i} || '';
    }
    for my $i (keys %UsedSubRoles) {
        $subRoleValues{$i} =  $subRoleNames{$i} || '';
    }
    for my $i (keys %UsedLevels) {
        $levelValues{$i} =  $Defs::personLevel{$i} || '';
    }
    for my $i (keys %UsedCerts) {
        $certValues{$i} =  $certNames{$i} || '';
    }
    $resultHTML = runTemplate(
        $Data,
        {
            rowdata => \@rowdata,
            filter => {
                types => \%typeValues,
                subtypes => \%subRoleValues,
                levels => \%levelValues,
                certs => \%certValues,
            }
        },
        'person/list.templ',
    );

    return ($resultHTML,$title);
}

sub personList_lookupVals {
    my($Data)=@_;
    my $lang = $Data->{'lang'};
    my %ynVals=( 1 => $lang->txt('Y'), 0 => $lang->txt('N'));
    my %lookupfields=(
        intGender => {
            $Defs::GENDER_MALE => $lang->txt($Defs::genderInfo{$Defs::GENDER_MALE}),
            $Defs::GENDER_FEMALE => $lang->txt($Defs::genderInfo{$Defs::GENDER_FEMALE}),
            $Defs::GENDER_NONE=> '',
        },
    );

    return \%lookupfields;
}

1;
# vim: set et sw=4 ts=4:
