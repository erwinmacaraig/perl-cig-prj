#
# $Header: svn://svn/SWM/trunk/web/MemberTypesBulk.pm 10489 2014-01-20 23:10:54Z fkhezri $
#

package MemberTypesBulk;

require Exporter;
@ISA =  qw(Exporter);
@EXPORT = qw(updateBulkMemberTypes listBulkMemberTypes);
@EXPORT_OK = qw(updateBulkMemberTypes listBulkMemberTypes);

use strict;
use CGI qw(param unescape escape);

use lib '.';
use Reg_common;
use Defs;
use Utils;
use HTMLForm;
use FieldLabels;
use AuditLog;
use MemberTypesCommon;

sub listBulkMemberTypes {
	my ($Data, $memberID) = @_;
	my $type = param("ty") || $Defs::MEMBER_TYPE_PLAYER;
	my $sub_type = param("ty2") || $Defs::MEMBER_SUBTYPE_ACCRED;
  my $FieldLabels = FieldLabels::getFieldLabels($Data, $Defs::LEVEL_MEMBER);
  my ($DefCodes, $DefCodesFull) = get_defcodes($Data, 0);
  my $client = setClient($Data->{'clientValues'}) || '';
  my $resultHTML = '';
	my $heading = '';
  my $type_name = ($Data->{'SystemConfig'}{'TYPE_NAME_' . $type}) ? $Data->{'SystemConfig'}{'TYPE_NAME_' . $type} : $Defs::memberTypeName{$type};
  my @MTDataOrder = ();
  my %MTHeaderData = ();
  my %MTBlankData = ();
  if ($sub_type == $Defs::MEMBER_SUBTYPE_POS) {
    @MTDataOrder = getMT_PositionsOrder();
    %MTHeaderData = getMT_Positions($Data, {}, $FieldLabels, $DefCodes, $sub_type); 
    %MTBlankData = getMT_Positions($Data, {}, $FieldLabels, $DefCodes, $type, $sub_type);
  }
  else {
    @MTDataOrder = getMT_AccreditationsOrder();
    %MTHeaderData = getMT_Accreditations($Data, {}, $FieldLabels, $DefCodes, $sub_type); 
    %MTBlankData = getMT_Accreditations($Data, {}, $FieldLabels, $DefCodes, $sub_type);
  }
  my $st = qq[
    SELECT
      *,
      DATE_FORMAT(dtDate1, "%d/%m/%Y") AS dtDate1, 
      DATE_FORMAT(dtDate2, "%d/%m/%Y") AS dtDate2, 
      DATE_FORMAT(dtDate3, "%d/%m/%Y") AS dtDate3
    FROM
      tblMember_Types
    WHERE
      intMemberID = ?
      AND intAssocID = ?
      AND intTypeID = ?
      AND intSubTypeID = ?
      AND intRecStatus <> $Defs::RECSTATUS_DELETED
    ORDER BY 
      intSubTypeID ASC, 
      tblMember_Types.dtDate1, 
      tblMember_Types.dtDate2
  ];
  my $q = $Data->{'db'}->prepare($st) or query_error($st);
  $q->execute(
    $memberID,
    $Data->{'clientValues'}{'assocID'} || -1,
    $type,
    $sub_type
  );
  my $table_data = '';
  my $shade = 0;
  my $i = 0;
  while (my $RecordData = $q->fetchrow_hashref()) {
    $i++;
    my %MTData = ();
    if ($sub_type == $Defs::MEMBER_SUBTYPE_POS) {
      %MTData = getMT_Positions($Data, $RecordData, $FieldLabels, $DefCodes, $type, $sub_type);
    }
    else {
      %MTData = getMT_Accreditations($Data, $RecordData, $FieldLabels, $DefCodes, $sub_type);
    }
    $table_data .= _list_row_data(\%MTData, \@MTDataOrder, $shade, $i, $RecordData->{'intMemberTypeID'});
    $shade = ($shade) ? 0 : 1;
  }
  for (my $count = 0; $count < 8; $count++) {
    $i++;
    $table_data .= _list_row_data(\%MTBlankData, \@MTDataOrder, $shade, $i);
    $shade = ($shade) ? 0 : 1;
  }
  my $table_header = _list_row_header(\%MTHeaderData, \@MTDataOrder); 
  my $name = ($sub_type == $Defs::MEMBER_SUBTYPE_POS) ? 'Positions Held' : 'Accreditations';
  $table_data ||= qq[<tr><td>There are no records to edit</td></tr>];
  $resultHTML .= qq[
    <form action="main.cgi" name="bmt_form" method="POST" onsubmit="document.getElementById('HFsubbut').disabled=true;return true;">
    <table width="100%"  class="listTable">
      <caption class="sectionheader">$name</caption>
      $table_header
      $table_data
    </table>
    <div> <input type="submit" name="subbut" value="Update" class="HF_submit button proceed-button" id="HFsubbut"> </div>
    <input type="hidden" name="client" value="$client">
    <input type="hidden" name="a" value="M_MT_BULK_UPDATE">
    <input type="hidden" name="ty" value="$type">
    <input type="hidden" name="ty2" value="$sub_type">
    <input type="hidden" name="rows" value="$i">
    </form><br><br>
    <p><a href="$Data->{'target'}?client=$client&amp;a=M_MT_LIST&amp;ty=$type">Back</a></p>
  ];
	$heading ||= 'Member Types';
  return ($resultHTML, $heading);
}

