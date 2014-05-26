#
# $Header: svn://svn/SWM/trunk/web/Node.pm 10895 2014-03-06 03:07:13Z dhanslow $
#

package Node;
require Exporter;
@ISA = qw(Exporter);
@EXPORT=qw(handleNode);
@EXPORT_OK=qw(handleNode);

use strict;
use Reg_common;
use Utils;
use HTMLForm;
use AuditLog;
use Logo;
use GridDisplay;
use ListAssocs;
use HomeNode;


sub handleNode	{
	my ($action, $Data, $nodeID, $typeID)=@_;

	my $resultHTML='';
	my $nodeName=
	my $title='';
	if ($action =~/^N_DT/) {
		#Node Details
			($resultHTML,$title)=node_details($action, $Data, $nodeID, $typeID);
	}
	elsif ($action =~/N_CFG_/) {
		#Node Configuration
	}
	elsif ($action eq 'N_L') {
		#List Node Children
			($resultHTML,$title)=listNodes($Data, $nodeID, $typeID);
	}
	elsif ($action eq 'N_HOME') {
			($resultHTML,$title)=showNodeHome($Data, $nodeID);
	}
	elsif ($action eq 'N_S') {
		#List Node Stats
	}


	return ($resultHTML,$title);
}


sub node_details	{
	my ($action, $Data, $nodeID, $typeID)=@_;

	my $field=loadNodeDetails($Data->{'db'}, $nodeID) || ();
	my $option='display';
	$option='edit' if $action eq 'N_DTE' and $Data->{'clientValues'}{'authLevel'} >= $typeID;
	
	my $client=setClient($Data->{'clientValues'}) || '';
	my %FieldDefinitions=(
		fields=>	{
			strName => {
				label => 'Name',
				value => $field->{strName},
				type  => 'text',
				size  => '40',
				maxsize => '150',
        readonly =>1,
			},
			strNameAbbrev => {
				label => 'Abbreviation',
				value => $field->{strNameAbbrev},
				type  => 'text',
				size  => '30',
				maxsize => '50',
			},
			strContact => {
				label => 'Contact Person',
				value => $field->{strContact},
				type  => 'text',
				size  => '30',
				maxsize => '50',
			},
			strAddress1 => {
				label => 'Address Line 1',
				value => $field->{strAddress1},
				type  => 'text',
				size  => '30',
				maxsize => '50',
			},
			strAddress2 => {
				label => 'Address Line 2',
				value => $field->{strAddress2},
				type  => 'text',
				size  => '30',
				maxsize => '50',
			},
			strSuburb => {
				label => 'Suburb',
				value => $field->{strSuburb},
				type  => 'text',
				size  => '30',
				maxsize => '50',
			},
			strState => {
				label => 'State',
				value => $field->{strState},
				type  => 'text',
				size  => '30',
				maxsize => '50',
			},
			strCountry => {
				label => 'Country',
				value => $field->{strCountry},
				type  => 'text',
				size  => '30',
				maxsize => '50',
			},
			strPostalCode => {
				label => 'Postal Code',
				value => $field->{strPostalCode},
				type  => 'text',
				size  => '15',
				maxsize => '15',
			},
			strPhone => {
				label => 'Phone',
				value => $field->{strPhone},
				type  => 'text',
				size  => '20',
				maxsize => '20',
			},
			strFax => {
				label => 'Fax',
				value => $field->{strFax},
				type  => 'text',
				size  => '20',
				maxsize => '20',
			},
			strEmail => {
				label => 'Email',
				value => $field->{strEmail},
				type  => 'text',
				size  => '35',
				maxsize => '250',
				validate => 'EMAIL',
			},
			intEstParticipants => {
				label =>  $typeID == $Defs::LEVEL_NATIONAL ? 'Estimated Participants': '',
				type => 'text',
				size  => '10',
				value => $field->{'intEstParticipants'},
				validate => 'NUMBER',
			},
			intEstRegPlayers=> {
				label => $typeID == $Defs::LEVEL_NATIONAL ? 'Estimated Registered Players' : '',
				type => 'text',
				size  => '10',
				value => $field->{'intEstRegPlayers'},
				validate => 'NUMBER',
			},
			intEstUnRegPlayers=> {
				label => $typeID == $Defs::LEVEL_NATIONAL ? 'Estimated Un-Registered Players' : '',
				type => 'text',
				size  => '10',
				value => $field->{'intEstUnRegPlayers'},
				validate => 'NUMBER',
			},
			strNotes => {
				label => 'Notes',
				value => $field->{strNotes},
				type => 'textarea',
				rows => '10',
				cols => '40',
			},
			SP1	=> {
				type =>'_SPACE_',
			},
		},
		order => [qw(strName strNameAbbrev strContact strAddress1 strAddress2 strSuburb strState strCountry strPostalCode strPhone strFax SP1 strEmail SP1 intEstParticipants intEstRegPlayers intEstUnRegPlayers strNotes)],
		options => {
			labelsuffix => ':',
			hideblank => 1,
			target => $Data->{'target'},
			formname => 'n_form',
      submitlabel => $Data->{'lang'}->txt('Update'),
      introtext => $Data->{'lang'}->txt('HTMLFORM_INTROTEXT'),
			NoHTML => 1, 
			updateSQL => qq[
        UPDATE tblNode
          SET --VAL--
        WHERE intNodeID=$nodeID
				],
			auditFunction=> \&auditLog,
      auditAddParams => [
        $Data,
        'Add',
        'Node'
      ],
      auditEditParams => [
        $nodeID,
        $Data,
        'Update',
        'Node'
      ],
      afterupdateFunction => \&postNodeUpdate,
      afterupdateParams => [$option,$Data,$Data->{'db'}, $nodeID],

      LocaleMakeText => $Data->{'lang'},
		},
		carryfields =>	{
			client => $client,
			a=> $action,
		},
	);
	my $resultHTML='';
	($resultHTML, undef )=handleHTMLForm(\%FieldDefinitions, undef, $option, '',$Data->{'db'});
	my $title=$field->{strName};
	my $logodisplay = '';
  if($option eq 'display')  {
    my $chgoptions='';
    $chgoptions.=qq[<div style="float:right;"><a href="$Data->{'target'}?client=$client&amp;a=N_DTE"><img src="images/edit_icon.gif" border="0" alt="Edit"></a></div> ] if($Data->{'clientValues'}{'authLevel'} >= $typeID and allowedAction($Data, 'n_e'));
    $resultHTML=$resultHTML;
		$title=$chgoptions.$title;
    my $editlink = allowedAction($Data, 'n_e') ? 1 : 0;
    $logodisplay = showLogo(
      $Data,
      $typeID,
      $nodeID,
      $client,
      $editlink,
    );
  }

	$resultHTML = $logodisplay. $resultHTML;

	return ($resultHTML,$title);
}


sub loadNodeDetails {
  my($db, $id) = @_;
                                                                                                        
  my $statement=qq[
    SELECT intNodeID, intTypeID, intStatusID, strName, strNameAbbrev, strContact, strAddress1, strAddress2, strSuburb, strState, strCountry, strPostalCode, strPhone, strFax, strEmail, strNotes, intEstParticipants ,intEstRegPlayers, intEstUnRegPlayers 
    FROM tblNode
    WHERE intNodeID=$id
  ];
  my $query = $db->prepare($statement);
  $query->execute;
	my $field=$query->fetchrow_hashref();
  $query->finish;
                                                                                                        
  foreach my $key (keys %{$field})  { if(!defined $field->{$key}) {$field->{$key}='';} }
  return $field;
}

sub postNodeUpdate {
  my($id,$params,$action,$Data,$db, $nodeID)=@_;
  return undef if !$db;
  $nodeID ||= $id || 0;

  $Data->{'cache'}->delete('swm',"NodeObj-$nodeID") if $Data->{'cache'};

}


sub listNodes {
  my($Data, $nodeID, $typeID) = @_;

  my $db=$Data->{'db'};
	my $resultHTML = '';

	my $lang = $Data->{'lang'};
	my %textLabels = (
			'contact' => $lang->txt('Contact'),
			'email' => $lang->txt('Email'),
			'name' => $lang->txt('Name'),
			'phone' => $lang->txt('Phone'),
	);

  my $foundlevel=0;
  my $found = 0;
  my $client=setClient($Data->{'clientValues'});
  my %tempClientValues = getClient($client);
  my $currentname='';
  my $newtypeID=$typeID;
  my $lastnodeID=0;
  my $lastlevelID=0;
	my @rowdata = ();
  while(!$foundlevel)	{
		@rowdata = ();
    my $statement =qq[
      SELECT 
				PN.intNodeID AS PNintNodeID, 
				CN.strName, 
				CN.strContact, 
				CN.strPhone, 
				CN.strEmail, 
				CN.intNodeID AS CNintNodeID, 
				CN.intTypeID AS CNintTypeID, 
				PN.strName AS PNName, 
				CN.intStatusID
      FROM tblNode AS PN 
				LEFT JOIN tblNodeLinks ON PN.intNodeID=tblNodeLinks.intParentNodeID 
				JOIN tblNode as CN ON CN.intNodeID=tblNodeLinks.intChildNodeID
      WHERE PN.intNodeID = ?
        AND CN.intStatusID <> $Defs::RECSTATUS_DELETED
        AND CN.intDataAccess>$Defs::DATA_ACCESS_NONE
      ORDER BY CN.strName
    ];
    my $query = $db->prepare($statement);
    $query->execute($nodeID);
    my $results=0;
    $found=0;
    while (my $dref = $query->fetchrow_hashref) {
      $results=1;
      $currentname||=$dref->{PNName};
      if($dref->{CNintNodeID} and $dref->{intStatusID} == $Defs::NODE_HIDE) {
        $nodeID=$dref->{CNintNodeID}||0;
        $lastnodeID=$nodeID if $nodeID;
        $lastlevelID =$dref->{CNintTypeID} if $dref->{CNintTypeID} > 0;
        last;
      }
      else  {
        $tempClientValues{currentLevel} = $dref->{CNintTypeID};
        setClientValue(\%tempClientValues, $dref->{CNintTypeID}, $dref->{CNintNodeID});
        my $tempClient = setClient(\%tempClientValues);
        my $action=$Data->{'SystemConfig'}{'DefaultListAction'} || 'HOME';
        $action = 'L' if ($action eq 'SUMM');

				push @rowdata, {
					id => $dref->{'CNintNodeID'} || 0,
					strName => $dref->{'strName'} || '',
					SelectLink => "$Data->{'target'}?client=$tempClient&amp;a=N_$action",
					strContact => $dref->{'strContact'} || '',
					strPhone => $dref->{'strPhone'} || '',
					strEmail => $dref->{'strEmail'} || '',
				};
        $found++;
        $foundlevel=1;
        $newtypeID=$dref->{CNintTypeID};
      }
    }
    $query->finish;
    $foundlevel=1 if !$results; #Stop looping if no children;
  }

  if (!$found) {
    $lastnodeID||=$nodeID;
    $lastlevelID||=$typeID;
    my($r, $t)=listAssocs($Data, $lastnodeID, $lastlevelID, $currentname,1);
    return ($r,$t);
  }
	my $list_instruction= $Data->{'SystemConfig'}{"ListInstruction_$newtypeID"} ? qq[<div class="listinstruction">$Data->{'SystemConfig'}{"ListInstruction_$newtypeID"}</div>] : '';
	$list_instruction=eval($list_instruction) if $list_instruction;

  my @headers = (
    {
      type => 'Selector',
      field => 'SelectLink',
    },
    {
      name =>   $Data->{'lang'}->txt('Name'),
      field =>  'strName',
    },
	);
	
	if(!$Data->{'SystemConfig'}{'NoListDetails'})	{
    push @headers, {
      name =>   $Data->{'lang'}->txt('Contact'),
      field =>  'strContact',
    };
    push @headers, {
      name =>   $Data->{'lang'}->txt('Phone'),
      field =>  'strPhone',
    };
    push @headers, {
      name =>   $Data->{'lang'}->txt('Email'),
      field =>  'strEmail',
    };
	}
  my $grid  = showGrid(
    Data => $Data,
    columns => \@headers,
    rowdata => \@rowdata,
    gridid => 'grid',
    width => '99%',
  );

	$resultHTML = qq[ 
		$list_instruction
		$grid
	];

  my $title=$Data->{'SystemConfig'}{"PageTitle_List_$newtypeID"} 
		|| "$Data->{'LevelNames'}{$newtypeID.'_P'} in $currentname"; ###needs translation ->  WHAT in WHAT? 
  return ($resultHTML,$title);
}

1;


