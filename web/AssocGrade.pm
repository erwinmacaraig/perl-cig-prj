#
# $Header: svn://svn/SWM/trunk/web/AssocGrade.pm 8251 2013-04-08 09:00:53Z rlee $
#

package AssocGrade;

require Exporter;
@ISA = qw(Exporter);
@EXPORT=qw(handleAssocGrades getAssocGrades);
@EXPORT_OK=qw(handleAssocGrades getAssocGrades);

use strict;
use Reg_common;
use Utils;
use HTMLForm;
use AuditLog;
use CGI qw(unescape param);
use FormHelpers;
use GridDisplay;

sub handleAssocGrades	{
	my ($action, $Data)=@_;
	my $assocGradeID = param('assocGradeID') || 0;
	my $resultHTML='';
	my $title='';
	if ($action =~/^ASSGR_DT/) {
		($resultHTML,$title) = assocGrade_details($action, $Data, $assocGradeID);
	}
	elsif ($action =~/^ASSGR_L/) {
		($resultHTML,$title) = listAssocGrades($Data);
	}
	return ($resultHTML,$title);
}

sub assocGrade_details	{
	my ($action, $Data, $assocGradeID)=@_;
	my $option = 'display';
	$option = 'edit' if $action eq 'ASSGR_DTE' and allowedAction($Data, 'agegrp_e');
	$option = 'add' if $action eq 'ASSGR_DTA' and allowedAction($Data, 'agegrp_a');
	$assocGradeID = 0 if $option eq 'add';
	my $field = loadAssocGradeDetails($Data->{'db'}, $assocGradeID, $Data->{'clientValues'}{'assocID'}) || ();
	my $intAssocID = $Data->{'clientValues'}{'assocID'} >= 0 ? $Data->{'clientValues'}{'assocID'} : 0;
  my $client = setClient($Data->{'clientValues'}) || '';
  my $txt_Name = 'Division';
  my $txt_Names = 'Divisions';
	my %FieldDefinitions=(
		fields=>	{
			strGradeDesc => {
				label => "$txt_Name Name",
				value => $field->{strGradeDesc},
				type  => 'text',
				size  => '40',
				maxsize => '100',
        sectionname => 'details',
				compulsory => 1,
			},
			intRecStatus=> {
				label => "$txt_Name Active",
				value => $field->{intRecStatus},
				type  => 'checkbox',
				default => 1,
        sectionname => 'details',
				displaylookup => {1 => 'Yes', 0 => 'No'},
			},
		},
		order => [qw(strGradeDesc intRecStatus)],
		sections => [
			['details',"$txt_Name Details"],
		],	
		options => {
			labelsuffix => ':',
			hideblank => 1,
			target => $Data->{'target'},
			formname => 'n_form',
      submitlabel => "Update $txt_Name",
      introtext => 'auto',
			NoHTML => 1,
      updateSQL => qq[
        UPDATE tblAssoc_Grade
          SET --VAL--
        WHERE intAssocGradeID = $assocGradeID
					AND intAssocID = $intAssocID
			],
      addSQL => qq[
        INSERT INTO tblAssoc_Grade
          (intAssocID, --FIELDS-- )
					VALUES ($intAssocID, --VAL-- )
			],
      auditFunction=> \&auditLog,
      auditAddParams => [
        $Data,
        'Add',
        'Division',
      ],
      auditEditParams => [
        $assocGradeID,
        $Data,
        'Update',
        'Division',
      ],
      LocaleMakeText => $Data->{'lang'},
		},
    carryfields =>  {
      client => $client,
      a=> $action,
			assocGradeID => $assocGradeID,
    },
  );
	my $resultHTML='';
	($resultHTML, undef ) = handleHTMLForm(\%FieldDefinitions, undef, $option, '',$Data->{'db'});
	my $title = qq[$txt_Name - $field->{strGradeDesc}];
	if($option eq 'display')  {
		my $chgoptions='';
		$chgoptions.=qq[<span class = "button-small generic-button"><a href="$Data->{'target'}?client=$client&amp;a=ASSGR_DTE&amp;assocGradeID=$assocGradeID">Edit</a></span> ] if allowedAction($Data, 'assgr_e');
		$chgoptions=qq[<div class="changeoptions">$chgoptions</div>] if $chgoptions;
		$chgoptions= '' if (! $field->{intAssocID});
		$title=$chgoptions.$title;
	}
	$title="Add New $txt_Name" if $option eq 'add';
	my $text = qq[<p><a href="$Data->{'target'}?client=$client&amp;a=ASSGR_L">Click here</a> to return to list of $txt_Names</p>];
	$resultHTML = $text.$resultHTML.$text;
	return ($resultHTML,$title);
}


sub loadAssocGradeDetails {
	my($db, $id, $assocID) = @_;
  return {} if !$id;
	$assocID ||= 0;
  my $statement=qq[
    SELECT 
      *
    FROM 
      tblAssoc_Grade
    WHERE 
      intAssocGradeID = $id 
			AND intAssocID = $assocID
	];
	my $query = $db->prepare($statement);
	$query->execute;
	my $field = $query->fetchrow_hashref();
	$query->finish;
	foreach my $key (keys %{$field})  { 
		if(!defined $field->{$key}) {$field->{$key} = '';} 
	}
	return $field;
}

sub getAssocGrades	{
	my($Data) = @_;
  my $assocID = $Data->{'clientValues'}{'assocID'} || $Defs::INVALID_ID;
	my $st = qq[
		SELECT 
      intAssocGradeID, 
      strGradeDesc
		FROM 
      tblAssoc_Grade
		WHERE 
			intAssocID = $assocID
			AND intRecStatus = 1
		ORDER BY 
      strGradeDesc
	]; 
	my $query = $Data->{'db'}->prepare($st);
	$query->execute();
	my %AssocGrades = ();
	while (my ($id,$name) = $query->fetchrow_array()) {
		$AssocGrades{$id} = qq[$name] || '';
	}
	return (\%AssocGrades);
}

sub listAssocGrades {
  my ($Data) = @_;
  my $resultHTML = '';
  my $client = $Data->{client};
  my $txt_Name = $Data->{'SystemConfig'}{'txtDivision'} || 'Division';
  my $txt_Names = $Data->{'SystemConfig'}{'txtDivisions'} || 'Divisions';
  my $statement=qq[
    SELECT 
      intAssocGradeID,
      strGradeDesc,
      intRecStatus
    FROM 
      tblAssoc_Grade
    WHERE 
      intAssocID = ?
      AND intRecStatus <> -1
    ORDER BY
      strGradeDesc
  ];
  my $query = $Data->{'db'}->prepare($statement);
  $query->execute($Data->{'clientValues'}{'assocID'});
  my $found = 0;
  my %tempClientValues = getClient($client);
  my $currentname = '';
	my @rowdata = ();
  while (my $dref= $query->fetchrow_hashref()) {
    $found++;
    my $tempClient = setClient(\%tempClientValues);
		push @rowdata, {
			id => $dref->{'intAssocGradeID'},
			strGradeDesc => $dref->{'strGradeDesc'},
			intRecStatus => $dref->{'intRecStatus'},
			SelectLink => "$Data->{'target'}?client=$tempClient&amp;a=ASSGR_DTE&amp;assocGradeID=$dref->{intAssocGradeID}",
		}
  }
  my $addlink = '';
  my $title = $txt_Names;
  {
    my $tempClient = setClient(\%tempClientValues);
    $addlink = qq[<span class = "button-small generic-button"><a href="$Data->{'target'}?client=$tempClient&amp;a=ASSGR_DTA">Add</a></span>];
  }
  my $numlist = ($found and $found > 1)? qq[<div class="tablecount">$found rows found</div>] : '';
  my $modoptions = qq[<div class="changeoptions">$addlink</div>];
  $title = $modoptions.$title;
  my @headers = (
    {
      type => 'Selector',
      field => 'SelectLink',
    },
    {
      name =>   $Data->{'lang'}->txt($txt_Name.' Name'),
      field =>  'strGradeDesc',
    },
    {
      name =>   $Data->{'lang'}->txt('Active'),
      field =>  'intRecStatus',
			type => 'tick',
    },
  );

  my $grid  = showGrid(
    Data => $Data,
    columns => \@headers,
    rowdata => \@rowdata,
    gridid => 'grid',
    width => '99%',
    height => 700,
  );

	$resultHTML = qq[
		$grid
	];
  return ($resultHTML,$title);

}

1;
