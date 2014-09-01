package EntityIdentifier;
require Exporter;
@ISA =  qw(Exporter);
@EXPORT = qw(handleEntityIdentifiers);
@EXPORT_OK = qw(handleEntityIdentifiers);

use strict;
use Reg_common;
use Utils;
use HTMLForm;
use AuditLog;
use CGI qw(unescape param);
use FormHelpers;
use GridDisplay;
use Log;
use EntityStructure;
use WorkFlow;

use RecordTypeFilter;
use RuleMatrix;
use Data::Dumper;

sub handleEntityIdentifiers{ 
    my($action, $Data, $clubID)=@_;

    my $resultHTML='';
    my $title='';
    if($action =~/^C_ID_LIST/) {
        #List Venues
        my $tempResultHTML = '';
        ($tempResultHTML,$title)=listEntityIdentifier($Data,$clubID);
        $resultHTML .= $tempResultHTML;
    }
        
    return ($resultHTML,$title);
}

sub listEntityIdentifier{
	my($Data,$clubID) = @_;

    my $resultHTML = '';
    my $client = unescape($Data->{client});

    my %tempClientValues = getClient($client);

    my $entityID = getID($Data->{'clientValues'});

    my $statement =qq[
      SELECT 
        EI.intIdentifierId,
        EI.intEntityID,
        EI.intRealmID,
        EI.intIdentifierTypeID,
        IT.strIdentifierName,
        EI.strIdentifier,
        DATE_FORMAT(EI.dtValidFrom,"%d/%m/%Y") as dtValidFrom,
        DATE_FORMAT(EI.dtValidUntil,"%d/%m/%Y") as dtValidUntil,
        EI.strDescription
      FROM tblEntityIdentifier AS EI 
        INNER JOIN tblIdentifierTypes as IT ON EI.intIdentifierTypeID=IT.intIdentifierTypeID
      WHERE IT.intActive = 1
        AND EI.intEntityID = ?
      ORDER BY EI.intIdentifierId
    ];
    
    my $query = $Data->{'db'}->prepare($statement);
    $query->execute($clubID);
    
    my $results=0;
    my @rowdata = ();
    while (my $dref = $query->fetchrow_hashref) {
      $results=1;
      push @rowdata, {
        id => $dref->{'intIdentifierId'},
        intEntityID => $dref->{'intEntityID'},
        intRealmID => $dref->{'intRealmID'},
        intIdentifierTypeID => $dref->{'intIdentifierTypeID'},
        strIdentifierName => $dref->{'strIdentifierName'},
        strIdentifier => $dref->{'strIdentifier'},
        dtValidFrom => $dref->{'dtValidFrom'},
        dtValidUntil => $dref->{'dtValidUntil'},
        strDescription => $dref->{'strDescription'},
        SelectLink => "$Data->{'target'}?client=$client&amp;a=C_ID_EDIT",
      };
    }
    $query->finish;
    my $addlink='';
    my $title=qq[Identifiers];
    {
        my $tempClient = setClient(\%tempClientValues);
        $addlink=qq[<span class = "button-small generic-button"><a href="$Data->{'target'}?client=$client&amp;a=C_ID_ADD">].$Data->{'lang'}->txt('Add').qq[</a></span>];

    }
    my $modoptions=qq[<div class="changeoptions">$addlink</div>];
    $title=$modoptions.$title;
    my $rectype_options=show_recordtypes(
        $Data, 
        $Data->{'lang'}->txt('Name'),
        '',
        \%Defs::entityStatus,
        { 'ALL' => $Data->{'lang'}->txt('All'), },
    ) || '';
    
    my @headers = (
        {
            type  => 'Selector',
            field => 'SelectLink',
        },
        {
            name  => $Data->{'lang'}->txt('Type'),
            field => 'strIdentifierName',
        },
        {
            name   => $Data->{'lang'}->txt('Identifier'),
            field  => 'strIdentifier'
        },
        {
            name   => $Data->{'lang'}->txt('Valid From'),
            field  => 'dtValidFrom'
        },
        {
            name   => $Data->{'lang'}->txt('Valid Until'),
            field  => 'dtValidUntil'
        },
        {
            name   => $Data->{'lang'}->txt('Description'),
            field  => 'strDescription'
        },
    );
    
    my $filterfields = [
        {
            field     => 'strIdentifier',
            elementID => 'id_textfilterfield',
            type      => 'regex',
        },
        {
            field     => 'strIdentifierName',
            elementID => 'dd_actstatus',
            allvalue  => 'ALL',
        },
    ];
    
    my $grid  = showGrid(
        Data    => $Data,
        columns => \@headers,
        rowdata => \@rowdata,
        gridid  => 'grid',
        width   => '99%',
        filters => $filterfields,
    );

    $resultHTML = qq[
        <div class="grid-filter-wrap">
            <div style="width:99%;">$rectype_options</div>
            $grid
        </div>
    ];

    return ($resultHTML,$title);
}
1;