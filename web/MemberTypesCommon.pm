#
# $Header: svn://svn/SWM/trunk/web/MemberTypesCommon.pm 8251 2013-04-08 09:00:53Z rlee $
#

package MemberTypesCommon;

require Exporter;
@ISA =  qw(Exporter);
@EXPORT = qw(get_defcodes getMT_Accreditations getMT_AccreditationsOrder getMT_Positions getMT_PositionsOrder);
@EXPORT_OK = qw(get_defcodes getMT_Accreditations getMT_AccreditationsOrder getMT_Positions getMT_PositionsOrder);

use strict;
use CGI qw(param unescape escape);

use lib '.';
use Reg_common;
use Defs;
use Utils;
use SWSports;

sub get_defcodes {
  my ($Data, $option) = @_;
	my $DefCodes = {};
	my $DefCodesFull = {};
  my $defcodes_where = ($option eq "add") ? qq[AND intRecStatus <> $Defs::RECSTATUS_INACTIVE] : '';
  my $st = qq[
    SELECT 
      intType, 
      intCodeID, 
      strName
    FROM 
      tblDefCodes
    WHERE 
      intRealmID = $Data->{'Realm'}
      AND (intAssocID = $Data->{'clientValues'}{'assocID'} OR intAssocID = 0)
      AND intRecStatus <> $Defs::RECSTATUS_DELETED
      AND (intSubTypeID = $Data->{'RealmSubType'} OR intSubTypeID=0)
      $defcodes_where
  ];
  my $q = $Data->{'db'}->prepare($st);
  $q->execute;
  while (my $dref = $q->fetchrow_hashref())  {
    $DefCodes->{$dref->{intType}}{$dref->{intCodeID}} = $dref->{strName};
    $DefCodesFull->{$dref->{intCodeID}} = $dref->{strName};
  }
  return ($DefCodes, $DefCodesFull);
}

sub getMT_Accreditations {
  my ($Data, $RecordData, $FieldLabels, $DefCodes, $sub_type) = @_;
  return (
    intActive => {
      label => $FieldLabels->{'Accred.intActive'} || 'Active?',
      type => 'checkbox',
      value => $RecordData->{'intActive'},
      displaylookup => {1 => 'Yes', 0 => 'No'},
    },
    intInt7 => {
      label => $Data->{'SystemConfig'}{'ACCRED_ReAccreditation_HIDE'} ? '' : $FieldLabels->{'Accred.intInt7'} || 'Re-Accreditation',
      type => 'checkbox',
      value => $RecordData->{'intInt7'},
      displaylookup => {1 => 'Yes', 0 => 'No'},
    },
    strString1 => {
      label => $FieldLabels->{'Accred.strString1'} || '',
      type => 'text',
      size => 12,
      value => $RecordData->{'strString1'},
    },
    strString2 => {
      label => $FieldLabels->{'Accred.strString2'} || '',
      type => 'text',
      size => 12,
      value => $RecordData->{'strString2'},
    },
    strString3 => {
      label => $FieldLabels->{'Accred.strString3'} || '',
      type => 'text',
      size => 12,
      value => $RecordData->{'strString3'},
    },
    strString4 => {
      label => $FieldLabels->{'Accred.strString4'} || '',
      type => 'text',
      size => 12,
      value => $RecordData->{'strString4'},
    },
    intInt1 => {
      label => $FieldLabels->{'Accred.intInt1'} || 'Type',
      type => 'lookup',
      value => $RecordData->{'intInt1'},
      options =>  $DefCodes->{-35},
      firstoption => ['','Select Type'],
    },
    intInt2 => {
      label => $FieldLabels->{'Accred.intInt2'} || 'Level',
      type => 'lookup',
      value => $RecordData->{'intInt2'},
      options =>  $DefCodes->{-15},
      firstoption => ['','Select Level'],
    },
    intInt4 => {
      label => $Data->{'SystemConfig'}{'ACCRED_Sport_HIDE'} ? '' : $FieldLabels->{'Accred.intInt4'} || 'Sport',
      type => 'lookup',
      options =>  getSWSports(),
      firstoption => ['','Select a Sport'],
      value => $RecordData->{'intInt4'} || $Data->{'SystemConfig'}{'DefaultSport'} || 0,
    },
    intInt5 => {
      label => $FieldLabels->{'Accred.intInt5'} || 'Accreditation Provider',
      type => 'lookup',
      value => $RecordData->{'intInt5'},
      options =>  $DefCodes->{-32},
      firstoption => ['','Select Provider'],
    },
    dtDate1 => {
      label => $FieldLabels->{'Accred.dtDate1'} || 'Start Date',
      type => 'date',
      format => 'dd/mm/yyyy',
      value => $RecordData->{'dtDate1'},
      validate => 'DATE',
    },
    dtDate2 => {
      label => $FieldLabels->{'Accred.dtDate2'} || 'End Date',
      type => 'date',
      format => 'dd/mm/yyyy',
      value => $RecordData->{'dtDate2'},
      validate => 'DATE',
    },
    dtDate3 => {
      label => $Data->{'SystemConfig'}{'ACCRED_ApplicationDate_HIDE'} 
        ? '' 
        : ($Data->{'SystemConfig'}{'ACCRED_ApplicationDate'} 
          ? $Data->{'SystemConfig'}{'ACCRED_ApplicationDate'} 
          : $FieldLabels->{'Accred.dtDate3'}),
      type => 'date',
      format => 'dd/mm/yyyy',
      value => $RecordData->{'dtDate3'},
      validate => 'DATE',
    },
    intInt6 => {
      label => $FieldLabels->{'Accred.intInt6'} || 'Accreditation Result',
      type => 'lookup',
      value => $RecordData->{'intInt6'},
      options =>  $DefCodes->{-1003},
      firstoption => ['','Select Result'],
    },
    intSubTypeID => {
      type => 'hidden',
      value => $sub_type,
    }
  );
}

