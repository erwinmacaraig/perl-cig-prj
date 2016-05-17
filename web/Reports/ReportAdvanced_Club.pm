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
    my $SystemConfig = $Data->{'SystemConfig'};
    my $lang = $Data->{'lang'};
    my $txt_Clr = $Data->{'SystemConfig'}{'txtCLR'} || 'Clearance';
    my $txt_Transactions = $Data->{'SystemConfig'}{'txns_link_name'} || 'Transaction';
    my $txn_WHERE = '';
    if ( $clientValues->{clubID} and $clientValues->{clubID} > 0 ) {
        $txn_WHERE = qq[ AND TX.intTXNEntityID IN (0, $clientValues->{clubID})];
    }

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
            strStatus=> [ 'Active', { displaytype => 'lookup', fieldtype => 'dropdown', dropdownoptions => \%Defs::entityStatus, dbfield => 'E.strStatus', translate =>1,} ],
            strLocalName => [ "Organisation Name", { displaytype => 'text', fieldtype   => 'text', active => 1, allowsort   => 1, dbfield => "E.strLocalName", } ],
            strLocalShortName => [ "Organisation Short Name", { displaytype => 'text', fieldtype   => 'text', active => 1, allowsort   => 1, dbfield => "E.strLocalShortName"} ],
            strLatinName => [ "Name (International)", { displaytype => 'text', fieldtype   => 'text', active => 1, allowsort   => 1, dbfield => "E.strLatinName",} ],
            strLatinShortName => [ "Short Name (International)", { displaytype => 'text', fieldtype   => 'text', active => 1, allowsort   => 1, dbfield => "E.strLatinShortName",} ],
            strMAID=> [ "$Data->{'LevelNames'}{$Defs::LEVEL_CLUB} No", { displaytype => 'text', fieldtype   => 'text', allowsort   => 1, dbfield => "E.strMAID",} ],
            strContact=> [ 'Contact', { displaytype => 'text', fieldtype   => 'text', allowsort   => 1, dbfield => "E.strContact",} ],
            strAddress => [ 'Address Line 1', { displaytype => 'text', fieldtype   => 'text', allowsort   => 1, dbfield => "E.strAddress",} ],
            strAddress2 => [ 'Address Line 2', { displaytype => 'text', fieldtype   => 'text', allowsort   => 1, dbfield => "E.strAddress2",} ],
            strCity => [ 'City', { displaytype => 'text', fieldtype   => 'text', allowsort   => 1, dbfield => "E.strCity",} ],
            strState => [ 'State', { displaytype   => 'text', fieldtype     => 'text', allowsort     => 1, allowgrouping => 1, dbfield => "E.strState",} ],

            strEntityType=> [ 'Organisation Type', { displaytype => 'lookup', fieldtype => 'dropdown', dropdownoptions => \%Defs::entityType, dbfield => 'E.strEntityType', translate => 1,} ],
            intLegalTypeID=> [ 'Type of Legal Entity', { displaytype => 'lookup', fieldtype => 'dropdown', dropdownoptions => $CommonVals->{'LegalTypes'}, allowsort => 1, translate => 1, dbfield => "E.intLegalTypeID"
,} ],
            strLegalID=> [ 'Legal Entity Identification Number', { displaytype => 'text', fieldtype   => 'text', allowsort   => 1, dbfield => "E.strLegalID",} ],
            dtFrom=> ['Organisation Foundation Date', {active=>1, displaytype=>'date', fieldtype=>'datetime', allowsort=>1, dbfield=>'E.dtFrom', datetimeformat => ['MEDIUM','']}],
            dtTo=> ['Organisation Dissolution Date', {active=>1, displaytype=>'date', fieldtype=>'datetime', allowsort=>1, dbfield =>'E.dtTo', datetimeformat => ['MEDIUM','']}],
            strRegion=> [ 'Region', { displaytype   => 'text', fieldtype     => 'text', allowsort     => 1, allowgrouping => 1, dbfield => "E.strRegion",} ],
            strISOCountry=> [ 'Country', { displaytype     => 'lookup', fieldtype       => 'dropdown', dropdownoptions => $CommonVals->{'Countries'}, allowsort => 1, dbfield=> 'UCASE(strISOCountry)', allowgrouping=> 1,dbfield => "E.strISOCountry" } ],

            strDiscipline=> [ 'Sport', { displaytype => 'lookup', fieldtype => 'dropdown', dropdownoptions => \%Defs::entitySportType, translate => 1, dbfield => "E.strDiscipline",} ],
            strOrganisationLevel=> [ 'Level', { displaytype => 'lookup', fieldtype => 'dropdown', dropdownoptions => \%Defs::organisationLevel, translate => 1,dbfield => "E.strOrganisationLevel",} ],

            strPostalCode => [ 'Postal Code', { displaytype => 'text', fieldtype   => 'text', allowsort   => 1, dbfield => "E.strPostalCode",} ],
            strPhone => [ 'Phone', { displaytype => 'text', fieldtype   => 'text', allowsort   => 1, dbfield     => 'E.strPhone', } ],
            strFax => [ 'Fax', { displaytype => 'text', fieldtype   => 'text', allowsort   => 1, dbfield     => 'E.strFax', } ],
            strEmail => [ 'Email', { displaytype => 'text', fieldtype   => 'text', allowsort   => 1, dbfield     => 'E.strEmail', } ],
            strWebURL=> [ 'Website', { displaytype => 'text', fieldtype   => 'text', allowsort   => 1, dbfield     => 'E.strWebURL', } ],

              strRegionName => [
                (
                      $currentLevel > $Defs::LEVEL_REGION
                    ? $Data->{'lang'}->txt('Region Name')
                    : ''
                ),
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    dbfield => 'tblRegion.strLocalName',
                    allowsort   => 1,
                    allowgrouping => 1,
                }
              ],
            #Transactions
              intTransactionID => [
                $SystemConfig->{'AllowClubTXNs'} && $SystemConfig->{'AllowTXNrpts'} ? $lang->txt('Transaction ID') : '',
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 1,
                    optiongroup => 'transactions'
                }
              ],
              intProductNationalPeriodID => [
                $SystemConfig->{'AllowClubTXNs'} && $SystemConfig->{'AllowTXNrpts'} ? $lang->txt('Product Reporting') : '',
                {
                    displaytype     => 'lookup',
                    fieldtype       => 'dropdown',
                    dropdownoptions => $CommonVals->{'NationalPeriods'},
                    allowsort       => 1,
                    optiongroup     => 'transactions',
                    allowgrouping   => 1
                }
            ],
              intProductID => [
                $SystemConfig->{'AllowClubTXNs'} && $SystemConfig->{'AllowTXNrpts'} ? $lang->txt('Product') : '',
                {
                    displaytype     => 'lookup',
                    fieldtype       => 'dropdown',
                    dropdownoptions => $CommonVals->{'Products'}{'Options'},
                    dropdownorder   => $CommonVals->{'Products'}{'Order'},
                    allowsort       => 1,
                    optiongroup     => 'transactions',
                    multiple        => 1,
                    size            => 6,
                    dbfield         => 'TX.intProductID',
                    allowgrouping   => 1
                }
              ],
              strGroup => [
                $SystemConfig->{'AllowClubTXNs'} && $SystemConfig->{'AllowTXNrpts'} ? $lang->txt('Product Group') : '',
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 1,
                    optiongroup => 'transactions',
                    ddbfield    => 'P.strGroup'
                }
              ],
            strProductType=> [
                $SystemConfig->{'AllowClubTXNs'} && $SystemConfig->{'AllowTXNrpts'} ? $lang->txt('Product Type') : '',
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 1,
                    optiongroup => 'transactions',
                    ddbfield    => 'P.strProductType'
                }
              ],
                ,
              intQty => [
                $SystemConfig->{'AllowClubTXNs'} && $SystemConfig->{'AllowTXNrpts'} ? $lang->txt('Quantity') : '',
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    allowsort   => 1,
                    optiongroup => 'transactions',
                    total       => 1
                }
              ],
              TLstrReceiptRef => [
                $SystemConfig->{'AllowClubTXNs'} && $SystemConfig->{'AllowTXNrpts'}
                ? $lang->txt('Receipt Reference')
                : '',
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    optiongroup => 'transactions',
                    dbfield     => 'TL.strReceiptRef'
                }
              ],
              payment_type => [
                $SystemConfig->{'AllowClubTXNs'} && $SystemConfig->{'AllowTXNrpts'} ? $lang->txt('Payment Type') : '',
                {
                    displaytype     => 'lookup',
                    fieldtype       => 'dropdown',
                    dropdownoptions => \%Defs::paymentTypes,
                    allowsort       => 1,
                    translate       => 1,
                    optiongroup     => 'transactions',
                    dbfield         => 'TL.intPaymentType',
                    allowgrouping   => 1
                }
              ],
              strTXN => [
                $SystemConfig->{'AllowClubTXNs'} && $SystemConfig->{'AllowTXNrpts'} ? $lang->txt('Bank Reference Number') : '',
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    optiongroup => 'transactions',
                    dbfield     => 'TL.strTXN'
                }
              ],
              strOnlinePayReference => [
                $lang->txt('Payment Reference Number'),
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    optiongroup => 'transactions',
                    dbfield     => 'TL.strOnlinePayReference'
                }
              ],
            intLogID => [
                $SystemConfig->{'AllowClubTXNs'} && $SystemConfig->{'AllowTXNrpts'} ? $lang->txt('Payment Log ID') : '',
                {
                    displaytype => 'text',
                    fieldtype   => 'text',
                    optiongroup => 'transactions',
                    dbfield     => 'TL.intLogID'
                }
              ],
            intTransLogStatusID => [
                $SystemConfig->{'AllowClubTXNs'} && $SystemConfig->{'AllowTXNrpts'} ? $lang->txt('Payment Status') : '',
                {
                    displaytype     => 'lookup',
                    fieldtype       => 'dropdown',
                    dropdownoptions => \%Defs::TransLogStatus,
                    allowsort       => 1,
                    optiongroup     => 'transactions',
                    dbfield         => 'TL.intStatus'
                }
              ],
              intAmount => [
                $SystemConfig->{'AllowClubTXNs'} && $SystemConfig->{'AllowTXNrpts'} ? $lang->txt('Order Total') : '',
                {
                    displaytype => 'currency',
                    fieldtype   => 'text',
                    allowsort   => 1,
                    total       => 1,
                    optiongroup => 'transactions',
                    dbfield     => 'TL.intAmount'
                }
              ],
              dtTransaction => [
                ( $SystemConfig->{'AllowClubTXNs'} && $SystemConfig->{'AllowTXNrpts'} ? $lang->txt('Transaction Date') : '' ),
                {
                    displaytype => 'date',
                    fieldtype   => 'datetime',
                    allowsort   => 1,
                    TZdatetimeformat => ['MEDIUM','MEDIUM'],
                    optiongroup => 'transactions',
                    dbfield     => 'TX.dtTransaction',
                    sortfield   => 'TX.dtTransaction'
                }
              ],
              dtPaid => [
                ( $SystemConfig->{'AllowClubTXNs'} && $SystemConfig->{'AllowTXNrpts'} ? $lang->txt('Payment Date') : '' ),
                {
                    displaytype => 'date',
                    fieldtype   => 'datetime',
                    allowsort   => 1,
                    TZdatetimeformat => ['MEDIUM','MEDIUM'],
                    optiongroup => 'transactions',
                    dbfield     => 'TX.dtPaid'
                }
              ],


        },

        Order => [
            qw(
              strStatus
              strRegionName
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
              strAddress
              strAddress2
              strCity
              strState
              strPostalCode
              strPhone
              strFax
              strEmail
                strWebURL
                intTransactionID
                intProductNationalPeriodID
                intProductID
                strGroup
                strProductType
                intQty
                TLstrReceiptRef
                payment_type
                strTXN
                strOnlinePayReference
                intLogID
                intTransLogStatusID
                intAmount 
                dtTransaction
                dtPaid
              )
        ],
        OptionGroups => {
            default        => [ $Data->{'lang'}->txt('Details'), {} ],
            transactions => [
                $txt_Transactions,
                {
                    from =>
"LEFT JOIN tblTransactions AS TX ON (TX.intStatus<>-1 AND NOT (TX.intStatus IN (0,-1)) AND E.intEntityID=TX.intID AND TX.intTableType =0 $txn_WHERE) LEFT JOIN tblTransLog as TL ON (TL.intLogID = TX.intTransLogID)",
                }
            ],
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
            DateTimeFormatObject => $Data->{'l10n'}{'date'},
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

    $where_list=' AND '.$where_list if $where_list;# and ($where_levels or $current_where);

    my $products_join = '';
    if ( $from_list =~ /tblTransactions/ ) {
        $products_join = qq[ LEFT JOIN tblProducts as P ON (P.intProductID=TX.intProductID)];
    }

    $sql = qq[
        SELECT DISTINCT
            ###SELECT###
        FROM 
            tblEntity as E
            INNER JOIN tblTempEntityStructure AS TES ON (
                E.intEntityID = TES.intChildID
            )
            LEFT JOIN tblTempEntityStructure as RL ON (
                E.intEntityID = RL.intChildID
                AND RL.intParentLevel = $Defs::LEVEL_REGION
            )
            LEFT JOIN tblEntity as tblRegion ON (
                RL.intParentID = tblRegion.intEntityID
            ) 
            LEFT JOIN tblTransactions AS TX ON (
                E.intEntityID=TX.intID AND TX.intTableType >1
            ) 
            LEFT JOIN tblTransLog as TL ON (
                TL.intLogID = TX.intTransLogID
            )
            LEFT JOIN tblProducts as P ON (P.intProductID=TX.intProductID)

         WHERE
            E.intRealmID = $Data->{'Realm'}
            AND TES.intParentID = $self->{'EntityID'}
            AND TES.intChildLevel = $Defs::LEVEL_CLUB
            $where_list
    ];
    return ($sql,'');
  }
}

1;

# vim: set et sw=4 ts=4:
