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
use Authorize;
use FieldLabels;

sub handleEntityIdentifiers{ 
    my($action, $Data)=@_;

    my $resultHTML='';
    my $title='';
    if ($action =~/^C_ID_DT/) {
        ($resultHTML,$title)=provision($action, $Data);
    }
    elsif($action =~/^C_ID_LIST/) {
        #List Venues
        my $tempResultHTML = '';
        ($tempResultHTML,$title)=list($Data);
        $resultHTML .= $tempResultHTML;
    }
        
    return ($resultHTML,$title);
}

sub provision{
    my ($action, $Data)=@_;
    my $id= param('intIdentifierId') || 0;
    my $FieldLabels   = FieldLabels::getFieldLabels( $Data, $Defs::LEVEL_CLUB );
    
    my $entityID = getID($Data->{'clientValues'});
    return '' if ($id and !entityAllowed($Data, $entityID,$Defs::LEVEL_CLUB));
    my $option='display';
    $option='edit' if $action eq 'C_ID_DTE';
    $option='add' if $action eq 'C_ID_DTA';
    $option='del' if $action eq 'C_ID_DTD';
    $id=0 if $option eq 'add';
    
    
    my $client = unescape($Data->{client});
    if($option eq 'del'){
      my $st=qq[
         UPDATE tblEntityIdentifier
           SET intStatus = 0
          WHERE intIdentifierId=?
          ];
       my $query = $Data->{'db'}->prepare($st);
       $query->execute($id);
       $query->finish;
       my $cgi = new CGI;
       print $cgi->header(-location => qq[$Data->{'target'}?client=$client&amp;a=C_ID_LIST]);
    }
    my %tempClientValues = getClient($client);
    
    my $intRealmID = $Data->{'Realm'} ? $Data->{'Realm'} : 0;
    my $field=loadDetails($Data->{'db'}, $id) || ();
    
    my $st=qq[
        SELECT 
            DISTINCT
            intIdentifierTypeID as Value,
            strIdentifierName as Name
        FROM
            tblIdentifierTypes
        WHERE 
            intActive = 1 AND
            intRealmID = $intRealmID
        ORDER BY
            strIdentifierName
    ];
    my ($contacts_vals,$contacts_order)=getDBdrop_down_Ref($Data->{'db'},$st,'');
    
    my %FieldDefinitions = (
      fields=>  {
       intIdentifierTypeID => {
          label       => $FieldLabels->{'intIdentifierTypeID'},
          value       => $field->{intIdentifierTypeID},
          type        => 'lookup',
          options     => $contacts_vals,
          sectionname => 'details',
          firstoption => [ '', 'Select Types' ],
        },
        strIdentifier => {
          label => $FieldLabels->{'strIdentifier'},
          value => $field->{strIdentifier},
          type  => 'text',
          size  => '35',
          maxsize => '250',
          sectionname => 'details',
        },
        dtValidFrom=> {
          label       => $FieldLabels->{'dtValidFrom'},
          value       => $field->{dtValidFrom},
          type        => 'date',
          datetype    => 'dropdown',
          format      => 'dd/mm/yyyy',
          sectionname => 'details',
          validate    => 'DATE',
        },
        dtValidUntil=> {
          label       => $FieldLabels->{'dtValidUntil'},
          value       => $field->{dtValidUntil},
          type        => 'date',
          datetype    => 'dropdown',
          format      => 'dd/mm/yyyy',
          sectionname => 'details',
          validate    => 'DATE',
        },
        strDescription => {
           label => $FieldLabels->{'strDescription'},
           value => $field->{strDescription},
           type => 'textarea',
           rows => '10',
           cols => '40',
           sectionname => 'details',
        },
      },
     order => [qw(
        intIdentifierTypeID
        strIdentifier
        dtValidFrom
        dtValidUntil
        strDescription
        
      )],
      sections => [ 
        [ 'details', "Identifier Details" ], 
    ],
    options => {
      labelsuffix => ':',
      hideblank => 1,
      target => $Data->{'target'},
      formname => 'n_form',
      submitlabel => $Data->{'lang'}->txt('Update'),
      introtext => $Data->{'lang'}->txt('HTMLFORM_INTROTEXT'),
      NoHTML => 1, 
      updateSQL => qq[
          UPDATE tblEntityIdentifier
            SET --VAL--
          WHERE intIdentifierId=$id
      ],
      addSQL => qq[
          INSERT INTO tblEntityIdentifier (
              intEntityID, 
              intRealmID, 
              --FIELDS-- 
          )
          VALUES (
              $entityID,
              $intRealmID,
              --VAL-- 
          )
      ],
      auditFunction=> \&auditLog,
      auditAddParams => [
        $Data,
        'Add',
        'Entity Identifier'
      ],
      auditEditParams => [
        $id,
        $Data,
        'Update',
        'Entity Identifier'
      ],

      afteraddFunction => \&postAdd,
      afteraddParams => [$option,$Data,$Data->{'db'}],
      afterupdateFunction => \&postUpdate,
      afterupdateParams => [$option,$Data,$Data->{'db'}, $id],

      LocaleMakeText => $Data->{'lang'},
    },
    carryfields =>  {
      client => $client,
      a=> $action,
      intIdentifierId=> $id,
    },
    );
    my $resultHTML='';
    ($resultHTML, undef )=handleHTMLForm(\%FieldDefinitions, undef, $option, '',$Data->{'db'});
    my $title=qq[Entity- Idetifier];

    my $chgoptions='';
    if($option eq 'display')  {
        # Edit Venue.
        $chgoptions.=qq[<span class = "button-small generic-button"><a href="$Data->{'target'}?client=$client&amp;a=C_ID_DTE&amp;intIdentifierId=$id">].$Data->{'lang'}->txt('Edit Venue').qq[</a></span> ];
    }
    elsif ($option eq 'edit') {
        $chgoptions.=qq[<span class = "button-small generic-button"><a href="$Data->{'target'}?client=$client&amp;a=C_ID_DTD&amp;intIdentifierId=$id" onclick="return confirm('Are you sure you want to delete this Identifer');">Delete Identifier</a> ];
    }
    $chgoptions=qq[<div class="changeoptions">$chgoptions</div>] if $chgoptions;
    $title=$chgoptions.$title;
    
    $title="Add New Identifier" if $option eq 'add';
     my $text = qq[<p style = "clear:both;"><a href="$Data->{'target'}?client=$client&amp;a=C_ID_LIST">Click here</a> to return to list of Identifer</p>];
    $resultHTML = $text.$resultHTML.$text;
    return ($resultHTML,$title);
}

