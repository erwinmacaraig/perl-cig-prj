#
# $Header: svn://svn/SWM/trunk/web/Reports/ReportAdvanced_Club.pm 11233 2014-04-04 04:13:31Z dhanslow $
#

package Reports::ReportAdvanced_Club;

use strict;
use lib ".";
use ReportAdvanced_Common;
use Reports::ReportAdvanced;
our @ISA = qw(Reports::ReportAdvanced);

use strict;

sub _getConfiguration {
    my $self = shift;

    my $currentLevel = $self->{'EntityTypeID'} || 0;
    my $Data         = $self->{'Data'};
    my $clientValues = $Data->{'clientValues'};
    my $realm_id     = $Data->{'Realm'};
    my $CommonVals   = getCommonValues(
        $Data,
        {
            SubRealms           => 1,
            LegalTypes          => 1,
            CustomFields        => 1,
            FieldLabels         => 1,
            DefCodes            => 1,
            EntityCategories    => 1,
        },
    );
    my $txt_Clr = $Data->{'SystemConfig'}{'txtCLR'} || 'Clearance';
    my %config = (
        Name => 'Detailed Club Report',

        StatsReport     => 1,
        MemberTeam      => 0,
        ReportEntity    => 3,
        ReportLevel     => 0,
        Template        => 'default_adv',
        TemplateEmail   => 'default_adv_CSV',
        DistinctValues  => 1,
        DefaultPermType => 'Club',
        SQLBuilder => \&SQLBuilder,

        Fields => {
            strStatus=> [ 'Active', { displaytype => 'lookup', fieldtype => 'dropdown', dropdownoptions => \%Defs::entityStatus, dbfield => 'E.strStatus', } ],
            strLocalName => [ "$Data->{'LevelNames'}{$Defs::LEVEL_CLUB} Name", { displaytype => 'text', fieldtype   => 'text', active => 1, allowsort   => 1, } ],
            strLocalShortName => [ "$Data->{'LevelNames'}{$Defs::LEVEL_CLUB} Short Name", { displaytype => 'text', fieldtype   => 'text', active => 1, allowsort   => 1, } ],
            strLatinName => [ "International $Data->{'LevelNames'}{$Defs::LEVEL_CLUB} Name", { displaytype => 'text', fieldtype   => 'text', active => 1, allowsort   => 1, } ],
            strLatinShortName => [ "International $Data->{'LevelNames'}{$Defs::LEVEL_CLUB} Short Name", { displaytype => 'text', fieldtype   => 'text', active => 1, allowsort   => 1, } ],
            strMAID=> [ "$Data->{'LevelNames'}{$Defs::LEVEL_CLUB} No", { displaytype => 'text', fieldtype   => 'text', allowsort   => 1, } ],
            strContact=> [ 'Contact', { displaytype => 'text', fieldtype   => 'text', allowsort   => 1, } ],
            strAddress1 => [ 'Address Line 1', { displaytype => 'text', fieldtype   => 'text', allowsort   => 1, } ],
            strAddress2 => [ 'Address Line 2', { displaytype => 'text', fieldtype   => 'text', allowsort   => 1, } ],
            strCity => [ 'City', { displaytype => 'text', fieldtype   => 'text', allowsort   => 1, } ],
            strState => [ 'State', { displaytype   => 'text', fieldtype     => 'text', allowsort     => 1, allowgrouping => 1, } ],

            strEntityType=> [ 'Type of Organisation', { displaytype => 'lookup', fieldtype => 'dropdown', dropdownoptions => \%Defs::entityType, dbfield => 'E.strStatus', } ],
            intLegalTypeID=> [ 'Legal Entity Type', { displaytype => 'lookup', fieldtype => 'dropdown', dropdownoptions => $CommonVals->{'LegalTypes'}, allowsort => 1 } ],
            strLegalID=> [ 'Legal Type Number', { displaytype => 'text', fieldtype   => 'text', allowsort   => 1, } ],
            dtFrom=> ['Foundation Date', {active=>1, displaytype=>'date', fieldtype=>'datetime', allowsort=>1, dbformat=>' DATE_FORMAT(E.dtFrom,"%d/%m/%Y")', }],
            dtTo=> ['Dissolution Date', {active=>1, displaytype=>'date', fieldtype=>'datetime', allowsort=>1, dbformat=>' DATE_FORMAT(E.dtTo,"%d/%m/%Y")', }],
            strRegion=> [ 'Region', { displaytype   => 'text', fieldtype     => 'text', allowsort     => 1, allowgrouping => 1, } ],
            strISOCountry=> [ 'Country (ISO)', { displaytype     => 'lookup', fieldtype       => 'dropdown', dropdownoptions => $CommonVals->{'Countries'}, allowsort => 1, dbfield=> 'UCASE(strISOCountry)', allowgrouping=> 1 } ],

            strDiscipline=> [ 'Sport', { displaytype => 'lookup', fieldtype => 'dropdown', dropdownoptions => \%Defs::entitySportType, } ],
            strOrganisationLevel=> [ 'Level', { displaytype => 'lookup', fieldtype => 'dropdown', dropdownoptions => \%Defs::entitySportType, } ],

            strPostalCode => [ 'Postal Code', { displaytype => 'text', fieldtype   => 'text', allowsort   => 1, } ],
            strPhone => [ 'Phone', { displaytype => 'text', fieldtype   => 'text', allowsort   => 1, dbfield     => 'E.strPhone', } ],
            strFax => [ 'Fax', { displaytype => 'text', fieldtype   => 'text', allowsort   => 1, dbfield     => 'E.strFax', } ],
            strEmail => [ 'Email', { displaytype => 'text', fieldtype   => 'text', allowsort   => 1, dbfield     => 'E.strEmail', } ],
            strWebURL=> [ 'Website', { displaytype => 'text', fieldtype   => 'text', allowsort   => 1, dbfield     => 'E.strWebURL', } ],

        },

        Order => [
            qw(
              strStatus
              strLocalName
              strLocalShortName
              strLatinName
              strLatinShortName
                strEntityType
                intLegalTypeID
                strLegalID
                dtFrom
                dtTo
                strRegion
                strISOCountry
                strDiscipline
                strOrganisationLevel
              strContact
              strAddress1
              strAddress2
              strCity
              strState
              strPostalCode
              strPhone
              strFax
              strEmail
                strWebURL
              )
        ],
        OptionGroups => {
            default        => [ 'Details', {} ],
        },

        Config => {
            FormFieldPrefix    => 'c',
            FormName           => 'clubform_',
            EmailExport        => 1,
            limitView          => 5000,
            EmailSenderAddress => $Defs::admin_email,
            SecondarySort      => 1,
            RunButtonLabel     => 'Run Report',
            ReturnProcessData  => [qw(tblClub.strEmail tblClub.strName)],
        },
    );

        $config{'Fields'} = { %{$config{'Fields'}}, };
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
            E.*
        FROM 
            tblEntity as E
            LEFT JOIN tblEntityLinks as EL ON (
                E.intEntityID = EL.intChildEntityID
            )
         WHERE
            E.intRealmID = $Data->{'Realm'}
            AND EL.intParentEntityID = $self->{'EntityID'}
            AND E.intEntityLevel = $Defs::LEVEL_CLUB
            $where_list
    ];
    return ($sql,'');
  }
}

1;

# vim: set et sw=4 ts=4:
