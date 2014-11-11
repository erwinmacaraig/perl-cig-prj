#
# $Header: svn://svn/SWM/trunk/web/Reports/ReportAdvanced_Duplicates.pm 8251 2013-04-08 09:00:53Z rlee $
#

package Reports::ReportAdvanced_Duplicates;

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
	my $clientValues = $Data->{'clientValues'};
	my $CommonVals = getCommonValues(
		$Data,
		{
			SubRealms => 1,
		},
	);

	my %config = (
		Name => 'Duplicates Report',

		StatsReport => 1,
		MemberTeam => 0,
		ReportEntity => 1,
		ReportLevel => 0,
		Template => 'default_adv',
    TemplateEmail => 'default_adv_CSV',
		DistinctValues => 1,
    SQLBuilder => \&SQLBuilder,

		Fields => {
			strEntityName => [ "Organisation", { displaytype=>'text', fieldtype=>'text', allowsort=>1, active=>1, dbfield=>'tblEntity.strLocalName', allowgrouping=>1, } ],

            intEntityLevel=> [
                'Organisation Level',
                {
                    dbfield         => 'tblEntity.intEntityLevel',
                    displaytype     => 'lookup',
                    fieldtype       => 'dropdown',
                    dropdownoptions => \%Defs::DisplayEntityLevelNames,
                    allowgrouping   => 1
                }
            ],

			numMembers=> ["Number of Duplicates to be Resolved",{displaytype=>'none', fieldtype=>'text', active=>1, dbfield => 'COUNT(tblPerson.intPersonID)', total=>1, allowsort=>1}],
		},

		Order => [qw(
			numMembers
			strEntityName
            intEntityLevel
		)],
		OptionGroups => {
			default => ['Details',{}],
		},

		Config => {
			FormFieldPrefix => 'c',
			FormName => 'duplform_',
			EmailExport => 1,
			limitView  => 5000,
			EmailSenderAddress => $Defs::admin_email,
			SecondarySort => 1,
			RunButtonLabel => 'Run Report',
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

    my $PRtablename = "tblPersonRegistration_" . $Data->{'Realm'};

    $sql = qq[
      SELECT ###SELECT###
      FROM 
            tblPerson 
            INNER JOIN $PRtablename as PR ON (
                PR.intPersonID=tblPerson.intPersonID
             )
            LEFT JOIN tblTempEntityStructure as TempEnt ON (TempEnt.intChildID=PR.intEntityID)
            LEFT JOIN tblEntity ON (tblEntity.intEntityID = PR.intEntityID)
      WHERE  $where_levels $current_where $where_list 
       AND tblPerson.intSystemStatus=$Defs::PERSONSTATUS_POSSIBLE_DUPLICATE
        GROUP  BY tblEntity.intEntityID
    ];
    return ($sql,'');
  }
}

1;
