#
# $Header: svn://svn/SWM/trunk/web/Reports/ReportAdvanced_Clearances.pm 8849 2013-07-04 02:14:36Z dhanslow $
#

package Reports::ReportAdvanced_Clearances;

use strict;
use lib ".";
use ReportAdvanced_Common;
use Reports::ReportAdvanced;
our @ISA =qw(Reports::ReportAdvanced);


use strict;

sub _getConfiguration {
	my $self = shift;

	my $currentLevel = $self->{'EntityTypeID'} || 0;
	my $Data = $self->{'Data'};
	my $SystemConfig = $self->{'SystemConfig'};
	my $clientValues = $Data->{'clientValues'};

  my $txt_Clr = $SystemConfig->{'txtCLR'} || 'Clearance';
	my $showAgentFields = ($SystemConfig->{'clrHide_AgentFields'} == 1) ? '0' : '1';
  my $natnumname=$SystemConfig->{'NationalNumName'} || 'National Number';

  my $CommonVals = getCommonValues(
    $Data,
    {
      DefCodes => 1,
    },
  );

	my %config = (
		Name => "Request Report",

		StatsReport => 0,
		MemberTeam => 0,
		ReportEntity => 3,
		ReportLevel => 0,
		Template => 'default_adv',
		TemplateEmail => 'default_adv_CSV',
		DistinctValues => 1,
    SQLBuilder => \&SQLBuilder,

		Fields => {
            intPersonRequestID=> ["Request No.",{displaytype=>'text', fieldtype=>'text', active=>1, allowsort=>1}],
            strRequestType=> ['Request Type', { displaytype=>'lookup', fieldtype=> 'dropdown', dropdownoptions => \%Defs::personRequest, allowgrouping => 1}],
            strNationalNum=> [$natnumname,{displaytype=>'text', fieldtype=>'text', allowsort=>1}, active=>1],
            strLocalFirstname=> ["First name",{displaytype=>'text', fieldtype=>'text', active=>1, allowsort=>1}],
            strLocalSurname=> ["Family name",{displaytype=>'text', fieldtype=>'text', active=>1, allowsort=>1}],
            strLatinFirstname=> ["International First name",{displaytype=>'text', fieldtype=>'text', active=>1, allowsort=>1}],
            strLatinSurname=> ["International Family name",{displaytype=>'text', fieldtype=>'text', active=>1, allowsort=>1}],
            dtDOB=> ['Date of Birth',{displaytype=>'date', fieldtype=>'date', dbfield=>'M.dtDOB', dbformat=>' DATE_FORMAT(P.dtDOB,"%d/%m/%Y")'}, active=>1],
            dtYOB=> ['Year of Birth',{displaytype=>'date', fieldtype=>'text', allowgrouping=>1, allowsort=>1, dbfield=>'YEAR(P.dtDOB)', dbformat=>' YEAR(M.dtDOB)'}],
            SourceClubName=> ['Source Club',{displaytype=>'text', fieldtype=>'text', active=>1, allowsort=>1, dbfield => 'SourceClub.strLocalName', allowgrouping=>1}],
            DestinationClubName=> ['Destination Club',{displaytype=>'text', fieldtype=>'text', active=>1, allowsort=>1, dbfield => 'DestinationClub.strLocalName', allowgrouping=>1}],

            strSport=> ['Registration Sport', { displaytype=> 'lookup', fieldtype=> 'dropdown', dropdownoptions => \%Defs::sportType, allowgrouping=> 1 }],
            strPersonEntityRole=> [ 'Sub Role', { displaytype=>'text', fieldtype=>'text'}],
            strPersonType=> ['Registration Role', { displaytype=>'lookup', fieldtype=> 'dropdown', dropdownoptions => \%Defs::personType, allowgrouping => 1}],
            strPersonLevel=> ['Registration Level', { displaytype=> 'lookup', fieldtype=> 'dropdown', dropdownoptions => \%Defs::personLevel, allowgrouping=>1}],
            dtDateRequest=> ['Date Requested', {active=>1, displaytype=>'date', fieldtype=>'datetime', allowsort=>1, dbformat=>' DATE_FORMAT(PRQ.dtDateRequest,"%d/%m/%Y %H:%i")', }],
            strRequestStatus => ["Request Status" ,{displaytype=>'lookup', active=>1, fieldtype=>'dropdown', dropdownoptions => \%Defs::personRequestStatus, allowsort=>1, allowgrouping=>1}],
		},

		Order => [qw(
			intPersonRequestID
			strNationalNum
			strLocalFirstname
			strLocalSurname
			strLatinFirstname
			strLatinSurname
			dtDOB
			dtYOB
			SourceClubName
			DestinationClubName
            strRequestType
            strSport
            strPersonType
            strPersonLevel
            strPersonEntityRole
            strRequestStatus
			dtDateRequest
		)],
    OptionGroups => {
      default => ['Details',{}],
    },

		Config => {
			FormFieldPrefix => 'c',
			FormName => 'clearform_',
			EmailExport => 1,
			limitView  => 5000,
			EmailSenderAddress => $Defs::admin_email,
			SecondarySort => 1,
			RunButtonLabel => 'Run Report',
			ReturnProcessData => [qw(tblTeam.strEmail tblTeam.strName)],
		},
	);
	$self->{'Config'} = \%config;
}

sub SQLBuilder  {
  my($self, $OptVals, $ActiveFields) =@_ ;
  my $currentLevel = $self->{'EntityTypeID'} || 0;
  my $Data = $self->{'Data'};
  my $clientValues = $Data->{'clientValues'};
  my $SystemConfig = $Data->{'SystemConfig'};

  my $from_levels = $OptVals->{'FROM_LEVELS'};
  my $from_list = $OptVals->{'FROM_LIST'};
  my $where_levels = $OptVals->{'WHERE_LEVELS'};
  my $where_list = $OptVals->{'WHERE_LIST'};
  my $current_from = $OptVals->{'CURRENT_FROM'};
  my $current_where = $OptVals->{'CURRENT_WHERE'};
  my $select_levels = $OptVals->{'SELECT_LEVELS'};

  my $sql = '';
  { #Work out SQL

    $where_list=' AND '.$where_list if $where_list and ($where_levels or $current_where);

    $sql = qq[
      SELECT 
				PRQ.*,
				DATE_FORMAT(PRQ.dtDateRequest, "%d/%m/%Y") AS dtDateRequest,
				P.strLocalSurname,
				P.strLocalFirstname,
				P.strLatinSurname,
				P.strLatinFirstname,
				SourceClub.strLocalName as SourceClubName,
				DestinationClub.strLocalName as DestinationClubName,
				P.strNationalNum,
				DATE_FORMAT(P.dtDOB, "%d/%m/%Y") as dtDOB,
				DATE_FORMAT(P.dtDOB, "%Y") as dtYOB
				FROM tblPersonRequest as PRQ
					INNER JOIN tblPerson as P ON (P.intPersonID = PRQ.intPersonID)
					LEFT JOIN tblEntity as SourceClub ON (SourceClub.intEntityID = PRQ.intRequestFromEntityID)
					LEFT JOIN tblEntity as DestinationClub ON (DestinationClub.intEntityID = PRQ.intRequestToEntityID)
				WHERE 
                    PRQ.intRealmID = $Data->{'Realm'}
					AND (
                        PRQ.intRequestToEntityID = $self->{'EntityID'} 
                        OR PRQ.intRequestFromEntityID = $self->{'EntityID'}
                    )
					$where_list
    ];
    return ($sql,'');
  }
}

1;