sub getMT_AccreditationsOrder {
  return qw(intActive intInt7 strString1 intInt1 intInt2 intInt4 intInt5 dtDate1 dtDate2 dtDate3 intInt6 strString2 strString3 strString4 intSubTypeID);
}

sub getMT_Positions {
  my ($Data, $RecordData, $FieldLabels, $DefCodes, $type, $sub_type) = @_;
  my $intInt2_codeID = -16;
  $intInt2_codeID = -14 if ($type == $Defs::MEMBER_TYPE_OFFICIAL);
  $intInt2_codeID = -56 if ($type == $Defs::MEMBER_TYPE_VOLUNTEER);
  return (
    intActive => {
      label => $FieldLabels->{'Position.intActive'} || 'Active?',
      type => 'checkbox',
      value => $RecordData->{'intActive'},
      displaylookup => {1 => 'Yes', 0 => 'No'},
    },
    intInt1 => {
      label => $Data->{'SystemConfig'}{'POS_HIDE_TYPE'} ? '' : $FieldLabels->{'Position.intInt1'} || 'Type',
      type => 'lookup',
      value => $RecordData->{'intInt1'},
      options =>  \%Defs::entityInfo,
      firstoption => ['','Choose Type'],
    },
    intInt2 => {
      label => $Data->{'SystemConfig'}{'POS_Position_Label'} ? $Data->{'SystemConfig'}{'POS_Position_Label'} : $FieldLabels->{'Position.intInt2'} || 'Position',
      type => 'lookup',
      value => $RecordData->{'intInt2'},
      firstoption => ['','Choose Position'],
      options =>  $DefCodes->{$intInt2_codeID},
    },
    intInt3 => {
      label => $FieldLabels->{'Position.intInt3'} || 'Entity ID',
      type => 'lookup',
      value => $RecordData->{'intInt3'},
      options =>  $DefCodes,
    },
    intInt4 => {
      label => ($Data->{'SystemConfig'}{'POS_Level_Label'} and $type == $Defs::MEMBER_TYPE_MISC)
        ? $Data->{'SystemConfig'}{'POS_Level_Label'}
        : $FieldLabels->{'Position.intInt4'} || 'Level',
      type => 'lookup',
      value => $RecordData->{'intInt4'},
      firstoption => ['','Choose Level'],
      options =>  $DefCodes->{-96},
    },
    intInt5 => {
      label => ($Data->{'SystemConfig'}{'POS_Preference_Label'} and $type == $Defs::MEMBER_TYPE_MISC)
        ? $Data->{'SystemConfig'}{'POS_Preference_Label'}
        : $FieldLabels->{'Position.intInt5'},
      type => 'lookup',
      value => $RecordData->{'intInt5'},
      firstoption => ['','Choose Preference'],
      options =>  $DefCodes->{-97},
    },
    dtDate1 => {
      label => $FieldLabels->{'Position.dtDate1'} || 'Start Date',
      type => 'date',
      format => 'dd/mm/yyyy',
      validate => 'DATE',
      value => $RecordData->{'dtDate1'},
    },
    dtDate2 => {
      label => $FieldLabels->{'Position.dtDate2'} || 'End Date',
      type => 'date',
      format => 'dd/mm/yyyy',
      validate => 'DATE',
      value => $RecordData->{'dtDate2'},
    },
    strString1 => {
      label => ($Data->{'SystemConfig'}{'POS_RegNo_Label'} and $type == $Defs::MEMBER_TYPE_MISC)
        ? $Data->{'SystemConfig'}{'POS_RegNo_Label'}
        : $FieldLabels->{'Position.strString1'} || "Registration Number",
      type => 'text',
      value => $RecordData->{'strString1'},
    },
    strString2 => {
      label => ($Data->{'SystemConfig'}{'POS_RegNo2_Label'} and $type == $Defs::MEMBER_TYPE_MISC)
        ? $Data->{'SystemConfig'}{'POS_RegNo2_Label'}
        : $FieldLabels->{'Position.strString2'} || "",
      type => 'text',
      value => $RecordData->{'strString2'},
    },
    intSubTypeID => {
      type => 'hidden',
      value => $sub_type,
    },
  );
}

sub getMT_PositionsOrder {
  return qw(intActive intInt1 intInt2 intInt4 intInt5 dtDate1 dtDate2 strString1 strString2 intSubTypeID);
}

1;