sub updateBulkMemberTypes {
	my ($Data, $memberID) = @_;
	my $type = param("ty") || $Defs::MEMBER_TYPE_PLAYER;
	my $sub_type = param("ty2") || $Defs::MEMBER_SUBTYPE_ACCRED;
	my $rows = param("rows") || -1;
  my $assocID= $Data->{'clientValues'}{'assocID'} || -1;
  my $client = setClient($Data->{'clientValues'}) || '';
  my $log = new AuditLogObj(db => $Data->{'db'});
  my $resultHTML = '';
	my $heading = '';
  my @MTDataOrder = ();
  my $audit_section = '';
  if ($sub_type == $Defs::MEMBER_SUBTYPE_POS) {
    @MTDataOrder = getMT_PositionsOrder();
    $audit_section = "Position";
  }
  else {
    @MTDataOrder = getMT_AccreditationsOrder();
    $audit_section = "Accred";
  }
  my $i=0;
  my $cols = @MTDataOrder - 1;
  my $update_count = 0;
  my $insert_count = 0;
  my $error_count = 0;
  while ($i < $rows) {
    my $blank_cols = 0;
    my $column_data = '';
    $i++;
    my $memberTypeID =  param("d_intMemberTypeID_$i") || 0;
    my $query_fields = '';
    my $query_fields_input = '';
    my @query_data = ();
    my $ii = 0;
    for my $field (@MTDataOrder) {
      my $param_data = param("d_" . $field . "_$i") || '';
     if ($field =~ 'dtDate') {
        my($day,$mon,$year)= $param_data=~/(\d\d)\/(\d\d)\/(\d\d\d\d)/;
        $day ||='00';
        $mon ||='00';
        $year ||='0000';
        $param_data = "$year-$mon-$day";
        $param_data = "" if ($param_data eq '0000-00-00');
      }
      $query_fields .= ', ' if ($ii);
      if ($memberTypeID > 0) {
        $query_fields .= $field . ' = ?';
      }
      else {
        $query_fields_input .= ',' if ($ii);
        $query_fields .= $field;
        $query_fields_input .= '?';
      }
      push @query_data, $param_data;
      $blank_cols++ unless ($param_data);
      $ii++;
    }
    my $st = '';
    my $audit_type = '';
    if ($memberTypeID > 0) {
      push @query_data, $memberTypeID;
      $st = qq[
        UPDATE tblMember_Types
        SET $query_fields
        WHERE intMemberTypeID = ?
      ];
      $update_count++;
      $audit_type = "Update";
    }
    else {
      next if ($blank_cols == $cols);
      $query_fields .= qq[,intMemberID, intAssocID, intTypeID, intRecStatus];
      $query_fields_input .= qq[,?,?,?, 1];
      push @query_data, $memberID;
      push @query_data, $assocID;
      push @query_data, $type;
      $st = qq[
        INSERT INTO tblMember_Types
          ($query_fields)
        VALUES
          ($query_fields_input)
      ];
      $audit_type = "Create";
      $insert_count++;
    }
    if ($st) {
      my $q = $Data->{'db'}->prepare($st) or query_error($st);
      $memberTypeID = $q->{mysql_insertid} unless ($memberTypeID);
      $q->execute(@query_data) or query_error($st);
      auditLog($memberTypeID, $Data, $audit_type,"Bulk Member Types: $audit_section");
    }
    else {
      $error_count++;
    }
  }
  $resultHTML = qq[
    <p><b>Bulk Record update/insert complete</b></p>
    <p>$insert_count records added</p>
    <p>$update_count records updated</p>
    <p>$error_count records encountered errors</p>
    <p><a href="$Data->{'target'}?client=$client&amp;a=M_MT_LIST&amp;ty=$type">Return to $Defs::memberTypeName{$type} Member Type</a></p>
  ];
	$heading ||= 'Member Types';
  return ($resultHTML, $heading);
}

sub _list_row_header {
  my ($MTData, $MTDataOrder) = @_;
  my $body = '';
  for my $field (@$MTDataOrder) {
    next unless ($MTData->{$field}{'label'});
    $body .= qq[
      <th>$MTData->{$field}{'label'}</th>
    ];
  }
  return qq[
    <tr>
    $body
    </tr>
  ];
}

sub _list_row_data {
  my ($MTData, $MTDataOrder, $shade, $i, $mtID) = @_;
  my $shade_class = ($shade) ? 'class="rowshade" ' : '';
  $mtID ||= -1;
  my $body = '';
  for my $field (@$MTDataOrder) {
    my $label = $MTData->{$field}{'label'} || '';
    my $type = $MTData->{$field}{'type'} || '';
    my $value = $MTData->{$field}{'value'} || '';
    my $default = $MTData->{$field}{'default'} || '';
    my $size = $MTData->{$field}{'size'} || '';
    my $maxsize = $MTData->{$field}{'maxsize'} || '';
    my $options = $MTData->{$field}{'options'} || '';
    my $order = $MTData->{$field}{'order'} || '';
    my $multiple = $MTData->{$field}{'multiple'} || '';
    my $firstoption = $MTData->{$field}{'firstoption'} || '';
    my $datetype = $MTData->{$field}{'datetype'} || '';
    next unless ($label or $type eq 'hidden');
    my $fieldHTML = '';
    if ($type eq 'text') {
      my $sz = $size ? qq[ size="$size" ] : '';
      my $ms = $maxsize ? qq[ maxlength="$maxsize" ] : '';
      $fieldHTML = qq[<td $shade_class><input type="text" name="d_] . $field . qq[_$i" value="$value" id="l_$i" $sz $ms></td>];
    }
    elsif ($type eq 'checkbox') {
      if($value eq '' and $default) {
        $value = $default;
      }
      my $checked = ($value and $value == 1) ? ' checked ' : '';
      $fieldHTML = qq[<td $shade_class><input class="nb" type="checkbox" name="d_] . $field . qq[_$i" value="1" id="l_$i" $checked></td>];
    }
    elsif ($type eq 'lookup') {
      #my $field_name = "d_" . $field . "_$i";
      my $field_name =  $field . "_$i";
      $fieldHTML = HTMLForm::drop_down(
        $field_name, 
        $options, 
        $order, 
        $value, 
        $size, 
        $multiple, 
        $firstoption, 
        ''
      );
      $fieldHTML = qq[<td $shade_class>$fieldHTML</td>];
    }
    elsif ($type eq "date") {
      $value = '' if $value eq '00/00/00';
      $value = '' if $value eq '00/00/0000';
      $value = '' if $value eq '0000-00-00';
      $value ||= '';
      if ($datetype eq 'dropdown')  {
        my $field_name = $field . "_$i";
        $fieldHTML = HTMLForm::_date_selection_dropdown($field_name, $value, '', '');
      }
      else  {
        my $field_name = $field . "_$i";
        $fieldHTML = HTMLForm::_date_selection_picker($field_name, $value);
      }
      $fieldHTML = qq[<td $shade_class>$fieldHTML</td>];
    }
    elsif ($type eq "hidden") {
      $fieldHTML = qq[<input type="hidden" name="d_] . $field . qq[_$i" value="$value">];
    }
    else {
      $fieldHTML = qq[<td $shade_class><b>$type:</b> $value</td>];
    }
    $body .= $fieldHTML;
  }
  return qq[
    <tr>
    $body
      <input type="hidden" name="d_intMemberTypeID_$i" value="$mtID">
    </tr>
  ];
}

1;
