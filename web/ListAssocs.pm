#
# $Header: svn://svn/SWM/trunk/web/ListAssocs.pm 8251 2013-04-08 09:00:53Z rlee $
#

package ListAssocs;

require Exporter;
@ISA =  qw(Exporter);
@EXPORT = qw(listAssocs);
@EXPORT_OK = qw(listAssocs);

use strict;
use lib '.', "..";
use Defs;
use Reg_common;
use Utils;
use RecordTypeFilter;
use GridDisplay;

sub listAssocs {
  my(
		$Data, 
		$nodeID, 
		$level, 
		$headingname, 
		$fromlistnode, 
		$action
	) = @_;

	$fromlistnode||=0;
	my $typeID=$Defs::LEVEL_ASSOC;
	my $db=$Data->{'db'};
	my $resultHTML = '';
	my $client = $Data->{client};

	my $lang = $Data->{'lang'};

	my $assocRecStatus = !$Data->{'SystemConfig'}{'AllowStatusChange'} 
		? qq[AND tblAssoc.intRecStatus = $Defs::RECSTATUS_ACTIVE] 
		: '';
	if ($action eq "A_Lu") {
		update_checkboxes($Data, $Defs::LEVEL_ASSOC);
		$action = "A_L";
    auditLog(getID($Data->{'clientValues'}) || 0, $Data, 'Update', 'Assoc Status');
	} 
	my $orignodeID=$nodeID;
	my $orignodename='';
	my $currentlevel=$Data->{'clientValues'}{'currentLevel'};
	$currentlevel=$level if($level and $level >0 and $fromlistnode);
	if($currentlevel != $Defs::LEVEL_ZONE and $currentlevel >= $Defs::LEVEL_ASSOC)	{
		#Associations can only be part of a zone.  This current Node isn't a zone.
		# We will have to traverse down the tree to find a zone - and from there
		# look for associations.
		$nodeID=find_zone($Data,$nodeID);
		if($nodeID != $orignodeID)	{
			my $st=qq[SELECT strName FROM tblNode WHERE intNodeID=?];
			my $query = $db->prepare($st);
			$query->execute($orignodeID);
			($orignodename)=$query->fetchrow_array() || '';
			$query->finish();
		}
	}
	$orignodename=$headingname if $headingname;
	my $statement =qq[
		SELECT 
			tblAssoc.intAssocID, 
			tblAssoc.strName, 
			tblAssoc.strContact, 
			tblAssoc.strPhone, 
			tblAssoc.strEmail, 
			tblNode.strName AS NodeName, 
			tblAssoc.intRecStatus,
			CONCAT(CON.strContactFirstname, ' ', CON.strContactSurname) AS DefContact
		FROM tblAssoc 
			JOIN tblAssoc_Node ON tblAssoc.intAssocID = tblAssoc_Node.intAssocID 
			JOIN tblNode ON tblNode.intNodeID=tblAssoc_Node.intNodeID
			LEFT JOIN tblContacts AS CON ON (
				CON.intClubID = 0
				AND CON.intAssocID = tblAssoc.intAssocID
				AND CON.intPrimaryContact = 1
			)

		WHERE tblAssoc_Node.intNodeID = ?
		 	AND tblAssoc.intRecStatus <> $Defs::RECSTATUS_DELETED
			$assocRecStatus
		ORDER BY tblAssoc_Node.intSortOrder, tblAssoc.strName
	];
	my $query = $db->prepare($statement);
	$query->execute($nodeID);
	my $allowedits = 0;
	if(
		$Data->{'SystemConfig'}{'AllowStatusChange'} 
		and allowedAction($Data, 'a_a')
	) {
		$allowedits = 1;
	}
my $rectype_options = '';
my $filterfields = [];
if($Data->{'SystemConfig'}{'AllowStatusChange'}) {
 	$rectype_options = show_recordtypes($Data, $Defs::LEVEL_ASSOC,0,undef,'Name');
  	$filterfields = [
  	{
  	field => 'strName',
      	elementID => 'id_textfilterfield',
      	type => 'regex',
    	},
    	{
      	field => 'intRecStatus',
      	elementID => 'dd_actstatus',
      	allvalue => '2',
    	},
      ];
}

	my $found = 0;
	$client=setClient($Data->{'clientValues'});
	my %tempClientValues = getClient($client);
	my $currentname='';
	my @rowdata = ();
 	while (my $dref = $query->fetchrow_hashref) {
		$dref->{'DefContact'} ||= $dref->{'strContact'} || '';
		$currentname||=$dref->{NodeName};
		$tempClientValues{currentLevel} = $typeID;
		setClientValue(\%tempClientValues, $typeID, $dref->{intAssocID});
		my $tempClient = setClient(\%tempClientValues);
		my $laction=$Data->{'SystemConfig'}{'DefaultListAction'} || 'HOME';
		if($laction eq 'L')	{$laction='M_L';}
		else	{$laction='A_'.$laction;}

		push @rowdata, {
			id => $dref->{'intAssocID'} || next,
			strName => $dref->{'strName'},
			DefContact => $dref->{'DefContact'},
			strPhone => $dref->{'strPhone'},
			strEmail => $dref->{'strEmail'},
			intRecStatus => $dref->{'intRecStatus'},
			SelectLink => "$Data->{'target'}?client=$tempClient&amp;a=$laction",
		};
		$found++;
	}

	my $title=$Data->{'SystemConfig'}{"PageTitle_List_$typeID"} 
		|| "$Data->{'LevelNames'}{$typeID.'_P'} - $currentname";


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
  if(!$Data->{'SystemConfig'}{'NoListDetails'}) {
    push @headers, {
      name =>   $Data->{'lang'}->txt('Contact'),
      field =>  'DefContact',
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
	if($Data->{'SystemConfig'}{'AllowStatusChange'})	{
    push @headers, {
      name =>   $Data->{'lang'}->txt('Active?'),
      field =>  'intRecStatus',
			type => 'tick',
			editor => 'checkbox',
			width => 20,
    };
	}

	my $list_instruction= $Data->{'SystemConfig'}{"ListInstruction_$Defs::LEVEL_ASSOC"} 
		? qq[<div class="listinstruction">$Data->{'SystemConfig'}{"ListInstruction_$Defs::LEVEL_ASSOC"}</div>] 
		: '';


  my $grid  = showGrid(
    Data => $Data,
    columns => \@headers,
    rowdata => \@rowdata,
		filters => $filterfields,
    gridid => 'grid',
    width => '99%',
    height => 700,
		client => $client,
    saveurl => 'ajax/aj_grid_update.cgi',
    ajax_keyfield => 'intAssocID',
		saveaction => 'edit_stat_assoc',
  );

	$resultHTML = qq[
		$list_instruction
		<div style="width:99%;">$rectype_options</div>
		$grid
	];
  return ($resultHTML,$title);
}

sub find_zone {
  my($Data, $ID)  =@_;
  #This function will traverse down a tree (assumed to be a one way stick) 
  # and return the ID of the ZONE it encounters

  my $db=$Data->{'db'} || '';
  my $looptimes=0;
  do  {
    return 0 if !$ID;
    $looptimes++;
    my $st=qq[
      SELECT CN.intNodeID AS CNintNodeID, CN.intTypeID AS CNintTypeID
      FROM tblNode AS PN
        LEFT JOIN tblNodeLinks ON PN.intNodeID=tblNodeLinks.intParentNodeID
        LEFT JOIN tblNode AS CN ON CN.intNodeID=tblNodeLinks.intChildNodeID
      WHERE PN.intNodeID = $ID
      LIMIT 1
    ];
    my $query = $db->prepare($st);
    $query->execute;
    my $dref=$query->fetchrow_hashref();
    $query->finish();
    return $dref->{'CNintNodeID'} if $dref->{'CNintTypeID'} == $Defs::LEVEL_ZONE;
    return 0 if !$dref->{CNintNodeID};
    $ID=$dref->{CNintNodeID};
  } while ($looptimes < 8); #This shouldn't happen more than 8 times
  return 0;
}


1;
