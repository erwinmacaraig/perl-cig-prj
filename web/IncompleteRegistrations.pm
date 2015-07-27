package IncompleteRegistrations;
require Exporter;
@ISA    = qw(Exporter);
@EXPORT = @EXPORT_OK = qw(
    handleIncompleteRegistrations
    deleteRelatedRegistrationRecords
);

use strict;
use lib '.', '..';
use Defs;

use CGI qw(cookie unescape);

use GridDisplay;
use Reg_common;
use PersonUtils;
use Utils;

use Data::Dumper;

use JSON;
use FlashMessage;
use Switch;

sub handleIncompleteRegistrations  {
    my ($action, $Data, $entityID) = @_;

    my $resultHTML = '';
    my $personName = my $title = '';
    my $incompleteID = safe_param( 'irID', 'number' );

    my $lang = $Data->{'lang'};

    if ( $action eq 'INCOMPLPR_D')   {
        ($resultHTML , $title)= deleteIncompleteRegistrations( $Data, $entityID, $incompleteID) ;
        $action = 'INCOMPLPR_';

        $Data->{'RedirectTo'} = "$Defs::base_url/" . $Data->{'target'} . "?client=$Data->{'client'}&a=INCOMPLPR_";
    }
    if ( $action eq 'INCOMPLPR_')   {
        ($resultHTML , $title)= listIncompleteRegistrations( $Data, $entityID) ;
    }
    else    {
        print STDERR "Unknown action $action\n";
    }
    return ( $resultHTML, $title );
}

###### SUBS BELOW ######