sub postAdd{

    my($id,$params,$action,$Data,$db)=@_;
    return undef if !$db;
    if($action eq 'add')  {
       my $cl=setClient($Data->{'clientValues'}) || '';
       my %cv=getClient($cl);
       my $clm=setClient(\%cv);
       return (0,qq[
         <div class="OKmsg"> Identifier Added Successfully</div><br>
         <a href="$Data->{'target'}?client=$cl&amp;intIdentifierId=$id&amp;a=C_ID_DTE">Display Details</a><br><br>
         <b>or</b><br><br>
         <a href="$Data->{'target'}?client=$cl&amp;a=C_ID_DTA">Add another Identifier</a>

        ]);
    }
}

sub postUpdate {
  my($id,$params,$action,$Data,$db, $entityID)=@_;
  return undef if !$db;
  $entityID ||= $id || 0;

}

sub loadDetails {
  my($db, $id) = @_;
                                                                                                        
  my $statement=qq[
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
        AND EI.intIdentifierId = ?
  ];
  my $query = $db->prepare($statement);
  $query->execute($id);
  my $field=$query->fetchrow_hashref();
  $query->finish;
                                                                                                        
  foreach my $key (keys %{$field})  { if(!defined $field->{$key}) {$field->{$key}='';} }
  return $field;
}

sub list{
	my($Data) = @_;

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
        AND EI.intStatus = 0
        AND EI.intEntityID = ?
      ORDER BY EI.intIdentifierId
    ];
    
    my $query = $Data->{'db'}->prepare($statement);
    $query->execute($entityID);
    
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
        SelectLink => "$Data->{'target'}?client=$client&amp;a=C_ID_DTE&amp;intIdentifierId=$dref->{'intIdentifierId'}",
      };
    }
    $query->finish;
    my $addlink='';
    my $title=qq[Identifiers];
    {
        my $tempClient = setClient(\%tempClientValues);
        $addlink=qq[<span class = "button-small generic-button"><a href="$Data->{'target'}?client=$client&amp;a=C_ID_DTA">].$Data->{'lang'}->txt('Add').qq[</a></span>];

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