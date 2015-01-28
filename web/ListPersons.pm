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
            PR.strPersonType AS PRstrPersonType,
            PR.strStatus AS PRStatus,
            PR.strPersonSubType AS PRstrPersonSubType,
            PR.strPersonLevel AS PRstrPersonLevel
        FROM tblPerson  AS P
            INNER JOIN tblPersonRegistration_$realm_id AS PR ON ( 
                P.intPersonID = PR.intPersonID
                AND PR.strStatus NOT IN ('ROLLED_OVER')
                AND PR.intEntityID = ?
            )
        WHERE 
            P.strStatus <> 'DELETED' 
            AND PR.strStatus <> 'INPROGRESS'
            AND P.intRealmID = $realm_id
        ORDER BY 
            strLocalSurname, 
            strLocalFirstname,
            P.intPersonID
    ];

    my $query = $Data->{'db'}->prepare($statement);
    $query->execute(
        $entityID, 
    );
warn($entityID.$statement);
    my $found = 0;
    my @rowdata = ();
    my $newaction='P_HOME';
    my $lookupfields = personList_lookupVals($Data);

    my %tempClientValues = getClient($client);
    $tempClientValues{currentLevel} = $Defs::LEVEL_PERSON;
    my %PersonSeen=();
    my %PersonRegos = ();
    while (my $dref = $query->fetchrow_hashref()) {
        next if (defined $dref->{intSystemStatus} and $dref->{intSystemStatus} == $Defs::PERSONSTATUS_DELETED);
        next if (
            (
                $dref->{'PRStatus'} eq $Defs::PERSONREGO_STATUS_DELETED
                or $dref->{'PRStatus'} eq $Defs::PERSONREGO_STATUS_TRANSFERRED 
                or $dref->{'PRStatus'} eq $Defs::PERSONREGO_STATUS_INPROGRESS
                or $dref->{'PRStatus'} eq $Defs::PERSONREGO_STATUS_SUSPENDED
                or $dref->{'strStatus'} eq $Defs::PERSON_STATUS_DELETED
                or $dref->{'strStatus'} eq $Defs::PERSON_STATUS_SUSPENDED
            )
            and $Data->{'clientValues'}{'authLevel'} < $Defs::LEVEL_NATIONAL
        );

        $dref->{'PRStatus'} = $dref->{'PRActiveStatus'} if ($dref->{'PRActiveStatus'});
        $dref->{'PRStatus'} = ($dref->{'PRStatus'} eq $Defs::PERSONREGO_STATUS_ACTIVE and $dref->{'PRintPaymentRequired'}) ? $Defs::PERSONREGO_STATUS_ACTIVE_PENDING_PAYMENT : $Defs::PERSONREGO_STATUS_ACTIVE;

        $dref->{'PRStatus'} = $lang->txt('SUSPENDED') if ($dref->{'strStatus'} eq 'SUSPENDED');
        $dref->{'strStatus'} = $lang->txt($Defs::personStatus{$dref->{'strStatus'}}); ## Lets use PR status
        
        push @{$PersonRegos{$dref->{'intPersonID'}}}, {
            type => $dref->{'PRstrPersonType'},
            status => $dref->{'PRStatus'},
            subtype => $dref->{'PRstrPersonSubType'},
            level => $dref->{'PRstrPersonLevel'},
        };
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
        $dref->{'SelectLink'} = "$target?client=$tempClient&amp;a=$newaction";
        push @rowdata, $dref;
        $found++;
    }
    foreach my $row (@rowdata)  {
        my $id = $row->{'intPersonID'} || next;
        my %types = ();
        my %subtypes = ();
        my %levels = ();
        foreach my $reg (@{$PersonRegos{$id}}) {
            my $type = $reg->{'type'} || '';
            my $status = $reg->{'status'} || 'INACTIVE';
            my $subtype = $reg->{'subtype'} || '';
            my $level = $reg->{'level'} || '';
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
        } 
        my $types_str = '';
        for my $t (keys %types) {
            next if !$t;
            my $status = $types{$t} || 'INACTIVE';
            $types_str .= qq[<span class = "TYPE_STATUS_$status">].$lang->txt($Defs::personType{$t}).qq[</span> ];
        }
        my $subtypes_str = '';
        for my $st (keys %subtypes) {
            next if !$st;
            my $status = $subtypes{$st} || 'INACTIVE';
            $subtypes_str .= qq[<span class = "SUBTYPE_STATUS_$status">].$lang->txt($st).qq[</span> ];
        }
        my $levels_str = '';
        for my $l (keys %levels) {
            next if !$l;
            my $status = $levels{$l} || 'INACTIVE';
            $levels_str .= qq[<span class = "SUBTYPE_STATUS_$status">].$lang->txt($l).qq[</span> ];
        }
        $row->{'types'} = $types_str;
        $row->{'subtypes'} = $subtypes_str;
        $row->{'levels'} = $levels_str;
    }


    $title = $lang->txt("$Data->{'LevelNames'}{$Defs::LEVEL_PERSON.'_P'} in $Data->{'LevelNames'}{$type}");

    $resultHTML = runTemplate(
        $Data,
        {
            rowdata => \@rowdata,
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
