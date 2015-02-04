package IncompleteRegistrations;
require Exporter;
@ISA    = qw(Exporter);
@EXPORT = @EXPORT_OK = qw(
    handleIncompleteRegistrations
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

sub handleIncompleteRegistrations  {
    my ($action, $Data, $entityID) = @_;

    my $resultHTML = '';
    my $personName = my $title = '';
    my $incompleteID = safe_param( 'irID', 'number' );

    my $lang = $Data->{'lang'};

    if ( $action eq 'INCOMPLPR_D')   {
        ($resultHTML , $title)= deleteIncompleteRegistrations( $Data, $entityID, $incompleteID) ;
        $action = 'INCOMPLPR_';
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
            pr.*,
            IF(pr.strStatus != 'ACTIVE', pr.strStatus, IF(pr.strStatus = 'ACTIVE' AND pr.intPaymentRequired = 1, 'ACTIVE_INCOMPLING_PAYMENT', pr.strStatus)) AS displayStatus,
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
        GROUP BY 
            pr.intPersonRegistrationID
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
        $local_latin_name .= qq[ ($name)] if ($name and $name ne ' ');

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
                    <input type ="submit" value = "].$lang->txt('Resume').qq[" class = "btn btn-inside-panels">
                    $postfields
                </form>
            ];

        }
        
        push @rowdata, {
            id => $dref->{'intPersonRegistrationID'} || 0,
            dtAdded=> $Data->{'l10n'}{'date'}->TZformat($dref->{'dtAdded'}|| '' , 'MEDIUM','SHORT'),
            dtAdded_RAW => $dref->{'dtAdded'} || '',
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
        },
        {
            name  => $Data->{'lang'}->txt('Type'),
            field => 'RegistrationNature',
            width  => 60,
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
            width  => 50,
        },
        {
            name => ' ',
            type  => 'HTML',
            field => 'resume',
            width  => 100,
            sortable => 0,
        },
        {
            name => ' ',
            type  => 'HTML',
            field => 'delete',
            width  => 100,
            sortable => 0,
        },
    );

    my $filterfields = [
        {
            field     => 'strLocalName',
            elementID => 'id_textfilterfield',
            type      => 'regex',
        },
        {
            field     => 'strStatus',
            elementID => 'dd_actstatus',
            allvalue  => 'ALL',
        },
    ];   
    $client=setClient($Data->{'clientValues'}) || '';
    my %tempClientValues = getClient($client);
    my @fielddata = ();
    my $tempaction;
    $st = qq[
        SELECT
            intEntityLevel,
            IF(strStatus != 'ACTIVE', strStatus, IF(strStatus = 'ACTIVE' AND intPaymentRequired = 1, 'ACTIVE_INCOMPLING_PAYMENT', strStatus)) AS displayStatus,
            intEntityID,
            strLocalName,
            strStatus
        FROM
            tblEntity
        INNER JOIN
            tblEntityLinks ON (tblEntity.intEntityID = tblEntityLinks.intChildEntityID)
        WHERE
            intParentEntityID = ?
            AND intRealmID = ?
            AND (strStatus IN ('INCOMPLING') OR (strStatus IN ('ACTIVE') AND intPaymentRequired = 1))
        ORDER BY
            intEntityLevel, strLocalName ASC 
        ];
    $query = $Data->{db}->prepare($st);
    $query->execute( $entityID, $Data->{Realm} );
    while (my $dref = $query->fetchrow_hashref) {
        print STDERR Dumper $dref;
        $tempClientValues{currentLevel} = $dref->{intEntityLevel};
        setClientValue(\%tempClientValues, $dref->{intEntityLevel}, $dref->{intEntityID});
        my $tempClient = setClient(\%tempClientValues);
        		$tempaction = "$Data->{'target'}?client=$client&amp;a=VENUE_DTE&amp;venueID=".$dref->{intEntityID};
        push @fielddata, {
            id => $dref->{intEntityID},
            SelectLink => "$tempaction",
            strLocalName => $dref->{strLocalName},
            EntityLevel => $Defs::LevelNames{$dref->{intEntityLevel}},
            strStatus => $dref->{strStatus}, 
            displayStatus => $Defs::personRegoStatus{$dref->{displayStatus}},
       };
    }

    my @entityheadersgrid = (
        {
            name  => $Data->{'lang'}->txt('Name'),
            field => 'strLocalName',
            width  => 60,
        },
        {
            name  => $Data->{'lang'}->txt('Level'),
            field => 'EntityLevel',
            width  => 60,
        },
        {
            name   => $Data->{'lang'}->txt('Status'),
            #field  => 'strStatus',
            field  => 'displayStatus',
            width  => 30,
        },
        {
            type  => 'Selector',
            field => 'SelectLink',
            width  => 30,
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
            filters => $filterfields,
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
           
    return ($resultHTML,$title);
}


sub deleteIncompleteRegistrations    {

    my ($Data, $entityID, $incompleteID) = @_;
    
    my $lang = $Data->{'lang'};
    my $client = setClient( $Data->{'clientValues'} ) || '';

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
    return 1;
}


1;