sub listIncompleteRegistrations    {

    my ($Data, $entityID) = @_;
    
    my $lang = $Data->{'lang'};
    my $client = setClient( $Data->{'clientValues'} ) || '';

    my %RegFilters=();
    my $st = qq[
        SELECT
            RS.id,
            RS.parameters,
            RS.ts,
            pr.*,
            p.strLocalFirstname,
            p.strLocalSurname,
            p.strLatinFirstname,
            p.strLatinSurname,
            p.dtDOB,
            p.intGender,
            er.strEntityRoleName
        FROM
            tblRegoState AS RS
            INNER JOIN tblPerson as p ON (
                p.intPersonID = RS.entityID 
            )
            LEFT JOIN tblPersonRegistration_$Data->{'Realm'} AS pr ON (
                RS.regoID = pr.intPersonRegistrationID
                AND pr.intEntityID = RS.userEntityID
            )
            LEFT JOIN tblEntityTypeRoles as er ON (
                er.strEntityRoleKey = pr.strPersonEntityRole
                and er.strPersonType = pr.strPersonType
            )
        WHERE
            p.intRealmID = ?
            AND RS.regoType = 'PERSON'
            AND RS.userEntityID = ?
        ORDER BY
          pr.dtAdded DESC
    ];
    my $results=0;
    my @rowdata = ();
    my $query = $Data->{'db'}->prepare($st);
    $query->execute(
        $Data->{'Realm'},
        $entityID
    );
    while (my $dref = $query->fetchrow_hashref) {
        $results=1;
        my $localname = formatPersonName($Data, $dref->{'strLocalFirstname'}, $dref->{'strLocalSurname'}, $dref->{'intGender'});
        my $name = formatPersonName($Data, $dref->{'strLatinFirstname'}, $dref->{'strLatinSurname'}, $dref->{'intGender'});
        my $local_latin_name = $localname;
        $local_latin_name .= qq[ ($name)] if (($name and $name ne ', ') and $name ne ' ');

        my $delete = qq[
            <a href = "$Data->{'target'}?client=$client&amp;a=INCOMPLPR_D&amp;irID=$dref->{'id'}" class = "btn btn-inside-panels" onclick = "return confirm('].$lang->txt('Are you sure you want to delete this registration?').qq[');">].$lang->txt('Delete').qq[</a>
        ];

        my $resume = '';
        {
            my $postfields = '';
            my $pf = decode_json($dref->{'parameters'});
            my %resumeClient = getClient($pf->{'client'},1);
            $resumeClient{'authLevel'} = $Data->{'clientValues'}{'authLevel'};
            $resumeClient{'userID'} = $Data->{'clientValues'}{'userID'};
            my $resClient = setClient(\%resumeClient);
            $pf->{'client'}= $resClient;
            for my $k (keys \%{$pf})  {
                $postfields .= qq[<input type = "hidden" name = "$k" value = "$pf->{$k}">];

            }
            $resume = qq[
                <form action = "$Data->{'target'}" method = "POST">
                    <input type ="submit" value = "].$lang->txt('View & Resume').qq[" class = "btn btn-inside-panels">
                    $postfields
                </form>
            ];

        }
        if($Data->{'clientValues'}{'authLevel'} != $Data->{'clientValues'}{'currentLevel'})    {
            $resume = '';
            $delete = '';
        }
        
        push @rowdata, {
            id => $dref->{'intPersonRegistrationID'} || 0,
            dtAdded=> $Data->{'l10n'}{'date'}->TZformat($dref->{'ts'}|| '' , 'MEDIUM','SHORT'),
            dtAdded_RAW => $dref->{'ts'} || '',
            PersonLevel=> $Defs::personLevel{$dref->{'strPersonLevel'}} || '',
            PersonType=> $Defs::personType{$dref->{'strPersonType'}} || '',
            AgeLevel=> $Defs::ageLevel{$dref->{'strAgeLevel'}} || '',
            RegistrationNature=> $Defs::registrationNature{$dref->{'strRegistrationNature'}} || '',
            PersonEntityRole=> $dref->{'strEntityRoleName'} || $dref->{'strPersonEntityRole'} || '',
            Sport=> $Defs::sportType{$dref->{'strSport'}} || '',
            LocalName=>$localname,
            LatinName=>$name,
            resume =>$resume,
            delete =>$delete,
            LocalLatinName=>$local_latin_name,
          };
    }

    my @headers = (
        {
            name  => $Data->{'lang'}->txt('Person'),
            field => 'LocalLatinName',
            defaultShow => 1,
        },
        {
            name  => $Data->{'lang'}->txt('Type'),
            field => 'RegistrationNature',
            width  => 60,
            defaultShow => 1,
        },
        {
            name   => $Data->{'lang'}->txt('Type'),
            field  => 'PersonType',
            width  => 30,
        },
        {
            name   => $Data->{'lang'}->txt('Role'),
            field  => 'PersonEntityRole',
            width  => 30,
        },
        {
            name   => $Data->{'lang'}->txt('Sport'),
            field  => 'Sport',
            width  => 40,
        },
        {
            name  => $Data->{'lang'}->txt('Level'),
            field => 'PersonLevel',
            width  => 40,
        },
        {
            name  => $Data->{'lang'}->txt('Age Level'),
            field => 'AgeLevel',
            width  => 40,
        },
        {
            name  => $Data->{'lang'}->txt('Added'),
            field => 'dtAdded',
            sortdata => 'dtAdded_RAW',
        },
        {
            name => ' ',
            type  => 'HTML',
            field => 'resume',
            width  => 100,
            sortable => 0,
            defaultShow => 1,
        },
        {
            name => ' ',
            type  => 'HTML',
            field => 'delete',
            width  => 100,
            sortable => 0,
        },
    );

    $client=setClient($Data->{'clientValues'}) || '';
    my %tempClientValues = getClient($client);
    my @fielddata = ();
    my $tempaction;
    $st = qq[
        SELECT
            RS.id,
            RS.parameters,
            RS.ts,
            RS.regoType,
            tblEntity.intEntityLevel,
            tblEntity.intEntityID,
            tblEntity.strLocalName
        FROM
            tblRegoState AS RS
            INNER JOIN 
                tblEntity ON (RS.entityID = tblEntity.intEntityID)
        WHERE
            RS.regoType IN ('CLUB','VENUE')
            AND RS.userEntityID = ?
        ORDER BY
            RS.ts DESC
        ];
    $query = $Data->{db}->prepare($st);
    $query->execute( $entityID);
    while (my $dref = $query->fetchrow_hashref) {
        my $delete = qq[
            <a href = "$Data->{'target'}?client=$client&amp;a=INCOMPLPR_D&amp;irID=$dref->{'id'}" class = "btn btn-inside-panels" onclick = "return confirm('].$lang->txt('Are you sure you want to delete this registration?').qq[');">].$lang->txt('Delete').qq[</a>
        ];

        my $resume = '';
        {
            my $postfields = '';
            my $pf = decode_json($dref->{'parameters'});
            my %resumeClient = getClient($pf->{'client'},1);
            $resumeClient{'authLevel'} = $Data->{'clientValues'}{'authLevel'};
            $resumeClient{'userID'} = $Data->{'clientValues'}{'userID'};
            my $resClient = setClient(\%resumeClient);
            $pf->{'client'}= $resClient;
            for my $k (keys \%{$pf})  {
                $postfields .= qq[<input type = "hidden" name = "$k" value = "$pf->{$k}">];

            }
            $resume = qq[
                <form action = "$Data->{'target'}" method = "POST">
                    <input type ="submit" value = "].$lang->txt('View & Resume').qq[" class = "btn btn-inside-panels">
                    $postfields
                </form>
            ];

        }
        if($Data->{'clientValues'}{'authLevel'} != $Data->{'clientValues'}{'currentLevel'})    {
            $resume = '';
            $delete = '';
        }
    my $type = $dref->{'regoType'} eq 'VENUE'
            ? $Data->{'lang'}->txt('Venue')
            : $Data->{'lang'}->txt('Club');
        push @fielddata, {
            id => $dref->{intEntityID},
            dtAdded=> $Data->{'l10n'}{'date'}->TZformat($dref->{'ts'}|| '' , 'MEDIUM','SHORT'),
            dtAdded_RAW => $dref->{'ts'} || '',
            strLocalName => $dref->{strLocalName},
            regoType => $type,
            EntityLevel => $Defs::LevelNames{$dref->{intEntityLevel}},
            resume => $resume,
            delete => $delete,
       };
    }

    my @entityheadersgrid = (
        {
            name  => $Data->{'lang'}->txt('Name'),
            field => 'strLocalName',
            defaultShow => 1,
        },
        {
            name  => $Data->{'lang'}->txt('Type'),
            field => 'regoType',
            defaultShow => 1,
        },
        {
            name  => $Data->{'lang'}->txt('Added'),
            field => 'dtAdded',
            sortdata => 'dtAdded_RAW',
        },
        {
            name => ' ',
            type  => 'HTML',
            field => 'resume',
            width  => 100,
            sortable => 0,
            defaultShow => 1,
        },
        {
            name => ' ',
            type  => 'HTML',
            field => 'delete',
            width  => 100,
            sortable => 0,
        },
    );
   

    my $resultHTML = '';
    if(@rowdata){
        my $grid = showGrid(
            Data    => $Data,
            columns => \@headers,
            rowdata => \@rowdata,
            gridid  => 'grid',
            width   => '100%',
        ); 
        $resultHTML .=  qq[
            <h2 class = "section-header">].$lang->txt('Persons') .qq[</h2>
            <div style="clear:both">&nbsp;</div>
            <div class="clearfix">
                    $grid             
            </div>
        ];
    }
    if(@fielddata){
    	 my $grid2  = showGrid(
        Data    => $Data,
        columns => \@entityheadersgrid,
        rowdata => \@fielddata,   
        gridid  => 'grid2',     
        width   => '100%',
        
        );
        $resultHTML .= qq[
            <h2 class = "section-header">].$lang->txt('Clubs').'/'.$lang->txt('Venues') .qq[</h2>
            <div style="clear:both">&nbsp;</div>
            <div class="clearfix">
                    $grid2          
            </div>
        ];
    }
    if(! @rowdata and ! @fielddata){
    	$resultHTML = $lang->txt('No Incomplete Registrations');
    }
    my $title = $Data->{'lang'}->txt('Incomplete Registrations');
           

    my $flashMessage = getFlashMessage($Data, 'IR_FM');
    $resultHTML = $flashMessage . $resultHTML if($flashMessage);

    return ($resultHTML,$title);
}


sub deleteIncompleteRegistrations    {

    my ($Data, $entityID, $incompleteID) = @_;
    
    my $lang = $Data->{'lang'};
    my $client = setClient( $Data->{'clientValues'} ) || '';
    my %flashMessage;

    my $stateRegoRef = getRegoStateById($Data, $incompleteID);

    if($entityID != $stateRegoRef->{'userEntityID'} or !$stateRegoRef) {
        $flashMessage{'flash'}{'type'} = 'error';
        $flashMessage{'flash'}{'message'} = $lang->txt('Invalid ID');
        setFlashMessage($Data, 'IR_FM', \%flashMessage);

        return 0;
    }
    else {
    
        my $st = qq[
            DELETE FROM
                tblRegoState
            WHERE
                id = ?
                AND userEntityID = ?
            LIMIT 1
        ];
                #AND userID = ?
        my $query = $Data->{db}->prepare($st);
        my $userID = $Data->{'clientValues'}{'userID'} || 0;
        $query->execute( 
            $incompleteID,
            $entityID, 
        );

            #$userID,

        if($query->rows) {
            my $deletedRecords = deleteRelatedRegistrationRecords(
                $Data,
                $stateRegoRef->{'regoType'},
                $stateRegoRef->{'userEntityID'},
                $stateRegoRef->{'entityID'},
                $stateRegoRef->{'regoID'},
                $userID,
            );

            $flashMessage{'flash'}{'type'} = 'success';
            $flashMessage{'flash'}{'message'} = $lang->txt('Incomplete registration has been delete');
            setFlashMessage($Data, 'IR_FM', \%flashMessage);

            return 1;
        }
        else {
            $flashMessage{'flash'}{'type'} = 'error';
            $flashMessage{'flash'}{'message'} = $lang->txt('Invalid ID');
            setFlashMessage($Data, 'IR_FM', \%flashMessage);

            return 0;
        }

    }
}

sub deleteRelatedRegistrationRecords {
    my ($Data, $type, $userEntityID, $entityID, $regoID, $userID) = @_;

    switch($type) {
        case 'PERSON' {
            my $sdp = qq [
                DELETE
                    tp.*,
                    tpc.*,
                    td.*,
                    tuf.*
                FROM tblPerson tp
                LEFT JOIN tblPersonCertifications tpc ON (tpc.intPersonID = tp.intPersonID)
                LEFT JOIN tblDocuments td ON (td.intPersonID = tp.intPersonID)
                LEFT JOIN tblUploadedFiles tuf ON (tuf.intFileID = td.intUploadFileID)
                WHERE
                    tp.intPersonID = ?
                    AND tp.strStatus = 'INPROGRESS'
            ];
            my $query = $Data->{'db'}->prepare($sdp);
            $query->execute($entityID);
            $query->finish();

            if($regoID) {
                #join to other tables here: tblCertifications etc
                my $sdpr = qq [
                    DELETE FROM
                        tblPersonRegistration_$Data->{'Realm'}
                    WHERE
                        intPersonID = ?
                        AND intPersonRegistrationID = ?
                        AND strStatus = 'INPROGRESS'
                ];

                $query = $Data->{'db'}->prepare($sdpr);
                $query->execute(
                    $entityID,
                    $regoID
                );
                $query->finish();
            }
        }
        case ['CLUB', 'VENUE'] {
            my $id = $entityID,
            my $st = qq[
                DELETE
                    te.*,
                    tef.*,
                    td.*,
                    tuf.*
                FROM tblEntity te
                LEFT JOIN tblEntityFields tef ON (tef.intEntityID = te.intEntityID)
                LEFT JOIN tblDocuments td ON (td.intEntityID = te.intEntityID AND td.intEntityLevel = te.intEntityLevel AND td.intPersonID = 0 AND td.intPersonRegistrationID = 0)
                LEFT JOIN tblUploadedFiles tuf ON (tuf.intFileID = td.intUploadFileID)
                WHERE
                    te.intEntityID = ?
                    AND te.strStatus = 'INPROGRESS'
            ];
            my $query = $Data->{'db'}->prepare($st);
            $query->execute($entityID);
            $query->finish();
        }
    }

    return 1;
}

sub getRegoStateById {
    my ($Data, $stateID) = @_;

    my $st = qq[
        SELECT
            id,
            userEntityID,
            regoType,
            entityID,
            regoID
        FROM
            tblRegoState
        WHERE
            id = ?
        LIMIT 1
    ];

    my $query = $Data->{db}->prepare($st);
    $query->execute($stateID) or query_error($st);

    return $query->fetchrow_hashref;
}

1;
