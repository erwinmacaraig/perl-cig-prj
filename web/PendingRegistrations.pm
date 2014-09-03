package PendingRegistrations;
require Exporter;
@ISA    = qw(Exporter);
@EXPORT = @EXPORT_OK = qw(
    handlePendingRegistrations
);

use strict;
use lib '.', '..', 'Clearances';
use Defs;

use Reg_common;
use Utils;
use HTMLForm;
use FieldLabels;
use ConfigOptions qw(ProcessPermissions);
use DeQuote;
use CGI qw(cookie unescape);
use ConfigOptions;

use FieldCaseRule;
use InstanceOf;
use GridDisplay;
use PersonUtils;

use Log;
use Data::Dumper;

use RecordTypeFilter;
use PersonRegistrationDetail;

sub handlePendingRegistrations  {
    my ($action, $Data, $entityID, $personRegistrationID) = @_;

    my $resultHTML = '';
    my $personName = my $title = '';
    my $lang = $Data->{'lang'};

    if ( $action eq 'PENDPR_D' ) {
        $resultHTML = personRegistrationDetail($action, $Data, $entityID, $personRegistrationID) || '';
        $title = $lang->txt('Registration Detail');
    }
    elsif ( $action eq 'PENDPR_')   {
        ($resultHTML , $title)= listPendingRegistrations( $Data, $entityID) ;
        $title = $lang->txt('Pending Registrations');
    }
    else {
        print STDERR "Unknown action $action\n";
    }
    return ( $resultHTML, $title );
}

###### SUBS BELOW ######

sub listPendingRegistrations    {


    my ($Data, $entityID) = @_;
    

    my $lang = $Data->{'lang'};
    my $client = setClient( $Data->{'clientValues'} ) || '';

    my %RegFilters=();
    my $st = qq[
        SELECT
            pr.*,
            p.strLocalFirstname,
            p.strLocalSurname,
            p.strLatinFirstname,
            p.strLatinSurname,
            np.strNationalPeriodName,
            p.dtDOB,
            DATE_FORMAT(p.dtDOB, "%d/%m/%Y") as DOB,
            p.intGender,
            p.intGender as Gender,
            DATE_FORMAT(pr.dtAdded, "%Y%m%d%H%i") as dtAdded_,
            DATE_FORMAT(pr.dtAdded, "%Y-%m-%d %H:%i") as dtAdded_formatted,
            DATE_FORMAT(pr.dtLastUpdated, "%Y%m%d%H%i") as dtLastUpdated_,
            er.strEntityRoleName,
            WFT.strTaskType as WFTTaskType,
            ApprovalEntity.strLocalName as ApprovalLocalName,
            ApprovalEntity.strLatinName as ApprovalEntityName,
            RejectedEntity.strLocalName as RejectedLocalName,
            RejectedEntity.strLatinName as RejectedEntityName
        FROM
            tblPersonRegistration_$Data->{'Realm'} AS pr
            LEFT JOIN tblNationalPeriod as np ON (
                np.intNationalPeriodID = pr.intNationalPeriodID
            )
            LEFT JOIN tblEntityTypeRoles as er ON (
                er.strEntityRoleKey = pr.strPersonEntityRole
                and er.strSport = pr.strSport
                and er.strPersonType = pr.strPersonType
            )
            INNER JOIN tblPerson as p ON (
                p.intPersonID = pr.intPersonID
            )
            INNER JOIN tblWFTask as WFT ON (
                WFT.intPersonRegistrationID = pr.intPersonRegistrationID
                AND WFT.intPersonID = pr.intPersonID
                AND WFT.strTaskStatus IN ('ACTIVE')
            )
            LEFT JOIN tblEntity as ApprovalEntity ON (
                ApprovalEntity.intEntityID = WFT.intApprovalEntityID
            )
            LEFT JOIN tblEntity as RejectedEntity ON (
                RejectedEntity.intEntityID = WFT.intProblemResolutionEntityID
            )
        WHERE
            p.intRealmID = ?
            AND pr.intEntityID = ?
            AND pr.strStatus IN ('PENDING', 'REJECTED')
        GROUP BY 
            pr.intPersonRegistrationID
        ORDER BY
          pr.dtAdded DESC
    ];
    my $results=0;
    my @rowdata = ();
    my $query = $Data->{'db'}->prepare($st);
    $query->execute(
        $Data->{'Realm'},
        $entityID
    );
    while (my $dref = $query->fetchrow_hashref) {
        $results=1;
        my $localname = formatPersonName($Data, $dref->{'strLocalFirstname'}, $dref->{'strLocalSurname'}, $dref->{'intGender'});
        my $name = formatPersonName($Data, $dref->{'strLatinFirstname'}, $dref->{'strLatinSurname'}, $dref->{'intGender'});
        my $local_latin_name = $localname;
        $local_latin_name .= qq[ ($name)] if ($name and $name ne ' ');

        my $entitylocalname = $dref->{'ApprovalLocalName'};
        my $taskTo= $entitylocalname;
        $taskTo.= qq[ ($dref->{'ApprovalEntityName'})] if ($dref->{'ApprovalEntityName'});
        
        if ($dref->{'strStatus'} eq $Defs::WF_TASK_STATUS_REJECTED) {
            $entitylocalname = $dref->{'RejectedLocalName'};
            $taskTo= $entitylocalname;
            $taskTo.= qq[ ($dref->{'RejectedEntityName'})] if ($dref->{'RejectedEntityName'});
        }
        push @rowdata, {
            id => $dref->{'intPersonRegistrationID'} || 0,
            dtAdded=> $dref->{'dtAdded_formatted'} || '',
            PersonLevel=> $Defs::personLevel{$dref->{'strPersonLevel'}} || '',
            PersonEntityRole=> $dref->{'strEntityRoleName'} || '',
            PersonType=> $Defs::personType{$dref->{'strPersonType'}} || '',
            AgeLevel=> $Defs::ageLevel{$dref->{'strAgeLevel'}} || '',
            RegistrationNature=> $Defs::registrationNature{$dref->{'strRegistrationNature'}} || '',
            Status=> $Defs::wfTaskStatus{$dref->{'strStatus'}} || '',
            PersonEntityRole=> $dref->{'strPersonEntityRole'} || '',
            Sport=> $Defs::sportType{$dref->{'strSport'}} || '',
            LocalName=>$localname,
            LatinName=>$name,
            LocalLatinName=>$local_latin_name,
            CurrentTask=>$dref->{'strTaskType'},
            CurrentTaskApproval=>$dref->{'intApprovalEntityID'},
            CurrentTaskProblem=>$dref->{'intProblemResolutionEntityID'},
            NationalPeriodName => $dref->{'strNationalPeriodName'} || '',
            TaskType => $Defs::wfTaskType{$dref->{'WFTTaskType'}} || '',
            TaskTo=>$taskTo,
            SelectLink => "$Data->{'target'}?client=$client&amp;a=PENDPR_D&amp;prID=$dref->{'intPersonRegistrationID'}",
          };
    }

    my $title=$lang->txt('Registration History');

    my $rectype_options='';
    #my $rectype_options=show_recordtypes(
    #    $Data,
    #    '',
    #    '',
    #    \%Defs::personRegoStatus,
    #    { 'ALL' => $Data->{'lang'}->txt('All'), },
    #) || '';
    #$rectype_options='';

    my @headers = (
        {
            type  => 'Selector',
            field => 'SelectLink',
        },
        {
            name  => $Data->{'lang'}->txt('Registration Type'),
            field => 'RegistrationNature',
            width  => 60,
        },
        {
            name  => $Data->{'lang'}->txt('Person'),
            field => 'LocalLatinName',
        },
        {
            name   => $Data->{'lang'}->txt('Type'),
            field  => 'PersonType',
            width  => 30,
        },
        {
            name   => $Data->{'lang'}->txt('Role'),
            field  => 'PersonEntityRole',
            width  => 30,
        },
        {
            name   => $Data->{'lang'}->txt('Sport'),
            field  => 'Sport',
            width  => 40,
        },
        {
            name  => $Data->{'lang'}->txt('Level'),
            field => 'PersonLevel',
            width  => 40,
        },
        {
            name  => $Data->{'lang'}->txt('Age Level'),
            field => 'AgeLevel',
            width  => 40,
        },
        {
            name  => $Data->{'lang'}->txt('Status'),
            field => 'Status',
            width  => 40,
        },
        {
            name  => $Data->{'lang'}->txt('Current Task'),
            field => 'TaskType',
            width  => 50,
        },
        {
            name  => $Data->{'lang'}->txt('Task Assigned To'),
            field => 'TaskTo',
            width  => 70,
        },
        {
            name  => $Data->{'lang'}->txt('Date Registration Added'),
            field => 'dtAdded',
            width  => 50,
        },
    );

    my $filterfields = [
        {
            field     => 'strLocalName',
            elementID => 'id_textfilterfield',
            type      => 'regex',
        },
        {
            field     => 'strStatus',
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

    my $resultHTML = qq[
        <div class="grid-filter-wrap">
            <div style="width:99%;">$rectype_options</div>
            $grid
        </div>
    ];

    return ($resultHTML,$title);
}
1;
